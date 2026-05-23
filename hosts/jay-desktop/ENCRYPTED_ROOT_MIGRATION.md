# jay-desktop Encrypted Root Migration to NVMe

This guide migrates `jay-desktop` from the current Intel SATA SSD root disk
onto the `2 TB` WD_BLACK NVMe while keeping:

- an encrypted root filesystem
- Btrfs subvolumes: `@`, `@nix`, `@home`, `@log`, `@swap`
- a swap file at `/swap/swapfile`
- Windows on the Samsung SATA SSD untouched

This procedure assumes:

- current root disk: `111.8G` Intel `SSDMCEAW120A4`
- Windows disk: `465.8G` Samsung `850 EVO`
- temporary copy/staging disk: `931.5G` `ST1000LM014-1EJ164`, mounted as
  `/mnt/slow` and reformatted to `ext4`
- target disk: `1.8T` WD_BLACK `SN850X`

This guide destroys the current contents of the WD_BLACK NVMe. If Arch or any
other data still matters on that disk, stop here.

Do this from NixOS installer media, not from the running installed system.

## Intended Final Layout

- `nvme0n1p1`: `512 MiB` EFI system partition, GPT label `nixos-efi`
- `nvme0n1p2`: rest of disk, GPT label `nixos-crypt`
- LUKS2 on `nixos-crypt`
- Btrfs on `/dev/mapper/cryptroot`
- Btrfs subvolumes:
  - `@`
  - `@nix`
  - `@home`
  - `@log`
  - `@swap`

## 1. Pre-Migration Prep on the Running System

Make sure `/mnt/slow` is available as an `ext4` staging disk.

Check the disks:

```sh
lsblk -o NAME,PATH,MODEL,SERIAL,SIZE,TYPE,FSTYPE,LABEL,PARTLABEL,UUID,MOUNTPOINTS
```

Expected devices:

```text
/dev/sda      111.8G  INTEL SSDMCEAW120A4
/dev/sdb      465.8G  Samsung SSD 850 EVO 500GB
/dev/sdc      931.5G  ST1000LM014-1EJ164
/dev/nvme0n1    1.8T  WD_BLACK SN850X HS 2000GB
```

Copy the data you care about onto `/mnt/slow`.

Typical copy commands:

```sh
sudo rsync -aHAXv --numeric-ids --partial --append-verify --info=progress2 --progress /home/ /mnt/slow/home/
sudo rsync -aHAXv --numeric-ids --partial --append-verify --info=progress2 --progress /etc/nixos/ /mnt/slow/etc-nixos/
```

Adjust paths if you have other local state to preserve.

## 2. Boot the Installer and Identify the Target Disk

Boot a NixOS installer USB and open a shell.

List the disks again and confirm the target by model:

```sh
lsblk -o NAME,PATH,MODEL,SERIAL,SIZE,TYPE,FSTYPE,LABEL,PARTLABEL,UUID,MOUNTPOINTS
```

The target disk for the new install is:

```text
MODEL: WD_BLACK SN850X HS 2000GB
SIZE:  1.8T
PATH:  /dev/nvme0n1
```

Do not partition:

- the Intel SATA SSD unless you are explicitly retiring it now
- the Samsung Windows SSD
- the `ST1000LM014` staging disk

## 2.5. Mount the Staging Disk in the Installer

The installer environment does not know about your usual `/mnt/slow` mount, so
mount it manually at `/slow` before you need the staged repo or backup data.

If you labeled the filesystem `slow`, use:

```sh
sudo mkdir -p /slow
sudo mount /dev/disk/by-label/slow /slow
```

Verify that the staged data is present:

```sh
ls /slow
ls /slow/etc/nixos
```

If the label is missing or different, identify the disk first:

```sh
lsblk -o NAME,PATH,MODEL,SIZE,FSTYPE,LABEL,MOUNTPOINTS
```

Then mount the correct partition directly, for example:

```sh
sudo mount /dev/sdc1 /slow
```

## 3. Partition the NVMe

This wipes the NVMe.

```sh
sudo swapoff --all

sudo parted /dev/nvme0n1 -- mklabel gpt
sudo parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 513MiB
sudo parted /dev/nvme0n1 -- set 1 esp on
sudo parted /dev/nvme0n1 -- name 1 nixos-efi
sudo parted /dev/nvme0n1 -- mkpart primary 513MiB 100%
sudo parted /dev/nvme0n1 -- name 2 nixos-crypt
```

## 4. Create the Encrypted Btrfs Layout

