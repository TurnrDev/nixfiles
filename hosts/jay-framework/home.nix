{ lib, ... }:

{
  imports = [
    ../../modules/home-manager/roles/laptop.nix
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
          ping_url = "https://healthchecks.infra.turnr.net/ping/66bb872c-5ff0-4398-ba0c-7db7f3f7b731";
          send_logs = true;
        };
      });

}
