{ config, lib, ... }:

let
  cfg = config.my.identity;
  passwordHash = "$y$j9T$rDs32oazycO5s2isGALVj/$7iZRUxecxC3StPLIzuhA3dXPjsS9n9PkJ7q/1jF8llB";
in
{
  options.my.identity = with lib; {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable the shared personal identity profile.";
    };

    username = mkOption {
      type = types.str;
      default = "jay";
      description = "Default username for the shared personal identity profile.";
    };

    fullName = mkOption {
      type = types.str;
      default = "Jay Turner";
      description = "Display name for the shared personal identity profile.";
    };

    email = mkOption {
      type = types.str;
      default = "jaynicholasturner@gmail.com";
      description = "Default Git email for the shared personal identity profile.";
    };

    homeDirectory = mkOption {
      type = types.str;
      default = "/home/${config.my.identity.username}";
      defaultText = literalExpression ''"/home/${config.my.identity.username}"'';
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

  config = lib.mkIf cfg.enable {
    users.users.root.hashedPassword = passwordHash;

    users.users.${cfg.username} = {
      isNormalUser = true;
      description = cfg.fullName;
      home = cfg.homeDirectory;
      hashedPassword = passwordHash;
    };
  };
}
