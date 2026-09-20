import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.config
import qs.components
import qs.components.icons
import qs.services

Rectangle {
    id: root

    required property var notification
    property bool popup: false
    property int bodyLines: popup ? 4 : 6
    readonly property bool hovered: cardHover.hovered
    readonly property bool critical: notification.urgency === NotificationUrgency.Critical
    readonly property var buttons: notification.actions.filter(a => a.identifier !== "default" && a.text)

    signal timedOut()

    implicitHeight: content.implicitHeight + 28
    radius: 20
    color: popup ? Theme.islandBg : Theme.tileBg
    border.width: 1
    // Critical gets a small red dot by the app name, not a red border around the whole card:
    // browsers send their web pushes as critical, and a wall of red reads as alarming.
    border.color: popup ? Theme.islandBorder : "transparent"

    function relativeTime(ms) {
        const s = Math.floor((clock.date - ms) / 1000);
        if (s < 60)
            return "now";
        if (s < 3600)
            return `${Math.floor(s / 60)}m`;
        if (s < 86400)
            return `${Math.floor(s / 3600)}h`;
        return Qt.formatDateTime(new Date(ms), "d MMM");
    }

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

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Every popup goes away on its own; the history page keeps it either way. Browsers send their
    // web pushes as critical with "never expire", which otherwise pins them to the screen forever.
    Timer {
        id: expireTimer
        running: root.popup && !root.hovered
        interval: root.notification.expireTimeout > 0 ? root.notification.expireTimeout
            : root.critical ? Notifications.criticalTimeout
            : Notifications.defaultTimeout
        onTriggered: root.timedOut()
    }

    HoverHandler {
        id: cardHover
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Notifications.invokeDefault(root.notification)
    }

    Row {
        id: content
        x: 14
        y: 14
        width: parent.width - 28
        spacing: 12

        Item {
            id: iconBox
            width: 40
            height: 40

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: Theme.controlBg
                clip: true

                Image {
                    id: picture
                    anchors.fill: parent
                    source: root.iconSource(root.notification.image) || root.iconSource(root.notification.appIcon)
                    sourceSize.width: 80
                    sourceSize.height: 80
                    fillMode: root.notification.image ? Image.PreserveAspectCrop : Image.PreserveAspectFit
                    anchors.margins: root.notification.image ? 0 : 6
                    asynchronous: true
                    visible: status === Image.Ready
                }

                BellIcon {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    color: Theme.textSecondary
                    visible: !picture.visible
                }
            }

            // A browser sends the site's picture plus its own icon: show whose notification it is.
            Rectangle {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: -3
                width: 18
                height: 18
                radius: 9
                color: root.popup ? Theme.islandBg : Theme.tileBg
                visible: badge.status === Image.Ready && root.notification.image !== ""

                Image {
                    id: badge
                    anchors.fill: parent
                    anchors.margins: 2
                    source: root.notification.image ? root.iconSource(root.notification.appIcon) : ""
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
                    text: root.notification.appName || "Notification"
                    color: Theme.textSecondary
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    font.family: Theme.fontFamily
                }

                Row {
                    id: meta
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.relativeTime(Notifications.timeFor(root.notification))
                        color: Theme.textSecondary
                        font.pixelSize: 11
                        font.family: Theme.fontFamily
                    }

                    Rectangle {
                        width: 20
                        height: 20
                        radius: 10
                        anchors.verticalCenter: parent.verticalCenter
                        color: closeMouse.containsMouse ? Theme.controlHover : Theme.controlBg
                        opacity: root.hovered || !root.popup ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: Theme.textSecondary
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
                text: root.summaryText(root.notification.summary)
                textFormat: Text.PlainText
                color: Theme.textPrimary
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
                text: root.bodyText(root.notification.body)
                textFormat: Text.StyledText
                linkColor: Theme.accent
                color: Theme.textSecondary
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
}
