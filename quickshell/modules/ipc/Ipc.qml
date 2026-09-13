import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.services

Scope {
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
        name: "screenshot"
        description: "Take a screenshot"
        onPressed: Screenshot.start("region")
    }
}
