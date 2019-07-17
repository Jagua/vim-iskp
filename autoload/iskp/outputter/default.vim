let s:save_cpo = &cpo
set cpo&vim


let s:Outputter = {}
let s:Outputter.Name = 'default'


function! s:Run(ctx) abort
  if exists('b:iskp_outputter') && b:iskp_outputter !=# 'default'
        \ && has_key(g:iskp_outputters, b:iskp_outputter)
    return g:iskp_outputters[b:iskp_outputter].Run(a:ctx)
  endif
  if (has('terminal') || has('nvim') && exists('*termopen'))
        \ && has_key(g:iskp_outputters, 'terminal')
    return g:iskp_outputters['terminal'].Run(a:ctx)
  elseif has_key(g:iskp_outputters, 'buffer')
    return g:iskp_outputters['buffer'].Run(a:ctx)
  else
    throw 'iskp: default: internal error'
  endif
endfunction
let s:Outputter.Run = function('s:Run')


function! iskp#outputter#default#new() abort
  return deepcopy(s:Outputter)
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
