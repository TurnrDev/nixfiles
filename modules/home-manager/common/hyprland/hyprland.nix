{
  lib,
  osConfig,
  pkgs,
  ...
}:

let
  toLua = lib.generators.toLua { };
  generated = {
    pkgs = {
      jq = lib.getExe pkgs.jq;
      setxkbmap = lib.getExe' pkgs.setxkbmap "setxkbmap";
    };
    xwayland = {
      inherit (osConfig.services.xserver.xkb) layout variant;
    };
  };
in
{
  imports = [ ../dms/dms.nix ];

  home.packages = [
    pkgs.lua
    pkgs.bibata-cursors
  ];

  home.pointerCursor = {
    enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # Let NixOS own XDG portal services/config for this host. Keeping a second
  # Home Manager portal configuration in the same session makes debugging much
  # harder and risks duplicate backend registrations.
  xdg.portal.enable = lib.mkForce false;

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    configType = "lua";
    settings = { };

    extraConfig = ''
      require("generated")
      require("config.core")

      -- DMS owns these writable visual fragments. Monitor configuration remains
      -- Nix-backed by config.core, with DMS outputs taking runtime precedence.
      require("dms.colors")
      require("dms.layout")
      require("dms.outputs")
      require("dms.cursor")

      require("config.rules")
      require("config.binds")

      -- User-managed rules from DMS take final precedence.
      require("dms.windowrules")
    '';

    extraLuaFiles = {
      generated = {
        content = ''
          _G.nix = ${toLua generated}
        '';
        autoLoad = false;
      };

      "config.core" = {
        content = ./lua/core.lua;
        autoLoad = false;
      };
      "config.binds" = {
        content = ./lua/binds.lua;
        autoLoad = false;
      };
      "config.rules" = {
        content = ./lua/rules.lua;
        autoLoad = false;
      };
    };
  };
}
