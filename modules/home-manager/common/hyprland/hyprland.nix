{ configs, pkgs, inputs, ... }:

let
  zoomInCommand =
    "exec, hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor -j | jq '.float * 1.1')";
  zoomOutCommand =
    "exec, hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor -j | jq '(.float / 1.1) | if . < 1 then 1 else . end')";
  zoomResetCommand = "exec, hyprctl -q keyword cursor:zoom_factor 1";
in

{
  imports = [
    ../dms/dms.nix
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    settings = {
      "$mainMod" = "SUPER";
      "$altMod" = "SUPER+ALT";
      exec-once = [
        "[workspace 2 silent] uwsm app -- discord"
        "[workspace 2 silent] uwsm app -- spotify"
      ];
      bindd = [
        "$mainMod, Super_L, Launch Spotlight, exec, dms ipc call spotlight toggle"
        "$mainMod, Super_R, Launch Spotlight, exec, dms ipc call spotlight toggle"
        "$mainMod, W, Launch Firefox, exec, uwsm app -- firefox"
        "$mainMod, C, Launch IDE, exec, uwsm app -- code"
        "$mainMod, G, Launch Git client, exec, uwsm app -- gitkraken"
        "$mainMod, T, Launch Terminal, exec, ghostty"
        "SUPER SHIFT, E, Exit Hyprland, exit"
        "$mainMod, Q, Close Window, killactive"
        "$mainMod, F, Fullscreen, fullscreen, 1"
        "SUPER SHIFT, F, Exit Fullscreen, fullscreen, 0"
        "SUPER SHIFT, T, Toggle Floating, togglefloating"

        "$mainMod, left, Focus Left, movefocus, l"
        "$mainMod, down, Focus Down, movefocus, d"
        "$mainMod, up, Focus Up, movefocus, u"
        "$mainMod, right, Focus Right, movefocus, r"
        "$mainMod, H, Focus Left, movefocus, l"
        "$mainMod, J, Focus Down, movefocus, d"
        "$mainMod, K, Focus Up, movefocus, u"
        "$mainMod, L, Focus Right, movefocus, r"

        "SUPER SHIFT, left, Move Window Left, movewindow, l"
        "SUPER SHIFT, down, Move Window Down, movewindow, d"
        "SUPER SHIFT, up, Move Window Up, movewindow, u"
        "SUPER SHIFT, right, Move Window Right, movewindow, r"
        "SUPER SHIFT, H, Move Window Left, movewindow, l"
        "SUPER SHIFT, J, Move Window Down, movewindow, d"
        "SUPER SHIFT, K, Move Window Up, movewindow, u"
        "SUPER SHIFT, L, Move Window Right, movewindow, r"

        "$mainMod, Home, Focus First Window, focuswindow, first"
        "$mainMod, End, Focus Last Window, focuswindow, last"

        "SUPER CTRL, left, Focus Monitor Left, focusmonitor, l"
        "SUPER CTRL, right, Focus Monitor Right, focusmonitor, r"
        "SUPER CTRL, H, Focus Monitor Left, focusmonitor, l"
        "SUPER CTRL, J, Focus Monitor Down, focusmonitor, d"
        "SUPER CTRL, K, Focus Monitor Up, focusmonitor, u"
        "SUPER CTRL, L, Focus Monitor Right, focusmonitor, r"

        "SUPER SHIFT CTRL, left, Move Window To Left Monitor, movewindow, mon:l"
        "SUPER SHIFT CTRL, down, Move Window To Lower Monitor, movewindow, mon:d"
        "SUPER SHIFT CTRL, up, Move Window To Upper Monitor, movewindow, mon:u"
        "SUPER SHIFT CTRL, right, Move Window To Right Monitor, movewindow, mon:r"
        "SUPER SHIFT CTRL, H, Move Window To Left Monitor, movewindow, mon:l"
        "SUPER SHIFT CTRL, J, Move Window To Lower Monitor, movewindow, mon:d"
        "SUPER SHIFT CTRL, K, Move Window To Upper Monitor, movewindow, mon:u"
        "SUPER SHIFT CTRL, L, Move Window To Right Monitor, movewindow, mon:r"

        "$mainMod, Page_Down, Next Workspace, workspace, e+1"
        "$mainMod, Page_Up, Previous Workspace, workspace, e-1"
        "$mainMod, U, Next Workspace, workspace, e+1"
        "$mainMod, I, Previous Workspace, workspace, e-1"
        "SUPER CTRL, down, Send Window To Next Workspace, movetoworkspace, e+1"
        "SUPER CTRL, up, Send Window To Previous Workspace, movetoworkspace, e-1"
        "SUPER CTRL, U, Send Window To Next Workspace, movetoworkspace, e+1"
        "SUPER CTRL, I, Send Window To Previous Workspace, movetoworkspace, e-1"

        "SUPER SHIFT, Page_Down, Move Window To Next Workspace, movetoworkspace, e+1"
        "SUPER SHIFT, Page_Up, Move Window To Previous Workspace, movetoworkspace, e-1"
        "SUPER SHIFT, U, Move Window To Next Workspace, movetoworkspace, e+1"
        "SUPER SHIFT, I, Move Window To Previous Workspace, movetoworkspace, e-1"

        "$mainMod, mouse_down, Next Workspace, workspace, e+1"
        "$mainMod, mouse_up, Previous Workspace, workspace, e-1"
        "SUPER CTRL, mouse_down, Send Window To Next Workspace, movetoworkspace, e+1"
        "SUPER CTRL, mouse_up, Send Window To Previous Workspace, movetoworkspace, e-1"

        "$mainMod, 1, Workspace 1, workspace, 1"
        "$mainMod, 2, Workspace 2, workspace, 2"
        "$mainMod, 3, Workspace 3, workspace, 3"
        "$mainMod, 4, Workspace 4, workspace, 4"
        "$mainMod, 5, Workspace 5, workspace, 5"
        "$mainMod, 6, Workspace 6, workspace, 6"
        "$mainMod, 7, Workspace 7, workspace, 7"
        "$mainMod, 8, Workspace 8, workspace, 8"
        "$mainMod, 9, Workspace 9, workspace, 9"

        "SUPER SHIFT, 1, Move Window To Workspace 1, movetoworkspace, 1"
        "SUPER SHIFT, 2, Move Window To Workspace 2, movetoworkspace, 2"
        "SUPER SHIFT, 3, Move Window To Workspace 3, movetoworkspace, 3"
        "SUPER SHIFT, 4, Move Window To Workspace 4, movetoworkspace, 4"
        "SUPER SHIFT, 5, Move Window To Workspace 5, movetoworkspace, 5"
        "SUPER SHIFT, 6, Move Window To Workspace 6, movetoworkspace, 6"
        "SUPER SHIFT, 7, Move Window To Workspace 7, movetoworkspace, 7"
        "SUPER SHIFT, 8, Move Window To Workspace 8, movetoworkspace, 8"
        "SUPER SHIFT, 9, Move Window To Workspace 9, movetoworkspace, 9"

        "$mainMod, bracketleft, Preselect Left Column, layoutmsg, preselect l"
        "$mainMod, bracketright, Preselect Right Column, layoutmsg, preselect r"
        "$mainMod, R, Toggle Split, layoutmsg, togglesplit"
        "SUPER CTRL, F, Reset Window Size, resizeactive, exact 100%"
        "$mainMod, code:20, Expand Window Left, resizeactive, -100 0"
        "$mainMod, code:21, Shrink Window Left, resizeactive, 100 0"
        "SUPER SHIFT, P, Toggle DPMS, dpms, toggle"

        "$altMod, mouse_down, Zoom In, ${zoomInCommand}"
        "$altMod, mouse_up, Zoom Out, ${zoomOutCommand}"
        "$altMod, 0, Reset Zoom, ${zoomResetCommand}"
      ];
      binde = [
        "$mainMod, minus, resizeactive, -10% 0"
        "$mainMod, equal, resizeactive, 10% 0"
        "SUPER SHIFT, minus, resizeactive, 0 -10%"
        "SUPER SHIFT, equal, resizeactive, 0 10%"
        "$altMod, equal, ${zoomInCommand}"
        "$altMod, minus, ${zoomOutCommand}"
      ];
      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];
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
