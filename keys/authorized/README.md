# Authorized SSH keys

Put public OpenSSH keys in this directory with a `.pub` suffix. They are added
declaratively to both `root` and the shared personal user on every host that
imports the NixOS default role.

Never put private keys in this directory.
