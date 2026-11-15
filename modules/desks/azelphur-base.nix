{ inputs, ... }:

# Hardware used across desks at Azelphur's.

{
  flake.modules.nixos.desk-azelphur-base =
    { ... }:
    {
      imports = with inputs.self.modules.nixos; [
        desk-base
        hardware-keyboard-kemove-k68
      ];

    };

  flake.modules.homeManager.desk-azelphur-base =
    { ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        hardware-keyboard-kemove-k68
      ];

    };
}
