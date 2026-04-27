{ inputs, ... }:

{
  imports = [
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  # systemd in the initrd is what makes TPM-backed LUKS token unlocking work
  # cleanly during boot once a volume has been enrolled with
  # `systemd-cryptenroll`.
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
