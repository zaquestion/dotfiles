#!/usr/bin/env bash
# PreToolUse(Bash) hook: refuse to let Claude push, and end its turn when it
# tries. Wired up in ~/.claude/settings.json. Pushing stays a human step.
#
# stdin is the hook payload; .tool_input.command is the shell command Claude is
# about to run. The regex matches "push" only in git's *subcommand* position,
# so global options still count (-C dir, -c k=v, --no-pager) while "git commit
# -m push" and "git log --grep=push" don't. Compound commands are covered too,
# since the match floats anywhere in the line: "cd foo && git push" is caught.
set -u

cmd=$(jq -r '.tool_input.command // ""')

git_push='\bgit\b([[:space:]]+(-[cC][[:space:]]+[^[:space:]]+|--[a-zA-Z-]+(=[^[:space:]]+)?|-[a-zA-Z]))*[[:space:]]+push\b'

printf '%s' "$cmd" | grep -qE "$git_push" || exit 0

# Both halves of this payload matter. permissionDecision:deny refuses this one
# call, which on its own just hands the model an error to react to -- and the
# obvious reaction is to reach for another route. continue:false ends the turn
# outright, so there is no next tool call to reroute into.
cat <<'JSON'
{
  "continue": false,
  "stopReason": "Blocked: git push is disabled by a local hook. Stopping here rather than looking for another way to push.",
  "systemMessage": "Hook blocked git push and stopped the turn.",
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "git push is blocked by a local hook, deliberately, and this turn is now over. Do not retry it, and do not reach for another route to the same outcome -- not gh, not a script or Makefile target that pushes, not a git alias. Summarize what is ready to be pushed and leave the push to the user."
  }
}
JSON
