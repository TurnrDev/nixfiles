{ ... }:
{
  # Native Hyprland window rules live here.
  #
  # This module uses Home Manager's Lua config generator, so rule definitions are
  # written as attribute sets under `settings.window_rule`. Home Manager renders
  # them into native Lua `hl.windowrule(...)` calls.
  #
  # Usage:
  # - Use `match.*` fields for selectors such as `match.class`,
  #   `match.initial_class`, or `match.title`.
  # - Use normal Nix booleans and lists for rule values, for example
  #   `float = true;` and `size = [ 835 660 ];`.
  # - Keep one attrset per named rule so intent stays readable.
  #
  # Example:
  # wayland.windowManager.hyprland.settings = {
  #   window_rule = [
  #     {
  #       name = "float-pavucontrol";
  #       match.class = "^(pavucontrol)$";
  #       float = true;
  #       center = true;
  #     }
  #   ];
  # };

  # Quickshell floating rules
  wayland.windowManager.hyprland.settings.window_rule = [
    {
      name = "float-system-monitor";
      match.initial_title = "^(System Monitor)$";
      match.initial_class = "^(org.quickshell)$";

      float = true;
      size = [ 835 660 ];
    }
    {
      name = "float-quickshell";
      match.initial_class = "^(org.quickshell)$";

      float = true;
    }
  ];
}
