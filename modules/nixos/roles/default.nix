# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  userSecretOwner = config.my.identity.username;
  hostSecretsFile = ../../../secrets/hosts + "/${config.networking.hostName}.yaml";
in
{
  imports = [
    inputs.sops-nix.nixosModules.sops
    ../common/gradle.nix
    ../common/identity.nix
    ../common/obojima-glyph.nix
    ../common/python.nix
    ../common/systemd-boot.nix
  ];

  # Bootloader.
  # boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelModules = [ "fuse" ];
  programs.fuse.enable = true;
  programs.fuse.userAllowOther = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/London";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "gb";
  };

  # Use the XKB layout/variant for the TTY and initrd so the early LUKS
  # unlock prompt matches the desktop keyboard layout.
  console = {
    useXkbConfig = true;
    earlySetup = true;
  };

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # Allow unfree packages
  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "electron-39.8.10"
    ];
  };
  nix = {
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    extraOptions = ''
      !include /etc/nix/github-access-token.conf
    '';
  };

  # Every host decrypts system and user-consumed secrets with its root-only
  # OpenSSH host identity, which is available before /home is mounted.
  sops.age.sshKeyPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
  ];

  # Decrypt user-consumed secrets during system activation so Home Manager
  # services never need access to a SOPS identity. The files remain readable
  # only by their intended desktop user.
  sops.secrets = {
    github-token = {
      sopsFile = ../../../secrets/shared.yaml;
    };
  }
  // {
    git-signing-secret-key = {
      sopsFile = ../../../secrets/shared.yaml;
      owner = userSecretOwner;
      group = "users";
      mode = "0400";
    };
    storagebox-borg-passphrase = {
      sopsFile = hostSecretsFile;
      owner = userSecretOwner;
      group = "users";
      mode = "0400";
    };
    ovh-borg2-s3-access-key-id = {
      sopsFile = ../../../secrets/shared.yaml;
      owner = userSecretOwner;
      group = "users";
      mode = "0400";
    };
    ovh-borg2-s3-secret-access-key = {
      sopsFile = ../../../secrets/shared.yaml;
      owner = userSecretOwner;
      group = "users";
      mode = "0400";
    };
  };

  sops.templates."github-access-token.conf" = {
    path = "/etc/nix/github-access-token.conf";
    content = ''
      access-tokens = github.com=${config.sops.placeholder.github-token}
    '';
    owner = "root";
    group = "root";
    mode = "0400";
    restartUnits = [ "nix-daemon.service" ];
  };

  sops.templates."ovh-borg2-aws-credentials" = {
    path = "/run/secrets/ovh-borg2-aws-credentials";
    content = ''
      [default]
      aws_access_key_id=${config.sops.placeholder.ovh-borg2-s3-access-key-id}
      aws_secret_access_key=${config.sops.placeholder.ovh-borg2-s3-secret-access-key}
    '';
    owner = userSecretOwner;
    group = "users";
    mode = "0400";
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    android-tools
    busybox
    dig
    dmidecode
    file
    gh
    jq
    libnotify
    localsend
    mtr
    nano
    nixfmt
    nixfmt-tree
    nmap
    p7zip
    pciutils
    pwvucontrol
    ripgrep
    sbctl
    screen
    smartmontools
    sops
    tpm2-tss
    unzip
    usbutils
    wakeonlan
    wget
    whois
    yq
    zstd
  ];

  users.users = lib.mkIf config.my.identity.enable {
    ${config.my.identity.username} = {
      extraGroups = [
        "adbusers"
        "docker"
      ];
    };
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  virtualisation.docker.enable = true;

  services.fwupd.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}
