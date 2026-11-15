{ inputs, ... }:

{
  flake.modules.nixos.desk-base = {
    imports = with inputs.self.modules.nixos; [
      hardware-mouse-logitech-mx-master-3s
    ];
  };
}
