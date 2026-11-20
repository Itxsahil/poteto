pragma Singleton

import QtQuick
import Quickshell

// The shell's shared sizes and timings: one place to make it rounder or squarer, snappier or
// calmer. Colors are in Theme.qml; this is everything else that every module repeats.
//
// Use them by role, not by number: a list row is Tokens.radius.row whatever its size today.
// Animations take theirs through components/Anim.qml and CAnim.qml. A number that is not a
// "feel" choice stays literal: a spinner's loop, a half-height pill radius (height / 2), a
// drawn icon's corners.
Singleton {
    id: root

    readonly property Radii radius: Radii {}
    readonly property Durations duration: Durations {}
    readonly property Easings easing: Easings {}
    // The thin frame around the screen (components/Surface.qml), in pixels; 0 turns it off.
    // Its rounded inside corners are radius.screen
    readonly property int frameWidth: 10

    // Corner radii, smallest to largest. scale makes every corner rounder (1.2) or squarer (0.8).
    component Radii: QtObject {
        readonly property real scale: 1
        // key caps, little badges and cells, hover rows in dense lists
        readonly property real tiny: 6 * scale
        // thumbnails, small badges and buttons
        readonly property real small: 10 * scale
        // list rows: launcher results, Wi-Fi networks, clipboard entries
        readonly property real row: 12 * scale
        // chips and inputs
        readonly property real chip: 14 * scale
        // buttons (PillButton)
        readonly property real button: 16 * scale
        // search fields and picker cards (wallpapers, videos, emoji)
        readonly property real field: 18 * scale
        // cards: notifications, the power menu
        readonly property real card: 20 * scale
        // control center tiles, the screenshot and recorder toolbars (Tile)
        readonly property real tile: 22 * scale
        // large surfaces: the island's open views and control center, the bar's drop-down panel,
        // the music pill opened into its panel
        readonly property real panel: 30 * scale
        // the round curve where a pill hanging from the top flows into the frame (Surface); the
        // same size as the screen's corners, so every corner of the wallpaper looks alike
        readonly property real flare: 20 * scale
        // the screen's own corners: the inside of the frame around it. A little rounder than
        // Hyprland's window rounding (decoration.rounding, 10), so windows sit inside them
        readonly property real screen: 22 * scale
    }

    // Animation lengths in milliseconds. scale slows everything down (1.5) or speeds it up (0.7).
    component Durations: QtObject {
        readonly property real scale: 1
        // hover and press feedback: a color change under the pointer
        readonly property int press: Math.round(120 * scale)
        // small fades and a selection moving
        readonly property int fade: Math.round(150 * scale)
        // a view, a popup or a label fading in or out
        readonly property int view: Math.round(200 * scale)
        // a page sliding, a theme fading across the shell
        readonly property int page: Math.round(320 * scale)
        // the island changing shape
        readonly property int morph: Math.round(380 * scale)
    }

    // Easing curves (Easing.Type values)
    component Easings: QtObject {
        // almost everything: starts fast, settles gently
        readonly property int standard: Easing.OutCubic
        // the island's shape change, which overshoots a little (with morphOvershoot)
        readonly property int morph: Easing.OutBack
        readonly property real morphOvershoot: 1.2
    }
}
