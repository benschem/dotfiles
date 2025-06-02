" Lean and minimal vim setup - I only really use it on servers

" Just in case
set encoding=utf-8

" Persistant undo - undo changes even after closing and reopening a file
if !isdirectory(expand("~/.vim/undodir"))
  call mkdir(expand("~/.vim/undodir"), "p")
endif

if has('persistent_undo')
  set undofile
  set undodir=~/.vim/undodir
endif

" Prevents Vim from cluttering directories
set noswapfile
set nobackup
set nowritebackup

if &compatible
  " Vim defaults to `compatible` when selecting a vimrc with the command-line `-u` argument. Override this.
  set nocompatible
endif

" Enable synatx highlighting
syntax on

" Show line numbers
set number

" Always show a simple status bar
set laststatus=2

" Highlight matching brace
set showmatch

" Use spaces instead of tab
set expandtab

" Default to tabs 2 spaces wide
set tabstop=2
set softtabstop=2
set shiftwidth=2

" Autodetect indentation
filetype plugin indent on

" Use search highlighting and incremental search
set hlsearch
set incsearch

" Set netrw folder view to tree view
let g:netrw_liststyle = 3

" Keep a margin of lines visible around the cursor, making movement more readable
set scrolloff=3
set sidescrolloff=5

" Make trailing whitespace and tabs visible
set list
set listchars=tab:▸\ ,trail:·

colorscheme pablo
