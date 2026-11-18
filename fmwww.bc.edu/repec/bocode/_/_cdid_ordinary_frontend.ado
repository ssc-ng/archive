*! Private ordinary command branch for composition into cdid; current StataNow19.5.
program define _cdid_ordinary_frontend,eclass
    version 19.5
    syntax varlist(numeric fv min=1) [if] [in] [iweight], TIME(varname numeric) GVAR(varname numeric) ///
        [IVAR(varname numeric) RCS ALLOWUNBALANCED WVAR(varname numeric) METHOD(string) ///
        CALLBACK(string) PAYLOAD(string) CONTROLgroup(string) ///
        BASEperiod(string) ANTICIPation(integer 0) FIXweights(string) CLUSTER(varname) NOINFFUNC ///
        BSTRAP(integer 1) CBAND(integer 1) BITERS(integer 1000) Level(real 95) ///
        WORKSPACE(real 1073741824) CHUNK(integer 1024) POSTING(string) SAVING(string) CMDLINE(string asis)]
    if `level'<=0 | `level'>=100 | missing(`level') {
        display as error "level() must be between 0 and 100"
        exit 198
    }
    if !inlist(`bstrap',0,1) | !inlist(`cband',0,1) {
        display as error "bstrap() and cband() must be 0 or 1"
        exit 198
    }
    if `biters'<1 | `chunk'<1 {
        display as error "biters() and chunk() must be positive integers"
        exit 198
    }
    if "`weight'"!="" & "`wvar'"!="" {
        display as error "specify either iweights or wvar(), not both"
        exit 198
    }
    if "`posting'"=="" local posting "matrix"
    if !inlist("`posting'","matrix","state") {
        display as error "posting() must be matrix or state"
        exit 198
    }
    local method_norm=cond("`method'"=="","dr",strlower(strtrim("`method'")))
    if "`method_norm'"!="custom" & (`"`callback'"'!="" | `"`payload'"'!="") {
        display as error "callback() and payload() require method(custom)"
        exit 198
    }
    if "`cluster'"=="`ivar'" local cluster ""
    local alpha=cond(`level'==95,.05,1-`level'/100)
    local compute_if=("`noinffunc'"=="")
    local sort0 `"`c(sortrngstate)'"'
    tempname held limits owner stageframe omitted prior_r ordrows
    tempvar heldsample requested evaluated generated_weight esmark
    local fit_token ""
    local final_token ""
    local made_owner=0
    local made_stage=0
    _return hold `prior_r'
    _estimates hold `held',copy restore nullok varname(`heldsample')
    capture noisily {
        quietly mark `requested' `if' `in'
        if "`cluster'"!="" quietly markout `requested' `cluster',strok
        if "`weight'"!="" {
            quietly gen double `generated_weight' `exp' if `requested'
            local wvar "`generated_weight'"
        }
        if "`method_norm'"=="custom" {
            mata: cdid_custom_validate_symbols(st_local("callback"),st_local("payload"))
            gettoken outcome formula : varlist
            local formula : list retokenize formula
            quietly generate byte `evaluated'=1
            if `"`formula'"'!="" {
                quietly fvrevar `formula'
                local evalvars `"`r(varlist)'"'
                quietly markout `evaluated' `evalvars'
            }
            local ispanel=("`rcs'"=="")
            local allow=("`allowunbalanced'"!="")
            local ctl=cond("`controlgroup'"=="","nevertreated",strlower(strtrim("`controlgroup'")))
            local bp=cond("`baseperiod'"=="","varying",strlower(strtrim("`baseperiod'")))
            local fw=strlower(strtrim("`fixweights'"))
            mata: cdid_ord_custom_intake("`owner'","`requested'","`evaluated'",st_local("outcome"), ///
                st_local("time"),st_local("gvar"),st_local("ivar"),st_local("wvar"), ///
                st_local("cluster"),st_local("formula"),1,`ispanel',`allow', ///
                st_local("ctl"),st_local("bp"),`anticipation',st_local("fw"), ///
                st_local("callback"),st_local("payload"),`workspace')
            local made_owner=1
            mata: st_matrix("`ordrows'", cdid_ord_custom_rows("`owner'"))
            frame create `stageframe'
            local made_stage=1
            frame `stageframe' {
                mata: cdid_ord_custom_stage("`owner'")
                local expanded ""
                if `"`formula'"'!="" {
                    quietly fvexpand `formula'
                    local expanded `"`r(varlist)'"'
                }
                local kept ""
                local kept_positions ""
                local position=0
                mata: `omitted'=J(1,0,0)
                foreach term of local expanded {
                    local ++position
                    quietly _ms_parse_parts `term'
                    local omit=r(omit)
                    mata: `omitted'=`omitted',`omit'
                    if !`omit' {
                        local kept `"`kept' `term'"'
                        local kept_positions `"`kept_positions' `position'"'
                    }
                }
                local generated ""
                if `"`kept'"'!="" {
                    // convert the complete expansion so that every level keeps its base
                    quietly fvrevar `expanded'
                    local full_generated `"`r(varlist)'"'
                    foreach position of local kept_positions {
                        local generated `"`generated' `: word `position' of `full_generated''"'
                    }
                }
                mata: cdid_ord_custom_encode("`owner'",st_local("generated"),st_local("expanded"),`omitted')
            }
            frame drop `stageframe'
            local made_stage=0
            mata: st_local("fit_token",cdid_ord_custom_fit_store("`owner'",st_local("limits"), ///
                `alpha',`bstrap',`cband',`biters',`compute_if',`chunk',`workspace'))
        }
        else {
            local options ""
            foreach opt in ivar wvar method controlgroup baseperiod fixweights {
                if "``opt''"!="" local options "`options' `opt'(``opt'')"
            }
            _cdid_ordinary `varlist' if `requested',time(`time') gvar(`gvar') `options' ///
                `rcs' `allowunbalanced' anticipation(`anticipation')
            matrix `ordrows' = r(sample_rows)
            mata: st_local("fit_token",cdid_ord_frontend_build(st_local("cluster"),st_local("ivar"), ///
                (st_local("rcs")!=""),`compute_if',`bstrap',`cband',`biters',`alpha',`chunk',`workspace',st_local("limits")))
        }
        gettoken ord_depvar ord_covariates : varlist
        mata: st_local("fit_token",cdid_state_bind_text(st_local("fit_token"),"",st_local("limits"), ///
            ("depvar",st_local("ord_depvar") \ "time_name",st_local("time") \ "gvar_name",st_local("gvar") \ ///
            "covariate_names",strtrim(st_local("ord_covariates")) \ "ord.method",st_local("method_norm") \ ///
            "ivar_name",st_local("ivar") \ "cmdline",substr(st_local("cmdline"),3,max((0,strlen(st_local("cmdline"))-4))))))
        local saveopt ""
        if `"`saving'"'!="" local saveopt `"saving(`"`saving'"')"'
        _cdid_ordinary_post,token("`fit_token'") limits(`limits') posting(`posting') `saveopt'
        local final_token `"`e(state_token)'"'
        ereturn local cmd "cdid"
        ereturn local mode "ordinary"
        ereturn local method "`method_norm'"
        if "`method_norm'"=="custom" {
            ereturn local callback `"`callback'"'
            ereturn local payload `"`payload'"'
        }
        ereturn local estat_cmd "cdid_estat"
        ereturn local depvar "`: word 1 of `varlist''"
        ereturn local source_state_token ""
        quietly generate byte `esmark' = 0
        mata: cdid_mark_rows("`esmark'", st_matrix("`ordrows'"))
        ereturn repost, esample(`esmark')
        _cdid_post_finish, title("Difference-in-differences (ordinary mode)") endpoint(cells) ///
            ivar(`ivar') time(`time') gvar(`gvar') clustvar(`cluster') covariates(`ord_covariates')
        mata: cdid_ord_replay(st_global("e(state_token)"))
        _estimates unhold `held',not
    }
    local rc=_rc
    if `made_stage' capture frame drop `stageframe'
    if `made_owner' capture mata: rmexternal("`owner'")
    capture mata: mata drop `omitted'
    if `"`fit_token'"'!="" capture mata: cdid_state_drop(st_local("fit_token"))
    capture mata: rmexternal(st_local("limits"))
    if `rc' {
        if `"`final_token'"'!="" capture mata: cdid_state_drop(st_local("final_token"))
        capture _estimates unhold `held'
    }
    _return restore `prior_r'
    quietly set sortrngstate `sort0'
    if `rc' exit `rc'
end
