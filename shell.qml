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
            }

            Item {
                id: widgetsLayer
                anchors.fill: parent

                Clock {
                    id: clockWidget
                    screenWidth: desktopWindow.width
                    screenHeight: desktopWindow.height
                }

                SystemInfo {
                    id: sysinfoWidget
                    screenWidth: desktopWindow.width
                    screenHeight: desktopWindow.height
                }

                CalendarWidget {
                    id: calendarWidget
                    screenWidth: desktopWindow.width
                    screenHeight: desktopWindow.height
                }

                MediaWidget {
                    id: mediaWidget
                    screenWidth: desktopWindow.width
                    screenHeight: desktopWindow.height
                }

                WeatherWidget {
                    id: weatherWidget
                    screenWidth: desktopWindow.width
                    screenHeight: desktopWindow.height
                }

                PosterWidget {
                    id: posterWidget
                    screenWidth: desktopWindow.width
                    screenHeight: desktopWindow.height
                }

                BatteryWidget {
                    id: batteryWidget
                    screenWidth: desktopWindow.width
                    screenHeight: desktopWindow.height
                }

                VolumeBrightnessWidget {
                    id: volumeWidget
                    screenWidth: desktopWindow.width
                    screenHeight: desktopWindow.height
                }

                NetworkWidget {
                    id: networkWidget
                    screenWidth: desktopWindow.width
                    screenHeight: desktopWindow.height
                }

                NotesWidget {
                    id: notesWidget
                    screenWidth: desktopWindow.width
                    screenHeight: desktopWindow.height
                }

                TodoWidget {
                    id: todoWidget
                    screenWidth: desktopWindow.width
                    screenHeight: desktopWindow.height
                }
            }
        }
    }
}
