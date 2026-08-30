import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property real screenWidth: 1920
    property real screenHeight: 1080

    // Position & sizing properties
    property real posX: 400
    property real posY: 480
    property real scaleFactor: 0.85

    x: Math.max(10, Math.min(root.screenWidth - root.width - 10, posX))
    y: Math.max(10, Math.min(root.screenHeight - root.height - 10, posY))
    width: Math.round(360 * scaleFactor)
    height: Math.round(180 * scaleFactor)

    // ─── Settings Persistence ───
    Process {
        id: loadSettingsProc
        command: ["sh", "-c", "cat ~/.config/quickshell/widget_settings.json 2>/dev/null || echo '{}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text)
                    if (data.poster) {
                        if (data.poster.scale !== undefined) root.scaleFactor = Math.max(0.5, Math.min(2.5, data.poster.scale))
                        var w = Math.round(360 * root.scaleFactor)
                        var h = Math.round(180 * root.scaleFactor)
                        if (data.poster.x !== undefined) root.posX = Math.max(10, Math.min(root.screenWidth - w - 10, data.poster.x))
                        if (data.poster.y !== undefined) root.posY = Math.max(10, Math.min(root.screenHeight - h - 10, data.poster.y))
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
        var script = "python3 -c 'import json, os; p=os.path.expanduser(\"~/.config/quickshell/widget_settings.json\"); d=json.load(open(p)) if os.path.exists(p) else {}; d[\"poster\"]={\"x\":" + Math.round(root.x) + ",\"y\":" + Math.round(root.y) + ",\"scale\":" + root.scaleFactor.toFixed(2) + "}; open(p,\"w\").write(json.dumps(d,indent=2))'"
        saveSettingsProc.command = ["sh", "-c", script]
        saveSettingsProc.running = true
    }

    Component.onCompleted: {
        loadSettingsProc.running = true
    }

    // ─── Material Dark Slate Theme Palette ───
    readonly property color colBg: "#3A454B"              // Dark Slate Main Card
    readonly property color colBadgeBg: "#4D585F"         // Slate Pill Badge
    readonly property color colTextPrimary: "#FFFFFF"
    readonly property color colTextSecondary: "#B0BEC5"

    // ─── Quotes / Editorial Content ───
    property var quotes: [
        {
            title: "SUMMER MEMORIES",
            subtitle: "Warm sunlight, ocean breeze, and the quiet beauty of an endless horizon.",
            seal: "SPECIAL",
            footer: "PACIFIC DRIVE · 2026",
            date: "EST. CALIFORNIA"
        },
        {
            title: "CREATIVE FOCUS",
            subtitle: "Simplicity is the ultimate sophistication. Design with intention and clarity.",
            seal: "STUDIO",
            footer: "MATERIAL YOU · GOOGLE",
            date: "DAILY EDITION"
        },
        {
            title: "NIGHT HORIZONS",
            subtitle: "Under quiet stars and glowing screens, great ideas take flight.",
            seal: "ARCHIVE",
            footer: "QUICKSHELL LINUX",
            date: "VOL. 04"
        }
    ]
    property int currentQuoteIndex: 0

    // ─── Scaled Visual Content ───
    Item {
        id: scaledContent
        width: 360
        height: 180
        scale: root.scaleFactor
        transformOrigin: Item.TopLeft

        // ─── Material Editorial Poster Card ───
        Rectangle {
            anchors.fill: parent
            color: root.colBg
            radius: 32
            antialiasing: true

            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8

                // Top Bar: Seal Badge & Date Range
                Row {
                    width: parent.width

                    Rectangle {
                        height: 20
                        width: sealText.implicitWidth + 14
                        radius: 10
                        color: root.colBadgeBg
                        antialiasing: true

                        Text {
                            id: sealText
                            anchors.centerIn: parent
                            text: root.quotes[root.currentQuoteIndex].seal
                            color: root.colTextPrimary
                            font.pixelSize: 9
                            font.bold: true
                            font.letterSpacing: 1
                            font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                        }
                    }

                    Item {
                        width: Math.max(0, parent.width - (parent.children[0].width + dateLabel.width))
                        height: 1
                    }

                    Text {
                        id: dateLabel
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.quotes[root.currentQuoteIndex].date
                        color: root.colTextSecondary
                        font.pixelSize: 10
                        font.letterSpacing: 0.8
                        font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                    }
                }

                // Main English Title
                Text {
                    text: root.quotes[root.currentQuoteIndex].title
                    color: root.colTextPrimary
                    font.pixelSize: 17
                    font.bold: true
                    font.letterSpacing: 1.2
                    font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                }

                // Subtitle / English Quote
                Text {
                    text: root.quotes[root.currentQuoteIndex].subtitle
                    color: root.colTextSecondary
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                    width: parent.width
                    lineHeight: 1.25
                    font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                }

                // Subtle Accent Rule
                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#1AFFFFFF"
                }

                // Footer text
                Row {
                    width: parent.width
                    Text {
                        text: root.quotes[root.currentQuoteIndex].footer
                        color: root.colTextSecondary
                        font.pixelSize: 10
                        font.letterSpacing: 0.6
                        font.bold: true
                        font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                    }
                    Item {
                        width: Math.max(0, parent.width - parent.children[0].width - hintText.width)
                        height: 1
                    }
                    Text {
                        id: hintText
                        text: "Double-click to cycle"
                        color: "#60FFFFFF"
                        font.pixelSize: 9
                        font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                    }
                }
            }
        }
    }

    // ─── Interactive MouseArea ───
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

        onDoubleClicked: {
            root.currentQuoteIndex = (root.currentQuoteIndex + 1) % root.quotes.length
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
}
