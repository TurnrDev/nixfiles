{
  inputs,
  ...
}:

{
  flake.modules.nixos.role-desktop =
    { ... }:
    {
      imports = with inputs.self.modules.nixos; [
        role-workstation
      ];
    };

  flake.modules.homeManager.role-desktop =
    { ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        role-workstation
      ];
    };
}
