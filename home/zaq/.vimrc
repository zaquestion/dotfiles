set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Bundle 'rking/ag.vim'
"Bundle 'Shougo/neocomplete'
"Bundle 'Shougo/neosnippet'
"Bundle 'Shougo/neosnippet-snippets'
Plugin 'nsf/gocode', {'rtp': 'vim/'}

call vundle#end()
filetype plugin indent on

noremap <C-\> :exec 'Ag!' expand('<cword>') $projects<CR>

syntax on

set relativenumber
set number

"remove awful omnicomplete scratch preview
set completeopt-=preview

"shows matching ({[]})
set showmatch

"allows case insensitive searching with smart exceptions
set ignorecase
set smartcase

"Keybinding hotkeys for switching windows
map <C-h> <C-w>h
map <C-j> <C-w>j
map <C-k> <C-w>k
map <C-l> <C-w>l

"map <C-H> <C-w>H
"map <C-J> <C-w>J
"map <C-K> <C-w>K
"map <C-L> <C-w>L

"ctags config

"tagbar gotags config
set rtp+=$projects/tagbar
nmap <F8> :TagbarToggle<CR>


let g:tagbar_type_go = { 
    \ 'ctagstype' : 'go',
    \ 'kinds'     : [ 
        \ 'p:package',
        \ 'i:imports:1',
        \ 'c:constants',
        \ 'v:variables',
        \ 't:types',
        \ 'n:interfaces',
        \ 'w:fields',
        \ 'e:embedded',
        \ 'm:methods',
        \ 'r:constructor',
        \ 'f:functions'
    \ ],
    \ 'sro' : '.',
    \ 'kind2scope' : { 
        \ 't' : 'ctype',
        \ 'n' : 'ntype'
    \ },
    \ 'scope2kind' : { 
        \ 'ctype' : 't',
        \ 'ntype' : 'n' 
    \ },
    \ 'ctagsbin'  : 'gotags',
    \ 'ctagsargs' : '-sort -silent'
    \ }
