{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../../modules/home-manager/roles/desktop.nix
    ../../modules/home-manager/hardware/amd.nix
  ];

  programs.borgmatic.backups.shared.hooks.extraConfig.healthchecks = {
    ping_url = "https://healthchecks.infra.turnr.net/ping/3864da02-bd3e-4f8f-9685-825959aa6cf9";
    send_logs = true;
  };

}
