set nocompatible

set tabstop=4
set shiftwidth=4
set autoindent
set nowrap

set number
set showmode
set ruler
set showcmd
set incsearch
set hlsearch

syntax on
filetype plugin on

set ignorecase
set infercase
set omnifunc=syntaxcomplete#Complete

colorscheme base16-railscasts
highlight CursorLine cterm=None ctermbg=55 ctermfg=None
autocmd InsertEnter * set cursorline 
autocmd InsertLeave * set nocursorline 
inoremap <c-c> <c-c>:set nocursorline<cr>
nnoremap <c-h> :noh<cr>

hi clear SpellBad
hi SpellBad cterm=underline ctermbg=None ctermfg=red
