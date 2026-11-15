{
  inputs,
  ...
}:

{
  flake.modules.nixos.role-laptop =
    { config, ... }:
    {
      imports = with inputs.self.modules.nixos; [
        desk-azelphur-workbench
        desk-base
        desk-home
        hardware-bluetooth
        hardware-laptop-displays
        role-workstation
        service-wireguard
        system-plymouth-luks
      ];

      # Enable touchpad input.
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
        desk-azelphur-workbench
        role-workstation
      ];

      programs.dank-material-shell.plugins.networkStatus.enable = true;
      programs.dank-material-shell.plugins.dankBatteryAlerts.enable = true;
    };
}
