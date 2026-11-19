import QtQuick
import qs.config
import qs.components
import qs.services

// Password prompt for polkit. The password goes straight to polkit (which checks it
// through PAM) and is cleared from the field as soon as it is sent.
Item {
    id: root

    property bool active: false
    readonly property var flow: Polkit.flow
    readonly property bool waiting: flow !== null && !flow.isResponseRequired && !flow.isCompleted
    property bool wrong: false

    signal closeRequested()

    implicitWidth: 460
    implicitHeight: content.implicitHeight

    function submit() {
        if (!flow || !flow.isResponseRequired || input.text.length === 0)
            return;
        wrong = false;
        Polkit.submit(input.text);
        input.text = "";
    }

    onActiveChanged: {
        input.text = "";
        wrong = false;
        if (active)
            input.forceActiveFocus();
    }

    Connections {
        target: root.flow
        function onAuthenticationFailed() {
            root.wrong = true;
            shake.restart();
        }
        function onIsResponseRequiredChanged() {
            if (root.flow.isResponseRequired && root.active)
                input.forceActiveFocus();
        }
    }

    Column {
        id: content
        width: parent.width
        spacing: 12

        Item {
            width: parent.width
            height: Math.max(40, heading.implicitHeight)

            Rectangle {
                id: badge
                width: 40
                height: 40
                radius: 20
                color: Theme.accent

                // padlock
                Canvas {
                    anchors.centerIn: parent
                    width: 16
                    height: 18
                    property color tint: Theme.onAccent
                    onTintChanged: requestPaint()
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        ctx.strokeStyle = tint;
                        ctx.fillStyle = tint;
                        ctx.lineWidth = 2;
                        ctx.beginPath();
                        ctx.arc(8, 7, 4.5, Math.PI, 0);
                        ctx.lineTo(12.5, 9);
                        ctx.moveTo(3.5, 9);
                        ctx.lineTo(3.5, 7);
                        ctx.stroke();
                        ctx.beginPath();
                        ctx.roundedRect(1, 8.5, 14, 9.5, 2.5, 2.5);
                        ctx.fill();
                    }
                }
            }

            Column {
                id: heading
                anchors.left: badge.right
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    text: "Authentication required"
                    color: Theme.textPrimary
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    font.family: Theme.fontFamily
                }

                Text {
                    width: parent.width
                    text: root.flow?.message ?? ""
                    visible: text !== ""
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    color: Theme.textSecondary
                    font.pixelSize: 11
                    font.family: Theme.fontFamily
                }
            }
        }

        Rectangle {
            id: field
            width: parent.width
            height: 44
            radius: 14
            color: Theme.tileBg
            border.width: 1
            border.color: root.wrong ? Theme.danger : input.activeFocus ? Theme.accent : "transparent"
            Behavior on border.color { ColorAnimation { duration: 140 } }

            SequentialAnimation {
                id: shake
                NumberAnimation { target: field; property: "x"; to: 8; duration: 50 }
                NumberAnimation { target: field; property: "x"; to: -8; duration: 50 }
                NumberAnimation { target: field; property: "x"; to: 5; duration: 50 }
                NumberAnimation { target: field; property: "x"; to: 0; duration: 70 }
            }

            TextInput {
                id: input
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.right: busy.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                enabled: root.flow?.isResponseRequired ?? false
                echoMode: root.flow?.responseVisible ? TextInput.Normal : TextInput.Password
                passwordCharacter: "•"
                inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                color: Theme.textPrimary
                selectionColor: Theme.accent
                selectedTextColor: Theme.onAccent
                font.pixelSize: 15
                font.family: Theme.fontFamily
                clip: true

                Keys.onReturnPressed: root.submit()
                Keys.onEnterPressed: root.submit()
                Keys.onEscapePressed: root.closeRequested()

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !input.text
                    text: (root.flow?.inputPrompt ?? "").replace(/:\s*$/, "") || "Password"
                    color: Theme.textSecondary
                    font: input.font
                }
            }

            Spinner {
                id: busy
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                width: 16
                height: 16
                visible: root.waiting
            }
        }

        Item {
            width: parent.width
            height: 32

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.right: buttons.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                text: root.wrong ? "Wrong password, try again"
                    : root.flow?.supplementaryMessage ? root.flow.supplementaryMessage
                    : root.waiting ? "Checking…"
                    : "↵ authenticate   Esc cancel"
                color: root.wrong || root.flow?.supplementaryIsError ? Theme.danger : Theme.textSecondary
                font.pixelSize: 11
                font.family: Theme.fontFamily
            }

            Row {
                id: buttons
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                PillButton {
                    text: "Cancel"
                    onClicked: root.closeRequested()
                }

                PillButton {
                    text: "Authenticate"
                    primary: true
                    enabled: input.text.length > 0 && (root.flow?.isResponseRequired ?? false)
                    onClicked: root.submit()
                }
            }
        }
    }
}
