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
  avatar = ../../../../assets/jay.png;
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
      tailscale = {
        enable = lib.mkDefault false;
        src = inputs."dux-plugin-tailscale";
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
    # Needed for the Home Assistant Monitor plugin's websocket connection.
    qt6.qtwebsockets
    # The standalone Dux file manager is published from its own flake.
    inputs.dux-files.packages.${stdenv.hostPlatform.system}.default
  ];

  # A widely supported per-user fallback.  Dux itself prefers AccountsService,
  # while its greeter can sync this image into its cache.
  home.file.".face".source = avatar;

  stylix.targets.dank-material-shell.enable = true;

}
