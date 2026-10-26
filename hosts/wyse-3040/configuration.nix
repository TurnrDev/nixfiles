{ ... }:

{
  imports = [
    ../../modules/nixos/roles/default.nix
  ];

  networking.hostName = "wyse-3040";
  nixpkgs.hostPlatform = "x86_64-linux";

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
