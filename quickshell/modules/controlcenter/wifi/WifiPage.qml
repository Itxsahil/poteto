import QtQuick
import qs.config
import qs.components
import qs.components.icons
import qs.services

Item {
    id: root

    property string expandedSsid: ""
    property bool typing: false

    readonly property var current: Wifi.active
    readonly property var liveKnown: Wifi.networks.filter(n => !n.active && Wifi.savedNames.includes(n.ssid))
    readonly property var liveOthers: Wifi.networks.filter(n => !n.active && !Wifi.savedNames.includes(n.ssid))

    // Every refresh builds new arrays, and a new array rebuilds every row, which would wipe a
    // half-typed password. So the lists only follow the scan results while nothing is being typed.
    property var known: []
    property var others: []

    // What a row shows. Raw signal wobbles every scan, so it's bucketed the way WifiIcon draws it.
    function signature(list) {
        return list.map(n => `${n.ssid}\u0001${n.secure}\u0001${n.signal >= 75 ? 3 : n.signal >= 50 ? 2 : n.signal >= 25 ? 1 : 0}`).join("\u0002");
    }

    function sync() {
        if (typing)
            return;
        if (signature(liveKnown) !== signature(known))
            known = liveKnown;
        if (signature(liveOthers) !== signature(others))
            others = liveOthers;
    }

    onLiveKnownChanged: sync()
    onLiveOthersChanged: sync()
    onTypingChanged: sync()
    Component.onCompleted: sync()

    signal backRequested()

    function reset() {
        expandedSsid = "";
        flick.contentY = 0;
    }

    function quality(signal) {
        return signal >= 75 ? "Excellent signal" : signal >= 50 ? "Good signal" : signal >= 25 ? "Fair signal" : "Weak signal";
    }

    Connections {
        target: Wifi
        function onErrorSsidChanged() {
            if (Wifi.errorSsid)
                root.expandedSsid = Wifi.errorSsid;
        }
        function onConnectingSsidChanged() {
            if (!Wifi.connectingSsid && !Wifi.errorSsid)
                root.expandedSsid = "";
        }
    }

    component SectionLabel: Text {
        leftPadding: 6
        color: Theme.textSecondary
        font.pixelSize: 11
        font.weight: Font.DemiBold
        font.letterSpacing: 0.4
        font.family: Theme.fontFamily
    }

    component Lock: Canvas {
        width: 10
        height: 13
        property color tint: Theme.textSecondary
        onTintChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.strokeStyle = tint;
            ctx.fillStyle = tint;
            ctx.lineWidth = 1.6;
            ctx.beginPath();
            ctx.arc(5, 5, 3, Math.PI, 0);
            ctx.lineTo(8, 6);
            ctx.moveTo(2, 6);
            ctx.lineTo(2, 5);
            ctx.stroke();
            ctx.beginPath();
            ctx.roundedRect(0, 6, 10, 7, 1.5, 1.5);
            ctx.fill();
        }
    }

    // One network inside a grouped list: a single line, with the password field or
    // actions sliding out underneath when it is expanded.
    component NetworkRow: Item {
        id: row

        required property var modelData
        required property int index
        readonly property string ssid: modelData.ssid
        readonly property bool isSaved: Wifi.savedNames.includes(ssid)
        readonly property bool isConnecting: Wifi.connectingSsid === ssid
        readonly property bool hasError: Wifi.errorSsid === ssid
        readonly property bool expanded: root.expandedSsid === ssid
        readonly property bool needsPassword: modelData.secure && (!isSaved || hasError)
        readonly property bool hasStatus: isConnecting || hasError
        readonly property int lineHeight: hasStatus ? 52 : 46

        width: parent.width
        height: lineHeight + (expanded ? detail.implicitHeight + 12 : 0)
        clip: true

        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        // Follows the expand animation so the password field never opens under the bottom fade.
        // Deferred, because the Column relays out (and the content grows) after this height change.
        onHeightChanged: if (expanded) Qt.callLater(ensureVisible)

        function ensureVisible() {
            const bottom = mapToItem(body, 0, height).y + 28;
            if (bottom > flick.contentY + flick.height)
                flick.contentY = Math.min(bottom - flick.height, Math.max(0, flick.contentHeight - flick.height));
        }

        function activate() {
            if (isConnecting)
                return;
            if (!modelData.secure) {
                Wifi.connect(ssid, "");
                return;
            }
            root.expandedSsid = expanded ? "" : ssid;
        }

        Rectangle {
            visible: row.index > 0
            x: 48
            width: parent.width - 60
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
            onClicked: row.activate()
        }

        WifiIcon {
            id: sigIcon
            x: 16
            y: row.lineHeight / 2 - height / 2
            width: 18
            height: 14
            strength: row.modelData.signal
        }

        Column {
            anchors.left: sigIcon.right
            anchors.leftMargin: 14
            anchors.right: trailing.left
            anchors.rightMargin: 10
            y: row.lineHeight / 2 - height / 2
            spacing: 1

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: row.ssid
                color: Theme.textPrimary
                font.pixelSize: 13
                font.family: Theme.fontFamily
            }

            Text {
                visible: row.hasStatus
                text: row.isConnecting ? "Connecting…" : Wifi.errorText
                color: row.isConnecting ? Theme.accent : Theme.danger
                font.pixelSize: 11
                font.family: Theme.fontFamily
            }
        }

        Item {
            id: trailing
            anchors.right: parent.right
            anchors.rightMargin: 18
            y: row.lineHeight / 2 - height / 2
            width: 18
            height: 18

            Lock {
                anchors.centerIn: parent
                visible: row.modelData.secure && !row.isConnecting
            }

            Spinner {
                anchors.fill: parent
                visible: row.isConnecting
            }
        }

        Column {
            id: detail
            x: 16
            y: row.lineHeight
            width: parent.width - 32
            spacing: 8
            opacity: row.expanded ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            Row {
                spacing: 8
                visible: row.needsPassword

                Rectangle {
                    width: detail.width - joinBtn.width - 8
                    height: 36
                    radius: 12
                    color: Theme.controlBg
                    border.width: 1
                    border.color: input.activeFocus ? Theme.accent : row.hasError ? Theme.danger : "transparent"

                    TextInput {
                        id: input
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.right: showBtn.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        echoMode: showBtn.revealed ? TextInput.Normal : TextInput.Password
                        color: Theme.textPrimary
                        selectionColor: Theme.accent
                        selectedTextColor: Theme.onAccent
                        font.pixelSize: 13
                        font.family: Theme.fontFamily
                        clip: true
                        enabled: !row.isConnecting
                        onActiveFocusChanged: root.typing = activeFocus
                        onAccepted: if (text.length >= 8) Wifi.connect(row.ssid, text)
                        Keys.onEscapePressed: {
                            text = "";
                            root.expandedSsid = "";
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !input.text
                            text: "Password"
                            color: Theme.textSecondary
                            font: input.font
                        }
                    }

                    Text {
                        id: showBtn
                        property bool revealed: false
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: revealed ? "Hide" : "Show"
                        color: Theme.textSecondary
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        font.family: Theme.fontFamily

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: showBtn.revealed = !showBtn.revealed
                        }
                    }
                }

                PillButton {
                    id: joinBtn
                    anchors.verticalCenter: parent.verticalCenter
                    height: 36
                    radius: 12
                    text: row.isConnecting ? "Joining…" : "Join"
                    primary: true
                    enabled: input.text.length >= 8 && !row.isConnecting
                    onClicked: Wifi.connect(row.ssid, input.text)
                }

                Connections {
                    target: row
                    function onExpandedChanged() {
                        if (row.expanded && row.needsPassword)
                            input.forceActiveFocus();
                        if (!row.expanded)
                            input.text = "";
                    }
                }
            }

            Row {
                spacing: 8
                visible: !row.needsPassword

                PillButton {
                    text: row.isConnecting ? "Connecting…" : "Connect"
                    primary: true
                    enabled: !row.isConnecting
                    onClicked: Wifi.connect(row.ssid, "")
                }

                PillButton {
                    visible: row.isSaved
                    text: "Forget"
                    danger: true
                    onClicked: {
                        Wifi.forget(row.ssid);
                        root.expandedSsid = "";
                    }
                }
            }
        }
    }

    component Group: Rectangle {
        property alias model: repeater.model
        width: parent.width
        height: rows.height
        radius: 18
        color: Theme.tileBg

        Column {
            id: rows
            width: parent.width

            Repeater {
                id: repeater
                delegate: NetworkRow {}
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
                text: "Wi-Fi"
                color: Theme.textPrimary
                font.pixelSize: 18
                font.weight: Font.Bold
                font.family: Theme.fontFamily
            }

            Text {
                text: !Wifi.enabled ? "Turned off"
                    : Wifi.scanning ? "Scanning…"
                    : `${Wifi.networks.length} networks nearby`
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
                visible: Wifi.enabled
                spinning: Wifi.scanning
                onClicked: Wifi.rescan()
            }

            Toggle {
                anchors.verticalCenter: parent.verticalCenter
                checked: Wifi.enabled
                onToggled: on => Wifi.setEnabled(on)
            }
        }
    }

    Column {
        anchors.centerIn: flick
        spacing: 10
        visible: !Wifi.enabled || (Wifi.networks.length === 0 && !Wifi.scanning)

        WifiIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 54
            height: 42
            connected: false
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Wifi.enabled ? "No networks found" : "Wi-Fi is off"
            color: Theme.textPrimary
            font.pixelSize: 14
            font.weight: Font.DemiBold
            font.family: Theme.fontFamily
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Wifi.enabled ? "Try scanning again" : "Turn it on to see nearby networks"
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
        visible: Wifi.enabled && Wifi.networks.length > 0
        contentWidth: width
        contentHeight: body.height + 12
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: body
            width: flick.width
            spacing: 8

            // The network you're on, set apart from the rest
            Rectangle {
                id: hero
                readonly property bool expanded: root.current !== null && root.expandedSsid === root.current.ssid
                visible: root.current !== null
                width: parent.width
                height: 68 + (expanded ? heroActions.height + 12 : 0)
                radius: 18
                color: Qt.alpha(Theme.accent, heroMouse.containsMouse || expanded ? 0.2 : 0.14)
                border.width: 1
                border.color: Qt.alpha(Theme.accent, 0.3)
                clip: true
                Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 120 } }

                MouseArea {
                    id: heroMouse
                    width: parent.width
                    height: 68
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.expandedSsid = hero.expanded ? "" : root.current.ssid
                }

                Rectangle {
                    id: heroBadge
                    x: 14
                    y: 14
                    width: 40
                    height: 40
                    radius: 20
                    color: Theme.accent

                    WifiIcon {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -1
                        width: 20
                        height: 16
                        strength: root.current?.signal ?? 0
                        color: Theme.onAccent
                        dimColor: Qt.alpha(Theme.onAccent, 0.35)
                    }
                }

                Column {
                    anchors.left: heroBadge.right
                    anchors.leftMargin: 12
                    anchors.right: chevron.left
                    anchors.rightMargin: 10
                    y: 34 - height / 2
                    spacing: 2

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: root.current?.ssid ?? ""
                        color: Theme.textPrimary
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        font.family: Theme.fontFamily
                    }

                    Text {
                        text: `Connected · ${root.quality(root.current?.signal ?? 0)}`
                        color: Theme.accent
                        font.pixelSize: 11
                        font.family: Theme.fontFamily
                    }
                }

                Text {
                    id: chevron
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    y: 34 - height / 2
                    text: "›"
                    rotation: hero.expanded ? 90 : 0
                    color: Theme.textSecondary
                    font.pixelSize: 20
                    font.family: Theme.fontFamily
                    Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                }

                Row {
                    id: heroActions
                    x: 14
                    y: 68
                    spacing: 8
                    opacity: hero.expanded ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 180 } }

                    PillButton {
                        text: "Disconnect"
                        onClicked: {
                            Wifi.disconnect();
                            root.expandedSsid = "";
                        }
                    }

                    PillButton {
                        visible: root.current !== null && Wifi.savedNames.includes(root.current.ssid)
                        text: "Forget"
                        danger: true
                        onClicked: {
                            Wifi.forget(root.current.ssid);
                            root.expandedSsid = "";
                        }
                    }
                }
            }

            Item { width: 1; height: 4; visible: root.current !== null && root.known.length > 0 }

            SectionLabel {
                visible: root.known.length > 0
                text: "Known networks"
            }

            Group {
                visible: root.known.length > 0
                model: root.known
            }

            Item { width: 1; height: 4; visible: root.others.length > 0 }

            SectionLabel {
                visible: root.others.length > 0
                text: "Other networks"
            }

            Group {
                visible: root.others.length > 0
                model: root.others
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
