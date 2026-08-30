import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property real screenWidth: 1920
    property real screenHeight: 1080

    // Position & sizing properties
    property real posX: 10
    property real posY: 517
    property real scaleFactor: 0.8

    x: Math.max(10, Math.min(root.screenWidth - root.width - 10, posX))
    y: Math.max(10, Math.min(root.screenHeight - root.height - 10, posY))
    width: Math.round(360 * scaleFactor)
    height: Math.round(180 * scaleFactor)

    // ─── Settings Persistence ───
    Process {
        id: loadSettingsProc
        command: ["sh", "-c", "cat ~/.config/quickshell/widget_settings.json 2>/dev/null || echo '{}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text)
                    if (data.media) {
                        if (data.media.scale !== undefined) root.scaleFactor = Math.max(0.5, Math.min(2.5, data.media.scale))
                        var w = Math.round(360 * root.scaleFactor)
                        var h = Math.round(180 * root.scaleFactor)
                        if (data.media.x !== undefined) root.posX = Math.max(10, Math.min(root.screenWidth - w - 10, data.media.x))
                        if (data.media.y !== undefined) root.posY = Math.max(10, Math.min(root.screenHeight - h - 10, data.media.y))
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
        var script = "python3 -c 'import json, os; p=os.path.expanduser(\"~/.config/quickshell/widget_settings.json\"); d=json.load(open(p)) if os.path.exists(p) else {}; d[\"media\"]={\"x\":" + Math.round(root.x) + ",\"y\":" + Math.round(root.y) + ",\"scale\":" + root.scaleFactor.toFixed(2) + "}; open(p,\"w\").write(json.dumps(d,indent=2))'"
        saveSettingsProc.command = ["sh", "-c", script]
        saveSettingsProc.running = true
    }

    // ─── Media Properties ───
    property string title: "Pretty Patterns"
    property string artist: "ATLAS"
    property string artUrl: ""
    property string status: "Stopped"
    property real positionSec: 0
    property real lengthSec: 0
    property string posStr: "0:00"
    property string lenStr: "0:00"
    property real progress: 0.35

    function fmtTime(seconds) {
        var m = Math.floor(seconds / 60)
        var s = Math.floor(seconds % 60)
        return m + ":" + (s < 10 ? "0" + s : s)
    }

    // ─── MPRIS Process Query ───
    Process {
        id: mediaProc
        command: ["playerctl", "metadata", "--format", "{{title}};;{{artist}};;{{mpris:artUrl}};;{{position}};;{{mpris:length}};;{{status}}"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var line = text.trim()
                if (line.length > 0 && line.includes(";;")) {
                    var parts = line.split(";;")
                    root.title = parts[0] || "Unknown Title"
                    root.artist = parts[1] || "Unknown Artist"
                    root.artUrl = parts[2] || ""

                    var posMicro = parseFloat(parts[3]) || 0
                    var lenMicro = parseFloat(parts[4]) || 0
                    root.positionSec = posMicro / 1000000.0
                    root.lengthSec = lenMicro / 1000000.0
                    root.status = parts[5] || "Playing"

                    root.posStr = root.fmtTime(root.positionSec)
                    root.lenStr = root.lengthSec > 0 ? root.fmtTime(root.lengthSec) : "--:--"
                    root.progress = root.lengthSec > 0 ? Math.min(1.0, root.positionSec / root.lengthSec) : 0
                } else {
                    root.status = "Stopped"
                    root.title = "Pretty Patterns"
                    root.artist = "ATLAS"
                    root.progress = 0.35
                    root.artUrl = ""
                    root.posStr = "1:12"
                    root.lenStr = "3:45"
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            mediaProc.running = true
        }
    }

    Component.onCompleted: {
        loadSettingsProc.running = true
        mediaProc.running = true
    }

    // ─── Material / Pixel Dark Palette ───
    readonly property color colBg: "#2B353A"              // Android Pixel Dark Slate Card
    readonly property color colPillBg: "#3D484E"          // Control Pill Background
    readonly property color colAccent: "#C2E7FF"          // Pixel Light Cyan/Green Accent
    readonly property color colAccentDark: "#1E2A30"      // Dark Text on Accent
    readonly property color colTextPrimary: "#E1E2E5"
    readonly property color colTextSecondary: "#A0ACAC"

    // ─── Scaled Visual Content ───
    Item {
        id: scaledContent
        width: 360
        height: 180
        scale: root.scaleFactor
        transformOrigin: Item.TopLeft

        Rectangle {
            anchors.fill: parent
            color: root.colBg
            radius: 28
            antialiasing: true

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                // Top Header: Album Art + Track Info + Media Controls Pill
                Row {
                    width: parent.width
                    height: 84
                    spacing: 12

                    // Album Art Squircle
                    Rectangle {
                        width: 84
                        height: 84
                        radius: 20
                        color: root.colPillBg
                        clip: true
                        antialiasing: true

                        Image {
                            anchors.fill: parent
                            source: root.artUrl
                            fillMode: Image.PreserveAspectCrop
                            visible: root.artUrl.length > 0 && status === Image.Ready
                            asynchronous: true
                        }

                        // Pixel Fallback Pattern / Art
                        Item {
                            anchors.fill: parent
                            visible: !root.artUrl || root.artUrl.length === 0

                            Rectangle {
                                anchors.fill: parent
                                color: "#3B474D"
                            }

                            Canvas {
                                anchors.fill: parent
                                antialiasing: true
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.reset()
                                    ctx.fillStyle = "#A2C9C2"
                                    ctx.beginPath()
                                    ctx.arc(42, 42, 28, 0, Math.PI * 2)
                                    ctx.fill()
                                    ctx.fillStyle = "#2B353A"
                                    ctx.beginPath()
                                    ctx.arc(42, 42, 10, 0, Math.PI * 2)
                                    ctx.fill()
                                }
                            }
                        }
                    }

                    // Middle Column: Title & Artist
                    Column {
                        width: parent.width - 84 - 12 - 110 - 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3

                        Text {
                            text: root.title
                            color: root.colTextPrimary
                            font.pixelSize: 15
                            font.bold: true
                            elide: Text.ElideRight
                            width: parent.width
                            font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                        }

                        Text {
                            text: root.artist
                            color: root.colTextSecondary
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            width: parent.width
                            font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                        }
                    }

                    // Right Controls Pill (Prev, Play/Scallop, Next)
                    Rectangle {
                        width: 110
                        height: 48
                        radius: 24
                        color: root.colPillBg
                        anchors.verticalCenter: parent.verticalCenter
                        antialiasing: true

                        Row {
                            anchors.centerIn: parent
                            spacing: 4

                            // Previous Track
                            Item {
                                width: 28
                                height: 28

                                Text {
                                    anchors.centerIn: parent
                                    text: "⏮"
                                    color: root.colTextPrimary
                                    font.pixelSize: 13
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        Quickshell.execDetached(["playerctl", "previous"])
                                        mediaProc.running = true
                                    }
                                }
                            }

                            // Scalloped Play / Pause Button (Pixel Style)
                            Item {
                                width: 36
                                height: 36

                                Canvas {
                                    id: scallopCanvas
                                    anchors.fill: parent
                                    antialiasing: true

                                    onPaint: {
                                        var ctx = getContext("2d")
                                        ctx.reset()
                                        var cx = width / 2
                                        var cy = height / 2
                                        var rOuter = 17
                                        var rInner = 14
                                        var points = 12

                                        ctx.beginPath()
                                        for (var i = 0; i < points * 2; i++) {
                                            var angle = (i * Math.PI) / points
                                            var r = (i % 2 === 0) ? rOuter : rInner
                                            var x = cx + r * Math.cos(angle)
                                            var y = cy + r * Math.sin(angle)
                                            if (i === 0) ctx.moveTo(x, y)
                                            else ctx.lineTo(x, y)
                                        }
                                        ctx.closePath()
                                        ctx.fillStyle = root.colAccent
                                        ctx.fill()
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: root.status === "Playing" ? "❚❚" : "▶"
                                    color: root.colAccentDark
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        Quickshell.execDetached(["playerctl", "play-pause"])
                                        mediaProc.running = true
                                    }
                                }
                            }

                            // Next Track
                            Item {
                                width: 28
                                height: 28

                                Text {
                                    anchors.centerIn: parent
                                    text: "⏭"
                                    color: root.colTextPrimary
                                    font.pixelSize: 13
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        Quickshell.execDetached(["playerctl", "next"])
                                        mediaProc.running = true
                                    }
                                }
                            }
                        }
                    }
                }

                // Bottom Section: Progress Bar & Seek Timers
                Column {
                    width: parent.width
                    spacing: 6

                    // Wave / Pill Progress Bar
                    Rectangle {
                        width: parent.width
                        height: 8
                        radius: 4
                        color: root.colPillBg
                        antialiasing: true

                        Rectangle {
                            width: Math.max(parent.radius * 2, parent.width * root.progress)
                            height: parent.height
                            radius: parent.radius
                            color: root.colAccent
                            antialiasing: true
                        }
                    }

                    // Pos & Length Text
                    Row {
                        width: parent.width

                        Text {
                            text: root.posStr
                            color: root.colTextSecondary
                            font.pixelSize: 10
                            font.family: "Google Sans Flex, Google Sans, Inter, monospace"
                        }

                        Item {
                            width: Math.max(0, parent.width - parent.children[0].width - parent.children[2].width)
                            height: 1
                        }

                        Text {
                            text: root.lenStr
                            color: root.colTextSecondary
                            font.pixelSize: 10
                            font.family: "Google Sans Flex, Google Sans, Inter, monospace"
                        }
                    }
                }
            }
        }
    }

    // ─── Drag & Resize MouseArea ───
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
}
