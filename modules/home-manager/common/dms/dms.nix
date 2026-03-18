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

}
