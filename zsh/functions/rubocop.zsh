# Never call the global rubocop in a rails project by accident again.
rubocop() {
  # Avoid infinite recursion if already inside `bundle exec` or rubocop function
  # Necessary in case I accidently type `be rubocop` or `bundle exec rubocop`
  if [[ "${FUNCNAME[1]}" == "rubocop" ]] || [ -n "$BUNDLER_ORIG_MANPATH" ]; then
    command rubocop "$@"
    return $?
  fi

  # If in a Bundler-aware project, use the Bundler-installed RuboCop
  if [ -f Gemfile ]; then
    if bundle show rubocop >/dev/null 2>&1; then
      [[ -t 1 ]] && echo "⚠️ You forgot to prepend \`bundle exec\` - doing it for you."
      command bundle exec rubocop "$@"
    else
      [[ -t 1 ]] && echo "⚠️ Rubocop is not in your Gemfile. Falling back to global rubocop."
      command rubocop "$@"
    fi
  else
    command rubocop "$@"
  fi
}
