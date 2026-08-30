import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property real screenWidth: 1920
    property real screenHeight: 1080

    // Position & sizing properties
    property real posX: 40
    property real posY: 760
    property real scaleFactor: 0.88

    x: Math.max(10, Math.min(root.screenWidth - root.width - 10, posX))
    y: Math.max(10, Math.min(root.screenHeight - root.height - 10, posY))
    width: Math.round(280 * scaleFactor)
    height: Math.round(190 * scaleFactor)

    // Clipboard History List
    property var historyList: [
        "git push -u origin added",
        "https://github.com/AbsolOrg/Awe",
        "quickshell -p ~/.config/quickshell/Awe"
    ]
    property string lastCopied: ""
    property string copyToast: ""

    // ─── Settings Persistence ───
    Process {
        id: loadSettingsProc
        command: ["sh", "-c", "cat ~/.config/quickshell/widget_settings.json 2>/dev/null || echo '{}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text)
                    if (data.clipboard) {
                        if (data.clipboard.scale !== undefined) root.scaleFactor = Math.max(0.5, Math.min(2.5, data.clipboard.scale))
                        var w = Math.round(280 * root.scaleFactor)
                        var h = Math.round(190 * root.scaleFactor)
                        if (data.clipboard.x !== undefined) root.posX = Math.max(10, Math.min(root.screenWidth - w - 10, data.clipboard.x))
                        if (data.clipboard.y !== undefined) root.posY = Math.max(10, Math.min(root.screenHeight - h - 10, data.clipboard.y))
                        if (data.clipboard.list && Array.isArray(data.clipboard.list) && data.clipboard.list.length > 0) {
                            root.historyList = data.clipboard.list
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
        var jsonStr = JSON.stringify(root.historyList).replace(/'/g, "'\\''")
        var script = "python3 -c 'import json, os; p=os.path.expanduser(\"~/.config/quickshell/widget_settings.json\"); d=json.load(open(p)) if os.path.exists(p) else {}; d[\"clipboard\"]={\"x\":" + Math.round(root.x) + ",\"y\":" + Math.round(root.y) + ",\"scale\":" + root.scaleFactor.toFixed(2) + ",\"list\":" + jsonStr + "}; open(p,\"w\").write(json.dumps(d,indent=2))'"
        saveSettingsProc.command = ["sh", "-c", script]
        saveSettingsProc.running = true
    }

    // Process to check wl-paste for new clipboard item
    Process {
        id: pasteProc
        command: ["wl-paste", "-n"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var str = text.trim()
                if (str.length > 0 && str !== root.lastCopied && str.length < 500) {
                    root.lastCopied = str
                    var list = root.historyList.filter(item => item !== str)
                    list.unshift(str)
                    if (list.length > 8) list = list.slice(0, 8)
                    root.historyList = list
                    root.saveSettings()
                }
            }
        }
    }

    // Process to copy item back to clipboard
    Process {
        id: copyProc
        running: false
    }

    function copyToClipboard(str) {
        copyProc.command = ["sh", "-c", "printf '%s' " + JSON.stringify(str) + " | wl-copy"]
        copyProc.running = true
        root.copyToast = "Copied!"
        toastTimer.restart()
    }

    Timer {
        id: toastTimer
        interval: 1500
        onTriggered: root.copyToast = ""
    }

    Timer {
        interval: 2500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: pasteProc.running = true
    }

    Component.onCompleted: {
        loadSettingsProc.running = true
    }

    // Material 3 Palette
    readonly property color colBg: "#232D33"
    readonly property color colBadgeBg: "#303B42"
    readonly property color colAccent: "#C2E7FF"
    readonly property color colAccentGreen: "#A2C9C2"
    readonly property color colTextPrimary: "#FFFFFF"
    readonly property color colTextSecondary: "#9CA8AC"

    // ─── Scaled Visual Content ───
    Item {
        id: scaledContent
        width: 280
        height: 190
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

                // Header Row: CLIPBOARD Badge + Toast + Clear Button
                Row {
                    width: parent.width

                    Rectangle {
                        height: 22
                        width: badgeRow.implicitWidth + 16
                        radius: 11
                        color: root.colBadgeBg
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
                                color: root.colAccentGreen
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "CLIPBOARD"
                                color: root.colTextPrimary
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 0.6
                                font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                            }
                        }
                    }

                    Item {
                        width: Math.max(0, parent.width - parent.children[0].width - rightRow.width)
                        height: 1
                    }

                    Row {
                        id: rightRow
                        spacing: 8
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: root.copyToast.length > 0
                            text: root.copyToast
                            color: root.colAccentGreen
                            font.pixelSize: 10
                            font.bold: true
                            font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                        }

                        // Clear Button
                        Rectangle {
                            width: 20
                            height: 20
                            radius: 10
                            color: root.colBadgeBg
                            antialiasing: true

                            Text {
                                anchors.centerIn: parent
                                text: "×"
                                color: "#FFB4AB"
                                font.pixelSize: 14
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.historyList = []
                                    root.saveSettings()
                                }
                            }
                        }
                    }
                }

                // Clipboard History Items List
                ListView {
                    width: parent.width
                    height: 120
                    clip: true
                    spacing: 6
                    model: root.historyList

                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 32
                        radius: 16
                        color: itemArea.containsMouse ? "#3A4750" : root.colBadgeBg
                        antialiasing: true

                        Row {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            // Copy Vector Icon
                            Canvas {
                                width: 14
                                height: 14
                                anchors.verticalCenter: parent.verticalCenter
                                antialiasing: true
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.reset()
                                    ctx.strokeStyle = root.colAccent
                                    ctx.lineWidth = 1.3
                                    ctx.strokeRect(4, 1, 8, 8)
                                    ctx.fillStyle = root.colBadgeBg
                                    ctx.fillRect(1, 4, 8, 8)
                                    ctx.strokeRect(1, 4, 8, 8)
                                }
                            }

                            Text {
                                width: parent.width - 24
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData
                                color: root.colTextPrimary
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                font.family: "Google Sans Flex, Google Sans, Inter, monospace"
                            }
                        }

                        MouseArea {
                            id: itemArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.copyToClipboard(modelData)
                        }
                    }
                }
            }
        }
    }
}
