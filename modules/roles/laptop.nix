{
  inputs,
  ...
}:

{
  flake.modules.nixos.roles.laptop =
    { config, ... }:
    {
      imports = with inputs.self.modules.nixos; [
        roles.workstation
        ../hardware/bluetooth.nix
        ../hardware/kemove.nix
        ../hardware/keychron.nix
        ../hardware/logitech-mx-master-3s.nix
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
        user = config.home.username;
      };

      boot.plymouth.enable = true;

      services.logind.settings.Login = {
        HandleLidSwitch = "suspend";
        HandleLidSwitchDocked = "ignore";
      };
    };

  flake.modules.homeManager.roles.laptop =
    { ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        roles.workstation
        ../hardware/kemove.nix
      ];

      programs.dank-material-shell.plugins.networkStatus.enable = true;
      programs.dank-material-shell.plugins.dankBatteryAlerts.enable = true;
    };
}
