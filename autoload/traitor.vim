" Factory for applying traits to objects
func! traitor#factory() " {{{
    let factory = {}
    let factory.__applied_traits = []
    let factory.debug = 3
    " let factory.debug = 0

    fu factory.reset_defaults() dict " {{{
        let self.traits = {}
        let self.default_properties = {
                    \ "__reserved_for_future_use": []
                    \ }
        let self.core_traits = [
                    \ "traits#core#all",
                    \ "traits#debug#all"
                    \ ]
    endfu " }}}
    call factory.reset_defaults()

    " Pre-register a single traitset with the factory.
    fu factory.add(traitset, name) dict " {{{
        return self.fetch(a:traitset, a:name)
    endfu " }}}

    " Retrieve a traitset by name. Optionally, store the traitset under a
    " different name. Cache the trait.
    fu factory.fetch(traitset, ...) dict " {{{
        let traitset_name = a:traitset
        if len(a:000) > 0
            let traitset_name = a:000[0]
        end
        if ! has_key(self.traits, traitset_name)
            try
                "let self.traits.{"" . traitset_name . ""} = {a:traitset}()
                exec "let self.traits['" . traitset_name . "'] = {a:traitset}()"
            catch /.*/
                call self.log("Traitset '" . traitset_name . "' not found.
                            \ Do you have a function by that name that returns a Dict of Funcrefs?", 2)
                exec "let self.traits['" . traitset_name . "'] = {}"
            endtry
        endif
        exec "return self.traits['" . traitset_name . "']"
    endfu " }}}

    " Apply traitset to instance
    "
    " Copy all functions from a given traitset onto a given instance.  If there
    " is already an existing function for a key or any `__functionname#`
    " variations that may have already been created by `apply`, move them to
    " new series of `__functionname#` functions, add the new function from the
    " traitset as a `__functionname#` function at the end of the series, then "
    " create a new `functionname` method that calls the `__functioname#`
    " functions in order.
    "
    fu factory.apply(trait, instance) dict " < String | List[String] >, <Dict> " {{{
      if type(a:trait) == type("")
        call self.__apply(a:trait, a:instance)
      elseif type(a:trait) == type([])
        for trait in a:trait
          call self.__apply(trait, a:instance)
        endfor
      else
        call self.log("Invalid value: traitset must be a String or a List of Strings.", 1)
      endif
      return a:instance
    endfu " }}}

    fu factory.__apply(trait, instance) dict " <String>, <Dict> " {{{
        " Mix in some core traits.
        if index(self.__applied_traits, a:trait) > 0
            self.log("Already applied traitset " . a:trait, 2)
            finish
        end
        if ! has_key(a:instance, '__core_traits_applied')
            exec "let a:instance['__applied_traits'] = []"
            let a:instance['__core_traits_applied'] = 1
            for traits in self.core_traits
                call self.apply(traits, a:instance)
            endfor
            call self.log("Applied core traitset to instance: " . a:instance.__instance_name())
            if ! has_key(a:instance, '__default_values_applied')
                let a:instance['__default_values_applied'] = 1
                for item in items(self.default_properties)
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
    endfu " }}}

    fu factory.find_chains(instance, key) dict " {{{
        let chains = []
        for key in keys(a:instance)
            if match(key, a:key) > -1
                call add(chains, key)
            endif
        endfor
        return chains
    endfu " }}}

    fu factory.reset_cache() dict " {{{
        let self.traits = {}
        call self.log("Factory trait cache reset.", 3)
    endfu " }}}

    fu factory.fast_apply(traitset, instance) dict " {{{
        let traitset = {}
        exec "let traitset = " . a:traitset . "()"
        call extend(a:instance, traitset)
        call add(self.__applied_traits, a:traitset)
        if has_key(self, "traits")
            exec "call extend(self.traits, { '" . a:traitset . "': traitset} )"
        end
    endfu " }}}

    call factory.fast_apply("traits#core#all", factory)
    call factory.fast_apply("traits#debug#all", factory)
    call factory.log("Factory bootstrapped with traits required in function implementations.", 3)

    return factory
endfunc " }}}
