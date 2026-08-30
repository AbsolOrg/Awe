# Contributing to Awe

Thank you for your interest in contributing to Awe! We welcome contributions of new Material 3 widgets, design themes, performance enhancements, and bug fixes.

---

## Code Quality and Style Guidelines

### 1. No Emojis in Code
- Do not include emojis in QML source files, code comments, variable names, or property strings.
- Keep UI text and codebase comments professional and clean.

### 2. Color Format in QML
- Use 8-digit hexadecimal colors formatted as `#AARRGGBB` for transparent colors (e.g. `#1FFFFFFF` for 12% white opacity, `#24FFFFFF` for 14% opacity).
- Avoid CSS-style `rgba(r, g, b, a)` strings in QML property assignments as they can cause parser errors in certain Qt environments.

### 3. Font and Numeric Properties
- Always specify `font.pixelSize` as an integer (e.g. `font.pixelSize: 9`, not `8.5`).
- Ensure width, height, and coordinates scale properly using `scaleFactor`.

### 4. Event Layering and Input Masking
- When implementing draggable components, place the background dragging `MouseArea` underneath interactive buttons, inputs, and sliders in the z-stack.
- Always register new widgets in `shell.qml` inside the `mask: Region` block to maintain proper Wayland layershell desktop click-through.

---

## Adding a New Widget

When creating a new widget (e.g. `MyWidget.qml`), follow this standard structure:

### 1. Widget Structure Template

```qml
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property real screenWidth: 1920
    property real screenHeight: 1080

    // Coordinates and sizing
    property real posX: 100
    property real posY: 100
    property real scaleFactor: 0.88

    x: Math.max(10, Math.min(root.screenWidth - root.width - 10, posX))
    y: Math.max(10, Math.min(root.screenHeight - root.height - 10, posY))
    width: Math.round(280 * scaleFactor)
    height: Math.round(160 * scaleFactor)

    // Persistence loader
    Process {
        id: loadSettingsProc
        command: ["sh", "-c", "cat ~/.config/quickshell/widget_settings.json 2>/dev/null || echo '{}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text)
                    if (data.mywidget) {
                        if (data.mywidget.scale !== undefined) root.scaleFactor = Math.max(0.5, Math.min(2.5, data.mywidget.scale))
                        var w = Math.round(280 * root.scaleFactor)
                        var h = Math.round(160 * root.scaleFactor)
                        if (data.mywidget.x !== undefined) root.posX = Math.max(10, Math.min(root.screenWidth - w - 10, data.mywidget.x))
                        if (data.mywidget.y !== undefined) root.posY = Math.max(10, Math.min(root.screenHeight - h - 10, data.mywidget.y))
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
        var script = "python3 -c 'import json, os; p=os.path.expanduser(\"~/.config/quickshell/widget_settings.json\"); d=json.load(open(p)) if os.path.exists(p) else {}; d[\"mywidget\"]={\"x\":" + Math.round(root.x) + ",\"y\":" + Math.round(root.y) + ",\"scale\":" + root.scaleFactor.toFixed(2) + "}; open(p,\"w\").write(json.dumps(d,indent=2))'"
        saveSettingsProc.command = ["sh", "-c", script]
        saveSettingsProc.running = true
    }

    Component.onCompleted: {
        loadSettingsProc.running = true
    }

    // Material 3 Dark Palette
    readonly property color colBg: "#232D33"
    readonly property color colBadgeBg: "#303B42"
    readonly property color colAccent: "#C2E7FF"
    readonly property color colTextPrimary: "#FFFFFF"
    readonly property color colTextSecondary: "#9CA8AC"

    Item {
        id: scaledContent
        width: 280
        height: 160
        scale: root.scaleFactor
        transformOrigin: Item.TopLeft

        // Drag MouseArea
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

        // Card container
        Rectangle {
            anchors.fill: parent
            color: root.colBg
            radius: 32
            border.color: "#1FFFFFFF"
            border.width: 1.5
            antialiasing: true

            // Content elements
        }
    }
}
```

### 2. Registering in `shell.qml`
Add the new widget to:
1. The `mask: Region` definition:
   ```qml
   Region { item: myWidget }
   ```
2. The `widgetsLayer` hierarchy:
   ```qml
   MyWidget {
       id: myWidget
       visible: widgetManager.widgetVisibility["mywidget"] !== false
       screenWidth: desktopWindow.width
       screenHeight: desktopWindow.height
   }
   ```

### 3. Registering in `WidgetManager.qml`
1. Add the default visibility entry in `widgetVisibility`:
   ```qml
   mywidget: true
   ```
2. Add the item in the expanded toggle grid model:
   ```qml
   { id: "mywidget", label: "My Widget" }
   ```

### 4. Updating `widget_settings.json`
Add default coordinates and scale configuration to avoid overlapping with existing desktop widgets.

---

## Testing Your Changes

Before submitting a Pull Request, verify that your changes load cleanly without any warnings or errors:

```bash
quickshell -p /path/to/Awe
```

Ensure the terminal output logs:
```
INFO: Configuration Loaded
```
with zero `ERROR` or `WARN` messages.

---

## Submitting a Pull Request

1. Fork the repository and create a descriptive feature branch:
   ```bash
   git checkout -b feature/my-new-widget
   ```
2. Commit your changes with clear, concise commit messages.
3. Push to your branch and open a Pull Request against `main`.
