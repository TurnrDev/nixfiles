_:
{
  # The Wyse firmware boots the internal eMMC reliably, whereas it fails to
  # load EFI binaries from the M.2-to-microSD adapter. The root filesystem and
  # Nix store remain on that SD card. The GPT partition labels are unique and
  # remain stable even if the two MMC devices enumerate in a different order.
  fileSystems."/" = {
    device = "/dev/disk/by-partlabel/disk-g9-switcher-card-root";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/ESP";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };
}
