#/usr/bin/env bash

# Note: You'll notice a lot of `set +/-x` in this file. This controls where
# bash echos the executed commands.
# set -x; # enables
# set +x; # disables
# When enabled all executed commands are echo'd included those in executed scripts
# Example `set -x && source ~/.bashrc` would echo every command ~/.bashrc
# Logging everything would be fairly verbose therefore some commands are
# disabled line by line with `set +x; command; set -x`

test -r ~/.dotfiles_initialized && echo "dotfiles already setup; ~/.dotfiles_initialized exists!" && exit 0

set -x
# Prune unwanted XDG skeleton dirs, but only if empty (rmdir won't touch dirs
# with contents); silence the "not empty"/"not found" noise. List nested dirs
# before their parent so leaves are removed first (e.g. Pictures/* then
# Pictures), since rmdir won't remove a dir that still has subdirs.
for d in Desktop Templates Public Music \
         Pictures/Screenshots Pictures/Camera Pictures; do
	rmdir ~/"$d" 2>/dev/null
done
# Setup home directories
test ! -d ~/downloads && test -d ~/Downloads && mv ~/Downloads ~/downloads
mkdir -p ~/downloads

xdg-user-dirs-update --set DOWNLOAD ~/downloads
mkdir -p ~/scripts
mkdir -p ~/projects/c
mkdir -p ~/projects/go
mkdir -p ~/projects/go/src
mkdir -p ~/projects/go/pkg
mkdir -p ~/projects/go/bin
mkdir -p ~/projects/go-mod/src
mkdir -p ~/projects/python
mkdir -p ~/snips

echo "===== Replicating Folder Structure ====="
# Find all directories and make in $HOME. Directories cannot be symlinked from
# dotfiles as they won't always have all of the needed configs and I don't want
# to track everything in them nor maintain a .gitignore
(cd home/zaq && find . -type d -exec test ! -d ~/'{}' \; -and -exec mkdir ~/'{}' \;)

test -f ~/.bashrc && \
read -p "Existing ~/.bashrc found. Overwrite (Y/n)? " answer && \
case ${answer:0:1} in
    y|Y )
	    rm ~/.bashrc
    ;;
    * )
    ;;
esac

# fish writes a placeholder ~/.config/fish/config.fish the first time it runs,
# and the symlink pass below leaves real files alone -- so ours would never
# land on a machine where fish has already been started once.
test -f ~/.config/fish/config.fish && test ! -L ~/.config/fish/config.fish && \
read -p "Existing ~/.config/fish/config.fish found. Overwrite (Y/n)? " answer && \
case ${answer:0:1} in
    y|Y )
	    rm ~/.config/fish/config.fish
    ;;
    * )
    ;;
esac

echo "===== Symlinking Files ====="
# Find all files and create symlinks from $HOME. .gitkeep files only exist to
# keep otherwise empty dirs in the repo, they don't belong in $HOME.
# Link when the target is missing/broken (! -e) or is already a symlink (-L),
# using -f to refresh stale links; real files are left untouched so we never
# clobber something like a hand-edited ~/.bashrc.
#
# *.in files are templates, not configs -- symlinking one would put a literal
# @SCALE@ in front of a compiler. They're rendered further down instead, and are
# the only files here that don't appear in $HOME under their own name.
(cd home/zaq && find . -type f ! -name .gitkeep ! -name '*.in' -exec test ! -e ~/'{}' -o -L ~/'{}' \; -and -exec ln -sfn `pwd`/'{}' ~/'{}' \;)

