let s:save_cpo = &cpo
set cpo&vim


let g:iskp_outputters = {}
lockvar g:iskp_outputters


function! iskp#define(outputter) abort
  if !has_key(a:outputter, 'Name')
    echoerr printf('iskp: not found Name key in %s', string(a:outputter))
  endif
  if !has_key(a:outputter, 'Run')
    echoerr printf('iskp: not found Run key in %s', string(a:outputter))
  endif
  let name = get(a:outputter, 'Name')
  unlockvar g:iskp_outputters
  let g:iskp_outputters[name] = deepcopy(a:outputter)
  lockvar g:iskp_outputters
endfunction


function! s:outputters_in_rtp() abort
  let outputter_path_list = globpath(&runtimepath, 'autoload/iskp/outputter/*.vim', 1, 1)
  let outputter_name_list = map(outputter_path_list, 'fnamemodify(v:val, ":t:r")')
  return map(outputter_name_list, 'iskp#outputter#{v:val}#new()')
endfunction


function! s:define_outputters_in_rtp() abort
  call map(s:outputters_in_rtp(), 'iskp#define(v:val)')
endfunction


call s:define_outputters_in_rtp()


function! iskp#run(...) abort
  if a:0 == 0
    let outputter_name = 'default'
  else
    let outputter_name = get(a:, '1')
    if !has_key(g:iskp_outputters, outputter_name)
      echoerr printf('iskp: invalid outputter name: %s', outputter_name)
    endif
  endif
  let outputter = g:iskp_outputters[outputter_name]
  let l:Iskp_func = get(get(outputter, 'Run'), 'func')
  let args = get(get(outputter, 'Run'), 'args')
  let dict = get(outputter, 'dict', {})
  let ctx = get(a:, '2', get(args, 0, {}))
  let ctx.word = get(ctx, 'word', iskp#get_keyword(get(ctx, 'mode', mode())))
  if empty(ctx.word)
    call s:echo_none_keyword()
    return
  endif
  let ctx.cmdlns = get(ctx, 'cmdlns',
        \ [&shell, &shellcmdflag, printf('%s %s', &keywordprg, ctx.word)])
  let ctx.cmdln = get(ctx, 'cmdln',
        \ printf('%s %s %s', ctx.cmdlns[0], ctx.cmdlns[1], shellescape(ctx.cmdlns[2])))
  let ctx.filetype = &filetype
  if stridx(&keywordprg, ':') == 0
    execute &keywordprg ctx.word
  else
    call call(l:Iskp_func, [ctx], dict)
  endif
endfunction


function! iskp#on_FileType() abort
  if exists('g:no_plugin_maps') || exists('g:no_iskp_maps') || exists('b:no_iskp_maps')
    return
  endif

  nmap <buffer> K <Plug>(iskp)
  vmap <buffer> K <Plug>(iskp)
endfunction


function! iskp#new_buffer(lines, ctx) abort
  let lines = iskp#strip_lines(a:lines)
  let bufname = iskp#get_bufname(a:ctx)
  let opener = get(a:ctx, 'open', 'new')
  if winheight(0) > iskp#strdisplayheight(lines)
    let height = printf('+resize\ %d', iskp#strdisplayheight(lines))
  else
    let height = ''
  endif
  execute printf('%s %s %s', opener, height, bufname)

  " Note: Using execute() prevents to print '\d\+ more lines' message.
  "       'put = lines' (without execute()) prints its message.
  call execute('put = lines')
  1 delete _
  call iskp#set_buffer_local_options(a:ctx)
endfunction


function! iskp#new_preview(lines, ctx) abort
  let lines = iskp#strip_lines(a:lines)
  let bufname = iskp#get_bufname(a:ctx)
  let opener = get(a:ctx, 'open', 'pedit')
  if &previewheight > iskp#strdisplayheight(lines)
    let height = printf('+resize\ %d', iskp#strdisplayheight(lines))
  else
    let height = ''
  endif
  execute printf('%s %s %s', opener, height, bufname)
  wincmd P

  " Note: Using execute() prevents to print '\d\+ more lines' message.
  "       'put = lines' (without execute()) prints its message.
  call execute('put = lines')
  1 delete _
  call iskp#set_buffer_local_options(a:ctx)
endfunction


function! iskp#set_buffer_local_options(ctx) abort
  setlocal buftype=nofile readonly nofoldenable nomodified nomodifiable
  setlocal noswapfile nowritebackup bufhidden=delete nobuflisted
  execute printf('setlocal filetype=iskp.iskp_%s', a:ctx.filetype)
endfunction


function! iskp#strip_lines(lines) abort
  let lines = a:lines
  let l:IsEmptyLine = {lines, lnum -> lines[lnum] =~? '^[[:blank:]]*$'}
  while !empty(lines) && l:IsEmptyLine(lines, 0)
    let lines = lines[1:]
  endwhile
  while !empty(lines) && l:IsEmptyLine(lines, -1)
    let lines = lines[:-2]
  endwhile
  return lines
endfunction


function! iskp#strdisplayheight(lines) abort
  let i = 0
  let winwidth = winwidth(0) - &foldcolumn - (&number ? &numberwidth : 0)
  for line in a:lines
    let i += empty(line) ? 1 : float2nr(ceil(round(strdisplaywidth(line)) / round(winwidth)))
  endfor
  return i
endfunction


function! iskp#get_bufname(ctx) abort
  return get(a:ctx, 'bufname', printf('*iskp-%s*', get(a:ctx, 'word', '')))
endfunction


function! iskp#get_keyword(mode) abort
  if a:mode =~? '^n'
    call s:set_iskeyword()
    let word = expand('<cword>')
    call s:unset_iskeyword()
    return word
  elseif a:mode =~? '^v'
    let start = getpos('''<')
    let end = getpos('''>')
    if start[1] !=# end[1]  " [1] : lnum
      return ''
    endif
    if start[2] > end[2]    " [2] : col
      let [start, end] = [end, start]
    endif
    let line = getline(start[1])
    return line[start[2] - 1 : end[2] - 1]
  endif
endfunction


function! s:set_iskeyword() abort
  return s:set_or_unset_iskeyword('+')
endfunction


function! s:unset_iskeyword() abort
  return s:set_or_unset_iskeyword('-')
endfunction


function! s:set_or_unset_iskeyword(op) abort
  let isk = get(b:, 'iskp_iskeyword', '')
  if !empty(isk)
    execute printf('setlocal iskeyword%s=%s', a:op, isk)
  endif
endfunction


function! s:echo_none_keyword() abort
  echohl ErrorMsg
  echo 'iskp: no keyword'
  echohl None
endfunction


"
" command
"


function! iskp#complete(lead, cmd, pos) abort
  return filter(map(s:option_list(), 'v:val'), 'v:val =~# a:lead')
endfunction


function! iskp#command(arg) abort
  let args = split(a:arg)
  if !empty(filter(copy(args), 'v:val =~# "-h\\%[elp]"'))
    call s:echo_help()
    return
  endif
  let obj = s:parse_args(args)
  let outputter_name = get(obj, 'outputter_name', 'default')
  let ctx = empty(get(obj, 'word', '')) ? {} : {'word' : obj.word}
  return iskp#run(outputter_name, ctx)
endfunction


function! s:parse_args(args) abort
  let args = a:args
  let obj = {}
  while !empty(args)
    let [arg; args] = args
    let opt = filter(s:option_list(), 'arg ==# v:val')
    if empty(opt)
      let obj.word = arg
    else
      let obj.outputter_name = opt[0][1:]
    endif
  endwhile
  return obj
endfunction


function! s:option_list() abort
  return map(add(keys(g:iskp_outputters), 'help'), '"-" . v:val')
endfunction


function! s:echo_help() abort
  echo join([
        \ 'Iskp {options} {keyword}',
        \ '  options:',
        \ join(map(s:option_list(), '"    " . v:val'), "\n"),
        \], "\n")
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
