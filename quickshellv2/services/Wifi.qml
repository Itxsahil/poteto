pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Wi-Fi through NetworkManager (nmcli): the radio, the networks in range, and connecting to,
// leaving and forgetting them. Follows `nmcli monitor`, so changes made elsewhere show up too.
// Draws nothing; modules/controlcenter/WifiPage.qml is the menu.
Singleton {
    id: root

    property bool enabled: true
    property string device: ""
    property var networks: []
    // Saved Wi-Fi profiles by the network they join: { ssid: [uuid, …] }. A profile's name is only
    // a label (it may be "Office" for the SSID "CompanyWiFi"), so profiles are matched by their
    // 802-11-wireless.ssid and addressed by UUID
    property var savedBySsid: ({})
    // The SSIDs that have a saved profile
    readonly property var savedNames: Object.keys(savedBySsid)
    readonly property var active: networks.find(n => n.active) ?? null

    property bool scanning: false
    property string connectingSsid: ""
    property string errorSsid: ""
    property string errorText: ""

    function splitFields(line) {
        const out = [];
        let cur = "";
        for (let i = 0; i < line.length; i++) {
            const c = line[i];
            if (c === "\\" && i + 1 < line.length)
                cur += line[++i];
            else if (c === ":") {
                out.push(cur);
                cur = "";
            } else
                cur += c;
        }
        out.push(cur);
        return out;
    }

    function isSaved(ssid) {
        return (savedBySsid[ssid] ?? []).length > 0;
    }

    function refresh() {
        if (listProc.running || savedProc.running || radioProc.running) {
            refreshDebounce.restart();
            return;
        }
        radioProc.running = true;
        savedProc.running = true;
        listProc.running = true;
    }

    function rescan() {
        if (!enabled || scanning)
            return;
        scanning = true;
        rescanProc.running = true;
    }

    function setEnabled(on) {
        enabled = on;
        radioSetProc.command = ["nmcli", "radio", "wifi", on ? "on" : "off"];
        radioSetProc.running = true;
    }

    function connect(ssid, password) {
        if (connectProc.running)
            return;
        errorSsid = "";
        errorText = "";
        connectingSsid = ssid;
        const uuids = savedBySsid[ssid] ?? [];
        const saved = uuids.length > 0;
        connectProc.ssid = ssid;
        connectProc.createdProfile = !saved || !!password;
        // The profiles there were before, so a failed attempt removes only the one it made
        connectProc.before = saved && !password ? uuids : [];

        if (saved && !password)
            connectProc.command = ["nmcli", "connection", "up", "uuid", uuids[0]];
        else if (password)
            connectProc.command = ["nmcli", "device", "wifi", "connect", ssid, "password", password];
        else
            connectProc.command = ["nmcli", "device", "wifi", "connect", ssid];

        // A new password replaces the saved profiles for this network
        if (saved && password) {
            forgetProc.command = ["nmcli", "connection", "delete", ...uuids.flatMap(u => ["uuid", u])];
            forgetProc.thenConnect = true;
            forgetProc.running = true;
        } else {
            connectProc.running = true;
        }
    }

    function disconnect() {
        if (!device)
            return;
        disconnectProc.command = ["nmcli", "device", "disconnect", device];
        disconnectProc.running = true;
    }

    // Every saved profile for this network
    function forget(ssid) {
        const uuids = savedBySsid[ssid] ?? [];
        if (uuids.length === 0)
            return;
        forgetProc.command = ["nmcli", "connection", "delete", ...uuids.flatMap(u => ["uuid", u])];
        forgetProc.thenConnect = false;
        forgetProc.running = true;
    }

    Component.onCompleted: {
        deviceProc.running = true;
        refresh();
    }

    Process {
        id: deviceProc
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE", "device"]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.split("\n").find(l => root.splitFields(l)[1] === "wifi");
                root.device = line ? root.splitFields(line)[0] : "";
            }
        }
    }

    Process {
        id: radioProc
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!radioSetProc.running)
                    root.enabled = text.trim() === "enabled";
            }
        }
    }

    Process {
        id: savedProc
        // Each Wi-Fi profile's UUID and the SSID it joins (nmcli -g escapes ":" and "\\")
        command: ["sh", "-c", `
            nmcli -t -f UUID,TYPE connection show | while IFS=: read -r uuid type; do
                [ "$type" = 802-11-wireless ] || continue
                printf '%s\\t%s\\n' "$uuid" "$(nmcli -g 802-11-wireless.ssid connection show uuid "$uuid")"
            done
        `]
        stdout: StdioCollector {
            onStreamFinished: {
                const map = {};
                for (const line of text.split("\n")) {
                    const tab = line.indexOf("\t");
                    if (tab < 0)
                        continue;
                    const uuid = line.slice(0, tab);
                    const ssid = line.slice(tab + 1).replace(/\\(.)/g, "$1");
                    if (!uuid || !ssid)
                        continue;
                    (map[ssid] = map[ssid] ?? []).push(uuid);
                }
                root.savedBySsid = map;
            }
        }
    }

    Process {
        id: listProc
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL,SECURITY,SSID", "device", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector {
            onStreamFinished: {
                const bySsid = {};
                for (const line of text.split("\n")) {
                    if (!line)
                        continue;
                    const f = root.splitFields(line);
                    const ssid = f.slice(3).join(":");
                    if (!ssid)
                        continue;
                    const net = {
                        ssid: ssid,
                        signal: parseInt(f[1]) || 0,
                        secure: f[2] !== "" && f[2] !== "--",
                        active: f[0].trim() === "*"
                    };
                    const prev = bySsid[ssid];
                    if (!prev)
                        bySsid[ssid] = net;
                    else {
                        prev.active = prev.active || net.active;
                        prev.signal = Math.max(prev.signal, net.signal);
                    }
                }
                root.networks = Object.values(bySsid).sort((a, b) => {
                    if (a.active !== b.active)
                        return a.active ? -1 : 1;
                    return b.signal - a.signal;
                });
            }
        }
    }

    Process {
        id: rescanProc
        command: ["nmcli", "device", "wifi", "rescan"]
        onExited: {
            rescanSettle.restart();
        }
    }

    Timer {
        id: rescanSettle
        interval: 1500
        onTriggered: {
            root.scanning = false;
            root.refresh();
        }
    }

    Process {
        id: radioSetProc
        onExited: root.refresh()
    }

    Process {
        id: connectProc
        property string ssid: ""
        property bool createdProfile: false
        property var before: []

        stderr: StdioCollector {
            id: connectErr
        }

        onExited: code => {
            if (code !== 0) {
                const err = connectErr.text;
                root.errorSsid = ssid;
                root.errorText = /secrets|password|802-1x|psk/i.test(err) ? "Incorrect password" : "Couldn't connect";
                // The profile this attempt made: one for this SSID that was not there before. By
                // UUID, never by name, which another network's profile might have
                if (createdProfile) {
                    cleanupProc.command = ["sh", "-c", `
                        ssid="$1"; shift
                        nmcli -t -f UUID,TYPE connection show | while IFS=: read -r uuid type; do
                            [ "$type" = 802-11-wireless ] || continue
                            [ "$(nmcli -g 802-11-wireless.ssid connection show uuid "$uuid" | sed 's/\\\\\\(.\\)/\\1/g')" = "$ssid" ] || continue
                            case " $* " in *" $uuid "*) continue ;; esac
                            nmcli connection delete uuid "$uuid"
                        done
                    `, "sh", ssid, ...before];
                    cleanupProc.running = true;
                }
            }
            root.connectingSsid = "";
            root.refresh();
        }
    }

    Process {
        id: cleanupProc
        onExited: root.refresh()
    }

    Process {
        id: forgetProc
        property bool thenConnect: false
        onExited: {
            if (thenConnect) {
                thenConnect = false;
                connectProc.running = true;
            } else {
                root.refresh();
            }
        }
    }

    Process {
        id: disconnectProc
        onExited: root.refresh()
    }

    Process {
        id: monitor
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: refreshDebounce.restart()
        }
        onExited: monitorRestart.restart()
    }

    Timer {
        id: monitorRestart
        interval: 3000
        onTriggered: monitor.running = true
    }

    Timer {
        id: refreshDebounce
        interval: 400
        onTriggered: root.refresh()
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
