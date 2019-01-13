let s:save_cpo = &cpo
set cpo&vim


let s:Outputter = {}
let s:Outputter.Name = 'terminal'


function! s:Run(ctx, ...) abort dict
  if !has('timers')
    echoerr 'iskp: require Vim enabled +timers feature'
  endif
  let l:Rewind = {ch -> execute([
        \ 'if has("nvim")',
        \ '  return',
        \ 'elseif exists("*term_wait") && exists("*ch_getbufnr")',
        \ '  call term_wait(ch_getbufnr(ch, "out"))',
        \ '  1',
        \ '  redraw',
        \ 'elseif has("timers")',
        \ '  call timer_start(250, {ctx -> execute(["1", "redraw"])})',
        \ 'endif',
        \], '')}
  let self.buf = s:term(a:ctx.cmdlns, {
        \ 'term_name' : iskp#get_bufname(a:ctx),
        \ 'exit_cb' : l:Rewind,
        \})
  return {
        \ 'buf' : self.buf,
        \ 'Wait' : function('s:Wait'),
        \}
endfunction
let s:Outputter.Run = function('s:Run')
let s:Outputter.buf = 0


function! s:Wait(opt) abort dict
  if has('nvim')
    echoerr 'iskp: outputter/terminal: s:Wait() does not work in Nvim'
  endif
  let timeout_default = 5000
  let timeout = get(a:opt, 'timeout', timeout_default)
  let buf = self.buf
  if empty(buf)
    return {'buf' : 0}
  endif
  let ctr = timeout / 50
  while empty(filter(split(term_getstatus(buf), ','), 'v:val ==# "finished"'))
        \ && ctr >= 0
    sleep 50m
    let ctr -= 1
  endwhile
  if ctr < 0
    call job_stop(term_getjob(buf))
  endif

  return {'buf' : buf}
endfunction


function! s:term(cmd, term_opts) abort
  if has('terminal')
    return term_start(a:cmd, a:term_opts)
  elseif has('nvim') && exists('*termopen')
    new
    return termopen(a:cmd, a:term_opts)
  else
    echoerr 'iskp: require Vim enabled +terminal feature'
  endif
endfunction


function! iskp#outputter#terminal#new() abort
  return deepcopy(s:Outputter)
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
