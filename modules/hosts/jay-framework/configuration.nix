{
  config,
  inputs,
  lib,
  ...
}:

{
  flake.modules.nixos.jay-framework =
    { config, ... }:
    {
      networking.hostName = "jay-framework";

      imports = with inputs.self.modules.nixos; [
        role-gaming
        role-laptop
        role-nix-builder
        user-jay
      ];

      my.wireguard.home = {
        enable = true;
        sopsFile = ../../../secrets/hosts/jay-framework.yaml;
        ipv4Address = "10.117.25.241/32";
        ipv6Address = "fd00:7389:538a:05fd::3/64";
      };

      my.displays.internal = {
        width = 2256;
        height = 1504;
        freq = "59.999";
      };

      services.xserver.xkb = {
        layout = "gb";
        variant = "colemak";
      };

      users.users = {
        ${config.my.users.jay.username} = {
          extraGroups = [ "kvm" ];
        };
      };
    };

  flake.modules.homeManager.jay-framework =
    { config, lib, ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        role-gaming
        role-laptop
      ];

      programs.borgmatic.backups =
        lib.genAttrs
          [
            "borg1.4"
            "borg2"
          ]
          (_: {
            settings = {
              exclude_patterns = lib.mkAfter [
                "${config.home.homeDirectory}/games"
              ];
              healthchecks = {
                ping_url = "https://healthchecks.infra.turnr.net/ping/66bb872c-5ff0-4398-ba0c-7db7f3f7b731";
                send_logs = true;
              };
            };
          });
    };

}
