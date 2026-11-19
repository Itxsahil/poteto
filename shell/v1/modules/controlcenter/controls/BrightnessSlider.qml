import QtQuick
import qs.config
import qs.components
import qs.components.icons
import qs.services

ControlSlider {
    minValue: 0.01
    value: Brightness.value

    onMoved: v => Brightness.set(v)

    SunIcon {
        anchors.fill: parent
        color: Theme.controlIconOnFill
    }
}
