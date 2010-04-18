"=============================================================================
" FILE: spoj.vim
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

function! onlinejudge#spoj#submit(user, pass, problem_id) " {{{
  let lang = s:filetype2nr(&filetype)
  if lang < 0
    return
  endif
  let src = join(getline(1, '$'), "\n")
  if lang == s:filetype2nr('java')
    let src = substitute(src, '\npublic class \zs\w\+\ze', 'Main', '')
  endif

  call onlinejudge#curl_formdata('https://www.spoj.pl/submit/complete/',
        \ { 'login_user': a:user
        \ , 'password': a:pass
        \ , 'file': '<-'
        \ , 'lang': lang
        \ , 'problemcode': a:problem_id
        \ , 'submit': 'Send'
        \ }, src)
endfunction " }}}

function! onlinejudge#spoj#user_status(user, pass)  " {{{
  let res = onlinejudge#curl('GET', 'https://www.spoj.pl/status/' . a:user . '/', {}, {})
  let problems = matchstr(res, '<table class="problems"\zs.\{-\}\ze</table>')
  let lines = []
  let i = 1
  let tr = matchstr(problems, '<tr class="kol\d*">\zs.\{-\}\ze</tr>', 0, i)
  while tr != ''
    let tr = substitute(tr, '[\r\n]', '', 'g')
    let id = matchstr(tr, '<td class="statustext">\zs.\{-\}\ze</td>')
    let sm = matchstr(tr, '<td class="status_sm">\zs.\{-\}\ze</td>')
    let [code, title] = matchlist(tr, '<a .*title="\(\w\+\)">\([^<>]\+\)')[1:2]
    let result = matchstr(tr, '<td class="statusres" [^>]*>\s*\zs.\{-\}\ze\s*</td>')
    let slang = matchstr(tr, '<td class="slang">\s*<p>\zs.\{-\}\ze</p>')
    call add(lines, join([id, sm, title.'['.code.']', result, slang], "\t"))
    let i = i+1
    let tr = matchstr(problems, '<tr class="kol\d*">\zs.\{-\}\ze</tr>', 0, i)
  endwhile
  return lines
endfunction " }}}

function! onlinejudge#spoj#sample_io(user, pass, problem_id)  " {{{
  let res = onlinejudge#curl('GET', 'https://www.spoj.pl/problems/' . a:problem_id . '/', {}, {})
  let res = substitute(res, '\s*<br */>\s*', "\n", 'g')
  let res = substitute(res, '\r\n', "\n", 'g')
  let res = substitute(res, '&nbsp;', ' ', 'g')
  let input = matchstr(res, '<\(b\|strong\)>Input:</\1>\zs.\{-\}\ze<')
  let output = matchstr(res, '<\(b\|strong\)>Output:</\1>\zs.\{-\}\ze<')
  if input != '' && output != ''
    return [split(input, '\n'), split(output, '\n')]
  endif

  " very ad-hoc!
  " http://www.spoj.pl/problems/DIGRT/
  let input = matchstr(res, '<pre><p>Input:</p>\zs.\{-\}\ze<strong>')
  let input = substitute(input, '<p>', '', 'g')
  let output = matchstr(res, '<strong><p>Output:</p></strong>\zs.\{-\}\ze</pre>')
  let output = substitute(output, '<p>', '', 'g')
  return [split(input, '</p>'), split(output, '</p>')]
endfunction " }}}

function! onlinejudge#spoj#submit_complete(arglead, cmdline, cursorpos) " {{{
  return [expand('%:t:r')]
endfunction " }}}

function! s:filetype2nr(ft) " {{{
  if a:ft == 'c'
   " C99 strict (gcc 4.3.2)
    return 34
  elseif a:ft == 'cpp'
    " C++ (g++ 4.3.2)
    return 41
  elseif a:ft == 'haskell'
    " Haskell (ghc 6.10.4)
    return 21
  elseif a:ft == 'java'
    " Java (JavaSE 6)
    return 10
  elseif a:ft == 'scala'
    " Scala (Scalac 2.7.4)
    return 39
  elseif a:ft == 'perl'
    " Perl (perl 5.10.0)
    return 3
  elseif a:ft == 'python'
    " Python (python 2.6.2)
    return 44
  elseif a:ft == 'ruby'
    " Ruby (ruby 1.9.0)
    return 17
  else
    echoerr 'filetype "' . a:ft . '" is unavailable'
    return -1
  endif
endfunction " }}}

" vim: set et ts=2 sw=2 sts=2 fdm=marker:

