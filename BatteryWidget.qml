import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property real screenWidth: 1920
    property real screenHeight: 1080

    // Position & sizing properties
    property real posX: 400
    property real posY: 40
    property real scaleFactor: 0.9

    x: Math.max(10, Math.min(root.screenWidth - root.width - 10, posX))
    y: Math.max(10, Math.min(root.screenHeight - root.height - 10, posY))
    width: Math.round(180 * scaleFactor)
    height: Math.round(120 * scaleFactor)

    // Battery properties
    property int batteryLevel: 85
    property bool isCharging: false
    property string statusText: "Discharging"

    // ─── Settings Persistence ───
    Process {
        id: loadSettingsProc
        command: ["sh", "-c", "cat ~/.config/quickshell/widget_settings.json 2>/dev/null || echo '{}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text)
                    if (data.battery) {
                        if (data.battery.scale !== undefined) root.scaleFactor = Math.max(0.5, Math.min(2.5, data.battery.scale))
                        var w = Math.round(180 * root.scaleFactor)
                        var h = Math.round(120 * root.scaleFactor)
                        if (data.battery.x !== undefined) root.posX = Math.max(10, Math.min(root.screenWidth - w - 10, data.battery.x))
                        if (data.battery.y !== undefined) root.posY = Math.max(10, Math.min(root.screenHeight - h - 10, data.battery.y))
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
        var script = "python3 -c 'import json, os; p=os.path.expanduser(\"~/.config/quickshell/widget_settings.json\"); d=json.load(open(p)) if os.path.exists(p) else {}; d[\"battery\"]={\"x\":" + Math.round(root.x) + ",\"y\":" + Math.round(root.y) + ",\"scale\":" + root.scaleFactor.toFixed(2) + "}; open(p,\"w\").write(json.dumps(d,indent=2))'"
        saveSettingsProc.command = ["sh", "-c", script]
        saveSettingsProc.running = true
    }

    // ─── Query Linux System Battery Status ───
    Process {
        id: batProc
        command: ["sh", "-c", "cap=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1); stat=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1); echo \"${cap:-85};;${stat:-Discharging}\""]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var line = text.trim()
                if (line.length > 0 && line.includes(";;")) {
                    var parts = line.split(";;")
                    var cap = parseInt(parts[0])
                    if (!isNaN(cap)) root.batteryLevel = Math.min(100, Math.max(0, cap))
                    var st = parts[1] || "Discharging"
                    root.statusText = st
                    root.isCharging = (st === "Charging" || st === "Full")
                }
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            batProc.running = true
        }
    }

    Component.onCompleted: {
        loadSettingsProc.running = true
        batProc.running = true
    }

    // ─── Theme Palette ───
    readonly property color colBgTile: Theme.colBgTile
    readonly property color colBadgeBg: Theme.colPillBg
    readonly property color colAccent: Theme.colAccent
    readonly property color colTextPrimary: Theme.colTextPrimary
    readonly property color colTextSecondary: Theme.colTextSecondary

    // ─── Scaled Visual Content ───
    Item {
        id: scaledContent
        width: 180
        height: 120
        scale: root.scaleFactor
        transformOrigin: Item.TopLeft

        Rectangle {
            anchors.fill: parent
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
                anchors.margins: 16

                // Top Bar: Vector Icon Badge + Charging Label
                Row {
                    anchors.top: parent.top
                    width: parent.width

                    // Pill Badge with Canvas Vector Battery/Bolt Icon (Zero Emojis)
                    Rectangle {
                        height: 28
                        width: 42
                        radius: 14
                        color: root.isCharging ? root.colAccent : root.colBadgeBg
                        antialiasing: true

                        Canvas {
                            id: iconCanvas
                            anchors.fill: parent
                            antialiasing: true

                            Connections {
                                target: root
                                function onIsChargingChanged() { iconCanvas.requestPaint() }
                                function onBatteryLevelChanged() { iconCanvas.requestPaint() }
                            }

                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.reset()
                                var cx = width / 2
                                var cy = height / 2

                                if (root.isCharging) {
                                    // Material Lightning Bolt Vector
                                    ctx.beginPath()
                                    ctx.moveTo(cx + 1, cy - 8)
                                    ctx.lineTo(cx - 6, cy + 1)
                                    ctx.lineTo(cx - 1, cy + 1)
                                    ctx.lineTo(cx - 2, cy + 8)
                                    ctx.lineTo(cx + 5, cy - 1)
                                    ctx.lineTo(cx, cy - 1)
                                    ctx.closePath()
                                    ctx.fillStyle = "#1E2A30"
                                    ctx.fill()
                                } else {
                                    // Material Battery Outline Vector
                                    ctx.strokeStyle = "#FFFFFF"
                                    ctx.lineWidth = 1.8
                                    ctx.beginPath()
                                    ctx.rect(cx - 8, cy - 5, 14, 10)
                                    ctx.stroke()

                                    ctx.fillStyle = "#FFFFFF"
                                    ctx.fillRect(cx + 6, cy - 2, 2, 4)

                                    // Inner fill bar
                                    var fillW = Math.max(1, Math.round(10 * (root.batteryLevel / 100.0)))
                                    ctx.fillRect(cx - 6, cy - 3, fillW, 6)
                                }
                            }
                        }
                    }

                    Item {
                        width: Math.max(0, parent.width - 42 - statusLabel.width)
                        height: 1
                    }

                    Text {
                        id: statusLabel
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.isCharging ? "Charging" : "Battery"
                        color: root.colTextSecondary
                        font.pixelSize: 11
                        font.bold: true
                        font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                    }
                }

                // Middle Big Battery Level % Display
                Text {
                    anchors.bottom: batBar.top
                    anchors.bottomMargin: 8
                    anchors.left: parent.left
                    text: root.batteryLevel + "%"
                    color: root.colTextPrimary
                    font.pixelSize: 28
                    font.bold: true
                    font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                }

                // Bottom Material Progress Bar
                Rectangle {
                    id: batBar
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 8
                    radius: 4
                    color: root.colBadgeBg
                    antialiasing: true

                    Rectangle {
                        width: Math.max(parent.radius * 2, parent.width * (root.batteryLevel / 100.0))
                        height: parent.height
                        radius: parent.radius
                        color: root.batteryLevel <= 20 ? "#FFB4AB" : (root.isCharging ? root.colAccent : "#A2C9C2")
                        antialiasing: true
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
