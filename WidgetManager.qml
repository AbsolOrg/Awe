import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property real screenWidth: 1920
    property real screenHeight: 1080

    // Top centered floating pill
    x: Math.round((screenWidth - width) / 2)
    y: 12
    width: isExpanded ? 360 : 190
    height: isExpanded ? 320 : 34
    z: 999

    property bool isExpanded: false
    property bool lockDragging: false

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
                    if (data.manager) {
                        if (data.manager.lockDragging !== undefined) root.lockDragging = data.manager.lockDragging
                        if (data.manager.visibility !== undefined) {
                            var vis = Object.assign({}, root.widgetVisibility, data.manager.visibility)
                            root.widgetVisibility = vis
                        }
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
            lockDragging: root.lockDragging,
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
            anchors.margins: root.isExpanded ? 14 : 4
            spacing: 10

            // ─── Header Pill Bar (Always Visible) ───
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                // Settings Toggle Button
                Rectangle {
                    width: 26
                    height: 26
                    radius: 13
                    color: root.isExpanded ? root.colAccent : root.colPillBg
                    antialiasing: true

                    Canvas {
                        anchors.fill: parent
                        antialiasing: true
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()
                            var cx = width / 2
                            var cy = height / 2

                            ctx.fillStyle = root.isExpanded ? "#1E2A30" : "#FFFFFF"
                            ctx.beginPath()
                            ctx.arc(cx, cy, 3, 0, Math.PI * 2)
                            ctx.fill()

                            ctx.strokeStyle = root.isExpanded ? "#1E2A30" : "#FFFFFF"
                            ctx.lineWidth = 1.6
                            for (var i = 0; i < 6; i++) {
                                var a = i * Math.PI / 3
                                ctx.beginPath()
                                ctx.moveTo(cx + Math.cos(a) * 4.5, cy + Math.sin(a) * 4.5)
                                ctx.lineTo(cx + Math.cos(a) * 7.5, cy + Math.sin(a) * 7.5)
                                ctx.stroke()
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.isExpanded = !root.isExpanded
                    }
                }

                // Desktop Widgets Label
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.isExpanded ? "Widget Manager" : "Awe Desktop"
                    color: root.colTextPrimary
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 0.4
                    font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                }

                // Lock / Unlock Dragging Button
                Rectangle {
                    width: 26
                    height: 26
                    radius: 13
                    color: root.lockDragging ? "#FFB4AB" : root.colPillBg
                    antialiasing: true

                    Canvas {
                        anchors.fill: parent
                        antialiasing: true
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()
                            var cx = width / 2
                            var cy = height / 2

                            ctx.fillStyle = root.lockDragging ? "#1E2A30" : "#FFFFFF"
                            ctx.fillRect(cx - 5, cy - 1, 10, 7)

                            ctx.strokeStyle = root.lockDragging ? "#1E2A30" : "#FFFFFF"
                            ctx.lineWidth = 1.5
                            ctx.beginPath()
                            if (root.lockDragging) {
                                ctx.arc(cx, cy - 1, 3.5, Math.PI, 0)
                            } else {
                                ctx.arc(cx - 1, cy - 2, 3.5, Math.PI, 0.2)
                            }
                            ctx.stroke()
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.lockDragging = !root.lockDragging
                            root.saveSettings()
                        }
                    }
                }
            }

            // ─── Expanded Widget Toggle Grid (Visible when isExpanded) ───
            Grid {
                visible: root.isExpanded
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
                        width: (parent.width - 6) / 2
                        height: 26
                        radius: 13
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
    }
}
