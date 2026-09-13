import QtQuick
import qs.config
import qs.components

Tile {
    id: root

    property date today: new Date()
    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth()
    readonly property int firstDow: Qt.locale().firstDayOfWeek

    readonly property var cells: {
        const first = new Date(viewYear, viewMonth, 1);
        const offset = (first.getDay() - firstDow + 7) % 7;
        const out = [];
        for (let i = 0; i < 42; i++)
            out.push(new Date(viewYear, viewMonth, 1 - offset + i));
        return out;
    }

    function reset() {
        viewYear = today.getFullYear();
        viewMonth = today.getMonth();
    }

    function shift(delta) {
        const d = new Date(viewYear, viewMonth + delta, 1);
        viewYear = d.getFullYear();
        viewMonth = d.getMonth();
    }

    WheelHandler {
        onWheel: event => root.shift(event.angleDelta.y > 0 ? -1 : 1)
    }

    Column {
        anchors.fill: parent
        spacing: 4

        Item {
            width: parent.width
            height: 24

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.locale().standaloneMonthName(root.viewMonth) + " " + root.viewYear
                color: Theme.textPrimary
                font.pixelSize: 14
                font.weight: Font.DemiBold
                font.family: Theme.fontFamily
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Repeater {
                    model: [-1, 1]

                    Rectangle {
                        required property int modelData
                        width: 24
                        height: 24
                        radius: 12
                        color: navHover.hovered ? Theme.controlBg : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: parent.modelData < 0 ? "‹" : "›"
                            color: Theme.textPrimary
                            font.pixelSize: 18
                            font.family: Theme.fontFamily
                        }

                        HoverHandler { id: navHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: root.shift(parent.modelData) }
                    }
                }
            }
        }

        Row {
            Repeater {
                model: 7

                Text {
                    required property int index
                    width: root.width / 7 - root.padding * 2 / 7
                    height: 18
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: Qt.locale().dayName((root.firstDow + index) % 7, Locale.NarrowFormat)
                    color: Theme.textSecondary
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    font.family: Theme.fontFamily
                }
            }
        }

        Grid {
            columns: 7

            Repeater {
                model: root.cells

                Item {
                    required property var modelData
                    readonly property bool inMonth: modelData.getMonth() === root.viewMonth
                    readonly property bool isToday: modelData.toDateString() === root.today.toDateString()

                    width: root.width / 7 - root.padding * 2 / 7
                    height: 26

                    Rectangle {
                        anchors.centerIn: parent
                        width: 24
                        height: 24
                        radius: 12
                        color: Theme.accent
                        visible: parent.isToday
                    }

                    Text {
                        anchors.centerIn: parent
                        text: parent.modelData.getDate()
                        color: parent.isToday ? Theme.onAccent : parent.inMonth ? Theme.textPrimary : Theme.textSecondary
                        opacity: parent.inMonth || parent.isToday ? 1 : 0.35
                        font.pixelSize: 12
                        font.weight: parent.isToday ? Font.Bold : Font.Normal
                        font.family: Theme.fontFamily
                    }
                }
            }
        }
    }
}
