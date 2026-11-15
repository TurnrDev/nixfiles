{
  config,
  lib,
  modulesPath,
  ...
}:

{
  flake.modules.nixos.g9-switcher = {
    # The root filesystem lives on the M.2-to-microSD adapter, so these drivers
    # must be available before the real root is mounted.
    boot.initrd.availableKernelModules = [
      "mmc_block"
      "sdhci"
      "sdhci_acpi"
      "sdhci_pci"
    ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [
      "mmc_block"
      "sdhci"
      "sdhci_acpi"
      "sdhci_pci"
    ];
    boot.extraModulePackages = [ ];

    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
