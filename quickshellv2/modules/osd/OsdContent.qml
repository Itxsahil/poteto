import QtQuick
import qs.config
import qs.services

// What the OSD shows: an icon, a level bar and the value, "󰕾 ━━━━━━━━──── 72%", for the volume,
// the mic or the brightness. Volume past 100% fills the bar and laps over it in Theme.boost;
// muted fades it and says so (a muted mic in red, "Off"). No surface of its
// own; the pill grows around it, and the bar puts it where the time is.
Item {
    id: root

    readonly property bool isVolume: Osd.kind === "volume"
    readonly property bool isMic: Osd.kind === "mic"
    readonly property real percent: isVolume ? Audio.percent : isMic ? Audio.micPercent : Brightness.percent
    readonly property bool dimmed: (isVolume && Audio.muted) || (isMic && Audio.micMuted)
    readonly property real boost: Math.max(0, Math.min(100, percent - 100)) / 100
    readonly property string glyph: isMic ? (Audio.micMuted ? "󰍭" : "󰍬")
        : !isVolume ? "󰃠"
        : Audio.muted || percent === 0 ? "󰝟"
        : percent < 34 ? "󰕿"
        : percent < 67 ? "󰖀"
        : "󰕾"

    implicitWidth: 220
    implicitHeight: 22

    Text {
        id: icon
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 18
        horizontalAlignment: Text.AlignHCenter
        text: root.glyph
        // A muted mic is the one state worth noticing at a glance
        color: root.isMic && root.dimmed ? Theme.danger : root.dimmed ? Theme.textDim : Theme.text
        font.pixelSize: 15
        font.family: Theme.monoFamily
    }

    Text {
        id: value
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 40
        horizontalAlignment: Text.AlignRight
        text: root.isMic && root.dimmed ? "Off" : root.dimmed ? "Mute" : Math.round(root.percent) + "%"
        color: root.isMic && root.dimmed ? Theme.danger : root.dimmed ? Theme.textDim : root.boost > 0 ? Theme.boost : Theme.text
        font.pixelSize: 12
        font.weight: Font.DemiBold
        font.family: Theme.monoFamily
    }

    Rectangle {
        anchors.left: icon.right
        anchors.leftMargin: 10
        anchors.right: value.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        height: 6
        radius: 3
        color: Theme.control

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * Math.max(0, Math.min(1, root.percent / 100))
            radius: parent.radius
            color: Theme.text
            opacity: root.dimmed ? 0.4 : 1
            Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        }

        // The second lap, past 100%
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * root.boost
            visible: root.boost > 0
            radius: parent.radius
            color: Theme.boost
            opacity: root.dimmed ? 0.4 : 1
            Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        }
    }
}
