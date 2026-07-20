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
  codexChatsMcp = pkgs.python3Packages.buildPythonApplication rec {
    pname = "codex-chats-mcp";
    version = "0.1.1";
    pyproject = true;

    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/34/cd/69cf9748c9c03ebde3c1b80c94e7ce54f9f5ed82700d8442d61844324c13/codex_chats_mcp-0.1.1.tar.gz";
      hash = "sha256-L9+H6ALWmpZSgqDBrXx7KPx0Zvwd4sGnNTsK7lEjJQ8=";
    };

    build-system = [ pkgs.python3Packages.setuptools ];
    dependencies = with pkgs.python3Packages; [
      mcp
      python-dotenv
      typer
    ];

    pythonImportsCheck = [ "codex_chats_mcp" ];
  };
  toLua = lib.generators.toLua { };
  hostName = config.networking.hostName;
  hasPersonalFolders = lib.elem hostName config.my.syncthing.personalFolderHosts;
  hasWorkFolders = lib.elem hostName config.my.syncthing.workFolderHosts;
  hasAllFolders = hasPersonalFolders || hasWorkFolders;
in
{
  imports = [
    ./default.nix
    ../common/virtualisation.nix
    ../services/dms-home-assistant-monitor.nix
  ];

  options.my.syncthing.personalDeviceList = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    readOnly = true;
    default = [
      "home-server"
      "jay-framework"
      "jay-desktop"
    ];
    description = "Internal shared Syncthing device list for personal folders.";
  };

  options.my.syncthing.workDeviceList = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    readOnly = true;
    default = [ "jay-mopo" ];
    description = "Internal shared Syncthing device list for work-only peers.";
  };

  options.my.syncthing.personalFolderHosts = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    readOnly = true;
    default = [
      "jay-desktop"
      "jay-framework"
    ];
    description = "Hosts that should declare personal Syncthing folders locally.";
  };

  options.my.syncthing.workFolderHosts = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    readOnly = true;
    default = [ "jay-mopo" ];
    description = "Hosts that should declare work-only Syncthing folders locally.";
  };

  config = {
    my.backups.borgmatic.extraExcludePatterns = lib.mkAfter [
      "${config.my.identity.homeDirectory}/.config/Code"
      "${config.my.identity.homeDirectory}/.config/GitKraken"
      "${config.my.identity.homeDirectory}/.gitkraken"
      "${config.my.identity.homeDirectory}/.vscode"
      "${config.my.identity.homeDirectory}/.vscode-server"
    ];

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
            hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
            hl.env("XCURSOR_SIZE", "24")
            hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
            hl.env("HYPRCURSOR_SIZE", "24")

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

    # Keep the full Plasma session easy to restore for troubleshooting, but
    # don't install it in the normal day-to-day Hyprland setup.
    services.displayManager.sddm.enable = false;
    # services.desktopManager.plasma6.enable = true;

    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = false;
      extraPortals = lib.mkForce (
        with pkgs;
        [
          xdg-desktop-portal-hyprland
          kdePackages.xdg-desktop-portal-kde
        ]
      );
      config = {
        common = {
          default = [ "hyprland" ];
          "org.freedesktop.impl.portal.FileChooser" = [ "kde" ];
        };
        hyprland = {
          default = [ "hyprland" ];
          "org.freedesktop.impl.portal.FileChooser" = [ "kde" ];
        };
      };
    };

    # Some KDE utilities launched under Hyprland still look for the generic
    # applications.menu instead of honoring XDG_MENU_PREFIX=plasma-.
    environment.etc."xdg/menus/applications.menu".source =
      "${pkgs.kdePackages.plasma-workspace}/etc/xdg/menus/plasma-applications.menu";

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
      bibata-cursors
      cameractrls-gtk4
      codex
      codexChatsMcp
      dbeaver-bin
      file
      gimp
      gitkraken
      gnome-disk-utility
      grimblast
      imagemagick
      jetbrains.idea
      jetbrains.jdk
      jetbrains.pycharm
      jetbrains.webstorm
      (josm.override {
        jre = pkgs.jre.override { enableJavaFX = true; };
      })
      kdePackages.ark
      kdePackages.dolphin
      kdePackages.kate
      kdePackages.kio
      kdePackages.kio-extras
      kdePackages.kio-fuse
      kdePackages.qtsvg
      kotlin
      libreoffice
      openscad-unstable
      postman
      prusa-slicer
      qview
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
          "jay-mopo" = {
            id = "SN4ZRBM-SUQN22Q-IM65G3R-XITRUKX-AQAL4AI-RZCIKAJ-7RAPCVC-JO3O5QB";
          };
        };
        folders = {
        }
        // lib.optionalAttrs hasPersonalFolders {
          "3D Printing" = {
            path = "${config.my.identity.homeDirectory}/3D Printing/";
            devices = config.my.syncthing.personalDeviceList;
            versioning = {
              type = "simple";
              params.keep = "10";
            };
          };
          "Documents" = {
            path = "${config.my.identity.homeDirectory}/Documents/";
            devices = config.my.syncthing.personalDeviceList;
            versioning = {
              type = "simple";
              params.keep = "10";
            };
          };
        }
        // lib.optionalAttrs hasAllFolders {
          "JOSM" = {
            path = "${config.my.identity.homeDirectory}/.config/JOSM/";
            devices = config.my.syncthing.personalDeviceList ++ config.my.syncthing.workDeviceList;
            versioning = {
              type = "simple";
              params.keep = "10";
            };
          };
        };
      };
    };
  };
}
