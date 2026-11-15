{ inputs, ... }:

{
  flake.modules.nixos.system-home-manager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      repoLib = import ../../../lib { inherit lib; };
      backupCommand = pkgs.writeShellScript "home-manager-backup" (
        builtins.readFile ../../../scripts/home-manager-backup.sh
      );
    in
    {
      imports = with inputs.self.modules.nixos; [
        core_home-manager
      ];

      _module.args.repoLib = repoLib;
      users.manageLingering = true;
      home-manager = {
        inherit backupCommand;
        extraSpecialArgs = { inherit inputs repoLib; };
        users.jay = {
          home.username = config.my.users.jay.username;
          home.homeDirectory = config.my.users.jay.homeDirectory;
          nixpkgs.overlays = config.nixpkgs.overlays;
        };
      };
    };
}
