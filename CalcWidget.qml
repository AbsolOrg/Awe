import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property real screenWidth: 1920
    property real screenHeight: 1080

    // Position & sizing properties
    property real posX: 1400
    property real posY: 40
    property real scaleFactor: 0.88

    x: Math.max(10, Math.min(root.screenWidth - root.width - 10, posX))
    y: Math.max(10, Math.min(root.screenHeight - root.height - 10, posY))
    width: Math.round(250 * scaleFactor)
    height: Math.round(320 * scaleFactor)

    // Calculator State
    property string expr: ""
    property string result: "0"
    property string copyToast: ""

    function pushKey(key) {
        if (key === "C") {
            root.expr = ""
            root.result = "0"
        } else if (key === "⌫") {
            if (root.expr.length > 0) {
                root.expr = root.expr.slice(0, -1)
                evaluatePartial()
            }
        } else if (key === "=") {
            evaluateFinal()
        } else if (key === "±") {
            if (root.result !== "0" && root.result !== "Error") {
                if (root.result.startsWith("-")) {
                    root.result = root.result.slice(1)
                    root.expr = root.result
                } else {
                    root.result = "-" + root.result
                    root.expr = root.result
                }
            }
        } else if (key === "%") {
            try {
                var v = parseFloat(root.result) / 100.0
                root.result = v.toString()
                root.expr = root.result
            } catch (e) {}
        } else {
            root.expr += key
            evaluatePartial()
        }
    }

    function evaluatePartial() {
        try {
            var safe = root.expr.replace(/×/g, "*").replace(/÷/g, "/").replace(/−/g, "-")
            if (/^[0-9+\-*/().\s]+$/.test(safe) && !/[+\-*/.]$/.test(safe)) {
                var val = eval(safe)
                if (!isNaN(val) && isFinite(val)) {
                    root.result = (Math.round(val * 100000000) / 100000000).toString()
                }
            }
        } catch (e) {}
    }

    function evaluateFinal() {
        try {
            var safe = root.expr.replace(/×/g, "*").replace(/÷/g, "/").replace(/−/g, "-")
            if (/^[0-9+\-*/().\s]+$/.test(safe)) {
                var val = eval(safe)
                if (!isNaN(val) && isFinite(val)) {
                    var finalVal = (Math.round(val * 100000000) / 100000000).toString()
                    root.result = finalVal
                    root.expr = finalVal
                } else {
                    root.result = "Error"
                }
            }
        } catch (e) {
            root.result = "Error"
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
                        var w = Math.round(250 * root.scaleFactor)
                        var h = Math.round(320 * root.scaleFactor)
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

    // Process to copy result to clipboard
    Process {
        id: copyProc
        running: false
    }

    function copyResult() {
        copyProc.command = ["sh", "-c", "printf '%s' " + JSON.stringify(root.result) + " | wl-copy"]
        copyProc.running = true
        root.copyToast = "Copied!"
        toastTimer.restart()
    }

    Timer {
        id: toastTimer
        interval: 1400
        onTriggered: root.copyToast = ""
    }

    Component.onCompleted: {
        loadSettingsProc.running = true
    }

    // Material 3 Palette
    readonly property color colBg: "#232D33"
    readonly property color colDisplayBg: "#1C252B"
    readonly property color colPillBg: "#303B42"
    readonly property color colNumBg: "#2A363E"
    readonly property color colOpBg: "#36454F"
    readonly property color colAccent: "#C2E7FF"
    readonly property color colAccentGreen: "#A2C9C2"
    readonly property color colClearBg: "#3D2E32"
    readonly property color colClearText: "#FFB4AB"
    readonly property color colTextPrimary: "#FFFFFF"
    readonly property color colTextSecondary: "#9CA8AC"

    // ─── Scaled Visual Content ───
    Item {
        id: scaledContent
        width: 250
        height: 320
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

        // Main Material 3 Elevated Card
        Rectangle {
            anchors.fill: parent
            color: root.colBg
            radius: 32
            border.color: "#1FFFFFFF"
            border.width: 1.5
            antialiasing: true

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                // Header Row: CALCULATOR Pill Badge + Copy Toast
                Row {
                    width: parent.width

                    Rectangle {
                        height: 22
                        width: badgeRow.implicitWidth + 14
                        radius: 11
                        color: root.colPillBg
                        antialiasing: true

                        Row {
                            id: badgeRow
                            anchors.centerIn: parent
                            spacing: 5

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 6
                                height: 6
                                radius: 3
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

                    Item {
                        width: Math.max(0, parent.width - parent.children[0].width - toastLabel.width)
                        height: 1
                    }

                    Text {
                        id: toastLabel
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.copyToast
                        color: root.colAccentGreen
                        font.pixelSize: 9
                        font.bold: true
                        font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                    }
                }

                // Expression & Result Screen
                Rectangle {
                    width: parent.width
                    height: 58
                    radius: 18
                    color: root.colDisplayBg
                    border.color: "#1AFFFFFF"
                    border.width: 1
                    antialiasing: true

                    Column {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 1

                        // Expression
                        Text {
                            width: parent.width
                            text: root.expr.length > 0 ? root.expr : " "
                            color: root.colTextSecondary
                            font.pixelSize: 11
                            horizontalAlignment: Text.AlignRight
                            elide: Text.ElideLeft
                            font.family: "Google Sans Flex, Google Sans, Inter, monospace"
                        }

                        // Main Big Result
                        Text {
                            width: parent.width
                            text: root.result
                            color: "#FFFFFF"
                            font.pixelSize: (root.result.length > 10 ? 18 : 22)
                            font.bold: true
                            horizontalAlignment: Text.AlignRight
                            elide: Text.ElideLeft
                            font.family: "Google Sans Flex, Google Sans, Inter, monospace"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.copyResult()
                    }
                }

                // Material 3 Keypad Rows
                Column {
                    width: parent.width
                    spacing: 5

                    // Row 1: C, ⌫, %, ÷
                    Row {
                        spacing: 5
                        anchors.horizontalCenter: parent.horizontalCenter

                        CalcBtn { label: "C"; btnColor: root.colClearBg; labelColor: root.colClearText; onClicked: root.pushKey("C") }
                        CalcBtn { label: "⌫"; btnColor: root.colClearBg; labelColor: root.colClearText; onClicked: root.pushKey("⌫") }
                        CalcBtn { label: "%"; btnColor: root.colOpBg; labelColor: root.colAccent; onClicked: root.pushKey("%") }
                        CalcBtn { label: "÷"; btnColor: root.colOpBg; labelColor: root.colAccent; onClicked: root.pushKey("÷") }
                    }

                    // Row 2: 7, 8, 9, ×
                    Row {
                        spacing: 5
                        anchors.horizontalCenter: parent.horizontalCenter

                        CalcBtn { label: "7"; onClicked: root.pushKey("7") }
                        CalcBtn { label: "8"; onClicked: root.pushKey("8") }
                        CalcBtn { label: "9"; onClicked: root.pushKey("9") }
                        CalcBtn { label: "×"; btnColor: root.colOpBg; labelColor: root.colAccent; onClicked: root.pushKey("×") }
                    }

                    // Row 3: 4, 5, 6, −
                    Row {
                        spacing: 5
                        anchors.horizontalCenter: parent.horizontalCenter

                        CalcBtn { label: "4"; onClicked: root.pushKey("4") }
                        CalcBtn { label: "5"; onClicked: root.pushKey("5") }
                        CalcBtn { label: "6"; onClicked: root.pushKey("6") }
                        CalcBtn { label: "−"; btnColor: root.colOpBg; labelColor: root.colAccent; onClicked: root.pushKey("−") }
                    }

                    // Row 4: 1, 2, 3, +
                    Row {
                        spacing: 5
                        anchors.horizontalCenter: parent.horizontalCenter

                        CalcBtn { label: "1"; onClicked: root.pushKey("1") }
                        CalcBtn { label: "2"; onClicked: root.pushKey("2") }
                        CalcBtn { label: "3"; onClicked: root.pushKey("3") }
                        CalcBtn { label: "+"; btnColor: root.colOpBg; labelColor: root.colAccent; onClicked: root.pushKey("+") }
                    }

                    // Row 5: ±, 0, ., =
                    Row {
                        spacing: 5
                        anchors.horizontalCenter: parent.horizontalCenter

                        CalcBtn { label: "±"; btnColor: root.colNumBg; labelColor: root.colTextSecondary; onClicked: root.pushKey("±") }
                        CalcBtn { label: "0"; onClicked: root.pushKey("0") }
                        CalcBtn { label: "."; onClicked: root.pushKey(".") }
                        CalcBtn { label: "="; btnColor: root.colAccent; labelColor: "#1E2A30"; isBold: true; onClicked: root.pushKey("=") }
                    }
                }
            }
        }
    }

    // Material 3 Tonal Button Component
    component CalcBtn: Rectangle {
        property string label: ""
        property color btnColor: root.colNumBg
        property color labelColor: root.colTextPrimary
        property bool isBold: false
        signal clicked()

        width: 52
        height: 34
        radius: 17
        color: btnArea.pressed ? "#4A5A66" : (btnArea.containsMouse ? "#3A4A54" : btnColor)
        scale: btnArea.pressed ? 0.93 : (btnArea.containsMouse ? 1.04 : 1.0)
        antialiasing: true

        Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
        Behavior on color { ColorAnimation { duration: 90 } }

        Text {
            anchors.centerIn: parent
            text: label
            color: labelColor
            font.pixelSize: (label === "=" || label === "+" || label === "−" || label === "×" || label === "÷") ? 14 : 12
            font.bold: isBold || (label === "=")
            font.family: "Google Sans Flex, Google Sans, Inter, monospace"
        }

        MouseArea {
            id: btnArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }
}
