import QtQuick
import Quickshell
import Quickshell.Wayland

ShellRoot {
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: desktopWindow
            property var modelData
            screen: modelData

            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "quickshell:desktop-widgets"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "transparent"

            mask: Region {
                Region { item: widgetManager }
                Region { item: clockWidget }
                Region { item: sysinfoWidget }
                Region { item: calendarWidget }
                Region { item: mediaWidget }
                Region { item: weatherWidget }
                Region { item: posterWidget }
                Region { item: batteryWidget }
                Region { item: volumeWidget }
                Region { item: networkWidget }
                Region { item: notesWidget }
                Region { item: todoWidget }
                Region { item: timerWidget }
                Region { item: thermalWidget }
                Region { item: quoteWidget }
                Region { item: clipboardWidget }
                Region { item: cryptoWidget }
                Region { item: worldclockWidget }
                Region { item: gitWidget }
                Region { item: resourcewheelWidget }
            }

            Item {
                id: widgetsLayer
                anchors.fill: parent

                WidgetManager {
                    id: widgetManager
                    screenWidth: desktopWindow.width
                    screenHeight: desktopWindow.height
                }

                Clock {
                    id: clockWidget
                    visible: widgetManager.widgetVisibility["clock"] !== false
                    screenWidth: desktopWindow.width
                    screenHeight: desktopWindow.height
                }

                SystemInfo {
                    id: sysinfoWidget
                    visible: widgetManager.widgetVisibility["sysinfo"] !== false
                    screenWidth: desktopWindow.width
                    screenHeight: desktopWindow.height
                }

                CalendarWidget {
                    id: calendarWidget
                    visible: widgetManager.widgetVisibility["calendar"] !== false
                    screenWidth: desktopWindow.width
                    screenHeight: desktopWindow.height
                }

                MediaWidget {
                    id: mediaWidget
                    visible: widgetManager.widgetVisibility["media"] !== false
                    screenWidth: desktopWindow.width
                    screenHeight: desktopWindow.height
                }

                WeatherWidget {
                    id: weatherWidget
                    visible: widgetManager.widgetVisibility["weather"] !== false
                    screenWidth: desktopWindow.width
                    screenHeight: desktopWindow.height
                }

                PosterWidget {
                    id: posterWidget
                    visible: widgetManager.widgetVisibility["poster"] !== false
                    screenWidth: desktopWindow.width
                    screenHeight: desktopWindow.height
                }

                BatteryWidget {
                    id: batteryWidget
                    visible: widgetManager.widgetVisibility["battery"] !== false
                    screenWidth: desktopWindow.width
                    screenHeight: desktopWindow.height
                }

                VolumeBrightnessWidget {
                    id: volumeWidget
                    visible: widgetManager.widgetVisibility["quickcontrols"] !== false
                    screenWidth: desktopWindow.width
                    screenHeight: desktopWindow.height
                }

                NetworkWidget {
                    id: networkWidget
                    visible: widgetManager.widgetVisibility["network"] !== false
                    screenWidth: desktopWindow.width
                    screenHeight: desktopWindow.height
                }

                NotesWidget {
                    id: notesWidget
                    visible: widgetManager.widgetVisibility["notes"] !== false
                    screenWidth: desktopWindow.width
                    screenHeight: desktopWindow.height
                }

                TodoWidget {
                    id: todoWidget
                    visible: widgetManager.widgetVisibility["todo"] !== false
                    screenWidth: desktopWindow.width
                    screenHeight: desktopWindow.height
                }

                TimerWidget {
                    id: timerWidget
                    visible: widgetManager.widgetVisibility["timer"] !== false
                    screenWidth: desktopWindow.width
                    screenHeight: desktopWindow.height
                }

                ThermalWidget {
                    id: thermalWidget
                    visible: widgetManager.widgetVisibility["thermal"] !== false
                    screenWidth: desktopWindow.width
                    screenHeight: desktopWindow.height
                }

                QuoteWidget {
                    id: quoteWidget
                    visible: widgetManager.widgetVisibility["quote"] !== false
                    screenWidth: desktopWindow.width
                    screenHeight: desktopWindow.height
                }

                ClipboardWidget {
                    id: clipboardWidget
                    visible: widgetManager.widgetVisibility["clipboard"] !== false
                    screenWidth: desktopWindow.width
                    screenHeight: desktopWindow.height
                }

                CryptoWidget {
                    id: cryptoWidget
                    visible: widgetManager.widgetVisibility["crypto"] !== false
                    screenWidth: desktopWindow.width
                    screenHeight: desktopWindow.height
                }

                WorldClockWidget {
                    id: worldclockWidget
                    visible: widgetManager.widgetVisibility["worldclock"] !== false
                    screenWidth: desktopWindow.width
                    screenHeight: desktopWindow.height
                }

                GitDashboardWidget {
                    id: gitWidget
                    visible: widgetManager.widgetVisibility["git"] !== false
                    screenWidth: desktopWindow.width
                    screenHeight: desktopWindow.height
                }

                ResourceWheelWidget {
                    id: resourcewheelWidget
                    visible: widgetManager.widgetVisibility["resourcewheel"] !== false
                    screenWidth: desktopWindow.width
                    screenHeight: desktopWindow.height
                }
            }
        }
    }
}
