{
  config,
  ...
}:

{
  boot.initrd.supportedFilesystems = [ "btrfs" ];
  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-partlabel/nixos-crypt";
    allowDiscards = true;
    crypttabExtraOpts = [ "tpm2-device=auto" ];
  };
  boot.supportedFilesystems = [ "btrfs" ];

  fileSystems."/" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [
      "subvol=@"
      "compress=zstd"
      "noatime"
    ];
  };
  fileSystems."/nix" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [
      "subvol=@nix"
      "compress=zstd"
      "noatime"
    ];
  };
  fileSystems."/home" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [
      "subvol=@home"
      "compress=zstd"
      "noatime"
    ];
  };
  fileSystems."/var/log" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [
      "subvol=@log"
      "compress=zstd"
      "noatime"
    ];
  };
  fileSystems."/swap" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [
      "subvol=@swap"
      "noatime"
      "compress=no"
    ];
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/nixos-efi";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

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

  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 32 * 1024;
    }
  ];
}
