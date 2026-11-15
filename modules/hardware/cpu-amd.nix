{
  inputs,
  ...
}:
{
  flake.modules.nixos.hardware-cpu-amd = {
    imports = with inputs.self.modules.nixos; [
      core_amdcpu
    ];
  };
}
