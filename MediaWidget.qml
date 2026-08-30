import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property real screenWidth: 1920
    property real screenHeight: 1080

    // Position & sizing properties
    property real posX: 40
    property real posY: 430
    property real scaleFactor: 0.9

    x: Math.max(10, Math.min(root.screenWidth - root.width - 10, posX))
    y: Math.max(10, Math.min(root.screenHeight - root.height - 10, posY))
    width: Math.round(380 * scaleFactor)
    height: Math.round(160 * scaleFactor)

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
                        var h = Math.round(160 * root.scaleFactor)
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
    property string title: "No Media Playing"
    property string artist: "Tap play or launch a player"
    property string artUrl: ""
    property string status: "Stopped"
    property real positionSec: 0
    property real lengthSec: 0
    property string posStr: "0:00"
    property string lenStr: "0:00"
    property real progress: 0

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
                    root.title = "No Media Playing"
                    root.artist = "Android Pixel Media"
                    root.progress = 0
                    root.artUrl = ""
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

    // ─── Material Dark Slate Theme Palette ───
    readonly property color colBg: "#3A454B"              // Dark Slate Main Card
    readonly property color colBadgeBg: "#4D585F"         // Slate Pill Badge
    readonly property color colTextPrimary: "#FFFFFF"
    readonly property color colTextSecondary: "#B0BEC5"

    // ─── Scaled Visual Content ───
    Item {
        id: scaledContent
        width: 380
        height: 160
        scale: root.scaleFactor
        transformOrigin: Item.TopLeft

        Rectangle {
            anchors.fill: parent
            color: root.colBg
            radius: 32
            antialiasing: true

            Row {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16

                // Album Art / Disc Squircle
                Rectangle {
                    width: 116
                    height: 128
                    radius: 24
                    color: root.colBadgeBg
                    clip: true
                    antialiasing: true

                    Image {
                        anchors.fill: parent
                        source: root.artUrl
                        fillMode: Image.PreserveAspectCrop
                        visible: root.artUrl.length > 0 && status === Image.Ready
                        asynchronous: true
                    }

                    // Fallback Music Disc
                    Column {
                        anchors.centerIn: parent
                        visible: !root.artUrl || root.artUrl.length === 0
                        spacing: 6

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 48
                            height: 48
                            radius: 24
                            color: "#303B40"

                            Rectangle {
                                anchors.centerIn: parent
                                width: 16
                                height: 16
                                radius: 8
                                color: "#D1E8DA"
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "MUSIC"
                            color: root.colTextPrimary
                            font.pixelSize: 9
                            font.bold: true
                            font.letterSpacing: 1
                            font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                        }
                    }
                }

                // Controls & Details Column
                Column {
                    width: parent.width - 132
                    height: parent.height
                    spacing: 8

                    // Title & Artist
                    Column {
                        width: parent.width
                        spacing: 2

                        Text {
                            text: root.title
                            color: root.colTextPrimary
                            font.pixelSize: 14
                            font.bold: true
                            elide: Text.ElideRight
                            width: parent.width
                            font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                        }

                        Text {
                            text: root.artist
                            color: root.colTextSecondary
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            width: parent.width
                            font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                        }
                    }

                    // Progress Bar & Duration
                    Column {
                        width: parent.width
                        spacing: 4

                        Rectangle {
                            width: parent.width
                            height: 6
                            radius: 3
                            color: root.colBadgeBg
                            antialiasing: true

                            Rectangle {
                                width: Math.max(parent.radius * 2, parent.width * root.progress)
                                height: parent.height
                                radius: parent.radius
                                color: "#D1E8DA"
                                antialiasing: true
                            }
                        }

                        Row {
                            width: parent.width
                            Text {
                                text: root.posStr
                                color: root.colTextSecondary
                                font.pixelSize: 9
                                font.family: "Google Sans Flex, Google Sans, Inter, monospace"
                            }
                            Item {
                                width: parent.width - parent.children[0].width - parent.children[2].width
                                height: 1
                            }
                            Text {
                                text: root.lenStr
                                color: root.colTextSecondary
                                font.pixelSize: 9
                                font.family: "Google Sans Flex, Google Sans, Inter, monospace"
                            }
                        }
                    }

                    // Playback Buttons
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 16

                        // Prev Button
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 32
                            height: 32
                            radius: 16
                            color: root.colBadgeBg
                            antialiasing: true

                            Text {
                                anchors.centerIn: parent
                                text: "⏮"
                                color: root.colTextPrimary
                                font.pixelSize: 12
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    Quickshell.execDetached(["playerctl", "previous"])
                                    mediaProc.running = true
                                }
                            }
                        }

                        // Play/Pause Main Button
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 42
                            height: 42
                            radius: 21
                            color: "#D1E8DA"
                            antialiasing: true

                            Text {
                                anchors.centerIn: parent
                                text: root.status === "Playing" ? "⏸" : "▶"
                                color: "#253338"
                                font.pixelSize: 16
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

                        // Next Button
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 32
                            height: 32
                            radius: 16
                            color: root.colBadgeBg
                            antialiasing: true

                            Text {
                                anchors.centerIn: parent
                                text: "⏭"
                                color: root.colTextPrimary
                                font.pixelSize: 12
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
