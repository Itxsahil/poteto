import QtQuick
import qs.config

// A ColorAnimation with the shell's timing (config/Tokens.qml): hover-fast by default, since most
// color changes are feedback under the pointer.
//
//     Behavior on color { CAnim {} }
//     Behavior on border.color { CAnim { duration: Tokens.duration.fade } }
ColorAnimation {
    duration: Tokens.duration.press
    easing.type: Tokens.easing.standard
}
