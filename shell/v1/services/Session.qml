pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string user: Quickshell.env("USER")
    property string uptime: ""
    property var capabilities: ({ suspend: true, hibernate: true, reboot: true, poweroff: true })

    readonly property var actions: [
        { id: "lock", label: "Lock", glyph: "󰌾", key: "L", confirm: false, available: true },
        { id: "logout", label: "Logout", glyph: "󰍃", key: "E", confirm: true, available: true },
        { id: "suspend", label: "Suspend", glyph: "󰤄", key: "S", confirm: false, available: capabilities.suspend },
        { id: "hibernate", label: "Hibernate", glyph: "󰤁", key: "H", confirm: false, available: capabilities.hibernate },
        { id: "reboot", label: "Reboot", glyph: "󰜉", key: "R", confirm: true, available: capabilities.reboot },
        { id: "poweroff", label: "Shutdown", glyph: "⏻", key: "P", confirm: true, available: capabilities.poweroff }
    ].filter(a => a.available)

    readonly property var commands: ({
        lock: ["hyprlock"],
        logout: ["hyprctl", "dispatch", "hl.dsp.exit()"],
        suspend: ["systemctl", "suspend"],
        hibernate: ["systemctl", "hibernate"],
        reboot: ["systemctl", "reboot"],
        poweroff: ["systemctl", "poweroff"]
    })

    function refresh() {
        uptimeProc.running = true;
        if (!capsProc.running)
            capsProc.running = true;
    }

    function run(id) {
        const command = commands[id];
        if (command)
            Quickshell.execDetached(command);
    }

    Component.onCompleted: refresh()

    Process {
        id: uptimeProc
        command: ["uptime", "-p"]
        stdout: StdioCollector {
            onStreamFinished: root.uptime = text.trim().replace(/^up\s+/, "")
        }
    }

    Process {
        id: capsProc
        command: ["sh", "-c", `
            for m in CanSuspend CanHibernate CanReboot CanPowerOff; do
                printf '%s=' "$m"
                busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager "$m" 2>/dev/null | sed 's/^s //; s/"//g'
            done
        `]
        stdout: StdioCollector {
            onStreamFinished: {
                const found = {};
                for (const line of text.split("\n")) {
                    const [key, value] = line.split("=");
                    if (key)
                        found[key] = value?.trim();
                }
                const ok = key => found[key] === undefined || found[key] === "" || found[key] === "yes" || found[key] === "challenge";
                root.capabilities = {
                    suspend: ok("CanSuspend"),
                    hibernate: ok("CanHibernate"),
                    reboot: ok("CanReboot"),
                    poweroff: ok("CanPowerOff")
                };
            }
        }
    }
}
