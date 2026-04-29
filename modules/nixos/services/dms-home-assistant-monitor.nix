{ config, inputs, ... }:

{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  sops.age.sshKeyPaths = [
    "${config.my.identity.homeDirectory}/.ssh/id_ed25519"
  ];

  sops.secrets.hass_token = {
    sopsFile = ../../../secrets/shared.yaml;
    path = "/run/secrets/hass_token";
    owner = config.my.identity.username;
    group = "users";
    mode = "0400";
  };
}
