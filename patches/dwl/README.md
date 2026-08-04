# dwl patches

Patches for dwl (`~/projects/dwl`), kept here so the whole stack can be rebuilt
from a clean checkout. They are numbered in apply order and were verified to
apply cleanly on top of dwl `0.7` (`74e45c4`).

`config.h` is *not* a patch -- dwl gitignores it, so it lives in the dotfiles
tree at `home/zaq/projects/dwl/config.h` and `setup.sh` symlinks it into place.

## The stack

| # | Patch | Origin |
|---|-------|--------|
| 0001 | `ipc.patch` | upstream [dwl-ipc-unstable-v2](https://codeberg.org/dwl/dwl-patches/wiki/ipc) -- lets status bars talk to dwl |
| 0002 | `pertag.patch` | upstream [pertag](https://codeberg.org/dwl/dwl-patches/wiki/pertag) -- per-tag layout, mfact, nmaster |
| 0003 | `publish-focused-client-pid.patch` | local -- see below |
| 0004 | `mark-floating-client-in-layout-symbol.patch` | local -- see below |

Not tracked: the local `config.mk` uncomments `XWAYLAND`/`XLIBS` to build X11
support. Nothing currently uses it (no Xwayland clients), so it's left out of the
stack -- re-enable by hand in `config.mk` if X11 clients ever come back.

### 0003-publish-focused-client-pid.patch

Writes the focused client's pid to `$XDG_RUNTIME_DIR/dwl/focused.pid` on every
focus change. Wayland has no cross-client equivalent of X11's
`_NET_ACTIVE_WINDOW` + `_NET_WM_PID`, so this is what lets `focused_dir` (and the
`footcwd` launcher) resolve the active window's working directory.

### 0004-mark-floating-client-in-layout-symbol.patch

Appends `~` to the layout symbol sent over ipc when the focused client is
floating, so waybar shows `[]=~` instead of `[]=`. dwl already publishes the
floating state as its own ipc event, but waybar 0.12's `dwl/window` module
ignores it -- `{layout}` (fed by the layout_symbol event) is the only hook we
have. Only the ipc copy is decorated; `monitor->ltsymbol` is untouched.

## Applying

`setup.sh` does this automatically: on a **clean** dwl checkout it applies the
stack in order, and on a dirty one it assumes the patches are already there and
leaves the tree alone. Either way it never builds -- that stays manual:

    cd ~/projects/dwl
    make && sudo make install
    # restart the dwl session for the new binary to take effect

By hand, from a clean checkout at `0.7`:

    cd ~/projects/dwl
    for p in ~/projects/dotfiles/patches/dwl/0*.patch; do git apply "$p"; done

Note the patches are interdependent and must go on in numeric order -- each
one's context assumes the previous landed. For the same reason, don't use
`git apply --reverse --check` to test whether an individual patch is applied:
0002 and 0003 rewrite the `dwl.c` lines 0001 needs to reverse, so a
fully-applied 0001 reports as *not* applied. Check the tree as a whole instead:

    git -C ~/projects/dwl diff --stat

The two local patches (0003, 0004) are the exception -- nothing stacks on them
and they touch disjoint parts of `dwl.c`, so either can be dropped and re-added
on its own:

    git apply --reverse ~/projects/dotfiles/patches/dwl/0004-mark-floating-client-in-layout-symbol.patch
    git apply ~/projects/dotfiles/patches/dwl/0004-mark-floating-client-in-layout-symbol.patch

## Fresh-machine ordering

`setup.sh` creates `~/projects/dwl/` and drops the `config.h` symlink there, so
a later `git clone` into that path fails on the non-empty directory. Clone dwl
first, or populate the directory in place:

    git -C ~/projects/dwl init
    git -C ~/projects/dwl remote add origin https://codeberg.org/dwl/dwl.git
    git -C ~/projects/dwl fetch --depth 1 origin v0.7
    git -C ~/projects/dwl checkout FETCH_HEAD
