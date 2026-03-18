{ config, lib, pkgs, ... }:

let
  powerMenu = pkgs.writeShellScriptBin "power-menu" ''
    set -eu

    fuzzel_cmd='${lib.getExe pkgs.fuzzel}'
    lock_cmd='${config.jay.commands.lock}'

    choose() {
      printf '%s\n' "$@" | "$fuzzel_cmd" --dmenu --prompt 'power> ' --placeholder 'Choose action' --lines 5 --width 24
    }

    confirm() {
      choice="$(printf '%s\n' no yes | "$fuzzel_cmd" --dmenu --prompt "confirm> " --placeholder "$1" --lines 2 --width 18)"
      [ "$choice" = "yes" ]
    }

    action="$(choose lock suspend logout reboot poweroff)"

    case "$action" in
      lock)
        "$lock_cmd"
        ;;
      suspend)
        if confirm "Suspend the system?"; then
          "$lock_cmd"
          /run/current-system/sw/bin/systemctl suspend
        fi
        ;;
      logout)
        if confirm "End the current session?"; then
          /run/current-system/sw/bin/uwsm stop
        fi
        ;;
      reboot)
        if confirm "Reboot the system?"; then
          /run/current-system/sw/bin/systemctl reboot
        fi
        ;;
      poweroff)
        if confirm "Power off the system?"; then
          /run/current-system/sw/bin/systemctl poweroff
        fi
        ;;
      "")
        exit 0
        ;;
    esac
  '';
in
{
  options.jay.commands.powerMenu = lib.mkOption {
    type = lib.types.str;
    internal = true;
    description = "Absolute path to the shared power menu helper.";
  };

  config = {
    home.packages = [
      powerMenu
    ];
    jay.commands.powerMenu = lib.getExe powerMenu;
    programs.fuzzel = {
      enable = true;
      settings = {
        main = {
          font = lib.mkForce "${config.stylix.fonts.sansSerif.name}:size=18";
          prompt = "󰍉 ";
          placeholder = "Search applications";
          lines = 10;
          width = 42;
          terminal = "foot -e";
          "icons-enabled" = true;
          "use-bold" = true;
          "show-actions" = true;
          "match-mode" = "fzf";
          fields = "name,generic,keywords,categories";
          "horizontal-pad" = 24;
          "vertical-pad" = 18;
          "inner-pad" = 14;
          "line-height" = 28;
          anchor = "top";
          layer = "overlay";
          "y-margin" = 72;
        };
        colors = lib.mkForce {
          background = "${config.lib.stylix.colors.base00}eb";
          text = "${config.lib.stylix.colors.base05}ff";
          prompt = "${config.lib.stylix.colors.base0B}ff";
          placeholder = "${config.lib.stylix.colors.base04}ff";
          input = "${config.lib.stylix.colors.base07}ff";
          match = "${config.lib.stylix.colors.base0D}ff";
          selection = "${config.lib.stylix.colors.base02}ff";
          "selection-text" = "${config.lib.stylix.colors.base07}ff";
          "selection-match" = "${config.lib.stylix.colors.base0B}ff";
          counter = "${config.lib.stylix.colors.base04}ff";
          border = "${config.lib.stylix.colors.base03}ff";
        };
        border = {
          width = 1;
          radius = 22;
          "selection-radius" = 16;
        };
      };
    };
  };
}
