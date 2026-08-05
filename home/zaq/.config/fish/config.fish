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

    # ---- how ----
    # `how <question>` asks claude for a shell command and leaves it sitting on
    # the prompt, unexecuted, so it can be read and edited before it runs.
    #
    # Ported from a zsh version; three things had no fish equivalent:
    #   print -z <cmd>    pushes onto the next prompt -> `commandline -r`, which
    #                     replaces the line being edited (hence the function
    #                     lives in the interactive block; commandline errors out
    #                     everywhere else)
    #   pbcopy            -> wl-copy, same wayland clipboard ~/scripts/snip uses
    #   alias how='noglob ...'
    #                     fish has no noglob, so a `*` or `?` in the question is
    #                     still glob-expanded (or, with no match, is an error
    #                     before the function is ever called). Quote those:
    #                     how 'how do I delete every *.o'
    #
    # -p prints one response and exits; --tools "" leaves the model unable to do
    # anything but answer, which also keeps it from stalling on a permission
    # prompt nothing is there to accept. `command` so a future `how`/`claude`
    # alias can't recurse, `--` so a question opening with `-` isn't read as a
    # flag. The model is told to skip markdown, but asks anyway often enough to
    # be worth stripping backticks and blank lines; string collect keeps a
    # multi-line answer as one string instead of letting the command
    # substitution split it into separate arguments.
    function how --description 'ask claude for a command, leave it on the prompt'
        if test (count $argv) -eq 0
            echo "Usage: how <what command do you need?>"
            return 1
        end

        set -l result (command claude -p --model sonnet --max-turns 1 --tools "" \
            --append-system-prompt "You are a command-line expert. Respond with ONLY the command itself - no explanation, no markdown, no code blocks." \
            -- "$argv" 2>/dev/null \
            | string replace -ra '`' '' | string trim \
            | string match -rv '^$' | string collect)

        test -n "$result"; or return 1

        # printf rather than echo: no trailing newline, so pasting the clipboard
        # into another prompt doesn't submit the command on arrival.
        printf '%s' $result | wl-copy
        echo "Command ready (also copied to clipboard):"
        commandline -r -- $result
    end

    # ---- ssh agent ----
    # keychain starts one ssh-agent and hands every later login the same one,
    # so the passphrase is typed once per boot instead of once per terminal.
    # Inert until keychain is installed -- and only id_ed25519 now,
    # google_compute_engine is gone.
    #
    # keychain 3 is a python rewrite with a verb-based CLI, so this is no
    # longer 2.x's `keychain --eval --agents ssh id_ed25519 | source`. That
    # still works -- 3.x translates legacy invocations -- but two calls beat
    # one --eval here, for two reasons:
    #
    #   --eval picks its output syntax from $SHELL, which only reads as fish
    #   when fish is the login shell; start fish from anything else and it
    #   emits sh syntax that `source` then chokes on. `env --shell env` is
    #   plain KEY=value, so the syntax can't be guessed wrong.
    #
    #   ...and the fish syntax it would emit is `set -x -U`, i.e. universal
    #   variables, which fish persists to ~/.config/fish/fish_variables. This
    #   boot's socket path would outlive its agent, survive a reboot, and be
    #   handed to every future session until some later keychain run
    #   overwrote it. Parsing into `set -gx` keeps the agent env per-session.
    #
    # The key has to be tested for separately: with every requested key absent
    # keychain refuses to start an agent and says so in red, which on a machine
    # that simply doesn't have this key would nag at every single shell start
    # (--ignore-missing only covers the some-missing case). Testing first also
    # skips the python spawn entirely there, the same way fish_add_path above
    # self-prunes.
    #
    # --quiet drops ssh-add's "Identity added" while leaving the passphrase
    # prompt and real errors alone; --no-gui because dwl's Xwayland sets
    # DISPLAY but no ssh-askpass is installed here, so a prompt without a
    # controlling tty would die on the missing binary rather than fall back to
    # the terminal. Costs ~0.3s per interactive start -- the python zipapp is
    # slower to spawn than the old shell script was.
    #
    # With the key not yet loaded this prints "Press Enter to initialize keys"
    # and waits: 3.x coordinates terminals so that when several start at once
    # only the one you answer runs ssh-add, and the rest pick up the result.
    # Pass --immediate to skip the wait and prompt for the passphrase outright.
    if command -q keychain; and test -r $HOME/.ssh/id_ed25519
        keychain add --quiet --no-gui id_ed25519
        for kv in (keychain env --shell env)
            set -gx (string split -m1 = -- $kv)
        end
    end

    mise activate fish | source
else
    # scripts and `fish -c` get shims instead of the activate hook, per mise's
    # recommendation
    mise activate fish --shims | source
end

# Machine-local overrides, untracked -- the old ~/.bashrc.local
test -r $HOME/.config/fish/config.local.fish
and source $HOME/.config/fish/config.local.fish
