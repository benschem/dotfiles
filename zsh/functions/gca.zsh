# gca & gcan TODO:/FIXIT:
# Edge cases:
# - If the branch has no commits or a shallow history, merge-base might behave unexpectedly.
# - If the reflog is cleared or expired, HEAD@{1} might be missing.

# Wrapper for git commit --amend with push safety checks
gca() {
  local use_no_edit=false

  # Check if gcan called this with --no-edit
  [[ "$1" == "--no-edit" ]] && {
    use_no_edit=true
    shift  # Remove --no-edit from args
  }

  # Build the amend command
  local amend_cmd=(git commit --amend)
  $use_no_edit && amend_cmd+=(--no-edit)

  # Run the amend command
  if ! "${amend_cmd[@]}"; then
    echo "[ERROR] Amend failed. Aborting push safety check." >&2
    return 1
  fi

  # Get current branch and upstream (if any)
  local current_branch
  current_branch=$(git symbolic-ref --short HEAD 2>/dev/null)

  local upstream
  upstream=$(git rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>/dev/null)

  if [[ -n "$upstream" ]]; then
    # Get base and SHA values for push-safety check
    local merge_base upstream_sha head_sha
    merge_base=$(git merge-base HEAD "$upstream")
    upstream_sha=$(git rev-parse "$upstream")
    head_sha=$(git rev-parse HEAD)

    # If the upstream SHA isn't an ancestor of HEAD, history was rewritten
    if [[ "$merge_base" != "$upstream_sha" ]]; then
      echo "[WARN] HEAD is not a descendant of $upstream"
      echo "       You may have rewritten published history!"
      echo "       - Undo amend and commit separately:    git reset --soft HEAD@{1}^ && gc"
      echo "       - OR force push the new history:       gpf"
    else
      echo "[INFO] Amended commit not yet pushed. Safe to push."
      echo "       - Use:   gp"
    fi
  else
    # No upstream configured
    echo "[WARN] No upstream set for '$current_branch'."
    echo "       - Set upstream:                  gup"
    echo "       - Pull with rebase:              gpl"
    echo "       - Push safely or force push:     gp OR gpf"
  fi
}

# Variant for git commit --amend --no-edit
gcan() {
  gca --no-edit "$@"
}
