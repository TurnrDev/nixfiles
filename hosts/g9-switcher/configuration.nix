{ config, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./storage.nix
    ../../modules/nixos/roles/default.nix
    ../../modules/nixos/services/monitorctl.nix
  ];

  networking.hostName = "g9-switcher";
  nixpkgs.hostPlatform = "x86_64-linux";
  # The shared default role enables Lanzaboote for the existing Secure Boot
  # hosts. The Wyse installer uses the standard UEFI systemd-boot path.
  boot.lanzaboote.enable = lib.mkForce false;
  boot.loader.systemd-boot.enable = lib.mkForce true;
  boot.loader.efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = "/boot";
  };

  hardware.enableAllFirmware = true;

  # `D` keeps the HDMI connector enabled even when the G9 does not provide an
  # EDID. It is necessary for monitor-switch's local_video safety guard; the
  # requested resolution may still fall back when the EDID is absent.
  boot.kernelParams = [ "video=HDMI-A-3:1920x1080@60D" ];

  sops.secrets.monitorctl-mqtt = {
    # This value is a systemd EnvironmentFile containing
    # MONITORCTL_MQTT_USERNAME/PASSWORD lines.
    sopsFile = ../../secrets/hosts/g9-switcher.yaml;
    mode = "0400";
  };

  services.monitorctl = {
    enable = true;
    instances.g9_bottom = {
      # The card number can change; monitor-switch follows this physical DRM
      # connector's ddc symlink, then profile-matches the monitor's EDID.
      connector = "/sys/class/drm/card*-HDMI-A-3";
      port = 8765;

      mqtt = {
        enable = true;
        # TCP/1883 is reachable from this controller. Credentials belong in a
        # SOPS secret, not this declarative configuration.
        host = "10.117.25.10";
        # Upstream prefixes this to form the HA device identifier
        # `monitorctl_g9_bottom` and entity unique IDs such as
        # `monitorctl_g9_bottom_input_source`.
        nodeId = "g9_bottom";
        deviceName = "Samsung Odyssey G9 (bottom)";
        credentialsFile = config.sops.secrets.monitorctl-mqtt.path;
      };

      featureOverrides.input_source.options = [
        {
          id = "dp1";
          label = "Desktop";
          write = 15;
          read = 3;
        }
        {
          id = "dp2";
          label = "Laptop";
          write = 16;
          read = 4;
        }
        {
          id = "hdmi";
          label = "Wyse";
          write = 17;
          read = 1;
          guard = "local_video";
        }
      ];

      # The G9 declares 0xC9, but its fragile capabilities read can fail. Keep
      # firmware diagnostics available from the measured VCP code regardless.
      featureOverrides.firmware_level = {
        vcp = 201; # 0xC9
        label = "Firmware level";
        category = "sensor";
        readonly = true;
        static = true;
        display_format = "version";
      };
    };

    # The second LC49G95T will be the top monitor. Keeping this disabled until
    # it is connected means its absence cannot produce restart or DDC traffic.
    instances.g9_top = {
      enable = false;
      connector = "/sys/class/drm/card*-HDMI-A-1";
      port = 8766;
      mqtt = {
        enable = true;
        host = "10.117.25.10";
        nodeId = "g9_top";
        deviceName = "Samsung Odyssey G9 (top)";
        credentialsFile = config.sops.secrets.monitorctl-mqtt.path;
      };
    };
  };
}
