from meld.macoswindow import enable_native_titlebar, maximize_window


class Recorder:

    def __init__(self):
        self.calls = []

    def __getattr__(self, name):
        return lambda *args: self.calls.append((name, args))


def test_native_titlebar_is_unchanged_off_macos():
    window, header_bar, content_box = Recorder(), Recorder(), Recorder()

    changed = enable_native_titlebar(
        window, header_bar, content_box, platform='linux')

    assert not changed
    assert not window.calls
    assert not header_bar.calls
    assert not content_box.calls


def test_native_titlebar_moves_header_bar_into_content_on_macos():
    window, header_bar, content_box = Recorder(), Recorder(), Recorder()

    changed = enable_native_titlebar(
        window, header_bar, content_box, platform='darwin')

    assert changed
    assert header_bar.calls == [
        ('set_show_close_button', (False,)),
        ('set_title', (None,)),
        ('reparent', (content_box,)),
    ]
    assert content_box.calls == [('reorder_child', (header_bar, 0))]
    assert window.calls == [('set_titlebar', (None,))]


def test_macos_window_starts_maximized():
    window = Recorder()

    changed = maximize_window(window, platform='darwin')

    assert changed
    assert window.calls == [('maximize', ())]


def test_non_macos_window_keeps_saved_size():
    window = Recorder()

    changed = maximize_window(window, platform='linux')

    assert not changed
    assert not window.calls
