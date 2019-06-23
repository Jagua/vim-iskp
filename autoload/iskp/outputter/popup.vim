let s:save_cpo = &cpo
set cpo&vim


let s:Outputter = {}
let s:Outputter.Name = 'popup'


function! s:Run(ctx) abort
  if !exists('*popup_atcursor') || !has('job') || !get(a:ctx, 'job', 1)
    throw 'iskp: require Vim enabled +textprop and +job feature'
  endif
  return job_start(a:ctx.cmdlns, {
        \ 'close_cb' : function('s:close_cb', [a:ctx]),
        \})
endfunction
let s:Outputter.Run = function('s:Run')


function! s:close_cb(ctx, ch) abort
  call s:popup(a:ctx.word, s:content(a:ch), a:ctx.filetype)
endfunction


function! s:content(ch) abort
  let lines = []
  while ch_status(a:ch, {'part' : 'out'}) ==# 'buffered'
    call add(lines, ch_read(a:ch))
  endwhile
  return iskp#strip_lines(lines)
endfunction


function! s:popup(title, content, filetype) abort
  " FIXME: signwidth is always set 0 because Vim 8.1 does not have
  "        the method in order to know whether |sign| is being displayed.
  let signwidth = 0
  let foldwidth = &foldcolumn
  let numberwidth = &number ? max([&numberwidth, float2nr(ceil(log10(line('$')))) + 1]) : 0
  let col = signwidth + foldwidth + numberwidth + 1
  let popup_opts = {
        \ 'col' : col,
        \ 'title' : a:title,
        \ 'border' : [],
        \ 'padding' : [0, 1, 0, 1],
        \}
  if get(s:, 'winid', 0) != 0
    call popup_close(s:winid)
  endif
  let s:winid = popup_atcursor(a:content, popup_opts)
  if s:winid == 0
    throw 'iskp: failed popup_atcursor()'
  endif
  call setbufvar(winbufnr(s:winid), '&filetype', printf('iskp.iskp_%s', a:filetype))
endfunction


function! iskp#outputter#popup#new() abort
  return deepcopy(s:Outputter)
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
