let
  readPublicKey = path: builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile path);
  jayFramework = readPublicKey ../hosts/jay-framework/id_ed25519.pub;
  # Keep existing recipients in this list when adding a new device, unless you
  # intentionally want to revoke that device's access to the secret.
  devices = [ jayFramework ];
in
{
  "storagebox-borg-passphrase.age" = {
    publicKeys = devices;
    armor = true;
  };
}
