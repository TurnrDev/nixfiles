{ pkgs, ... }:
{
  home.packages = [ pkgs.go-hass-agent ];

  xdg.configFile."go-hass-agent/commands.toml".text = ''
    [[button]]
    name = "Reboot"
    exec = "${pkgs.systemd}/bin/systemctl reboot"
    icon = "mdi:restart"

    [[button]]
    name = "Power Off"
    exec = "${pkgs.systemd}/bin/systemctl poweroff"
    icon = "mdi:power"

    [[button]]
    name = "Suspend"
    exec = "${pkgs.systemd}/bin/systemctl suspend"
    icon = "mdi:power-sleep"

    [[button]]
    name = "Hibernate"
    exec = "${pkgs.systemd}/bin/systemctl hibernate"
    icon = "mdi:power"
  '';

  systemd.user.services.go-hass-agent = {
    Unit = {
      Description = "go-hass-agent";
      Wants = [ "network-online.target" ];
      After = [ "network-online.target" ];
    };

    Service = {
      ExecStart = "${pkgs.go-hass-agent}/bin/go-hass-agent run";
      Restart = "always";
      RestartSec = 5;
    };

    Install.WantedBy = [ "default.target" ];
  };
}
