{ inputs, ... }:

{
  flake.modules.homeManager.program-spotify =
    {
      config,
      lib,
      osConfig,
      ...
    }:
    {
      imports = [
        inputs.spicetify-nix.homeManagerModules.spicetify
      ];

      programs.borgmatic.backups =
        lib.genAttrs
          [
            "borg1.4"
            "borg2"
          ]
          (_: {
            settings.exclude_patterns = lib.mkAfter [
              "${osConfig.my.users.${config.home.username}.homeDirectory}/.config/spotify"
            ];
          });

      programs.spicetify = {
        enable = true;
      };
    };
}
