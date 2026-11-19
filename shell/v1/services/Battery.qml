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

    // --- Low-battery warnings ---------------------------------------------------------------
    // While discharging, one notification when the level reaches Settings.batteryLow (15%), and a
    // critical one at Settings.batteryCritical (5%). Both show even in Do Not Disturb (the
    // x-poteto-show-in-dnd hint, services/Notifications.qml); only the critical one stays up. Each is
    // sent once per discharge: plugging in resets them. Starting the shell already below a level
    // warns right away.

    readonly property int percent: Math.round(level * 100)
    readonly property bool discharging: present && state === UPowerDeviceState.Discharging
    // 0: nothing sent yet this discharge, 1: the low warning, 2: the critical one
    property int warned: 0

    function checkLevel() {
        if (!discharging) {
            warned = 0;
            return;
        }
        const critical = Settings.batteryCritical;
        const low = Math.max(Settings.batteryLow, critical);
        const stage = critical > 0 && percent <= critical ? 2 : low > 0 && percent <= low ? 1 : 0;
        if (stage > warned) {
            warn(stage);
            warned = stage;
        } else if (stage < warned && percent > (warned === 2 ? critical : low) + 2) {
            // Clearly back above the level it warned at (a level setting changed, or a reading
            // that went up): it may warn again. The 2% margin keeps a reading that wobbles
            // between 15% and 16% from warning twice.
            warned = stage;
        }
    }

    function warn(stage) {
        const t = formatTime(device?.timeToEmpty);
        const body = `${percent}% left${t ? ` · ${t} remaining` : ""}. Plug in the charger.`;
        const showInDnd = `boolean:${Notifications.showInDndHint}:true`;
        Quickshell.execDetached(stage === 2
            ? ["notify-send", "-a", "Battery", "-u", "critical", "-h", showInDnd, "-i", "battery-empty", "Battery critically low", body]
            : ["notify-send", "-a", "Battery", "-u", "normal", "-h", showInDnd, "-i", "battery-caution", "Battery low", body]);
    }

    onPercentChanged: checkLevel()
    onDischargingChanged: checkLevel()
    Component.onCompleted: checkLevel()

    Connections {
        target: Settings
        function onBatteryLowChanged() { root.checkLevel(); }
        function onBatteryCriticalChanged() { root.checkLevel(); }
    }

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