echo "===== Installing packages ====="
# Debian/apt only; skipped elsewhere. apt install is idempotent -- already
# installed packages are a no-op -- so re-running setup costs nothing.
#
# The desktop itself: dwl is built from source below, but everything it starts
# or spawns is packaged. waybar is the bar (dwlstart runs /usr/bin/waybar by
# absolute path), foot the terminal, wmenu the launcher on mod-p, swaylock the
# locker on mod-shift-l (colors from ~/.config/swaylock/config), brightnessctl
# the backlight keys, and pavucontrol what the bar's pulseaudio module opens on
# click. grim/slurp back ~/scripts/snip on mod-shift-s.
#
# pipewire/pipewire-pulse/wireplumber are what the volume keys talk to through
# wpctl, which wireplumber ships. xdg-user-dirs provides the
# xdg-user-dirs-update called at the top of this script.
#
# dwl's own build deps come next. It links wlroots 0.18 specifically -- see
# PKGS in its Makefile -- so the 0.19 packages, when Debian has them, are the
# wrong ones -- and why the checkout further down pins dwl to the 0.7 tag.
# Not listed here: gcc/git/pkg-config, already below for scrcpy. git matters
# beyond that one build -- it is what checks out dwl, scrcpy and voxtype -- and
# this block running first is what puts it there in time.
#
# Fonts: waybar's config.jsonc draws its icons from Font Awesome and Weather
# Icons (plus the Nerd Font below), and Roboto is the text face its stylesheet
# asks for first.
#
# curl and unzip are used further down (the font, keychain and codelldb
# fetches) and each of those blocks skips itself when the binary is missing --
# quietly, which is how a run can look clean and install nothing. jq reads the
# GitHub release JSON in the keychain install.
#
# wtype is how voxtype gets dictated text into the focused client -- it drives
# the virtual-keyboard protocol, which dwl supports natively, so unlike ydotool
# it needs no uinput access and no root. cmake, libasound2-dev and libclang-dev
# are voxtype's own build deps (bindgen wants libclang); the build is below.
# The remainder are scrcpy's build and runtime deps, per upstream doc/linux.md;
# the build itself is further down.
#
# Deliberately not here: a display manager. dwl's `make install` drops its
# session into /usr/local/share/wayland-sessions, which any wayland-capable DM
# picks up, and installing gdm3 on a machine that already has one opens a
# debconf prompt to pick the default -- an interactive question in the middle of
# an otherwise mechanical install. Also not here: mise, which isn't in Debian.
# Both are in the README's prerequisites.
set +x # apt is noisy enough on its own
if command -v apt >/dev/null; then
	sudo apt install -y \
		fish \
		waybar \
		foot \
		wmenu \
		swaylock \
		brightnessctl \
		pavucontrol \
		pipewire \
		pipewire-bin \
		pipewire-pulse \
		wireplumber \
		xdg-user-dirs \
		make \
		libwlroots-0.18-dev \
		libwayland-dev \
		wayland-protocols \
		libxkbcommon-dev \
		libinput-dev \
		fonts-font-awesome \
		fonts-weather-icons \
		fonts-roboto \
		grim \
		slurp \
		wl-clipboard \
		wtype \
		curl \
		unzip \
		cmake \
		libasound2-dev \
		libclang-dev \
		jq \
		ffmpeg \
		libsdl3-0 \
		libusb-1.0-0 \
		adb \
		wget \
		gcc \
		git \
		pkg-config \
		meson \
		ninja-build \
		libsdl3-dev \
		libavcodec-dev \
		libavdevice-dev \
		libavformat-dev \
		libavutil-dev \
		libswresample-dev \
		libusb-1.0-0-dev \
		libv4l-dev
else
	echo "  no apt; skipping package install"
fi

# The rest of waybar's icons come from Nerd Fonts' Material Design Icons remap
# (U+F0000+), which no Debian package covers -- fonts-materialdesignicons-webfont
# is the old BMP numbering and overlaps FontAwesome entirely. The symbols-only
# release is icons with no text glyphs, so it's inert until something in the font
# stack falls through to it. Idempotent: skipped once the ttf is in place.
nerd_fonts=~/.local/share/fonts
if [ ! -f "$nerd_fonts/SymbolsNerdFont-Regular.ttf" ] && command -v curl >/dev/null; then
	nf_tar=$(mktemp)
	if curl -sfL -o "$nf_tar" \
		"https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/NerdFontsSymbolsOnly.tar.xz"; then
		mkdir -p "$nerd_fonts"
		tar -xJf "$nf_tar" -C "$nerd_fonts" --wildcards 'SymbolsNerdFont*.ttf'
		fc-cache -f "$nerd_fonts"
	else
		echo "  failed to fetch Symbols Nerd Font; some waybar icons will be tofu"
	fi
	rm -f "$nf_tar"
fi
set -x

