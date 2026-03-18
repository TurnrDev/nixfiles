{ config, pkgs, lib, ... }:

with config.lib.stylix.colors.withHashtag;
{
  home.packages = with pkgs; [
    playerctl
    pwvucontrol
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
      height = 40;
      margin = "10 16 0 16";
      spacing = 10;
      fixed-center = true;
      modules-left = [ "mpris" ];
      modules-center = [ "hyprland/workspaces" "hyprland/window" ];
      modules-right = [ "network" "bluetooth" "wireplumber" "backlight" "battery" "tray" "clock" ];
      clock = {
        format = "  {:%a %d %b  %H:%M}";
        format-alt = "󰃭  {:%Y-%m-%d}";
      };
      mpris = {
        format = "{player_icon} {dynamic}";
        format-paused = "{status_icon} {dynamic}";
        dynamic-len = 36;
        artist-len = 18;
        title-len = 28;
        ellipsis = "...";
        dynamic-order = [ "artist" "title" ];
        player-icons = {
          default = "";
          firefox = "";
          mpv = "󰐹";
          spotify = "";
        };
        status-icons = {
          paused = "";
          playing = "";
          stopped = "";
        };
      };
      network = {
        family = "ipv4_6";
        interval = 5;
        format-wifi = "󰖩  {signalStrength}%";
        format-ethernet = "󰈀  Wired";
        format-linked = "󰈀  Linked";
        format-disconnected = "󰖪  Offline";
        format-disabled = "󰖪  Off";
        tooltip-format-wifi = "{essid}\n{ipaddr}";
        tooltip-format-ethernet = "{ifname}\n{ipaddr}";
        max-length = 16;
      };
      bluetooth = {
        format = "󰂯  {status}";
        format-disabled = "󰂲  Off";
        format-off = "󰂲  Off";
        format-on = "󰂯  On";
        format-connected = "󰂱  {device_alias}";
        format-connected-battery = "󰂱  {device_alias} {device_battery_percentage}%";
        format-no-controller = "󰂲";
        tooltip-format-connected = "{controller_alias}\n{device_enumerate}";
        tooltip-format-enumerate-connected = "• {device_alias}";
        max-length = 20;
      };
      wireplumber = {
        format = "{icon} {volume}%";
        format-muted = "󰖁  Mute";
        on-click = "pwvucontrol";
        on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        format-icons = [ "" "" "" ];
        max-volume = 150;
        scroll-step = 5;
        states = {
          warning = 40;
          critical = 15;
        };
      };
      backlight = {
        format = "{icon} {percent}%";
        format-icons = [ "󰃞" "󰃟" "󰃠" ];
      };
      battery = {
        interval = 2;
        states = {
          warning = 20;
          critical = 10;
        };
        format = "{icon} {capacity}%";
        format-charging = "󰂄 {capacity}%";
        format-plugged = "󱟢 {capacity}%";
        format-full = "󰁹 {capacity}%";
        format-icons = [ "" "" "" "" "" ];
        max-length = 25;
      };
      tray = {
        spacing = 8;
        icon-size = 18;
      };
      "hyprland/workspaces" = {
        all-outputs = true;
        format = "{id}";
        sort-by = "id";
      };
      "hyprland/window" = {
        separate-outputs = true;
        icon = true;
        icon-size = 16;
        max-length = 72;
        rewrite = {
          "(.*) - Mozilla Firefox" = "$1";
          "(.*) — Mozilla Firefox" = "$1";
          "(.*) - Visual Studio Code" = "$1";
          "(.*) — Visual Studio Code" = "$1";
        };
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
@define-color warning ${base09};
@define-color danger ${base08};

* {
  border: none;
  font-family: '${config.stylix.fonts.sansSerif.name}', '${config.stylix.fonts.emoji.name}', 'Symbols Nerd Font Mono';
  font-size: 15px;
  min-height: 0;
}

window#waybar {
  background: transparent;
  color: @text;
}

.modules-left > widget > #mpris,
.modules-center > widget > #workspaces,
.modules-center > widget > #window,
.modules-right > widget > #network,
.modules-right > widget > #bluetooth,
.modules-right > widget > #wireplumber,
.modules-right > widget > #backlight,
.modules-right > widget > #battery,
.modules-right > widget > #tray,
.modules-right > widget > #clock {
  background-image: linear-gradient(180deg, alpha(@surface-2, 0.96), alpha(@surface, 0.94));
  border: 1px solid alpha(@border, 0.82);
  border-radius: 18px;
  color: @text;
  min-height: 34px;
  padding-left: 14px;
  padding-right: 14px;
}

#mpris {
  min-width: 260px;
  padding-left: 16px;
  padding-right: 18px;
}

#workspaces {
  padding-left: 6px;
  padding-right: 6px;
}

#workspaces button {
  background: transparent;
  border-radius: 14px;
  color: @base04;
  margin: 5px 4px;
  min-width: 34px;
  padding-left: 10px;
  padding-right: 10px;
}

#workspaces button:hover {
  background: alpha(@surface-2, 0.92);
  color: @text-strong;
}

#workspaces button.active {
  background: @accent;
  color: @base00;
}

#workspaces button.urgent {
  background: @danger;
  color: @base00;
}

#window {
  color: @text-strong;
  min-width: 360px;
  padding-left: 16px;
  padding-right: 16px;
}

window#waybar.empty #window {
  background: transparent;
  border-color: transparent;
  min-width: 0;
  padding: 0;
}

#mpris.paused,
#network.disconnected,
#network.disabled,
#bluetooth.disabled,
#bluetooth.off,
#bluetooth.no-controller,
#wireplumber.muted {
  color: @base04;
}

#battery.charging,
#battery.plugged {
  color: @accent-strong;
}

#wireplumber.warning,
#battery.warning {
  color: @warning;
}

#wireplumber.critical,
#battery.critical {
  color: @danger;
}

#tray menu {
  background: alpha(@surface-2, 0.98);
  color: @text;
}

#tray > .passive {
  -gtk-icon-effect: dim;
}

#tray > .needs-attention {
  -gtk-icon-effect: highlight;
}

tooltip {
  background: alpha(@surface-2, 0.98);
  border: 1px solid alpha(@border, 0.88);
  border-radius: 16px;
}

tooltip label {
  color: @text-strong;
}
  '';
}
