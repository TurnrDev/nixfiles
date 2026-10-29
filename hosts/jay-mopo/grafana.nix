{
  lib,
  pkgs,
  ...
}:

let
  giTypelibs = lib.makeSearchPathOutput "lib" "lib/girepository-1.0" [
    pkgs.cairo
    pkgs.gdk-pixbuf
    pkgs.glib
    pkgs.gobject-introspection
    pkgs.graphene
    pkgs.gtk4
    pkgs.gtk4-layer-shell
    pkgs.harfbuzz
    pkgs.libsoup_3
    pkgs.pango
    pkgs.webkitgtk_6_0
  ];
  toggle = pkgs.writeShellApplication {
    name = "grafana-wallpaper-toggle";
    runtimeInputs = [ pkgs.systemd ];
    text = ''
      if systemctl --user is-active --quiet grafana-wallpaper.service; then
        systemctl --user stop grafana-wallpaper.service
      else
        systemctl --user start grafana-wallpaper.service
      fi
    '';
  };
  toggleInteraction = pkgs.writeShellApplication {
    name = "grafana-wallpaper-toggle-interaction";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.systemd
    ];
    text = ''
      state_file="''${XDG_RUNTIME_DIR:?}/grafana-wallpaper-interactive"

      if [ -e "$state_file" ]; then
        rm "$state_file"
      else
        touch "$state_file"
      fi

      systemctl --user restart grafana-wallpaper.service
    '';
  };
in
{
  home.packages = [
    toggle
    toggleInteraction
  ];

  wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''
    hl.bind(
      "SUPER + SHIFT + G",
      hl.dsp.exec_cmd("${lib.getExe toggle}"),
      { description = "Toggle Grafana Wallpaper" }
    )
    hl.bind(
      "SUPER + SHIFT + I",
      hl.dsp.exec_cmd("${lib.getExe toggleInteraction}"),
      { description = "Toggle Grafana Wallpaper Interaction" }
    )
  '';

  systemd.user.services.grafana-wallpaper = {
    Unit = {
      Description = "Grafana desktop wallpaper";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.gjs}/bin/gjs -m ${./grafana.js}";
      Environment = [
        "GDK_BACKEND=wayland"
        "GIO_EXTRA_MODULES=${pkgs.glib-networking}/lib/gio/modules"
        "GI_TYPELIB_PATH=${giTypelibs}"
        "LD_PRELOAD=${pkgs.gtk4-layer-shell}/lib/libgtk4-layer-shell.so"
      ];
      Restart = "on-failure";
      RestartSec = "3s";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
