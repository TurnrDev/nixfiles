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

    implicitHeight: 74
    color: "transparent"
    focusable: false
    exclusiveZone: 74

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 10
        gradient: Gradient {
            GradientStop { position: 0.0; color: theme.barGradientTop }
            GradientStop { position: 1.0; color: theme.barGradientBottom }
        }
        radius: 26
        border.width: 1
        border.color: theme.outline

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            anchors.topMargin: 10
            anchors.bottomMargin: 10
            spacing: 12

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                radius: 20
                color: theme.surfaceAlt
                border.width: 1
                border.color: theme.outlineStrong
                implicitHeight: 40
                implicitWidth: workspaceRow.implicitWidth + 12

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
                                onClicked: rootRef.focusWorkspace(workspaceId)
                            }
                        }
                    }
                }
            }

            BarChip {
                Layout.fillWidth: true
                theme: panel.theme
                leftAligned: true
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
                highlighted: rootRef.quickSettingsVisible && rootRef.quickSettingsScreen === screenModel
                label: rootRef.systemState.network.label
                monospace: true
                onClicked: rootRef.toggleQuickSettings(screenModel)
            }

            BarChip {
                theme: panel.theme
                clickable: true
                subdued: rootRef.systemState.volume.muted
                label: rootRef.systemState.volume.label
                monospace: true
                onClicked: rootRef.runCommand(theme.volumeControlCommand)
            }

            BarChip {
                theme: panel.theme
                label: rootRef.systemState.brightness.label
                monospace: true
                subdued: true
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
                label: rootRef.timeLabel
                monospace: true
            }

            BarChip {
                theme: panel.theme
                clickable: true
                highlighted: true
                label: "󰐥"
                monospace: true
                onClicked: rootRef.runCommand(theme.powerMenuCommand)
            }
        }
    }
}
