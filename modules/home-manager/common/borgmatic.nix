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
  borg2Package = pkgs.callPackage ../../../packages/borg2 { };
  inherit (identity) homeDirectory;
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
  ovhAccessKeySecretName = "ovh-borg2-s3-access-key-id";
  ovhSecretKeySecretName = "ovh-borg2-s3-secret-access-key";
  ovhCredentialsTemplateName = "ovh-borg2-aws-credentials";
  ovhCredentialsPath = osConfig.sops.templates.${ovhCredentialsTemplateName}.path;
  borgPassphrasePath = osConfig.sops.secrets.${secretName}.path;
  sshKeyPath = "${homeDirectory}/.ssh/id_ed25519";
  sshCommand = "ssh -i ${sshKeyPath} -o IdentitiesOnly=yes -p 23";
  borgmaticPackage = pkgs.borgmatic;
  commonBackup = {
    location.excludeHomeManagerSymlinks = true;
    settings = {
      source_directories = [ homeDirectory ];
      archive_name_format = "{hostname}-{utcnow}";
      exclude_patterns = defaultExcludePatterns;
      encryption_passcommand = "${pkgs.coreutils}/bin/cat ${borgPassphrasePath}";
      keep_hourly = 4;
      keep_daily = 7;
      keep_weekly = 4;
      keep_monthly = 6;
      keep_yearly = 2;
      checks = [
        {
          name = "repository";
          max_duration = 1800;
          frequency = "1 week";
        }
        {
          name = "archives";
          frequency = "2 weeks";
        }
      ];
      statistics = true;
      borg_exit_codes = [
        {
          code = 105;
          treat_as = "warning";
        }
      ];
    };
  };
in
{
  config = lib.mkMerge [
    {
      programs.borgmatic.enable = lib.mkDefault true;
    }
    (lib.mkIf config.programs.borgmatic.enable {
      home.packages = [
        borgPackage
        borg2Package
      ];

      home.sessionVariables = {
        AWS_DEFAULT_REGION = "gra";
        AWS_REGION = "gra";
        AWS_SHARED_CREDENTIALS_FILE = ovhCredentialsPath;
      };

      programs.borgmatic = {
        package = borgmaticPackage;
        backups = {
          "borg1.4" = lib.recursiveUpdate commonBackup {
            settings = {
              repositories = defaultRepositories;
              local_path = lib.getExe borgPackage;
              remote_path = "borg-1.4";
              ssh_command = sshCommand;
            };
          };
          borg2 = lib.recursiveUpdate commonBackup {
            settings = {
              repositories = [
                {
                  label = "ovh-gra";
                  path = "s3:https://s3.gra.io.cloud.ovh.net/borg-2/${hostName}";
                }
              ];
              local_path = lib.getExe borg2Package;
            };
          };
        };
      };

      services.borgmatic = {
        enable = true;
        frequency = lib.mkDefault "daily";
      };

      systemd.user.services.borgmatic = {
        Unit.AssertPathExists = [
          borgPassphrasePath
          ovhCredentialsPath
        ];
        Service.Environment = [
          "AWS_DEFAULT_REGION=gra"
          "AWS_REGION=gra"
          "AWS_SHARED_CREDENTIALS_FILE=${ovhCredentialsPath}"
        ];
      };
    })
  ];
}
