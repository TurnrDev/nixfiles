# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, inputs, lib, pkgs, ... }:

{
  my.backups.borgmatic.extraExcludePatterns = lib.mkAfter [
    "${config.my.identity.homeDirectory}/.local/share/Steam"
    "${config.my.identity.homeDirectory}/.steam-shared"
    "${config.my.identity.homeDirectory}/.steam"
  ];

  programs.steam = {
    enable = true;
    extraCompatPackages = with pkgs; [ proton-ge-bin ];
  };

  environment.systemPackages = with pkgs; [
    prismlauncher
  ];

}
