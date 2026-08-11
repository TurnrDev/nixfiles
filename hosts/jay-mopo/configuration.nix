{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  mv = inputs.multiverse.multiverse.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/roles/laptop.nix
    ../../modules/nixos/hardware/intel-arc.nix
  ];

  networking.hostName = "jay-mopo";

  my.displays = {
    internal = {
      width = 2880;
      height = 1800;
      freq = "90.001";
    };
  };

  programs.dockmgr.profiles = lib.mkBefore [
    {
      name = "Docked Work";
      match.and = [
        {
          displays.connectedAllOf = [
            "desc:Dell Inc. DELL U2413 84K964B5CTTL"
            "desc:Dell Inc. DELL U2412M YPPY06853EVS"
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
      hooks.session.postUp = [
        ''
          hyprctl eval 'require("config.workspace-routing").apply({
            "eDP-1",
            "desc:Dell Inc. DELL U2413 84K964B5CTTL",
            "desc:Dell Inc. DELL U2412M YPPY06853EVS",
          })'
        ''
      ];
      hooks.session.postDown = [
        ''hyprctl eval 'require("config.workspace-routing").clear()' ''
      ];
      outputs = {
        ${config.my.displays.internal.identifier} = config.my.displays.internalOutput // {
          scale = 1.5;
        };
        "desc:Dell Inc. DELL U2413 84K964B5CTTL" = {
          mode = "1920x1200@59.950";
          position = {
            x = 1920;
            y = 0;
          };
          scale = 1.0;
        };
        "desc:Dell Inc. DELL U2412M YPPY06853EVS" = {
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

  my.backups.borgmatic.enable = false;

  environment.systemPackages = with pkgs; [
    android-studio
    (mv.version "borgbackup" "1.4.5")
    dbeaver-bin
    (mv.version "go" "1.24.4")
    jetbrains.idea
    jetbrains.jdk
    kotlin
    (mv.version "nodejs" "24.15.0")
    (mv.version "python3" "3.11.5")
    python313
  ];

  users.users = lib.mkIf config.my.identity.enable {
    ${config.my.identity.username} = {
      extraGroups = [ "kvm" ];
    };
  };

}
