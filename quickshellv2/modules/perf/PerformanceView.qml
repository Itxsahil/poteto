import QtQuick
import qs.config
import qs.services

// The performance monitor (Super + M): CPU with each thread and core, memory, the GPUs, storage,
// network, the system's sensors and the busiest processes, from services/SystemStats.qml, which
// only samples while this is open. Laid out as a bento grid like the control center.
Item {
    id: root

    property bool active: false

    readonly property var s: SystemStats.sample
    readonly property int gap: 10
    readonly property real col: (width - gap * 2) / 3
    readonly property string mono: "JetBrainsMono Nerd Font"
    readonly property color warn: Theme.warning
    readonly property color bad: Theme.danger

    signal closeRequested()

    implicitWidth: 760
    implicitHeight: grid.implicitHeight

    // Plain until a number needs attention: warning past `high`, danger past `critical`
    function level(value, high, critical) {
        return value >= critical ? bad : value >= high ? warn : Theme.text;
    }

    function pct(used, total) {
        return total > 0 ? 100 * used / total : 0;
    }

    onActiveChanged: {
        if (active)
            keys.forceActiveFocus();
    }

    Item {
        id: keys
        focus: root.active
        Keys.onEscapePressed: root.closeRequested()
    }

    // ---- pieces ----

    component Label: Text {
        color: Theme.textDim
        font.pixelSize: 11
        font.weight: Font.DemiBold
        font.letterSpacing: 0.6
        font.family: Theme.fontFamily
    }

    component Value: Text {
        color: Theme.text
        font.pixelSize: 13
        font.family: Theme.fontFamily
    }

    component Big: Text {
        color: Theme.text
        font.pixelSize: 28
        font.weight: Font.Bold
        font.family: Theme.fontFamily
    }

    // A rounded card, as the control center's tiles are
    component Tile: Rectangle {
        id: tile
        property int padding: 14
        default property alias content: tileContent.data
        radius: 22
        color: Theme.tile

        Item {
            id: tileContent
            anchors.fill: parent
            anchors.margins: tile.padding
        }
    }

    // A name and its value, in the System tile
    component Line: Item {
        property string name
        property string value
        property color valueColor: Theme.text
        width: parent.width
        height: 16
        visible: value !== ""
        Value {
            text: parent.name
            font.pixelSize: 12
            color: Theme.textDim
        }
        Value {
            anchors.right: parent.right
            text: parent.value
            font.pixelSize: 12
            font.family: root.mono
            color: parent.valueColor
        }
    }

    // A thin bar, 0–100
    component Meter: Rectangle {
        id: meter
        property real value: 0
        property color fill: Theme.accent
        height: 6
        radius: 3
        color: Theme.control

        Rectangle {
            width: Math.max(meter.height, meter.width * Math.min(1, Math.max(0, meter.value / 100)))
            height: parent.height
            radius: parent.radius
            color: meter.fill
            visible: meter.value > 0
            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        }
    }

    // The last minute as a filled line; `max` 0 scales to the largest value
    component Graph: Canvas {
        id: graph
        property var values: []
        property real max: 100
        property color tint: Theme.accent

        onValuesChanged: requestPaint()
        onTintChanged: requestPaint()
        onWidthChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const v = values;
            if (v.length < 2)
                return;
            const top = max > 0 ? max : Math.max(1, ...v) * 1.15;
            const step = width / (SystemStats.historyLength - 1);
            const x0 = width - (v.length - 1) * step;
            const y = val => height - Math.min(1, val / top) * (height - 2) - 1;
            ctx.beginPath();
            ctx.moveTo(x0, height);
            for (let i = 0; i < v.length; i++)
                ctx.lineTo(x0 + i * step, y(v[i]));
            ctx.lineTo(width, height);
            ctx.closePath();
            ctx.fillStyle = Qt.alpha(tint, 0.16);
            ctx.fill();
            ctx.beginPath();
            for (let i = 0; i < v.length; i++) {
                if (i === 0)
                    ctx.moveTo(x0, y(v[0]));
                else
                    ctx.lineTo(x0 + i * step, y(v[i]));
            }
            ctx.strokeStyle = tint;
            ctx.lineWidth = 1.5;
            ctx.lineJoin = "round";
            ctx.stroke();
        }
    }

    Column {
        id: grid
        width: parent.width
        spacing: root.gap

        // Title
        Item {
            width: parent.width
            height: 30

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                text: "Performance"
                color: Theme.text
                font.pixelSize: 18
                font.weight: Font.Bold
                font.family: Theme.fontFamily
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                text: !root.s.load ? "Reading…"
                    : `up ${SystemStats.formatUptime(root.s.load.uptime)}  ·  ${root.s.load.processes} processes  ·  Esc to close`
                color: Theme.textDim
                font.pixelSize: 11
                font.family: Theme.fontFamily
            }
        }

        // ---- CPU (wide) and memory ----
        Row {
            spacing: root.gap

            Tile {
                width: root.col * 2 + root.gap
                height: 200

                Column {
                    id: cpuHead
                    anchors.left: parent.left
                    anchors.top: parent.top
                    spacing: 2

                    Label { text: "CPU" }

                    Row {
                        spacing: 10

                        Big {
                            text: root.s.cpu !== undefined ? Math.round(root.s.cpu) + "%" : "–"
                            color: root.level(root.s.cpu ?? 0, 75, 92)
                        }

                        Column {
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 5

                            Value {
                                text: root.s.freqs ? (Math.max(...root.s.freqs) / 1000).toFixed(2) + " GHz" : ""
                                font.pixelSize: 11
                                color: Theme.textDim
                            }

                            Value {
                                text: root.s.temps?.cpu != null ? Math.round(root.s.temps.cpu) + " °C" : ""
                                font.pixelSize: 11
                                color: root.level(root.s.temps?.cpu ?? 0, 80, 92)
                            }
                        }
                    }
                }

                Graph {
                    anchors.left: parent.left
                    anchors.right: threads.left
                    anchors.rightMargin: 16
                    anchors.bottom: parent.bottom
                    anchors.top: cpuHead.bottom
                    anchors.topMargin: 10
                    values: SystemStats.cpuHistory
                }

                // Each thread, and the cores' temperatures under their two threads
                Item {
                    id: threads
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 230

                    Label {
                        anchors.left: parent.left
                        text: `${root.s.threads?.length ?? 0} THREADS`
                    }

                    Label {
                        anchors.right: parent.right
                        text: root.s.governor ? root.s.governor.toUpperCase() : ""
                        color: Qt.alpha(Theme.textDim, 0.7)
                    }

                    Row {
                        id: bars
                        anchors.top: parent.top
                        anchors.topMargin: 22
                        anchors.bottom: coreTemps.top
                        anchors.bottomMargin: 6
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 6

                        Repeater {
                            model: root.s.threads ?? []

                            Item {
                                required property var modelData
                                required property int index
                                width: (threads.width - 6 * ((root.s.threads?.length ?? 1) - 1)) / Math.max(1, root.s.threads?.length ?? 1)
                                height: bars.height

                                Rectangle {
                                    id: track
                                    anchors.top: parent.top
                                    anchors.bottom: pctText.top
                                    anchors.bottomMargin: 4
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 14
                                    radius: 4
                                    color: Theme.control

                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        width: parent.width
                                        height: Math.max(parent.radius, parent.height * Math.min(1, modelData / 100))
                                        radius: parent.radius
                                        color: root.level(modelData, 75, 92) === Theme.text ? Theme.accent : root.level(modelData, 75, 92)
                                        Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                                    }
                                }

                                Text {
                                    id: pctText
                                    anchors.bottom: parent.bottom
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: Math.round(modelData)
                                    color: Theme.textDim
                                    font.pixelSize: 10
                                    font.family: root.mono
                                }
                            }
                        }
                    }

                    Row {
                        id: coreTemps
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 6
                        visible: (root.s.temps?.cores?.length ?? 0) > 0

                        Repeater {
                            model: root.s.temps?.cores ?? []

                            Rectangle {
                                required property var modelData
                                required property int index
                                // A core is two threads wide
                                width: (threads.width - 6 * ((root.s.temps?.cores?.length ?? 1) - 1)) / Math.max(1, root.s.temps?.cores?.length ?? 1)
                                height: 20
                                radius: 6
                                color: Theme.control

                                Text {
                                    anchors.centerIn: parent
                                    text: `C${index}  ${Math.round(modelData)}°`
                                    color: root.level(modelData, 80, 92)
                                    font.pixelSize: 10
                                    font.family: root.mono
                                }
                            }
                        }
                    }
                }
            }

            Tile {
                width: root.col
                height: 200

                Column {
                    width: parent.width
                    spacing: 2

                    Label { text: "MEMORY" }

                    Big {
                        text: root.s.mem ? Math.round(root.pct(root.s.mem.used, root.s.mem.total)) + "%" : "–"
                        color: root.level(root.pct(root.s.mem?.used ?? 0, root.s.mem?.total ?? 1), 80, 92)
                    }

                    Value {
                        text: root.s.mem ? `${SystemStats.formatBytes(root.s.mem.used)} of ${SystemStats.formatBytes(root.s.mem.total)}` : ""
                        font.pixelSize: 11
                        color: Theme.textDim
                    }
                }

                Graph {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: swap.top
                    anchors.bottomMargin: 10
                    height: 60
                    values: SystemStats.memHistory
                }

                Column {
                    id: swap
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    spacing: 5
                    visible: (root.s.mem?.swapTotal ?? 0) > 0

                    Item {
                        width: parent.width
                        height: 14
                        Label { text: "SWAP" }
                        Value {
                            anchors.right: parent.right
                            text: root.s.mem ? `${SystemStats.formatBytes(root.s.mem.swapUsed)} / ${SystemStats.formatBytes(root.s.mem.swapTotal)}` : ""
                            font.pixelSize: 11
                            color: Theme.textDim
                        }
                    }

                    Meter {
                        width: parent.width
                        value: root.pct(root.s.mem?.swapUsed ?? 0, root.s.mem?.swapTotal ?? 0)
                        fill: Qt.alpha(Theme.text, 0.6)
                    }
                }
            }
        }

        // ---- GPU, storage, network ----
        Row {
            spacing: root.gap

            Tile {
                width: root.col
                height: 160

                Column {
                    width: parent.width
                    spacing: 6

                    Item {
                        width: parent.width
                        height: 14
                        Label { text: "GPU" }
                        Label {
                            anchors.right: parent.right
                            text: root.s.gpu?.name ?? ""
                            color: Qt.alpha(Theme.textDim, 0.7)
                            font.weight: Font.Normal
                            font.letterSpacing: 0
                        }
                    }

                    // NVIDIA: its numbers while awake; asleep, it is left asleep
                    Big {
                        visible: root.s.gpu != null
                        text: !root.s.gpu ? "" : root.s.gpu.asleep ? "Asleep" : root.s.gpu.util != null ? Math.round(root.s.gpu.util) + "%" : "Awake"
                        color: root.s.gpu?.asleep ? Theme.textDim : root.level(root.s.gpu?.util ?? 0, 80, 95)
                        font.pixelSize: root.s.gpu?.asleep ? 20 : 28
                    }

                    Value {
                        visible: root.s.gpu?.asleep ?? false
                        width: parent.width
                        wrapMode: Text.Wrap
                        text: "Not woken to check, so it stays off and saves battery"
                        font.pixelSize: 11
                        color: Theme.textDim
                    }

                    Column {
                        width: parent.width
                        spacing: 4
                        visible: root.s.gpu != null && !root.s.gpu.asleep && root.s.gpu.memTotal != null

                        Item {
                            width: parent.width
                            height: 14
                            Value {
                                text: `${Math.round(root.s.gpu?.memUsed ?? 0)} / ${Math.round(root.s.gpu?.memTotal ?? 0)} MB`
                                font.pixelSize: 11
                                color: Theme.textDim
                            }
                            Value {
                                anchors.right: parent.right
                                text: `${Math.round(root.s.gpu?.temp ?? 0)} °C · ${(root.s.gpu?.power ?? 0).toFixed(1)} W`
                                font.pixelSize: 11
                                color: root.level(root.s.gpu?.temp ?? 0, 80, 90) === Theme.text ? Theme.textDim : root.level(root.s.gpu?.temp ?? 0, 80, 90)
                            }
                        }

                        Meter {
                            width: parent.width
                            value: root.pct(root.s.gpu?.memUsed ?? 0, root.s.gpu?.memTotal ?? 0)
                        }
                    }
                }

                Value {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    visible: root.s.igpu != null
                    text: root.s.igpu ? `Intel graphics  ·  ${root.s.igpu.freq} MHz` : ""
                    font.pixelSize: 11
                    color: Theme.textDim
                }
            }

            Tile {
                width: root.col
                height: 160

                Column {
                    width: parent.width
                    spacing: 7

                    Item {
                        width: parent.width
                        height: 14
                        Label { text: "STORAGE" }
                        Label {
                            anchors.right: parent.right
                            text: root.s.temps?.ssd != null ? `SSD ${Math.round(root.s.temps.ssd)} °C` : ""
                            color: root.level(root.s.temps?.ssd ?? 0, 60, 70) === Theme.text ? Qt.alpha(Theme.textDim, 0.7) : root.level(root.s.temps?.ssd ?? 0, 60, 70)
                        }
                    }

                    Repeater {
                        model: root.s.disk?.space ?? []

                        Column {
                            required property var modelData
                            width: parent.width
                            spacing: 4

                            readonly property real used: root.pct(modelData.used, modelData.total)

                            Item {
                                width: parent.width
                                height: 15
                                Value {
                                    text: modelData.mount
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                }
                                Value {
                                    anchors.right: parent.right
                                    text: `${SystemStats.formatBytes(modelData.used)} / ${SystemStats.formatBytes(modelData.total)}`
                                    font.pixelSize: 11
                                    color: Theme.textDim
                                }
                            }

                            Meter {
                                width: parent.width
                                value: parent.used
                                fill: root.level(parent.used, 85, 95) === Theme.text ? Theme.accent : root.level(parent.used, 85, 95)
                            }
                        }
                    }
                }

                Row {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    spacing: 14

                    Value {
                        // null: the disk / is on could not be told, so there is nothing to show
                        text: "↓ " + (root.s.disk?.read == null ? "—" : SystemStats.formatRate(root.s.disk.read))
                        font.pixelSize: 11
                        font.family: root.mono
                        color: Theme.textDim
                    }

                    Value {
                        text: "↑ " + (root.s.disk?.write == null ? "—" : SystemStats.formatRate(root.s.disk.write))
                        font.pixelSize: 11
                        font.family: root.mono
                        color: Theme.textDim
                    }
                }
            }

            Tile {
                width: root.col
                height: 160

                Item {
                    id: netHead
                    width: parent.width
                    height: 14
                    Label { text: "NETWORK" }
                    Label {
                        anchors.right: parent.right
                        text: root.s.net?.iface ?? ""
                        color: Qt.alpha(Theme.textDim, 0.7)
                    }
                }

                Column {
                    id: netRates
                    anchors.top: netHead.bottom
                    anchors.topMargin: 6
                    spacing: 1

                    Value {
                        text: "↓ " + SystemStats.formatRate(root.s.net?.down ?? 0)
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                        font.family: root.mono
                    }

                    Value {
                        text: "↑ " + SystemStats.formatRate(root.s.net?.up ?? 0)
                        font.pixelSize: 12
                        font.family: root.mono
                        color: Theme.textDim
                    }
                }

                Graph {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: netRates.bottom
                    anchors.topMargin: 6
                    anchors.bottom: netTotals.top
                    anchors.bottomMargin: 6
                    values: SystemStats.downHistory
                    max: 0
                }

                Value {
                    id: netTotals
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    text: root.s.net ? `${SystemStats.formatBytes(root.s.net.rxTotal)} down · ${SystemStats.formatBytes(root.s.net.txTotal)} up since boot` : ""
                    font.pixelSize: 10
                    color: Theme.textDim
                }
            }
        }

        // ---- processes and system ----
        Row {
            spacing: root.gap

            Tile {
                width: root.col * 2 + root.gap
                height: procColumn.implicitHeight + padding * 2

                Column {
                    id: procColumn
                    width: parent.width
                    spacing: 2

                    Item {
                        width: parent.width
                        height: 20
                        Label { text: "BUSIEST PROCESSES" }
                        Label {
                            anchors.right: parent.right
                            anchors.rightMargin: 72
                            text: "CPU"
                        }
                        Label {
                            anchors.right: parent.right
                            anchors.rightMargin: 140
                            text: "MEMORY"
                        }
                    }

                    Repeater {
                        model: root.s.top ?? []

                        Rectangle {
                            id: procRow
                            required property var modelData
                            // Clicked once, End asks again for a few seconds before it ends anything
                            property bool confirming: false

                            width: parent.width
                            height: 28
                            radius: 8
                            color: rowHover.hovered ? Theme.tileHover : "transparent"

                            HoverHandler {
                                id: rowHover
                            }

                            Value {
                                anchors.left: parent.left
                                anchors.leftMargin: 6
                                anchors.right: parent.right
                                anchors.rightMargin: 200
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight
                                text: procRow.modelData.name
                                font.pixelSize: 12
                            }

                            Value {
                                anchors.right: parent.right
                                anchors.rightMargin: 140
                                anchors.verticalCenter: parent.verticalCenter
                                text: SystemStats.formatBytes(procRow.modelData.rss)
                                font.pixelSize: 11
                                font.family: root.mono
                                color: Theme.textDim
                            }

                            Value {
                                anchors.right: parent.right
                                anchors.rightMargin: 72
                                anchors.verticalCenter: parent.verticalCenter
                                text: procRow.modelData.cpu.toFixed(1) + "%"
                                font.pixelSize: 11
                                font.family: root.mono
                                color: root.level(procRow.modelData.cpu, 50, 90) === Theme.text ? Theme.textDim : root.level(procRow.modelData.cpu, 50, 90)
                            }

                            // Only your own processes, and none the session depends on
                            // (scripts/sysstats decides), can be ended from here
                            Rectangle {
                                anchors.right: parent.right
                                anchors.rightMargin: 4
                                anchors.verticalCenter: parent.verticalCenter
                                visible: procRow.modelData.endable && (rowHover.hovered || procRow.confirming)
                                width: 58
                                height: 22
                                radius: 11
                                color: procRow.confirming ? Theme.danger : endMouse.containsMouse ? Theme.controlHover : Theme.control

                                Text {
                                    anchors.centerIn: parent
                                    text: procRow.confirming ? "Sure?" : "End"
                                    color: procRow.confirming ? Theme.accentText : Theme.text
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    font.family: Theme.fontFamily
                                }

                                MouseArea {
                                    id: endMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (procRow.confirming) {
                                            SystemStats.end(procRow.modelData.pid);
                                            procRow.confirming = false;
                                        } else {
                                            procRow.confirming = true;
                                            confirmTimer.restart();
                                        }
                                    }
                                }

                                Timer {
                                    id: confirmTimer
                                    interval: 3000
                                    onTriggered: procRow.confirming = false
                                }
                            }
                        }
                    }

                    Value {
                        visible: (root.s.top?.length ?? 0) === 0
                        text: "Measuring…"
                        font.pixelSize: 11
                        color: Theme.textDim
                    }
                }
            }

            Tile {
                width: root.col
                height: procColumn.implicitHeight + padding * 2

                Column {
                    width: parent.width
                    spacing: 9

                    Label { text: "SYSTEM" }

                    Line {
                        name: "Load"
                        value: root.s.load ? root.s.load.avg.map(v => v.toFixed(2)).join("  ") : ""
                    }

                    Line {
                        name: "Fan"
                        value: root.s.temps?.fan != null ? (root.s.temps.fan > 0 ? root.s.temps.fan + " RPM" : "Off") : ""
                    }

                    Line {
                        name: "Battery"
                        value: !root.s.battery ? ""
                            : root.s.battery.status === "Discharging" ? `${root.s.battery.watts} W draw`
                            : root.s.battery.status === "Charging" ? `${root.s.battery.watts} W charging`
                            : `${root.s.battery.level}% · ${root.s.battery.status}`
                    }

                    Line {
                        name: "Uptime"
                        value: root.s.load ? SystemStats.formatUptime(root.s.load.uptime) : ""
                    }

                    Line {
                        name: "Disk"
                        value: root.s.disk?.name ?? ""
                    }
                }
            }
        }
    }
}
