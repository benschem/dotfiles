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

" silent! because Apple's vim has no internal diff - there the line no-ops
silent! set diffopt+=internal,algorithm:histogram,indent-heuristic,linematch:60

" $COLORTERM is unset on plain terminals and over some SSH sessions, where the
" ctermbg fallbacks below apply instead.
if has('termguicolors') && $COLORTERM =~# '^\%(truecolor\|24bit\)$'
  set termguicolors
endif

colorscheme embark

" Same colours as delta as themes can be too hard to read.
" DiffText is the changed span within a DiffChange line.
highlight DiffAdd    guibg=#12341a ctermbg=22
highlight DiffDelete guibg=#3a1a1a guifg=#6e2727 ctermbg=52 ctermfg=88
highlight DiffChange guibg=#1f2a3a ctermbg=17
highlight DiffText   guibg=#2d4a6b ctermbg=24
