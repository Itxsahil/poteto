pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property string view: ""

    function toggle(name) {
        view = view === name ? "" : name;
    }

    function open(name) {
        view = name;
    }

    function close(name) {
        if (!name || view === name)
            view = "";
    }
}
