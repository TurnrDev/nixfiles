{ pkgs, ... }:

let
  script = builtins.readFile ../../../scripts/dockmgr;
  version = builtins.head (builtins.elemAt (builtins.split ''DOCKMGR_VERSION="([^"]+)"'' script) 1);

  dockMgr =
    (pkgs.writeShellApplication {
      name = "dockmgr";
      runtimeInputs = with pkgs; [
        bash
        coreutils
        gawk
        gnugrep
        jq
        libnotify
        systemd
        util-linux
      ];
      text = script;
    }).overrideAttrs
      (_: {
        pname = "dockmgr";
        inherit version;
        name = "dockmgr-${version}";
      });
in
{
  home.packages = [ dockMgr ];

  systemd.user.services.dockmgr = {
    Unit = {
      Description = "Watch dock state and switch DMS profiles";
      ConditionPathExists = "%h/.config/dockmgr/config.json";
      Wants = [ "dms.service" ];
      After = [ "dms.service" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${dockMgr}/bin/dockmgr watch";
      ExecStartPre = "${pkgs.coreutils}/bin/test -r %h/.config/dockmgr/config.json";
      Environment = [
        "PATH=%h/.nix-profile/bin:/etc/profiles/per-user/%u/bin:/run/current-system/sw/bin"
        "XDG_CONFIG_HOME=%h/.config"
      ];
      Restart = "always";
      RestartPreventExitStatus = "75";
      RestartSec = "3s";
    };

    Install.WantedBy = [
      "dms.service"
    ];
  };
}
