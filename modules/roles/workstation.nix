{
  config,
  inputs,
  lib,
  osConfig,
  pkgs,
  ...
}:

{
  flake.modules.nixos.role-workstation =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      hostName = config.networking.hostName;
      hasPersonalFolders = lib.elem hostName config.my.syncthing.personalFolderHosts;
      hasWorkFolders = lib.elem hostName config.my.syncthing.workFolderHosts;
      hasAllFolders = hasPersonalFolders || hasWorkFolders;
      unsetAwsLcSystem = old: {
        preBuild = (old.preBuild or "") + ''
          unset AWS_LC_SYS_USE_SYSTEM
        '';
      };
      tectonicAwsLcWorkaround = final: prev: {
        codex = prev.codex.overrideAttrs (
          old:
          unsetAwsLcSystem old
          // {
            buildInputs = (old.buildInputs or [ ]) ++ [
              final.oniguruma
              final.sqlite
              final.zstd
            ];
          }
        );
        tectonic-unwrapped = prev.tectonic-unwrapped.overrideAttrs unsetAwsLcSystem;
        tectonic = prev.tectonic.override {
          inherit (final) tectonic-unwrapped;
        };
      };
    in
    {
      imports = with inputs.self.modules.nixos; [
        desktop-dux
        desktop-hyprland
        inputs.dockmgr.nixosModules.default
        role-cad
        role-default
        role-python-development
        service-borgmatic
        service-go-hass-agent
        service-kdeconnect
        service-libvirt
        theme-stylix
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
        # aws-lc-sys cannot use nixpkgs' system-library override when a package
        # supplies OpenSSL. Build that crate's bundled AWS-LC instead.
        nixpkgs.overlays = [ tectonicAwsLcWorkaround ];

        # Interactive hosts provide a Wayland session and local sound stack. Xorg
        # stays disabled; Xwayland supports the remaining legacy X11 applications
        # inside Hyprland without running an X display server.
        services.xserver = {
          enable = false;
          xkb.layout = "gb";
        };
        services.pulseaudio.enable = false;
        security.rtkit.enable = true;
        services.pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
        };

        programs.dockmgr.enable = true;

        # Enable CUPS to print documents.
        services.avahi.enable = true;
        services.printing.enable = true;

        # Define workstation-specific groups and packages for the shared user.
        users.users = lib.optionalAttrs (config.my.users ? jay) {
          ${config.my.users.jay.username} = {
            extraGroups = [
              "networkmanager"
              "wheel"
            ];
            packages = with pkgs; [ ];
          };
        };

        environment.systemPackages = with pkgs; [
          bibata-cursors
          cameractrls-gtk4
          gimp
          sourcegit
          gnome-disk-utility
          imagemagick
          jetbrains.pycharm
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
          libreoffice
          libnotify
          nwg-displays
          postman
          plezy
          qview
          pwvucontrol
          vlc
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
          user = "${config.my.users.jay.username}";
          configDir = "${config.my.users.jay.homeDirectory}/.config/syncthing";
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
                path = "${config.my.users.jay.homeDirectory}/3D Printing/";
                devices = config.my.syncthing.personalDeviceList;
                versioning = {
                  type = "simple";
                  params.keep = "10";
                };
              };
              "Documents" = {
                path = "${config.my.users.jay.homeDirectory}/Documents/";
                devices = config.my.syncthing.personalDeviceList;
                versioning = {
                  type = "simple";
                  params.keep = "10";
                };
              };
            }
            // lib.optionalAttrs hasAllFolders {
              "JOSM" = {
                path = "${config.my.users.jay.homeDirectory}/.config/JOSM/";
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
    };

  flake.modules.homeManager.role-workstation =
    {
      config,
      lib,
      osConfig,
      ...
    }:
    {
      imports = with inputs.self.modules.homeManager; [
        desktop-default-apps
        desktop-hyprland
        inputs.dockmgr.homeManagerModules.default
        program-codex
        program-discord
        program-firefox
        program-spotify
        program-vscode
        role-default
        role-python-development
        service-borgmatic
        service-go-hass-agent
        service-kdeconnect
        theme-stylix
      ];

      fonts.fontconfig = {
        enable = true;
        antialiasing = true;
      };

      # Workstations hold the configuration checkout and perform builds/deployments.
      # Appliance hosts use Git but do not carry the checkout itself.
      home.activation.linkNixosRepository = lib.hm.dag.entryAfter [ "createReposDirectory" ] ''
        run ln -sfnT /etc/nixos "$HOME/Repos/nixos"
      '';

      programs.borgmatic.backups =
        lib.genAttrs
          [
            "borg1.4"
            "borg2"
          ]
          (_: {
            settings.exclude_patterns = lib.mkAfter [
              "${osConfig.my.users.${config.home.username}.homeDirectory}/.config/Code"
              "${osConfig.my.users.${config.home.username}.homeDirectory}/.config/GitKraken"
              "${osConfig.my.users.${config.home.username}.homeDirectory}/.gitkraken"
              "${osConfig.my.users.${config.home.username}.homeDirectory}/.vscode"
              "${osConfig.my.users.${config.home.username}.homeDirectory}/.vscode-server"
            ];
          });
    };
}
