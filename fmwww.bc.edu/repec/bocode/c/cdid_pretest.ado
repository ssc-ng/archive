*! version 1.0.0.0  16nov2026
*! cdid_pretest: conditional pretrend Cramer-von Mises test
program define cdid_pretest, rclass
    version 19.5
    local sort0 `"`c(sortrngstate)'"'
    local rng0 `"`c(rngstate)'"'
    tempname prior_r held result ordinary stats draws family grid usercheck
    tempvar heldsample rawweight
    local held_e=0
    local preserved=0
    local made_result=0
    local made_ordinary=0
    local made_user=0
    local n_callbacks=0
    local store ""
    _return hold `prior_r'
    capture noisily {
        // Mode is resolved before active variables or appended chained inputs.
        syntax [anything(name=request)] [if] [in] [iweight], ///
            [TIME(string) GVAR(string) IVAR(string) COVARS(string) NOCONStant ///
            MODE(string) PANEL(string) RCS ALLOWUNBALANCED(string) METHOD(string) ///
            CALLBACK(string) PAYLOAD(string) ///
            CONTROLgroup(string) WVAR(string) CLUSTER(string) ///
            BSTRAP(string) CBAND(string) BITERS(string) Level(string) PL(string) CORES(string) ///
            ANTICIPation(string) BASEperiod(string) FIXWEIGHTS(string) ///
            FRAME(string) FRAMEIVAR(string) FRAMEGVAR(string) FRAMECOVARS(string) FRAMEWVAR(string) FRAMECLUSTER(string) ///
            SELECTION(string) SELMODEL(string) SELPOOLING(string) SELCOVARS(string) FRAMESELCOVARS(string) ///
            SELNOCONStant SELCONStant SELZERO SELUNIVERSE(string) SELRHO(string) SELJUSTIFICATION(string) ///
            SELMETHOD(string) IMPPOOLING(string) OUTCOMEPOOLING(string) WORKSPACE(string) CHUNK(string) WORKCAP(string) ///
            SIGNS(name) POSTING(string) STORE(name) SAVING(string)]
        foreach option in request time gvar ivar covars noconstant if in weight exp mode panel rcs allowunbalanced method callback payload controlgroup wvar cluster clustervars bstrap cband biters level pl cores anticipation baseperiod fixweights frame frameivar framegvar framecovars framewvar framecluster selection selmodel selpooling selcovars frameselcovars selnoconstant selconstant selzero seluniverse selrho seljustification selmethod imppooling outcomepooling workspace chunk workcap posting store saving {
            local raw_`option' `"``option''"'
        }
        quietly mata: mata mlib index
        local mode=strlower(strtrim("`mode'"))
        if !inlist("`mode'","","chained","ordinary") {
            display as error "mode() must be chained or ordinary"
            exit 198
        }
        local panel=strlower(strtrim("`panel'"))
        if "`panel'"=="true" local panel "1"
        if "`panel'"=="false" local panel "0"
        if "`panel'"=="" local panel=cond("`rcs'"!="","0","1")
        if !inlist("`panel'","0","1") {
            display as error "panel() must be true or false (1 or 0)"
            exit 198
        }
        if "`rcs'"!="" & "`panel'"!="0" {
            display as error "rcs (repeated cross-sections) cannot be combined with panel(true)"
            exit 198
        }
        if "`mode'"=="" local mode=cond("`panel'"=="1","chained","ordinary")
        if "`method'"=="" local method "ipw"
        local method=strlower(strtrim("`method'"))
        if !inlist("`method'","ipw","reg","dr","custom") {
            display as error "method() must be ipw, reg, dr or custom"
            exit 198
        }
        if "`method'"!="custom" & (`"`callback'"'!="" | `"`payload'"'!="") {
            display as error "callback() and payload() require method(custom)"
            exit 198
        }
        if "`method'"=="custom" & "`mode'"=="ordinary" {
            mata: cdid_custom_validate_symbols(st_local("callback"),st_local("payload"))
        }
        if "`controlgroup'"=="" local controlgroup "nevertreated"
        local controlgroup=strlower(strtrim("`controlgroup'"))
        if !inlist("`controlgroup'","nevertreated","notyettreated") {
            display as error "controlgroup() must be nevertreated or notyettreated"
            exit 198
        }
        local allowunbalanced=strlower(strtrim("`allowunbalanced'"))
        if "`allowunbalanced'"=="true" local allowunbalanced "1"
        if "`allowunbalanced'"=="false" local allowunbalanced "0"
        if "`allowunbalanced'"!="" & !inlist("`allowunbalanced'","0","1") {
            display as error "allowunbalanced() must be true or false (1 or 0)"
            exit 198
        }
        local allow_supplied=("`allowunbalanced'"!="")
        if "`bstrap'"=="" local bstrap "1"
        if "`cband'"=="" local cband "1"
        if !inlist("`bstrap'","0","1") {
            display as error "bstrap() must be 0 or 1"
            exit 198
        }
        if !inlist("`cband'","0","1") {
            display as error "cband() must be 0 or 1"
            exit 198
        }
        if "`biters'"=="" local biters "1000"
        if "`level'"=="" local level "95"
        if "`pl'"=="" local pl "0"
        if "`cores'"=="" local cores "1"
        capture confirm integer number `biters'
        if _rc | `biters'<1 {
            display as error "biters() must be a positive integer"
            exit 198
        }
        capture confirm number `level'
        if _rc | `level'<=0 | `level'>=100 {
            display as error "level() must be between 0 and 100"
            exit 198
        }
        capture confirm integer number `cores'
        if _rc | `cores'<1 {
            display as error "cores() must be a positive integer"
            exit 198
        }
        if !inlist("`pl'","0","1") {
            display as error "pl() must be 0 or 1"
            exit 198
        }
        if `pl' | `cores'!=1 {
            display as error "cdid_pretest runs serially; pl(1) and cores() greater than 1 are not available"
            exit 198
        }
        local alpha=cond(`level'==95,.05,1-`level'/100)
        if "`posting'"=="" local posting "matrix"
        if !inlist("`posting'","matrix","state") {
            display as error "posting() must be matrix or state"
            exit 198
        }
        if "`posting'"=="state" & "`store'"=="" {
            display as error "posting(state) requires store(name), which names the stored results"
            exit 198
        }
        mata: cdid_pt_assert_free(st_local("store"))
        if "`saving'"!="" confirm new file `"`saving'"'
        if "`weight'"!="" & "`wvar'"!="" {
            display as error "specify either iweights or wvar(), not both"
            exit 198
        }
        local clustervars `"`cluster'"'
        gettoken outcome tail : request
        if `"`covars'"'!="" & `"`tail'"'!="" {
            display as error "specify covariates either in varlist or in covars(), not both"
            exit 198
        }
        if `"`covars'"'=="" local covars `"`tail'"'
        if "`outcome'"=="" {
            display as error "outcome variable required"
            exit 198
        }
        if "`time'"=="" | "`gvar'"=="" {
            display as error "time() and gvar() are required"
            exit 198
        }
        _estimates hold `held',copy restore nullok varname(`heldsample')
        local held_e=1
        preserve
        local preserved=1
        local wtopt ""
        if "`weight'"!="" local wtopt "[`weight'`exp']"
        else if "`wvar'"!="" local wtopt "wvar(`wvar')"
        local signopt ""
        if "`signs'"!="" local signopt "signs(`signs')"
        local idopt ""
        if "`ivar'"!="" local idopt "ivar(`ivar')"
        local clusteropt ""
        if "`clustervars'"!="" local clusteropt "clustervars(`clustervars')"
        if "`mode'"=="ordinary" {
            // The chained-mode options have no effect in ordinary mode, as in R, where
            // they are not passed to the ordinary test, and are not checked here.
            // r(inactive_options) lists all of them, specified or not; the note
            // names those specified.
            foreach o in anticipation baseperiod fixweights frame frameivar framegvar framecovars framewvar framecluster ///
                selection selmodel selpooling selcovars frameselcovars seluniverse selrho seljustification selmethod ///
                imppooling outcomepooling workspace chunk workcap {
                local pt_inactive "`pt_inactive' `o'()"
                if `"`raw_`o''"'!="" local pt_specified "`pt_specified' `o'()"
            }
            foreach o in selnoconstant selconstant selzero {
                local pt_inactive "`pt_inactive' `o'"
                if "`raw_`o''"!="" local pt_specified "`pt_specified' `o'"
            }
            local pt_inactive = strtrim("`pt_inactive'")
            local pt_specified = strtrim("`pt_specified'")
            local outcomepooling ""
            local panelopt ""
            if "`panel'"=="0" local panelopt "rcs"
            local allowopt ""
            if "`allowunbalanced'"=="1" local allowopt "allowunbalanced"
            local iw ""
            local wopt ""
            if "`weight'"!="" local iw "[`weight'`exp']"
            else local wopt "`wtopt'"
            local cbopts ""
            if `"`callback'"'!="" local cbopts `"callback(`"`callback'"')"'
            if `"`payload'"'!="" local cbopts `"`cbopts' payload(`"`payload'"')"'
            _cdid_ordinary_pretest `outcome' `covars' `if' `in' `iw',time(`time') gvar(`gvar') ///
                `idopt' `panelopt' `allowopt' `wopt' `clusteropt' `noconstant' method(`method') `cbopts' ///
                controlgroup(`controlgroup') bstrap(`bstrap') cband(`cband') biters(`biters') ///
                level(`level') pl(0) cores(1) `signopt' posting(`posting') store(`ordinary')
            local made_ordinary=1
            local n_callbacks=r(n_callbacks)
            local active_bytes=1073741824
            mata: cdid_pt_from_ordinary("`ordinary'","`result'",`bstrap',`cband',floor(`active_bytes'/8))
            local made_result=1
        }
        else {
            if "`panel'"!="1" | "`allowunbalanced'"=="0" {
                display as error "chained mode requires panel data; specify mode(ordinary) for repeated cross-sections or unbalanced panels"
                error 459
            }
            if inlist("`method'","reg","dr") {
                if "`outcomepooling'"=="" local outcomepooling "separate"
                local outcomepooling=strlower(strtrim("`outcomepooling'"))
                if !inlist("`outcomepooling'","separate","pooled") {
                    display as error "outcomepooling() must be separate or pooled"
                    exit 198
                }
            }
            else local outcomepooling ""
            if "`selection'"=="" local selection "none"
            if "`selmethod'"=="" local selmethod "ipw"
            local selection=strlower(strtrim("`selection'"))
            local selmethod=strlower(strtrim("`selmethod'"))
            if !inlist("`selection'","none","conditional_mtar","corollary1") {
                display as error "selection() must be none or conditional_mtar"
                exit 198
            }
            if !inlist("`selmethod'","ipw","imputation","dr") {
                display as error "selmethod() must be ipw, imputation or dr"
                exit 198
            }
            if "`seluniverse'"=="" local seluniverse "F"
            local seluniverse=strupper(strtrim("`seluniverse'"))
            if "`selmethod'"=="ipw" {
                if "`selmodel'"=="" local selmodel "pair_logit"
                if "`selpooling'"=="" local selpooling "separate"
                local has_q=(`"`selcovars'`frameselcovars'`selnoconstant'`selconstant'`selzero'"'!="")
                mata: _cdid_pt_selection_declaration(st_local("selection"),`has_q',st_local("seluniverse"), ///
                    (st_local("selrho")!=""),(st_local("seljustification")!=""), ///
                    st_local("selmodel"),st_local("selpooling"),st_local("seljustification"))
            }
            else if "`selmethod'"=="imputation" {
                if "`method'"=="custom" {
                    display as error "method(custom) is not allowed with selmethod(imputation)"
                    error 459
                }
                if "`imppooling'"=="" local imppooling "separate"
                local imppooling=strlower(strtrim("`imppooling'"))
                if !inlist("`imppooling'","separate","within_cohort","across_cohorts") {
                    display as error "imppooling() must be separate, within_cohort or across_cohorts"
                    exit 198
                }
                if !inlist("`selection'","conditional_mtar","corollary1") | "`seluniverse'"!="F" | `"`selrho'"'!="" {
                    display as error "selmethod(imputation) requires selection(conditional_mtar), seluniverse(F) and no selrho()"
                    error 459
                }
                // Inactive observation-model/Q options under pure imputation:
                // never expand, confirm, read, validate or inherit Q.
                local selmodel "pair_logit"
                local selpooling "separate"
                local seljustification ""
                local selcovars ""
                local frameselcovars ""
                local selnoconstant ""
                local selconstant ""
                local selzero ""
            }
            else {
                if "`imppooling'"=="" local imppooling "separate"
                local imppooling=strlower(strtrim("`imppooling'"))
                if !inlist("`imppooling'","separate","within_cohort","across_cohorts") {
                    display as error "imppooling() must be separate, within_cohort or across_cohorts"
                    exit 198
                }
                if "`selmodel'"=="" local selmodel "pair_logit"
                if "`selpooling'"=="" local selpooling "separate"
                local selmodel=strlower(strtrim("`selmodel'"))
                local selpooling=strlower(strtrim("`selpooling'"))
                if !inlist("`selmodel'","pair_logit","independent_period_logit") {
                    display as error "selmodel() must be pair_logit or independent_period_logit"
                    exit 198
                }
                if !inlist("`selpooling'","separate","within_cohort","across_cohorts") {
                    display as error "selpooling() must be separate, within_cohort or across_cohorts"
                    exit 198
                }
                mata: _cdid_aug_public_gate(st_local("method"),st_local("selection"),st_local("seluniverse"), ///
                    st_local("selmodel"),st_local("selpooling"),(st_local("selrho")!=""),st_local("seljustification"))
                mata: _cdid_pt_selection_declaration(st_local("selection"),1,st_local("seluniverse"), ///
                    (st_local("selrho")!=""),(st_local("seljustification")!=""), ///
                    st_local("selmodel"),st_local("selpooling"),st_local("seljustification"))
                if "`selzero'"!="" & (`"`selcovars'`frameselcovars'"'!="" | "`selconstant'"!="") {
                    display as error "selzero (no observation-model design) cannot be combined with selcovars(), frameselcovars() or selconstant"
                    exit 198
                }
                if "`selconstant'"!="" & (`"`selcovars'`frameselcovars'"'!="" | "`selnoconstant'`selzero'"!="") {
                    display as error "selconstant (intercept-only observation model) cannot be combined with selcovars(), frameselcovars(), selnoconstant or selzero"
                    exit 198
                }
            }
            if "`anticipation'"=="" local anticipation "0"
            if "`baseperiod'"=="" local baseperiod "varying"
            if "`workspace'"=="" local workspace "1073741824"
            if "`chunk'"=="" local chunk "."
            else confirm number `chunk'
            if "`workcap'"=="" local workcap "."
            else confirm number `workcap'
            confirm integer number `anticipation'
            confirm number `workspace'
            if `anticipation'<0 {
                display as error "anticipation() must be a nonnegative integer"
                exit 198
            }
            if `workspace'<1024 | `workspace'>=. | `workspace'!=floor(`workspace') {
                display as error "workspace() must be an integer number of bytes, at least 1024"
                exit 198
            }
            if `chunk'<. & (`chunk'<1 | `chunk'!=floor(`chunk')) {
                display as error "chunk() must be a positive integer"
                exit 198
            }
            if `workcap'<. & (`workcap'<1 | `workcap'!=floor(`workcap')) {
                display as error "workcap() must be a positive integer"
                exit 198
            }
            if !inlist("`baseperiod'","varying","universal") {
                display as error "baseperiod() must be varying or universal"
                exit 198
            }
            if !inlist("`fixweights'","","first_period","base_period") {
                display as error "fixweights() must be first_period or base_period in chained mode"
                exit 198
            }
            if "`ivar'"=="" {
                display as error "chained mode requires ivar()"
                exit 198
            }
            if "`weight'"!="" {
                quietly generate double `rawweight' `exp' `if' `in'
                local wvar "`rawweight'"
            }
            local opts ""
            foreach o in frame frameivar framegvar framecovars framewvar framecluster wvar fixweights {
                if `"``o''"'!="" local opts `"`opts' `o'(``o'')"'
            }
            if "`selmethod'"!="ipw" {
                local opts `"`opts' selmethod(`selmethod') imppooling(`imppooling')"'
            }
            if "`outcomepooling'"!="" {
                local opts `"`opts' outcomepooling(`outcomepooling')"'
            }
            if "`selection'"!="none" {
                if "`selmethod'"=="imputation" {
                    local opts `"`opts' selection(`selection') seluniverse(`seluniverse')"'
                }
                else {
                    foreach o in selection selmodel selpooling seluniverse selrho seljustification selcovars frameselcovars {
                        if `"``o''"'!="" local opts `"`opts' `o'(``o'')"'
                    }
                    local opts "`opts' `selnoconstant' `selconstant' `selzero'"
                }
            }
            local cluster_vars : list retokenize clustervars
            local id_name "`ivar'"
            local extra_cluster : list cluster_vars - id_name
            local extra_count : word count `extra_cluster'
            if `extra_count'>1 {
                display as error "cluster() accepts at most one variable in addition to the unit identifier"
                exit 459
            }
            if `extra_count' {
                capture confirm variable `extra_cluster'
                if !_rc local opts "`opts' cluster(`extra_cluster')"
                else if "`frame'"!="" & "`framecluster'"=="" local opts "`opts' framecluster(`extra_cluster')"
                else if "`framecluster'"=="" error 111
            }
            if "`method'"=="custom" {
                mata: _cdid_custom_name_gate(st_local("callback"),st_local("payload"))
                mata: cdid_custom_pt_not_applicable("`result'",`biters',`alpha',`bstrap',`cband', ///
                    st_local("covars"),st_local("clustervars"),st_local("signs"),floor(`workspace'/8))
                local made_result=1
                local active_bytes=`workspace'
                local n_callbacks=0
            }
            else {
                _cdid_pretest_chained `outcome' `if' `in',ivar(`ivar') time(`time') gvar(`gvar') output(`result') ///
                    covars(`covars') `noconstant' `opts' method(`method') controlgroup(`controlgroup') ///
                    anticipation(`anticipation') baseperiod(`baseperiod') biters(`biters') alpha(`alpha') ///
                    workspace(`workspace') chunk(`chunk') workcap(`workcap') `signopt' posting(`posting') ///
                    bstrap(`bstrap') cband(`cband') clustervars(`clustervars')
                local made_result=1
                local active_bytes=`workspace'
            }
        }
        local rng_after `"`c(rngstate)'"'
        mata: cdid_pt_request_meta("`result'")
        mata: cdid_pt_export("`result'","`stats'","`draws'","`family'","`grid'",st_local("posting"),`c(max_matdim)',floor(`active_bytes'/8))
        if "`saving'"!="" mata: cdid_pt_save("`result'",st_local("saving"),floor(`active_bytes'/8))
        if "`store'"!="" {
            mata: cdid_pt_put(st_local("store"),*findexternal("`result'"),floor(`active_bytes'/8))
            local made_user=1
        }
    }
    local rc=_rc
    if `made_result' capture mata: rmexternal("`result'")
    if `made_ordinary' capture mata: rmexternal("`ordinary'")
    if `preserved' restore
    if `held_e' capture _estimates unhold `held'
    quietly set sortrngstate `sort0'
    if `rc' {
        if `made_user' capture mata: rmexternal(st_local("store"))
        _return restore `prior_r'
        return add
        exit `rc'
    }
    _return drop `prior_r'
    return clear
    local j=0
    foreach stat in N M K C B alpha CvM CvMcval CvMpval N_distinct N_rows N_requested N_input {
        local ++j
        return scalar `stat'=`stats'[1,`j']
    }
    if "`posting'"=="matrix" {
        if `pt_draws'>0 return matrix CvMb=`draws'
        if `pt_family'>0 {
            matrix colnames `family'=`pt_family_columns'
            return matrix family=`family'
        }
        if `pt_grid'>0 {
            matrix colnames `grid'=first_grid_row multiplicity
            return matrix grid=`grid'
        }
    }
    return local status "`pt_status'"
    return local reason `"`pt_reason'"'
    return local mode "`pt_mode'"
    return local method "`pt_method'"
    return local outcome_pooling "`outcomepooling'"
    return local callback `"`callback'"'
    return local payload `"`payload'"'
    return local formula `"`pt_formula'"'
    return local X_columns `"`pt_xcols'"'
    return local Z_columns `"`pt_zcols'"'
    return local clustervars `"`clustervars'"'
    return local state_token "`store'"
    return local posting "`posting'"
    return local rng "`pt_rng'"
    return local description `"`pt_policy'"'
    return local influence_function `"`pt_channel'"'
    return local grid_rule `"`pt_membership'"'
    return scalar n_callbacks=`n_callbacks'
    return scalar bstrap_requested=`bstrap'
    return scalar cband_requested=`cband'
    return scalar multipliers_used=`pt_used'
    return scalar rcs_dr_corrected_if=("`pt_mode'"=="ordinary" & "`panel'"=="0" & "`pt_method'"=="dr")
    return scalar formula_defaulted=("`pt_mode'"=="ordinary" & `"`covars'"'=="" & "`noconstant'"=="")
    return scalar id_defaulted=("`pt_mode'"=="ordinary" & "`panel'"=="0" & "`ivar'"=="")
    return scalar allowunbalanced_supplied=`allow_supplied'
    return local allowunbalanced_requested "`allowunbalanced'"
    if "`pt_inactive'"!="" return local inactive_options "`pt_inactive'"
    if "`pt_specified'"!="" {
        display as text "note: chained-mode options have no effect in ordinary mode: `pt_specified'"
    }
    _cdid_pretest_display, stats(`stats') mode(`pt_mode') method(`pt_method') status(`pt_status') ///
        reason(`"`pt_reason'"') clustervars(`clustervars')
end
