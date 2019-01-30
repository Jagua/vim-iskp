let s:save_cpo = &cpo
set cpo&vim


let s:Outputter = {}
let s:Outputter.Name = 'preview'


function! s:Run(ctx) abort
  if has('job') && get(a:ctx, 'job', 1)
    return job_start(a:ctx.cmdlns, {
          \ 'out_mode' : 'raw',
          \ 'close_cb' : function('s:close_cb', [a:ctx]),
          \})
  else
    let lines = systemlist(a:ctx.cmdln)
    return iskp#new_preview(lines, a:ctx)
  endif
endfunction
let s:Outputter.Run = function('s:Run')


function! s:close_cb(ctx, ch) abort
  let msg = ''
  while ch_canread(a:ch) && ch_status(a:ch) ==# 'buffered'
    let msg .= ch_readraw(a:ch)
  endwhile
  let lines = split(msg, '\n')
  return iskp#new_preview(lines, a:ctx)
endfunction


if has('nvim')
  function! s:Run(ctx) abort
    if exists('*jobstart')
      return jobstart(a:ctx.cmdlns, {
            \ '_chunks' : [''],
            \ 'on_stdout' : function('s:on_stdout'),
            \ 'on_exit' : function('s:on_exit', [a:ctx]),
            \})
    else
      let lines = systemlist(a:ctx.cmdln)
      return iskp#new_preview(lines, a:ctx)
    endif
  endfunction
  let s:Outputter.Run = function('s:Run')


  function! s:on_stdout(job_id, data, event) abort dict
    let self._chunks[-1] .= a:data[0]
    call extend(self._chunks, a:data[1:])
  endfunction


  function! s:on_exit(ctx, job_id, data, event) abort dict
    return iskp#new_preview(self._chunks, a:ctx)
  endfunction
endif


function! iskp#outputter#preview#new() abort
  return deepcopy(s:Outputter)
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
