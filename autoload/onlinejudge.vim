"=============================================================================
" FILE: onlinejudge.vim
" AUTHOR: eagletmt <eagletmt@gmail.com>
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================

" interface {{{
function! onlinejudge#submit(args)  " {{{
  let [service, problem_id] = matchlist(a:args, '^\(\w\+\)\s\+\(.*\)$')[1:2]

  if index(s:service_list(), service) == -1
    echoerr 'unknown service: ' . fname
  else
    let [user, pass] = s:account(service)
    call onlinejudge#{service}#submit(user, pass, problem_id)
    call onlinejudge#user_status(service)
  endif
endfunction " }}}

function! onlinejudge#user_status(service)  " {{{
  let [user, pass] = s:account(a:service)
  let res = onlinejudge#{a:service}#user_status(user, pass)

  let bufnr = s:new_unique('onlinejudge-status', a:service . '-status', '')
  setlocal buftype=nofile bufhidden=hide noswapfile
  execute 'nnoremap <buffer> <silent> <Leader><Leader> :<C-u>call onlinejudge#user_status("' . a:service . '")<CR>'
  call setline(1, res)
endfunction " }}}

function! onlinejudge#test(service, problem_id) " {{{
  if !exists(':QuickRun')
    echoerr 'onlinejudge#test requires quickrun'
    return
  endif

  let src_bufnr = bufnr('%')

  let input = []
  let output = []

  let input_bufnr = s:bufnr_filetype('onlinejudge-input')
  if input_bufnr == 0
    let [input, output] = onlinejudge#sample_io(a:service, a:problem_id)
    if empty(input)
      echoerr 'failed to get sample input!'
      return
    endif
    if empty(output)
      echoerr 'failed to get sample output!'
      return
    endif
  else
    let input = getbufline(input_bufnr, 1, '$')
  endif

  call s:new_unique('onlinejudge-output', a:service . '-output', '')
  setlocal buftype=nofile bufhidden=hide noswapfile
  diffthis
  call setline(1, output)

  call s:new_unique('onlinejudge-input', a:service . '-input', 'vertical')
  setlocal buftype=nofile bufhidden=hide noswapfile
  call setline(1, input)

  execute bufwinnr(src_bufnr) . 'wincmd w'
  execute 'QuickRun -runmode simple -input "=' . join(input, "\n") . '"'

  let quickrun_bufnr = s:bufnr_filetype('quickrun')
  execute bufwinnr(quickrun_bufnr) . 'wincmd w'
  diffthis
  execute bufwinnr(src_bufnr) . 'wincmd w'

  diffupdate
endfunction " }}}

function! onlinejudge#sample_io(service, problem_id) " {{{
  let [user, pass] = s:account(a:service)
  return onlinejudge#{a:service}#sample_io(user, pass, a:problem_id)
endfunction " }}}

function! onlinejudge#submit_complete(arglead, cmdline, cursorpos)  " {{{
  let m = matchlist(a:cmdline, '\v(\w\s+)((\w+)\s+)')
  if empty(m)
    return onlinejudge#service_complete(a:arglead, a:cmdline, a:cursorpos)
  else
    let service = m[3]
    if index(s:service_list(), service) == -1
      return []
    else
      let cmdline = m[2]
      let cursorpos = a:cursorpos - len(m[1])
      return onlinejudge#{service}#submit_complete(a:arglead, cmdline, cursorpos)
    endif
  endif
endfunction " }}}

function! onlinejudge#service_complete(arglead, cmdline, cursorpos) " {{{
  return filter(s:service_list(), 'v:val =~# "^' . a:arglead . '"')
endfunction " }}}
" }}}

" private functions {{{
function! s:account(service)  " {{{
  if !exists('g:onlinejudge_account')
    let g:onlinejudge_account = {}
  endif
  if !has_key(g:onlinejudge_account, a:service)
    let g:onlinejudge_account[a:service] = {}
  endif
  if !has_key(g:onlinejudge_account[a:service], 'user')
    let g:onlinejudge_account[a:service].user = input('input username for ' . a:service . ': ')
  endif
  if !has_key(g:onlinejudge_account[a:service], 'pass')
    let g:onlinejudge_account[a:service].pass = inputsecret('input password for ' . a:service . ': ')
  endif
  return [g:onlinejudge_account[a:service].user, g:onlinejudge_account[a:service].pass]
endfunction " }}}

function! s:bufnr_filetype(ft)  " {{{
  for i in range(1, winnr('$'))
    let n = winbufnr(i)
    if getbufvar(n, '&filetype') == a:ft
      return n
    endif
  endfor
  return 0
endfunction " }}}

function! s:new_unique(ft, title, sp)  " {{{
  let bufnr = s:bufnr_filetype(a:ft)
  if bufnr == 0
    execute a:sp . ' new ' . a:title
  else
    execute bufwinnr(bufnr) . 'wincmd w'
    if expand('%') != a:title
      execute 'edit ' . a:title
    endif
  endif
  let &l:filetype = a:ft
  return bufnr
endfunction " }}}
" }}}

" utilities {{{
function! onlinejudge#curl(method, url, params, opts) " {{{
  let cmd = 'curl -s'
  if a:method == 'GET'
    let cmd .= ' -G'
  elseif a:method == 'POST'
    let cmd .= ''
  endif

  for [k,v] in items(a:params)
    let cmd .= ' -d ' . k . '=' . onlinejudge#encodeURIComponent(v)
  endfor
  for [k,v] in items(a:opts)
    let cmd .= ' ' . k . ' ' . v
  endfor
  let cmd .= ' ' . a:url

  return system(cmd)
endfunction " }}}

function! onlinejudge#curl_formdata(url, params, stdin) " {{{
  let cmd = 'curl -s'

  for [k,v] in items(a:params)
    if v =~# '^[@<]'
      let cmd .= " -F '" . k . '=' . v . "'"
    else
      let cmd .= ' -F ' . k . '=' . onlinejudge#encodeURIComponent(v)
    endif
  endfor
  let cmd .= ' ' . a:url

  return system(cmd, a:stdin)
endfunction " }}}

function! onlinejudge#encodeURIComponent(s) " {{{
  return substitute(a:s, '[^a-zA-Z0-9_-]', '\=printf("%%%02X", char2nr(submatch(0)))', 'g')
endfunction " }}}

function! onlinejudge#remove_tag(s, name) " {{{
  return substitute(substitute(a:s, '<' . a:name . '\(\| [^>]*\)>', '', 'gi'), '</' . a:name . '>', '', 'gi')
endfunction " }}}

function! onlinejudge#remove_tags(s, names) " {{{
  let ret = a:s
  for name in a:names
    let ret = onlinejudge#remove_tag(ret, name)
  endfor
  return ret
endfunction " }}}

function! s:service_list()  " {{{
  return map(split(globpath(&runtimepath, 'autoload/onlinejudge/*.vim'), "\n"), 'fnamemodify(v:val, ":t:r")')
endfunction " }}}
" }}}

" vim: set et ts=2 sw=2 sts=2 fdm=marker:

