" Add Rspec-like functionality
fun! traits#testable#all() " {{{
  let traits = {}

  fu traits.should(...) dict
    " check incoming args and behave appropriately
    " mb use global object that holds all functions to avoid applying a whole bunch of methods to a object that it won't use directly; implement functions using features of that external object, passing in self where needed.
    call self.log("yes, it really should " . string(a:000) . ", shouldn't it?")
  endfu

  fu traits.should_not(...) dict
    call self.log("definitely, it should not " . string(a:000) . ", should it?")
  endfu

  fu traits.is(...) dict
    call self.log("presumably is " . string(a:000) . ".")
  endfu

  fu! traits.works() dict
    call self.log(string(self))
    let test_methods = filter(copy(keys(self)),'v:val =~ "should_\\|^is_" && v:val !~ "should_not$"')
    for each in test_methods
        call self.log(each)
    endfor

    "for item in items(self)
    "    if type(item[1]) == type(function("function"))
    "        call self.log(string(item[0]))
    "    endif
    "endfor
    call self.log("sure would be nice to know if it *does* indeed work")
  endfu

  return traits
endfun " }}}

fun! TestFoo()
  let traits = ["traits#testable#all"]
  let test_that_it = Factory().apply(traits, {})
  let test_that_it.debug= 3
  let it = Factory().apply(traits, {})

  fu test_that_it.should_not_be_full()
    it.should_not("be_full")
  endfu

  fu test_that_it.should_be_empty()
    it.should("be_empty")
  endfu

  fu test_that_it.is_good()
    it.should("be_good")
  endfu

  fu test_that_it.should_accept_list()
    it.is("unimplemented")
  endfu

  call test_that_it.works()
endfun

call extend(Factory(), {"traits": {}}) " reset factory caches
call Factory().reset_cache()
echo TestFoo()
