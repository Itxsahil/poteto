pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.components
import qs.services

// The settings drawer: slides in from the left edge of the screen and is drawn as part of the
// shell's one surface (components/Surface.qml), flowing into the frame like the island does from
// the top. It lives in the island's window (modules/island/Island.qml), which positions it
// vertically and draws its background; it holds the content and is transparent itself.
//
// Every setting here is read from and written to config/Settings.qml (~/.config/poteto/shell.json)
// or the service that owns it, so a change shows at once and survives a restart. Opened with
// Super + , or `qs ipc call settings toggle`; Esc or a click outside closes it.
Rectangle {
    id: root

    property bool open: false
    // Hangs from the left edge (read by Surface)
    readonly property int edge: 3
    // 0 hidden, 1 fully out; it slides by animating this
    property real progress: open ? 1 : 0
    readonly property int fullWidth: 440

    signal closeRequested()

    width: fullWidth
    x: Tokens.frameWidth - fullWidth * (1 - progress)
    visible: progress > 0
    radius: Tokens.radius.panel
    color: "transparent"
    clip: true

    Behavior on progress { Anim { duration: Tokens.duration.page } }

    onOpenChanged: {
        if (open)
            keys.forceActiveFocus();
    }

    // Takes the keyboard while open, for Esc
    Item {
        id: keys
        focus: root.open
        Keys.onEscapePressed: root.closeRequested()
    }

    // The header: a title and the close button
    Item {
        id: header
        x: 20
        y: 16
        width: parent.width - 40
        height: 40

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "Settings"
            color: Theme.textPrimary
            font.pixelSize: 20
            font.weight: Font.Bold
            font.family: Theme.fontFamily
        }

        CircleButton {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 32
            height: 32
            baseColor: "transparent"
            glyph: "✕"
            glyphSize: 13
            glyphColor: Theme.textSecondary
            glyphOffset: 0
            onClicked: root.closeRequested()
        }
    }

    Flickable {
        anchors.top: header.bottom
        anchors.topMargin: 8
        anchors.bottom: parent.bottom
        x: 20
        width: parent.width - 40
        contentHeight: content.implicitHeight + 24
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        Column {
            id: content
            width: parent.width
            spacing: 20

            SettingsSection {
                title: "Appearance"

                SettingRow {
                    label: "Layout"
                    detail: "The island hanging from the top, or one flat bar"

                    Segmented {
                        options: [{ value: "pill", label: "Island" }, { value: "bar", label: "Bar" }]
                        current: Layout.bar ? "bar" : "pill"
                        onPicked: value => Layout.setMode(value === "bar" ? "bar" : "island")
                    }
                }

                SettingRow {
                    label: "Workspaces"
                    detail: "The pill top left (the bar always shows them)"

                    Toggle {
                        checked: Settings.showWorkspaces
                        onToggled: checked => Settings.set("showWorkspaces", checked)
                    }
                }

                SettingRow {
                    label: "Music and date"
                    detail: "The pill top right (the bar always shows them)"

                    Toggle {
                        checked: Settings.showMusic
                        onToggled: checked => Settings.set("showMusic", checked)
                    }
                }

                SettingRow {
                    label: "Theme"
                    detail: ThemeManager.themes.find(t => t.id === ThemeManager.current)?.name ?? ThemeManager.current

                    PillButton {
                        text: "Change"
                        onClicked: ShellState.open("themes")
                    }
                }

                // Only for the theme made from the wallpaper
                SettingRow {
                    visible: ThemeManager.current === ThemeManager.dynamicId
                    label: "Dynamic mode"
                    detail: "Light, dark, or by how bright the wallpaper is"

                    Segmented {
                        options: [{ value: "dark", label: "Dark" }, { value: "light", label: "Light" }, { value: "auto", label: "Auto" }]
                        current: ThemeManager.dynamicTheme?.colors.mode ?? ThemeManager.dynamicTheme?.variant ?? "dark"
                        onPicked: value => ThemeManager.applyDynamic(value, "", "")
                    }
                }

                SettingRow {
                    visible: ThemeManager.current === ThemeManager.dynamicId
                    label: "Dynamic style"
                    detail: ThemeManager.dynamicTheme?.colors.scheme ?? "tonal-spot"

                    PillButton {
                        text: "Next style"
                        onClicked: ThemeManager.cycleDynamicScheme()
                    }
                }
            }

            SettingsSection {
                title: "Night light"

                SettingRow {
                    label: "Night light"
                    detail: "Warmer colors, easier on the eyes at night"

                    Toggle {
                        checked: NightLight.enabled
                        onToggled: checked => NightLight.setEnabled(checked)
                    }
                }

                // 6500 K (left) to 2000 K (right); the drag is written a moment after it settles
                Item {
                    width: parent.width
                    height: warmth.height + 20

                    ControlSlider {
                        id: warmth

                        property int pending: 0

                        function fraction(k: int): real {
                            return (NightLight.maxTemperature - k) / (NightLight.maxTemperature - NightLight.minTemperature);
                        }

                        x: 12
                        y: 6
                        width: parent.width - 24
                        dimmed: !NightLight.enabled
                        value: pending > 0 ? fraction(pending) : fraction(NightLight.temperature)
                        label: (pending > 0 ? pending : NightLight.temperature) + " K"
                        onMoved: v => {
                            pending = Math.round((NightLight.maxTemperature - v * (NightLight.maxTemperature - NightLight.minTemperature)) / 100) * 100;
                            warmthWrite.restart();
                        }

                        Timer {
                            id: warmthWrite
                            interval: 150
                            onTriggered: {
                                NightLight.setTemperature(warmth.pending);
                                if (!NightLight.enabled)
                                    NightLight.setEnabled(true);
                                warmth.pending = 0;
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "󰖔"
                            color: Theme.controlIconOnFill
                            font.pixelSize: 16
                            font.family: Theme.monoFamily
                        }
                    }
                }
            }

            SettingsSection {
                title: "Notifications"

                SettingRow {
                    label: "Do Not Disturb"
                    detail: "Notifications go straight to history; critical ones and battery warnings still show"

                    Toggle {
                        checked: Notifications.dnd
                        onToggled: checked => Notifications.setDnd(checked)
                    }
                }

                SettingRow {
                    label: "Test notifications"
                    detail: "One of every kind, a few seconds apart"

                    PillButton {
                        text: "Send"
                        onClicked: Notifications.sendTests("")
                    }
                }
            }

            SettingsSection {
                visible: Battery.present
                title: "Battery"

                SettingRow {
                    label: "Low battery warning"
                    detail: "A notification when the battery gets this low"

                    Stepper {
                        value: Settings.batteryLow
                        from: 0
                        to: 50
                        step: 5
                        suffix: "%"
                        zeroText: "Off"
                        onMoved: value => Settings.set("batteryLow", value)
                    }
                }

                SettingRow {
                    label: "Critical warning"
                    detail: "A warning that stays up until dismissed"

                    Stepper {
                        value: Settings.batteryCritical
                        from: 0
                        to: 20
                        step: 1
                        suffix: "%"
                        zeroText: "Off"
                        onMoved: value => Settings.set("batteryCritical", value)
                    }
                }

                SettingRow {
                    label: "See the warning"
                    detail: "Sends the low battery notification now"

                    PillButton {
                        text: "Preview"
                        onClicked: Battery.warn(1)
                    }
                }
            }

            Text {
                width: parent.width
                leftPadding: 4
                text: "Saved in ~/.config/poteto/shell.json as you change them. Esc closes."
                color: Theme.textSecondary
                font.pixelSize: 11
                font.family: Theme.fontFamily
                wrapMode: Text.WordWrap
            }
        }
    }
}
