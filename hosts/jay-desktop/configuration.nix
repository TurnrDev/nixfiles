{
  config,
  ...
}:

{
  imports = [
    # Regenerate hardware-configuration.nix with:
    # sudo nixos-generate-config --show-hardware-config --no-filesystems > /etc/nixos/hosts/$(hostname)/hardware-configuration.nix
    ./hardware-configuration.nix
    ./storage.nix
    ../../modules/nixos/roles/desktop.nix
    ../../modules/nixos/hardware/bluetooth.nix
    ../../modules/nixos/hardware/keychron.nix
    ../../modules/nixos/hardware/logitech-mx-master-3s.nix
    ../../modules/nixos/roles/gaming.nix
  ];

  networking = {
    hostName = "jay-desktop";
    interfaces = {
      enp13s0 = {
        wakeOnLan.enable = true;
      };
    };
  };

  programs.dockmgr.profiles = [
    {
      name = "Default";
      outputs."DP-2" = {
        mode = "5120x1440@240";
        position = {
          x = 0;
          y = 0;
        };
        scale = 1.0;
      };
    }
  ];

}
