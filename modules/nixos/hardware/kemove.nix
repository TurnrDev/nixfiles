{ lib, ... }:

{
  # Kemove K68 exposes several keyboard interfaces.  Override the laptop
  # default of GB Colemak for each interface in the standalone greeter.
  programs.dms-greeter.compositor.customConfig = lib.mkAfter ''
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
}
