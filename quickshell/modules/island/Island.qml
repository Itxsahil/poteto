import QtQuick
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
import qs.modules.polkit

PanelWindow {
    id: root

    required property ShellScreen targetScreen

    // The pill holds its own 8px gap from the top of the screen instead of the window doing it,
    // so its shadow has somewhere to fall above it. The exclusive zone covers both, leaving the
    // same 52px reserved for windows as before.
    readonly property int gapTop: 8

    // In bar mode the strip across the top reserves the space and shows the idle status, so this
    // window reserves nothing and only appears when something is opened in it.
    readonly property int topGap: Layout.bar ? Layout.barHeight + 6 : gapTop

    screen: targetScreen
    anchors.top: true
    implicitWidth: 800
    // Tall enough for whatever the pill has to show. The control center is not a fixed height —
    // the audio pickers appear when there is a device to choose, and their chips wrap — and in bar
    // mode the pill starts further down, so a fixed window clipped the bottom of the panel.
    implicitHeight: topGap + Math.max(680, controlCenter.implicitHeight + 56)
    color: "transparent"
    // In bar mode this reserves the bar's height on the bar's behalf — see SimpleBar.qml
    exclusiveZone: Layout.bar ? Layout.barHeight : 44 + gapTop

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "dynamic-island"
    WlrLayershell.keyboardFocus: pill.viewOpen || pill.showPanel ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    mask: Region {
        // Nothing to click when the bar is showing the status and nothing is open
        item: pill.hidden ? nothing : pill
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
        onTriggered: focusGrab.active = pill.viewOpen || pill.showPanel
    }

    // The panel opened from the bar closes the same way a view does: click away, or Esc
    Connections {
        target: ShellState
        function onPanelChanged() {
            if (pill.showPanel)
                grabArm.restart();
            else
                focusGrab.active = pill.viewOpen;
        }
    }

    Shadow {
        target: pill
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
        Behavior on opacity { NumberAnimation { duration: 150 } }
        width: viewItem ? viewItem.implicitWidth + 24
            : showPanel ? controlCenter.implicitWidth + 40
            : showOsd ? osd.implicitWidth + 40
            : idle.implicitWidth + 36
        height: viewItem ? viewItem.implicitHeight + 24
            : showPanel ? controlCenter.implicitHeight + 40
            : 36
        radius: viewOpen ? 30 : showPanel ? 32 : height / 2
        color: Theme.islandBg
        border.color: Theme.islandBorder
        border.width: 1
        clip: true

        Behavior on width { NumberAnimation { duration: 380; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
        Behavior on height { NumberAnimation { duration: 380; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
        Behavior on radius { NumberAnimation { duration: 300 } }

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
            opacity: pill.showPanel || pill.showOsd || pill.viewOpen ? 0 : 1
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
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
            Behavior on opacity { NumberAnimation { duration: 250 } }
        }

        Launcher {
            id: launcher
            anchors.top: parent.top
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            active: pill.view === "launcher"
            opacity: active ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
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
            Behavior on opacity { NumberAnimation { duration: 200 } }
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
            Behavior on opacity { NumberAnimation { duration: 200 } }
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
            Behavior on opacity { NumberAnimation { duration: 200 } }
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
            Behavior on opacity { NumberAnimation { duration: 200 } }
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
            Behavior on opacity { NumberAnimation { duration: 200 } }
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
            Behavior on opacity { NumberAnimation { duration: 200 } }
            onCloseRequested: ShellState.close("keybinds")
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
            Behavior on opacity { NumberAnimation { duration: 200 } }
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
            Behavior on opacity { NumberAnimation { duration: 200 } }
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
            Behavior on opacity { NumberAnimation { duration: 200 } }
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
            Behavior on opacity { NumberAnimation { duration: 200 } }
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
            Behavior on opacity { NumberAnimation { duration: 200 } }
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
            Behavior on opacity { NumberAnimation { duration: 200 } }
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
            Behavior on opacity { NumberAnimation { duration: 200 } }
            onCloseRequested: ShellState.close()
        }
    }
}
