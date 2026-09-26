import QtQuick
import QtQuick.Effects
import qs.config

// A soft drop shadow that lifts one of the shell's surfaces off the wallpaper, matching the one
// Hyprland draws under windows (decoration:shadow in hypr/hyprland.lua).
//
// Declare it as a sibling *before* the surface it lifts, in the same parent, and point it at that
// surface. It tracks the surface's position, size and corner radius, including while they animate:
//
//     Shadow { target: pill }
//     Rectangle { id: pill; radius: 18; color: Theme.islandBg }
//
// The shadow is the surface's silhouette, so it also covers the area behind it; surfaces the shell
// draws are opaque, which hides that. Make sure the window has room around the surface, or the
// shadow is cut off at the window edge.
MultiEffect {
    id: root

    required property Item target
    // Rectangle has `radius`; a plain Item does not.
    property real cornerRadius: target?.radius ?? 0

    x: target.x
    y: target.y
    width: target.width
    height: target.height
    visible: target.visible
    opacity: target.opacity

    source: shape
    // Only the shadow is wanted, never a blurred copy of the silhouette.
    blurEnabled: false
    shadowEnabled: true
    shadowBlur: 1.0
    shadowVerticalOffset: 3
    shadowColor: Theme.shadow
    blurMax: 24
    autoPaddingEnabled: true

    // The silhouette the shadow is cast from. Never drawn itself: MultiEffect renders it into a
    // texture, which a hidden item with its own layer still provides.
    Rectangle {
        id: shape
        anchors.fill: parent
        radius: root.cornerRadius
        color: "black"
        visible: false
        layer.enabled: true
    }
}
