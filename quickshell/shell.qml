//@ pragma IconTheme breeze-dark
import QtQuick
import Quickshell
import qs.modules.ipc
import qs.modules.bar
import qs.modules.island
import qs.modules.screenshot

ShellRoot {
    Ipc {}

    Variants {
        model: Quickshell.screens

        Scope {
            id: screenScope
            required property ShellScreen modelData

            WorkspacesBar {
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
        }
    }
}
