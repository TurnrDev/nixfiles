# Copy this file into modules/ and replace `example` with a unique module name.
# Keep either or both blocks. Registering a module does not enable it on a host.
{ inputs, ... }:

## Any items I might use at Azelphur's place on a regular basis

{
  flake.modules.nixos.desk-azelphur-floating =
    # Add config, lib, or pkgs here when needed: { config, lib, pkgs, ... }:
    { ... }:
    {
      imports = with inputs.self.modules.nixos; [
        # Import other modules, never this module itself:
        hardware-keyboard-kemove-k68
      ];

      # NixOS settings go here.
      # environment.systemPackages = [ pkgs.ripgrep ];
    };

  flake.modules.homeManager.desk-azelphur-floating =
    # Add config, lib, pkgs, or osConfig here when needed.
    # config is the user's Home Manager config; osConfig is the NixOS config.
    { ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        hardware-keyboard-kemove-k68
      ];

      # Home Manager settings go here.
      # home.packages = [ pkgs.ripgrep ];
    };
}
