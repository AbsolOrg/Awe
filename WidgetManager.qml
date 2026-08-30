import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property real screenWidth: 1920
    property real screenHeight: 1080

    // Top centered floating pill / notch
    x: Math.round((screenWidth - width) / 2)
    y: 10
    width: isExpanded ? 360 : 180
    height: isExpanded ? 340 : 34
    z: 999

    property bool isExpanded: false

    // Widget visibility states
    property var widgetVisibility: ({
        clock: true,
        poster: true,
        calendar: true,
        media: true,
        sysinfo: true,
        battery: true,
        weather: true,
        quickcontrols: true,
        network: true,
        notes: true,
        todo: true,
        timer: true,
        thermal: true,
        quote: true,
        clipboard: true,
        crypto: true,
        worldclock: true,
        git: true,
        resourcewheel: true
    })

    // ─── Settings Persistence ───
    Process {
        id: loadSettingsProc
        command: ["sh", "-c", "cat ~/.config/quickshell/widget_settings.json 2>/dev/null || echo '{}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text)
                    if (data.manager && data.manager.visibility !== undefined) {
                        var vis = Object.assign({}, root.widgetVisibility, data.manager.visibility)
                        root.widgetVisibility = vis
                    }
                } catch (e) {}
            }
        }
    }

    Process {
        id: saveSettingsProc
        running: false
    }

    function saveSettings() {
        var jsonStr = JSON.stringify({
            visibility: root.widgetVisibility
        }).replace(/'/g, "'\\''")
        var script = "python3 -c 'import json, os; p=os.path.expanduser(\"~/.config/quickshell/widget_settings.json\"); d=json.load(open(p)) if os.path.exists(p) else {}; d[\"manager\"]=" + jsonStr + "; open(p,\"w\").write(json.dumps(d,indent=2))'"
        saveSettingsProc.command = ["sh", "-c", script]
        saveSettingsProc.running = true
    }

    function toggleWidget(name) {
        var vis = Object.assign({}, root.widgetVisibility)
        vis[name] = !vis[name]
        root.widgetVisibility = vis
        root.saveSettings()
    }

    Component.onCompleted: {
        loadSettingsProc.running = true
    }

    // Material 3 Palette
    readonly property color colBg: "#232D33"
    readonly property color colPillBg: "#303B42"
    readonly property color colAccent: "#C2E7FF"
    readonly property color colAccentGreen: "#A2C9C2"
    readonly property color colTextPrimary: "#FFFFFF"
    readonly property color colTextSecondary: "#9CA8AC"

    Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
    Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

    // Main Floating Pill / Expanded Card
    Rectangle {
        anchors.fill: parent
        color: root.colBg
        radius: root.isExpanded ? 24 : 17
        border.color: "#24FFFFFF"
        border.width: 1.5
        antialiasing: true
        clip: true

        Column {
            anchors.fill: parent
            anchors.margins: root.isExpanded ? 12 : 4
            spacing: 8

            // ─── Header Notch Bar (Entire bar is clickable to toggle expand/collapse) ───
            Rectangle {
                width: parent.width
                height: root.isExpanded ? 30 : 26
                radius: 13
                color: notchArea.containsMouse ? "#1AFFFFFF" : "transparent"
                antialiasing: true

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    // Active Green Indicator Dot
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 7
                        height: 7
                        radius: 3.5
                        color: root.colAccentGreen
                        antialiasing: true
                    }

                    // Notch Title Label
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.isExpanded ? "Desktop Widgets" : "Awe Widgets"
                        color: root.colTextPrimary
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 0.5
                        font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                    }

                    // Expanding Chevron Icon
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.isExpanded ? "▲" : "▼"
                        color: root.colAccent
                        font.pixelSize: 9
                        font.bold: true
                    }
                }

                MouseArea {
                    id: notchArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.isExpanded = !root.isExpanded
                }
            }

            // ─── Expanded Scrollable Widget Toggle Grid ───
            Item {
                visible: root.isExpanded
                width: parent.width
                height: parent.height - 38
                clip: true

                Flickable {
                    id: scrollFlick
                    anchors.fill: parent
                    contentWidth: width
                    contentHeight: widgetGrid.implicitHeight + 10
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true

                    Grid {
                        id: widgetGrid
                        width: parent.width
                        columns: 2
                        spacing: 6

                        Repeater {
                            model: [
                                { id: "clock", label: "Clock" },
                                { id: "poster", label: "Poster" },
                                { id: "calendar", label: "Calendar" },
                                { id: "media", label: "Media Player" },
                                { id: "sysinfo", label: "System Info" },
                                { id: "battery", label: "Battery" },
                                { id: "weather", label: "Weather" },
                                { id: "quickcontrols", label: "Volume / Brightness" },
                                { id: "network", label: "Network" },
                                { id: "notes", label: "Notes" },
                                { id: "todo", label: "Tasks / Todo" },
                                { id: "timer", label: "Pomodoro Timer" },
                                { id: "thermal", label: "Hardware Thermals" },
                                { id: "quote", label: "Daily Quote" },
                                { id: "clipboard", label: "Clipboard" },
                                { id: "crypto", label: "Crypto Ticker" },
                                { id: "worldclock", label: "World Clock" },
                                { id: "git", label: "Git Dashboard" },
                                { id: "resourcewheel", label: "Resource Wheel" }
                            ]

                            Rectangle {
                                width: (widgetGrid.width - 6) / 2
                                height: 28
                                radius: 14
                                color: (root.widgetVisibility[modelData.id] !== false) ? root.colPillBg : "#1A2226"
                                border.color: (root.widgetVisibility[modelData.id] !== false) ? root.colAccent : "#2A343A"
                                border.width: 1
                                antialiasing: true

                                Row {
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    spacing: 6

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 6
                                        height: 6
                                        radius: 3
                                        color: (root.widgetVisibility[modelData.id] !== false) ? root.colAccentGreen : "#667780"
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.label
                                        color: (root.widgetVisibility[modelData.id] !== false) ? "#FFFFFF" : "#809299"
                                        font.pixelSize: 10
                                        font.bold: (root.widgetVisibility[modelData.id] !== false)
                                        elide: Text.ElideRight
                                        width: parent.width - 20
                                        font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.toggleWidget(modelData.id)
                                }
                            }
                        }
                    }
                }

                // Smooth Minimalist Scrollbar Indicator
                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: 2
                    width: 3
                    radius: 1.5
                    color: "#15FFFFFF"
                    visible: scrollFlick.contentHeight > scrollFlick.height

                    Rectangle {
                        width: parent.width
                        height: Math.max(20, (scrollFlick.height / scrollFlick.contentHeight) * scrollFlick.height)
                        y: (scrollFlick.contentY / (scrollFlick.contentHeight - scrollFlick.height)) * (scrollFlick.height - height)
                        radius: 1.5
                        color: root.colAccent
                        antialiasing: true
                    }
                }
            }
        }
    }
}
