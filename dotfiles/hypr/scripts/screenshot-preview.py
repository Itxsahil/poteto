#!/usr/bin/env python3

import sys
from pathlib import Path

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Gdk", "4.0")

from gi.repository import Gtk, Gdk, Gio, GLib


class ScreenshotPreview(Gtk.Application):
    def __init__(self, image_path):
        super().__init__(
            application_id="dev.sahil.ScreenshotPreview"
        )

        self.image_path = Path(image_path).resolve()
        self.window = None

    def do_activate(self):
        # -----------------------------
        # Create preview window
        # -----------------------------

        self.window = Gtk.ApplicationWindow(application=self)

        self.window.set_title("Screenshot Preview")
        self.window.set_default_size(320, 200)

        # No normal title bar.
        self.window.set_decorated(False)

        # -----------------------------
        # Display screenshot
        # -----------------------------

        picture = Gtk.Picture.new_for_filename(
            str(self.image_path)
        )

        picture.set_content_fit(
            Gtk.ContentFit.COVER
        )

        picture.set_can_shrink(True)

        self.window.set_child(picture)

        # -----------------------------
        # Drag and drop
        # -----------------------------

        drag = Gtk.DragSource()

        # Left mouse button.
        drag.set_button(1)

        # We're giving/copying the file to
        # another application.
        drag.set_actions(Gdk.DragAction.COPY)

        drag.connect(
            "prepare",
            self.prepare_drag
        )

        picture.add_controller(drag)

        # -----------------------------
        # Automatically disappear
        # after 8 seconds.
        # -----------------------------

        GLib.timeout_add_seconds(
            8,
            self.close_preview
        )

        self.window.present()

    def prepare_drag(self, source, x, y):
        file = Gio.File.new_for_path(
            str(self.image_path)
        )

        file_list = Gdk.FileList.new_from_list(
            [file]
        )

        return Gdk.ContentProvider.new_for_value(
            file_list
        )

    def close_preview(self):
        if self.window:
            self.window.close()

        return False


if len(sys.argv) != 2:
    print(
        "Usage: screenshot-preview.py IMAGE"
    )
    sys.exit(1)


image_path = Path(sys.argv[1])

if not image_path.exists():
    print(f"Image doesn't exist: {image_path}")
    sys.exit(1)


app = ScreenshotPreview(image_path)

app.run([])