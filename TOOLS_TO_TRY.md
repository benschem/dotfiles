# Terminal tools to try

A backlog, not a plan. The goal is spending less time in VS Code, so these are
ordered by how much they move that needle per hour spent learning them. Try one
at a time.

Already set up: delta as the pager, lazygit with a side-by-side toggle, vimdiff
as the difftool, histogram diffs and move colouring.

## Loose ends

**Verify the server vim.** The `diffopt` line in `.vimrc` is silenced, so on a
vim built without the internal diff it does nothing rather than erroring. On the
server:

    vim -Nes -u ~/.vimrc -c 'redir! > /tmp/d.txt' -c 'silent set diffopt?' -c 'redir END' -c 'qa!' < /dev/null; cat /tmp/d.txt

If the output lacks `internal`, install `vim-nox` instead of `vim`.

**Enable rerere.** One line in `.gitconfig`, nothing to install:

    [rerere]
      enabled = true

Git records how a conflict was resolved and replays it when the same conflict
reappears. With `pull.rebase` and repeated rebases, the same conflicts come back
constantly.

## Next

**Ghostty splits.** No install. `cmd+d`, lazygit one side, vim the other. That's
the VS Code layout — persistent file list, edit alongside. Try this before
installing anything, it might be the whole answer.

**vim-fugitive.** Not a plugin manager job — vim 9 loads packages natively:

    git clone https://github.com/tpope/vim-fugitive ~/.vim/pack/plugins/start/vim-fugitive

`:Gdiffsplit` is the two-pane editable diff *inside* the editor, with buffers and
undo intact — what `difftool` only approximates. `:Git` is a status buffer you
stage from. Works in neovim too, so it isn't a bet on staying with vim.

**fzf.** `brew install fzf`

Fuzzy finder that composes with everything. `ctrl+r` becomes searchable history
instead of a linear scroll, `ctrl+t` inserts file paths into any command, and it
pipes into git for picking commits, branches and files. Biggest reduction in
typing paths from memory, which is much of what makes an editor feel faster.

**tig.** `brew install tig`

The history browser lazygit isn't. `tig` for the log graph, `tig blame` for
who-changed-this, `tig status` for a quick look. Vim keys, learns in ten minutes.

## Then

**diffnav.** `brew install dlvhdr/formulae/diffnav`

Pipe a diff in, get a file tree on the left and the delta-rendered diff on the
right. `git diff | diffnav`, `gh pr diff 42 | diffnav`. Reading only.

**git-absorb.** `brew install git-absorb`

Works out which of your unstaged fixes belongs to which earlier commit and stages
them as `fixup!` commits, ready for `git rebase -i --autosquash`.

**gh-dash.** `brew install gh-dash`

TUI over `gh` — PRs, issues, check status, review state. Removes most reasons to
open a browser.

## Consider later

**difftastic.** `brew install difftastic`

Structural diff: parses the language and diffs the syntax tree, so reformatting
shows as no change. Complements delta rather than replacing it — reach for it
when a diff is drowning in noise. `git -c diff.external=difft diff`.

**neovim, with diffview.nvim and gitsigns.nvim.** The only real reasons to
switch: diffview is the actual Ctrl+Shift+G analogue (persistent file panel plus
diff, and a file-history mode), and gitsigns puts change markers in the gutter
with hunk staging in the buffer. Both are Lua, so neither exists for vim.
Deferred until fugitive shows whether the file panel is genuinely missed.

**jujutsu (jj).** A different VCS using git repos as its backend. Better model —
no staging area, everything is a commit, undo works. Also a whole new mental
model, so not while still learning terminal git.
