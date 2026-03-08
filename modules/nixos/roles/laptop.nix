# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, inputs, pkgs, ... }:

{
  imports =
    [
      ./pc.nix
      ../hardware/bluetooth.nix
    ];

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;
}
