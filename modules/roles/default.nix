{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

{
  flake.modules.nixos.role-default =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = with inputs.self.modules.nixos; [
        program-zsh
        inputs.sops-nix.nixosModules.sops
        system-bootloader
      ];

      boot.kernelModules = [ "fuse" ];
      programs.fuse.enable = true;
      programs.fuse.userAllowOther = true;

      # Use latest kernel.
      boot.kernelPackages = pkgs.linuxPackages_latest;

      # Keep /tmp clean
      boot.tmp.cleanOnBoot = true;

      # Enable networking
      networking.networkmanager.enable = true;
      networking.hosts = {
        "10.117.25.10" = [
          "home"
          "home.turnr.net"
        ];
        "10.117.25.11" = [ "jay-desktop" ];
        "10.117.25.14" = [ "g9-switcher" ];
        # WireGuard peers, available regardless of public DNS availability.
        "10.117.25.241" = [ "jay-framework" ];
        "10.117.25.242" = [ "jay-mopo" ];
        "fd00:7389:538a:05fd::3" = [ "jay-framework" ];
        "fd00:7389:538a:05fd::4" = [ "jay-mopo" ];
      };

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

      # Use the XKB layout/variant for the TTY and initrd so the early LUKS
      # unlock prompt matches the desktop keyboard layout.
      console = {
        useXkbConfig = true;
        earlySetup = true;
      };

      # Allow unfree packages
      nixpkgs.config = {
        allowUnfree = true;
        permittedInsecurePackages = [
          "electron-39.8.10"
        ];
      };
      nix = {
        # The normal deployment user is already in wheel. Trust it for Nix store
        # imports so locally-built closures can be copied to every host over SSH.
        settings.trusted-users = [
          "root"
          config.my.identity.username
        ];
        settings.experimental-features = [
          # Enables flake commands such as `nix fmt`.
          "nix-command"
          "flakes"
        ];
      };

      # Every host decrypts system and user-consumed secrets with its root-only
      # OpenSSH host identity, which is available before /home is mounted.
      sops.age.sshKeyPaths = [
        "/etc/ssh/ssh_host_ed25519_key"
      ];

      # List packages installed in system profile. To search, run:
      # $ nix search wget
      environment.systemPackages = with pkgs; [
        android-tools
        busybox
        dig
        dmidecode
        file
        gh
        gnumake
        jq
        localsend
        mtr
        nano
        nmap
        p7zip
        pciutils
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
            "wheel"
          ];
        };
      };

      virtualisation.docker.enable = true;

      services.fwupd.enable = true;

      services.openssh.enable = true;

      # This value determines the NixOS release from which the default
      # settings for stateful data, like file locations and database versions
      # on your system were taken. It‘s perfectly fine and recommended to leave
      # this value at the release version of the first install of this system.
      # Before changing this value read the documentation for this option
      # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
      system.stateVersion = "25.11"; # Did you read the comment?
    };

  flake.modules.homeManager.role-default = {
    imports = with inputs.self.modules.homeManager; [
      ../common/git.nix
      program-zsh
    ];

    home.stateVersion = "25.11";
    nixpkgs.config.allowUnfree = true;

    programs.btop.enable = true;
  };
}
