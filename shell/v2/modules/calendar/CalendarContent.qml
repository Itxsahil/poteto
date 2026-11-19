import QtQuick
import Quickshell
import qs.config

// The calendar (the calendar button beside the pill or on the bar, or qs ipc call calendar):
// a month at a time, weeks starting on Monday, today in the accent. ←/→ or the arrows change
// month, scrolling does too, T or "Today" comes back, Esc closes.
Item {
    id: root

    property bool active: false
    // The month on show, as its first day
    property date shown: new Date()
    readonly property date today: clock.date

    readonly property int year: shown.getFullYear()
    readonly property int month: shown.getMonth()
    // As "2026-10" keys: comparing the dates themselves left this binding stale on first open
    readonly property bool showingToday: Qt.formatDate(shown, "yyyy-MM") === Qt.formatDate(clock.date, "yyyy-MM")
    // The six weeks of cells on show, starting on the Monday on or before the 1st
    readonly property var cells: {
        const first = new Date(year, month, 1);
        const lead = (first.getDay() + 6) % 7;
        const out = [];
        for (let i = 0; i < 42; i++) {
            const d = new Date(year, month, 1 - lead + i);
            out.push({
                day: d.getDate(),
                inMonth: d.getMonth() === month,
                isToday: d.toDateString() === today.toDateString(),
                weekend: d.getDay() === 0 || d.getDay() === 6
            });
        }
        return out;
    }

    signal closeRequested()

    function step(delta) {
        shown = new Date(year, month + delta, 1);
    }

    function goToday() {
        shown = new Date(today.getFullYear(), today.getMonth(), 1);
    }

    onActiveChanged: {
        if (active) {
            goToday();
            keys.forceActiveFocus();
        }
    }

    implicitWidth: 340
    implicitHeight: column.implicitHeight

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Item {
        id: keys
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape)
                root.closeRequested();
            else if (event.key === Qt.Key_Left || event.key === Qt.Key_H || event.key === Qt.Key_PageUp)
                root.step(-1);
            else if (event.key === Qt.Key_Right || event.key === Qt.Key_L || event.key === Qt.Key_PageDown)
                root.step(1);
            else if (event.key === Qt.Key_T)
                root.goToday();
            else
                return;
            event.accepted = true;
        }
    }

    WheelHandler {
        property real accumulated: 0
        onWheel: event => {
            accumulated += event.angleDelta.y;
            if (Math.abs(accumulated) < 120)
                return;
            root.step(accumulated > 0 ? -1 : 1);
            accumulated = 0;
        }
    }

    // A small round arrow or text button for the header
    component HeaderButton: Rectangle {
        id: button
        property string text
        property bool round: true
        signal clicked()
        width: round ? 28 : label.implicitWidth + 20
        height: 28
        radius: 14
        color: mouse.containsMouse ? Theme.tileHover : Theme.tile
        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
            id: label
            anchors.centerIn: parent
            text: button.text
            color: Theme.text
            font.pixelSize: button.round ? 14 : 11
            font.weight: Font.Medium
            font.family: button.round ? Theme.monoFamily : Theme.fontFamily
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }

    Column {
        id: column
        width: parent.width
        spacing: 12

        // Month and year, today's date under them, and the controls
        Item {
            width: parent.width
            height: 40

            Column {
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    text: Qt.formatDate(root.shown, "MMMM yyyy")
                    color: Theme.text
                    font.pixelSize: 17
                    font.weight: Font.DemiBold
                    font.family: Theme.fontFamily
                }

                Text {
                    text: Qt.formatDate(root.today, "dddd, d MMMM")
                    color: Theme.textDim
                    font.pixelSize: 11
                    font.family: Theme.fontFamily
                }
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                HeaderButton {
                    visible: !root.showingToday
                    round: false
                    text: "Today"
                    onClicked: root.goToday()
                }

                HeaderButton {
                    text: "󰅁"
                    onClicked: root.step(-1)
                }

                HeaderButton {
                    text: "󰅂"
                    onClicked: root.step(1)
                }
            }
        }

        // Weekday names, then the days
        Grid {
            id: grid
            columns: 7
            width: parent.width

            readonly property real cell: width / 7

            Repeater {
                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

                Text {
                    required property string modelData
                    required property int index
                    width: grid.cell
                    height: 24
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: modelData
                    color: index >= 5 ? Qt.alpha(Theme.textDim, 0.8) : Theme.textDim
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    font.family: Theme.fontFamily
                }
            }

            Repeater {
                model: root.cells

                Item {
                    required property var modelData
                    width: grid.cell
                    height: 38

                    Rectangle {
                        anchors.centerIn: parent
                        width: 32
                        height: 32
                        radius: 16
                        color: parent.modelData.isToday ? Theme.accent : "transparent"
                    }

                    Text {
                        anchors.centerIn: parent
                        text: parent.modelData.day
                        color: parent.modelData.isToday ? Theme.accentText
                            : !parent.modelData.inMonth ? Qt.alpha(Theme.text, 0.25)
                            : parent.modelData.weekend ? Theme.textDim
                            : Theme.text
                        font.pixelSize: 13
                        font.weight: parent.modelData.isToday ? Font.Bold : Font.Normal
                        font.family: Theme.fontFamily
                    }
                }
            }
        }
    }
}
