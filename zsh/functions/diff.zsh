# Use bat with diff for syntax highlighting if available
diff() {
  if command -v bat >/dev/null 2>&1; then
    command diff -u "$@" | bat --language=diff --style=plain --paging=never --theme=GitHub
  else
    command diff -u "$@"
    echo "" >&2
    echo "# 'bat' not found. Run: 'brew install bat' for a colored diff" >&2
  fi
}
