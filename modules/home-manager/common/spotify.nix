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

  programs.borgmatic.backups =
    lib.genAttrs
      [
        "borg1.4"
        "borg2"
      ]
      (_: {
        location.extraConfig.exclude_patterns = lib.mkAfter [
          "${identity.homeDirectory}/.config/spotify"
        ];
      });

  programs.spicetify = {
    enable = true;
  };

}
