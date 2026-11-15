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
      options.my.users.${username} = with lib; {
        username = mkOption {
          type = types.str;
          default = username;
          description = "Default username for the shared personal identity profile.";
        };

        fullName = mkOption {
          type = types.str;
          default = "Jay Turner";
          description = "Display name for the shared personal identity profile.";
        };

        email = mkOption {
          type = types.str;
          default = "jay@turnr.net";
          description = "Default Git email for the shared personal identity profile.";
        };

        homeDirectory = mkOption {
          type = types.str;
          default = "/home/${username}";
          defaultText = literalExpression ''"/home/${username}"'';
          description = "Home directory for the shared personal identity profile.";
        };

        keyBootstrap.enable = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Whether Home Manager should auto-generate missing SSH and GPG identity
            keys for this user.

            This only creates local keys. Remote key distribution is documented in
            `NEW_HOST_SETUP.md` so it can happen interactively with password
            prompts when needed.
          '';
        };
      };

      config = {
        nix.settings.trusted-users = [ username ];

        home-manager.users."${username}" = {
          imports = [
            inputs.self.modules.homeManager."user-${username}"
          ];
        };

        users.users.${username} = {
          description = "Jay Turner";
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
    { ... }:
    {
      home.username = "${username}";
    };
}
