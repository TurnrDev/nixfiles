{
  config,
  identity,
  inputs,
  lib,
  osConfig,
  pkgs,
  ...
}:

let
  multiverse = inputs.multiverse.multiverse.${pkgs.stdenv.hostPlatform.system};
  borgVersion = lib.last (
    builtins.filter (version: lib.hasPrefix "1.4." version) (multiverse.versionsOf "borgbackup")
  );
  borgPackage = multiverse.version "borgbackup" borgVersion;
  homeDirectory = identity.homeDirectory;
  hostName = osConfig.networking.hostName;
  defaultRepositories = [
    {
      label = "hetzner-fsn1";
      path = "ssh://u551190@u551190.your-storagebox.de:23/./${hostName}";
    }
    {
      label = "hetzner-hel1";
      path = "ssh://u650719@u650719.your-storagebox.de:23/./${hostName}";
    }
  ];
  defaultExcludePatterns = [
    "*.pyc"
    "*.sqlite"
    "*.sqlite-*"
    "*cache*"
    "${homeDirectory}/.codex"
    "${homeDirectory}/.cache"
    "${homeDirectory}/.local/share/Trash"
    "${homeDirectory}/.thumbnails"
    "${homeDirectory}/Downloads"
  ];

  secretName = "storagebox-borg-passphrase";
  secretFile = ../../../secrets/hosts/${hostName}.yaml;
  sshKeyPath = "${homeDirectory}/.ssh/id_ed25519";
  sshCommand = "ssh -i ${sshKeyPath} -o IdentitiesOnly=yes -p 23";
  borgmaticPackage = pkgs.borgmatic;
  sopsPackage = pkgs.sops;
in
{
  config = lib.mkMerge [
    {
      programs.borgmatic.enable = lib.mkDefault true;
    }
    (lib.mkIf config.programs.borgmatic.enable {
      home.packages = [
        sopsPackage
        borgPackage
      ];

    sops = {
      age.sshKeyPaths = [ sshKeyPath ];
      secrets.${secretName} = {
        sopsFile = secretFile;
      };
    };

      programs.borgmatic = {
        package = borgmaticPackage;
        backups.shared = {
        location = {
          sourceDirectories = [ homeDirectory ];
          repositories = defaultRepositories;
          excludeHomeManagerSymlinks = true;
          extraConfig = {
            archive_name_format = "{hostname}-{utcnow}";
            exclude_patterns = defaultExcludePatterns;
          };
        };
        storage = {
          encryptionPasscommand = "${pkgs.coreutils}/bin/cat ${config.sops.secrets.${secretName}.path}";
          extraConfig = {
            local_path = lib.getExe borgPackage;
            remote_path = "borg-1.4";
            ssh_command = sshCommand;
          };
        };
        retention = {
          keepHourly = 4;
          keepDaily = 7;
          keepWeekly = 4;
          keepMonthly = 6;
          keepYearly = 2;
        };
        consistency.extraConfig = {
          checks = [
            {
              name = "repository";
              max_duration = 1800;
            }
            {
              name = "archives";
              frequency = "2 weeks";
            }
          ];
        };
        output.extraConfig = {
          statistics = true;
          borg_exit_codes = [
            {
              code = 105;
              treat_as = "warning";
            }
          ];
        };
        };
      };

      services.borgmatic = {
        enable = true;
        frequency = lib.mkDefault "daily";
      };

      systemd.user.services.borgmatic = {
        Unit = {
          # Ensure the decrypted sops secret is mounted before borgmatic tries to
          # read the shared encryption passphrase.
          After = [ "sops-nix.service" ];
          Requires = [ "sops-nix.service" ];
        };
      };
    })
  ];
}