echo "===== Installing keychain ====="
# Sourced by ~/.config/fish/config.fish to share one ssh-agent across logins.
# Not the Debian package: apt only carries 2.8.5, and 3.x is a python rewrite
# with the verb-based CLI ("keychain add", "keychain env") that the fish config
# calls. Upstream ships it as a zipapp -- one self-contained .pyz that runs on
# any python3 -- so installing is a download, a checksum and a chmod.
#
# Unlike the nerd font and codelldb above this tracks the latest release rather
# than a pinned version, so the tag and the expected hash are both resolved at
# run time from the GitHub API. Note what that checksum can and cannot do: the
# .pyz and the SHA256SUMS naming it come from the same release, so this catches
# a truncated or corrupted download, not a compromised upstream. Re-running
# setup is how this gets updated.
#
# Idempotent, and cheap when there's nothing to do: the API response and
# SHA256SUMS are both small, and the .pyz is only fetched when the installed
# binary doesn't already hash to what the latest release publishes.
set +x
keychain_bin=~/.local/bin/keychain
keychain_api=https://api.github.com/repos/danielrobbins/keychain/releases/latest
if ! command -v python3 >/dev/null; then
	# The zipapp's shebang is /usr/bin/env python3; without one it's inert.
	echo "  no python3; skipping keychain install"
elif ! command -v curl >/dev/null; then
	echo "  no curl; skipping keychain install"
elif ! command -v jq >/dev/null; then
	echo "  no jq; skipping keychain install"
elif ! kc_rel=$(curl -sfL "$keychain_api"); then
	echo "  couldn't reach the GitHub API; leaving keychain as-is"
