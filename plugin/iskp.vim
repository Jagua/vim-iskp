if exists('g:loaded_iskp')
  finish
endif
let g:loaded_iskp = 1


let s:save_cpo = &cpo
set cpo&vim


augroup iskp-event
  autocmd!
  autocmd FileType * call iskp#on_FileType()
augroup END


command! -nargs=* -range -complete=customlist,iskp#complete Iskp call iskp#command(<q-args>)


nnoremap <silent> <Plug>(iskp) :<C-u>call iskp#run('default', {'mode' : 'n'})<CR>
vnoremap <silent> <Plug>(iskp) :<C-u>call iskp#run('default', {'mode' : 'v'})<CR>


let &cpo = s:save_cpo
unlet s:save_cpo
