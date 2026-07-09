local function raw_dispatch(command)
  return function()
    hl.exec_cmd("hyprctl dispatch " .. command)
  end
end
-- hyprctl eval "hl.config({ cursor = { zoom_factor = $(hyprctl getoption cursor:zoom_factor | awk '/^float/ {print $2 * 0.9}') }})"

local zoom_in =
  "hyprctl eval \"hl.config({ cursor = { zoom_factor = $(hyprctl getoption cursor:zoom_factor -j | "
  .. nix.pkgs.jq
  .. " '.float * 1.1') }})\""
local zoom_out =
  "hyprctl eval \"hl.config({ cursor = { zoom_factor = $(hyprctl getoption cursor:zoom_factor -j | "
  .. nix.pkgs.jq
  .. " '(.float / 1.1) | if . < 1 then 1 else . end') }})\""

-- Applications and session management.
hl.bind("SUPER + Super_L", hl.dsp.exec_cmd("dms ipc call spotlight toggle"), { description = "Launch Spotlight" })
hl.bind("SUPER + Super_R", hl.dsp.exec_cmd("dms ipc call spotlight toggle"), { description = "Launch Spotlight" })
hl.bind("SUPER + W", hl.dsp.exec_cmd("uwsm app -- firefox"), { description = "Launch Firefox" })
hl.bind("SUPER + C", hl.dsp.exec_cmd("uwsm app -- code"), { description = "Launch IDE" })
hl.bind("SUPER + G", hl.dsp.exec_cmd("uwsm app -- gitkraken"), { description = "Launch Git Client" })
hl.bind("SUPER + T", hl.dsp.exec_cmd("uwsm app -- ghostty"), { description = "Launch Terminal" })
hl.bind("SUPER + SHIFT + E", hl.dsp.exit(), { description = "Exit Hyprland" })

