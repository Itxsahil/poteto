pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.config

Singleton {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property var battery: UPower.devices.values.find(d => d.isLaptopBattery) ?? null
    readonly property bool present: device?.isLaptopBattery ?? false
    readonly property real level: {
        const p = device?.percentage ?? 0;
        return p > 1 ? p / 100 : p;
    }
    readonly property int state: device?.state ?? UPowerDeviceState.Unknown
    readonly property bool charging: state === UPowerDeviceState.Charging
    readonly property bool full: state === UPowerDeviceState.FullyCharged
    readonly property real health: battery?.healthSupported ? battery.healthPercentage : 0
    readonly property color color: charging || full ? Theme.batteryGood
        : level <= 0.15 ? Theme.batteryCritical
        : level <= 0.30 ? Theme.batteryLow
        : Theme.batteryGood

    function formatTime(seconds) {
        if (!seconds || seconds <= 0)
            return "";
        const h = Math.floor(seconds / 3600);
        const m = Math.round((seconds % 3600) / 60);
        return h > 0 ? `${h}h ${m}m` : `${m}m`;
    }

    readonly property string statusText: {
        if (!present)
            return "No battery";
        if (full)
            return "Fully charged";
        if (charging) {
            const t = formatTime(device.timeToFull);
            return t ? `Charging · ${t} left` : "Charging";
        }
        if (state === UPowerDeviceState.PendingCharge)
            return "Plugged in, not charging";
        const t = formatTime(device?.timeToEmpty);
        return t ? `${t} remaining` : "On battery";
    }
}
