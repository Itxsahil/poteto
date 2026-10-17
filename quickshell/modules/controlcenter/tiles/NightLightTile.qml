import QtQuick
import qs.config
import qs.services

// Night light: the round button turns it on and off, the tile opens its warmth page
QuickToggleTile {
    title: "Night Light"
    subtitle: NightLight.enabled ? `On · ${NightLight.temperature} K` : "Off"
    active: NightLight.enabled

    onToggleRequested: NightLight.toggle()

    Text {
        anchors.centerIn: parent
        text: NightLight.enabled ? "󰖔" : "󰖙"
        color: NightLight.enabled ? Theme.onAccent : Theme.textPrimary
        font.pixelSize: 18
        font.family: "JetBrainsMono Nerd Font"
    }
}
