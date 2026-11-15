{ inputs, ... }:

let
  avatar = ../../user/jay.png;
in
{
  flake.modules.nixos.desktop-dux =
    { config, ... }:
    {
      imports = [ inputs.dux-greeter.nixosModules.default ];

      sops.secrets.hass_token = {
        sopsFile = ../../../secrets/shared.yaml;
        path = "/run/secrets/hass_token";
        owner = config.my.users.jay.username;
        group = "users";
        mode = "0400";
      };

      # Dux reads the user icon from AccountsService.  Keep its standard icon
      # location backed by the checked-in avatar so the desktop and greeter use
      # the same image on every host.  Nix copies the source into /nix/store,
      # so the link never points at the working tree.
      services.accounts-daemon.enable = true;
      systemd.tmpfiles.rules = [
        "d /var/lib/AccountsService/icons 0755 root root -"
        "L+ /var/lib/AccountsService/icons/${config.my.users.jay.username} - - - - ${avatar}"
      ];

      programs.dms-greeter = {
        enable = true;
        configHome = config.my.users.jay.homeDirectory;
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

            hl.on("hyprland.start", function()
              hl.exec_cmd("${config.programs.dockmgr.package}/bin/dockmgr watch --config ${config.programs.dockmgr.configFile} --context greeter")
            end)
          '';
        };
      };

      # The greeter owns a separate Hyprland instance. Restart it on a dockmgr
      # update so its compositor-local watcher immediately uses the new package
      # and generated profile configuration.
      systemd.services.greetd.restartTriggers = [
        config.programs.dockmgr.package
        config.programs.dockmgr.configFile
      ];
    };

  flake.modules.homeManager.desktop-dux =
    {
      config,
      lib,
      pkgs,
      inputs,
      ...
    }:

    let
      settings = builtins.fromJSON (builtins.readFile ./settings.json);
      sessionTarget = config.wayland.systemd.target;
      multiverse = inputs.multiverse.multiverse.${pkgs.stdenv.hostPlatform.system};
      multiverseQtMultimediaVersion = multiverse.tip.qt6Packages.qtmultimedia.version;
      qtMultimediaDeviceRemovalFix = final: prev: {
        qt6 =
          let
            patchQt6 =
              qt6:
              (qt6.overrideScope (
                _qtFinal: qtPrev: {
                  qtmultimedia = qtPrev.qtmultimedia.overrideAttrs (
                    oldAttrs:
                    lib.optionalAttrs (lib.versionOlder oldAttrs.version "6.12.1") {
                      patches = (oldAttrs.patches or [ ]) ++ [
                        (final.fetchurl {
                          url = "https://github.com/qt/qtmultimedia/commit/8e7f6edf9a04d6c6484ecebca1227c06ec3b3640.patch";
                          hash = "sha256-FyHzu2XYErN9LI14IuBJkJ6mJvnculTVdmcds//z+Tg=";
                        })
                      ];
                    }
                  );
                }
              ))
              // {
                override = args: patchQt6 (qt6.override args);
              };
          in
          patchQt6 prev.qt6;
      };
    in

    {
      imports = [
        inputs.dux.homeModules.dank-material-shell
      ];

      # QTBUG-150678: Qt Multimedia's native PipeWire backend can use a freed
      # stream when an audio device is removed. Qt 6.12.0 lacks this fix, so keep
      # the backport through that release and omit it from Qt 6.12.1 onward.
      nixpkgs.overlays = [ qtMultimediaDeviceRemovalFix ];

      warnings = lib.optional (lib.versionAtLeast multiverseQtMultimediaVersion "6.12.1") "Qt Multimedia ${multiverseQtMultimediaVersion} is available at the Multiverse tip; remove the local device-removal overlay and update Nixpkgs to use Qt Multimedia ${multiverseQtMultimediaVersion}.";

      systemd.user.services.dms = {
        Unit = {
          PartOf = [ sessionTarget ];
          After = [ sessionTarget ];
          Requisite = [ sessionTarget ];
        };

        Service = {
          Restart = "on-failure";
          RestartSec = "2s";
          # Dux only adds the QML imports bundled with its own wrapper.  User
          # packages are not searched automatically, so expose QtWebSockets to
          # the QML engine that loads the Home Assistant Monitor plugin.
          Environment = [
            "NIXPKGS_QT6_QML_IMPORT_PATH=${pkgs.qt6.qtwebsockets}/lib/qt-6/qml"
          ];
        };

        Install.WantedBy = lib.mkForce [ sessionTarget ];
      };

      programs.dank-material-shell = {
        enable = true;
        inherit settings;

        plugins = {
          dankBatteryAlerts = {
            enable = lib.mkDefault false;
            src = inputs."dux-plugins" + "/DankBatteryAlerts";
          };
          dankKDEConnect.src = inputs."dux-plugins" + "/DankKDEConnect";
          dankLauncherKeys.src = inputs."dux-plugins" + "/DankLauncherKeys";
          dankNotepadModule.src = inputs."dux-plugins" + "/DankNotepadModule";
          dmsScreenshot.src = inputs."dux-screenshot";
          homeAssistantMonitor = {
            src = inputs."dux-plugin-hass";
            settings = {
              hassUrl = "https://assistant.home.turnr.net";
              hassTokenPath = "/run/secrets/hass_token";
              hassToken = "";
            };
          };
          dockerManager = {
            src = inputs."dux-plugin-docker-manager";
            settings = {
              terminalApp = "ghostty --hold";
              groupByCompose = true;
            };
          };
          emojiLauncher.src = inputs."dux-emoji-launcher";
          networkStatus = {
            enable = lib.mkDefault false;
            src = ../../../packages/dux-network-status;
          };
        };

        systemd = {
          enable = true; # Systemd service for auto-start
          restartIfChanged = true; # Auto-restart the Dux compatibility service when its shell changes
        };

        # Core features
        enableSystemMonitoring = true; # System monitoring widgets (dgop)
        enableVPN = false; # VPN management widget
        enableDynamicTheming = false;
        enableAudioWavelength = true; # Audio visualizer (cava)
        enableCalendarEvents = false; # Calendar integration (khal)
        enableClipboardPaste = true; # Pasting items from the clipboard (wtype)
      };

      home.packages = with pkgs; [
        jq
        # Needed for the Home Assistant Monitor plugin's websocket connection.
        qt6.qtwebsockets
      ];

      # A widely supported per-user fallback.  Dux itself prefers AccountsService,
      # while its greeter can sync this image into its cache.
      home.file.".face".source = avatar;

      stylix.targets.dank-material-shell.enable = true;

    };
}
