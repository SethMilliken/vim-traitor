" Default factory
if !exists("g:traitor_default_factory_enable")
  "finish
end

let s:factory = traitor#factory()

function! Factory() "{{{
  return s:factory
endfunction "}}}

function! FactoryReset() "{{{
  let s:factory = traitor#factory()
  return s:factory
endfunction "}}}

function! FactoryNew() "{{{
  return traitor#factory()
endfunction "}}}
