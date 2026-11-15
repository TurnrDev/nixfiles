{
  config,
  lib,
  osConfig,
  ...
}:

{
  imports = [
    ../common/elite.nix
    # ./emulation.nix
  ];

  programs.borgmatic.backups =
    lib.genAttrs
      [
        "borg1.4"
        "borg2"
      ]
      (_: {
        settings.exclude_patterns = lib.mkAfter [
          "${osConfig.my.users.${config.home.username}.homeDirectory}/.local/share/Steam"
          "${osConfig.my.users.${config.home.username}.homeDirectory}/.steam-shared"
          "${osConfig.my.users.${config.home.username}.homeDirectory}/.steam"
          "srv/nfs/games"
        ];
      });
}
