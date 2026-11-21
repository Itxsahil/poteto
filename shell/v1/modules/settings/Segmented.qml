pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.components

// A choice between a few options, as one pill with the chosen one filled
//
//     Segmented { options: [{ value: "pill", label: "Pill" }, { value: "bar", label: "Bar" }];
//                 current: Settings.style; onPicked: value => ... }
Rectangle {
    id: root

    // [{ value, label }]
    property var options: []
    property string current

    signal picked(string value)

    implicitWidth: buttons.implicitWidth + 6
    implicitHeight: 30
    radius: height / 2
    color: Theme.controlBg

    Row {
        id: buttons
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: root.options

            Rectangle {
                id: option

                required property var modelData
                readonly property bool chosen: modelData.value === root.current

                width: optionText.implicitWidth + 22
                height: root.height - 6
                radius: height / 2
                color: chosen ? Theme.controlFill : optionMouse.containsMouse ? Theme.controlHover : "transparent"
                Behavior on color { CAnim {} }

                Text {
                    id: optionText
                    anchors.centerIn: parent
                    text: option.modelData.label
                    color: option.chosen ? Theme.controlIconOnFill : Theme.textPrimary
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    font.family: Theme.fontFamily
                }

                MouseArea {
                    id: optionMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(option.modelData.value)
                }
            }
        }
    }
}
