{ configs, pkgs, inputs, ... }:
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
    settings =
      {
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

        xwayland = {
          force_zero_scaling = true;
          enabled = true;
        };

        binds = {
          scroll_event_delay = 0;
        };
      };
  };
}
