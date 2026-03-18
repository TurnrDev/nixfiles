import "."
import Quickshell
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: panel

    required property var screenModel
    required property var rootRef
    required property var theme

    screen: screenModel
    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 88
    color: "transparent"
    focusable: false
    exclusiveZone: 88

    MaterialCard {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        anchors.topMargin: 10
        anchors.bottomMargin: 8
        theme: panel.theme
        tone: "surface"
        outlined: true
        cornerRadius: 32

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.topMargin: 12
            anchors.bottomMargin: 12
            spacing: 10

            MaterialCard {
                Layout.alignment: Qt.AlignVCenter
                implicitHeight: 56
                implicitWidth: workspaceRow.implicitWidth + 18
                theme: panel.theme
                tone: "surfaceContainer"
                cornerRadius: 26

                Row {
                    id: workspaceRow
                    anchors.centerIn: parent
                    spacing: 6

                    Repeater {
                        model: 10

                        delegate: Item {
                            readonly property int workspaceNumber: rootRef.hyprState.workspaceStart + index
                            implicitWidth: chip.implicitWidth
                            implicitHeight: chip.implicitHeight

                            WorkspaceChip {
                                id: chip
                                theme: panel.theme
                                workspaceId: parent.workspaceNumber
                                active: parent.workspaceNumber === rootRef.hyprState.activeWorkspace
                                occupied: rootRef.hyprState.occupied.indexOf(parent.workspaceNumber) !== -1
                                onClicked: function(workspaceId) {
                                    rootRef.focusWorkspace(workspaceId)
                                }
                            }
                        }
                    }
                }
            }

            BarChip {
                Layout.fillWidth: true
                theme: panel.theme
                leftAligned: true
                subdued: true
                label: rootRef.hyprState.activeWindow === "" ? "Desktop" : rootRef.hyprState.activeWindow
            }

            BarChip {
                visible: rootRef.systemState.media !== ""
                theme: panel.theme
                leftAligned: true
                label: rootRef.systemState.media
                subdued: true
            }

            BarChip {
                theme: panel.theme
                clickable: true
                highlighted: true
                label: rootRef.systemState.network.connected && rootRef.systemState.network.currentSsid !== ""
                    ? "󰤨 " + rootRef.systemState.network.currentSsid
                    : rootRef.systemState.network.label
                onClicked: function() {
                    rootRef.toggleQuickSettings(screenModel)
                }
            }

            BarChip {
                theme: panel.theme
                clickable: true
                subdued: rootRef.systemState.volume.muted
                label: rootRef.systemState.volume.label
                monospace: true
                onClicked: function() {
                    rootRef.runCommand(theme.volumeControlCommand)
                }
            }

            BarChip {
                theme: panel.theme
                subdued: true
                label: rootRef.systemState.brightness.label
                monospace: true
            }

            BarChip {
                visible: rootRef.systemState.battery.present
                theme: panel.theme
                subdued: !rootRef.systemState.battery.charging
                highlighted: rootRef.systemState.battery.charging
                label: rootRef.systemState.battery.label
                monospace: true
            }

            BarChip {
                theme: panel.theme
                subdued: true
                label: rootRef.timeLabel
                monospace: true
            }

            BarChip {
                theme: panel.theme
                clickable: true
                danger: true
                label: "󰐥"
                monospace: true
                onClicked: function() {
                    rootRef.runCommand(theme.powerMenuCommand)
                }
            }
        }
    }
}