else
	# Pull the tag and the two asset URLs straight out of the release JSON
	# rather than reconstructing them from a filename convention. Each of the
	# three is wrapped so it yields exactly one value -- first() picks the
	# single match, and // "" turns "no match at all" into an empty string
	# rather than no output. Without that a release missing an asset would
	# emit two lines instead of three and silently shift the sed reads below
	# by one.
	kc_meta=$(printf '%s' "$kc_rel" | jq -r '
		[ (.tag_name // ""),
		  (first(.assets[]? | select(.name | endswith(".pyz")) | .browser_download_url) // ""),
		  (first(.assets[]? | select(.name == "SHA256SUMS") | .browser_download_url) // "")
		] | .[]
	' 2>/dev/null)
	keychain_ver=$(echo "$kc_meta" | sed -n 1p)
	kc_pyz_url=$(echo "$kc_meta" | sed -n 2p)
	kc_sums_url=$(echo "$kc_meta" | sed -n 3p)

	if [ -z "$keychain_ver" ] || [ -z "$kc_pyz_url" ] || [ -z "$kc_sums_url" ]; then
		echo "  couldn't parse the latest keychain release; leaving keychain as-is"
	elif ! keychain_sha=$(curl -sfL "$kc_sums_url" \
		| grep -F "$(basename "$kc_pyz_url")" | cut -d' ' -f1) \
		|| [ -z "$keychain_sha" ]; then
		echo "  couldn't fetch the checksum for keychain $keychain_ver; leaving keychain as-is"
	elif [ "$(sha256sum "$keychain_bin" 2>/dev/null | cut -d' ' -f1)" = "$keychain_sha" ]; then
		echo "  keychain $keychain_ver already installed; skipping"
	else
		kc_tmp=$(mktemp)
		if ! curl -sfL -o "$kc_tmp" "$kc_pyz_url"; then
			echo "  failed to fetch keychain $keychain_ver"
		elif [ "$(sha256sum "$kc_tmp" | cut -d' ' -f1)" != "$keychain_sha" ]; then
			# Refuse to install what didn't arrive intact: this is the binary
			# that ends up holding the ssh keys.
			echo "  keychain $keychain_ver checksum MISMATCH; not installing"
		else
			mkdir -p ~/.local/bin
			install -m 755 "$kc_tmp" "$keychain_bin"
			echo "  installed: keychain $keychain_ver"
		fi
		rm -f "$kc_tmp"
	fi
fi
set -x

echo "===== Setting the default audio sink ====="
# The volume keys in dwl's config.h drive @DEFAULT_AUDIO_SINK@, so they are only
# ever as right as wireplumber's idea of the default -- and on this machine that
# idea is wrong out of the box:
#
#   alsa_output.platform-sound.HiFi__Headphones__sink   priority.session = 1000
#   audio_effect.j316-convolver  (the speakers)         priority.session =  850
#
# With no *configured* default, wireplumber picks by priority.session, so the
# headphone jack wins with nothing plugged into it and the keys adjust a sink no
# audio is going through. Picking the speakers once in pavucontrol is what fixed
# it before, and what that actually did was write
# default.configured.audio.sink into
# ~/.local/state/wireplumber/default-nodes -- untracked local state, so a fresh
# machine has never had it. This writes the same thing without the detour.
#
# The speakers are a filter-chain node, not an ALSA one: the Asahi audio setup
# runs `pipewire -c filter-chain.conf` as filter-chain.service and the convolver
# it publishes is doing the DSP the hardware expects the OS to do. That is also
# why it loses the priority contest -- filter-chain nodes get no say in it.
#
# The node name is hardcoded rather than guessed at, and the block skips itself
# where that node doesn't exist. On ordinary hardware there is nothing to fix:
# the speaker sink outranks the jack the way it should, and quietly configuring
# some heuristic's best guess as the permanent default would be a worse answer
# than leaving wireplumber alone.
set +x
wp_sink=audio_effect.j316-convolver
wp_state=${XDG_STATE_HOME:-$HOME/.local/state}/wireplumber/default-nodes
if ! command -v wpctl >/dev/null || ! command -v pw-dump >/dev/null; then
	echo "  no wpctl/pw-dump; skipping"
elif grep -q '^default\.configured\.audio\.sink=' "$wp_state" 2>/dev/null; then
	# Never override a choice already made -- including one made by hand in
	# pavucontrol since the last run. This is the idempotent path.
	echo "  a default sink is already configured; leaving it alone"
elif ! wp_id=$(pw-dump 2>/dev/null | jq -r --arg n "$wp_sink" \
	'first(.[] | select(.info.props."node.name" == $n
	                and .info.props."media.class" == "Audio/Sink") | .id) // ""') \
	|| [ -z "$wp_id" ]; then
	# Either pipewire isn't reachable from here (a tty with no user session bus)
	# or this isn't the machine that has that node. Both are fine to skip.
	echo "  $wp_sink not present; leaving the default sink to wireplumber"
else
	wpctl set-default "$wp_id" && echo "  default sink set to $wp_sink (id $wp_id)"
fi
set -x

echo "===== Setting fish as the login shell ====="
# The config above is only half the story -- without this, ~/.config/fish is
# just a config for a shell nothing ever starts. chsh prompts for the account
# password, so this can't be done unattended. Idempotent: skipped once the
# passwd entry already points at fish.
set +x
fish_path=$(command -v fish)
if [ -z "$fish_path" ]; then
	echo "  fish not installed; skipping"
elif [ "$(getent passwd "$USER" | cut -d: -f7)" = "$fish_path" ]; then
	echo "  login shell is already $fish_path; skipping"
elif ! grep -qxF "$fish_path" /etc/shells; then
	# chsh refuses anything not in /etc/shells for a non-root caller. The
	# Debian package registers it on install, so this only bites on a
	# hand-built fish.
	echo "  $fish_path missing from /etc/shells; add it, then: chsh -s $fish_path"
else
	chsh -s "$fish_path" || echo "  chsh failed; rerun by hand: chsh -s $fish_path"
fi
set -x

echo "===== Provisioning language tooling ====="
# Everything below is idempotent -- re-running is a no-op once installed.

# mise-managed tools, from the now-symlinked ~/.config/mise/config.toml
command -v mise >/dev/null && mise install

# The following are expected by the nvim setup but live outside mise:

# rust-analyzer is a rustup component, not a standalone binary
command -v rustup >/dev/null && rustup component add rust-analyzer

# python tooling for nvim -- yapf (formatter) + pynvim (python3 host) -- into
# the mise-managed python; pip is a no-op when already satisfied
command -v mise >/dev/null && mise exec -- python -m pip install --quiet yapf pynvim

# codelldb DAP adapter for rustaceanvim, extracted from the vscode-lldb vsix
set +x # this block is noisy; keep the log readable
codelldb_dir=~/.local/share/nvim/codelldb
if [ ! -x "$codelldb_dir/extension/adapter/codelldb" ] && command -v unzip >/dev/null; then
	case "$(uname -m)" in
		aarch64 | arm64) cl_asset=codelldb-linux-arm64.vsix ;;
		x86_64) cl_asset=codelldb-linux-x64.vsix ;;
		*) cl_asset= ;;
	esac
	if [ -n "$cl_asset" ]; then
		mkdir -p "$codelldb_dir"
		if curl -sfL -o "$codelldb_dir/codelldb.vsix" \
			"https://github.com/vadimcn/codelldb/releases/download/v1.12.2/$cl_asset"; then
			unzip -q -o "$codelldb_dir/codelldb.vsix" -d "$codelldb_dir"
			rm -f "$codelldb_dir/codelldb.vsix"
		fi
	fi
