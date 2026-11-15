{ inputs, ... }:

{
  flake.modules.nixos.desktop-hyprland =
    { lib, pkgs, ... }:
    {
      programs.hyprland = {
        enable = true;
        xwayland.enable = true;
        withUWSM = true;
      };

      # Use Hyprland's built-in UWSM session and let Dux remember whichever
      # session was chosen last, while still defaulting system-side to UWSM.
      services.displayManager.defaultSession = "hyprland-uwsm";

      # Some KDE utilities launched under Hyprland still look for the generic
      # applications.menu instead of honoring XDG_MENU_PREFIX=plasma-.
      environment.etc."xdg/menus/applications.menu".source =
        "${pkgs.kdePackages.plasma-workspace}/etc/xdg/menus/plasma-applications.menu";

      xdg.portal = {
        enable = true;
        xdgOpenUsePortal = false;
        extraPortals = lib.mkForce (
          with pkgs;
          [
            xdg-desktop-portal-hyprland
            kdePackages.xdg-desktop-portal-kde
          ]
        );
        config = {
          common = {
            default = [ "hyprland" ];
            "org.freedesktop.impl.portal.FileChooser" = [
              "kde"
            ];
          };
          hyprland = {
            default = [ "hyprland" ];
            "org.freedesktop.impl.portal.FileChooser" = [
              "kde"
            ];
          };
        };
      };
    };

  flake.modules.homeManager.desktop-hyprland =
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
      imports = with inputs.self.modules.homeManager; [
        desktop-dux
      ];

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
          "config.workspace-routing" = {
            content = ./lua/workspace-routing.lua;
            autoLoad = false;
          };
        };
      };
    };
}
