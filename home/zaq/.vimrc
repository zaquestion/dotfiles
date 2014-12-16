set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'fatih/vim-go'
Plugin 'rking/ag.vim'
Plugin 'Valloric/YouCompleteMe'

call vundle#end()
filetype plugin indent on

" Some Linux distributions set filetype in /etc/vimrc.
" Clear filetype flags before changing runtimepath to force Vim to reload them.
if exists("g:did_load_filetypes")
	filetype off
	filetype plugin indent off
endif
set rtp+=/usr/local/go/misc/vim " replace $GOROOT with the output of: go env GOROOT
filetype plugin indent on
syntax on
noremap <C-\> :exec 'Ag!' expand('<cword>') $projects<CR>

syntax on

autocmd BufWritePre * :%s/\s\+$//e

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
