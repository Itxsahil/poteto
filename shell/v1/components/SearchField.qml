import QtQuick
import qs.config

// The search box at the top of the island's views: a magnifier, the text, a placeholder, and
// whatever the view puts inside it at the right end (a count, a button, filter chips).
//
//     SearchField {
//         id: search
//         width: parent.width
//         placeholder: "Search themes"
//         onTextChanged: root.selected = 0
//         onKeyPressed: event => { if (event.key === Qt.Key_Escape) { ...; event.accepted = true; } }
//
//         Text { text: "3/12"; ... }      // at the right end
//     }
//
// Keys go to the view through keyPressed: set event.accepted for the ones it handles, and the
// rest reach the text as typing.
Rectangle {
    id: root

    property alias text: textInput.text
    property string placeholder: "Search"
    // The text input itself, for its font or anything else a view needs from it
    readonly property alias input: textInput
    // Space between the right edge and the items at the right end (a button wants less)
    property int trailingMargin: 16
    // Items declared inside the field go in a row at its right end
    default property alias trailing: trailingRow.data

    signal keyPressed(var event)

    function focusInput(): void {
        textInput.forceActiveFocus();
    }

    function clear(): void {
        textInput.text = "";
    }

    implicitHeight: 48
    height: implicitHeight
    radius: Tokens.radius.field
    color: Theme.tileBg

    // The field's own parts are listed in `data` on purpose: declared plainly here, they would go
    // to the default property (trailing) and end up inside the row at the right end
    data: [
        Canvas {
            id: glass
            width: 18
            height: 18
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            property color tint: Theme.textSecondary
            onTintChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                ctx.strokeStyle = tint;
                ctx.lineWidth = 2;
                ctx.lineCap = "round";
                ctx.beginPath();
                ctx.arc(7.5, 7.5, 5.5, 0, Math.PI * 2);
                ctx.moveTo(11.5, 11.5);
                ctx.lineTo(16, 16);
                ctx.stroke();
            }
        },
        TextInput {
            id: textInput
            anchors.left: glass.right
            anchors.leftMargin: 12
            anchors.right: trailingRow.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.textPrimary
            selectionColor: Theme.accent
            selectedTextColor: Theme.onAccent
            font.pixelSize: 16
            font.family: Theme.fontFamily
            clip: true

            Keys.onPressed: event => root.keyPressed(event)

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: !textInput.text
                text: root.placeholder
                color: Theme.textSecondary
                font: textInput.font
            }
        },
        Row {
            id: trailingRow
            anchors.right: parent.right
            anchors.rightMargin: root.trailingMargin
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
        }
    ]
}
