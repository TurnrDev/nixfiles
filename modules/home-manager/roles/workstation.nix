{
  identity,
  inputs,
  lib,
  ...
}:

{
  imports = [
    ./default.nix
    ../common/default-apps.nix
    ../common/discord.nix
    inputs.dockmgr.homeManagerModules.default
    ../common/firefox.nix
    ../common/go-hass-agent.nix
    ../common/hyprland/hyprland.nix
    ../common/kdeconnect.nix
    ../common/spotify.nix
    ../common/stylix.nix
    ../common/vscode.nix
  ];

  fonts.fontconfig = {
    enable = true;
    antialiasing = true;
  };

  programs.borgmatic.backups =
    lib.genAttrs
      [
        "borg1.4"
        "borg2"
      ]
      (_: {
        location.extraConfig.exclude_patterns = lib.mkAfter [
          "${identity.homeDirectory}/.config/Code"
          "${identity.homeDirectory}/.config/GitKraken"
          "${identity.homeDirectory}/.gitkraken"
          "${identity.homeDirectory}/.vscode"
          "${identity.homeDirectory}/.vscode-server"
        ];
      });
}
