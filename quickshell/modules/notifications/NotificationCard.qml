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
    property int bodyLines: popup ? 3 : 6
    readonly property bool hovered: cardHover.hovered
    readonly property bool critical: notification.urgency === NotificationUrgency.Critical
    readonly property var buttons: notification.actions.filter(a => a.identifier !== "default" && a.text)

    signal timedOut()

    implicitHeight: content.implicitHeight + 28
    radius: 20
    color: popup ? Theme.islandBg : Theme.tileBg
    border.width: 1
    border.color: critical ? Theme.danger : popup ? Theme.islandBorder : "transparent"

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

    Timer {
        id: expireTimer
        running: root.popup && !root.critical && root.notification.expireTimeout !== 0 && !root.hovered
        interval: root.notification.expireTimeout > 0 ? root.notification.expireTimeout : Notifications.defaultTimeout
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

        Rectangle {
            id: iconBox
            width: 40
            height: 40
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

        Column {
            width: parent.width - iconBox.width - parent.spacing
            spacing: 3

            Item {
                width: parent.width
                height: 16

                Text {
                    anchors.left: parent.left
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
                text: root.notification.summary
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
                text: root.notification.body
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
