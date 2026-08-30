import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property real screenWidth: 1920
    property real screenHeight: 1080

    // Position & sizing properties
    property real posX: 40
    property real posY: 490
    property real scaleFactor: 0.88

    x: Math.max(10, Math.min(root.screenWidth - root.width - 10, posX))
    y: Math.max(10, Math.min(root.screenHeight - root.height - 10, posY))
    width: Math.round(290 * scaleFactor)
    height: Math.round(150 * scaleFactor)

    // Visualizer modes: "bars" (16-bar spectrum), "wave" (sine soundwave), "radial" (circular)
    property string vizMode: "bars"
    property var modeList: ["bars", "wave", "radial"]
    property int modeIndex: 0
    property bool isPlaying: false
    property real wavePhase: 0

    // ─── Settings Persistence ───
    Process {
        id: loadSettingsProc
        command: ["sh", "-c", "cat ~/.config/quickshell/widget_settings.json 2>/dev/null || echo '{}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text)
                    if (data.visualizer) {
                        if (data.visualizer.scale !== undefined) root.scaleFactor = Math.max(0.5, Math.min(2.5, data.visualizer.scale))
                        if (data.visualizer.mode !== undefined) {
                            root.vizMode = data.visualizer.mode
                            root.modeIndex = Math.max(0, root.modeList.indexOf(data.visualizer.mode))
                        }
                        var w = Math.round(290 * root.scaleFactor)
                        var h = Math.round(150 * root.scaleFactor)
                        if (data.visualizer.x !== undefined) root.posX = Math.max(10, Math.min(root.screenWidth - w - 10, data.visualizer.x))
                        if (data.visualizer.y !== undefined) root.posY = Math.max(10, Math.min(root.screenHeight - h - 10, data.visualizer.y))
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
        var script = "python3 -c 'import json, os; p=os.path.expanduser(\"~/.config/quickshell/widget_settings.json\"); d=json.load(open(p)) if os.path.exists(p) else {}; d[\"visualizer\"]={\"x\":" + Math.round(root.x) + ",\"y\":" + Math.round(root.y) + ",\"scale\":" + root.scaleFactor.toFixed(2) + ",\"mode\":\"" + root.vizMode + "\"}; open(p,\"w\").write(json.dumps(d,indent=2))'"
        saveSettingsProc.command = ["sh", "-c", script]
        saveSettingsProc.running = true
    }

    // MPRIS Player Status Check
    Process {
        id: mprisProc
        command: ["playerctl", "status"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var st = text.trim().toLowerCase()
                root.isPlaying = (st === "playing")
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: mprisProc.running = true
    }

    // High frequency animation timer for wave canvas
    Timer {
        interval: 35
        running: true
        repeat: true
        onTriggered: {
            root.wavePhase = (root.wavePhase + 0.12) % (Math.PI * 2)
            vizCanvas.requestPaint()
        }
    }

    Component.onCompleted: {
        loadSettingsProc.running = true
    }

    // Material 3 Palette
    readonly property color colBg: "#232D33"
    readonly property color colPillBg: "#303B42"
    readonly property color colAccent: "#C2E7FF"
    readonly property color colAccentGreen: "#A2C9C2"
    readonly property color colAccentLilac: "#D7AEFB"
    readonly property color colTextPrimary: "#FFFFFF"
    readonly property color colTextSecondary: "#9CA8AC"

    // ─── Scaled Visual Content ───
    Item {
        id: scaledContent
        width: 290
        height: 150
        scale: root.scaleFactor
        transformOrigin: Item.TopLeft

        // Drag & Double-Click Mode MouseArea
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            drag.target: root
            drag.axis: Drag.XAndYAxis
            drag.minimumX: 10
            drag.maximumX: Math.max(10, root.screenWidth - root.width - 10)
            drag.minimumY: 10
            drag.maximumY: Math.max(10, root.screenHeight - root.height - 10)
            cursorShape: drag.active ? Qt.ClosedHandCursor : (containsMouse ? Qt.OpenHandCursor : Qt.ArrowCursor)

            onDoubleClicked: {
                root.modeIndex = (root.modeIndex + 1) % root.modeList.length
                root.vizMode = root.modeList[root.modeIndex]
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
            border.color: "#1FFFFFFF"
            border.width: 1.5
            antialiasing: true

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8

                // Header Row: VISUALIZER Badge + Mode Pill
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
                                color: root.isPlaying ? root.colAccentGreen : root.colAccent
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "SPECTRUM"
                                color: "#FFFFFF"
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 0.6
                                font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                            }
                        }
                    }

                    Item {
                        width: Math.max(0, parent.width - parent.children[0].width - modeBadge.width)
                        height: 1
                    }

                    // Mode Switcher Pill
                    Rectangle {
                        id: modeBadge
                        height: 22
                        width: modeLabel.implicitWidth + 16
                        radius: 11
                        color: root.colPillBg
                        antialiasing: true

                        Text {
                            id: modeLabel
                            anchors.centerIn: parent
                            text: (root.vizMode === "bars" ? "16-Bar Equalizer" : (root.vizMode === "wave" ? "Fluid Sine Wave" : "Radial Soundwave"))
                            color: root.colAccent
                            font.pixelSize: 9
                            font.bold: true
                            font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.modeIndex = (root.modeIndex + 1) % root.modeList.length
                                root.vizMode = root.modeList[root.modeIndex]
                                root.saveSettings()
                            }
                        }
                    }
                }

                // Middle Canvas Visualizer
                Item {
                    width: parent.width
                    height: 74

                    Canvas {
                        id: vizCanvas
                        anchors.fill: parent
                        antialiasing: true

                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()
                            var w = width
                            var h = height
                            var cx = w / 2
                            var cy = h / 2
                            var phase = root.wavePhase
                            var amp = root.isPlaying ? 1.0 : 0.35

                            if (root.vizMode === "bars") {
                                // 16-Bar Spectrum Equalizer
                                var numBars = 16
                                var barW = (w - (numBars - 1) * 4) / numBars

                                for (var i = 0; i < numBars; i++) {
                                    var val = Math.sin(phase + i * 0.45) * 0.5 + 0.5
                                    var val2 = Math.cos(phase * 1.3 + i * 0.3) * 0.3 + 0.3
                                    var barH = Math.max(4, (val * 0.7 + val2 * 0.3) * (h - 8) * amp)
                                    var x = i * (barW + 4)
                                    var y = h - barH

                                    // Gradient bar fill
                                    var grad = ctx.createLinearGradient(x, y, x, h)
                                    grad.addColorStop(0, root.colAccent)
                                    grad.addColorStop(1, root.colAccentGreen)
                                    ctx.fillStyle = grad
                                    ctx.fillRect(x, y, barW, barH)
                                }
                            } else if (root.vizMode === "wave") {
                                // Fluid Sine Waveforms
                                ctx.lineWidth = 2.5
                                ctx.strokeStyle = root.colAccent
                                ctx.lineCap = "round"
                                ctx.beginPath()

                                for (var wx = 0; wx <= w; wx += 3) {
                                    var normX = wx / w
                                    var sine = Math.sin(normX * Math.PI * 4 + phase) * Math.cos(normX * Math.PI * 2 + phase * 0.5)
                                    var wy = cy + sine * (h * 0.38) * amp
                                    if (wx === 0) ctx.moveTo(wx, wy)
                                    else ctx.lineTo(wx, wy)
                                }
                                ctx.stroke()

                                // Secondary Harmonic Waveform
                                ctx.lineWidth = 1.5
                                ctx.strokeStyle = root.colAccentGreen
                                ctx.beginPath()

                                for (var wx2 = 0; wx2 <= w; wx2 += 3) {
                                    var normX2 = wx2 / w
                                    var sine2 = Math.sin(normX2 * Math.PI * 6 - phase * 1.2) * 0.7
                                    var wy2 = cy + sine2 * (h * 0.25) * amp
                                    if (wx2 === 0) ctx.moveTo(wx2, wy2)
                                    else ctx.lineTo(wx2, wy2)
                                }
                                ctx.stroke()
                            } else if (root.vizMode === "radial") {
                                // Radial Pulsing Soundwave
                                var rBase = 22
                                ctx.lineWidth = 2
                                ctx.strokeStyle = root.colAccent
                                ctx.beginPath()

                                for (var a = 0; a <= 360; a += 4) {
                                    var rad = a * Math.PI / 180
                                    var waveR = rBase + (Math.sin(a * 6 * Math.PI / 180 + phase * 2) * 9 + Math.cos(a * 3 * Math.PI / 180 - phase) * 4) * amp
                                    var rx = cx + waveR * Math.cos(rad)
                                    var ry = cy + waveR * Math.sin(rad)
                                    if (a === 0) ctx.moveTo(rx, ry)
                                    else ctx.lineTo(rx, ry)
                                }
                                ctx.closePath()
                                ctx.stroke()

                                // Center Core Dot
                                ctx.fillStyle = root.colAccentGreen
                                ctx.beginPath()
                                ctx.arc(cx, cy, 4, 0, Math.PI * 2)
                                ctx.fill()
                            }
                        }
                    }
                }

                // Bottom Status Pill
                Row {
                    width: parent.width
                    Text {
                        text: root.isPlaying ? "Audio Active · Syncing spectrum" : "Ambient Mode · Ready for media"
                        color: root.colTextSecondary
                        font.pixelSize: 9
                        font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                    }
                }
            }
        }
    }
}
