" Add debuging functionality
fun! traits#debug#all() " {{{
    let traits = {}

    fu traits.debug_level() dict
        if has_key(self, "debug")
            return self.debug
        else
            return 0
        endif
    endfu

    fu traits.log(message, ...)
        let debug_level = self.debug_level()
        let message_level = 3 " default
        if len(a:000) > 0
            let message_level = a:000[0]
        endif
        if message_level <= debug_level
            if message_level == 1 | let hl = "ErrorMsg" | endif
            if message_level == 2 | let hl = "WarningMsg" | endif
            if message_level == 3 | let hl = "Special" | endif
            exec "echohl " . hl . "|echomsg a:message |echohl None"
        endif
    endfu

    return traits
endfun " }}}
