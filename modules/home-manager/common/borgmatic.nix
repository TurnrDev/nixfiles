{ config, inputs, lib, osConfig ? null, pkgs, ... }:

let
  # Keep borgmatic and borgbackup from the same explicitly pinned package set.
  # Mixing borgmatic from one nixpkgs snapshot with borgbackup from another can
  # create Python dependency conflicts in the closure.
  borg14Pkgs = inputs."nixpkgs-borg14".legacyPackages.${pkgs.system};
  borg14Package = borg14Pkgs.borgbackup;
  hostName = osConfig.networking.hostName;
  defaultRepositoryPath = "ssh://u551190@u551190.your-storagebox.de:23/./${hostName}";
  defaultSourceDirectories = [ config.home.homeDirectory ];
  defaultExcludePatterns = [
    "${config.home.homeDirectory}/.cache"
    "${config.home.homeDirectory}/Downloads"
    "${config.home.homeDirectory}/.local/share/Trash"
  ];
  defaults = {
    enable = true;
    frequency = "hourly";
    localPath = lib.getExe borg14Package;
    remotePath = "borg-1.4";
    sourceDirectories = defaultSourceDirectories;
    excludePatterns = defaultExcludePatterns;
    healthchecksUrl = null;
    repositories = {
      storagebox = {
        label = "storagebox";
        path = defaultRepositoryPath;
      };
    };
  };
  # Read per-device overrides from the NixOS module when Home Manager is being
  # evaluated through a host config. Otherwise fall back to the shared defaults.
  cfg =
    if osConfig != null && osConfig ? my && osConfig.my ? backups && osConfig.my.backups ? borgmatic then
      osConfig.my.backups.borgmatic
    else
      defaults;

  secretName = "storagebox-borg-passphrase";
  secretFile = ../../../secrets/storagebox-borg-passphrase.age;
  sshKeyPath = "${config.home.homeDirectory}/.ssh/id_ed25519";
  sshCommand = "ssh -i ${sshKeyPath} -o IdentitiesOnly=yes -p 23";
  borgmaticPackage = borg14Pkgs.borgmatic;
  agenixPackage = inputs.agenix.packages.${pkgs.system}.default;
  repositories = lib.mapAttrsToList (_: repo: {
    inherit (repo) label path;
  }) cfg.repositories;
  # Only render the healthchecks section when the host actually configured a
  # ping URL. borgmatic treats the hook as absent otherwise.
  healthchecksConfig = lib.optionalAttrs (cfg.healthchecksUrl != null) {
    healthchecks = {
      ping_url = cfg.healthchecksUrl;
      send_logs = true;
    };
  };
in
lib.mkIf cfg.enable {
  assertions = [
    {
      assertion = lib.hasPrefix "1.4." borg14Package.version;
      message = "Pinned Borg package must resolve to Borg 1.4.x, got ${borg14Package.version}.";
    }
  ];

  home.packages = [
    agenixPackage
    borg14Package
  ];

  age = {
    identityPaths = [ sshKeyPath ];
    secrets.${secretName}.file = secretFile;
  };

  programs.borgmatic = {
    enable = true;
    package = borgmaticPackage;
    backups.shared = {
      location = {
        sourceDirectories = cfg.sourceDirectories;
        repositories = repositories;
        excludeHomeManagerSymlinks = true;
        extraConfig = {
          archive_name_format = "{hostname}-{utcnow}";
          exclude_patterns = cfg.excludePatterns;
        };
      };
      storage = {
        encryptionPasscommand = "${pkgs.coreutils}/bin/cat ${config.age.secrets.${secretName}.path}";
        extraConfig = {
          local_path = cfg.localPath;
          remote_path = cfg.remotePath;
          ssh_command = sshCommand;
        };
      };
      retention = {
        keepHourly = 48;
        keepDaily = 14;
        keepWeekly = 26;
        keepMonthly = 24;
        keepYearly = 5;
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
      };
      hooks.extraConfig = healthchecksConfig;
    };
  };

  services.borgmatic = {
    enable = true;
    frequency = cfg.frequency;
  };

  systemd.user.services.borgmatic = {
    Unit = {
      # Ensure the decrypted age secret is mounted before borgmatic tries to
      # read the shared encryption passphrase.
      After = [ "agenix.service" ];
      Requires = [ "agenix.service" ];
    };
  };
}
