import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property real screenWidth: 1920
    property real screenHeight: 1080

    // Position & sizing properties
    property real posX: 40
    property real posY: 170
    property real scaleFactor: 0.9

    x: Math.max(10, Math.min(root.screenWidth - root.width - 10, posX))
    y: Math.max(10, Math.min(root.screenHeight - root.height - 10, posY))
    width: Math.round(380 * scaleFactor)
    height: Math.round(245 * scaleFactor)

    // ─── Settings Persistence ───
    Process {
        id: loadSettingsProc
        command: ["sh", "-c", "cat ~/.config/quickshell/widget_settings.json 2>/dev/null || echo '{}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text)
                    if (data.calendar) {
                        if (data.calendar.scale !== undefined) root.scaleFactor = Math.max(0.5, Math.min(2.5, data.calendar.scale))
                        var w = Math.round(380 * root.scaleFactor)
                        var h = Math.round(245 * root.scaleFactor)
                        if (data.calendar.x !== undefined) root.posX = Math.max(10, Math.min(root.screenWidth - w - 10, data.calendar.x))
                        if (data.calendar.y !== undefined) root.posY = Math.max(10, Math.min(root.screenHeight - h - 10, data.calendar.y))
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
        var script = "python3 -c 'import json, os; p=os.path.expanduser(\"~/.config/quickshell/widget_settings.json\"); d=json.load(open(p)) if os.path.exists(p) else {}; d[\"calendar\"]={\"x\":" + Math.round(root.x) + ",\"y\":" + Math.round(root.y) + ",\"scale\":" + root.scaleFactor.toFixed(2) + "}; open(p,\"w\").write(json.dumps(d,indent=2))'"
        saveSettingsProc.command = ["sh", "-c", script]
        saveSettingsProc.running = true
    }

    Component.onCompleted: {
        loadSettingsProc.running = true
        root.updateCalendar()
    }

    // ─── Material Dark Slate Theme Palette ───
    readonly property color colBg: "#3A454B"              // Dark Slate Main Card
    readonly property color colBadgeBg: "#4D585F"         // Slate Pill Badge
    readonly property color colTextPrimary: "#FFFFFF"
    readonly property color colTextSecondary: "#B0BEC5"
    readonly property color colTextMuted: "#6B7880"
    readonly property color colTodayCircle: "#D1E8DA"      // Pastel Light Mint Today Highlight
    readonly property color colTodayText: "#253338"

    property var todayDate: new Date()
    property string monthName: ""
    property string yearString: ""
    property string fullDateFormatted: ""
    property var calendarModel: []

    function updateCalendar() {
        var now = new Date()
        root.todayDate = now
        var months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
        var daysOfWeek = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

        root.monthName = months[now.getMonth()]
        root.yearString = now.getFullYear().toString()
        root.fullDateFormatted = daysOfWeek[now.getDay()] + ", " + months[now.getMonth()].slice(0, 3) + " " + now.getDate()

        var year = now.getFullYear()
        var month = now.getMonth()
        var firstDay = new Date(year, month, 1).getDay()
        var daysInMonth = new Date(year, month + 1, 0).getDate()
        var daysInPrevMonth = new Date(year, month, 0).getDate()

        var list = []
        for (var i = firstDay - 1; i >= 0; i--) {
            list.push({
                day: (daysInPrevMonth - i).toString(),
                isCurrent: false,
                isToday: false
            })
        }

        var todayNum = now.getDate()
        for (var d = 1; d <= daysInMonth; d++) {
            list.push({
                day: d.toString(),
                isCurrent: true,
                isToday: (d === todayNum)
            })
        }

        var totalNeeded = list.length > 35 ? 42 : 35
        var nextCount = totalNeeded - list.length
        for (var n = 1; n <= nextCount; n++) {
            list.push({
                day: n.toString(),
                isCurrent: false,
                isToday: false
            })
        }

        root.calendarModel = list
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.updateCalendar()
    }

    // ─── Scaled Visual Content ───
    Item {
        id: scaledContent
        width: 380
        height: 245
        scale: root.scaleFactor
        transformOrigin: Item.TopLeft

        // ─── Material 3 Android Dark Slate Calendar Card ───
        Rectangle {
            anchors.fill: parent
            color: root.colBg
            radius: 32
            antialiasing: true

            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                Row {
                    width: parent.width

                    Column {
                        spacing: 2
                        Text {
                            text: (root.monthName + " " + root.yearString).toUpperCase()
                            color: root.colTextPrimary
                            font.pixelSize: 13
                            font.bold: true
                            font.letterSpacing: 1.0
                            font.family: "Google Sans Flex, Google Sans, Space Grotesk, Inter, sans-serif"
                        }
                        Text {
                            text: root.fullDateFormatted
                            color: root.colTextSecondary
                            font.pixelSize: 11
                            font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                        }
                    }

                    Item {
                        width: Math.max(0, parent.width - (parent.children[0].width + calendarBadge.width))
                        height: 1
                    }

                    Rectangle {
                        id: calendarBadge
                        height: 24
                        width: badgeRow.implicitWidth + 16
                        radius: 12
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
                                color: root.colTodayCircle
                                antialiasing: true
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "CALENDAR"
                                color: root.colTextPrimary
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 0.6
                                font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#1AFFFFFF"
                }

                Grid {
                    width: parent.width
                    columns: 7
                    spacing: 0

                    Repeater {
                        model: ["S", "M", "T", "W", "T", "F", "S"]
                        Item {
                            width: Math.floor(parent.width / 7)
                            height: 18

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: (index === 0 || index === 6) ? "#FFD8D0" : root.colTextSecondary
                                font.pixelSize: 11
                                font.bold: true
                                font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                            }
                        }
                    }
                }

                Grid {
                    width: parent.width
                    columns: 7
                    spacing: 0

                    Repeater {
                        model: root.calendarModel
                        Item {
                            width: Math.floor(parent.width / 7)
                            height: 24

                            Rectangle {
                                visible: modelData.isToday
                                anchors.centerIn: parent
                                width: 22
                                height: 22
                                radius: 11
                                color: root.colTodayCircle
                                antialiasing: true
                            }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.day
                                color: modelData.isToday ? root.colTodayText : (modelData.isCurrent ? root.colTextPrimary : root.colTextMuted)
                                font.pixelSize: 11
                                font.bold: modelData.isToday || modelData.isCurrent
                                font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                            }
                        }
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
