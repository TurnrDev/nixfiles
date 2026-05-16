{ lib }:

# Helper constructors for `wayland.windowManager.hyprland.settings.bind`.
#
# This module exists to keep bind definitions in `binds.nix` readable while still
# generating native Hyprland Lua through Home Manager's `configType = "lua"`
# support.
#
# Usage:
# - Use `keyCombo` to build documented Hyprland key strings such as
#   `SUPER + Q` or `SUPER SHIFT + 1`.
# - Use `mkLuaBind` for native dispatcher calls written as Lua, for example
#   `hl.dsp.window.close()`.
# - Use `mkExecBind` for shell commands that should run through
#   `hl.dsp.exec_cmd(...)`.
# - Use the shared modifier aliases (`mainMod`, `mainShift`, `mainCtrl`, ...)
#   so bind call sites stay consistent.
#
# Example:
# let
#   bindUtils = import ./bind-utils.nix { inherit lib; };
# in
# {
#   wayland.windowManager.hyprland.settings.bind = [
#     (bindUtils.mkLuaBind {
#       key = bindUtils.keyCombo bindUtils.mainMod "Q";
#       description = "Close Window";
#       action = "hl.dsp.window.close()";
#     })
#     (bindUtils.mkExecBind {
#       key = bindUtils.keyCombo bindUtils.mainMod "T";
#       description = "Launch Terminal";
#       command = "ghostty";
#     })
#   ];
# }
#
# Temporary DMS note:
# DMS still parses a hyprlang-style `hyprland.conf` for keybind discovery, so
# these helpers currently attach `_dms` metadata alongside the real Lua bind
# definition. Hyprland itself uses only the Lua bind output.

let
  toLua = lib.generators.toLua { };
  mkLuaInline = lib.generators.mkLuaInline;

  mkArgs =
    {
      key,
      action,
      description ? null,
      flags ? { },
    }:
    let
      bindFlags = flags // lib.optionalAttrs (description != null) { inherit description; };
    in
    [
      key
      (mkLuaInline action)
    ]
    ++ lib.optional (bindFlags != { }) bindFlags;
in
rec {
  # Shared modifier aliases and bind constructors for Hyprland's Lua config.
  # These helpers keep call sites readable while still generating native
  # `hl.bind(...)` expressions.
  mainMod = "SUPER";

  altMod = "${mainMod} ALT";
  mainShift = "${mainMod} SHIFT";
  mainCtrl = "${mainMod} CTRL";
  mainShiftCtrl = "${mainMod} SHIFT CTRL";
  ctrlAlt = "CTRL ALT";
  ctrlShift = "CTRL SHIFT";

  keyCombo =
    mods: key:
    if mods == "" then
      key
    else
      "${lib.concatStringsSep " + " (lib.splitString " " mods)} + ${key}";

  mkLuaBind =
    {
      key,
      action,
      description ? null,
      flags ? { },
      dmsDispatcher ? "lua", # TODO: Delete this parameter once DMS reads bind metadata from native `hyprland.lua` or `hyprctl binds -j`; until then the compatibility `hyprland.conf` mirror still needs an explicit legacy dispatcher name.
      dmsParams ? action, # TODO: Delete this parameter at the same time as `dmsDispatcher`; it exists only so the compatibility `hyprland.conf` mirror can print legacy dispatcher arguments for DMS.
    }:
    {
      _args = mkArgs {
        inherit key action description flags;
      };
      _dms = { # TODO: Delete this entire attrset once DMS no longer parses a synthetic `hyprland.conf` file for Hyprland keybind discovery; every field below exists only for the temporary mirror generator in `modules/home-manager/common/dms/dms.nix`.
        inherit key flags;
        description = if description == null then "" else description;
        dispatcher = dmsDispatcher;
        params = dmsParams;
      };
    };

  mkExecBind =
    {
      key,
      command,
      description ? null,
      flags ? { },
    }:
    mkLuaBind {
      inherit key description flags;
      dmsDispatcher = "exec";
      dmsParams = command;
      action = "hl.dsp.exec_cmd(${toLua command})";
    };
}
