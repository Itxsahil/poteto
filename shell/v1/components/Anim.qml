import QtQuick
import qs.config

// A NumberAnimation with the shell's timing (config/Tokens.qml): Tokens.duration.view and the
// standard curve unless told otherwise.
//
//     Behavior on opacity { Anim {} }
//     Behavior on x { Anim { duration: Tokens.duration.page } }
NumberAnimation {
    duration: Tokens.duration.view
    easing.type: Tokens.easing.standard
}
