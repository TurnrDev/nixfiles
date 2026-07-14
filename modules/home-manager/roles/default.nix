{
  config,
  inputs,
  identity,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
    ../common/borgmatic.nix
    ../common/identity.nix
    ../common/git.nix
    ../common/zsh.nix
  ];

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "25.11";
  nixpkgs.config.allowUnfree = true;

  sops.age.sshKeyPaths = lib.mkDefault [
    "${identity.homeDirectory}/.ssh/id_ed25519"
  ];

  home.sessionVariables.SOPS_AGE_KEY_FILE =
    "${identity.homeDirectory}/.config/sops/age/keys.txt";

  programs.btop.enable = true;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
