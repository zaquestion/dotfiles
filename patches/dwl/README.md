# dwl patches

Patches for dwl (`~/projects/dwl`), kept here so the whole stack can be rebuilt
from a clean checkout. They are numbered in apply order and were verified to
apply cleanly on top of dwl `0.7` (`74e45c4`).

`config.h` is *not* a patch -- dwl gitignores it, so it lives in the dotfiles
tree and `setup.sh` puts it into place. It is the one tracked file that is
*rendered* rather than symlinked: the source is
`home/zaq/projects/dwl/config.h.in`, and `setup.sh` stamps `@SCALE@` from the
eDP-1 panel's preferred mode before writing `~/projects/dwl/config.h`. dwl
matches a `MonitorRule` on the output name, so `eDP-1` alone cannot say whether
the scale should be 1 or 2, and that is the only thing in the file that can't be
written portably -- the `~/scripts` paths use `$HOME` through `SHCMD`.

The practical consequence: **edit `config.h.in`, not `~/projects/dwl/config.h`.**
`setup.sh` refuses to render over a rendered file that is newer than the
template, so a hand edit isn't silently destroyed -- but it also won't make it
back into the repo on its own.

## The stack

| # | Patch | Origin |
|---|-------|--------|
| 0001 | `ipc.patch` | upstream [dwl-ipc-unstable-v2](https://codeberg.org/dwl/dwl-patches/wiki/ipc) -- lets status bars talk to dwl |
| 0002 | `pertag.patch` | upstream [pertag](https://codeberg.org/dwl/dwl-patches/wiki/pertag) -- per-tag layout, mfact, nmaster |
| 0003 | `publish-focused-client-pid.patch` | local -- see below |
| 0004 | `mark-floating-client-in-layout-symbol.patch` | local -- see below |
| 0005 | `place-new-floating-clients-over-the-focused-client.patch` | local -- see below |
| 0006 | `autostart-session-services.patch` | local -- see below |
| 0007 | `recolour-focused-border-while-dictating.patch` | local -- see below |

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

### 0005-place-new-floating-clients-over-the-focused-client.patch

Places a newly mapped floating client over whichever client was focused at the
time, copying its size as well as its position. dwl otherwise honours the
geometry the client reports for itself, and a fresh xdg toplevel reports
`x=y=0`, so every float opens in the monitor's top-left corner. Written for
`~/scripts/footpager` (the scrollback pager on `ctrl+shift+[` in `foot.ini`),
which should appear over the terminal whose buffer it is showing, but it
applies to any float. With nothing else on screen the corner placement stands.

### 0006-autostart-session-services.patch

Points `dwl.desktop` at `~/scripts/dwlstart` via dwl's `-s` flag, so the bar and
the dictation daemon come up with the session. dwl runs the `-s` command through
`/bin/sh` once the wayland socket exists and the backend is started, so
`WAYLAND_DISPLAY` is already set for everything the script launches.

This is a patch and not a tracked dotfile because `dwl.desktop` is part of the
dwl source tree -- dwl does *not* gitignore it the way it does `config.h`, so
the symlink trick `config.h` uses does not work here. Two things follow from
that, and both were live bugs before this patch:

- `make install` copies `dwl.desktop` out of the source tree over
  `/usr/local/share/wayland-sessions/dwl.desktop`. An autostart edited directly
  into the installed copy therefore survives exactly until the next dwl
  rebuild, which is how the session ended up starting no bar at all while a
  hand-started waybar kept the current session looking fine.
- A symlink there would leave `git -C ~/projects/dwl status` permanently dirty,
  and `setup.sh` gates the whole patch stack on `git diff --quiet` -- so it
  would silently stop applying patches on a fresh checkout.

The `-s` command is a path to a script rather than an inline command list on
purpose: changing what autostarts is then just an edit to a tracked file in
`~/scripts`, with no patch edit, no rebuild and no `sudo make install`.

The path is written `@HOME@/scripts/dwlstart` and stamped by `setup.sh` as it
applies the patch. This is the one place `$HOME` can't be used directly: `Exec=`
in a desktop entry is tokenized by the display manager, which expands nothing,
and unlike `config.h` (`SHCMD`) or `foot.ini` (`sh -c`) there is no shell in
front of it. dwl *does* run the resulting string through `/bin/sh -c`, but only
after the DM has already handed it over as a literal argument.

Note `dwl-log.desktop` (the variant that redirects to `/tmp/dwl.log`) is
installed in `/usr/local/share/wayland-sessions` but has no counterpart in the
dwl source tree, so it is not covered by this patch and starts nothing. Log in
with the plain `dwl` session, or add `-s` to that file by hand.

### 0007-recolour-focused-border-while-dictating.patch

Paints the focused client's border with `dictatecolor` while the mic is open, so
the dictation indicator is around the window the text is about to land in rather
than only in the bar. SIGUSR1 turns it on, SIGUSR2 turns it off;
`~/scripts/dictate-indicator` follows voxtype's state stream and sends them, and
also recolours the caret in every open foot window over OSC 12.

Two signals rather than one toggle because the sender is not the only thing that
ends a recording (`~/scripts/dictate` has a silence watchdog, voxtype has
`audio.max_duration_secs`), so a toggle would invert on any transition the
sender didn't see and stay wrong from then on.

The signals are registered with `wl_event_loop_add_signal`, not appended to the
`sigaction` list at the top of `setup()`. That list feeds `handlesig`, a real
async signal handler that restricts itself to `waitpid`/`quit` accordingly;
recolouring a border mutates the scene graph, which is not async-signal-safe.
`wl_event_loop_add_signal` blocks the signal and delivers it over a signalfd the
event loop polls, so the callback is an ordinary dispatch.

**Rebuild before this one reaches a login.** The default disposition of SIGUSR1
is *terminate*, so an unpatched dwl is killed by the signal rather than coloured
by it -- and `dwlstart` runs the indicator at session start, which would turn
every login into an instant logout. `dictate-indicator` guards against exactly
this: it reads `SigBlk` from `/proc/<dwl>/status` and only signals a dwl that has
SIGUSR1 and SIGUSR2 blocked, which is the signalfd registration above and so is
direct evidence the patch is live. Nothing breaks if the rebuild lags; the border
simply stays blue until it happens.

`dictatecolor` is `#eb4d4b`, matching `#custom-voxtype.recording` in
`~/.config/waybar/style.css` and the caret colour in `dictate-indicator`. It is
added to `config.def.h` by this patch, but the build uses the tracked
`config.h` -- both carry it.

## Applying

`setup.sh` does this automatically: on a **clean** dwl checkout it applies the
stack in order, and on a dirty one it assumes the patches are already there and
leaves the tree alone. It then builds and installs the result -- `make clean &&
make` as you, `sudo make install` for the parts outside `$HOME` -- so a patch
edit reaches the screen with nothing more than a rerun and a fresh login. A
half-applied stack is not built.

After editing a patch by hand, the same two steps:

    cd ~/projects/dwl
    make && sudo make install
    # log out and back in for the new binary to take effect

By hand, from a clean checkout at `0.7` -- note the `sed`, which is what stamps
0006's `@HOME@` and is a no-op for the other six:

    cd ~/projects/dwl
    for p in ~/projects/dotfiles/patches/dwl/0*.patch; do
        sed "s|@HOME@|$HOME|g" "$p" | git apply -
    done

Note the patches are interdependent and must go on in numeric order -- each
one's context assumes the previous landed. For the same reason, don't use
`git apply --reverse --check` to test whether an individual patch is applied:
0002 and 0003 rewrite the `dwl.c` lines 0001 needs to reverse, so a
fully-applied 0001 reports as *not* applied. Check the tree as a whole instead:

    git -C ~/projects/dwl diff --stat

The local patches (0003, 0004, 0005, 0006) are the exception -- nothing stacks
on them and they touch disjoint parts of the tree, so any can be dropped and
re-added on its own:

    git apply --reverse ~/projects/dotfiles/patches/dwl/0004-mark-floating-client-in-layout-symbol.patch
    git apply ~/projects/dotfiles/patches/dwl/0004-mark-floating-client-in-layout-symbol.patch

## The checkout

`setup.sh` makes it — the same one-liner as below — just *before* it renders
`config.h` and applies the stack. That order is load-bearing: setup's folder
replication has already created `~/projects/dwl`, and `git clone` is happy with
an existing empty directory but refuses one that has `config.h` in it.

`v0.7` and not the branch: dwl links one wlroots version, and 0.7 is the release
built against wlroots 0.18 — which is what trixie packages, and what setup's apt
block installs as `libwlroots-0.18-dev`. A newer dwl wants 0.19 and won't build
against it.

An existing checkout is left alone, patched or not, so re-running setup never
resets the tree. By hand:

    git clone --depth 1 --branch v0.7 https://codeberg.org/dwl/dwl.git ~/projects/dwl
