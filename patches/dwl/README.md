# dwl patches

Local patches for dwl (`~/projects/dwl`), kept here so they can be applied or
dropped at will. They stack on top of the ipc + pertag patches already in that
tree.

## 0001-publish-focused-client-pid.patch

Writes the focused client's pid to `$XDG_RUNTIME_DIR/dwl/focused.pid` on every
focus change. Wayland has no cross-client equivalent of X11's
`_NET_ACTIVE_WINDOW` + `_NET_WM_PID`, so this is what lets `focused_dir` (and the
`footcwd` launcher) resolve the active window's working directory.

Apply:

    cd ~/projects/dwl
    git apply ~/projects/dotfiles/patches/dwl/0001-publish-focused-client-pid.patch
    make && sudo make install
    # restart the dwl session for the new binary to take effect

Remove:

    cd ~/projects/dwl
    git apply --reverse ~/projects/dotfiles/patches/dwl/0001-publish-focused-client-pid.patch
    make && sudo make install

Check whether it's currently applied (exit 0 = can be reversed = applied):

    git apply --reverse --check ~/projects/dotfiles/patches/dwl/0001-publish-focused-client-pid.patch
