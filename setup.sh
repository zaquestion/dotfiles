#/usr/bin/env bash

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

# blow away default
rm ~/.bashrc
ln -s `pwd`/home/zaq/.bashrc ~/.bashrc
# needed for PATH and GO env vars
set +x
source ~/.bashrc
set -x

# Get Applications
if ! [ -x "$(command -v go)" ]; then
	echo "===== Downloading latest GoLang ====="
	curl `curl -s -L https://golang.org/dl | grep 'download downloadBox.\+linux-amd64' | cut -d'"' -f 4` > ~/downloads/golang.tar.gz
	sudo tar -C /usr/local/ ~/downloads/golang.tar.gz
fi

if ! [ -x "$(command -v hub)" ]; then
	echo "===== Getting hub ====="
	go get github.com/github/hub
fi

if ! [ -x "$(command -v pyenv)" ]; then
	echo "===== Intalling pyenv ====="
	curl -L https://raw.githubusercontent.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash
fi

if ! [ -x "$(command -v st)" ]; then
	 git clone https://go.googlesource.com/image /tmp/image-go-fonts
	 sudo cp /tmp/image-go-fonts/font/gofont/ttfs/Go-Mono* /usr/share/fonts/truetype/
	 git clone git://git.suckless.org/st ~/projects/c/st
	 cp ~/st/* ~/projects/c/st/
	 (cd ~/projects/c/st && make install)
fi


echo "===== Replicating Folder Structure ====="
# Find all directories and make in $HOME. Directories cannot be symlinked from
# dotfiles as they won't always have all of the needed configs and I don't want
# to track everything in them nor maintain a .gitignore
(cd home/zaq && find . -type d -exec test ! -d ~/'{}' \; -and -exec mkdir ~/'{}' \;)

echo "===== Symlinking Files ====="
# Find all files and create symlinks from $HOME
(cd home/zaq && find . -type f -exec test ! -r ~/'{}' \; -and -exec ln -s `pwd`/'{}' ~/'{}' \;)

echo '===== "system" packages ====='
sudo apt-get install neovim tmux keychain xclip scrot graphviz keynav mercurial
sudo apt-get install -y build-essential cmake

# Python Stuff
echo "===== Python Environment ====="
sudo apt-get install -y make openssl libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev
sudo apt-get install -y llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev liblzma-dev libgdbm-dev

if pyenv versions | grep '3\.6\.0'; then
	pyenv global 3.6.0
else
	pyenv install 3.6.0 && pyenv global 3.6.0
fi

set +x
source ~/.bashrc
set -x
pip install neovim seqdiag yapf

# Config Applications
echo "===== nvim Environment ====="
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
nvim +PluginInstall +GoInstallBinaries +qall && \
(cd ~/.vim/bundle/YouCompleteMe && ./install.py --clang-completer --gocode-completer)

touch ~/.dotfiles_initialized
