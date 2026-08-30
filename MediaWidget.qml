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
    width: Math.round(380 * scaleFactor)
    height: Math.round(190 * scaleFactor)

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
                        var w = Math.round(380 * root.scaleFactor)
                        var h = Math.round(190 * root.scaleFactor)
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

    // ─── Built-in Demo Playlist for Seamless Playback ───
    property var demoTracks: [
        { title: "Pretty Patterns", artist: "ATLAS", duration: 225 },
        { title: "Midnight Horizon", artist: "Pixel Waves", duration: 198 },
        { title: "Summer Breeze", artist: "California Drive", duration: 240 },
        { title: "Neon Sunset", artist: "Studio M3", duration: 210 }
    ]
    property int currentDemoTrackIndex: 0

    // ─── Media State Properties ───
    property string title: "Pretty Patterns"
    property string artist: "ATLAS"
    property string artUrl: ""
    property string status: "Playing"
    property real positionSec: 72
    property real lengthSec: 225
    property string posStr: "1:12"
    property string lenStr: "3:45"
    property real progress: 0.32
    property bool hasActivePlayer: false

    function fmtTime(seconds) {
        var m = Math.floor(seconds / 60)
        var s = Math.floor(seconds % 60)
        return m + ":" + (s < 10 ? "0" + s : s)
    }

    // Process for executing media commands
    Process {
        id: controlProc
        running: false
    }

    function sendMediaCmd(action) {
        if (hasActivePlayer) {
            if (action === "play-pause") controlProc.command = ["playerctl", "play-pause"]
            else if (action === "next") controlProc.command = ["playerctl", "next"]
            else if (action === "previous") controlProc.command = ["playerctl", "previous"]
            else if (action === "rewind") controlProc.command = ["playerctl", "position", "10-"]
            else if (action === "forward") controlProc.command = ["playerctl", "position", "10+"]
            controlProc.running = true
        } else {
            // Built-in Player Simulation when no system MPRIS player is running
            if (action === "play-pause") {
                root.status = (root.status === "Playing") ? "Paused" : "Playing"
            } else if (action === "next") {
                root.currentDemoTrackIndex = (root.currentDemoTrackIndex + 1) % root.demoTracks.length
                var nextTrk = root.demoTracks[root.currentDemoTrackIndex]
                root.title = nextTrk.title
                root.artist = nextTrk.artist
                root.lengthSec = nextTrk.duration
                root.positionSec = 0
            } else if (action === "previous") {
                root.currentDemoTrackIndex = (root.currentDemoTrackIndex - 1 + root.demoTracks.length) % root.demoTracks.length
                var prevTrk = root.demoTracks[root.currentDemoTrackIndex]
                root.title = prevTrk.title
                root.artist = prevTrk.artist
                root.lengthSec = prevTrk.duration
                root.positionSec = 0
            } else if (action === "rewind") {
                root.positionSec = Math.max(0, root.positionSec - 10)
            } else if (action === "forward") {
                root.positionSec = Math.min(root.lengthSec, root.positionSec + 10)
            }
            root.updateTimes()
        }
    }

    function updateTimes() {
        root.posStr = root.fmtTime(root.positionSec)
        root.lenStr = root.lengthSec > 0 ? root.fmtTime(root.lengthSec) : "0:00"
        root.progress = root.lengthSec > 0 ? Math.min(1.0, root.positionSec / root.lengthSec) : 0
    }

    // ─── MPRIS Process Query ───
    Process {
        id: mediaProc
        command: ["playerctl", "metadata", "--format", "{{title}};;{{artist}};;{{mpris:artUrl}};;{{position}};;{{mpris:length}};;{{status}}"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var line = text.trim()
                if (line.length > 0 && line.includes(";;") && !line.includes("No players found")) {
                    var parts = line.split(";;")
                    root.hasActivePlayer = true
                    root.title = parts[0] || "Unknown Title"
                    root.artist = parts[1] || "Unknown Artist"
                    root.artUrl = parts[2] || ""

                    var posMicro = parseFloat(parts[3]) || 0
                    var lenMicro = parseFloat(parts[4]) || 0
                    root.positionSec = posMicro / 1000000.0
                    root.lengthSec = lenMicro / 1000000.0
                    root.status = parts[5] || "Playing"

                    root.updateTimes()
                } else {
                    root.hasActivePlayer = false
                }
            }
        }
    }

    // Playback Progress Timer
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            mediaProc.running = true
            if (!root.hasActivePlayer && root.status === "Playing") {
                root.positionSec = (root.positionSec + 1) % (root.lengthSec + 1)
                root.updateTimes()
            }
        }
    }

    Component.onCompleted: {
        loadSettingsProc.running = true
        mediaProc.running = true
    }

    // ─── Material You / M3 Dark Palette ───
    readonly property color colBg: "#2B353A"              // Android Pixel Dark Slate Card
    readonly property color colPillBg: "#3D484E"          // Control Pill / Inactive Track
    readonly property color colAccent: "#C2E7FF"          // M3 Light Cyan Active Accent
    readonly property color colAccentDark: "#1E2A30"      // Dark Fill for Scalloped Button Icon
    readonly property color colTextPrimary: "#E1E2E5"
    readonly property color colTextSecondary: "#A0ACAC"

    // ─── Scaled Visual Content ───
    Item {
        id: scaledContent
        width: 380
        height: 190
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

                // Top Section: Album Art + Song Title/Artist
                Row {
                    width: parent.width
                    height: 80
                    spacing: 12

                    // Album Art Squircle
                    Rectangle {
                        width: 80
                        height: 80
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

                        // Pixel Fallback Vector Art
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
                                    ctx.arc(40, 40, 26, 0, Math.PI * 2)
                                    ctx.fill()
                                    ctx.fillStyle = "#2B353A"
                                    ctx.beginPath()
                                    ctx.arc(40, 40, 9, 0, Math.PI * 2)
                                    ctx.fill()
                                }
                            }
                        }
                    }

                    // Title & Artist Column
                    Column {
                        width: parent.width - 80 - 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Text {
                            text: root.title
                            color: root.colTextPrimary
                            font.pixelSize: 16
                            font.bold: true
                            elide: Text.ElideRight
                            width: parent.width
                            font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                        }

                        Text {
                            text: root.artist
                            color: root.colTextSecondary
                            font.pixelSize: 13
                            elide: Text.ElideRight
                            width: parent.width
                            font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                        }
                    }
                }

                // Middle Section: Material 3 Progress Track with Thumb Handle
                Column {
                    width: parent.width
                    spacing: 4

                    Item {
                        id: progressTrack
                        width: parent.width
                        height: 14

                        // Inactive Track
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 6
                            radius: 3
                            color: root.colPillBg
                            antialiasing: true
                        }

                        // Active Track (Accent Pill)
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.max(6, parent.width * root.progress)
                            height: 6
                            radius: 3
                            color: root.colAccent
                            antialiasing: true
                        }

                        // M3 Slider Thumb Handle Indicator
                        Rectangle {
                            width: 6
                            height: 14
                            radius: 3
                            color: root.colAccent
                            x: Math.min(parent.width - width, Math.max(0, parent.width * root.progress - width / 2))
                            anchors.verticalCenter: parent.verticalCenter
                            antialiasing: true
                        }

                        // Interactive Seek Click/Drag
                        MouseArea {
                            anchors.fill: parent
                            onClicked: (mouse) => {
                                var ratio = Math.max(0, Math.min(1.0, mouse.x / width))
                                root.progress = ratio
                                root.positionSec = Math.round(ratio * root.lengthSec)
                                root.updateTimes()
                                if (root.hasActivePlayer) {
                                    controlProc.command = ["playerctl", "position", root.positionSec]
                                    controlProc.running = true
                                }
                            }
                        }
                    }

                    // Duration Timers Row
                    Row {
                        width: parent.width

                        Text {
                            text: root.posStr
                            color: root.colTextSecondary
                            font.pixelSize: 10
                            font.bold: true
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
                            font.bold: true
                            font.family: "Google Sans Flex, Google Sans, Inter, monospace"
                        }
                    }
                }

                // Bottom Section: Complete Playback Controls Row (Rewind, Prev, Play/Pause Scallop, Next, Forward)
                Rectangle {
                    width: parent.width
                    height: 48
                    radius: 24
                    color: root.colPillBg
                    antialiasing: true

                    Row {
                        anchors.centerIn: parent
                        spacing: 12

                        // Rewind (-10s) Vector Button
                        Item {
                            width: 32
                            height: 32
                            anchors.verticalCenter: parent.verticalCenter

                            Canvas {
                                anchors.fill: parent
                                antialiasing: true
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.reset()
                                    ctx.strokeStyle = root.colTextPrimary
                                    ctx.lineWidth = 1.8
                                    ctx.beginPath()
                                    ctx.arc(16, 16, 9, Math.PI * 0.2, Math.PI * 1.8, true)
                                    ctx.stroke()

                                    ctx.fillStyle = root.colTextPrimary
                                    ctx.beginPath()
                                    ctx.moveTo(8, 8)
                                    ctx.lineTo(13, 11)
                                    ctx.lineTo(12, 6)
                                    ctx.closePath()
                                    ctx.fill()

                                    ctx.font = "bold 8px sans-serif"
                                    ctx.textAlign = "center"
                                    ctx.textBaseline = "middle"
                                    ctx.fillText("10", 16, 17)
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.sendMediaCmd("rewind")
                            }
                        }

                        // Previous Track Vector Button
                        Item {
                            width: 32
                            height: 32
                            anchors.verticalCenter: parent.verticalCenter

                            Canvas {
                                anchors.fill: parent
                                antialiasing: true
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.reset()
                                    ctx.fillStyle = root.colTextPrimary
                                    ctx.fillRect(9, 10, 2, 12)
                                    ctx.beginPath()
                                    ctx.moveTo(21, 10)
                                    ctx.lineTo(13, 16)
                                    ctx.lineTo(21, 22)
                                    ctx.closePath()
                                    ctx.fill()
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.sendMediaCmd("previous")
                            }
                        }

                        // Scalloped Play / Pause Main Button (Pixel M3 Style)
                        Item {
                            width: 42
                            height: 42
                            anchors.verticalCenter: parent.verticalCenter

                            Canvas {
                                id: scallopCanvas
                                anchors.fill: parent
                                antialiasing: true

                                Connections {
                                    target: root
                                    function onStatusChanged() { scallopCanvas.requestPaint() }
                                }

                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.reset()
                                    var cx = width / 2
                                    var cy = height / 2
                                    var rOuter = 20
                                    var rInner = 16.5
                                    var points = 12

                                    // Scalloped Background
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

                                    // Vector Play / Pause Icon
                                    ctx.fillStyle = root.colAccentDark
                                    if (root.status === "Playing") {
                                        ctx.fillRect(cx - 5.5, cy - 7, 4, 14)
                                        ctx.fillRect(cx + 1.5, cy - 7, 4, 14)
                                    } else {
                                        ctx.beginPath()
                                        ctx.moveTo(cx - 4, cy - 8)
                                        ctx.lineTo(cx + 7, cy)
                                        ctx.lineTo(cx - 4, cy + 8)
                                        ctx.closePath()
                                        ctx.fill()
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.sendMediaCmd("play-pause")
                            }
                        }

                        // Next Track Vector Button
                        Item {
                            width: 32
                            height: 32
                            anchors.verticalCenter: parent.verticalCenter

                            Canvas {
                                anchors.fill: parent
                                antialiasing: true
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.reset()
                                    ctx.fillStyle = root.colTextPrimary
                                    ctx.beginPath()
                                    ctx.moveTo(11, 10)
                                    ctx.lineTo(19, 16)
                                    ctx.lineTo(11, 22)
                                    ctx.closePath()
                                    ctx.fill()
                                    ctx.fillRect(21, 10, 2, 12)
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.sendMediaCmd("next")
                            }
                        }

                        // Forward (+10s) Vector Button
                        Item {
                            width: 32
                            height: 32
                            anchors.verticalCenter: parent.verticalCenter

                            Canvas {
                                anchors.fill: parent
                                antialiasing: true
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.reset()
                                    ctx.strokeStyle = root.colTextPrimary
                                    ctx.lineWidth = 1.8
                                    ctx.beginPath()
                                    ctx.arc(16, 16, 9, Math.PI * 1.2, Math.PI * 0.8, false)
                                    ctx.stroke()

                                    ctx.fillStyle = root.colTextPrimary
                                    ctx.beginPath()
                                    ctx.moveTo(24, 8)
                                    ctx.lineTo(19, 11)
                                    ctx.lineTo(20, 6)
                                    ctx.closePath()
                                    ctx.fill()

                                    ctx.font = "bold 8px sans-serif"
                                    ctx.textAlign = "center"
                                    ctx.textBaseline = "middle"
                                    ctx.fillText("10", 16, 17)
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.sendMediaCmd("forward")
                            }
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
