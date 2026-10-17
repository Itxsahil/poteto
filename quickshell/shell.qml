//@ pragma IconTheme breeze-dark
import QtQuick
import Quickshell
import qs.services
import qs.modules.ipc
import qs.modules.bar
import qs.modules.island
import qs.modules.screenshot
import qs.modules.notifications
import qs.modules.colorpicker
import qs.modules.recorder
import qs.modules.player

ShellRoot {
    // Singletons start when first used; night light has no UI until the control center opens,
    // so start it here to apply the saved setting
    Component.onCompleted: NightLight.enabled

    Ipc {}

    PlayerWindow {}

    Variants {
        model: Quickshell.screens

        Scope {
            id: screenScope
            required property ShellScreen modelData

            WorkspacesBar {
                targetScreen: screenScope.modelData
            }

            StatusBar {
                targetScreen: screenScope.modelData
            }

            SimpleBar {
                targetScreen: screenScope.modelData
            }

            Island {
                targetScreen: screenScope.modelData
            }

            ScreenshotOverlay {
                targetScreen: screenScope.modelData
            }

            ScreenshotPreview {
                targetScreen: screenScope.modelData
            }

            ColorPickerOverlay {
                targetScreen: screenScope.modelData
            }

            RecorderOverlay {
                targetScreen: screenScope.modelData
            }

            NotificationPopups {
                targetScreen: screenScope.modelData
            }
        }
    }
}
