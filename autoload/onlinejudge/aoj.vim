"=============================================================================
" FILE: aoj.vim
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

let s:langs = {
      \ 'c': 'C',
      \ 'cpp': 'C++',
      \ 'java': 'JAVA',
      \ }

function! onlinejudge#aoj#submit(user, pass, problem_id) " {{{
  let src = join(getline(1, '$'), "\n")

  let lang = ''
  if has_key(s:langs, &l:filetype)
    let lang = s:langs[&l:filetype]
  else
    let lang = input('Language: ')
    if !has_key(s:langs, lang)
      echoerr 'No such language: ' . lang
      return ''
    endif
  endif

  if lang == 'JAVA'
    let src = substitute(src, '\npublic class \zs\w\+\ze', 'Main', '')
  endif
  call onlinejudge#curl('POST', 'http://rose.u-aizu.ac.jp/onlinejudge/servlet/Submit',
        \ {'userID': a:user, 'password': a:pass, 'problemNO': a:problem_id,
        \ 'language': lang, 'sourceCode': src, 'submit': 'Send'}, {})
endfunction " }}}

function! onlinejudge#aoj#user_status(user, pass)  " {{{
  let res = onlinejudge#curl('GET', 'http://rose.u-aizu.ac.jp/onlinejudge/Status.jsp',
        \ {}, {})
  let table = matchstr(res, '<table class="status" [^>]\+>\zs.\{-\}\ze</table>')
  let lines = []
  for l in split(table, '<tr[^>]\+>')[2:]
    let author = matchstr(l, 'href="UserInfo.jsp?id=\zs[^"]\+')
    let problem = matchstr(l, 'description.jsp?id=\zs\d\+')
    let result = substitute(matchstr(l, '<FONT \+COLOR[^>]\+>\zs.\{-\}\ze</FONT>'), '<[^>]\+>', '', 'g')

    let ths = split(l, '\n')
    call map(ths, 'substitute(v:val, "<[^>]*>", "", "g")')
    call filter(ths, 'v:val !~# "^\\s*$"')
    call reverse(ths)
    let [date, code, memory, time, lang] = ths[0:4]
    call add(lines, join([author, problem, result, lang, time, memory, code, date], "\t"))
  endfor
  return lines
endfunction " }}}

function! onlinejudge#aoj#sample_io(user, pass, problem_id)  " {{{
  let res = onlinejudge#curl('GET',
        \ 'http://rose.u-aizu.ac.jp/onlinejudge/ProblemSet/description.jsp',
        \ {'id': a:problem_id}, {})
  let input = matchstr(res, '<H\d>Sample Input</H\d>[\s\r\n]*<pre>\zs.\{-\}\ze</pre>')
  let input = substitute(input, '\r\n', "\n", 'g')
  let output = matchstr(res, '<H\d>Output for the Sample Input</H\d>[\s\r\n]*<pre>\zs.\{-\}\ze</pre>')
  if empty(output)
    let output = matchstr(res, '<H\d>Sample Output</H\d>[\s\r\n]*<pre>\zs.\{-\}\ze</pre>')
  endif
  let output = substitute(output, '\r\n', "\n", 'g')
  return [split(input, '\n'), split(output, '\n')]
endfunction " }}}

function! onlinejudge#aoj#submit_complete(arglead, cmdline, cursorpos)  " {{{
  return [matchstr(expand('%:t'), '\d\{4\}')]
endfunction " }}}

" vim: set et ts=2 sw=2 sts=2 fdm=marker:"


