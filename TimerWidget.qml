import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property real screenWidth: 1920
    property real screenHeight: 1080

    // Position & sizing properties
    property real posX: 640
    property real posY: 160
    property real scaleFactor: 0.88

    x: Math.max(10, Math.min(root.screenWidth - root.width - 10, posX))
    y: Math.max(10, Math.min(root.screenHeight - root.height - 10, posY))
    width: Math.round(240 * scaleFactor)
    height: Math.round(230 * scaleFactor)

    // Timer State
    property string timerMode: "focus" // "focus" (25m), "break" (5m), "custom", "stopwatch"
    property int totalSec: 1500
    property int remainingSec: 1500
    property bool isRunning: false

    function getFormattedTime() {
        var m = Math.floor(root.remainingSec / 60)
        var s = Math.floor(root.remainingSec % 60)
        return (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s)
    }

    function setMode(mode) {
        root.timerMode = mode
        root.isRunning = false
        if (mode === "focus") {
            root.totalSec = 1500
            root.remainingSec = 1500
        } else if (mode === "break") {
            root.totalSec = 300
            root.remainingSec = 300
        } else if (mode === "custom") {
            if (root.totalSec < 60) root.totalSec = 600
            root.remainingSec = root.totalSec
        } else if (mode === "stopwatch") {
            root.totalSec = 3600
            root.remainingSec = 0
        }
        ringCanvas.requestPaint()
        root.saveSettings()
    }

    function adjustTime(deltaSec) {
        if (root.timerMode === "stopwatch") return
        var newSec = Math.max(60, Math.min(7200, (root.isRunning ? root.remainingSec : root.totalSec) + deltaSec))
        if (!root.isRunning) {
            root.totalSec = newSec
            root.remainingSec = newSec
            if (root.timerMode !== "focus" && root.timerMode !== "break") {
                root.timerMode = "custom"
            }
        } else {
            root.remainingSec = newSec
            if (newSec > root.totalSec) root.totalSec = newSec
        }
        ringCanvas.requestPaint()
        root.saveSettings()
    }

    // ─── Settings Persistence ───
    Process {
        id: loadSettingsProc
        command: ["sh", "-c", "cat ~/.config/quickshell/widget_settings.json 2>/dev/null || echo '{}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text)
                    if (data.timer) {
                        if (data.timer.scale !== undefined) root.scaleFactor = Math.max(0.5, Math.min(2.5, data.timer.scale))
                        var w = Math.round(240 * root.scaleFactor)
                        var h = Math.round(230 * root.scaleFactor)
                        if (data.timer.x !== undefined) root.posX = Math.max(10, Math.min(root.screenWidth - w - 10, data.timer.x))
                        if (data.timer.y !== undefined) root.posY = Math.max(10, Math.min(root.screenHeight - h - 10, data.timer.y))
                        if (data.timer.mode !== undefined) root.timerMode = data.timer.mode
                        if (data.timer.totalSec !== undefined) {
                            root.totalSec = data.timer.totalSec
                            root.remainingSec = data.timer.totalSec
                        }
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
        var script = "python3 -c 'import json, os; p=os.path.expanduser(\"~/.config/quickshell/widget_settings.json\"); d=json.load(open(p)) if os.path.exists(p) else {}; d[\"timer\"]={\"x\":" + Math.round(root.x) + ",\"y\":" + Math.round(root.y) + ",\"scale\":" + root.scaleFactor.toFixed(2) + ",\"mode\":\"" + root.timerMode + "\",\"totalSec\":" + root.totalSec + "}; open(p,\"w\").write(json.dumps(d,indent=2))'"
        saveSettingsProc.command = ["sh", "-c", script]
        saveSettingsProc.running = true
    }

    Timer {
        interval: 1000
        running: root.isRunning
        repeat: true
        onTriggered: {
            if (root.timerMode === "stopwatch") {
                root.remainingSec++
            } else {
                if (root.remainingSec > 0) {
                    root.remainingSec--
                } else {
                    root.isRunning = false
                }
            }
            ringCanvas.requestPaint()
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
    readonly property color colAccentAmber: "#FFE082"
    readonly property color colTextPrimary: "#FFFFFF"
    readonly property color colTextSecondary: "#9CA8AC"

    // ─── Scaled Visual Content ───
    Item {
        id: scaledContent
        width: 240
        height: 230
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

                // Header Mode Pills (Focus / Break / Watch)
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 6

                    // Focus Pill (25m)
                    Rectangle {
                        height: 22
                        width: 60
                        radius: 11
                        color: root.timerMode === "focus" ? root.colAccent : root.colPillBg
                        antialiasing: true
                        Text {
                            anchors.centerIn: parent
                            text: "25m"
                            color: root.timerMode === "focus" ? "#1E2A30" : root.colTextSecondary
                            font.pixelSize: 10
                            font.bold: true
                            font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setMode("focus")
                        }
                    }

                    // Break Pill (5m)
                    Rectangle {
                        height: 22
                        width: 60
                        radius: 11
                        color: root.timerMode === "break" ? root.colAccentGreen : root.colPillBg
                        antialiasing: true
                        Text {
                            anchors.centerIn: parent
                            text: "5m"
                            color: root.timerMode === "break" ? "#1E2A30" : root.colTextSecondary
                            font.pixelSize: 10
                            font.bold: true
                            font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setMode("break")
                        }
                    }

                    // Stopwatch Pill
                    Rectangle {
                        height: 22
                        width: 60
                        radius: 11
                        color: root.timerMode === "stopwatch" ? root.colAccentAmber : root.colPillBg
                        antialiasing: true
                        Text {
                            anchors.centerIn: parent
                            text: "Watch"
                            color: root.timerMode === "stopwatch" ? "#1E2A30" : root.colTextSecondary
                            font.pixelSize: 10
                            font.bold: true
                            font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setMode("stopwatch")
                        }
                    }
                }

                // Middle: Circular Progress Ring with Interactive Time Adjustment Buttons
                Item {
                    width: parent.width
                    height: 116

                    // Circular Progress Canvas
                    Canvas {
                        id: ringCanvas
                        width: 116
                        height: 116
                        anchors.centerIn: parent
                        antialiasing: true

                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()
                            var cx = width / 2
                            var cy = height / 2
                            var r = 50

                            // Inactive Base Ring
                            ctx.strokeStyle = root.colPillBg
                            ctx.lineWidth = 6
                            ctx.beginPath()
                            ctx.arc(cx, cy, r, 0, Math.PI * 2)
                            ctx.stroke()

                            // Active Progress Arc
                            var ratio = (root.totalSec > 0) ? (root.remainingSec / root.totalSec) : 0
                            if (root.timerMode === "stopwatch") ratio = (root.remainingSec % 60) / 60.0

                            ctx.strokeStyle = (root.timerMode === "break") ? root.colAccentGreen : (root.timerMode === "stopwatch" ? root.colAccentAmber : root.colAccent)
                            ctx.lineWidth = 6
                            ctx.lineCap = "round"
                            ctx.beginPath()
                            ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + (ratio * Math.PI * 2), false)
                            ctx.stroke()
                        }
                    }

                    // Left Minus Button (-1m / -5m)
                    Rectangle {
                        anchors.left: parent.left
                        anchors.leftMargin: 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: 26
                        height: 26
                        radius: 13
                        color: minusArea.containsMouse ? "#33FFFFFF" : root.colPillBg
                        visible: root.timerMode !== "stopwatch"
                        antialiasing: true

                        Text {
                            anchors.centerIn: parent
                            text: "-1m"
                            color: "#FFFFFF"
                            font.pixelSize: 9
                            font.bold: true
                            font.family: "Google Sans Flex, Google Sans, Inter, monospace"
                        }

                        MouseArea {
                            id: minusArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.adjustTime(-60)
                        }
                    }

                    // Center Time Display
                    Column {
                        anchors.centerIn: parent
                        spacing: 0

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.getFormattedTime()
                            color: root.colTextPrimary
                            font.pixelSize: 21
                            font.bold: true
                            font.family: "Google Sans Flex, Google Sans, Inter, monospace"
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.isRunning ? "RUNNING" : (root.timerMode === "custom" ? "CUSTOM" : "PAUSED")
                            color: root.isRunning ? root.colAccent : root.colTextSecondary
                            font.pixelSize: 8
                            font.bold: true
                            font.letterSpacing: 0.6
                            font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                        }
                    }

                    // Right Plus Button (+1m / +5m)
                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: 26
                        height: 26
                        radius: 13
                        color: plusArea.containsMouse ? "#33FFFFFF" : root.colPillBg
                        visible: root.timerMode !== "stopwatch"
                        antialiasing: true

                        Text {
                            anchors.centerIn: parent
                            text: "+1m"
                            color: "#FFFFFF"
                            font.pixelSize: 9
                            font.bold: true
                            font.family: "Google Sans Flex, Google Sans, Inter, monospace"
                        }

                        MouseArea {
                            id: plusArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.adjustTime(60)
                        }
                    }
                }

                // Bottom Controls: Play/Pause + Reset + +5m Quick Pill
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8

                    // Play / Pause Button
                    Rectangle {
                        width: 68
                        height: 28
                        radius: 14
                        color: root.isRunning ? "#FFB4AB" : root.colAccent
                        antialiasing: true

                        Text {
                            anchors.centerIn: parent
                            text: root.isRunning ? "Pause" : "Start"
                            color: "#1E2A30"
                            font.pixelSize: 11
                            font.bold: true
                            font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.isRunning = !root.isRunning
                                ringCanvas.requestPaint()
                            }
                        }
                    }

                    // Reset Button
                    Rectangle {
                        width: 58
                        height: 28
                        radius: 14
                        color: root.colPillBg
                        antialiasing: true

                        Text {
                            anchors.centerIn: parent
                            text: "Reset"
                            color: "#FFFFFF"
                            font.pixelSize: 11
                            font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setMode(root.timerMode)
                        }
                    }

                    // +5m Quick Adjustment Pill
                    Rectangle {
                        width: 44
                        height: 28
                        radius: 14
                        color: root.colPillBg
                        visible: root.timerMode !== "stopwatch"
                        antialiasing: true

                        Text {
                            anchors.centerIn: parent
                            text: "+5m"
                            color: root.colAccent
                            font.pixelSize: 10
                            font.bold: true
                            font.family: "Google Sans Flex, Google Sans, Inter, monospace"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.adjustTime(300)
                        }
                    }
                }
            }
        }
    }
}
