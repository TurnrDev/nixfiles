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
    qtThemingEnabled = true;
  };
  sessionTarget = config.wayland.systemd.target;
in

{
  imports = [
    inputs.dms.homeModules.dank-material-shell
    ./display-manager.nix
    ./wallpaper-automation.nix
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
          hassUrl = "https://assistant.home.turnr.dev";
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
    enableDynamicTheming = true; # Wallpaper-based theming (matugen)
    enableAudioWavelength = true; # Audio visualizer (cava)
    enableCalendarEvents = false; # Calendar integration (khal)
    enableClipboardPaste = true; # Pasting items from the clipboard (wtype)
  };

  home.packages = with pkgs; [
    adw-gtk3
    papirus-icon-theme

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
      name = "Papirus";
      package = pkgs.papirus-icon-theme;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "breeze";
    qt5ctSettings = {
      Appearance = {
        icon_theme = "Papirus";
        style = "breeze";
      };
    };
    qt6ctSettings = {
      Appearance = {
        icon_theme = "Papirus";
        style = "breeze";
      };
    };
  };

  home.activation.createDmsLuaFiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for f in \
      "$HOME/.config/hypr/dms/colors.lua" \
      "$HOME/.config/hypr/dms/cursor.lua" \
      "$HOME/.config/hypr/dms/layout.lua" \
      "$HOME/.config/hypr/dms/outputs.lua" \
      "$HOME/.config/hypr/dms/windowrules.lua"
    do
      if [ ! -f "$f" ]; then
        mkdir -p "$(dirname "$f")"
        if [ "$(basename "$f")" = "outputs.lua" ]; then
          echo 'hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })' > "$f"
        else
          touch "$f"
        fi
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
