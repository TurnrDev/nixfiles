{ config, pkgs, ... }:

let
  sessionTarget = config.wayland.systemd.target;
  dockMgr = pkgs.writeShellApplication {
    name = "dockmgr";
    runtimeInputs = with pkgs; [
      bash
      coreutils
      gawk
      gnugrep
      jq
      systemd
    ];
    text = builtins.readFile ../../../scripts/dockmgr;
  };
in
{
  home.packages = [ dockMgr ];

  systemd.user.services.dockmgr = {
    Unit = {
      Description = "Watch dock state and switch DMS profiles";
      ConditionPathExists = "%h/.config/dockmgr/config.json";
      PartOf = [ sessionTarget ];
      Requires = [
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
      ExecStart = "${dockMgr}/bin/dockmgr watch";
      ExecStartPre = "${pkgs.coreutils}/bin/test -r %h/.config/dockmgr/config.json";
      Environment = [
        "PATH=%h/.nix-profile/bin:/etc/profiles/per-user/%u/bin:/run/current-system/sw/bin"
        "XDG_CONFIG_HOME=%h/.config"
      ];
      Restart = "always";
      RestartSec = "3s";
    };

    Install.WantedBy = [
      sessionTarget
    ];
  };
}
