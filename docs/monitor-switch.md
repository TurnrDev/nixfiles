# monitor-switch on `g9-switcher`

`services.monitorctl` runs one upstream `monitor-switch` process per enabled
physical monitor. Each process has its own DDC connector glob, HTTP port, MQTT
node ID, cache, availability topic, and failure domain. It resolves the I2C bus
by following the selected DRM connector's `ddc` symlink; no `/dev/i2c-N` number
is configured.

## Bottom G9 instance

The active instance is `monitorctl-g9_bottom.service` and is configured for
`/sys/class/drm/card*-HDMI-A-3`. The upstream `samsung-lc49g95t` profile is
selected from the monitor EDID. Local labels deliberately describe the desk,
not the cable:

| Upstream input ID | Home Assistant label |
| --- | --- |
| `dp1` | Desktop |
| `dp2` | Laptop |
| `hdmi` | Wyse |

The service binds its upstream HTTP UI/API only to `127.0.0.1:8765`. Reach it
over SSH if needed:

```sh
ssh -L 8765:127.0.0.1:8765 g9-switcher
```

The static `video=HDMI-A-3:1920x1080@60D` kernel argument requests a mode and,
more importantly, forces the connector enabled. It needs a reboot before it can
be assessed. The requested pixels can fall back when the G9 withholds EDID;
the successful condition is instead `connected`, `enabled`, `dpms On`, a live
framebuffer, and `local_video: true` from the API.

## MQTT and credentials

The bottom G9 uses node ID `g9_bottom`. Upstream consequently publishes retained
discovery under `homeassistant/<component>/g9_bottom/<feature>/config`, creates
device identifier `monitorctl_g9_bottom`, uses entity unique IDs such as
`monitorctl_g9_bottom_input_source`, and uses independent runtime/availability
topics below `monitorctl/g9_bottom`. Its MQTT Last Will retains `offline`; a
successful connection publishes `online`.

The `monitorctl-mqtt` SOPS secret is host-specific at
`secrets/hosts/g9-switcher.yaml`. Its decrypted value is a systemd environment
file:

```ini
MONITORCTL_MQTT_USERNAME=monitorswitch
MONITORCTL_MQTT_PASSWORD=replace-with-a-dedicated-random-password
```

It is read by systemd from `/run/secrets/monitorctl-mqtt`; it is never embedded
in the generated Nix configuration or Nix store. TCP port 1883 on
`10.117.25.10` was reachable from the controller during implementation. That
only verifies network reachability: confirm Mosquitto authentication from the
service log after deploying.

## Adding the top G9

`instances.g9_top` is deliberately present but disabled. It therefore has
no systemd unit and cannot cause DDC retries while no monitor is attached.
Once connected, determine its connector without hardcoding its bus:

```sh
for connector in /sys/class/drm/card*-*; do
  test -e "$connector/ddc" || continue
  printf '%s -> %s\n' "$connector" "$(readlink -f "$connector/ddc")"
done
ddcutil detect
```

Set its physical connector and `enable = true`. Keep `nodeId = "g9_top"` so
it becomes the independent HA device `monitorctl_g9_top`. It will select the
same upstream LC49G95T profile from its EDID. Use the same feature overrides
only if the top monitor's input wiring and desired labels are also identical;
the labels are local desk policy, not characteristics of a G9.

```nix
services.monitorctl.instances.g9_top = {
  enable = true;
  connector = "/sys/class/drm/card*-DP-1"; # replace with the discovered port
  port = 8766;
  mqtt = {
    enable = true;
    host = "10.117.25.10";
    nodeId = "g9_top";
    deviceName = "Samsung Odyssey G9 (top)";
    credentialsFile = config.sops.secrets.monitorctl-mqtt.path;
  };
};
```

## Deployment and validation

```sh
# On the build machine: with no --build-host, nixos-rebuild builds locally,
# copies the closure over SSH, and activates it on the Wyse.
nixos-rebuild switch --flake /etc/nixos#g9-switcher \
  --target-host jay@g9-switcher --use-remote-sudo
ssh jay@g9-switcher 'sudo systemctl reboot'

# After it comes back:
ssh jay@g9-switcher 'systemctl status monitorctl-g9_bottom'
ssh jay@g9-switcher 'journalctl -u monitorctl-g9_bottom -b --no-pager'
ssh jay@g9-switcher 'curl http://127.0.0.1:8765/healthz'
ssh jay@g9-switcher 'cat /sys/class/drm/card*-HDMI-A-3/{status,enabled,dpms}'
```

In normal use, test state and commands through the HTTP UI/API or Home
Assistant. Confirm manual OSD input changes appear within the 15-second fast
poll interval. Restarting `monitorctl-g9_bottom` should republish the same retained
discovery topics, not create new entities, because its node ID and feature names
are unchanged.

Do not deliberately select a known-inactive DP input. The upstream
`local_video` guard is retained on the Wyse HDMI option; it rejects selecting
that input unless the DRM connector reports an active signal. Recovery from a
G9 DDC wedge by reactivating the HDMI link has not been tested on this headless
Intel/NixOS machine, so it is not claimed as supported.
