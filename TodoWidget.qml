import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property real screenWidth: 1920
    property real screenHeight: 1080

    // Position & sizing properties
    property real posX: 680
    property real posY: 170
    property real scaleFactor: 0.9

    x: Math.max(10, Math.min(root.screenWidth - root.width - 10, posX))
    y: Math.max(10, Math.min(root.screenHeight - root.height - 10, posY))
    width: Math.round(280 * scaleFactor)
    height: Math.round(240 * scaleFactor)

    // Todo items list
    property var taskList: [
        { text: "Update Quickshell desktop widgets", done: true },
        { text: "Material 3 theme refinement", done: true },
        { text: "Check soundwave equalizer animations", done: false },
        { text: "Customize wallpaper photo frame", done: false }
    ]

    readonly property int completedCount: {
        var c = 0
        for (var i = 0; i < taskList.length; i++) {
            if (taskList[i].done) c++
        }
        return c
    }

    readonly property real progressRatio: taskList.length > 0 ? completedCount / taskList.length : 0

    // ─── Settings Persistence ───
    Process {
        id: loadSettingsProc
        command: ["sh", "-c", "cat ~/.config/quickshell/widget_settings.json 2>/dev/null || echo '{}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text)
                    if (data.todo) {
                        if (data.todo.scale !== undefined) root.scaleFactor = Math.max(0.5, Math.min(2.5, data.todo.scale))
                        var w = Math.round(280 * root.scaleFactor)
                        var h = Math.round(240 * root.scaleFactor)
                        if (data.todo.x !== undefined) root.posX = Math.max(10, Math.min(root.screenWidth - w - 10, data.todo.x))
                        if (data.todo.y !== undefined) root.posY = Math.max(10, Math.min(root.screenHeight - h - 10, data.todo.y))
                        if (data.todo.list && Array.isArray(data.todo.list) && data.todo.list.length > 0) {
                            root.taskList = data.todo.list
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
        var jsonStr = JSON.stringify(root.taskList).replace(/'/g, "'\\''")
        var script = "python3 -c 'import json, os; p=os.path.expanduser(\"~/.config/quickshell/widget_settings.json\"); d=json.load(open(p)) if os.path.exists(p) else {}; d[\"todo\"]={\"x\":" + Math.round(root.x) + ",\"y\":" + Math.round(root.y) + ",\"scale\":" + root.scaleFactor.toFixed(2) + ",\"list\":" + jsonStr + "}; open(p,\"w\").write(json.dumps(d,indent=2))'"
        saveSettingsProc.command = ["sh", "-c", script]
        saveSettingsProc.running = true
    }

    // ─── GTK3 Add Task Prompt Process ───
    Process {
        id: addTaskProc
        command: ["python3", "-c", "import gi; gi.require_version('Gtk', '3.0'); from gi.repository import Gtk; dialog=Gtk.MessageDialog(message_type=Gtk.MessageType.QUESTION, buttons=Gtk.ButtonsType.OK_CANCEL, text='Add New Task:'); entry=Gtk.Entry(); entry.set_placeholder_text('Enter task description...'); entry.show(); dialog.vbox.pack_end(entry, True, True, 8); res=dialog.run(); txt=entry.get_text().strip() if res==Gtk.ResponseType.OK else ''; dialog.destroy(); print(txt)"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var taskText = text.trim()
                if (taskText.length > 0) {
                    var list = root.taskList.slice()
                    list.push({ text: taskText, done: false })
                    root.taskList = list
                    root.saveSettings()
                }
            }
        }
    }

    Component.onCompleted: {
        loadSettingsProc.running = true
    }

    // Material 3 Palette
    readonly property color colBg: "#3A454B"
    readonly property color colBadgeBg: "#4D585F"
    readonly property color colAccent: "#C2E7FF"
    readonly property color colAccentGreen: "#D1E8DA"
    readonly property color colTextPrimary: "#FFFFFF"
    readonly property color colTextSecondary: "#B0BEC5"

    // ─── Scaled Visual Content ───
    Item {
        id: scaledContent
        width: 280
        height: 240
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
            antialiasing: true

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8

                // Header Row: Tasks Badge + Progress Pill + Add Button
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
                                color: root.colAccentGreen
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "TASKS"
                                color: root.colTextPrimary
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 0.6
                                font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                            }
                        }
                    }

                    Item {
                        width: Math.max(0, parent.width - parent.children[0].width - rightBtns.width)
                        height: 1
                    }

                    Row {
                        id: rightBtns
                        spacing: 8
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.completedCount + "/" + root.taskList.length
                            color: root.colTextSecondary
                            font.pixelSize: 11
                            font.bold: true
                            font.family: "Google Sans Flex, Google Sans, Inter, monospace"
                        }

                        // Add Task Pill Button
                        Rectangle {
                            width: 22
                            height: 22
                            radius: 11
                            color: root.colAccent
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
                                onClicked: addTaskProc.running = true
                            }
                        }
                    }
                }

                // Progress Bar
                Rectangle {
                    width: parent.width
                    height: 4
                    radius: 2
                    color: root.colBadgeBg
                    antialiasing: true

                    Rectangle {
                        width: Math.max(parent.radius * 2, parent.width * root.progressRatio)
                        height: parent.height
                        radius: parent.radius
                        color: root.progressRatio === 1.0 ? "#A2C9C2" : root.colAccent
                        antialiasing: true
                    }
                }

                // Task List Items Container
                ListView {
                    width: parent.width
                    height: 160
                    clip: true
                    spacing: 6
                    model: root.taskList

                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 32
                        radius: 16
                        color: root.colBadgeBg
                        antialiasing: true

                        Row {
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 8

                            // Checkbox Pill
                            Rectangle {
                                width: 20
                                height: 20
                                radius: 10
                                color: modelData.done ? root.colAccentGreen : "#2B353A"
                                anchors.verticalCenter: parent.verticalCenter
                                antialiasing: true

                                Text {
                                    anchors.centerIn: parent
                                    visible: modelData.done
                                    text: "✓"
                                    color: "#1E2A30"
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var list = root.taskList.slice()
                                        list[index] = { text: modelData.text, done: !modelData.done }
                                        root.taskList = list
                                        root.saveSettings()
                                    }
                                }
                            }

                            // Task Text
                            Text {
                                width: parent.width - 20 - 8 - 24
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.text
                                color: modelData.done ? "#88979E" : root.colTextPrimary
                                font.pixelSize: 11
                                font.strikeout: modelData.done
                                font.bold: !modelData.done
                                elide: Text.ElideRight
                                font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                            }

                            // Delete Single Task Button
                            Item {
                                width: 20
                                height: 20
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: "×"
                                    color: "#88979E"
                                    font.pixelSize: 14
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var list = root.taskList.slice()
                                        list.splice(index, 1)
                                        root.taskList = list
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
