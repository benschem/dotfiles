# Never call the global rubocop in a rails project by accident again.
rubocop() {
  # Avoid infinite recursion if already inside `bundle exec` or rubocop function
  # Necessary in case I accidently type `be rubocop` or `bundle exec rubocop`
  if [[ "${FUNCNAME[1]}" == "rubocop" ]] || [ -n "$BUNDLER_ORIG_MANPATH" ]; then
    command rubocop "$@"
    return
  fi

  # If in a Bundler-aware project, use the Bundler-installed RuboCop
  if [ -f Gemfile ]; then
    echo "You forgot to prepend `bundle exec` - doing it for you."
    command bundle exec rubocop "$@"
  else
    command rubocop "$@"
  fi
}

