#This should be prepended to the file if already existing.
export projects=~/projects
export GOPATH=$projects/go
export GOROOT=/usr/local/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
#alias git=hub

export zaq=$GOPATH/src/github.com/zaqthefreshman

source ~/.git-completion.bash
