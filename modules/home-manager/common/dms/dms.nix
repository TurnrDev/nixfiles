{ config, configs, lib, pkgs, inputs, ... }:

let
  # DMS still ships hyprlang snippets and CLI parsers that target
  # `~/.config/hypr/hyprland.conf`, so this module currently has to bridge
  # between native Hyprland Lua and DMS' legacy expectations.
  settings = (builtins.fromJSON (builtins.readFile ./settings.json)) // {
    gtkThemingEnabled = true;
    iconTheme = "Adwaita";
    qtThemingEnabled = false;
  };
  bindUtils = import ../hyprland/bind-utils.nix { inherit lib; };
  inherit (bindUtils)
    altMod
    ctrlAlt
    ctrlShift
    keyCombo
    mainMod
    mainShift
    mkExecBind
    ;
  dmsHyprSources = [
    "${config.home.homeDirectory}/.config/hypr/dms/colors.conf" # TODO: Remove this list entry when DMS stops emitting hyprlang snippet files or when we replace this startup re-source bridge with a native Lua integration.
    "${config.home.homeDirectory}/.config/hypr/dms/cursor.conf" # TODO: Remove this list entry when DMS stops emitting hyprlang snippet files or when we replace this startup re-source bridge with a native Lua integration.
    "${config.home.homeDirectory}/.config/hypr/dms/layout.conf" # TODO: Remove this list entry when DMS stops emitting hyprlang snippet files or when we replace this startup re-source bridge with a native Lua integration.
    "${config.home.homeDirectory}/.config/hypr/dms/outputs.conf" # TODO: Remove this list entry when DMS stops emitting hyprlang snippet files or when we replace this startup re-source bridge with a native Lua integration.
    "${config.home.homeDirectory}/.config/hypr/dms/windowrules.conf" # TODO: Remove this list entry when DMS stops emitting hyprlang snippet files or when we replace this startup re-source bridge with a native Lua integration.
  ];
  mkEnv = name: value: {
    _args = [
      name
      value
    ];
  };
  mkDmsBind =
    {
      mods ? "",
      key,
      description,
      command,
      flags ? { },
    }:
    mkExecBind {
      key = keyCombo mods key;
      inherit command description flags;
    };
  renderDmsMirrorBind = # TODO: Delete this helper when we remove the compatibility `hyprland.conf` mirror; its only job is to turn native Lua binds back into legacy hyprlang `bindd*` lines for DMS.
    bind:
    let
      dms = bind._dms;
      parts = lib.splitString " + " dms.key;
      key = lib.last parts;
      mods = lib.concatStringsSep " " (lib.init parts);
      suffix =
        lib.optionalString (dms.flags.repeating or false) "e"
        + lib.optionalString (dms.flags.locked or false) "l"
        + lib.optionalString (dms.flags.mouse or false) "m"
        + lib.optionalString (dms.flags.release or false) "r";
    in
    "bindd${suffix} = ${mods}, ${key}, ${dms.description}, ${dms.dispatcher}, ${dms.params}";
  dmsMirrorBinds =
    lib.filter (bind: builtins.isAttrs bind && bind ? _dms) config.wayland.windowManager.hyprland.settings.bind; # TODO: Delete this filtered bind list when DMS can discover keybinds from `hyprland.lua` or `hyprctl binds -j` instead of needing a generated `hyprland.conf`.
in

