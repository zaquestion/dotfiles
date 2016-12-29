if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1

setlocal formatoptions-=t

setlocal comments=s1:/*,mb:*,ex:*/,://
setlocal commentstring=//\ %s

setlocal lazyredraw

nnoremap <CR> :GoDef<CR>

let b:undo_ftplugin = "setl fo< com< cms<"

let g:syntastic_go_checkers = ['golint', 'govet', 'errcheck']
let g:syntastic_mode_map = { 'mode': 'active', 'passive_filetypes': ['go'] }
