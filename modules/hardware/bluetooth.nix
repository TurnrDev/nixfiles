{ ... }:

{
  flake.modules.nixos.hardware-bluetooth =
    _:

    {
      hardware.bluetooth.enable = true;
      services.blueman.enable = true;
    };
}
