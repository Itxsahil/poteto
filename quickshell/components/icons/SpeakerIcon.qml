import QtQuick
import qs.config

Canvas {
    id: root

    property real level: 0
    property bool muted: false
    property color color: Theme.textPrimary

    implicitWidth: 22
    implicitHeight: 22

    onLevelChanged: requestPaint()
    onMutedChanged: requestPaint()
    onColorChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.scale(width / 22, height / 22);
        ctx.fillStyle = color;
        ctx.strokeStyle = color;

        ctx.beginPath();
        ctx.moveTo(2, 8);
        ctx.lineTo(6, 8);
        ctx.lineTo(11, 3.5);
        ctx.lineTo(11, 18.5);
        ctx.lineTo(6, 14);
        ctx.lineTo(2, 14);
        ctx.closePath();
        ctx.fill();

        ctx.lineWidth = 2;
        ctx.lineCap = "round";

        if (muted || level === 0) {
            ctx.beginPath();
            ctx.moveTo(14.5, 8); ctx.lineTo(20, 14);
            ctx.moveTo(20, 8); ctx.lineTo(14.5, 14);
            ctx.stroke();
            return;
        }

        const waves = level > 0.66 ? 3 : level > 0.33 ? 2 : 1;
        for (let i = 1; i <= waves; i++) {
            ctx.beginPath();
            ctx.arc(10, 11, 3 + i * 3, -Math.PI / 4, Math.PI / 4);
            ctx.stroke();
        }
    }
}
