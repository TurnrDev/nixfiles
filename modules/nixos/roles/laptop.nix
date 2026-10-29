# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  ...
}:

{
  imports = [
    ./workstation.nix
    ../hardware/bluetooth.nix
    ../hardware/keychron.nix
    ../hardware/logitech-mx-master-3s.nix
    ../common/dockmgr-laptop-monitors.nix
    ../services/wireguard.nix
  ];

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  # The LUKS passphrase is the only login required at boot.  Dux's greetd
  # module turns this into greetd's initial session, while retaining the Dux
  # login screen for explicit logins after logout or session failure.
  services.displayManager.autoLogin = {
    enable = true;
    user = config.my.identity.username;
  };

  boot.plymouth.enable = true;

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchDocked = "ignore";
  };

}
