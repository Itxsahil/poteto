//@ pragma IconTheme breeze-dark
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services
import qs.modules.bar
import qs.modules.screenshot

ShellRoot {
    // Singletons start when first used. These have no UI, so start them here: each one applies
    // its saved setting once (light/dark mode, night light), then follows changes.
    Component.onCompleted: {
        Appearance.apply();
        NightLight.apply();
    }

    // qs ipc call layout toggle|pill|bar|status
    IpcHandler {
        target: "layout"
        function toggle(): string { Config.toggleStyle(); return Config.style; }
        function pill(): string { Config.setStyle("pill"); return Config.style; }
        function bar(): string { Config.setStyle("bar"); return Config.style; }
        function status(): string { return Config.style; }
    }

    // qs ipc call appearance toggle|dark|light|status
    IpcHandler {
        target: "appearance"
        function toggle(): string { Config.toggleMode(); return Config.mode; }
        function dark(): string { Config.setMode("dark"); return Config.mode; }
        function light(): string { Config.setMode("light"); return Config.mode; }
        function status(): string { return Config.mode; }
    }

    // qs ipc call nightlight toggle|on|off|status
    IpcHandler {
        target: "nightlight"
        function toggle(): bool { NightLight.toggle(); return Config.nightLight; }
        function on(): bool { Config.setNightLight(true); return true; }
        function off(): bool { Config.setNightLight(false); return false; }
        function status(): bool { return Config.nightLight; }
    }

    // qs ipc call launcher toggle|open|close (Alt + Space in hypr/bindings.lua)
    IpcHandler {
        target: "launcher"
        function toggle(): void { ShellState.toggle("launcher"); }
        function open(): void { ShellState.open("launcher"); }
        function close(): void { ShellState.close("launcher"); }
    }

    // qs ipc call controlcenter toggle|open|close|wifi (Super + C in hypr/bindings.lua)
    IpcHandler {
        target: "controlcenter"
        function toggle(): void { ShellState.toggle("controlcenter"); }
        function open(): void { ShellState.open("controlcenter"); }
        function close(): void { ShellState.close("controlcenter"); }
        function wifi(): void { ShellState.openPage("wifi"); }
    }

    // qs ipc call screenshot region|window|screen|cancel (Super + Shift + 4 / 3 in hypr/bindings.lua)
    IpcHandler {
        target: "screenshot"
        function region(): void { Screenshot.start("region"); }
        function window(): void { Screenshot.start("window"); }
        function screen(): void { Screenshot.start("screen"); }
        function cancel(): void { Screenshot.cancel(); }
    }

    Variants {
        model: Quickshell.screens

        Scope {
            id: screenScope

            required property ShellScreen modelData

            // The same in either layout
            ScreenshotOverlay {
                targetScreen: screenScope.modelData
            }

            ScreenshotPreview {
                targetScreen: screenScope.modelData
            }

            // Only the chosen layout exists at all, so the other one reserves no space. In pill
            // mode the pill itself grows into the launcher and control center; the bar drops a
            // panel down for them instead.
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

            LazyLoader {
                active: Config.style === "bar"

                BarPanel {
                    targetScreen: screenScope.modelData
                }
            }
        }
    }
}
