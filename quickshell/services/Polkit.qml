pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Polkit

// The session's polkit authentication agent: whenever any app asks for admin rights
// (pkexec, disk tools, the login theme switcher), the password prompt opens in the island.
Singleton {
    id: root

    readonly property AuthFlow flow: agent.flow
    readonly property bool active: agent.isActive
    readonly property bool registered: agent.isRegistered

    function submit(password) {
        if (flow && flow.isResponseRequired)
            flow.submit(password);
    }

    function cancel() {
        if (flow && !flow.isCompleted)
            flow.cancelAuthenticationRequest();
    }

    PolkitAgent {
        id: agent
        onAuthenticationRequestStarted: ShellState.open("polkit")
        onIsActiveChanged: {
            if (!isActive)
                ShellState.close("polkit");
        }
    }

    // Closing the prompt any other way (Esc, clicking outside, another view) is a cancel.
    Connections {
        target: ShellState
        function onViewChanged() {
            if (ShellState.view !== "polkit")
                root.cancel();
        }
    }
}
