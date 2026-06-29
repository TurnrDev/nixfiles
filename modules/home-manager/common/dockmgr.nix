{ config, pkgs, ... }:

let
  sessionTarget = config.wayland.systemd.target;
in
{
  systemd.user.services.dockmgr = {
    Unit = {
      Description = "Watch dock state and switch DMS profiles";
      ConditionPathExists = "%h/.config/dockmgr/config.json";
      PartOf = [ sessionTarget ];
      Wants = [
        "default.target"
        sessionTarget
        "dms.service"
      ];
      After = [
        "default.target"
        sessionTarget
        "dms.service"
      ];
    };

    Service = {
      Type = "simple";
      ExecStart = "/etc/nixos/scripts/dockmgr watch";
      ExecStartPre = "${pkgs.coreutils}/bin/test -r %h/.config/dockmgr/config.json";
      Environment = [
        "PATH=%h/.nix-profile/bin:/etc/profiles/per-user/%u/bin:/run/current-system/sw/bin"
        "XDG_CONFIG_HOME=%h/.config"
      ];
      Restart = "always";
      RestartSec = "3s";
    };

    Install.WantedBy = [
      "default.target"
      sessionTarget
    ];
  };
}
