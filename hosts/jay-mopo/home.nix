{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  firefoxProfilesIni = pkgs.writeText "firefox-profiles.ini" ''
    [General]
    StartWithLastProfile=1
    Version=2

    [Install4F96D1932A9F858E]
    Default=jrxoxku9.default-release
    Locked=1

    [Profile0]
    IsRelative=1
    Name=default-release
    Path=jrxoxku9.default-release
    ShowSelector=1
    StoreID=642ce52d
    Default=1
  '';
in

{
  imports = [
    ../../modules/home-manager/roles/laptop.nix
    ./google-drive.nix
  ];

  programs.vscode.profiles.default.userSettings = {
    "editor.formatOnSave" = lib.mkForce false;
    "editor.codeActionsOnSave" = lib.mkForce { };
  };

  programs.firefox.profiles = {
    default = {
      name = "Personal";
      path = "jrxoxku9.default-release";
      storeId = "642ce52d";
    };

    profile1 = {
      id = 1;
      name = "Work";
      path = "CfqUTwRK.Profile 1";
      isDefault = false;
    };
  };

  stylix.targets.firefox.profileNames = lib.mkForce [ "default" "profile1" ];

  # Firefox must own this file: it saves the selected profile and profile
  # edits there. Initialise it once rather than linking it read-only from Nix.
  home.file."${config.xdg.configHome}/mozilla/firefox/profiles.ini".enable = false;
  home.activation.makeFirefoxProfilesIniMutable = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    profiles_ini="${config.xdg.configHome}/mozilla/firefox/profiles.ini"
    if [ ! -e "$profiles_ini" ]; then
      install -m 600 ${firefoxProfilesIni} "$profiles_ini"
    fi
  '';

  programs.borgmatic.backups.shared.location.extraConfig.exclude_patterns = lib.mkAfter [
    "${config.home.homeDirectory}/Repos/mopo/.db_data"
    "${config.home.homeDirectory}/Repos/mopo/.redis_data"
    "*.xb"
    "*.xb.zstd"
  ];

}
