{
  config,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/roles/desktop.nix
    ../../modules/nixos/hardware/bluetooth.nix
    ../../modules/nixos/hardware/keychron.nix
    ../../modules/nixos/hardware/logitech-mx-master-3s.nix
    ../../modules/nixos/roles/gaming.nix
  ];

  fileSystems."/mnt/win" = {
    device = "/dev/disk/by-uuid/9AFC2B85FC2B5AB1";
    fsType = "ntfs3";
    options = [
      "nofail"
      "noauto"
      "x-systemd.automount"
      "ro"
      "uid=${config.my.identity.username}"
      "gid=users"
      "windows_names"
    ];
  };

  fileSystems."/mnt/slow" = {
    device = "/dev/disk/by-label/slow";
    fsType = "ext4";
    options = [
      "nofail"
      "noauto"
      "x-systemd.automount"
    ];
  };

  networking = {
    hostName = "jay-desktop";
    interfaces = {
      enp13s0 = {
        wakeOnLan.enable = true;
      };
    };
  };

  my.dockmgr.profiles = [
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

  # Per-device borgmatic overrides live in the host config. The shared module
  # provides the defaults and translates this block into borgmatic YAML.
  my.backups.borgmatic = {
    frequency = "daily";
    sourceDirectories = [ config.my.identity.homeDirectory ];
    healthchecksUrl = "https://healthchecks.home.turnr.dev/ping/3864da02-bd3e-4f8f-9685-825959aa6cf9";
    repositories = {
      hetzner.path = "ssh://u551190@u551190.your-storagebox.de:23/./arch";
    };
  };

}
