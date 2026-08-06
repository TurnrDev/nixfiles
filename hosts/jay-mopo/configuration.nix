{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/roles/laptop.nix
    ../../modules/nixos/hardware/intel-arc.nix
  ];

  networking.hostName = "jay-mopo";

  my.dockmgr = {
    internalDisplay = {
      width = 2880;
      height = 1800;
      freq = "90.001";
    };

    profiles = lib.mkBefore [
      {
        name = "Docked Work";
        match.and = [
          {
            displays.connectedAllOf = [
              "DP-5"
              "DP-7"
            ];
          }
          {
            usb.allOf = [
              "258a:003a"
              "05e3:0625"
              "05e3:0610"
              "05e3:0608"
            ];
          }
        ];
        outputs = {
          ${config.my.dockmgr.internalDisplay.identifier} = config.my.dockmgr.internalOutput // {
            scale = 1.5;
          };
          "DP-5" = {
            mode = "1920x1200@59.950";
            position = {
              x = 1920;
              y = 0;
            };
            scale = 1.0;
          };
          "DP-7" = {
            mode = "1920x1200@59.950";
            position = {
              x = 3840;
              y = 0;
            };
            scale = 1.0;
          };
        };
      }
    ];
  };

  my.identity.email = lib.mkForce "jay.turner@mopo.co";

  stylix.base16Scheme = ../../modules/home-manager/common/stylix/themes/mopo.yaml;

  services.xserver.xkb = {
    layout = "gb";
    variant = "colemak";
  };

  # jay-mopo uses a Meteor Lake Intel iGPU. Use the generic modesetting stack
  # with Mesa plus Intel's current media/compute userspace drivers.
  services.xserver.videoDrivers = [ "modesetting" ];
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-compute-runtime
      intel-media-driver
      vpl-gpu-rt
    ];
  };

  # Per-device borgmatic overrides live in the host config. The shared module
  # provides the defaults and translates this block into borgmatic YAML.
  #
  my.backups.borgmatic.enable = false;
  #   my.backups.borgmatic = {
  #     frequency = "daily";
  #     sourceDirectories = [ config.my.identity.homeDirectory ];
  #     healthchecksUrl = "https://healthchecks.home.turnr.dev/ping/66bb872c-5ff0-4398-ba0c-7db7f3f7b731";
  #     repositories = {
  #       hetzner.path = "ssh://u551190@u551190.your-storagebox.de:23/./${config.networking.hostName}";
  #     };
  #   };

  users.users = lib.mkIf config.my.identity.enable {
    ${config.my.identity.username} = {
      extraGroups = [ "kvm" ];
    };
  };

}
