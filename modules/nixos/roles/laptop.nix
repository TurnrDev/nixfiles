# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, inputs, pkgs, ... }:

{
  imports =
    [
      ./workstation.nix
      ../hardware/bluetooth.nix
      ../services/tailscale.nix
    ];

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;
  services.power-profiles-daemon.enable = true;
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchDocked = "ignore";
  };
  
}
