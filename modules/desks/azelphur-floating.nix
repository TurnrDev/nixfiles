{ inputs, ... }:

# Hardware used across desks at Azelphur's.

{
  flake.modules.nixos.desk-azelphur-floating =
    { ... }:
    {
      imports = with inputs.self.modules.nixos; [
        hardware-keyboard-kemove-k68
      ];

    };

  flake.modules.homeManager.desk-azelphur-floating =
    { ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        hardware-keyboard-kemove-k68
      ];

    };
}
