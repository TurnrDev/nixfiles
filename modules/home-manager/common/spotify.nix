{
  identity,
  inputs,
  lib,
  ...
}:

{
  imports = [
    inputs.spicetify-nix.homeManagerModules.spicetify
  ];

  programs.borgmatic.backups.shared.location.extraConfig.exclude_patterns = lib.mkAfter [
    "${identity.homeDirectory}/.config/spotify"
  ];

  programs.spicetify = {
    enable = true;
  };

}
