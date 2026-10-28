{ config, lib, ... }:

let
  keyDirectory = ../../../keys/authorized;
  keyFiles = lib.filter (
    name: (builtins.readDir keyDirectory).${name} == "regular" && lib.hasSuffix ".pub" name
  ) (builtins.attrNames (builtins.readDir keyDirectory));
  authorizedKeys = map (
    name: lib.removeSuffix "\n" (builtins.readFile (keyDirectory + "/${name}"))
  ) keyFiles;
in
{
  # Keys are declarative rather than installed with ssh-copy-id. Every system
  # importing the default role receives the same operator and deployment keys.
  users.users = lib.mkIf config.my.identity.enable {
    root.openssh.authorizedKeys.keys = authorizedKeys;
    ${config.my.identity.username}.openssh.authorizedKeys.keys = authorizedKeys;
  };
}
