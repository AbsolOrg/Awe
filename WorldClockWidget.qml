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

    // UI Shape & Layout Styles:
    // 0: Classic M3 Card, 1: Floating Multi-Pills, 2: 2-Column Grid Tiles, 3: Arch Expressive
    property int shapeStyleIndex: 0
    property var styleNames: ["Classic Card", "Floating Pills", "Grid Tiles", "Arch Expressive"]

    x: Math.max(10, Math.min(root.screenWidth - root.width - 10, posX))
    y: Math.max(10, Math.min(root.screenHeight - root.height - 10, posY))
    width: Math.round(290 * scaleFactor)
    height: Math.round((root.shapeStyleIndex === 2 ? 80 + Math.ceil(root.cities.length / 2) * 68 : (root.shapeStyleIndex === 1 ? 60 + root.cities.length * 42 : 70 + Math.max(2, root.cities.length) * 34)) * scaleFactor)

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
                        if (data.worldclock.shapeStyle !== undefined) root.shapeStyleIndex = data.worldclock.shapeStyle % 4
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
        var script = "python3 -c 'import json, os; p=os.path.expanduser(\"~/.config/quickshell/widget_settings.json\"); d=json.load(open(p)) if os.path.exists(p) else {}; d[\"worldclock\"]={\"x\":" + Math.round(root.x) + ",\"y\":" + Math.round(root.y) + ",\"scale\":" + root.scaleFactor.toFixed(2) + ",\"shapeStyle\":" + root.shapeStyleIndex + ",\"cities\":" + jsonCities + "}; open(p,\"w\").write(json.dumps(d,indent=2))'"
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

    // Material 3 Palette
    readonly property color colBg: "#232D33"
    readonly property color colPillBg: "#303B42"
    readonly property color colAccent: "#C2E7FF"
    readonly property color colAccentSun: "#FFE082"
    readonly property color colAccentMoon: "#D7AEFB"
    readonly property color colTextPrimary: "#FFFFFF"
    readonly property color colTextSecondary: "#9CA8AC"

    // ─── Scaled Visual Content ───
    Item {
        id: scaledContent
        width: 290
        height: (root.shapeStyleIndex === 2 ? 80 + Math.ceil(root.cities.length / 2) * 68 : (root.shapeStyleIndex === 1 ? 60 + root.cities.length * 42 : 70 + Math.max(2, root.cities.length) * 34))
        scale: root.scaleFactor
        transformOrigin: Item.TopLeft

        // Drag & Shape/UI Switch MouseArea
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

            // Double click to switch UI Shapes / Layout styles!
            onDoubleClicked: {
                root.shapeStyleIndex = (root.shapeStyleIndex + 1) % 4
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

        // ════════════════════════════════════════════════════════════════
        // VARIANT 0: Classic M3 Elevated Card (shapeStyleIndex === 0)
        // ════════════════════════════════════════════════════════════════
        Rectangle {
            visible: root.shapeStyleIndex === 0
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

                // Header Row
                Row {
                    width: parent.width

                    Rectangle {
                        height: 22
                        width: b0Row.implicitWidth + 16
                        radius: 11
                        color: root.colPillBg
                        antialiasing: true

                        Row {
                            id: b0Row
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
                                color: "#FFFFFF"
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 0.6
                                font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                            }
                        }
                    }

                    Item {
                        width: Math.max(0, parent.width - parent.children[0].width - r0Row.width)
                        height: 1
                    }

                    Row {
                        id: r0Row
                        spacing: 6
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            height: 20
                            width: st0Text.implicitWidth + 10
                            radius: 10
                            color: root.colPillBg
                            antialiasing: true

                            Text {
                                id: st0Text
                                anchors.centerIn: parent
                                text: root.styleNames[root.shapeStyleIndex]
                                color: root.colAccent
                                font.pixelSize: 9
                                font.bold: true
                                font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                            }
                        }

                        // Add Custom Timezone Button (+)
                        Rectangle {
                            width: 22
                            height: 22
                            radius: 11
                            color: root.colAccent
                            antialiasing: true

                            Text {
                                anchors.centerIn: parent
                                text: "+"
                                color: "#1E2A30"
                                font.pixelSize: 14
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: addTzProc.running = true
                            }
                        }
                    }
                }

                // City List
                Column {
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: root.cities

                        Rectangle {
                            width: parent.width
                            height: 28
                            radius: 14
                            color: root.colPillBg
                            antialiasing: true

                            property var timeInfo: root.getTimeForOffset(modelData.offset)

                            Row {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 8

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 8
                                    height: 8
                                    radius: 4
                                    color: timeInfo.isNight ? root.colAccentMoon : root.colAccentSun
                                    antialiasing: true
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.name
                                    color: "#FFFFFF"
                                    font.pixelSize: 11
                                    font.bold: true
                                    font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                                }

                                Item {
                                    width: Math.max(0, parent.width - 8 - 80 - t0Row.width)
                                    height: 1
                                }

                                Row {
                                    id: t0Row
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
                                        width: off0Text.implicitWidth + 8
                                        radius: 7
                                        color: "#1FFFFFFF"
                                        antialiasing: true

                                        Text {
                                            id: off0Text
                                            anchors.centerIn: parent
                                            text: modelData.tag
                                            color: root.colAccent
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

        // ════════════════════════════════════════════════════════════════
        // VARIANT 1: Floating Multi-Pill Pods (shapeStyleIndex === 1)
        // ════════════════════════════════════════════════════════════════
        Column {
            visible: root.shapeStyleIndex === 1
            anchors.fill: parent
            spacing: 6

            // Floating Header Pill
            Rectangle {
                width: parent.width
                height: 30
                radius: 15
                color: root.colBg
                border.color: "#1FFFFFFF"
                border.width: 1.5
                antialiasing: true

                Row {
                    anchors.fill: parent
                    anchors.margins: 8
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
                        text: "TIMEZONES · PODS"
                        color: "#FFFFFF"
                        font.pixelSize: 9
                        font.bold: true
                        font.letterSpacing: 0.5
                        font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                    }

                    Item {
                        width: Math.max(0, parent.width - 150 - addPillBtn.width)
                        height: 1
                    }

                    Rectangle {
                        id: addPillBtn
                        anchors.verticalCenter: parent.verticalCenter
                        width: 18
                        height: 18
                        radius: 9
                        color: root.colAccent
                        antialiasing: true

                        Text {
                            anchors.centerIn: parent
                            text: "+"
                            color: "#1E2A30"
                            font.pixelSize: 12
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: addTzProc.running = true
                        }
                    }
                }
            }

            // Stacked Floating Stadium Pods
            Repeater {
                model: root.cities

                Rectangle {
                    width: parent.width
                    height: 36
                    radius: 18
                    color: root.colBg
                    border.color: "#1FFFFFFF"
                    border.width: 1.5
                    antialiasing: true

                    property var timeInfo: root.getTimeForOffset(modelData.offset)

                    Row {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 10
                            height: 10
                            radius: 5
                            color: timeInfo.isNight ? root.colAccentMoon : root.colAccentSun
                            antialiasing: true
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.name
                            color: "#FFFFFF"
                            font.pixelSize: 12
                            font.bold: true
                            font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                        }

                        Item {
                            width: Math.max(0, parent.width - 100 - t1Row.width)
                            height: 1
                        }

                        Row {
                            id: t1Row
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: timeInfo.timeStr
                                color: root.colAccent
                                font.pixelSize: 13
                                font.bold: true
                                font.family: "Google Sans Flex, Google Sans, Inter, monospace"
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: timeInfo.ampm
                                color: "#9CA8AC"
                                font.pixelSize: 9
                                font.bold: true
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                height: 16
                                width: off1Text.implicitWidth + 8
                                radius: 8
                                color: root.colPillBg
                                antialiasing: true

                                Text {
                                    id: off1Text
                                    anchors.centerIn: parent
                                    text: modelData.tag
                                    color: "#FFFFFF"
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

        // ════════════════════════════════════════════════════════════════
        // VARIANT 2: 2-Column Grid Tiles (shapeStyleIndex === 2)
        // ════════════════════════════════════════════════════════════════
        Rectangle {
            visible: root.shapeStyleIndex === 2
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

                // Header
                Row {
                    width: parent.width

                    Rectangle {
                        height: 22
                        width: b2Row.implicitWidth + 16
                        radius: 11
                        color: root.colPillBg
                        antialiasing: true

                        Row {
                            id: b2Row
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
                                text: "TIMEZONES · GRID"
                                color: "#FFFFFF"
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 0.5
                                font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                            }
                        }
                    }

                    Item {
                        width: Math.max(0, parent.width - parent.children[0].width - addGridBtn.width)
                        height: 1
                    }

                    Rectangle {
                        id: addGridBtn
                        width: 22
                        height: 22
                        radius: 11
                        color: root.colAccent
                        antialiasing: true

                        Text {
                            anchors.centerIn: parent
                            text: "+"
                            color: "#1E2A30"
                            font.pixelSize: 14
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: addTzProc.running = true
                        }
                    }
                }

                // Grid Tiles
                Grid {
                    width: parent.width
                    columns: 2
                    spacing: 6

                    Repeater {
                        model: root.cities

                        Rectangle {
                            width: (parent.width - 6) / 2
                            height: 60
                            radius: 18
                            color: root.colPillBg
                            antialiasing: true

                            property var timeInfo: root.getTimeForOffset(modelData.offset)

                            Column {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 2

                                Row {
                                    width: parent.width

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 6
                                        height: 6
                                        radius: 3
                                        color: timeInfo.isNight ? root.colAccentMoon : root.colAccentSun
                                    }

                                    Item { width: 4; height: 1 }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.name
                                        color: "#9CA8AC"
                                        font.pixelSize: 10
                                        font.bold: true
                                        elide: Text.ElideRight
                                        width: parent.width - 50
                                    }

                                    Item { width: Math.max(0, parent.width - 6 - (parent.width - 50) - 30); height: 1 }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.tag
                                        color: root.colAccent
                                        font.pixelSize: 8
                                        font.bold: true
                                    }
                                }

                                Text {
                                    text: timeInfo.timeStr + " " + timeInfo.ampm
                                    color: "#FFFFFF"
                                    font.pixelSize: 14
                                    font.bold: true
                                    font.family: "Google Sans Flex, Google Sans, Inter, monospace"
                                }
                            }
                        }
                    }
                }
            }
        }

        // ════════════════════════════════════════════════════════════════
        // VARIANT 3: Arch Expressive (shapeStyleIndex === 3)
        // ════════════════════════════════════════════════════════════════
        Rectangle {
            visible: root.shapeStyleIndex === 3
            anchors.fill: parent
            color: root.colBg
            radius: 40
            border.color: root.colAccent
            border.width: 1.5
            antialiasing: true

            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8

                // Header Arched Arch
                Row {
                    width: parent.width

                    Rectangle {
                        height: 24
                        width: b3Row.implicitWidth + 18
                        radius: 12
                        color: root.colAccent
                        antialiasing: true

                        Row {
                            id: b3Row
                            anchors.centerIn: parent
                            spacing: 6

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 7
                                height: 7
                                radius: 3.5
                                color: "#1E2A30"
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "EXPRESSIVE ARCH"
                                color: "#1E2A30"
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 0.6
                                font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                            }
                        }
                    }

                    Item {
                        width: Math.max(0, parent.width - parent.children[0].width - addArchBtn.width)
                        height: 1
                    }

                    Rectangle {
                        id: addArchBtn
                        width: 24
                        height: 24
                        radius: 12
                        color: root.colPillBg
                        antialiasing: true

                        Text {
                            anchors.centerIn: parent
                            text: "+"
                            color: "#FFFFFF"
                            font.pixelSize: 14
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: addTzProc.running = true
                        }
                    }
                }

                // Vertical Timeline Flow
                Column {
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: root.cities

                        Rectangle {
                            width: parent.width
                            height: 28
                            radius: 14
                            color: root.colPillBg
                            antialiasing: true

                            property var timeInfo: root.getTimeForOffset(modelData.offset)

                            Row {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 8

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 8
                                    height: 8
                                    radius: 4
                                    color: timeInfo.isNight ? root.colAccentMoon : root.colAccentSun
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.name
                                    color: "#FFFFFF"
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                Item {
                                    width: Math.max(0, parent.width - 8 - 80 - t3Row.width)
                                    height: 1
                                }

                                Row {
                                    id: t3Row
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 6

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: timeInfo.timeStr
                                        color: root.colAccent
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
