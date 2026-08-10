{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  settings = (builtins.fromJSON (builtins.readFile ./settings.json)) // {
    # dockmgr exclusively owns Hyprland output configuration.
    hyprlandOutputSettings = { };
  };
  sessionTarget = config.wayland.systemd.target;
in

{
  imports = [
    inputs.dms.homeModules.dank-material-shell
  ];

  systemd.user.services.dms = {
    Unit = {
      PartOf = [ sessionTarget ];
      After = [ sessionTarget ];
      Requisite = [ sessionTarget ];
    };

    Service = {
      Restart = "on-failure";
      RestartSec = "2s";
    };

    Install.WantedBy = lib.mkForce [ sessionTarget ];
  };

  programs.dank-material-shell = {
    enable = true;
    inherit settings;

    plugins = {
      dankBatteryAlerts = {
        enable = lib.mkDefault false;
        src = inputs."dms-plugins" + "/DankBatteryAlerts";
      };
      dankKDEConnect.src = inputs."dms-plugins" + "/DankKDEConnect";
      dankLauncherKeys.src = inputs."dms-plugins" + "/DankLauncherKeys";
      dankNotepadModule.src = inputs."dms-plugins" + "/DankNotepadModule";
      grimblast.src = inputs."dms-plugins-taylan" + "/grimblast";
      homeAssistantMonitor = {
        src = inputs."dms-plugin-hass";
        settings = {
          hassUrl = "https://assistant.home.turnr.net";
          hassTokenPath = "/run/secrets/hass_token";
          hassToken = "";
        };
      };
      dockerManager = {
        src = inputs."dms-plugin-docker-manager";
        settings = {
          terminalApp = "ghostty --hold";
          groupByCompose = true;
        };
      };
      emojiLauncher.src = inputs."dms-emoji-launcher";
      tailscale = {
        enable = lib.mkDefault false;
        src = inputs."dms-plugin-tailscale";
      };
    };

    systemd = {
      enable = true; # Systemd service for auto-start
      restartIfChanged = true; # Auto-restart dms.service when dank-material-shell changes
    };

    # Core features
    enableSystemMonitoring = true; # System monitoring widgets (dgop)
    enableVPN = true; # VPN management widget
    enableDynamicTheming = false;
    enableAudioWavelength = true; # Audio visualizer (cava)
    enableCalendarEvents = false; # Calendar integration (khal)
    enableClipboardPaste = true; # Pasting items from the clipboard (wtype)
  };

  home.packages = with pkgs; [
    # Needed for the Home Assistant Monitor plugin's websocket connection.
    qt6.qtwebsockets
  ];

  xdg.configFile =
    let
      enabledPlugins = lib.filterAttrs (
        _: plugin: plugin.enable
      ) config.programs.dank-material-shell.plugins;
    in
    lib.mapAttrs' (name: _: {
      name = "DankMaterialShell/plugins/${name}";
      value.force = true;
    }) enabledPlugins;

}
