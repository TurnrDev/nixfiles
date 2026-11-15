_:

let
  # Kemove K68 exposes several keyboard interfaces.
  hl_config = ''
    hl.device({
      name = "sonix-kemove-k68",
      kb_layout = "gb",
      kb_variant = "",
      resolve_binds_by_sym = true,
    })

    hl.device({
      name = "sonix-kemove-k68-system-control",
      kb_layout = "gb",
      kb_variant = "",
      resolve_binds_by_sym = true,
    })

    hl.device({
      name = "sonix-kemove-k68-keyboard",
      kb_layout = "gb",
      kb_variant = "",
      resolve_binds_by_sym = true,
    })
  '';
in
{
  flake.modules.nixos.hardware-keyboard-kemove-k68 =
    { lib, ... }:

    {
      programs.dms-greeter.compositor.customConfig = lib.mkAfter hl_config;
    };

  flake.modules.homeManager.hardware-keyboard-kemove-k68 =
    { lib, ... }:

    {
      wayland.windowManager.hyprland.extraConfig = lib.mkAfter hl_config;
    };
}
