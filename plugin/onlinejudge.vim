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

if exists('g:loaded_onlinejudge') && g:loaded_onlinejudge
  finish
endif

if !executable('curl')
  echoerr 'onlinejudge requires cURL'
  finish
endif

command! -nargs=+ -complete=customlist,onlinejudge#submit_complete OnlineJudgeSubmit call onlinejudge#submit(<q-args>)
command! -nargs=+ -complete=customlist,onlinejudge#service_complete OnlineJudgeUserStatus call onlinejudge#user_status(<f-args>)
command! -nargs=+ -complete=customlist,onlinejudge#submit_complete OnlineJudgeTest call onlinejudge#test(<f-args>)

let g:loaded_onlinejudge = 1

" vim: set et ts=2 sw=2 sts=2 foldmethod=marker:

