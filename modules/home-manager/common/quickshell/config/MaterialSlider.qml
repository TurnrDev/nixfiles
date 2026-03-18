import QtQuick

Item {
    id: slider

    required property var theme
    property real from: 0
    property real to: 100
    property real value: 0
    property real stepSize: 1
    property bool enabled: true
    property bool dragging: false
    property real visualValue: value
    signal moved(real value)
    signal committed(real value)

    function clamp(input) {
        return Math.max(slider.from, Math.min(slider.to, input))
    }

    function snap(input) {
        const ratio = Math.round((slider.clamp(input) - slider.from) / slider.stepSize)
        return slider.from + ratio * slider.stepSize
    }

    function updateFromMouse(xPosition, commit) {
        const width = Math.max(1, track.width)
        const ratio = Math.max(0, Math.min(1, xPosition / width))
        const nextValue = slider.snap(slider.from + ratio * (slider.to - slider.from))

        slider.visualValue = nextValue
        slider.moved(nextValue)

        if (commit)
            slider.committed(nextValue)
    }

    implicitHeight: 30
    implicitWidth: 180

    onValueChanged: {
        if (!dragging)
            visualValue = value
    }

    Rectangle {
        id: track
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 8
        radius: 4
        color: slider.enabled ? theme.surfaceContainerHighest : theme.surfaceContainerLow
    }

    Rectangle {
        anchors.left: track.left
        anchors.verticalCenter: track.verticalCenter
        height: track.height
        width: track.width * ((slider.visualValue - slider.from) / Math.max(1, slider.to - slider.from))
        radius: track.radius
        color: slider.enabled ? theme.primaryContainer : theme.outline

        Behavior on width {
            NumberAnimation {
                duration: slider.dragging ? 0 : 120
            }
        }
    }

    Rectangle {
        width: 22
        height: 22
        radius: 11
        x: track.x + track.width * ((slider.visualValue - slider.from) / Math.max(1, slider.to - slider.from)) - width / 2
        y: track.y + track.height / 2 - height / 2
        color: slider.enabled ? theme.primaryContainerForeground : theme.outlineVariant
        border.width: 1
        border.color: slider.enabled ? theme.primaryOutline : theme.outline

        Behavior on x {
            NumberAnimation {
                duration: slider.dragging ? 0 : 120
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: slider.enabled
        hoverEnabled: slider.enabled
        cursorShape: slider.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPressed: function(mouse) {
            slider.dragging = true
            slider.updateFromMouse(mouse.x, false)
        }
        onPositionChanged: function(mouse) {
            if (pressed)
                slider.updateFromMouse(mouse.x, false)
        }
        onReleased: function(mouse) {
            slider.updateFromMouse(mouse.x, true)
            slider.dragging = false
        }
        onCanceled: slider.dragging = false
    }
}
