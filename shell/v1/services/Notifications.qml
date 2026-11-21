pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.config

Singleton {
    id: root

    readonly property int maxHistory: 50
    readonly property int maxPopups: 4
    readonly property int defaultTimeout: 5000
    readonly property int criticalTimeout: 20000

    // Do Not Disturb: kept in config/Settings.qml ("quiet" in shell.json, the settings drawer's switch),
    // so it survives a restart. Change it with setDnd() / toggleDnd(), not by assigning.
    readonly property bool dnd: Settings.quiet
    property var popups: []
    readonly property string showInDndHint: "x-poteto-show-in-dnd"

    // Sample notifications of every shape (tools/notif-test in the repo): one kind, or all of
    // them a few seconds apart when kind is ""
    readonly property string testScript: Quickshell.shellDir + "/../../tools/notif-test"

    function sendTests(kind: string): void {
        Quickshell.execDetached(kind ? [testScript, kind] : [testScript]);
    }

    function setDnd(on) {
        Settings.set("quiet", !!on);
    }

    function toggleDnd() {
        setDnd(!dnd);
    }
    property var arrivedAt: ({})
    // Everything that arrived at or before this has been seen
    property double readAt: 0

    readonly property var history: [...server.trackedNotifications.values].reverse()
    readonly property int count: history.length

    // Counted from what is actually still in the history rather than tallied as they arrive: a
    // notification you dismiss, or one the app withdraws, leaves the history and stops counting.
    // A tally cannot do that, and would drift above the number of notifications you can still see.
    // Anything with no arrival time was restored across a shell reload, so it is not new.
    readonly property int unread: history.filter(n => !n.transient && (arrivedAt[n.id] ?? 0) > readAt).length

    function timeFor(notification) {
        return arrivedAt[notification.id] ?? Date.now();
    }

    function hidePopup(notification) {
        popups = popups.filter(n => n !== notification);
        if (notification.transient && notification.tracked)
            notification.expire();
    }

    // Every popup off the screen; they stay in the history. keepCritical leaves the critical ones
    // (and the shell's own warnings), which Do Not Disturb would still show
    function clearPopups(keepCritical: bool): void {
        for (const n of [...root.popups]) {
            if (keepCritical && (n.urgency === NotificationUrgency.Critical || n.hints[root.showInDndHint] === true))
                continue;
            root.hidePopup(n);
        }
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
    }

    function markRead() {
        readAt = Date.now();
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
        // Kept on incoming notifications (unlisted hints are dropped). x-poteto-show-in-dnd: the
        // shell's own warnings that must be seen even in Do Not Disturb (services/Battery.qml).
        extraHints: [root.showInDndHint]

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

            if (root.dnd && notification.urgency !== NotificationUrgency.Critical
                    && notification.hints[root.showInDndHint] !== true)
                return;

            root.popups = [notification, ...root.popups.filter(n => n !== notification)].slice(0, root.maxPopups);
        }
    }
}
