#!/usr/bin/env bash
# Claude Code statusline.
#
# Layout:   ~/projects/eeg/seizure_tool  (main)*
#           Opus 5 · ctx 34% · 58.4k ($1.20)  +120 -8
#
# Two lines, split by how often they change: where you are stays put for
# minutes at a time, while the meters below move with every turn -- so the
# place you look to orient yourself doesn't shift when a number widens. Every
# segment is optional and simply vanishes when its field is absent, so the bar
# never shows a placeholder or a zero -- an empty spot means "nothing to
# report". When no meter has anything to say the second line is dropped
# entirely rather than printed blank.

input=$(cat)

R=$'\033[0m'
DIR=$'\033[1;34m'         # cwd, bold -- the anchor you scan for
BRANCH=$'\033[33m'        # git
DIRTY=$'\033[31m'         # the * on a dirty tree
GREY=$'\033[38;5;250m'    # meter text: light enough to read on a dark bg,
SEP=$'\033[38;5;242m'     # while the separators between them stay back
OK=$'\033[32m'
WARN=$'\033[33m'
HOT=$'\033[31m'
ADD=$'\033[32m'
DEL=$'\033[31m'

j() { jq -r "$1 // empty" <<<"$input"; }

# ---- cwd, $HOME abbreviated to ~ ----
dir=$(j '.workspace.current_dir'); [ -n "$dir" ] || dir=$PWD
case "$dir" in
    "$HOME") pwd_str='~' ;;
    "$HOME"/*) pwd_str="~${dir#"$HOME"}" ;;
    *) pwd_str=$dir ;;
esac
line1="${DIR}${pwd_str}${R}"

# ---- git: branch, or a short sha when detached; * if dirty ----
# Parenthesized either way -- a detached HEAD then reads as (a1b2c3d), same
# shape as a branch, since what matters is that it's the git segment.
# --no-optional-locks so rendering the bar can't contend with a running git.
g() { git --no-optional-locks -C "$dir" "$@" 2>/dev/null; }
if ref=$(g symbolic-ref --short HEAD); then
    head_str=$ref
elif sha=$(g rev-parse --short HEAD); then
    head_str=$sha
fi
if [ -n "$head_str" ]; then
    dirty=""
    [ -n "$(g status --porcelain)" ] && dirty="${DIRTY}*${R}"
    line1="$line1  ${BRANCH}(${head_str})${R}${dirty}"
fi

# ---- meters: model, context used, session/weekly usage, tokens and spend ----
# Joined with a mid-dot so they read as one group distinct from the git segment
# above, rather than several things competing for attention. Each entry carries
# its own color and ends by restoring $GREY, so a colored percentage can sit
# mid-group without bleeding into the text after it.
meters=()

# A percentage is silent until it matters: green, then yellow, then red as it
# approaches the limit it's measuring.
pct_meter() { # $1 = label prefix, $2 = raw percentage
    local p c
    p=$(printf '%.0f' "$2")
    if [ "$p" -ge 85 ]; then c=$HOT
    elif [ "$p" -ge 60 ]; then c=$WARN
    else c=$OK
    fi
    printf '%s%s%s%%%s' "$1" "$c" "$p" "$GREY"
}

model=$(j '.model.display_name')
[ -n "$model" ] && meters+=("$model")

ctx=$(j '.context_window.used_percentage')
[ -n "$ctx" ] && meters+=("$(pct_meter 'ctx ' "$ctx")")

# Rate limits show up only once the subscription has reported them, so these
# segments are absent on an API-key session rather than reading 0%.
five=$(j '.rate_limits.five_hour.used_percentage')
[ -n "$five" ] && meters+=("$(pct_meter '5h ' "$five")")
week=$(j '.rate_limits.seven_day.used_percentage')
[ -n "$week" ] && meters+=("$(pct_meter '7d ' "$week")")

# ---- tokens in context, with the session's spend trailing in parens ----
# The token count is what .context_window.used_percentage is a percentage of:
# input + cache-creation + cache-read from the last exchange, i.e. how full the
# window currently is, NOT a running session total (the payload has no such
# field). So it reads as the absolute twin of the ctx% above -- the percentage
# says how close the ceiling is, the count says how much is actually in there,
# which is the number that matters when deciding what to /clear.
#
# Cost is subordinated to it: dimmer, in parens, because it's the thing you
# glance at rather than act on. Either half stands alone if the other is
# missing -- an API-key session with no cost reported still shows its tokens.
human_tokens() { # $1 = raw count -> 842, 58.4k, 124k, 1.2M
    awk -v n="$1" 'BEGIN{
        if (n >= 1000000) printf "%.1fM", n/1000000
        else if (n >= 100000) printf "%.0fk", n/1000
        else if (n >= 1000) printf "%.1fk", n/1000
        else printf "%d", n
    }'
}

tok=$(j '.context_window.total_input_tokens')
cost=$(j '.cost.total_cost_usd')
cost_str=""
if [ -n "$cost" ] && awk -v c="$cost" 'BEGIN{exit !(c >= 0.01)}'; then
    cost_str=$(awk -v c="$cost" 'BEGIN{printf "$%.2f", c}')
fi
if [ -n "$tok" ] && [ "$tok" != "0" ]; then
    usage="$(human_tokens "$tok")"
    [ -n "$cost_str" ] && usage="$usage ${SEP}(${cost_str})${GREY}"
    meters+=("$usage")
elif [ -n "$cost_str" ]; then
    meters+=("$cost_str")
fi

line2=""
if [ ${#meters[@]} -gt 0 ]; then
    joined=$(IFS=$'\x01'; printf '%s' "${meters[*]}")
    line2="${GREY}${joined//$'\x01'/${SEP} · ${GREY}}${R}"
fi

# ---- lines written this session ----
add=$(j '.cost.total_lines_added')
del=$(j '.cost.total_lines_removed')
diff_str=""
[ -n "$add" ] && [ "$add" != "0" ] && diff_str=" ${ADD}+${add}${R}"
[ -n "$del" ] && [ "$del" != "0" ] && diff_str="$diff_str ${DEL}-${del}${R}"
if [ -n "$diff_str" ]; then
    diff_str=${diff_str# }
    [ -n "$line2" ] && line2="$line2  $diff_str" || line2=$diff_str
fi

printf '%s\n' "$line1"
# Not a `&&` one-liner: that would leave the script exiting 1 whenever there
# are no meters to print, which reads as a failed statusline command.
if [ -n "$line2" ]; then
    printf '%s\n' "$line2"
fi
