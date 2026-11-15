_:

{
  flake.modules.nixos.hardware-mouse-logitech-mx-master-3s =
    _:

    {
      hardware.logitech.wireless.enable = true;
      programs.solaar.enable = true;
    };
}
