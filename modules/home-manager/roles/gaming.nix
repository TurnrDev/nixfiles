{
  config,
  identity,
  inputs,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../common/elite.nix
  ];

  programs.borgmatic.backups.shared.location.extraConfig.exclude_patterns = lib.mkAfter [
    "${identity.homeDirectory}/.local/share/Steam"
    "${identity.homeDirectory}/.steam-shared"
    "${identity.homeDirectory}/.steam"
  ];
}
