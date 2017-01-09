# "Application" Variables
export projects=~/projects
export GOPATH=$projects/go
export GOROOT=/usr/local/go
export PATH=~/bin:$GOPATH/bin:~/.pyenv/bin:$GOROOT/bin:$PATH
export EDITOR=$(which vim)

# Source external
if [ ! -r ~/.git-completion.bash ]; then
	echo "downloading .git-completion.bash"
	curl -s 'https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash' > ~/.git-completion.bash
fi
if [ ! -r ~/.hub-completion.bash ]; then
	echo "downloading .hub-completion.bash"
	curl -s 'https://raw.githubusercontent.com/github/hub/master/etc/hub.bash_completion.sh' > ~/.hub-completion.bash
fi
source ~/.git-completion.bash

eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# "Application" Alias
if which nvim; then
	export EDITOR=$(which nvim)
	alias vim=nvim
fi
if which hub; then
	alias git=hub
	source ~/.hub-completion.bash
fi

# User Variables
export zaq=$GOPATH/src/github.com/zaquestion
export lab=$GOPATH/src/github.com/TuneLab
export pylab=$projects/python/TuneLab/

# User Alias
alias ag="ag --ignore-dir vendor"

# Terminal Settings
export TERM="xterm-256color"

git_prompt ()
{
	if ! git rev-parse --git-dir > /dev/null 2>&1; then
		return 0
	fi

	git_branch=$(git branch 2>/dev/null| sed -n '/^\*/s/^\* //p')

	if git diff --quiet 2>/dev/null >&2; then
		git_color="${c_git_clean}"
	else
		git_color=${c_git_cleanit_dirty}
	fi

	echo "($git_color$git_branch${c_reset})"
}

# export all these for subshells
export -f git_prompt
export PS1="\u@\h:\w \[\033[m\]\$(git_prompt)\n\$ "

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000000
HISTFILESIZE=10000000

# Avoid duplicates
export HISTCONTROL=ignoredups:erasedups
# When the shell exits, append to the history file instead of overwriting it
shopt -s histappend
