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

read -p "Setup requires an internet connection, is long, and requires checkins. Is this okay? (Y/n)? " answer
case ${answer:0:1} in
    y|Y )
    ;;
    * )
	    exit 0
    ;;
esac

set -x
find ~ -mindepth 1 -maxdepth 1 -type d -exec rmdir {} \;
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
mkdir -p ~/projects/python

echo "===== Replicating Folder Structure ====="
# Find all directories and make in $HOME. Directories cannot be symlinked from
# dotfiles as they won't always have all of the needed configs and I don't want
# to track everything in them nor maintain a .gitignore
(cd home/zaq && find . -type d -exec test ! -d ~/'{}' \; -and -exec mkdir ~/'{}' \;)

test -f ~/.bashrc && \
read -p "Existing ~/.bashrc found. Overwrite (Y/n)? " answer && \
case ${answer:0:1} in
    Y )
	    rm ~/.bashrc
    ;;
    * )
    ;;
esac

echo "===== Symlinking Files ====="
# Find all files and create symlinks from $HOME
(cd home/zaq && find . -type f -exec test ! -r ~/'{}' \; -and -exec ln -s `pwd`/'{}' ~/'{}' \;)

# needed for PATH and GO env vars
set +x; source ~/.bashrc; set -x

echo '===== "system" packages ====='
sudo apt-get install -y neovim tmux keychain xclip scrot graphviz keynav curl x11-server-utils xinit
sudo apt-get install -y build-essential cmake libxinerama-dev

# Get Applications
if ! [ -x "$(command -v go)" ]; then
	set +x; echo "===== Downloading latest GoLang ====="; set -x
	curl $(curl -s -L https://golang.org/dl | grep 'download downloadBox.\+linux-amd64' | cut -d'"' -f 4) | sudo tar -C /usr/local/ -xzf -
fi

if ! [ -x "$(command -v hub)" ]; then
	set +x; echo "===== Getting hub ====="; set -x
	go get github.com/github/hub
fi

if ! [ -x "$(command -v pyenv)" ]; then
	set +x; echo "===== Installing pyenv ====="; set -x
	curl -L https://raw.githubusercontent.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash
	set +x; source ~/.bashrc; set -x
fi

if ! [ -x "$(command -v dwm)" ]; then
	set +x; echo "===== Compiling dwm ====="; set -x
	go get github.com/zaquestion/gods
	git clone git://git.suckless.org/dwm ~/projects/c/dwm
	cp ~/dwm/* ~/projects/c/dwm/
	(cd ~/projects/c/dwm && sudo make install)
fi

if ! [ -x "$(command -v st)" ]; then
	set +x; echo "===== Compiling st ====="; set -x
	git clone https://go.googlesource.com/image /tmp/image-go-fonts
	sudo cp /tmp/image-go-fonts/font/gofont/ttfs/Go-Mono* /usr/share/fonts/truetype/
	git clone git://git.suckless.org/st ~/projects/c/st
	cp ~/st/* ~/projects/c/st/
	(cd ~/projects/c/st && sudo make install)
fi


# Python Stuff
echo "===== Python Environment ====="
sudo apt-get install -y make pyenv openssl libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev
sudo apt-get install -y llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev liblzma-dev libgdbm-dev

if pyenv versions | grep '3\.6\.0'; then
	pyenv global 3.6.0
else
	PYTHON_CONFIGURE_OPTS="--enable-shared" pyenv install 3.6.0 && pyenv global 3.6.0
fi

set +x; source ~/.bashrc; set -x
pip install neovim seqdiag yapf awscli

# Config Applications
echo "===== nvim Environment ====="
test ! -d ~/.vim/bundle/Vundle.vim && git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim && \
nvim +PluginInstall +GoInstallBinaries +qall && \
(cd ~/.vim/bundle/YouCompleteMe && ./install.py --clang-completer --gocode-completer)

# From https://docs.docker.com/engine/installation/linux/debian/
echo "===== Docker ====="
compose_version=$(curl -sL "https://github.com/docker/compose/tags" | grep tag-name | grep --only '>[0-9\.]\+<' | head -n1 | cut -c 2- | rev | cut -c 2- | rev)
sudo apt-get install -y apt-transport-https ca-certificates gnupg2 && \
sudo apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D && \
echo "deb https://apt.dockerproject.org/repo debian-jessie main" | sudo tee /etc/apt/sources.list.d/docker.list && \

sudo apt-get update && \
sudo apt-get install -y docker-engine && \
sudo groupadd docker && \
sudo gpasswd -a ${USER} docker && \

sudo curl -L "https://github.com/docker/compose/releases/download/${compose_version}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
sudo chmod a+x /usr/local/bin/docker-compose

touch ~/.dotfiles_initialized
