import QtQuick

Rectangle {
    id: chip

    required property var theme
    property string label: ""
    property bool highlighted: false
    property bool subdued: false
    property bool danger: false
    property bool clickable: false
    property bool leftAligned: false
    property bool monospace: false
    property bool outlined: false
    signal clicked

    property bool hovered: false
    property bool pressed: false

    function fillColor() {
        if (chip.danger)
            return chip.pressed ? theme.danger : theme.dangerContainer

        if (chip.highlighted)
            return chip.pressed ? theme.primaryOutline : theme.primaryContainer

        if (chip.subdued)
            return chip.hovered ? theme.surfaceContainerHigh : theme.surfaceContainer

        return chip.hovered ? theme.surfaceContainer : theme.surfaceContainerLow
    }

    function strokeColor() {
        if (chip.danger)
            return theme.danger

        if (chip.highlighted)
            return theme.primaryOutline

        return chip.hovered ? theme.outlineStrong : theme.outline
    }

    function textColor() {
        if (chip.danger)
            return theme.dangerContainerForeground

        if (chip.highlighted)
            return theme.primaryContainerForeground

        return chip.subdued ? theme.textMuted : theme.text
    }

    radius: 23
    implicitHeight: 46
    implicitWidth: Math.max(96, labelText.implicitWidth + 32)
    color: fillColor()
    border.width: outlined ? 1 : 0
    border.color: strokeColor()
    antialiasing: true
    scale: pressed ? 0.985 : 1

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

    Behavior on scale {
        NumberAnimation {
            duration: 120
        }
    }

    Text {
        id: labelText
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        text: chip.label
        color: chip.textColor()
        font.family: chip.monospace ? theme.monoFamily : theme.sansFamily
        font.pixelSize: 14
        font.weight: Font.DemiBold
        horizontalAlignment: chip.leftAligned ? Text.AlignLeft : Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    MouseArea {
        anchors.fill: parent
        enabled: chip.clickable
        hoverEnabled: chip.clickable
        cursorShape: chip.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onEntered: chip.hovered = true
        onExited: {
            chip.hovered = false
            chip.pressed = false
        }
        onPressed: chip.pressed = true
        onCanceled: chip.pressed = false
        onClicked: {
            chip.pressed = false
            chip.clicked()
        }
    }
}
