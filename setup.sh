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
(cd home/zaq && find . -type f ! -name .gitkeep -exec test ! -e ~/'{}' -o -L ~/'{}' \; -and -exec ln -sfn `pwd`/'{}' ~/'{}' \;)

echo "===== Installing packages ====="
# Debian/apt only; skipped elsewhere. apt install is idempotent -- already
# installed packages are a no-op -- so re-running setup costs nothing.
# Fonts: waybar's config.jsonc draws its icons from Font Awesome and Weather
# Icons (plus the Nerd Font below), and Roboto is the text face its stylesheet
# asks for first.
# grim/slurp back ~/scripts/snip, bound to mod-shift-s in dwl's config.h.
# swaylock is the screen locker, bound to mod-shift-l; it reads its colors from
# ~/.config/swaylock/config.
# jq reads the GitHub release JSON in the keychain install below.
# The remainder are scrcpy's build and runtime deps, per upstream doc/linux.md;
# the build itself is further down.
set +x # apt is noisy enough on its own
if command -v apt >/dev/null; then
	sudo apt install -y \
		fish \
		fonts-font-awesome \
		fonts-weather-icons \
		fonts-roboto \
		grim \
		slurp \
		swaylock \
		wl-clipboard \
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

echo "===== Applying dwl patches ====="
# dwl is built from a local checkout; our patches live in patches/dwl and are
# applied in filename order. A patch that reverse-checks cleanly is already
# applied, so re-running setup is a no-op. Note this only patches the source --
# the compositor still has to be rebuilt and reinstalled by hand for any of it
# to take effect. See patches/dwl/README.md.
set +x # the loop is noisy under -x; the echoes below say everything useful
dwl_src=~/projects/dwl
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
else
	# Clean checkout: apply the stack in order. They're interdependent -- each
	# patch's context assumes the previous one landed -- so this has to be
	# sequential, and a failure partway leaves the tree partially patched.
	for p in "$(pwd)"/patches/dwl/0*.patch; do
		if git -C "$dwl_src" apply "$p"; then
			echo "  applied: $(basename "$p")"
		else
			echo "  FAILED:  $(basename "$p") -- tree is now PARTIALLY patched."
			echo "  Reset with 'git -C $dwl_src checkout .' and see patches/dwl/README.md"
			break
		fi
	done
	echo "  -> run 'make && sudo make install' in $dwl_src, then restart the session"
fi
set -x

touch ~/.dotfiles_initialized
