{
    inputs,
    ...
}:

{
  flake.modules.nixos.foo = {
    { ... }:
    {
        imports = with inputs.self.modules.nixos; [
            foo
        ];
    };
  };

  flake.modules.homeManager.foo = {
    { ... }:
    {
        imports = with inputs.self.modules.homeManager; [
            foo
        ];
    };
  };
}
