import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property real screenWidth: 1920
    property real screenHeight: 1080

    // Position & sizing properties
    property real posX: 790
    property real posY: 980
    property real scaleFactor: 0.95

    x: Math.max(10, Math.min(root.screenWidth - root.width - 10, posX))
    y: Math.max(10, Math.min(root.screenHeight - root.height - 10, posY))
    width: Math.round(350 * scaleFactor)
    height: Math.round(72 * scaleFactor)

    // Pinned Apps List
    property var appsList: [
        { name: "Terminal", cmd: "x-terminal-emulator || ghostty || kitty || alacritty || konsole || xterm", icon: "term", color: "#C2E7FF" },
        { name: "Browser", cmd: "brave || firefox || chromium || google-chrome || xdg-open https://google.com", icon: "web", color: "#FFE082" },
        { name: "Files", cmd: "xdg-open ~ || nautilus || dolphin || thunar", icon: "folder", color: "#A2C9C2" },
        { name: "Code", cmd: "code || vscodium || zed || kate || nvim", icon: "code", color: "#D7AEFB" },
        { name: "Launcher", cmd: "fuzzel || rofi -show drun || wofi --show drun", icon: "grid", color: "#FFB4AB" }
    ]

    // ─── Settings Persistence ───
    Process {
        id: loadSettingsProc
        command: ["sh", "-c", "cat ~/.config/quickshell/widget_settings.json 2>/dev/null || echo '{}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text)
                    if (data.dock) {
                        if (data.dock.scale !== undefined) root.scaleFactor = Math.max(0.5, Math.min(2.5, data.dock.scale))
                        var w = Math.round(350 * root.scaleFactor)
                        var h = Math.round(72 * root.scaleFactor)
                        if (data.dock.x !== undefined) root.posX = Math.max(10, Math.min(root.screenWidth - w - 10, data.dock.x))
                        if (data.dock.y !== undefined) root.posY = Math.max(10, Math.min(root.screenHeight - h - 10, data.dock.y))
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
        var script = "python3 -c 'import json, os; p=os.path.expanduser(\"~/.config/quickshell/widget_settings.json\"); d=json.load(open(p)) if os.path.exists(p) else {}; d[\"dock\"]={\"x\":" + Math.round(root.x) + ",\"y\":" + Math.round(root.y) + ",\"scale\":" + root.scaleFactor.toFixed(2) + "}; open(p,\"w\").write(json.dumps(d,indent=2))'"
        saveSettingsProc.command = ["sh", "-c", script]
        saveSettingsProc.running = true
    }

    Process {
        id: launchProc
        running: false
    }

    function launchApp(cmd) {
        launchProc.command = ["sh", "-c", cmd + " &"]
        launchProc.running = true
    }

    Component.onCompleted: {
        loadSettingsProc.running = true
    }

    // Material 3 Palette
    readonly property color colBg: "#232D33"
    readonly property color colItemHover: "#35424A"

    // ─── Scaled Visual Content ───
    Item {
        id: scaledContent
        width: 350
        height: 72
        scale: root.scaleFactor
        transformOrigin: Item.TopLeft

        // Drag MouseArea on Pill Background
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

        // Floating M3 Pill Dock Container
        Rectangle {
            anchors.fill: parent
            color: root.colBg
            radius: 36
            border.color: "#24FFFFFF"
            border.width: 1.5
            antialiasing: true

            Row {
                anchors.centerIn: parent
                spacing: 12

                Repeater {
                    model: root.appsList

                    Rectangle {
                        width: 52
                        height: 52
                        radius: 26
                        color: appBtnArea.containsMouse ? root.colItemHover : "transparent"
                        scale: appBtnArea.pressed ? 0.92 : (appBtnArea.containsMouse ? 1.08 : 1.0)
                        antialiasing: true

                        Behavior on scale {
                            NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
                        }

                        // App Vector Icon Canvas
                        Canvas {
                            anchors.fill: parent
                            antialiasing: true
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.reset()
                                var cx = width / 2
                                var cy = height / 2
                                var iconType = modelData.icon

                                if (iconType === "term") {
                                    ctx.fillStyle = modelData.color
                                    ctx.fillRect(cx - 15, cy - 12, 30, 24)

                                    ctx.strokeStyle = "#1E2A30"
                                    ctx.lineWidth = 2
                                    ctx.lineCap = "round"
                                    ctx.beginPath()
                                    ctx.moveTo(cx - 8, cy - 4)
                                    ctx.lineTo(cx - 4, cy)
                                    ctx.lineTo(cx - 8, cy + 4)
                                    ctx.moveTo(cx - 1, cy + 4)
                                    ctx.lineTo(cx + 7, cy + 4)
                                    ctx.stroke()
                                } else if (iconType === "web") {
                                    ctx.fillStyle = modelData.color
                                    ctx.beginPath()
                                    ctx.arc(cx, cy, 14, 0, Math.PI * 2)
                                    ctx.fill()

                                    ctx.strokeStyle = "#1E2A30"
                                    ctx.lineWidth = 1.8
                                    ctx.beginPath()
                                    ctx.arc(cx, cy, 10, 0, Math.PI * 2)
                                    ctx.moveTo(cx - 10, cy)
                                    ctx.lineTo(cx + 10, cy)
                                    ctx.moveTo(cx, cy - 10)
                                    ctx.lineTo(cx, cy + 10)
                                    ctx.stroke()
                                } else if (iconType === "folder") {
                                    ctx.fillStyle = modelData.color
                                    ctx.fillRect(cx - 14, cy - 10, 28, 20)

                                    ctx.fillStyle = "#1E2A30"
                                    ctx.fillRect(cx - 14, cy - 12, 12, 5)
                                } else if (iconType === "code") {
                                    ctx.fillStyle = modelData.color
                                    ctx.fillRect(cx - 15, cy - 12, 30, 24)

                                    ctx.strokeStyle = "#1E2A30"
                                    ctx.lineWidth = 2
                                    ctx.lineCap = "round"
                                    ctx.beginPath()
                                    ctx.moveTo(cx - 4, cy - 5)
                                    ctx.lineTo(cx - 9, cy)
                                    ctx.lineTo(cx - 4, cy + 5)

                                    ctx.moveTo(cx + 4, cy - 5)
                                    ctx.lineTo(cx + 9, cy)
                                    ctx.lineTo(cx + 4, cy + 5)
                                    ctx.stroke()
                                } else if (iconType === "grid") {
                                    ctx.fillStyle = modelData.color
                                    ctx.beginPath()
                                    ctx.arc(cx, cy, 14, 0, Math.PI * 2)
                                    ctx.fill()

                                    ctx.fillStyle = "#1E2A30"
                                    for (var r = -1; r <= 1; r++) {
                                        for (var c = -1; c <= 1; c++) {
                                            ctx.beginPath()
                                            ctx.arc(cx + c * 5.5, cy + r * 5.5, 1.8, 0, Math.PI * 2)
                                            ctx.fill()
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: appBtnArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.launchApp(modelData.cmd)
                        }
                    }
                }
            }
        }
    }
}
