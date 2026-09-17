import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.services

Scope {
    Connections {
        target: Recorder
        function onNameRequested() { ShellState.open("recordname"); }
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { ShellState.toggle("launcher"); }
        function open(): void { ShellState.open("launcher"); }
        function close(): void { ShellState.close("launcher"); }
    }

    IpcHandler {
        target: "clipboard"
        function toggle(): void { ShellState.toggle("clipboard"); }
        function open(): void { ShellState.open("clipboard"); }
        function close(): void { ShellState.close("clipboard"); }
    }

    IpcHandler {
        target: "wallpaper"
        function toggle(): void { ShellState.toggle("wallpaper"); }
        function open(): void { ShellState.open("wallpaper"); }
        function close(): void { ShellState.close("wallpaper"); }
        function random(): void { Wallpaper.applyRandom(); }
    }

    IpcHandler {
        target: "theme"
        function toggle(): void { ShellState.toggle("themes"); }
        function open(): void { ShellState.open("themes"); }
        function close(): void { ShellState.close("themes"); }
        function apply(id: string): void { ThemeManager.apply(id); }
        function current(): string { return ThemeManager.current; }
        function list(): string { return ThemeManager.themes.map(t => t.id).join("\n"); }
    }

    IpcHandler {
        target: "session"
        function toggle(): void { ShellState.toggle("power"); }
        function open(): void { ShellState.open("power"); }
        function close(): void { ShellState.close("power"); }
        function lock(): void { Session.run("lock"); }
    }

    IpcHandler {
        target: "recorder"
        function toggle(): void { Recorder.toggle(); }
        function stop(): void { Recorder.stop(); }
        function status(): string { return Recorder.recording ? `recording ${Recorder.formatElapsed(Recorder.elapsed)}` : Recorder.finishing ? "saving" : "idle"; }
    }

    IpcHandler {
        target: "colorpicker"
        function pick(): void { ColorPicker.start(); }
        function cancel(): void { ColorPicker.cancel(); }
        function last(): string { return ColorPicker.history[0] ?? ""; }
    }

    IpcHandler {
        target: "emoji"
        function toggle(): void { ShellState.toggle("emoji"); }
        function open(): void { ShellState.open("emoji"); }
        function close(): void { ShellState.close("emoji"); }
    }

    IpcHandler {
        target: "mpd"
        function toggle(): void { Mpd.toggle(); }
        function next(): void { Mpd.next(); }
        function previous(): void { Mpd.previous(); }
        function status(): string { return Mpd.connected ? `${Mpd.state}: ${Mpd.title}` : "disconnected"; }
    }

    IpcHandler {
        target: "notifications"
        function toggleDnd(): void { Notifications.dnd = !Notifications.dnd; }
        function dnd(): bool { return Notifications.dnd; }
        function clear(): void { Notifications.clearAll(); }
        function count(): int { return Notifications.count; }
    }

    IpcHandler {
        target: "screenshot"
        function region(): void { Screenshot.start("region"); }
        function window(): void { Screenshot.start("window"); }
        function screen(): void { Screenshot.start("screen"); }
        function cancel(): void { Screenshot.cancel(); }
    }

    GlobalShortcut {
        name: "launcher"
        description: "Toggle the app launcher"
        onPressed: ShellState.toggle("launcher")
    }

    GlobalShortcut {
        name: "clipboard"
        description: "Toggle clipboard history"
        onPressed: ShellState.toggle("clipboard")
    }

    GlobalShortcut {
        name: "wallpaper"
        description: "Toggle wallpaper switcher"
        onPressed: ShellState.toggle("wallpaper")
    }

    GlobalShortcut {
        name: "themes"
        description: "Toggle theme switcher"
        onPressed: ShellState.toggle("themes")
    }

    GlobalShortcut {
        name: "recorder"
        description: "Start or stop screen recording"
        onPressed: Recorder.toggle()
    }

    GlobalShortcut {
        name: "colorpicker"
        description: "Pick a color from the screen"
        onPressed: ColorPicker.start()
    }

    GlobalShortcut {
        name: "emoji"
        description: "Toggle emoji picker"
        onPressed: ShellState.toggle("emoji")
    }

    GlobalShortcut {
        name: "power"
        description: "Toggle power menu"
        onPressed: ShellState.toggle("power")
    }

    GlobalShortcut {
        name: "screenshot"
        description: "Take a screenshot"
        onPressed: Screenshot.start("region")
    }
}
