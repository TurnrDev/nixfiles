{ config, pkgs, lib, ... }:

let
  hyprctl = "${pkgs.hyprland}/bin/hyprctl";
  lockCommand = config.jay.commands.lock;
  idleLock = pkgs.writeShellScript "jay-idle-lock" ''
    ${hyprctl} dispatch global quickshell:lock >/dev/null 2>&1 || true
    exec ${lockCommand}
  '';
  beforeSleep = pkgs.writeShellScript "jay-before-sleep" ''
    ${pkgs.systemd}/bin/loginctl lock-session
    exec ${lockCommand}
  '';
  afterSleep = pkgs.writeShellScript "jay-after-sleep" ''
    ${hyprctl} dispatch global quickshell:lockFocus >/dev/null 2>&1 || true
    exec ${hyprctl} dispatch dpms on
  '';
in
{
  services.hypridle = {
    enable = true;
    systemdTarget = "hyprland-session.target";
    settings = {
      general = {
        lock_cmd = "${idleLock}";
        before_sleep_cmd = "${beforeSleep}";
        after_sleep_cmd = "${afterSleep}";
        inhibit_sleep = 3;
      };

      listener = [
        {
          timeout = 300;
          on-timeout = lockCommand;
        }
        {
          timeout = 600;
          on-timeout = "${hyprctl} dispatch dpms off";
          on-resume = "${hyprctl} dispatch dpms on";
        }
        {
          timeout = 900;
          on-timeout = "${pkgs.systemd}/bin/systemctl suspend";
        }
      ];
    };
  };
}
