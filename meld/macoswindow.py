# Copyright (C) 2026 Patrick Farrell <patrick.farrell@maths.ox.ac.uk>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.

import sys


def enable_native_titlebar(window, header_bar, content_box, platform=None):
    """Use Quartz's native window frame while retaining Meld's toolbar.

    A GtkHeaderBar installed as a GtkWindow titlebar enables GTK client-side
    decorations. On macOS that hides the standard Cocoa titlebar from window
    managers such as Rectangle. Reparent the header bar into the content and
    leave the GtkApplicationWindow itself to the Quartz backend.
    """
    if platform is None:
        platform = sys.platform
    if platform != 'darwin':
        return False

    header_bar.set_show_close_button(False)
    header_bar.set_title(None)
    header_bar.reparent(content_box)
    content_box.reorder_child(header_bar, 0)
    window.set_titlebar(None)
    return True


def maximize_window(window, platform=None):
    """Start Meld maximized on macOS, without entering full-screen mode."""
    if platform is None:
        platform = sys.platform
    if platform != 'darwin':
        return False

    window.maximize()
    return True
