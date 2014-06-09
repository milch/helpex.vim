" A set of Elixir development tools
" Version: 0.0.1
" Author:  sanmiguel <michael.coles@gmail.com>
" License: Apache 2

if exists('g:loaded_helpex')
  finish
endif

" TODO: Start node
" TODO: reconnect socket if necessary
let s:elixir_namespace= '\<[A-Z][[:alnum:]]\+\(\.[A-Z][[:alnum:].]\+\)*.*$'
let s:erlang_module= ':\<'
let s:elixir_fun_w_arity = '.*/[0-9]$'
let s:elixir_module = '[A-Z][[:alnum:]_]\+\([A_Z][[:alnum:]_]+\)*'

let s:sock = vimproc#socket_open('localhost', 9999)

function! helpex#socket()
    if s:sock.eof
        call s:sock.close() 
        let s:sock = vimproc#socket_open('localhost', 9999)
    endif
endfunction

function! helpex#get_suggestions(hint)
    call helpex#socket()
    call s:sock.write("complete:" . a:hint . "\n")
    let reply = ""
    while reply !~# '.*\nEOF\n'
        let reply .= s:sock.read()
    endwhile
    return filter(split(reply, '\n'), 'v:val != "EOF"')
endfunction

function! helpex#omnifunc(findstart, base)
    if a:findstart
        " return int 0 < n <= col('.')
        " TODO: Probably not right
        let lnum = line('.')
        let column = col('.')
        let line = strpart(getline('.'), 0, column - 1)
        if line =~ s:erlang_module
            return match(line, s:erlang_module)
        elseif line =~ s:elixir_namespace
            return match(line, s:elixir_namespace)
        endif

        return col('.')
    endif

    if ! a:findstart
        let suggestions = helpex#get_suggestions(a:base)
        if len(suggestions) == 1
            return { 'words': suggestions, 'refresh': 'always' }
        elseif len(suggestions) > 1
            return { 'words': map(suggestions, 's:parse_suggestion(a:base, v:val)'), 'refresh': 'always'}
        endif
    endif
endfunction

function! s:parse_suggestion(base, suggestion)
    if a:suggestion =~ s:elixir_fun_w_arity
        let [word, arity] = split(a:suggestion, "/")
        return {'word': a:base.word.' ', 'abbr': a:suggestion, 'kind': 'f' }
    elseif a:suggestion =~ s:elixir_module
        return {'word': a:base.a:suggestion, 'abbr': a:suggestion, 'kind': 'm'}
    elseif a:suggestion =~ s:erlang_module
        return {'word': a:suggestion, 'abbr': a:suggestion, 'kind': 'f'}
    else
        return {'word': a:base.a:suggestion, 'abbr': a:suggestion }
    endif
endfunction

let g:loaded_helpex = 1
