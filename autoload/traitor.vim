" Factory for applying traits to objects
fu! traitor#factory() " {{{
    let factory = {}
    let factory.traits = {}
    let factory.default_values = {}
    let factory.core_traits = [
                \ "traits#core#all",
                \ "traits#debug#all"
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

    call extend(factory, traits#debug#all())

    return factory
endfunction " }}}
