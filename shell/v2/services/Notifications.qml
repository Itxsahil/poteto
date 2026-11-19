pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.config

// The session's notification server (org.freedesktop.Notifications). In quiet mode (Config.quiet)
// only critical ones are shown; the rest go straight to history. Nothing pops up on its own: the
// pill grows into them (modules/notifications/NotificationContent.qml through
// modules/bar/Views.qml), the newest at once, with older unseen ones waiting behind it. Every
// notification also stays in history until it is dismissed or withdrawn.
Singleton {
    id: root

    readonly property int maxHistory: 50
    // Waiting to be shown; past this many the oldest ones leave the queue (they stay in history)
    readonly property int maxQueue: 5
    readonly property int defaultTimeout: 5000
    readonly property int criticalTimeout: 12000

    // Newest first; the first is the one the pill is showing
    property var queue: []
    readonly property var current: queue.length > 0 ? queue[0] : null
    property var arrivedAt: ({})

    // Newest first. By id, which only goes up: the server's own list is not in arrival order
    // (a replacement keeps its old place, and so do ones kept across a shell reload)
    readonly property var history: [...server.trackedNotifications.values].sort((a, b) => b.id - a.id)
    readonly property int count: history.length
    // Everything that arrived at or before this has been seen (the history page was opened)
    property double readAt: 0
    // Counted from what is still in history, so dismissed or withdrawn ones stop counting.
    // Anything without an arrival time came back across a shell reload, so it is not new.
    readonly property int unread: history.filter(n => !n.transient && (arrivedAt[n.id] ?? 0) > readAt).length

    // A notification just arrived (for the pill's arrival animation)
    signal arrived(var notification)

    function timeFor(notification) {
        return arrivedAt[notification?.id] ?? Date.now();
    }

    // The pill is done with the one it is showing: on to the next. Transient ones (that asked
    // not to be kept) go away for good; the rest stay in history.
    function next() {
        const done = current;
        queue = queue.slice(1);
        if (done && done.transient && done.tracked)
            done.expire();
    }

    function dismiss(notification) {
        queue = queue.filter(n => n !== notification);
        notification.dismiss();
    }

    function invokeDefault(notification) {
        const action = notification.actions.find(a => a.identifier === "default");
        if (action)
            action.invoke();
        else
            dismiss(notification);
    }

    function markRead() {
        readAt = Date.now();
    }

    function clearAll() {
        queue = [];
        for (const n of [...server.trackedNotifications.values])
            n.dismiss();
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
                root.queue = root.queue.filter(n => n !== notification);
                const remaining = Object.assign({}, root.arrivedAt);
                delete remaining[id];
                root.arrivedAt = remaining;
            });

            const tracked = server.trackedNotifications.values;
            for (let i = 0; i < tracked.length - root.maxHistory; i++)
                tracked[i].expire();

            // Quiet mode: into history only, unless it is critical
            if (Config.quiet && notification.urgency !== NotificationUrgency.Critical)
                return;

            // The newest takes the pill straight away; the one it pushes aside waits right behind
            // it. A replacement (same id) updates in place where it already is in the queue.
            if (!root.queue.includes(notification))
                root.queue = [notification, ...root.queue].slice(0, root.maxQueue);
            root.arrived(notification);
        }
    }
}
