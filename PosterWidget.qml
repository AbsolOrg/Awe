import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property real screenWidth: 1920
    property real screenHeight: 1080

    // Position & sizing properties
    property real posX: 400
    property real posY: 480
    property real scaleFactor: 0.85

    x: Math.max(10, Math.min(root.screenWidth - root.width - 10, posX))
    y: Math.max(10, Math.min(root.screenHeight - root.height - 10, posY))
    width: Math.round(200 * scaleFactor)
    height: Math.round(200 * scaleFactor)

    // User customized image path, temp preview path, and shape index
    property string imagePath: ""
    property string tempPathInput: ""
    property int shapeIndex: 0
    property bool showPathDialog: false

    // ─── Settings Persistence ───
    Process {
        id: loadSettingsProc
        command: ["sh", "-c", "cat ~/.config/quickshell/widget_settings.json 2>/dev/null || echo '{}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text)
                    if (data.poster) {
                        if (data.poster.scale !== undefined) root.scaleFactor = Math.max(0.5, Math.min(2.5, data.poster.scale))
                        var w = Math.round(200 * root.scaleFactor)
                        var h = Math.round(200 * root.scaleFactor)
                        if (data.poster.x !== undefined) root.posX = Math.max(10, Math.min(root.screenWidth - w - 10, data.poster.x))
                        if (data.poster.y !== undefined) root.posY = Math.max(10, Math.min(root.screenHeight - h - 10, data.poster.y))
                        if (data.poster.imagePath !== undefined) root.imagePath = data.poster.imagePath
                        if (data.poster.shapeIndex !== undefined) root.shapeIndex = data.poster.shapeIndex
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
        var safePath = root.imagePath.replace(/'/g, "'\\''")
        var script = "python3 -c 'import json, os; p=os.path.expanduser(\"~/.config/quickshell/widget_settings.json\"); d=json.load(open(p)) if os.path.exists(p) else {}; d[\"poster\"]={\"x\":" + Math.round(root.x) + ",\"y\":" + Math.round(root.y) + ",\"scale\":" + root.scaleFactor.toFixed(2) + ",\"imagePath\":\"" + safePath + "\",\"shapeIndex\":" + root.shapeIndex + "}; open(p,\"w\").write(json.dumps(d,indent=2))'"
        saveSettingsProc.command = ["sh", "-c", script]
        saveSettingsProc.running = true
    }

    // Process to ask user for path / file via Zenity / Python GUI prompt on right-click option
    Process {
        id: pathPromptProc
        command: ["python3", "-c", "import tkinter as tk, tkinter.filedialog as fd, tkinter.simpledialog as sd; root=tk.Tk(); root.withdraw(); root.attributes('-topmost', True); path=sd.askstring('Image Path', 'Paste image file path or URL:'); print(path if path else '')"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var selected = text.trim()
                if (selected.length > 0) {
                    root.tempPathInput = selected
                    root.showPathDialog = true
                }
            }
        }
    }

    // Process to open standard file chooser
    Process {
        id: pickerProc
        command: ["python3", "-c", "import tkinter as tk, tkinter.filedialog as fd; root=tk.Tk(); root.withdraw(); root.attributes('-topmost', True); path=fd.askopenfilename(title='Select Image for Frame', filetypes=[('Images', '*.png *.jpg *.jpeg *.webp *.bmp *.gif')]); print(path if path else '')"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var selected = text.trim()
                if (selected.length > 0) {
                    root.tempPathInput = selected
                    root.showPathDialog = true
                }
            }
        }
    }

    Component.onCompleted: {
        loadSettingsProc.running = true
    }

    // ─── Smooth / Curved Shapes ───
    property var shapeNames: [
        "circle", "squircle", "stadium_h", "arch",
        "semicircle_top", "ellipse", "pebble", "pillow",
        "flower_4", "scallop_8", "clover_4", "badge_4",
        "pill_v", "heart"
    ]

    function drawShapePath(ctx, shapeType, w, h) {
        var cx = w / 2
        var cy = h / 2
        var r = Math.min(w, h) / 2 - 2

        ctx.beginPath()

        if (shapeType === "circle") {
            ctx.arc(cx, cy, r, 0, Math.PI * 2)
        } else if (shapeType === "squircle") {
            var radius = r * 0.45
            ctx.moveTo(cx - r + radius, cy - r)
            ctx.lineTo(cx + r - radius, cy - r)
            ctx.quadraticCurveTo(cx + r, cy - r, cx + r, cy - r + radius)
            ctx.lineTo(cx + r, cy + r - radius)
            ctx.quadraticCurveTo(cx + r, cy + r, cx + r - radius, cy + r)
            ctx.lineTo(cx - r + radius, cy + r)
            ctx.quadraticCurveTo(cx - r, cy + r, cx - r, cy + r - radius)
            ctx.lineTo(cx - r, cy - r + radius)
            ctx.quadraticCurveTo(cx - r, cy - r, cx - r + radius, cy - r)
        } else if (shapeType === "stadium_h") {
            var rx = r
            var ry = r * 0.65
            ctx.moveTo(cx - rx + ry, cy - ry)
            ctx.lineTo(cx + rx - ry, cy - ry)
            ctx.arc(cx + rx - ry, cy, ry, -Math.PI / 2, Math.PI / 2)
            ctx.lineTo(cx - rx + ry, cy + ry)
            ctx.arc(cx - rx + ry, cy, ry, Math.PI / 2, 3 * Math.PI / 2)
        } else if (shapeType === "arch") {
            ctx.moveTo(cx - r, cy + r)
            ctx.lineTo(cx + r, cy + r)
            ctx.lineTo(cx + r, cy)
            ctx.arc(cx, cy, r, 0, Math.PI, true)
            ctx.lineTo(cx - r, cy + r)
        } else if (shapeType === "semicircle_top") {
            ctx.moveTo(cx - r, cy + r * 0.3)
            ctx.arc(cx, cy + r * 0.3, r, Math.PI, 0, false)
            ctx.lineTo(cx - r, cy + r * 0.3)
        } else if (shapeType === "ellipse") {
            ctx.ellipse(cx - r, cy - r * 0.65, r * 2, r * 1.3)
        } else if (shapeType === "pebble") {
            ctx.moveTo(cx - r * 0.8, cy - r * 0.5)
            ctx.bezierCurveTo(cx - r, cy - r, cx + r * 0.2, cy - r, cx + r * 0.9, cy - r * 0.4)
            ctx.bezierCurveTo(cx + r * 1.1, cy, cx + r * 0.8, cy + r * 0.9, cx, cy + r)
            ctx.bezierCurveTo(cx - r * 0.9, cy + r * 0.9, cx - r * 1.1, cy, cx - r * 0.8, cy - r * 0.5)
        } else if (shapeType === "pillow") {
            ctx.moveTo(cx, cy - r)
            ctx.quadraticCurveTo(cx + r * 0.8, cy - r * 0.8, cx + r, cy)
            ctx.quadraticCurveTo(cx + r * 0.8, cy + r * 0.8, cx, cy + r)
            ctx.quadraticCurveTo(cx - r * 0.8, cy + r * 0.8, cx - r, cy)
            ctx.quadraticCurveTo(cx - r * 0.8, cy - r * 0.8, cx, cy - r)
        } else if (shapeType === "scallop_8") {
            var teeth = 8
            var rInner = r * 0.82
            for (var a = 0; a <= 360; a += 2) {
                var rad = a * Math.PI / 180
                var wave = (Math.cos(teeth * rad) + 1.0) / 2.0
                var radiusVal = rInner + (r - rInner) * wave
                var x = cx + radiusVal * Math.sin(rad)
                var y = cy - radiusVal * Math.cos(rad)
                if (a === 0) ctx.moveTo(x, y)
                else ctx.lineTo(x, y)
            }
        } else if (shapeType === "flower_4" || shapeType === "clover_4") {
            var rIn = r * 0.65
            for (var fl = 0; fl <= 360; fl += 3) {
                var flRad = fl * Math.PI / 180
                var flR = rIn + (r - rIn) * (Math.cos(4 * flRad) + 1.0) / 2.0
                var fx = cx + flR * Math.sin(flRad)
                var fy = cy - flR * Math.cos(flRad)
                if (fl === 0) ctx.moveTo(fx, fy)
                else ctx.lineTo(fx, fy)
            }
        } else if (shapeType === "badge_4") {
            for (var bg = 0; bg <= 360; bg += 3) {
                var bgRad = bg * Math.PI / 180
                var bgR = r * 0.75 + r * 0.25 * Math.abs(Math.sin(2 * bgRad))
                var bx = cx + bgR * Math.sin(bgRad)
                var by = cy - bgR * Math.cos(bgRad)
                if (bg === 0) ctx.moveTo(bx, by)
                else ctx.lineTo(bx, by)
            }
        } else if (shapeType === "pill_v") {
            var pvy = r
            var pvx = r * 0.55
            ctx.moveTo(cx - pvx, cy - pvy + pvx)
            ctx.arc(cx, cy - pvy + pvx, pvx, Math.PI, 0, false)
            ctx.lineTo(cx + pvx, cy + pvy - pvx)
            ctx.arc(cx, cy + pvy - pvx, pvx, 0, Math.PI, false)
            ctx.lineTo(cx - pvx, cy - pvy + pvx)
        } else if (shapeType === "heart") {
            ctx.moveTo(cx, cy + r * 0.75)
            ctx.bezierCurveTo(cx - r * 1.1, cy + r * 0.2, cx - r * 1.1, cy - r * 0.7, cx, cy - r * 0.35)
            ctx.bezierCurveTo(cx + r * 1.1, cy - r * 0.7, cx + r * 1.1, cy + r * 0.2, cx, cy + r * 0.75)
        } else {
            ctx.arc(cx, cy, r, 0, Math.PI * 2)
        }

        ctx.closePath()
    }

    // Hidden source image component
    Image {
        id: sourceImage
        source: root.imagePath
        visible: false
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        onStatusChanged: {
            shapeCanvas.requestPaint()
        }
    }

    // Temp image preview for confirmation dialog
    Image {
        id: tempPreviewImage
        source: root.tempPathInput
        visible: false
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    // ─── Scaled Visual Content ───
    Item {
        id: scaledContent
        width: 200
        height: 200
        scale: root.scaleFactor
        transformOrigin: Item.TopLeft

        Canvas {
            id: shapeCanvas
            anchors.fill: parent
            antialiasing: true

            Connections {
                target: root
                function onImagePathChanged() { shapeCanvas.requestPaint() }
                function onShapeIndexChanged() { shapeCanvas.requestPaint() }
            }

            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()

                var currentShape = root.shapeNames[root.shapeIndex % root.shapeNames.length]

                // Clip path to current shape
                root.drawShapePath(ctx, currentShape, width, height)
                ctx.clip()

                if (sourceImage.status === Image.Ready && root.imagePath.length > 0) {
                    // Draw custom image filled inside shape
                    ctx.drawImage(sourceImage, 0, 0, width, height)
                } else {
                    // Placeholder material style fill when no image selected
                    var grad = ctx.createLinearGradient(0, 0, width, height)
                    grad.addColorStop(0, "#3D484E")
                    grad.addColorStop(1, "#253035")
                    ctx.fillStyle = grad
                    ctx.fill()

                    // Text inside shape
                    ctx.fillStyle = "#A2C9C2"
                    ctx.font = "bold 12px 'Google Sans', sans-serif"
                    ctx.textAlign = "center"
                    ctx.textBaseline = "middle"
                    ctx.fillText("Right-click for Path / Pic", width / 2, height / 2 - 8)
                    ctx.fillStyle = "#A0ACAC"
                    ctx.font = "11px 'Google Sans', sans-serif"
                    ctx.fillText("Double-tap for Shape", width / 2, height / 2 + 12)
                }
            }
        }

        // Confirmation / Adjustment Dialog Overlay before setting
        Rectangle {
            id: pathConfirmOverlay
            visible: root.showPathDialog
            anchors.fill: parent
            radius: 24
            color: "#1E2A30"
            border.color: "#3D484E"
            border.width: 2
            z: 100

            Column {
                anchors.centerIn: parent
                spacing: 8
                width: parent.width - 20

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Set Image Path?"
                    color: "#FFFFFF"
                    font.pixelSize: 13
                    font.bold: true
                    font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.tempPathInput.length > 25 ? "..." + root.tempPathInput.slice(-22) : root.tempPathInput
                    color: "#A0ACAC"
                    font.pixelSize: 10
                    elide: Text.ElideMiddle
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    font.family: "Google Sans Flex, Google Sans, Inter, monospace"
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10

                    Rectangle {
                        width: 70
                        height: 28
                        radius: 14
                        color: "#C2E7FF"

                        Text {
                            anchors.centerIn: parent
                            text: "Set Pic"
                            color: "#1E2A30"
                            font.pixelSize: 11
                            font.bold: true
                            font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.imagePath = root.tempPathInput
                                root.showPathDialog = false
                                root.saveSettings()
                            }
                        }
                    }

                    Rectangle {
                        width: 70
                        height: 28
                        radius: 14
                        color: "#3D484E"

                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: "#FFFFFF"
                            font.pixelSize: 11
                            font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.showPathDialog = false
                            }
                        }
                    }
                }
            }
        }
    }

    // Timer to differentiate single click vs double tap
    Timer {
        id: singleClickTimer
        interval: 220
        repeat: false
        onTriggered: {
            pickerProc.running = true
        }
    }

    // ─── Mouse Handling ───
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        drag.target: root
        drag.axis: Drag.XAndYAxis
        drag.minimumX: 10
        drag.maximumX: Math.max(10, root.screenWidth - root.width - 10)
        drag.minimumY: 10
        drag.maximumY: Math.max(10, root.screenHeight - root.height - 10)
        cursorShape: drag.active ? Qt.ClosedHandCursor : (containsMouse ? Qt.OpenHandCursor : Qt.ArrowCursor)

        onDoubleClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                singleClickTimer.stop()
                root.shapeIndex = (root.shapeIndex + 1) % root.shapeNames.length
                root.saveSettings()
            }
        }

        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                singleClickTimer.stop()
                pathPromptProc.running = true
            } else if (mouse.button === Qt.LeftButton) {
                singleClickTimer.start()
            }
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
