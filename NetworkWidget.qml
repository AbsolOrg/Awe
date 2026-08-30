import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property real screenWidth: 1920
    property real screenHeight: 1080

    // Position & sizing properties
    property real posX: 800
    property real posY: 400
    property real scaleFactor: 0.9

    x: Math.max(10, Math.min(root.screenWidth - root.width - 10, posX))
    y: Math.max(10, Math.min(root.screenHeight - root.height - 10, posY))
    width: Math.round(320 * scaleFactor)
    height: Math.round(140 * scaleFactor)

    // Network properties
    property string ssid: "Connected"
    property string ipAddress: "127.0.0.1"
    property bool hideIp: false
    property string downSpeedStr: "0 KB/s"
    property string upSpeedStr: "0 KB/s"
    property int signalPercent: 88
    property bool isConnected: true

    // Internal speed tracking
    property var lastNet: ({ rx: 0, tx: 0, time: 0 })
    property var historyData: [10, 15, 8, 25, 40, 20, 60, 45, 80, 55, 30, 70]

    // ─── Settings Persistence ───
    Process {
        id: loadSettingsProc
        command: ["sh", "-c", "cat ~/.config/quickshell/widget_settings.json 2>/dev/null || echo '{}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text)
                    if (data.network) {
                        if (data.network.scale !== undefined) root.scaleFactor = Math.max(0.5, Math.min(2.5, data.network.scale))
                        if (data.network.hideIp !== undefined) root.hideIp = data.network.hideIp
                        var w = Math.round(320 * root.scaleFactor)
                        var h = Math.round(140 * root.scaleFactor)
                        if (data.network.x !== undefined) root.posX = Math.max(10, Math.min(root.screenWidth - w - 10, data.network.x))
                        if (data.network.y !== undefined) root.posY = Math.max(10, Math.min(root.screenHeight - h - 10, data.network.y))
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
        var script = "python3 -c 'import json, os; p=os.path.expanduser(\"~/.config/quickshell/widget_settings.json\"); d=json.load(open(p)) if os.path.exists(p) else {}; d[\"network\"]={\"x\":" + Math.round(root.x) + ",\"y\":" + Math.round(root.y) + ",\"scale\":" + root.scaleFactor.toFixed(2) + ",\"hideIp\":" + (root.hideIp ? "True" : "False") + "}; open(p,\"w\").write(json.dumps(d,indent=2))'"
        saveSettingsProc.command = ["sh", "-c", script]
        saveSettingsProc.running = true
    }

    // ─── Network Info Process ───
    Process {
        id: netProc
        command: ["sh", "-c", "ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes:' | cut -d: -f2 | head -1); ip=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -1); rx=0; tx=0; while read -r line; do if echo \"$line\" | grep -qv 'lo:'; then r=$(echo \"$line\" | awk '{print $2}'); t=$(echo \"$line\" | awk '{print $10}'); rx=$((rx + r)); tx=$((tx + t)); fi; done < <(tail -n +3 /proc/net/dev); echo \"${ssid:-Online};;${ip:-127.0.0.1};;$rx;;$tx\""]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var line = text.trim()
                if (line.includes(";;")) {
                    var parts = line.split(";;")
                    root.ssid = parts[0] || "Connected"
                    root.ipAddress = parts[1] || "127.0.0.1"

                    var rxNow = parseInt(parts[2]) || 0
                    var txNow = parseInt(parts[3]) || 0
                    var now = Date.now()

                    if (root.lastNet.time > 0 && now > root.lastNet.time) {
                        var dt = (now - root.lastNet.time) / 1000.0
                        var rxDiff = Math.max(0, rxNow - root.lastNet.rx) / dt
                        var txDiff = Math.max(0, txNow - root.lastNet.tx) / dt

                        // Format string
                        if (rxDiff >= 1048576) root.downSpeedStr = (rxDiff / 1048576).toFixed(1) + " MB/s"
                        else root.downSpeedStr = Math.round(rxDiff / 1024) + " KB/s"

                        if (txDiff >= 1048576) root.upSpeedStr = (txDiff / 1048576).toFixed(1) + " MB/s"
                        else root.upSpeedStr = Math.round(txDiff / 1024) + " KB/s"

                        // Push to history for sparkline graph
                        var val = Math.min(100, Math.max(5, Math.round(rxDiff / 20480)))
                        var hist = root.historyData.slice(1)
                        hist.push(val)
                        root.historyData = hist
                        sparkCanvas.requestPaint()
                    }

                    root.lastNet = { rx: rxNow, tx: txNow, time: now }
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: netProc.running = true
    }

    Component.onCompleted: {
        loadSettingsProc.running = true
        netProc.running = true
    }

    // Material 3 Palette
    readonly property color colBg: "#3A454B"
    readonly property color colBadgeBg: "#4D585F"
    readonly property color colAccent: "#C2E7FF"
    readonly property color colAccentGreen: "#D1E8DA"
    readonly property color colTextPrimary: "#FFFFFF"
    readonly property color colTextSecondary: "#B0BEC5"

    // ─── Scaled Visual Content ───
    Item {
        id: scaledContent
        width: 320
        height: 140
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

            onDoubleClicked: {
                root.hideIp = !root.hideIp
                root.saveSettings()
            }

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
            antialiasing: true

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8

                // Header Row: Network Badge Pill + IP Address (Double-click to Hide/Show)
                Row {
                    width: parent.width

                    Rectangle {
                        height: 22
                        width: badgeRow.implicitWidth + 16
                        radius: 11
                        color: root.colBadgeBg
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
                                color: root.colAccentGreen
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "NETWORK"
                                color: root.colTextPrimary
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 0.6
                                font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                            }
                        }
                    }

                    Item {
                        width: Math.max(0, parent.width - parent.children[0].width - ipPill.width)
                        height: 1
                    }

                    // IP Badge Pill (Clickable / Double-clickable to toggle hidden state)
                    Rectangle {
                        id: ipPill
                        height: 22
                        width: ipRow.implicitWidth + 14
                        radius: 11
                        color: ipMouseArea.containsMouse ? "#55626A" : root.colBadgeBg
                        antialiasing: true

                        Row {
                            id: ipRow
                            anchors.centerIn: parent
                            spacing: 5

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.hideIp ? "•••.•••.•••.•••" : root.ipAddress
                                color: root.hideIp ? "#88979E" : root.colTextSecondary
                                font.pixelSize: 10
                                font.bold: true
                                font.family: "Google Sans Flex, Google Sans, Inter, monospace"
                            }
                        }

                        MouseArea {
                            id: ipMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.hideIp = !root.hideIp
                                root.saveSettings()
                            }
                        }
                    }
                }

                // Middle Row: Wi-Fi Icon Badge + SSID Name + Live Sparkline
                Row {
                    width: parent.width
                    height: 46
                    spacing: 10

                    // Wi-Fi Vector Icon Badge
                    Rectangle {
                        width: 42
                        height: 42
                        radius: 21
                        color: root.colBadgeBg
                        anchors.verticalCenter: parent.verticalCenter
                        antialiasing: true

                        Canvas {
                            anchors.fill: parent
                            antialiasing: true
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.reset()
                                var cx = width / 2
                                var cy = height / 2 + 5

                                ctx.fillStyle = "#FFFFFF"
                                ctx.beginPath()
                                ctx.arc(cx, cy - 2, 2.5, 0, Math.PI * 2)
                                ctx.fill()

                                ctx.strokeStyle = "#FFFFFF"
                                ctx.lineWidth = 1.8
                                ctx.beginPath()
                                ctx.arc(cx, cy - 2, 7, -Math.PI * 0.75, -Math.PI * 0.25)
                                ctx.stroke()

                                ctx.beginPath()
                                ctx.arc(cx, cy - 2, 12, -Math.PI * 0.75, -Math.PI * 0.25)
                                ctx.stroke()
                            }
                        }
                    }

                    // SSID & Status Column
                    Column {
                        width: 120
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: root.ssid
                            color: root.colTextPrimary
                            font.pixelSize: 14
                            font.bold: true
                            elide: Text.ElideRight
                            width: parent.width
                            font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                        }

                        Text {
                            text: "Online · Stable"
                            color: root.colTextSecondary
                            font.pixelSize: 10
                            font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                        }
                    }

                    // Sparkline Activity Graph Canvas
                    Canvas {
                        id: sparkCanvas
                        width: parent.width - 42 - 120 - 20
                        height: 38
                        anchors.verticalCenter: parent.verticalCenter
                        antialiasing: true

                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()
                            var data = root.historyData
                            if (!data || data.length < 2) return

                            var step = width / (data.length - 1)
                            ctx.strokeStyle = root.colAccent
                            ctx.lineWidth = 2
                            ctx.lineCap = "round"
                            ctx.lineJoin = "round"

                            ctx.beginPath()
                            for (var i = 0; i < data.length; i++) {
                                var x = i * step
                                var y = height - (data[i] / 100.0) * (height - 6) - 3
                                if (i === 0) ctx.moveTo(x, y)
                                else ctx.lineTo(x, y)
                            }
                            ctx.stroke()
                        }
                    }
                }

                // Bottom Row: Download & Upload Speed Pill Badges
                Row {
                    width: parent.width
                    spacing: 8

                    // Download Pill
                    Rectangle {
                        height: 24
                        width: (parent.width - 8) / 2
                        radius: 12
                        color: root.colBadgeBg
                        antialiasing: true

                        Row {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: "↓"
                                color: root.colAccent
                                font.pixelSize: 11
                                font.bold: true
                            }

                            Text {
                                text: root.downSpeedStr
                                color: root.colTextPrimary
                                font.pixelSize: 10
                                font.bold: true
                                font.family: "Google Sans Flex, Google Sans, Inter, monospace"
                            }
                        }
                    }

                    // Upload Pill
                    Rectangle {
                        height: 24
                        width: (parent.width - 8) / 2
                        radius: 12
                        color: root.colBadgeBg
                        antialiasing: true

                        Row {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: "↑"
                                color: root.colAccentGreen
                                font.pixelSize: 11
                                font.bold: true
                            }

                            Text {
                                text: root.upSpeedStr
                                color: root.colTextPrimary
                                font.pixelSize: 10
                                font.bold: true
                                font.family: "Google Sans Flex, Google Sans, Inter, monospace"
                            }
                        }
                    }
                }
            }
        }
    }
}