fi
set -x

echo "===== Installing scrcpy ====="
# Built from source rather than installed from apt: Debian only carries 3.3.4
# (trixie-backports), and upstream marks the distro packages obsolete. The
# official static build is x86_64-only, so it's no help on arm64 either.
# install_release.sh fetches the prebuilt server (a checksum-verified, arch-
# independent blob), builds the client with meson/ninja and installs it with
# sudo -- see doc/linux.md upstream. Deps came in with the apt block above.
# Idempotent: skipped once scrcpy is on PATH. To update after a new release:
#   cd ~/projects/scrcpy && git pull && ./install_release.sh
# and to uninstall: sudo ninja -Cbuild-auto uninstall
set +x # meson and ninja are noisy enough on their own
scrcpy_src=~/projects/scrcpy
if command -v scrcpy >/dev/null; then
	echo "  scrcpy already installed; skipping"
elif ! command -v meson >/dev/null; then
	echo "  no meson; skipping scrcpy build"
else
	test -d "$scrcpy_src/.git" || git clone https://github.com/Genymobile/scrcpy "$scrcpy_src"
	# The build shells out to sudo for the install step, so this may prompt.
	if (cd "$scrcpy_src" && ./install_release.sh); then
		echo "  installed: $(scrcpy --version 2>/dev/null | head -1)"
	else
		echo "  scrcpy build failed; see $scrcpy_src"
	fi
fi
set -x

echo "===== Installing voxtype ====="
# Push-to-talk dictation, bound to mod-slash in dwl's config.h. Built from source
# rather than installed from the .deb: upstream's aarch64 binaries are marked
# experimental, and the .deb wouldn't carry the parakeet engine anyway -- that
# is a compile-time cargo feature, and it's the whole reason for choosing
# voxtype over a whisper-only setup. See ~/.config/voxtype/config.toml for why
# parakeet and not whisper.
#
# The build is slow (ONNX Runtime and a lot of Rust) but idempotent: skipped
# once the binary is on PATH. To update after a new release:
#   cd ~/projects/voxtype && git pull && cargo build --release --features parakeet
#   install -m 755 target/release/voxtype ~/.local/bin/voxtype
set +x # cargo is noisy enough on its own
voxtype_src=~/projects/voxtype
if command -v voxtype >/dev/null; then
	echo "  voxtype already installed; skipping"
elif ! command -v cargo >/dev/null; then
	echo "  no cargo; skipping voxtype build (mise install provisions rust)"
else
	test -d "$voxtype_src/.git" || git clone https://github.com/peteonrails/voxtype "$voxtype_src"
	# --features parakeet pulls in parakeet-rs and its ONNX Runtime. No GPU
	# feature: the parakeet EPs upstream ships are CUDA/TensorRT/MIGraphX/
	# CoreML, none of which mean anything on an Apple GPU under Linux, and the
	# model is fast enough on the CPU cores for dictation-length clips.
	if (cd "$voxtype_src" && cargo build --release --features parakeet); then
		mkdir -p ~/.local/bin
		install -m 755 "$voxtype_src/target/release/voxtype" ~/.local/bin/voxtype
		echo "  installed: $(~/.local/bin/voxtype --version 2>/dev/null | head -1)"
		# Read out of config.toml rather than named here. This line used to
		# carry its own copy of the model name and had already drifted from the
		# config -- following it downloaded parakeet-tdt-0.6b-v3 while the
		# daemon was asking for the unified build, which fails at load rather
		# than falling back. The config is the thing voxtype actually reads, so
		# it is the thing to quote.
		vox_model=$(sed -n 's/^model[[:space:]]*=[[:space:]]*"\(.*\)".*/\1/p' \
			~/.config/voxtype/config.toml 2>/dev/null | head -1)
		if [ -n "$vox_model" ]; then
			echo "  -> fetch the model (~700MB) with:"
			echo "     voxtype setup --download --model $vox_model"
		else
			echo "  -> couldn't read the model out of ~/.config/voxtype/config.toml;"
			echo "     fetch whatever [parakeet] model = names there"
		fi
	else
		echo "  voxtype build failed; see $voxtype_src"
	fi
