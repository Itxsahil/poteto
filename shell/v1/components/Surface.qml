import QtQuick
import qs.config

// The shell's surface, drawn as one shape by shaders/surface.frag: the frame around the screen
// and up to six pieces hanging from it (the top edge, the left for the settings drawer, a corner). Where a
// piece's side meets the frame it flows in
// with a round curve as wide as the frame's own corners, so the wallpaper showing through reads as
// one hole with every corner rounded alike (computed, not drawn, so it holds at any size and
// through every animation). Fill a whole screen-sized
// window with it and list the pills; they only hold their content and stay transparent.
//
//     Surface {
//         anchors.fill: parent
//         pills: [island, workspaces, status]
//         frameWidth: Tokens.frameWidth
//     }
//
// Each pill's position, size, `radius` (its corners) and opacity are read live; a pill fading
// out recedes into the edge it hangs from. Pills must sit in an item at the surface's origin.
ShaderEffect {
    id: root

    // Up to six. Each hangs from the top edge unless it has `property int edge`: 1 the right,
    // 2 the bottom-right corner, 3 the left
    property list<Item> pills
    property real frameWidth: Tokens.frameWidth
    property real frameRadius: Tokens.radius.screen
    // Where the inside of the frame starts at the top, and above which nothing of the frame is
    // drawn: in bar mode the bar is the frame's top edge, so these are its bottom
    property real frameTop: frameWidth
    property real frameClip: -1e4
    // A full-width band the pills hang from: y of its top and bottom, and how present it is.
    // The default is the screen's top edge (a band above the screen)
    property real wallTop: -100
    property real wallBottom: 0
    property real wallAlpha: 1
    // How wide the round join between a pill and the frame is
    property real smoothing: Tokens.radius.flare

    // Read by the shader
    property color color: Theme.islandBg
    readonly property vector2d size: Qt.vector2d(width, height)
    readonly property vector4d wall: Qt.vector4d(wallTop, wallBottom, wallAlpha, 0)
    readonly property vector4d rect0: rectOf(0)
    readonly property vector4d rect1: rectOf(1)
    readonly property vector4d rect2: rectOf(2)
    readonly property vector4d rect3: rectOf(3)
    readonly property vector4d rect4: rectOf(4)
    readonly property vector4d rect5: rectOf(5)
    readonly property vector4d radii: Qt.vector4d(radiusOf(0), radiusOf(1), radiusOf(2), radiusOf(3))
    readonly property vector4d radii2: Qt.vector4d(radiusOf(4), radiusOf(5), 0, 0)
    readonly property vector4d alphas: Qt.vector4d(alphaOf(0), alphaOf(1), alphaOf(2), alphaOf(3))
    readonly property vector4d alphas2: Qt.vector4d(alphaOf(4), alphaOf(5), 0, 0)
    readonly property vector4d edges: Qt.vector4d(edgeOf(0), edgeOf(1), edgeOf(2), edgeOf(3))
    readonly property vector4d edges2: Qt.vector4d(edgeOf(4), edgeOf(5), 0, 0)

    // Reading x, y, width and height here makes the bindings follow them
    function rectOf(i: int): vector4d {
        const it = pills[i] ?? null;
        if (!it)
            return Qt.vector4d(0, 0, 0, 0);
        return Qt.vector4d(it.x, it.y, it.width, it.height);
    }

    function edgeOf(i: int): real {
        return pills[i]?.edge ?? 0;
    }

    function radiusOf(i: int): real {
        return pills[i]?.radius ?? 0;
    }

    // Effective visibility: an item in a hidden parent reads as not visible
    function alphaOf(i: int): real {
        const it = pills[i] ?? null;
        return it && it.visible ? it.opacity : 0;
    }

    fragmentShader: Qt.resolvedUrl("../shaders/surface.frag.qsb")
}
