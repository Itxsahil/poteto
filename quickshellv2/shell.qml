import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.modules.bar

ShellRoot {
    // qs -p <this folder> ipc call layout toggle|pill|bar|status
    IpcHandler {
        target: "layout"
        function toggle(): string { Config.toggleStyle(); return Config.style; }
        function pill(): string { Config.setStyle("pill"); return Config.style; }
        function bar(): string { Config.setStyle("bar"); return Config.style; }
        function status(): string { return Config.style; }
    }

    Variants {
        model: Quickshell.screens

        Scope {
            id: screenScope

            required property ShellScreen modelData

            // Only the chosen layout exists at all, so the other one reserves no space
            LazyLoader {
                active: Config.style === "pill"

                Pill {
                    targetScreen: screenScope.modelData
                }
            }

            LazyLoader {
                active: Config.style === "bar"

                Bar {
                    targetScreen: screenScope.modelData
                }
            }
        }
    }
}
