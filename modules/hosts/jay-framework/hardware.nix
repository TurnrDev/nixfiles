{ inputs, ... }:

{
  flake.modules.nixos.jay-framework =
    { config, lib, ... }:
    {
      imports = with inputs.self.modules.nixos; [
        hardware-cpu-amd
        hardware-gpu-amd
      ];

      boot.initrd.availableKernelModules = [
        "nvme"
        "xhci_pci"
        "thunderbolt"
        "usb_storage"
        "sd_mod"
      ];
      # Plymouth needs early KMS to show the graphical LUKS prompt.
      boot.initrd.kernelModules = [ "amdgpu" ];
      boot.kernelModules = [ "kvm-amd" ];
      boot.extraModulePackages = [ ];

      hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };

  flake.modules.homeManager.jay-framework = {
    imports = with inputs.self.modules.homeManager; [
      hardware-gpu-amd
    ];
  };
}
