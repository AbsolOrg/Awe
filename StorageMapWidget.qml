import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property real screenWidth: 1920
    property real screenHeight: 1080

    // Position & sizing properties
    property real posX: 400
    property real posY: 900
    property real scaleFactor: 0.88

    x: Math.max(10, Math.min(root.screenWidth - root.width - 10, posX))
    y: Math.max(10, Math.min(root.screenHeight - root.height - 10, posY))
    width: Math.round(270 * scaleFactor)
    height: Math.round(150 * scaleFactor)

    // Storage metrics
    property string totalSize: "448 GB"
    property string usedSize: "32 GB"
    property string freeSize: "413 GB"
    property real usedPercent: 8.0

    // ─── Settings Persistence ───
    Process {
        id: loadSettingsProc
        command: ["sh", "-c", "cat ~/.config/quickshell/widget_settings.json 2>/dev/null || echo '{}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text)
                    if (data.storagemap) {
                        if (data.storagemap.scale !== undefined) root.scaleFactor = Math.max(0.5, Math.min(2.5, data.storagemap.scale))
                        var w = Math.round(270 * root.scaleFactor)
                        var h = Math.round(150 * root.scaleFactor)
                        if (data.storagemap.x !== undefined) root.posX = Math.max(10, Math.min(root.screenWidth - w - 10, data.storagemap.x))
                        if (data.storagemap.y !== undefined) root.posY = Math.max(10, Math.min(root.screenHeight - h - 10, data.storagemap.y))
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
        var script = "python3 -c 'import json, os; p=os.path.expanduser(\"~/.config/quickshell/widget_settings.json\"); d=json.load(open(p)) if os.path.exists(p) else {}; d[\"storagemap\"]={\"x\":" + Math.round(root.x) + ",\"y\":" + Math.round(root.y) + ",\"scale\":" + root.scaleFactor.toFixed(2) + "}; open(p,\"w\").write(json.dumps(d,indent=2))'"
        saveSettingsProc.command = ["sh", "-c", script]
        saveSettingsProc.running = true
    }

    // Disk space query process
    Process {
        id: diskProc
        command: ["sh", "-c", "df -h / | awk 'NR==2 {print $2\";;\"$3\";;\"$4\";;\"$5}' | tr -d '%'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var line = text.trim()
                if (line.includes(";;")) {
                    var parts = line.split(";;")
                    root.totalSize = parts[0] || "448G"
                    root.usedSize = parts[1] || "32G"
                    root.freeSize = parts[2] || "413G"
                    root.usedPercent = Math.min(100, Math.max(1, parseFloat(parts[3]) || 8))
                }
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: diskProc.running = true
    }

    Component.onCompleted: {
        loadSettingsProc.running = true
    }

    // Theme Palette
    readonly property color colBg: Theme.colBg
    readonly property color colPillBg: Theme.colPillBg
    readonly property color colAccent: Theme.colAccent
    readonly property color colAccentGreen: Theme.colAccentGreen
    readonly property color colAccentAmber: Theme.colAccentWarning
    readonly property color colTextPrimary: Theme.colTextPrimary
    readonly property color colTextSecondary: Theme.colTextSecondary

    // ─── Scaled Visual Content ───
    Item {
        id: scaledContent
        width: 270
        height: 150
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

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8

                // Header Row: STORAGE Badge + Percent
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
                                color: root.colAccentAmber
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "STORAGE MAP"
                                color: "#FFFFFF"
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 0.6
                                font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                            }
                        }
                    }

                    Item {
                        width: Math.max(0, parent.width - parent.children[0].width - pctTag.width)
                        height: 1
                    }

                    Rectangle {
                        id: pctTag
                        height: 22
                        width: pctText.implicitWidth + 14
                        radius: 11
                        color: root.colPillBg
                        antialiasing: true

                        Text {
                            id: pctText
                            anchors.centerIn: parent
                            text: Math.round(root.usedPercent) + "% Used"
                            color: root.colAccentAmber
                            font.pixelSize: 9
                            font.bold: true
                            font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                        }
                    }
                }

                // Middle: Segmented Visual Bar
                Column {
                    width: parent.width
                    spacing: 6

                    // Segmented Progress Bar
                    Rectangle {
                        width: parent.width
                        height: 18
                        radius: 9
                        color: root.colPillBg
                        clip: true
                        antialiasing: true

                        // Used Space Fill
                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: Math.max(10, parent.width * (root.usedPercent / 100.0))
                            radius: 9
                            color: root.colAccentAmber
                            antialiasing: true
                        }
                    }

                    // Numeric Metrics Breakdown
                    Row {
                        width: parent.width

                        Text {
                            text: "Used: " + root.usedSize
                            color: root.colAccentAmber
                            font.pixelSize: 10
                            font.bold: true
                            font.family: "Google Sans Flex, Google Sans, Inter, monospace"
                        }

                        Item {
                            width: Math.max(0, parent.width - 90 - 90)
                            height: 1
                        }

                        Text {
                            text: "Free: " + root.freeSize
                            color: root.colAccentGreen
                            font.pixelSize: 10
                            font.bold: true
                            font.family: "Google Sans Flex, Google Sans, Inter, monospace"
                        }
                    }
                }

                // Bottom Partition Label
                Row {
                    width: parent.width
                    spacing: 6

                    Rectangle {
                        height: 20
                        width: (parent.width - 6) / 2
                        radius: 10
                        color: root.colPillBg
                        antialiasing: true

                        Row {
                            anchors.centerIn: parent
                            spacing: 5
                            Text { text: "Root (/):"; color: root.colTextSecondary; font.pixelSize: 9; font.family: "Google Sans Flex, Google Sans, Inter, sans-serif" }
                            Text { text: root.totalSize; color: "#FFFFFF"; font.pixelSize: 9; font.bold: true; font.family: "Google Sans Flex, Google Sans, Inter, monospace" }
                        }
                    }

                    Rectangle {
                        height: 20
                        width: (parent.width - 6) / 2
                        radius: 10
                        color: root.colPillBg
                        antialiasing: true

                        Row {
                            anchors.centerIn: parent
                            spacing: 5
                            Text { text: "Status:"; color: root.colTextSecondary; font.pixelSize: 9; font.family: "Google Sans Flex, Google Sans, Inter, sans-serif" }
                            Text { text: "Optimal"; color: root.colAccentGreen; font.pixelSize: 9; font.bold: true; font.family: "Google Sans Flex, Google Sans, Inter, sans-serif" }
                        }
                    }
                }
            }
        }
    }
}
