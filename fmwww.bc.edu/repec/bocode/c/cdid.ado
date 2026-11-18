*! version 1.0.0.0  16nov2026
*! cdid: chained and ordinary difference-in-differences
program define cdid, eclass
    version 19.5
    if replay() {
        if "`e(cmd)'"!="cdid" error 301
        syntax
        local replay_sort `"`c(sortrngstate)'"'
        capture noisily {
            capture mata: _cdid_mlib_ready()
if _rc quietly mata: mata mlib index
            if "`e(design)'"=="static" mata: cdid_static_display()
            else if "`e(mode)'"=="ordinary" mata: cdid_ord_replay(st_global("e(state_token)"))
            else if "`e(result_kind)'"=="aggregation" mata: cdid_chained_agg_replay(st_global("e(state_token)"))
            else mata: cdid_frontend_display(st_global("e(state_token)"))
            if "`e(mode)'"=="chained" & "`e(result_kind)'"!="aggregation" capture noisily mata: cdid_mref_note()
        }
        local replay_rc=_rc
        quietly set sortrngstate `replay_sort'
        if `replay_rc' exit `replay_rc'
        exit
    }
    local caller_cmdline `"cdid `0'"'
    // Preserve ordinary's bare flag and chained's explicit Boolean spelling.
    // bind keeps option parentheses/quoted contents together; only the option token changes.
    syntax anything(name=initial_varlist id="varlist") [if] [in] [iweight], [*]
    local normalized_options ""
    local remaining `"`options'"'
    while `"`remaining'"'!="" {
        gettoken option_token remaining : remaining, bind
        if strlower(`"`option_token'"')=="allowunbalanced" {
            local lookahead `"`remaining'"'
            gettoken next_token lookahead : lookahead, bind
            if substr(strtrim(`"`next_token'"'),1,1)!="(" local option_token "allowunbalanced(true)"
        }
        local normalized_options `"`normalized_options' `option_token'"'
    }
    local initial_weight ""
    if "`weight'"!="" local initial_weight "[`weight'`exp']"
    local 0 `"`initial_varlist' `if' `in' `initial_weight', `normalized_options'"'
    local full_0 `"`0'"'
    syntax anything(name=static_varlist id="varlist") [if] [in] [iweight], [DVAR(string) MISSINGREFerence(string) *]
    if `"`dvar'"'!="" {
        if `"`missingreference'"'!="" {
            local mref_dvar=strlower(strtrim(`"`missingreference'"'))
            if !inlist("`mref_dvar'","exclude","error") {
                display as error "missingreference() must be exclude or error"
                exit 198
            }
            if "`mref_dvar'"=="exclude" {
                display as error "missingreference(exclude) is not available with dvar(); omit missingreference() or specify missingreference(error)"
                exit 198
            }
            local full_0 `"`static_varlist' `if' `in' `initial_weight', dvar(`dvar') `options'"'
        }
        _cdid_static `full_0'
        ereturn local cmdline `"`caller_cmdline'"'
        exit
    }
    local 0 `"`full_0'"'
    syntax anything(name=raw_varlist id="varlist") [if] [in] [iweight], TIME(varname numeric) GVAR(varname numeric) ///
        [IVAR(varname) COVARS(string) NOCONStant FRAME(name) FRAMEIVAR(name) FRAMEGVAR(name) FRAMECOVARS(string) WVAR(varname numeric) ///
        FRAMEWVAR(name) FIXWEIGHTS(string) METHOD(string) CALLBACK(string) PAYLOAD(string) ///
        CONTROLgroup(string) ANTICIPation(integer 0) ///
        BASEperiod(string) PTASSUMPTION(string) PTSTART(string) TARGETS(name) TARGETCOHORTS(numlist) ///
        GMMWEIGHTING(string) GMMCOVARIANCE(string) NOINFFUNC ///
        BSTRAP(real 1) CBAND(integer 1) BITERS(integer 1000) Level(real 95) WORKSPACE(real 1073741824) ///
        CHUNK(string) WORKCAP(string) CONDITION(real 1e-10) RIDGE(real 1e-4) POSTING(string) SAVING(string) ///
        MODE(string) RCS PANEL(string) ALLOWUNBALANCED(string) ///
        SELECTION(string) SELMODEL(string) SELPOOLING(string) ///
        SELCOVARS(string) FRAMESELCOVARS(string) SELNOCONStant SELCONStant SELZERO ///
        SELUNIVERSE(string) SELRHO(string) SELJUSTIFICATION(string) ///
        SELMETHOD(string) IMPPOOLING(string) OUTCOMEPOOLING(string) ///
        CLUSTER(varname) FRAMECLUSTER(name) KEEPNUISANCE CROSSpair PRESET(string) MISSINGREFerence(string)]
    local mode=strlower(strtrim("`mode'"))
    local preset=strlower(strtrim("`preset'"))
    if "`preset'"!="" {
        if "`preset'"!="cohort_time_fe" {
            display as error "preset() must be cohort_time_fe"
            exit 198
        }
        if "`mode'"=="ordinary" | "`rcs'"!="" | "`crosspair'"!="" {
            display as error "preset(cohort_time_fe) requires chained mode without crosspair"
            exit 198
        }
        if strlower(strtrim("`method'"))=="custom" {
            display as error "preset(cohort_time_fe) requires method(reg), method(ipw), or method(dr)"
            exit 198
        }
        if "`weight'"!="" | "`wvar'"!="" | "`framewvar'"!="" | "`fixweights'"!="" {
            display as error "preset(cohort_time_fe) requires unit sampling weights; weights are not allowed"
            exit 198
        }
        if `anticipation'!=0 | strlower(strtrim("`baseperiod'"))!="universal" {
            display as error "preset(cohort_time_fe) requires anticipation(0) and baseperiod(universal)"
            exit 198
        }
        local gw=strlower(strtrim("`gmmweighting'"))
        if strlower(strtrim("`method'"))=="reg" {
            if !inlist("`gw'","","within") | !inlist(strlower(strtrim("`gmmcovariance'")),"","tikhonov") {
                display as error "preset(cohort_time_fe) with method(reg) uses within-unit least squares; omit gmmweighting() and gmmcovariance() or specify gmmweighting(within)"
                exit 198
            }
            local gmmweighting "within"
        }
        else {
            if !inlist("`gw'","","optimal","two_step","identity") | "`crosspair'"!="" {
                display as error "preset(cohort_time_fe) with method(ipw) or method(dr) uses optimal or identity GMM weighting without crosspair"
                exit 198
            }
        }
        local cg=strlower(strtrim("`controlgroup'"))
        local pa=strlower(strtrim("`ptassumption'"))
        if inlist("`cg'","","nevertreated") & !inlist("`pa'","","post") {
            display as error "preset(cohort_time_fe) with never-treated controls uses ptassumption(post) and estimates separate pre-treatment deviations"
            exit 198
        }
        if "`cg'"=="notyettreated" & ("`pa'"!="all" | "`ptstart'"=="") {
            display as error "preset(cohort_time_fe) with not-yet-treated controls requires ptassumption(all) and ptstart() at the first study date"
            exit 198
        }
        if strtrim("`outcomepooling'")!="" & strlower(strtrim("`outcomepooling'"))!="separate" {
            display as error "preset(cohort_time_fe) specifies its own common outcome model; omit outcomepooling()"
            exit 198
        }
    }
    // missingreference(): chained cohort models only. Ordinary mode ignores it;
    // the time-invariant preset refuses an explicit exclude.
    local mref_policy=strlower(strtrim(`"`missingreference'"'))
    if "`mref_policy'"!="" & "`mode'"!="ordinary" & "`rcs'"=="" {
        if !inlist("`mref_policy'","exclude","error") {
            display as error "missingreference() must be exclude or error"
            exit 198
        }
    }
    if "`preset'"!="" & "`mref_policy'"=="exclude" {
        display as error "missingreference(exclude) is not available with preset(cohort_time_fe): the fixed-effects preset requires time-invariant covariates supplied for every study unit and has no reference-date contexts to restrict. Omit this option or use a chained cohort model."
        exit 198
    }
    if "`mref_policy'"=="" local mref_policy "exclude"
    if "`preset'"!="" local mref_policy ""
    if "`crosspair'"!="" & ("`mode'"=="ordinary" | "`rcs'"!="") {
        display as error "crosspair requires chained mode"
        exit 198
    }
    if !inlist("`mode'","","chained","ordinary") {
        display as error "mode() must be chained or ordinary"
        exit 198
    }
    if "`mode'"=="chained" & "`rcs'"!="" {
        display as error "rcs is not allowed in chained mode, which requires panel data; specify mode(ordinary) or omit mode()"
        exit 198
    }
    if "`mode'"=="" local mode=cond("`rcs'"!="","ordinary","chained")
    // Chained-only options have no effect in ordinary mode, as in R (not evaluated).
    // e(inactive_options) lists all of them, specified or not, as R lists the
    // arguments a specification makes inactive; the note names those specified.
    local ordinary_inactive ""
    local ordinary_specified ""
    if "`mode'"=="ordinary" {
        local ordinary_inactive "ptassumption() ptstart() targets() targetcohorts() gmmweighting() gmmcovariance() workcap() condition() ridge() selection() selmodel() selpooling() selcovars() seluniverse() selrho() seljustification() selmethod() selnoconstant selconstant selzero outcomepooling() imppooling() missingreference() keepnuisance"
        foreach o in ptassumption ptstart targets targetcohorts gmmweighting gmmcovariance workcap {
            if `"``o''"'!="" local ordinary_specified "`ordinary_specified' `o'()"
        }
        if `condition'!=1e-10 local ordinary_specified "`ordinary_specified' condition()"
        if `ridge'!=1e-4 local ordinary_specified "`ordinary_specified' ridge()"
        foreach o in selection selmodel selpooling selcovars seluniverse selrho seljustification selmethod {
            if `"``o''"'!="" local ordinary_specified "`ordinary_specified' `o'()"
        }
        foreach o in selnoconstant selconstant selzero {
            if "``o''"!="" local ordinary_specified "`ordinary_specified' `o'"
        }
        foreach o in outcomepooling imppooling missingreference {
            if `"``o''"'!="" local ordinary_specified "`ordinary_specified' `o'()"
        }
        if "`keepnuisance'"!="" local ordinary_specified "`ordinary_specified' keepnuisance"
        local ordinary_specified = strtrim("`ordinary_specified'")
        // Not evaluated, as in R: the missing-outcome options are not checked here
        foreach o in selection selmodel selpooling selcovars seluniverse selrho seljustification selmethod ///
            selnoconstant selconstant selzero imppooling {
            local `o' ""
        }
    }
    if "`selection'"=="" local selection "none"
    if "`selmodel'"=="" local selmodel "pair_logit"
    if "`selpooling'"=="" local selpooling "separate"
    if "`seluniverse'"=="" local seluniverse "F"
    if "`selmethod'"=="" local selmethod "ipw"
    if "`gmmcovariance'"=="" local gmmcovariance "tikhonov"
    local method_norm=cond("`method'"=="","dr",strlower(strtrim("`method'")))
    if !inlist("`method_norm'","dr","reg","ipw","custom") {
        display as error "method() must be dr, reg, ipw or custom"
        exit 198
    }
    if "`method_norm'"!="custom" & (`"`callback'"'!="" | `"`payload'"'!="") {
        display as error "callback() and payload() require method(custom)"
        exit 198
    }
    if "`mode'"=="ordinary" {
        if "`frame'`frameivar'`framegvar'`framecovars'`framewvar'`frameselcovars'`framecluster'"!="" | "`noconstant'"!="" {
            display as error "frame(), the frame*() options and noconstant are not allowed in ordinary mode"
            exit 198
        }
        if `"`covars'"'!="" | "`panel'"!="" {
            display as error "covars() and panel() are not allowed in ordinary mode; list the covariates after the outcome and specify rcs for repeated cross-sections"
            exit 198
        }
        local ordinary_unbalanced ""
        if "`allowunbalanced'"!="" {
            if !inlist(strlower("`allowunbalanced'"),"true","1","false","0") {
                display as error "allowunbalanced() must be true or false"
                exit 198
            }
            if inlist(strlower("`allowunbalanced'"),"true","1") local ordinary_unbalanced "allowunbalanced"
        }
        local ordinary_options ""
        foreach o in ivar wvar fixweights method controlgroup baseperiod posting {
            if "``o''"!="" local ordinary_options "`ordinary_options' `o'(``o'')"
        }
        if `"`callback'"'!="" local ordinary_options `"`ordinary_options' callback(`"`callback'"')"'
        if `"`payload'"'!="" local ordinary_options `"`ordinary_options' payload(`"`payload'"')"'
        if "`cluster'"!="" local ordinary_options "`ordinary_options' cluster(`cluster')"
        if "`chunk'"!="" local ordinary_options "`ordinary_options' chunk(`chunk')"
        local ordinary_weight ""
        if "`weight'"!="" local ordinary_weight "[`weight'`exp']"
        local ordinary_save ""
        if `"`saving'"'!="" local ordinary_save `"saving(`"`saving'"')"'
        capture mata: _cdid_mlib_ready()
if _rc quietly mata: mata mlib index
        // The intake uses describe(), which alone does not autoload.
        quietly mata: (void) &cdid_ordinary_collect()
        _cdid_ordinary_frontend `raw_varlist' `if' `in' `ordinary_weight',time(`time') gvar(`gvar') ///
            `ordinary_options' `rcs' `ordinary_unbalanced' `noinffunc' bstrap(`bstrap') cband(`cband') ///
            biters(`biters') level(`level') workspace(`workspace') anticipation(`anticipation') `ordinary_save' cmdline(`"`caller_cmdline'"')
        ereturn local cmdline `"`caller_cmdline'"'
        ereturn local inactive_options "`ordinary_inactive'"
        if "`ordinary_specified'"!="" {
            display as text "note: chained-mode options have no effect in ordinary mode: `ordinary_specified'"
        }
        exit
    }
    if "`ivar'"=="" {
        display as error "chained mode requires ivar()"
        exit 198
    }
    if "`panel'"!="" & !inlist(strlower("`panel'"),"true","1") {
        display as error "rcs is not allowed in chained mode, which requires panel data; specify mode(ordinary) or omit mode()"
        exit 198
    }
    if "`allowunbalanced'"!="" {
        if !inlist(strlower("`allowunbalanced'"),"true","1","false","0") {
            display as error "allowunbalanced() must be true or false"
            exit 198
        }
        if inlist(strlower("`allowunbalanced'"),"false","0") {
            display as error "allowunbalanced(false) is not allowed in chained mode, which uses all units"
            exit 198
        }
    }
    if "`weight'"!="" & "`wvar'"!="" {
        display as error "specify either iweights or wvar(), not both"
        exit 198
    }
    if "`chunk'"=="" local chunk "."
    else confirm number `chunk'
    if "`workcap'"=="" local workcap "."
    else confirm number `workcap'
    gettoken outcome varcovars : raw_varlist
    if "`outcome'"=="" {
        display as error "outcome variable required"
        exit 198
    }
    unab outcome : `outcome'
    if wordcount("`outcome'") != 1 {
        display as error "outcome must be a single numeric variable"
        exit 198
    }
    confirm numeric variable `outcome'
    if `"`varcovars'"'!="" & `"`covars'"'!="" {
        display as error "specify covariates either in varlist or in covars(), not both"
        exit 198
    }
    if `"`covars'"'=="" local covars `"`varcovars'"'
    local covars_user `"`covars'"'
    // the observation-model design options are inactive under selmethod(imputation)
    local selcovars_given = (`"`selcovars'`frameselcovars'"'!="")
    local seldesign_active = (strlower(strtrim("`selmethod'"))!="imputation")
    if `seldesign_active' & "`selzero'"!="" & (`selcovars_given' | "`selconstant'"!="") {
        display as error "selzero (no observation-model design) cannot be combined with selcovars(), frameselcovars() or selconstant"
        exit 198
    }
    if `seldesign_active' & "`selconstant'"!="" & (`selcovars_given' | "`selnoconstant'`selzero'"!="") {
        display as error "selconstant (intercept-only observation model) cannot be combined with selcovars(), frameselcovars(), selnoconstant or selzero"
        exit 198
    }
    local method "`method_norm'"
    if "`method'"=="custom" {
        if strlower(strtrim("`selmethod'"))=="imputation" {
            display as error "method(custom) is not allowed with selmethod(imputation)"
            exit 459
        }
        if strlower(strtrim("`selmethod'"))=="dr" {
            display as error "method(custom) is not allowed with selmethod(dr)"
            exit 459
        }
    }
    if "`controlgroup'"=="" local controlgroup "nevertreated"
    if "`baseperiod'"=="" local baseperiod "varying"
    if "`ptassumption'"=="" local ptassumption "post"
    if "`gmmweighting'"=="" local gmmweighting "optimal"
    local ptassumption=strlower(strtrim("`ptassumption'"))
    local gmmweighting=strlower(strtrim("`gmmweighting'"))
    local ptassumption_req "`ptassumption'"
    local ptstart_req "`ptstart'"
    local xp_ptstart "."
    if "`crosspair'"!="" {
        if "`method'"=="custom" {
            display as error "crosspair is not available with method(custom)"
            exit 198
        }
        if !inlist("`ptassumption'","post","ctrl","all") {
            display as error "ptassumption() must be post, ctrl, or all"
            exit 198
        }
        if "`ptstart'"!="" local xp_ptstart "`ptstart'"
    }
    else if "`gmmweighting'"=="within" & "`method'"=="custom" {
        display as error "gmmweighting(within) is not available with method(custom)"
        exit 198
    }
    if "`posting'"=="" local posting "matrix"
    if `level'<=0 | `level'>=100 | missing(`level') {
        display as error "level() must be between 0 and 100"
        exit 198
    }
    local alpha=cond(`level'==95,.05,1-`level'/100)
    local compute_if=("`noinffunc'"=="")
    local frameopts ""
    foreach o in frame frameivar framegvar framecovars framewvar frameselcovars framecluster {
        if `"``o''"'!="" local frameopts `"`frameopts' `o'(``o'')"'
    }
    // crosspair and preset(): factor-variable terms enter as their indicator columns (omitted
    // levels dropped), so that every route of these estimators reads plain numeric covariates
    local xp_fvfrom ""
    local xp_fvto ""
    if "`crosspair'"!="" | "`preset'"!="" {
        foreach role in covars selcovars {
            if regexm(`"``role''"', "[.#]") {
                quietly fvexpand ``role'' `if' `in'
                local xp_terms ""
                local xp_bn ""
                foreach t in `r(varlist)' {
                    // a base level is omitted only where Stata omits it (a factor without
                    // its main effect, as in i.cf#c.x, keeps every level)
                    quietly _ms_parse_parts `t'
                    if !r(omit) {
                        local xp_terms "`xp_terms' `t'"
                        local xp_bn "`xp_bn' `=ustrregexra("`t'", "(^|#)([0-9]+)b?\.", "$1$2bn.")'"
                    }
                }
                quietly fvrevar `xp_bn' `if' `in'
                local `role' "`r(varlist)'"
                local xp_fvfrom "`xp_fvfrom' `r(varlist)'"
                local xp_fvto "`xp_fvto' `xp_terms'"
            }
        }
    }
    local xopts ""
    if `"`covars'"'!="" local xopts `"covars(`covars')"'
    local selopts ""
    foreach o in selection selmodel selpooling selcovars seluniverse selrho selmethod imppooling outcomepooling gmmcovariance {
        if `"``o''"'!="" local selopts `"`selopts' `o'(``o'')"'
    }
    if `"`seljustification'"'!="" local selopts `"`selopts' seljustification(`"`seljustification'"')"'
    if "`selnoconstant'"!="" local selopts `"`selopts' selnoconstant"'
    if "`selconstant'"!="" local selopts `"`selopts' selconstant"'
    if "`selzero'"!="" local selopts `"`selopts' selzero"'
    local clopts ""
    if "`cluster'"!="" local clopts "cluster(`cluster')"
    local tgopts ""
    if "`targets'"!="" local tgopts "targets(`targets')"
    if "`targetcohorts'"!="" local tgopts "`tgopts' targetcohorts(`targetcohorts')"
    local wopts ""
    if "`wvar'"!="" local wopts "wvar(`wvar')"
    if "`fixweights'"!="" local wopts "`wopts' fixweights(`fixweights')"
    local ptopts ""
    if "`ptstart_req'"!="" local ptopts "ptstart(`ptstart_req')"
    local saveopts ""
    if `"`saving'"'!="" local saveopts `"saving(`"`saving'"')"'
    tempname held bundle request prior_r
    tempvar heldsample generated_weight esmark
    // e(sample): observations meeting if/in with nonmissing ivar(), time() and gvar();
    // chained estimation retains observations whose outcome is missing.
    quietly mark `esmark' `if' `in'
    quietly markout `esmark' `ivar' `time' `gvar', strok
    local fit_token ""
    local final_token ""
    local sort0 `"`c(sortrngstate)'"'
    _return hold `prior_r'
    _estimates hold `held', copy restore nullok varname(`heldsample')
    capture noisily {
        // Refresh native library discovery only; no install/adopath/profile edit.
        capture mata: _cdid_mlib_ready()
if _rc quietly mata: mata mlib index
        if "`method'"=="custom" {
            mata: cdid_custom_validate_symbols(st_local("callback"),st_local("payload"))
        }
        if "`weight'"!="" {
            quietly generate double `generated_weight' `exp' `if' `in'
            local wopts "wvar(`generated_weight')"
            if "`fixweights'"!="" local wopts "`wopts' fixweights(`fixweights')"
        }
        mata: cdid_nuis_begin(`=("`keepnuisance'"!="")')
        mata: cdid_chain_clear()
        local prep_method=cond("`method'"=="custom","ipw","`method'")
        local xp_wname "`wvar'"
        if "`xp_wname'"=="" local xp_wname "`framewvar'"
        if "`weight'"!="" local xp_wname "`generated_weight'"
        mata: cdid_xp_request(`=("`crosspair'"!="")',st_local("ptassumption"),`xp_ptstart',st_local("xp_wname"),strlower(strtrim(st_local("controlgroup"))))
        mata: cdid_etwfe_request(`=("`preset'"!="")')
        mata: cdid_mref_request(st_local("mref_policy"))
        _cdid_request_prepare_mref `outcome' `if' `in',ivar(`ivar') time(`time') gvar(`gvar') ///
            store(`bundle') `xopts' `wopts' `frameopts' `selopts' `clopts' `tgopts' `noconstant' method(`prep_method') ///
            controlgroup(`controlgroup') anticipation(`anticipation') baseperiod(`baseperiod') ///
            ptassumption(`ptassumption_req') `ptopts' maxentries(`=floor(`workspace'/8)') ///
            `=cond("`method'"=="custom","fullreference","")' ///
            `=cond("`preset'"!="" & strlower("`selection'")!="none","referencechecked","")'
        if "`method'"=="custom" {
            mata: cdid_custom_public_store(st_local("bundle"),st_local("request"), ///
                st_local("callback"),st_local("payload"),st_local("gmmweighting"), ///
                (st_local("noconstant")==""),`workspace',`chunk',`workcap',`condition',`ridge', ///
                `compute_if',`bstrap',`cband',`biters',`alpha',st_local("posting"))
        }
        else {
            if "`xp_fvfrom'"!="" mata: cdid_xp_fv_names(st_local("bundle"),st_local("xp_fvfrom"),st_local("xp_fvto"))
            mata: cdid_etwfe_request(`=("`preset'"!="")')
            mata: cdid_public_default_store(st_local("bundle"),st_local("request"),st_local("gmmweighting"), ///
                (st_local("noconstant")==""),`workspace',`chunk',`workcap',`condition',`ridge', ///
                `compute_if',`bstrap',`cband',`biters',`alpha',st_local("posting"))
        }
        local active_cluster "`cluster'"
        if "`active_cluster'"=="" local active_cluster "`framecluster'"
        mata: st_local("fit_token",cdid_chained_bind_names(st_local("fit_token"), ///
            st_local("request"),st_local("ivar"),st_local("active_cluster")))
        mata: st_local("fit_token",cdid_state_bind_text(st_local("fit_token"),st_local("request"),"", ///
            ("depvar",st_local("outcome") \ "time_name",st_local("time") \ "gvar_name",st_local("gvar") \ ///
            "covariate_names",strtrim(st_local("covars_user")) \ "cmdline",st_local("caller_cmdline"))))
        _cdid_public_post,token("`fit_token'") request(`request') `saveopts'
        local final_token `"`e(state_token)'"'
        ereturn repost, esample(`esmark')
        ereturn local cmd "cdid"
        ereturn local cmdline `"`caller_cmdline'"'
        ereturn local mode "chained"
        ereturn local estat_cmd "cdid_estat"
        mata: cdid_mref_post()
        if "`weight'"!="" {
            ereturn local wtype "`weight'"
            ereturn local wexp `"`exp'"'
        }
        ereturn local depvar "`outcome'"
        ereturn local method "`=strlower("`method'")'"
        if "`method'"=="custom" {
            ereturn local callback `"`callback'"'
            ereturn local payload `"`payload'"'
        }
        ereturn local gmm_weighting "`=strlower("`gmmweighting'")'"
        ereturn local gmm_covariance "`=strlower("`gmmcovariance'")'"
        ereturn local base_period "`=strlower("`baseperiod'")'"
        ereturn local control_group "`=strlower("`controlgroup'")'"
        ereturn local pt_assumption "`=strlower("`ptassumption'")'"
        ereturn local cross_pair "`=cond("`crosspair'"!="","crosspair","")'"
        ereturn local preset "`preset'"
        ereturn local selection "`=strlower("`selection'")'"
        ereturn local selection_canonical "`=cond(strlower("`selection'")=="none","none","conditional_mtar")'"
        ereturn local selection_model "`=cond(strlower("`selmethod'")=="imputation","none",strlower("`selmodel'"))'"
        ereturn local selection_pooling "`=cond(strlower("`selmethod'")=="imputation","inactive",strlower("`selpooling'"))'"
        ereturn local selection_universe "`=strupper("`seluniverse'")'"
        ereturn local selection_est_method "`=strlower("`selmethod'")'"
        ereturn local selection_justification `"`seljustification'"'
        local outcome_active = inlist(strlower("`method'"),"reg","dr")
        if `outcome_active' {
            ereturn local outcome_pooling "`=cond(strtrim("`outcomepooling'")=="","separate",strlower(strtrim("`outcomepooling'")))'"
        }
        else ereturn local outcome_pooling ""
        local inact = cond(`outcome_active',"","outcome_pooling")
        if inlist(strlower("`selmethod'"),"imputation","dr") {
            ereturn local imputation_pooling "`=cond(strtrim("`imppooling'")=="","separate",strlower(strtrim("`imppooling'")))'"
            if strlower("`selmethod'")=="imputation" {
                local inact = cond("`inact'"=="","selection_model selection_pooling selection_xformla","`inact' selection_model selection_pooling selection_xformla")
            }
        }
        else {
            local inact = cond("`inact'"=="","imputation_pooling","`inact' imputation_pooling")
        }
        ereturn local inactive_arguments "`inact'"
        ereturn scalar anticipation=`anticipation'
        ereturn local source_state_token ""
        ereturn local fit_state_lifetime "temporary fit storage released after posting"
        mata: cdid_chain_finish(st_global("e(state_token)"))
        if `"`e(state_file)'"'!="" mata: cdid_chain_append(st_global("e(state_token)"),st_global("e(state_file)"))
        if "`keepnuisance'"!="" {
            mata: cdid_nuis_finish(st_global("e(state_token)"),"chained",st_global("e(method)"), ///
                st_global("e(selection_canonical)"),st_global("e(selection_est_method)"),st_local("active_cluster"))
            ereturn local nuisance "kept"
            if `"`e(state_file)'"'!="" mata: cdid_nuis_append(st_global("e(state_token)"),st_global("e(state_file)"))
        }
        local fit_title "Chained difference-in-differences"
        if "`crosspair'"!="" local fit_title "`fit_title' (cross-pair)"
        if "`preset'"!="" local fit_title "`fit_title' (cohort-by-date fixed effects)"
        _cdid_post_finish, title("`fit_title'") endpoint(cells) ivar(`ivar') time(`time') gvar(`gvar') ///
            clustvar(`active_cluster') covariates(`covars_user')
        mata: cdid_mref_display()
        mata: cdid_frontend_display(st_global("e(state_token)"))
        mata: cdid_mref_note()
        _estimates unhold `held', not
    }
    local rc=_rc
    capture mata: cdid_nuis_begin(0)
    capture mata: cdid_xp_request(0,"",.)
    capture mata: cdid_etwfe_request(0)
    capture mata: cdid_mref_request("")
    capture mata: cdid_chain_clear()
    if `"`fit_token'"'!="" capture mata: cdid_state_drop(st_local("fit_token"))
    capture mata: rmexternal(st_local("bundle"))
    capture mata: rmexternal(st_local("request"))
    if `rc' {
        if `"`final_token'"'!="" capture mata: cdid_state_drop(st_local("final_token"))
        capture _estimates unhold `held'
    }
    quietly set sortrngstate `sort0'
    _return restore `prior_r'
    if `rc' exit `rc'
end
