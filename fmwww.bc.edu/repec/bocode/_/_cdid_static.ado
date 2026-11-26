*! version 1.0.0.1  17nov2026
program define _cdid_static, eclass
    version 19.5
    syntax anything(name=raw_varlist id="varlist") [if] [in] [iweight], TIME(varname numeric) ///
        DVAR(varname numeric) [IVAR(varname) GVAR(string) COVARS(string) METHOD(string) ///
        SWITCHERS(string) SWITCHTIMES(numlist) OUTCOMEPOOLING(string) CLUSTER(varname) ///
        NOINFFUNC BSTRAP(real 1) CBAND(integer 1) BITERS(integer 1000) Level(real 95) ///
        WORKSPACE(real 1073741824) MODE(string) GMMWEIGHTING(string) GMMCOVARIANCE(string) ///
        CONDITION(real 1e-10) RIDGE(real 1e-4) SELECTION(string) SELMETHOD(string) SELMODEL(string) ///
        SELPOOLING(string) IMPPOOLING(string) IMPSCALE(string) SELCOVARS(string) SELCONSTANT ///
        SELUNIVERSE(string) SELRHO(varname numeric) SELJUSTIFICATION(string) KEEPNUISANCE *]
    if `"`gvar'"'!="" {
        display as error "specify either gvar() (absorbing adoption dates) or dvar() (a binary treatment indicator), not both"
        exit 198
    }
    if `"`options'"'!="" {
        gettoken first : options, bind
        local first=strlower(regexr(`"`first'"',"\(.*$",""))
        display as error "option `first'() is not available with dvar(); see {help cdid##dvar:dvar()}"
        exit 198
    }
    if "`weight'"!="" {
        display as error "weights are not allowed with dvar(); estimation uses equal unit weights"
        exit 198
    }
    if !inlist(strlower(strtrim("`mode'")),"","chained") {
        display as error "dvar() estimation requires panel data in chained mode"
        exit 198
    }
    if "`ivar'"=="" {
        display as error "dvar() requires ivar()"
        exit 198
    }
    local method=cond("`method'"=="","dr",strlower(strtrim("`method'")))
    if !inlist("`method'","dr","ipw","reg") {
        display as error "method() must be dr, ipw, or reg with dvar()"
        exit 198
    }
    local switchers=cond("`switchers'"=="","both",strlower(strtrim("`switchers'")))
    if !inlist("`switchers'","both","entry","exit") {
        display as error "switchers() must be both, entry, or exit"
        exit 198
    }
    local outcomepooling=cond(`"`outcomepooling'"'=="","separate",strlower(strtrim(`"`outcomepooling'"')))
    if !inlist("`outcomepooling'","separate","pooled") & !regexm("`outcomepooling'","^[a-z0-9:.| ]+$") {
        display as error "outcomepooling() must be separate, pooled, or blocks of cells such as entry:2003 entry:2004 | exit:2003"
        exit 198
    }
    local gmmweighting=cond("`gmmweighting'"=="","optimal",strlower(strtrim("`gmmweighting'")))
    if !inlist("`gmmweighting'","optimal","two_step","identity") {
        display as error "gmmweighting() must be optimal, two_step, or identity with dvar()"
        exit 198
    }
    if !inlist(strlower(strtrim("`gmmcovariance'")),"","tikhonov") {
        display as error "gmmcovariance() must be tikhonov"
        exit 198
    }
    if `condition'<=0 | `condition'>=1 | missing(`condition') | `ridge'<=0 | missing(`ridge') {
        display as error "condition() must lie in (0, 1) and ridge() must be positive"
        exit 198
    }
    local selection=cond("`selection'"=="","none",strlower(strtrim("`selection'")))
    local selmethod=cond("`selmethod'"=="","ipw",strlower(strtrim("`selmethod'")))
    local selmodel=cond("`selmodel'"=="","pair_logit",strlower(strtrim("`selmodel'")))
    local selpooling=cond("`selpooling'"=="","separate",strlower(strtrim("`selpooling'")))
    local imppooling=cond("`imppooling'"=="","separate",strlower(strtrim("`imppooling'")))
    local impscale=cond("`impscale'"=="","per_period",strlower(strtrim("`impscale'")))
    if !inlist("`selection'","none","conditional_mtar") {
        display as error "selection() must be none or conditional_mtar"
        exit 198
    }
    if !inlist("`selmethod'","ipw","imputation","dr") {
        display as error "selmethod() must be ipw, imputation, or dr"
        exit 198
    }
    if "`selection'"=="none" & "`selmethod'"!="ipw" {
        display as error "selmethod(`selmethod') requires selection(conditional_mtar)"
        exit 198
    }
    if !inlist("`selmodel'","pair_logit","independent_period_logit") {
        display as error "selmodel() must be pair_logit or independent_period_logit"
        exit 198
    }
    foreach o in selpooling imppooling {
        if !inlist("``o''","separate","within_group","pooled") {
            display as error "`o'() must be separate, within_group, or pooled with dvar()"
            exit 198
        }
    }
    if !inlist("`impscale'","per_period","per_change") {
        display as error "impscale() must be per_period or per_change"
        exit 198
    }
    local seluniverse=cond(strtrim("`seluniverse'")=="","F",strupper(strtrim("`seluniverse'")))
    if !inlist("`seluniverse'","F","B","A") {
        display as error "seluniverse() must be F, B, or A"
        exit 198
    }
    if "`seluniverse'"=="F" & ("`selrho'"!="" | `"`seljustification'"'!="") {
        display as error "selrho() and seljustification() require seluniverse(B) or seluniverse(A)"
        exit 198
    }
    if "`seluniverse'"!="F" {
        if "`selection'"!="conditional_mtar" | "`selmethod'"!="ipw" | "`selmodel'"!="pair_logit" {
            display as error "seluniverse(`seluniverse') with dvar() requires selection(conditional_mtar), selmethod(ipw), and selmodel(pair_logit)"
            exit 198
        }
        if strtrim(`"`seljustification'"')=="" {
            display as error "seluniverse(`seluniverse') requires seljustification()"
            exit 198
        }
    }
    if `"`selcovars'"'!="" & "`selconstant'"!="" {
        display as error "selconstant (intercept-only observation model) cannot be combined with selcovars()"
        exit 198
    }
    local route "baseline"
    if "`selection'"=="conditional_mtar" {
        if "`selmethod'"=="ipw" local route "weighting"
        else if "`selmethod'"=="imputation" local route "imputation"
        else local route "augmented"
    }
    if !inlist(`bstrap',0,1) | !inlist(`cband',0,1) {
        display as error "bstrap() and cband() must be 0 or 1"
        exit 198
    }
    if `biters'<1 {
        display as error "biters() must be a positive integer"
        exit 198
    }
    if `level'<=0 | `level'>=100 | missing(`level') {
        display as error "level() must be between 0 and 100"
        exit 198
    }
    if `workspace'<8 | missing(`workspace') | `workspace'!=floor(`workspace') {
        display as error "workspace() must be a positive integer number of bytes"
        exit 198
    }
    gettoken outcome varcovars : raw_varlist
    unab outcome : `outcome'
    if wordcount("`outcome'")!=1 {
        display as error "outcome must be a single numeric variable"
        exit 198
    }
    confirm numeric variable `outcome'
    if `"`varcovars'"'!="" & `"`covars'"'!="" {
        display as error "specify covariates either in varlist or in covars(), not both"
        exit 198
    }
    if `"`covars'"'=="" local covars `"`varcovars'"'
    marksample touse, novarlist
    markout `touse' `time' `dvar'
    if "`cluster'"!="" markout `touse' `cluster', strok
    capture confirm string variable `ivar'
    if _rc markout `touse' `ivar'
    else markout `touse' `ivar', strok
    local xvars ""
    local xnames ""
    if `"`covars'"'!="" {
        _cdid_static_terms `covars' if `touse'
        local xnames "`r(names)'"
        local positions "`r(positions)'"
        quietly fvrevar `r(expanded)' if `touse'
        local generated "`r(varlist)'"
        foreach p of local positions {
            local xvars "`xvars' `: word `p' of `generated''"
        }
    }
    local svars ""
    local snames ""
    if inlist("`route'","weighting","augmented") & "`selconstant'"=="" {
        if `"`selcovars'"'=="" {
            local svars "`xvars'"
            local snames "`xnames'"
        }
        else {
            _cdid_static_terms `selcovars' if `touse'
            local snames "`r(names)'"
            local positions "`r(positions)'"
            quietly fvrevar `r(expanded)' if `touse'
            local generated "`r(varlist)'"
            foreach p of local positions {
                local svars "`svars' `: word `p' of `generated''"
            }
        }
    }
    quietly count if `touse'
    if r(N)==0 error 2000
    tempvar uid ord
    quietly egen long `uid'=group(`ivar') if `touse'
    tempvar dup
    quietly bysort `touse' `uid' `time': gen byte `dup'=(_N>1)
    quietly count if `touse' & `dup'
    if r(N) {
        display as error "ivar() and time() do not uniquely identify the observations"
        exit 459
    }
    local clustered=("`cluster'"!="")
    tempvar cid
    if `clustered' {
        quietly egen long `cid'=group(`cluster') if `touse'
        tempvar cmin cmax
        quietly bysort `uid' (`cid'): gen long `cmin'=`cid'[1] if `touse'
        quietly by `uid': gen long `cmax'=`cid'[_N] if `touse'
        quietly count if `touse' & `cmin'!=`cmax'
        if r(N) {
            display as error "cluster() must be constant within units"
            exit 459
        }
        quietly summarize `cid' if `touse', meanonly
        if r(max)<2 {
            display as error "at least two clusters are required for clustered inference"
            exit 459
        }
    }
    else quietly gen byte `cid'=1
    quietly gen long `ord'=_n
    sort `touse' `uid' `time'
    capture mata: _cdid_mlib_ready()
    if _rc quietly mata: mata mlib index
    local compute_if=("`noinffunc'"=="")
    local band_status ""
    capture noisily mata: cdid_static_run("`outcome'","`dvar'","`xvars'","`time'","`cid'","`touse'", ///
        "`method'","`switchers'","`switchtimes'","`outcomepooling'",`compute_if',`bstrap',`cband', ///
        `biters',`level',`workspace',`clustered',"`gmmweighting'",`condition',`ridge', ///
        "`route'","`selmodel'","`selpooling'","`imppooling'",("`impscale'"=="per_period"),"`svars'", ///
        "`seluniverse'","`selrho'",("`keepnuisance'"!=""),"`xnames'","`snames'")
    local rc=_rc
    sort `ord'
    if `rc' {
        capture matrix drop __cdid_st_b __cdid_st_V __cdid_st_cells
        exit `rc'
    }
    local N=__cdid_st_n
    tempname b V cells
    matrix `cells'=__cdid_st_cells
    matrix drop __cdid_st_cells
    if __cdid_st_navail>0 {
        matrix `b'=__cdid_st_b
        matrix `V'=__cdid_st_V
        matrix drop __cdid_st_b __cdid_st_V
        if `compute_if' ereturn post `b' `V', esample(`touse') obs(`N') depname(`outcome')
        else ereturn post `b', esample(`touse') obs(`N') depname(`outcome')
    }
    else ereturn post, esample(`touse') obs(`N') depname(`outcome')
    ereturn matrix cells=`cells'
    ereturn scalar T=__cdid_st_T
    if `clustered' ereturn scalar N_clust=__cdid_st_C
    ereturn scalar att=__cdid_st_agg
    ereturn scalar se_att=__cdid_st_agg_se
    ereturn scalar se_att_analytic=__cdid_st_agg_ase
    ereturn scalar se_att_bootstrap=__cdid_st_agg_bse
    ereturn scalar n_switchers=__cdid_st_switchers
    ereturn scalar critical_value=cond("`band_status'"=="ok",__cdid_st_bcrit,__cdid_st_crit)
    ereturn scalar level=`level'
    ereturn scalar alpha=1-`level'/100
    ereturn scalar biters=`biters'
    ereturn scalar draws=__cdid_st_draws
    ereturn scalar N_missing=__cdid_st_nmiss
    scalar drop __cdid_st_n __cdid_st_T __cdid_st_C __cdid_st_agg __cdid_st_agg_se __cdid_st_agg_ase ///
        __cdid_st_agg_bse __cdid_st_switchers __cdid_st_crit __cdid_st_bcrit __cdid_st_draws __cdid_st_navail __cdid_st_nmiss
    ereturn local band_status "`band_status'"
    if !`compute_if' ereturn local vce "none"
    else ereturn local vce=cond(`bstrap',"bootstrap","analytic")
    if `compute_if' & `bstrap' ereturn local vcetype "Bootstrap"
    ereturn local band=cond("`band_status'"=="ok","simultaneous","pointwise")
    if `clustered' ereturn local clustvar "`cluster'"
    ereturn local switchtimes "`switchtimes'"
    ereturn local selection "`selection'"
    if "`selection'"=="conditional_mtar" {
        ereturn local selection_est_method "`selmethod'"
        if "`route'"!="imputation" {
            ereturn local selection_model "`selmodel'"
            ereturn local selection_pooling "`selpooling'"
            ereturn local selection_universe "`seluniverse'"
            if "`selrho'"!="" ereturn local selection_rho "`selrho'"
            if "`seluniverse'"!="F" ereturn local selection_justification `"`seljustification'"'
            ereturn local selection_covariates `"`=cond("`selconstant'"!="","_cons",cond(`"`selcovars'"'=="",`"`covars'"',`"`selcovars'"'))'"'
        }
        if "`route'"!="weighting" {
            ereturn local imputation_pooling "`imppooling'"
            ereturn local imputation_scale "`impscale'"
        }
    }
    ereturn local outcome_pooling "`outcomepooling'"
    if e(N_missing)>0 | "`selection'"!="none" ereturn local gmm_weighting "`gmmweighting'"
    ereturn local switchers "`switchers'"
    ereturn local method "`method'"
    ereturn local covariates `"`=strtrim(`"`covars'"')'"'
    ereturn local dvar "`dvar'"
    ereturn local time "`time'"
    ereturn local ivar "`ivar'"
    ereturn local design "static"
    ereturn local estat_cmd "cdid_estat"
    ereturn local mode "chained"
    ereturn local title "Difference-in-differences with binary treatment switching"
    if "`keepnuisance'"!="" {
        mata: st_local("token", "cdid_static_" + strofreal(cdid_static_seq()))
        mata: cdid_static_nuis_finish("`token'", "`cluster'")
        ereturn local state_token "`token'"
        ereturn local nuisance "kept"
    }
    ereturn local cmd "cdid"
    mata: cdid_static_display()
end

* Expands factor-variable terms. The caller converts the complete expansion with fvrevar, which
* keeps every level relative to its base, and retains the terms at r(positions): the levels that
* Stata omits (base levels of factors with their main effect, collinear terms) are dropped.
program define _cdid_static_terms, rclass
    version 19.5
    syntax varlist(fv numeric) [if]
    fvexpand `varlist' `if'
    local expanded "`r(varlist)'"
    local keep ""
    local positions ""
    local position = 0
    foreach t of local expanded {
        local ++position
        quietly _ms_parse_parts `t'
        if !r(omit) {
            local keep "`keep' `t'"
            local positions "`positions' `position'"
        }
    }
    return local expanded "`expanded'"
    return local positions = strtrim("`positions'")
    return local names = strtrim("`keep'")
end