fi
set -x

echo "===== Checking out dwl ====="
# The compositor's source, which the two sections below write into: config.h is
# rendered there and the patch stack is applied there. Pinned to v0.7 rather
# than tracking the branch, because dwl links a specific wlroots -- 0.7 is the
# release built against wlroots 0.18, which is what trixie packages
# (libwlroots-0.18-dev, up in the apt block). Newer dwl wants 0.19 and won't
# build here.
#
# This runs *before* the config.h render below, which is the whole reason a
# plain clone works: the folder replication near the top of this script has
# already created ~/projects/dwl (it mirrors every directory under home/zaq, and
# config.h.in lives in one), but nothing has written into it -- config.h.in is a
# template, excluded from the symlink pass -- and clone is happy with an
# existing empty directory. Render first and it wouldn't be: clone refuses a
# non-empty target. If this ever grows a step that drops a file in there
# earlier, this becomes an init/fetch/checkout in place.
#
# Shallow, and detached at the tag: this is a build tree, not somewhere to do
# dwl development. The patch stack applies to the worktree and doesn't need
# history. Idempotent -- an existing checkout is left alone, including one
# already patched, since re-cloning would throw the patches away.
set +x
dwl_src=~/projects/dwl
dwl_url=https://codeberg.org/dwl/dwl.git
dwl_ver=v0.7
if [ -d "$dwl_src/.git" ]; then
	echo "  $dwl_src is already a checkout; leaving it alone"
elif git clone -q --depth 1 --branch "$dwl_ver" "$dwl_url" "$dwl_src"; then
	echo "  checked out dwl $dwl_ver in $dwl_src"
else
	# The likely second failure is a leftover directory from the first: the
	# render below puts config.h in there whether or not this worked, and clone
	# won't touch a non-empty target. Hence the rm in the recovery line.
	echo "  couldn't check out dwl $dwl_ver; fix the network and rerun, or:"
	echo "    rm -rf $dwl_src && git clone --depth 1 --branch $dwl_ver $dwl_url $dwl_src"
fi
set -x

