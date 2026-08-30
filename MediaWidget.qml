import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property real screenWidth: 1920
    property real screenHeight: 1080

    // Position & sizing properties
    property real posX: 100
    property real posY: 100
    property real scaleFactor: 1.0

    x: Math.max(0, Math.min(root.screenWidth - root.width, posX))
    y: Math.max(0, Math.min(root.screenHeight - root.height, posY))
    width: Math.round(420 * scaleFactor)
    height: Math.round(440 * scaleFactor)

    // ─── Media State Properties ───
    property string title: "No Media Playing"
    property string artist: "Waiting for player..."
    property string artUrl: ""
    property string status: "Paused"
    property real positionSec: 0
    property real lengthSec: 0

    // ─── Material 3 Color Palette ───
    readonly property color colBg: "#2B3236"              // Dark Surface
    readonly property color colPillBg: "#3F484C"          // Surface Container Highest
    readonly property color colAccent: "#A8C7FA"          // Primary (Light Blue)
    readonly property color colOnAccent: "#062E6F"        // On Primary (Dark Blue)
    readonly property color colTextPrimary: "#E3E2E6"     // On Surface
    readonly property color colTextSecondary: "#C4C6CA"   // On Surface Variant

    // ─── Backend: Media Control & Metadata ───
    
    // Command runner for Play/Pause/Next/Prev
    Process {
        id: controlProc
        running: false
    }

    function sendMediaCmd(action) {
        if (action === "play-pause") controlProc.command = ["playerctl", "play-pause"]
        else if (action === "next") controlProc.command = ["playerctl", "next"]
        else if (action === "previous") controlProc.command = ["playerctl", "previous"]
        controlProc.running = true
    }

    // Polling Process to get all metadata and time
    Process {
        id: mediaProc
        command: ["sh", "-c", "playerctl metadata --format '{{title}}|||{{artist}}|||{{mpris:artUrl}}|||{{status}}|||{{position}}|||{{mpris:length}}' 2>/dev/null || echo 'NONE'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var line = text.trim()
                if (line === "NONE" || line === "") {
                    root.title = "No Media"
                    root.artist = ""
                    root.artUrl = ""
                    root.status = "Paused"
                    return;
                }
                
                var parts = line.split("|||")
                if (parts.length >= 4) {
                    root.title = parts[0] || "Unknown Title"
                    root.artist = parts[1] || "Unknown Artist"
                    root.artUrl = parts[2] || ""
                    root.status = parts[3] || "Paused"
                    
                    var posMicro = parseFloat(parts[4]) || 0
                    var lenMicro = parseFloat(parts[5]) || 0
                    root.positionSec = posMicro / 1000000.0
                    root.lengthSec = lenMicro / 1000000.0
                }
            }
        }
    }

    // Timer to update UI every 1 second
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            mediaProc.running = true
        }
    }

    // ─── Dragging Logic (Background) ───
    MouseArea {
        anchors.fill: parent
        drag.target: root
        drag.axis: Drag.XAndYAxis
        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.ArrowCursor
        onReleased: {
            root.posX = root.x
            root.posY = root.y
        }
        onWheel: (wheel) => {
            var delta = wheel.angleDelta.y / 1200.0
            root.scaleFactor = Math.max(0.7, Math.min(1.5, root.scaleFactor + delta))
        }
    }

    // ─── Visual Content ───
    Item {
        id: scaledContent
        width: 420
        height: 440
        scale: root.scaleFactor
        transformOrigin: Item.TopLeft

        Rectangle {
            anchors.fill: parent
            color: root.colBg
            radius: 32
            antialiasing: true

            Column {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 24

                // ─── TOP HEADER (Art, Info, Controls) ───
                Row {
                    width: parent.width
                    height: 90
                    spacing: 16

                    // 1. Album Art
                    Rectangle {
                        width: 90
                        height: 90
                        radius: 16
                        color: root.colPillBg
                        clip: true
                        
                        Image {
                            anchors.fill: parent
                            source: root.artUrl
                            fillMode: Image.PreserveAspectCrop
                            visible: root.artUrl !== ""
                        }
                        
                        // Fallback icon if no art
                        Text {
                            anchors.centerIn: parent
                            text: "🎵"
                            font.pixelSize: 32
                            visible: root.artUrl === ""
                        }
                    }

                    // 2. Title & Artist
                    Column {
                        width: parent.width - 90 - controlsPill.width - 32
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        Text {
                            text: root.title
                            color: root.colTextPrimary
                            font.pixelSize: 18
                            font.bold: true
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            text: root.artist
                            color: root.colTextSecondary
                            font.pixelSize: 14
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }

                    // 3. Media Controls Pill (Aligned Right)
                    Rectangle {
                        id: controlsPill
                        width: 140
                        height: 56
                        radius: 28
                        color: root.colPillBg
                        anchors.verticalCenter: parent.verticalCenter

                        Row {
                            anchors.centerIn: parent
                            spacing: 8

                            // Previous Button
                            Item {
                                width: 28; height: 28
                                anchors.verticalCenter: parent.verticalCenter
                                Canvas {
                                    anchors.fill: parent; antialiasing: true
                                    onPaint: {
                                        var ctx = getContext("2d"); ctx.reset();
                                        ctx.fillStyle = root.colTextPrimary
                                        ctx.fillRect(6, 6, 3, 16)
                                        ctx.beginPath(); ctx.moveTo(22, 6); ctx.lineTo(11, 14); ctx.lineTo(22, 22); ctx.fill();
                                    }
                                }
                                MouseArea { anchors.fill: parent; onClicked: root.sendMediaCmd("previous") }
                            }

                            // Scalloped Play/Pause Button
                            Item {
                                width: 48; height: 48
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
                                        var ctx = getContext("2d"); ctx.reset();
                                        var cx = width / 2; var cy = height / 2;
                                        
                                        // Draw the Material 3 Star/Scallop Shape
                                        var points = 12; var rOuter = 24; var rInner = 20;
                                        ctx.beginPath()
                                        for (var i = 0; i < points * 2; i++) {
                                            var angle = (i * Math.PI) / points
                                            var r = (i % 2 === 0) ? rOuter : rInner
                                            if (i === 0) ctx.moveTo(cx + r * Math.cos(angle), cy + r * Math.sin(angle))
                                            else ctx.lineTo(cx + r * Math.cos(angle), cy + r * Math.sin(angle))
                                        }
                                        ctx.closePath();
                                        ctx.fillStyle = root.colAccent
                                        ctx.fill();

                                        // Draw Play/Pause Icon inside
                                        ctx.fillStyle = root.colOnAccent
                                        if (root.status === "Playing") {
                                            ctx.fillRect(cx - 6, cy - 8, 4, 16)
                                            ctx.fillRect(cx + 2, cy - 8, 4, 16)
                                        } else {
                                            ctx.beginPath(); ctx.moveTo(cx - 4, cy - 9); ctx.lineTo(cx + 8, cy); ctx.lineTo(cx - 4, cy + 9); ctx.fill();
                                        }
                                    }
                                }
                                MouseArea { anchors.fill: parent; onClicked: root.sendMediaCmd("play-pause") }
                            }

                            // Next Button
                            Item {
                                width: 28; height: 28
                                anchors.verticalCenter: parent.verticalCenter
                                Canvas {
                                    anchors.fill: parent; antialiasing: true
                                    onPaint: {
                                        var ctx = getContext("2d"); ctx.reset();
                                        ctx.fillStyle = root.colTextPrimary
                                        ctx.beginPath(); ctx.moveTo(6, 6); ctx.lineTo(17, 14); ctx.lineTo(6, 22); ctx.fill();
                                        ctx.fillRect(19, 6, 3, 16)
                                    }
                                }
                                MouseArea { anchors.fill: parent; onClicked: root.sendMediaCmd("next") }
                            }
                        }
                    }
                }

                // ─── BOTTOM AREA (Lyrics Display Simulation) ───
                // Matches the text layout seen in your screenshot
                Rectangle {
                    width: parent.width
                    height: 250
                    color: "transparent"

                    Column {
                        anchors.centerIn: parent
                        spacing: 12
                        width: parent.width * 0.9

                        Text {
                            text: "Would you remind me of the choices I've given?"
                            color: root.colTextSecondary
                            opacity: 0.3
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width
                            wrapMode: Text.WordWrap
                        }
                        
                        Text {
                            text: "I just want to feel your touch but I'm alive"
                            color: root.colTextSecondary
                            opacity: 0.6
                            font.pixelSize: 15
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            text: "If fading is a chance to bring a new dawn"
                            color: root.colTextPrimary
                            font.pixelSize: 17
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            text: "Erasing all the haste to grieve in my flaws"
                            color: root.colTextSecondary
                            opacity: 0.6
                            font.pixelSize: 15
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width
                            wrapMode: Text.WordWrap
                        }
                        
                        Text {
                            text: "Are this drops I am sweating just for the nothing"
                            color: root.colTextSecondary
                            opacity: 0.3
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }
    }
}
