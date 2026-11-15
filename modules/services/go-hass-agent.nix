{ ... }:

{
  flake.modules.nixos.service-go-hass-agent = _: {
    security.polkit.enable = true;

    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        const allowedActions = [
          "org.freedesktop.login1.power-off",
          "org.freedesktop.login1.power-off-multiple-sessions",
          "org.freedesktop.login1.reboot",
          "org.freedesktop.login1.reboot-multiple-sessions",
          "org.freedesktop.login1.suspend",
          "org.freedesktop.login1.suspend-multiple-sessions",
          "org.freedesktop.login1.hibernate",
          "org.freedesktop.login1.hibernate-multiple-sessions"
        ];

        if (
          subject.user === "jay" &&
          allowedActions.indexOf(action.id) !== -1
        ) {
          return polkit.Result.YES;
        }
      });
    '';
  };

  flake.modules.homeManager.service-go-hass-agent =
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
    };
}
