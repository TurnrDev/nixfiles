{ config, inputs, lib, pkgs, ... }:

{
  imports = [
    ../../modules/home-manager/roles/laptop.nix
  ];

  programs.dank-material-shell.settings = {
    dockLauncherLogoCustomPath = lib.mkForce "/etc/nixos/framework-logo.svg";
    dockLauncherLogoMode = lib.mkForce "custom";
    launcherLogoCustomPath = lib.mkForce "/etc/nixos/framework-logo.svg";
    launcherLogoMode = lib.mkForce "custom";
  };
}
