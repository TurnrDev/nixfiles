{
  identity,
  lib,
  ...
}:

{
  imports = [
    ../common/elite.nix
    ./emulation.nix
  ];

  programs.borgmatic.backups =
    lib.genAttrs
      [
        "borg1.4"
        "borg2"
      ]
      (_: {
        location.extraConfig.exclude_patterns = lib.mkAfter [
          "${identity.homeDirectory}/.local/share/Steam"
          "${identity.homeDirectory}/.steam-shared"
          "${identity.homeDirectory}/.steam"
        ];
      });
}
