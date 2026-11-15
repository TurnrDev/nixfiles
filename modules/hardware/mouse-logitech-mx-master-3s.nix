# Copy this file into modules/ and replace `example` with a unique module name.
# Keep either or both blocks. Registering a module does not enable it on a host.
{ inputs, ... }:

{
  flake.modules.nixos.hardware-mouse-logitech-mx-master-3s =
    _:

    {
      hardware.logitech.wireless.enable = true;
      programs.solaar.enable = true;
    };
}
