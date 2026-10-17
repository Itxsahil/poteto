//@ pragma IconTheme breeze-dark
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services
import qs.modules.bar
import qs.modules.screenshot
import qs.modules.player
import qs.modules.colorpicker

ShellRoot {
    // Singletons start when first used. These have no UI, so start them here: each one applies
    // its saved setting once (light/dark mode, accent color, night light), then follows changes; Osd starts
    // listening for changes made outside the shell.
    Component.onCompleted: {
        Appearance.apply();
        Appearance.applyAccent();
        NightLight.apply();
        Osd.shown;
        // The polkit agent and the notification server have to be up before anything asks, not on
        // first use
        Polkit.registered;
        Notifications.count;
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

    // qs ipc call controlcenter toggle|open|close|wifi|bluetooth|notifications (Super + C in hypr/bindings.lua)
    IpcHandler {
        target: "controlcenter"
        function toggle(): void { ShellState.toggle("controlcenter"); }
        function open(): void { ShellState.open("controlcenter"); }
        function close(): void { ShellState.close("controlcenter"); }
        function wifi(): void { ShellState.openPage("wifi"); }
        function bluetooth(): void { ShellState.openPage("bluetooth"); }
        function notifications(): void { ShellState.openPage("notifications"); }
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

    // qs ipc call videos toggle|open|close (Alt + Shift + V in hypr/bindings.lua)
    IpcHandler {
        target: "videos"
        function toggle(): void { ShellState.toggle("videos"); }
        function open(): void { ShellState.open("videos"); }
        function close(): void { ShellState.close("videos"); }
    }

    // qs ipc call player play <path>|stop|next|previous|loop|speed <step>|status
    IpcHandler {
        target: "player"
        function play(path: string): void { Player.play(path, [path]); }
        function stop(): void { Player.close(); }
        function next(): void { Player.next(); }
        function previous(): void { Player.previous(); }
        function loop(): string { Player.cycleLoop(); return Player.loop; }
        function speed(step: int): string { Player.cycleSpeed(step); return Player.speed + "x"; }
        function status(): string { return Player.playing ? `${Player.title} · loop ${Player.loop} · ${Player.speed}x` : "idle"; }
    }

    // The video window: one, opened by the video browser or qs ipc call player play
    PlayerWindow {}

    // qs ipc call session toggle|open|close|lock|logout|suspend|reboot|poweroff (Alt + X opens
    // the power menu)
    IpcHandler {
        target: "session"
        function toggle(): void { ShellState.toggle("power"); }
        function open(): void { Session.openMenu(""); }
        function close(): void { ShellState.close("power"); }
        function lock(): void { Session.run("lock"); }
        function logout(): void { Session.openMenu("logout"); }
        function suspend(): void { Session.run("suspend"); }
        function reboot(): void { Session.openMenu("reboot"); }
        function poweroff(): void { Session.openMenu("poweroff"); }
    }

    // qs ipc call quiet toggle|on|off|status: notifications to history only (critical ones still show)
    IpcHandler {
        target: "quiet"
        function toggle(): bool { Config.setQuiet(!Config.quiet); return !Config.quiet; }
        function on(): bool { Config.setQuiet(true); return true; }
        function off(): bool { Config.setQuiet(false); return false; }
        function status(): bool { return Config.quiet; }
    }

    // qs ipc call notifications status|next|clear
    IpcHandler {
        target: "notifications"
        function status(): string {
            return `${Notifications.queue.length} waiting, ${Notifications.count} in history`
                + (Notifications.current ? ` · showing "${Notifications.current.summary}"` : "");
        }
        function next(): void { Notifications.next(); }
        function clear(): void { Notifications.clearAll(); }
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

    // qs ipc call colorpicker pick|cancel|last (Super + Shift + C in hypr/bindings.lua)
    IpcHandler {
        target: "colorpicker"
        function pick(): void { ColorPicker.start(); }
        function cancel(): void { ColorPicker.cancel(); }
        function last(): string { return ColorPicker.history[0] ?? ""; }
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

            ColorPickerOverlay {
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