```sh
sudo mkfs.fat -F 32 -n NIXBOOT /dev/nvme0n1p1

sudo cryptsetup luksFormat --type luks2 /dev/disk/by-partlabel/nixos-crypt
sudo cryptsetup open /dev/disk/by-partlabel/nixos-crypt cryptroot

sudo mkfs.btrfs -L nixos-root /dev/mapper/cryptroot
sudo mount /dev/mapper/cryptroot /mnt

sudo btrfs subvolume create /mnt/@
sudo btrfs subvolume create /mnt/@nix
sudo btrfs subvolume create /mnt/@home
sudo btrfs subvolume create /mnt/@log
sudo btrfs subvolume create /mnt/@swap
sudo chattr +C /mnt/@swap

sudo umount /mnt

sudo mount -o subvol=@,compress=zstd,noatime /dev/mapper/cryptroot /mnt
sudo mkdir -p /mnt/boot /mnt/nix /mnt/home /mnt/var/log /mnt/swap
sudo mount -o subvol=@nix,compress=zstd,noatime /dev/mapper/cryptroot /mnt/nix
sudo mount -o subvol=@home,compress=zstd,noatime /dev/mapper/cryptroot /mnt/home
sudo mount -o subvol=@log,compress=zstd,noatime /dev/mapper/cryptroot /mnt/var/log
sudo mount -o subvol=@swap,noatime,compress=no /dev/mapper/cryptroot /mnt/swap
sudo mount /dev/disk/by-partlabel/nixos-efi /mnt/boot
```

## 5. Refresh Hardware Config and Keep the Flake as Source of Truth

The important distinction here is:

- your checked-in flake in `/etc/nixos` is the config you want to install
- `nixos-generate-config` is only used to scan the new NVMe layout and produce
  fresh hardware-specific mount and LUKS details

First, generate fresh hardware data against the mounted target:

```sh
sudo nixos-generate-config --root /mnt
```

That writes temporary files under `/mnt/etc/nixos/`, including a generated
`hardware-configuration.nix` for the new disk layout.

Now copy your real flake into the target install, because that is what
`nixos-install --flake` should use. In this migration flow, that means the repo
you staged onto `/mnt/slow/etc/nixos`, now mounted in the installer at
`/slow/etc/nixos`:

```sh
sudo mkdir -p /mnt/etc
sudo rsync -aHAX /slow/etc/nixos/ /mnt/etc/nixos/
```

At this point, your copied flake may have reintroduced the old
`hosts/jay-desktop/hardware-configuration.nix` from the Intel-root system. Fix
that before installing.

Use the freshly generated hardware file as reference and make sure the copied
`/mnt/etc/nixos/hosts/jay-desktop/hardware-configuration.nix` contains:

- `boot.initrd.luks.devices."cryptroot".device = "/dev/disk/by-partlabel/nixos-crypt";`
- `fileSystems."/"` on `/dev/mapper/cryptroot` with `subvol=@`
- `fileSystems."/nix"` with `subvol=@nix`
- `fileSystems."/home"` with `subvol=@home`
- `fileSystems."/var/log"` with `subvol=@log`
- `fileSystems."/swap"` with `subvol=@swap`
- `fileSystems."/boot"` on `/dev/disk/by-partlabel/nixos-efi`

In other words: do not install from the generated stub config, and do not
blindly trust the old checked-in hardware file either. Install from your flake,
but update the flake's `hosts/jay-desktop/hardware-configuration.nix` so it
matches the newly generated NVMe/LUKS/Btrfs layout first.

## 6. Restore Preserved Data Into the New Root

At minimum, restore your saved home directory contents:

```sh
sudo rsync -aHAXv --numeric-ids --info=progress2 --progress /slow/home/ /mnt/home/
```

If you staged the flake elsewhere, restore that too before install:

```sh
sudo rsync -aHAX /slow/etc-nixos/ /mnt/etc/nixos/
```

Only restore non-reproducible data. Do not blindly copy old transient system
state into the new install.

## 7. Install NixOS

Install from the flake:

```sh
sudo nixos-install --flake /mnt/etc/nixos#jay-desktop
```

If bootloader config or hardware config still references the wrong disk, fix
that before rebooting.

## 8. Reboot and Verify

After install:

```sh
sudo reboot
```

Once booted into the new system:

```sh
findmnt -no SOURCE,FSTYPE /
lsblk -f
swapon --show
cat /proc/cmdline
```

Expected results:

- `/` is mounted from `/dev/mapper/cryptroot` as `btrfs`
- `/boot` is the NVMe EFI partition labeled `nixos-efi`
- the encrypted backing partition is on `nvme0n1p2`
- swap is `/swap/swapfile`
- boot prompts for the LUKS passphrase

## 9. After the Migration

Once you have confirmed the NVMe system boots and your data is present:

- the Intel mSATA SSD can be removed and repurposed as a USB drive
- the `ST1000LM014` can stay as temporary staging until you are sure nothing is
  missing
- after that, either keep the `1 TB` disk as Linux storage or unplug it

## Notes

- The `jay-desktop` config uses manual GRUB entries for Windows and Arch. If
  Arch is being removed, clean those entries up later.
- Reformatting `/mnt/slow` from `exfat` to `ext4` was the right move for this
  migration because it preserves Linux ownership, mode bits, ACLs, and xattrs.
- Do not run write benchmarks or destructive commands against the old Intel SSD
  until you are certain the NVMe install is working.