{
  imports = [
    inputs.dms.homeModules.dank-material-shell
    ../hyprland/env.nix
    ./wallpaper-automation.nix
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
    files=(
      "$HOME/.config/hypr/dms/colors.conf"
      "$HOME/.config/hypr/dms/cursor.conf"
      "$HOME/.config/hypr/dms/layout.conf"
      "$HOME/.config/hypr/dms/outputs.conf"
      "$HOME/.config/hypr/dms/binds.conf" # TODO: Remove this stub file entry when DMS no longer writes editable Hyprland overrides to `dms/binds.conf` and the compatibility `hyprland.conf` mirror is gone.
      "$HOME/.config/hypr/dms/windowrules.conf"
    )
    for f in "''${files[@]}"
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
    (lib.mapAttrs' (name: _: {
      name = "DankMaterialShell/plugins/${name}";
      value.force = true;
    }) enabledPlugins)
    // {
      "hypr/hyprland.conf".text = # TODO: Delete this entire generated file entry when DMS stops parsing `~/.config/hypr/hyprland.conf`; Hyprland itself should keep using `hyprland.lua`, and this mirror exists only for DMS' legacy parser.
        ''
        # Generated only for tools that still parse hyprland.conf.
        # Hyprland 0.55+ loads hyprland.lua when it exists.

        source = ./dms/binds.conf # TODO: Remove this line when DMS no longer uses `dms/binds.conf` for editable Hyprland keybind overrides.

        ${lib.concatMapStringsSep "\n" renderDmsMirrorBind dmsMirrorBinds}
      '';
    };

  wayland.windowManager.hyprland.settings = {
    env = [
      (mkEnv "DMS_DANKBAR_LAYER" "overlay")
      (mkEnv "DMS_HIDE_TRAYIDS" "discord,spotify")
      (mkEnv "QT_QPA_PLATFORMTHEME" "gtk3")
      (mkEnv "QT_QPA_PLATFORMTHEME_QT6" "gtk3")
      (mkEnv "QS_ICON_THEME" "Adwaita")
    ];
    on = [
      {
        _args = [
          "hyprland.start"
          (lib.generators.mkLuaInline ''
            function()
              for _, source in ipairs({
                ${lib.concatMapStringsSep ",\n    " (source: ''"${source}"'') dmsHyprSources}
              }) do
                hl.exec_cmd("hyprctl keyword source " .. source) -- TODO: Remove this startup bridge call when DMS exports native Lua Hyprland config or when these hyprlang snippet files are no longer needed.
              end
            end
          '')
        ];
      }
    ];
    bind = [
      (mkDmsBind {
        mods = mainMod;
        key = "space";
        description = "Toggle Spotlight";
        command = "dms ipc call spotlight toggle";
      })
      (mkDmsBind {
        mods = mainMod;
        key = "V";
        description = "Toggle Clipboard";
        command = "dms ipc call clipboard toggle";
      })
      (mkDmsBind {
        mods = mainMod;
        key = "M";
        description = "Open Process List";
        command = "dms ipc call processlist focusOrToggle";
      })
      (mkDmsBind {
        mods = mainMod;
        key = "comma";
        description = "Open Settings";
        command = "dms ipc call settings focusOrToggle";
      })
      (mkDmsBind {
        mods = mainMod;
        key = "N";
        description = "Toggle Notifications";
        command = "dms ipc call notifications toggle";
      })
      (mkDmsBind {
        mods = mainShift;
        key = "N";
        description = "Toggle Notepad";
        command = "dms ipc call notepad toggle";
      })
      (mkDmsBind {
        mods = mainMod;
        key = "Y";
        description = "Change Wallpaper";
        command = "dms ipc call dankdash wallpaper";
      })
      (mkDmsBind {
        mods = mainMod;
        key = "TAB";
        description = "Toggle Overview";
        command = "dms ipc call hypr toggleOverview";
      })
      (mkDmsBind {
        mods = mainMod;
        key = "X";
        description = "Toggle Power Menu";
        command = "dms ipc call powermenu toggle";
      })
      (mkDmsBind {
        mods = mainShift;
        key = "Slash";
        description = "Show Keybinds";
        command = "dms ipc call keybinds toggle hyprland";
      })
      (mkDmsBind {
        mods = mainMod;
        key = "L";
        description = "Lock Session";
        command = "dms ipc call lock lock";
      })
      (mkDmsBind {
        mods = ctrlAlt;
        key = "Delete";
        description = "Open Process List";
        command = "dms ipc call processlist focusOrToggle";
      })
      (mkDmsBind {
        mods = ctrlShift;
        key = "Escape";
        description = "Open Process List";
        command = "dms ipc call processlist focusOrToggle";
      })
      (mkDmsBind {
        mods = mainShift;
        key = "W";
        description = "Toggle Window Rules";
        command = "dms ipc call window-rules toggle";
      })
      (mkDmsBind {
        mods = ctrlShift;
        key = "R";
        description = "Rename Workspace";
        command = "dms ipc call workspace-rename open";
      })
      (mkDmsBind {
        key = "Print";
        description = "Take Screenshot";
        command = "dms screenshot";
      })
      (mkDmsBind {
        mods = "CTRL";
        key = "Print";
        description = "Take Full Screenshot";
        command = "dms screenshot full";
      })
      (mkDmsBind {
        mods = "ALT";
        key = "Print";
        description = "Take Window Screenshot";
        command = "dms screenshot window";
      })
      (mkDmsBind {
        key = "XF86AudioRaiseVolume";
        description = "Raise Volume";
        command = "dms ipc call audio increment 3";
        flags = {
          locked = true;
          repeating = true;
        };
      })
      (mkDmsBind {
        key = "XF86AudioLowerVolume";
        description = "Lower Volume";
        command = "dms ipc call audio decrement 3";
        flags = {
          locked = true;
          repeating = true;
        };
      })
      (mkDmsBind {
        mods = "CTRL";
        key = "XF86AudioRaiseVolume";
        description = "Seek Forward";
        command = "dms ipc call mpris increment 3";
        flags = {
          locked = true;
          repeating = true;
        };
      })
      (mkDmsBind {
        mods = "CTRL";
        key = "XF86AudioLowerVolume";
        description = "Seek Backward";
        command = "dms ipc call mpris decrement 3";
        flags = {
          locked = true;
          repeating = true;
        };
      })
      (mkDmsBind {
        key = "XF86MonBrightnessUp";
        description = "Brightness Up";
        command = "dms ipc call brightness increment 5 \"\"";
        flags = {
          locked = true;
          repeating = true;
        };
      })
      (mkDmsBind {
        key = "XF86MonBrightnessDown";
        description = "Brightness Down";
        command = "dms ipc call brightness decrement 5 \"\"";
        flags = {
          locked = true;
          repeating = true;
        };
      })
      (mkDmsBind {
        key = "XF86AudioMute";
        description = "Mute Volume";
        command = "dms ipc call audio mute";
        flags.locked = true;
      })
      (mkDmsBind {
        key = "XF86AudioMicMute";
        description = "Mute Microphone";
        command = "dms ipc call audio micmute";
        flags.locked = true;
      })
      (mkDmsBind {
        key = "XF86AudioPause";
        description = "Play Pause Media";
        command = "dms ipc call mpris playPause";
        flags.locked = true;
      })
      (mkDmsBind {
        key = "XF86AudioPlay";
        description = "Play Pause Media";
        command = "dms ipc call mpris playPause";
        flags.locked = true;
      })
      (mkDmsBind {
        key = "XF86AudioPrev";
        description = "Previous Track";
        command = "dms ipc call mpris previous";
        flags.locked = true;
      })
      (mkDmsBind {
        key = "XF86AudioNext";
        description = "Next Track";
        command = "dms ipc call mpris next";
        flags.locked = true;
      })
    ];
  };

}
