function! quickrun#hook#onlinejudge#new()
  return deepcopy(s:hook)
endfunction

let s:hook = {
      \ 'name': 'onlinejudge',
      \ 'kind': 'hook',
      \ 'config': { 'enable': 0, 'input': '' },
      \ }

function! s:hook.on_ready(session, context)
  " on_ready is called after config is expanded
  if !empty(self.config.input)
    let a:session.config.input = self.config.input
  endif
endfunction
