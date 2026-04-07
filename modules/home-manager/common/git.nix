{ config, identity, lib, pkgs, ... }:

let
  gitName = identity.fullName;
  gitEmail = identity.email;
  gpg = lib.getExe config.programs.gpg.package;
  gpgconf = lib.getExe' config.programs.gpg.package "gpgconf";
  sshKeygen = lib.getExe' pkgs.openssh "ssh-keygen";
  sshDir = "${config.home.homeDirectory}/.ssh";
  sshKeyPath = "${sshDir}/id_ed25519";
  gpgHome = toString config.programs.gpg.homedir;
  signingUid = "${gitName} <${gitEmail}>";
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
        key = null;
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

      if ! ${gpg} --batch --list-secret-keys --with-colons ${lib.escapeShellArg gitEmail} 2>/dev/null | grep -q '^sec:'; then
        ${gpgconf} --launch gpg-agent >/dev/null 2>&1 || true
        run ${gpg} --batch --pinentry-mode loopback --passphrase "" --quick-generate-key ${lib.escapeShellArg signingUid} ed25519 sign 0
      fi
    '';
  })
]
