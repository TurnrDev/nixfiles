{
  ...
}:

{
  fileSystems."/" = {
    device = "/dev/mapper/luks-99292f4d-fda6-4bce-9ff5-f6b344d1e449";
    fsType = "ext4";
  };
  boot.initrd.luks.devices."luks-99292f4d-fda6-4bce-9ff5-f6b344d1e449".device =
    "/dev/disk/by-uuid/99292f4d-fda6-4bce-9ff5-f6b344d1e449";
  boot.initrd.luks.devices."luks-d5a84443-b5a5-485b-848e-8c50df120425".device =
    "/dev/disk/by-uuid/d5a84443-b5a5-485b-848e-8c50df120425";
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/86A7-6521";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };
  swapDevices = [ { device = "/dev/mapper/luks-d5a84443-b5a5-485b-848e-8c50df120425"; } ];
}
