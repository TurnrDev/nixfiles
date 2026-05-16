{ lib, ... }:

# Primary Hyprland keybind definitions.
#
# This module defines `wayland.windowManager.hyprland.settings.bind` using the
# native Lua bind helpers from `bind-utils.nix`. Add compositor actions with
# `mkActionBind` and external commands with `mkShellBind`.
#
# Usage:
# - `mods` is written as space-separated modifier aliases, for example
#   `mainMod`, `mainShift`, or `mainShiftCtrl`.
# - `key` should match the documented Hyprland key name directly, for example
#   `Q`, `Page_Down`, `SUPER_L`, `mouse:272`, or `XF86AudioMute`.
# - `flags` maps to Hyprland bind options such as `release`, `repeating`,
#   `locked`, or `mouse`.
# - `action` strings are native Lua dispatcher calls, typically `hl.dsp.*(...)`.
# - `command` strings are external commands executed via `hl.dsp.exec_cmd(...)`.
#
# Example:
# (mkActionBind {
#   mods = mainMod;
#   key = "Q";
#   description = "Close Window";
#   action = "hl.dsp.window.close()";
# })
#
# (mkShellBind {
#   mods = mainMod;
#   key = "T";
#   description = "Launch Terminal";
#   command = "ghostty";
# })

let
  bindUtils = import ./bind-utils.nix { inherit lib; };
  inherit (bindUtils)
    altMod
    keyCombo
    mainCtrl
    mainMod
    mainShift
    mainShiftCtrl
    mkExecBind
    mkLuaBind
    ;

  mkActionBind =
    {
      mods ? "",
      key,
      description,
      action,
      flags ? { },
    }:
    mkLuaBind {
      key = keyCombo mods key;
      inherit action description flags;
    };

  mkShellBind =
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
    mkActionBind {
      mods = mainMod;
      key = n;
      description = "Workspace ${n}";
      action = ''hl.dsp.focus({ workspace = "${n}" })'';
    }
  ) workspaceNumbers;

  moveToWorkspaceBinds = builtins.map (
    n:
    mkActionBind {
      mods = mainShift;
      key = n;
      description = "Move Window To Workspace ${n}";
      action = ''hl.dsp.window.move({ workspace = "${n}" })'';
    }
  ) workspaceNumbers;

  zoomInCommand =
    "hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor -j | jq '.float * 1.1')";
  zoomOutCommand =
    "hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor -j | jq '(.float / 1.1) | if . < 1 then 1 else . end')";
  zoomResetCommand = "hyprctl -q keyword cursor:zoom_factor 1";
