{ inputs, ... }:

{
  flake.modules.nixos.jay-mopo =
    {
      config,
      lib,
      pkgs,
      repoLib,
      ...
    }:

    let
      mv = inputs.multiverse.multiverse.${pkgs.stdenv.hostPlatform.system};
      borgVersion = repoLib.versionBetween mv "borgbackup" "1.2.6" "2.0.0";
    in
    {
      imports = with inputs.self.modules.nixos; [
        desk-work
        role-java-development
        role-laptop
        role-nix-builder
        user-jay
      ];

      networking.hostName = "jay-mopo";

      sops.secrets.rclone-gdrive-config = {
        sopsFile = ../../../secrets/hosts/jay-mopo.yaml;
        owner = config.users.users.jay.name;
        group = "users";
        mode = "0400";
      };

      services.tailscale.enable = true;

      my.wireguard.home = {
        enable = true;
        sopsFile = ../../../secrets/hosts/jay-mopo.yaml;
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

      my.users.jay.email = "jay.turner@mopo.co";

      stylix.base16Scheme = ../../themes/themes/mopo.yaml;

      services.xserver.xkb = {
        layout = "gb";
        variant = "colemak";
      };

      environment.systemPackages =
        with pkgs;
        [
          android-studio
          dbeaver-bin
          go
          jetbrains.idea
          jetbrains.jdk
          kotlin
          (mv.version "nodejs" (repoLib.versionBetween mv "nodejs" "24.22.1" "25.0.0"))
          (mv.version "python3" (repoLib.versionBetween mv "python3" "3.11.5" "3.12.0"))
          python313
        ]
        ++
          lib.optionals (!config.home-manager.users.${config.my.users.jay.username}.programs.borgmatic.enable)
            [
              (mv.version "borgbackup" borgVersion)
            ];

      users.users = {
        ${config.my.users.jay.username} = {
          extraGroups = [ "kvm" ];
        };
      };

    };

  flake.modules.homeManager.jay-mopo =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      firefoxProfilesIni = pkgs.writeText "firefox-profiles.ini" ''
        [General]
        StartWithLastProfile=1
        Version=2

        [Install4F96D1932A9F858E]
        Default=jrxoxku9.default-release
        Locked=1

        [Profile0]
        IsRelative=1
        Name=default-release
        Path=jrxoxku9.default-release
        ShowSelector=1
        StoreID=642ce52d
        Default=1
      '';
    in
    {
      imports = with inputs.self.modules.homeManager; [
        jay-mopo-google-drive
        jay-mopo-grafana
        role-laptop
      ];

      # The keyboard's dedicated screenshot key emits Super+Shift+R.
      wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''
        hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd("dms screenshot"), {
          description = "Take Screenshot",
          device = { inclusive = true, list = { "at-translated-set-2-keyboard" } },
        })
        hl.bind("SUPER + SHIFT + CTRL + R", hl.dsp.exec_cmd("dms screenshot full"), {
          description = "Take Full Screenshot",
          device = { inclusive = true, list = { "at-translated-set-2-keyboard" } },
        })
        hl.bind("SUPER + SHIFT + ALT + R", hl.dsp.exec_cmd("dms screenshot window"), {
          description = "Take Window Screenshot",
          device = { inclusive = true, list = { "at-translated-set-2-keyboard" } },
        })
      '';

      programs.vscode.profiles.default.userSettings = {
        "editor.formatOnSave" = lib.mkForce false;
        "editor.codeActionsOnSave" = lib.mkForce { };
      };

      programs.firefox.profiles = {
        default = {
          name = "Personal";
          path = "jrxoxku9.default-release";
          storeId = "642ce52d";
        };

        profile1 = {
          id = 1;
          name = "Work";
          path = "CfqUTwRK.Profile 1";
          isDefault = false;
        };
      };

      stylix.targets.firefox.profileNames = lib.mkForce [
        "default"
        "profile1"
      ];

      # Firefox must own this file: it saves the selected profile and profile
      # edits there. Initialise it once rather than linking it read-only from Nix.
      home.file."${config.xdg.configHome}/mozilla/firefox/profiles.ini".enable = false;
      home.activation.makeFirefoxProfilesIniMutable = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        profiles_ini="${config.xdg.configHome}/mozilla/firefox/profiles.ini"
        if [ ! -e "$profiles_ini" ]; then
          install -m 600 ${firefoxProfilesIni} "$profiles_ini"
        fi
      '';

      programs.borgmatic.backups =
        lib.genAttrs
          [
            "borg1.4"
            "borg2"
          ]
          (_: {
            settings = {
              exclude_patterns = lib.mkAfter [
                "${config.home.homeDirectory}/Repos/mopo/.db_data"
                "${config.home.homeDirectory}/Repos/mopo/.redis_data"
                "${config.home.homeDirectory}/NoBackup"
                "*.xb"
                "*.xb.*"
              ];
            };
          });

    };
}
