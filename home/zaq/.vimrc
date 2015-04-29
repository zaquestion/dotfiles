set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" let Vundle manage Vundle, required
Plugin 'gmarik/Vundle.vim'

Plugin 'Valloric/YouCompleteMe'
Plugin 'sirver/ultisnips'
Plugin 'honza/vim-snippets'

Plugin 'marijnh/tern_for_vim'
Plugin 'fatih/vim-go'

Plugin 'majutsushi/tagbar'
Plugin 'rking/ag.vim'

Plugin 'zaqthefreshman/vim-monokai'
Plugin 'tmhedberg/SimpylFold'

Plugin 'terryma/vim-multiple-cursors'

Plugin 'tpope/vim-fugitive'

call vundle#end()

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

"remove trailing whitespace on save
autocmd BufWritePre * :%s/\s\+$//e

colorscheme monokai

set relativenumber
set number

"remove awful omnicomplete scratch preview
set completeopt-=preview

"shows matching ({[]})
set showmatch

"allows case insensitive searching with smart exceptions
set ignorecase
set smartcase

"do highlighting on search and macro do clear search
set hlsearch
nnoremap <CR> :noh<CR>

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
function! UpdateTags()
  	silent! !~/scripts/update-tags.sh %:p:h %:t &
	redraw!
endfunction
autocmd BufWritePost * :call UpdateTags()
set tags=$projects/tags
nmap <F8> :TagbarToggle<CR>

" Trigger configuration. Do not use <tab> if you use https://github.com/Valloric/YouCompleteMe.
let g:UltiSnipsExpandTrigger="<c-l>"
let g:UltiSnipsJumpForwardTrigger="<c-b>"
let g:UltiSnipsJumpBackwardTrigger="<c-z>"
