import QtQuick
import qs.config
import qs.components.icons
import qs.services

QuickToggleTile {
    title: "Notifications"
    subtitle: Notifications.dnd ? "Do Not Disturb"
        : Notifications.unread > 0 ? `${Notifications.unread} new`
        : Notifications.count > 0 ? `${Notifications.count} in history`
        : "No notifications"
    active: Notifications.dnd

    onToggleRequested: Notifications.dnd = !Notifications.dnd

    BellIcon {
        anchors.centerIn: parent
        width: 18
        height: 18
        muted: Notifications.dnd
        color: Notifications.dnd ? Theme.onAccent : Theme.textPrimary
    }
}
