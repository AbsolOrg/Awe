import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property real screenWidth: 1920
    property real screenHeight: 1080

    // Top centered floating pill / notch
    x: Math.round((screenWidth - width) / 2)
    y: 10
    width: isExpanded ? 390 : 180
    height: isExpanded ? 410 : 34
    z: 999

    property bool isExpanded: false

    // Widget visibility states
    property var widgetVisibility: ({
        clock: true,
        poster: true,
        calendar: true,
        media: true,
        sysinfo: true,
        battery: true,
        weather: true,
        quickcontrols: true,
        network: true,
        notes: true,
        todo: true,
        timer: true,
        thermal: true,
        quote: true,
        clipboard: true,
        crypto: true,
        worldclock: true,
        git: true,
        resourcewheel: true,
        visualizer: true,
        habits: true,
        ping: true,
        storagemap: true,
        calc: true
    })

    // ─── Settings Persistence ───
    Process {
        id: loadSettingsProc
        command: ["sh", "-c", "cat ~/.config/quickshell/widget_settings.json 2>/dev/null || echo '{}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text)
                    if (data.manager && data.manager.visibility !== undefined) {
                        var vis = Object.assign({}, root.widgetVisibility, data.manager.visibility)
                        root.widgetVisibility = vis
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
        var jsonStr = JSON.stringify({
            visibility: root.widgetVisibility
        }).replace(/'/g, "'\\''")
        var script = "python3 -c 'import json, os; p=os.path.expanduser(\"~/.config/quickshell/widget_settings.json\"); d=json.load(open(p)) if os.path.exists(p) else {}; d.setdefault(\"manager\", {})[\"visibility\"]=" + jsonStr + "; open(p,\"w\").write(json.dumps(d,indent=2))'"
        saveSettingsProc.command = ["sh", "-c", script]
        saveSettingsProc.running = true
    }

    function toggleWidget(name) {
        var vis = Object.assign({}, root.widgetVisibility)
        vis[name] = !vis[name]
        root.widgetVisibility = vis
        root.saveSettings()
    }

    Component.onCompleted: {
        loadSettingsProc.running = true
    }

    // Dynamic Theme Palette from Theme singleton
    readonly property color colBg: Theme.colBg
    readonly property color colPillBg: Theme.colPillBg
    readonly property color colAccent: Theme.colAccent
    readonly property color colAccentGreen: Theme.colAccentGreen
    readonly property color colTextPrimary: Theme.colTextPrimary
    readonly property color colTextSecondary: Theme.colTextSecondary

    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    // Main Floating Pill / Expanded Card
    Rectangle {
        anchors.fill: parent
        color: root.colBg
        radius: root.isExpanded ? 24 : 17
        border.color: Theme.borderColor
        border.width: Theme.borderWidth
        antialiasing: true
        clip: true

        // Top glossy specular highlight in Liquid Glass mode
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
            anchors.margins: root.isExpanded ? 12 : 4
            spacing: 8

            // ─── Header Notch Bar (Click to toggle expand/collapse) ───
            Rectangle {
                width: parent.width
                height: root.isExpanded ? 30 : 26
                radius: 13
                color: notchArea.containsMouse ? "#1AFFFFFF" : "transparent"
                antialiasing: true

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    // Active Green Indicator Dot
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 7
                        height: 7
                        radius: 3.5
                        color: root.colAccentGreen
                        antialiasing: true
                    }

                    // Notch Title Label
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.isExpanded ? "Desktop Widgets & Themes" : "Awe Widgets"
                        color: root.colTextPrimary
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 0.5
                        font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                    }

                    // Expanding Chevron Icon
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.isExpanded ? "▲" : "▼"
                        color: root.colAccent
                        font.pixelSize: 9
                        font.bold: true
                    }
                }

                MouseArea {
                    id: notchArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.isExpanded = !root.isExpanded
                }
            }

            // ─── Theme Selection Header & Chips ───
            Column {
                visible: root.isExpanded
                width: parent.width
                spacing: 6

                Row {
                    spacing: 6
                    width: parent.width

                    Text {
                        text: "THEME PRESET"
                        color: root.colTextSecondary
                        font.pixelSize: 9
                        font.bold: true
                        font.letterSpacing: 1.0
                        font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                    }
                }

                // Horizontal scrollable theme chips
                Flickable {
                    id: themeFlick
                    width: parent.width
                    height: 32
                    contentWidth: themeRow.implicitWidth
                    contentHeight: 32
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.HorizontalFlick
                    clip: true

                    WheelHandler {
                        onWheel: (event) => {
                            themeFlick.contentX = Math.max(0, Math.min(themeFlick.contentWidth - themeFlick.width, themeFlick.contentX - event.angleDelta.y))
                        }
                    }

                    Row {
                        id: themeRow
                        spacing: 6

                        Repeater {
                            model: Theme.themes

                            Rectangle {
                                id: themeChip
                                width: chipRow.implicitWidth + 16
                                height: 30
                                radius: 15
                                color: (Theme.currentTheme === modelData.id) ? root.colPillBg : "#12FFFFFF"
                                border.color: (Theme.currentTheme === modelData.id) ? root.colAccent : "#1FFFFFFF"
                                border.width: (Theme.currentTheme === modelData.id) ? 1.5 : 1.0
                                antialiasing: true

                                Row {
                                    id: chipRow
                                    anchors.centerIn: parent
                                    spacing: 5

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.icon
                                        font.pixelSize: 11
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.name
                                        color: (Theme.currentTheme === modelData.id) ? root.colTextPrimary : root.colTextSecondary
                                        font.pixelSize: 10
                                        font.bold: (Theme.currentTheme === modelData.id)
                                        font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Theme.setTheme(modelData.id)
                                }
                            }
                        }
                    }
                }
            }

            // Divider Line
            Rectangle {
                visible: root.isExpanded
                width: parent.width
                height: 1
                color: "#15FFFFFF"
            }

            // ─── Widgets Header & Scrollable Toggle Grid ───
            Column {
                visible: root.isExpanded
                width: parent.width
                height: parent.height - 110
                spacing: 6

                Text {
                    text: "TOGGLE WIDGETS"
                    color: root.colTextSecondary
                    font.pixelSize: 9
                    font.bold: true
                    font.letterSpacing: 1.0
                    font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                }

                Item {
                    width: parent.width
                    height: parent.height - 18
                    clip: true

                    Flickable {
                        id: scrollFlick
                        anchors.fill: parent
                        contentWidth: width
                        contentHeight: widgetGrid.implicitHeight + 10
                        boundsBehavior: Flickable.StopAtBounds
                        clip: true

                        Grid {
                            id: widgetGrid
                            width: parent.width
                            columns: 2
                            spacing: 6

                            Repeater {
                                model: [
                                    { id: "clock", label: "Clock" },
                                    { id: "poster", label: "Poster" },
                                    { id: "calendar", label: "Calendar" },
                                    { id: "media", label: "Media Player" },
                                    { id: "sysinfo", label: "System Info" },
                                    { id: "battery", label: "Battery" },
                                    { id: "weather", label: "Weather" },
                                    { id: "quickcontrols", label: "Volume / Brightness" },
                                    { id: "network", label: "Network" },
                                    { id: "notes", label: "Notes" },
                                    { id: "todo", label: "Tasks / Todo" },
                                    { id: "timer", label: "Pomodoro Timer" },
                                    { id: "thermal", label: "Hardware Thermals" },
                                    { id: "quote", label: "Daily Quote" },
                                    { id: "clipboard", label: "Clipboard" },
                                    { id: "crypto", label: "Crypto Ticker" },
                                    { id: "worldclock", label: "World Clock" },
                                    { id: "git", label: "Git Dashboard" },
                                    { id: "resourcewheel", label: "Resource Wheel" },
                                    { id: "visualizer", label: "Audio Visualizer" },
                                    { id: "habits", label: "Habit Tracker" },
                                    { id: "ping", label: "Network Ping" },
                                    { id: "storagemap", label: "Storage Map" },
                                    { id: "calc", label: "Calculator" }
                                ]

                                Rectangle {
                                    width: (widgetGrid.width - 6) / 2
                                    height: 28
                                    radius: 14
                                    color: (root.widgetVisibility[modelData.id] !== false) ? root.colPillBg : "#12FFFFFF"
                                    border.color: (root.widgetVisibility[modelData.id] !== false) ? root.colAccent : "#1AFFFFFF"
                                    border.width: 1
                                    antialiasing: true

                                    Row {
                                        anchors.fill: parent
                                        anchors.margins: 6
                                        spacing: 6

                                        Rectangle {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 6
                                            height: 6
                                            radius: 3
                                            color: (root.widgetVisibility[modelData.id] !== false) ? root.colAccentGreen : "#667780"
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData.label
                                            color: (root.widgetVisibility[modelData.id] !== false) ? root.colTextPrimary : root.colTextSecondary
                                            font.pixelSize: 10
                                            font.bold: (root.widgetVisibility[modelData.id] !== false)
                                            elide: Text.ElideRight
                                            width: parent.width - 20
                                            font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.toggleWidget(modelData.id)
                                    }
                                }
                            }
                        }
                    }

                    // Smooth Minimalist Scrollbar Indicator
                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.rightMargin: 2
                        width: 3
                        radius: 1.5
                        color: "#15FFFFFF"
                        visible: scrollFlick.contentHeight > scrollFlick.height

                        Rectangle {
                            width: parent.width
                            height: Math.max(20, (scrollFlick.height / scrollFlick.contentHeight) * scrollFlick.height)
                            y: (scrollFlick.contentY / (scrollFlick.contentHeight - scrollFlick.height)) * (scrollFlick.height - height)
                            radius: 1.5
                            color: root.colAccent
                            antialiasing: true
                        }
                    }
                }
            }
        }
    }

}
