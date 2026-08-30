import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property real screenWidth: 1920
    property real screenHeight: 1080

    // Position & sizing properties
    property real posX: 1120
    property real posY: 730
    property real scaleFactor: 0.88

    x: Math.max(10, Math.min(root.screenWidth - root.width - 10, posX))
    y: Math.max(10, Math.min(root.screenHeight - root.height - 10, posY))
    width: Math.round(240 * scaleFactor)
    height: Math.round(270 * scaleFactor)

    // Calculator State
    property string expr: ""
    property string result: "0"

    function pushKey(key) {
        if (key === "C") {
            root.expr = ""
            root.result = "0"
        } else if (key === "=") {
            try {
                var safeExpr = root.expr.replace(/×/g, "*").replace(/÷/g, "/")
                if (/^[0-9+\-*/().\s]+$/.test(safeExpr)) {
                    var val = eval(safeExpr)
                    root.result = val.toString()
                    root.expr = val.toString()
                }
            } catch (e) {
                root.result = "Error"
            }
        } else if (key === "⌫") {
            if (root.expr.length > 0) root.expr = root.expr.slice(0, -1)
        } else {
            root.expr += key
            try {
                var safeE = root.expr.replace(/×/g, "*").replace(/÷/g, "/")
                if (/^[0-9+\-*/().\s]+$/.test(safeE)) {
                    var v = eval(safeE)
                    if (!isNaN(v)) root.result = v.toString()
                }
            } catch (e) {}
        }
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
                    if (data.calc) {
                        if (data.calc.scale !== undefined) root.scaleFactor = Math.max(0.5, Math.min(2.5, data.calc.scale))
                        var w = Math.round(240 * root.scaleFactor)
                        var h = Math.round(270 * root.scaleFactor)
                        if (data.calc.x !== undefined) root.posX = Math.max(10, Math.min(root.screenWidth - w - 10, data.calc.x))
                        if (data.calc.y !== undefined) root.posY = Math.max(10, Math.min(root.screenHeight - h - 10, data.calc.y))
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
        var script = "python3 -c 'import json, os; p=os.path.expanduser(\"~/.config/quickshell/widget_settings.json\"); d=json.load(open(p)) if os.path.exists(p) else {}; d[\"calc\"]={\"x\":" + Math.round(root.x) + ",\"y\":" + Math.round(root.y) + ",\"scale\":" + root.scaleFactor.toFixed(2) + "}; open(p,\"w\").write(json.dumps(d,indent=2))'"
        saveSettingsProc.command = ["sh", "-c", script]
        saveSettingsProc.running = true
    }

    Component.onCompleted: {
        loadSettingsProc.running = true
    }

    // Material 3 Palette
    readonly property color colBg: "#232D33"
    readonly property color colPillBg: "#303B42"
    readonly property color colKeyBg: "#28343B"
    readonly property color colAccent: "#C2E7FF"
    readonly property color colAccentGreen: "#A2C9C2"
    readonly property color colAccentAmber: "#FFE082"
    readonly property color colTextPrimary: "#FFFFFF"
    readonly property color colTextSecondary: "#9CA8AC"

    // ─── Scaled Visual Content ───
    Item {
        id: scaledContent
        width: 240
        height: 270
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

                // Header Row: CALCULATOR Badge
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
                                color: root.colAccent
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "CALCULATOR"
                                color: "#FFFFFF"
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 0.6
                                font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                            }
                        }
                    }
                }

                // Display Screen
                Rectangle {
                    width: parent.width
                    height: 48
                    radius: 14
                    color: root.colPillBg
                    antialiasing: true

                    Column {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 1

                        Text {
                            width: parent.width
                            text: root.expr.length > 0 ? root.expr : "0"
                            color: root.colTextSecondary
                            font.pixelSize: 10
                            horizontalAlignment: Text.AlignRight
                            elide: Text.ElideLeft
                            font.family: "Google Sans Flex, Google Sans, Inter, monospace"
                        }

                        Text {
                            width: parent.width
                            text: root.result
                            color: "#FFFFFF"
                            font.pixelSize: 16
                            font.bold: true
                            horizontalAlignment: Text.AlignRight
                            elide: Text.ElideLeft
                            font.family: "Google Sans Flex, Google Sans, Inter, monospace"
                        }
                    }
                }

                // 4x4 Keypad Grid
                Grid {
                    width: parent.width
                    columns: 4
                    spacing: 6

                    Repeater {
                        model: [
                            "C", "⌫", "%", "/",
                            "7", "8", "9", "*",
                            "4", "5", "6", "-",
                            "1", "2", "3", "+",
                            "0", ".", "="
                        ]

                        Rectangle {
                            width: (modelData === "0") ? (48 * 2 + 6) : 48
                            height: 28
                            radius: 14
                            color: (modelData === "=") ? root.colAccent : ((modelData === "C" || modelData === "⌫") ? "#2B3C44" : (["+", "-", "*", "/", "%"].indexOf(modelData) >= 0 ? root.colPillBg : root.colKeyBg))
                            antialiasing: true

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: (modelData === "=") ? "#1E2A30" : ((modelData === "C" || modelData === "⌫") ? "#FFB4AB" : (["+", "-", "*", "/", "%"].indexOf(modelData) >= 0 ? root.colAccent : "#FFFFFF"))
                                font.pixelSize: 11
                                font.bold: true
                                font.family: "Google Sans Flex, Google Sans, Inter, monospace"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.pushKey(modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
