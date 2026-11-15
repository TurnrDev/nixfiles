{ inputs, ... }:

{
  flake.modules.nixos.jay-desktop =
    { ... }:
    {
      imports = with inputs.self.modules.nixos; [
        hardware-cpu-amd
        hardware-gpu-amd
        hardware-low-ram
      ];

      boot.initrd.availableKernelModules = [
        "xhci_pci"
        "ahci"
        "nvme"
        "usbhid"
        "sd_mod"
      ];
      boot.initrd.kernelModules = [ ];
      boot.extraModulePackages = [ ];

    };

  flake.modules.homeManager.jay-desktop = {
    imports = with inputs.self.modules.homeManager; [
      hardware-gpu-amd
    ];
  };
}
