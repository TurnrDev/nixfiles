{
  inputs,
  ...
}:

{
  flake.modules.nixos.role-laptop =
    { config, ... }:
    {
      imports = with inputs.self.modules.nixos; [
        role-workstation
        system-plymouth-luks
        hardware-bluetooth
        desk-azelphur-floating
        desk-home
        ../common/dockmgr-laptop-monitors.nix
        ../services/wireguard.nix
      ];

      # Enable touchpad support (enabled default in most desktopManager).
      services.libinput.enable = true;
      services.upower.enable = true;
      services.power-profiles-daemon.enable = true;

      # Dux's greetd module turns this into greetd's initial session. The normal
      # Dux greeter remains available after logout or session failure.
      services.displayManager.autoLogin = {
        enable = true;
        user = config.my.users.jay.username;
      };

      services.logind.settings.Login = {
        HandleLidSwitch = "suspend";
        HandleLidSwitchDocked = "ignore";
      };
    };

  flake.modules.homeManager.role-laptop =
    { ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        role-workstation
        desk-azelphur-floating
      ];

      programs.dank-material-shell.plugins.networkStatus.enable = true;
      programs.dank-material-shell.plugins.dankBatteryAlerts.enable = true;
    };
}
