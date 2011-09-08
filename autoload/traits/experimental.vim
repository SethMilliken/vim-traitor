" Experimental traits
fun! traits#experimental#all() " {{{
    let traits = {}

    fu traits.resolve(object,...) dict
      if len(a:000) >0
        let recursive = 1
      else
        let recursive = 0
      endif 
      if type(a:object) == type("") && recursive == 1
        call self.report("String:")
        call self.i_up()
        call self.report(a:object)
        call self.i_down()
      elseif type(a:object) == type(0) && recursive == 1
        call self.report("Number:")
        call self.i_up()
        call self.report(a:object)
        call self.i_down()
      elseif type(a:object) == type([])
        call self.report("List:")
        call self.report("[")
        call self.i_up()
        for item in a:object
          call self.resolve(item, recursive)
          echo ","
        endfor
        call self.i_down()
        call self.report("]")
      elseif type(a:object) == type({})
        call self.report("Dict:")
        call self.i_up()
        for item in items(a:object)
          call self.banner(item[0])
          call self.i_up()
          call self.resolve(item[1], recursive)
          call self.i_down()
        endfor
        call self.i_down()
      elseif type(a:object) == type(function("function")) || recursive == 0
        let funcnum = matchstr(string(a:object), '[[:digit:]]\+')
        call self.report("Function: " . funcnum)
        redir => functionlisting
        silent! exec "function {" . funcnum . "}"
        redir END
        for line in split(functionlisting, '\n')
          call self.i_up(4)
          call self.report(line)
          call self.i_down(4)
        endfor
      endif
  endfu

    fu traits.introspect()
      call self.resolve(self)
    endfu

    fu traits.banner(contents)
      call self.report(printf("%s[ %-20s ]%s", repeat('=', 3), a:contents, repeat('=', 15)))
    endfu

    fu traits.report(contents)
      echo printf("|%s%s", self.indentation(), a:contents)
    endfu

    fu traits.indentation()
      return repeat('  ', self.indent_level)
    endfu

    fu traits.i_up(...)
      let increment = 1
      if len(a:000) > 0
        let increment = a:000[0]
      end
      let self.indent_level += increment
    endfu

    fu traits.i_down(...)
      let increment = 1
      if len(a:000) > 0
        let increment = a:000[0]
      end
      let self.indent_level -= increment
    endfu

    return traits
endfun " }}}

let instance = traits#experimental#all()
let instance.indent_level = 0
call instance.introspect()
"call instance.resolve(1234)
"call instance.resolve("2345")
