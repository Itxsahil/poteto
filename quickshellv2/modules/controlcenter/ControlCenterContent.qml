import QtQuick
import Quickshell
import qs.config
import qs.services

// The control center, with no surface of its own: the pill grows into it in pill mode, and a
// panel drops down from the bar in bar mode.
//
// Mostly a design for now: Wi-Fi (services/Wifi.qml; its label or a right click opens the Wi-Fi
// menu, WifiPage.qml), Dark (the desktop's light/dark mode, Config.mode), Night (night light,
// services/NightLight.qml), the Sound slider (services/Audio.qml; click "Sound" to mute), the
// Screen slider (services/Brightness.qml) and the settings button (opens Poteto) are real. Every
// other toggle and button changes only what is drawn here; none of it reaches Bluetooth, the
// player or the session yet.
Item {
    id: root

    property bool active: false
    readonly property string page: ShellState.page

    // Stand-in state, so the controls can be tried
    property var toggles: ({ bluetooth: false, quiet: false, awake: false, airplane: false })
    property bool playing: true

    signal closeRequested()

    function flip(id) {
        const next = Object.assign({}, toggles);
        next[id] = !next[id];
        toggles = next;
    }

    onActiveChanged: {
        if (active && page === "main")
            keys.forceActiveFocus();
    }
    // Always opens on the main page
    onVisibleChanged: {
        if (!visible)
            ShellState.page = "main";
    }
    onPageChanged: {
        if (page === "main" && active)
            keys.forceActiveFocus();
    }

    implicitWidth: 448
    implicitHeight: page === "wifi" ? wifi.implicitHeight : column.implicitHeight

    Item {
        id: keys
        focus: root.active
        Keys.onEscapePressed: root.closeRequested()
    }

    WifiPage {
        id: wifi
        width: parent.width
        active: root.active && root.page === "wifi"
        opacity: root.page === "wifi" ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }
        onBackRequested: ShellState.page = "main"
    }

    Column {
        id: column
        width: parent.width
        spacing: 12
        opacity: root.page === "main" ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }

        // Quick toggles
        Row {
            id: toggleRow

            readonly property var items: [
                { id: "wifi", label: "Wi-Fi", glyph: "󰖩" },
                { id: "bluetooth", label: "Bluetooth", glyph: "󰂯" },
                { id: "quiet", label: "Quiet", glyph: "󰽥" },
                { id: "dark", label: "Dark", glyph: "󰔎" },
                { id: "night", label: "Night", glyph: "󰖨" },
                { id: "awake", label: "Awake", glyph: "󰅶" },
                { id: "airplane", label: "Airplane", glyph: "󰀝" }
            ]

            width: parent.width

            Repeater {
                model: toggleRow.items

                Column {
                    id: toggle

                    required property var modelData
                    readonly property bool isWifi: modelData.id === "wifi"
                    readonly property bool isOn: isWifi ? Wifi.enabled
                        : modelData.id === "dark" ? Config.mode === "dark"
                        : modelData.id === "night" ? NightLight.enabled
                        : root.toggles[modelData.id] ?? false

                    width: toggleRow.width / toggleRow.items.length
                    spacing: 6

                    RoundButton {
                        anchors.horizontalCenter: parent.horizontalCenter
                        glyph: toggle.modelData.glyph
                        on: toggle.isOn
                        onClicked: toggle.isWifi ? Wifi.setEnabled(!Wifi.enabled)
                            : toggle.modelData.id === "dark" ? Config.toggleMode()
                            : toggle.modelData.id === "night" ? NightLight.toggle()
                            : root.flip(toggle.modelData.id)
                        onSecondaryClicked: {
                            if (toggle.isWifi)
                                ShellState.openPage("wifi");
                        }
                    }

                    // Wi-Fi's label names the network and opens the Wi-Fi menu
                    Item {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: name.width + (chevron.visible ? chevron.implicitWidth + 2 : 0)
                        height: name.implicitHeight

                        Text {
                            id: name
                            // A long network name is cut short, with room left for the chevron
                            width: toggle.isWifi ? Math.min(implicitWidth, toggle.width - 12) : implicitWidth
                            elide: Text.ElideRight
                            text: toggle.isWifi && Wifi.enabled && Wifi.active ? Wifi.active.ssid : toggle.modelData.label
                            color: toggle.isOn || labelMouse.containsMouse ? Theme.text : Theme.textDim
                            font.pixelSize: 11
                            font.family: Theme.fontFamily
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }

                        Text {
                            id: chevron
                            visible: toggle.isWifi
                            anchors.left: name.right
                            anchors.leftMargin: 2
                            anchors.verticalCenter: name.verticalCenter
                            text: "󰅂"
                            color: labelMouse.containsMouse ? Theme.text : Theme.textDim
                            font.pixelSize: 10
                            font.family: Theme.monoFamily
                        }

                        MouseArea {
                            id: labelMouse
                            anchors.fill: parent
                            anchors.margins: -4
                            enabled: toggle.isWifi
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ShellState.openPage("wifi")
                        }
                    }
                }
            }
        }

        DotSlider {
            width: parent.width
            label: "Sound"
            visible: Audio.available
            value: Audio.percent
            maxValue: Audio.maxPercent
            dimmed: Audio.muted
            labelClickable: true
            onMoved: v => Audio.setPercent(v)
            onLabelClicked: Audio.toggleMute()
        }

        DotSlider {
            width: parent.width
            label: "Screen"
            visible: Brightness.available
            value: Brightness.percent
            onMoved: v => Brightness.set(v)
        }

        // Now playing, then the session
        Item {
            width: parent.width
            height: 34

            RoundButton {
                id: record
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: 34
                implicitHeight: 34

                Rectangle {
                    anchors.centerIn: parent
                    width: 10
                    height: 10
                    radius: 5
                    color: Theme.danger
                }
            }

            Column {
                anchors.left: record.right
                anchors.leftMargin: 10
                anchors.right: transport.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: "Song name"
                    color: Theme.text
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    font.family: Theme.fontFamily
                }

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: "Artist"
                    color: Theme.textDim
                    font.pixelSize: 11
                    font.family: Theme.fontFamily
                }
            }

            Row {
                id: transport
                anchors.right: divider.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                RoundButton {
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: 30
                    implicitHeight: 30
                    flat: true
                    glyph: "󰒮"
                    glyphSize: 14
                }

                // Play / pause: the one solid button in the row
                RoundButton {
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: 32
                    implicitHeight: 32
                    on: true
                    onColor: Theme.text
                    onGlyph: Theme.background
                    glyph: root.playing ? "󰏤" : "󰐊"
                    glyphSize: 14
                    onClicked: root.playing = !root.playing
                }

                RoundButton {
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: 30
                    implicitHeight: 30
                    flat: true
                    glyph: "󰒭"
                    glyphSize: 14
                }
            }

            Rectangle {
                id: divider
                anchors.right: session.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 18
                color: Theme.border
            }

            Row {
                id: session
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                // Settings: opens Poteto (settings/poteto-settings), and gets out of its way
                RoundButton {
                    implicitWidth: 32
                    implicitHeight: 32
                    glyph: "󰒓"
                    glyphSize: 14
                    onClicked: {
                        Quickshell.execDetached(["poteto-settings"]);
                        root.closeRequested();
                    }
                }

                RoundButton {
                    implicitWidth: 32
                    implicitHeight: 32
                    glyph: "󰌾"
                    glyphSize: 14
                }

                RoundButton {
                    implicitWidth: 32
                    implicitHeight: 32
                    glyph: "󰜉"
                    glyphSize: 14
                }

                RoundButton {
                    implicitWidth: 32
                    implicitHeight: 32
                    on: true
                    onColor: Theme.danger
                    onGlyph: Theme.background
                    glyph: "⏻"
                    glyphSize: 14
                }
            }
        }
    }
}
