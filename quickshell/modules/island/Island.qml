import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.modules.controlcenter
import qs.modules.launcher
import qs.modules.clipboard
import qs.modules.wallpaper
import qs.modules.themes
import qs.modules.power

PanelWindow {
    id: root

    required property ShellScreen targetScreen

    screen: targetScreen
    anchors.top: true
    margins.top: 8
    implicitWidth: 800
    implicitHeight: 600
    color: "transparent"
    exclusiveZone: 44

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "dynamic-island"
    WlrLayershell.keyboardFocus: pill.viewOpen || pill.showPanel ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    mask: Region {
        item: pill
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
        onTriggered: focusGrab.active = pill.viewOpen
    }

    Rectangle {
        id: pill

        property bool expanded: false
        readonly property string view: Hyprland.focusedMonitor?.name === root.targetScreen.name ? ShellState.view : ""
        readonly property bool viewOpen: view !== ""
        readonly property Item viewItem: view === "launcher" ? launcher
            : view === "clipboard" ? clipboardView
            : view === "wallpaper" ? wallpaperView
            : view === "themes" ? themeView
            : view === "power" ? powerView
            : null
        readonly property bool showPanel: expanded && !viewOpen
        readonly property bool showOsd: osd.osdVisible && !showPanel && !viewOpen

        function collapse() {
            closeTimer.stop();
            expanded = false;
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
                focusGrab.active = false;
        }

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
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
            onHoveredChanged: {
                if (hovered) {
                    closeTimer.stop();
                    pill.expanded = true;
                } else {
                    closeTimer.restart();
                }
            }
        }

        Timer {
            id: closeTimer
            interval: 250
            onTriggered: {
                if (controlCenter.busy) {
                    restart();
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
