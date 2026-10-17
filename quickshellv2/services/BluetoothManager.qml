pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

// Bluetooth through BlueZ (Quickshell.Bluetooth): the adapter's power and scanning, every device
// worth showing (paired, connected, or nearby with a real name), and pairing, connecting,
// disconnecting and forgetting them. Pairing a new device connects it once it is paired.
// modules/controlcenter/BluetoothPage.qml is the menu.
Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: !!adapter
    readonly property bool enabled: !!(adapter && adapter.enabled)
    readonly property bool scanning: !!(adapter && adapter.discovering)

    readonly property var devices: Bluetooth.devices.values
        .filter(d => d.paired || d.connected || hasRealName(d))
        .sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || displayName(a).localeCompare(displayName(b)))
    readonly property var pairedDevices: devices.filter(d => d.paired)
    readonly property var otherDevices: devices.filter(d => !d.paired)
    readonly property var connectedDevices: devices.filter(d => d.connected)

    property string pairingAddress: ""
    property string errorAddress: ""

    function hasRealName(d) {
        const n = d.name || d.deviceName || "";
        return n !== "" && !/^([0-9a-f]{2}[-:]){5}[0-9a-f]{2}$/i.test(n);
    }

    function displayName(d) {
        return d.name || d.deviceName || d.address;
    }

    function batteryPercent(d) {
        if (!d?.batteryAvailable)
            return -1;
        return Math.round(d.battery > 1 ? d.battery : d.battery * 100);
    }

    function setEnabled(on) {
        if (adapter)
            adapter.enabled = on;
    }

    function startScan() {
        if (adapter && adapter.enabled && !adapter.discovering)
            adapter.discovering = true;
    }

    function stopScan() {
        if (adapter && adapter.discovering)
            adapter.discovering = false;
    }

    function toggleScan() {
        if (scanning)
            stopScan();
        else
            startScan();
    }

    function connect(device) {
        errorAddress = "";
        if (!device.paired) {
            pairingAddress = device.address;
            pairWatch.started = false;
            pairWatch.elapsed = 0;
            pairWatch.restart();
            device.pair();
            return;
        }
        device.trusted = true;
        device.connect();
    }

    function disconnect(device) {
        device.disconnect();
    }

    function forget(device) {
        if (pairingAddress === device.address)
            pairingAddress = "";
        device.forget();
    }

    Timer {
        id: pairWatch
        property bool started: false
        property int elapsed: 0
        interval: 400
        repeat: true
        onTriggered: {
            const d = Bluetooth.devices.values.find(x => x.address === root.pairingAddress);
            elapsed += interval;
            if (!d) {
                root.pairingAddress = "";
                stop();
                return;
            }
            if (d.pairing)
                started = true;
            if (d.paired) {
                root.pairingAddress = "";
                stop();
                d.trusted = true;
                d.connect();
            } else if ((started && !d.pairing) || elapsed > 30000) {
                if (d.pairing)
                    d.cancelPair();
                root.errorAddress = d.address;
                root.pairingAddress = "";
                stop();
            }
        }
    }
}
