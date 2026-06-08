{
  configs,
  pkgs,
  inputs,
  ...
}:
{
  # Wrapper module for generic Hyprland config.
  # Use this file for core compositor settings that don't deserve their own module.
  #
  # Example:
  # wayland.windowManager.hyprland.settings = {
  #   general.gaps_out = 20;
  #   input.kb_variant = "colemak";
  # };
  imports = [
    ../dms/dms.nix
    ./execs.nix
    ./binds.nix
    ./rules.nix
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    configType = "hyprlang";
    settings = {
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
      };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        force_default_wallpaper = 0;
      };

      input = {
        follow_mouse = 1;
        numlock_by_default = true;
        touchpad = {
          natural_scroll = false;
          disable_while_typing = false;
          tap-to-click = false;
        };
        kb_layout = "gb";
        kb_variant = "colemak";
        # Let binds follow the typed symbol instead of the first layout's
        # physical key positions when multiple layouts are in play.
        resolve_binds_by_sym = true;
      };

      device = [
        {
          name = "keychron-keychron-v6-max";
          kb_layout = "gb";
          kb_variant = "";
          resolve_binds_by_sym = true;
        }
        {
          name = "keychron--keychron-link--keyboard";
          kb_layout = "gb";
          kb_variant = "";
          resolve_binds_by_sym = true;
        }
      ];

      decoration = {
        rounding = 10;
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
        };
        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
        };
      };

      # Constrain a single tiled window on ultrawide displays.
      # 16:9 yields 2560px width on a 1440px-tall monitor.
      layout = {
        single_window_aspect_ratio = "16 9";
        single_window_aspect_ratio_tolerance = 0.1;
      };

      xwayland = {
        force_zero_scaling = true;
        enabled = true;
      };

      binds = {
        scroll_event_delay = 0;
      };

      # Hyprland's input block covers Wayland clients; XWayland/Proton
      # clients such as Elite Dangerous need their XKB layout set too.
      "exec-once" = [
        "${pkgs.setxkbmap}/bin/setxkbmap -layout gb"
      ];
    };
  };
}
