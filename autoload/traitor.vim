" TODO list " {{{
" TODO: establish "reserved" names that cannot be overridden; these could silently fail or make noise.
" TODO: parameterize all "magic" values
" TODO: document all customization options
" TODO: allow traits to set properties as well as functions (force overwrite,
" if missing, error)
" TODO: establish naming conventions: Dict of functions is called a `set of traits`, named `module#feature_traits` or `FeatureTraits`
" individual functions are just functions.
" TODO: register the application of a set of traits; use this to prevent reapplication
" of traits
" }}}

" Demonstration of Traitor functionality
function! DemoFunction() " {{{
    let factory = traitor#factory() " instantiate object factory
    let factory.debug = 3 " 0 = off; 1 = error; 2 = info; 3 = info
    let factory.default_values = {'debug': 3} " set default properties on all objects
    "let factory.core_traits = [ "traitor#core_traits" ] " override set of default core traits added to every object; list of strings that are functions that generate a Dict of functions or a custom key added with factory.add()
    call factory.add("traitor#demo_irregular_traits", "Irregular") " register a set of traits under a custom name

    let instance = {} " create a new object instance
    let instance.name = "DemoInstance" " give it a name
    let instance.value = "instance value" " give it a default `value` value

    " apply a set of traits to the instance
    for traits in [
                \ "traitor#demo_base_traits",
                \ "traitor#demo_override_traits",
                \ "UnavailableTraits",
                \ "Irregular",
                \ "traitor#demo_chain_traits"
                \ ]
        call factory.apply(traits, instance)
    endfor

    "exercise the instance
    call instance.express()
    call instance.unique()
    call instance.base()
    call instance.irregular()
    call instance.chain()
    call instance.output("custom output")

    " demonstrate invalid type error
    let instance = factory.apply(["invalid"], instance)
endfunction " }}}

" Factory for applying traits to objects
fu! traitor#factory() " {{{
    let factory = {}
    let factory.traits = {}
    let factory.default_values = {}
    let factory.core_traits = [
                \ "traitor#core_traits",
                \ "traitor#debug_traits"
                \ ]

    " Pregister a trait with the factory.
    fu factory.add(trait, name) dict
        return self.fetch(a:trait, a:name)
    endfu

    " Retrieve a set of traits by name. Optionally, store the trait under a
    " different name.
    fu factory.fetch(trait, ...) dict
        let trait_name = a:trait
        if len(a:000) > 0
            let trait_name = a:000[0]
        end
        if ! has_key(self.traits, trait_name)
            try
                "let self.traits.{"" . trait_name . ""} = {a:trait}()
                exec "let self.traits['" . trait_name . "'] = {a:trait}()"
            catch /.*/
                call self.log("'" . trait_name . "' is not available.
                            \ Do you have a function by that name that returns a Dict of Funcrefs?", 2)
                exec "let self.traits['" . trait_name . "'] = {}"
            endtry
        endif
        exec "return self.traits['" . trait_name . "']"
    endfu

    " Apply trait to instance
    "
    " Copy all functions from a given trait onto a given instance.  If there
    " is already an existing function for a key or any `__functionname#`
    " variations that may have already been created by `apply`, move them to
    " new series of `__functionname#` functions, add the new function from the
    " trait as a `__functionname#` function at the end of the series, then "
    " create a new `functionname` method that calls the `__functioname#`
    " functions in order.
    "
    " xTODO: handle non-function values for existing keys
    " TODO: clean up
    " TODO: refactor
    fu factory.apply(trait, instance) dict
        if type(a:trait) != type("")
            call self.log("Invalid value: trait must be a String.", 1)
            return a:instance
        endif
        " Mix in some core traits.
        if ! has_key(a:instance, '__core_traits_applied')
            let a:instance['__core_traits_applied'] = 1
            for traits in self.core_traits
                call self.apply(traits, a:instance)
            endfor
            call self.log("Applied core traits to instance: " . a:instance.__instance_name())
            if ! has_key(a:instance, '__default_values_applied')
                let a:instance['__default_values_applied'] = 1
                for item in items(self.default_values)
                    exec "let a:instance['" . item[0] . "'] = " . item[1]
                endfor
                call self.log("Applied default values to instance: " . a:instance.__instance_name())
            end
        end
        let trait = self.fetch(a:trait)
        for key in keys(trait)
            exec "let valuetype = type(trait." . key . ")"
            if valuetype == type(function("function"))
                let chains = self.find_chains(a:instance, key)
                if len(chains) > 0
                    if len(chains) > 1
                        if has_key(a:instance, key)
                            call remove(a:instance, key)
                        end
                        call remove(chains, index(chains, key))
                    end
                    call self.log("Instance already has key '" . key . "': chaining calls")
                    let funcrefs = {}
                    let i = 0
                    " Gather funcfrefs for existing methods
                    for chain in chains
                        let i += 1
                        exec "let funcrefs.__" . key . i . " = a:instance['". chain . "']"
                    endfor
                    " Add new trait's method to chain
                    exec "let funcrefs.__" . key . (i + 1) . " = trait['". key . "']"
                    " Strip all methods off:
                    for chain in chains
                        call remove(a:instance, chain)
                    endfor
                    " Create new method with all callers
                    let call_list = [ "function! a:instance.". key ."() dict" ]
                    for key in sort(keys(funcrefs))
                        exec "let a:instance['" . key . "'] = funcrefs." . key
                        exec "call add(call_list, \"call self." . key . "()\")"
                    endfor
                    call add(call_list, "endfunction")
                    exec join(call_list, "\n")
                else
                    " No prior function with same name; add it.
                    let a:instance[key] = trait[key]
                endif
            endif
        endfor
        return a:instance
    endfu

    fu factory.find_chains(instance, key) dict
        let chains = []
        for key in keys(a:instance)
            if match(key, a:key) > -1
                call add(chains, key)
            endif
        endfor
        return chains
    endfu

    call extend(factory, traitor#debug_traits())

    return factory
endfunction " }}}

" Traits to be applied automatically to all Factory processed objects.
fu! traitor#core_traits() " {{{
    let trait = {}

    fu trait.__instance_name() dict
        if has_key(self, "name")
            return self.name
        else
            return "Nameless"
        endif
    endfu

    fu trait.output(message) dict
        echo printf("%20s expression: %25s", a:message , self.value)
    endfu

    fu trait.push(message) dict
        echo printf("%20s says %25s", self.__instance_name(), a:message)
    endfu

    return trait
endfu " }}}
fu! traitor#debug_traits() " {{{
    let trait = {}

    fu trait.debug_level() dict
        if has_key(self, "debug")
            return self.debug
        else
            return 0
        endif
    endfu

    fu trait.log(message, ...)
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

    return trait
endfu " }}}

" Demonstration traits
fu! traitor#demo_base_traits() " {{{
    let trait = {}
    let trait.value = "class variable"
    fu trait.express() dict
        call self.output("base")
    endfu
    fu trait.base() dict
        call self.log("base")
    endfu

    return trait

endfu " }}}
fu! traitor#demo_override_traits() " {{{
    let trait = {}

    fu trait.express() dict
        call self.output("overriding")
    endfu

    fu trait.unique() dict
        call self.log("unique method")
    endfu

    return trait
endfu " }}}
fu! traitor#demo_irregular_traits() " {{{
    let trait = {}

    fu trait.express() dict
        call self.output("IRReGulaR")
    endfu

    fu trait.irregular() dict
        call self.log("irReguLar")
    endfu

    return trait
endfu " }}}
fu! traitor#demo_chain_traits() " {{{
    let trait = {}

    fu trait.express() dict
        call self.output("chain")
    endfu

    fu trait.chain() dict
        call self.log("chain")
    endfu

    return trait
endfu " }}}

map <buffer> K <Esc>:w<CR>:so %<CR>:call DemoFunction()<CR>

" Commands (<CR> to execute): " {{{
python << BLOCKCOMMENT
"""
" }}}
echo "test"
call DemoFunction()

- ensure no duplicates
o fetch instances of traits
o parse traits

" End Commands " {{{
"""
BLOCKCOMMENT
" }}}
" vim: ft=vim fdl=0

