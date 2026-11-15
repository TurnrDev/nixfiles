{ inputs, ... }:

{
  flake.modules.nixos.desk-home =
    { ... }:
    {
      imports = with inputs.self.modules.nixos; [
        hardware-keyboard-Keychron-v6-max
        hardware-mouse-logitech-mx-master-3s
      ];
    };
}
