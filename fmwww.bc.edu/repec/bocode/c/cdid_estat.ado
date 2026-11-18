*! version 1.0.0.0  16nov2026
*! estat after cdid: simple, group, dynamic and calendar aggregations
program define cdid_estat,eclass
    version 19.5
    if "`e(cmd)'"=="cdid" & "`e(design)'"=="static" {
        display as error "estat simple, group, dynamic and calendar are not available after dvar() estimation"
        display as error "{p 4 4 2}The switcher-weighted average effect is stored in e(att) and e(se_att); cdid_export, type(aggregate) exports it and type(cells) exports the cells. See {help cdid##dvar:dvar()}.{p_end}"
        exit 321
    }
    if "`e(cmd)'"!="cdid" | !inlist("`e(mode)'","ordinary","chained") error 301
    syntax anything(name=type), [MINE(string) MAXE(string) BALANCEE(string) NARM ///
        BSTRAP(string) CBAND(integer -1) BITERS(string) Level(string) CLUSTER(string) ///
        WORKSPACE(real 1073741824) CHUNK(integer 1024) POSTING(string) SAVING(string)]
    if !inlist("`type'","simple","group","dynamic","calendar") {
        display as error "estat after cdid requires simple, group, dynamic, or calendar"
        exit 198
    }
    if "`e(mode)'"=="ordinary" {
        if "`bstrap'"=="" local bstrap -1
        else confirm integer number `bstrap'
        foreach numeric_option in mine maxe balancee biters level {
            if "``numeric_option''"=="" local `numeric_option' "."
            else if !inlist("``numeric_option''",".",".a",".b") confirm number ``numeric_option''
        }
        if `mine'==. local mine=.b
        if `maxe'==. local maxe=.a
        local options ""
        foreach opt in cluster posting {
            if "``opt''"!="" local options "`options' `opt'(``opt'')"
        }
        if `"`saving'"'!="" local options `"`options' saving(`"`saving'"')"'
        local prior_cmdline `"`e(cmdline)'"'
        _cdid_ordinary_aggregate,type(`type') mine(`mine') maxe(`maxe') balancee(`balancee') `narm' ///
            bstrap(`bstrap') cband(`cband') biters(`biters') level(`level') workspace(`workspace') chunk(`chunk') `options'
        if `"`prior_cmdline'"'!="" ereturn local cmdline `"`prior_cmdline'"'
        ereturn local estat_cmdline `"estat `0'"'
        exit
    }
    if "`bstrap'"=="" local bstrap "-1"
    else if !inlist("`bstrap'","-1","0","1",".") {
        confirm number `bstrap'
    }
    foreach numeric_option in mine maxe balancee level {
        if "``numeric_option''"=="" local `numeric_option' "."
        else if inlist("``numeric_option''",".",".a",".b") local `numeric_option' "."
        else confirm number ``numeric_option''
    }
    if "`biters'"=="" local biters "-1"
    else if inlist("`biters'",".",".a",".b") local biters "."
    else confirm number `biters'
    local options ""
    foreach opt in cluster posting {
        if "``opt''"!="" local options "`options' `opt'(``opt'')"
    }
    if `"`saving'"'!="" local options `"`options' saving(`"`saving'"')"'
    _cdid_chained_aggregate,type(`type') mine(`mine') maxe(`maxe') balancee(`balancee') `narm' ///
        bstrap(`bstrap') cband(`cband') biters(`biters') level(`level') workspace(`workspace') chunk(`chunk') `options' finish
    ereturn local estat_cmdline `"estat `0'"'
end
