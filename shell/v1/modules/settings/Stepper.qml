import QtQuick
import qs.config
import qs.components

// A number with − and + beside it, kept between from and to in steps
//
//     Stepper { value: Settings.batteryLow; from: 0; to: 50; step: 5; suffix: "%"; onMoved: v => ... }
Row {
    id: root

    property int value
    property int from: 0
    property int to: 100
    property int step: 1
    property string suffix
    // What 0 reads as, when it means "off"
    property string zeroText: ""

    signal moved(int value)

    spacing: 6

    CircleButton {
        anchors.verticalCenter: parent.verticalCenter
        width: 28
        height: 28
        glyph: "−"
        glyphSize: 16
        baseColor: Theme.controlBg
        hoverColor: Theme.controlHover
        opacity: root.value > root.from ? 1 : 0.4
        onClicked: if (root.value > root.from) root.moved(Math.max(root.from, root.value - root.step))
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        width: 48
        horizontalAlignment: Text.AlignHCenter
        text: root.value === 0 && root.zeroText ? root.zeroText : root.value + root.suffix
        color: Theme.textPrimary
        font.pixelSize: 13
        font.weight: Font.DemiBold
        font.family: Theme.fontFamily
    }

    CircleButton {
        anchors.verticalCenter: parent.verticalCenter
        width: 28
        height: 28
        glyph: "+"
        glyphSize: 16
        baseColor: Theme.controlBg
        hoverColor: Theme.controlHover
        opacity: root.value < root.to ? 1 : 0.4
        onClicked: if (root.value < root.to) root.moved(Math.min(root.to, root.value + root.step))
    }
}
