setlocal lazyredraw
let g:syntastic_go_checkers = ['golint', 'govet', 'errcheck']
let g:syntastic_mode_map = { 'mode': 'active', 'passive_filetypes': ['go'] }

" Set go guru scope to current Git repo root... Update ad-hoc with :GoGuruScope if needing to include code outside of repo root.
"let root_module = system("ABS=$(git rev-parse --show-toplevel); (cd $ABS && echo -n $(grep module go.mod | cut -d' ' -f2-))")
"let g:go_guru_scope = [root_module]

nnoremap <leader>b :GoBuild<CR>
nnoremap <leader>t :GoTest<CR>
nnoremap <leader><leader>t :GoTestFunc<CR>
nnoremap <leader>r :call LanguageClient#textDocument_references()<CR>
nnoremap <leader>p :GoChannelPeers<CR>
nnoremap <leader>m :GoImplements<CR>
nnoremap <leader>i :GoInfo<CR>
nnoremap <leader>d :GoDoc<CR>

set shiftwidth=8
