import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs.config
import qs.components
import qs.components.icons
import qs.services

Item {
    id: root

    property string expandedAddress: ""

    readonly property var liveConnected: BluetoothManager.connectedDevices
    readonly property var liveMine: BluetoothManager.pairedDevices.filter(d => !d.connected)
    readonly property var liveOthers: BluetoothManager.otherDevices.filter(d => !d.connected)

    // The service rebuilds its arrays whenever any device's state changes, and a new array
    // rebuilds every row (dropping a row's "Couldn't connect"). Only follow membership and order.
    property var connected: []
    property var mine: []
    property var others: []

    signal backRequested()

    function reset() {
        expandedAddress = "";
        flick.contentY = 0;
    }

    function signature(list) {
        return list.map(d => d.address).join(",");
    }

    function sync() {
        if (signature(liveConnected) !== signature(connected))
            connected = liveConnected;
        if (signature(liveMine) !== signature(mine))
            mine = liveMine;
        if (signature(liveOthers) !== signature(others))
            others = liveOthers;
    }

    onLiveConnectedChanged: sync()
    onLiveMineChanged: sync()
    onLiveOthersChanged: sync()
    Component.onCompleted: sync()

    component SectionLabel: Row {
        property string text
        property bool busy: false
        leftPadding: 6
        spacing: 8
        height: 18

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: parent.text
            color: Theme.textSecondary
            font.pixelSize: 11
            font.weight: Font.DemiBold
            font.letterSpacing: 0.4
            font.family: Theme.fontFamily
        }

        Spinner {
            anchors.verticalCenter: parent.verticalCenter
            width: 11
            height: 11
            color: Theme.textSecondary
            visible: parent.busy
        }
    }

    // The device's own icon (headset, mouse, ...) when the icon theme has it, else the Bluetooth rune.
    component DeviceIcon: Item {
        property var device
        property color tint: Theme.textPrimary
        width: 18
        height: 18

        Image {
            id: img
            anchors.fill: parent
            source: parent.device?.icon ? Quickshell.iconPath(parent.device.icon, true) : ""
            sourceSize.width: 36
            sourceSize.height: 36
            visible: status === Image.Ready
        }

        BluetoothIcon {
            anchors.centerIn: parent
            width: 10
            height: 15
            color: parent.tint
            visible: !img.visible
        }
    }

    // A device in one of the grouped lists: one line, actions sliding out when expanded.
    component DeviceRow: Item {
        id: row

        required property var modelData
        required property int index
        readonly property var device: modelData
        readonly property string address: device.address
        readonly property bool isConnecting: device.state === BluetoothDeviceState.Connecting
        readonly property bool isPairing: device.pairing || BluetoothManager.pairingAddress === address
        readonly property bool busy: isConnecting || isPairing
        readonly property bool expanded: root.expandedAddress === address
        property bool failed: BluetoothManager.errorAddress === address
        property bool wasConnecting: false
        readonly property bool hasStatus: busy || failed
        readonly property int lineHeight: hasStatus ? 52 : 46

        width: parent.width
        height: lineHeight + (expanded ? actions.height + 12 : 0)
        clip: true

        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        onIsConnectingChanged: {
            if (isConnecting) {
                wasConnecting = true;
                failed = false;
            } else if (wasConnecting) {
                wasConnecting = false;
                if (!device.connected)
                    failed = true;
            }
        }

        // Deferred, because the Column relays out (and the content grows) after this height change.
        onHeightChanged: if (expanded) Qt.callLater(ensureVisible)

        function ensureVisible() {
            // The row (or the whole page, on reload) can be gone by the time this deferred call runs.
            if (!flick || !body || !expanded)
                return;
            const bottom = mapToItem(body, 0, height).y + 28;
            if (bottom > flick.contentY + flick.height)
                flick.contentY = Math.min(bottom - flick.height, Math.max(0, flick.contentHeight - flick.height));
        }

        Rectangle {
            visible: row.index > 0
            x: 52
            width: parent.width - 64
            height: 1
            color: Qt.alpha(Theme.textPrimary, 0.06)
        }

        Rectangle {
            x: 4
            y: 4
            width: parent.width - 8
            height: parent.height - 8
            radius: 12
            color: row.expanded || rowMouse.containsMouse ? Theme.tileHover : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        MouseArea {
            id: rowMouse
            width: parent.width
            height: row.lineHeight
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (row.busy)
                    return;
                if (!row.device.paired) {
                    BluetoothManager.connect(row.device);
                    return;
                }
                root.expandedAddress = row.expanded ? "" : row.address;
            }
        }

        Rectangle {
            id: badge
            x: 12
            y: row.lineHeight / 2 - height / 2
            width: 28
            height: 28
            radius: 14
            // A tint rather than a solid color, so it still shows on the hover/expanded highlight
            color: Qt.alpha(Theme.textPrimary, 0.09)

            DeviceIcon {
                anchors.centerIn: parent
                width: 16
                height: 16
                device: row.device
            }
        }

        Column {
            anchors.left: badge.right
            anchors.leftMargin: 12
            anchors.right: trailing.left
            anchors.rightMargin: 10
            y: row.lineHeight / 2 - height / 2
            spacing: 1

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: BluetoothManager.displayName(row.device)
                color: Theme.textPrimary
                font.pixelSize: 13
                font.family: Theme.fontFamily
            }

            Text {
                visible: row.hasStatus
                text: row.isPairing ? "Pairing…" : row.isConnecting ? "Connecting…" : "Couldn't connect"
                color: row.busy ? Theme.accent : Theme.danger
                font.pixelSize: 11
                font.family: Theme.fontFamily
            }
        }

        Item {
            id: trailing
            anchors.right: parent.right
            anchors.rightMargin: 18
            y: row.lineHeight / 2 - height / 2
            width: row.device.paired ? 18 : pairHint.implicitWidth
            height: 18

            Spinner {
                anchors.fill: parent
                visible: row.busy
            }

            Text {
                id: pairHint
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: !row.device.paired && !row.busy
                text: "Pair"
                color: rowMouse.containsMouse ? Theme.accent : Theme.textSecondary
                font.pixelSize: 11
                font.weight: Font.DemiBold
                font.family: Theme.fontFamily
            }
        }

        Row {
            id: actions
            x: 16
            y: row.lineHeight
            spacing: 8
            opacity: row.expanded ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            PillButton {
                text: row.isConnecting ? "Connecting…" : "Connect"
                primary: true
                enabled: !row.busy
                onClicked: BluetoothManager.connect(row.device)
            }

            PillButton {
                text: "Forget"
                danger: true
                onClicked: {
                    root.expandedAddress = "";
                    BluetoothManager.forget(row.device);
                }
            }
        }
    }

    // A connected device, set apart from the rest with its battery level.
    component ConnectedCard: Rectangle {
        id: card

        required property var modelData
        readonly property var device: modelData
        readonly property bool expanded: root.expandedAddress === device.address
        readonly property bool isDisconnecting: device.state === BluetoothDeviceState.Disconnecting
        readonly property int battery: BluetoothManager.batteryPercent(device)

        width: parent.width
        height: 68 + (expanded ? cardActions.height + 12 : 0)
        radius: 18
        color: Qt.alpha(Theme.accent, cardMouse.containsMouse || expanded ? 0.2 : 0.14)
        border.width: 1
        border.color: Qt.alpha(Theme.accent, 0.3)
        clip: true
        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 120 } }

        MouseArea {
            id: cardMouse
            width: parent.width
            height: 68
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expandedAddress = card.expanded ? "" : card.device.address
        }

        Rectangle {
            id: cardBadge
            x: 14
            y: 14
            width: 40
            height: 40
            radius: 20
            color: Theme.accent

            DeviceIcon {
                anchors.centerIn: parent
                width: 20
                height: 20
                device: card.device
                tint: Theme.onAccent
            }
        }

        Column {
            anchors.left: cardBadge.right
            anchors.leftMargin: 12
            anchors.right: cardTrailing.left
            anchors.rightMargin: 10
            y: 34 - height / 2
            spacing: 2

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: BluetoothManager.displayName(card.device)
                color: Theme.textPrimary
                font.pixelSize: 14
                font.weight: Font.DemiBold
                font.family: Theme.fontFamily
            }

            Text {
                text: card.isDisconnecting ? "Disconnecting…"
                    : "Connected" + (card.battery >= 0 ? ` · ${card.battery}% battery` : "")
                color: Theme.accent
                font.pixelSize: 11
                font.family: Theme.fontFamily
            }
        }

        Item {
            id: cardTrailing
            anchors.right: parent.right
            anchors.rightMargin: 18
            y: 34 - height / 2
            width: 18
            height: 22

            Spinner {
                anchors.centerIn: parent
                width: 16
                height: 16
                visible: card.isDisconnecting
            }

            Text {
                anchors.centerIn: parent
                visible: !card.isDisconnecting
                text: "›"
                rotation: card.expanded ? 90 : 0
                color: Theme.textSecondary
                font.pixelSize: 20
                font.family: Theme.fontFamily
                Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }
        }

        Row {
            id: cardActions
            x: 14
            y: 68
            spacing: 8
            opacity: card.expanded ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            PillButton {
                text: "Disconnect"
                enabled: !card.isDisconnecting
                onClicked: {
                    BluetoothManager.disconnect(card.device);
                    root.expandedAddress = "";
                }
            }

            PillButton {
                text: "Forget"
                danger: true
                onClicked: {
                    root.expandedAddress = "";
                    BluetoothManager.forget(card.device);
                }
            }
        }
    }

    component Group: Rectangle {
        property alias model: repeater.model
        default property alias extra: rows.data
        width: parent.width
        height: rows.height
        radius: 18
        color: Theme.tileBg

        Column {
            id: rows
            width: parent.width

            Repeater {
                id: repeater
                delegate: DeviceRow {}
            }
        }
    }

    Item {
        id: header
        width: parent.width
        height: 40

        CircleButton {
            id: backBtn
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            glyph: "‹"
            glyphSize: 26
            onClicked: root.backRequested()
        }

        Column {
            anchors.left: backBtn.right
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: "Bluetooth"
                color: Theme.textPrimary
                font.pixelSize: 18
                font.weight: Font.Bold
                font.family: Theme.fontFamily
            }

            Text {
                text: !BluetoothManager.available ? "No adapter found"
                    : !BluetoothManager.enabled ? "Turned off"
                    : BluetoothManager.scanning ? "Searching for devices…"
                    : `${BluetoothManager.connectedDevices.length} connected  ·  ${BluetoothManager.pairedDevices.length} paired`
                color: Theme.textSecondary
                font.pixelSize: 11
                font.family: Theme.fontFamily
            }
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            CircleButton {
                anchors.verticalCenter: parent.verticalCenter
                glyph: "↻"
                glyphSize: 18
                visible: BluetoothManager.enabled
                spinning: BluetoothManager.scanning
                onClicked: BluetoothManager.toggleScan()
            }

            Toggle {
                anchors.verticalCenter: parent.verticalCenter
                visible: BluetoothManager.available
                checked: BluetoothManager.enabled
                onToggled: on => BluetoothManager.setEnabled(on)
            }
        }
    }

    Column {
        anchors.centerIn: flick
        spacing: 10
        visible: !flick.visible

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 56
            height: 56
            radius: 28
            color: Theme.tileBg

            BluetoothIcon {
                anchors.centerIn: parent
                width: 18
                height: 27
                color: Theme.textSecondary
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: !BluetoothManager.available ? "No Bluetooth adapter"
                : !BluetoothManager.enabled ? "Bluetooth is off"
                : "No devices found"
            color: Theme.textPrimary
            font.pixelSize: 14
            font.weight: Font.DemiBold
            font.family: Theme.fontFamily
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: BluetoothManager.available
            text: !BluetoothManager.enabled ? "Turn it on to connect your devices"
                : "Put your device in pairing mode, then search"
            color: Theme.textSecondary
            font.pixelSize: 12
            font.family: Theme.fontFamily
        }
    }

    Flickable {
        id: flick
        anchors.top: header.bottom
        anchors.topMargin: 16
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        contentWidth: width
        contentHeight: body.height + 12
        boundsBehavior: Flickable.StopAtBounds
        visible: BluetoothManager.enabled && (BluetoothManager.devices.length > 0 || BluetoothManager.scanning)

        Column {
            id: body
            width: flick.width
            spacing: 8

            Repeater {
                model: root.connected
                delegate: ConnectedCard {}
            }

            Item { width: 1; height: 4; visible: root.connected.length > 0 && root.mine.length > 0 }

            SectionLabel {
                visible: root.mine.length > 0
                text: "My devices"
            }

            Group {
                visible: root.mine.length > 0
                model: root.mine
            }

            Item { width: 1; height: 4; visible: root.others.length > 0 || BluetoothManager.scanning }

            SectionLabel {
                visible: root.others.length > 0 || BluetoothManager.scanning
                text: "Other devices"
                busy: BluetoothManager.scanning
            }

            Group {
                visible: root.others.length > 0 || BluetoothManager.scanning
                model: root.others

                // Stands in for the list while a search hasn't found anything yet
                Item {
                    width: parent.width
                    height: 46
                    visible: root.others.length === 0

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Searching for devices…"
                        color: Theme.textSecondary
                        font.pixelSize: 12
                        font.family: Theme.fontFamily
                    }
                }
            }
        }
    }

    // Fade the list out where it scrolls under the page edge
    Rectangle {
        anchors.left: flick.left
        anchors.right: flick.right
        anchors.bottom: flick.bottom
        height: 28
        visible: flick.visible && flick.contentY + flick.height < flick.contentHeight - 1
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.alpha(Theme.islandBg, 0) }
            GradientStop { position: 1.0; color: Theme.islandBg }
        }
    }
}
