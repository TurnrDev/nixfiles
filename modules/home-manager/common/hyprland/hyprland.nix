{ configs, pkgs, inputs, ... }:

{
  home.packages = with pkgs; [
    playerctl # cli to media player control
    # pkgs.hyprpicker # colour picker
  ];
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    extraConfig = ''
    submap = fit-switch
    bindrt = $mainMod, SUPER_L, submap, reset
    bind = , escape, submap, reset
    bind = $mainMod, F, layoutmsg, fit active
    bind = $mainMod, V, layoutmsg, fit visible
    bind = $mainMod, A, layoutmsg, fit all
    bind = $mainMod, E, layoutmsg, fit toend
    bind = $mainMod, B, layoutmsg, fit tobeg
    submap = reset
    '';
    settings = {
      "$mainMod" = "SUPER";
      "$shiftMod" = "SUPER_SHIFT";
      "$altMod" = "SUPER+ALT";
      exec-once = [
        "uwsm app -- nm-applet"
        "uwsm app -- hyprlock --no-fade-in --immediate-render --grace 0"
        "uwsm app -- discord"
        "[workspace 2 silent] uwsm app -- spotify"
      ];
      bindd = [
        "$mainMod, W, Launch Firefox, exec, uwsm app -- firefox"
        "$mainMod, T, Launch terminal emulator, exec, uwsm app -- foot"
        "$mainMod, Super_L, Launch Rofi, exec, uwsm app -- fuzzel"
        "$mainMod, Super_R, Launch Rofi, exec, uwsm app -- fuzzel"
        "$mainMod, Q, Close, killactive"
        "$mainMod, F, Fullscreen, fullscreen"
        # "$shiftMod, F, Tiled fullscreen, layoutmsg, colresize 1"
        #"$shiftMod, F, Fake fullscreen,fakefullscreen"
        "$altMod, Space, Toggle Floating, togglefloating"
        # "$mainMod, J, Toggle split, togglesplit" # hy3
        ", XF86AudioRaiseVolume, Raise Volume, exec, pactl set-sink-volume @DEFAULT_SINK@ +5%"
        ", XF86AudioLowerVolume, Lower Volume, exec, pactl set-sink-volume @DEFAULT_SINK@ -5%"
        ", XF86AudioMute, Mute Volume, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle"
        ", XF86MonBrightnessUp, Brightness Up, exec, brightnessctl s +5%"
        ", XF86MonBrightnessDown, Brightness Down, exec, brightnessctl s 5%-"
        ", XF86AudioPlay, Media Play, exec, playerctl play-pause"
        ", XF86AudioNext, Media Next, exec, playerctl next"
        ", XF86AudioPrev, Media Previous, exec, playerctl previous"
        # "$mainMod, F5, Spotify Media Play, exec, playerctl --player=spotify play-pause"
        # "$mainMod, F8, Spotify Media Next, exec, playerctl --player=spotify next"
        # "$mainMod, F7, Spotify Media Previous, exec, playerctl --player=spotify previous"
        "$mainMod, mouse_down, Zoom In, exec, hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor -j | jq '.float * 1.1')"
        "$mainMod, mouse_up, Zoom Out, exec, hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor -j | jq '(.float / 1.1) | if . < 1 then 1 else . end')"
        "$shiftMod, mouse_up, Reset Zoom, exec, hyprctl -q keyword cursor:zoom_factor 1"
        "$shiftMod, mouse_down, Reset Zoom, exec, hyprctl -q keyword cursor:zoom_factor 1"
        "$shiftMod, minus, Reset Zoom, exec, hyprctl -q keyword cursor:zoom_factor 1"
        "$mainMod, O, Execute a fit operation, submap, fit-switch"
        "$mainMod, up, Move layout up, layoutmsg, move -col"
        "$mainMod, down, Move layout down, layoutmsg, move +col"
        "$mainMod, left, Move layout left, layoutmsg, move -col"
        "$mainMod, right, Move layout right, layoutmsg, move +col"
        "$shiftMod, up, Move window left, layoutmsg, swapcol l"
        "$shiftMod, down, Move window right, layoutmsg, swapcol r" 
        "$shiftMod, left, Move window left, layoutmsg, swapcol l"
        "$shiftMod, right, Move window right, layoutmsg, swapcol r"
      ];
      binde = [
        "$mainMod, equal, exec, hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor -j | jq '.float * 1.1')"
        "$mainMod, minus, exec, hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor -j | jq '(.float * 0.9) | if . < 1 then 1 else . end')"
      ];
      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        layout = "scrolling";
      };
      scrolling = {
        fullscreen_on_one_column = false;
      };
      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        force_default_wallpaper = 0;
      };
      input = {
        follow_mouse = 1;
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
      windowrule = [
        {
          name = "transparency";
          "match:class" = "(.*)";
          opacity = "1.0 0.8";
        }
        {
          name = "Youtube";
          "match:title" = "(.*)(- YouTube)(.*)";
          opacity = "1.0 1.0";
        }
        # {
        #   name = "Jellyfin";
        #   "match:class" = "org.jellyfin.JellyfinDesktop";
        #   opacity = "1.0 1.0";
        # }
      ];
    };
  };
}
