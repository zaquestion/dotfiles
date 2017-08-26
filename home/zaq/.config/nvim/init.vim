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
Plugin 'mileszs/ack.vim'

Plugin 'zaquestion/vim-monokai'
Plugin 'tmhedberg/SimpylFold'

Plugin 'tpope/vim-fugitive'

Plugin 'scrooloose/syntastic'
Plugin 'Chiel92/vim-autoformat'
Plugin 'godlygeek/tabular'

call vundle#end()

set timeoutlen=1000 ttimeoutlen=10

" Some Linux distributions set filetype in /etc/vimrc.
" Clear filetype flags before changing runtimepath to force Vim to reload them.
if exists("g:did_load_filetypes")
	filetype off
	filetype plugin indent off
endif
set rtp+=/usr/local/go/misc/vim " replace $GOROOT with the output of: go env GOROOT
filetype plugin indent on
syntax on

if executable('ag')
	let g:ackprg = 'ag --ignore-dir vendor --vimgrep --smart-case'
endif
let g:ackhighlight = 1

" use Ag instead of Ack when typing
cnoreabbrev ag Ack
cnoreabbrev Ag Ack

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
set ignorecase
set smartcase

" Path completion
set wildmode=longest,list
set wildmenu

" Do highlighting on search and macro do clear search
set hlsearch
nnoremap <leader><CR> :noh

set pastetoggle=<F2>

" Keybinding hotkeys for switching windows
map <C-h> <C-w>h
map <C-j> <C-w>j
map <C-k> <C-w>k
map <C-l> <C-w>l

map + <C-w>+
map - <C-w>-

" Leader config
let mapleader=","
map <leader>e :e <C-R>=expand("%:p:h") . "/" <CR>

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

tnoremap <Esc> <C-\><C-n>
let g:terminal_scrollback_buffer_size = 2147483647

let g:formatters_python = ['yapf']
let g:formatdef_yapf = "'yapf --style=\"{based_on_style: pep8, indent_width: 4, join_multiple_lines: true, SPACE_BETWEEN_ENDING_COMMA_AND_CLOSING_BRACKET: false, COALESCE_BRACKETS: true, DEDENT_CLOSING_BRACKETS: true, COLUMN_LIMIT: 120}\" -l '.a:firstline.'-'.a:lastline"
