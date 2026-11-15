{
  inputs,
  lib,
  ...
}:
{
  flake.modules.nixos.jay-desktop = {
    imports = with inputs.self.modules.nixos; [
      role-nix-builder
      role-desktop
      role-gaming
      desk-home
    ];

    networking = {
      hostName = "jay-desktop";
      interfaces = {
        enp13s0 = {
          wakeOnLan.enable = true;
        };
      };
    };

    programs.dockmgr.profiles = [
      {
        name = "Default";
        outputs."DP-2" = {
          mode = "5120x1440@240";
          position = {
            x = 0;
            y = 0;
          };
          scale = 1.0;
        };
      }
    ];
  };

  flake.modules.homeManager.jay-desktop = {
    imports = with inputs.self.modules.homeManager; [
      role-desktop
      role-gaming
    ];

    programs.borgmatic.backups =
      lib.genAttrs
        [
          "borg1.4"
          "borg2"
        ]
        (_: {
          settings.healthchecks = {
            ping_url = "https://healthchecks.infra.turnr.net/ping/3864da02-bd3e-4f8f-9685-825959aa6cf9";
            send_logs = true;
          };
        });

  };
}