-- Window management.
hl.bind("SUPER + Q", hl.dsp.window.close(), { description = "Close Window" })
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }), { description = "Enter Fullscreen" })
hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }), { description = "Exit Fullscreen" })
hl.bind("SUPER + SHIFT + T", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle Floating" })

hl.bind("SUPER + left", hl.dsp.focus({ direction = "l" }), { description = "Focus Left" })
hl.bind("SUPER + down", hl.dsp.focus({ direction = "d" }), { description = "Focus Down" })
hl.bind("SUPER + up", hl.dsp.focus({ direction = "u" }), { description = "Focus Up" })
hl.bind("SUPER + right", hl.dsp.focus({ direction = "r" }), { description = "Focus Right" })
hl.bind("SUPER + H", hl.dsp.focus({ direction = "l" }), { description = "Focus Left" })
hl.bind("SUPER + J", hl.dsp.focus({ direction = "d" }), { description = "Focus Down" })
hl.bind("SUPER + K", hl.dsp.focus({ direction = "u" }), { description = "Focus Up" })
hl.bind("SUPER + L", hl.dsp.focus({ direction = "r" }), { description = "Focus Right" })

hl.bind("SUPER + SHIFT + left", hl.dsp.window.move({ direction = "l" }), { description = "Move Window Left" })
hl.bind("SUPER + SHIFT + down", hl.dsp.window.move({ direction = "d" }), { description = "Move Window Down" })
hl.bind("SUPER + SHIFT + up", hl.dsp.window.move({ direction = "u" }), { description = "Move Window Up" })
hl.bind("SUPER + SHIFT + right", hl.dsp.window.move({ direction = "r" }), { description = "Move Window Right" })
hl.bind("SUPER + SHIFT + H", hl.dsp.window.move({ direction = "l" }), { description = "Move Window Left" })
hl.bind("SUPER + SHIFT + J", hl.dsp.window.move({ direction = "d" }), { description = "Move Window Down" })
hl.bind("SUPER + SHIFT + K", hl.dsp.window.move({ direction = "u" }), { description = "Move Window Up" })
hl.bind("SUPER + SHIFT + L", hl.dsp.window.move({ direction = "r" }), { description = "Move Window Right" })
hl.bind("SUPER + Home", hl.dsp.focus({ window = "first" }), { description = "Focus First Window" })
hl.bind("SUPER + End", hl.dsp.focus({ window = "last" }), { description = "Focus Last Window" })

-- Monitor navigation.
hl.bind("SUPER + CTRL + left", hl.dsp.focus({ monitor = "l" }), { description = "Focus Monitor Left" })
hl.bind("SUPER + CTRL + right", hl.dsp.focus({ monitor = "r" }), { description = "Focus Monitor Right" })
hl.bind("SUPER + CTRL + H", hl.dsp.focus({ monitor = "l" }), { description = "Focus Monitor Left" })
hl.bind("SUPER + CTRL + J", hl.dsp.focus({ monitor = "d" }), { description = "Focus Monitor Down" })
hl.bind("SUPER + CTRL + K", hl.dsp.focus({ monitor = "u" }), { description = "Focus Monitor Up" })
hl.bind("SUPER + CTRL + L", hl.dsp.focus({ monitor = "r" }), { description = "Focus Monitor Right" })
hl.bind("SUPER + SHIFT + CTRL + left", hl.dsp.window.move({ monitor = "l" }), { description = "Move Window To Left Monitor" })
hl.bind("SUPER + SHIFT + CTRL + down", hl.dsp.window.move({ monitor = "d" }), { description = "Move Window To Lower Monitor" })
hl.bind("SUPER + SHIFT + CTRL + up", hl.dsp.window.move({ monitor = "u" }), { description = "Move Window To Upper Monitor" })
hl.bind("SUPER + SHIFT + CTRL + right", hl.dsp.window.move({ monitor = "r" }), { description = "Move Window To Right Monitor" })
hl.bind("SUPER + SHIFT + CTRL + H", hl.dsp.window.move({ monitor = "l" }), { description = "Move Window To Left Monitor" })
hl.bind("SUPER + SHIFT + CTRL + J", hl.dsp.window.move({ monitor = "d" }), { description = "Move Window To Lower Monitor" })
hl.bind("SUPER + SHIFT + CTRL + K", hl.dsp.window.move({ monitor = "u" }), { description = "Move Window To Upper Monitor" })
hl.bind("SUPER + SHIFT + CTRL + L", hl.dsp.window.move({ monitor = "r" }), { description = "Move Window To Right Monitor" })

hl.bind("SUPER + 1", hl.dsp.focus({ workspace = "1" }), { description = "Workspace 1" })
hl.bind("SUPER + 2", hl.dsp.focus({ workspace = "2" }), { description = "Workspace 2" })
hl.bind("SUPER + 3", hl.dsp.focus({ workspace = "3" }), { description = "Workspace 3" })
hl.bind("SUPER + 4", hl.dsp.focus({ workspace = "4" }), { description = "Workspace 4" })
hl.bind("SUPER + 5", hl.dsp.focus({ workspace = "5" }), { description = "Workspace 5" })
hl.bind("SUPER + 6", hl.dsp.focus({ workspace = "6" }), { description = "Workspace 6" })
hl.bind("SUPER + 7", hl.dsp.focus({ workspace = "7" }), { description = "Workspace 7" })
hl.bind("SUPER + 8", hl.dsp.focus({ workspace = "8" }), { description = "Workspace 8" })
hl.bind("SUPER + 9", hl.dsp.focus({ workspace = "9" }), { description = "Workspace 9" })
hl.bind("SUPER + SHIFT + 1", hl.dsp.window.move({ workspace = "1" }), { description = "Move Window To Workspace 1" })
hl.bind("SUPER + SHIFT + 2", hl.dsp.window.move({ workspace = "2" }), { description = "Move Window To Workspace 2" })
hl.bind("SUPER + SHIFT + 3", hl.dsp.window.move({ workspace = "3" }), { description = "Move Window To Workspace 3" })
hl.bind("SUPER + SHIFT + 4", hl.dsp.window.move({ workspace = "4" }), { description = "Move Window To Workspace 4" })
hl.bind("SUPER + SHIFT + 5", hl.dsp.window.move({ workspace = "5" }), { description = "Move Window To Workspace 5" })
hl.bind("SUPER + SHIFT + 6", hl.dsp.window.move({ workspace = "6" }), { description = "Move Window To Workspace 6" })
hl.bind("SUPER + SHIFT + 7", hl.dsp.window.move({ workspace = "7" }), { description = "Move Window To Workspace 7" })
hl.bind("SUPER + SHIFT + 8", hl.dsp.window.move({ workspace = "8" }), { description = "Move Window To Workspace 8" })
hl.bind("SUPER + SHIFT + 9", hl.dsp.window.move({ workspace = "9" }), { description = "Move Window To Workspace 9" })

-- Layout, resize, display power, and zoom.
hl.bind("SUPER + bracketleft", hl.dsp.layout("preselect l"), { description = "Preselect Left Column" })
hl.bind("SUPER + bracketright", hl.dsp.layout("preselect r"), { description = "Preselect Right Column" })
hl.bind("SUPER + R", hl.dsp.layout("togglesplit"), { description = "Toggle Split" })
hl.bind("SUPER + code:20", hl.dsp.window.resize({ x = -100, y = 0, relative = true }), { description = "Expand Window Left" })
hl.bind("SUPER + code:21", hl.dsp.window.resize({ x = 100, y = 0, relative = true }), { description = "Shrink Window Left" })
hl.bind("SUPER + SHIFT + P", hl.dsp.dpms({ action = "toggle" }), { description = "Toggle DPMS" })
hl.bind("SUPER + mouse_down", hl.dsp.exec_cmd(zoom_in), { description = "Zoom In" })
hl.bind("SUPER + mouse_up", hl.dsp.exec_cmd(zoom_out), { description = "Zoom Out" })
hl.bind("SUPER + 0", hl.dsp.exec_cmd("hyprctl eval \"hl.config({ cursor = { zoom_factor = 1 } })\""), { description = "Reset Zoom" })
hl.bind("SUPER + equal", hl.dsp.exec_cmd(zoom_in), { description = "Zoom In", repeating = true })
hl.bind("SUPER + minus", hl.dsp.exec_cmd(zoom_out), { description = "Zoom Out", repeating = true })
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { description = "Move Window", mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { description = "Resize Window", mouse = true })

-- DMS shell actions. These stay in the repository rather than dms.binds.lua.
hl.bind("SUPER + space", hl.dsp.exec_cmd("dms ipc call spotlight toggle"), { description = "Toggle Spotlight" })
hl.bind("SUPER + V", hl.dsp.exec_cmd("dms ipc call clipboard toggle"), { description = "Toggle Clipboard" })
hl.bind("SUPER + M", hl.dsp.exec_cmd("dms ipc call processlist focusOrToggle"), { description = "Open Process List" })
hl.bind("SUPER + comma", hl.dsp.exec_cmd("dms ipc call settings focusOrToggle"), { description = "Open Settings" })
hl.bind("SUPER + N", hl.dsp.exec_cmd("dms ipc call notifications toggle"), { description = "Toggle Notifications" })
hl.bind("SUPER + SHIFT + N", hl.dsp.exec_cmd("dms ipc call notepad toggle"), { description = "Toggle Notepad" })
hl.bind("SUPER + Y", hl.dsp.exec_cmd("dms ipc call dankdash wallpaper"), { description = "Change Wallpaper" })
hl.bind("SUPER + TAB", hl.dsp.exec_cmd("dms ipc call hypr toggleOverview"), { description = "Toggle Overview" })
hl.bind("SUPER + X", hl.dsp.exec_cmd("dms ipc call powermenu toggle"), { description = "Toggle Power Menu" })
hl.bind("SUPER + SHIFT + Slash", hl.dsp.exec_cmd("dms ipc call keybinds toggle hyprland"), { description = "Show Keybinds" })
hl.bind("SUPER + L", hl.dsp.exec_cmd("dms ipc call lock lock"), { description = "Lock Session" })
hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd("dms ipc call processlist focusOrToggle"), { description = "Open Process List" })
hl.bind("CTRL + SHIFT + Escape", hl.dsp.exec_cmd("dms ipc call processlist focusOrToggle"), { description = "Open Process List" })
hl.bind("SUPER + SHIFT + W", hl.dsp.exec_cmd("dms ipc call window-rules toggle"), { description = "Toggle Window Rules" })
hl.bind("CTRL + SHIFT + R", hl.dsp.exec_cmd("dms ipc call workspace-rename open"), { description = "Rename Workspace" })
hl.bind("Print", hl.dsp.exec_cmd("dms screenshot"), { description = "Take Screenshot" })
hl.bind("CTRL + Print", hl.dsp.exec_cmd("dms screenshot full"), { description = "Take Full Screenshot" })
hl.bind("ALT + Print", hl.dsp.exec_cmd("dms screenshot window"), { description = "Take Window Screenshot" })

-- Media and brightness controls.
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("dms ipc call audio increment 3"), { description = "Raise Volume", locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("dms ipc call audio decrement 3"), { description = "Lower Volume", locked = true, repeating = true })
hl.bind("CTRL + XF86AudioRaiseVolume", hl.dsp.exec_cmd("dms ipc call mpris increment 3"), { description = "Seek Forward", locked = true, repeating = true })
hl.bind("CTRL + XF86AudioLowerVolume", hl.dsp.exec_cmd("dms ipc call mpris decrement 3"), { description = "Seek Backward", locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd([[dms ipc call brightness increment 5 ""]]), { description = "Brightness Up", locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd([[dms ipc call brightness decrement 5 ""]]), { description = "Brightness Down", locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("dms ipc call audio mute"), { description = "Mute Volume", locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("dms ipc call audio micmute"), { description = "Mute Microphone", locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("dms ipc call mpris playPause"), { description = "Play Pause Media", locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("dms ipc call mpris playPause"), { description = "Play Pause Media", locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("dms ipc call mpris previous"), { description = "Previous Track", locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("dms ipc call mpris next"), { description = "Next Track", locked = true })
