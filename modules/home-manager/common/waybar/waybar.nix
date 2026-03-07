{ config, pkgs, lib, nixpkgs-staging, ... }:

# with config.lib.stylix.colors.withHashtag;
{
  home.packages = with pkgs; [
    playerctl
  ];
  programs.waybar = {
    enable = true;
    systemd.enable = true;
  };
  #programs.waybar.systemd.target = "hyprland-session.target";
  programs.waybar.settings = {
    mainBar = {
      layer = "top";
      position = "top";
      height = 32;
      modules-left = [ "cava" "mpris" "image/album_art" "custom/media" ];
      modules-center = [ "hyprland/workspaces" ];
      modules-right = [ "tray" "wireplumber" "backlight" "battery" "clock" ];
      cava = {
        framerate = 30;
        autosens =  0;
        sensitivity = 5;
        bars = 14;
        lower_cutoff_freq = 50;
        higher_cutoff_freq = 10000;
        method = "pipewire";
        stereo = true;
        reverse = false;
        bar_delimiter = 0;
        monstercat = false;
        waves = false;
        noise_reduction = 0.77;
        input_delay = 2;
        format-icons = ["▁" "▂" "▃" "▄" "▅" "▆" "▇" "█" ];
        #format-icons =  ["A" "-" "A" "-" "a" "*" ";" "." ];
        actions = {
          on-click-right = "mode";
        };
      };
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
#   programs.waybar.style = lib.mkForce ''
# @define-color base00 ${base00}; @define-color base01 ${base01}; @define-color base02 ${base02}; @define-color base03 ${base03};
# @define-color base04 ${base04}; @define-color base05 ${base05}; @define-color base06 ${base06}; @define-color base07 ${base07};

# @define-color base08 ${base08}; @define-color base09 ${base09}; @define-color base0A ${base0A}; @define-color base0B ${base0B};
# @define-color base0C ${base0C}; @define-color base0D ${base0D}; @define-color base0E ${base0E}; @define-color base0F ${base0F};

# @define-color text ${base0D};

# * {
#   border: none;
#   font-family: 'JetBrains Mono', 'Symbols Nerd Font Mono';
#   /*font-family: monospace, sans-serif;*/
#   font-size: 20px;
#   font-feature-settings: '"zero", "ss01", "ss02", "ss03", "ss04", "ss05", "cv31"';
#   min-height: 15px;
#   margin-bottom: 0px;
# }

# window#waybar {
#   background: alpha(@base00, 0);
# }

# #cava {
#   font-family: monospace, sans-serif;
#   border-top-left-radius: 12px;
#   border-bottom-left-radius: 12px;
#   border-top-right-radius: 12px;
#   border-bottom-right-radius: 12px;
#   background-color: @base00;
#   color: @text;
#   margin-top: 5px;
#   margin-right: 0px;
#   margin-left: 10px;
#   padding-top: 1px;
#   padding-left: 10px;
#   padding-right: 5px;
#   min-width: 180px;
# }

# #mpris {
#   border-top-right-radius: 12px;
#   border-bottom-right-radius: 12px;
#   background-color: @base00;
#   color: @text;
#   margin-top: 5px;
#   margin-right: 0px;
#   margin-left: -8px;
#   padding-top: 1px;
#   padding-left: 5px;
#   padding-right: 10px;
# }

# #custom-arch, #workspaces {
#   border-radius: 12px;
#   background-color: @base00;
#   color: @text;
#   margin-top: 5px;
#   margin-right: 15px;
#   padding-top: 1px;
#   padding-left: 10px;
#   padding-right: 10px;
# }

# #custom-arch {
#   font-size: 20px;
#   margin-left: 15px;
#   color: @text;
# }

# #workspaces button {
#   background: @base00;
#   color: @text;
# }

# #custom-spotify {
#   border-radius: 10px;
#   background-color: @base00;
#   color: @text;
#   margin-top: 5px;
#   padding-left: 10px;
#   padding-right: 10px;
#   margin-right: 15px;
# }

# #window, #tray, #memory, #backlight, #pulseaudio, #bluetooth, #network, #battery, #wireplumber, #clock {
#   border-radius: 8px;
#   background-color: @base00;
#   color: @text;
#   margin-top: 5px;
#   padding-left: 10px;
#   padding-right: 10px;
#   margin-right: 10px;
# }

# #battery.warning {
#   color: #eed202;
# }

# #battery.critical {
#   color: #ff0000;
# }
#   '';
}
