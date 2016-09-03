#This should be prepended to the file if already existing.
export projects=~/projects
export GOPATH=$projects/go
export GOROOT=/usr/local/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
export EDITOR=/usr/bin/vim
if which nvim; then
	export EDITOR=$(which nvim)
fi
if which hub; then
	alias git=hub
fi
alias ag="ag --ignore-dir Godeps"

export zaq=$GOPATH/src/github.com/zaquestion


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

export TERM="xterm-color"

source ~/.git-completion.bash

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=100000
HISTFILESIZE=100000

# Avoid duplicates
export HISTCONTROL=ignoredups:erasedups
# When the shell exits, append to the history file instead of overwriting it
shopt -s histappend

# After each command, append to the history file and reread it
export PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a; history -c; history -r"
