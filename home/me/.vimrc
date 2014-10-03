set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Bundle 'Shougo/neocomplete'
Bundle 'Shougo/neosnippet'
Bundle 'Shougo/neosnippet-snippets'
Plugin 'fatih/vim-go'

call vundle#end()
filetype plugin indent on

syntax on

set relativenumber
set number

"Keybinding
map <C-h> <C-w>h
map <C-j> <C-w>j
map <C-k> <C-w>k
map <C-l> <C-w>l

"map <C-H> <C-w>H
"map <C-J> <C-w>J
"map <C-K> <C-w>K
"map <C-L> <C-w>L
