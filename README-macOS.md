# Meld for macOS

This fork packages Meld 3.24.0 as a macOS application with a native Cocoa
window frame. Meld's comparison toolbar remains intact, but it lives below the
native titlebar instead of replacing it with GTK client-side decoration. As a
result, the window has standard macOS traffic-light controls and works with
window managers such as Rectangle.

The application uses GTK's native Quartz backend and standard `Primary`
accelerators, so common shortcuts use Command (`⌘C`, `⌘S`, `⌘W`, and so
on). This is the real Meld application, not a Cocoa rewrite.

## Build

Install the prerequisites:

```sh
brew install python@3.13 gtksourceview4 pygobject3 py3cairo librsvg itstool
```

Then run:

```sh
./macos/build-app.sh
```

The result is `dist/Meld.app`, accompanied by a command-line launcher. Install
both with:

```sh
ditto dist/Meld.app /Applications/Meld.app
mkdir -p ~/.local/bin
install -m 755 dist/meld ~/.local/bin/meld
rehash
```

The launcher directly executes the custom app and waits for it to close, which
makes it suitable for `git difftool`. The bundle intentionally reuses
Homebrew's Python, GTK, GtkSourceView, PyGObject, and related libraries, so keep
those formulae installed.
