# Copyright (C) 2026 Patrick Farrell <patrick.farrell@maths.ox.ac.uk>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.

import ctypes
import os
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


def fill_screen(window, platform=None, native_filler=None):
    """Fill the display on macOS without entering a full-screen Space."""
    if platform is None:
        platform = sys.platform
    if platform != 'darwin':
        return False

    gdk_window = window.get_window()
    if gdk_window is None:
        return False

    if native_filler is None:
        resources = os.path.join(
            os.path.dirname(sys.executable), '..', 'Resources', 'lib')
        library = ctypes.CDLL(os.path.join(
            resources, 'meld-native-window.dylib'))
        native_filler = library.meld_macos_fill_screen
        native_filler.argtypes = (ctypes.c_void_p,)
        native_filler.restype = ctypes.c_int

    return bool(native_filler(ctypes.c_void_p(hash(gdk_window))))
