//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1

import "."
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

ShellRoot {
    id: root

    property var hyprState: ({
        workspaceStart: 1,
        activeWorkspace: 1,
        occupied: [],
        activeWindow: "Desktop"
    })

    property var systemState: ({
        media: "",
        network: {
            label: "Offline",
            detail: "No active connection",
            connected: false,
            wifiEnabled: true
        },
        volume: {
            label: "Vol --",
            muted: false
        },
        brightness: {
            label: "Light --"
        },
        battery: {
            present: false,
            label: "",
            charging: false
        }
    })

    property bool quickSettingsVisible: false
    property var quickSettingsScreen: null
    property string timeLabel: ""

    Theme {
        id: themeData
    }

    function safeParse(text, fallback) {
        try {
            return JSON.parse(text)
        } catch (error) {
            return fallback
        }
    }

    function runCommand(command) {
        if (!command || command.length === 0)
            return

        actionProc.running = false
        actionProc.command = command
        actionProc.running = true
    }

    function focusWorkspace(workspaceId) {
        runCommand([themeData.hyprctlBin, "dispatch", "workspace", String(workspaceId)])
    }

    function toggleQuickSettings(screen) {
        if (!screen)
            return

        if (quickSettingsVisible && quickSettingsScreen === screen) {
            quickSettingsVisible = false
            quickSettingsScreen = null
            return
        }

        quickSettingsScreen = screen
        quickSettingsVisible = true
    }

    function closeQuickSettings() {
        quickSettingsVisible = false
        quickSettingsScreen = null
    }

    function updateTime() {
        timeLabel = "󰥔 " + Qt.formatDateTime(new Date(), "ddd d MMM  HH:mm")
    }

    Process {
        id: actionProc
    }

    Component.onCompleted: updateTime()

    Process {
        id: hyprStateProc
        command: themeData.hyprStateCommand
        stdout: StdioCollector {
            onStreamFinished: root.hyprState = root.safeParse(this.text, root.hyprState)
        }
    }

    Timer {
        interval: 400
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: hyprStateProc.running = true
    }

    Process {
        id: systemStateProc
        command: themeData.systemStateCommand
        stdout: StdioCollector {
            onStreamFinished: root.systemState = root.safeParse(this.text, root.systemState)
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: systemStateProc.running = true
    }

    Timer {
        interval: 30000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.updateTime()
    }

    GlobalShortcut {
        name: "toggleQuickSettings"
        description: "Toggle quick settings"
        onPressed: {
            const focusedMonitor = Hyprland.focusedMonitor

            if (focusedMonitor)
                root.toggleQuickSettings(focusedMonitor.screen)
        }
    }

    GlobalShortcut {
        name: "lock"
        description: "Close shell surfaces before lock"
        onPressed: root.closeQuickSettings()
    }

    GlobalShortcut {
        name: "lockFocus"
        description: "Close shell surfaces after sleep"
        onPressed: root.closeQuickSettings()
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            Scope {
                required property var modelData

                Bar {
                    screenModel: modelData
                    rootRef: root
                    theme: themeData
                }

                QuickSettings {
                    screenModel: modelData
                    rootRef: root
                    theme: themeData
                }
            }
        }
    }
}
