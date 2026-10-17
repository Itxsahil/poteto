import QtQuick
import qs.config
import qs.services

// The Wi-Fi menu, a page of the control center: the radio switch and every network in range.
// Click a network to join it (asking for a password the first time), hover one to leave or
// forget it.
Item {
    id: root

    property bool active: false
    readonly property int rowHeight: 46
    readonly property int maxRows: 6
    // The network whose password is being asked for
    property string asking: ""

    signal backRequested()

    function choose(net) {
        if (net.active || Wifi.connectingSsid)
            return;
        if (net.secure && !Wifi.isSaved(net.ssid))
            ask(net.ssid);
        else {
            asking = "";
            Wifi.connect(net.ssid, "");
        }
    }

    function ask(ssid) {
        asking = ssid;
        password.text = "";
        password.forceActiveFocus();
    }

    function submit() {
        if (!asking || !password.text)
            return;
        Wifi.connect(asking, password.text);
        asking = "";
        password.text = "";
        keys.forceActiveFocus();
    }

    function glyphFor(signal) {
        return signal >= 75 ? "󰤨" : signal >= 50 ? "󰤥" : signal >= 25 ? "󰤢" : "󰤟";
    }

    onActiveChanged: {
        if (active) {
            keys.forceActiveFocus();
            Wifi.rescan();
        } else {
            asking = "";
        }
    }

    // A wrong password asks again, right away
    Connections {
        target: Wifi
        function onErrorSsidChanged() {
            if (root.active && Wifi.errorSsid && Wifi.errorText === "Incorrect password")
                root.ask(Wifi.errorSsid);
        }
    }

    implicitHeight: column.implicitHeight

    Item {
        id: keys
        Keys.onEscapePressed: root.backRequested()
    }

    Column {
        id: column
        width: parent.width
        spacing: 10

        PageHeader {
            title: "Wi-Fi"
            checked: Wifi.enabled
            scanning: Wifi.scanning
            onBackClicked: root.backRequested()
            onRescanClicked: Wifi.rescan()
            onToggled: on => Wifi.setEnabled(on)
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.border
        }

        // Shown instead of the list when there is nothing to list
        Text {
            width: parent.width
            height: 60
            visible: !Wifi.enabled || Wifi.networks.length === 0
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: !Wifi.enabled ? "Wi-Fi is off" : !Wifi.device ? "No Wi-Fi adapter" : "Looking for networks…"
            color: Theme.textDim
            font.pixelSize: 13
            font.family: Theme.fontFamily
        }

        ListView {
            id: list
            width: parent.width
            visible: Wifi.enabled && count > 0
            height: Math.min(contentHeight, root.maxRows * root.rowHeight)
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: Wifi.enabled ? Wifi.networks : []
            spacing: 2

            delegate: Rectangle {
                id: row

                required property var modelData
                readonly property var net: modelData
                readonly property bool connecting: Wifi.connectingSsid === net.ssid
                readonly property bool failed: Wifi.errorSsid === net.ssid && !connecting
                readonly property bool saved: Wifi.isSaved(net.ssid)
                readonly property bool asking: root.asking === net.ssid

                width: list.width
                height: root.rowHeight + (asking ? 44 : 0)
                radius: 12
                color: asking || net.active ? Theme.tile
                    : hover.containsMouse ? Qt.alpha(Theme.tile, 0.7)
                    : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                clip: true

                MouseArea {
                    id: hover
                    width: parent.width
                    height: root.rowHeight
                    hoverEnabled: true
                    cursorShape: row.net.active ? Qt.ArrowCursor : Qt.PointingHandCursor
                    onClicked: row.asking ? (root.asking = "") : root.choose(row.net)
                }

                Item {
                    width: parent.width
                    height: root.rowHeight

                    // Signal strength, in a circle that fills in once connected
                    Rectangle {
                        id: badge
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 30
                        height: 30
                        radius: 15
                        color: row.net.active ? Theme.accent : Theme.tileHover

                        Text {
                            anchors.centerIn: parent
                            text: root.glyphFor(row.net.signal)
                            color: row.net.active ? Theme.accentText : Theme.text
                            font.pixelSize: 15
                            font.family: Theme.monoFamily
                        }
                    }

                    Column {
                        anchors.left: badge.right
                        anchors.leftMargin: 10
                        anchors.right: actions.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: row.net.ssid
                            color: Theme.text
                            font.pixelSize: 13
                            font.weight: row.net.active ? Font.DemiBold : Font.Medium
                            font.family: Theme.fontFamily
                        }

                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            visible: text !== ""
                            text: row.connecting ? "Connecting…"
                                : row.failed ? Wifi.errorText
                                : row.net.active ? "Connected"
                                : row.saved ? "Saved"
                                : ""
                            color: row.failed ? Theme.danger : Theme.textDim
                            font.pixelSize: 11
                            font.family: Theme.fontFamily
                        }
                    }

                    Row {
                        id: actions
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        // Hover-only: leave the network, or forget a saved one
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: row.net.active && (hover.containsMouse || leaveMouse.containsMouse || forget.hovered)
                            width: leaveText.implicitWidth + 20
                            height: 26
                            radius: 13
                            color: leaveMouse.containsMouse ? Theme.tileHover : Theme.background

                            Text {
                                id: leaveText
                                anchors.centerIn: parent
                                text: "Disconnect"
                                color: Theme.text
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                font.family: Theme.fontFamily
                            }

                            MouseArea {
                                id: leaveMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Wifi.disconnect()
                            }
                        }

                        RoundButton {
                            id: forget
                            anchors.verticalCenter: parent.verticalCenter
                            visible: row.saved && (hover.containsMouse || leaveMouse.containsMouse || hovered)
                            implicitWidth: 26
                            implicitHeight: 26
                            flat: true
                            glyph: "󰆴"
                            glyphSize: 13
                            onClicked: Wifi.forget(row.net.ssid)
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: row.net.secure
                            text: "󰌾"
                            color: Theme.textDim
                            font.pixelSize: 12
                            font.family: Theme.monoFamily
                        }
                    }
                }

                // Password, for a secured network that is not saved yet
                Rectangle {
                    y: root.rowHeight
                    x: 8
                    width: parent.width - 16
                    height: 34
                    radius: 10
                    visible: row.asking
                    color: Theme.background
                    border.color: password.activeFocus && row.asking ? Theme.accent : Theme.border
                    border.width: 1

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        visible: password.text === ""
                        text: "Password"
                        color: Theme.textDim
                        font.pixelSize: 13
                        font.family: Theme.fontFamily
                    }

                    // The one text field lives outside the list (see below); this shows its place
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.right: reveal.left
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        visible: row.asking
                        clip: true
                        text: password.displayText
                        color: Theme.text
                        font.pixelSize: 13
                        font.family: Theme.fontFamily

                        // A caret, since the real field is not the one drawn
                        Rectangle {
                            x: Math.min(parent.contentWidth + 1, parent.width - 2)
                            anchors.verticalCenter: parent.verticalCenter
                            width: 1.5
                            height: 16
                            color: Theme.accent
                            visible: password.activeFocus && blink.on

                            Timer {
                                id: blink
                                property bool on: true
                                interval: 530
                                repeat: true
                                running: password.activeFocus
                                onRunningChanged: on = true
                                onTriggered: on = !on
                            }
                        }
                    }

                    RoundButton {
                        id: reveal
                        anchors.right: join.left
                        anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: 26
                        implicitHeight: 26
                        flat: true
                        glyph: password.echoMode === TextInput.Password ? "󰈈" : "󰈉"
                        glyphSize: 13
                        onClicked: {
                            password.echoMode = password.echoMode === TextInput.Password ? TextInput.Normal : TextInput.Password;
                            password.forceActiveFocus();
                        }
                    }

                    Rectangle {
                        id: join
                        anchors.right: parent.right
                        anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        width: joinText.implicitWidth + 22
                        height: 26
                        radius: 8
                        color: password.text ? Theme.accent : Theme.tileHover
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            id: joinText
                            anchors.centerIn: parent
                            text: "Join"
                            color: password.text ? Theme.accentText : Theme.textDim
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            font.family: Theme.fontFamily
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.submit()
                        }
                    }
                }
            }
        }
    }

    // The password field itself. It is kept out of the list so a rescan that rebuilds the rows
    // does not throw away what is being typed; the row only draws it.
    TextInput {
        id: password
        width: 0
        height: 0
        opacity: 0
        echoMode: TextInput.Password
        passwordCharacter: "•"
        onAccepted: root.submit()
        Keys.onEscapePressed: {
            root.asking = "";
            keys.forceActiveFocus();
        }
    }
}
