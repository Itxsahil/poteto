pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    readonly property int maxHistory: 50
    readonly property int maxPopups: 4
    readonly property int defaultTimeout: 5000

    property bool dnd: false
    property var popups: []
    property var arrivedAt: ({})
    property int unread: 0

    readonly property var history: [...server.trackedNotifications.values].reverse()
    readonly property int count: history.length

    function timeFor(notification) {
        return arrivedAt[notification.id] ?? Date.now();
    }

    function hidePopup(notification) {
        popups = popups.filter(n => n !== notification);
        if (notification.transient && notification.tracked)
            notification.expire();
    }

    function dismiss(notification) {
        popups = popups.filter(n => n !== notification);
        notification.dismiss();
    }

    function invokeDefault(notification) {
        const action = notification.actions.find(a => a.identifier === "default");
        if (action)
            action.invoke();
        else
            dismiss(notification);
    }

    function clearAll() {
        popups = [];
        for (const n of [...server.trackedNotifications.values])
            n.dismiss();
        unread = 0;
    }

    function markRead() {
        unread = 0;
    }

    NotificationServer {
        id: server

        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: notification => {
            notification.tracked = true;

            const times = Object.assign({}, root.arrivedAt);
            times[notification.id] = Date.now();
            root.arrivedAt = times;

            const id = notification.id;
            notification.closed.connect(() => {
                root.popups = root.popups.filter(n => n !== notification);
                const remaining = Object.assign({}, root.arrivedAt);
                delete remaining[id];
                root.arrivedAt = remaining;
            });

            const tracked = server.trackedNotifications.values;
            for (let i = 0; i < tracked.length - root.maxHistory; i++)
                tracked[i].expire();

            if (!notification.transient)
                root.unread++;

            if (root.dnd && notification.urgency !== NotificationUrgency.Critical)
                return;

            root.popups = [notification, ...root.popups.filter(n => n !== notification)].slice(0, root.maxPopups);
        }
    }
}
