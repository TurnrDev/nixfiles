{ lib, ... }:
{
  # Startup hooks for Hyprland's Lua config.
  #
  # In the Lua config path we prefer `settings.on` with the `hyprland.start`
  # event instead of hyprlang's `exec-once`. Add one handler object per hook.
  #
  # Usage:
  # wayland.windowManager.hyprland.settings.on = [
  #   {
  #     _args = [
  #       "hyprland.start"
  #       (lib.generators.mkLuaInline ''
  #         function()
  #           hl.exec_cmd("[workspace 3 silent] uwsm app -- slack")
  #           hl.exec_cmd("uwsm app -- nm-applet")
  #         end
  #       '')
  #     ];
  #   }
  # ];
  wayland.windowManager.hyprland.settings.on = [ ];
}
