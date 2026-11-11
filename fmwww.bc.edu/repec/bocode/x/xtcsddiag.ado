*! xtcsddiag  version 1.0.0  21oct2026
*! Residual diagnostics for heterogeneous panels with cross-sectional dependence:
*! serial correlation, heteroskedasticity, normality and parameter stability tested unit by
*! unit on CCE (Pesaran 2006), mean-group or two-way fixed-effects residuals, with exact
*! Monte Carlo unit p-values (Dufour et al. 1998, 2004) combined across units (Fisher;
*! inverse normal), and CD tests of the residuals (Pesaran 2015; Juodis and Reese 2022).
*! Author : Yusuf Toyin Yusuf, Kwara State University (yusuf.yusuf@kwasu.edu.ng)

capture program drop xtcsddiag
program define xtcsddiag, rclass sortpreserve
    version 14

    syntax varlist(min=2 numeric ts) [if] [in] [,  ///
        ESTimator(string) Lags(integer 1) Reps(integer 999) SEED(string) ///
        GENerate(name) UNITs NODisplay ]

    gettoken depvar xvars : varlist
    local xvars = strtrim("`xvars'")

    qui xtset
    local ivar "`r(panelvar)'"
    local tvar "`r(timevar)'"
    local tdelta = r(tdelta)
    if "`ivar'" == "" | "`tvar'" == "" {
        di as err "panel and time variables must be set; use {bf:xtset} panelvar timevar"
        exit 459
    }
    local estimator = lower(strtrim("`estimator'"))
    if "`estimator'" == "" local estimator "cce"
    if !inlist("`estimator'", "cce", "mg", "fe") {
        di as err "estimator() must be cce, mg or fe"
        exit 198
    }
    local est = cond("`estimator'" == "cce", 1, cond("`estimator'" == "mg", 2, 3))
    if `lags' < 1 {
        di as err "lags() must be a positive integer"
        exit 198
    }
    if `reps' < 19 {
        di as err "reps() must be at least 19"
        exit 198
    }
    if "`generate'" != "" confirm new variable `generate'
    if "`seed'" != "" set seed `seed'

    marksample touse
    markout `touse' `ivar' `tvar'
    tsrevar `depvar'
    local yt "`r(varlist)'"
    tsrevar `xvars'
    local xt "`r(varlist)'"
    local k : word count `xt'

    // each unit's observations must be consecutive (lags of the residuals)
    tempvar gap nseen
    sort `ivar' `tvar'
    qui by `ivar': gen long `nseen' = sum(`touse')
    qui by `ivar': gen byte `gap' = (`tvar' - `tvar'[_n-1] != `tdelta') if `touse' & _n > 1 & `touse'[_n-1]
    qui by `ivar': replace `gap' = 1 if `touse' & _n > 1 & !`touse'[_n-1] & `nseen' > 1
    qui count if `gap' == 1
    if r(N) > 0 {
        di as err "the observations of some units are not consecutive in `tvar'; xtcsddiag needs gap-free unit series"
        exit 459
    }

    // cross-section averages (CCE)
    local zt ""
    if `est' == 1 {
        foreach v in `yt' `xt' {
            tempvar m
            qui bysort `touse' `tvar': egen double `m' = mean(`v') if `touse'
            local zt "`zt' `m'"
        }
    }
    sort `ivar' `tvar'
    qui count if `touse'
    local nobs = r(N)
    tempvar first
    qui by `ivar': gen byte `first' = sum(`touse') == 1 & `touse'
    qui count if `first'
    local Nall = r(N)
    if `Nall' < 2 {
        di as err "at least 2 panel units are needed"
        exit 2001
    }

    _xtcsddiag_load
    tempvar ehat
    qui gen double `ehat' = .
    tempname UN CB CD BM INFO
    local chunk = min(`reps', 200)
    mata: xcs_run("`yt'", "`xt'", "`zt'", "`ivar'", "`tvar'", "`touse'", "`ehat'", ///
        `est', `lags', `reps', `chunk', "`UN'", "`CB'", "`CD'", "`BM'", "`INFO'")
    local N = el(`INFO', 1, 2)
    if `N' < 2 {
        di as err "fewer than 2 units have enough observations for the unit tests"
        exit 2001
    }

    matrix colnames `UN' = id T stat_bg stat_bp stat_jb stat_cusum stat_hansen ///
        p_bg p_bp p_jb p_cusum p_hansen
    matrix rownames `CB' = serial hetero normality cusum hansen
    matrix colnames `CB' = units fisher p_fisher z_invnorm p_invnorm share_rej
    matrix colnames `CD' = CD p_CD CDw p_CDw pairs mean_absrho
    matrix colnames `BM' = `xvars'

    local estname = cond(`est' == 1, "CCE (unit OLS with cross-section averages)", ///
        cond(`est' == 2, "mean group (unit OLS)", "two-way fixed effects (common slopes)"))
    if "`nodisplay'" == "" {
        _xtcsddiag_display, un(`UN') cb(`CB') cd(`CD') estname(`estname') ///
            ivar(`ivar') nall(`Nall') n(`N') tmin(`=el(`INFO',1,3)') tmax(`=el(`INFO',1,4)') ///
            lags(`lags') reps(`reps') depvar(`depvar') est(`est') `units'
    }

    if "`generate'" != "" {
        qui gen double `generate' = `ehat'
        label variable `generate' "xtcsddiag residuals (`estimator')"
    }

    return scalar N_g = `N'
    return scalar N_all = `Nall'
    return scalar N = `nobs'
    return scalar T_min = el(`INFO', 1, 3)
    return scalar T_max = el(`INFO', 1, 4)
    return scalar lags = `lags'
    return scalar reps = `reps'
    local tn "serial hetero normality cusum hansen"
    local j 0
    foreach t of local tn {
        local ++j
        return scalar p_`t'_fisher  = el(`CB', `j', 3)
        return scalar p_`t'_invnorm = el(`CB', `j', 5)
    }
    return scalar CD = el(`CD', 1, 1)
    return scalar p_CD = el(`CD', 1, 2)
    return scalar CDw = el(`CD', 1, 3)
    return scalar p_CDw = el(`CD', 1, 4)
    return local estimator "`estimator'"
    return local depvar "`depvar'"
    return local indepvars "`xvars'"
    return matrix b = `BM'
    return matrix cd = `CD'
    return matrix units = `UN'
    return matrix table = `CB'
end
