import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import qs.config
import qs.services

// The workspace overview (Alt + Tab), on the focused screen: a dimmed screen with a card per
// workspace, each the wallpaper with its windows drawn live where they sit (services/Overview.qml
// says which and which one is selected). Hold Alt and press Tab to move on, Shift + Tab to go
// back, arrows too; let go of Alt, press Enter or click a card to go there; Esc or a click
// outside the cards stays where you are.
PanelWindow {
    id: root

    required property ShellScreen targetScreen

    readonly property var monitor: Hyprland.monitorFor(targetScreen)
    readonly property bool shown: Overview.open && Hyprland.focusedMonitor?.name === targetScreen.name

    // Cards keep the screen's shape, as large as fits the row
    readonly property real gap: 28
    readonly property real cardRadius: 14
    readonly property int count: Math.max(1, Overview.workspaces.length)
    readonly property real cardWidth: Math.min(420, (width - 120 - gap * (count - 1)) / count)
    readonly property real cardHeight: cardWidth * (monitor ? monitor.height / monitor.width : 9 / 16)
    readonly property real scale: monitor ? cardWidth / (monitor.width / monitor.scale) : 0.2

    screen: targetScreen
    visible: shown || fade.running
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "overview"
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.5)
        opacity: root.shown ? 1 : 0
        Behavior on opacity {
            NumberAnimation { id: fade; duration: 160; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: Overview.cancel()
        }

        Item {
            id: keys
            focus: root.shown
            Keys.onPressed: event => {
                const back = event.modifiers & Qt.ShiftModifier;
                if (event.key === Qt.Key_Escape)
                    Overview.cancel();
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                    Overview.commit();
                else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && back) || event.key === Qt.Key_Left)
                    Overview.prev();
                else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Right)
                    Overview.next();
                else
                    return;
                event.accepted = true;
            }
            // Letting go of Alt goes to the selected workspace, as Alt + Tab does elsewhere
            Keys.onReleased: event => {
                if (event.key === Qt.Key_Alt || event.key === Qt.Key_Meta) {
                    Overview.commit();
                    event.accepted = true;
                }
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: root.gap

            Repeater {
                model: Overview.workspaces

                Column {
                    id: card

                    required property var modelData
                    required property int index
                    readonly property bool isSelected: index === Overview.index
                    readonly property bool isCurrent: modelData.id === Overview.currentId
                    readonly property var windows: modelData.toplevels?.values ?? []

                    spacing: 10
                    scale: isSelected ? 1 : 0.94
                    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                    ClippingRectangle {
                        id: frame
                        width: root.cardWidth
                        height: root.cardHeight
                        radius: root.cardRadius
                        color: Theme.tileBg

                        // The wallpaper, as on the workspace
                        Image {
                            anchors.fill: parent
                            source: Wallpaper.current ? "file://" + Wallpaper.current : ""
                            sourceSize.width: 640
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }

                        // Each window, live, where it is on the screen
                        Repeater {
                            model: card.windows

                            ClippingRectangle {
                                id: win
                                required property var modelData
                                readonly property var ipc: modelData.lastIpcObject ?? ({})
                                readonly property var at: ipc.at ?? [0, 0]
                                readonly property var size: ipc.size ?? [0, 0]

                                x: (at[0] - (root.monitor?.x ?? 0)) * root.scale
                                y: (at[1] - (root.monitor?.y ?? 0)) * root.scale
                                width: Math.max(8, size[0] * root.scale)
                                height: Math.max(8, size[1] * root.scale)
                                radius: 5
                                color: Theme.islandBg
                                visible: size[0] > 0

                                ScreencopyView {
                                    anchors.fill: parent
                                    captureSource: root.shown ? win.modelData.wayland : null
                                    live: root.shown
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: card.windows.length === 0
                            text: "Empty"
                            color: Theme.textSecondary
                            font.pixelSize: 13
                            font.family: Theme.fontFamily
                        }

                        // The selection, drawn over the previews
                        Rectangle {
                            anchors.fill: parent
                            radius: root.cardRadius
                            color: "transparent"
                            border.width: card.isSelected ? 3 : 1
                            border.color: card.isSelected ? Theme.accent : Qt.alpha(Theme.textPrimary, 0.15)
                            Behavior on border.color { ColorAnimation { duration: 140 } }
                        }

                        // A click goes there; hovering does not select, so a resting pointer
                        // never fights Tab
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Overview.select(card.index);
                                Overview.commit();
                            }
                        }
                    }

                    // On a pill of its own, so it reads over the dimmed wallpaper in any theme
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: label.implicitWidth + 24
                        height: 28
                        radius: height / 2
                        color: Theme.islandBg
                        border.width: 1
                        border.color: Theme.islandBorder

                        Row {
                            id: label
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: "Workspace " + card.modelData.id
                                color: card.isSelected ? Theme.textPrimary : Theme.textSecondary
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                                font.family: Theme.fontFamily
                            }

                            Text {
                                visible: card.isCurrent
                                text: "· current"
                                color: Theme.textSecondary
                                font.pixelSize: 13
                                font.family: Theme.fontFamily
                            }
                        }
                    }
                }
            }
        }
    }
}
