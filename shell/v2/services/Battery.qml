pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

// The laptop battery through UPower: level, charging, and a line of status ("2h 10m remaining").
// Draws nothing; modules/bar/BatteryIndicator.qml shows it next to the pill or on the bar, when
// Config.showBattery is on.
Singleton {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool present: device?.isLaptopBattery ?? false
    // 0–100
    readonly property int percent: {
        const p = device?.percentage ?? 0;
        return Math.round(p > 1 ? p : p * 100);
    }
    readonly property int state: device?.state ?? UPowerDeviceState.Unknown
    readonly property bool charging: state === UPowerDeviceState.Charging
    readonly property bool full: state === UPowerDeviceState.FullyCharged
    readonly property bool pluggedIn: charging || full || state === UPowerDeviceState.PendingCharge
    readonly property bool low: !pluggedIn && percent <= 20
    readonly property bool critical: !pluggedIn && percent <= 10

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
