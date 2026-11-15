_:

{
  flake.modules.nixos.hardware-npu-intel = _: {
    hardware.cpu.intel.npu.enable = true;
  };
}
