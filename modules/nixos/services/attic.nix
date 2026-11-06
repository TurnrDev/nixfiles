{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.attic;
  atticTokenPath = config.sops.secrets.attic-token.path;
  uploadQueueDirectory = "/var/lib/attic-upload/pending";
  enqueueUpload = pkgs.writeShellScript "attic-enqueue-upload" ''
    # Do not make a post-build hook interfere with Nix's build loop. The hook
    # can run as an unprivileged Nix build user, so it only creates one private
    # queue file in a group-writable spool; systemd performs network I/O later.
    set -u
    queue_file="$(${pkgs.coreutils}/bin/mktemp ${uploadQueueDirectory}/paths.XXXXXX)" || exit 0
    ${pkgs.coreutils}/bin/chmod 0600 "$queue_file" || exit 0
    for path in ''${OUT_PATHS:-}; do
      printf "%s\\n" "$path" >> "$queue_file" || {
        ${pkgs.coreutils}/bin/rm -f "$queue_file"
        exit 0
      }
    done
  '';
  uploadPending = pkgs.writeShellScript "attic-upload-pending" ''
    set -eu
    for queue in ${uploadQueueDirectory}/paths.*; do
      [ -e "$queue" ] || break
      while IFS= read -r path || [ -n "$path" ]; do
        [ -n "$path" ] || continue

        # A path can be garbage collected before a disconnected machine gets
        # back online. Drop that stale queue item instead of retrying forever.
        if ! ${pkgs.nix}/bin/nix path-info "$path" >/dev/null 2>&1; then
          continue
        fi

        # attic push checks which paths are already present and honours the
        # cache upstream-key filter, so this does not republish Nixpkgs paths.
        ${pkgs.attic-client}/bin/attic push home "$path"
      done < "$queue"
      ${pkgs.coreutils}/bin/rm -f "$queue"
    done
  '';
in
{
  options.my.attic = {
    enable = lib.mkEnableOption "the private home Attic binary cache" // {
      default = true;
    };

    upload.enable = lib.mkEnableOption "asynchronous uploading of locally built paths to Attic";
  };

  config = lib.mkIf cfg.enable {
    nix.settings = {
      substituters = lib.mkAfter [ "https://attic.infra.turnr.net/home" ];
      trusted-public-keys = lib.mkAfter [ "home:UZTl/gEUbtCPZdJgPOUAC0CO0dBNndyk0dOOf73vCGA=" ];
      netrc-file = "/run/secrets/attic-netrc";
      # Continue with another substituter or a source build when Attic is down.
      fallback = true;
    };

    sops.secrets.attic-token = {
      sopsFile = ../../../secrets/shared.yaml;
      owner = "root";
      group = "root";
      mode = "0400";
    };

    # Attic accepts a token as the Basic Auth password; Nix reads this at daemon
    # runtime, so the token is never copied into a Nix expression or the store.
    sops.templates.attic-netrc = {
      path = "/run/secrets/attic-netrc";
      content = ''
        machine attic.infra.turnr.net
        password ${config.sops.placeholder.attic-token}
      '';
      owner = "root";
      group = "root";
      mode = "0400";
      restartUnits = [ "nix-daemon.service" ];
    };

    environment.systemPackages = [ pkgs.attic-client ];

    environment.etc."attic/config.toml" = lib.mkIf cfg.upload.enable {
      mode = "0400";
      text = ''
        default-server = "home"

        [servers.home]
        endpoint = "https://attic.infra.turnr.net/"
        token-file = "${atticTokenPath}"
      '';
    };

    nix.settings.post-build-hook = lib.mkIf cfg.upload.enable enqueueUpload;

    systemd.tmpfiles.rules = lib.mkIf cfg.upload.enable [
      "d /var/lib/attic-upload 0750 root nixbld -"
      "d ${uploadQueueDirectory} 0730 root nixbld -"
    ];

    systemd.services.attic-upload = lib.mkIf cfg.upload.enable {
      description = "Upload queued locally-built Nix paths to Attic";
      after = [
        "network-online.target"
        "sops-nix.service"
      ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "exec";
        ExecStart = uploadPending;
        Environment = "XDG_CONFIG_HOME=/etc";
        StateDirectory = "attic-upload";
        UMask = "0077";
        Restart = "on-failure";
        RestartSec = "5min";
      };
    };

    systemd.paths.attic-upload = lib.mkIf cfg.upload.enable {
      wantedBy = [ "multi-user.target" ];
      pathConfig.PathChanged = uploadQueueDirectory;
    };

    # A timer covers boots and missed inotify events, and retries work left in
    # the durable local spool after an unavailable-network failure.
    systemd.timers.attic-upload = lib.mkIf cfg.upload.enable {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitInactiveSec = "5min";
        Persistent = true;
      };
    };
  };
}
