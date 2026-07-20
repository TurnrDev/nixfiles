{
  config,
  lib,
  ...
}:

{
  services.tailscale.enable = true;

  home-manager.users = lib.mkIf config.my.identity.enable {
    ${config.my.identity.username}.programs.dank-material-shell.plugins.tailscale.enable = true;
  };
}
