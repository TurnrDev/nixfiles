{ config, pkgs, lib, ... }:

with config.lib.stylix.colors.withHashtag;

let
  nmcli = "${pkgs.networkmanager}/bin/nmcli";
  wpctl = "${pkgs.wireplumber}/bin/wpctl";

  hyprState = pkgs.writeShellScriptBin "jay-quickshell-hypr-state" ''
    set -euo pipefail

    active_workspace="$(${pkgs.hyprland}/bin/hyprctl activeworkspace -j 2>/dev/null | ${pkgs.jq}/bin/jq '.id // 1' 2>/dev/null || printf '1')"

    if [[ "$active_workspace" =~ ^-?[0-9]+$ ]] && [ "$active_workspace" -lt 1 ]; then
      active_workspace=1
    fi

    workspace_start=$(( ((active_workspace - 1) / 10) * 10 + 1 ))
    workspaces_json="$(${pkgs.hyprland}/bin/hyprctl workspaces -j 2>/dev/null || printf '[]')"
    window_json="$(${pkgs.hyprland}/bin/hyprctl activewindow -j 2>/dev/null || printf '{}')"

    ${pkgs.jq}/bin/jq -n \
      --argjson activeWorkspace "$active_workspace" \
      --argjson workspaceStart "$workspace_start" \
      --argjson workspaces "$workspaces_json" \
      --argjson window "$window_json" '
        {
          workspaceStart: $workspaceStart,
          activeWorkspace: $activeWorkspace,
          occupied: (
            $workspaces
            | [
                .[]
                | .id
                | select(type == "number" and . >= $workspaceStart and . < ($workspaceStart + 10))
              ]
          ),
          activeWindow: (
            ($window.title // $window.initialTitle // $window.class // "Desktop")
            | tostring
            | gsub("[\r\n\t]+"; " ")
            | gsub(" +"; " ")
            | if length > 72 then .[0:69] + "..." else . end
          )
        }
      '
  '';

  systemState = pkgs.writeShellScriptBin "jay-quickshell-system-state" ''
    set -euo pipefail

    media=""
    if media_raw="$(${pkgs.playerctl}/bin/playerctl metadata --format '{{ artist }} - {{ title }}' 2>/dev/null)" && [[ -n "$media_raw" ]]; then
      media="󰎆 $media_raw"
      media="''${media//$'\n'/ }"
      if [ "''${#media}" -gt 52 ]; then
        media="''${media:0:49}..."
      fi
    fi

    volume_label="󰕿 --"
    volume_muted=false
    if volume_raw="$(${wpctl} get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)" && [[ -n "$volume_raw" ]]; then
      if [[ "$volume_raw" == *MUTED* ]]; then
        volume_muted=true
      fi

      if [[ "$volume_raw" =~ ([0-9]+(\.[0-9]+)?) ]]; then
        volume_percent="$(${pkgs.gawk}/bin/awk -v value="''${BASH_REMATCH[1]}" 'BEGIN { printf "%d", value * 100 }')"
        if [ "$volume_muted" = true ]; then
          volume_label="󰝟 muted"
        elif [ "$volume_percent" -lt 34 ]; then
          volume_label="󰕿 ''${volume_percent}%"
        elif [ "$volume_percent" -lt 67 ]; then
          volume_label="󰖀 ''${volume_percent}%"
        else
          volume_label="󰕾 ''${volume_percent}%"
        fi
      fi
    fi

    brightness_label="󰃞 --"
    if brightness_raw="$(${pkgs.brightnessctl}/bin/brightnessctl -m 2>/dev/null)" && [[ -n "$brightness_raw" ]]; then
      IFS=, read -r _ _ _ brightness_percent _ <<< "$brightness_raw"
      brightness_percent="''${brightness_percent%%%}"
      brightness_label="󰃞 ''${brightness_percent}%"
    fi

    battery_present=false
    battery_label=""
    battery_charging=false
    battery_dir=""
    for candidate in /sys/class/power_supply/BAT*; do
      if [ -d "$candidate" ]; then
        battery_dir="$candidate"
        break
      fi
    done

    if [ -n "$battery_dir" ]; then
      battery_present=true
      battery_capacity="$(<"$battery_dir/capacity")"
      battery_status="$(<"$battery_dir/status")"

      case "$battery_status" in
        Charging)
          battery_charging=true
          battery_label="󰂄 ''${battery_capacity}%"
          ;;
        Full)
          battery_charging=true
          battery_label="󰁹 ''${battery_capacity}%"
          ;;
        *)
          if [ "$battery_capacity" -ge 95 ]; then
            battery_icon="󰁹"
          elif [ "$battery_capacity" -ge 80 ]; then
            battery_icon="󰂂"
          elif [ "$battery_capacity" -ge 60 ]; then
            battery_icon="󰂀"
          elif [ "$battery_capacity" -ge 40 ]; then
            battery_icon="󰁾"
          elif [ "$battery_capacity" -ge 20 ]; then
            battery_icon="󰁼"
          else
            battery_icon="󰁺"
          fi
          battery_label="''${battery_icon} ''${battery_capacity}%"
          ;;
      esac
    fi

    wifi_enabled=false
    wifi_state="$(${nmcli} radio wifi 2>/dev/null || printf 'disabled')"
    if [ "$wifi_state" = "enabled" ]; then
      wifi_enabled=true
    fi

    connected_device=""
    while IFS=: read -r device state; do
      case "$state" in
        connected|connected\ \(externally\))
          connected_device="$device"
          break
          ;;
      esac
    done < <(${nmcli} -t -f DEVICE,STATE dev status 2>/dev/null || true)

    network_connected=false
    network_label="Offline"
    network_detail="No active connection"

    if [ -n "$connected_device" ]; then
      network_connected=true
      network_type="$(${nmcli} -g GENERAL.TYPE dev show "$connected_device" 2>/dev/null | ${pkgs.coreutils}/bin/head -n 1 || true)"
      network_connection="$(${nmcli} -g GENERAL.CONNECTION dev show "$connected_device" 2>/dev/null | ${pkgs.coreutils}/bin/head -n 1 || true)"
      network_ip="$(${nmcli} -g IP4.ADDRESS dev show "$connected_device" 2>/dev/null | ${pkgs.coreutils}/bin/head -n 1 || true)"
      network_ip="''${network_ip%%/*}"

      case "$network_type" in
        *wireless*|wifi)
          network_label="󰤨 ''${network_connection:-Wi-Fi}"
          ;;
        *ethernet*)
          network_label="󰈀 Wired"
          ;;
        *)
          network_label="󰲝 ''${network_connection:-Online}"
          ;;
      esac

      if [ -n "$network_ip" ]; then
        network_detail="$connected_device  •  $network_ip"
      else
        network_detail="$connected_device"
      fi
    elif [ "$wifi_enabled" = false ]; then
      network_label="󰤮 Wi-Fi off"
      network_detail="Wireless disabled"
    fi

    ${pkgs.jq}/bin/jq -n \
      --arg media "$media" \
      --arg networkLabel "$network_label" \
      --arg networkDetail "$network_detail" \
      --arg volumeLabel "$volume_label" \
      --arg brightnessLabel "$brightness_label" \
      --arg batteryLabel "$battery_label" \
      --argjson wifiEnabled "$wifi_enabled" \
      --argjson networkConnected "$network_connected" \
      --argjson volumeMuted "$volume_muted" \
      --argjson batteryPresent "$battery_present" \
      --argjson batteryCharging "$battery_charging" '
        {
          media: $media,
          network: {
            label: $networkLabel,
            detail: $networkDetail,
            connected: $networkConnected,
            wifiEnabled: $wifiEnabled
          },
          volume: {
            label: $volumeLabel,
            muted: $volumeMuted
          },
          brightness: {
            label: $brightnessLabel
          },
          battery: {
            present: $batteryPresent,
            label: $batteryLabel,
            charging: $batteryCharging
          }
        }
      '
  '';

  themeFile = pkgs.writeTextDir "Theme.qml" ''
    import QtQuick

    QtObject {
      readonly property color background: "${base00}"
      readonly property color surface: "${base01}"
      readonly property color surfaceAlt: "${base02}"
      readonly property color popupSurface: "${base01}"
      readonly property color outline: "${base03}"
      readonly property color outlineStrong: "${base0B}"
      readonly property color text: "${base07}"
      readonly property color textMuted: "${base05}"
      readonly property color accent: "${base0B}"
      readonly property color accentStrong: "${base0D}"
      readonly property color warning: "${base09}"
      readonly property color danger: "${base08}"
      readonly property color barGradientTop: "${base01}"
      readonly property color barGradientBottom: "${base00}"
      readonly property color popupGradientTop: "${base02}"
      readonly property color popupGradientBottom: "${base01}"
      readonly property color scrim: "#990e1513"

      readonly property string sansFamily: "${config.stylix.fonts.sansSerif.name}"
      readonly property string monoFamily: "${config.stylix.fonts.monospace.name}"
      readonly property string hyprctlBin: "${pkgs.hyprland}/bin/hyprctl"

      readonly property var hyprStateCommand: [ "${lib.getExe hyprState}" ]
      readonly property var systemStateCommand: [ "${lib.getExe systemState}" ]
      readonly property var lockCommand: [ "${config.jay.commands.lock}" ]
      readonly property var volumeControlCommand: [ "${lib.getExe pkgs.pwvucontrol}" ]
      readonly property var networkSettingsCommand: [ "${pkgs.kdePackages.systemsettings}/bin/systemsettings", "kcm_networkmanagement" ]
      readonly property var connectionEditorCommand: [ "${pkgs.networkmanagerapplet}/bin/nm-connection-editor" ]
      readonly property var wifiOnCommand: [ "${nmcli}", "radio", "wifi", "on" ]
      readonly property var wifiOffCommand: [ "${nmcli}", "radio", "wifi", "off" ]
      readonly property var powerMenuCommand: [ "${config.jay.commands.powerMenu}" ]
    }
  '';

  quickshellConfig = pkgs.runCommand "jay-quickshell-config" { } ''
    mkdir -p "$out"
    cp -r ${./config}/. "$out/"
    cp ${themeFile}/Theme.qml "$out/Theme.qml"
  '';
in
{
  home.packages = [
    hyprState
    systemState
    pkgs.brightnessctl
    pkgs.kdePackages.plasma-nm
    pkgs.networkmanagerapplet
    pkgs.pwvucontrol
  ];

  programs.quickshell = {
    enable = true;
    activeConfig = "jay";
    configs.jay = quickshellConfig;
    systemd = {
      enable = true;
      target = "hyprland-session.target";
    };
  };

  systemd.user.services.quickshell = {
    Unit = {
      ConditionEnvironment = lib.mkForce [
        "WAYLAND_DISPLAY"
        "HYPRLAND_INSTANCE_SIGNATURE"
      ];
      PartOf = lib.mkForce [ "hyprland-session.target" ];
    };
  };
}
