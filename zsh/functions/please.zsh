## Rerun the last command with sudo
function please {
  sudo $(fc -ln -1)
  # fc -ln -1 outputs the last command exactly as typed
}
