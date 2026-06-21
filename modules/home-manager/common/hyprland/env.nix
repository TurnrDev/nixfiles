{ ... }:
{
  # Hyprland env lines rendered as `env=NAME,value`.
  # Keep one env assignment per string.
  wayland.windowManager.hyprland.settings.env = [
    "UV_PROJECT_ENVIRONMENT,.venv"
  ];
}
