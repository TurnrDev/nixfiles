import "."
import Quickshell
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: popup

    required property var screenModel
    required property var rootRef
    required property var theme

    screen: screenModel
    anchors {
        top: true
        right: true
    }

    implicitWidth: popupCard.width + 16
    implicitHeight: popupCard.implicitHeight + 86
    visible: rootRef.quickSettingsVisible && rootRef.quickSettingsScreen === screenModel
    color: "transparent"
    exclusiveZone: 0
    focusable: false

    Rectangle {
        id: popupCard
        width: 380
        implicitHeight: contentColumn.implicitHeight + 40
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 86
        anchors.rightMargin: 16
        radius: 28
        gradient: Gradient {
            GradientStop { position: 0.0; color: theme.popupGradientTop }
            GradientStop { position: 1.0; color: theme.popupGradientBottom }
        }
        border.width: 1
        border.color: theme.outline

        MouseArea {
            anchors.fill: parent
            onClicked: function(mouse) {
                mouse.accepted = true
            }
        }

        ColumnLayout {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            Text {
                text: "Quick Settings"
                color: theme.text
                font.family: theme.sansFamily
                font.pixelSize: 24
                font.weight: Font.DemiBold
            }

            Rectangle {
                Layout.fillWidth: true
                radius: 22
                color: theme.surface
                border.width: 1
                border.color: theme.outline
                implicitHeight: networkColumn.implicitHeight + 24

                ColumnLayout {
                    id: networkColumn
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 6

                    Text {
                        text: rootRef.systemState.network.label
                        color: theme.text
                        font.family: theme.sansFamily
                        font.pixelSize: 20
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: rootRef.systemState.network.detail
                        color: theme.textMuted
                        font.family: theme.sansFamily
                        font.pixelSize: 13
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                BarChip {
                    Layout.fillWidth: true
                    theme: popup.theme
                    clickable: true
                    label: rootRef.systemState.network.wifiEnabled ? "Disable Wi-Fi" : "Enable Wi-Fi"
                    onClicked: rootRef.runCommand(rootRef.systemState.network.wifiEnabled ? theme.wifiOffCommand : theme.wifiOnCommand)
                }

                BarChip {
                    Layout.fillWidth: true
                    theme: popup.theme
                    clickable: true
                    label: "Network Settings"
                    onClicked: rootRef.runCommand(theme.networkSettingsCommand)
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                BarChip {
                    Layout.fillWidth: true
                    theme: popup.theme
                    clickable: true
                    label: "Edit Connections"
                    onClicked: rootRef.runCommand(theme.connectionEditorCommand)
                }

                BarChip {
                    Layout.fillWidth: true
                    theme: popup.theme
                    clickable: true
                    label: "Volume Control"
                    onClicked: rootRef.runCommand(theme.volumeControlCommand)
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: theme.outline
                opacity: 0.75
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                BarChip {
                    Layout.fillWidth: true
                    theme: popup.theme
                    clickable: true
                    label: "Lock"
                    onClicked: {
                        rootRef.closeQuickSettings()
                        rootRef.runCommand(theme.lockCommand)
                    }
                }

                BarChip {
                    Layout.fillWidth: true
                    theme: popup.theme
                    clickable: true
                    highlighted: true
                    label: "Power Menu"
                    onClicked: {
                        rootRef.closeQuickSettings()
                        rootRef.runCommand(theme.powerMenuCommand)
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: "NetworkManager fallback stays available through KDE network settings and the connection editor while this shell layer settles in."
                color: theme.textMuted
                font.family: theme.sansFamily
                font.pixelSize: 12
                wrapMode: Text.Wrap
            }
        }
    }
}
