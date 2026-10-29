{ lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./storage.nix
    ../../modules/nixos/roles/default.nix
  ];

  networking.hostName = "g9-switcher";
  nixpkgs.hostPlatform = "x86_64-linux";
  # The shared default role enables Lanzaboote for the existing Secure Boot
  # hosts. The Wyse installer uses the standard UEFI systemd-boot path.
  boot.lanzaboote.enable = lib.mkForce false;
  boot.loader.systemd-boot.enable = lib.mkForce true;
  boot.loader.efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = "/boot";
  };

  hardware.enableAllFirmware = true;
}
