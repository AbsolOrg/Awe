import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property real screenWidth: 1920
    property real screenHeight: 1080

    // Position & sizing properties
    property real posX: 960
    property real posY: 350
    property real scaleFactor: 0.9

    x: Math.max(10, Math.min(root.screenWidth - root.width - 10, posX))
    y: Math.max(10, Math.min(root.screenHeight - root.height - 10, posY))
    width: Math.round(320 * scaleFactor)
    height: Math.round(140 * scaleFactor)

    // ─── Settings Persistence ───
    Process {
        id: loadSettingsProc
        command: ["sh", "-c", "cat ~/.config/quickshell/widget_settings.json 2>/dev/null || echo '{}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text)
                    if (data.weather) {
                        if (data.weather.scale !== undefined) root.scaleFactor = Math.max(0.5, Math.min(2.5, data.weather.scale))
                        var w = Math.round(320 * root.scaleFactor)
                        var h = Math.round(140 * root.scaleFactor)
                        if (data.weather.x !== undefined) root.posX = Math.max(10, Math.min(root.screenWidth - w - 10, data.weather.x))
                        if (data.weather.y !== undefined) root.posY = Math.max(10, Math.min(root.screenHeight - h - 10, data.weather.y))
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
        var script = "python3 -c 'import json, os; p=os.path.expanduser(\"~/.config/quickshell/widget_settings.json\"); d=json.load(open(p)) if os.path.exists(p) else {}; d[\"weather\"]={\"x\":" + Math.round(root.x) + ",\"y\":" + Math.round(root.y) + ",\"scale\":" + root.scaleFactor.toFixed(2) + "}; open(p,\"w\").write(json.dumps(d,indent=2))'"
        saveSettingsProc.command = ["sh", "-c", script]
        saveSettingsProc.running = true
    }

    // ─── Weather Data ───
    property string condition: "Loading..."
    property string temp: "--°C"
    property string wind: "--"
    property string humidity: "--"
    property string location: "Local Weather"

    Process {
        id: weatherProc
        command: ["sh", "-c", "curl -s --max-time 4 'wttr.in/?format=%C;%t;%w;%h;%l' 2>/dev/null || echo 'Overcast;+28°C;15km/h;65%;Local'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var raw = text.trim()
                if (raw.includes(";")) {
                    var parts = raw.split(";")
                    root.condition = parts[0] ? parts[0].trim() : "Partly Cloudy"
                    root.temp = parts[1] ? parts[1].replace("+", "").trim() : "26°C"
                    root.wind = parts[2] ? parts[2].trim() : "12km/h"
                    root.humidity = parts[3] ? parts[3].trim() : "60%"
                    if (parts[4] && parts[4].length > 0) root.location = parts[4].trim()
                }
            }
        }
    }

    Timer {
        interval: 900000 // 15 mins
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: weatherProc.running = true
    }

    Component.onCompleted: {
        loadSettingsProc.running = true
        weatherProc.running = true
    }

    // ─── Material Dark Slate Theme Palette ───
    readonly property color colBg: "#3A454B"              // Dark Slate Main Card
    readonly property color colBadgeBg: "#4D585F"         // Slate Pill Badge
    readonly property color colTextPrimary: "#FFFFFF"
    readonly property color colTextSecondary: "#B0BEC5"

    // ─── Scaled Visual Content ───
    Item {
        id: scaledContent
        width: 320
        height: 140
        scale: root.scaleFactor
        transformOrigin: Item.TopLeft

        Rectangle {
            anchors.fill: parent
            color: root.colBg
            radius: 32
            antialiasing: true

            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8

                // Header Row: Weather Pill Badge & Location
                Row {
                    width: parent.width

                    Rectangle {
                        height: 22
                        width: wBadgeRow.implicitWidth + 16
                        radius: 11
                        color: root.colBadgeBg
                        antialiasing: true

                        Row {
                            id: wBadgeRow
                            anchors.centerIn: parent
                            spacing: 6

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 7
                                height: 7
                                radius: 3.5
                                color: "#D1E8DA"
                                antialiasing: true
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "WEATHER"
                                color: root.colTextPrimary
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 0.6
                                font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                            }
                        }
                    }

                    Item {
                        width: Math.max(0, parent.width - (parent.children[0].width + locText.width))
                        height: 1
                    }

                    Text {
                        id: locText
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.location
                        color: root.colTextSecondary
                        font.pixelSize: 11
                        font.bold: true
                        font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                    }
                }

                // Middle Row: Big Temp + Condition
                Row {
                    width: parent.width
                    spacing: 14

                    Text {
                        text: root.temp
                        color: root.colTextPrimary
                        font.pixelSize: 36
                        font.bold: true
                        font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: root.condition
                            color: root.colTextPrimary
                            font.pixelSize: 14
                            font.bold: true
                            font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                        }

                        Text {
                            text: "Forecast condition"
                            color: root.colTextSecondary
                            font.pixelSize: 10
                            font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                        }
                    }
                }

                // Bottom Row: Mini Metric Pills (Humidity & Wind)
                Row {
                    spacing: 8

                    // Humidity Pill
                    Rectangle {
                        height: 22
                        width: humRow.implicitWidth + 14
                        radius: 11
                        color: root.colBadgeBg
                        antialiasing: true

                        Row {
                            id: humRow
                            anchors.centerIn: parent
                            spacing: 5

                            Text {
                                text: "HUM"
                                color: root.colTextSecondary
                                font.pixelSize: 9
                                font.bold: true
                                font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                            }

                            Text {
                                text: root.humidity
                                color: root.colTextPrimary
                                font.pixelSize: 9
                                font.bold: true
                                font.family: "Google Sans Flex, Google Sans, Inter, monospace"
                            }
                        }
                    }

                    // Wind Pill
                    Rectangle {
                        height: 22
                        width: windRow.implicitWidth + 14
                        radius: 11
                        color: root.colBadgeBg
                        antialiasing: true

                        Row {
                            id: windRow
                            anchors.centerIn: parent
                            spacing: 5

                            Text {
                                text: "WIND"
                                color: root.colTextSecondary
                                font.pixelSize: 9
                                font.bold: true
                                font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                            }

                            Text {
                                text: root.wind
                                color: root.colTextPrimary
                                font.pixelSize: 9
                                font.bold: true
                                font.family: "Google Sans Flex, Google Sans, Inter, monospace"
                            }
                        }
                    }
                }
            }
        }
    }

    // ─── Drag & Resize MouseArea ───
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

        onClicked: {
            weatherProc.running = true
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
