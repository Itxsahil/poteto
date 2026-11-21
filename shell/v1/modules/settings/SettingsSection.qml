import QtQuick
import qs.config

// A titled group of rows in the settings drawer: the title above, the rows on one tile
//
//     SettingsSection {
//         title: "Night light"
//         SettingRow { label: "Night light"; Toggle { ... } }
//     }
Column {
    id: root

    property string title
    // Rows declared inside the section go on the tile
    default property alias rows: rowsColumn.data

    width: parent?.width ?? implicitWidth
    spacing: 8

    // The section's own parts are listed in `data` on purpose: declared plainly here they would go
    // to the default property (rows) and end up inside the tile
    data: [
        Text {
            leftPadding: 4
            text: root.title
            color: Theme.textSecondary
            font.pixelSize: 12
            font.weight: Font.DemiBold
            font.family: Theme.fontFamily
        },
        Rectangle {
            width: root.width
            height: rowsColumn.implicitHeight + 8
            radius: Tokens.radius.tile
            color: Theme.tileBg

            Column {
                id: rowsColumn
                x: 4
                y: 4
                width: parent.width - 8
            }
        }
    ]
}
