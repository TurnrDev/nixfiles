{ configs, pkgs, inputs, ... }:

let
  settings = builtins.fromJSON (builtins.readFile ./settings.json);
in

{
  imports = [
    inputs.dms.homeModules.dank-material-shell
  ];

  programs.dank-material-shell = {
    enable = true;
    inherit settings;
    
    # plugins = {
    #   dankKDEConnect.enable = true;
    #   dankLauncherKeys.enable = true;
    #   dankNotepadModule.enable = true;
    #   grimblast.enable = true;
    #   homeAssistantMonitor = {
    #     enable = true;
    #     settings = {
    #       hassUrl = "https://assistant.home.turnr.dev";
    #     };
    #   };
    #   dockerManager = {
    #     enable = true;
    #     settings = {
    #       terminalApp = "foot --hold";
    #       groupByCompose = true;
    #     };
    #   };
    # };

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

  wayland.windowManager.hyprland.settings = {
    source = [
      "~/.config/hypr/dms/colors.conf"
      "~/.config/hypr/dms/cursor.conf"
      "~/.config/hypr/dms/layout.conf"
      "~/.config/hypr/dms/outputs.conf"
      "~/.config/hypr/dms/windowrules.conf"
    ];
    env = [
      "DMS_DISABLE_MATUGEN,1"
      "DMS_DANKBAR_LAYER,overlay"
      "DMS_HIDE_TRAYIDS,discord,spotify"
    ];
    bind = [
      "SUPER, space, exec, dms ipc call spotlight toggle"
      "SUPER, V, exec, dms ipc call clipboard toggle"
      "SUPER, M, exec, dms ipc call processlist focusOrToggle"
      "SUPER, comma, exec, dms ipc call settings focusOrToggle"
      "SUPER, N, exec, dms ipc call notifications toggle"
      "SUPER SHIFT, N, exec, dms ipc call notepad toggle"
      "SUPER, Y, exec, dms ipc call dankdash wallpaper"
      "SUPER, TAB, exec, dms ipc call hypr toggleOverview"
      "SUPER, X, exec, dms ipc call powermenu toggle"
      "SUPER SHIFT, Slash, exec, dms ipc call keybinds toggle hyprland"
      "SUPER ALT, L, exec, dms ipc call lock lock"
      "CTRL ALT, Delete, exec, dms ipc call processlist focusOrToggle"
      "CTRL SHIFT, Escape, exec, dms ipc call processlist focusOrToggle"
      "SUPER SHIFT, W, exec, dms ipc call window-rules toggle"
      "CTRL SHIFT, R, exec, dms ipc call workspace-rename open"
      ", Print, exec, dms screenshot"
      "CTRL, Print, exec, dms screenshot full"
      "ALT, Print, exec, dms screenshot window"
    ];
    bindel = [
      ", XF86AudioRaiseVolume, exec, dms ipc call audio increment 3"
      ", XF86AudioLowerVolume, exec, dms ipc call audio decrement 3"
      "CTRL, XF86AudioRaiseVolume, exec, dms ipc call mpris increment 3"
      "CTRL, XF86AudioLowerVolume, exec, dms ipc call mpris decrement 3"
      ", XF86MonBrightnessUp, exec, dms ipc call brightness increment 5 \"\""
      ", XF86MonBrightnessDown, exec, dms ipc call brightness decrement 5 \"\""
    ];
    bindl = [
      ", XF86AudioMute, exec, dms ipc call audio mute"
      ", XF86AudioMicMute, exec, dms ipc call audio micmute"
      ", XF86AudioPause, exec, dms ipc call mpris playPause"
      ", XF86AudioPlay, exec, dms ipc call mpris playPause"
      ", XF86AudioPrev, exec, dms ipc call mpris previous"
      ", XF86AudioNext, exec, dms ipc call mpris next"
    ];
  };

}
