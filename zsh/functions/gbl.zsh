## Nicer `git branch --list` output by calling the shorthand `gbl`
gbl() {
  # Set variables
  local shorthead localhead upstream_branch prefix

  shorthead=$(git symbolic-ref --short HEAD 2>/dev/null)
  localhead=$(git symbolic-ref HEAD 2>/dev/null)

  # Print HEAD info
  echo -e "\033[1;4mHead:\033[0m"
  printf "    \033[1;36m%s\033[0m → \033[1;36m%s\033[0m → \033[1;32m%s\033[0m\n" ".git/HEAD" "$localhead" "$shorthead"
  echo ""

  # Print local branches with tracking
  echo -e "\033[1;4mLocal branches:\033[0m"
  for branch in $(git for-each-ref --format="%(refname:short)" refs/heads); do
    [[ "$branch" == "$shorthead" ]] && prefix="*" || prefix=" "

    upstream_branch=$(git for-each-ref --format="%(upstream:short)" refs/heads/"$branch")
    if [[ -n $upstream_branch ]]; then
      if [[ "$branch" == "$shorthead" ]]; then
        printf "  \033[1;32m%s %-20s\033[0m → \033[1;15m%s\033[0m\n" "$prefix" "$branch" "$upstream_branch"
      else
        printf "  \033[0;37m%s %-20s\033[0m → \033[1;15m%s\033[0m\n" "$prefix" "$branch" "$upstream_branch"
      fi
    else
      if [[ "$branch" == "$shorthead" ]]; then
        printf "   \033[1;32m%s %-20s\033[0m →\n" "$prefix" "$branch"
      else
        printf "   \033[0;37m%s %-20s\033[0m →\n" "$prefix" "$branch"
      fi
    fi
  done
  echo ""

  # Print warning if no upstream remote set
  if ! git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
    echo -e "\033[1;31m[WARN] No upstream remote set for current branch '\033[1;32m$shorthead\033[1;31m'\033[0m"
    echo -e "\033[1;34m[INFO] Run git push --set-upstream origin $shorthead to set the upstream remote for this branch\033[0m"
    echo ""
  fi

  # Print remote branches
  echo -e "\033[1;4mRemote branches:\033[0m"
  git branch -r --color=never | while read -r line; do
    printf "    \033[1;33m%s\033[0m\n" "$line"
  done
}
