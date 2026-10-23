#!/usr/bin/env bash
# Blocks outward-facing GitHub writes from Bash. Read-only `gh` calls pass through
# so review comments can still be fetched. Ben posts to GitHub himself.
set -uo pipefail

command_line=$(jq -r '.tool_input.command // empty' 2>/dev/null) || exit 0
[ -z "$command_line" ] && exit 0

deny() {
  jq -nc --arg reason "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

ADVICE="Ben posts to GitHub himself. Draft the text and ask him to run it with '! <command>'."

gh_cmd='(^|[^[:alnum:]_./-])gh[[:space:]]'

# Writing gh subcommands
if printf '%s' "$command_line" | grep -Eq \
  "${gh_cmd}+(pr|issue|release|label|repo|gist|workflow|secret|variable|ruleset)[[:space:]]+(comment|create|edit|delete|merge|review|close|reopen|ready|lock|unlock|pin|unpin|transfer|archive|rename|set|remove|run|upload|develop)([[:space:]]|$)"; then
  deny "Blocked: this is a GitHub write. $ADVICE"
fi

# `gh api` carrying a write method, a body, or a graphql mutation
if printf '%s' "$command_line" | grep -Eq "${gh_cmd}*api([[:space:]]|$)"; then
  if printf '%s' "$command_line" | grep -Eqi '[[:space:]](-X|--method)[[:space:]]+(POST|PATCH|PUT|DELETE)'; then
    deny "Blocked: 'gh api' with a write method. $ADVICE"
  fi
  if printf '%s' "$command_line" | grep -Eq '[[:space:]](--input|--field|--raw-field|-f|-F)([[:space:]]|=)'; then
    deny "Blocked: 'gh api' sending a request body. $ADVICE"
  fi
  if printf '%s' "$command_line" | grep -Eqi 'mutation[[:space:]]*[({]'; then
    deny "Blocked: 'gh api graphql' mutation. $ADVICE"
  fi
fi

# Direct curl against the GitHub API with a method or body
if printf '%s' "$command_line" | grep -Eq 'curl.*(api\.github\.com|uploads\.github\.com)'; then
  if printf '%s' "$command_line" | grep -Eqi '[[:space:]](-X|--request)[[:space:]]+(POST|PATCH|PUT|DELETE)|[[:space:]](-d|--data|--data-raw|--data-binary|--data-urlencode|--json)([[:space:]]|=)'; then
    deny "Blocked: curl writing to the GitHub API. $ADVICE"
  fi
fi

exit 0
