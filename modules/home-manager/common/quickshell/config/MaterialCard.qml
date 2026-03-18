import QtQuick

Rectangle {
    id: card

    required property var theme
    property string tone: "surface"
    property real cornerRadius: 28
    property bool outlined: false

    function toneColor() {
        switch (card.tone) {
        case "primary":
            return theme.primaryContainer
        case "secondary":
            return theme.secondaryContainer
        case "surfaceLow":
            return theme.surfaceContainerLow
        case "surfaceHigh":
            return theme.surfaceContainerHigh
        case "surfaceHighest":
            return theme.surfaceContainerHighest
        default:
            return theme.surfaceContainer
        }
    }

    function strokeColor() {
        switch (card.tone) {
        case "primary":
            return theme.primaryOutline
        case "surfaceHighest":
            return theme.outlineStrong
        default:
            return theme.outline
        }
    }

    radius: cornerRadius
    color: toneColor()
    border.width: outlined ? 1 : 0
    border.color: strokeColor()
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
}
