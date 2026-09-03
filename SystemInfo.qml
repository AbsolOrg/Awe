import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property real screenWidth: 1920
    property real screenHeight: 1080

    // Orientation toggle (false = horizontal, true = vertical)
    property bool isVertical: false

    // Position & sizing properties
    property real posX: 40
    property real posY: 40
    property real scaleFactor: 0.9

    x: Math.max(10, Math.min(root.screenWidth - root.width - 10, posX))
    y: Math.max(10, Math.min(root.screenHeight - root.height - 10, posY))
    width: Math.round((isVertical ? 120 : 380) * scaleFactor)
    height: Math.round((isVertical ? 384 : 120) * scaleFactor)

    // ─── Settings Persistence ───
    Process {
        id: loadSettingsProc
        command: ["sh", "-c", "cat ~/.config/quickshell/widget_settings.json 2>/dev/null || echo '{}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text)
                    if (data.sysinfo) {
                        if (data.sysinfo.isVertical !== undefined) root.isVertical = data.sysinfo.isVertical
                        if (data.sysinfo.scale !== undefined) root.scaleFactor = Math.max(0.5, Math.min(2.5, data.sysinfo.scale))
                        var baseW = root.isVertical ? 120 : 380
                        var baseH = root.isVertical ? 384 : 120
                        var w = Math.round(baseW * root.scaleFactor)
                        var h = Math.round(baseH * root.scaleFactor)
                        if (data.sysinfo.x !== undefined) root.posX = Math.max(10, Math.min(root.screenWidth - w - 10, data.sysinfo.x))
                        if (data.sysinfo.y !== undefined) root.posY = Math.max(10, Math.min(root.screenHeight - h - 10, data.sysinfo.y))
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
        var script = "python3 -c 'import json, os; p=os.path.expanduser(\"~/.config/quickshell/widget_settings.json\"); d=json.load(open(p)) if os.path.exists(p) else {}; d[\"sysinfo\"]={\"x\":" + Math.round(root.x) + ",\"y\":" + Math.round(root.y) + ",\"scale\":" + root.scaleFactor.toFixed(2) + ",\"isVertical\":" + (root.isVertical ? "True" : "False") + "}; open(p,\"w\").write(json.dumps(d,indent=2))'"
        saveSettingsProc.command = ["sh", "-c", script]
        saveSettingsProc.running = true
    }

    Component.onCompleted: {
        loadSettingsProc.running = true
        diskProc.running = true
    }

    // ─── Theme Palette ───
    readonly property color colBgTile: Theme.colBgTile
    readonly property color colBadgeBg: Theme.colPillBg
    readonly property color colTextPrimary: Theme.colTextPrimary
    readonly property color colTextSecondary: Theme.colTextSecondary

    // ─── System info properties ───
    property int cpuNumeric: 17
    property string cpuUsage: "17%"
    property int memNumeric: 12
    property string memUsage: "12%"
    property int diskNumeric: 56
    property string diskUsage: "56%"

    // ─── CPU Usage (reads /proc/stat) ───
    property var lastCpu: ({ idle: 0, total: 0 })

    Process {
        id: cpuProc
        command: ["cat", "/proc/stat"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var line = text.split("\n")[0]
                var parts = line.trim().split(/\s+/)
                var idle = parseInt(parts[4])
                var total = 0
                for (var i = 1; i < parts.length; i++) total += parseInt(parts[i])

                var diffIdle = idle - root.lastCpu.idle
                var diffTotal = total - root.lastCpu.total
                var usage = diffTotal > 0 ? (100 * (1 - diffIdle / diffTotal)) : 0

                root.cpuNumeric = Math.min(100, Math.max(0, Math.round(usage)))
                root.cpuUsage = root.cpuNumeric + "%"
                root.lastCpu = { idle: idle, total: total }
            }
        }
    }

    // ─── Memory Usage (reads /proc/meminfo) ───
    Process {
        id: memProc
        command: ["cat", "/proc/meminfo"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.split("\n")
                var total = 0, avail = 0
                for (var i = 0; i < lines.length; i++) {
                    if (lines[i].startsWith("MemTotal:"))
                        total = parseInt(lines[i].split(/\s+/)[1])
                    else if (lines[i].startsWith("MemAvailable:"))
                        avail = parseInt(lines[i].split(/\s+/)[1])
                }
                var used = total - avail
                var percent = total > 0 ? Math.round((used / total) * 100) : 0

                root.memNumeric = Math.min(100, Math.max(0, percent))
                root.memUsage = root.memNumeric + "%"
            }
        }
    }

    // ─── Disk Usage (df -h /) ───
    Process {
        id: diskProc
        command: ["sh", "-c", "df -k / | tail -1 | awk '{print $5}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var raw = text.trim().replace("%", "")
                var val = parseInt(raw)
                if (!isNaN(val)) {
                    root.diskNumeric = Math.min(100, Math.max(0, val))
                    root.diskUsage = root.diskNumeric + "%"
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            cpuProc.running = true
            memProc.running = true
            diskProc.running = true
        }
    }

    // ─── Scaled Visual Content ───
    Item {
        id: scaledContent
        width: root.isVertical ? 120 : 380
        height: root.isVertical ? 384 : 120
        scale: root.scaleFactor
        transformOrigin: Item.TopLeft

        // Dynamic Layout Container (Row for horizontal, Column for vertical)
        Grid {
            anchors.fill: parent
            columns: root.isVertical ? 1 : 3
            spacing: 12

            // ─── Tile 1: CPU Widget ───
            Rectangle {
                width: 118
                height: 120
                radius: 32
                color: root.colBgTile
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

                Item {
                    anchors.fill: parent
                    anchors.margins: 14

                    // Top Right Custom Pentagon Badge with CPU Pulse Icon
                    Item {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        width: 38
                        height: 38

                        Canvas {
                            anchors.fill: parent
                            antialiasing: true
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.reset()
                                var cx = width / 2
                                var cy = height / 2
                                var r = 16

                                ctx.beginPath()
                                for (var i = 0; i < 6; i++) {
                                    var angle = (i * 60 - 90) * Math.PI / 180
                                    var px = cx + r * Math.cos(angle)
                                    var py = cy + r * Math.sin(angle)
                                    if (i === 0) ctx.moveTo(px, py)
                                    else ctx.lineTo(px, py)
                                }
                                ctx.closePath()
                                ctx.fillStyle = root.colBadgeBg
                                ctx.fill()

                                // CPU Activity Waveform Icon
                                ctx.beginPath()
                                ctx.moveTo(cx - 8, cy)
                                ctx.lineTo(cx - 4, cy)
                                ctx.lineTo(cx - 2, cy - 6)
                                ctx.lineTo(cx + 2, cy + 6)
                                ctx.lineTo(cx + 4, cy - 3)
                                ctx.lineTo(cx + 6, cy)
                                ctx.lineTo(cx + 8, cy)
                                ctx.strokeStyle = "#FFFFFF"
                                ctx.lineWidth = 2
                                ctx.lineJoin = "round"
                                ctx.lineCap = "round"
                                ctx.stroke()
                            }
                        }
                    }

                    // Bottom Left CPU Percentage and Label
                    Column {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        spacing: 0

                        Text {
                            text: root.cpuUsage
                            color: root.colTextPrimary
                            font.pixelSize: 22
                            font.bold: true
                            font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                        }

                        Text {
                            text: "CPU"
                            color: root.colTextSecondary
                            font.pixelSize: 12
                            font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                        }
                    }
                }
            }

            // ─── Tile 2: RAM Widget ───
            Rectangle {
                width: 118
                height: 120
                radius: 32
                color: root.colBgTile
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

                Item {
                    anchors.fill: parent
                    anchors.margins: 14

                    // Top Right Custom 4-Lobe Clover / Squircle Badge with Chip Icon
                    Item {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        width: 38
                        height: 38

                        Canvas {
                            anchors.fill: parent
                            antialiasing: true
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.reset()
                                var cx = width / 2
                                var cy = height / 2
                                var rOuter = 16
                                var rInner = 12

                                ctx.beginPath()
                                for (var a = 0; a <= 360; a += 5) {
                                    var rad = a * Math.PI / 180
                                    var r = rInner + (rOuter - rInner) * (Math.cos(4 * rad) + 1.0) / 2.0
                                    var x = cx + r * Math.sin(rad)
                                    var y = cy - r * Math.cos(rad)
                                    if (a === 0) ctx.moveTo(x, y)
                                    else ctx.lineTo(x, y)
                                }
                                ctx.closePath()
                                ctx.fillStyle = root.colBadgeBg
                                ctx.fill()

                                // RAM Memory Chip Icon
                                ctx.beginPath()
                                ctx.rect(cx - 6, cy - 6, 12, 12)
                                ctx.strokeStyle = "#FFFFFF"
                                ctx.lineWidth = 1.8
                                ctx.stroke()

                                ctx.beginPath()
                                ctx.arc(cx, cy, 2, 0, 2 * Math.PI)
                                ctx.fillStyle = "#FFFFFF"
                                ctx.fill()
                            }
                        }
                    }

                    // Bottom Left RAM Percentage and Label
                    Column {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        spacing: 0

                        Text {
                            text: root.memUsage
                            color: root.colTextPrimary
                            font.pixelSize: 22
                            font.bold: true
                            font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                        }

                        Text {
                            text: "RAM"
                            color: root.colTextSecondary
                            font.pixelSize: 12
                            font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                        }
                    }
                }
            }

            // ─── Tile 3: Disk Widget ───
            Rectangle {
                width: 118
                height: 120
                radius: 32
                color: root.colBgTile
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

                Item {
                    anchors.fill: parent
                    anchors.margins: 14

                    // Top Right Custom Scalloped Gear Badge with Disk Stack Icon
                    Item {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        width: 38
                        height: 38

                        Canvas {
                            anchors.fill: parent
                            antialiasing: true
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.reset()
                                var cx = width / 2
                                var cy = height / 2
                                var rOuter = 16
                                var rInner = 13
                                var teeth = 12

                                ctx.beginPath()
                                for (var a = 0; a <= 360; a += 2) {
                                    var rad = a * Math.PI / 180
                                    var wave = (Math.cos(teeth * rad) + 1.0) / 2.0
                                    var r = rInner + (rOuter - rInner) * wave
                                    var x = cx + r * Math.sin(rad)
                                    var y = cy - r * Math.cos(rad)
                                    if (a === 0) ctx.moveTo(x, y)
                                    else ctx.lineTo(x, y)
                                }
                                ctx.closePath()
                                ctx.fillStyle = root.colBadgeBg
                                ctx.fill()

                                // Disk Storage Stack Icon
                                ctx.strokeStyle = "#FFFFFF"
                                ctx.lineWidth = 1.8
                                ctx.beginPath()
                                ctx.moveTo(cx - 7, cy - 4)
                                ctx.lineTo(cx + 7, cy - 4)
                                ctx.moveTo(cx - 7, cy)
                                ctx.lineTo(cx + 7, cy)
                                ctx.moveTo(cx - 7, cy + 4)
                                ctx.lineTo(cx + 7, cy + 4)
                                ctx.stroke()
                            }
                        }
                    }

                    // Bottom Left Disk Percentage and Label
                    Column {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        spacing: 0

                        Text {
                            text: root.diskUsage
                            color: root.colTextPrimary
                            font.pixelSize: 22
                            font.bold: true
                            font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                        }

                        Text {
                            text: "Disk"
                            color: root.colTextSecondary
                            font.pixelSize: 12
                            font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                        }
                    }
                }
            }
        }
    }

    // ─── Interactive MouseArea ───
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
            root.isVertical = !root.isVertical
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
}
