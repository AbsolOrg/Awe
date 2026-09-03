pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    visible: false

    // Active theme key
    property string currentTheme: "liquid_glass"

    // Theme metadata list for the UI picker
    readonly property var themes: [
        { id: "liquid_glass",    name: "Liquid Glass", icon: "🫧", desc: "Translucent frosted glass with specular gloss" },
        { id: "transparent",     name: "Transparent",  icon: "🪟", desc: "Minimal see-through floating aesthetic" },
        { id: "material",        name: "Material 3",   icon: "🎨", desc: "Original dark slate with Pixel cyan" },
        { id: "cyberpunk",       name: "Cyberpunk",    icon: "⚡", desc: "High-contrast neon glow on obsidian" },
        { id: "nordic",          name: "Nordic Frost", icon: "❄️", desc: "Arctic cold blue & snow storm palette" },
        { id: "oled",            name: "OLED Black",   icon: "🖤", desc: "100% pitch-black with crisp white typography" },
        { id: "warm_latte",      name: "Warm Latte",   icon: "☕", desc: "Cozy espresso & caramel with warm amber" },
        { id: "tokyo_night",     name: "Tokyo Night",  icon: "🌸", desc: "Midnight indigo-violet with lavender & cyan" },
        { id: "evergreen_moss",  name: "Evergreen",    icon: "🌲", desc: "Translucent forest green with phosphor telemetry" },
        { id: "aurora_prism",    name: "Aurora Prism", icon: "💎", desc: "Crystal glass with iridescent aurora reflections" }
    ]

    // Convenience booleans
    readonly property bool isGlass: currentTheme === "liquid_glass" || currentTheme === "evergreen_moss" || currentTheme === "aurora_prism"
    readonly property bool isTransparent: currentTheme === "transparent"
    readonly property bool isMaterial: currentTheme === "material"
    readonly property bool isCyberpunk: currentTheme === "cyberpunk"
    readonly property bool isNordic: currentTheme === "nordic"
    readonly property bool isOled: currentTheme === "oled"
    readonly property bool isLatte: currentTheme === "warm_latte"
    readonly property bool isTokyo: currentTheme === "tokyo_night"
    readonly property bool isEvergreen: currentTheme === "evergreen_moss"
    readonly property bool isAurora: currentTheme === "aurora_prism"

    // ─── Dynamic Palette Properties ───
    // Primary Panel Background
    readonly property color colBg: {
        switch (currentTheme) {
            case "liquid_glass":   return "#80141B24"
            case "transparent":    return "#260B0E14"
            case "cyberpunk":      return "#0A0B10"
            case "nordic":         return "#2E3440"
            case "oled":           return "#000000"
            case "warm_latte":     return "#1E1A16"
            case "tokyo_night":    return "#1A1B26"
            case "evergreen_moss": return "#8A0C1A12"
            case "aurora_prism":   return "#78161826"
            case "material":
            default:               return "#232D33"
        }
    }

    // Inner Sub-Card / Tile Background
    readonly property color colBgTile: {
        switch (currentTheme) {
            case "liquid_glass":   return "#8C1B2430"
            case "transparent":    return "#33141C26"
            case "cyberpunk":      return "#121420"
            case "nordic":         return "#3B4252"
            case "oled":           return "#0D0D0D"
            case "warm_latte":     return "#2D251E"
            case "tokyo_night":    return "#24283B"
            case "evergreen_moss": return "#99112419"
            case "aurora_prism":   return "#8C1E2033"
            case "material":
            default:               return "#3A454B"
        }
    }

    // Pill / Button / Badge Background
    readonly property color colPillBg: {
        switch (currentTheme) {
            case "liquid_glass":   return "#99263445"
            case "transparent":    return "#4D212C3B"
            case "cyberpunk":      return "#1D2032"
            case "nordic":         return "#434C5E"
            case "oled":           return "#1A1A1A"
            case "warm_latte":     return "#3D3228"
            case "tokyo_night":    return "#2F354F"
            case "evergreen_moss": return "#A6183324"
            case "aurora_prism":   return "#992B2E48"
            case "material":
            default:               return "#303B42"
        }
    }

    // Main Accent Color
    readonly property color colAccent: {
        switch (currentTheme) {
            case "liquid_glass":   return "#7DD3FC"
            case "transparent":    return "#38BDF8"
            case "cyberpunk":      return "#00FFE0"
            case "nordic":         return "#88C0D0"
            case "oled":           return "#FFFFFF"
            case "warm_latte":     return "#F59E0B"
            case "tokyo_night":    return "#7AA2F7"
            case "evergreen_moss": return "#22C55E"
            case "aurora_prism":   return "#E879F9"
            case "material":
            default:               return "#C2E7FF"
        }
    }

    // Secondary / Positive Accent (Green)
    readonly property color colAccentGreen: {
        switch (currentTheme) {
            case "liquid_glass":   return "#34D399"
            case "transparent":    return "#4ADE80"
            case "cyberpunk":      return "#39FF14"
            case "nordic":         return "#A3BE8C"
            case "oled":           return "#4ADE80"
            case "warm_latte":     return "#84CC16"
            case "tokyo_night":    return "#73DACA"
            case "evergreen_moss": return "#86EFAC"
            case "aurora_prism":   return "#34D399"
            case "material":
            default:               return "#A2C9C2"
        }
    }

    // Warm / Alert Accent
    readonly property color colAccentWarm: {
        switch (currentTheme) {
            case "liquid_glass":   return "#FB7185"
            case "transparent":    return "#F43F5E"
            case "cyberpunk":      return "#FF007F"
            case "nordic":         return "#BF616A"
            case "oled":           return "#F87171"
            case "warm_latte":     return "#E07A5F"
            case "tokyo_night":    return "#F7768E"
            case "evergreen_moss": return "#FB923C"
            case "aurora_prism":   return "#FB7185"
            case "material":
            default:               return "#FFB4AB"
        }
    }

    // Warning / Yellow Accent
    readonly property color colAccentWarning: {
        switch (currentTheme) {
            case "liquid_glass":   return "#FCD34D"
            case "transparent":    return "#FBBF24"
            case "cyberpunk":      return "#FFE600"
            case "nordic":         return "#EBCB8B"
            case "oled":           return "#FBBF24"
            case "warm_latte":     return "#FBBF24"
            case "tokyo_night":    return "#E0AF68"
            case "evergreen_moss": return "#FACC15"
            case "aurora_prism":   return "#38BDF8"
            case "material":
            default:               return "#FFD54F"
        }
    }

    // Primary Text Color
    readonly property color colTextPrimary: {
        switch (currentTheme) {
            case "nordic":         return "#ECEFF4"
            case "warm_latte":     return "#FDF8F5"
            case "tokyo_night":    return "#C0CAF5"
            case "evergreen_moss": return "#ECFDF5"
            case "aurora_prism":   return "#F5F3FF"
            default:               return "#FFFFFF"
        }
    }

    // Secondary Text Color
    readonly property color colTextSecondary: {
        switch (currentTheme) {
            case "liquid_glass":   return "#B0C4D4"
            case "transparent":    return "#94A3B8"
            case "cyberpunk":      return "#8894B8"
            case "nordic":         return "#D8DEE9"
            case "oled":           return "#A3A3A3"
            case "warm_latte":     return "#C4B5A5"
            case "tokyo_night":    return "#7982A9"
            case "evergreen_moss": return "#86EFAC"
            case "aurora_prism":   return "#C4B5FD"
            case "material":
            default:               return "#9CA8AC"
        }
    }

    // Border Color
    readonly property color borderColor: {
        switch (currentTheme) {
            case "liquid_glass":   return "#40FFFFFF"
            case "transparent":    return "#1AFFFFFF"
            case "cyberpunk":      return "#6600FFE0"
            case "nordic":         return "#26D8DEE9"
            case "oled":           return "#333333"
            case "warm_latte":     return "#33F59E0B"
            case "tokyo_night":    return "#38BB9AF7"
            case "evergreen_moss": return "#4D22C55E"
            case "aurora_prism":   return "#5CE879F9"
            case "material":
            default:               return "#24FFFFFF"
        }
    }

    // Border Width
    readonly property real borderWidth: {
        switch (currentTheme) {
            case "liquid_glass":   return 1.5
            case "cyberpunk":      return 1.5
            case "aurora_prism":   return 1.5
            case "evergreen_moss": return 1.2
            case "tokyo_night":    return 1.2
            case "transparent":    return 1.0
            default:               return 1.0
        }
    }

    // Specular Glass Top Highlight Gradient
    readonly property color glassGloss: {
        switch (currentTheme) {
            case "liquid_glass":   return "#2EFFFFFF"
            case "aurora_prism":   return "#3DF472B6"
            case "evergreen_moss": return "#2622C55E"
            case "tokyo_night":    return "#20BB9AF7"
            case "warm_latte":     return "#12F59E0B"
            case "transparent":    return "#12FFFFFF"
            default:               return "transparent"
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
                    if (data.manager && data.manager.theme) {
                        root.currentTheme = data.manager.theme
                    }
                } catch (e) {}
            }
        }
    }

    Process {
        id: saveSettingsProc
        running: false
    }

    function setTheme(newTheme) {
        root.currentTheme = newTheme
        var script = "python3 -c 'import json, os; p=os.path.expanduser(\"~/.config/quickshell/widget_settings.json\"); d=json.load(open(p)) if os.path.exists(p) else {}; d.setdefault(\"manager\", {})[\"theme\"]=\"" + newTheme + "\"; open(p,\"w\").write(json.dumps(d,indent=2))'"
        saveSettingsProc.command = ["sh", "-c", script]
        saveSettingsProc.running = true
    }

    // Watcher to keep theme in sync across multiple monitors or processes
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            if (!loadSettingsProc.running && !saveSettingsProc.running) {
                loadSettingsProc.running = true
            }
        }
    }

    Component.onCompleted: {
        loadSettingsProc.running = true
    }
}
