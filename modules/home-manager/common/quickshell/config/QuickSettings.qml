import "."
import Quickshell
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: popup

    required property var screenModel
    required property var rootRef
    required property var theme

    readonly property bool active: rootRef.quickSettingsVisible && rootRef.quickSettingsScreen === screenModel
    readonly property bool networkHeroProminent: rootRef.systemState.network.connected || rootRef.systemState.network.wifiEnabled

    function heroTextColor() {
        return popup.networkHeroProminent ? theme.primaryContainerForeground : theme.text
    }

    function heroSupportingColor() {
        return popup.networkHeroProminent ? theme.primaryContainerForeground : theme.textMuted
    }

    function networkHeroTitle() {
        if (rootRef.systemState.network.currentSsid !== "")
            return rootRef.systemState.network.currentSsid

        return rootRef.systemState.network.label
    }

    function networkHeroIcon() {
        if (rootRef.systemState.network.connected && rootRef.systemState.network.currentSsid === "")
            return "󰈀"

        if (rootRef.systemState.network.connected)
            return "󰤨"

        if (!rootRef.systemState.network.hasWifiDevice)
            return "󰤭"

        return rootRef.systemState.network.wifiEnabled ? "󰤯" : "󰤮"
    }

    function headerStatusLabel() {
        if (rootRef.systemState.network.connected)
            return "Online"

        if (!rootRef.systemState.network.hasWifiDevice)
            return "No Wi-Fi"

        return rootRef.systemState.network.wifiEnabled ? "Ready" : "Offline"
    }

    screen: screenModel
    anchors {
        top: true
        right: true
    }

    implicitWidth: popupCard.width + 20
    implicitHeight: popupCard.implicitHeight + 100
    visible: active
    color: "transparent"
    exclusiveZone: 0
    focusable: false

    Item {
        anchors.fill: parent

        MaterialCard {
            id: popupCard
            width: 512
            implicitHeight: contentColumn.implicitHeight + 52
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 92
            anchors.rightMargin: 16
            theme: popup.theme
            tone: "surface"
            outlined: true
            cornerRadius: 38
            opacity: popup.active ? 1 : 0
            scale: popup.active ? 1 : 0.985

            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 150
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: function(mouse) {
                    mouse.accepted = true
                }
            }

            ColumnLayout {
                id: contentColumn
                anchors.fill: parent
                anchors.margins: 24
                spacing: 16

                MaterialCard {
                    Layout.fillWidth: true
                    implicitHeight: headerRow.implicitHeight + 28
                    theme: popup.theme
                    tone: "surfaceHigh"
                    cornerRadius: 32

                    RowLayout {
                        id: headerRow
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 16

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                Layout.fillWidth: true
                                text: "System Controls"
                                color: theme.textMuted
                                font.family: theme.sansFamily
                                font.pixelSize: 11
                                font.capitalization: Font.AllUppercase
                                font.weight: Font.DemiBold
                                font.letterSpacing: 1.1
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "Quick Settings"
                                color: theme.text
                                font.family: theme.sansFamily
                                font.pixelSize: 29
                                font.weight: Font.DemiBold
                            }

                            Text {
                                Layout.fillWidth: true
                                text: rootRef.timeLabel + (rootRef.systemState.network.currentDevice !== "" ? "  •  " + rootRef.systemState.network.currentDevice : "")
                                color: theme.textMuted
                                font.family: theme.sansFamily
                                font.pixelSize: 12
                                wrapMode: Text.Wrap
                            }
                        }

                        MaterialTile {
                            theme: popup.theme
                            compact: true
                            centered: true
                            icon: rootRef.systemState.network.connected ? "󰤨" : "󰤮"
                            prominent: rootRef.systemState.network.connected
                            subdued: !rootRef.systemState.network.connected
                            clickable: false
                            title: popup.headerStatusLabel()
                        }
                    }
                }

                MaterialCard {
                    Layout.fillWidth: true
                    implicitHeight: networkHeroColumn.implicitHeight + 30
                    theme: popup.theme
                    tone: popup.networkHeroProminent ? "primary" : "surfaceHigh"
                    cornerRadius: 32

                    ColumnLayout {
                        id: networkHeroColumn
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 14

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 14

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Text {
                                    Layout.fillWidth: true
                                    text: "Internet"
                                    color: popup.heroSupportingColor()
                                    font.family: theme.sansFamily
                                    font.pixelSize: 11
                                    font.capitalization: Font.AllUppercase
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 1.1
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: popup.networkHeroTitle()
                                    color: popup.heroTextColor()
                                    font.family: theme.sansFamily
                                    font.pixelSize: 28
                                    font.weight: Font.DemiBold
                                    wrapMode: Text.Wrap
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: rootRef.systemState.network.detail
                                    color: popup.heroSupportingColor()
                                    font.family: theme.sansFamily
                                    font.pixelSize: 13
                                    wrapMode: Text.Wrap
                                }
                            }

                            Rectangle {
                                Layout.alignment: Qt.AlignTop
                                width: 58
                                height: 58
                                radius: 29
                                color: popup.networkHeroProminent ? theme.primaryContainerForeground : theme.primaryContainer

                                Text {
                                    anchors.centerIn: parent
                                    text: popup.networkHeroIcon()
                                    color: popup.networkHeroProminent ? theme.primaryContainer : theme.primaryContainerForeground
                                    font.family: theme.monoFamily
                                    font.pixelSize: 25
                                    font.weight: Font.DemiBold
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            MaterialTile {
                                Layout.fillWidth: true
                                theme: popup.theme
                                compact: true
                                icon: rootRef.systemState.network.wifiEnabled ? "󰤮" : "󰤯"
                                title: rootRef.systemState.network.wifiEnabled ? "Disable Wi-Fi" : "Enable Wi-Fi"
                                subdued: true
                                clickable: !rootRef.systemState.network.busy && !rootRef.connectPending
                                onClicked: rootRef.setWifiEnabled(!rootRef.systemState.network.wifiEnabled)
                            }

                            MaterialTile {
                                Layout.fillWidth: true
                                theme: popup.theme
                                compact: true
                                icon: "󰑐"
                                title: "Refresh"
                                supporting: rootRef.systemState.network.busy ? "Busy" : "Scan nearby"
                                subdued: true
                                clickable: !rootRef.systemState.network.busy && !rootRef.connectPending
                                onClicked: rootRef.refreshNetworkState()
                            }

                            MaterialTile {
                                Layout.fillWidth: true
                                theme: popup.theme
                                compact: true
                                icon: "󰌾"
                                title: rootRef.systemState.network.currentSsid !== "" ? "Saved Network" : "Credentials"
                                supporting: "Use saved secrets"
                                subdued: true
                                clickable: false
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: rootRef.systemState.network.error !== ""
                            text: rootRef.systemState.network.error
                            color: popup.heroTextColor()
                            font.family: theme.sansFamily
                            font.pixelSize: 12
                            wrapMode: Text.Wrap
                        }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 14
                    rowSpacing: 14

                    MaterialCard {
                        Layout.fillWidth: true
                        implicitHeight: volumeColumn.implicitHeight + 24
                        theme: popup.theme
                        tone: "surfaceHigh"
                        cornerRadius: 30

                        ColumnLayout {
                            id: volumeColumn
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 14

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                Rectangle {
                                    width: 42
                                    height: 42
                                    radius: 21
                                    color: theme.primaryContainer

                                    Text {
                                        anchors.centerIn: parent
                                        text: rootRef.systemState.volume.muted ? "󰝟" : "󰕾"
                                        color: theme.primaryContainerForeground
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
                                        text: "Sound"
                                        color: theme.textMuted
                                        font.family: theme.sansFamily
                                        font.pixelSize: 11
                                        font.capitalization: Font.AllUppercase
                                        font.weight: Font.DemiBold
                                        font.letterSpacing: 1
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: "Volume"
                                        color: theme.text
                                        font.family: theme.sansFamily
                                        font.pixelSize: 18
                                        font.weight: Font.DemiBold
                                    }
                                }

                                Text {
                                    text: Math.round(volumeSlider.dragging ? volumeSlider.visualValue : rootRef.systemState.volume.percent) + "%"
                                    color: theme.text
                                    font.family: theme.monoFamily
                                    font.pixelSize: 18
                                    font.weight: Font.DemiBold
                                }
                            }

                            MaterialSlider {
                                id: volumeSlider
                                Layout.fillWidth: true
                                theme: popup.theme
                                from: 0
                                to: 100
                                stepSize: 1
                                value: rootRef.systemState.volume.percent
                                enabled: !rootRef.connectPending
                                onCommitted: function(value) {
                                    rootRef.setVolumePercent(value)
                                }
                            }

                            MaterialTile {
                                Layout.fillWidth: true
                                theme: popup.theme
                                compact: true
                                icon: rootRef.systemState.volume.muted ? "󰖁" : "󰕾"
                                title: rootRef.systemState.volume.muted ? "Unmute Output" : "Mute Output"
                                subdued: true
                                clickable: !rootRef.connectPending
                                onClicked: rootRef.toggleMute()
                            }
                        }
                    }

                    MaterialCard {
                        Layout.fillWidth: true
                        implicitHeight: brightnessColumn.implicitHeight + 24
                        theme: popup.theme
                        tone: "surfaceHigh"
                        cornerRadius: 30

                        ColumnLayout {
                            id: brightnessColumn
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 14

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                Rectangle {
                                    width: 42
                                    height: 42
                                    radius: 21
                                    color: theme.secondaryContainer

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰃠"
                                        color: theme.secondaryContainerForeground
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
                                        text: "Display"
                                        color: theme.textMuted
                                        font.family: theme.sansFamily
                                        font.pixelSize: 11
                                        font.capitalization: Font.AllUppercase
                                        font.weight: Font.DemiBold
                                        font.letterSpacing: 1
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: "Brightness"
                                        color: theme.text
                                        font.family: theme.sansFamily
                                        font.pixelSize: 18
                                        font.weight: Font.DemiBold
                                    }
                                }

                                Text {
                                    text: Math.round(brightnessSlider.dragging ? brightnessSlider.visualValue : rootRef.systemState.brightness.percent) + "%"
                                    color: theme.text
                                    font.family: theme.monoFamily
                                    font.pixelSize: 18
                                    font.weight: Font.DemiBold
                                }
                            }

                            MaterialSlider {
                                id: brightnessSlider
                                Layout.fillWidth: true
                                theme: popup.theme
                                from: 5
                                to: 100
                                stepSize: 5
                                value: rootRef.systemState.brightness.percent
                                enabled: !rootRef.connectPending
                                onCommitted: function(value) {
                                    rootRef.setBrightnessPercent(value)
                                }
                            }

                            MaterialTile {
                                Layout.fillWidth: true
                                theme: popup.theme
                                compact: true
                                icon: rootRef.systemState.battery.present ? "󰁹" : "󰃞"
                                title: rootRef.systemState.battery.present ? rootRef.systemState.battery.label : "Hardware backlight"
                                subdued: true
                                clickable: false
                            }
                        }
                    }
                }

                MaterialCard {
                    Layout.fillWidth: true
                    implicitHeight: networkListColumn.implicitHeight + 24
                    theme: popup.theme
                    tone: "surfaceHigh"
                    cornerRadius: 32

                    ColumnLayout {
                        id: networkListColumn
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    text: "Networks"
                                    color: theme.text
                                    font.family: theme.sansFamily
                                    font.pixelSize: 19
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "Tap a network to join directly from the panel."
                                    color: theme.textMuted
                                    font.family: theme.sansFamily
                                    font.pixelSize: 12
                                    wrapMode: Text.Wrap
                                }
                            }

                            MaterialTile {
                                theme: popup.theme
                                compact: true
                                centered: true
                                icon: "󰑐"
                                title: rootRef.systemState.network.busy ? "Busy" : "Live Scan"
                                subdued: true
                                clickable: false
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: !rootRef.systemState.network.hasWifiDevice
                            text: "No wireless adapter detected."
                            color: theme.textMuted
                            font.family: theme.sansFamily
                            font.pixelSize: 12
                            wrapMode: Text.Wrap
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: rootRef.systemState.network.hasWifiDevice && !rootRef.systemState.network.wifiEnabled
                            text: "Enable Wi-Fi to start scanning nearby SSIDs."
                            color: theme.textMuted
                            font.family: theme.sansFamily
                            font.pixelSize: 12
                            wrapMode: Text.Wrap
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: rootRef.systemState.network.hasWifiDevice
                                && rootRef.systemState.network.wifiEnabled
                                && rootRef.systemState.network.scanResults.length === 0
                            text: "No nearby networks are being reported yet."
                            color: theme.textMuted
                            font.family: theme.sansFamily
                            font.pixelSize: 12
                            wrapMode: Text.Wrap
                        }

                        Flickable {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.min(286, networkRows.implicitHeight)
                            visible: rootRef.systemState.network.scanResults.length > 0
                            clip: true
                            contentWidth: width
                            contentHeight: networkRows.implicitHeight

                            Column {
                                id: networkRows
                                width: parent.width
                                spacing: 10

                                Repeater {
                                    model: rootRef.systemState.network.scanResults

                                    delegate: WifiNetworkRow {
                                        width: networkRows.width
                                        theme: popup.theme
                                        network: modelData
                                        busy: rootRef.connectPending || rootRef.systemState.network.busy
                                        onClicked: function(network) {
                                            if (!network.active)
                                                rootRef.connectNetwork(network)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 4
                    columnSpacing: 10
                    rowSpacing: 10

                    MaterialTile {
                        Layout.fillWidth: true
                        theme: popup.theme
                        compact: true
                        icon: "󰌾"
                        title: "Lock"
                        subdued: true
                        onClicked: {
                            rootRef.closeQuickSettings()
                            rootRef.runCommand(theme.lockCommand)
                        }
                    }

                    MaterialTile {
                        Layout.fillWidth: true
                        theme: popup.theme
                        compact: true
                        icon: "󰐥"
                        title: "Power"
                        danger: true
                        onClicked: {
                            rootRef.closeQuickSettings()
                            rootRef.runCommand(theme.powerMenuCommand)
                        }
                    }

                    MaterialTile {
                        Layout.fillWidth: true
                        theme: popup.theme
                        compact: true
                        icon: "󰕮"
                        title: "Edit"
                        subdued: true
                        onClicked: rootRef.runCommand(theme.connectionEditorCommand)
                    }

                    MaterialTile {
                        Layout.fillWidth: true
                        theme: popup.theme
                        compact: true
                        icon: "󰆍"
                        title: "Terminal"
                        subdued: true
                        onClicked: rootRef.runCommand(theme.networkTerminalCommand)
                    }
                }
            }
        }

        PasswordSheet {
            id: passwordSheet
            anchors.fill: parent
            theme: popup.theme
            sheetVisible: popup.active && rootRef.passwordDialogOpen
            ssid: rootRef.selectedNetwork ? rootRef.selectedNetwork.ssid : ""
            errorText: rootRef.systemState.network.error
            pending: rootRef.connectPending
            onCanceled: rootRef.clearPasswordDialog()
            onSubmitted: {
                rootRef.wifiPassword = passwordSheet.password
                rootRef.submitPasswordConnect()
            }
        }
    }
}
