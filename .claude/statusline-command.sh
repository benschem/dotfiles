#!/usr/bin/env bash
input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
input_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
output_tokens=$(echo "$input" | jq -r '.context_window.total_output_tokens // empty')
window_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')

# Shorten home directory to ~
home="$HOME"
short_cwd="${cwd/#$home/~}"

# Git branch (skip optional locks)
git_branch=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    git_branch="$branch"
  fi
fi

# Format token count (e.g. 12345 -> 12.3k, 1234567 -> 1.2M)
format_tokens() {
  local n=$1
  if [ -z "$n" ] || [ "$n" = "null" ] || [ -z "$n" ]; then echo ""; return; fi
  if [ "$n" -ge 1000000 ]; then
    printf '%.1fM' "$(echo "$n / 1000000" | bc -l)"
  elif [ "$n" -ge 1000 ]; then
    printf '%.1fk' "$(echo "$n / 1000" | bc -l)"
  else
    echo "$n"
  fi
}

# Context + tokens
ctx=""
if [ -n "$used_pct" ] && [ "$used_pct" != "null" ]; then
  total_tokens=""
  if [ -n "$input_tokens" ] && [ "$input_tokens" != "null" ] && [ -n "$output_tokens" ] && [ "$output_tokens" != "null" ]; then
    total_tokens=$(( input_tokens + output_tokens ))
  fi
  t_used=$(format_tokens "$total_tokens")
  t_max=$(format_tokens "$window_size")
  if [ -n "$t_used" ] && [ -n "$t_max" ]; then
    ctx="${t_used}/${t_max} (${used_pct}%)"
  else
    ctx="${used_pct}%"
  fi
fi

# Brighter colors: normal intensity, subtle hues
# 90=gray, 36=cyan, 35=magenta, 33=yellow
pipe="\033[90m | \033[0m"
parts=()
[ -n "$short_cwd" ] && parts+=("\033[36m${short_cwd}\033[0m")
[ -n "$git_branch" ] && parts+=("\033[35m${git_branch}\033[0m")
[ -n "$model" ] && parts+=("\033[33m${model}\033[0m")
[ -n "$ctx" ] && parts+=("\033[90m${ctx}\033[0m")

# Join with pipes
result=""
for i in "${!parts[@]}"; do
  if [ "$i" -gt 0 ]; then
    result+="$pipe"
  fi
  result+="${parts[$i]}"
done

printf "%b" "$result"
