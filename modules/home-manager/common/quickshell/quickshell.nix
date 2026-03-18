{ config, pkgs, lib, ... }:

with config.lib.stylix.colors.withHashtag;

let
  nmcli = "${pkgs.networkmanager}/bin/nmcli";
  wpctl = "${pkgs.wireplumber}/bin/wpctl";

  networkMenu = pkgs.writeShellScriptBin "jay-network-menu" ''
    set -euo pipefail

    fuzzel='${lib.getExe pkgs.fuzzel}'
    notify='${pkgs.libnotify}/bin/notify-send'

    prompt_password() {
      "$fuzzel" --dmenu --prompt-only='passphrase> ' --placeholder "$1" --password --width 34
    }

    wifi_device="$(${nmcli} -t -f DEVICE,TYPE device status | ${pkgs.gawk}/bin/awk -F: '$2 == "wifi" { print $1; exit }')"
    if [ -z "$wifi_device" ]; then
      "$notify" "Wi-Fi unavailable" "NetworkManager did not report a wireless device."
      exit 1
    fi

    wifi_state="$(${nmcli} radio wifi 2>/dev/null || printf 'disabled')"
    if [ "$wifi_state" != "enabled" ]; then
      action="$(printf '%s\n' "Enable Wi-Fi" "Open terminal network UI" | "$fuzzel" --dmenu --prompt 'network> ' --placeholder 'Wi-Fi is disabled' --lines 2 --width 32)"

      case "$action" in
        "Enable Wi-Fi")
          ${nmcli} radio wifi on
          ;;
        "Open terminal network UI")
          exec ${lib.getExe pkgs.foot} -e ${pkgs.networkmanager}/bin/nmtui
          ;;
        *)
          exit 0
          ;;
      esac

      sleep 1
    fi

    mapfile -t raw_networks < <(${nmcli} -t -f IN-USE,SIGNAL,SECURITY,SSID device wifi list ifname "$wifi_device" --rescan yes 2>/dev/null)
    if [ "''${#raw_networks[@]}" -eq 0 ]; then
      "$notify" "No Wi-Fi networks found" "NetworkManager did not return any nearby networks."
      exit 1
    fi

    display_networks=()
    network_records=()
    declare -A best_signal_by_ssid=()
    declare -A security_by_ssid=()
    declare -A active_by_ssid=()
    ordered_ssids=()

    for entry in "''${raw_networks[@]}"; do
      IFS=: read -r in_use signal security ssid <<< "$entry"
      [ -n "''${ssid:-}" ] || continue
      signal="''${signal:-0}"

      if [ -z "''${best_signal_by_ssid[$ssid]+x}" ]; then
        ordered_ssids+=("$ssid")
        best_signal_by_ssid[$ssid]="$signal"
        security_by_ssid[$ssid]="''${security:-}"
        active_by_ssid[$ssid]=false
      fi

      if [ "$in_use" = "*" ]; then
        active_by_ssid[$ssid]=true
      fi

      if [ -n "''${security:-}" ] && [ "$security" != "--" ]; then
        security_by_ssid[$ssid]="$security"
      fi

      if [ "$signal" -gt "''${best_signal_by_ssid[$ssid]}" ]; then
        best_signal_by_ssid[$ssid]="$signal"
      fi
    done

    for ssid in "''${ordered_ssids[@]}"; do
      signal="''${best_signal_by_ssid[$ssid]}"
      security="''${security_by_ssid[$ssid]}"
      is_active="''${active_by_ssid[$ssid]}"

      if [ "$signal" -ge 80 ]; then
        signal_icon="󰤨"
      elif [ "$signal" -ge 60 ]; then
        signal_icon="󰤥"
      elif [ "$signal" -ge 35 ]; then
        signal_icon="󰤢"
      else
        signal_icon="󰤟"
      fi

      active_prefix=""
      if [ "$is_active" = true ]; then
        active_prefix="󰄬 "
      fi

      security_suffix=""
      if [ -n "$security" ] && [ "$security" != "--" ]; then
        security_suffix="  󰌾"
      fi

      display_networks+=("$active_prefix$signal_icon $ssid$security_suffix")
      network_records+=("$ssid"$'\t'"$security")
    done

    if [ "''${#display_networks[@]}" -eq 0 ]; then
      "$notify" "No Wi-Fi networks found" "Only hidden or empty-SSID networks were reported."
      exit 1
    fi

    selection_index="$(printf '%s\n' "''${display_networks[@]}" | "$fuzzel" --dmenu --prompt 'wifi> ' --placeholder 'Choose a network' --lines 12 --width 44 --index)"
    [ -n "$selection_index" ] || exit 0

    IFS=$'\t' read -r selected_ssid selected_security <<< "''${network_records[$selection_index]}"
    [ -n "$selected_ssid" ] || exit 0

    if ${nmcli} --wait 20 device wifi connect "$selected_ssid" ifname "$wifi_device"; then
      "$notify" "Wi-Fi connected" "Joined $selected_ssid."
      exit 0
    fi

    if [ -z "''${selected_security:-}" ] || [ "$selected_security" = "--" ]; then
      "$notify" "Wi-Fi failed" "Couldn't connect to $selected_ssid."
      exit 1
    fi

    password="$(prompt_password "Password for $selected_ssid")"
    [ -n "$password" ] || exit 0

    if ${nmcli} --wait 20 device wifi connect "$selected_ssid" ifname "$wifi_device" password "$password"; then
      "$notify" "Wi-Fi connected" "Joined $selected_ssid."
    else
      "$notify" "Wi-Fi failed" "Couldn't connect to $selected_ssid with the supplied password."
      exit 1
    fi
  '';

  networkTerminal = pkgs.writeShellScriptBin "jay-network-terminal" ''
    exec ${lib.getExe pkgs.foot} -e ${pkgs.networkmanager}/bin/nmtui
  '';

  networkScan = pkgs.writeShellScriptBin "jay-quickshell-network-scan" ''
    set -euo pipefail

    unescape_nmcli_field() {
      printf '%s' "''${1//$'\037'/:}"
    }

    wifi_enabled=false
    wifi_state="$(${nmcli} radio wifi 2>/dev/null || printf 'disabled')"
    if [ "$wifi_state" = "enabled" ]; then
      wifi_enabled=true
    fi

    wifi_device="$(${nmcli} -t -f DEVICE,TYPE device status 2>/dev/null | ${pkgs.gawk}/bin/awk -F: '$2 == "wifi" { print $1; exit }' || true)"
    has_wifi_device=false
    if [ -n "$wifi_device" ]; then
      has_wifi_device=true
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
    current_ssid=""
    current_device=""
    current_ip=""

    if [ -n "$connected_device" ]; then
      network_connected=true
      current_device="$connected_device"
      network_type="$(${nmcli} -g GENERAL.TYPE dev show "$connected_device" 2>/dev/null | ${pkgs.coreutils}/bin/head -n 1 || true)"
      network_connection="$(${nmcli} -g GENERAL.CONNECTION dev show "$connected_device" 2>/dev/null | ${pkgs.coreutils}/bin/head -n 1 || true)"
      network_ip="$(${nmcli} -g IP4.ADDRESS dev show "$connected_device" 2>/dev/null | ${pkgs.coreutils}/bin/head -n 1 || true)"
      current_ip="''${network_ip%%/*}"

      case "$network_type" in
        *wireless*|wifi)
          current_ssid="$network_connection"
          network_label="󰤨 ''${network_connection:-Wi-Fi}"
          ;;
        *ethernet*)
          network_label="󰈀 Wired"
          ;;
        *)
          network_label="󰲝 ''${network_connection:-Online}"
          ;;
      esac

      if [ -n "$current_ip" ]; then
        network_detail="$connected_device  •  $current_ip"
      else
        network_detail="$connected_device"
      fi
    elif [ "$wifi_enabled" = false ]; then
      network_label="󰤮 Wi-Fi off"
      network_detail="Wireless disabled"
    elif [ "$has_wifi_device" = true ]; then
      network_label="󰤯 Wi-Fi ready"
      network_detail="Select a network to connect"
    else
      network_label="󰤭 No Wi-Fi"
      network_detail="No wireless adapter detected"
    fi

    declare -A best_signal_by_ssid=()
    declare -A security_by_ssid=()
    declare -A active_by_ssid=()
    ordered_ssids=()

    if [ "$wifi_enabled" = true ] && [ "$has_wifi_device" = true ]; then
      mapfile -t raw_networks < <(${nmcli} -t -f IN-USE,SIGNAL,SECURITY,SSID device wifi list ifname "$wifi_device" --rescan yes 2>/dev/null || true)

      for entry in "''${raw_networks[@]}"; do
        safe_entry="''${entry//\\:/$'\037'}"
        IFS=: read -r in_use signal security ssid <<< "$safe_entry"

        ssid="$(unescape_nmcli_field "''${ssid:-}")"
        security="$(unescape_nmcli_field "''${security:-}")"
        [ -n "$ssid" ] || continue

        signal="''${signal:-0}"

        if [ -z "''${best_signal_by_ssid[$ssid]+x}" ]; then
          ordered_ssids+=("$ssid")
          best_signal_by_ssid[$ssid]="$signal"
          security_by_ssid[$ssid]="$security"
          active_by_ssid[$ssid]=false
        fi

        if [ "$in_use" = "*" ]; then
          active_by_ssid[$ssid]=true
        fi

        if [ -n "$security" ] && [ "$security" != "--" ]; then
          security_by_ssid[$ssid]="$security"
        fi

        if [ "$signal" -gt "''${best_signal_by_ssid[$ssid]}" ]; then
          best_signal_by_ssid[$ssid]="$signal"
        fi
      done
    fi

    network_records=()
    for ssid in "''${ordered_ssids[@]}"; do
      network_records+=("$ssid"$'\t'"''${security_by_ssid[$ssid]:---}"$'\t'"''${best_signal_by_ssid[$ssid]:-0}"$'\t'"''${active_by_ssid[$ssid]:-false}")
    done

    network_json="$(
      printf '%s\n' "''${network_records[@]}" | ${pkgs.jq}/bin/jq -R -s '
        split("\n")
        | map(select(length > 0))
        | map(split("\t"))
        | map({
            ssid: .[0],
            security: .[1],
            secure: (.[1] != "" and .[1] != "--"),
            signal: ((.[2] | tonumber?) // 0),
            active: (.[3] == "true")
          })
        | sort_by([if .active then 0 else 1 end, -.signal, .ssid])
      '
    )"

    ${pkgs.jq}/bin/jq -n \
      --arg label "$network_label" \
      --arg detail "$network_detail" \
      --arg currentSsid "$current_ssid" \
      --arg currentDevice "$current_device" \
      --arg ipAddress "$current_ip" \
      --argjson wifiEnabled "$wifi_enabled" \
      --argjson connected "$network_connected" \
      --argjson hasWifiDevice "$has_wifi_device" \
      --argjson scanResults "$network_json" '
        {
          network: {
            label: $label,
            detail: $detail,
            wifiEnabled: $wifiEnabled,
            connected: $connected,
            currentSsid: $currentSsid,
            currentDevice: $currentDevice,
            ipAddress: $ipAddress,
            hasWifiDevice: $hasWifiDevice,
            scanResults: $scanResults
          }
        }
      '
  '';

  networkConnect = pkgs.writeShellScriptBin "jay-quickshell-network-connect" ''
    set -euo pipefail

    ssid="''${1:-}"
    password="''${2:-}"

    if [ -z "$ssid" ]; then
      ${pkgs.jq}/bin/jq -n --arg message "No network selected." '{ ok: false, message: $message }'
      exit 1
    fi

    wifi_device="$(${nmcli} -t -f DEVICE,TYPE device status 2>/dev/null | ${pkgs.gawk}/bin/awk -F: '$2 == "wifi" { print $1; exit }' || true)"
    if [ -z "$wifi_device" ]; then
      ${pkgs.jq}/bin/jq -n --arg message "NetworkManager did not report a wireless device." '{ ok: false, message: $message }'
      exit 1
    fi

    if [ -n "$password" ]; then
      if ${nmcli} --wait 20 device wifi connect "$ssid" ifname "$wifi_device" password "$password" >/dev/null 2>&1; then
        ${pkgs.jq}/bin/jq -n --arg message "Connected to $ssid." '{ ok: true, message: $message }'
        exit 0
      fi
    elif ${nmcli} --wait 20 device wifi connect "$ssid" ifname "$wifi_device" >/dev/null 2>&1; then
      ${pkgs.jq}/bin/jq -n --arg message "Connected to $ssid." '{ ok: true, message: $message }'
      exit 0
    fi

    if [ -n "$password" ]; then
      ${pkgs.jq}/bin/jq -n --arg message "Couldn't connect to $ssid with that password." '{ ok: false, message: $message }'
    else
      ${pkgs.jq}/bin/jq -n --arg message "Couldn't connect to $ssid. Leave the password blank only for saved networks." '{ ok: false, message: $message }'
    fi
    exit 1
  '';

  volumeControl = pkgs.writeShellScriptBin "jay-quickshell-volume-control" ''
    set -euo pipefail

    action="''${1:-}"
    value="''${2:-}"

    clamp_percent() {
      local candidate="$1"
      if ! [[ "$candidate" =~ ^[0-9]+$ ]]; then
        candidate=0
      fi

      if [ "$candidate" -lt 0 ]; then
        candidate=0
      elif [ "$candidate" -gt 100 ]; then
        candidate=100
      fi

      printf '%s' "$candidate"
    }

    case "$action" in
      set)
        percent="$(clamp_percent "$value")"
        ${wpctl} set-volume @DEFAULT_AUDIO_SINK@ "$percent%"
        ;;
      toggle-mute)
        ${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle
        ;;
      *)
        printf 'Unknown volume action: %s\n' "$action" >&2
        exit 1
        ;;
    esac
  '';

  brightnessControl = pkgs.writeShellScriptBin "jay-quickshell-brightness-control" ''
    set -euo pipefail

    action="''${1:-}"
    value="''${2:-}"

    clamp_percent() {
      local candidate="$1"
      if ! [[ "$candidate" =~ ^[0-9]+$ ]]; then
        candidate=5
      fi

      if [ "$candidate" -lt 5 ]; then
        candidate=5
      elif [ "$candidate" -gt 100 ]; then
        candidate=100
      fi

      printf '%s' "$candidate"
    }

    case "$action" in
      set)
        percent="$(clamp_percent "$value")"
        ${pkgs.brightnessctl}/bin/brightnessctl set "$percent%"
        ;;
      *)
        printf 'Unknown brightness action: %s\n' "$action" >&2
        exit 1
        ;;
    esac
  '';

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
    volume_percent=0
    volume_muted=false
    if volume_raw="$(${wpctl} get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)" && [[ -n "$volume_raw" ]]; then
      if [[ "$volume_raw" == *MUTED* ]]; then
        volume_muted=true
      fi

      if [[ "$volume_raw" =~ ([0-9]+(\.[0-9]+)?) ]]; then
        volume_percent="$(${pkgs.gawk}/bin/awk -v value="''${BASH_REMATCH[1]}" 'BEGIN { printf "%d", value * 100 }')"
        if [ "$volume_percent" -gt 100 ]; then
          volume_percent=100
        fi
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
    brightness_percent=50
    if brightness_raw="$(${pkgs.brightnessctl}/bin/brightnessctl -m 2>/dev/null)" && [[ -n "$brightness_raw" ]]; then
      IFS=, read -r _ _ _ brightness_percent _ <<< "$brightness_raw"
      brightness_percent="''${brightness_percent%%%}"
      if [ -z "$brightness_percent" ]; then
        brightness_percent=50
      fi
      brightness_label="󰃞 ''${brightness_percent}%"
    fi

    battery_present=false
    battery_percent=0
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
      battery_percent="$battery_capacity"
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

    wifi_device="$(${nmcli} -t -f DEVICE,TYPE device status 2>/dev/null | ${pkgs.gawk}/bin/awk -F: '$2 == "wifi" { print $1; exit }' || true)"

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
    elif [ -n "$wifi_device" ]; then
      network_label="󰤯 Wi-Fi ready"
      network_detail="Select a network to connect"
    else
      network_label="󰤭 No Wi-Fi"
      network_detail="No wireless adapter detected"
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
      --argjson volumePercent "$volume_percent" \
      --argjson brightnessPercent "$brightness_percent" \
      --argjson batteryPresent "$battery_present" \
      --argjson batteryPercent "$battery_percent" \
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
            muted: $volumeMuted,
            percent: $volumePercent
          },
          brightness: {
            label: $brightnessLabel,
            percent: $brightnessPercent
          },
          battery: {
            present: $batteryPresent,
            label: $batteryLabel,
            charging: $batteryCharging,
            percent: $batteryPercent
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
      readonly property color surfaceContainerLow: "${base00}"
      readonly property color surfaceContainer: "${base01}"
      readonly property color surfaceContainerHigh: "${base02}"
      readonly property color surfaceContainerHighest: "${base02}"
      readonly property color popupSurface: "${base01}"
      readonly property color outline: "${base03}"
      readonly property color outlineVariant: "${base03}"
      readonly property color outlineStrong: "${base04}"
      readonly property color text: "${base07}"
      readonly property color textMuted: "${base05}"
      readonly property color accent: "${base0B}"
      readonly property color accentStrong: "${base0D}"
      readonly property color primary: "${base0B}"
      readonly property color primaryContainer: "${base0C}"
      readonly property color primaryContainerForeground: "${base07}"
      readonly property color primaryOutline: "${base0B}"
      readonly property color secondaryContainer: "${base01}"
      readonly property color secondaryContainerForeground: "${base07}"
      readonly property color warning: "${base09}"
      readonly property color danger: "${base08}"
      readonly property color dangerContainer: "${base08}"
      readonly property color dangerContainerForeground: "${base00}"
      readonly property color barGradientTop: "${base01}"
      readonly property color barGradientBottom: "${base00}"
      readonly property color popupGradientTop: "${base02}"
      readonly property color popupGradientBottom: "${base01}"
      readonly property color scrim: "#990e1513"
      readonly property color scrimStrong: "#cc0e1513"

      readonly property string sansFamily: "${config.stylix.fonts.sansSerif.name}"
      readonly property string monoFamily: "${config.stylix.fonts.monospace.name}"
      readonly property string hyprctlBin: "${pkgs.hyprland}/bin/hyprctl"

      readonly property var hyprStateCommand: [ "${lib.getExe hyprState}" ]
      readonly property var systemStateCommand: [ "${lib.getExe systemState}" ]
      readonly property var networkScanCommand: [ "${lib.getExe networkScan}" ]
      readonly property var networkConnectCommandPrefix: [ "${lib.getExe networkConnect}" ]
      readonly property var lockCommand: [ "${config.jay.commands.lock}" ]
      readonly property var networkMenuCommand: [ "${lib.getExe networkMenu}" ]
      readonly property var networkTerminalCommand: [ "${lib.getExe networkTerminal}" ]
      readonly property var volumeMuteCommand: [ "${lib.getExe volumeControl}", "toggle-mute" ]
      readonly property var volumeSetCommandPrefix: [ "${lib.getExe volumeControl}", "set" ]
      readonly property var brightnessSetCommandPrefix: [ "${lib.getExe brightnessControl}", "set" ]
      readonly property var volumeControlCommand: [ "${lib.getExe pkgs.pwvucontrol}" ]
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
    networkScan
    networkConnect
    volumeControl
    brightnessControl
    pkgs.brightnessctl
    networkMenu
    networkTerminal
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
