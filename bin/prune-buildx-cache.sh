#!/bin/bash
#
# Weekly BuildKit build-cache prune.
#
# Why this exists: BuildKit garbage collects periodically, but only while
# buildkitd is actually running - and on a Mac that means only while OrbStack is
# up. A machine that hasn't opened OrbStack in months never collects anything,
# so the cache sits at whatever size it reached. This drops cache records
# nothing has touched for 30 days, across every builder.
#
# Scheduled on macOS by LaunchAgents/dev.benschem.prune-buildx-cache.plist,
# and on Linux by systemd/prune-buildx-cache.timer. Runs standalone too.

set -u

# launchd and systemd both hand you a bare PATH that omits /usr/local/bin,
# so put the usual install locations back before looking for docker.
PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"
DOCKER=$(command -v docker || true)

MAX_AGE=720h                 # 30 days
MAX_LOG_BYTES=262144         # 256 KB

# Log where each OS expects it. macOS keeps user logs in ~/Library/Logs; Debian,
# Ubuntu and Fedora all follow the XDG spec, where per-user state belongs in
# $XDG_STATE_HOME (~/.local/state by default). Decide on the OS rather than on
# whether a directory happens to exist, so the choice is explicit either way.
case "$(uname)" in
  Darwin) log_dir="$HOME/Library/Logs" ;;
  *)      log_dir="${XDG_STATE_HOME:-$HOME/.local/state}" ;;
esac
mkdir -p "$log_dir"
LOG="$log_dir/prune-buildx-cache.log"

# Roll the log over once it gets big, so it can't grow forever.
if [ -f "$LOG" ] && [ "$(wc -c < "$LOG")" -gt "$MAX_LOG_BYTES" ]; then
  mv -f "$LOG" "$LOG.old"
fi

# Send everything from here down to the log instead of the terminal.
exec >> "$LOG" 2>&1
echo "--- $(date '+%Y-%m-%d %H:%M:%S') ---"

if [ -z "$DOCKER" ]; then
  echo "docker not on PATH - skipping"
  exit 0
fi

# Deliberately does NOT start the daemon. Waking a VM on a timer is a worse
# trade than skipping a week: the cache only grows while the daemon is running,
# so a week where it never ran has nothing new to collect anyway.
if ! "$DOCKER" info > /dev/null 2>&1; then
  echo "docker daemon not reachable - skipping"
  exit 0
fi

# `docker buildx ls` prints each builder at the left margin, with its nodes
# indented underneath. We want the builder names only - pruning a node name
# just errors out. So: drop the header row, drop the indented node rows, take
# the first column, and strip the "*" that marks the current default builder.
list_builder_names() {
  "$DOCKER" buildx ls \
    | tail -n +2 \
    | grep -v '^[[:space:]]' \
    | cut -d ' ' -f 1 \
    | tr -d '*' \
    | grep -v '^$'
}

list_builder_names | while read -r builder; do
  result=$("$DOCKER" buildx prune --force --filter "until=$MAX_AGE" --builder "$builder" 2>&1 | tail -1)

  # Builders bound to a non-active Docker context can't be pruned from here.
  # OrbStack leaves a stale "default" behind, so this is expected, not a fault.
  case "$result" in
    *"switch to context"*) echo "$builder: skipped (inactive context)" ;;
    *)                     echo "$builder: $result" ;;
  esac
done

echo "free space: $(df -h "$HOME" | tail -1 | awk '{print $4}')"
