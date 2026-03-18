import QtQuick
import QtQuick.Layouts

Rectangle {
    id: row

    required property var theme
    required property var network
    property bool busy: false
    signal clicked(var network)

    property bool hovered: false
    property bool pressed: false

    function signalIcon() {
        if (row.network.signal >= 80)
            return "󰤨"
        if (row.network.signal >= 60)
            return "󰤥"
        if (row.network.signal >= 35)
            return "󰤢"
        return "󰤟"
    }

    function subtitleText() {
        const securityLabel = row.network.secure ? "Secured" : "Open"
        return securityLabel + "  •  " + String(row.network.signal) + "%"
    }

    radius: 26
    implicitHeight: 68
    color: row.network.active ? theme.primaryContainer : (row.hovered ? theme.surfaceContainer : theme.surfaceContainerLow)
    border.width: 0
    border.color: row.network.active ? theme.primaryOutline : theme.outline
    antialiasing: true
    scale: row.pressed ? 0.992 : 1

    Behavior on color {
        ColorAnimation {
            duration: 140
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: 110
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 16
        anchors.topMargin: 12
        anchors.bottomMargin: 12
        spacing: 14

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            width: 38
            height: 38
            radius: 19
            color: row.network.active ? theme.primaryContainerForeground : theme.surfaceContainerHigh

            Text {
                anchors.centerIn: parent
                text: row.signalIcon()
                color: row.network.active ? theme.primaryContainer : theme.text
                font.family: theme.monoFamily
                font.pixelSize: 18
                font.weight: Font.DemiBold
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: row.network.ssid
                color: row.network.active ? theme.primaryContainerForeground : theme.text
                font.family: theme.sansFamily
                font.pixelSize: 14
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: row.subtitleText()
                color: row.network.active ? theme.primaryContainerForeground : theme.textMuted
                font.family: theme.sansFamily
                font.pixelSize: 12
                elide: Text.ElideRight
            }
        }

        Text {
            text: row.network.active ? "Current" : "Join"
            color: row.network.active ? theme.primaryContainerForeground : theme.textMuted
            font.family: theme.sansFamily
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: !row.busy
        hoverEnabled: !row.busy
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onEntered: row.hovered = true
        onExited: {
            row.hovered = false
            row.pressed = false
        }
        onPressed: row.pressed = true
        onCanceled: row.pressed = false
        onClicked: {
            row.pressed = false
            row.clicked(row.network)
        }
    }
}
