" Demonstration of Traitor functionality
function! DemoFunction() " {{{
    let factory = traitor#factory() " instantiate object factory
    let factory.debug = 3 " 0 = off; 1 = error; 2 = info; 3 = info
    let factory.default_values = {'debug': 3} " set default properties on all objects
    "let factory.core_traits = [ "traitor#core_traits" ] " override set of default core traits added to every object; list of strings that are functions that generate a Dict of functions or a custom key added with factory.add()
    call factory.add("traitor#demo#irregular_traits", "Irregular") " register a set of traits under a custom name

    let instance = {} " create a new object instance
    let instance.name = "DemoInstance" " give it a name
    let instance.value = "instance value" " give it a default `value` value

    " apply a set of traits to the instance
    for traits in [
                \ "traitor#demo#base_traits",
                \ "traitor#demo#override_traits",
                \ "UnavailableTraits",
                \ "Irregular",
                \ "traitor#demo#chain_traits"
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

" Demonstration traits
fu! traitor#demo#base_traits() " {{{
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
fu! traitor#demo#override_traits() " {{{
    let trait = {}

    fu trait.express() dict
        call self.output("overriding")
    endfu

    fu trait.unique() dict
        call self.log("unique method")
    endfu

    return trait
endfu " }}}
fu! traitor#demo#irregular_traits() " {{{
    let trait = {}

    fu trait.express() dict
        call self.output("IRReGulaR")
    endfu

    fu trait.irregular() dict
        call self.log("irReguLar")
    endfu

    return trait
endfu " }}}
fu! traitor#demo#chain_traits() " {{{
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
