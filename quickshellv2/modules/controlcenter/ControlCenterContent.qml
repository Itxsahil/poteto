import QtQuick
import qs.config

// The control center, with no surface of its own: the pill grows into it in pill mode, and a
// panel drops down from the bar in bar mode.
//
// Mostly a design for now: apart from Dark (the desktop's light/dark mode, Config.mode), every
// toggle, slider and button changes only what is drawn here. None of it reaches Wi-Fi, Bluetooth,
// audio, brightness, the player or the session yet.
Item {
    id: root

    property bool active: false

    // Stand-in state, so the controls can be tried
    property var toggles: ({ wifi: true, bluetooth: false, quiet: false, night: true, awake: false, airplane: false })
    property real sound: 62
    property real screen: 80
    property bool playing: true

    signal closeRequested()

    function flip(id) {
        const next = Object.assign({}, toggles);
        next[id] = !next[id];
        toggles = next;
    }

    onActiveChanged: {
        if (active)
            keys.forceActiveFocus();
    }

    implicitWidth: 448
    implicitHeight: column.implicitHeight

    readonly property string iconFont: "JetBrainsMono Nerd Font"

    // A round icon button: a quick toggle at the top, a session button at the bottom
    component RoundButton: Rectangle {
        id: button

        property string glyph
        property int glyphSize: 15
        property bool on: false
        // No background until hovered, for the skip buttons beside play/pause
        property bool flat: false
        property color onColor: Theme.accent
        property color onGlyph: Theme.onAccent
        signal clicked()

        implicitWidth: 42
        implicitHeight: 42
        radius: width / 2
        color: on ? (mouse.containsMouse ? Qt.lighter(onColor, 1.12) : onColor)
            : flat ? (mouse.containsMouse ? Theme.tile : "transparent")
            : mouse.containsMouse ? Theme.tileHover : Theme.tile
        scale: mouse.pressed ? 0.92 : 1
        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on scale { NumberAnimation { duration: 90 } }

        Text {
            anchors.centerIn: parent
            text: button.glyph
            color: button.on ? button.onGlyph : Theme.text
            font.pixelSize: button.glyphSize
            font.family: root.iconFont
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }

    Item {
        id: keys
        focus: root.active
        Keys.onEscapePressed: root.closeRequested()
    }

    Column {
        id: column
        width: parent.width
        spacing: 12

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
                    readonly property bool isOn: modelData.id === "dark" ? Config.mode === "dark"
                        : root.toggles[modelData.id] ?? false

                    width: toggleRow.width / toggleRow.items.length
                    spacing: 6

                    RoundButton {
                        anchors.horizontalCenter: parent.horizontalCenter
                        glyph: toggle.modelData.glyph
                        on: toggle.isOn
                        onClicked: toggle.modelData.id === "dark" ? Config.toggleMode() : root.flip(toggle.modelData.id)
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: toggle.modelData.label
                        color: toggle.isOn ? Theme.text : Theme.textDim
                        font.pixelSize: 11
                        font.family: Theme.fontFamily
                        Behavior on color { ColorAnimation { duration: 140 } }
                    }
                }
            }
        }

        DotSlider {
            width: parent.width
            label: "Sound"
            value: root.sound
            onMoved: v => root.sound = v
        }

        DotSlider {
            width: parent.width
            label: "Screen"
            value: root.screen
            onMoved: v => root.screen = v
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
