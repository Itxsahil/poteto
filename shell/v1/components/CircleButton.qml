import QtQuick
import qs.config

// The shell's round icon button: page headers, toolbars, the music player's transport, a
// notification's close button. One glyph in a circle, a hover color, and an "active" look filled
// with the accent while the thing it controls is on.
//
//     CircleButton { glyph: "✕"; onClicked: ... }                         // 34px, tile colored
//     CircleButton { width: 32; height: 32; baseColor: "transparent"; ... } // flat until hovered
//     CircleButton { glyph: "󰐊"; glyphFont: Theme.monoFamily; active: true }
//
// The defaults are the plain button; every look the shell uses is a property away.
Rectangle {
    id: root

    property string glyph
    property int glyphSize: 20
    // Theme.monoFamily for a Nerd Font icon (Inter has none)
    property string glyphFont: Theme.fontFamily
    property color glyphColor: Theme.textPrimary
    // Optical centering: most glyphs sit a pixel low
    property real glyphOffset: -1
    property bool spinning: false

    // Colors at rest and under the pointer; "transparent" at rest is a flat button
    property color baseColor: Theme.tileBg
    property color hoverColor: Theme.controlBg
    // Filled with activeColor (the accent unless told otherwise) while the thing it controls is on
    property bool active: false
    property color activeColor: Theme.accent
    property color activeGlyphColor: Theme.onAccent

    // How much it shrinks while pressed (1: not at all)
    property real pressedScale: 1
    // Extra clickable room around a small button
    property real hitMargin: 0

    readonly property alias hovered: mouse.containsMouse
    readonly property alias pressed: mouse.pressed

    signal clicked()
    // Right click
    signal secondaryClicked()

    width: 34
    height: 34
    radius: width / 2
    color: active ? (mouse.containsMouse ? Qt.lighter(activeColor, 1.12) : activeColor)
        : (mouse.containsMouse ? hoverColor : baseColor)
    scale: mouse.pressed ? pressedScale : 1
    Behavior on color { CAnim {} }
    Behavior on scale { Anim { duration: Tokens.duration.press } }

    Text {
        id: glyphText
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.glyphOffset
        text: root.glyph
        color: root.active ? root.activeGlyphColor : root.glyphColor
        font.pixelSize: root.glyphSize
        font.family: root.glyphFont

        RotationAnimator on rotation {
            from: 0
            to: 360
            duration: 900
            loops: Animation.Infinite
            running: root.spinning
            onRunningChanged: if (!running) glyphText.rotation = 0
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.margins: -root.hitMargin
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => event.button === Qt.RightButton ? root.secondaryClicked() : root.clicked()
    }
}
