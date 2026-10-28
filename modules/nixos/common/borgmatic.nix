{ config, ... }:

let
  userSecretOwner = config.my.identity.username;
in
{
  sops.secrets = {
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
}
