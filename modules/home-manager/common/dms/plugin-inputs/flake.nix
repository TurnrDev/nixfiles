{
  inputs = {
    dms-plugins = {
      url = "git+https://github.com/AvengeMedia/dms-plugins";
      flake = false;
    };
    dms-plugins-taylan = {
      url = "git+https://github.com/TaylanTatli/dms-plugins";
      flake = false;
    };
    dms-plugin-hass = {
      url = "git+https://github.com/xxyangyoulin/dms-plugin-hass";
      flake = false;
    };
    dms-plugin-docker-manager = {
      url = "git+https://github.com/LuckShiba/DmsDockerManager";
      flake = false;
    };
    dms-plugin-tailscale = {
      url = "git+https://github.com/cglavin50/dms-tailscale";
      flake = false;
    };
  };

  outputs =
    { self, ... }@inputs:
    {
      sources = builtins.removeAttrs inputs [ "self" ];
    };
}
