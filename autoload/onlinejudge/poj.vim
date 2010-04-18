"=============================================================================
" FILE: poj.vim
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

function! s:login(user, pass) " {{{
  call onlinejudge#curl('POST', 'http://acm.pku.edu.cn/JudgeOnline/login',
        \ {'user_id1': a:user, 'password1': a:pass, 'url': '/JudgeOnline/'},
        \ {'-c': s:cookie_file})
endfunction " }}}

let s:lang2nr = {
      \ 'G++': 0,
      \ 'GCC': 1,
      \ 'Java': 2,
      \ 'Pascal': 3,
      \ 'C++': 4,
      \ 'C': 5,
      \ 'Fortran': 6,
      \ }

let s:cookie_file = tempname()

function! onlinejudge#poj#submit(user, pass, problem_id) " {{{
  call s:login(a:user, a:pass)

  let src = join(getline(1, '$'), "\n")

  let lang = ''
  if &filetype == 'cpp'
    if exists('g:poj_prefer_cpp') && g:poj_prefer_cpp
      let lang = 'C++'
    else
      let lang = 'G++'
    endif
  elseif &filetype == 'java'
    let lang = 'Java'
  elseif &filetype == 'c'
    if exists('g:poj_prefer_c') && g:poj_prefer_c
      let lang = 'C'
    else
      let lang = 'GCC'
    endif
  elseif &filetype == 'fortran'
    let lang = 'Fortran'
  elseif &filetype == 'pascal'
    let lang = 'Pascal'
  else
    let lang = input('Language: ')
    if !has_key(s:lang2nr, lang)
      echoerr 'No such language: ' . lang
      return ''
    endif
  endif

  if lang == 'Java'
    let src = substitute(src, '\npublic class \zs\w\+\ze', 'Main', '')
  endif
  call onlinejudge#curl('POST', 'http://acm.pku.edu.cn/JudgeOnline/submit',
        \ {'problem_id': a:problem_id, 'language': s:lang2nr[lang], 'source': src},
        \ {'-b': s:cookie_file})
endfunction " }}}

function! onlinejudge#poj#user_status(user, pass)  " {{{
  let res = onlinejudge#curl('GET', 'http://acm.pku.edu.cn/JudgeOnline/status',
        \ {'user_id': a:user}, {})
  let lines = []
  for l in split(res, '\n')
    let l = onlinejudge#remove_tags(l, ['tr', 'a', 'font'])
    let l = substitute(l, '</td>', '', 'g')
    if l[0:3] == '<td>'
      call add(lines, substitute(l[4:], '<td>', '\t', 'g'))
    endif
  endfor
  return lines
endfunction " }}}

function! onlinejudge#poj#sample_io(user, pass, problem_id)  " {{{
  let res = onlinejudge#curl('GET', 'http://acm.pku.edu.cn/JudgeOnline/problem',
        \ {'id': a:problem_id}, {})
  let input = matchstr(res, '<pre class="sio">\zs.\{-\}\ze</pre>', 0, 1)
  let input = substitute(input, '\r\n', "\n", 'g')
  let output = matchstr(res, '<pre class="sio">\zs.\{-\}\ze</pre>', 0, 2)
  let output = substitute(output, '\r\n', "\n", 'g')
  return [split(input, '\n'), split(output, '\n')]
endfunction " }}}

function! onlinejudge#poj#submit_complete(arglead, cmdline, cursorpos)  " {{{
  return [matchstr(expand('%:t'), '\d\{4\}')]
endfunction " }}}

" vim: set et ts=2 sw=2 sts=2 fdm=marker:"

