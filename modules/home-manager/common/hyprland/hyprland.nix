{ configs, pkgs, inputs, ... }:

let
  bindUtils = import ./bind-utils.nix;
  inherit (bindUtils)
    altMod
    mainCtrl
    mainMod
    mainShift
    mainShiftCtrl
    mkBind
    ;

  workspaceNumbers = builtins.map builtins.toString [
    1
    2
    3
    4
    5
    6
    7
    8
    9
  ];

  workspaceBinds = builtins.map (
    n:
    mkBind {
      mods = mainMod;
      key = n;
      description = "Workspace ${n}";
      dispatcher = "workspace";
      params = n;
    }
  ) workspaceNumbers;

  moveToWorkspaceBinds = builtins.map (
    n:
    mkBind {
      mods = mainShift;
      key = n;
      description = "Move Window To Workspace ${n}";
      dispatcher = "movetoworkspace";
      params = n;
    }
  ) workspaceNumbers;

  zoomInCommand =
    "hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor -j | jq '.float * 1.1')";
  zoomOutCommand =
    "hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor -j | jq '(.float / 1.1) | if . < 1 then 1 else . end')";
  zoomResetCommand = "hyprctl -q keyword cursor:zoom_factor 1";
in

{
  imports = [
    ../dms/dms.nix
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    settings = {
      exec-once = [
        "[workspace 2 silent] uwsm app -- discord"
        "[workspace 2 silent] uwsm app -- spotify"
      ];
      bindd = [
        (mkBind {
          mods = mainMod;
          key = "Super_L";
          description = "Launch Spotlight";
          dispatcher = "exec";
          params = "dms ipc call spotlight toggle";
        })
        (mkBind {
          mods = mainMod;
          key = "Super_R";
          description = "Launch Spotlight";
          dispatcher = "exec";
          params = "dms ipc call spotlight toggle";
        })
        (mkBind {
          mods = mainMod;
          key = "W";
          description = "Launch Firefox";
          dispatcher = "exec";
          params = "uwsm app -- firefox";
        })
        (mkBind {
          mods = mainMod;
          key = "C";
          description = "Launch IDE";
          dispatcher = "exec";
          params = "uwsm app -- code";
        })
        (mkBind {
          mods = mainMod;
          key = "G";
          description = "Launch Git Client";
          dispatcher = "exec";
          params = "uwsm app -- gitkraken";
        })
        (mkBind {
          mods = mainMod;
          key = "T";
          description = "Launch Terminal";
          dispatcher = "exec";
          params = "ghostty";
        })
        (mkBind {
          mods = mainShift;
          key = "E";
          description = "Exit Hyprland";
          dispatcher = "exit";
        })
        (mkBind {
          mods = mainMod;
          key = "Q";
          description = "Close Window";
          dispatcher = "killactive";
        })
        (mkBind {
          mods = mainMod;
          key = "F";
          description = "Enter Fullscreen";
          dispatcher = "fullscreen";
          params = "1";
        })
        (mkBind {
          mods = mainShift;
          key = "F";
          description = "Exit Fullscreen";
          dispatcher = "fullscreen";
          params = "0";
        })
        (mkBind {
          mods = mainShift;
          key = "T";
          description = "Toggle Floating";
          dispatcher = "togglefloating";
        })
        (mkBind {
          mods = mainMod;
          key = "left";
          description = "Focus Left";
          dispatcher = "movefocus";
          params = "l";
        })
        (mkBind {
          mods = mainMod;
          key = "down";
          description = "Focus Down";
          dispatcher = "movefocus";
          params = "d";
        })
        (mkBind {
          mods = mainMod;
          key = "up";
          description = "Focus Up";
          dispatcher = "movefocus";
          params = "u";
        })
        (mkBind {
          mods = mainMod;
          key = "right";
          description = "Focus Right";
          dispatcher = "movefocus";
          params = "r";
        })
        (mkBind {
          mods = mainMod;
          key = "H";
          description = "Focus Left";
          dispatcher = "movefocus";
          params = "l";
        })
        (mkBind {
          mods = mainMod;
          key = "J";
          description = "Focus Down";
          dispatcher = "movefocus";
          params = "d";
        })
        (mkBind {
          mods = mainMod;
          key = "K";
          description = "Focus Up";
          dispatcher = "movefocus";
          params = "u";
        })
        (mkBind {
          mods = mainMod;
          key = "L";
          description = "Focus Right";
          dispatcher = "movefocus";
          params = "r";
        })
        (mkBind {
          mods = mainShift;
          key = "left";
          description = "Move Window Left";
          dispatcher = "movewindow";
          params = "l";
        })
        (mkBind {
          mods = mainShift;
          key = "down";
          description = "Move Window Down";
          dispatcher = "movewindow";
          params = "d";
        })
        (mkBind {
          mods = mainShift;
          key = "up";
          description = "Move Window Up";
          dispatcher = "movewindow";
          params = "u";
        })
        (mkBind {
          mods = mainShift;
          key = "right";
          description = "Move Window Right";
          dispatcher = "movewindow";
          params = "r";
        })
        (mkBind {
          mods = mainShift;
          key = "H";
          description = "Move Window Left";
          dispatcher = "movewindow";
          params = "l";
        })
        (mkBind {
          mods = mainShift;
          key = "J";
          description = "Move Window Down";
          dispatcher = "movewindow";
          params = "d";
        })
        (mkBind {
          mods = mainShift;
          key = "K";
          description = "Move Window Up";
          dispatcher = "movewindow";
          params = "u";
        })
        (mkBind {
          mods = mainShift;
          key = "L";
          description = "Move Window Right";
          dispatcher = "movewindow";
          params = "r";
        })
        (mkBind {
          mods = mainMod;
          key = "Home";
          description = "Focus First Window";
          dispatcher = "focuswindow";
          params = "first";
        })
        (mkBind {
          mods = mainMod;
          key = "End";
          description = "Focus Last Window";
          dispatcher = "focuswindow";
          params = "last";
        })
        (mkBind {
          mods = mainCtrl;
          key = "left";
          description = "Focus Monitor Left";
          dispatcher = "focusmonitor";
          params = "l";
        })
        (mkBind {
          mods = mainCtrl;
          key = "right";
          description = "Focus Monitor Right";
          dispatcher = "focusmonitor";
          params = "r";
        })
        (mkBind {
          mods = mainCtrl;
          key = "H";
          description = "Focus Monitor Left";
          dispatcher = "focusmonitor";
          params = "l";
        })
        (mkBind {
          mods = mainCtrl;
          key = "J";
          description = "Focus Monitor Down";
          dispatcher = "focusmonitor";
          params = "d";
        })
        (mkBind {
          mods = mainCtrl;
          key = "K";
          description = "Focus Monitor Up";
          dispatcher = "focusmonitor";
          params = "u";
        })
        (mkBind {
          mods = mainCtrl;
          key = "L";
          description = "Focus Monitor Right";
          dispatcher = "focusmonitor";
          params = "r";
        })
        (mkBind {
          mods = mainShiftCtrl;
          key = "left";
          description = "Move Window To Left Monitor";
          dispatcher = "movewindow";
          params = "mon:l";
        })
        (mkBind {
          mods = mainShiftCtrl;
          key = "down";
          description = "Move Window To Lower Monitor";
          dispatcher = "movewindow";
          params = "mon:d";
        })
        (mkBind {
          mods = mainShiftCtrl;
          key = "up";
          description = "Move Window To Upper Monitor";
          dispatcher = "movewindow";
          params = "mon:u";
        })
        (mkBind {
          mods = mainShiftCtrl;
          key = "right";
          description = "Move Window To Right Monitor";
          dispatcher = "movewindow";
          params = "mon:r";
        })
        (mkBind {
          mods = mainShiftCtrl;
          key = "H";
          description = "Move Window To Left Monitor";
          dispatcher = "movewindow";
          params = "mon:l";
        })
        (mkBind {
          mods = mainShiftCtrl;
          key = "J";
          description = "Move Window To Lower Monitor";
          dispatcher = "movewindow";
          params = "mon:d";
        })
        (mkBind {
          mods = mainShiftCtrl;
          key = "K";
          description = "Move Window To Upper Monitor";
          dispatcher = "movewindow";
          params = "mon:u";
        })
        (mkBind {
          mods = mainShiftCtrl;
          key = "L";
          description = "Move Window To Right Monitor";
          dispatcher = "movewindow";
          params = "mon:r";
        })
        (mkBind {
          mods = mainMod;
          key = "Page_Down";
          description = "Next Workspace";
          dispatcher = "workspace";
          params = "e+1";
        })
        (mkBind {
          mods = mainMod;
          key = "Page_Up";
          description = "Previous Workspace";
          dispatcher = "workspace";
          params = "e-1";
        })
        (mkBind {
          mods = mainMod;
          key = "U";
          description = "Next Workspace";
          dispatcher = "workspace";
          params = "e+1";
        })
        (mkBind {
          mods = mainMod;
          key = "I";
          description = "Previous Workspace";
          dispatcher = "workspace";
          params = "e-1";
        })
        (mkBind {
          mods = mainCtrl;
          key = "down";
          description = "Send Window To Next Workspace";
          dispatcher = "movetoworkspace";
          params = "e+1";
        })
        (mkBind {
          mods = mainCtrl;
          key = "up";
          description = "Send Window To Previous Workspace";
          dispatcher = "movetoworkspace";
          params = "e-1";
        })
        (mkBind {
          mods = mainCtrl;
          key = "U";
          description = "Send Window To Next Workspace";
          dispatcher = "movetoworkspace";
          params = "e+1";
        })
        (mkBind {
          mods = mainCtrl;
          key = "I";
          description = "Send Window To Previous Workspace";
          dispatcher = "movetoworkspace";
          params = "e-1";
        })
        (mkBind {
          mods = mainShift;
          key = "Page_Down";
          description = "Move Window To Next Workspace";
          dispatcher = "movetoworkspace";
          params = "e+1";
        })
        (mkBind {
          mods = mainShift;
          key = "Page_Up";
          description = "Move Window To Previous Workspace";
          dispatcher = "movetoworkspace";
          params = "e-1";
        })
        (mkBind {
          mods = mainShift;
          key = "U";
          description = "Move Window To Next Workspace";
          dispatcher = "movetoworkspace";
          params = "e+1";
        })
        (mkBind {
          mods = mainShift;
          key = "I";
          description = "Move Window To Previous Workspace";
          dispatcher = "movetoworkspace";
          params = "e-1";
        })
        (mkBind {
          mods = mainMod;
          key = "mouse_down";
          description = "Next Workspace";
          dispatcher = "workspace";
          params = "e+1";
        })
        (mkBind {
          mods = mainMod;
          key = "mouse_up";
          description = "Previous Workspace";
          dispatcher = "workspace";
          params = "e-1";
        })
        (mkBind {
          mods = mainCtrl;
          key = "mouse_down";
          description = "Send Window To Next Workspace";
          dispatcher = "movetoworkspace";
          params = "e+1";
        })
        (mkBind {
          mods = mainCtrl;
          key = "mouse_up";
          description = "Send Window To Previous Workspace";
          dispatcher = "movetoworkspace";
          params = "e-1";
        })
        (mkBind {
          mods = mainMod;
          key = "bracketleft";
          description = "Preselect Left Column";
          dispatcher = "layoutmsg";
          params = "preselect l";
        })
        (mkBind {
          mods = mainMod;
          key = "bracketright";
          description = "Preselect Right Column";
          dispatcher = "layoutmsg";
          params = "preselect r";
        })
        (mkBind {
          mods = mainMod;
          key = "R";
          description = "Toggle Split";
          dispatcher = "layoutmsg";
          params = "togglesplit";
        })
        (mkBind {
          mods = mainCtrl;
          key = "F";
          description = "Reset Window Size";
          dispatcher = "resizeactive";
          params = "exact 100%";
        })
        (mkBind {
          mods = mainMod;
          key = "code:20";
          description = "Expand Window Left";
          dispatcher = "resizeactive";
          params = "-100 0";
        })
        (mkBind {
          mods = mainMod;
          key = "code:21";
          description = "Shrink Window Left";
          dispatcher = "resizeactive";
          params = "100 0";
        })
        (mkBind {
          mods = mainShift;
          key = "P";
          description = "Toggle DPMS";
          dispatcher = "dpms";
          params = "toggle";
        })
        (mkBind {
          mods = altMod;
          key = "mouse_down";
          description = "Zoom In";
          dispatcher = "exec";
          params = zoomInCommand;
        })
        (mkBind {
          mods = altMod;
          key = "mouse_up";
          description = "Zoom Out";
          dispatcher = "exec";
          params = zoomOutCommand;
        })
        (mkBind {
          mods = altMod;
          key = "0";
          description = "Reset Zoom";
          dispatcher = "exec";
          params = zoomResetCommand;
        })
      ] ++ workspaceBinds ++ moveToWorkspaceBinds;
      bindde = [
        (mkBind {
          mods = mainMod;
          key = "minus";
          description = "Resize Narrower";
          dispatcher = "resizeactive";
          params = "-10% 0";
        })
        (mkBind {
          mods = mainMod;
          key = "equal";
          description = "Resize Wider";
          dispatcher = "resizeactive";
          params = "10% 0";
        })
        (mkBind {
          mods = mainShift;
          key = "minus";
          description = "Resize Shorter";
          dispatcher = "resizeactive";
          params = "0 -10%";
        })
        (mkBind {
          mods = mainShift;
          key = "equal";
          description = "Resize Taller";
          dispatcher = "resizeactive";
          params = "0 10%";
        })
        (mkBind {
          mods = altMod;
          key = "equal";
          description = "Zoom In";
          dispatcher = "exec";
          params = zoomInCommand;
        })
        (mkBind {
          mods = altMod;
          key = "minus";
          description = "Zoom Out";
          dispatcher = "exec";
          params = zoomOutCommand;
        })
      ];
      binddm = [
        (mkBind {
          mods = mainMod;
          key = "mouse:272";
          description = "Move Window";
          dispatcher = "movewindow";
          includeEmptyParam = false;
        })
        (mkBind {
          mods = mainMod;
          key = "mouse:273";
          description = "Resize Window";
          dispatcher = "resizewindow";
          includeEmptyParam = false;
        })
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
