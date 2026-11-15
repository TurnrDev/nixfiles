{
  inputs,
  ...
}:

{
  flake.modules.nixos.roles.desktop =
    { ... }:
    {
      imports = with inputs.self.modules.nixos; [
        roles.workstation
      ];
    };

  flake.modules.homeManager.roles.desktop =
    { ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        roles.workstation
      ];
    };
}
