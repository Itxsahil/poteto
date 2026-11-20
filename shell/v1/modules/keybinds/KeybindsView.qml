import QtQuick
import qs.config
import qs.components
import qs.services

// The keybind cheatsheet. Hyprland's binds are read from hypr/bindings.lua, so this is the
// config itself rather than a copy of it.
Item {
    id: root

    property bool active: false

    readonly property var rows: {
        const q = search.text.trim().toLowerCase();
        const out = [];
        for (const group of Keybinds.groups) {
            const items = group.items.filter(it => !q
                || it.keys.toLowerCase().includes(q)
                || it.action.toLowerCase().includes(q)
                || (it.detail ?? "").toLowerCase().includes(q)
                || group.name.toLowerCase().includes(q));
            if (items.length === 0)
                continue;
            out.push({ header: true, name: group.name });
            for (const it of items)
                out.push({ header: false, keys: it.keys, action: it.action, detail: it.detail ?? "" });
        }
        return out;
    }

    signal closeRequested()

    implicitWidth: 740
    implicitHeight: 540

    onActiveChanged: {
        if (active) {
            search.text = "";
            list.positionViewAtBeginning();
            search.focusInput();
        }
    }

    SearchField {
        id: search
        width: parent.width
        placeholder: "Search keys or actions"
        onTextChanged: list.positionViewAtBeginning()
        onKeyPressed: event => {
            if (event.key === Qt.Key_Escape)
                root.closeRequested();
            else if (event.key === Qt.Key_Down)
                list.flick(0, -900);
            else if (event.key === Qt.Key_Up)
                list.flick(0, 900);
            else if (event.key === Qt.Key_PageDown)
                list.flick(0, -2600);
            else if (event.key === Qt.Key_PageUp)
                list.flick(0, 2600);
            else
                return;
            event.accepted = true;
        }

        Text {
            id: status
            anchors.verticalCenter: parent.verticalCenter
            text: `${Keybinds.count} shortcuts`
            color: Theme.textSecondary
            font.pixelSize: 11
            font.family: Theme.fontFamily
        }
    }

    Text {
        anchors.centerIn: list
        visible: root.rows.length === 0
        text: `Nothing matches "${search.text}"`
        color: Theme.textSecondary
        font.pixelSize: 13
        font.family: Theme.fontFamily
    }

    ListView {
        id: list
        anchors.top: search.bottom
        anchors.topMargin: 8
        anchors.bottom: footer.top
        anchors.bottomMargin: 6
        width: parent.width
        clip: true
        model: root.rows
        boundsBehavior: Flickable.StopAtBounds
        cacheBuffer: 600

        delegate: Item {
            id: row

            required property var modelData
            readonly property bool isHeader: modelData.header
            readonly property bool clash: !isHeader && (Keybinds.conflicts[modelData.keys] ?? false)
            readonly property var keyList: isHeader ? [] : modelData.keys.split(" + ")

            width: ListView.view.width
            height: isHeader ? 34 : 30

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 6
                visible: row.isHeader
                text: row.isHeader ? row.modelData.name : ""
                color: Theme.textSecondary
                font.pixelSize: 11
                font.weight: Font.DemiBold
                font.letterSpacing: 0.4
                font.family: Theme.fontFamily
            }

            Row {
                id: chips
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                visible: !row.isHeader

                Repeater {
                    model: row.keyList

                    Rectangle {
                        required property string modelData
                        width: keyText.implicitWidth + 14
                        height: 22
                        radius: Tokens.radius.tiny
                        color: row.clash ? Qt.alpha(Theme.danger, 0.16) : Theme.tileBg
                        border.width: 1
                        border.color: row.clash ? Qt.alpha(Theme.danger, 0.5) : Qt.alpha(Theme.textPrimary, 0.08)

                        Text {
                            id: keyText
                            anchors.centerIn: parent
                            text: modelData
                            color: Theme.textPrimary
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            font.family: Theme.fontFamily
                        }
                    }
                }
            }

            Text {
                id: action
                anchors.left: parent.left
                anchors.leftMargin: 250
                anchors.right: detail.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                visible: !row.isHeader
                elide: Text.ElideRight
                text: row.isHeader ? "" : row.modelData.action
                color: Theme.textPrimary
                font.pixelSize: 12
                font.family: Theme.fontFamily
            }

            Text {
                id: detail
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                visible: !row.isHeader && text !== ""
                width: Math.min(implicitWidth, 250)
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
                text: row.isHeader ? ""
                    : row.clash ? "bound twice"
                    : row.modelData.detail
                color: row.clash ? Theme.danger : Theme.textSecondary
                font.pixelSize: 11
                font.family: Theme.fontFamily
            }
        }
    }

    Item {
        id: footer
        anchors.bottom: parent.bottom
        width: parent.width
        height: 20

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            text: "Type to filter   ↑↓ scroll   Esc close   ·   read live from hypr/bindings.lua"
            color: Theme.textSecondary
            font.pixelSize: 11
            font.family: Theme.fontFamily
        }
    }
}
