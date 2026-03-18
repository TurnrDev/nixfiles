import QtQuick
import QtQuick.Layouts

Rectangle {
    id: tile

    required property var theme
    property string icon: ""
    property string title: ""
    property string supporting: ""
    property string trailing: ""
    property bool selected: false
    property bool prominent: false
    property bool danger: false
    property bool subdued: false
    property bool compact: false
    property bool centered: false
    property bool monospace: false
    property bool outlined: false
    property bool clickable: true
    signal clicked

    property bool hovered: false
    property bool pressed: false

    function fillColor() {
        if (tile.danger)
            return tile.pressed ? theme.danger : theme.dangerContainer

        if (tile.prominent || tile.selected)
            return tile.pressed ? theme.primaryOutline : theme.primaryContainer

        if (tile.subdued)
            return tile.hovered ? theme.surfaceContainerHigh : theme.surfaceContainer

        return tile.hovered ? theme.surfaceContainer : theme.surfaceContainerLow
    }

    function strokeColor() {
        if (tile.prominent || tile.selected)
            return theme.primaryOutline

        if (tile.danger)
            return theme.danger

        return tile.hovered ? theme.outlineStrong : theme.outline
    }

    function titleColor() {
        if (tile.danger)
            return theme.dangerContainerForeground

        if (tile.prominent || tile.selected)
            return theme.primaryContainerForeground

        return theme.text
    }

    function supportingColor() {
        if (tile.danger)
            return theme.dangerContainerForeground

        if (tile.prominent || tile.selected)
            return theme.primaryContainerForeground

        return theme.textMuted
    }

    radius: compact ? 22 : 28
    implicitHeight: compact ? 54 : (supporting === "" ? 82 : 98)
    implicitWidth: centered ? Math.max(112, contentColumn.implicitWidth + 36) : Math.max(144, layout.implicitWidth + 28)
    color: fillColor()
    border.width: outlined ? 1 : 0
    border.color: strokeColor()
    scale: pressed ? 0.985 : 1
    antialiasing: true

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

    RowLayout {
        id: layout
        anchors.fill: parent
        anchors.leftMargin: tile.compact ? 14 : 16
        anchors.rightMargin: tile.compact ? 14 : 16
        anchors.topMargin: tile.compact ? 12 : 16
        anchors.bottomMargin: tile.compact ? 12 : 16
        spacing: tile.compact ? 10 : 12
        visible: !tile.centered

        Text {
            visible: tile.icon !== ""
            text: tile.icon
            color: tile.titleColor()
            font.family: tile.monospace ? theme.monoFamily : theme.sansFamily
            font.pixelSize: tile.compact ? 18 : 22
            font.weight: Font.DemiBold
        }

        ColumnLayout {
            id: contentColumn
            Layout.fillWidth: true
            spacing: tile.supporting === "" ? 0 : 2

            Text {
                Layout.fillWidth: true
                text: tile.title
                color: tile.titleColor()
                font.family: tile.monospace ? theme.monoFamily : theme.sansFamily
                font.pixelSize: tile.compact ? 14 : 15
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: tile.supporting !== ""
                text: tile.supporting
                color: tile.supportingColor()
                font.family: theme.sansFamily
                font.pixelSize: 12
                wrapMode: Text.Wrap
                maximumLineCount: tile.compact ? 1 : 2
                elide: Text.ElideRight
            }
        }

        Text {
            visible: tile.trailing !== ""
            text: tile.trailing
            color: tile.supportingColor()
            font.family: tile.monospace ? theme.monoFamily : theme.sansFamily
            font.pixelSize: tile.compact ? 12 : 13
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignRight
        }
    }

    Column {
        anchors.centerIn: parent
        width: parent.width - 28
        spacing: 4
        visible: tile.centered

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: tile.icon !== ""
            text: tile.icon
            color: tile.titleColor()
            font.family: tile.monospace ? theme.monoFamily : theme.sansFamily
            font.pixelSize: tile.compact ? 18 : 22
            font.weight: Font.DemiBold
        }

        Text {
            width: parent.width
            text: tile.title
            color: tile.titleColor()
            font.family: tile.monospace ? theme.monoFamily : theme.sansFamily
            font.pixelSize: tile.compact ? 14 : 15
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: tile.clickable
        hoverEnabled: tile.clickable
        cursorShape: tile.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onEntered: tile.hovered = true
        onExited: {
            tile.hovered = false
            tile.pressed = false
        }
        onPressed: tile.pressed = true
        onReleased: tile.pressed = containsMouse
        onCanceled: tile.pressed = false
        onClicked: {
            tile.pressed = false
            tile.clicked()
        }
    }
}
