pragma Singleton

import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Io

// Webcam state for the camera view. Named Webcam, not Camera, because QtMultimedia already has a
// Camera type and the view needs both.
//
// The capture pipeline itself (Camera, CaptureSession, ImageCapture) lives in the view, not here:
// the webcam is only powered while the view is open, so its light never stays on in the background.
// This holds what survives a close — which camera, mirrored or not, the self-timer, and the last
// photo taken.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string saveDir: home + "/Pictures/Camera"

    // Mirrored by default: a preview of your own face reads as a mirror, not as a video call.
    // The saved photo follows the preview, so what you framed is what you get.
    property bool mirror: true
    // Self-timer in seconds, cycled through these by the view
    readonly property var timers: [0, 3, 10]
    property int timer: 0

    property int deviceIndex: 0
    property string lastShot: ""
    property int shotCount: 0

    // Shutter bookkeeping: the second a photo was named in, how many landed in it, and the photos
    // still waiting to be mirrored
    property string lastStamp: ""
    property int sameSecond: 0
    property var flipQueue: []

    readonly property var devices: mediaDevices.videoInputs
    readonly property bool available: devices.length > 0
    readonly property var device: available ? devices[Math.min(deviceIndex, devices.length - 1)]
        : mediaDevices.defaultVideoInput
    readonly property string deviceName: device ? device.description : "No camera found"

    MediaDevices {
        id: mediaDevices
    }

    Process {
        id: mkdir
        command: ["mkdir", "-p", root.saveDir]
    }

    Process {
        id: opener
        property string path: ""
        command: ["xdg-open", path]
    }

    // ImageCapture writes the raw sensor frame, which is the opposite way round from a mirrored
    // preview. Flip the file to match what was on screen, so the photo is the shot you framed.
    Process {
        id: flip
        property string path: ""
        command: ["magick", path, "-flop", path]
        onExited: {
            const done = root.flipQueue[0];
            root.flipQueue = root.flipQueue.slice(1);
            root.finishShot(done);
            root.pumpFlip();
        }
    }

    // Called when the view opens, so the folder is there well before the first shutter press
    function ensureDir() {
        if (!mkdir.running)
            mkdir.running = true;
    }

    function nextDevice() {
        if (devices.length > 1)
            deviceIndex = (deviceIndex + 1) % devices.length;
    }

    function cycleTimer() {
        timer = timers[(timers.indexOf(timer) + 1) % timers.length];
    }

    // ~/Pictures/Camera/2026-09-29_01-42-07.jpg, with -2, -3 ... for shots inside the same second,
    // which two quick shutter presses otherwise name identically, losing the first photo
    function nextPath() {
        const stamp = Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss");
        if (stamp === lastStamp) {
            sameSecond++;
        } else {
            lastStamp = stamp;
            sameSecond = 0;
        }
        return `${saveDir}/${stamp}${sameSecond ? "-" + (sameSecond + 1) : ""}.jpg`;
    }

    // One flip at a time: the process rewrites the file in place, and a second shot arriving
    // mid-flip would otherwise retarget it and report the wrong path as the one that was saved.
    function saved(path) {
        if (!mirror) {
            finishShot(path);
            return;
        }
        flipQueue = [...flipQueue, path];
        pumpFlip();
    }

    function pumpFlip() {
        if (flip.running || flipQueue.length === 0)
            return;
        flip.path = flipQueue[0];
        flip.running = true;
    }

    function finishShot(path) {
        lastShot = path;
        shotCount++;
    }

    function openLastShot() {
        if (!lastShot)
            return;
        opener.path = lastShot;
        opener.running = true;
    }

    function openFolder() {
        ensureDir();
        opener.path = saveDir;
        opener.running = true;
    }
}
