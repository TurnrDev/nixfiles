{
  # Nixos-anywhere/Disko owns the complete layout of the Wyse SD card.
  # Do not point this at the built-in /dev/mmcblk0 eMMC.
  disko.devices.disk.g9-switcher-card = {
    type = "disk";
    device = "/dev/mmcblk1";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [
              "fmask=0077"
              "dmask=0077"
            ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
