*! Private ordinary no-refit aggregation transaction.
program define _cdid_ordinary_aggregate,eclass
    version 19.5
    syntax, TYPE(string) [TOKEN(string) MINE(string) MAXE(string) BALANCEE(string) NARM ///
        BSTRAP(integer -1) CBAND(integer -1) BITERS(string) Level(string) CLUSTER(string) ///
        WORKSPACE(real 1073741824) CHUNK(integer 1024) POSTING(string) SAVING(string)]
    foreach numeric_option in mine maxe balancee biters level {
        if "``numeric_option''"=="" local `numeric_option' "."
        else if !inlist("``numeric_option''",".",".a",".b") confirm number ``numeric_option''
    }
    if "`token'"=="" local token `"`e(state_token)'"'
    if "`posting'"=="" local posting "matrix"
    if "`cluster'"=="" local cluster "inherit"
    if !inlist(`bstrap',-1,0,1) {
        display as error "bstrap() must be 0 or 1"
        exit 198
    }
    if !inlist(`cband',-1,0,1) {
        display as error "cband() must be 0 or 1"
        exit 198
    }
    if `chunk'<1 {
        display as error "chunk() must be a positive integer"
        exit 198
    }
    if `workspace'<=0 | missing(`workspace') {
        display as error "workspace() must be a positive number of bytes"
        exit 198
    }
    if !missing(`biters') & (`biters'<1 | `biters'!=floor(`biters')) {
        display as error "biters() must be a positive integer"
        exit 198
    }
    if !missing(`level') & (`level'<=0 | `level'>=100) {
        display as error "level() must be between 0 and 100"
        exit 198
    }
    if `mine'==. local mine=.b
    if `maxe'==. local maxe=.a
    foreach item in ivar time gvar depvar method covariates {
        local prior_`item' `"`e(`item')'"'
    }
    // The retained fit supplies the cluster name even after a unit-level aggregation.
    // An unavailable request goes to the ordinary consumer for unit-level inference.
    mata: st_local("fit_cluster", _cdid_ord_fit_cluster(st_local("token")))
    local cluster = strtrim("`cluster'")
    if "`cluster'"!="`fit_cluster'" {
        if strlower("`cluster'")=="none" | ("`prior_ivar'"!="" & "`cluster'"=="`prior_ivar'") local cluster ""
    }
    local sort0 `"`c(sortrngstate)'"'
    tempname held limits
    tempvar heldsample fitsample
    local fit_token ""
    local final_token ""
    _estimates hold `held',copy restore nullok varname(`heldsample')
    capture noisily {
        mata: st_local("fit_token",cdid_ord_consumer_aggregate(st_local("token"),st_local("type"), ///
            `mine',`maxe',`balancee',("`narm'"!=""),`bstrap',`cband',`biters',`level', ///
            `workspace',`chunk',st_local("cluster"),st_local("limits")))
        local saveopt ""
        if `"`saving'"'!="" local saveopt `"saving(`"`saving'"')"'
        quietly generate byte `fitsample' = e(sample)
        _cdid_ordinary_post,token("`fit_token'") limits(`limits') posting(`posting') `saveopt'
        local final_token `"`e(state_token)'"'
        ereturn repost, esample(`fitsample')
        ereturn local cmd "cdid"
        ereturn local estat_cmd "cdid_estat"
        _cdid_post_finish, title("Difference-in-differences (ordinary mode): `type' aggregation") ///
            endpoint(`type') ivar(`prior_ivar') time(`prior_time') gvar(`prior_gvar') clustvar(`fit_cluster') ///
            depvar(`prior_depvar') method(`prior_method') covariates(`prior_covariates')
        mata: cdid_ord_replay(st_global("e(state_token)"))
        _estimates unhold `held',not
    }
    local rc=_rc
    if `"`fit_token'"'!="" capture mata: cdid_state_drop(st_local("fit_token"))
    capture mata: rmexternal(st_local("limits"))
    if `rc' {
        if `"`final_token'"'!="" capture mata: cdid_state_drop(st_local("final_token"))
        capture _estimates unhold `held'
    }
    quietly set sortrngstate `sort0'
    if `rc' exit `rc'
end
