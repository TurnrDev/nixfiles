_:

{
  flake.modules.nixos.system-plymouth-luks = {
    # Show the graphical passphrase prompt for the host's LUKS devices.
    # Devices belong in host storage modules; early GPU drivers in hardware modules.
    boot.plymouth.enable = true;
  };
}
