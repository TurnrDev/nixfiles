# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  dmsPackages = inputs.dms.packages.${pkgs.stdenv.hostPlatform.system};
  toLua = lib.generators.toLua { };
  device_list = [
    "home-server"
    "jay-framework"
    "jay-desktop"
  ];
in
{
  imports = [
    ./default.nix
    ../services/dms-home-assistant-monitor.nix
  ];

  my.backups.borgmatic.extraExcludePatterns = lib.mkAfter [
    "${config.my.identity.homeDirectory}/.config/Code"
    "${config.my.identity.homeDirectory}/.config/GitKraken"
    "${config.my.identity.homeDirectory}/.gitkraken"
    "${config.my.identity.homeDirectory}/.vscode"
    "${config.my.identity.homeDirectory}/.vscode-server"
  ];

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = false;
  # Use Hyprland's built-in UWSM session and let DMS remember whichever
  # session was chosen last, while still defaulting system-side to UWSM.
  services.displayManager = {
    defaultSession = "hyprland-uwsm";
    dms-greeter = {
      enable = true;
      package = dmsPackages.default;
      configHome = config.my.identity.homeDirectory;
      quickshell.package = pkgs.quickshell;
      compositor = {
        name = "hyprland";
        customConfig = ''
          hl.env("DMS_RUN_GREETER", "1")

          hl.config({
            misc = {
              disable_hyprland_logo = true,
              disable_splash_rendering = true,
            },
            input = {
              kb_layout = "${config.services.xserver.xkb.layout}",
              kb_variant = "${config.services.xserver.xkb.variant}",
              numlock_by_default = true,
              resolve_binds_by_sym = true,
            },
          })

          hl.device({
            name = "keychron-keychron-v6-max",
            kb_layout = "gb",
            kb_variant = "",
            resolve_binds_by_sym = true,
          })

          hl.device({
            name = "keychron--keychron-link--keyboard",
            kb_layout = "gb",
            kb_variant = "",
            resolve_binds_by_sym = true,
          })
        '';
      };
    };
  };
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "gb";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Define workstation-specific groups and packages for the shared user.
  users.users = lib.mkIf config.my.identity.enable {
    ${config.my.identity.username} = {
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
      packages = with pkgs; [ ];
    };
  };

  programs.kdeconnect.enable = true;

  programs.git = {
    enable = true;
    config = {
      core.excludesFile = "/etc/gitignore";
      init.defaultBranch = "main";
    };
  };

  environment.etc."gitignore".text = ''
    .codex
  '';

  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };
  programs.foot = {
    enable = true;
    settings = {
      main = {
        shell = "zsh";
        font = "FiraCode Nerd Font Mono";
      };
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    android-studio
    cameractrls-gtk4
    codex
    dbeaver-bin
    ghostty
    gimp
    gitkraken
    grimblast
    imagemagick
    jetbrains.pycharm
    jetbrains.pycharm-oss
    josm
    openscad-unstable
    postman
    prusa-slicer
    vlc
    vscode
  ];

  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      fira-code-symbols
      font-awesome
      nerd-fonts.fira-code
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
    ];
  };

  services.syncthing = {
    enable = true;
    user = "${config.my.identity.username}";
    configDir = "${config.my.identity.homeDirectory}/.config/syncthing";
    settings = {
      devices = {
        "home-server" = {
          id = "D6Y3JIQ-HCGMVPG-K6YLKDK-7X4D7YI-4BSGQ5J-WJW3WNY-ZHCJYT5-2VMAKAT";
        };
        "jay-desktop" = {
          id = "6U7MTAP-I2W2B7O-F7D73JH-PKPBJXW-2NRDBP6-BHOKMS7-B5YTIBQ-2JGQLQL";
        };
        "jay-framework" = {
          id = "VUUG6YN-SHPRRSW-44UADVY-VQ4MQZX-3T5PPN5-65MCQ6K-GIP4Y5T-CXH2UAQ";
        };
      };
      folders = {
        "3D Printing" = {
          path = "${config.my.identity.homeDirectory}/3D Printing/";
          devices = device_list;
          versioning = {
            type = "simple";
            params.keep = "10";
          };
        };
        "Documents" = {
          path = "${config.my.identity.homeDirectory}/Documents/";
          devices = device_list;
          versioning = {
            type = "simple";
            params.keep = "10";
          };
        };
      };
    };
  };
}
