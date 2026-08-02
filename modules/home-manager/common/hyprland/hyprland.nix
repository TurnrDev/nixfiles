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
  ];

  # Let NixOS own XDG portal services/config for this host. Keeping a second
  # Home Manager portal configuration in the same session makes debugging much
  # harder and risks duplicate backend registrations.
  xdg.portal.enable = lib.mkForce false;

  wayland.windowManager.hyprland = {
    enable = true;
    # UWSM owns the graphical-session.target and D-Bus activation environment.
    # Home Manager's integration conflicts with that ownership.
    systemd.enable = false;
    configType = "lua";
    settings = { };

    extraConfig = ''
      require("generated")
      require("config.core")

      -- Keep only DMS's writable monitor overrides. The rest remains
      -- declaratively owned by Nix/Home Manager.
      require("dms.outputs")

      require("config.rules")
      require("config.binds")
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
