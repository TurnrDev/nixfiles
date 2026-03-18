{ config, pkgs, lib, ... }:

with config.lib.stylix.colors.withHashtag;

let
  jayLock = pkgs.writeShellScriptBin "jay-lock" ''
    set -euo pipefail

    ${pkgs.hyprland}/bin/hyprctl dispatch global quickshell:lock >/dev/null 2>&1 || true

    if ${pkgs.procps}/bin/pgrep -x hyprlock >/dev/null 2>&1; then
      exit 0
    fi

    exec ${lib.getExe config.programs.hyprlock.package} --immediate-render --grace 0
  '';

  lockListener = pkgs.writeShellScript "jay-lock-listener" ''
    set -euo pipefail

    session_path=""
    while [ -z "$session_path" ]; do
      session_path="$(${pkgs.systemd}/bin/loginctl show-session "$XDG_SESSION_ID" -p ObjectPath --value 2>/dev/null || true)"
      [ -n "$session_path" ] || ${pkgs.coreutils}/bin/sleep 2
    done

    ${pkgs.glib}/bin/gdbus monitor --system --dest org.freedesktop.login1 --object-path "$session_path" |
      while IFS= read -r line; do
        case "$line" in
          *"org.freedesktop.login1.Session.Lock"*)
            "${lib.getExe jayLock}" >/dev/null 2>&1 &
            ;;
        esac
      done
  '';
in
{
  options.jay.commands.lock = lib.mkOption {
    type = lib.types.str;
    internal = true;
    description = "Absolute path to the shared lock helper.";
  };

  config = {
    home.packages = with pkgs; [
      hyprlock
      jayLock
    ];
    jay.commands.lock = lib.getExe jayLock;
    stylix.targets.hyprlock.enable = false;
    programs.hyprlock.enable = true;
    programs.hyprlock.settings = {
      general = {
        grace = 0;
        hide_cursor = true;
        no_fade_in = true;
        ignore_empty_input = false;
      };

      background = [
        {
          monitor = "";
          color = "rgb(${lib.removePrefix "#" base00})";
        }
      ];

      label = [
        {
          monitor = "";
          text = ''<span font_weight="700">$TIME</span>'';
          color = "rgb(${lib.removePrefix "#" base06})";
          font_family = config.stylix.fonts.sansSerif.name;
          font_size = 72;
          position = "0, 170";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = ''cmd[update:60000] echo "$(date +'%A %d %B')"''; 
          color = "rgb(${lib.removePrefix "#" base05})";
          font_family = config.stylix.fonts.sansSerif.name;
          font_size = 24;
          position = "0, 92";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = ''<span font_weight="700">Jay</span>'';
          color = "rgb(${lib.removePrefix "#" base0B})";
          font_family = config.stylix.fonts.sansSerif.name;
          font_size = 28;
          position = "0, -148";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = "Locked";
          color = "rgb(${lib.removePrefix "#" base04})";
          font_family = config.stylix.fonts.sansSerif.name;
          font_size = 18;
          position = "0, -112";
          halign = "center";
          valign = "center";
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "320, 54";
          position = "0, -28";
          halign = "center";
          valign = "center";
          rounding = 27;
          dots_center = false;
          dots_rounding = -1;
          dots_size = "0.28";
          dots_spacing = "0.22";
          hide_input = false;
          outline_thickness = 2;
          placeholder_text = "Password";
          inner_color = "rgb(${lib.removePrefix "#" base01})";
          outer_color = "rgb(${lib.removePrefix "#" base03})";
          font_color = "rgb(${lib.removePrefix "#" base06})";
          font_family = config.stylix.fonts.sansSerif.name;
          check_color = "rgb(${lib.removePrefix "#" base0B})";
          fail_color = "rgb(${lib.removePrefix "#" base08})";
          fail_text = "Authentication failed";
          fail_transition = 200;
        }
      ];
    };
    systemd.user.services.jay-lock-listener = {
      Unit = {
        Description = "Listen for logind lock requests and launch Hyprlock";
        After = [ "hyprland-session.target" ];
        PartOf = [ "hyprland-session.target" ];
        ConditionEnvironment = [
          "HYPRLAND_INSTANCE_SIGNATURE"
          "XDG_SESSION_ID"
        ];
      };

      Service = {
        ExecStart = lockListener;
        Restart = "always";
        RestartSec = 2;
      };

      Install.WantedBy = [ "hyprland-session.target" ];
    };
    wayland.windowManager.hyprland.settings = {
      bindd = [
        "$mainMod, L, Lock Session, exec, ${config.jay.commands.lock}"
      ];
    };
  };
}
