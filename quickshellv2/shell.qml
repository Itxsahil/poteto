//@ pragma IconTheme breeze-dark
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services
import qs.modules.bar
import qs.modules.launcher

ShellRoot {
    // qs ipc call layout toggle|pill|bar|status
    IpcHandler {
        target: "layout"
        function toggle(): string { Config.toggleStyle(); return Config.style; }
        function pill(): string { Config.setStyle("pill"); return Config.style; }
        function bar(): string { Config.setStyle("bar"); return Config.style; }
        function status(): string { return Config.style; }
    }

    // qs ipc call launcher toggle|open|close (Alt + Space in hypr/bindings.lua)
    IpcHandler {
        target: "launcher"
        function toggle(): void { ShellState.launcherOpen = !ShellState.launcherOpen; }
        function open(): void { ShellState.launcherOpen = true; }
        function close(): void { ShellState.launcherOpen = false; }
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

            // In pill mode the pill itself becomes the launcher; the bar needs a panel for it
            LazyLoader {
                active: Config.style === "bar"

                BarLauncher {
                    targetScreen: screenScope.modelData
                }
            }
        }
    }
}
