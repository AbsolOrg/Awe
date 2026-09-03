import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property real screenWidth: 1920
    property real screenHeight: 1080

    // Position & sizing properties
    property real posX: 660
    property real posY: 730
    property real scaleFactor: 0.88

    x: Math.max(10, Math.min(root.screenWidth - root.width - 10, posX))
    y: Math.max(10, Math.min(root.screenHeight - root.height - 10, posY))
    width: Math.round(290 * scaleFactor)
    height: Math.round((72 + root.habitsList.length * 36) * scaleFactor)

    // Habits Matrix List
    property var habitsList: [
        { name: "Code Daily", streak: 18, days: [true, true, true, true, true, false, false], color: "#C2E7FF" },
        { name: "Hydrate (2L)", streak: 12, days: [true, true, true, true, false, false, false], color: "#A2C9C2" },
        { name: "Read / Study", streak: 7, days: [true, true, false, true, false, false, false], color: "#FFE082" }
    ]

    property var dayLabels: ["M", "T", "W", "T", "F", "S", "S"]

    // ─── Settings Persistence ───
    Process {
        id: loadSettingsProc
        command: ["sh", "-c", "cat ~/.config/quickshell/widget_settings.json 2>/dev/null || echo '{}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text)
                    if (data.habits) {
                        if (data.habits.scale !== undefined) root.scaleFactor = Math.max(0.5, Math.min(2.5, data.habits.scale))
                        var w = Math.round(290 * root.scaleFactor)
                        var h = Math.round((72 + root.habitsList.length * 36) * root.scaleFactor)
                        if (data.habits.x !== undefined) root.posX = Math.max(10, Math.min(root.screenWidth - w - 10, data.habits.x))
                        if (data.habits.y !== undefined) root.posY = Math.max(10, Math.min(root.screenHeight - h - 10, data.habits.y))
                        if (data.habits.list && Array.isArray(data.habits.list) && data.habits.list.length > 0) {
                            root.habitsList = data.habits.list
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
        var jsonStr = JSON.stringify(root.habitsList).replace(/'/g, "'\\''")
        var script = "python3 -c 'import json, os; p=os.path.expanduser(\"~/.config/quickshell/widget_settings.json\"); d=json.load(open(p)) if os.path.exists(p) else {}; d[\"habits\"]={\"x\":" + Math.round(root.x) + ",\"y\":" + Math.round(root.y) + ",\"scale\":" + root.scaleFactor.toFixed(2) + ",\"list\":" + jsonStr + "}; open(p,\"w\").write(json.dumps(d,indent=2))'"
        saveSettingsProc.command = ["sh", "-c", script]
        saveSettingsProc.running = true
    }

    // ─── GTK3 Custom Habit Prompt ───
    Process {
        id: addHabitProc
        command: ["python3", "-c", "import gi; gi.require_version('Gtk', '3.0'); from gi.repository import Gtk; dialog=Gtk.Dialog(title='Add New Habit', buttons=(Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL, Gtk.STOCK_OK, Gtk.ResponseType.OK)); vbox=dialog.get_content_area(); entry=Gtk.Entry(); entry.set_placeholder_text('Habit Name (e.g. Exercise, Meditate)'); vbox.pack_start(entry, True, True, 8); dialog.show_all(); res=dialog.run(); name=entry.get_text().strip(); dialog.destroy(); print(name if res==Gtk.ResponseType.OK else '')"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var name = text.trim()
                if (name.length > 0) {
                    var list = root.habitsList.slice()
                    var colors = ["#C2E7FF", "#A2C9C2", "#FFE082", "#D7AEFB", "#FFB4AB"]
                    var col = colors[list.length % colors.length]
                    list.push({ name: name, streak: 1, days: [false, false, false, false, false, false, false], color: col })
                    root.habitsList = list
                    root.saveSettings()
                }
            }
        }
    }

    Component.onCompleted: {
        loadSettingsProc.running = true
    }

    // Theme Palette
    readonly property color colBg: Theme.colBg
    readonly property color colPillBg: Theme.colPillBg
    readonly property color colAccent: Theme.colAccent
    readonly property color colAccentGreen: Theme.colAccentGreen
    readonly property color colTextPrimary: Theme.colTextPrimary
    readonly property color colTextSecondary: Theme.colTextSecondary

    // ─── Scaled Visual Content ───
    Item {
        id: scaledContent
        width: 290
        height: 72 + root.habitsList.length * 36
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

                // Header Row: HABITS Badge + Add Button
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
                                color: root.colAccentGreen
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "HABIT TRACKER"
                                color: "#FFFFFF"
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 0.6
                                font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                            }
                        }
                    }

                    Item {
                        width: Math.max(0, parent.width - parent.children[0].width - addHabitBtn.width)
                        height: 1
                    }

                    Rectangle {
                        id: addHabitBtn
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
                            onClicked: addHabitProc.running = true
                        }
                    }
                }

                // Habits Rows
                Column {
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: root.habitsList

                        Rectangle {
                            width: parent.width
                            height: 30
                            radius: 15
                            color: root.colPillBg
                            antialiasing: true

                            Row {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 6

                                // Habit Name + Streak
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.name
                                    color: "#FFFFFF"
                                    font.pixelSize: 10
                                    font.bold: true
                                    elide: Text.ElideRight
                                    width: 85
                                    font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                                }

                                // Streak Badge
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: 16
                                    width: stkText.implicitWidth + 8
                                    radius: 8
                                    color: "#1FFFFFFF"
                                    antialiasing: true

                                    Text {
                                        id: stkText
                                        anchors.centerIn: parent
                                        text: modelData.streak + "d"
                                        color: modelData.color || root.colAccent
                                        font.pixelSize: 8
                                        font.bold: true
                                        font.family: "Google Sans Flex, Google Sans, Inter, monospace"
                                    }
                                }

                                Item {
                                    width: Math.max(0, parent.width - 85 - 34 - daysRow.width)
                                    height: 1
                                }

                                // 7-Day Matrix Dots
                                Row {
                                    id: daysRow
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 4

                                    Repeater {
                                        model: 7

                                        Rectangle {
                                            width: 16
                                            height: 16
                                            radius: 8
                                            color: (modelData.days && modelData.days[index]) ? (modelData.color || root.colAccent) : "#20000000"
                                            border.color: (modelData.days && modelData.days[index]) ? "transparent" : "#40FFFFFF"
                                            border.width: 1
                                            antialiasing: true

                                            Text {
                                                anchors.centerIn: parent
                                                text: root.dayLabels[index]
                                                color: (modelData.days && modelData.days[index]) ? "#1E2A30" : "#80FFFFFF"
                                                font.pixelSize: 8
                                                font.bold: true
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    var list = root.habitsList.slice()
                                                    var habit = Object.assign({}, list[model.index])
                                                    var days = (habit.days || [false, false, false, false, false, false, false]).slice()
                                                    days[index] = !days[index]
                                                    habit.days = days
                                                    list[model.index] = habit
                                                    root.habitsList = list
                                                    root.saveSettings()
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
    }
}
