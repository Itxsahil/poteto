import QtQuick
import qs.config

Canvas {
    id: root

    property int strength: 0
    property bool connected: true
    property color color: Theme.textPrimary
    property color dimColor: Theme.wifiInactive
    readonly property int bars: !connected ? 0 : strength >= 75 ? 3 : strength >= 50 ? 2 : strength >= 25 ? 1 : 0

    implicitWidth: 18
    implicitHeight: 14

    onBarsChanged: requestPaint()
    onColorChanged: requestPaint()
    onDimColorChanged: requestPaint()
    onConnectedChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.scale(width / 18, height / 14);
        const cx = 9;
        const cy = 12.5;

        ctx.fillStyle = connected ? color : dimColor;
        ctx.beginPath();
        ctx.arc(cx, cy, 1.8, 0, Math.PI * 2);
        ctx.fill();

        ctx.lineWidth = 2;
        ctx.lineCap = "round";
        for (let i = 1; i <= 3; i++) {
            ctx.strokeStyle = i <= bars ? color : dimColor;
            ctx.beginPath();
            ctx.arc(cx, cy, i * 4, Math.PI * 1.25, Math.PI * 1.75);
            ctx.stroke();
        }
    }
}
