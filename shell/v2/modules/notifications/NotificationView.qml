import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.config
import qs.components
import qs.services

// One notification drawn the shell's way: app icon (a browser's site picture gets the app's icon
// as a badge), app name and time, the summary, the body with its links, and any action buttons.
// Used by the pill (NotificationContent.qml) and the history in the control center. No surface
// and no timing of its own; whoever holds it does those.
Row {
    id: root

    required property var notification
    // Shows the close button; the holder says when (hovered, or always)
    property bool showClose: false
    property int bodyLines: 3
    // How many more are waiting behind this one, shown as +N (0 hides it)
    property int waiting: 0

    readonly property bool critical: notification?.urgency === NotificationUrgency.Critical
    readonly property var buttons: (notification?.actions ?? []).filter(a => a.identifier !== "default" && a.text)

    spacing: 12

    // Bodies arrive as anything from plain text to the spec's small markup subset, and senders
    // (browsers especially) rarely escape "&" or "<". Rendering that raw as StyledText silently
    // drops everything after a stray "<", so escape it all, then put back only the allowed tags.
    function bodyText(raw) {
        if (!raw)
            return "";
        let s = raw.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
        s = s.replace(/&amp;(amp|lt|gt|quot|apos|#\d+|#x[0-9a-f]+);/gi, "&$1;");
        s = s.replace(/&lt;(\/?)(b|i|u)&gt;/gi, "<$1$2>");
        s = s.replace(/&lt;a\s+href=(?:"|&quot;)([^"&]*)(?:"|&quot;)\s*&gt;/gi, '<a href="$1">');
        s = s.replace(/&lt;\/a&gt;/gi, "</a>");
        s = s.replace(/&lt;img\b.*?&gt;/gi, "");
        // Web pushes often pad with blank lines; keep at most one
        s = s.replace(/^\s+|\s+$/g, "").replace(/[ \t]*(\r?\n)+[ \t]*/g, "\n");
        if (!/<a\s/i.test(s))
            s = s.replace(/(https?:\/\/[^\s<]+[^\s<.,;:!?)"'])/g, '<a href="$1">$1</a>');
        return s.replace(/\r?\n/g, "<br/>");
    }

    // Summaries are meant to be plain text, but senders still put markup in them: show the words,
    // not the tags.
    function summaryText(raw) {
        if (!raw)
            return "";
        return raw.replace(/<\/?(b|i|u|a)\b[^>]*>/gi, "")
            .replace(/&(amp|lt|gt|quot|apos);/gi, m => ({ "&amp;": "&", "&lt;": "<", "&gt;": ">", "&quot;": "\"", "&apos;": "'" })[m.toLowerCase()] ?? m);
    }

    function iconSource(icon) {
        if (!icon)
            return "";
        if (icon.startsWith("/"))
            return "file://" + icon;
        if (icon.startsWith("image://icon/"))
            return Quickshell.iconPath(icon.slice("image://icon/".length), true);
        if (icon.includes("://"))
            return icon;
        return Quickshell.iconPath(icon, true);
    }

    function relativeTime(ms) {
        const s = Math.floor((clock.date - ms) / 1000);
        return s < 60 ? "now" : s < 3600 ? `${Math.floor(s / 60)}m` : `${Math.floor(s / 3600)}h`;
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Item {
        id: iconBox
        width: 44
        height: 44

        ClippingRectangle {
            anchors.fill: parent
            radius: 14
            color: Theme.control

            Image {
                id: picture
                anchors.fill: parent
                anchors.margins: root.notification?.image ? 0 : 7
                source: root.iconSource(root.notification?.image) || root.iconSource(root.notification?.appIcon)
                sourceSize.width: 88
                sourceSize.height: 88
                fillMode: root.notification?.image ? Image.PreserveAspectCrop : Image.PreserveAspectFit
                asynchronous: true
                visible: status === Image.Ready
            }

            Text {
                anchors.centerIn: parent
                visible: !picture.visible
                text: "󰂚"
                color: Theme.textDim
                font.pixelSize: 20
                font.family: Theme.monoFamily
            }
        }

        // A browser sends the site's picture plus its own icon: show whose notification it is
        Rectangle {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: -3
            width: 18
            height: 18
            radius: 9
            color: Theme.background
            visible: badge.status === Image.Ready && (root.notification?.image ?? "") !== ""

            Image {
                id: badge
                anchors.fill: parent
                anchors.margins: 2
                source: root.notification?.image ? root.iconSource(root.notification.appIcon) : ""
                sourceSize.width: 32
                sourceSize.height: 32
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }
        }
    }

    Column {
        width: parent.width - iconBox.width - parent.spacing
        spacing: 3

        Item {
            width: parent.width
            height: 16

            Rectangle {
                id: urgentDot
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 6
                height: 6
                radius: 3
                color: Theme.danger
                visible: root.critical
            }

            Text {
                anchors.left: urgentDot.visible ? urgentDot.right : parent.left
                anchors.leftMargin: urgentDot.visible ? 6 : 0
                anchors.right: meta.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                text: root.notification?.appName || "Notification"
                color: Theme.textDim
                font.pixelSize: 11
                font.weight: Font.DemiBold
                font.family: Theme.fontFamily
            }

            Row {
                id: meta
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                // More waiting behind this one
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.waiting > 0
                    text: `+${root.waiting}`
                    color: Theme.accent
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    font.family: Theme.fontFamily
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.relativeTime(Notifications.timeFor(root.notification))
                    color: Theme.textDim
                    font.pixelSize: 11
                    font.family: Theme.fontFamily
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20
                    height: 20
                    radius: 10
                    color: closeMouse.containsMouse ? Theme.controlHover : Theme.control
                    opacity: root.showClose ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: Theme.textDim
                        font.pixelSize: 9
                        font.family: Theme.fontFamily
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifications.dismiss(root.notification)
                    }
                }
            }
        }

        Text {
            width: parent.width
            elide: Text.ElideRight
            maximumLineCount: 2
            wrapMode: Text.Wrap
            visible: text !== ""
            text: root.summaryText(root.notification?.summary)
            textFormat: Text.PlainText
            color: Theme.text
            font.pixelSize: 14
            font.weight: Font.DemiBold
            font.family: Theme.fontFamily
        }

        Text {
            width: parent.width
            elide: Text.ElideRight
            maximumLineCount: root.bodyLines
            wrapMode: Text.Wrap
            visible: text !== ""
            text: root.bodyText(root.notification?.body)
            textFormat: Text.StyledText
            linkColor: Theme.accent
            color: Theme.textDim
            font.pixelSize: 12
            font.family: Theme.fontFamily
            onLinkActivated: link => Qt.openUrlExternally(link)
        }

        Flow {
            width: parent.width
            spacing: 6
            topPadding: 6
            visible: root.buttons.length > 0

            Repeater {
                model: root.buttons

                PillButton {
                    required property var modelData
                    height: 28
                    text: modelData.text
                    onClicked: modelData.invoke()
                }
            }
        }
    }
}
