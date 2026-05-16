{ configs, pkgs, inputs, ... }:
{
  # Core Hyprland compositor configuration.
  # Use this file for settings that should live in the main `hl.config({ ... })`
  # block or in top-level `hl.device({ ... })` entries rather than in their own
  # focused module.
  #
  # This repo uses Home Manager's native Lua generator:
  # `wayland.windowManager.hyprland.configType = "lua"`.
  #
  # Usage:
  # - Put compositor variables under `settings.config`. Home Manager renders
  #   them into `hl.config({ ... })`.
  # - Put per-device overrides under `settings.device`. Home Manager renders
  #   them into `hl.device({ ... })`.
  # - Keep startup hooks, binds, and rules in `execs.nix`, `binds.nix`, and
  #   `rules.nix` respectively.
  #
  # Example:
  # wayland.windowManager.hyprland.settings = {
  #   config = {
  #     general.gaps_out = 20;
  #     input.kb_layout = "gb";
  #     input.kb_variant = "colemak";
  #   };
  #
  #   device = {
  #     name = "logitech-usb-keyboard";
  #     kb_layout = "gb";
  #     kb_variant = "";
  #   };
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
    configType = "lua";
    settings =
      {
        config = {
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
            resolve_binds_by_sym = true;
            touchpad = {
              natural_scroll = false;
              disable_while_typing = false;
              tap_to_click = false;
            };
            kb_layout = "gb";
            kb_variant = "colemak";
          };

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
        };

        # Keep the external Logitech K120 on plain QWERTY while the main
        # keyboard stays on the global Colemak layout.
        device = {
          name = "logitech-usb-keyboard";
          kb_layout = "gb";
          kb_variant = "";
        };
      };
  };
}
