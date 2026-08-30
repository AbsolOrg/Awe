import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property real screenWidth: 1920
    property real screenHeight: 1080

    // Position & sizing properties
    property real posX: 40
    property real posY: 550
    property real scaleFactor: 0.85

    x: Math.max(10, Math.min(root.screenWidth - root.width - 10, posX))
    y: Math.max(10, Math.min(root.screenHeight - root.height - 10, posY))
    width: Math.round(390 * scaleFactor)
    height: Math.round(195 * scaleFactor)

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
                        var w = Math.round(390 * root.scaleFactor)
                        var h = Math.round(195 * root.scaleFactor)
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

    // ─── Real MPRIS Media State Properties ───
    property bool hasActivePlayer: false
    property string title: "No Media Playing"
    property string artist: "Ready for playback"
    property string artUrl: ""
    property string status: "Stopped"
    property string playerName: "Media"
    property real positionSec: 0
    property real lengthSec: 0
    property string posStr: "0:00"
    property string lenStr: "0:00"
    property real progress: 0.0
    property real wavePhase: 0.0

    function fmtTime(seconds) {
        if (!seconds || seconds <= 0 || isNaN(seconds)) return "0:00"
        var m = Math.floor(seconds / 60)
        var s = Math.floor(seconds % 60)
        return m + ":" + (s < 10 ? "0" + s : s)
    }

    function updateTimes() {
        root.posStr = root.fmtTime(root.positionSec)
        root.lenStr = root.lengthSec > 0 ? root.fmtTime(root.lengthSec) : "0:00"
        root.progress = (root.lengthSec > 0) ? Math.min(1.0, Math.max(0, root.positionSec / root.lengthSec)) : 0
    }

    // Process for executing media commands
    Process {
        id: controlProc
        running: false
    }

    function sendMediaCmd(action) {
        if (action === "play-pause") controlProc.command = ["playerctl", "play-pause"]
        else if (action === "next") controlProc.command = ["playerctl", "next"]
        else if (action === "previous") controlProc.command = ["playerctl", "previous"]
        else if (action === "rewind") controlProc.command = ["playerctl", "position", "10-"]
        else if (action === "forward") controlProc.command = ["playerctl", "position", "10+"]
        controlProc.running = true
        // Query immediately after command
        queryTimer.start()
    }

    Timer {
        id: queryTimer
        interval: 300
        repeat: false
        onTriggered: mediaProc.running = true
    }

    // ─── MPRIS Process Query ───
    Process {
        id: mediaProc
        command: ["playerctl", "metadata", "--format", "{{playerName}};;{{title}};;{{artist}};;{{mpris:artUrl}};;{{position}};;{{mpris:length}};;{{status}}"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var line = text.trim()
                if (line.length > 0 && line.includes(";;") && !line.includes("No players found") && !line.includes("No player could handle")) {
                    var parts = line.split(";;")
                    root.hasActivePlayer = true
                    root.playerName = (parts[0] || "Media").replace(/^[a-z]/, (c) => c.toUpperCase())
                    root.title = (parts[1] && parts[1].trim().length > 0) ? parts[1].trim() : "Unknown Title"
                    root.artist = (parts[2] && parts[2].trim().length > 0) ? parts[2].trim() : "Unknown Artist"
                    root.artUrl = parts[3] || ""

                    var posMicro = parseFloat(parts[4]) || 0
                    var lenMicro = parseFloat(parts[5]) || 0
                    root.positionSec = posMicro / 1000000.0
                    root.lengthSec = lenMicro / 1000000.0
                    root.status = parts[6] || "Playing"

                    root.updateTimes()
                } else {
                    root.hasActivePlayer = false
                    root.status = "Stopped"
                    root.title = "No Media Playing"
                    root.artist = "Ready for playback"
                    root.artUrl = ""
                    root.positionSec = 0
                    root.lengthSec = 0
                    root.progress = 0
                    root.updateTimes()
                }
            }
        }
    }

    // Progress Polling Timer
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            mediaProc.running = true
            if (root.hasActivePlayer && root.status === "Playing") {
                root.positionSec = Math.min(root.lengthSec, root.positionSec + 1)
                root.updateTimes()
            }
        }
    }

    // Squiggly Wave Animation Timer (ONLY runs when real media is actually playing)
    Timer {
        interval: 35
        running: root.hasActivePlayer && root.status === "Playing"
        repeat: true
        onTriggered: {
            root.wavePhase = (root.wavePhase + 0.15) % (Math.PI * 2)
            waveSeekCanvas.requestPaint()
        }
    }

    Component.onCompleted: {
        loadSettingsProc.running = true
        mediaProc.running = true
    }

    // ─── Material 3 Dark Slate Palette ───
    readonly property color colBg: "#232D33"              // Material 3 Dark Slate Surface
    readonly property color colPillBg: "#303B42"          // Control Pill / Inactive Track
    readonly property color colAccent: "#C2E7FF"          // M3 Cyan Accent
    readonly property color colAccentDark: "#003549"      // Dark Fill for Scalloped Button Icon
    readonly property color colTextPrimary: "#E1E2E5"
    readonly property color colTextSecondary: "#9CA8AC"

    // ─── Scaled Visual Content ───
    Item {
        id: scaledContent
        width: 390
        height: 195
        scale: root.scaleFactor
        transformOrigin: Item.TopLeft

        // Drag MouseArea on Card Background (Underneath controls)
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

        // Main Material 3 Card
        Rectangle {
            anchors.fill: parent
            color: root.colBg
            radius: 32
            border.color: "#37434A"
            border.width: 1.5
            antialiasing: true

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                // ─── Top Section: Album Art + Track Info + Soundwave Equalizer ───
                Row {
                    width: parent.width
                    height: 72
                    spacing: 12

                    // Album Art Squircle / Vinyl
                    Rectangle {
                        width: 72
                        height: 72
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

                        // Pixel Material Fallback Graphic (Headphones / Music Note)
                        Item {
                            anchors.fill: parent
                            visible: !root.artUrl || root.artUrl.length === 0

                            Rectangle {
                                anchors.fill: parent
                                color: "#2B363C"
                            }

                            Canvas {
                                anchors.fill: parent
                                antialiasing: true
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.reset()
                                    var cx = width / 2
                                    var cy = height / 2

                                    // Outer headphone arch
                                    ctx.strokeStyle = root.hasActivePlayer ? root.colAccent : "#809292"
                                    ctx.lineWidth = 2.5
                                    ctx.lineCap = "round"
                                    ctx.beginPath()
                                    ctx.arc(cx, cy - 2, 16, Math.PI, 0)
                                    ctx.stroke()

                                    // Left & right ear pads
                                    ctx.fillStyle = root.hasActivePlayer ? root.colAccent : "#809292"
                                    ctx.beginPath()
                                    ctx.arc(cx - 15, cy - 2, 4.5, 0, Math.PI * 2)
                                    ctx.arc(cx + 15, cy - 2, 4.5, 0, Math.PI * 2)
                                    ctx.fill()
                                }
                            }
                        }
                    }

                    // Track Title, Artist, Player Badge, & Equalizer
                    Column {
                        width: parent.width - 72 - 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        // Row with Player Pill and Equalizer
                        Row {
                            width: parent.width

                            // Player Pill Tag
                            Rectangle {
                                height: 18
                                width: playerRow.implicitWidth + 12
                                radius: 9
                                color: root.colPillBg
                                antialiasing: true

                                Row {
                                    id: playerRow
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 5
                                        height: 5
                                        radius: 2.5
                                        color: (root.hasActivePlayer && root.status === "Playing") ? "#A2C9C2" : "#6E7C82"
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: root.hasActivePlayer ? root.playerName : "Ready"
                                        color: root.colTextSecondary
                                        font.pixelSize: 9
                                        font.bold: true
                                        font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                                    }
                                }
                            }

                            Item {
                                width: Math.max(0, parent.width - parent.children[0].width - eqRow.width)
                                height: 1
                            }

                            // Animated Equalizer Visualizer Bars (Only visible when actually playing)
                            Row {
                                id: eqRow
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 3
                                visible: root.hasActivePlayer && root.status === "Playing"

                                Repeater {
                                    model: 4
                                    Rectangle {
                                        width: 3
                                        height: 6 + Math.abs(Math.sin(root.wavePhase + index * 1.2)) * 10
                                        radius: 1.5
                                        color: root.colAccent
                                        anchors.bottom: parent.bottom
                                        antialiasing: true
                                    }
                                }
                            }
                        }

                        // Track Title
                        Text {
                            text: root.title
                            color: root.hasActivePlayer ? root.colTextPrimary : "#8D9A9E"
                            font.pixelSize: 15
                            font.bold: true
                            elide: Text.ElideRight
                            width: parent.width
                            font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                        }

                        // Artist Name
                        Text {
                            text: root.artist
                            color: root.colTextSecondary
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            width: parent.width
                            font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                        }
                    }
                }

                // ─── Middle Section: Android 14/15 Squiggly Wavy Seekbar ───
                Column {
                    width: parent.width
                    spacing: 3

                    Item {
                        id: progressTrack
                        width: parent.width
                        height: 18

                        // Squiggly Wave Canvas
                        Canvas {
                            id: waveSeekCanvas
                            anchors.fill: parent
                            antialiasing: true

                            Connections {
                                target: root
                                function onProgressChanged() { waveSeekCanvas.requestPaint() }
                                function onStatusChanged() { waveSeekCanvas.requestPaint() }
                            }

                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.reset()
                                var cy = height / 2
                                var totalW = width
                                var isPlaying = root.hasActivePlayer && root.status === "Playing"
                                var playedW = Math.max(0, Math.min(totalW, totalW * root.progress))

                                // Draw Inactive Base Track (Right side)
                                ctx.strokeStyle = root.colPillBg
                                ctx.lineWidth = 4
                                ctx.lineCap = "round"
                                ctx.beginPath()
                                ctx.moveTo(Math.max(playedW, 6), cy)
                                ctx.lineTo(totalW - 2, cy)
                                ctx.stroke()

                                // Draw Active Wave Track (Left side)
                                if (playedW > 0) {
                                    ctx.strokeStyle = root.colAccent
                                    ctx.lineWidth = 4
                                    ctx.lineCap = "round"
                                    ctx.lineJoin = "round"
                                    ctx.beginPath()

                                    if (isPlaying) {
                                        // Sine wave path
                                        var wavelength = 18.0
                                        var amplitude = 3.2
                                        ctx.moveTo(2, cy)
                                        for (var x = 2; x <= playedW; x += 2) {
                                            var y = cy + Math.sin((x / wavelength) * Math.PI * 2 + root.wavePhase) * amplitude
                                            ctx.lineTo(x, y)
                                        }
                                    } else {
                                        // Straight flat pill path when paused / stopped
                                        ctx.moveTo(2, cy)
                                        ctx.lineTo(playedW, cy)
                                    }
                                    ctx.stroke()
                                }
                            }
                        }

                        // M3 Slider Thumb Handle
                        Rectangle {
                            visible: root.hasActivePlayer && root.lengthSec > 0
                            width: 6
                            height: 14
                            radius: 3
                            color: root.colAccent
                            x: Math.min(parent.width - width, Math.max(0, parent.width * root.progress - width / 2))
                            anchors.verticalCenter: parent.verticalCenter
                            antialiasing: true
                        }

                        // Interactive Seek MouseArea
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: (root.hasActivePlayer && root.lengthSec > 0) ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: (mouse) => {
                                if (root.hasActivePlayer && root.lengthSec > 0) {
                                    var ratio = Math.max(0, Math.min(1.0, mouse.x / width))
                                    root.progress = ratio
                                    root.positionSec = Math.round(ratio * root.lengthSec)
                                    root.updateTimes()
                                    waveSeekCanvas.requestPaint()
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

                // ─── Bottom Section: Complete Playback Controls Row ───
                Rectangle {
                    width: parent.width
                    height: 48
                    radius: 24
                    color: root.colPillBg
                    antialiasing: true

                    Row {
                        anchors.centerIn: parent
                        spacing: 14

                        // Rewind (-10s) Vector Button
                        Rectangle {
                            width: 32
                            height: 32
                            radius: 16
                            color: rewArea.containsMouse ? "#3E4C54" : "transparent"
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
                                id: rewArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.sendMediaCmd("rewind")
                            }
                        }

                        // Previous Track Vector Button
                        Rectangle {
                            width: 32
                            height: 32
                            radius: 16
                            color: prevArea.containsMouse ? "#3E4C54" : "transparent"
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
                                id: prevArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
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
                                    function onHasActivePlayerChanged() { scallopCanvas.requestPaint() }
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
                                    if (root.hasActivePlayer && root.status === "Playing") {
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
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.sendMediaCmd("play-pause")
                            }
                        }

                        // Next Track Vector Button
                        Rectangle {
                            width: 32
                            height: 32
                            radius: 16
                            color: nextArea.containsMouse ? "#3E4C54" : "transparent"
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
                                id: nextArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.sendMediaCmd("next")
                            }
                        }

                        // Forward (+10s) Vector Button
                        Rectangle {
                            width: 32
                            height: 32
                            radius: 16
                            color: fwdArea.containsMouse ? "#3E4C54" : "transparent"
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
                                id: fwdArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.sendMediaCmd("forward")
                            }
                        }
                    }
                }
            }
        }
    }
}
