import QtQuick
import qs.config

Canvas {
    id: root

    property color color: Theme.textPrimary

    implicitWidth: 12
    implicitHeight: 18

    onColorChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.scale(width / 12, height / 18);
        ctx.strokeStyle = color;
        ctx.lineWidth = 1.9;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";
        ctx.beginPath();
        ctx.moveTo(1.5, 5);
        ctx.lineTo(10, 12.5);
        ctx.lineTo(6, 16.5);
        ctx.lineTo(6, 1.5);
        ctx.lineTo(10, 5.5);
        ctx.lineTo(1.5, 13);
        ctx.stroke();
    }
}
