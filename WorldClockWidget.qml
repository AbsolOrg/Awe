import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property real screenWidth: 1920
    property real screenHeight: 1080

    // Position & sizing properties
    property real posX: 1120
    property real posY: 850
    property real scaleFactor: 0.88

    x: Math.max(10, Math.min(root.screenWidth - root.width - 10, posX))
    y: Math.max(10, Math.min(root.screenHeight - root.height - 10, posY))
    width: Math.round(290 * scaleFactor)
    height: Math.round((70 + Math.max(2, root.cities.length) * 34) * scaleFactor)

    // Themes Palette
    property int themeIndex: 0
    property var themes: [
        { name: "Slate Cyber", bg: "#232D33", pillBg: "#303B42", accent: "#C2E7FF", sun: "#FFE082", moon: "#D7AEFB" },
        { name: "Midnight OLED", bg: "#13171A", pillBg: "#1E252B", accent: "#D7AEFB", sun: "#FFE082", moon: "#A2C9C2" },
        { name: "Mocha Earth", bg: "#2B231E", pillBg: "#3A302A", accent: "#FFD8B4", sun: "#FFE082", moon: "#FFB4AB" },
        { name: "Forest Pine", bg: "#1B2920", pillBg: "#26382C", accent: "#CCFF90", sun: "#FFE082", moon: "#A2C9C2" },
        { name: "Royal Amethyst", bg: "#261D30", pillBg: "#352843", accent: "#E8DEF8", sun: "#FFE082", moon: "#FFD8E4" }
    ]
    property var currentTheme: root.themes[root.themeIndex % root.themes.length]

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
                        if (data.worldclock.themeIndex !== undefined) root.themeIndex = data.worldclock.themeIndex
                        var w = Math.round(290 * root.scaleFactor)
                        var h = Math.round((70 + Math.max(2, root.cities.length) * 34) * root.scaleFactor)
                        if (data.worldclock.x !== undefined) root.posX = Math.max(10, Math.min(root.screenWidth - w - 10, data.worldclock.x))
                        if (data.worldclock.y !== undefined) root.posY = Math.max(10, Math.min(root.screenHeight - h - 10, data.worldclock.y))
                        if (data.worldclock.cities && Array.isArray(data.worldclock.cities) && data.worldclock.cities.length > 0) {
                            root.cities = data.worldclock.cities
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
        var jsonCities = JSON.stringify(root.cities).replace(/'/g, "'\\''")
        var script = "python3 -c 'import json, os; p=os.path.expanduser(\"~/.config/quickshell/widget_settings.json\"); d=json.load(open(p)) if os.path.exists(p) else {}; d[\"worldclock\"]={\"x\":" + Math.round(root.x) + ",\"y\":" + Math.round(root.y) + ",\"scale\":" + root.scaleFactor.toFixed(2) + ",\"themeIndex\":" + root.themeIndex + ",\"cities\":" + jsonCities + "}; open(p,\"w\").write(json.dumps(d,indent=2))'"
        saveSettingsProc.command = ["sh", "-c", script]
        saveSettingsProc.running = true
    }

    // ─── GTK3 Custom Timezone Prompt ───
    Process {
        id: addTzProc
        command: ["python3", "-c", "import gi; gi.require_version('Gtk', '3.0'); from gi.repository import Gtk; dialog=Gtk.Dialog(title='Add Timezone / City', buttons=(Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL, Gtk.STOCK_OK, Gtk.ResponseType.OK)); vbox=dialog.get_content_area(); c_entry=Gtk.Entry(); c_entry.set_placeholder_text('City Name (e.g. Dubai, Paris, Mumbai)'); o_entry=Gtk.Entry(); o_entry.set_placeholder_text('UTC Offset in Hours (e.g. 4, -5, 5.5)'); vbox.pack_start(c_entry, False, False, 6); vbox.pack_start(o_entry, False, False, 6); dialog.show_all(); res=dialog.run(); city=c_entry.get_text().strip(); off=o_entry.get_text().strip(); dialog.destroy(); print((city + ';;' + off) if res==Gtk.ResponseType.OK else '')"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var line = text.trim()
                if (line.includes(";;")) {
                    var parts = line.split(";;")
                    var cityName = parts[0] || "City"
                    var offsetVal = parseFloat(parts[1]) || 0
                    var tag = "UTC" + (offsetVal >= 0 ? "+" : "") + offsetVal
                    var list = root.cities.slice()
                    list.push({ name: cityName, zone: "UTC", offset: offsetVal, tag: tag })
                    root.cities = list
                    root.saveSettings()
                }
            }
        }
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

    // ─── Scaled Visual Content ───
    Item {
        id: scaledContent
        width: 290
        height: 70 + Math.max(2, root.cities.length) * 34
        scale: root.scaleFactor
        transformOrigin: Item.TopLeft

        // Drag & Theme Switch MouseArea on Card Background
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            drag.target: root
            drag.axis: Drag.XAndYAxis
            drag.minimumX: 10
            drag.maximumX: Math.max(10, root.screenWidth - root.width - 10)
            drag.minimumY: 10
            drag.maximumY: Math.max(10, root.screenHeight - root.height - 10)
            cursorShape: drag.active ? Qt.ClosedHandCursor : (containsMouse ? Qt.OpenHandCursor : Qt.ArrowCursor)

            // Double click to switch themes!
            onDoubleClicked: {
                root.themeIndex = (root.themeIndex + 1) % root.themes.length
                root.saveSettings()
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

        // Main Card
        Rectangle {
            anchors.fill: parent
            color: root.currentTheme.bg
            radius: 32
            border.color: "#1FFFFFFF"
            border.width: 1.5
            antialiasing: true

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8

                // Header Row: TIMEZONES Pill Badge + Theme Tag + Add UTC Button
                Row {
                    width: parent.width

                    Rectangle {
                        height: 22
                        width: badgeRow.implicitWidth + 16
                        radius: 11
                        color: root.currentTheme.pillBg
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
                                color: root.currentTheme.accent
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "TIMEZONES"
                                color: "#FFFFFF"
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 0.6
                                font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                            }
                        }
                    }

                    Item {
                        width: Math.max(0, parent.width - parent.children[0].width - rightHeaderRow.width)
                        height: 1
                    }

                    Row {
                        id: rightHeaderRow
                        spacing: 6
                        anchors.verticalCenter: parent.verticalCenter

                        // Theme indicator tag
                        Rectangle {
                            height: 20
                            width: thmText.implicitWidth + 10
                            radius: 10
                            color: root.currentTheme.pillBg
                            antialiasing: true

                            Text {
                                id: thmText
                                anchors.centerIn: parent
                                text: root.currentTheme.name
                                color: root.currentTheme.accent
                                font.pixelSize: 9
                                font.bold: true
                                font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                            }
                        }

                        // Add Custom Timezone / UTC Button (+)
                        Rectangle {
                            width: 22
                            height: 22
                            radius: 11
                            color: addBtnArea.containsMouse ? "#33FFFFFF" : root.currentTheme.accent
                            antialiasing: true

                            Text {
                                anchors.centerIn: parent
                                text: "+"
                                color: addBtnArea.containsMouse ? "#FFFFFF" : "#1E2A30"
                                font.pixelSize: 14
                                font.bold: true
                            }

                            MouseArea {
                                id: addBtnArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: addTzProc.running = true
                            }
                        }
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
                            color: cityArea.containsMouse ? "#20FFFFFF" : root.currentTheme.pillBg
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
                                    color: timeInfo.isNight ? root.currentTheme.moon : root.currentTheme.sun
                                    antialiasing: true
                                }

                                // City Name
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.name
                                    color: "#FFFFFF"
                                    font.pixelSize: 11
                                    font.bold: true
                                    font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                                }

                                Item {
                                    width: Math.max(0, parent.width - 8 - 80 - timeRow.width)
                                    height: 1
                                }

                                // Time + AM/PM + Offset Tag + Delete (on hover)
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
                                        color: "#9CA8AC"
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
                                            color: root.currentTheme.accent
                                            font.pixelSize: 8
                                            font.bold: true
                                            font.family: "Google Sans Flex, Google Sans, Inter, monospace"
                                        }
                                    }

                                    // Remove City Button (when list > 1)
                                    Rectangle {
                                        visible: root.cities.length > 1 && cityArea.containsMouse
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 14
                                        height: 14
                                        radius: 7
                                        color: "#FFB4AB"
                                        antialiasing: true

                                        Text {
                                            anchors.centerIn: parent
                                            text: "×"
                                            color: "#1E2A30"
                                            font.pixelSize: 10
                                            font.bold: true
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                var list = root.cities.slice()
                                                list.splice(index, 1)
                                                root.cities = list
                                                root.saveSettings()
                                            }
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: cityArea
                                anchors.fill: parent
                                hoverEnabled: true
                            }
                        }
                    }
                }
            }
        }
    }
}
