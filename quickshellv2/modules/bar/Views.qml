import QtQuick
import qs.services
import qs.modules.launcher
import qs.modules.controlcenter
import qs.modules.wallpaper
import qs.modules.logintheme
import qs.modules.loginvideo
import qs.modules.polkit
import qs.modules.clipboard
import qs.modules.emoji
import qs.modules.videos
import qs.modules.notifications
import qs.modules.power
import qs.modules.recorder
import qs.modules.keybinds
import qs.modules.perf
import qs.modules.camera
import qs.modules.calendar
import qs.modules.media

// Everything the pill grows into (or the bar's panel holds), in one place for both: the
// launcher, the control center, the media view, the calendar, the keybind cheatsheet, the
// performance monitor, clipboard history, the emoji picker, the video browser, the camera, the
// wallpaper picker, the login theme and video pickers, the power menu, naming a recording, the
// password prompt, and notifications.
// The host fills its surface with this, sizes the surface to wantedWidth × wantedHeight, and
// makes room for maxWidth × maxHeight.
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
    readonly property var views: [launcher, controlCenter, media, calendar, keybinds, performance, clipboard, emoji, videos, camera, wallpaper, loginTheme, loginVideo, power, recordName, polkit, notification]
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

    MediaContent {
        id: media
        readonly property string name: "media"
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

    CalendarContent {
        id: calendar
        readonly property string name: "calendar"
        readonly property int padX: 18
        readonly property int padTop: 16
        readonly property int padBottom: 14
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

    PerformanceView {
        id: performance
        readonly property string name: "performance"
        readonly property int padX: 14
        readonly property int padTop: 14
        readonly property int padBottom: 14
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

    KeybindsContent {
        id: keybinds
        readonly property string name: "keybinds"
        readonly property int padX: 14
        readonly property int padTop: 14
        readonly property int padBottom: 12
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

    ClipboardContent {
        id: clipboard
        readonly property string name: "clipboard"
        readonly property int padX: 12
        readonly property int padTop: 12
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

    EmojiContent {
        id: emoji
        readonly property string name: "emoji"
        readonly property int padX: 12
        readonly property int padTop: 12
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

    VideosContent {
        id: videos
        readonly property string name: "videos"
        readonly property int padX: 12
        readonly property int padTop: 12
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

    CameraContent {
        id: camera
        readonly property string name: "camera"
        readonly property int padX: 14
        readonly property int padTop: 14
        readonly property int padBottom: 12
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

    NotificationContent {
        id: notification
        readonly property string name: "notification"
        readonly property int padX: 16
        readonly property int padTop: 16
        readonly property int padBottom: 18
        x: padX
        y: padTop
        width: implicitWidth
        height: implicitHeight
        active: root.current === name
        opacity: active ? 1 : 0
        visible: opacity > 0
        Fade on opacity {}
    }

    PowerContent {
        id: power
        readonly property string name: "power"
        readonly property int padX: 16
        readonly property int padTop: 16
        readonly property int padBottom: 12
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

    RecordNameContent {
        id: recordName
        readonly property string name: "recordname"
        readonly property int padX: 16
        readonly property int padTop: 16
        readonly property int padBottom: 14
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
