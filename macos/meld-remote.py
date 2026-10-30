#!/usr/bin/env python3

"""Forward a command line to an already-running Meld application."""

import sys

from gi.repository import Gio


app = Gio.Application(
    application_id='org.gnome.Meld',
    flags=Gio.ApplicationFlags.HANDLES_COMMAND_LINE,
)
raise SystemExit(app.run(sys.argv))
