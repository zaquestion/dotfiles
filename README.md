# dotfiles

Configs for a Debian machine running a wayland desktop assembled out of small
pieces rather than installed as a desktop environment: [dwl] as the compositor,
[waybar] as the status bar, [swaylock] as the screen locker, [foot] as the
terminal and [fish] as the shell.

There is no settings daemon and nothing but gdm's session list in front of it.
Everything the desktop does — what starts at login, what the keybindings are,
what the bar shows — is a tracked file in here.

[dwl]: https://codeberg.org/dwl/dwl
[waybar]: https://github.com/Alexays/Waybar
[swaylock]: https://github.com/swaywm/swaylock
[foot]: https://codeberg.org/dnkl/foot
[fish]: https://fishshell.com

## The pieces

| | | |
|---|---|---|
| compositor | dwl 0.7 | built from `~/projects/dwl`, patched from `patches/dwl`, configured by the tracked `config.h` |
| bar | waybar | `~/.config/waybar`, started by `~/scripts/dwlstart` |
| locker | swaylock | `~/.config/swaylock/config`, on mod-shift-l |
| terminal | foot | `~/.config/foot/foot.ini`, opened in the focused window's cwd by `~/scripts/footcwd` |
| launcher | wmenu-run | on mod-p |
| screenshots | grim + slurp | `~/scripts/snip`, on mod-shift-s |
| dictation | voxtype | `~/scripts/dictate`, on mod-slash |
| shell | fish | `~/.config/fish/config.fish`, ssh-agent shared via keychain |
| editors | neovim | provisioned through mise; a helix config is tracked too, but nothing installs helix |
| toolchains | mise | `~/.config/mise/config.toml` |

Wayland has no cross-client equivalent of X11's `_NET_ACTIVE_WINDOW` +
`_NET_WM_PID`, which is why several of these lean on a dwl patch rather than on
a generic tool: `focused_dir` reads the focused client's pid out of
`$XDG_RUNTIME_DIR/dwl/focused.pid` (patch 0003), and `footcwd` is built on top
of it. See `patches/dwl/README.md` for the whole stack.

## Layout

    home/zaq/     mirrored into $HOME — setup.sh recreates the directories and
                  symlinks every file, so editing ~/.config/foot/foot.ini is
                  editing this repo
    patches/dwl/  the dwl patch stack, applied in filename order
    setup.sh      idempotent, guarded by ~/.dotfiles_initialized

Directories are recreated rather than symlinked: they don't all hold only
tracked files, and symlinking one would mean tracking everything that lands in
it. Files are only linked where nothing real is already in the way, so a
hand-edited `~/.bashrc` is never clobbered without a prompt.

### Absolute paths

A few files have to name a path that no shell will expand for them. The rule is
`$HOME` wherever something will expand it, and stamping at install time only
where nothing will:

| where | how |
|---|---|
| `config.h` keybindings | `$HOME`, via the `SHCMD` macro — dwl's `spawn()` is a bare `execvp()`, so the `/bin/sh` that macro adds is what expands it |
| `foot.ini` pipe-scrollback | `$HOME`, via `sh -c` — foot runs the command directly otherwise |
| `config.h` eDP-1 scale | **stamped**: `config.h.in` carries `@SCALE@`, and setup renders it from the panel's preferred mode |
| patch 0006 `dwl.desktop` | **stamped**: `@HOME@`, sed'd in as the patch is applied — `Exec=` is tokenized by the display manager, which expands nothing |

`config.h` is therefore the one tracked file that is generated rather than
symlinked. **Edit `home/zaq/projects/dwl/config.h.in`**, not the rendered
`~/projects/dwl/config.h`; setup won't render over a rendered file that is newer
than its template, but nor will it carry a hand edit back into the repo.

## Installing

`setup.sh` installs the desktop and its build deps, the awkward things with no
Debian package (Symbols Nerd Font, keychain 3, scrcpy, voxtype) and the language
toolchains. Two prerequisites it deliberately leaves alone:

