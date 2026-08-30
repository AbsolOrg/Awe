import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property real screenWidth: 1920
    property real screenHeight: 1080

    // Position & sizing properties
    property real posX: 400
    property real posY: 320
    property real scaleFactor: 0.9

    x: Math.max(10, Math.min(root.screenWidth - root.width - 10, posX))
    y: Math.max(10, Math.min(root.screenHeight - root.height - 10, posY))
    width: Math.round(260 * scaleFactor)
    height: Math.round(200 * scaleFactor)

    // Notes Data
    property var notesList: [
        { title: "Meeting Notes", body: "Plan Q3 Material 3 desktop widgets and animations.", color: "#2B353A" },
        { title: "Ideas", body: "Add smooth soundwave animations to media player.", color: "#323A2B" },
        { title: "Reminders", body: "Backup dotfiles and quickshell configs.", color: "#3B2E2B" }
    ]
    property int currentNoteIndex: 0

    // ─── Settings Persistence ───
    Process {
        id: loadSettingsProc
        command: ["sh", "-c", "cat ~/.config/quickshell/widget_settings.json 2>/dev/null || echo '{}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text)
                    if (data.notes) {
                        if (data.notes.scale !== undefined) root.scaleFactor = Math.max(0.5, Math.min(2.5, data.notes.scale))
                        var w = Math.round(260 * root.scaleFactor)
                        var h = Math.round(200 * root.scaleFactor)
                        if (data.notes.x !== undefined) root.posX = Math.max(10, Math.min(root.screenWidth - w - 10, data.notes.x))
                        if (data.notes.y !== undefined) root.posY = Math.max(10, Math.min(root.screenHeight - h - 10, data.notes.y))
                        if (data.notes.list && Array.isArray(data.notes.list) && data.notes.list.length > 0) {
                            root.notesList = data.notes.list
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
        var jsonStr = JSON.stringify(root.notesList).replace(/'/g, "'\\''")
        var script = "python3 -c 'import json, os; p=os.path.expanduser(\"~/.config/quickshell/widget_settings.json\"); d=json.load(open(p)) if os.path.exists(p) else {}; d[\"notes\"]={\"x\":" + Math.round(root.x) + ",\"y\":" + Math.round(root.y) + ",\"scale\":" + root.scaleFactor.toFixed(2) + ",\"list\":" + jsonStr + "}; open(p,\"w\").write(json.dumps(d,indent=2))'"
        saveSettingsProc.command = ["sh", "-c", script]
        saveSettingsProc.running = true
    }

    // ─── GTK3 Note Edit Prompt ───
    Process {
        id: editNoteProc
        command: ["python3", "-c", "import gi; gi.require_version('Gtk', '3.0'); from gi.repository import Gtk; dialog=Gtk.Dialog(title='Edit Quick Note', buttons=(Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL, Gtk.STOCK_OK, Gtk.ResponseType.OK)); vbox=dialog.get_content_area(); t_entry=Gtk.Entry(); t_entry.set_placeholder_text('Note Title'); b_view=Gtk.TextView(); b_view.set_wrap_mode(Gtk.WrapMode.WORD); b_buf=b_view.get_buffer(); vbox.pack_start(t_entry, False, False, 6); vbox.pack_start(b_view, True, True, 6); dialog.show_all(); res=dialog.run(); title=t_entry.get_text().strip(); start, end=b_buf.get_bounds(); body=b_buf.get_text(start, end, True).strip(); dialog.destroy(); print((title if title else 'Note') + ';;' + body if res==Gtk.ResponseType.OK else '')"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var line = text.trim()
                if (line.includes(";;")) {
                    var parts = line.split(";;")
                    var list = root.notesList.slice()
                    if (list[root.currentNoteIndex]) {
                        list[root.currentNoteIndex] = {
                            title: parts[0] || "Quick Note",
                            body: parts[1] || "",
                            color: list[root.currentNoteIndex].color || "#2B353A"
                        }
                    } else {
                        list.push({ title: parts[0], body: parts[1], color: "#2B353A" })
                    }
                    root.notesList = list
                    root.saveSettings()
                }
            }
        }
    }

    Component.onCompleted: {
        loadSettingsProc.running = true
    }

    // Material 3 Palette
    readonly property color colBadgeBg: "#4D585F"
    readonly property color colAccent: "#C2E7FF"
    readonly property color colTextPrimary: "#FFFFFF"
    readonly property color colTextSecondary: "#B0BEC5"

    property var currentNote: (root.notesList && root.notesList.length > root.currentNoteIndex) ? root.notesList[root.currentNoteIndex] : { title: "Memo", body: "Click to write a note...", color: "#2B353A" }

    // ─── Scaled Visual Content ───
    Item {
        id: scaledContent
        width: 260
        height: 200
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

        // Main Sticky Note Card
        Rectangle {
            anchors.fill: parent
            color: root.currentNote.color || "#2B353A"
            radius: 32
            border.color: "#4D585F"
            border.width: 1.5
            antialiasing: true

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8

                // Header Row: Badge + Note Switcher + Add Button
                Row {
                    width: parent.width

                    // Badge Pill
                    Rectangle {
                        height: 22
                        width: badgeRow.implicitWidth + 14
                        radius: 11
                        color: root.colBadgeBg
                        antialiasing: true

                        Row {
                            id: badgeRow
                            anchors.centerIn: parent
                            spacing: 5

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 6
                                height: 6
                                radius: 3
                                color: "#FFE082"
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "NOTES"
                                color: root.colTextPrimary
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 0.6
                                font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                            }
                        }
                    }

                    Item {
                        width: Math.max(0, parent.width - parent.children[0].width - ctrlRow.width)
                        height: 1
                    }

                    // Note Navigation Controls
                    Row {
                        id: ctrlRow
                        spacing: 6
                        anchors.verticalCenter: parent.verticalCenter

                        // Prev Note Button
                        Rectangle {
                            width: 20
                            height: 20
                            radius: 10
                            color: root.colBadgeBg
                            Text {
                                anchors.centerIn: parent
                                text: "‹"
                                color: "#FFFFFF"
                                font.pixelSize: 13
                                font.bold: true
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.notesList.length > 0) {
                                        root.currentNoteIndex = (root.currentNoteIndex - 1 + root.notesList.length) % root.notesList.length
                                    }
                                }
                            }
                        }

                        // Counter Text
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: (root.currentNoteIndex + 1) + "/" + Math.max(1, root.notesList.length)
                            color: root.colTextSecondary
                            font.pixelSize: 10
                            font.bold: true
                            font.family: "Google Sans Flex, Google Sans, Inter, monospace"
                        }

                        // Next Note Button
                        Rectangle {
                            width: 20
                            height: 20
                            radius: 10
                            color: root.colBadgeBg
                            Text {
                                anchors.centerIn: parent
                                text: "›"
                                color: "#FFFFFF"
                                font.pixelSize: 13
                                font.bold: true
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.notesList.length > 0) {
                                        root.currentNoteIndex = (root.currentNoteIndex + 1) % root.notesList.length
                                    }
                                }
                            }
                        }

                        // Add Note Button
                        Rectangle {
                            width: 20
                            height: 20
                            radius: 10
                            color: root.colAccent
                            Text {
                                anchors.centerIn: parent
                                text: "+"
                                color: "#1E2A30"
                                font.pixelSize: 13
                                font.bold: true
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var list = root.notesList.slice()
                                    list.push({ title: "New Memo", body: "Double-click to write...", color: "#2B353A" })
                                    root.notesList = list
                                    root.currentNoteIndex = list.length - 1
                                    root.saveSettings()
                                }
                            }
                        }
                    }
                }

                // Note Title
                Text {
                    text: root.currentNote.title || "Memo"
                    color: root.colTextPrimary
                    font.pixelSize: 15
                    font.bold: true
                    elide: Text.ElideRight
                    width: parent.width
                    font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                }

                // Note Body Text Container
                Rectangle {
                    width: parent.width
                    height: 100
                    radius: 18
                    color: "#20000000"
                    clip: true

                    Text {
                        anchors.fill: parent
                        anchors.margins: 10
                        text: root.currentNote.body || "Click to add note content..."
                        color: root.colTextSecondary
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                        elide: Text.ElideRight
                        font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onDoubleClicked: {
                            editNoteProc.running = true
                        }
                    }
                }

                // Bottom Row: Color Swatches & Delete
                Row {
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: ["#2B353A", "#323A2B", "#3B2E2B", "#2B333B"]
                        Rectangle {
                            width: 14
                            height: 14
                            radius: 7
                            color: modelData
                            border.color: (root.currentNote.color === modelData) ? "#FFFFFF" : "#555"
                            border.width: (root.currentNote.color === modelData) ? 2 : 1
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var list = root.notesList.slice()
                                    if (list[root.currentNoteIndex]) {
                                        list[root.currentNoteIndex].color = modelData
                                        root.notesList = list
                                        root.saveSettings()
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        width: Math.max(0, parent.width - 4 * 22 - delBtn.width)
                        height: 1
                    }

                    // Delete Note Button
                    Rectangle {
                        id: delBtn
                        width: 22
                        height: 22
                        radius: 11
                        color: root.colBadgeBg
                        Canvas {
                            anchors.fill: parent
                            antialiasing: true
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.reset()
                                var cx = width / 2
                                var cy = height / 2
                                ctx.strokeStyle = "#FFB4AB"
                                ctx.lineWidth = 1.4
                                ctx.beginPath()
                                ctx.moveTo(cx - 4, cy - 4)
                                ctx.lineTo(cx + 4, cy + 4)
                                ctx.moveTo(cx + 4, cy - 4)
                                ctx.lineTo(cx - 4, cy + 4)
                                ctx.stroke()
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.notesList.length > 1) {
                                    var list = root.notesList.slice()
                                    list.splice(root.currentNoteIndex, 1)
                                    root.notesList = list
                                    root.currentNoteIndex = Math.max(0, root.currentNoteIndex - 1)
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
