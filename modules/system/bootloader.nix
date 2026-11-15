# Copy this file into modules/ and replace `example` with a unique module name.
# Keep either or both blocks. Registering a module does not enable it on a host.
{ inputs, ... }:

{
  flake.modules.nixos.example =
    { lib, ... }:

    {
      imports = [
        inputs.lanzaboote.nixosModules.lanzaboote
      ];

      boot.lanzaboote = {
        enable = lib.mkDefault true;
        # Reuse the sbctl PKI so Secure Boot key creation and Lanzaboote's UKI
        # signing both point at the same trust chain.
        pkiBundle = "/var/lib/sbctl";
      };

      boot.loader = {
        efi.canTouchEfiVariables = true;
        timeout = 1;
        systemd-boot = {
          enable = lib.mkDefault false;
          configurationLimit = 10;
        };
      };
    };
}
