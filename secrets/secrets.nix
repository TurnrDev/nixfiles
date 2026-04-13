let
  readPublicKey = path: builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile path);
in
{
  "storagebox-borg-passphrase.age" = {
    publicKeys = map readPublicKey [
      ../hosts/jay-framework/id_ed25519.pub
    ];
    armor = true;
  };
}
