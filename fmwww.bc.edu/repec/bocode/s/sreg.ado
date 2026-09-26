*! sreg 1.0.0 24sep2026 -- Stratified Randomized Experiments
program define sreg, eclass sortpreserve
    version 14.2
    local cmdline `"sreg `0'"'
    syntax [varlist(numeric fv default=none)] [if] [in], [TREATment(varname numeric) ///
        STRata(varname numeric) CLuster(varname numeric) CLUSTERSIze(varname numeric) ///
        SMALLSTRata K(string) NOHC1 Level(cilevel) ///
        Y(varname numeric) D(varname numeric) S(varname numeric) ///
        X(varlist numeric fv) G_id(varname numeric) NG(varname numeric) HC1(string)]
    if `"`varlist'`if'`in'`treatment'`strata'`cluster'`clustersize'`smallstrata'`k'`nohc1'`y'`d'`s'`x'`g_id'`ng'`hc1'"' == "" {
        if "`e(cmd)'" != "sreg" error 301
        sreg_display, level(`level')
        exit
    }
    if "`y'`d'`s'`x'`g_id'`ng'`hc1'" != "" {
        local legacy 1
        if "`varlist'`treatment'`strata'`cluster'`clustersize'`nohc1'" != "" {
            di as error "Do not combine legacy and primary syntax."
            exit 198
        }
        if "`y'" == "" {
            di as error "Observed outcomes have not been provided; specify y()."
            exit 198
        }
        local varlist `y' `x'
        local treatment `d'
        local strata `s'
        local cluster `g_id'
        local clustersize `ng'
        if "`hc1'" != "" & !inlist("`hc1'", "true", "false") {
            di as error "hc1() must be true or false."
            exit 198
        }
        if "`hc1'" == "false" local nohc1 nohc1
    }
    gettoken depvar covariates : varlist
    if "`depvar'" == "" {
        di as error "Observed outcomes have not been provided."
        exit 198
    }
    confirm numeric variable `depvar'
    if "`treatment'" == "" {
        di as error "Treatments have not been provided; specify treatment()."
        exit 198
    }
    if "`clustersize'" != "" & "`cluster'" == "" & "`legacy'" != "1" {
        di as error "clustersize() requires cluster()."
        exit 198
    }
    if "`k'" == "" local k .
    else {
        capture confirm integer number `k'
        if _rc {
            di as error "k() must be a positive integer."
            exit 198
        }
        if `k' <= 0 {
            di as error "k() must be a positive integer."
            exit 198
        }
    }
    marksample touse, novarlist
    quietly count if `touse'
    local npre = r(N)
    markout `touse' `depvar' `treatment' `strata' `cluster' `clustersize'
    local xvars
    if "`covariates'" != "" {
        quietly fvexpand `covariates' if `touse'
        local expanded `r(varlist)'
        local active
        foreach term of local expanded {
            _ms_parse_parts `term'
            if !r(omit) local active `active' `term'
        }
        if "`active'" != "" {
            quietly fvrevar `active'
            local xvars `r(varlist)'
            markout `touse' `xvars'
        }
    }
    quietly count if `touse'
    local nobs = r(N)
    if !`nobs' error 2000
    local sreg_warnings
    if `nobs' < `npre' {
        di as text "Warning: The data contains missing values; proceeding while ignoring these values."
        local sreg_warnings "Missing observations omitted. | "
    }
    tempname b V beta betabig nunits nstrata adjusted design ksmall bs Vs bb Vb ps ns nb
    capture quietly mata: sreg_api_version()
    if _rc == 3499 {
        quietly findfile sreg_mata.mata
        quietly do "`r(fn)'"
    }
    local hc = ("`nohc1'" == "")
    local ss = ("`smallstrata'" != "")
    mata: sreg_run("`depvar'", "`treatment'", "`strata'", "`cluster'", "`clustersize'", "`xvars'", "`touse'", `hc', `ss', `k')
    local arms = colsof(`b')
    local names
    forvalues j=1/`arms' {
        local names `names' tau`j'
    }
    matrix colnames `b' = `names'
    matrix colnames `V' = `names'
    matrix rownames `V' = `names'
    ereturn post `b' `V', esample(`touse') obs(`nobs') depname(`depvar')
    ereturn scalar N_units = scalar(`nunits')
    ereturn scalar N_strata = scalar(`nstrata')
    ereturn scalar N_treatments = `arms'
    ereturn scalar adjusted = scalar(`adjusted')
    ereturn scalar HC1 = `hc'
    ereturn scalar smallstrata = `ss'
    ereturn scalar k = scalar(`ksmall')
    ereturn scalar level = `level'
    if "`cluster'" != "" ereturn scalar N_clust = scalar(`nunits')
    if scalar(`adjusted') {
        matrix colnames `beta' = `active'
        ereturn matrix beta = `beta'
    }
    if scalar(`design') == 0 ereturn local design "large strata"
    if scalar(`design') == 1 ereturn local design "small strata"
    if scalar(`design') == 2 {
        ereturn local design "mixed design"
        if scalar(`adjusted') {
            matrix colnames `betabig' = `active'
            ereturn matrix beta_large = `betabig'
            tempname betasmall
            matrix `betasmall' = e(beta)
            ereturn matrix beta_small = `betasmall'
        }
        foreach mat in bs Vs bb Vb {
            matrix colnames ``mat'' = `names'
        }
        matrix rownames `Vs' = `names'
        matrix rownames `Vb' = `names'
        ereturn matrix b_small = `bs'
        ereturn matrix V_small = `Vs'
        ereturn matrix b_large = `bb'
        ereturn matrix V_large = `Vb'
        ereturn scalar p_small = scalar(`ps')
        ereturn scalar N_small = scalar(`ns')
        ereturn scalar N_large = scalar(`nb')
    }
    ereturn local depvar "`depvar'"
    ereturn local treatment "`treatment'"
    ereturn local strata "`strata'"
    ereturn local clustvar "`cluster'"
    ereturn local clustersize "`clustersize'"
    ereturn local covariates "`covariates'"
    ereturn local adjustment_terms "`active'"
    ereturn local warnings `"`sreg_warnings'"'
    ereturn local vce "sreg"
    ereturn local vcetype "Design-based"
    ereturn local properties "b V"
    ereturn local cmdline `"`cmdline'"'
    ereturn local cmd "sreg"
    sreg_display, level(`level')
end

program define sreg_display
    version 14.2
    syntax [, Level(cilevel)]
    di as text _n "Saturated Model Estimation Results under CAR" _c
    if e(adjusted) di as text " with linear adjustments" _c
    di as text _n "Observations: " as result %10.0gc e(N)
    if "`e(clustvar)'" != "" di as text "Clusters: " as result %10.0gc e(N_clust)
    di as text "Number of treatments: " as result e(N_treatments)
    di as text "Number of strata: " as result e(N_strata)
    di as text "Setup: " as result "`e(design)'"
    if e(smallstrata) di as text "Strata size (k, small strata): " as result e(k)
    di as text "Standard errors: " as result cond(e(HC1), "adjusted (HC1)", "unadjusted")
    di as text "Treatment assignment: " as result cond("`e(clustvar)'"=="", "individual level", "cluster level")
    di as text "Covariates used in linear adjustments: " as result cond(e(adjusted),"`e(covariates)'", "")
    if "`e(design)'" == "mixed design" di as text "Represented population share in small strata: " as result %8.5f e(p_small)
    ereturn display, level(`level')
end
