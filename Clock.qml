import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property real screenWidth: 1920
    property real screenHeight: 1080

    // Position & sizing properties
    property real posX: 480
    property real posY: 100
    property real scaleFactor: 1.0
    property string clockStyle: "cookie" // "cookie", "nothing", "androidStacked", "digital"

    x: Math.max(10, Math.min(root.screenWidth - root.width - 10, posX))
    y: Math.max(10, Math.min(root.screenHeight - root.height - 10, posY))
    width: Math.round((clockStyle === "cookie" || clockStyle === "nothing" ? 320 : clockStyle === "androidStacked" ? 220 : 420) * scaleFactor)
    height: Math.round((clockStyle === "cookie" || clockStyle === "nothing" ? 320 : clockStyle === "androidStacked" ? 360 : 180) * scaleFactor)

    // ─── Settings Persistence ───
    Process {
        id: loadSettingsProc
        command: ["sh", "-c", "cat ~/.config/quickshell/widget_settings.json 2>/dev/null || echo '{}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text)
                    if (data.clock) {
                        if (data.clock.scale !== undefined) root.scaleFactor = Math.max(0.5, Math.min(2.5, data.clock.scale))
                        if (data.clock.style !== undefined) root.clockStyle = data.clock.style
                        var w = Math.round((root.clockStyle === "cookie" || root.clockStyle === "nothing" ? 320 : root.clockStyle === "androidStacked" ? 220 : 420) * root.scaleFactor)
                        var h = Math.round((root.clockStyle === "cookie" || root.clockStyle === "nothing" ? 320 : root.clockStyle === "androidStacked" ? 360 : 180) * root.scaleFactor)
                        if (data.clock.x !== undefined) root.posX = Math.max(10, Math.min(root.screenWidth - w - 10, data.clock.x))
                        if (data.clock.y !== undefined) root.posY = Math.max(10, Math.min(root.screenHeight - h - 10, data.clock.y))
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
        var script = "python3 -c 'import json, os; p=os.path.expanduser(\"~/.config/quickshell/widget_settings.json\"); d=json.load(open(p)) if os.path.exists(p) else {}; d[\"clock\"]={\"x\":" + Math.round(root.x) + ",\"y\":" + Math.round(root.y) + ",\"scale\":" + root.scaleFactor.toFixed(2) + ",\"style\":\"" + root.clockStyle + "\"}; open(p,\"w\").write(json.dumps(d,indent=2))'"
        saveSettingsProc.command = ["sh", "-c", script]
        saveSettingsProc.running = true
    }

    Component.onCompleted: {
        loadSettingsProc.running = true
    }

    // ─── Theme Palette ───
    readonly property color colCookieBg: "#3A454B"          // Organic Dark Slate Cookie Face
    readonly property color colCookieNumbers: "#45FFFFFF"     // Subtle Muted Face Numbers (12, 3, 6, 9)
    readonly property color colHands: "#E3ECE9"             // Soft Light Blue-White Hands
    readonly property color colPrimary: "#B5D2C2"          // Soft Sage Green Pastel
    readonly property color colPrimaryContainer: "#86A896"    // Deep Sage Pastel
    readonly property color colSecondary: "#D1E8DA"
    readonly property color colGlassBg: "#3B1B2621"
    readonly property color colNothingRed: "#D32F2F"        // Nothing OS Signature Red
    readonly property color colNothingDarkBg: "#18181B"      // Nothing OS Dark Matte Container

    // ─── Time & Date Properties ───
    property int hours: 0
    property int minutes: 0
    property int seconds: 0
    property real secondsSmooth: 0
    property string dayString: "13"
    property string monthString: "07"
    property string hours12String: "01"
    property string minutesString: "07"
    property string timeDigital: "00:00"

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var now = new Date()
            root.hours = now.getHours()
            root.minutes = now.getMinutes()
            root.seconds = now.getSeconds()

            var d = now.getDate()
            var m = now.getMonth() + 1
            root.dayString = d < 10 ? "0" + d : d.toString()
            root.monthString = m < 10 ? "0" + m : m.toString()

            var h12 = root.hours % 12 || 12
            var h12Str = h12 < 10 ? "0" + h12 : h12.toString()
            var mStr = root.minutes < 10 ? "0" + root.minutes : root.minutes.toString()

            root.hours12String = h12Str
            root.minutesString = mStr
            root.timeDigital = h12Str + ":" + mStr
        }
    }

    // ─── Smooth Hand & Seconds Orbit Sweep ───
    Timer {
        interval: 33
        running: root.clockStyle === "cookie" || root.clockStyle === "nothing"
        repeat: true
        onTriggered: {
            var now = new Date()
            var s = now.getSeconds() + now.getMilliseconds() / 1000.0
            var m = now.getMinutes() + s / 60.0
            var h = (now.getHours() % 12) + m / 60.0
            minuteHand.rotation = m * 6
            hourHand.rotation = h * 30
            nothingSecondHand.rotation = s * 6
            root.secondsSmooth = s
        }
    }

    // ─── Scaled Visual Content ───
    Item {
        id: scaledContent
        width: root.clockStyle === "cookie" || root.clockStyle === "nothing" ? 320 : root.clockStyle === "androidStacked" ? 220 : 420
        height: root.clockStyle === "cookie" || root.clockStyle === "nothing" ? 320 : root.clockStyle === "androidStacked" ? 360 : 180
        scale: root.scaleFactor
        transformOrigin: Item.TopLeft

        // ════════════════════════════════════════════════════
        // STYLE 1: Organic Rotating Cookie Clock
        // ════════════════════════════════════════════════════
        Item {
            anchors.fill: parent
            visible: root.clockStyle === "cookie"

            // Organic Wavy Canvas (Rotates COUNTER-CLOCKWISE, opposite to clockwise seconds orbit)
            Canvas {
                id: cookieCanvas
                anchors.centerIn: parent
                width: 290
                height: 290
                antialiasing: true

                RotationAnimation on rotation {
                    running: root.clockStyle === "cookie"
                    duration: 120000 // 120 seconds per full turn
                    from: 360
                    to: 0
                    loops: Animation.Infinite
                    easing.type: Easing.Linear
                }

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    var cx = width / 2
                    var cy = height / 2
                    var rOuter = 135
                    var rInner = 105
                    var lobes = 9

                    // Soft Drop Shadow
                    ctx.beginPath()
                    for (var a = 0; a <= 360; a += 1) {
                        var rad = a * Math.PI / 180
                        var wave = (Math.cos(lobes * rad) + 1.0) / 2.0
                        var r = rInner + (rOuter - rInner) * Math.pow(wave, 0.7)
                        var x = cx + r * Math.sin(rad)
                        var y = (cy + 4) - r * Math.cos(rad)
                        if (a === 0) ctx.moveTo(x, y)
                        else ctx.lineTo(x, y)
                    }
                    ctx.closePath()
                    ctx.fillStyle = "rgba(0, 0, 0, 0.28)"
                    ctx.fill()

                    // Main Organic Sine Cookie Face
                    ctx.beginPath()
                    for (var a2 = 0; a2 <= 360; a2 += 1) {
                        var rad2 = a2 * Math.PI / 180
                        var wave2 = (Math.cos(lobes * rad2) + 1.0) / 2.0
                        var r2 = rInner + (rOuter - rInner) * Math.pow(wave2, 0.7)
                        var x2 = cx + r2 * Math.sin(rad2)
                        var y2 = cy - r2 * Math.cos(rad2)
                        if (a2 === 0) ctx.moveTo(x2, y2)
                        else ctx.lineTo(x2, y2)
                    }
                    ctx.closePath()
                    ctx.fillStyle = root.colCookieBg
                    ctx.fill()
                }
            }

            // ─── Fixed Top-Left Pentagon Badge (Bigger, overlapping main clock slightly) ───
            Item {
                x: 42
                y: 30
                width: 58
                height: 58

                Canvas {
                    anchors.fill: parent
                    antialiasing: true
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.reset()
                        var cx = width / 2
                        var cy = height / 2
                        var r = 25

                        ctx.beginPath()
                        for (var i = 0; i < 5; i++) {
                            var angle = (i * 72 - 90) * Math.PI / 180
                            var px = cx + r * Math.cos(angle)
                            var py = cy + r * Math.sin(angle)
                            if (i === 0) ctx.moveTo(px, py)
                            else ctx.lineTo(px, py)
                        }
                        ctx.closePath()
                        ctx.fillStyle = root.colCookieBg
                        ctx.fill()
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: root.dayString
                    color: "#FFFFFF"
                    font.pixelSize: 20
                    font.bold: true
                    font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                }
            }

            // ─── Fixed Bottom-Right Capsule Badge (Bigger, overlapping main clock slightly) ───
            Rectangle {
                x: 224
                y: 232
                width: 60
                height: 38
                radius: 19
                color: root.colCookieBg
                antialiasing: true

                Text {
                    anchors.centerIn: parent
                    text: root.monthString
                    color: "#FFFFFF"
                    font.pixelSize: 20
                    font.bold: true
                    font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                }
            }

            // Static Dial Numbers (12, 3, 6, 9) - STAY FIXED
            Item {
                anchors.centerIn: parent
                width: 290
                height: 290

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 34
                    text: "12"
                    color: root.colCookieNumbers
                    font.pixelSize: 56
                    font.bold: true
                    font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    x: 218
                    text: "3"
                    color: root.colCookieNumbers
                    font.pixelSize: 56
                    font.bold: true
                    font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 196
                    text: "6"
                    color: root.colCookieNumbers
                    font.pixelSize: 56
                    font.bold: true
                    font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    x: 48
                    text: "9"
                    color: root.colCookieNumbers
                    font.pixelSize: 56
                    font.bold: true
                    font.family: "Google Sans Flex, Google Sans, Inter, sans-serif"
                }
            }

            // Clock Hands Dial & Clockwise Orbiting Seconds Circle
            Item {
                id: dialCenter
                anchors.centerIn: parent
                width: 320
                height: 320

                // Orbiting Seconds Circle
                Item {
                    anchors.centerIn: parent
                    width: 320
                    height: 320
                    rotation: root.secondsSmooth * 6

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 52
                        width: 15
                        height: 15
                        radius: 7.5
                        color: "#FFFFFF"
                        antialiasing: true
                    }
                }

                // Hour Hand Pill
                Item {
                    id: hourHand
                    anchors.centerIn: parent
                    width: 26
                    height: 320
                    rotation: 220
                    antialiasing: true

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.verticalCenter
                        anchors.bottomMargin: -13
                        width: 26
                        height: 78
                        radius: 13
                        color: root.colHands
                        antialiasing: true
                    }
                }

                // Minute Hand Pill
                Item {
                    id: minuteHand
                    anchors.centerIn: parent
                    width: 20
                    height: 320
                    rotation: 70
                    antialiasing: true

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.verticalCenter
                        anchors.bottomMargin: -10
                        width: 20
                        height: 108
                        radius: 10
                        color: root.colHands
                        antialiasing: true
                    }
                }

                // Center Cap Dot
                Rectangle {
                    anchors.centerIn: parent
                    width: 12
                    height: 12
                    radius: 6
                    color: root.colCookieBg
                    antialiasing: true
                }
            }
        }

        // ════════════════════════════════════════════════════
        // STYLE 2: Nothing OS Dot-Matrix / Red Accent Clock
        // ════════════════════════════════════════════════════
        Item {
            anchors.fill: parent
            visible: root.clockStyle === "nothing"

            // Dark Matte Container Face
            Rectangle {
                anchors.centerIn: parent
                width: 290
                height: 290
                radius: 145
                color: root.colNothingDarkBg
                border.width: 1.5
                border.color: "#27272A"
                antialiasing: true
            }

            // Outer Dot-Matrix Hour Ring
            Canvas {
                id: nothingMatrixCanvas
                anchors.centerIn: parent
                width: 290
                height: 290
                antialiasing: true

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    var cx = width / 2
                    var cy = height / 2
                    var r = 120

                    for (var i = 0; i < 60; i++) {
                        var angle = (i * 6 - 90) * Math.PI / 180
                        var x = cx + r * Math.cos(angle)
                        var y = cy + r * Math.sin(angle)
                        ctx.beginPath()
                        ctx.arc(x, y, i % 5 === 0 ? 3 : 1.5, 0, 2 * Math.PI)
                        ctx.fillStyle = i % 5 === 0 ? "#E4E4E7" : "#52525B"
                        ctx.fill()
                    }
                }
            }

            // Center Nothing OS Hands & Dot-Matrix Accents
            Item {
                anchors.centerIn: parent
                width: 290
                height: 290

                // Nothing OS Hour Hand
                Item {
                    anchors.centerIn: parent
                    width: 12
                    height: 290
                    rotation: (root.hours % 12 + root.minutes / 60.0) * 30
                    antialiasing: true

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.verticalCenter
                        width: 12
                        height: 65
                        radius: 6
                        color: "#FFFFFF"
                        antialiasing: true
                    }
                }

                // Nothing OS Minute Hand
                Item {
                    anchors.centerIn: parent
                    width: 8
                    height: 290
                    rotation: (root.minutes + root.seconds / 60.0) * 6
                    antialiasing: true

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.verticalCenter
                        width: 8
                        height: 95
                        radius: 4
                        color: "#E4E4E7"
                        antialiasing: true
                    }
                }

                // Nothing OS Signature Red Second Hand
                Item {
                    id: nothingSecondHand
                    anchors.centerIn: parent
                    width: 4
                    height: 290
                    rotation: 0
                    antialiasing: true

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.verticalCenter
                        width: 4
                        height: 105
                        radius: 2
                        color: root.colNothingRed
                        antialiasing: true
                    }
                }

                // Center Red Core Dot
                Rectangle {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    radius: 7
                    color: root.colNothingRed
                    border.width: 3
                    border.color: "#FFFFFF"
                    antialiasing: true
                }
            }
        }

        // ════════════════════════════════════════════════════
        // STYLE 3: Stacked 2-Line Expressive Desktop Clock
        // ════════════════════════════════════════════════════
        Item {
            anchors.fill: parent
            visible: root.clockStyle === "androidStacked"

            Rectangle {
                anchors.fill: parent
                color: root.colGlassBg
                radius: 40
                border.width: 0
                antialiasing: true
            }

            Column {
                anchors.centerIn: parent
                spacing: -18

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.hours12String
                    color: root.colPrimary
                    font.pixelSize: 110
                    font.bold: true
                    font.letterSpacing: -3
                    font.family: "Google Sans Clock, Google Sans, Space Grotesk, Inter, Roboto, sans-serif"
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.minutesString
                    color: root.colPrimaryContainer
                    font.pixelSize: 110
                    font.bold: true
                    font.letterSpacing: -3
                    font.family: "Google Sans Clock, Google Sans, Space Grotesk, Inter, Roboto, sans-serif"
                }
            }
        }

        // ════════════════════════════════════════════════════
        // STYLE 4: Soft Pill Horizontal Digital Clock
        // ════════════════════════════════════════════════════
        Rectangle {
            anchors.fill: parent
            visible: root.clockStyle === "digital"
            color: root.colGlassBg
            radius: 36
            border.width: 0
            antialiasing: true

            Text {
                anchors.centerIn: parent
                text: root.timeDigital
                color: root.colPrimary
                font.pixelSize: 84
                font.bold: true
                font.letterSpacing: -2
                font.family: "Google Sans Clock, Google Sans, Space Grotesk, Inter, Roboto, sans-serif"
            }
        }
    }

    // ─── Interactive MouseArea (Drag, Resize, Style Switch) ───
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

        onDoubleClicked: {
            if (root.clockStyle === "cookie") {
                root.clockStyle = "nothing"
            } else if (root.clockStyle === "nothing") {
                root.clockStyle = "androidStacked"
            } else if (root.clockStyle === "androidStacked") {
                root.clockStyle = "digital"
            } else {
                root.clockStyle = "cookie"
            }
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
}
