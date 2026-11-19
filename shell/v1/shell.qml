//@ pragma IconTheme Papirus
import QtQuick
import Quickshell
import qs.services
import qs.modules.ipc
import qs.modules.bar
import qs.modules.island
import qs.modules.overview
import qs.modules.screenshot
import qs.modules.notifications
import qs.modules.colorpicker
import qs.modules.recorder
import qs.modules.player

ShellRoot {
    // Singletons start when first used. Night light has no UI until the control center opens, so
    // start it here to apply the saved setting; the clipboard to clear out its old /tmp previews;
    // the battery to watch for low-battery warnings even if nothing shows the battery
    Component.onCompleted: {
        NightLight.enabled;
        Clipboard.legacyDir;
        Battery.percent;
    }

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

            WorkspaceOverview {
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
