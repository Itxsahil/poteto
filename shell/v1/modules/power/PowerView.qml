import QtQuick
import qs.config
import qs.services

Item {
    id: root

    property bool active: false
    property int selected: 0
    property string armed: ""

    readonly property var actions: Session.actions
    readonly property int buttonWidth: 108
    readonly property int buttonGap: 10

    signal closeRequested()

    implicitWidth: actions.length * buttonWidth + (actions.length - 1) * buttonGap
    implicitHeight: header.height + 12 + 128 + 10 + footer.height

    function trigger(index) {
        const action = actions[index];
        if (!action)
            return;
        selected = index;
        if (action.confirm && armed !== action.id) {
            armed = action.id;
            disarmTimer.restart();
            return;
        }
        armed = "";
        closeRequested();
        Session.run(action.id);
    }

    function move(delta) {
        armed = "";
        selected = (selected + delta + actions.length) % actions.length;
    }

    onActiveChanged: {
        if (active) {
            selected = 0;
            armed = "";
            Session.refresh();
            keys.forceActiveFocus();
        }
    }

    Timer {
        id: disarmTimer
        interval: 3000
        onTriggered: root.armed = ""
    }

    Item {
        id: keys
        focus: true
        Keys.onPressed: event => {
            const key = event.text.toUpperCase();
            const byKey = root.actions.findIndex(a => a.key === key);
            if (event.key === Qt.Key_Escape) {
                if (root.armed)
                    root.armed = "";
                else
                    root.closeRequested();
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab || event.key === Qt.Key_J || event.key === Qt.Key_Down) {
                root.move(1);
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab || event.key === Qt.Key_K || event.key === Qt.Key_Up) {
                root.move(-1);
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                root.trigger(root.selected);
            } else if (byKey >= 0) {
                root.trigger(byKey);
            } else {
                return;
            }
            event.accepted = true;
        }
    }

    Item {
        id: header
        width: parent.width
        height: 44

        Rectangle {
            id: avatar
            width: 40
            height: 40
            radius: 20
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.accent

            Text {
                anchors.centerIn: parent
                text: (Session.user || "?").charAt(0).toUpperCase()
                color: Theme.onAccent
                font.pixelSize: 17
                font.weight: Font.Bold
                font.family: Theme.fontFamily
            }
        }

        Column {
            anchors.left: avatar.right
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                text: Session.user
                color: Theme.textPrimary
                font.pixelSize: 15
                font.weight: Font.DemiBold
                font.family: Theme.fontFamily
            }

            Text {
                text: Session.uptime ? `Up ${Session.uptime}` : ""
                color: Theme.textSecondary
                font.pixelSize: 11
                font.family: Theme.fontFamily
            }
        }
    }

    Row {
        id: buttons
        anchors.top: header.bottom
        anchors.topMargin: 12
        spacing: root.buttonGap

        Repeater {
            model: root.actions

            Rectangle {
                id: button

                required property var modelData
                required property int index
                readonly property bool isSelected: index === root.selected
                readonly property bool isArmed: root.armed === modelData.id
                readonly property color contentColor: isArmed ? Theme.islandBg : Theme.textPrimary

                width: root.buttonWidth
                height: 128
                radius: 24
                color: isArmed ? Theme.danger : isSelected ? Theme.tileHover : Theme.tileBg
                border.width: 2
                border.color: isArmed ? Theme.danger : isSelected ? Theme.textPrimary : "transparent"
                scale: mouse.pressed ? 0.96 : 1

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
                Behavior on scale { NumberAnimation { duration: 100 } }

                Column {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: button.modelData.glyph
                        color: button.isArmed ? button.contentColor : button.modelData.confirm && button.isSelected ? Theme.danger : button.contentColor
                        font.pixelSize: 34
                        font.family: "JetBrainsMono Nerd Font"
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: button.isArmed ? "Press again" : button.modelData.label
                        color: button.contentColor
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        font.family: Theme.fontFamily
                    }
                }

                Rectangle {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 10
                    width: 20
                    height: 20
                    radius: 6
                    color: button.isArmed ? Qt.alpha(Theme.islandBg, 0.25) : Theme.controlBg

                    Text {
                        anchors.centerIn: parent
                        text: button.modelData.key
                        color: button.isArmed ? button.contentColor : Theme.textSecondary
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.family: Theme.fontFamily
                    }
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: {
                        if (root.selected !== button.index)
                            root.armed = "";
                        root.selected = button.index;
                    }
                    onClicked: root.trigger(button.index)
                }
            }
        }
    }

    Item {
        id: footer
        anchors.top: buttons.bottom
        anchors.topMargin: 10
        width: parent.width
        height: 20

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            text: root.armed ? "Press again to confirm  ·  Esc to cancel" : "Letter or ↵ to choose   ←→ navigate   Esc close"
            color: root.armed ? Theme.danger : Theme.textSecondary
            font.pixelSize: 11
            font.family: Theme.fontFamily
        }
    }
}
