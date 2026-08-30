import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property real screenWidth: 1920
    property real screenHeight: 1080

    // Position & sizing properties
    property real posX: 400
    property real posY: 460
    property real scaleFactor: 0.9

    x: Math.max(10, Math.min(root.screenWidth - root.width - 10, posX))
    y: Math.max(10, Math.min(root.screenHeight - root.height - 10, posY))
    width: Math.round(340 * scaleFactor)
    height: Math.round(140 * scaleFactor)

    // Quotes Database
    property var quotesList: [
        { text: "Simplicity is prerequisite for reliability.", author: "Edsger W. Dijkstra", tag: "Design" },
        { text: "Make it work, make it right, make it fast.", author: "Kent Beck", tag: "Craft" },
        { text: "Design is not just what it looks like and feels like. Design is how it works.", author: "Steve Jobs", tag: "Vision" },
        { text: "Programs must be written for people to read, and only incidentally for machines to execute.", author: "Harold Abelson", tag: "Clarity" },
        { text: "The details are not the details. They make the design.", author: "Charles Eames", tag: "Art" },
        { text: "Talk is cheap. Show me the code.", author: "Linus Torvalds", tag: "Linux" }
    ]
    property int currentQuoteIndex: 0

    // ─── Settings Persistence ───
    Process {
        id: loadSettingsProc
        command: ["sh", "-c", "cat ~/.config/quickshell/widget_settings.json 2>/dev/null || echo '{}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text)
                    if (data.quote) {
                        if (data.quote.scale !== undefined) root.scaleFactor = Math.max(0.5, Math.min(2.5, data.quote.scale))
                        if (data.quote.index !== undefined) root.currentQuoteIndex = data.quote.index % root.quotesList.length
                        var w = Math.round(340 * root.scaleFactor)
                        var h = Math.round(140 * root.scaleFactor)
                        if (data.quote.x !== undefined) root.posX = Math.max(10, Math.min(root.screenWidth - w - 10, data.quote.x))
                        if (data.quote.y !== undefined) root.posY = Math.max(10, Math.min(root.screenHeight - h - 10, data.quote.y))
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
        var script = "python3 -c 'import json, os; p=os.path.expanduser(\"~/.config/quickshell/widget_settings.json\"); d=json.load(open(p)) if os.path.exists(p) else {}; d[\"quote\"]={\"x\":" + Math.round(root.x) + ",\"y\":" + Math.round(root.y) + ",\"scale\":" + root.scaleFactor.toFixed(2) + ",\"index\":" + root.currentQuoteIndex + "}; open(p,\"w\").write(json.dumps(d,indent=2))'"
        saveSettingsProc.command = ["sh", "-c", script]
        saveSettingsProc.running = true
    }

    function nextQuote() {
        root.currentQuoteIndex = (root.currentQuoteIndex + 1) % root.quotesList.length
        root.saveSettings()
    }

    Component.onCompleted: {
        loadSettingsProc.running = true
    }

    // Material 3 Palette
    readonly property color colBg: "#232D33"
    readonly property color colBadgeBg: "#303B42"
    readonly property color colAccent: "#D7AEFB"
    readonly property color colTextPrimary: "#FFFFFF"
    readonly property color colTextSecondary: "#9CA8AC"

    property var activeQuote: root.quotesList[root.currentQuoteIndex] || root.quotesList[0]

    // ─── Scaled Visual Content ───
    Item {
        id: scaledContent
        width: 340
        height: 140
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

                // Header Row: INSPIRATION Badge + Tag + Refresh Button
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
                                color: root.colAccent
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "INSPIRATION"
                                color: root.colTextPrimary
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 0.6
                                font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                            }
                        }
                    }

                    Item {
                        width: Math.max(0, parent.width - parent.children[0].width - refreshBtn.width)
                        height: 1
                    }

                    // Refresh Button
                    Rectangle {
                        id: refreshBtn
                        width: 24
                        height: 24
                        radius: 12
                        color: refArea.containsMouse ? "#33FFFFFF" : root.colBadgeBg
                        antialiasing: true

                        Text {
                            anchors.centerIn: parent
                            text: "↻"
                            color: "#FFFFFF"
                            font.pixelSize: 14
                            font.bold: true
                        }

                        MouseArea {
                            id: refArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.nextQuote()
                        }
                    }
                }

                // Middle Quote Body Text
                Text {
                    width: parent.width
                    height: 52
                    text: "“" + root.activeQuote.text + "”"
                    color: root.colTextPrimary
                    font.pixelSize: 12
                    font.italic: true
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                    maximumLineCount: 3
                    lineHeight: 1.15
                    font.family: "Google Sans Flex, Google Sans, Inter, Georgia, serif"
                }

                // Bottom Author Tag Row
                Row {
                    width: parent.width
                    spacing: 6

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "— " + root.activeQuote.author
                        color: root.colAccent
                        font.pixelSize: 11
                        font.bold: true
                        font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                    }

                    Item {
                        width: Math.max(0, parent.width - parent.children[0].width - tagBadge.width)
                        height: 1
                    }

                    Rectangle {
                        id: tagBadge
                        height: 18
                        width: tagText.implicitWidth + 12
                        radius: 9
                        color: root.colBadgeBg
                        antialiasing: true

                        Text {
                            id: tagText
                            anchors.centerIn: parent
                            text: root.activeQuote.tag
                            color: root.colTextSecondary
                            font.pixelSize: 9
                            font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                        }
                    }
                }
            }
        }
    }
}
