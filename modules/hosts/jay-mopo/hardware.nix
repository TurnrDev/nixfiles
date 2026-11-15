{
  inputs,
  ...
}:

{
  flake.modules.nixos.jay-mopo = {
    imports = with inputs.self.modules.nixos; [
      hardware-cpu-intel
      hardware-gpu-intel
      hardware-npu-intel
    ];

    boot.initrd.availableKernelModules = [
      "xhci_pci"
      "thunderbolt"
      "nvme"
      "usbhid"
      "rtsx_usb_sdmmc"
    ];
    # Plymouth needs early KMS to show the graphical LUKS prompt.
    boot.initrd.kernelModules = [ "i915" ];
    boot.extraModulePackages = [ ];
  };
}
