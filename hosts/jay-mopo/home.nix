{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../../modules/home-manager/roles/laptop.nix
    ./google-drive.nix
  ];

  programs.vscode.profiles.default.userSettings = {
    "editor.formatOnSave" = lib.mkForce false;
    "editor.codeActionsOnSave" = lib.mkForce { };
  };

  programs.borgmatic.backups.shared.location.extraConfig.exclude_patterns = lib.mkAfter [
    "${config.home.homeDirectory}/Repos/mopo/.db_data"
    "${config.home.homeDirectory}/Repos/mopo/.redis_data"
    "*.xb"
    "*.xb.zstd"
  ];

}
