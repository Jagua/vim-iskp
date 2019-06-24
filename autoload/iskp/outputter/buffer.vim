let s:save_cpo = &cpo
set cpo&vim


let s:Outputter = {}
let s:Outputter.Name = 'buffer'


function! s:Run(ctx) abort
  call iskp#execute_cmd(a:ctx, function('s:new_buffer'))
endfunction
let s:Outputter.Run = function('s:Run')


function! s:new_buffer(ctx, lines) abort
  let bufname = iskp#get_bufname(a:ctx)
  let opener = get(a:ctx, 'open', 'new')
  if winheight(0) > iskp#strdisplayheight(a:lines)
    let height = printf('+resize\ %d', iskp#strdisplayheight(a:lines))
  else
    let height = ''
  endif
  execute printf('%s %s %s', opener, height, bufname)

  " Note: Using execute() prevents to print '\d\+ more lines' message.
  "       'put = a:lines' (without execute()) prints its message.
  call execute('put = a:lines')
  1 delete _
  call iskp#set_buffer_local_options(a:ctx)
endfunction


function! iskp#outputter#buffer#new() abort
  return deepcopy(s:Outputter)
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
