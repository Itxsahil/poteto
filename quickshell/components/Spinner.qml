import QtQuick
import qs.config

Canvas {
    id: root

    property color color: Theme.accent

    implicitWidth: 18
    implicitHeight: 18

    onColorChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const r = Math.min(width, height) / 2 - 2;
        ctx.strokeStyle = color;
        ctx.lineWidth = 2;
        ctx.lineCap = "round";
        ctx.beginPath();
        ctx.arc(width / 2, height / 2, r, 0, Math.PI * 1.4);
        ctx.stroke();
    }

    RotationAnimator on rotation {
        from: 0
        to: 360
        duration: 800
        loops: Animation.Infinite
        running: root.visible
    }
}
