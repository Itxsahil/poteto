import QtQuick
import qs.config
import qs.components.icons
import qs.services

QuickToggleTile {
    readonly property var connected: BluetoothManager.connectedDevices

    title: "Bluetooth"
    subtitle: {
        if (!BluetoothManager.available)
            return "Unavailable";
        if (!BluetoothManager.enabled)
            return "Off";
        if (connected.length === 1) {
            const battery = BluetoothManager.batteryPercent(connected[0]);
            return BluetoothManager.displayName(connected[0]) + (battery >= 0 ? ` · ${battery}%` : "");
        }
        if (connected.length > 1)
            return `${connected.length} devices`;
        return "Not connected";
    }
    active: BluetoothManager.enabled

    onToggleRequested: BluetoothManager.setEnabled(!BluetoothManager.enabled)

    BluetoothIcon {
        anchors.centerIn: parent
        width: 12
        height: 18
        color: BluetoothManager.enabled ? Theme.onAccent : Theme.textSecondary
    }
}
