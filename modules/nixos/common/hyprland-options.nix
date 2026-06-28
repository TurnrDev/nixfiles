{ lib, ... }:

{
  options.my.hyprland.monitors = lib.mkOption {
    type = lib.types.listOf (
      lib.types.attrsOf (
        lib.types.oneOf [
          lib.types.bool
          lib.types.int
          lib.types.float
          lib.types.str
        ]
      )
    );
    default = [
      {
        output = "";
        mode = "preferred";
        position = "auto";
        scale = "auto";
      }
    ];
    description = "Nix-owned Hyprland monitor configurations.";
  };
}
