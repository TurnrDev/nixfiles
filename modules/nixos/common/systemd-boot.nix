{ inputs, ... }:

{
  imports = [
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  # Keep systemd in the initrd for the graphical, passphrase-based LUKS
  # unlock flow managed by Plymouth.
  boot.initrd.systemd.enable = true;
  boot.lanzaboote = {
    enable = true;
    # Reuse the sbctl PKI so Secure Boot key creation and Lanzaboote's UKI
    # signing both point at the same trust chain.
    pkiBundle = "/var/lib/sbctl";
  };

  # Bootloader.
  boot.loader = {
    efi.canTouchEfiVariables = true;
    timeout = 1;
    systemd-boot = {
      enable = false;
      configurationLimit = 10;
    };
  };
}
