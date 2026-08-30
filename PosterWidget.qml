import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io

Item {
    id: root
    property real screenWidth: 1920
    property real screenHeight: 1080

    // Position & sizing properties
    property real posX: 40
    property real posY: 40
    property real scaleFactor: 0.85

    x: Math.max(10, Math.min(root.screenWidth - root.width - 10, posX))
    y: Math.max(10, Math.min(root.screenHeight - root.height - 10, posY))
    width: Math.round(210 * scaleFactor)
    height: Math.round(210 * scaleFactor)

    // User customized image/GIF path and shape index
    property string imagePath: ""
    property int shapeIndex: 1

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
                        var size = Math.round(210 * root.scaleFactor)
                        if (data.poster.x !== undefined) root.posX = Math.max(10, Math.min(root.screenWidth - size - 10, data.poster.x))
                        if (data.poster.y !== undefined) root.posY = Math.max(10, Math.min(root.screenHeight - size - 10, data.poster.y))
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

    // ─── GTK3 File Chooser Process ───
    Process {
        id: pickerProc
        command: ["python3", "-c", "import gi; gi.require_version('Gtk', '3.0'); from gi.repository import Gtk; dialog=Gtk.FileChooserDialog(title='Select Image / GIF for Poster', action=Gtk.FileChooserAction.OPEN); dialog.add_buttons(Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL, Gtk.STOCK_OPEN, Gtk.ResponseType.OK); f=Gtk.FileFilter(); f.set_name('Images & GIFs (*.gif, *.png, *.jpg, *.jpeg, *.webp)'); f.add_mime_type('image/gif'); f.add_mime_type('image/png'); f.add_mime_type('image/jpeg'); f.add_mime_type('image/webp'); dialog.add_filter(f); res=dialog.run(); path=dialog.get_filename() if res==Gtk.ResponseType.OK else ''; dialog.destroy(); print(path if path else '')"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var selected = text.trim()
                if (selected.length > 0) {
                    root.imagePath = selected
                    root.saveSettings()
                }
            }
        }
    }

    Component.onCompleted: {
        loadSettingsProc.running = true
    }

    // ─── Material 3 Organic Shape Profiles ───
    property var shapeNames: [
        "squircle", "arch", "scallop_12", "flower_4",
        "pebble", "pill_v", "circle",
        "pillow", "heart", "stadium_h"
    ]

    function drawShapePath(ctx, shapeType, w, h) {
        var cx = w / 2
        var cy = h / 2
        var r = Math.min(w, h) / 2 - 4

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
        } else if (shapeType === "arch") {
            ctx.moveTo(cx - r, cy + r * 0.9)
            ctx.lineTo(cx + r, cy + r * 0.9)
            ctx.lineTo(cx + r, cy - r * 0.1)
            ctx.arc(cx, cy - r * 0.1, r, 0, Math.PI, true)
            ctx.lineTo(cx - r, cy + r * 0.9)
        } else if (shapeType === "scallop_12") {
            var teeth = 12
            var rInner = r * 0.85
            for (var a = 0; a <= 360; a += 2) {
                var rad = a * Math.PI / 180
                var wave = (Math.cos(teeth * rad) + 1.0) / 2.0
                var radiusVal = rInner + (r - rInner) * wave
                var x = cx + radiusVal * Math.sin(rad)
                var y = cy - radiusVal * Math.cos(rad)
                if (a === 0) ctx.moveTo(x, y)
                else ctx.lineTo(x, y)
            }
        } else if (shapeType === "flower_4") {
            var rIn = r * 0.68
            for (var fl = 0; fl <= 360; fl += 2) {
                var flRad = fl * Math.PI / 180
                var flR = rIn + (r - rIn) * (Math.cos(4 * flRad) + 1.0) / 2.0
                var fx = cx + flR * Math.sin(flRad)
                var fy = cy - flR * Math.cos(flRad)
                if (fl === 0) ctx.moveTo(fx, fy)
                else ctx.lineTo(fx, fy)
            }
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
        } else if (shapeType === "pill_v") {
            var pvy = r
            var pvx = r * 0.65
            ctx.moveTo(cx - pvx, cy - pvy + pvx)
            ctx.arc(cx, cy - pvy + pvx, pvx, Math.PI, 0, false)
            ctx.lineTo(cx + pvx, cy + pvy - pvx)
            ctx.arc(cx, cy + pvy - pvx, pvx, 0, Math.PI, false)
            ctx.lineTo(cx - pvx, cy - pvy + pvx)
        } else if (shapeType === "stadium_h") {
            var rx = r
            var ry = r * 0.65
            ctx.moveTo(cx - rx + ry, cy - ry)
            ctx.lineTo(cx + rx - ry, cy - ry)
            ctx.arc(cx + rx - ry, cy, ry, -Math.PI / 2, Math.PI / 2)
            ctx.lineTo(cx - rx + ry, cy + ry)
            ctx.arc(cx - rx + ry, cy, ry, Math.PI / 2, 3 * Math.PI / 2)
        } else if (shapeType === "heart") {
            ctx.moveTo(cx, cy + r * 0.75)
            ctx.bezierCurveTo(cx - r * 1.1, cy + r * 0.2, cx - r * 1.1, cy - r * 0.7, cx, cy - r * 0.35)
            ctx.bezierCurveTo(cx + r * 1.1, cy - r * 0.7, cx + r * 1.1, cy + r * 0.2, cx, cy + r * 0.75)
        } else {
            ctx.arc(cx, cy, r, 0, Math.PI * 2)
        }

        ctx.closePath()
    }

    // ─── Scaled Visual Content (PURE ORGANIC SHAPE, ZERO TEXT, GIF SUPPORT) ───
    Item {
        id: scaledContent
        width: 210
        height: 210
        scale: root.scaleFactor
        transformOrigin: Item.TopLeft

        // 1. Soft Ambient Drop Shadow Canvas
        Canvas {
            id: shadowCanvas
            anchors.fill: parent
            antialiasing: true

            Connections {
                target: root
                function onShapeIndexChanged() { shadowCanvas.requestPaint() }
            }

            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                var currentShape = root.shapeNames[root.shapeIndex % root.shapeNames.length]

                ctx.shadowColor = "rgba(0, 0, 0, 0.45)"
                ctx.shadowBlur = 14
                ctx.shadowOffsetX = 0
                ctx.shadowOffsetY = 5
                root.drawShapePath(ctx, currentShape, width, height)
                ctx.fillStyle = "#1E262B"
                ctx.fill()
            }
        }

        // 2. Animated Image / Static Image Element (Supports animated GIFs & static images)
        AnimatedImage {
            id: animImage
            anchors.fill: parent
            source: root.imagePath
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            playing: true
            visible: false
            onStatusChanged: {
                maskCanvas.requestPaint()
            }
        }

        // 3. Shape Mask Canvas for MultiEffect
        Canvas {
            id: maskCanvas
            anchors.fill: parent
            visible: false
            antialiasing: true

            Connections {
                target: root
                function onShapeIndexChanged() {
                    maskCanvas.requestPaint()
                    outlineCanvas.requestPaint()
                    placeholderCanvas.requestPaint()
                }
            }

            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                var currentShape = root.shapeNames[root.shapeIndex % root.shapeNames.length]
                root.drawShapePath(ctx, currentShape, width, height)
                ctx.fillStyle = "#FFFFFF"
                ctx.fill()
            }
        }

        // 4. MultiEffect: Clips the animated GIF / image to the exact organic shape
        MultiEffect {
            id: maskedEffect
            anchors.fill: parent
            source: animImage
            maskSource: maskCanvas
            maskEnabled: true
            visible: root.imagePath.length > 0 && animImage.status === Image.Ready
            antialiasing: true
        }

        // 5. Material 3 Fallback Placeholder (when no image is loaded)
        Canvas {
            id: placeholderCanvas
            anchors.fill: parent
            visible: root.imagePath.length === 0 || animImage.status !== Image.Ready
            antialiasing: true

            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                var currentShape = root.shapeNames[root.shapeIndex % root.shapeNames.length]

                // Clip to shape
                ctx.save()
                root.drawShapePath(ctx, currentShape, width, height)
                ctx.clip()

                // Gradient background
                var grad = ctx.createLinearGradient(0, 0, width, height)
                grad.addColorStop(0, "#3E494F")
                grad.addColorStop(1, "#222C31")
                ctx.fillStyle = grad
                ctx.fill()

                // Minimalist vector camera / frame graphic (zero text)
                var cx = width / 2
                var cy = height / 2
                ctx.strokeStyle = "#A2C9C2"
                ctx.lineWidth = 2
                ctx.strokeRect(cx - 24, cy - 20, 48, 36)

                ctx.beginPath()
                ctx.arc(cx - 10, cy - 10, 4, 0, Math.PI * 2)
                ctx.fillStyle = "#A2C9C2"
                ctx.fill()

                ctx.beginPath()
                ctx.moveTo(cx - 20, cy + 12)
                ctx.lineTo(cx - 6, cy - 2)
                ctx.lineTo(cx + 6, cy + 6)
                ctx.lineTo(cx + 20, cy + 12)
                ctx.closePath()
                ctx.fillStyle = "#A2C9C2"
                ctx.fill()
                ctx.restore()
            }
        }

        // 6. Smooth Contour Outline on Shape Edge
        Canvas {
            id: outlineCanvas
            anchors.fill: parent
            antialiasing: true

            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                var currentShape = root.shapeNames[root.shapeIndex % root.shapeNames.length]
                root.drawShapePath(ctx, currentShape, width, height)
                ctx.strokeStyle = "rgba(255, 255, 255, 0.16)"
                ctx.lineWidth = 1.5
                ctx.stroke()
            }
        }
    }

    // ─── Drag & Interaction MouseArea ───
    MouseArea {
        id: dragArea
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
                root.shapeIndex = (root.shapeIndex + 1) % root.shapeNames.length
                root.saveSettings()
            }
        }

        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                pickerProc.running = true
            } else if (mouse.button === Qt.LeftButton) {
                if (root.imagePath.length === 0) {
                    pickerProc.running = true
                }
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
