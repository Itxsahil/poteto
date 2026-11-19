import QtQuick
import qs.config
import qs.services

// The Audio menu, a page of the control center (the device button at the end of the Sound or
// Mic slider): where sound goes and where it comes from. Each section has the level of the one
// in use on top, then every device or port; click one to switch to it. A port the sound card
// has switched off is dimmed, says why (the jack is empty, or earphones are in and the speakers
// are cut), and cannot be chosen.
Item {
    id: root

    property bool active: false
    readonly property int rowHeight: 50

    signal backRequested()

    onActiveChanged: {
        if (active)
            keys.forceActiveFocus();
    }

    implicitHeight: column.implicitHeight

    Item {
        id: keys
        Keys.onEscapePressed: root.backRequested()
    }

    component SectionLabel: Text {
        leftPadding: 6
        topPadding: 6
        color: Theme.textDim
        font.pixelSize: 11
        font.weight: Font.DemiBold
        font.letterSpacing: 0.4
        font.family: Theme.fontFamily
    }

    // One device or port
    component DeviceRow: Rectangle {
        id: row

        required property var modelData
        readonly property var entry: modelData

        width: parent?.width ?? 0
        height: root.rowHeight
        radius: 14
        opacity: entry.available || entry.active ? 1 : 0.5
        color: entry.active ? Theme.tile
            : mouse.containsMouse && entry.available ? Qt.alpha(Theme.tile, 0.7)
            : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: row.entry.available && !row.entry.active
            cursorShape: Qt.PointingHandCursor
            onClicked: Audio.select(row.entry)
        }

        Rectangle {
            id: badge
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 34
            height: 34
            radius: 17
            color: row.entry.active ? Theme.accent : Theme.tileHover
            Behavior on color { ColorAnimation { duration: 160 } }

            Text {
                anchors.centerIn: parent
                text: Audio.glyphFor(row.entry.kind)
                color: row.entry.active ? Theme.accentText : Theme.text
                font.pixelSize: 16
                font.family: Theme.monoFamily
            }
        }

        Column {
            anchors.left: badge.right
            anchors.leftMargin: 12
            anchors.right: check.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: row.entry.label
                color: Theme.text
                font.pixelSize: 13
                font.weight: row.entry.active ? Font.DemiBold : Font.Medium
                font.family: Theme.fontFamily
            }

            Text {
                width: parent.width
                elide: Text.ElideRight
                visible: text !== ""
                // Why a port is marked as not there: the built-in ones (speakers, internal mic)
                // because something is plugged into the jack, the jack ones because it is empty
                readonly property string why: row.entry.available ? ""
                    : row.entry.kind === "speaker" ? "Earphones plugged in"
                    : row.entry.kind === "mic" ? "Headset plugged in"
                    : "Unplugged"
                text: [row.entry.detail, why].filter(Boolean).join(" · ")
                color: Theme.textDim
                font.pixelSize: 11
                font.family: Theme.fontFamily
            }
        }

        Text {
            id: check
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: "󰄬"
            visible: row.entry.active
            color: Theme.accent
            font.pixelSize: 15
            font.family: Theme.monoFamily
        }
    }

    Column {
        id: column
        width: parent.width
        spacing: 8

        PageHeader {
            title: "Audio"
            showSwitch: false
            onBackClicked: root.backRequested()
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.border
        }

        SectionLabel {
            text: "OUTPUT"
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

        Column {
            width: parent.width
            spacing: 2

            Repeater {
                model: Audio.outputs
                DeviceRow {}
            }
        }

        SectionLabel {
            text: "INPUT"
        }

        DotSlider {
            width: parent.width
            label: "Mic"
            visible: Audio.micAvailable
            value: Audio.micPercent
            dimmed: Audio.micMuted
            dimmedText: "Off"
            labelClickable: true
            onMoved: v => Audio.setMicPercent(v)
            onLabelClicked: Audio.toggleMicMute()
        }

        Column {
            width: parent.width
            spacing: 2

            Repeater {
                model: Audio.inputs
                DeviceRow {}
            }
        }
    }
}
