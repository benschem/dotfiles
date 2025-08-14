whatchanged() {
  local branch

  # If argument given, compare to that branch, otherwise use master or main
  if [[ -n $1 ]]; then
    branch=$1
  else
    branch=$(git symbolic-ref --quiet refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
    [[ -z $branch ]] && branch=master
  fi

  echo "=== Committed changes (current branch vs $branch) ==="
  git diff --stat --color "$branch..."

  echo
  echo "=== Staged changes ==="
  git diff --stat --cached --color

  echo
  echo "=== Unstaged changes ==="
  git diff --stat --color

  echo
  echo "=== Untracked files ==="
  git ls-files --others --exclude-standard
}

