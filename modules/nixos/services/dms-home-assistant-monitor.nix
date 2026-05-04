{ config, ... }:

{
  sops.secrets.hass_token = {
    sopsFile = ../../../secrets/shared.yaml;
    path = "/run/secrets/hass_token";
    owner = config.my.identity.username;
    group = "users";
    mode = "0400";
  };
}
