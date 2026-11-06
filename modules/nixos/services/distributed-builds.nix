{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.nixDistributedBuilds;
  privateKeyPath = config.sops.secrets.nix-remote-builder-ssh-private-key.path;
  remoteBuilderPublicKey = lib.removeSuffix "\n" (
    builtins.readFile ../../../keys/authorized/nix-remote-builder.pub
  );
  builder = hostName: maxJobs: speedFactor: {
    inherit hostName maxJobs speedFactor;
    system = "x86_64-linux";
    sshUser = "nix-remote-builder";
    sshKey = privateKeyPath;
    supportedFeatures = [
      "big-parallel"
      "kvm"
      "nixos-test"
    ];
  };
  knownBuilders = {
    jay-desktop = builder "jay-desktop" 12 4;
    jay-framework = builder "jay-framework" 6 3;
    # Kept here, but deliberately not selectable until home-server is NixOS and
    # has this module enabled. speedFactor affects scheduling, not availability.
    home-server = builder "home-server" 1 1;
  };
in
{
  options.my.nixDistributedBuilds = {
    enable = lib.mkEnableOption "native SSH distributed Nix builds";

    maxJobs = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 0;
      description = "Maximum local Nix build jobs; zero disables normal local builds.";
    };

    builders = lib.mkOption {
      type = lib.types.listOf (lib.types.enum (builtins.attrNames knownBuilders));
      default = [ ];
      description = "Named remote builders, ordered by preference.";
    };

    remoteBuilder.enable = lib.mkEnableOption "accepting restricted Nix remote build jobs";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !(builtins.elem config.networking.hostName cfg.builders);
        message = "A host must not delegate builds to itself.";
      }
    ];

    nix = {
      distributedBuilds = cfg.builders != [ ];
      buildMachines = map (name: knownBuilders.${name}) cfg.builders;
      settings = {
        max-jobs = cfg.maxJobs;
        builders-use-substitutes = true;
        connect-timeout = 5;
      };
    };

    # Nix invokes SSH for these builders. Keep unavailable laptops from waiting
    # on the operating system's much longer TCP timeout; Nix then tries the
    # next eligible builder or uses this host's non-zero local capacity.
    programs.ssh.extraConfig = lib.mkIf (cfg.builders != [ ]) ''
      Host ${lib.concatStringsSep " " cfg.builders}
        BatchMode yes
        ConnectTimeout 5
        ConnectionAttempts 1
    '';

    # Only the client private key is secret. The public client and host keys are
    # declarative in keys/authorized and keys/known_hosts respectively.
    sops.secrets = lib.optionalAttrs (cfg.builders != [ ]) {
      nix-remote-builder-ssh-private-key = {
        sopsFile = ../../../secrets/shared.yaml;
        owner = "root";
        group = "root";
        mode = "0400";
      };
    };

    sops.templates.nix-remote-builder-authorized-keys = lib.mkIf cfg.remoteBuilder.enable {
      path = "/etc/ssh/authorized_keys/nix-remote-builder";
      content = ''
        restrict,command="${pkgs.nix}/bin/nix-store --serve --write" ${remoteBuilderPublicKey}
      '';
      owner = "root";
      group = "root";
      mode = "0400";
    };

    users.users.nix-remote-builder = lib.mkIf cfg.remoteBuilder.enable {
      isSystemUser = true;
      group = "nix-remote-builder";
      createHome = true;
      home = "/var/lib/nix-remote-builder";
    };
    users.groups.nix-remote-builder = lib.mkIf cfg.remoteBuilder.enable { };
    services.openssh.extraConfig = lib.mkIf cfg.remoteBuilder.enable ''
      Match User nix-remote-builder
        AuthorizedKeysFile /etc/ssh/authorized_keys/nix-remote-builder
    '';
    nix.settings.trusted-users = lib.mkIf cfg.remoteBuilder.enable [ "nix-remote-builder" ];
  };
}
