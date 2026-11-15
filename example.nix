# Copy to a descriptive filename under modules/ and replace `example` below.
# Keep either or both blocks. Registering a module does not enable it on a host.
{ inputs, ... }:

{
  flake.modules.nixos.example =
    # Add config, lib, or pkgs here when needed: { config, lib, pkgs, ... }:
    { ... }:
    {
      imports = with inputs.self.modules.nixos; [
        # Import other modules, never this module itself:
        # core_system-core
      ];

      # NixOS settings go here.
      # environment.systemPackages = [ pkgs.ripgrep ];
    };

  flake.modules.homeManager.example =
    # Add config, lib, pkgs, or osConfig here when needed.
    # config is the user's Home Manager config; osConfig is the NixOS config.
    { ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        # core_system-core
      ];

      # Home Manager settings go here.
      # home.packages = [ pkgs.ripgrep ];
    };
}
