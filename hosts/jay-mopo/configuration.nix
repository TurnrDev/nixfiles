{
  config,
  inputs,
  lib,
  pkgs,
  repoLib,
  ...
}:

let
  mv = inputs.multiverse.multiverse.${pkgs.stdenv.hostPlatform.system};
  # go-override # remove-begin
  goPatched = pkgs.go_1_26.overrideAttrs (
    _finalAttrs: _previousAttrs: {
      version = "1.26.10";
      src = pkgs.fetchurl {
        url = "https://go.dev/dl/go1.26.10.src.tar.gz";
        hash = "sha256-/WPog7ovK/ypPBZGsx6+9j4rHk0rMXyXidl2po2B828=";
      };
    }
  );
  # go-override # remove-end
  # node-override # remove-begin
  nodePatched = pkgs.nodejs_24.overrideAttrs (
    _finalAttrs: _previousAttrs: {
      version = "24.22.1";
      src = pkgs.fetchurl {
        url = "https://nodejs.org/dist/v24.22.1/node-v24.22.1.tar.xz";
        hash = "sha256-T1N5eWKAza6wwvNY/QS2oWzE+336g7WoyRqdljtDUjE=";
      };
    }
  );
  # node-override # remove-end
  borgVersion = repoLib.versionBetween mv "borgbackup" "1.2.6" "2.0.0";
in
{
  imports = [
    # Regenerate hardware-configuration.nix with:
    # sudo nixos-generate-config --show-hardware-config --no-filesystems > /etc/nixos/hosts/$(hostname)/hardware-configuration.nix
    ./hardware-configuration.nix
    ./storage.nix
    ../../modules/nixos/roles/laptop.nix
    ../../modules/nixos/hardware/intel-arc.nix
  ];

  networking.hostName = "jay-mopo";

  # go-override # remove
  warnings =
    lib.optional (lib.versionAtLeast pkgs.go.version "1.26.10") "nixos-unstable now provides Go 1.26.10 or later; remove # go-override."
    # node-override # remove
    ++ lib.optional (lib.versionAtLeast pkgs.nodejs_24.version "24.22.1") "nixos-unstable now provides Node.js 24.22.1 or later; remove # node-override.";

  sops.secrets.rclone-gdrive-config = {
    sopsFile = ../../secrets/hosts/jay-mopo.yaml;
    owner = config.my.identity.username;
    group = "users";
    mode = "0400";
  };

  services.tailscale.enable = true;

  my.wireguard.home = {
    enable = true;
    sopsFile = ../../secrets/hosts/jay-mopo.yaml;
    ipv4Address = "10.117.25.242/32";
    ipv6Address = "fd00:7389:538a:05fd::4/64";
  };

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

  environment.systemPackages =
    with pkgs;
    [
      android-studio
      dbeaver-bin
      (repoLib.versionAtLeastOrLocal go "1.26.10" goPatched) # go-override # go
      jetbrains.idea
      jetbrains.jdk
      kotlin
      (repoLib.multiverseVersionBetweenOrLocal mv "nodejs" "24.22.1" "25.0.0" nodePatched) # node-override # (mv.version "nodejs" (repoLib.versionBetween mv "nodejs" "24.22.1" "25.0.0"))
      (mv.version "python3" (repoLib.versionBetween mv "python3" "3.11.5" "3.12.0"))
      python313
    ]
    ++
      lib.optionals (!config.home-manager.users.${config.my.identity.username}.programs.borgmatic.enable)
        [
          (mv.version "borgbackup" borgVersion)
        ];

  users.users = lib.mkIf config.my.identity.enable {
    ${config.my.identity.username} = {
      extraGroups = [ "kvm" ];
    };
  };

}