echo "===== Rendering dwl's config.h ====="
# The one tracked file that is generated rather than symlinked. dwl matches a
# MonitorRule on the output *name*, and "eDP-1" says nothing about whether the
# panel behind it is 254dpi or 96dpi -- so the scale cannot be written portably
# and has to be decided here, at install time, on the machine it applies to.
#
# The panel's preferred mode is the first line of its sysfs `modes`, which is
# readable without a running compositor (wlr-randr would need a session, and
# this may well run from a tty). 2560 as the cutoff is the usual HiDPI-laptop
# line: this machine's 3456x2160 lands well above it, a 1920x1080 panel well
# below. A desktop with no eDP-1 at all gets 1, which is what the fallback
# MonitorRule already says anyway.
#
# Everything else in config.h uses $HOME through SHCMD and needs no stamping --
# see the comment there. If the eDP-1 rule is ever dropped, this whole section
# and the .in suffix can go with it.
set +x
dwl_cfg_in=$(pwd)/home/zaq/projects/dwl/config.h.in
dwl_cfg=~/projects/dwl/config.h
panel_w=
for m in /sys/class/drm/*-eDP-1/modes; do
	test -r "$m" || continue
	panel_w=$(head -1 "$m" | cut -dx -f1)
	break
done
if [ -n "$panel_w" ] && [ "$panel_w" -ge 2560 ] 2>/dev/null; then
	dwl_scale=2
else
	dwl_scale=1
fi
mkdir -p ~/projects/dwl
if [ -f "$dwl_cfg" ] && [ ! -L "$dwl_cfg" ] && [ "$dwl_cfg" -nt "$dwl_cfg_in" ]; then
	# Edited in place since the last render. Rendering over it would throw away
	# keybindings without saying so, and this is the one file here where that is
	# possible at all -- symlinks can't be clobbered this way.
	echo "  $dwl_cfg is newer than the template; leaving it alone"
	echo "  (put the change in home/zaq/projects/dwl/config.h.in and delete the rendered file)"
else
	# -L as well as -f: a run from before this file was a template left a
	# symlink here, and sed > would write back through it into the repo.
	rm -f "$dwl_cfg"
	sed "s/@SCALE@/$dwl_scale/g" "$dwl_cfg_in" >"$dwl_cfg"
	echo "  rendered $dwl_cfg with scale $dwl_scale (eDP-1 ${panel_w:-absent})"
fi
set -x

echo "===== Applying dwl patches ====="
# dwl is built from a local checkout; our patches live in patches/dwl and are
# applied in filename order. A patch that reverse-checks cleanly is already
# applied, so re-running setup is a no-op. This only patches the source; the
# build below is what makes any of it take effect. See patches/dwl/README.md.
#
# dwl_ready is what the build reads: set only where the source is in a state
# worth compiling, so a missing checkout or a half-applied stack doesn't get
# built and installed over a working compositor.
set +x # the loop is noisy under -x; the echoes below say everything useful
dwl_src=~/projects/dwl
dwl_ready=
if [ ! -d "$dwl_src/.git" ]; then
	echo "  no dwl checkout at $dwl_src; skipping (see patches/dwl/README.md)"
elif ! git -C "$dwl_src" diff --quiet; then
	# A dirty tree means the stack is already applied (or hand-modified), so
	# leave it alone. We gate on tree cleanliness rather than reverse-checking
	# each patch, because reverse-check is unreliable for a stack: 0002 and
	# 0003 rewrite the dwl.c context lines that 0001 needs in order to reverse,
	# so an already-applied 0001 reports as failed once the rest land on top.
	echo "  $dwl_src has local modifications; assuming already patched, leaving alone"
	echo "  (verify with: git -C $dwl_src diff --stat)"
	dwl_ready=yes
else
	# Clean checkout: apply the stack in order. They're interdependent -- each
	# patch's context assumes the previous one landed -- so this has to be
	# sequential, and a failure partway leaves the tree partially patched.
	# Piped through sed rather than applied directly, to stamp @HOME@ into
	# 0006's dwl.desktop. That one is an Exec= line in a desktop entry, which
	# the display manager tokenizes without expanding anything, so a $HOME
	# written there would reach dwl as a literal -- and unlike config.h and
	# foot.ini there is no shell standing in front of it to fix that. The sed is
	# a no-op for the other six.
	dwl_ready=yes
	for p in "$(pwd)"/patches/dwl/0*.patch; do
		if sed "s|@HOME@|$HOME|g" "$p" | git -C "$dwl_src" apply -; then
			echo "  applied: $(basename "$p")"
		else
			echo "  FAILED:  $(basename "$p") -- tree is now PARTIALLY patched."
			echo "  Reset with 'git -C $dwl_src checkout .' and see patches/dwl/README.md"
			dwl_ready=
			break
		fi
	done
fi
set -x

echo "===== Building and installing dwl ====="
# Unconditional, and from clean: everything above -- the checkout, the rendered
# config.h, the patch stack -- is source, and none of it reaches the screen
# until the compositor is rebuilt. `clean` first because a rebuild here is
# always answering a change the Makefile can't see all of: config.mk and
# config.h are dependencies of dwl.o, but a patch that touches util.c or the
# protocol XML is not, and a stale object is a compositor that doesn't match
# the tree it was built from.
#
# `make clean && make` as the user, `make install` under sudo, rather than one
# `sudo make clean install`: install is the only step that writes outside
# $HOME (/usr/local/bin, the man page, the wayland-sessions entry), and
# building as root would leave root-owned dwl and *.o in ~/projects/dwl -- so
# the next by-hand `make` in there fails on files it can't overwrite. Same
# result, no debris. This prompts for the sudo password like the apt and scrcpy
# steps do.
#
# Installing replaces the running compositor's binary but not the running
# compositor: dwl keeps executing the image it started with, so a rebuild
# mid-session changes nothing until the next login. That's also why this is
# safe to run from inside a dwl session.
set +x # the compiler is noisy enough on its own
if [ -z "$dwl_ready" ]; then
	echo "  dwl source isn't in a known-good state; not building"
	echo "  (fix the above, then: cd $dwl_src && make && sudo make install)"
elif ! (cd "$dwl_src" && make clean && make); then
	echo "  dwl build FAILED; the installed compositor is untouched"
	echo "  (build deps come from the apt block above; see $dwl_src)"
elif ! (cd "$dwl_src" && sudo make install); then
	echo "  dwl install FAILED; the installed compositor is untouched"
else
	echo "  installed: $(dwl -v 2>&1 | head -1)"
	echo "  -> log out and back in for the new compositor to take effect"
fi
set -x

touch ~/.dotfiles_initialized
