# "Application" Variables
export projects=~/projects
export GOPATH=$projects/go
export GOBIN=$projects/go/bin
export GOROOT=/usr/local/go
export PATH=~/scripts/:~/bin:$GOPATH/bin:/snap/bin:~/.pyenv/bin:$GOROOT/bin:$PATH
export EDITOR=$(which vim)

eval "$(keychain --eval --agents ssh id_rsa)"

# Source external
if [ ! -r ~/.git-completion.bash ]; then
	echo "downloading .git-completion.bash"
	curl -s 'https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash' > ~/.git-completion.bash
fi
source ~/.git-completion.bash

if [ ! -r ~/.docker-compose-completion.bash ]; then
	curl -sL "https://raw.githubusercontent.com/docker/compose/$(docker-compose version --short)/contrib/completion/bash/docker-compose" > ~/.docker-compose-completion.bash
fi
source ~/.docker-compose-completion.bash

xset r rate 200 100
# "Application" Alias
if which nvim; then
	export EDITOR=$(which nvim)
	alias vim=nvim
fi
if which hub; then
	alias git=hub
	if [ ! -r ~/.hub-completion.bash ]; then
		echo "downloading .hub-completion.bash"
		curl -s 'https://raw.githubusercontent.com/github/hub/master/etc/hub.bash_completion.sh' > ~/.hub-completion.bash
	fi
	source ~/.hub-completion.bash
fi
if which gh; then
        source <(gh completion -s bash)
fi
if which lab; then
	alias git=lab
        source <(lab completion bash)
fi

if [ ! -x ~/.bashrc.local ]; then
	source ~/.bashrc.local
fi


# User Variables
export zaq=$GOPATH/src/github.com/zaquestion

# User Alias
alias ag="ag --ignore-dir vendor"
alias xclip="xclip -selection clipboard"

# Terminal Settings
export TERM="xterm-256color"

git_branch()
{
	if ! $(which git) rev-parse --git-dir > /dev/null 2>&1; then
		return 0
	fi

	echo $($(which git) branch 2>/dev/null| sed -n '/^\*/s/^\* //p')
}

git_prompt ()
{
	if ! $(which git) rev-parse --git-dir > /dev/null 2>&1; then
		return 0
	fi

	echo "($(git_branch))"
}
# export all these for subshells
export -f git_prompt
export PS1="\u@\h:\w \[\033[m\]\$(git_prompt)\n\$ "

############### HISTORY SECTION ####################
# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
export HISTSIZE=-1
export HISTFILESIZE=-1

# Avoid duplicates
export HISTCONTROL=erasedups:ignoredups:ignorespace
export PROMPT_COMMAND="history -a"
# prevents reused lines from being commited
set revert-all-at-newline on
# Attempt to combine multiline commands into 1 history line with semicolons
shopt -s cmdhist
shopt -u lithist
# When the shell exits, append to the history file instead of overwriting it
shopt -s histappend
# Once a i-search fails allows you to modify the search and keep searching (readline)
shopt -s histreedit
# Prevent C-s from sent XOF (pause)
# Allows C-s to be used in i-search
stty -ixon

## Bash up arrow search completion
## http://askubuntu.com/questions/59846/bash-history-search-partial-up-arrow
## arrow up search through history
bind '"\e[A":history-search-backward'
## arrow down
bind '"\e[B":history-search-forward'
############### HISTORY SECTION ####################

# Modifies PROMPT_COMMAND
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# expand environment vars to there full path for tab complete
shopt -s direxpand
# badass globbing
shopt -s globstar

# Disables caps lock key
# reset: setxkbmap -option
setxkbmap -option ctrl:nocaps
