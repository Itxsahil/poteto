pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool enabled: true
    property string device: ""
    property var networks: []
    property var savedNames: []
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
        return savedNames.includes(ssid);
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
        const saved = isSaved(ssid);
        connectProc.ssid = ssid;
        connectProc.createdProfile = !saved || !!password;

        if (saved && !password)
            connectProc.command = ["nmcli", "connection", "up", "id", ssid];
        else if (password)
            connectProc.command = ["nmcli", "device", "wifi", "connect", ssid, "password", password];
        else
            connectProc.command = ["nmcli", "device", "wifi", "connect", ssid];

        if (saved && password) {
            forgetProc.command = ["nmcli", "connection", "delete", "id", ssid];
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

    function forget(ssid) {
        forgetProc.command = ["nmcli", "connection", "delete", "id", ssid];
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
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.savedNames = text.split("\n")
                    .map(l => root.splitFields(l))
                    .filter(f => f[1] === "802-11-wireless")
                    .map(f => f[0]);
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

        stderr: StdioCollector {
            id: connectErr
        }

        onExited: code => {
            if (code !== 0) {
                const err = connectErr.text;
                root.errorSsid = ssid;
                root.errorText = /secrets|password|802-1x|psk/i.test(err) ? "Incorrect password" : "Couldn't connect";
                if (createdProfile)
                    cleanupProc.command = ["nmcli", "connection", "delete", "id", ssid];
                if (createdProfile)
                    cleanupProc.running = true;
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
