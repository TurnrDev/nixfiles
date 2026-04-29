{ config, configs, lib, pkgs, inputs, ... }:

let
  settings = (builtins.fromJSON (builtins.readFile ./settings.json)) // {
    gtkThemingEnabled = true;
    iconTheme = "Adwaita";
    qtThemingEnabled = false;
  };
  bindUtils = import ../hyprland/bind-utils.nix;
  inherit (bindUtils)
    altMod
    ctrlAlt
    ctrlShift
    mainMod
    mainShift
    mkBind
    ;
in

{
  imports = [
    inputs.dms.homeModules.dank-material-shell
    ../hyprland/env.nix
  ];

  programs.dank-material-shell = {
    enable = true;
    inherit settings;

    plugins = {
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
    };

    systemd = {
      enable = true;             # Systemd service for auto-start
      restartIfChanged = true;   # Auto-restart dms.service when dank-material-shell changes
    };

    # Core features
    enableSystemMonitoring = true;     # System monitoring widgets (dgop)
    enableVPN = true;                  # VPN management widget
    enableDynamicTheming = true;       # Wallpaper-based theming (matugen)
    enableAudioWavelength = true;      # Audio visualizer (cava)
    enableCalendarEvents = false;       # Calendar integration (khal)
    enableClipboardPaste = true;       # Pasting items from the clipboard (wtype)
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

  home.activation.createDmsSourceFiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for f in \
      "$HOME/.config/hypr/dms/colors.conf" \
      "$HOME/.config/hypr/dms/cursor.conf" \
      "$HOME/.config/hypr/dms/layout.conf" \
      "$HOME/.config/hypr/dms/outputs.conf" \
      "$HOME/.config/hypr/dms/windowrules.conf"
    do
      if [ ! -f "$f" ]; then
        mkdir -p "$(dirname "$f")"
        touch "$f"
      fi
    done
  '';

  xdg.configFile =
    let
      enabledPlugins = lib.filterAttrs (_: plugin: plugin.enable) config.programs.dank-material-shell.plugins;
    in
    lib.mapAttrs' (name: _: {
      name = "DankMaterialShell/plugins/${name}";
      value.force = true;
    }) enabledPlugins;

  wayland.windowManager.hyprland.settings = {
    env = [
      "DMS_DANKBAR_LAYER,overlay"
      "DMS_HIDE_TRAYIDS,discord,spotify"
      "QT_QPA_PLATFORMTHEME,gtk3"
      "QT_QPA_PLATFORMTHEME_QT6,gtk3"
      "QS_ICON_THEME,Adwaita"
    ];
    source = [
      "~/.config/hypr/dms/colors.conf"
      "~/.config/hypr/dms/cursor.conf"
      "~/.config/hypr/dms/layout.conf"
      "~/.config/hypr/dms/outputs.conf"
      "~/.config/hypr/dms/windowrules.conf"
    ];
    bindd = [
      (mkBind {
        mods = mainMod;
        key = "space";
        description = "Toggle Spotlight";
        dispatcher = "exec";
        params = "dms ipc call spotlight toggle";
      })
      (mkBind {
        mods = mainMod;
        key = "V";
        description = "Toggle Clipboard";
        dispatcher = "exec";
        params = "dms ipc call clipboard toggle";
      })
      (mkBind {
        mods = mainMod;
        key = "M";
        description = "Open Process List";
        dispatcher = "exec";
        params = "dms ipc call processlist focusOrToggle";
      })
      (mkBind {
        mods = mainMod;
        key = "comma";
        description = "Open Settings";
        dispatcher = "exec";
        params = "dms ipc call settings focusOrToggle";
      })
      (mkBind {
        mods = mainMod;
        key = "N";
        description = "Toggle Notifications";
        dispatcher = "exec";
        params = "dms ipc call notifications toggle";
      })
      (mkBind {
        mods = mainShift;
        key = "N";
        description = "Toggle Notepad";
        dispatcher = "exec";
        params = "dms ipc call notepad toggle";
      })
      (mkBind {
        mods = mainMod;
        key = "Y";
        description = "Change Wallpaper";
        dispatcher = "exec";
        params = "dms ipc call dankdash wallpaper";
      })
      (mkBind {
        mods = mainMod;
        key = "TAB";
        description = "Toggle Overview";
        dispatcher = "exec";
        params = "dms ipc call hypr toggleOverview";
      })
      (mkBind {
        mods = mainMod;
        key = "X";
        description = "Toggle Power Menu";
        dispatcher = "exec";
        params = "dms ipc call powermenu toggle";
      })
      (mkBind {
        mods = mainShift;
        key = "Slash";
        description = "Show Keybinds";
        dispatcher = "exec";
        params = "dms ipc call keybinds toggle hyprland";
      })
      (mkBind {
        mods = mainMod;
        key = "L";
        description = "Lock Session";
        dispatcher = "exec";
        params = "dms ipc call lock lock";
      })
      (mkBind {
        mods = ctrlAlt;
        key = "Delete";
        description = "Open Process List";
        dispatcher = "exec";
        params = "dms ipc call processlist focusOrToggle";
      })
      (mkBind {
        mods = ctrlShift;
        key = "Escape";
        description = "Open Process List";
        dispatcher = "exec";
        params = "dms ipc call processlist focusOrToggle";
      })
      (mkBind {
        mods = mainShift;
        key = "W";
        description = "Toggle Window Rules";
        dispatcher = "exec";
        params = "dms ipc call window-rules toggle";
      })
      (mkBind {
        mods = ctrlShift;
        key = "R";
        description = "Rename Workspace";
        dispatcher = "exec";
        params = "dms ipc call workspace-rename open";
      })
      (mkBind {
        key = "Print";
        description = "Take Screenshot";
        dispatcher = "exec";
        params = "dms screenshot";
      })
      (mkBind {
        mods = "CTRL";
        key = "Print";
        description = "Take Full Screenshot";
        dispatcher = "exec";
        params = "dms screenshot full";
      })
      (mkBind {
        mods = "ALT";
        key = "Print";
        description = "Take Window Screenshot";
        dispatcher = "exec";
        params = "dms screenshot window";
      })
    ];
    binddel = [
      (mkBind {
        key = "XF86AudioRaiseVolume";
        description = "Raise Volume";
        dispatcher = "exec";
        params = "dms ipc call audio increment 3";
      })
      (mkBind {
        key = "XF86AudioLowerVolume";
        description = "Lower Volume";
        dispatcher = "exec";
        params = "dms ipc call audio decrement 3";
      })
      (mkBind {
        mods = "CTRL";
        key = "XF86AudioRaiseVolume";
        description = "Seek Forward";
        dispatcher = "exec";
        params = "dms ipc call mpris increment 3";
      })
      (mkBind {
        mods = "CTRL";
        key = "XF86AudioLowerVolume";
        description = "Seek Backward";
        dispatcher = "exec";
        params = "dms ipc call mpris decrement 3";
      })
      (mkBind {
        key = "XF86MonBrightnessUp";
        description = "Brightness Up";
        dispatcher = "exec";
        params = "dms ipc call brightness increment 5 \"\"";
      })
      (mkBind {
        key = "XF86MonBrightnessDown";
        description = "Brightness Down";
        dispatcher = "exec";
        params = "dms ipc call brightness decrement 5 \"\"";
      })
    ];
    binddl = [
      (mkBind {
        key = "XF86AudioMute";
        description = "Mute Volume";
        dispatcher = "exec";
        params = "dms ipc call audio mute";
      })
      (mkBind {
        key = "XF86AudioMicMute";
        description = "Mute Microphone";
        dispatcher = "exec";
        params = "dms ipc call audio micmute";
      })
      (mkBind {
        key = "XF86AudioPause";
        description = "Play Pause Media";
        dispatcher = "exec";
        params = "dms ipc call mpris playPause";
      })
      (mkBind {
        key = "XF86AudioPlay";
        description = "Play Pause Media";
        dispatcher = "exec";
        params = "dms ipc call mpris playPause";
      })
      (mkBind {
        key = "XF86AudioPrev";
        description = "Previous Track";
        dispatcher = "exec";
        params = "dms ipc call mpris previous";
      })
      (mkBind {
        key = "XF86AudioNext";
        description = "Next Track";
        dispatcher = "exec";
        params = "dms ipc call mpris next";
      })
    ];
  };

}
