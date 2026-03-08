{ config, inputs, pkgs, ... }:

{
  imports = [
    ../../modules/home-manager/roles/laptop.nix
  ];

  home.username = "jay";
  home.homeDirectory = "/home/jay";

  services.kanshi = {
    enable = true;
    settings = [
      {
        profile.name = "internal";
        profile.outputs = [
          {
            criteria = "eDP-1";
            status = "enable";
            scale = 1.0;
            mode = "2256x1504@60.00Hz";
            position = "0,0";
          }
        ];
      }
      {
        profile.name = "docked";
        profile.outputs = [
          {
            criteria = "eDP-1";
            status = "enable";
            scale = 1.0;
            mode = "2256x1504@60.00Hz";
            position = "0,1440";
          }
          {
            criteria = "Samsung Electric Company LC49G95T H1AK500000";
            status = "enable";
            scale = 1.0;
            mode = "5120x1440@59.98Hz";
            position = "0,0";
          }
        ];
      }
    ];
  };

  # Restart kanshi when the generated HM config path changes on switch.
  systemd.user.services.kanshi.Unit.X-Restart-Triggers = [
    config.xdg.configFile."kanshi/config".source
  ];
}
