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

}
