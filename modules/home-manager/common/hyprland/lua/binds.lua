local layouts = require("config.core")

local zoom_in = 'hyprctl eval "hl.config({ cursor = { zoom_factor = $(hyprctl getoption cursor:zoom_factor -j | '
	.. nix.pkgs.jq
	.. " '.float * 1.1') }})\""
local zoom_out = 'hyprctl eval "hl.config({ cursor = { zoom_factor = $(hyprctl getoption cursor:zoom_factor -j | '
	.. nix.pkgs.jq
	.. " '(.float / 1.1) | if . < 1 then 1 else . end') }})\""

-- Applications and session management.
hl.bind("SUPER + Super_L", hl.dsp.exec_cmd("dms ipc call spotlight toggle"), { description = "Launch Spotlight" })
hl.bind("SUPER + Super_R", hl.dsp.exec_cmd("dms ipc call spotlight toggle"), { description = "Launch Spotlight" })
hl.bind("SUPER + W", hl.dsp.exec_cmd("uwsm app -- firefox"), { description = "Launch Firefox" })
hl.bind("SUPER + C", hl.dsp.exec_cmd("uwsm app -- code"), { description = "Launch IDE" })
hl.bind("SUPER + T", hl.dsp.exec_cmd("uwsm app -- ghostty"), { description = "Launch Terminal" })

-- Window management.
hl.bind("SUPER + Q", hl.dsp.window.close(), { description = "Close Window" })
hl.bind(
	"SUPER + F",
	hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }),
	{ description = "Maximise Window" }
)
hl.bind(
	"SUPER + SHIFT + F",
	hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }),
	{ description = "Toggle Fullscreen" }
)
hl.bind(
	"SUPER + CTRL + F",
	hl.dsp.window.fullscreen_state({
		internal = 0,
		client = 2,
		action = "toggle",
	}),
	{ description = "Toggle Fake Fullscreen" }
)
hl.bind(
	"SUPER + CTRL + SHIFT + F",
	hl.dsp.window.fullscreen_state({
		internal = 2,
		client = 0,
		action = "toggle",
	}),
	{ description = "Toggle Fullscreen Without Notifying Client" }
)
hl.bind("SUPER + SHIFT + T", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle Floating" })
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
hl.bind("SUPER + F12", hl.dsp.exec_cmd("dockmgr once"), { description = "Apply DockMgr Profile" }) -- Used regularly
hl.bind("SUPER + bracketleft", layouts.dwindle, { description = "Switch To Dwindle Layout" })
hl.bind("SUPER + bracketright", layouts.master, { description = "Switch To Centred Master Layout" })
hl.bind("SUPER + SHIFT + bracketleft", function()
	layouts.master(layouts.ratios.one_to_two_to_one)
end, { description = "Centred Master Layout (1:2:1)" })
hl.bind("SUPER + SHIFT + bracketright", function()
	layouts.master(layouts.ratios.two_to_three_to_two)
end, { description = "Centred Master Layout (2:3:2)" })
hl.bind("SUPER + M", hl.dsp.layout("swapwithmaster master"), { description = "Make Focused Window Master" })

-- Zoom zoom. Used infrequently, but loved when used. Keep.
hl.bind("SUPER + mouse_up", hl.dsp.exec_cmd(zoom_in), { description = "Zoom In" })
hl.bind("SUPER + mouse_down", hl.dsp.exec_cmd(zoom_out), { description = "Zoom Out" })
hl.bind(
	"SUPER + 0",
	hl.dsp.exec_cmd('hyprctl eval "hl.config({ cursor = { zoom_factor = 1 } })"'),
	{ description = "Reset Zoom" }
)
hl.bind("SUPER + equal", hl.dsp.exec_cmd(zoom_in), { description = "Zoom In", repeating = true })
hl.bind("SUPER + minus", hl.dsp.exec_cmd(zoom_out), { description = "Zoom Out", repeating = true })
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { description = "Move Window", mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { description = "Resize Window", mouse = true })

-- Dux shell actions. The v2 executable remains `dms` for compatibility.
hl.bind("SUPER + TAB", hl.dsp.exec_cmd("dms ipc call hypr toggleOverview"), { description = "Toggle Overview" })
hl.bind("SUPER + Slash", hl.dsp.exec_cmd("dms ipc call keybinds toggle hyprland"), { description = "Show Keybinds" })
hl.bind("SUPER + L", hl.dsp.exec_cmd("dms ipc call lock lock"), { description = "Lock Session" })
hl.bind(
	"CTRL + SHIFT + Escape",
	hl.dsp.exec_cmd("dms ipc call processlist focusOrToggle"),
	{ description = "Open Process List" }
)
hl.bind("Print", hl.dsp.exec_cmd("dms screenshot"), { description = "Take Screenshot" })
hl.bind("CTRL + Print", hl.dsp.exec_cmd("dms screenshot full"), { description = "Take Full Screenshot" })
hl.bind("ALT + Print", hl.dsp.exec_cmd("dms screenshot window"), { description = "Take Window Screenshot" })

-- Media and brightness controls.
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("dms ipc call audio increment 3"),
	{ description = "Raise Volume", locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("dms ipc call audio decrement 3"),
	{ description = "Lower Volume", locked = true, repeating = true }
)
hl.bind(
	"CTRL + XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("dms ipc call mpris increment 3"),
	{ description = "Seek Forward", locked = true, repeating = true }
)
hl.bind(
	"CTRL + XF86AudioLowerVolume",
	hl.dsp.exec_cmd("dms ipc call mpris decrement 3"),
	{ description = "Seek Backward", locked = true, repeating = true }
)
hl.bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd([[dms ipc call brightness increment 5 ""]]),
	{ description = "Brightness Up", locked = true, repeating = true }
)
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd([[dms ipc call brightness decrement 5 ""]]),
	{ description = "Brightness Down", locked = true, repeating = true }
)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("dms ipc call audio mute"), { description = "Mute Volume", locked = true })
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("dms ipc call audio micmute"),
	{ description = "Mute Microphone", locked = true }
)
hl.bind(
	"XF86AudioPause",
	hl.dsp.exec_cmd("dms ipc call mpris playPause"),
	{ description = "Play Pause Media", locked = true }
)
hl.bind(
	"XF86AudioPlay",
	hl.dsp.exec_cmd("dms ipc call mpris playPause"),
	{ description = "Play Pause Media", locked = true }
)
hl.bind(
	"XF86AudioPrev",
	hl.dsp.exec_cmd("dms ipc call mpris previous"),
	{ description = "Previous Track", locked = true }
)
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("dms ipc call mpris next"), { description = "Next Track", locked = true })
