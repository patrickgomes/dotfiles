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
set mouse=""

set ignorecase
set infercase

syntax on
filetype plugin on

" Always show powerlevel9k statusline
set laststatus=2

nmap <c-h> :noh<cr>
hi clear SpellBad

" For clever completion with the :find command
set path=/usr/include/**,./**

" Load plugins with pathogen
execute pathogen#infect()

" --------- Keybinddings --------- 
let mapleader = "!"

" Find references to identifier under the cursor
nnoremap <leader>r yiw:Ack <c-r>"<cr>

" Save and execute script
nmap <F2> :w<cr>:! bash %<cr>

" Save and debug script
nmap <F3> :w<cr>:! bash -x %<cr>
