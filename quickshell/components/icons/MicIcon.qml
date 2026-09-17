import QtQuick
import qs.config

Canvas {
    id: root

    property color color: Theme.textPrimary
    property bool muted: false

    implicitWidth: 22
    implicitHeight: 22

    onColorChanged: requestPaint()
    onMutedChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.scale(width / 22, height / 22);
        ctx.strokeStyle = color;
        ctx.fillStyle = color;
        ctx.lineWidth = 1.9;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";

        ctx.beginPath();
        ctx.roundedRect(8, 2.5, 6, 11, 3, 3);
        ctx.fill();

        ctx.beginPath();
        ctx.moveTo(5, 10);
        ctx.bezierCurveTo(5, 13.6, 7.7, 16.3, 11, 16.3);
        ctx.bezierCurveTo(14.3, 16.3, 17, 13.6, 17, 10);
        ctx.moveTo(11, 16.3);
        ctx.lineTo(11, 19.5);
        ctx.moveTo(8, 19.5);
        ctx.lineTo(14, 19.5);
        ctx.stroke();

        if (muted) {
            ctx.lineWidth = 2.2;
            ctx.beginPath();
            ctx.moveTo(3.5, 3);
            ctx.lineTo(18.5, 19);
            ctx.stroke();
        }
    }
}
