import QtQuick
import qs.services
import qs.modules.launcher
import qs.modules.controlcenter
import qs.modules.wallpaper
import qs.modules.logintheme
import qs.modules.loginvideo
import qs.modules.polkit

// Everything the pill grows into (or the bar's panel holds), in one place for both: the
// launcher, the control center, the wallpaper picker, the login theme and video pickers, and the
// password prompt. The host fills its surface with this, sizes the surface to wantedWidth ×
// wantedHeight, and makes room for maxWidth × maxHeight.
//
// Each view is laid out at its own padding (padX, padTop, padBottom) inside the surface, comes
// in once the surface has mostly grown, and leaves before it shrinks.
Item {
    id: root

    // Which view this host shows: a ShellState view name, or "" for none
    property string current: ""
    // Opened from the keyboard rather than a hover peek, so the control center takes keys too
    property bool pinned: false

    readonly property Item item: views.find(v => v.name === current) ?? null
    readonly property real wantedWidth: item ? item.implicitWidth + item.padX * 2 : 0
    readonly property real wantedHeight: item ? item.implicitHeight + item.padTop + item.padBottom : 0
    readonly property var views: [launcher, controlCenter, wallpaper, loginTheme, loginVideo, polkit]
    readonly property real maxWidth: Math.max(...views.map(v => v.implicitWidth + v.padX * 2))
    // The launcher grows with its results, so its room is its tallest, not what it is now
    readonly property real maxHeight: Math.max(launcher.maxRows * launcher.rowHeight + 120,
        ...views.filter(v => v !== launcher).map(v => v.implicitHeight + v.padTop + v.padBottom))

    component Fade: Behavior {
        id: fade
        NumberAnimation {
            duration: fade.targetValue > 0 ? 260 : 120
            easing.type: Easing.InOutQuad
        }
    }

    LauncherContent {
        id: launcher
        readonly property string name: "launcher"
        readonly property int padX: 10
        readonly property int padTop: 4
        readonly property int padBottom: 8
        x: padX
        y: padTop
        width: implicitWidth
        height: implicitHeight
        active: root.current === name
        opacity: active ? 1 : 0
        visible: opacity > 0
        Fade on opacity {}
        onCloseRequested: ShellState.close(name)
    }

    ControlCenterContent {
        id: controlCenter
        readonly property string name: "controlcenter"
        readonly property int padX: 14
        readonly property int padTop: 14
        readonly property int padBottom: 14
        x: padX
        y: padTop
        width: implicitWidth
        height: implicitHeight
        // A hover peek shows it but leaves the keyboard alone
        active: root.current === name && root.pinned
        opacity: root.current === name ? 1 : 0
        visible: opacity > 0
        Fade on opacity {}
        onCloseRequested: ShellState.close(name)
    }

    WallpaperContent {
        id: wallpaper
        readonly property string name: "wallpaper"
        readonly property int padX: 10
        readonly property int padTop: 10
        readonly property int padBottom: 10
        x: padX
        y: padTop
        width: implicitWidth
        height: implicitHeight
        active: root.current === name
        opacity: active ? 1 : 0
        visible: opacity > 0
        Fade on opacity {}
        onCloseRequested: ShellState.close(name)
    }

    LoginThemeContent {
        id: loginTheme
        readonly property string name: "logintheme"
        readonly property int padX: 14
        readonly property int padTop: 14
        readonly property int padBottom: 10
        x: padX
        y: padTop
        width: implicitWidth
        height: implicitHeight
        active: root.current === name
        opacity: active ? 1 : 0
        visible: opacity > 0
        Fade on opacity {}
        onCloseRequested: ShellState.close(name)
    }

    LoginVideoContent {
        id: loginVideo
        readonly property string name: "loginvideo"
        readonly property int padX: 10
        readonly property int padTop: 10
        readonly property int padBottom: 10
        x: padX
        y: padTop
        width: implicitWidth
        height: implicitHeight
        active: root.current === name
        opacity: active ? 1 : 0
        visible: opacity > 0
        Fade on opacity {}
        onCloseRequested: ShellState.close(name)
    }

    PolkitContent {
        id: polkit
        readonly property string name: "polkit"
        readonly property int padX: 18
        readonly property int padTop: 18
        readonly property int padBottom: 16
        x: padX
        y: padTop
        width: implicitWidth
        height: implicitHeight
        active: root.current === name
        opacity: active ? 1 : 0
        visible: opacity > 0
        Fade on opacity {}
        onCloseRequested: ShellState.close(name)
    }
}
