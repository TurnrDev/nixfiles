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
            wifiEnabled: true,
            currentSsid: "",
            currentDevice: "",
            ipAddress: "",
            hasWifiDevice: false,
            scanResults: [],
            busy: false,
            error: ""
        },
        volume: {
            label: "Vol --",
            muted: false,
            percent: 0
        },
        brightness: {
            label: "Light --",
            percent: 50
        },
        battery: {
            present: false,
            label: "",
            charging: false,
            percent: 0
        }
    })

    property bool quickSettingsVisible: false
    property var quickSettingsScreen: null
    property string timeLabel: ""
    property var selectedNetwork: null
    property string wifiPassword: ""
    property bool passwordDialogOpen: false
    property bool connectPending: false
    property var networkConnectResult: ({ ok: false, message: "" })
    property bool statefulRefreshNetwork: false
    property bool pendingRefreshNetwork: false

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

    function mergeFields(current, partial, keys) {
        const next = {}

        for (let index = 0; index < keys.length; index++) {
            const key = keys[index]
            next[key] = partial[key] !== undefined ? partial[key] : current[key]
        }

        return next
    }

    function mergeSystemState(partial) {
        const next = partial || {}

        return {
            media: next.media !== undefined ? next.media : root.systemState.media,
            network: root.mergeFields(root.systemState.network, next.network || {}, [
                "label",
                "detail",
                "connected",
                "wifiEnabled",
                "currentSsid",
                "currentDevice",
                "ipAddress",
                "hasWifiDevice",
                "scanResults",
                "busy",
                "error"
            ]),
            volume: root.mergeFields(root.systemState.volume, next.volume || {}, [
                "label",
                "muted",
                "percent"
            ]),
            brightness: root.mergeFields(root.systemState.brightness, next.brightness || {}, [
                "label",
                "percent"
            ]),
            battery: root.mergeFields(root.systemState.battery, next.battery || {}, [
                "present",
                "label",
                "charging",
                "percent"
            ])
        }
    }

    function applySystemState(partial) {
        root.systemState = root.mergeSystemState(partial)
    }

    function runCommand(command) {
        if (!command || command.length === 0)
            return

        actionProc.running = false
        actionProc.command = command
        actionProc.running = true
    }

    function runStatefulCommand(command, refreshNetwork) {
        if (!command || command.length === 0)
            return

        root.statefulRefreshNetwork = refreshNetwork
        statefulProc.running = false
        statefulProc.command = command
        statefulProc.running = true
    }

    function refreshSystemState() {
        systemStateProc.running = false
        systemStateProc.running = true
    }

    function refreshNetworkState() {
        if (root.connectPending)
            return

        networkScanProc.running = false
        networkScanProc.running = true
    }

    function scheduleRefresh(includeNetwork) {
        root.pendingRefreshNetwork = root.pendingRefreshNetwork || includeNetwork
        refreshTimer.running = false
        refreshTimer.running = true
    }

    function focusWorkspace(workspaceId) {
        runCommand([themeData.hyprctlBin, "dispatch", "workspace", String(workspaceId)])
    }

    function clearPasswordDialog() {
        root.passwordDialogOpen = false
        root.selectedNetwork = null
        root.wifiPassword = ""
        root.applySystemState({
            network: {
                error: ""
            }
        })
    }

    function toggleQuickSettings(screen) {
        if (!screen)
            return

        if (root.quickSettingsVisible && root.quickSettingsScreen === screen) {
            root.closeQuickSettings()
            return
        }

        root.quickSettingsScreen = screen
        root.quickSettingsVisible = true
        root.refreshNetworkState()
    }

    function closeQuickSettings() {
        root.quickSettingsVisible = false
        root.quickSettingsScreen = null
        root.clearPasswordDialog()
        root.applySystemState({
            network: {
                busy: false,
                error: ""
            }
        })
    }

    function updateTime() {
        timeLabel = "󰥔 " + Qt.formatDateTime(new Date(), "ddd d MMM  HH:mm")
    }

    function setWifiEnabled(enabled) {
        root.applySystemState({
            network: {
                busy: true,
                error: ""
            }
        })
        root.runStatefulCommand(enabled ? themeData.wifiOnCommand : themeData.wifiOffCommand, true)
    }

    function toggleMute() {
        root.runStatefulCommand(themeData.volumeMuteCommand, false)
    }

    function setVolumePercent(percent) {
        root.runStatefulCommand(
            themeData.volumeSetCommandPrefix.concat([String(Math.max(0, Math.min(100, Math.round(percent))))]),
            false
        )
    }

    function setBrightnessPercent(percent) {
        const clamped = Math.max(5, Math.min(100, Math.round(percent / 5) * 5))
        root.runStatefulCommand(themeData.brightnessSetCommandPrefix.concat([String(clamped)]), false)
    }

    function openPasswordSheet(network) {
        if (!network)
            return

        root.selectedNetwork = network
        root.wifiPassword = ""
        root.passwordDialogOpen = true
        root.applySystemState({
            network: {
                error: ""
            }
        })
    }

    function submitNetworkConnect(network, password) {
        if (!network || !network.ssid || root.connectPending)
            return

        const args = [network.ssid]

        if (password !== undefined && password !== "")
            args.push(password)

        root.selectedNetwork = network
        root.connectPending = true
        root.networkConnectResult = ({ ok: false, message: "" })
        root.applySystemState({
            network: {
                busy: true,
                error: ""
            }
        })

        networkConnectProc.running = false
        networkConnectProc.command = themeData.networkConnectCommandPrefix.concat(args)
        networkConnectProc.running = true
    }

    function connectNetwork(network) {
        if (!network || root.connectPending)
            return

        if (network.secure) {
            root.openPasswordSheet(network)
            return
        }

        root.passwordDialogOpen = false
        root.submitNetworkConnect(network, "")
    }

    function submitPasswordConnect() {
        if (!root.selectedNetwork)
            return

        root.submitNetworkConnect(root.selectedNetwork, root.wifiPassword)
    }

    function networkSummary() {
        if (root.systemState.network.currentSsid !== "")
            return root.systemState.network.currentSsid

        return root.systemState.network.connected ? root.systemState.network.detail : "Choose a network"
    }

    Component.onCompleted: updateTime()
    onQuickSettingsVisibleChanged: {
        if (quickSettingsVisible)
            root.refreshNetworkState()
    }

    Process {
        id: actionProc
    }

    Process {
        id: statefulProc

        onExited: function() {
            root.applySystemState({
                network: {
                    busy: false
                }
            })
            root.scheduleRefresh(root.statefulRefreshNetwork)
        }
    }

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
            onStreamFinished: root.applySystemState(root.safeParse(this.text, {}))
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refreshSystemState()
    }

    Process {
        id: networkScanProc
        command: themeData.networkScanCommand
        stdout: StdioCollector {
            onStreamFinished: root.applySystemState(root.safeParse(this.text, {}))
        }
    }

    Timer {
        interval: 10000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            if (root.quickSettingsVisible || root.systemState.network.wifiEnabled)
                root.refreshNetworkState()
        }
    }

    Process {
        id: networkConnectProc
        stdout: StdioCollector {
            onStreamFinished: root.networkConnectResult = root.safeParse(this.text, root.networkConnectResult)
        }
        onExited: function(exitCode) {
            root.connectPending = false

            root.applySystemState({
                network: {
                    busy: false,
                    error: exitCode === 0 ? "" : root.networkConnectResult.message
                }
            })

            if (exitCode === 0)
                root.clearPasswordDialog()

            root.scheduleRefresh(true)
        }
    }

    Timer {
        id: refreshTimer
        interval: 850
        repeat: false
        onTriggered: {
            root.refreshSystemState()

            if (root.pendingRefreshNetwork || root.quickSettingsVisible || root.systemState.network.wifiEnabled)
                root.refreshNetworkState()

            root.pendingRefreshNetwork = false
        }
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
