import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.config
import qs.services

// The notification the pill has grown into (Notifications.current), drawn by
// NotificationView.qml. No surface of its own; the pill (or the bar's panel) is the card. It
// leaves on its own after a few seconds, or longer for critical ones; hovering holds it, a click
// runs its default action, the cross dismisses it. When the next one in the queue takes its
// place, the content slides in again without the pill closing.
Item {
    id: root

    property bool active: false
    readonly property var notification: Notifications.current
    readonly property bool critical: notification?.urgency === NotificationUrgency.Critical
    readonly property bool hovered: hover.hovered

    // Nothing to close for this view: it closes itself by moving the queue on
    signal closeRequested()

    implicitWidth: 400
    implicitHeight: Math.max(48, content.implicitHeight)

    // Each new one slides in from above
    onNotificationChanged: {
        if (notification)
            enter.restart();
    }

    SequentialAnimation {
        id: enter
        PropertyAction { target: content; property: "opacity"; value: 0 }
        PropertyAction { target: content; property: "y"; value: -10 }
        PauseAnimation { duration: 120 }
        ParallelAnimation {
            NumberAnimation { target: content; property: "opacity"; to: 1; duration: 260; easing.type: Easing.OutCubic }
            NumberAnimation { target: content; property: "y"; to: 0; duration: 380; easing.type: Easing.OutBack; easing.overshoot: 1.6 }
        }
    }

    // How long this one stays, held while hovered. Browsers send their web pushes as critical
    // with "never expire", which would otherwise pin them in the pill for good.
    Timer {
        id: expire
        running: root.active && root.notification !== null && !root.hovered
        interval: root.notification?.expireTimeout > 0 ? Math.min(root.notification.expireTimeout, Notifications.criticalTimeout)
            : root.critical ? Notifications.criticalTimeout
            : Notifications.defaultTimeout
        onTriggered: Notifications.next()
    }

    // A new one restarts the clock even if the timer was already running
    Connections {
        target: Notifications
        function onCurrentChanged() {
            if (expire.running)
                expire.restart();
        }
    }

    HoverHandler {
        id: hover
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.notification)
                Notifications.invokeDefault(root.notification);
        }
    }

    // How much time is left, as a hairline along the bottom
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: -8
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width * 0.4
        height: 2
        radius: 1
        color: Qt.alpha(Theme.text, 0.1)
        visible: root.notification !== null

        Rectangle {
            id: left
            height: parent.height
            radius: 1
            color: root.critical ? Theme.danger : Theme.accent
            width: parent.width

            NumberAnimation on width {
                id: countdown
                running: false
            }
        }

        // Restart the hairline whenever the timer (re)starts, pause it while hovered
        Connections {
            target: expire
            function onRunningChanged() {
                if (expire.running) {
                    left.width = left.parent.width;
                    countdown.from = left.parent.width;
                    countdown.to = 0;
                    countdown.duration = expire.interval;
                    countdown.restart();
                } else {
                    countdown.stop();
                    left.width = left.parent.width;
                }
            }
        }
    }

    NotificationView {
        id: content
        width: parent.width
        notification: root.notification
        showClose: root.hovered
        waiting: Math.max(0, Notifications.queue.length - 1)
    }
}
