setlocal lazyredraw
setlocal shiftwidth=8

" vim-go is gone; drive Go via gopls (LSP) + telescope + plain go commands.
nnoremap <buffer> <leader>b :!go build ./...<CR>
nnoremap <buffer> <leader>t :!go test ./...<CR>
nnoremap <buffer> <leader>r <cmd>Telescope lsp_references<CR>
nnoremap <buffer> <leader>m <cmd>Telescope lsp_implementations<CR>
nnoremap <buffer> <leader>i <cmd>lua vim.lsp.buf.hover()<CR>

" debug the nearest Go test via nvim-dap-go (delve)
nnoremap <buffer> <leader>dt <cmd>lua require('dap-go').debug_test()<CR>
