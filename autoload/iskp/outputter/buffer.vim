let s:save_cpo = &cpo
set cpo&vim


let s:Outputter = {}
let s:Outputter.Name = 'buffer'


function! s:Run(ctx) abort
  if has('job') && get(a:ctx, 'job', 1)
    return job_start(a:ctx.cmdlns, {
          \ 'out_mode' : 'raw',
          \ 'close_cb' : function('s:close_cb', [a:ctx]),
          \})
  else
    let lines = systemlist(a:ctx.cmdln)
    return iskp#new_buffer(lines, a:ctx)
  endif
endfunction
let s:Outputter.Run = function('s:Run')


function! s:close_cb(ctx, ch) abort
  let msg = ''
  while ch_canread(a:ch) && ch_status(a:ch) ==# 'buffered'
    let msg .= ch_readraw(a:ch)
  endwhile
  let lines = split(msg, '\n')
  return iskp#new_buffer(lines, a:ctx)
endfunction


function! iskp#outputter#buffer#new() abort
  return deepcopy(s:Outputter)
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
