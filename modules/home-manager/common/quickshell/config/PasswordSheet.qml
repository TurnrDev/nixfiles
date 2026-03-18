import "."
import QtQuick
import QtQuick.Layouts

Item {
    id: sheet

    required property var theme
    property bool sheetVisible: false
    property string ssid: ""
    property string errorText: ""
    property bool pending: false
    property alias password: passwordInput.text
    signal canceled
    signal submitted

    anchors.fill: parent
    visible: opacity > 0.01
    opacity: sheetVisible ? 1 : 0
    z: 40

    Behavior on opacity {
        NumberAnimation {
            duration: 140
        }
    }

    onSheetVisibleChanged: {
        if (sheetVisible)
            passwordInput.forceActiveFocus()
        else
            passwordInput.text = ""
    }

    Rectangle {
        anchors.fill: parent
        color: theme.scrimStrong
    }

    MouseArea {
        anchors.fill: parent
        z: 1
        onClicked: function(mouse) {
            mouse.accepted = true
        }
    }

    MaterialCard {
        id: dialog
        z: 2
        anchors.centerIn: parent
        width: Math.min(parent.width - 28, 360)
        implicitHeight: content.implicitHeight + 32
        theme: sheet.theme
        tone: "surfaceHigh"
        cornerRadius: 28

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            Text {
                Layout.fillWidth: true
                text: "Join " + (sheet.ssid === "" ? "Wi-Fi" : sheet.ssid)
                color: theme.text
                font.family: theme.sansFamily
                font.pixelSize: 18
                font.weight: Font.DemiBold
                wrapMode: Text.Wrap
            }

            Text {
                Layout.fillWidth: true
                text: "Enter a password, or leave it blank to try saved credentials."
                color: theme.textMuted
                font.family: theme.sansFamily
                font.pixelSize: 12
                wrapMode: Text.Wrap
            }

            Rectangle {
                Layout.fillWidth: true
                radius: 20
                implicitHeight: 48
                color: theme.surfaceContainerHighest
                border.width: 1
                border.color: passwordInput.activeFocus ? theme.primaryOutline : theme.outline

                TextInput {
                    id: passwordInput
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    verticalAlignment: Text.AlignVCenter
                    color: theme.text
                    font.family: theme.sansFamily
                    font.pixelSize: 14
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    clip: true
                    enabled: !sheet.pending

                    Keys.onReturnPressed: {
                        if (!sheet.pending)
                            sheet.submitted()
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    visible: passwordInput.text === "" && !passwordInput.activeFocus
                    text: "Wi-Fi password"
                    color: theme.textMuted
                    font.family: theme.sansFamily
                    font.pixelSize: 14
                }
            }

            Text {
                Layout.fillWidth: true
                visible: sheet.errorText !== ""
                text: sheet.errorText
                color: theme.danger
                font.family: theme.sansFamily
                font.pixelSize: 12
                wrapMode: Text.Wrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                MaterialTile {
                    Layout.fillWidth: true
                    theme: sheet.theme
                    title: "Cancel"
                    compact: true
                    centered: true
                    clickable: !sheet.pending
                    onClicked: sheet.canceled()
                }

                MaterialTile {
                    Layout.fillWidth: true
                    theme: sheet.theme
                    title: sheet.pending ? "Connecting…" : "Connect"
                    compact: true
                    centered: true
                    prominent: true
                    clickable: !sheet.pending
                    onClicked: sheet.submitted()
                }
            }
        }
    }
}
