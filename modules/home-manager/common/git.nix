{ config, identity, lib, pkgs, ... }:

let
  gitName = identity.fullName;
  gitEmail = identity.email;
  homeDirectory = identity.homeDirectory;
  gpg = lib.getExe config.programs.gpg.package;
  gpgconf = lib.getExe' config.programs.gpg.package "gpgconf";
  sshKeygen = lib.getExe' pkgs.openssh "ssh-keygen";
  reposDir = "${homeDirectory}/Repos";
  sshDir = "${homeDirectory}/.ssh";
  sshKeyPath = "${sshDir}/id_ed25519";
  gpgHome = toString config.programs.gpg.homedir;
  signingKey = "E4C8D6EEB05503E94B2896CA53C55D34138B4E04";
  signingSecretName = "git-signing-secret-key";
  importSigningKey = pkgs.writeShellScript "import-git-signing-key" ''
    set -eu

    export GNUPGHOME=${lib.escapeShellArg gpgHome}

    if ${gpg} --batch --list-secret-keys ${lib.escapeShellArg signingKey} >/dev/null 2>&1; then
      exit 0
    fi

    ${gpgconf} --launch gpg-agent >/dev/null 2>&1 || true
    ${gpg} --batch --import ${lib.escapeShellArg config.sops.secrets.${signingSecretName}.path}
  '';
in
lib.mkMerge [
  {
    programs.git = {
      enable = true;
      settings = {
        user = {
          name = gitName;
          email = gitEmail;
        };
        init.defaultBranch = "main";
      };
      signing = {
        format = "openpgp";
        key = signingKey;
        signByDefault = true;
      };
    };

    programs.gpg = {
      enable = true;
    };

    services.gpg-agent = {
      enable = true;
      enableZshIntegration = true;
      defaultCacheTtl = 1800;
      maxCacheTtl = 7200;
      pinentry.package = pkgs.pinentry-qt;
    };

    sops.secrets.${signingSecretName} = {
      sopsFile = ../../../secrets/shared.yaml;
    };

    systemd.user.services.import-git-signing-key = {
      Unit = {
        Description = "Import Git signing GPG key";
        After = [ "sops-nix.service" ];
        Requires = [ "sops-nix.service" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = importSigningKey;
      };
      Install.WantedBy = [ "default.target" ];
    };

    home.activation.createReposDirectory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p ${lib.escapeShellArg reposDir}
      run ln -sfnT /etc/nixos ${lib.escapeShellArg reposDir}/nixos
    '';
  }

  (lib.mkIf identity.keyBootstrap.enable {
    home.activation.generateIdentityKeys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      export GNUPGHOME=${lib.escapeShellArg gpgHome}

      if [[ ! -d ${lib.escapeShellArg sshDir} ]]; then
        run mkdir -m 700 -p ${lib.escapeShellArg sshDir}
      fi

      if [[ ! -f ${lib.escapeShellArg sshKeyPath} ]]; then
        run ${sshKeygen} -q -t ed25519 -a 100 -C ${lib.escapeShellArg gitEmail} -N "" -f ${lib.escapeShellArg sshKeyPath}
      fi
    '';
  })
]
