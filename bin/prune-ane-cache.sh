#!/bin/bash
#
# Clear the Apple Neural Engine bundle cache when it grows past a threshold.
#
# macOS compiles Neural Engine model bundles and caches the results in
# directories named com.apple.e5rt.e5bundlecache. The copy belonging to
# mediaanalysisd - the daemon that scans Photos for faces, objects and scenes -
# has a long-standing bug where it grows without ever evicting. In August 2026 it
# reached 17 GB.
#
# Deleting it is safe; macOS regenerates what it needs. The cost is that Photos
# re-analysis runs again afterwards, which means fan noise and battery drain for
# a while. That cost is why this is threshold-based rather than unconditional:
# there's no point paying it to reclaim a few hundred megabytes.
#
# Scheduled by LaunchAgents/dev.benschem.prune-ane-cache.plist. macOS only -
# there is no Neural Engine, and no such cache, on the Linux boxes.

set -u

THRESHOLD_MB=5120            # 5 GB - below this, re-analysis isn't worth it
CACHE_DIR_NAME="com.apple.e5rt.e5bundlecache"
MAX_LOG_BYTES=262144         # 256 KB

if [ "$(uname)" != "Darwin" ]; then
  exit 0
fi

LOG="$HOME/Library/Logs/prune-ane-cache.log"
mkdir -p "$(dirname "$LOG")"

if [ -f "$LOG" ] && [ "$(wc -c < "$LOG")" -gt "$MAX_LOG_BYTES" ]; then
  mv -f "$LOG" "$LOG.old"
fi

exec >> "$LOG" 2>&1
echo "--- $(date '+%Y-%m-%d %H:%M:%S') ---"

# macOS TCC protects app container data. A process without Full Disk Access can
# stat these paths but not traverse them, so `find` below silently omits the
# mediaanalysisd cache - the only one that ever misbehaves - and we'd report a
# confident "under threshold" while several gigabytes sat there. Terminal
# usually has the grant and launchd agents usually don't, so this fails exactly
# when it's running unattended. Detect it and fail loudly instead.
container_data="$HOME/Library/Containers/com.apple.mediaanalysisd/Data"
if [ -d "$container_data" ] && ! ls "$container_data" >/dev/null 2>&1; then
  echo "BLIND: cannot read $container_data (Operation not permitted)."
  echo "This process lacks Full Disk Access, so the mediaanalysisd cache is"
  echo "invisible from here and any size reading below would be wrong."
  echo "Fix: System Settings > Privacy & Security > Full Disk Access, add the"
  echo "program that runs this job. Or run it yourself from a Terminal that has"
  echo "the grant already."
  exit 1
fi

# Collect every copy of the cache. There are several: mediaanalysisd's is the
# one that misbehaves, but the emoji picker and Spotlight keep their own.
caches=()
while IFS= read -r dir; do
  caches+=("$dir")
done < <(find "$HOME/Library" -type d -name "$CACHE_DIR_NAME" 2>/dev/null)

if [ "${#caches[@]}" -eq 0 ]; then
  # Not an error: macOS recreates these lazily, so zero is exactly what you see
  # for a while after a successful clean. Worth noting rather than passing over
  # in silence though - these are Apple-internal paths with no stability
  # guarantee, so if this keeps appearing for weeks while Photos is in use, the
  # likelier explanation is that the cache moved and this script needs updating.
  echo "no directories named $CACHE_DIR_NAME found under ~/Library"
  echo "(normal for a while after a clean - if it persists for weeks, the path"
  echo "has probably changed and this script is looking in the wrong place)"
  exit 0
fi

total_mb=0
for dir in "${caches[@]}"; do
  size_mb=$(du -sm "$dir" 2>/dev/null | cut -f1)
  [ -n "$size_mb" ] || continue
  total_mb=$((total_mb + size_mb))
  echo "  ${size_mb}M  $dir"
done

echo "total ${total_mb}M across ${#caches[@]} cache(s), threshold ${THRESHOLD_MB}M"

if [ "$total_mb" -le "$THRESHOLD_MB" ]; then
  echo "under threshold - leaving alone"
  exit 0
fi

for dir in "${caches[@]}"; do
  # Belt and braces before an rm -rf. Refuse anything that isn't a real
  # directory, isn't named exactly what we're looking for, or somehow sits
  # outside ~/Library. A symlink here would be especially bad news.
  case "$dir" in
    "$HOME"/Library/*) ;;
    *) echo "  REFUSED (outside ~/Library): $dir"; continue ;;
  esac

  if [ "$(basename "$dir")" != "$CACHE_DIR_NAME" ]; then
    echo "  REFUSED (unexpected name): $dir"
    continue
  fi

  if [ -L "$dir" ] || [ ! -d "$dir" ]; then
    echo "  REFUSED (not a real directory): $dir"
    continue
  fi

  rm -rf "$dir" && echo "  cleared $dir"
done

echo "reclaimed ~${total_mb}M. Photos will re-analyse, so expect some fan noise."
echo "free space: $(df -h "$HOME" | tail -1 | awk '{print $4}')"
