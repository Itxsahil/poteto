#version 440
// The shell's surface: the frame around the screen and every piece hanging from it (the island,
// the workspaces, status and recording pills from the top edge, the settings drawer from the
// right, the notifications from the bottom-right corner), drawn as one shape.
//
// Each piece is a signed distance field (negative inside, positive outside), joined with a smooth
// minimum: where a pill's side meets the frame the join is a round curve `smoothing` wide, the same
// as the frame's own inside corners, so the wallpaper showing through reads as one hole with every
// corner rounded alike. Computed, so it holds at any size and every frame of an animation.
//
// Compiled with qsb (tools/build-shaders) into surface.frag.qsb, which is what the shell loads.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    // The item's size in pixels
    vec2 size;
    vec4 color;
    // The frame: its width and its rounded inside corners (both 0 for no frame)
    float frameWidth;
    float frameRadius;
    // Where the inside of the frame starts at the top (the frame's width, or the bottom of the bar
    // in bar mode), and above which it is not drawn at all (so the bar shows)
    float frameTop;
    float frameClip;
    // A horizontal band the pills hang from: its top and bottom in pixels, and how present it is
    // (the screen's top edge, or the bottom of the bar in bar mode)
    vec4 wall;
    // How wide the round join between a pill and the frame is
    float smoothing;
    // Up to six pieces: x, y, width, height in pixels (width 0: unused)
    vec4 rect0;
    vec4 rect1;
    vec4 rect2;
    vec4 rect3;
    vec4 rect4;
    vec4 rect5;
    // Their corner radii, how present each is (0 to 1: one fading out recedes) and the edge each
    // hangs from (0: the top, 1: the right, 2: the bottom-right corner); pieces 0-3 in the first,
    // 4-5 in the second
    vec4 radii;
    vec4 radii2;
    vec4 alphas;
    vec4 alphas2;
    vec4 edges;
    vec4 edges2;
};

float sdRoundedBox(vec2 p, vec2 center, vec2 halfSize, float radius) {
    radius = min(radius, min(halfSize.x, halfSize.y));
    vec2 d = abs(p - center) - halfSize + vec2(radius);
    return length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0) - radius;
}

// A box rounded only on the side away from the edge it hangs from, that side run far out (into
// the frame, out of sight), so nothing pulls away from the edge. edge 0: the top, 1: the right,
// 2: the bottom-right corner (run out to the right and down, rounded only at the top left)
float sdHanging(vec2 p, vec4 r, float radius, float edge) {
    vec2 topLeft = r.xy;
    vec2 bottomRight = r.xy + r.zw;
    if (edge > 1.5)
        bottomRight += vec2(64.0);
    else if (edge > 0.5)
        bottomRight.x += 64.0;
    else
        topLeft.y -= 64.0;
    vec2 halfSize = (bottomRight - topLeft) * 0.5;
    vec2 q = p - (topLeft + bottomRight) * 0.5;
    bool away = edge > 1.5 ? (p.x < r.x + radius && p.y < r.y + radius)
        : edge > 0.5 ? q.x < 0.0 : q.y > 0.0;
    float rad = away ? min(radius, min(r.z * 0.5, r.w * 0.5)) : 0.0;
    vec2 d = abs(q) - halfSize + vec2(rad);
    return length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0) - rad;
}

// Circular smooth minimum: the join is an arc of radius k, tangent to both shapes
float smin(float a, float b, float k) {
    if (k <= 0.0)
        return min(a, b);
    return max(k, min(a, b)) - length(max(vec2(k) - vec2(a, b), vec2(0.0)));
}

// A piece: its rectangle hanging from its edge, rounded on the far side. Absent ones are far away;
// a fading one recedes into the edge it hangs from.
float pill(vec2 p, vec4 r, float radius, float alpha, float edge) {
    if (r.z <= 0.0 || r.w <= 0.0 || alpha <= 0.0)
        return 1e5;
    float d = sdHanging(p, r, radius, edge);
    float extent = edge > 1.5 ? max(r.z, r.w) : edge > 0.5 ? r.z : r.w;
    return d + (1.0 - alpha) * (extent + smoothing);
}

void main() {
    vec2 p = qt_TexCoord0 * size;

    // The frame: everything outside the inner rounded rectangle
    float d = 1e5;
    if (frameWidth > 0.0) {
        vec2 innerMin = vec2(frameWidth, frameTop);
        vec2 innerMax = size - vec2(frameWidth);
        d = -sdRoundedBox(p, (innerMin + innerMax) * 0.5, (innerMax - innerMin) * 0.5, frameRadius);
        // Nothing above frameClip (the bar in bar mode): there the frame is far away
        if (p.y < frameClip)
            d = max(d, frameClip - p.y);
    }

    // The band the pills hang from
    if (wall.z > 0.0) {
        float band = abs(p.y - (wall.x + wall.y) * 0.5) - (wall.y - wall.x) * 0.5;
        d = min(d, band + (1.0 - wall.z) * 1e3);
    }

    // Each piece flows into the frame in a round curve
    d = smin(d, pill(p, rect0, radii.x, alphas.x, edges.x), smoothing);
    d = smin(d, pill(p, rect1, radii.y, alphas.y, edges.y), smoothing);
    d = smin(d, pill(p, rect2, radii.z, alphas.z, edges.z), smoothing);
    d = smin(d, pill(p, rect3, radii.w, alphas.w, edges.w), smoothing);
    d = smin(d, pill(p, rect4, radii2.x, alphas2.x, edges2.x), smoothing);
    d = smin(d, pill(p, rect5, radii2.y, alphas2.y, edges2.y), smoothing);

    // A soft edge one pixel wide
    float aa = max(fwidth(d), 0.0001);
    float coverage = clamp(0.5 - d / aa, 0.0, 1.0);
    fragColor = vec4(color.rgb, 1.0) * color.a * coverage * qt_Opacity;
}
