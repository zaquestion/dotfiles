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

echo "===== Symlinking Files ====="
# Find all files and create symlinks from $HOME. .gitkeep files only exist to
# keep otherwise empty dirs in the repo, they don't belong in $HOME.
# Link when the target is missing/broken (! -e) or is already a symlink (-L),
# using -f to refresh stale links; real files are left untouched so we never
# clobber something like a hand-edited ~/.bashrc.
(cd home/zaq && find . -type f ! -name .gitkeep -exec test ! -e ~/'{}' -o -L ~/'{}' \; -and -exec ln -sfn `pwd`/'{}' ~/'{}' \;)

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

touch ~/.dotfiles_initialized
