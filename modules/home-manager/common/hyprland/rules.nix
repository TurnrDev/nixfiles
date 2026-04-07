{ ... }:
{
  # Native Hyprland window and workspace rules live here.
  # Window/layer rules: https://wiki.hyprland.org/Configuring/Window-Rules/
  # Workspace rules: https://wiki.hyprland.org/Configuring/Workspace-Rules/
  #
  # Examples:
  # wayland.windowManager.hyprland.settings = {
  #   windowrule = [
  #     {
  #       name = "float-pavucontrol";
  #       "match:class" = "^(pavucontrol)$";
  #       float = "on";
  #       center = "on";
  #     }
  #   ];
  #
  #   workspace = [
  #     "1, monitor:eDP-1, default:true"
  #     "2, monitor:HDMI-A-1"
  #   ];
  # };

  # Quickshell floating rules
  wayland.windowManager.hyprland.settings.windowrule = [
    {
      name = "float-system-monitor";
      "match:initial_title" = "^(System Monitor)$";
      "match:initial_class" = "^(org.quickshell)$";

      float = "on";
      size = "835 660";
    }
    {
      name = "float-quickshell";
      "match:initial_class" = "^(org.quickshell)$";

      float = "on";
    }
  ];
}
