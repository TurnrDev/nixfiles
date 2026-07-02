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

  home.packages = [ pkgs.lua ];

  xdg.portal = {
    enable = true;

    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      kdePackages.xdg-desktop-portal-kde
      kdePackages.plasma-workspace
    ];

    config = {
      common = {
        default = [ "hyprland" "kde" "plasmanotify" ];

        "org.freedesktop.impl.portal.Lockdown" = [ "none" ];
        "org.freedesktop.impl.portal.Notification" = [ "plasmanotify" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "kde" ];
        "org.freedesktop.impl.portal.AppChooser" = [ "kde" ];
      };

      hyprland = {
        default = [ "hyprland" "kde" "plasmanotify" ];

        "org.freedesktop.impl.portal.Lockdown" = [ "none" ];
        "org.freedesktop.impl.portal.Notification" = [ "plasmanotify" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "kde" ];
        "org.freedesktop.impl.portal.AppChooser" = [ "kde" ];
      };
    };
  };

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
