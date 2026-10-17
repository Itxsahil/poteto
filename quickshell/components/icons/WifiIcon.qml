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
        // Drawn on an 18 × 14 grid with a 1-unit margin all round: the outer arc's stroke reaches
        // past the 18 × 14 box, and a canvas cuts off whatever falls outside it
        ctx.scale(width / 20, height / 16);
        ctx.translate(1, 1);
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
