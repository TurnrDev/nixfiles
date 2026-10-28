{ inputs, lib, ... }:

{
  imports = [
    inputs.disko.nixosModules.disko
    ./disko.nix
    ../../modules/nixos/roles/default.nix
  ];

  networking.hostName = "g9-switcher";
  nixpkgs.hostPlatform = "x86_64-linux";
  # The shared default role enables Lanzaboote for the existing Secure Boot
  # hosts. The Wyse installer uses the standard UEFI systemd-boot path.
  boot.lanzaboote.enable = lib.mkForce false;
  boot.loader.systemd-boot.enable = lib.mkForce true;

  # Keep the TF card adapter available during boot and after installation.
  boot.initrd.availableKernelModules = [
    "mmc_block"
    "sdhci"
    "sdhci_acpi"
    "sdhci_pci"
  ];
  boot.kernelModules = [
    "mmc_block"
    "sdhci"
    "sdhci_acpi"
    "sdhci_pci"
  ];

  hardware.enableAllFirmware = true;
}
