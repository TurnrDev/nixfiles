{ ... }:

{
  flake.modules.nixos.hardware-low-ram =
    _:

    {
      zramSwap = {
        enable = true;
        algorithm = "zstd";
        memoryPercent = 50;
        priority = 100;
      };
    };
}
