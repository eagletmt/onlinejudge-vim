"=============================================================================
" FILE: mjudge.vim
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

let s:cookie_file = tempname()

function! s:login(user, pass) " {{{
  let r = onlinejudge#curl('POST', 'http://m-judge.maximum.vc/login.cgi',
        \ {'user': a:user, 'pswd': a:pass},
        \ {'-c': s:cookie_file})
endfunction " }}}

let s:lang2nr = {
      \ 'C': 0,
      \ 'C++': 1,
      \ 'Java': 2,
      \ }

function! onlinejudge#mjudge#submit(user, pass, problem_id) " {{{
  call s:login(a:user, a:pass)

  let src = join(getline(1, '$'), "\n")

  let lang = ''
  if &filetype == 'cpp'
    let lang = 'C++'
  elseif &filetype == 'java'
    let lang = 'Java'
  elseif &filetype == 'c'
    let lang = 'C'
  else
    let lang = input('Language: ')
    if !has_key(s:lang2nr, lang)
      echoerr 'No such language: ' . lang
      return ''
    endif
  endif

  call onlinejudge#curl('POST', 'http://m-judge.maximum.vc/submit.cgi',
        \ {'m': 1, 'pid': a:problem_id, 'lang': s:lang2nr[lang], 'code': src},
        \ {'-b': s:cookie_file})
endfunction " }}}

function! onlinejudge#mjudge#user_status(user, pass)  " {{{
  let res = onlinejudge#curl('GET', 'http://m-judge.maximum.vc/result.cgi',
        \ {'s_uid': a:user}, {})
  let res = matchstr(res, '<tbody>\zs.*\ze</tbody>\n</table>')
  let lines = []
  for t in split(res, '</tbody>')
    let t = onlinejudge#remove_tags(t, ['tbody', 'tr', 'a'])
    let t = substitute(t, '\n', '', 'g')
    let ds = split(t, '<td>')
    call map(ds, 'onlinejudge#remove_tags(v:val, ["td"])')
    call add(lines, join(ds, "\t"))
  endfor
  return lines
endfunction " }}}

function! onlinejudge#mjudge#sample_io(user, pass, problem_id)  " {{{
  let res = onlinejudge#curl('GET', 'http://m-judge.maximum.vc/problem.cgi',
        \ {'pid': a:problem_id}, {})
  let res = matchstr(res, 'Sample Input\zs.*')
  let input = matchstr(res, '<pre>\zs.\{-\}\ze</pre>', 0, 1)
  let input = substitute(input, '\r\n', "\n", 'g')
  let output = matchstr(res, '<pre>\zs.\{-\}\ze</pre>', 0, 2)
  let output = substitute(output, '\r\n', "\n", 'g')
  return [split(input, '\n'), split(output, '\n')]
endfunction " }}}

function! onlinejudge#mjudge#submit_complete(arglead, cmdline, cursorpos)  " {{{
  return [matchstr(expand('%:t'), '\d\+')]
endfunction " }}}

" vim: set et ts=2 sw=2 sts=2 fdm=marker:"

