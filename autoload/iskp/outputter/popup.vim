let s:save_cpo = &cpo
set cpo&vim


let s:Outputter = {}
let s:Outputter.Name = 'popup'


function! s:Run(ctx) abort
  call iskp#execute_cmd(a:ctx, function('s:new_popup'))
endfunction
let s:Outputter.Run = function('s:Run')


function! s:new_popup(ctx, lines) abort
  if !exists('*popup_atcursor')
    throw 'iskp: popup: require Vim enabled +textprop feature'
  endif
  " FIXME: signwidth is always set 0 because Vim 8.1 does not have
  "        the method in order to know whether |sign| is being displayed.
  let signwidth = 0
  let foldwidth = &foldcolumn
  let numberwidth = &number ? max([&numberwidth, float2nr(ceil(log10(line('$')))) + 1]) : 0
  let col = signwidth + foldwidth + numberwidth + 1
  let popup_opts = {
        \ 'col' : col,
        \ 'title' : a:ctx.word,
        \ 'border' : [],
        \ 'padding' : [0, 1, 0, 1],
        \}
  if get(s:, 'winid', 0) != 0
    call popup_close(s:winid)
  endif
  let s:winid = popup_atcursor(a:lines, popup_opts)
  if s:winid == 0
    throw 'iskp: popup: failed popup_atcursor()'
  endif
  call setbufvar(winbufnr(s:winid), '&filetype', printf('iskp.iskp_%s', a:ctx.filetype))
endfunction


function! iskp#outputter#popup#new() abort
  return deepcopy(s:Outputter)
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
