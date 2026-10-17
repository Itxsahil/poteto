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
    // its saved setting once (light/dark mode, night light), then follows changes; Osd starts
    // listening for changes made outside the shell.
    Component.onCompleted: {
        Appearance.apply();
        NightLight.apply();
        Osd.shown;
        // The polkit agent has to be registered before anything asks, not on first use
        Polkit.registered;
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

    // qs ipc call clipboard toggle|open|close (Super + V in hypr/bindings.lua)
    IpcHandler {
        target: "clipboard"
        function toggle(): void { ShellState.toggle("clipboard"); }
        function open(): void { ShellState.open("clipboard"); }
        function close(): void { ShellState.close("clipboard"); }
    }

    // qs ipc call emoji toggle|open|close (Super + . in hypr/bindings.lua)
    IpcHandler {
        target: "emoji"
        function toggle(): void { ShellState.toggle("emoji"); }
        function open(): void { ShellState.open("emoji"); }
        function close(): void { ShellState.close("emoji"); }
    }

    // qs ipc call wallpaper toggle|open|close|random (Alt + W in hypr/bindings.lua)
    IpcHandler {
        target: "wallpaper"
        function toggle(): void { ShellState.toggle("wallpaper"); }
        function open(): void { ShellState.open("wallpaper"); }
        function close(): void { ShellState.close("wallpaper"); }
        function random(): void { Wallpaper.applyRandom(); }
    }

    // qs ipc call logintheme toggle|open|close|apply <id>|current|list (Alt + Shift + T)
    IpcHandler {
        target: "logintheme"
        function toggle(): void { ShellState.toggle("logintheme"); }
        function open(): void { ShellState.open("logintheme"); }
        function close(): void { ShellState.close("logintheme"); }
        function apply(id: string): void { LoginTheme.apply(id); }
        function current(): string { return LoginTheme.active; }
        function list(): string { return LoginTheme.themes.map(t => t.id).join("\n"); }
    }

    // qs ipc call loginvideo toggle|open|close|current (Alt + Shift + W)
    IpcHandler {
        target: "loginvideo"
        function toggle(): void { ShellState.toggle("loginvideo"); }
        function open(): void { ShellState.open("loginvideo"); }
        function close(): void { ShellState.close("loginvideo"); }
        function current(): string { return LoginVideo.current; }
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
