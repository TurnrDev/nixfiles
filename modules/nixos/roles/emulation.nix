{
  config,
  pkgs,
  ...
}:

let
  es-de = pkgs.callPackage ../../../packages/es-de { };
  greenlight = pkgs.callPackage ../../../packages/greenlight { };
  kytyps5 = pkgs.callPackage ../../../packages/kytyps5 { };
  sharpemu = pkgs.callPackage ../../../packages/sharpemu { };
in
{
  boot.supportedFilesystems = [ "nfs" ];

  environment.systemPackages = with pkgs; [
    es-de
    nfs-utils

    # Multi-system emulation and arcade hardware.
    retroarch-full
    ares
    mame

    # Nintendo.
    melonds
    azahar
    dolphin-emu
    cemu
    ryubing

    # Sony.
    pcsx2
    rpcs3
    shadps4
    sharpemu
    kytyps5
    ppsspp
    vita3k

    # Microsoft.
    xemu
    xenia-canary
    greenlight
  ];

  fileSystems."/srv/nfs/games" = {
    device = "home.turnr.net:/data/media/games";
    fsType = "nfs";
    options = [
      "_netdev"
      "nfsvers=4.2"
      "ro"
      "noauto"
      "x-systemd.automount"
      "x-systemd.mount-timeout=10"
      "timeo=14"
      "x-systemd.idle-timeout=1min"
    ];
  };

  services.syncthing.settings.folders = {
    "Ryujinx" = {
      path = "${config.my.identity.homeDirectory}/.config/Ryujinx/";
      devices = config.my.syncthing.personalDeviceList;
      versioning = {
        type = "simple";
        params.keep = "10";
      };
    };
    "Retroarch-saves" = {
      path = "${config.my.identity.homeDirectory}/.config/retroarch/saves/";
      devices = config.my.syncthing.personalDeviceList;
      versioning = {
        type = "simple";
        params.keep = "10";
      };
    };
    "Retroarch-states" = {
      path = "${config.my.identity.homeDirectory}/.config/retroarch/states/";
      devices = config.my.syncthing.personalDeviceList;
      versioning = {
        type = "simple";
        params.keep = "10";
      };
    };
  };
}
