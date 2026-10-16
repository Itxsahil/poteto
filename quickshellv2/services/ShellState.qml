pragma Singleton

import QtQuick
import Quickshell

// What the shell has open right now. Shared by every screen; each window decides for itself
// whether it is the one that shows it (the focused monitor).
Singleton {
    property bool launcherOpen: false
}
