import QtQuick
import qs.config

Canvas {
    id: root

    property real level: 0
    property color fillColor: Theme.batteryGood
    property color outlineColor: Theme.textSecondary
    property color boltColor: Theme.textPrimary
    property color boltStroke: Theme.tileBg
    property bool charging: false

    implicitWidth: 34
    implicitHeight: 18

    onLevelChanged: requestPaint()
    onFillColorChanged: requestPaint()
    onChargingChanged: requestPaint()
    onOutlineColorChanged: requestPaint()
    onBoltColorChanged: requestPaint()
    onBoltStrokeChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.scale(width / 34, height / 18);
        const bodyW = 30;
        const h = 18;

        ctx.strokeStyle = outlineColor;
        ctx.lineWidth = 1.5;
        ctx.beginPath();
        ctx.roundedRect(0.75, 0.75, bodyW - 1.5, h - 1.5, 4, 4);
        ctx.stroke();

        ctx.fillStyle = outlineColor;
        ctx.beginPath();
        ctx.roundedRect(bodyW + 0.5, h / 2 - 3.5, 3, 7, 1.5, 1.5);
        ctx.fill();

        ctx.fillStyle = fillColor;
        ctx.beginPath();
        ctx.roundedRect(3, 3, Math.max(2, (bodyW - 6) * level), h - 6, 2, 2);
        ctx.fill();

        if (charging) {
            const cx = bodyW / 2;
            ctx.fillStyle = boltColor;
            ctx.strokeStyle = boltStroke;
            ctx.lineWidth = 1;
            ctx.beginPath();
            ctx.moveTo(cx + 2, 1.5);
            ctx.lineTo(cx - 4, 10);
            ctx.lineTo(cx, 10);
            ctx.lineTo(cx - 2, 16.5);
            ctx.lineTo(cx + 4, 8);
            ctx.lineTo(cx, 8);
            ctx.closePath();
            ctx.fill();
            ctx.stroke();
        }
    }
}
