*! xtutest  version 1.3.0  20oct2026
*! Test for an inverse U- (or U-) shaped relationship and estimate the turning point in
*! heterogeneous panels: CCE mean-group (Pesaran 2006) Lind-Mehlum intersection-union test,
*! turning point of the mean curve with Fieller and delta intervals, median unit turning point.
*! v1.1.0: estimator(fe|re|iv|gmm) homogeneous-slope variants; residual diagnostics (serial
*!         correlation, heteroskedasticity, normality, stability) for every estimator.
*! Author : Yusuf Toyin Yusuf, Kwara State University (yusuf.yusuf@kwasu.edu.ng)

capture program drop xtutest
program define xtutest, eclass sortpreserve
    version 14

    if replay() {
        if "`e(cmd)'" != "xtutest" error 301
        syntax [, UNITs DIag]
        _xtutest_display, `units' `diag'
        exit
    }

    syntax varlist(min=2 numeric) [if] [in] [,          ///
        ESTimator(string)                              /// cce (default) mg ccep fe re iv gmm
        NOCCE                                          /// synonym for estimator(mg)
        IVinst(varlist ts)                             /// instruments for x and x^2 (iv)
        ENDOG GMMLags(integer 2) NOTIME ONEstep        /// gmm: x endogenous; lag depth; no time effects; one-step
        INTerval(numlist min=2 max=2 ascending)        /// [xL, xH]
        Ushape                                         /// test U instead of inverse U
        Level(cilevel)                                 ///
        NORMal                                         /// N(0,1) instead of t(N-1) reference
        POOLed                                         /// add the pooled two-way FE test
        UNITs NODisplay GRaph DIag ]

    gettoken depvar rest : varlist
    gettoken xvar controls : rest
    local controls = strtrim("`controls'")

    qui xtset
    local ivar "`r(panelvar)'"
    local tvar "`r(timevar)'"
    if "`ivar'" == "" | "`tvar'" == "" {
        di as err "panel and time variables must be set; use {bf:xtset} panelvar timevar"
        exit 459
    }
    marksample touse
    markout `touse' `ivar' `tvar'

    local estimator = lower(strtrim("`estimator'"))
    if "`estimator'" == "" local estimator = cond("`nocce'" == "", "cce", "mg")
    if "`nocce'" != "" & "`estimator'" != "mg" {
        di as err "nocce may not be combined with estimator(`estimator')"
        exit 198
    }
    if !inlist("`estimator'", "cce", "mg", "ccep", "fe", "re", "iv", "gmm") {
        di as err "estimator() must be cce, mg, ccep, fe, re, iv or gmm"
        exit 198
    }
    local het = inlist("`estimator'", "cce", "mg", "ccep")
    if !`het' & "`pooled'" != "" {
        di as err "option pooled is for estimator(cce), estimator(ccep) and estimator(mg)"
        exit 198
    }
    if "`ivinst'" != "" & "`estimator'" != "iv" {
        di as err "ivinst() is for estimator(iv)"
        exit 198
    }
    if "`onestep'" != "" & "`estimator'" != "gmm" {
        di as err "onestep is for estimator(gmm)"
        exit 198
    }
    if "`endog'" != "" & "`estimator'" != "gmm" {
        di as err "endog is for estimator(gmm)"
        exit 198
    }
    local cce = inlist("`estimator'", "cce", "ccep")
    local kw : word count `controls'
    local npar = 3 + `kw' + `cce' * (3 + `kw')

    // panel structure; unbalanced panels are allowed (v1.3.0)
    tempvar Ti one first
    qui bysort `touse' `ivar': gen long `Ti' = _N if `touse'
    qui count if `touse'
    if r(N) == 0 error 2000
    if `het' {
        // each unit regression needs at least npar + 3 observations; drop units with fewer
        qui count if `touse' & `Ti' < `npar' + 3
        if r(N) > 0 {
            qui bysort `touse' `ivar': gen byte `first' = (_n == 1) if `touse' & `Ti' < `npar' + 3
            qui count if `first' == 1
            di as txt "(`r(N)' unit(s) with fewer than " `npar' + 3 " observations dropped: each unit regression has `npar' coefficients)"
            qui replace `touse' = 0 if `Ti' < `npar' + 3
            drop `first'
        }
    }
    qui bysort `touse' `tvar': gen byte `one' = (_n == 1) if `touse'
    qui count if `one' == 1 & `touse'
    local T = r(N)
    qui bysort `touse' `ivar': gen byte `first' = (_n == 1) if `touse'
    qui count if `first' == 1 & `touse'
    local N = r(N)
    if `N' < 10 {
        di as err "at least 10 panel units are needed (N = `N')"
        if `het' & `cce' di as err "(CCE adds 3 + #controls cross-section averages to each unit regression; try fewer controls)"
        exit 2001
    }
    qui su `Ti' if `touse', meanonly
    local balanced = (r(min) == r(max) & r(min) == `T')
    if "`interval'" == "" {
        qui _pctile `xvar' if `touse', p(5 95)
        local xL = r(r1)
        local xH = r(r2)
        local intsrc "5th and 95th percentiles of `xvar'"
    }
    else {
        local xL : word 1 of `interval'
        local xH : word 2 of `interval'
        local intsrc "user specified"
    }
    local ush = ("`ushape'" != "")
    local normal = ("`normal'" != "")
    local dopooled = ("`pooled'" != "")

    // ---------------------------------------------------------------
    // estimation
    // ---------------------------------------------------------------
    _xtutest_load
    sort `ivar' `tvar'
    tempname BB VV UN RES POOL DG PDG ST
    local sqname = substr("`xvar'", 1, 29) + "_sq"
    local cn "`xvar' `sqname' `controls'"
    if `het' {
        capture noisily mata: xtu_run()
        if _rc {
            di as err "Mata engine failed (rc = " _rc "); if you have just used {bf:mata clear}, type {bf:discard} and retry"
            exit 498
        }
        local df = el(`RES', 1, 22)
        local estname = cond(`cce', "CCE mean group", "mean group")
        if "`estimator'" == "ccep" local estname "CCE pooled"
    }
    else {
        tempvar esamp
        qui gen byte `esamp' = 0
        local copt ""
        local iopt ""
        if "`controls'" != "" local copt "controls(`controls')"
        if "`ivinst'"   != "" local iopt "ivinst(`ivinst')"
        _xtutest_pooled, depvar(`depvar') xvar(`xvar') ivar(`ivar') tvar(`tvar') touse(`touse') ///
            est(`estimator') esamp(`esamp') `copt' `iopt' `endog' gmmlags(`gmmlags') `notime' `onestep'
        matrix `BB'  = r(b)
        matrix `VV'  = r(V)
        matrix `PDG' = r(pdiag)
        matrix `ST'  = r(stats)
        local estname "`r(estname)'"
        local df  = r(df)
        local Ngp = r(N_g)
        local mund   = r(mundlak)
        local mund_df = r(mundlak_df)
        local mund_p = r(mundlak_p)
        local rho    = r(rho)
        local tbreak = r(tbreak)
        local dfin = cond(`normal', ., `df')
        mata: xtu_frombV("`BB'", "`VV'", `xL', `xH', `ush', `level', `dfin', `Ngp', `T')
        local df = `dfin'
        qui replace `touse' = `esamp'
    }

    // ---------------------------------------------------------------
    // post
    // ---------------------------------------------------------------
    matrix colnames `BB' = `cn'
    matrix rownames `VV' = `cn'
    matrix colnames `VV' = `cn'
    qui count if `touse'
    local nobs = r(N)
    ereturn post `BB' `VV', esample(`touse') obs(`nobs') depname(`depvar')

    local names "sL sH tL tH S p tp f_lo f_hi f_bounded d_lo d_hi tp_median m_lo m_hi share n_curv cd cd_p N_g T df"
    local j 0
    foreach nm of local names {
        local ++j
        ereturn scalar `nm' = el(`RES', 1, `j')
    }
    ereturn scalar balanced = `balanced'
    if `het' {
        ereturn scalar T_min = `Tmin'
        ereturn scalar T_avg = `Tavg'
    }
    ereturn scalar xL = `xL'
    ereturn scalar xH = `xH'
    ereturn scalar level = `level'
    ereturn scalar cce = `cce'
    ereturn scalar het = `het'
    ereturn scalar ushape = `ush'
    ereturn scalar normal = `normal'
    ereturn local cmd "xtutest"
    ereturn local cmdline "xtutest `0'"
    local ttl = cond(`ush', "Panel test for a U shape", "Panel test for an inverse U shape")
    ereturn local title "`ttl'"
    ereturn local depvar "`depvar'"
    ereturn local xvar "`xvar'"
    ereturn local controls "`controls'"
    ereturn local ivar "`ivar'"
    ereturn local tvar "`tvar'"
    ereturn local estimator "`estimator'"
    ereturn local estname "`estname'"
    ereturn local interval "`intsrc'"
    if `het' {
        if "`estimator'" == "ccep" ereturn local vce "nonparametric CCE pooled (Pesaran 2006)"
        else ereturn local vce "mean group (Pesaran and Smith 1995)"
        matrix colnames `UN' = id b_x b_xsq tp curvature p_bg p_bp p_jb p_cusum
        ereturn matrix units = `UN'
        matrix rownames `DG' = serial hetero normality stability
        matrix colnames `DG' = share_rej n_units fisher p_fisher z_invnorm p_invnorm
        ereturn matrix diag = `DG'
        if `dopooled' {
            matrix colnames `POOL' = sL sH tL tH S p tp b_x b_xsq se_x se_xsq
            ereturn matrix pooled = `POOL'
        }
    }
    else {
        ereturn local vce = cond("`estimator'" == "gmm", "robust (see estimator)", "cluster-robust (units)")
        matrix rownames `PDG' = serial hetero normality stability
        matrix colnames `PDG' = stat df p
        ereturn matrix diag = `PDG'
        matrix colnames `ST' = F1_x F1_xsq overid p_overid p_ar1 p_ar2
        ereturn matrix ivgmm = `ST'
        if "`estimator'" == "re" {
            ereturn scalar mundlak   = `mund'
            ereturn scalar mundlak_df = `mund_df'
            ereturn scalar mundlak_p = `mund_p'
        }
        if "`estimator'" == "gmm" ereturn scalar rho = `rho'
        if inlist("`estimator'", "fe", "re") ereturn scalar tbreak = `tbreak'
    }

    if "`nodisplay'" == "" _xtutest_display, `units' `diag'
    if "`graph'" != "" xtutest_graph
end
