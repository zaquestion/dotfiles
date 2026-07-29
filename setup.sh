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
# Fonts: waybar's config.jsonc uses glyphs from all three of these, and without
# them the bar renders tofu boxes instead of icons.
set +x # apt is noisy enough on its own
if command -v apt >/dev/null; then
	sudo apt install -y \
		fonts-font-awesome \
		fonts-weather-icons \
		fonts-material-design-icons-iconfont \
		fonts-materialdesignicons-webfont
else
	echo "  no apt; skipping package install"
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
