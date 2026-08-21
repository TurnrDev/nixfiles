{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../../modules/home-manager/roles/laptop.nix
    ../../modules/home-manager/hardware/amd.nix
  ];

  programs.borgmatic.backups.shared.hooks.extraConfig.healthchecks = {
    ping_url = "https://healthchecks.infra.turnr.net/ping/66bb872c-5ff0-4398-ba0c-7db7f3f7b731";
    send_logs = true;
  };

}
