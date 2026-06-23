{ config, ... }:

let
  sessionTarget = config.wayland.systemd.target;
in
{
  systemd.user.services.dockmgr = {
    Unit = {
      Description = "Watch dock state and switch DMS output profiles";
      PartOf = [ sessionTarget ];
      Wants = [
        sessionTarget
        "dms.service"
      ];
      After = [
        sessionTarget
        "dms.service"
      ];
    };

    Service = {
      Type = "simple";
      ExecStart = "/etc/nixos/scripts/dockmgr watch";
      Environment = [
        "PATH=%h/.nix-profile/bin:/etc/profiles/per-user/%u/bin:/run/current-system/sw/bin"
      ];
      Restart = "always";
      RestartSec = "3s";
    };

    Install.WantedBy = [ sessionTarget ];
  };
}