- **A display manager.** `make install` drops dwl's session into
  `/usr/local/share/wayland-sessions`, which any wayland-capable DM picks up.
  Installing `gdm3` on a machine that already has one opens a debconf prompt to
  choose the default, which is a poor thing to hit mid-install. `sudo apt
  install gdm3` if there isn't one.
- **mise**, which isn't in Debian — install it from
  [mise.jdx.dev](https://mise.jdx.dev) first. Every step of the language
  provisioning is `command -v mise`-guarded, so without it setup completes
  looking clean and installs almost none of the toolchain.

Then clone dwl **before** running setup, because setup creates
`~/projects/dwl/` for the `config.h` symlink and `git clone` refuses a
non-empty directory:

    git clone --branch v0.7 https://codeberg.org/dwl/dwl.git ~/projects/dwl

Run setup from the repo root — the symlink pass is `pwd`-relative:

    ./setup.sh

It is not an unattended install: `chsh` wants the account password, overwriting
an existing `~/.bashrc` or `config.fish` asks first, and both the apt block and
scrcpy's install step go through `sudo`. Then build the compositor, which setup
never does:

    cd ~/projects/dwl && make && sudo make install

Log out and pick the `dwl` session. Dictation needs its model fetched once
more, ~700MB — setup prints the command with the right model name filled in,
read out of `[parakeet] model` in `~/.config/voxtype/config.toml`, which is the
only place that name should ever be written down:

    voxtype setup --download --model "$(sed -n 's/^model.*"\(.*\)".*/\1/p' \
        ~/.config/voxtype/config.toml)"

## What setup.sh does

Prunes the XDG skeleton dirs it doesn't want and creates the ones it does;
mirrors `home/zaq` into `$HOME` as symlinks; installs the desktop, its build
deps and the fonts from apt; fetches Symbols Nerd Font (waybar's Material Design
icons live in a private-use range no Debian package covers); installs keychain 3
from its GitHub release, checksum-verified, tracking latest rather than a pin;
configures the default audio sink (see below); makes fish the login shell; runs
`mise install` and adds the tooling that lives outside it (rust-analyzer, yapf,
pynvim, codelldb); builds scrcpy and voxtype from source; renders `config.h`;
and applies the dwl patch stack to a clean checkout.

All of it is idempotent and re-running costs nothing — but the guard file means
a second run needs `rm ~/.dotfiles_initialized` first.

Nothing here is x86- or arm-specific. The one place the architecture is even
consulted is the codelldb download, which handles `x86_64` and `aarch64`
alike; scrcpy and voxtype are built from source precisely because their upstream
binaries aren't portable across the two, and everything else fetched (the font
tarball, keychain's zipapp, the mise tools) is either arch-neutral or resolved
per-arch by mise.

## Machine-specific bits

Two things here know what machine they're on. Both are Asahi/Apple-silicon
audio, and both skip themselves elsewhere rather than misfiring:

- **The default audio sink.** On this hardware the headphone-jack sink carries
  `priority.session = 1000` and the speakers — a filter-chain convolver node,
  because the Asahi audio stack does its DSP in pipewire — carry 850. WirePlumber
  picks by priority unless a default has been *configured*, so with nothing
  plugged in the jack still wins, and the volume keys (which drive
  `@DEFAULT_AUDIO_SINK@`) end up adjusting a sink no audio goes through. Setup
  writes the configured default once, which is exactly what picking the speakers
  in pavucontrol used to do by hand. It never overrides an existing choice, and
  it does nothing at all where that node is absent — on ordinary hardware the
  speakers outrank the jack correctly and there is nothing to fix.
- **The dictation mic.** `~/scripts/dictate` hardcodes
  `mic=effect_output.j316-mic`, the capture side of that same filter chain, and
  `silence_dbfs=-35` was measured against it in a quiet room. Where the node
  doesn't exist ffmpeg fails at once, and since the watchdog's output goes to
  `/dev/null` it fails *silently*: mod-slash and voxtype's 120s
  `max_duration_secs` still end a recording, but the 10s silence auto-stop is
  gone. `-f pulse -i default` is the portable spelling. voxtype's own
  `config.toml` already names the pipewire default source and needs no change.
