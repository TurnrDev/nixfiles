{ config, lib, pkgs, ... }:

let
  cfg = config.services.hardware.openrgb;
  openrgb = lib.getExe cfg.package;
  setG512White = pkgs.writeShellApplication {
    name = "set-logitech-g512-white";
    runtimeInputs = with pkgs; [
      coreutils
      gnugrep
      gnused
    ];
    text = ''
      devices=""

      for _ in $(seq 1 10); do
        devices="$(${openrgb} --client --list-devices 2>/dev/null || true)"
        if printf '%s\n' "$devices" | grep -Eiq '(^|[^[:alnum:]])(Logitech[[:space:]]+)?G512([^[:alnum:]]|$)'; then
          break
        fi

        sleep 1
      done

      device_ids="$(
        printf '%s\n' "$devices" \
          | grep -Ei '(^|[^[:alnum:]])(Logitech[[:space:]]+)?G512([^[:alnum:]]|$)' \
          | sed -nE 's/^[[:space:]]*([0-9]+):.*/\1/p' \
          || true
      )"

      if [ -z "$device_ids" ]; then
        echo "No Logitech G512 device detected by OpenRGB."
        exit 0
      fi

      for device_id in $device_ids; do
        ${openrgb} --client --device "$device_id" --mode static --color FFFFFF
      done
    '';
  };
in
{
  services.hardware.openrgb.enable = true;

  systemd.services.logitech-g512-white = {
    description = "Set Logitech G512 RGB lighting to static white";
    after = [ "openrgb.service" ];
    wants = [ "openrgb.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = lib.getExe setG512White;
    };
  };
}
