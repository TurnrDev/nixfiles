{ inputs, ... }:

{
  flake.modules.nixos.role-gaming =
    { lib, pkgs, ... }:
    {
      imports = with inputs.self.modules.nixos; [
        program-minecraft
        role-gaming-emulation
      ];

      # Keep the lightweight Game Boy setup on gaming hosts; override per host.
      # For example: my.emulation.dolphin.enable = true;
      my.emulation = {
        enable = lib.mkDefault true;
        retroarch.enable = lib.mkDefault true;
      };

      programs.steam = {
        enable = true;
        extraCompatPackages = with pkgs; [
          proton-ge-bin
        ];
      };
    };

  flake.modules.homeManager.role-gaming =
    {
      config,
      lib,
      osConfig,
      ...
    }:
    {
      imports = with inputs.self.modules.homeManager; [
        program-elite-dangerous
        role-gaming-emulation
      ];

      programs.borgmatic.backups =
        lib.genAttrs
          [
            "borg1.4"
            "borg2"
          ]
          (_: {
            settings.exclude_patterns = lib.mkAfter [
              "${osConfig.my.users.${config.home.username}.homeDirectory}/.local/share/Steam"
              "${osConfig.my.users.${config.home.username}.homeDirectory}/.steam-shared"
              "${osConfig.my.users.${config.home.username}.homeDirectory}/.steam"
              "srv/nfs/games"
            ];
          });
    };

  flake.modules.nixos.role-gaming-emulation =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.emulation;
      # Each standalone emulator is opt-in. Package options allow local overrides.
      emulatorPackages = {
        ares = "ares";
        mame = "mame";
        melonds = "melonds";
        azahar = "azahar";
        dolphin = "dolphin-emu";
        cemu = "cemu";
        ryubing = "ryubing";
        pcsx2 = "pcsx2";
        rpcs3 = "rpcs3";
        shadps4 = "shadps4";
        sharpemu = "sharpemu";
        kytyps5 = "kytyps5";
        ppsspp = "ppsspp";
        vita3k = "vita3k";
        xemu = "xemu";
        xenia = "xenia-canary";
        greenlight = "greenlight";
      };
      selectedEmulators = lib.filter (name: cfg.${name}.enable) (builtins.attrNames emulatorPackages);
      multiverse = inputs.multiverse.lib.mkMultiverse {
        system = pkgs.stdenv.hostPlatform.system;
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [ "es-de-3.4.1" ];
        };
      };
      # Standard state roots. Add or override entries for custom/portable saves.
      # Sync whole roots so settings, memory cards, save states and battery saves
      # stay together. These paths never depend on emulator activation or packages.
      stateDirectories = {
        "ES-DE" = "ES-DE";
        "Retroarch" = ".config/retroarch";
        "Ryujinx" = ".config/Ryujinx";
        "ares-config" = ".config/ares";
        "ares-data" = ".local/share/ares";
        "MAME-config" = ".config/mame";
        "MAME-data" = ".mame";
        "melonDS-config" = ".config/melonDS";
        "melonDS-data" = ".local/share/melonDS";
        "Azahar-config" = ".config/azahar-emu";
        "Azahar-data" = ".local/share/azahar-emu";
        "Dolphin-config" = ".config/dolphin-emu";
        "Dolphin-data" = ".local/share/dolphin-emu";
        "Cemu-config" = ".config/Cemu";
        "Cemu-data" = ".local/share/Cemu";
        "PCSX2" = ".config/PCSX2";
        "RPCS3" = ".config/rpcs3";
        "shadPS4" = ".local/share/shadPS4";
        "SharpEmu" = ".local/share/SharpEmu";
        "PPSSPP" = ".config/ppsspp";
        "Vita3K-config" = ".config/Vita3K";
        "Vita3K-data" = ".local/share/Vita3K";
        "xemu-config" = ".config/xemu";
        "xemu-data" = ".local/share/xemu";
        "Xenia-config" = ".config/xenia";
        "Xenia-data" = ".local/share/xenia";
        "Greenlight" = ".config/Greenlight";
      };
      syncFolder = path: {
        inherit path;
        devices = config.my.syncthing.personalDeviceList;
        versioning = {
          type = "simple";
          params.keep = "10";
        };
      };
    in
    {
      options.my.emulation = {
        stateFolders = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          description = "Syncthing folder IDs mapped to absolute emulator settings/save directories. All entries are synced and excluded from both Borg backups regardless of emulator activation. Add custom save locations here; portable emulators such as KytyPS5 require their actual user-data directory.";
          example = lib.literalExpression ''{ "KytyPS5" = "/home/jay/Games/KytyPS5/user"; }'';
        };
        enable = lib.mkEnableOption "the selected emulators and their supporting configuration";
        retroarch = {
          enable = lib.mkEnableOption "RetroArch with only the selected cores";
          cores = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            # Both have existing Pokemon Yellow saves under ~/.config/retroarch/saves/.
            default = [
              "sameboy"
              "mgba"
            ];
            description = "Libretro core names from pkgs.libretro. SameBoy and mGBA both support Game Boy games; mGBA also supports GBA.";
          };
          package = lib.mkOption {
            type = lib.types.package;
            default = pkgs.retroarch.withCores (cores: map (name: cores.${name}) cfg.retroarch.cores);
            defaultText = lib.literalExpression "pkgs.retroarch.withCores (cores: map (name: cores.\${name}) config.my.emulation.retroarch.cores)";
            description = "RetroArch package shared by the system installation and ES-DE core discovery.";
          };
        };
        esDe = {
          enable = lib.mkEnableOption "the ES-DE emulation frontend";
          package = lib.mkOption {
            type = lib.types.package;
            default = multiverse.version "es-de" "3.4.1";
            defaultText = lib.literalExpression ''multiverse.version "es-de" "3.4.1"'';
            description = "ES-DE package; evaluated only when enabled.";
          };
        };
        romMount.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Mount the shared ROM library at /srv/nfs/games when emulation is enabled.";
        };
      }
      // lib.mapAttrs (name: packageName: {
        enable = lib.mkEnableOption "the ${name} emulator";
        package = lib.mkOption {
          type = lib.types.package;
          default =
            if name == "sharpemu" then
              pkgs.callPackage ../../packages/sharpemu { }
            else if name == "kytyps5" then
              pkgs.kytyps5
                or (throw "KytyPS5 currently supplies only a development shell. Set my.emulation.kytyps5.package to a packaged emulator before enabling it.")
            else
              pkgs.${packageName};
          defaultText = lib.literalExpression (
            if name == "sharpemu" then "pkgs.callPackage ../../packages/sharpemu { }" else "pkgs.${packageName}"
          );
          description = "Package installed when ${name} is enabled.";
        };
      }) emulatorPackages;

      config = lib.mkMerge [
        {
          my.emulation.stateFolders = lib.mapAttrs (
            _: directory: lib.mkDefault "${config.my.identity.homeDirectory}/${directory}"
          ) stateDirectories;
          services.syncthing.settings.folders = lib.mapAttrs (
            name: path:
            syncFolder path
            // lib.optionalAttrs (name == "ES-DE") {
              # This symlink contains machine-specific Nix store paths.
              ignorePatterns = [ "/custom_systems/es_find_rules.xml" ];
            }
          ) cfg.stateFolders;
        }
        (lib.mkIf cfg.enable {
          environment.systemPackages =
            lib.optional cfg.retroarch.enable cfg.retroarch.package
            ++ lib.optional cfg.esDe.enable cfg.esDe.package
            ++ lib.optional cfg.romMount.enable pkgs.nfs-utils
            ++ map (name: cfg.${name}.package) selectedEmulators;

          boot.supportedFilesystems = lib.optional cfg.romMount.enable "nfs";
          fileSystems."/srv/nfs/games" = lib.mkIf cfg.romMount.enable {
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

        })
      ];
    };

  flake.modules.homeManager.role-gaming-emulation =
    {
      config,
      lib,
      pkgs,
      osConfig,
      ...
    }:

    let
      cfg = osConfig.my.emulation;
      stateDirectories = builtins.attrValues cfg.stateFolders;
      esDeSettingsDirectory = "${config.home.homeDirectory}/ES-DE/settings";
      esDeSettingsFile = "${esDeSettingsDirectory}/es_settings.xml";
      initialEsDeSettings = pkgs.writeText "es-de-settings.xml" ''
        <?xml version="1.0"?>
        <string name="ROMDirectory" value="/srv/nfs/games/roms/" />
      '';
    in
    {
      # Keeping old saves safe is independent of installing their emulator.
      programs.borgmatic.backups = lib.genAttrs [ "borg1.4" "borg2" ] (_: {
        settings.exclude_patterns = lib.mkAfter stateDirectories;
      });

      home.file."ES-DE/custom_systems/es_find_rules.xml" =
        lib.mkIf (cfg.enable && cfg.esDe.enable && cfg.retroarch.enable)
          {
            text = ''
              <?xml version="1.0"?>
              <!-- This is the ES-DE find rules configuration file for Linux. -->
              <ruleList>
                <core name="RETROARCH">
                  <rule type="corepath">
                    <entry>${cfg.retroarch.package}/lib/retroarch/cores/</entry>
                  </rule>
                </core>
              </ruleList>
            '';
          };

      # ES-DE owns this file and updates it from the UI. Seed it when absent, or
      # update only the declarative ROM path while leaving every other setting
      # mutable.
      home.activation.configureEsDeRomDirectory = lib.mkIf (cfg.enable && cfg.esDe.enable) (
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          settings_directory=${lib.escapeShellArg esDeSettingsDirectory}
          settings_file=${lib.escapeShellArg esDeSettingsFile}

          run mkdir -p "$settings_directory"

          if [[ ! -e "$settings_file" ]]; then
            run install -m 600 ${initialEsDeSettings} "$settings_file"
          elif grep -q '<string name="ROMDirectory"' "$settings_file"; then
            run sed -i \
              's#<string name="ROMDirectory" value="[^"]*" */>#<string name="ROMDirectory" value="/srv/nfs/games/roms/" />#' \
              "$settings_file"
          else
            run sed -i \
              '$a<string name="ROMDirectory" value="/srv/nfs/games/roms/" />' \
              "$settings_file"
          fi
        ''
      );
    };

}
