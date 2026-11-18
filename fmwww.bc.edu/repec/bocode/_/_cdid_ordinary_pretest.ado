*! Private ordinary conditional-pretest consumer; no standalone default-mode binding.
program define _cdid_ordinary_pretest, rclass
    version 19.5
    local sort0 `"`c(sortrngstate)'"'
    tempname prior_r held input stats draws family mult omitted gridframe
    tempvar heldsample requested evaluated rawweight ordervar groupvar gridmark
    local held_e=0
    local preserved=0
    local made_grid=0
    local made_input=0
    local made_store=0
    local store ""
    _return hold `prior_r'
    capture noisily {
        syntax varlist(numeric fv min=1) [if] [in] [iweight], TIME(varname numeric) GVAR(varname numeric) ///
            [IVAR(varname) RCS ALLOWUNBALANCED WVAR(varname numeric) METHOD(string) ///
            CONTROLgroup(string) CLUSTERVARS(varlist) NOCONStant CALLBACK(string) PAYLOAD(string) ///
            BSTRAP(integer 1) CBAND(integer 1) BITERS(integer 1000) Level(real 95) ///
            PL(integer 0) CORES(integer 1) WORKSPACE(real 1073741824) CHUNK(integer 1024) ///
            SIGNS(name) POSTING(string) STORE(name)]
        if "`method'"=="" local method "ipw"
        if "`controlgroup'"=="" local controlgroup "nevertreated"
        if "`posting'"=="" local posting "matrix"
        if !inlist("`method'","ipw","reg","dr","custom") error 198
        if "`method'"!="custom" & (`"`callback'"'!="" | `"`payload'"'!="") {
            display as error "callback() and payload() require method(custom)"
            exit 198
        }
        if "`method'"=="custom" {
            mata: cdid_custom_validate_symbols(st_local("callback"),st_local("payload"))
        }
        if !inlist("`controlgroup'","nevertreated","notyettreated") error 198
        if !inlist(`bstrap',0,1) | !inlist(`cband',0,1) | !inlist(`pl',0,1) error 198
        if `cores'<1 | `biters'<1 | `chunk'<1 | `level'<=0 | `level'>=100 | missing(`level') error 198
        if `workspace'<1024 | missing(`workspace') | `workspace'!=floor(`workspace') error 198
        if `pl' | `cores'!=1 {
            display as error "cdid_pretest runs serially; pl(1) and cores() greater than 1 are not available"
            exit 198
        }
        if !inlist("`posting'","matrix","state") error 198
        if "`posting'"=="state" & "`store'"=="" {
            display as error "posting(state) requires store(name), which names the stored results"
            exit 198
        }
        if "`weight'"!="" & "`wvar'"!="" {
            display as error "specify either iweights or wvar(), not both"
            exit 198
        }
        if "`rcs'"=="" & "`ivar'"=="" {
            display as error "panel data require ivar(); specify rcs for repeated cross-sections"
            exit 198
        }
        local ispanel=("`rcs'"=="")
        local allow=("`allowunbalanced'"!="")
        local intercept=("`noconstant'"=="")
        local alpha=cond(`level'==95,.05,1-`level'/100)
        gettoken outcome formula : varlist
        local formula : list retokenize formula
        mata: st_local("op_raw",invtokens(cdid_ref_formula_names(st_local("formula"))))
        _estimates hold `held',copy restore nullok varname(`heldsample')
        local held_e=1
        preserve
        local preserved=1
        quietly mark `requested' `if' `in'
        if "`weight'"!="" {
            quietly generate double `rawweight' `exp' if `requested'
            local wvar "`rawweight'"
        }
        quietly generate double `ordervar'=.
        quietly generate double `groupvar'=.
        /* Grid factors retain the outer input level catalogue; nuisance factors
           drop globally empty retained levels through their separate expansion. */
        local gridexpanded ""
        if `"`formula'"'!="" {
            quietly fvexpand `formula' if `requested'
            local gridexpanded `"`r(varlist)'"'
        }
        quietly generate byte `evaluated'=1
        if `"`formula'"'!="" {
            quietly fvrevar `formula'
            local evalvars `"`r(varlist)'"'
            quietly markout `evaluated' `evalvars'
        }
        mata: cdid_op_intake("`input'","`requested'","`evaluated'",st_local("outcome"),st_local("time"), ///
            st_local("gvar"),st_local("ivar"),st_local("wvar"),st_local("clustervars"), ///
            st_local("formula"),`ispanel',`allow',`intercept',st_local("method"), ///
            st_local("controlgroup"),floor(`workspace'/8),"`ordervar'","`groupvar'", ///
            st_local("callback"),st_local("payload"))
        local made_input=1
        if `op_varying_w' display as text "Time-varying raw weights: each ordinary comparison uses its earlier-period weight."
        quietly keep if !missing(`ordervar')
        quietly sort `ordervar'
        quietly replace `gvar'=`groupvar'
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
        mata: cdid_op_encode("`input'",0,st_local("generated"),st_local("expanded"),`omitted')
        quietly generate byte `gridmark'=0
        mata: cdid_op_gridmark("`input'","`gridmark'")
        frame put `gridmark' `op_raw' if `gridmark',into(`gridframe')
        local made_grid=1
        frame `gridframe' {
            local kept ""
            local kept_positions ""
            local position=0
            mata: `omitted'=J(1,0,0)
            foreach term of local gridexpanded {
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
                quietly fvrevar `gridexpanded'
                local full_generated `"`r(varlist)'"'
                foreach position of local kept_positions {
                    local generated `"`generated' `: word `position' of `full_generated''"'
                }
            }
            mata: cdid_op_encode("`input'",1,st_local("generated"),st_local("gridexpanded"),`omitted')
        }
        frame drop `gridframe'
        local made_grid=0
        local rng "caller"
        if "`signs'"!="" local rng "fixed"
        mata: cdid_op_execute("`input'",`biters',`alpha',`chunk',`workspace',st_local("rng"), ///
            st_local("signs"),st_local("posting"),st_local("store"),`c(max_matdim)',"`stats'","`draws'","`family'","`mult'")
        if "`store'"!="" local made_store=1
    }
    local rc=_rc
    if `made_grid' capture frame drop `gridframe'
    if `preserved' restore
    if `held_e' capture _estimates unhold `held'
    if `made_input' capture mata: cdid_op_drop("`input'")
    capture mata: mata drop `omitted'
    quietly set sortrngstate `sort0'
    if `rc' {
        if `made_store' capture mata: cdid_op_drop(st_local("store"))
        _return restore `prior_r'
        return add
        exit `rc'
    }
    _return drop `prior_r'
    return clear
    local i=0
    foreach stat in N M K C B alpha CvM CvMcval CvMpval N_distinct N_rows N_requested N_input {
        local ++i
        return scalar `stat'=`stats'[1,`i']
    }
    if "`posting'"=="matrix" {
        if "`op_status'"=="available" return matrix CvMb=`draws'
        matrix colnames `family'=cell group time base unavailable
        matrix colnames `mult'=first_grid_row multiplicity
        return matrix family=`family'
        return matrix grid=`mult'
    }
    return scalar bstrap_requested=`bstrap'
    return scalar cband_requested=`cband'
    return scalar multipliers_used=("`op_status'"=="available")
    return scalar rcs_dr_corrected_if=(!`ispanel' & "`method'"=="dr")
    return scalar formula_defaulted=(`"`formula'"'=="" & `intercept')
    return scalar id_defaulted=(!`ispanel' & "`ivar'"=="")
    return scalar n_callbacks=`op_n_callbacks'
    return local status "`op_status'"
    return local reason `"`op_reason'"'
    return local family_reasons `"`op_family_reasons'"'
    return local mode "ordinary"
    return local method "`method'"
    return local callback `"`callback'"'
    return local payload `"`payload'"'
    return local panel_mode "`=cond(`ispanel',"panel","rcs")'"
    return local control_group "`controlgroup'"
    return local formula `"`formula'"'
    return local X_columns `"`op_xcols'"'
    return local Z_columns `"`op_zcols'"'
    return local clustervars `"`clustervars'"'
    return local state_token "`store'"
    return local posting "`posting'"
    return local grid_rule `"`op_membership'"'
    return local influence_function `"`op_channel'"'
    return local rng "`rng'"
    return local reference "did 2.5.1 conditional pretrend test (Callaway and Sant'Anna)"
    return local reducer "unstandardized Cramer-von Mises statistic with cluster sums; p-value is the share of bootstrap draws strictly above it; critical value is the type-1 bootstrap quantile"
end
