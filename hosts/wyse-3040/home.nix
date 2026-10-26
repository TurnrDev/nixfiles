{ ... }:

{
  imports = [
    ../../modules/home-manager/roles/default.nix
  ];

  # Enable this once the installed host has its Storage Box secret defined.
  programs.borgmatic.enable = false;
}
