{ pkgs, ... }:
let
  goHassAgent = pkgs.callPackage ../../../pkgs/go-hass-agent.nix { };
in
{
  home.packages = [ goHassAgent ];

  # Run go-hass-agent continuously as a user service so it starts on login.
  systemd.user.services.go-hass-agent = {
    Unit = {
      Description = "go-hass-agent";
      Wants = [ "network-online.target" ];
      After = [ "network-online.target" ];
    };

    Service = {
      ExecStart = "${goHassAgent}/bin/go-hass-agent run";
      Restart = "always";
      RestartSec = 5;
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
