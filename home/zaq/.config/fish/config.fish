# ~/.config/fish/config.fish
#
# Ported from the old bash setup (home/zaq/.bashrc on master).
#
# Deliberately NOT ported, because fish already does it:
#   HISTSIZE/HISTFILESIZE=-1            fish history is unbounded
#   HISTCONTROL=erasedups:ignoredups:ignorespace
#                                       fish dedupes, and skips commands typed
#                                       with a leading space
#   PROMPT_COMMAND="history -a", histappend
#                                       fish writes history as you go
#   shopt cmdhist / histreedit          multiline commands are stored whole and
#                                       stay editable from the history pager
#   bind up/down history-search         fish's default up/down is prefix search
#   stty -ixon                          fish turns off flow control itself
#   shopt globstar                      ** is native fish globbing
#   shopt direxpand                     fish expands vars during completion
#   git/gh completions (curl'd by hand) fish bundles both
#
# Dropped as X11-only, now the compositor's job (dwl config.h / foot.ini):
#   xset r rate 200 100                 key repeat
#   setxkbmap -option ctrl:nocaps       caps -> ctrl
#   export TERM=screen-256color         was for st+tmux; foot sets TERM itself

# ---- "Application" variables ----
set -gx projects $HOME/projects
set -gx GOPATH $projects/go
set -gx PNPM_HOME $HOME/.local/share/pnpm
# nvim comes from mise, so point EDITOR at the shim rather than a versioned path
set -gx EDITOR $HOME/.local/share/mise/shims/nvim

# ---- User variables ----
set -gx zaq $GOPATH/src/github.com/zaquestion

# PATH, highest priority first. fish_add_path skips directories that don't
# exist, so this self-prunes on a fresh machine.
fish_add_path -gp \
    $HOME/.local/bin \
    $PNPM_HOME \
    $HOME/.local/share/mise/shims \
    $HOME/scripts \
    $HOME/bin \
    $GOPATH/bin \
    /usr/sbin

# Bash printed nothing at startup; neither should fish.
set -g fish_greeting ''

# ---- Prompt ----
# The old PS1: two lines, uncolored, with the git branch after the cwd.
#   PS1="\u@\h:\w \[\033[m\]\$(git_prompt)\n\$ "
# The hand-rolled git_prompt is gone: fish bundles fish_git_prompt, which
# already prints " (branch)" -- and unlike the old one it knows about
# rebase/merge/bisect state and prints nothing outside a repo. Defaults show
# the branch only; dirty/staged/untracked markers are opt-in via
# __fish_git_prompt_show{dirtystate,untrackedfiles,stashstate}.
# Detached HEAD reads "((abcd1234))" -- fish parenthesizes the sha itself.
function fish_prompt --description 'user@host:cwd (branch), then $ on its own line'
    # prompt_pwd -d 0 keeps directory names full length, matching bash's \w
    # (which only abbreviates $HOME to ~)
    echo -n (whoami)@(prompt_hostname):(prompt_pwd -d 0)
    set_color normal
    fish_git_prompt
    echo
    if fish_is_root_user
        echo -n '# '
    else
        echo -n '$ '
    end
end

# ---- Completion ----
# Bash's tab: insert the longest common prefix, then list the candidates when
# more than one remains. fish agrees on the first tab, but from the second on
# its `complete` walks the pager, inserting entries one at a time. Dismissing
# the pager before completing again keeps every tab a prefix-insert, recomputed
# against whatever is on the line -- so typing more and hitting tab narrows,
# exactly like bash. shift-tab (complete-and-search) still opens the pager to
# pick an entry by hand.
function __tab_complete_prefix --description 'complete the common prefix, never cycle the pager'
    if commandline --paging-mode
        commandline -f cancel
    end
    commandline -f complete
end

# fish calls this after installing its own preset bindings, which is the only
# hook that survives a later `set fish_key_bindings ...`
function fish_user_key_bindings
    bind tab __tab_complete_prefix
end

if status is-interactive
    # ---- Aliases ----
    alias vim nvim
    alias rgf 'rg --files | rg'
    # dropped: `ag`, `xclip`, and the git=hub / git=lab aliases -- none of those
    # binaries are installed here (wl-copy replaces xclip on wayland)

    # ssh agent; keychain reuses one agent across logins. Inert until keychain
    # is installed -- and only id_ed25519 now, google_compute_engine is gone.
    command -q keychain; and keychain --eval --agents ssh id_ed25519 | source

    mise activate fish | source
else
    # scripts and `fish -c` get shims instead of the activate hook, per mise's
    # recommendation
    mise activate fish --shims | source
end

# Machine-local overrides, untracked -- the old ~/.bashrc.local
test -r $HOME/.config/fish/config.local.fish
and source $HOME/.config/fish/config.local.fish
