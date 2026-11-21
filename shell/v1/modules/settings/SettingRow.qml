import QtQuick
import qs.config

// One row of a settings section: a label, an optional line of detail under it, and a control at
// its right end (declared inside the row)
//
//     SettingRow { label: "Workspaces"; detail: "The pill top left"; Toggle { ... } }
Item {
    id: root

    property string label
    property string detail
    // The control declared inside the row, at its right end
    default property alias control: controlSlot.data

    width: parent?.width ?? implicitWidth
    implicitHeight: Math.max(texts.implicitHeight, controlSlot.height) + 20

    // The row's own parts are listed in `data` on purpose: declared plainly here they would go to
    // the default property (control) and end up in the control's slot
    data: [
        Column {
            id: texts
            anchors.left: root.left
            anchors.leftMargin: 12
            anchors.right: controlSlot.left
            anchors.rightMargin: 12
            anchors.verticalCenter: root.verticalCenter
            spacing: 2

            Text {
                width: parent.width
                text: root.label
                color: Theme.textPrimary
                font.pixelSize: 13
                font.weight: Font.DemiBold
                font.family: Theme.fontFamily
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                visible: root.detail !== ""
                text: root.detail
                color: Theme.textSecondary
                font.pixelSize: 11
                font.family: Theme.fontFamily
                wrapMode: Text.WordWrap
            }
        },
        Item {
            id: controlSlot
            anchors.right: root.right
            anchors.rightMargin: 12
            anchors.verticalCenter: root.verticalCenter
            width: childrenRect.width
            height: childrenRect.height
        }
    ]
}
