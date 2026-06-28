{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  settings = (builtins.fromJSON (builtins.readFile ./settings.json)) // {
    gtkThemingEnabled = true;
    iconTheme = "Adwaita";
    qtThemingEnabled = false;
  };
in

{
  imports = [
    inputs.dms.homeModules.dank-material-shell
    ./wallpaper-automation.nix
  ];

  systemd.user.services.dms.Service = {
    Restart = "on-failure";
    RestartSec = "2s";
  };

  programs.dank-material-shell = {
    enable = true;
    inherit settings;

    plugins = {
      dankBatteryAlerts.src = inputs.dms-plugins + "/DankBatteryAlerts";
      dankKDEConnect.src = inputs.dms-plugins + "/DankKDEConnect";
      dankLauncherKeys.src = inputs.dms-plugins + "/DankLauncherKeys";
      dankNotepadModule.src = inputs.dms-plugins + "/DankNotepadModule";
      grimblast.src = inputs.dms-plugins-taylan + "/grimblast";
      homeAssistantMonitor = {
        src = inputs.dms-plugin-hass;
        settings = {
          hassUrl = "https://assistant.home.turnr.dev";
          hassTokenPath = "/run/secrets/hass_token";
          hassToken = "";
        };
      };
      dockerManager = {
        src = inputs.dms-plugin-docker-manager;
        settings = {
          terminalApp = "ghostty --hold";
          groupByCompose = true;
        };
      };
      tailscale.src = inputs.dms-plugin-tailscale;
    };

    systemd = {
      enable = true; # Systemd service for auto-start
      restartIfChanged = true; # Auto-restart dms.service when dank-material-shell changes
    };

    # Core features
    enableSystemMonitoring = true; # System monitoring widgets (dgop)
    enableVPN = true; # VPN management widget
    enableDynamicTheming = true; # Wallpaper-based theming (matugen)
    enableAudioWavelength = true; # Audio visualizer (cava)
    enableCalendarEvents = false; # Calendar integration (khal)
    enableClipboardPaste = true; # Pasting items from the clipboard (wtype)
  };

  home.packages = with pkgs; [
    adw-gtk3
    adwaita-icon-theme

    # Needed for the Home Assistant Monitor plugin's websocket connection.
    qt6.qtwebsockets
  ];

  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3";
      package = pkgs.adw-gtk3;
    };
    gtk4.theme = config.gtk.theme;
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
  };

  home.activation.createDmsLuaFiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for f in \
      "$HOME/.config/hypr/dms/colors.lua" \
      "$HOME/.config/hypr/dms/cursor.lua" \
      "$HOME/.config/hypr/dms/layout.lua" \
      "$HOME/.config/hypr/dms/windowrules.lua"
    do
      if [ ! -f "$f" ]; then
        mkdir -p "$(dirname "$f")"
        touch "$f"
      fi
    done
  '';

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
