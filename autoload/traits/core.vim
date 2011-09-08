" Traits to be applied automatically to all Factory processed objects.
fun! traits#core#all() " {{{
    let traits = {}

    fu traits.__instance_name() dict
        if ! has_key(self, "name")
            let self.name = "Nameless"
        endif
        return self.name
    endfu

    fu traits.output(message) dict
        echo printf("%20s expression: %25s", a:message , self.value)
    endfu

    fu traits.push(message) dict
        echo printf("%20s says %25s", self.__instance_name(), a:message)
    endfu

    return traits
endfun " }}}
