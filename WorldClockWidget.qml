import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property real screenWidth: 1920
    property real screenHeight: 1080

    // Position & sizing properties
    property real posX: 40
    property real posY: 800
    property real scaleFactor: 0.88

    x: Math.max(10, Math.min(root.screenWidth - root.width - 10, posX))
    y: Math.max(10, Math.min(root.screenHeight - root.height - 10, posY))
    width: Math.round(280 * scaleFactor)
    height: Math.round(155 * scaleFactor)

    // Cities List with timezone offsets in hours
    property var cities: [
        { name: "London", zone: "UTC", offset: 0, tag: "UTC+0" },
        { name: "New York", zone: "EDT", offset: -4, tag: "UTC-4" },
        { name: "Tokyo", zone: "JST", offset: 9, tag: "UTC+9" }
    ]

    property var currentTime: new Date()

    function getTimeForOffset(offsetHours) {
        var now = root.currentTime
        var utcMs = now.getTime() + (now.getTimezoneOffset() * 60000)
        var cityDate = new Date(utcMs + (offsetHours * 3600000))
        var h = cityDate.getHours()
        var m = cityDate.getMinutes()
        var h12 = h % 12 || 12
        var ampm = h >= 12 ? "PM" : "AM"
        var isNight = h < 6 || h >= 19
        return {
            timeStr: (h12 < 10 ? "0" + h12 : h12) + ":" + (m < 10 ? "0" + m : m),
            ampm: ampm,
            isNight: isNight
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
                    if (data.worldclock) {
                        if (data.worldclock.scale !== undefined) root.scaleFactor = Math.max(0.5, Math.min(2.5, data.worldclock.scale))
                        var w = Math.round(280 * root.scaleFactor)
                        var h = Math.round(155 * root.scaleFactor)
                        if (data.worldclock.x !== undefined) root.posX = Math.max(10, Math.min(root.screenWidth - w - 10, data.worldclock.x))
                        if (data.worldclock.y !== undefined) root.posY = Math.max(10, Math.min(root.screenHeight - h - 10, data.worldclock.y))
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
        var script = "python3 -c 'import json, os; p=os.path.expanduser(\"~/.config/quickshell/widget_settings.json\"); d=json.load(open(p)) if os.path.exists(p) else {}; d[\"worldclock\"]={\"x\":" + Math.round(root.x) + ",\"y\":" + Math.round(root.y) + ",\"scale\":" + root.scaleFactor.toFixed(2) + "}; open(p,\"w\").write(json.dumps(d,indent=2))'"
        saveSettingsProc.command = ["sh", "-c", script]
        saveSettingsProc.running = true
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.currentTime = new Date()
    }

    Component.onCompleted: {
        loadSettingsProc.running = true
    }

    // Material 3 Palette
    readonly property color colBg: "#232D33"
    readonly property color colBadgeBg: "#303B42"
    readonly property color colAccent: "#C2E7FF"
    readonly property color colAccentSun: "#FFE082"
    readonly property color colAccentMoon: "#D7AEFB"
    readonly property color colTextPrimary: "#FFFFFF"
    readonly property color colTextSecondary: "#9CA8AC"

    // ─── Scaled Visual Content ───
    Item {
        id: scaledContent
        width: 280
        height: 155
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

                // Header Row: WORLD CLOCK Pill Badge
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
                                text: "TIMEZONES"
                                color: root.colTextPrimary
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 0.6
                                font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                            }
                        }
                    }

                    Item {
                        width: Math.max(0, parent.width - parent.children[0].width - tagText.width)
                        height: 1
                    }

                    Text {
                        id: tagText
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Global Sync"
                        color: root.colTextSecondary
                        font.pixelSize: 10
                        font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                    }
                }

                // City Clocks List
                Column {
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: root.cities

                        Rectangle {
                            width: parent.width
                            height: 28
                            radius: 14
                            color: root.colBadgeBg
                            antialiasing: true

                            property var timeInfo: root.getTimeForOffset(modelData.offset)

                            Row {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 8

                                // Sun / Moon Indicator Dot
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 8
                                    height: 8
                                    radius: 4
                                    color: timeInfo.isNight ? root.colAccentMoon : root.colAccentSun
                                    antialiasing: true
                                }

                                // City Name
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.name
                                    color: root.colTextPrimary
                                    font.pixelSize: 11
                                    font.bold: true
                                    font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                                }

                                Item {
                                    width: Math.max(0, parent.width - 8 - 80 - timeRow.width)
                                    height: 1
                                }

                                // Time + AM/PM + Offset Tag
                                Row {
                                    id: timeRow
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 6

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: timeInfo.timeStr
                                        color: "#FFFFFF"
                                        font.pixelSize: 12
                                        font.bold: true
                                        font.family: "Google Sans Flex, Google Sans, Inter, monospace"
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: timeInfo.ampm
                                        color: root.colTextSecondary
                                        font.pixelSize: 9
                                        font.bold: true
                                        font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                                    }

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        height: 14
                                        width: offText.implicitWidth + 8
                                        radius: 7
                                        color: "#1FFFFFFF"
                                        antialiasing: true

                                        Text {
                                            id: offText
                                            anchors.centerIn: parent
                                            text: modelData.tag
                                            color: root.colTextSecondary
                                            font.pixelSize: 8
                                            font.bold: true
                                            font.family: "Google Sans Flex, Google Sans, Inter, monospace"
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
