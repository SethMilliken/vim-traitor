" Traits for manipulating a list of items
fun! traits#traitset#all() " {{{
    let traits = {}

    " "node": specialized form of a fold that looks like this
    " nodename <comment string> <foldmarker open>
    " <comment string> <foldmarker close>

    " Create a fold named "nodename" underneath a node named
    " "previous_node_name". If "previous_node_name" is empty,
    " create "nodename" at the first line.
    fu traits.create_node_under(nodename, previous_node_name) dict " {{{
        let l:origview = winsaveview()
        if self.find_node(a:nodename) == 0
            if a:previous_node_name != ""
                if self.find_node(a:previous_node_name) == 0
                    call self.create_node_under(a:previous_node_name, "")
                end
                call FoldUnfolded()
                normal o
            else
                normal ggO
                normal k
            end
            exe "normal I" . a:nodename
            call FoldWrap()
            call FoldUnfolded()
        end
        call winrestview(l:origview)
    endfu " }}}

    " Folds: manipulation
    " Returns the line number on which a fold with the name "label"
    " is found.
    fu traits.find_node(label) dict " {{{
        let l:location = NodeLocation(a:label)
        if l:location > 0
            call setpos(".", [0, l:location, 0, 0])
        end
        return line(".")
    endfu " }}}

    fu traits.NodeLocation(label,...) dict " {{{
        if len(a:label) == 0
            return 0
        end
        if len(a:000) > 0
            let l:options = 'n'
        else
            let l:options = 'cwn'
        end
        let l:openmarker = CommentedFoldMarkerOpen()
        let l:expression = a:label . "\\s*" . l:openmarker
        let l:matchline = search(l:expression, l:options)
        " echo printf("line: %2s had expression: %s", l:matchline, l:expression)
        return l:matchline
    endfu " }}}

    fu traits.OpenNode(label) dict " {{{
        let l:nodefound = self.find_node(a:label)
        if l:nodefound
            normal zv
            return 1
        endif
        return 0
    endfu " }}}

    fu traits.CloseNode(label) dict " {{{
        let l:nodefound = self.find_node(a:label)
        if l:nodefound
            normal zc
            return 1
        endif
        return 0
    endfu " }}}

    fu traits.InsertNode(label) dict " {{{
        let l:origview = winsaveview()
        call append(line(".") - 1, [""])
        normal k
        call AppendText(a:label)
        call FoldWrap()
        call OpenNode(a:label)
        call winrestview(l:origview)
    endfu " }}}

    fu traits.FoldWrap() dict " {{{
        " appending closemarker first to prevent ruining current folds
        call append(line("."), CommentedFoldMarkerClose())
        call append(line("."), [CommentedFoldMarkerOpen(), ""])
        " BUG: J on a line above an open comment line destroys subsequent fold states in the document unless there is a closed fold immediately above.
        " normal Jj
        normal 0"td$"_dd0"tPj
    endfu " }}}

    fu traits.FoldMarkerOpen() dict " {{{
        return substitute(&foldmarker, ",.*", "", "")
    endfu " }}}

    fu traits.FoldMarkerClose() dict " {{{
        return substitute(&foldmarker, ".*,", "", "")
    endfu " }}}

    fu traits.FoldInsert() dict " {{{
        normal O
        call FoldWrap()
    endfu " }}}

    fu traits.FoldUnfolded() " {{{
        silent! normal zc
    endfu " }}}

    fu traits.FoldDefaultNodes() dict " {{{
        " Save position
        let l:origview = winsaveview()
        " Do work
        normal gg
        normal zR
        let l:hasnext = 1
        while (l:hasnext)
            let l:currentline = line(".")
            call FoldNodeIfDefault()
            silent! normal zj
            let l:hasnext = l:currentline != line(".")
        endwhile
        " Restore position
        call winrestview(l:origview)
    endfu " }}}

    fu traits.FoldNodeIfDefault() dict " {{{
        let l:isdone = match(getline("."), '^done.* {{') > -1
        let l:hasat = match(getline("."), '^@.* {{') > -1
        let l:allcaps = match(getline("."), '^[A-Z]* {{') > -1
        let l:isrecurring = match(getline("."), '^(.).* {{') > -1
        " echo printf("isdone: %s, hasat: %s, allcap: %s", l:isdone, l:hasat, l:allcaps)
        if (l:hasat)
            return
        endif
        if (l:isrecurring)
            return
        endif
        if (l:allcaps)
            return
        endif
        if (l:isdone)
        endif
        normal zc
    endfu " }}}

    fu traits.CommentedFoldMarkerOpen() dict " {{{
        let fcms = CommentStringFull()
        return substitute(fcms, '%s', FoldMarkerOpen(), 'g')
    endfu " }}}

    fu traits.CommentedFoldMarkerClose() dict " {{{
        let fcms = CommentStringFull()
        let rawclosemarker = substitute(fcms, '%s', FoldMarkerClose(), 'g')
        return text#strip_front(rawclosemarker)
    endfu " }}}


    " Commentmarkers:
    fu traits.CommentStringOpen() dict " {{{
        return substitute(CommentStringFull(), "%s.*", "", "")
    endfu " }}}

    fu traits.CommentStringClose() dict " {{{
        return substitute(CommentStringFull(), ".*%s", "", "")
    endfu " }}}

    fu traits.ExpandedCommentString() dict " {{{
        return text#strip_front(substitute(CommentStringFull(), "%s", "", ""))
    endfu " }}}

    fu traits.CommentStringFull() dict " {{{
        return len(&commentstring) > 0 ? &commentstring : " %s"
    endfu " }}}

    return traits
endfun " }}}
