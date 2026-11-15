{ ... }:

{
  flake.modules.nixos.hardware-npu-intel =
    { ... }:
    {
      hardware.cpu.intel.npu.enable = true;
    };
}
