import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.components
import qs.config
import qs.services
import qs.modules.controlcenter
import qs.modules.launcher
import qs.modules.clipboard
import qs.modules.wallpaper
import qs.modules.themes
import qs.modules.power
import qs.modules.emoji
import qs.modules.recorder
import qs.modules.logintheme
import qs.modules.loginvideo
import qs.modules.videos
import qs.modules.camera
import qs.modules.keybinds
import qs.modules.perf
import qs.modules.media
import qs.modules.polkit
import qs.modules.bar
import qs.modules.settings

PanelWindow {
    id: root

    required property ShellScreen targetScreen

    // The island hangs from the top edge of the screen: no gap above it. Windows keep clear of it
    // and of the frame through modules/island/Reservations.qml, since this window covers the
    // whole screen and so cannot reserve an edge itself.
    readonly property int gapTop: 0
    // At rest it is 30px tall (Layout.pillHeight, the side pills'
    // too), the time with 40px either side
    readonly property int pillHeight: Layout.pillHeight
    readonly property int idlePadding: 80

    // In bar mode the strip across the top reserves the space and shows the idle status, so this
    // window only shows something when something is opened in it. What opens then hangs from the
    // bottom of the bar instead, covering its 1px bottom line so the two read as one piece.
    readonly property int topGap: Layout.bar ? Layout.barHeight - 1 : gapTop

    // The whole screen: the shell's surface (the frame, the island and the side pills) is drawn
    // here as one shape, components/Surface.qml. Only the pills take input (mask below).
    screen: targetScreen
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    // Always on the Overlay layer, so what opens here shows above a fullscreen window (Alt + F),
    // which Hyprland draws over the Top layer. Never moved between layers: Hyprland 0.57 ignores a
    // layer change on a mapped surface (and moving it is a suspect in its crashes). Instead the
    // window is unmapped while the workspace is fullscreen and nothing is open, so the idle
    // surface stays out of the way of a fullscreen video or game; when something opens over one,
    // only the island shows (no frame, no side pills)
    readonly property bool fullscreen: Hyprland.monitorFor(targetScreen)?.activeWorkspace?.hasFullscreen ?? false
    visible: !fullscreen || pill.viewOpen || pill.showPanel || pill.showOsd || settingsDrawer.open
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "dynamic-island"
    WlrLayershell.keyboardFocus: pill.viewOpen || pill.showPanel || settingsDrawer.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Input only on the pills; the frame and everything between them let clicks through
    mask: Region {
        // Nothing to click when the bar is showing the status and nothing is open
        item: pill.hidden ? nothing : pill

        Region {
            item: workspacesBar.visible ? workspacesBar.pill : nothing
            intersection: Intersection.Combine
        }
        Region {
            item: statusBar.pillShown ? statusBar.pill : nothing
            intersection: Intersection.Combine
        }
        Region {
            item: statusBar.visible ? statusBar.recPill : nothing
            intersection: Intersection.Combine
        }
        Region {
            item: settingsDrawer.visible ? settingsDrawer : nothing
            intersection: Intersection.Combine
        }
    }

    Item {
        id: nothing
        width: 0
        height: 0
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    HyprlandFocusGrab {
        id: focusGrab
        windows: [root]
        onCleared: ShellState.close()
    }

    Timer {
        id: grabArm
        interval: 150
        // showPanel, not ShellState.panel: the flag is shared by every screen, and a grab armed on
        // a screen that is not showing the panel would clear the shared state and close it
        onTriggered: focusGrab.active = pill.viewOpen || pill.showPanel || settingsDrawer.open
    }

    // The panel opened from the bar closes the same way a view does: click away, or Esc
    Connections {
        target: ShellState
        function onPanelChanged() {
            if (pill.showPanel)
                grabArm.restart();
            else
                focusGrab.active = pill.viewOpen || settingsDrawer.open;
        }
        // The settings drawer too: click away, or Esc
        function onSettingsChanged() {
            if (settingsDrawer.open)
                grabArm.restart();
            else
                focusGrab.active = pill.viewOpen || pill.showPanel;
        }
    }

    // The shell's surface, behind everything: the frame and every pill as one shape, with one
    // shadow under all of it. The pills below are transparent and only hold their content.
    Item {
        id: surfaceLayer
        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 1.0
            // Nearly even all round, so every edge of the wallpaper looks inset alike
            shadowVerticalOffset: 1
            shadowColor: Theme.shadow
            blurMax: 24
        }

        Surface {
            anchors.fill: parent
            pills: [pill, workspacesBar.pill, statusBar.pill, statusBar.recPill, settingsDrawer]
            // No frame over a fullscreen window
            frameWidth: root.fullscreen ? 0 : Tokens.frameWidth
            frameRadius: root.fullscreen ? 0 : Tokens.radius.screen
            // In bar mode the bar is the frame's top edge: the frame starts below it, never over
            // it, and covers only its 1px bottom line so the two read as one piece
            frameTop: Layout.bar ? Layout.barHeight : Tokens.frameWidth
            frameClip: Layout.bar ? Layout.barHeight - 1 : -1e4
            // In bar mode what opens hangs from the bar's bottom edge, while it is open
            wallTop: Layout.bar ? Layout.barHeight - 1 : -100
            wallBottom: Layout.bar ? Layout.barHeight : 0
            wallAlpha: Layout.bar ? pill.opacity : 1
        }
    }

    WorkspacesBar {
        id: workspacesBar
        anchors.fill: parent
        targetScreen: root.targetScreen
        suppressed: root.fullscreen
    }

    StatusBar {
        id: statusBar
        anchors.fill: parent
        targetScreen: root.targetScreen
        suppressed: root.fullscreen
    }

    // Slides in from the right edge, below the pills at the top and clear of the bottom
    SettingsDrawer {
        id: settingsDrawer
        open: pill.focused && ShellState.settings
        y: (Layout.bar ? Layout.barHeight : Layout.pillHeight) + 40
        height: parent.height - y - Tokens.frameWidth - 40
        onCloseRequested: ShellState.settings = false
    }

    Rectangle {
        id: pill

        property bool expanded: false
        readonly property bool focused: Hyprland.focusedMonitor?.name === root.targetScreen.name
        readonly property string view: focused ? ShellState.view : ""
        readonly property bool viewOpen: view !== ""
        readonly property Item viewItem: view === "launcher" ? launcher
            : view === "clipboard" ? clipboardView
            : view === "wallpaper" ? wallpaperView
            : view === "themes" ? themeView
            : view === "power" ? powerView
            : view === "emoji" ? emojiView
            : view === "recordname" ? recordNameView
            : view === "videos" ? videosView
            : view === "camera" ? cameraView
            : view === "keybinds" ? keybindsView
            : view === "performance" ? performanceView
            : view === "media" ? mediaView
            : view === "logintheme" ? loginThemeView
            : view === "loginvideo" ? loginVideoView
            : view === "polkit" ? polkitView
            : null
        // ShellState.panel is one flag for the whole shell, so without the same focused-monitor
        // check the views use, clicking one bar would open a control center on every screen
        readonly property bool showPanel: (expanded || (ShellState.panel && focused)) && !viewOpen
        // Bar mode has its own idle status, so the pill stays out of the way until it is needed
        readonly property bool hidden: Layout.bar && !viewOpen && !showPanel && !showOsd
        readonly property bool showOsd: osd.osdVisible && !showPanel && !viewOpen

        function collapse() {
            closeTimer.stop();
            expanded = false;
            ShellState.panel = false;
            controlCenter.reset();
        }

        onShowPanelChanged: {
            if (showPanel)
                panelKeys.forceActiveFocus();
        }

        onViewOpenChanged: {
            if (viewOpen)
                grabArm.restart();
            else
                focusGrab.active = showPanel;
        }

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.topGap
        opacity: hidden ? 0 : 1
        visible: opacity > 0
        Behavior on opacity { Anim { duration: Tokens.duration.fade } }
        width: viewItem ? viewItem.implicitWidth + 24
            : showPanel ? controlCenter.implicitWidth + 40
            : showOsd ? osd.implicitWidth + 40
            : idle.implicitWidth + root.idlePadding
        height: viewItem ? viewItem.implicitHeight + 24
            : showPanel ? controlCenter.implicitHeight + 40
            : root.pillHeight
        radius: viewOpen || showPanel ? Tokens.radius.panel : height / 2
        // Drawn by the surface behind it (Surface.qml); its radius rounds the bottom corners
        color: "transparent"
        clip: true

        Behavior on width { Anim { duration: Tokens.duration.morph; easing.type: Tokens.easing.morph; easing.overshoot: Tokens.easing.morphOvershoot } }
        Behavior on height { Anim { duration: Tokens.duration.morph; easing.type: Tokens.easing.morph; easing.overshoot: Tokens.easing.morphOvershoot } }
        Behavior on radius { Anim { duration: Tokens.duration.page } }

        HoverHandler {
            // Bar mode opens the panel with a click instead, so a stray pointer cannot trip it
            enabled: !Layout.bar
            onHoveredChanged: {
                if (hovered) {
                    closeTimer.stop();
                    if (!pill.expanded)
                        openTimer.restart();
                } else {
                    openTimer.stop();
                    closeTimer.restart();
                }
            }
        }

        // The panel opens once the pointer rests on the pill, not as it passes over the top of
        // the screen on its way somewhere else
        Timer {
            id: openTimer
            interval: 180
            onTriggered: pill.expanded = true
        }

        // A click opens it at once and pins it: it stays when the pointer leaves, until a click
        // elsewhere or Esc (the same as opening it from the bar)
        TapHandler {
            enabled: !pill.showPanel && !pill.viewOpen && !pill.hidden
            onTapped: {
                openTimer.stop();
                ShellState.panel = true;
            }
        }

        Timer {
            id: closeTimer
            interval: 300
            onTriggered: {
                if (controlCenter.busy) {
                    restart();
                    return;
                }
                // Pinned with a click: leaving does not close it
                if (ShellState.panel) {
                    pill.expanded = false;
                    return;
                }
                pill.collapse();
            }
        }

        Item {
            id: panelKeys
            focus: pill.showPanel
            Keys.onEscapePressed: {
                if (controlCenter.page !== "")
                    controlCenter.page = "";
                else
                    pill.collapse();
            }
        }

        IdleContent {
            id: idle
            anchors.centerIn: parent
            date: clock.date
            clockOnly: true
            opacity: pill.showPanel || pill.showOsd || pill.viewOpen ? 0 : 1
            visible: opacity > 0
            Behavior on opacity { Anim { duration: Tokens.duration.fade } }
        }

        IslandOsd {
            id: osd
            anchors.centerIn: parent
            suppressed: pill.expanded
            shown: pill.showOsd
        }

        ControlCenter {
            id: controlCenter
            anchors.top: parent.top
            anchors.topMargin: 20
            anchors.horizontalCenter: parent.horizontalCenter
            width: implicitWidth
            height: implicitHeight
            date: clock.date
            opacity: pill.showPanel ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { Anim {} }
        }

        Launcher {
            id: launcher
            anchors.top: parent.top
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            active: pill.view === "launcher"
            opacity: active ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { Anim {} }
            onCloseRequested: ShellState.close()
        }

        ClipboardView {
            id: clipboardView
            anchors.top: parent.top
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            active: pill.view === "clipboard"
            opacity: active ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { Anim {} }
            onCloseRequested: ShellState.close()
        }

        RecordNameView {
            id: recordNameView
            anchors.top: parent.top
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            active: pill.view === "recordname"
            opacity: active ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { Anim {} }
            onCloseRequested: ShellState.close("recordname")
        }

        EmojiView {
            id: emojiView
            anchors.top: parent.top
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            active: pill.view === "emoji"
            opacity: active ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { Anim {} }
            onCloseRequested: ShellState.close()
        }

        PowerView {
            id: powerView
            anchors.top: parent.top
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            active: pill.view === "power"
            opacity: active ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { Anim {} }
            onCloseRequested: ShellState.close()
        }

        ThemeView {
            id: themeView
            anchors.top: parent.top
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            active: pill.view === "themes"
            opacity: active ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { Anim {} }
            onCloseRequested: ShellState.close()
        }

        KeybindsView {
            id: keybindsView
            anchors.top: parent.top
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            active: pill.view === "keybinds"
            opacity: active ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { Anim {} }
            onCloseRequested: ShellState.close("keybinds")
        }

        MediaView {
            id: mediaView
            anchors.top: parent.top
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            width: implicitWidth
            height: implicitHeight
            active: pill.view === "media"
            opacity: active ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { Anim {} }
            onCloseRequested: ShellState.close("media")
        }

        PerformanceView {
            id: performanceView
            anchors.top: parent.top
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            width: implicitWidth
            active: pill.view === "performance"
            opacity: active ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { Anim {} }
            onCloseRequested: ShellState.close("performance")
        }

        VideosView {
            id: videosView
            anchors.top: parent.top
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            active: pill.view === "videos"
            opacity: active ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { Anim {} }
            onCloseRequested: ShellState.close("videos")
        }

        CameraView {
            id: cameraView
            anchors.top: parent.top
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            active: pill.view === "camera"
            opacity: active ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { Anim {} }
            onCloseRequested: ShellState.close("camera")
        }

        LoginThemeView {
            id: loginThemeView
            anchors.top: parent.top
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            active: pill.view === "logintheme"
            opacity: active ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { Anim {} }
            onCloseRequested: ShellState.close("logintheme")
        }

        LoginVideoView {
            id: loginVideoView
            anchors.top: parent.top
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            active: pill.view === "loginvideo"
            opacity: active ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { Anim {} }
            onCloseRequested: ShellState.close("loginvideo")
        }

        PolkitView {
            id: polkitView
            anchors.top: parent.top
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            active: pill.view === "polkit"
            opacity: active ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { Anim {} }
            onCloseRequested: ShellState.close("polkit")
        }

        WallpaperView {
            id: wallpaperView
            anchors.top: parent.top
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            active: pill.view === "wallpaper"
            opacity: active ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { Anim {} }
            onCloseRequested: ShellState.close()
        }
    }
}
