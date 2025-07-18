# Run commands in the exact security and environment context of the file's user owner
asowner() {
  if [ ! -e "$1" ]; then
    echo "File '$1' does not exist" >&2
    return 1
  fi

  if stat --version >/dev/null 2>&1; then
    # GNU stat (Linux)
    owner=$(stat -c '%U' "$1")
  else
    # BSD stat (macOS)
    owner=$(stat -f '%Su' "$1")
  fi

  if [ -z "$owner" ]; then
    echo "Could not determine owner of '$1'" >&2
    return 1
  fi

  sudo -u "$owner" "${@:2}"
}
