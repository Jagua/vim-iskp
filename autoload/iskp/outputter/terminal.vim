let s:save_cpo = &cpo
set cpo&vim


let s:Outputter = {}
let s:Outputter.Name = 'terminal'


function! s:Run(ctx) abort dict
  let resp = s:term(a:ctx.cmdlns, {
        \ 'term_name' : iskp#get_bufname(a:ctx),
        \ 'exit_cb' : function('s:exit_cb'),
        \})
  return {'Wait' : function('s:Wait', [], resp)}
endfunction
let s:Outputter.Run = function('s:Run')


function! s:Wait(...) abort dict
  let timeout_default = 5000
  let timeout = get(get(a:, '1', {}), 'timeout', timeout_default)
  if !has('nvim')
    return call(funcref('s:wait_on_vim'), [timeout], self)
  else
    return call(funcref('s:wait_on_neovim'), [timeout], self)
  endif
endfunction


function! s:wait_on_vim(timeout) abort dict
  if empty(self.bufnr)
    return {'buf' : 0}
  endif
  let ctr = a:timeout / 50
  while empty(filter(split(term_getstatus(self.bufnr), ','), 'v:val ==# "finished"'))
        \ && ctr >= 0
    sleep 50m
    let ctr -= 1
  endwhile
  if ctr < 0
    call job_stop(term_getjob(self.bufnr))
  endif
  return {'buf' : self.bufnr}
endfunction


function! s:wait_on_neovim(timeout) abort dict
  if self.job_id == 0
    return {'buf' : 0}
  endif
  while jobwait([self.job_id], a:timeout)[0] >= 0
    sleep 100m
  endwhile
  return {'buf' : self.bufnr}
endfunction


function! s:exit_cb(job, ...) abort
  if exists('*term_wait') && exists('*ch_getbufnr')
    call term_wait(ch_getbufnr(a:job, 'out'))
    1
    redraw
  endif
endfunction


function! s:term(cmd, term_opts) abort
  if has('terminal')
    let bufnr = term_start(a:cmd, a:term_opts)
    return {'bufnr' : bufnr}
  elseif has('nvim') && exists('*termopen')
    new
    let job_id = termopen(a:cmd, a:term_opts)
    return {'bufnr' : bufnr('%'), 'job_id' : job_id}
  else
    throw 'iskp: terminal: require Vim enabled +terminal feature'
  endif
endfunction


function! iskp#outputter#terminal#new() abort
  return deepcopy(s:Outputter)
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
