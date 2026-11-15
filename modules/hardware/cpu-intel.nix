{
  inputs,
  ...
}:
{
  flake.modules.nixos.hardware-cpu-intel = {
    imports = with inputs.self.modules.nixos; [
      core_intelcpu
    ];
  };
}
