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
            }
        }
    }
}
