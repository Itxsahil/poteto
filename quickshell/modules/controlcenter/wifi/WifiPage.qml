import QtQuick
import qs.config
import qs.components
import qs.components.icons
import qs.services

Item {
    id: root

    property string expandedSsid: ""
    readonly property bool typing: list.typing

    signal backRequested()

    function reset() {
        expandedSsid = "";
        list.positionViewAtBeginning();
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
        anchors.centerIn: list
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

    ListView {
        id: list

        property bool typing: false

        anchors.top: header.bottom
        anchors.topMargin: 14
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        spacing: 6
        visible: Wifi.enabled
        model: Wifi.enabled ? Wifi.networks : []
        boundsBehavior: Flickable.StopAtBounds

        add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 } }

        delegate: Rectangle {
            id: row

            required property var modelData
            readonly property string ssid: modelData.ssid
            readonly property bool isActive: modelData.active
            readonly property bool isSaved: Wifi.savedNames.includes(ssid)
            readonly property bool isConnecting: Wifi.connectingSsid === ssid
            readonly property bool hasError: Wifi.errorSsid === ssid
            readonly property bool expanded: root.expandedSsid === ssid
            readonly property bool needsPassword: modelData.secure && (!isSaved || hasError)

            width: ListView.view.width
            height: 52 + (expanded ? detail.implicitHeight + 10 : 0)
            radius: 16
            color: expanded || rowMouse.containsMouse ? Theme.tileHover : Theme.tileBg
            clip: true

            Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 120 } }

            function activate() {
                if (isConnecting)
                    return;
                if (!isActive && !modelData.secure) {
                    Wifi.connect(ssid, "");
                    return;
                }
                root.expandedSsid = expanded ? "" : ssid;
            }

            MouseArea {
                id: rowMouse
                width: parent.width
                height: 52
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: row.activate()
            }

            WifiIcon {
                id: sigIcon
                x: 16
                y: 26 - height / 2
                width: 20
                height: 16
                strength: row.modelData.signal
                color: row.isActive ? Theme.accent : Theme.textPrimary
            }

            Column {
                anchors.left: sigIcon.right
                anchors.leftMargin: 14
                anchors.right: trailing.left
                anchors.rightMargin: 10
                y: 26 - height / 2
                spacing: 1

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: row.ssid
                    color: Theme.textPrimary
                    font.pixelSize: 13
                    font.weight: row.isActive ? Font.DemiBold : Font.Normal
                    font.family: Theme.fontFamily
                }

                Text {
                    text: row.isConnecting ? "Connecting…"
                        : row.isActive ? "Connected"
                        : row.hasError ? Wifi.errorText
                        : row.isSaved ? "Saved"
                        : row.modelData.secure ? "Secured" : "Open"
                    color: row.isActive || row.isConnecting ? Theme.accent
                        : row.hasError ? Theme.danger
                        : Theme.textSecondary
                    font.pixelSize: 11
                    font.family: Theme.fontFamily
                }
            }

            Row {
                id: trailing
                anchors.right: parent.right
                anchors.rightMargin: 16
                y: 26 - height / 2
                spacing: 10

                Canvas {
                    id: lock
                    width: 10
                    height: 13
                    anchors.verticalCenter: parent.verticalCenter
                    visible: row.modelData.secure && !row.isActive && !row.isConnecting
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

                Spinner {
                    width: 18
                    height: 18
                    anchors.verticalCenter: parent.verticalCenter
                    visible: row.isConnecting
                }

                CheckIcon {
                    width: 16
                    height: 12
                    anchors.verticalCenter: parent.verticalCenter
                    visible: row.isActive && !row.isConnecting
                }
            }

            Column {
                id: detail
                x: 16
                y: 52
                width: parent.width - 32
                spacing: 8
                opacity: row.expanded ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 180 } }

                Row {
                    spacing: 8
                    visible: row.needsPassword && !row.isActive

                    Rectangle {
                        id: field
                        width: detail.width - connectBtn.width - 8
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
                            onActiveFocusChanged: list.typing = activeFocus
                            onAccepted: if (text.length > 0) Wifi.connect(row.ssid, text)
                            Keys.onEscapePressed: {
                                text = "";
                                root.expandedSsid = "";
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: !input.text && !input.activeFocus
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
                        id: connectBtn
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
                            if (row.expanded && row.needsPassword && !row.isActive)
                                input.forceActiveFocus();
                            if (!row.expanded)
                                input.text = "";
                        }
                    }
                }

                Row {
                    spacing: 8
                    visible: !row.needsPassword || row.isActive

                    PillButton {
                        visible: !row.isActive
                        text: row.isConnecting ? "Connecting…" : "Connect"
                        primary: true
                        enabled: !row.isConnecting
                        onClicked: Wifi.connect(row.ssid, "")
                    }

                    PillButton {
                        visible: row.isActive
                        text: "Disconnect"
                        onClicked: {
                            Wifi.disconnect();
                            root.expandedSsid = "";
                        }
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
    }
}
