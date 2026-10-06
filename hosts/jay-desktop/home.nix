{ lib, ... }:

{
  imports = [
    ../../modules/home-manager/roles/desktop.nix
    ../../modules/home-manager/roles/gaming.nix
    ../../modules/home-manager/hardware/amd.nix
  ];

  programs.borgmatic.backups =
    lib.genAttrs
      [
        "borg1.4"
        "borg2"
      ]
      (_: {
        hooks.extraConfig.healthchecks = {
          ping_url = "https://healthchecks.infra.turnr.net/ping/3864da02-bd3e-4f8f-9685-825959aa6cf9";
          send_logs = true;
        };
      });

}
