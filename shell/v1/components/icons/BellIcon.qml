import QtQuick
import qs.config

Canvas {
    id: root

    property color color: Theme.textPrimary
    property bool muted: false

    implicitWidth: 18
    implicitHeight: 18

    onColorChanged: requestPaint()
    onMutedChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.scale(width / 18, height / 18);
        ctx.strokeStyle = color;
        ctx.fillStyle = color;
        ctx.lineWidth = 1.7;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";

        ctx.beginPath();
        ctx.moveTo(4, 13);
        ctx.lineTo(4, 8);
        ctx.bezierCurveTo(4, 5, 6.2, 2.8, 9, 2.8);
        ctx.bezierCurveTo(11.8, 2.8, 14, 5, 14, 8);
        ctx.lineTo(14, 13);
        ctx.lineTo(15.5, 14.5);
        ctx.lineTo(2.5, 14.5);
        ctx.closePath();
        ctx.stroke();

        ctx.beginPath();
        ctx.arc(9, 15.6, 1.6, 0, Math.PI);
        ctx.fill();

        if (muted) {
            ctx.beginPath();
            ctx.moveTo(2, 2);
            ctx.lineTo(16, 16);
            ctx.stroke();
        }
    }
}
