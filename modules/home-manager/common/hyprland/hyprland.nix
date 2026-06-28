{
  lib,
  osConfig,
  pkgs,
  ...
}:

let
  toLua = lib.generators.toLua { };
  generated = {
    monitors = osConfig.my.hyprland.monitors;
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

  home.packages = [ pkgs.lua ];

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    configType = "lua";
    settings = { };

    extraLuaFiles = {
      generated = {
        content = ''
          _G.nix = ${toLua generated}
        '';
        autoLoad = false;
      };

      "config.init" = ./lua/init.lua;
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
