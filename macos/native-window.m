/* Native Cocoa operations used by Meld's Quartz backend. */

#include <AppKit/AppKit.h>
#include <gdk/quartz/gdkquartz-cocoa-access.h>

int
meld_macos_fill_screen (GdkWindow *window)
{
    NSWindow *native_window;
    NSScreen *screen;

    if (window == NULL)
        return 0;

    native_window = gdk_quartz_window_get_nswindow (window);
    if (native_window == nil)
        return 0;

    screen = native_window.screen;
    if (screen == nil)
        screen = [NSScreen mainScreen];
    if (screen == nil)
        return 0;

    /* Use the complete display frame rather than visibleFrame. This is not
     * NSWindow's full-screen mode: it remains in the current macOS Space. */
    [native_window setFrame:screen.frame display:YES animate:NO];
    return 1;
}
