import QtQuick
import qs.config

Canvas {
    id: root

    property color color: Theme.textPrimary

    implicitWidth: 22
    implicitHeight: 22

    onColorChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.scale(width / 22, height / 22);
        const c = 11;
        ctx.fillStyle = color;
        ctx.strokeStyle = color;
        ctx.beginPath();
        ctx.arc(c, c, 4.5, 0, Math.PI * 2);
        ctx.fill();
        ctx.lineWidth = 2;
        ctx.lineCap = "round";
        for (let i = 0; i < 8; i++) {
            const a = i * Math.PI / 4;
            ctx.beginPath();
            ctx.moveTo(c + Math.cos(a) * 7.5, c + Math.sin(a) * 7.5);
            // (9.5, not 10: the round cap adds 1, and 11 + 10 + 1 ran off the 22-wide canvas)
            ctx.lineTo(c + Math.cos(a) * 9.5, c + Math.sin(a) * 9.5);
            ctx.stroke();
        }
    }
}
