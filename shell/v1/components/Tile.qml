import QtQuick
import qs.config

Rectangle {
    id: root

    property int padding: 14
    default property alias content: inner.data

    radius: Tokens.radius.tile
    color: Theme.tileBg

    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: root.padding
    }
}
