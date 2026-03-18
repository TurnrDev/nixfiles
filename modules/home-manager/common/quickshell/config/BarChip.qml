import QtQuick

Rectangle {
    id: chip

    required property var theme
    property string label: ""
    property bool highlighted: false
    property bool subdued: false
    property bool clickable: false
    property bool leftAligned: false
    property bool monospace: false
    signal clicked

    radius: 18
    implicitHeight: 38
    implicitWidth: Math.max(96, labelText.implicitWidth + 30)
    color: highlighted ? theme.accent : (subdued ? theme.surfaceAlt : theme.surface)
    border.width: highlighted ? 0 : 1
    border.color: theme.outline

    Text {
        id: labelText
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        text: chip.label
        color: highlighted ? theme.background : (subdued ? theme.textMuted : theme.text)
        font.family: chip.monospace ? theme.monoFamily : theme.sansFamily
        font.pixelSize: 14
        font.weight: Font.DemiBold
        horizontalAlignment: chip.leftAligned ? Text.AlignLeft : Text.AlignHCenter
        elide: Text.ElideRight
    }

    MouseArea {
        anchors.fill: parent
        enabled: chip.clickable
        hoverEnabled: chip.clickable
        cursorShape: chip.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onEntered: chip.opacity = 0.92
        onExited: chip.opacity = 1
        onClicked: chip.clicked()
    }
}
