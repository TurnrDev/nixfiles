import QtQuick

Rectangle {
    id: chip

    required property var theme
    property int workspaceId: 1
    property bool active: false
    property bool occupied: false
    signal clicked(int workspaceId)

    radius: 15
    implicitWidth: 34
    implicitHeight: 34
    color: active ? theme.accent : (occupied ? theme.surfaceAlt : "transparent")
    border.width: active ? 0 : 1
    border.color: occupied ? theme.outlineStrong : theme.outline

    Text {
        anchors.centerIn: parent
        text: String(chip.workspaceId)
        color: active ? theme.background : (occupied ? theme.text : theme.textMuted)
        font.family: theme.monoFamily
        font.pixelSize: 13
        font.weight: Font.DemiBold
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: chip.opacity = 0.92
        onExited: chip.opacity = 1
        onClicked: chip.clicked(chip.workspaceId)
    }
}
