{ config, pkgs, lib, nixpkgs-staging, ... }:

with config.lib.stylix.colors.withHashtag;
{
  home.packages = with pkgs; [
    playerctl
  ];
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    systemd.target = "hyprland-session.target";
  };
  systemd.user.services.waybar.Unit.ConditionEnvironment = lib.mkForce [
    "WAYLAND_DISPLAY"
    "HYPRLAND_INSTANCE_SIGNATURE"
  ];
  programs.waybar.settings = {
    mainBar = {
      layer = "top";
      position = "top";
      height = 32;
      modules-left = [ "mpris" ];
      modules-center = [ "hyprland/workspaces" ];
      modules-right = [ "tray" "wireplumber" "backlight" "battery" "clock" ];
      clock = {
        format = "{:%d %b %Y - %H:%M}";
      };
      mpris = {
        format = "{dynamic}";
        title-len = 60;
        ellipsis = "...";
        dynamic-order = ["artist" "title"];
      };
      wireplumber = {
        format = "{icon} {volume}%";
        format-muted = "";
        on-click = "pwvucontrol";
        format-icons = ["" "" ""];
      };
      backlight = {
        format = "{icon} {percent}%";
        format-icons = ["" ""];
      };
      battery = {
        interval = 2;
        states = {
          warning = 20;
          critical = 10;
        };
        format = "{icon} {capacity}%";
        format-charging = " {capacity}%";
        format-icons = ["" "" "" "" ""];
        max-length = 25;
      };
      tray = {
        spacing = 5;
        icon-size = 21;
      };
      "hyprland/workspaces" = {
        all-outputs = true;
      };
    };
  };
  programs.waybar.style = lib.mkForce ''
@define-color base00 ${base00}; @define-color base01 ${base01}; @define-color base02 ${base02}; @define-color base03 ${base03};
@define-color base04 ${base04}; @define-color base05 ${base05}; @define-color base06 ${base06}; @define-color base07 ${base07};

@define-color base08 ${base08}; @define-color base09 ${base09}; @define-color base0A ${base0A}; @define-color base0B ${base0B};
@define-color base0C ${base0C}; @define-color base0D ${base0D}; @define-color base0E ${base0E}; @define-color base0F ${base0F};

@define-color text ${base05};
@define-color text-strong ${base06};
@define-color accent ${base0B};
@define-color accent-strong ${base0D};
@define-color surface ${base01};
@define-color surface-2 ${base02};
@define-color border ${base03};

* {
  border: none;
  font-family: '${config.stylix.fonts.sansSerif.name}', '${config.stylix.fonts.emoji.name}', 'Symbols Nerd Font Mono';
  font-size: 16px;
  min-height: 0;
}

window#waybar {
  background: alpha(@base00, 0);
  color: @text;
}

#mpris, #workspaces, #tray, #wireplumber, #backlight, #battery, #clock {
  background-color: alpha(@surface, 0.95);
  border: 1px solid alpha(@border, 0.75);
  border-radius: 12px;
  color: @text;
  margin-top: 5px;
  padding-left: 12px;
  padding-right: 12px;
}

#mpris {
  margin-left: 10px;
  margin-right: 15px;
  min-width: 220px;
}

#workspaces {
  margin-right: 15px;
  padding-left: 6px;
  padding-right: 6px;
}

#workspaces button {
  background: transparent;
  border-radius: 10px;
  color: @base04;
  padding-left: 8px;
  padding-right: 8px;
}

#workspaces button:hover {
  background: @surface-2;
  color: @text-strong;
}

#workspaces button.active {
  background: @accent;
  color: @base00;
}

#tray, #wireplumber, #backlight, #battery, #clock {
  margin-right: 10px;
}

#battery.warning {
  color: @base09;
}

#battery.critical {
  color: @base08;
}
  '';
}
