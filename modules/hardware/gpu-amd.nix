{
  inputs,
  ...
}:
{
  flake.modules.nixos.hardware-gpu-amd = {
    imports = with inputs.self.modules.nixos; [
      core_amdgpu
    ];
  };

  flake.modules.homeManager.hardware-gpu-amd =
    { lib, pkgs, ... }:
    {
      programs.btop.package = lib.mkForce pkgs.btop-rocm;
    };
}