in
{
  wayland.windowManager.hyprland.settings.bind =
    [
      (mkShellBind {
        mods = mainMod;
        key = "SUPER_L";
        description = "Launch Spotlight";
        command = "dms ipc call spotlight toggle";
        flags.release = true;
      })
      (mkShellBind {
        mods = mainMod;
        key = "SUPER_R";
        description = "Launch Spotlight";
        command = "dms ipc call spotlight toggle";
        flags.release = true;
      })
      (mkShellBind {
        mods = mainMod;
        key = "W";
        description = "Launch Firefox";
        command = "uwsm app -- firefox";
      })
      (mkShellBind {
        mods = mainMod;
        key = "C";
        description = "Launch IDE";
        command = "uwsm app -- code";
      })
      (mkShellBind {
        mods = mainMod;
        key = "G";
        description = "Launch Git Client";
        command = "uwsm app -- gitkraken";
      })
      (mkShellBind {
        mods = mainMod;
        key = "T";
        description = "Launch Terminal";
        command = "ghostty";
      })
      (mkShellBind {
        mods = mainShift;
        key = "E";
        description = "Exit Hyprland";
        command = "uwsm stop";
      })
      (mkActionBind {
        mods = mainMod;
        key = "Q";
        description = "Close Window";
        action = "hl.dsp.window.close()";
      })
      (mkActionBind {
        mods = mainMod;
        key = "F";
        description = "Enter Fullscreen";
        action = ''hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })'';
      })
      (mkActionBind {
        mods = mainShift;
        key = "F";
        description = "Exit Fullscreen";
        action = ''hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" })'';
      })
      (mkActionBind {
        mods = mainShift;
        key = "T";
        description = "Toggle Floating";
        action = ''hl.dsp.window.float({ action = "toggle" })'';
      })
      (mkActionBind {
        mods = mainMod;
        key = "Home";
        description = "Focus First Window";
        action = ''hl.dsp.focus({ window = "first" })'';
      })
      (mkActionBind {
        mods = mainMod;
        key = "End";
        description = "Focus Last Window";
        action = "hl.dsp.focus({ last = true })";
      })
      (mkActionBind {
        mods = mainMod;
        key = "Page_Down";
        description = "Next Workspace";
        action = ''hl.dsp.focus({ workspace = "e+1" })'';
      })
      (mkActionBind {
        mods = mainMod;
        key = "Page_Up";
        description = "Previous Workspace";
        action = ''hl.dsp.focus({ workspace = "e-1" })'';
      })
      (mkActionBind {
        mods = mainMod;
        key = "U";
        description = "Next Workspace";
        action = ''hl.dsp.focus({ workspace = "e+1" })'';
      })
      (mkActionBind {
        mods = mainMod;
        key = "I";
        description = "Previous Workspace";
        action = ''hl.dsp.focus({ workspace = "e-1" })'';
      })
      (mkActionBind {
        mods = mainCtrl;
        key = "down";
        description = "Send Window To Next Workspace";
        action = ''hl.dsp.window.move({ workspace = "e+1" })'';
      })
      (mkActionBind {
        mods = mainCtrl;
        key = "up";
        description = "Send Window To Previous Workspace";
        action = ''hl.dsp.window.move({ workspace = "e-1" })'';
      })
      (mkActionBind {
        mods = mainCtrl;
        key = "U";
        description = "Send Window To Next Workspace";
        action = ''hl.dsp.window.move({ workspace = "e+1" })'';
      })
      (mkActionBind {
        mods = mainCtrl;
        key = "I";
        description = "Send Window To Previous Workspace";
        action = ''hl.dsp.window.move({ workspace = "e-1" })'';
      })
      (mkActionBind {
        mods = mainShift;
        key = "Page_Down";
        description = "Move Window To Next Workspace";
        action = ''hl.dsp.window.move({ workspace = "e+1" })'';
      })
      (mkActionBind {
        mods = mainShift;
        key = "Page_Up";
        description = "Move Window To Previous Workspace";
        action = ''hl.dsp.window.move({ workspace = "e-1" })'';
      })
      (mkActionBind {
        mods = mainShift;
        key = "U";
        description = "Move Window To Next Workspace";
        action = ''hl.dsp.window.move({ workspace = "e+1" })'';
      })
      (mkActionBind {
        mods = mainShift;
        key = "I";
        description = "Move Window To Previous Workspace";
        action = ''hl.dsp.window.move({ workspace = "e-1" })'';
      })
      (mkActionBind {
        mods = mainMod;
        key = "mouse_down";
        description = "Next Workspace";
        action = ''hl.dsp.focus({ workspace = "e+1" })'';
      })
      (mkActionBind {
        mods = mainMod;
        key = "mouse_up";
        description = "Previous Workspace";
        action = ''hl.dsp.focus({ workspace = "e-1" })'';
      })
      (mkActionBind {
        mods = mainCtrl;
        key = "mouse_down";
        description = "Send Window To Next Workspace";
        action = ''hl.dsp.window.move({ workspace = "e+1" })'';
      })
      (mkActionBind {
        mods = mainCtrl;
        key = "mouse_up";
        description = "Send Window To Previous Workspace";
        action = ''hl.dsp.window.move({ workspace = "e-1" })'';
      })
      (mkActionBind {
        mods = mainMod;
        key = "bracketleft";
        description = "Preselect Left Column";
        action = ''hl.dsp.layout("preselect l")'';
      })
      (mkActionBind {
        mods = mainMod;
        key = "bracketright";
        description = "Preselect Right Column";
        action = ''hl.dsp.layout("preselect r")'';
      })
      (mkActionBind {
        mods = mainMod;
        key = "R";
        description = "Toggle Split";
        action = ''hl.dsp.layout("togglesplit")'';
      })
      (mkActionBind {
        mods = mainCtrl;
        key = "F";
        description = "Reset Window Size";
        action = "hl.dsp.window.resize({ x = 0, y = 0 })";
      })
      (mkActionBind {
        mods = mainMod;
        key = "code:20";
        description = "Expand Window Left";
        action = "hl.dsp.window.resize({ x = -100, y = 0, relative = true })";
      })
      (mkActionBind {
        mods = mainMod;
        key = "code:21";
        description = "Shrink Window Left";
        action = "hl.dsp.window.resize({ x = 100, y = 0, relative = true })";
      })
      (mkActionBind {
        mods = mainShift;
        key = "P";
        description = "Toggle DPMS";
        action = ''hl.dsp.dpms({ action = "toggle" })'';
      })
      (mkShellBind {
        mods = altMod;
        key = "mouse_down";
        description = "Zoom In";
        command = zoomInCommand;
      })
      (mkShellBind {
        mods = altMod;
        key = "mouse_up";
        description = "Zoom Out";
        command = zoomOutCommand;
      })
      (mkShellBind {
        mods = altMod;
        key = "0";
        description = "Reset Zoom";
        command = zoomResetCommand;
      })
    ]
    ++ map
      (
        spec:
        mkActionBind {
          inherit (spec) mods key description;
          action = ''hl.dsp.focus({ direction = "${spec.direction}" })'';
        }
      )
      [
        { mods = mainMod; key = "left"; description = "Focus Left"; direction = "l"; }
        { mods = mainMod; key = "down"; description = "Focus Down"; direction = "d"; }
        { mods = mainMod; key = "up"; description = "Focus Up"; direction = "u"; }
        { mods = mainMod; key = "right"; description = "Focus Right"; direction = "r"; }
        { mods = mainMod; key = "H"; description = "Focus Left"; direction = "l"; }
        { mods = mainMod; key = "J"; description = "Focus Down"; direction = "d"; }
        { mods = mainMod; key = "K"; description = "Focus Up"; direction = "u"; }
        { mods = mainMod; key = "L"; description = "Focus Right"; direction = "r"; }
      ]
    ++ map
      (
        spec:
        mkActionBind {
          inherit (spec) mods key description;
          action = ''hl.dsp.window.move({ direction = "${spec.direction}" })'';
        }
      )
      [
        { mods = mainShift; key = "left"; description = "Move Window Left"; direction = "l"; }
        { mods = mainShift; key = "down"; description = "Move Window Down"; direction = "d"; }
        { mods = mainShift; key = "up"; description = "Move Window Up"; direction = "u"; }
        { mods = mainShift; key = "right"; description = "Move Window Right"; direction = "r"; }
        { mods = mainShift; key = "H"; description = "Move Window Left"; direction = "l"; }
        { mods = mainShift; key = "J"; description = "Move Window Down"; direction = "d"; }
        { mods = mainShift; key = "K"; description = "Move Window Up"; direction = "u"; }
        { mods = mainShift; key = "L"; description = "Move Window Right"; direction = "r"; }
      ]
    ++ map
      (
        spec:
        mkActionBind {
          inherit (spec) mods key description;
          action = ''hl.dsp.focus({ monitor = "${spec.monitor}" })'';
        }
      )
      [
        { mods = mainCtrl; key = "left"; description = "Focus Monitor Left"; monitor = "l"; }
        { mods = mainCtrl; key = "right"; description = "Focus Monitor Right"; monitor = "r"; }
        { mods = mainCtrl; key = "H"; description = "Focus Monitor Left"; monitor = "l"; }
        { mods = mainCtrl; key = "J"; description = "Focus Monitor Down"; monitor = "d"; }
        { mods = mainCtrl; key = "K"; description = "Focus Monitor Up"; monitor = "u"; }
        { mods = mainCtrl; key = "L"; description = "Focus Monitor Right"; monitor = "r"; }
      ]
    ++ map
      (
        spec:
        mkActionBind {
          inherit (spec) mods key description;
          action = ''hl.dsp.window.move({ monitor = "${spec.monitor}" })'';
        }
      )
      [
        { mods = mainShiftCtrl; key = "left"; description = "Move Window To Left Monitor"; monitor = "l"; }
        { mods = mainShiftCtrl; key = "down"; description = "Move Window To Lower Monitor"; monitor = "d"; }
        { mods = mainShiftCtrl; key = "up"; description = "Move Window To Upper Monitor"; monitor = "u"; }
        { mods = mainShiftCtrl; key = "right"; description = "Move Window To Right Monitor"; monitor = "r"; }
        { mods = mainShiftCtrl; key = "H"; description = "Move Window To Left Monitor"; monitor = "l"; }
        { mods = mainShiftCtrl; key = "J"; description = "Move Window To Lower Monitor"; monitor = "d"; }
        { mods = mainShiftCtrl; key = "K"; description = "Move Window To Upper Monitor"; monitor = "u"; }
        { mods = mainShiftCtrl; key = "L"; description = "Move Window To Right Monitor"; monitor = "r"; }
      ]
    ++ workspaceBinds
    ++ moveToWorkspaceBinds
    ++ [
      (mkActionBind {
        mods = mainMod;
        key = "minus";
        description = "Resize Narrower";
        action = "hl.dsp.window.resize({ x = -10, y = 0, relative = true })";
        flags.repeating = true;
      })
      (mkActionBind {
        mods = mainMod;
        key = "equal";
        description = "Resize Wider";
        action = "hl.dsp.window.resize({ x = 10, y = 0, relative = true })";
        flags.repeating = true;
      })
      (mkActionBind {
        mods = mainShift;
        key = "minus";
        description = "Resize Shorter";
        action = "hl.dsp.window.resize({ x = 0, y = -10, relative = true })";
        flags.repeating = true;
      })
      (mkActionBind {
        mods = mainShift;
        key = "equal";
        description = "Resize Taller";
        action = "hl.dsp.window.resize({ x = 0, y = 10, relative = true })";
        flags.repeating = true;
      })
      (mkShellBind {
        mods = altMod;
        key = "equal";
        description = "Zoom In";
        command = zoomInCommand;
        flags.repeating = true;
      })
      (mkShellBind {
        mods = altMod;
        key = "minus";
        description = "Zoom Out";
        command = zoomOutCommand;
        flags.repeating = true;
      })
      (mkActionBind {
        mods = mainMod;
        key = "mouse:272";
        description = "Move Window";
        action = "hl.dsp.window.drag()";
        flags.mouse = true;
      })
      (mkActionBind {
        mods = mainMod;
        key = "mouse:273";
        description = "Resize Window";
        action = "hl.dsp.window.resize()";
        flags.mouse = true;
      })
    ];
}
