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
  stylixScheme = ./themes/trainerdex.yaml;
  dmsTheme = import ./themes/dms-from-stylix.nix { colors = config.lib.stylix.colors; };
  dmsThemeFile = pkgs.writeText "dankMaterialShell-stylix-color-theme.json" (builtins.toJSON dmsTheme);
  dmsSettings =
    settings
    // {
      currentThemeName = lib.mkForce "custom";
      customThemeFile = lib.mkForce dmsThemeFile;
    };
in

{
  imports = [
    inputs.dms.homeModules.dank-material-shell
    ./display-manager.nix
    ./wallpaper-automation.nix
  ];

  config = {
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
      settings = dmsSettings;

      plugins = {
        dankBatteryAlerts.src = inputs."dms-plugins" + "/DankBatteryAlerts";
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
        tailscale.src = inputs."dms-plugin-tailscale";
      };

      systemd = {
        enable = true; # Systemd service for auto-start
        restartIfChanged = true; # Auto-restart dms.service when dank-material-shell changes
      };

      # Core features
      enableSystemMonitoring = true; # System monitoring widgets (dgop)
      enableVPN = true; # VPN management widget
      enableDynamicTheming = false; # Stylix owns palette generation now
      enableAudioWavelength = true; # Audio visualizer (cava)
      enableCalendarEvents = false; # Calendar integration (khal)
      enableClipboardPaste = true; # Pasting items from the clipboard (wtype)
    };

    home.packages = with pkgs; [
      papirus-icon-theme

      # Needed for the Home Assistant Monitor plugin's websocket connection.
      qt6.qtwebsockets
    ];

    stylix = {
      enable = true;
      autoEnable = true;
      polarity = "dark";
      base16Scheme = lib.mkDefault stylixScheme;

      cursor = {
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Ice";
        size = 24;
      };

      fonts = {
        monospace = {
          package = pkgs.nerd-fonts.fira-code;
          name = "FiraCode Nerd Font Mono";
        };
        sansSerif = {
          package = pkgs.inter;
          name = "Inter";
        };
        serif = {
          package = pkgs.source-serif;
          name = "Source Serif 4";
        };
        sizes = {
          applications = 11;
          desktop = 11;
          popups = 11;
          terminal = 12;
        };
      };

      targets = {
        gtk.enable = true;
        qt.enable = true;
      };
    };

    gtk = {
      enable = true;
      iconTheme = {
        name = "Papirus";
        package = pkgs.papirus-icon-theme;
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
  };
}
