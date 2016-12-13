set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

Plugin 'Valloric/YouCompleteMe'
Plugin 'sirver/ultisnips'
Plugin 'honza/vim-snippets'

Plugin 'fatih/vim-go'

Plugin 'majutsushi/tagbar'
Plugin 'rking/ag.vim'

Plugin 'zaquestion/vim-monokai'
Plugin 'tmhedberg/SimpylFold'

Plugin 'terryma/vim-multiple-cursors'

Plugin 'tpope/vim-fugitive'
Plugin 'solars/github-vim'
Plugin 'christoomey/vim-system-copy'

Plugin 'scrooloose/syntastic'

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

let g:ag_prg="ag --ignore-dir Godeps --vimgrep --smart-case"
noremap <C-\> :exec 'Ag!' expand('<cword>') $projects<CR>

"remove trailing whitespace on save
autocmd BufWritePre * :%s/\s\+$//e

autocmd BufNewFile,BufRead *.diag set filetype=diag
autocmd BufNewFile,BufRead *.gv set filetype=graphviz

colorscheme monokai

set splitbelow
set splitright

set relativenumber
set number

" Remove awful omnicomplete scratch preview
set completeopt-=preview

" Shows matching ({[]})
set showmatch

" Allows case insensitive searching with smart exceptions
set ignorecase
set smartcase

" Path completion
set wildmode=longest,list
set wildmenu

" Do highlighting on search and macro do clear search
set hlsearch
nnoremap <CR> :let @/ = ""<CR>

set pastetoggle=<F2>

" Keybinding hotkeys for switching windows
map <C-h> <C-w>h
map <C-j> <C-w>j
map <C-k> <C-w>k
map <C-l> <C-w>l

" Leader config
let mapleader=","

" ctags config
function! UpdateTags()
  	silent! !~/scripts/update-tags.sh %:p:h %:t &
	redraw!
endfunction
autocmd BufWritePost * :call UpdateTags()
set tags=$projects/tags
nmap <F8> :TagbarToggle<CR>

" Trigger configuration. Do not use <tab> if you use https://github.com/Valloric/YouCompleteMe.
let g:UltiSnipsExpandTrigger="<c-l>"
let g:UltiSnipsJumpForwardTrigger="<c-m>"
let g:UltiSnipsJumpBackwardTrigger="<c-b>"

let g:netrw_liststyle=3
let g:netrw_bufsettings = 'noma nomod nu nobl nowrap ro'

:tnoremap <Esc> <C-\><C-n>
let g:terminal_scrollback_buffer_size = 2147483647
