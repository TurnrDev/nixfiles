{ pkgs, ... }:

{
  # Tools for building, inspecting, and deploying NixOS configurations.
  # `nix fmt` is provided by the flake formatter and enabled in the default
  # role through the `nix-command` experimental feature.
  environment.systemPackages = with pkgs; [
    nixos-rebuild
    nix-output-monitor
    nix-tree
    nvd
  ];
  settings.experimental-features = [
    # Enables flake commands such as `nix fmt`.
    "nix-command"
    "flakes"
  ];
}
