*! version 1.0.0.0  16nov2026
*! cdid_chain: identification chains and GMM comparison weights after cdid
program cdid_chain, rclass
    version 19.5
    if "`e(cmd)'"=="cdid" & "`e(design)'"=="static" {
        display as error "cdid_chain is not available after dvar() estimation; see {help cdid##dvar:dvar()}"
        exit 198
    }
    syntax [, Cohort(numlist) Time(numlist) PRE TOL(real 1e-10) WEIGHTS SAVing(string asis) TABle(string)]
    if "`e(cmd)'"!="cdid" {
        display as error "last estimates not found; cdid_chain requires cdid estimation results"
        exit 301
    }
    if "`e(mode)'"!="chained" {
        display as error "cdid_chain requires results from cdid in chained mode"
        exit 198
    }
    if "`e(preset)'"!="" {
        display as error "cdid_chain is not available after preset(`e(preset)'), whose estimates do not come from chained comparisons"
        exit 498
    }
    if `tol'<0 | missing(`tol') {
        display as error "tol() must be a nonnegative number"
        exit 198
    }
    capture mata: _cdid_mlib_ready()
    if _rc quietly mata: mata mlib index
    local table=strlower(strtrim("`table'"))
    if "`table'"!="" & `"`saving'"'=="" {
        display as error "table() requires saving()"
        exit 198
    }
    if `"`saving'"'!="" {
        if "`table'"=="" local table "summary"
        if !inlist("`table'","summary","witness","weights") {
            display as error "table() must be summary, witness, or weights"
            exit 198
        }
        gettoken sfile sopts : saving, parse(",")
        local sopts=strtrim(subinstr(`"`sopts'"',",","",1))
        if !inlist(`"`sopts'"',"","replace") {
            display as error "saving() allows only the replace suboption"
            exit 198
        }
        tempname fr
        frame create `fr'
        frame `fr' {
            mata: cdid_chain_table("`table'","`cohort'","`time'",`=("`pre'"!="")',`tol')
            save `sfile', `sopts'
        }
        frame drop `fr'
    }
    mata: cdid_chain_show("`cohort'","`time'",`=("`pre'"!="")',`tol',`=("`weights'"!="")')
    // return only the results of cdid_chain
    foreach s in n_cells n_available n_chained n_moments overid_df {
        local r_`s' = r(`s')
    }
    local r_kind "`r(kind)'"
    return clear
    foreach s in n_cells n_available n_chained n_moments overid_df {
        if !missing(`r_`s'') return scalar `s' = `r_`s''
    }
    return local kind "`r_kind'"
end
