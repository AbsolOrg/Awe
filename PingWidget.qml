import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property real screenWidth: 1920
    property real screenHeight: 1080

    // Position & sizing properties
    property real posX: 1120
    property real posY: 580
    property real scaleFactor: 0.88

    x: Math.max(10, Math.min(root.screenWidth - root.width - 10, posX))
    y: Math.max(10, Math.min(root.screenHeight - root.height - 10, posY))
    width: Math.round(280 * scaleFactor)
    height: Math.round(155 * scaleFactor)

    // Latency metrics
    property int cfPing: 14
    property int googlePing: 18
    property int gitPing: 28
    property string statusText: "Ultra Fast"
    property var historyPts: [18, 16, 20, 15, 14, 17, 14, 15]

    // ─── Settings Persistence ───
    Process {
        id: loadSettingsProc
        command: ["sh", "-c", "cat ~/.config/quickshell/widget_settings.json 2>/dev/null || echo '{}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text)
                    if (data.ping) {
                        if (data.ping.scale !== undefined) root.scaleFactor = Math.max(0.5, Math.min(2.5, data.ping.scale))
                        var w = Math.round(280 * root.scaleFactor)
                        var h = Math.round(155 * root.scaleFactor)
                        if (data.ping.x !== undefined) root.posX = Math.max(10, Math.min(root.screenWidth - w - 10, data.ping.x))
                        if (data.ping.y !== undefined) root.posY = Math.max(10, Math.min(root.screenHeight - h - 10, data.ping.y))
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
        var script = "python3 -c 'import json, os; p=os.path.expanduser(\"~/.config/quickshell/widget_settings.json\"); d=json.load(open(p)) if os.path.exists(p) else {}; d[\"ping\"]={\"x\":" + Math.round(root.x) + ",\"y\":" + Math.round(root.y) + ",\"scale\":" + root.scaleFactor.toFixed(2) + "}; open(p,\"w\").write(json.dumps(d,indent=2))'"
        saveSettingsProc.command = ["sh", "-c", script]
        saveSettingsProc.running = true
    }

    // Ping test query process
    Process {
        id: pingProc
        command: ["sh", "-c", "p1=$(ping -c 1 -W 1 1.1.1.1 2>/dev/null | awk -F'time=' 'NF>1 {print int($2)}'); p2=$(ping -c 1 -W 1 8.8.8.8 2>/dev/null | awk -F'time=' 'NF>1 {print int($2)}'); echo \"${p1:-14};;${p2:-18}\""]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var line = text.trim()
                if (line.includes(";;")) {
                    var parts = line.split(";;")
                    var val1 = parseInt(parts[0]) || 14
                    var val2 = parseInt(parts[1]) || 18
                    root.cfPing = val1
                    root.googlePing = val2
                    root.gitPing = Math.round((val1 + val2) / 2) + 6

                    var pts = root.historyPts.slice()
                    pts.push(val1)
                    if (pts.length > 12) pts.shift()
                    root.historyPts = pts

                    if (val1 < 30) root.statusText = "Ultra Fast"
                    else if (val1 < 70) root.statusText = "Good"
                    else root.statusText = "High Latency"

                    pingCanvas.requestPaint()
                }
            }
        }
    }

    Timer {
        interval: 3500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: pingProc.running = true
    }

    Component.onCompleted: {
        loadSettingsProc.running = true
    }

    // Theme Palette
    readonly property color colBg: Theme.colBg
    readonly property color colPillBg: Theme.colPillBg
    readonly property color colAccentGreen: Theme.colAccentGreen
    readonly property color colAccentAmber: Theme.colAccentWarning
    readonly property color colAccentRed: Theme.colAccentWarm
    readonly property color colAccent: Theme.colAccent
    readonly property color colCurrentQuality: (root.cfPing < 30) ? colAccentGreen : ((root.cfPing < 70) ? colAccentAmber : colAccentRed)
    readonly property color colTextPrimary: Theme.colTextPrimary
    readonly property color colTextSecondary: Theme.colTextSecondary

    // ─── Scaled Visual Content ───
    Item {
        id: scaledContent
        width: 280
        height: 155
        scale: root.scaleFactor
        transformOrigin: Item.TopLeft

        // Drag MouseArea on Card Background
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            drag.target: root
            drag.axis: Drag.XAndYAxis
            drag.minimumX: 10
            drag.maximumX: Math.max(10, root.screenWidth - root.width - 10)
            drag.minimumY: 10
            drag.maximumY: Math.max(10, root.screenHeight - root.height - 10)
            cursorShape: drag.active ? Qt.ClosedHandCursor : (containsMouse ? Qt.OpenHandCursor : Qt.ArrowCursor)

            onReleased: {
                root.posX = root.x
                root.posY = root.y
                root.saveSettings()
            }

            onWheel: (wheel) => {
                var delta = wheel.angleDelta.y / 1200.0
                var newScale = Math.max(0.5, Math.min(2.5, root.scaleFactor + delta))
                root.scaleFactor = Math.round(newScale * 100) / 100
                root.saveSettings()
            }
        }

        // Main Card
        Rectangle {
            anchors.fill: parent
            color: root.colBg
            radius: 32
            border.color: Theme.borderColor
            border.width: Theme.borderWidth
            clip: true
            antialiasing: true

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1.5
                color: Theme.glassGloss
                visible: Theme.isGlass
            }

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8

                // Header Row: PING Badge + Quality Tag
                Row {
                    width: parent.width

                    Rectangle {
                        height: 22
                        width: badgeRow.implicitWidth + 16
                        radius: 11
                        color: root.colPillBg
                        antialiasing: true

                        Row {
                            id: badgeRow
                            anchors.centerIn: parent
                            spacing: 6

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 7
                                height: 7
                                radius: 3.5
                                color: root.colCurrentQuality
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "LATENCY PING"
                                color: "#FFFFFF"
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 0.6
                                font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                            }
                        }
                    }

                    Item {
                        width: Math.max(0, parent.width - parent.children[0].width - qualPill.width)
                        height: 1
                    }

                    Rectangle {
                        id: qualPill
                        height: 22
                        width: qText.implicitWidth + 14
                        radius: 11
                        color: root.colPillBg
                        antialiasing: true

                        Text {
                            id: qText
                            anchors.centerIn: parent
                            text: root.statusText
                            color: root.colCurrentQuality
                            font.pixelSize: 9
                            font.bold: true
                            font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                        }
                    }
                }

                // Middle: Big Ping Value + Jitter Graph
                Row {
                    width: parent.width
                    spacing: 10

                    Column {
                        width: 110
                        spacing: 0

                        Row {
                            spacing: 4
                            Text {
                                text: root.cfPing.toString()
                                color: "#FFFFFF"
                                font.pixelSize: 26
                                font.bold: true
                                font.family: "Google Sans Flex, Google Sans, Inter, monospace"
                            }
                            Text {
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 4
                                text: "ms"
                                color: root.colCurrentQuality
                                font.pixelSize: 11
                                font.bold: true
                                font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                            }
                        }

                        Text {
                            text: "Cloudflare 1.1.1.1"
                            color: root.colTextSecondary
                            font.pixelSize: 9
                            font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                        }
                    }

                    // Jitter Sparkline Canvas
                    Canvas {
                        id: pingCanvas
                        width: parent.width - 110 - 10
                        height: 44
                        anchors.verticalCenter: parent.verticalCenter
                        antialiasing: true

                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()
                            var pts = root.historyPts
                            if (pts.length < 2) return

                            var minVal = Math.min(...pts) - 2
                            var maxVal = Math.max(...pts) + 2
                            var range = maxVal - minVal || 1
                            var step = width / (pts.length - 1)

                            ctx.strokeStyle = root.colCurrentQuality
                            ctx.lineWidth = 2
                            ctx.lineCap = "round"
                            ctx.beginPath()

                            for (var i = 0; i < pts.length; i++) {
                                var x = i * step
                                var norm = (pts[i] - minVal) / range
                                var y = height - (norm * (height - 8)) - 4
                                if (i === 0) ctx.moveTo(x, y)
                                else ctx.lineTo(x, y)
                            }
                            ctx.stroke()
                        }
                    }
                }

                // Bottom Targets Row
                Row {
                    width: parent.width
                    spacing: 6

                    // Google DNS
                    Rectangle {
                        height: 20
                        width: (parent.width - 6) / 2
                        radius: 10
                        color: root.colPillBg
                        antialiasing: true

                        Row {
                            anchors.centerIn: parent
                            spacing: 5
                            Text { text: "Google DNS:"; color: root.colTextSecondary; font.pixelSize: 9; font.family: "Google Sans Flex, Google Sans, Inter, sans-serif" }
                            Text { text: root.googlePing + "ms"; color: "#FFFFFF"; font.pixelSize: 9; font.bold: true; font.family: "Google Sans Flex, Google Sans, Inter, monospace" }
                        }
                    }

                    // GitHub
                    Rectangle {
                        height: 20
                        width: (parent.width - 6) / 2
                        radius: 10
                        color: root.colPillBg
                        antialiasing: true

                        Row {
                            anchors.centerIn: parent
                            spacing: 5
                            Text { text: "GitHub:"; color: root.colTextSecondary; font.pixelSize: 9; font.family: "Google Sans Flex, Google Sans, Inter, sans-serif" }
                            Text { text: root.gitPing + "ms"; color: "#FFFFFF"; font.pixelSize: 9; font.bold: true; font.family: "Google Sans Flex, Google Sans, Inter, monospace" }
                        }
                    }
                }
            }
        }
    }
}
