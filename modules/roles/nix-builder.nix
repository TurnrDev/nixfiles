{ inputs, ... }:

{
  flake.modules.nixos.role-nix-builder =
    { pkgs, ... }:
    {
      imports = with inputs.self.modules.nixos; [
        system-nix-github-auth
        service-attic-client
      ];

      # Tools for building, inspecting, and deploying NixOS configurations.
      # `nix fmt` is provided by the flake formatter and enabled in the default
      # role through the `nix-command` experimental feature.
      environment.systemPackages = with pkgs; [
        nixfmt
        nixfmt-tree
        nixos-rebuild
        nix-output-monitor
        nix-tree
        nvd
      ];
      nix.settings.experimental-features = [
        # Enables flake commands such as `nix fmt`.
        "nix-command"
        "flakes"
      ];

      my.attic.upload.enable = true;
    };
}
