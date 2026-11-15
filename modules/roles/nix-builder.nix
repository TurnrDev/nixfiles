{ inputs, ... }:

{
  flake.modules.nixos.role-nix-builder =
    { pkgs, ... }:
    {
      imports = with inputs.self.modules.nixos; [
        service-attic-client
        system-nix-github-auth
      ];

      # Build/deploy tools and standalone formatters; nix fmt uses the flake formatter.
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
