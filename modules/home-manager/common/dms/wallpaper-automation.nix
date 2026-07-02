{
  config,
  lib,
  pkgs,
  ...
}:

let
  wallpaperScript = "/etc/nixos/scripts/random_wallpaper.sh";
  hyprctl = lib.getExe' config.wayland.windowManager.hyprland.package "hyprctl";
  jq = lib.getExe pkgs.jq;
  socat = lib.getExe pkgs.socat;
  sha256sum = lib.getExe' pkgs.coreutils "sha256sum";
  cut = lib.getExe' pkgs.coreutils "cut";
  sleep = lib.getExe' pkgs.coreutils "sleep";
  sessionTarget = config.wayland.systemd.target;

  monitorWatcher = pkgs.writeShellScript "random-wallpaper-hypr-watch" ''
    set -eu

    run_wallpaper() {
      "${wallpaperScript}" space || true
    }

    monitor_hash() {
      ${hyprctl} monitors -j 2>/dev/null \
        | ${jq} -c 'map({name, width, height, scale, refreshRate, x, y, transform}) | sort_by(.name)' \
        | ${sha256sum} \
        | ${cut} -d' ' -f1
    }

    socket_path=""
    i=0
    while [ -z "$socket_path" ]; do
      i=$((i + 1))
      sig="''${HYPRLAND_INSTANCE_SIGNATURE:-}"
      runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$UID}"
      candidate="$runtime_dir/hypr/$sig/.socket2.sock"
      if [ -n "$sig" ] && [ -S "$candidate" ]; then
        socket_path="$candidate"
        break
      fi
      if [ "$i" -ge 60 ]; then
        echo "random-wallpaper monitor watcher: Hyprland socket not found" >&2
        exit 1
      fi
      ${sleep} 1
    done

    prev_hash="$(monitor_hash || true)"
    if [ -n "$prev_hash" ]; then
      run_wallpaper
    fi

    ${socat} -U - "UNIX-CONNECT:$socket_path" | while IFS= read -r line; do
      case "$line" in
        monitor*|focusedmon*|configreloaded*)
          new_hash="$(monitor_hash || true)"
          if [ -z "$new_hash" ]; then
            continue
          fi
          if [ "$new_hash" != "$prev_hash" ]; then
            prev_hash="$new_hash"
            run_wallpaper
          fi
          ;;
      esac
    done
  '';
in
{
  systemd.user.services.random-wallpaper-space = {
    Unit = {
      Description = "Set random wallpaper with query 'space'";
      PartOf = [ sessionTarget ];
      Requires = [ "dms.service" ];
      After = [ sessionTarget "dms.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${wallpaperScript} space";
    };
  };

  systemd.user.timers.random-wallpaper-space = {
    Unit = {
      Description = "Rotate wallpaper every 30 minutes";
      PartOf = [ sessionTarget ];
      After = [ sessionTarget ];
    };
    Timer = {
      Unit = "random-wallpaper-space.service";
      OnStartupSec = "2m";
      OnUnitActiveSec = "30m";
      Persistent = true;
    };
    Install.WantedBy = [ sessionTarget ];
  };

  systemd.user.services.random-wallpaper-monitor-watch = {
    Unit = {
      Description = "Watch Hyprland monitor events and update wallpaper on size/layout changes";
      PartOf = [ sessionTarget ];
      Requires = [ "dms.service" ];
      After = [ sessionTarget "dms.service" ];
    };
    Service = {
      Type = "simple";
      ExecStart = monitorWatcher;
      Restart = "always";
      RestartSec = "3s";
    };
    Install.WantedBy = [ sessionTarget ];
  };
}
