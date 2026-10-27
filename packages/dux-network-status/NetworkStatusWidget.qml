import QtQuick
import Quickshell.Io
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import qs.Modules.ControlCenter
import qs.Modules.ControlCenter.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property var status: ({ networkManager: [], tailscale: {}, tailnets: [] })
    property int refreshSeconds: pluginData.refreshSeconds || 15
    readonly property bool tailscaleConnected: status.tailscale.BackendState === "Running"
    readonly property bool anyConnected: tailscaleConnected
        || status.networkManager.some(profile => profile.active)

    function scriptPath(name) {
        return Qt.resolvedUrl(name).toString().replace("file://", "");
    }

    function refresh() {
        if (!statusProcess.running)
            statusProcess.running = true;
    }

    function toggle(kind, target, active) {
        if (toggleProcess.running)
            return;
        toggleProcess.command = ["sh", scriptPath("network-toggle.sh"), kind, target, active ? "active" : "inactive"];
        toggleProcess.running = true;
    }

    Timer {
        interval: root.refreshSeconds * 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Process {
        id: statusProcess
        command: ["sh", root.scriptPath("network-status.sh")]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.status = JSON.parse(this.text);
                } catch (error) {
                    ToastService.showError("Could not read VPN status");
                }
            }
        }
    }

    Process {
        id: toggleProcess
        onExited: root.refresh()
    }

    ccWidgetIcon: anyConnected ? "vpn_key" : "vpn_key_off"
    ccWidgetPrimaryText: "VPN & Tailnet"
    ccWidgetSecondaryText: {
        const active = status.networkManager.filter(profile => profile.active).length
            + (tailscaleConnected ? 1 : 0);
        return active > 0 ? `${active} connected` : "Disconnected";
    }
    ccWidgetIsActive: anyConnected
    onCcWidgetToggled: toggle("tailscale", "", tailscaleConnected)
    onCcWidgetExpanded: refresh()

    ccDetailContent: Component {
        Item {
            id: detailRoot
            readonly property Item headerActions: DActionButton {
                buttonSize: Theme.iconButtonSize
                iconSize: Theme.iconSize
                iconName: "sync"
                iconColor: Theme.surfaceText
                Accessible.name: "Refresh"
                onClicked: root.refresh()
            }

            DFlickable {
                anchors.fill: parent
                contentHeight: detailColumn.height
                clip: true

                Column {
                    id: detailColumn
                    width: parent.width
                    spacing: CcMetrics.detailContentGap

                    CcGroup {
                        visible: root.status.networkManager.length > 0

                        Repeater {
                            model: root.status.networkManager

                            CcToggleRow {
                                required property var modelData
                                iconName: "vpn_key"
                                iconColor: modelData.active ? Theme.primary : Theme.surfaceText
                                text: modelData.name
                                description: modelData.type === "wireguard" ? "WireGuard · NetworkManager" : "VPN · NetworkManager"
                                checked: modelData.active
                                onToggled: checked => root.toggle("networkmanager", modelData.uuid, !checked)
                            }
                        }
                    }

                    CcGroup {
                        CcToggleRow {
                            iconName: "device_hub"
                            iconColor: root.tailscaleConnected ? Theme.primary : Theme.surfaceText
                            text: "Tailscale"
                            description: root.status.tailscale.CurrentTailnet?.Name || "Not connected"
                            checked: root.tailscaleConnected
                            onToggled: checked => root.toggle("tailscale", "", !checked)
                        }

                        Repeater {
                            model: root.status.tailnets

                            CcListRow {
                                required property var modelData
                                iconName: "account_tree"
                                title: modelData.nickname || modelData.tailnet
                                subtitle: modelData.tailnet || ""
                                active: modelData.selected
                                clickable: !modelData.selected
                                onClicked: root.toggle("tailnet", modelData.id, false)
                                trailingBadge: modelData.selected ? "Current" : "Switch"
                                trailingBadgeColor: modelData.selected ? Theme.primary : Theme.surfaceVariantText
                            }
                        }
                    }
                }
            }
        }
    }
}
