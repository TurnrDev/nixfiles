{ inputs, ... }:

let
  username = "jay";
  passwordHash = "$y$j9T$rDs32oazycO5s2isGALVj/$7iZRUxecxC3StPLIzuhA3dXPjsS9n9PkJ7q/1jF8llB";
in
{
  flake.modules.nixos."user-${username}" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      key = "user-jay";
      imports = with inputs.self.modules.nixos; [
        system-home-manager
        program-zsh
        program-git
      ];

      options.my.users.${username} = {
        username = lib.mkOption {
          type = lib.types.str;
          readOnly = true;
          default = username;
        };
        fullName = lib.mkOption {
          type = lib.types.str;
          default = "Jay Turner";
        };
        email = lib.mkOption {
          type = lib.types.str;
          default = "jay@turnr.net";
        };
        homeDirectory = lib.mkOption {
          type = lib.types.str;
          default = "/home/${username}";
        };
        keyBootstrap.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Generate Jay's missing SSH identity keys through Home Manager.";
        };
      };

      config = {
        nix.settings.trusted-users = [ username ];
        users.manageLingering = true;

        # Apply this host's Home Manager configuration to Jay.
        home-manager.users.${username}.imports = [
          inputs.self.modules.homeManager."user-${username}"
        ]
        ++
          lib.optional (builtins.hasAttr config.networking.hostName inputs.self.modules.homeManager)
            inputs.self.modules.homeManager.${config.networking.hostName};

        # Preserve the root password previously supplied by identity.nix.
        users.users.root.hashedPassword = passwordHash;

        users.users.${username} = {
          description = config.my.users.${username}.fullName;
          home = config.my.users.${username}.homeDirectory;
          isNormalUser = true;
          extraGroups = [
            "networkmanager"
            "wheel"
            "video"
          ];
          shell = pkgs.zsh;
          hashedPassword = passwordHash;
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIItKt0ZXeprcmJjMpSmAK2/nePF/ReYq8vUs3hFI6RF9 jay@jay-desktop"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJiufISnh8+rlwmw+mD1knzf3eB+N9YNusBhjEWwfpfV jay@nixos"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEquQEz5pdFBKiClY1s4IkcMNf6zy0EEYiXhtYyNVVTQ jay@jay-mopo"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIDl+ZOGmGy7O6BghVbXB69W+EL5yrCCJE7Ia9ew2CK4 jay@server"
          ];
          linger = true;
        };
        programs.zsh.enable = true;
      };
    };

  flake.modules.homeManager."user-${username}" =
    { osConfig, ... }:
    {
      home.username = osConfig.my.users.${username}.username;
      home.homeDirectory = osConfig.my.users.${username}.homeDirectory;
      nixpkgs.overlays = osConfig.nixpkgs.overlays;
    };
}
