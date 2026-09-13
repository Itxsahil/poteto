import QtQuick
import qs.config

Canvas {
    id: root

    property color color: Theme.accent

    implicitWidth: 16
    implicitHeight: 12

    onColorChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.scale(width / 16, height / 12);
        ctx.strokeStyle = color;
        ctx.lineWidth = 2.2;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";
        ctx.beginPath();
        ctx.moveTo(1.5, 6.5);
        ctx.lineTo(5.5, 10.5);
        ctx.lineTo(14.5, 1.5);
        ctx.stroke();
    }
}
