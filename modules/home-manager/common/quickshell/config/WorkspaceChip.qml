import QtQuick

Rectangle {
    id: chip

    required property var theme
    property int workspaceId: 1
    property bool active: false
    property bool occupied: false
    signal clicked(int workspaceId)

    property bool hovered: false
    property bool pressed: false

    radius: 18
    implicitWidth: active ? 42 : 34
    implicitHeight: 36
    color: active ? theme.primaryContainer : (occupied ? theme.surfaceContainerHigh : "transparent")
    border.width: 1
    border.color: active ? theme.primaryOutline : (occupied ? theme.outlineStrong : theme.outline)
    antialiasing: true
    scale: pressed ? 0.97 : 1

    Behavior on color {
        ColorAnimation {
            duration: 140
        }
    }

    Behavior on border.color {
        ColorAnimation {
            duration: 140
        }
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 140
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: 120
        }
    }

    Text {
        anchors.centerIn: parent
        text: String(chip.workspaceId)
        color: active ? theme.primaryContainerForeground : (occupied ? theme.text : theme.textMuted)
        font.family: theme.monoFamily
        font.pixelSize: 13
        font.weight: Font.DemiBold
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: chip.hovered = true
        onExited: {
            chip.hovered = false
            chip.pressed = false
        }
        onPressed: chip.pressed = true
        onCanceled: chip.pressed = false
        onClicked: {
            chip.pressed = false
            chip.clicked(chip.workspaceId)
        }
    }
}
