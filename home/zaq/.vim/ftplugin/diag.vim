command! Firefox call OpenInFireFox()

function! OpenInFireFox()
	let path=expand("%:p")
	let file=expand("%:t")
	let svgname=split(l:file, '\.')[0].".svg"
  	execute 'silent! !firefox '.l:svgname
	redraw!
endfunction

function! RenderSeqSvg()
	let path=expand("%:p")
	let file=expand("%:t")
	let svgname=split(l:file, '\.')[0].".svg"
  	execute "silent! !seqdiag -T SVG ".l:path." -o ".l:svgname
	redraw!
endfunction
autocmd BufWritePost * :call RenderSeqSvg()
