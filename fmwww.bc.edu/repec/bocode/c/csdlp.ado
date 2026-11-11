*! csdlp 1.0.0  09nov2026
*! Causal state-dependent local projections: sieve LP with pointwise and
*! state-uniform inference for micro-macro panels
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane
*
* Implements David, Giacomini, Jiao & Wang (2026) "Causal State-Dependent
* Local Projections", FRB Chicago WP 2026-18, doi:10.21033/wp-2026-18.
*
*   Y_{i,t+h} = g_h(Z_{i,t-1}) X_t + W'_{i,t-1} gamma_h + u_{i,t+h}      (3)
*   g_h(z) ~ phi_J(z)' b_h, cubic B-splines, knots at empirical quantiles (6)
*   OLS (8); J by AIC (10)-(11) [BIC, GCV, LASSO, fixed also available]
*   HAC on the time-aggregated score (13)-(16); pointwise CI (17)-(18)
*   studentized sup-t uniform band via Gaussian simulation (19)-(21)
*   benchmark: linear-interaction LP (2b) and its Lemma-1 decomposition
*
* Full step -> equation map: help csdlp_methods

program define csdlp
    version 15.0
    * Mata functions in this file are private to csdlp.ado, so the
    * postestimation commands dispatch back into it.
    gettoken first rest : 0, parse(" ,")
    if "`first'" == "__diff" {
        _csdlp_diff `rest'
        exit
    }
    if "`first'" == "__agg" {
        _csdlp_agg `rest'
        exit
    }
    if replay() {
        if "`e(cmd)'" != "csdlp" {
            error 301
        }
        _csdlp_display `0'
        exit
    }
    _csdlp_est `0'
end

program define _csdlp_est, eclass sortpreserve
    version 15.0
    syntax varname(ts numeric) [if] [in] , SHock(varname ts numeric)       ///
        STate(varname ts numeric)                                          ///
        [ Horizons(numlist integer >=0 sort) CONTrols(varlist ts fv numeric) ///
          ABsorb(string) CUMulative NOCONStant INTERmediate                ///
          SELect(string) NBasis(numlist integer >=4 max=1)                 ///
          JMIN(integer 4) JMAX(integer 20) JLASso(integer 50)              ///
          VCE(string) Level(cilevel) LEVEL2(real 68) REPS(integer 2000)    ///
          SEED(string) GRID(integer 200) RANGE(numlist min=2 max=2 >=0 <=100) ///
          ZRANGE(numlist min=2 max=2 ascending) SCale(real 1)              ///
          QUantiles(numlist >0 <100) NORMalize(string)                     ///
          NOGRaph NOTABle GHorizons(numlist integer >=0) NAME(string)      ///
          SAVing(string) noLINear ]

    * ------------------------------------------------------------ checks
    qui tsset
    local ivar "`r(panelvar)'"
    local tvar "`r(timevar)'"
    local tdelta = r(tdelta)
    if "`tvar'" == "" {
        di as err "data must be {cmd:xtset} (panel) or {cmd:tsset} (single time series)"
        exit 459
    }
    if "`horizons'" == "" {
        local horizons 0
    }
    if "`select'" == "" {
        local select aic
    }
    local select = lower("`select'")
    if !inlist("`select'", "aic", "bic", "gcv", "lasso") {
        di as err "select() must be aic, bic, gcv or lasso"
        exit 198
    }
    if "`nbasis'" != "" {
        local select fixed
    }
    if `jmin' < 4 | `jmax' < `jmin' {
        di as err "need 4 <= jmin() <= jmax()"
        exit 198
    }
    if `reps' < 100 {
        di as err "reps() must be at least 100"
        exit 198
    }
    if `level2' < 0 | `level2' >= 100 {
        di as err "level2() must be in [0,100); 0 suppresses the inner band"
        exit 198
    }
    if `level2' >= `level' & `level2' > 0 {
        di as err "level2() must be smaller than level()"
        exit 198
    }
    if `grid' < 10 {
        di as err "grid() must be at least 10"
        exit 198
    }
    * vce
    local vcetype nw
    local lagfix 0
    if "`vce'" != "" {
        gettoken v1 v2 : vce
        local v1 = lower("`v1'")
        if inlist("`v1'", "nw", "hac", "newey", "driscoll", "dk") {
            local vcetype nw
            if "`v2'" != "" {
                confirm integer number `v2'
                local vcetype nwfix
                local lagfix = `v2'
            }
        }
        else if inlist("`v1'", "hlag", "h") {
            local vcetype hlag
        }
        else if inlist("`v1'", "cluster", "cl", "time") {
            local vcetype cluster
        }
        else {
            di as err "vce() must be nw [#], hlag or cluster"
            exit 198
        }
    }
    * normalisation
    local normopt -1
    if "`normalize'" != "" {
        local nz = lower("`normalize'")
        if inlist("`nz'", "on", "yes", "mean") {
            local normopt 1
        }
        else if inlist("`nz'", "off", "no", "none") {
            local normopt 0
        }
        else if "`nz'" != "auto" {
            di as err "normalize() must be auto, on or off"
            exit 198
        }
    }
    if "`quantiles'" == "" {
        local quantiles 5 25 50 75 95
    }

    * ------------------------------------------------------------ sample
    marksample touse, novarlist
    tsrevar `shock'
    local X `r(varlist)'
    tsrevar `state'
    local Z `r(varlist)'
    local W
    if "`controls'" != "" {
        fvrevar `controls'
        local W `r(varlist)'
    }
    markout `touse' `X' `Z' `W'

    local fevars
    local absorblist
    if "`absorb'" != "" {
        local absorb : subinstr local absorb "i." "", all
        foreach a of local absorb {
            local aa : subinstr local a "#" " ", all
            tempvar gfe
            qui egen long `gfe' = group(`aa') if `touse'
            markout `touse' `gfe'
            local fevars `fevars' `gfe'
            local absorblist `absorblist' `a'
        }
    }
    local addcons = ("`noconstant'" == "" & "`absorb'" == "")

    qui count if `touse'
    if r(N) < 30 {
        di as err "insufficient observations"
        exit 2001
    }
    * aggregate-shock check
    if "`ivar'" != "" {
        tempvar sdx
        qui bysort `tvar' `touse': egen double `sdx' = sd(`X') if `touse'
        qui summarize `sdx' if `touse', meanonly
        if r(max) > 1e-8 & r(max) < . {
            di as txt "(note: {bf:`shock'} varies across units within a period;" ///
                " csdlp treats it as an aggregate shock X_t)"
        }
        qui sort `ivar' `tvar'
    }
    qui summarize `tvar' if `touse', meanonly
    local tmin = r(min)

    * ------------------------------------------------------------ grid
    tempname GRIDM
    if "`zrange'" != "" {
        local za : word 1 of `zrange'
        local zb : word 2 of `zrange'
    }
    else {
        if "`range'" == "" {
            local range 5 95
        }
        local r1 : word 1 of `range'
        local r2 : word 2 of `range'
        if `r1' >= `r2' {
            di as err "range() must be increasing percentiles"
            exit 198
        }
        qui summarize `Z' if `touse'
        local za = r(min)
        local zb = r(max)
        if `r1' > 0 {
            _pctile `Z' if `touse', p(`r1')
            local za = r(r1)
        }
        if `r2' < 100 {
            _pctile `Z' if `touse', p(`r2')
            local zb = r(r1)
        }
    }
    mata: st_matrix("`GRIDM'", rangen(`za', `zb', `grid')')

    if "`seed'" != "" {
        set seed `seed'
    }

    * ------------------------------------------------------------ horizons
    local Jlist
    forvalues j = `jmin'/`jmax' {
        local Jlist `Jlist' `j'
    }
    if "`select'" == "fixed" {
        local Jlist `nbasis'
    }
    local crit `select'

    tempname IRF SUM QT JSEL
    tempvar esamp
    qui gen byte `esamp' = 0
    local first 1
    local mats
    foreach h of local horizons {
        tempvar yh th
        if `h' == 0 {
            if "`cumulative'" != "" {
                qui gen double `yh' = `varlist' - L.`varlist' if `touse'
            }
            else {
                qui gen double `yh' = `varlist' if `touse'
            }
        }
        else {
            if "`cumulative'" != "" {
                qui gen double `yh' = F`h'.`varlist' - L.`varlist' if `touse'
            }
            else {
                qui gen double `yh' = F`h'.`varlist' if `touse'
            }
        }
        local xf
        if "`intermediate'" != "" & `h' > 0 {
            forvalues j = 1/`h' {
                tempvar xf`j'
                qui gen double `xf`j'' = F`j'.`X' if `touse'
                local xf `xf' `xf`j''
            }
        }
        qui gen byte `th' = `touse'
        markout `th' `yh' `xf'
        qui count if `th'
        if r(N) < 30 {
            di as err "horizon `h': insufficient observations (" r(N) ")"
            exit 2001
        }

        local Jh `Jlist'
        local crith `crit'
        if "`select'" == "lasso" {
            _csdlp_lassoJ `yh' `X' `Z' "`W'" "`fevars'" `th' `jlasso' `addcons' `jmax'
            local Jh = r(J)
            local crith fixed
        }

        mata: csdlp_horizon(`h', "`yh'", "`X'", "`Z'", "`W'", "`xf'",      ///
            "`fevars'", "`ivar'", "`tvar'", "`th'", `tmin', `tdelta',      ///
            strtoreal(tokens("`Jh'")), "`crith'", "`vcetype'", `lagfix',   ///
            `normopt', `addcons', "`GRIDM'", `reps', `level', `level2',    ///
            strtoreal(tokens("`quantiles'")), `scale')

        matrix `IRF' = nullmat(`IRF') \ __csdlp_irf
        matrix `SUM' = nullmat(`SUM') \ __csdlp_sum
        matrix `QT'  = nullmat(`QT') \ __csdlp_q
        matrix `JSEL' = nullmat(`JSEL'), __csdlp_sum[1,5]
        foreach m in b V kn cen bl Vl ic {
            tempname `m'`h'
            matrix ``m'`h'' = __csdlp_`m'
        }
        local zbar`h' = scalar(__csdlp_zbar)
        local norm`h' = scalar(__csdlp_norm)
        if `first' {
            qui replace `esamp' = `th'
            local first 0
        }
        capture matrix drop __csdlp_irf __csdlp_sum __csdlp_q __csdlp_b __csdlp_V
        capture matrix drop __csdlp_kn __csdlp_cen __csdlp_bl __csdlp_Vl __csdlp_ic
    }
    capture scalar drop __csdlp_zbar __csdlp_norm

    * ------------------------------------------------------------ post
    matrix colnames `IRF' = h z g se pw_lo pw_hi u_lo u_hi u2_lo u2_hi    ///
        glin selin lpw_lo lpw_hi lu_lo lu_hi gprime omega
    matrix colnames `SUM' = h obs N T J lags crit crit2 b_lin se_lin p_lin ///
        b_proj W_nonlin df_nonlin p_nonlin W_nosd df_nosd p_nosd supt      ///
        p_supt aic normalized
    matrix colnames `QT' = h pctile z g se p glin selin plin
    local hn
    foreach h of local horizons {
        local hn `hn' h`h'
    }
    matrix colnames `JSEL' = `hn'
    matrix rownames `SUM' = `hn'

    local nh : word count `horizons'
    local h0 : word 1 of `horizons'
    qui count if `esamp'
    local N0 = r(N)
    ereturn post, esample(`esamp') obs(`N0')
    ereturn scalar N_g     = `SUM'[1,3]
    ereturn scalar T       = `SUM'[1,4]
    ereturn scalar n_h     = `nh'
    ereturn scalar level   = `level'
    ereturn scalar level2  = `level2'
    ereturn scalar reps    = `reps'
    ereturn scalar scale   = `scale'
    ereturn scalar jmin    = `jmin'
    ereturn scalar jmax    = `jmax'
    ereturn scalar normalized = `SUM'[1,22]
    ereturn local cmd       "csdlp"
    ereturn local cmdline   "csdlp `0'"
    ereturn local title     "Causal state-dependent local projections"
    ereturn local depvar    "`varlist'"
    ereturn local shock     "`shock'"
    ereturn local state     "`state'"
    ereturn local controls  "`controls'"
    ereturn local absorb    "`absorblist'"
    ereturn local horizons  "`horizons'"
    ereturn local select    "`select'"
    ereturn local vce       "`vcetype'"
    ereturn local ivar      "`ivar'"
    ereturn local tvar      "`tvar'"
    ereturn local cumulative "`cumulative'"
    ereturn local intermediate "`intermediate'"
    ereturn local constant  = cond(`addcons', "yes", "no")
    ereturn local quantiles "`quantiles'"
    ereturn local jlasso    "`jlasso'"
    foreach h of local horizons {
        ereturn scalar zbar_h`h' = `zbar`h''
        foreach m in b V kn cen bl Vl ic {
            ereturn matrix `m'_h`h' = ``m'`h''
        }
    }
    ereturn matrix J       = `JSEL'
    ereturn matrix quant   = `QT'
    ereturn matrix summary = `SUM'
    ereturn matrix irf     = `IRF'

    if "`notable'" == "" {
        _csdlp_display
    }
    if "`nograph'" == "" {
        local gopt
        if "`ghorizons'" != "" {
            local gopt `gopt' horizons(`ghorizons')
        }
        if "`name'" != "" {
            local gopt `gopt' name(`name')
        }
        if "`saving'" != "" {
            local gopt `gopt' saving(`saving')
        }
        if "`linear'" != "" {
            local gopt `gopt' nolinear
        }
        capture noisily csdlp_graph, `gopt'
    }
end

* ---------------------------------------------------------------- lasso J
program define _csdlp_lassoJ, rclass
    version 16.0
    args yh X Z W fev th jl addcons jmax
    local nw : word count `W'
    tempvar yd
    qui gen double `yd' = .
    local wd
    forvalues k = 1/`nw' {
        tempvar w`k'
        qui gen double `w`k'' = .
        local wd `wd' `w`k''
    }
    local pv
    forvalues k = 1/`jl' {
        tempvar p`k'
        qui gen double `p`k'' = .
        local pv `pv' `p`k''
    }
    mata: csdlp_lassoprep("`yh'", "`X'", "`Z'", "`W'", "`fev'", "`th'", ///
        `jl', `addcons', "`yd'", "`wd'", "`pv'")
    local nbl = scalar(__csdlp_nbl)
    capture scalar drop __csdlp_nbl
    local pv2
    forvalues k = 1/`nbl' {
        local pv2 `pv2' `p`k''
    }
    local always
    if "`wd'" != "" {
        local always (`wd')
    }
    capture qui lasso linear `yd' `always' `pv2' if `th', selection(cv)
    if _rc {
        di as err "lasso selection failed (Stata 16+ {cmd:lasso} required); rc=" _rc
        exit _rc
    }
    local sel "`e(allvars_sel)'"
    local cnt 0
    foreach v of local pv2 {
        local hit : list v in sel
        local cnt = `cnt' + `hit'
    }
    local J = max(4, `cnt')
    return scalar J = `J'
    return scalar nsel = `cnt'
end

* ---------------------------------------------------------------- display
program define _csdlp_display
    version 15.0
    tempname S Q
    matrix `S' = e(summary)
    matrix `Q' = e(quant)
    local nh = rowsof(`S')
    local lev = e(level)
    local lev2 = e(level2)
    local stt "`e(state)'"
    local sel = upper("`e(select)'")
    if "`sel'" == "FIXED" {
        local sel "fixed J"
    }
    local vce "`e(vce)'"
    if "`vce'" == "nw" {
        local vced "Newey-West HAC on time-aggregated score, L=floor(4((T-h)/100)^(2/9))"
    }
    if "`vce'" == "nwfix" {
        local vced "Newey-West HAC on time-aggregated score, fixed L"
    }
    if "`vce'" == "hlag" {
        local vced "Newey-West HAC on time-aggregated score, L = h"
    }
    if "`vce'" == "cluster" {
        local vced "clustered by time period (L = 0)"
    }

    di
    di as txt "{bf:Causal state-dependent local projections}" ///
        _col(52) "Number of obs (h=" el(`S',1,1) ") = " as res %9.0fc el(`S',1,2)
    di as txt "David, Giacomini, Jiao & Wang (2026)" ///
        _col(52) "Units (N)         = " as res %9.0fc e(N_g)
    di as txt "Sieve LP with state-uniform inference" ///
        _col(52) "Periods (T)       = " as res %9.0fc e(T)
    di
    di as txt "  Outcome   : " as res "`e(depvar)'" as txt cond("`e(cumulative)'"!="", "  (cumulative: y[t+h] - y[t-1])", "")
    di as txt "  Shock X(t): " as res "`e(shock)'" as txt "     State Z(i,t-1): " as res "`stt'"
    if "`e(controls)'" != "" {
        di as txt "  Controls  : " as res "`e(controls)'"
    }
    if "`e(absorb)'" != "" {
        di as txt "  Absorbed  : " as res "`e(absorb)'"
    }
    local jr = cond("`e(select)'"!="fixed", " over J = " + string(e(jmin)) + ",...," + string(e(jmax)), "")
    if "`e(select)'" == "lasso" {
        local jr " (CV-lasso at J_max = `e(jlasso)'; J = # non-zero sieve terms, min 4)"
    }
    di as txt "  Sieve     : cubic B-splines, knots at empirical quantiles; J by " ///
        as res "`sel'" as txt "`jr'"
    di as txt "  VCE       : `vced'"
    di as txt "  Bands     : studentized sup-t, " as res e(reps) as txt " Gaussian draws" ///
        cond(e(scale)!=1, "; responses scaled by delta = " + string(e(scale)), "")
    if e(normalized) == 1 {
        di as txt "  Note      : X_t absorbed by fixed effects; g_h(.) normalised to zero mean over the sample"
    }
    if "`e(intermediate)'" != "" {
        di as txt "  Note      : intermediate shocks X_{t+j} x phi(Z), j=1..h, included as controls"
    }

    * ---------------- Table 1
    di
    di as txt "{bf:Table 1. Sieve selection, linear benchmark and tests of state dependence}"
    di as txt "{hline 106}"
    di as txt "    h" _col(10) "Obs" _col(16) "J" _col(20) "Lags" ///
        _col(28) "Linear SD-LP slope" _col(57) "Proj." ///
        _col(67) "Linearity" _col(81) "No-SD" _col(90) "sup-t" _col(98) "sup-t"
    di as txt _col(32) "(s.e.)" _col(56) "(Lem. 1)" _col(66) "chi2" _col(75) "p" ///
        _col(83) "p" _col(90) "c(" %2.0f `lev' ")" _col(98) "p(g=0)"
    di as txt "{hline 106}"
    forvalues r = 1/`nh' {
        local pl = el(`S',`r',11)
        local st = cond(`pl'<.01, "***", cond(`pl'<.05, "**", cond(`pl'<.1, "*", "")))
        local wnl = el(`S',`r',13)
        local wnlf "%8.2f"
        if `wnl' >= 1e5 & `wnl' < . {
            local wnlf "%8.2e"
        }
        di as res %5.0f el(`S',`r',1) _col(7) %7.0f el(`S',`r',2) ///
            _col(15) %3.0f el(`S',`r',5) _col(20) %4.0f el(`S',`r',6) ///
            _col(27) %10.4f el(`S',`r',9) as txt "`st'" ///
            _col(41) "(" as res %8.4f el(`S',`r',10) as txt ")" ///
            _col(54) as res %9.4f el(`S',`r',12) ///
            _col(64) `wnlf' `wnl' _col(73) %6.3f el(`S',`r',15) ///
            _col(80) %6.3f el(`S',`r',18) ///
            _col(89) %6.3f el(`S',`r',7) _col(98) %6.3f el(`S',`r',20)
    }
    di as txt "{hline 106}"
    di as txt "  Slope: coefficient on Z*X in the standard LP (2b). Proj.: sample analogue of Lemma 1,"
    di as txt "  E[X^2(Z-mu)g(Z)]/E[X^2(Z-mu)^2] -- what the linear slope averages (slopes of g, not levels)."
    di as txt "  Linearity / No-SD: auxiliary HAC-Wald tests of H0: g_h linear / constant in z (cond. on J)."
    di as txt "  sup-t c: studentized uniform critical value; p(g=0): sup-t test of H0: g_h(z)=0 on the grid."

    * ---------------- Table 2
    di
    di as txt "{bf:Table 2. Causal state-dependent IRF g_h(z) at quantiles of the state}"
    di as txt "{hline 84}"
    di as txt "    h" _col(8) "pctile" _col(18) "z" ///
        _col(30) "Sieve g_h(z)" _col(47) "(s.e.)" _col(58) "Linear g_h(z)" _col(76) "(s.e.)"
    di as txt "{hline 84}"
    local nq = rowsof(`Q')
    local hprev = .
    forvalues r = 1/`nq' {
        local hh = el(`Q',`r',1)
        if `hh' != `hprev' & `r' > 1 {
            di as txt "{hline 84}"
        }
        local p1 = el(`Q',`r',6)
        local s1 = cond(`p1'<.01, "***", cond(`p1'<.05, "**", cond(`p1'<.1, "*", "")))
        local p2 = el(`Q',`r',9)
        local s2 = cond(`p2'<.01, "***", cond(`p2'<.05, "**", cond(`p2'<.1, "*", "")))
        if `hh' != `hprev' {
            di as res %5.0f `hh' _c
        }
        di as res _col(8) %5.0f el(`Q',`r',2) _col(14) %9.3f el(`Q',`r',3) ///
            _col(28) %11.4f el(`Q',`r',4) as txt "`s1'" ///
            _col(45) "(" as res %8.4f el(`Q',`r',5) as txt ")" ///
            _col(57) as res %11.4f el(`Q',`r',7) as txt "`s2'" ///
            _col(74) "(" as res %8.4f el(`Q',`r',8) as txt ")"
        local hprev = `hh'
    }
    di as txt "{hline 84}"
    di as txt "  *** p<0.01, ** p<0.05, * p<0.10 (pointwise, eq. 18).  Uniform bands: {stata csdlp_graph}"
    di as txt "  Differential responses: {help csdlp_postestimation:csdlp_diff};  aggregation: {help csdlp_postestimation:csdlp_agg}"
end

* ---------------------------------------------------------------- csdlp_diff
* differential response g_h(z_a) - g_h(z_b) across horizons (paper Fig. 4,
* footnote 17): variance (phi(z_a)-phi(z_b))' V_h (phi(z_a)-phi(z_b))
program define _csdlp_diff, rclass
    version 15.0
    if "`e(cmd)'" != "csdlp" {
        di as err "csdlp_diff requires {cmd:csdlp} results in memory"
        exit 301
    }
    syntax , AT(numlist min=2 max=2) [ VALues Horizons(numlist integer >=0) ///
        Level(cilevel) LEVEL2(real 68) NOGRaph NAME(string) SAVing(string)  ///
        noLINear ]
    local hall "`e(horizons)'"
    if "`horizons'" == "" {
        local horizons `hall'
    }
    foreach h of local horizons {
        local ok : list h in hall
        if !`ok' {
            di as err "horizon `h' was not estimated"
            exit 198
        }
    }
    if `level2' < 0 | `level2' >= `level' {
        local level2 0
    }
    local a1 : word 1 of `at'
    local a2 : word 2 of `at'
    if "`values'" == "" {
        if `a1' <= 0 | `a1' >= 100 | `a2' <= 0 | `a2' >= 100 {
            di as err "at() percentiles must lie in (0,100); use option values for state values"
            exit 198
        }
        tempvar zz
        qui tsrevar `e(state)'
        local zvar `r(varlist)'
        qui count if e(sample)
        if r(N) == 0 {
            * e(sample) is not restored by -estimates use-
            di as txt "(note: e(sample) unavailable -- percentiles computed over all" ///
                " non-missing values of `e(state)'; re-run csdlp for exact sample)"
            qui gen double `zz' = `zvar'
        }
        else {
            qui gen double `zz' = `zvar' if e(sample)
        }
        qui count if `zz' < .
        if r(N) == 0 {
            di as err "no non-missing values of `e(state)' in memory; use option values"
            exit 2000
        }
        _pctile `zz', p(`a1')
        local za = r(r1)
        _pctile `zz', p(`a2')
        local zb = r(r1)
        local lab "p`a1' vs p`a2'"
    }
    else {
        local za = `a1'
        local zb = `a2'
        local lab "z=`a1' vs z=`a2'"
    }
    local sc = e(scale)
    tempname R row
    foreach h of local horizons {
        mata: st_matrix("`row'", _csdlp_lcdiff(`za', `zb', `h', `sc'))
        matrix `R' = nullmat(`R') \ (`h', `za', `zb', `row')
    }
    * columns: h za zb d se dl sel
    local zc1 = invnormal(1-(1-`level'/100)/2)
    local zc2 = cond(`level2'>0, invnormal(1-(1-`level2'/100)/2), .)
    tempname OUT
    local nr = rowsof(`R')
    matrix `OUT' = J(`nr', 15, .)
    forvalues r = 1/`nr' {
        local d  = `R'[`r',4]
        local s  = `R'[`r',5]
        local dl = `R'[`r',6]
        local sl = `R'[`r',7]
        matrix `OUT'[`r',1]  = `R'[`r',1]
        matrix `OUT'[`r',2]  = `d'
        matrix `OUT'[`r',3]  = `s'
        matrix `OUT'[`r',4]  = `d' - `zc1'*`s'
        matrix `OUT'[`r',5]  = `d' + `zc1'*`s'
        matrix `OUT'[`r',6]  = `d' - `zc2'*`s'
        matrix `OUT'[`r',7]  = `d' + `zc2'*`s'
        matrix `OUT'[`r',8]  = 2*normal(-abs(`d'/`s'))
        matrix `OUT'[`r',9]  = `dl'
        matrix `OUT'[`r',10] = `sl'
        matrix `OUT'[`r',11] = `dl' - `zc1'*`sl'
        matrix `OUT'[`r',12] = `dl' + `zc1'*`sl'
        matrix `OUT'[`r',13] = `dl' - `zc2'*`sl'
        matrix `OUT'[`r',14] = `dl' + `zc2'*`sl'
        matrix `OUT'[`r',15] = 2*normal(-abs(`dl'/`sl'))
    }
    matrix colnames `OUT' = h d se lo hi lo2 hi2 p dlin selin llo lhi llo2 lhi2 plin

    di
    di as txt "{bf:Differential state-dependent responses: g_h(z_a) - g_h(z_b)}"
    di as txt "  z_a = " as res %9.4f `za' as txt ",  z_b = " as res %9.4f `zb' ///
        as txt "  (`lab';  state: `e(state)')"
    di as txt "{hline 78}"
    di as txt "    h" _col(14) "Sieve diff" _col(29) "(s.e.)" _col(39) "[`level'% pointwise CI]" ///
        _col(64) "Linear diff" _col(76) ""
    di as txt "{hline 78}"
    forvalues r = 1/`nr' {
        local p1 = `OUT'[`r',8]
        local s1 = cond(`p1'<.01, "***", cond(`p1'<.05, "**", cond(`p1'<.1, "*", "")))
        local p2 = `OUT'[`r',15]
        local s2 = cond(`p2'<.01, "***", cond(`p2'<.05, "**", cond(`p2'<.1, "*", "")))
        di as res %5.0f `OUT'[`r',1] _col(11) %11.4f `OUT'[`r',2] as txt "`s1'" ///
            _col(27) "(" as res %8.4f `OUT'[`r',3] as txt ")" ///
            _col(39) "[" as res %9.4f `OUT'[`r',4] as txt "," as res %9.4f `OUT'[`r',5] as txt "]" ///
            _col(62) as res %11.4f `OUT'[`r',9] as txt "`s2'"
    }
    di as txt "{hline 78}"
    di as txt "  Pointwise inference as in the paper's Fig. 4 (eq. 17-18 applied to phi(z_a)-phi(z_b))."
    di as txt "  *** p<0.01, ** p<0.05, * p<0.10"

    if "`nograph'" == "" & `nr' >= 2 {
        if "`name'" == "" {
            local name csdlp_diff
        }
        preserve
        qui {
            clear
            svmat double `OUT', names(col)
        }
        local pl
        local lg
        local k 0
        local pl `pl' (rarea lo hi h, color(navy%18) lwidth(none))
        local k = `k' + 1
        local lg `lg' `k' "`level'% CI"
        if `level2' > 0 {
            local pl `pl' (rarea lo2 hi2 h, color(navy%38) lwidth(none))
            local k = `k' + 1
            local lg `lg' `k' "`level2'% CI"
        }
        local pl `pl' (connected d h, lcolor(navy) mcolor(navy) msize(small) lwidth(medthick))
        local k = `k' + 1
        local lg `lg' `k' "Nonparametric (sieve)"
        if "`linear'" == "" {
            local pl `pl' (connected dlin h, lcolor(cranberry) mcolor(cranberry) msymbol(Oh) msize(small) lpattern(dash))
            local k = `k' + 1
            local lg `lg' `k' "Linear interaction"
        }
        twoway `pl', yline(0, lcolor(gs8)) xtitle("Horizon h") ///
            ytitle("Differential response") title("`lab'", size(medium)) ///
            graphregion(color(white)) plotregion(color(white) lcolor(gs12)) ///
            ylabel(, angle(horizontal) grid glcolor(gs15) glpattern(solid)) ///
            legend(order(`lg') rows(1) size(small) position(6) ring(1) region(lcolor(white))) ///
            name(`name', replace)
        if "`saving'" != "" {
            qui graph export "`saving'.png", replace width(2000)
        }
        restore
    }
    return scalar za = `za'
    return scalar zb = `zb'
    return matrix diff = `OUT'
end

* ---------------------------------------------------------------- csdlp_agg
* aggregate responsiveness (paper Sec. 6.2):
*   A_{t,h} = sum_i [K_{i,t-1}/sum_j K_{j,t-1}] g_h(Z_{i,t-1})
* a linear functional a_t'b_h of the sieve coefficients, so
* se(A_{t,h}) = sqrt(a_t' V_h a_t)
program define _csdlp_agg, rclass
    version 15.0
    if "`e(cmd)'" != "csdlp" {
        di as err "csdlp_agg requires {cmd:csdlp} results in memory"
        exit 301
    }
    syntax varname(ts numeric) [if] [in] [, Horizon(integer -1) Level(cilevel) ///
        NOGRaph NAME(string) SAVing(string) noLINear ALLobs CI ]
    local hall "`e(horizons)'"
    if `horizon' < 0 {
        local horizon : word 1 of `hall'
    }
    local ok : list horizon in hall
    if !`ok' {
        di as err "horizon `horizon' was not estimated"
        exit 198
    }
    marksample touse
    if "`allobs'" == "" {
        qui count if e(sample)
        if r(N) == 0 {
            di as err "e(sample) is not available (e.g. after {cmd:estimates use});" ///
                " re-run csdlp or specify option {cmd:allobs} with an if condition"
            exit 459
        }
        qui replace `touse' = 0 if !e(sample)
    }
    qui tsrevar `e(state)'
    local Z `r(varlist)'
    qui tsrevar `varlist'
    local K `r(varlist)'
    markout `touse' `Z' `K'
    qui count if `touse'
    if r(N) == 0 {
        di as err "no observations"
        exit 2000
    }
    qui count if `touse' & `K' < 0
    if r(N) > 0 {
        di as err "weights `varlist' must be non-negative"
        exit 459
    }
    local tvar "`e(tvar)'"
    local tfmt : format `tvar'
    local sc = e(scale)
    mata: _csdlp_aggm("`Z'", "`K'", "`tvar'", "`touse'", `horizon', `sc', `level')
    tempname A
    matrix `A' = __csdlp_agg
    capture matrix drop __csdlp_agg
    matrix colnames `A' = t agg se lo hi agglin selin llo lhi
    local mA  = scalar(__csdlp_m1)
    local smA = scalar(__csdlp_m2)
    local mL  = scalar(__csdlp_m3)
    local smL = scalar(__csdlp_m4)
    capture scalar drop __csdlp_m1 __csdlp_m2 __csdlp_m3 __csdlp_m4

    preserve
    qui {
        clear
        svmat double `A', names(col)
        summarize agg
        local sdA = r(sd)
        summarize agglin
        local sdL = r(sd)
        correlate agg agglin
        local rho = r(rho)
        format t `tfmt'
    }
    local nT = rowsof(`A')
    di
    di as txt "{bf:Aggregate responsiveness through state heterogeneity, h = `horizon'}"
    di as txt "  A(t) = sum_i [w(i,t)/sum_j w(j,t)] g_h(Z(i,t-1)),  weights: " as res "`varlist'"
    di as txt "{hline 70}"
    di as txt _col(30) "Sieve" _col(48) "Linear interaction"
    di as txt "{hline 70}"
    di as txt "  Time-average of A(t)" _col(24) as res %11.4f `mA' _col(46) %11.4f `mL'
    di as txt "    (s.e.)" _col(24) "(" as res %9.4f `smA' as txt ")" _col(46) "(" as res %9.4f `smL' as txt ")"
    di as txt "  Std. dev. over time" _col(24) as res %11.4f `sdA' _col(46) %11.4f `sdL'
    di as txt "  Corr(sieve, linear)" _col(24) as res %11.3f `rho'
    di as txt "  Periods" _col(24) as res %11.0f `nT'
    di as txt "{hline 70}"
    if e(normalized) == 1 {
        di as txt "  Note: g_h normalised (absorbed common component) -- A(t) is the incremental"
        di as txt "  component due to heterogeneity in the state, as in the paper's Sec. 6.2."
    }
    if "`nograph'" == "" {
        if "`name'" == "" {
            local name csdlp_agg
        }
        local pl
        local lg
        local k 0
        if "`ci'" != "" {
            local pl `pl' (rarea lo hi t, color(navy%20) lwidth(none))
            local k = `k' + 1
            local lg `lg' `k' "`level'% CI"
        }
        local pl `pl' (line agg t, lcolor(navy) lwidth(medthick))
        local k = `k' + 1
        local lg `lg' `k' "Nonparametric (sieve)"
        if "`linear'" == "" {
            local pl `pl' (line agglin t, lcolor(cranberry) lpattern(dash) lwidth(medthick))
            local k = `k' + 1
            local lg `lg' `k' "Linear interaction"
        }
        twoway `pl', yline(0, lcolor(gs8)) xtitle("") ///
            ytitle("Aggregate responsiveness, h = `horizon'") ///
            graphregion(color(white)) plotregion(color(white) lcolor(gs12)) ///
            ylabel(, angle(horizontal) grid glcolor(gs15) glpattern(solid)) ///
            legend(order(`lg') rows(1) size(small) position(6) ring(1) region(lcolor(white))) ///
            name(`name', replace)
        if "`saving'" != "" {
            qui graph export "`saving'.png", replace width(2000)
        }
    }
    restore
    return scalar mean = `mA'
    return scalar se_mean = `smA'
    return scalar mean_lin = `mL'
    return scalar se_mean_lin = `smL'
    return scalar sd = `sdA'
    return scalar sd_lin = `sdL'
    return scalar corr = `rho'
    return scalar horizon = `horizon'
    return matrix agg = `A'
end

* ================================================================ Mata engine
* Step -> equation map (David, Giacomini, Jiao & Wang 2026, WP 2026-18):
*   _csdlp_knots / _csdlp_bs : cubic B-spline sieve phi_J(z), interior knots
*                              at equally spaced empirical quantiles  eq.(6)
*   design D1 = X_t*phi(Z), W                                         eq.(7)
*   _csdlp_ols   : OLS theta_h(J)                                      eq.(8)
*   AIC/BIC/GCV  : sieve-dimension selection                    eq.(10)-(11)
*   P~ = Xphi - A12 A22^-1 W (FWL residual)                            eq.(13)
*   s_t = sum_i P~_it u_it ; Newey-West Omega, L=floor(4((T-h)/100)^(2/9))
*                                                                eq.(14)-(15)
*   V = A~11^-1 Omega A~11^-1 (raw-sum form, algebraically = eq.16)    eq.(16)
*   sigma^2(z) = phi(z)'V phi(z), pointwise CI                  eq.(17)-(18)
*   G = phi(z)'V^1/2 xi, studentized sup-t critical value       eq.(19)-(21)
*   Lemma 1: beta_proj, omega_h(z), g_h'(z)                          App. A
* Mata functions defined in an ado-file are private to that file; the
* postestimation commands therefore dispatch into csdlp (__diff, __agg).

version 15.0
mata:

real scalar _csdlp_ok()
{
    return(1)
}

struct _csdlp_fe {
    real scalar K
    pointer(real colvector) rowvector ord
    pointer(real colvector) rowvector gi
    pointer(real matrix) rowvector info
}

// ---------------------------------------------------------------- quantiles
real colvector _csdlp_quant(real colvector x, real colvector p)
{
    real colvector s, q
    real scalar n, i, hh, lo
    s = sort(x, 1)
    n = rows(s)
    q = J(rows(p), 1, .)
    for (i=1; i<=rows(p); i=i+1) {
        hh = (n-1)*p[i] + 1
        lo = floor(hh)
        if (lo < 1) lo = 1
        q[i] = s[n]
        if (lo < n) {
            q[i] = s[lo] + (hh-lo)*(s[lo+1]-s[lo])
        }
    }
    return(q)
}

// ---------------------------------------------------------------- knots
// full cubic knot vector: 4 x lo, interior knots at empirical quantiles
// l/(m+1), l=1..m (m = nbasis-4), 4 x hi
real rowvector _csdlp_knots(real colvector z, real scalar nbasis,
                            real scalar lo, real scalar hi)
{
    real scalar m
    real colvector iq
    m = nbasis - 4
    if (m <= 0) {
        return((J(1,4,lo), J(1,4,hi)))
    }
    iq = _csdlp_quant(z, (1::m)/(m+1))
    iq = uniqrows(iq)
    iq = select(iq, (iq:>lo) :& (iq:<hi))
    if (rows(iq)==0) {
        return((J(1,4,lo), J(1,4,hi)))
    }
    return((J(1,4,lo), iq', J(1,4,hi)))
}

// ---------------------------------------------------------------- B-spline
// cubic B-spline basis, local de Boor evaluation (only the 4 non-zero
// functions per point are computed, then scattered); n x (cols(t)-4).
// Numerically identical to the Cox-de Boor recursion _csdlp_bsref().
real matrix _csdlp_bs(real colvector x, real rowvector t)
{
    real scalar K, n, nb, k, j, r
    real colvector xx, s, tv, temp, saved, idx, Bv, rowi
    real matrix Lm, Rm, Nm
    K  = cols(t)
    n  = rows(x)
    nb = K - 4
    xx = rowmax((x, J(n,1,t[1])))
    xx = rowmin((xx, J(n,1,t[K])))
    s = J(n, 1, 4)
    for (k=5; k<=K-4; k=k+1) {
        s = s + (xx :>= t[k])
    }
    tv = t'
    Lm = J(n, 3, .)
    Rm = J(n, 3, .)
    for (j=1; j<=3; j=j+1) {
        Lm[., j] = xx - tv[s :+ (1-j)]
        Rm[., j] = tv[s :+ j] - xx
    }
    Nm = J(n, 4, 0)
    Nm[., 1] = J(n, 1, 1)
    for (j=1; j<=3; j=j+1) {
        saved = J(n, 1, 0)
        for (r=0; r<=j-1; r=r+1) {
            temp = Nm[., r+1] :/ (Rm[., r+1] + Lm[., j-r])
            Nm[., r+1] = saved + Rm[., r+1] :* temp
            saved = Lm[., j-r] :* temp
        }
        Nm[., j+1] = saved
    }
    Bv = J(n*nb, 1, 0)
    rowi = (1::n)
    for (r=0; r<=3; r=r+1) {
        idx = (rowi :- 1)*nb + (s :- 3 :+ r)
        Bv[idx] = Nm[., r+1]
    }
    return(colshape(Bv, nb))
}

// reference Cox-de Boor recursion (kept for validation)
real matrix _csdlp_bsref(real colvector x, real rowvector t)
{
    real scalar K, n, j, d, a, b, jl
    real colvector xx, v
    real matrix B, Bn
    K = cols(t)
    n = rows(x)
    xx = rowmax((x, J(n,1,t[1])))
    xx = rowmin((xx, J(n,1,t[K])))
    B = J(n, K-1, 0)
    jl = 0
    for (j=1; j<=K-1; j=j+1) {
        if (t[j] < t[j+1]) {
            B[., j] = (xx :>= t[j]) :& (xx :< t[j+1])
            jl = j
        }
    }
    if (jl > 0) {
        B[., jl] = B[., jl] + (xx :== t[K])
    }
    for (d=1; d<=3; d=d+1) {
        Bn = J(n, K-1-d, 0)
        for (j=1; j<=K-1-d; j=j+1) {
            v = J(n, 1, 0)
            a = t[j+d] - t[j]
            b = t[j+d+1] - t[j+1]
            if (a > 0) {
                v = v + ((xx :- t[j]) / a) :* B[., j]
            }
            if (b > 0) {
                v = v + ((t[j+d+1] :- xx) / b) :* B[., j+1]
            }
            Bn[., j] = v
        }
        B = Bn
    }
    return(B)
}

// basis actually used in estimation: full B-spline, or (under the
// normalisation for absorbed common components) columns 2..J centred
real matrix _csdlp_phi(real colvector z, real rowvector kn, real scalar norm,
                       real rowvector cen)
{
    real matrix P
    real scalar nb
    P = _csdlp_bs(z, kn)
    if (norm) {
        nb = cols(P)
        P = P[., (2..nb)] :- cen[(2..nb)]
    }
    return(P)
}

// linear-interaction basis (eq. 2b): (1, z) or, normalised, (z - zbar)
real matrix _csdlp_philin(real colvector z, real scalar norm, real scalar zbar)
{
    if (norm) {
        return(z :- zbar)
    }
    return((J(rows(z),1,1), z))
}

// ---------------------------------------------------------------- FE
struct _csdlp_fe scalar _csdlp_fesetup(real matrix F)
{
    struct _csdlp_fe scalar S
    real scalar k, n
    real colvector o, g
    real matrix inf
    S.K = cols(F)
    n = rows(F)
    S.ord  = J(1, max((S.K,1)), NULL)
    S.gi   = J(1, max((S.K,1)), NULL)
    S.info = J(1, max((S.K,1)), NULL)
    for (k=1; k<=S.K; k=k+1) {
        o = order(F[., k], 1)
        inf = panelsetup(F[o, k], 1)
        g = J(n, 1, 0)
        g[inf[., 1]] = J(rows(inf), 1, 1)
        g = runningsum(g)
        S.ord[k]  = &(o :+ 0)
        S.gi[k]   = &(g :+ 0)
        S.info[k] = &(inf :+ 0)
    }
    return(S)
}

// within transformation; alternating projections for >1 dimension
real matrix _csdlp_demean(real matrix M, struct _csdlp_fe scalar S)
{
    real matrix R, R0, Rs, mu, inf
    real colvector o, g, cnt
    real scalar k, it
    if (S.K == 0) {
        return(M)
    }
    if (cols(M) == 0) {
        return(M)
    }
    R = M
    for (it=1; it<=5000; it=it+1) {
        R0 = R
        for (k=1; k<=S.K; k=k+1) {
            o = *S.ord[k]
            g = *S.gi[k]
            inf = *S.info[k]
            Rs = R[o, .]
            cnt = inf[., 2] - inf[., 1] :+ 1
            mu = panelsum(Rs, inf) :/ cnt
            R[o, .] = Rs - mu[g, .]
        }
        if (S.K == 1) {
            break
        }
        if (max(abs(R - R0)) < 1e-11*(1 + max(abs(R)))) {
            break
        }
    }
    return(R)
}

// ---------------------------------------------------------------- OLS + HAC
// y, D1 (sieve block) and W are already within-transformed.
// V = M^-1 Omega M^-1 with M = sum P~P~' and Omega the Newey-West long-run
// variance of S_t = sum_i P~_it u_it -- identical to eq.(16) once the
// 1/(N(T-h)) and N^-1/2 normalisations of eqs.(13)-(16) are multiplied out.
void _csdlp_ols(real colvector y, real matrix D1, real matrix W,
                real colvector tix, real scalar Tr, real scalar L,
                real scalar wantV, real colvector b1, real matrix V,
                real scalar ssr, real scalar K)
{
    real matrix D, XX, XXi, Pt, M, Mi, Sp, S, Om, G
    real colvector bb, u, ord
    real matrix info
    real scalar p, k
    p = cols(D1)
    D = D1
    if (cols(W) > 0) {
        D = (D1, W)
    }
    XX  = quadcross(D, D)
    XXi = invsym(XX)
    bb  = XXi*quadcross(D, y)
    u   = y - D*bb
    ssr = quadcross(u, u)
    K   = sum(diag(XXi) :!= 0)
    b1  = bb[(1..p)]
    V   = J(p, p, .)
    if (!wantV) {
        return
    }
    Pt = D1
    if (cols(W) > 0) {
        Pt = D1 - W*(invsym(quadcross(W, W))*quadcross(W, D1))
    }
    M  = quadcross(Pt, Pt)
    Mi = invsym(M)
    ord  = order(tix, 1)
    info = panelsetup(tix[ord], 1)
    Sp = panelsum(Pt[ord, .] :* u[ord], info)
    S  = J(Tr, p, 0)
    S[tix[ord][info[., 1]], .] = Sp
    Om = quadcross(S, S)
    for (k=1; k<=L; k=k+1) {
        if (k < Tr) {
            G  = quadcross(S[|k+1,1 \ Tr,p|], S[|1,1 \ Tr-k,p|])
            Om = Om + (1 - k/(L+1))*(G + G')
        }
    }
    V = Mi*Om*Mi
    V = (V + V')/2
}

// ---------------------------------------------------------------- sup-t
// studentized Gaussian-multiplier critical values, eqs.(19)-(21)
// returns (c_lev1, c_lev2, p-value of sup|g/se| under H0: g=0 on the grid)
real rowvector _csdlp_supt(real matrix Pg, real matrix V, real colvector g,
                           real colvector se, real scalar reps,
                           real scalar lev1, real scalar lev2)
{
    real matrix Q, Vh, Gm
    real rowvector lam
    real colvector Tb, Ts, ok
    real scalar c1, c2, tmax, pv, m
    Q = .
    lam = .
    ok = (se :> 0) :& (se :< .)
    if (sum(ok) == 0) {
        return((., ., .))
    }
    symeigensystem(V, Q, lam)
    lam = lam :* (lam :> 0)
    Vh = Q*diag(sqrt(lam))*Q'
    Gm = (select(Pg, ok)*Vh)*rnormal(cols(Pg), reps, 0, 1)
    Gm = abs(Gm :/ select(se, ok))
    Tb = colmax(Gm)'
    Ts = sort(Tb, 1)
    m  = ceil(reps*lev1/100)
    if (m < 1) m = 1
    if (m > reps) m = reps
    c1 = Ts[m]
    c2 = .
    if (lev2 > 0) {
        m = ceil(reps*lev2/100)
        if (m < 1) m = 1
        if (m > reps) m = reps
        c2 = Ts[m]
    }
    tmax = max(abs(select(g, ok) :/ select(se, ok)))
    pv = mean(Tb :>= tmax)
    return((c1, c2, pv))
}

// ---------------------------------------------------------------- Wald
// H0: full B-spline coefficient vector lies in span(A)
real rowvector _csdlp_wald(real colvector bf, real matrix Vf, real matrix A)
{
    real matrix P, Q, R, RV
    real rowvector lam
    real colvector rb
    real scalar W, df
    Q = .
    lam = .
    P = I(rows(A)) - A*invsym(quadcross(A, A))*A'
    symeigensystem((P + P')/2, Q, lam)
    R = select(Q, lam :> 0.5)'
    if (rows(R) == 0) {
        return((., 0, .))
    }
    rb = R*bf
    RV = R*Vf*R'
    W  = rb'*invsym(RV)*rb
    df = rank(RV)
    if (df == 0) {
        return((., 0, .))
    }
    return((W, df, chi2tail(df, W)))
}

// ---------------------------------------------------------------- main
void csdlp_horizon(real scalar h, string scalar yv, string scalar xv,
                   string scalar zv, string scalar wv, string scalar xfv,
                   string scalar fev, string scalar iv, string scalar tv,
                   string scalar touse, real scalar tmin, real scalar tdelta,
                   real rowvector Jlist, string scalar crit, string scalar vce,
                   real scalar lagfix, real scalar normopt, real scalar addcons,
                   string scalar gridmat, real scalar reps, real scalar lev1,
                   real scalar lev2, real rowvector qprobs, real scalar scale)
{
    real colvector y, X, Z, tt, tix, yd, Xd, zg, inside, g, se, b, b1, bL
    real colvector gL, seL, gi, X2, om, gp, zq, gq, seq, pq, gLq, seLq, pLq
    real colvector bf, zp, zm, tg
    real matrix W, Xf, F, Wd, Phi, PhiL, D1, WJ, ext, V, V1, VL, ic, Pg, PgL
    real matrix irf, out, Pq, PqL, E
    real rowvector kn, cen, crv, crvL, wnl, wsd, sumrow
    real scalar n, Tr, Tdist, Nu, norm, lo, hi, L, nJ, r, ssr, K, j, rs
    real scalar nb, G, zbar, k, slope, blin, seblin, pblin, mu, Dz, bproj
    real scalar zc, eps, aicmin, nbsel, m
    struct _csdlp_fe scalar FE

    y  = st_data(., yv, touse)
    X  = st_data(., xv, touse)
    Z  = st_data(., zv, touse)
    n  = rows(y)
    W  = J(n, 0, .)
    if (wv != "") {
        W = st_data(., tokens(wv), touse)
    }
    if (addcons) {
        W = (W, J(n, 1, 1))
    }
    Xf = J(n, 0, .)
    if (xfv != "") {
        Xf = st_data(., tokens(xfv), touse)
    }
    F = J(n, 0, .)
    if (fev != "") {
        F = st_data(., tokens(fev), touse)
    }
    tt  = st_data(., tv, touse)
    tix = round((tt :- tmin) / tdelta) :+ 1
    Tr  = max(tix)
    Tdist = rows(uniqrows(tix))
    Nu = 1
    if (iv != "") {
        Nu = rows(uniqrows(st_data(., iv, touse)))
    }

    FE = _csdlp_fesetup(F)
    yd = _csdlp_demean(y, FE)
    Wd = _csdlp_demean(W, FE)

    // normalisation: automatic when the FE absorb X_t itself
    norm = normopt
    if (norm < 0) {
        norm = 0
        if (FE.K > 0) {
            Xd = _csdlp_demean(X, FE)
            if (sqrt(quadcross(Xd, Xd)) < 1e-6*sqrt(quadcross(X, X))) {
                norm = 1
            }
        }
    }

    lo = min(Z)
    hi = max(Z)

    // HAC truncation lag
    L = floor(4*(Tdist/100)^(2/9))
    if (vce == "cluster") {
        L = 0
    }
    if (vce == "hlag") {
        L = h
    }
    if (vce == "nwfix") {
        L = lagfix
    }

    // ---------------- sieve-dimension selection (Algorithm 1, steps 2-4)
    nJ = cols(Jlist)
    ic = J(nJ, 6, .)
    for (r=1; r<=nJ; r=r+1) {
        kn  = _csdlp_knots(Z, Jlist[r], lo, hi)
        Phi = _csdlp_bs(Z, kn)
        nb  = cols(Phi)
        cen = J(1, nb, 0)
        if (norm) {
            cen = mean(Phi)
        }
        Phi = _csdlp_phi(Z, kn, norm, cen)
        D1  = _csdlp_demean(X :* Phi, FE)
        WJ  = Wd
        if (cols(Xf) > 0) {
            ext = J(n, 0, .)
            for (j=1; j<=cols(Xf); j=j+1) {
                ext = (ext, Phi :* Xf[., j])
            }
            WJ = (Wd, _csdlp_demean(ext, FE))
        }
        b1 = .
        V1 = .
        ssr = .
        K = .
        _csdlp_ols(yd, D1, WJ, tix, Tr, L, 0, b1, V1, ssr, K)
        ic[r, 1] = Jlist[r]
        ic[r, 2] = nb
        ic[r, 3] = n*ln(ssr/n) + 2*K
        ic[r, 4] = n*ln(ssr/n) + K*ln(n)
        ic[r, 5] = (ssr/n)/((1 - K/n)^2)
        ic[r, 6] = K
    }
    rs = 1
    if (crit == "aic") {
        rs = _csdlp_argmin(ic[., 3])
    }
    if (crit == "bic") {
        rs = _csdlp_argmin(ic[., 4])
    }
    if (crit == "gcv") {
        rs = _csdlp_argmin(ic[., 5])
    }
    aicmin = ic[rs, 3]

    // ---------------- final sieve fit (Algorithm 1, step 5) + HAC variance
    kn  = _csdlp_knots(Z, Jlist[rs], lo, hi)
    Phi = _csdlp_bs(Z, kn)
    nb  = cols(Phi)
    nbsel = nb
    cen = J(1, nb, 0)
    if (norm) {
        cen = mean(Phi)
    }
    Phi = _csdlp_phi(Z, kn, norm, cen)
    D1  = _csdlp_demean(X :* Phi, FE)
    WJ  = Wd
    if (cols(Xf) > 0) {
        ext = J(n, 0, .)
        for (j=1; j<=cols(Xf); j=j+1) {
            ext = (ext, Phi :* Xf[., j])
        }
        WJ = (Wd, _csdlp_demean(ext, FE))
    }
    b = .
    V = .
    _csdlp_ols(yd, D1, WJ, tix, Tr, L, 1, b, V, ssr, K)

    // ---------------- linear-interaction benchmark, eq.(2b)
    zbar = mean(Z)
    PhiL = _csdlp_philin(Z, norm, zbar)
    D1 = _csdlp_demean(X :* PhiL, FE)
    WJ = Wd
    if (cols(Xf) > 0) {
        ext = J(n, 0, .)
        for (j=1; j<=cols(Xf); j=j+1) {
            ext = (ext, PhiL :* Xf[., j])
        }
        WJ = (Wd, _csdlp_demean(ext, FE))
    }
    bL = .
    VL = .
    _csdlp_ols(yd, D1, WJ, tix, Tr, L, 1, bL, VL, ssr, K)
    slope = 2
    if (norm) {
        slope = 1
    }
    blin   = bL[slope]
    seblin = sqrt(VL[slope, slope])
    pblin  = 2*normal(-abs(blin/seblin))

    // ---------------- grid: pointwise (17)-(18) and uniform (19)-(21)
    zg = st_matrix(gridmat)'
    if (cols(zg) > 1) {
        zg = zg'
    }
    G = rows(zg)
    inside = (zg :>= lo) :& (zg :<= hi)
    Pg  = _csdlp_phi(zg, kn, norm, cen)
    g   = Pg*b
    se  = sqrt(rowsum((Pg*V) :* Pg))
    PgL = _csdlp_philin(zg, norm, zbar)
    gL  = PgL*bL
    seL = sqrt(rowsum((PgL*VL) :* PgL))
    se  = se :/ inside
    seL = seL :/ inside
    crv  = _csdlp_supt(Pg, V, g, se, reps, lev1, lev2)
    crvL = _csdlp_supt(PgL, VL, gL, seL, reps, lev1, lev2)

    // derivative of g on the grid (for Lemma 1 / Prop. 2 display)
    eps = (hi - lo)*1e-4
    zp = rowmin((zg :+ eps, J(G,1,hi)))
    zm = rowmax((zg :- eps, J(G,1,lo)))
    gp = (_csdlp_phi(zp, kn, norm, cen)*b - _csdlp_phi(zm, kn, norm, cen)*b) :/ (zp - zm)

    // Lemma 1: beta_proj = E[X^2 (Z-mu) g(Z)] / E[X^2 (Z-mu)^2], omega_h(z)
    gi = Phi*b
    X2 = X:^2
    mu = sum(X2 :* Z)/sum(X2)
    Dz = sum(X2 :* (Z :- mu):^2)
    bproj = sum(X2 :* (Z :- mu) :* gi)/Dz
    om = J(G, 1, .)
    for (k=1; k<=G; k=k+1) {
        om[k] = sum(X2 :* (Z :- mu) :* (Z :>= zg[k]))/Dz
    }

    zc = invnormal(1 - (1 - lev1/100)/2)
    irf = J(G, 18, .)
    irf[., 1]  = J(G, 1, h)
    irf[., 2]  = zg
    irf[., 3]  = g*scale
    irf[., 4]  = se*abs(scale)
    irf[., 5]  = (g - zc*se)*scale
    irf[., 6]  = (g + zc*se)*scale
    irf[., 7]  = (g - crv[1]*se)*scale
    irf[., 8]  = (g + crv[1]*se)*scale
    if (lev2 > 0) {
        irf[., 9]  = (g - crv[2]*se)*scale
        irf[., 10] = (g + crv[2]*se)*scale
    }
    irf[., 11] = gL*scale
    irf[., 12] = seL*abs(scale)
    irf[., 13] = (gL - zc*seL)*scale
    irf[., 14] = (gL + zc*seL)*scale
    irf[., 15] = (gL - crvL[1]*seL)*scale
    irf[., 16] = (gL + crvL[1]*seL)*scale
    irf[., 17] = gp*scale
    irf[., 18] = om
    for (k=1; k<=G; k=k+1) {
        if (!inside[k]) {
            irf[k, (3..17)] = J(1, 15, .)
        }
    }
    // bands keep orientation when scale<0
    if (scale < 0) {
        irf[., (5,6,7,8,9,10,13,14,15,16)] = irf[., (6,5,8,7,10,9,14,13,16,15)]
    }

    // ---------------- auxiliary Wald tests (conditional on selected J)
    tg = J(nb, 1, .)
    for (j=1; j<=nb; j=j+1) {
        tg[j] = (kn[j+1] + kn[j+2] + kn[j+3])/3
    }
    E = I(nb)
    if (norm) {
        E = (J(1, nb-1, 0) \ I(nb-1))
    }
    bf = E*b
    wnl = _csdlp_wald(bf, E*V*E', (J(nb,1,1), tg))
    wsd = _csdlp_wald(bf, E*V*E', J(nb,1,1))

    // ---------------- quantile table
    zq  = _csdlp_quant(Z, qprobs'/100)
    Pq  = _csdlp_phi(zq, kn, norm, cen)
    gq  = Pq*b
    seq = sqrt(rowsum((Pq*V) :* Pq))
    pq  = 2*normal(-abs(gq :/ seq))
    PqL = _csdlp_philin(zq, norm, zbar)
    gLq = PqL*bL
    seLq = sqrt(rowsum((PqL*VL) :* PqL))
    pLq = 2*normal(-abs(gLq :/ seLq))
    m = rows(zq)
    out = (J(m,1,h), qprobs', zq, gq*scale, seq*abs(scale), pq, gLq*scale, seLq*abs(scale), pLq)

    sumrow = (h, n, Nu, Tdist, nbsel, L, crv[1], crv[2], blin*scale,
              seblin*abs(scale), pblin, bproj*scale, wnl[1], wnl[2], wnl[3],
              wsd[1], wsd[2], wsd[3], max(abs(select(g, inside) :/ select(se, inside))),
              crv[3], aicmin, norm)

    st_matrix("__csdlp_irf", irf)
    st_matrix("__csdlp_sum", sumrow)
    st_matrix("__csdlp_q", out)
    st_matrix("__csdlp_b", b')
    st_matrix("__csdlp_V", V)
    st_matrix("__csdlp_kn", kn)
    st_matrix("__csdlp_cen", cen)
    st_matrix("__csdlp_bl", bL')
    st_matrix("__csdlp_Vl", VL)
    st_matrix("__csdlp_ic", ic)
    st_numscalar("__csdlp_zbar", zbar)
    st_numscalar("__csdlp_norm", norm)
}

real scalar _csdlp_argmin(real colvector v)
{
    real scalar i, k, best
    k = 1
    best = v[1]
    for (i=2; i<=rows(v); i=i+1) {
        if (v[i] < best) {
            best = v[i]
            k = i
        }
    }
    return(k)
}

// ---------------------------------------------------------------- lasso prep
// writes within-transformed y, W and X*phi_Jlasso(Z) into existing Stata vars
void csdlp_lassoprep(string scalar yv, string scalar xv, string scalar zv,
                     string scalar wv, string scalar fev, string scalar touse,
                     real scalar Jl, real scalar addcons, string scalar outy,
                     string scalar outw, string scalar outp)
{
    real colvector y, X, Z
    real matrix W, F, Phi
    real rowvector kn, cen
    real scalar n, nb, norm
    struct _csdlp_fe scalar FE
    y = st_data(., yv, touse)
    X = st_data(., xv, touse)
    Z = st_data(., zv, touse)
    n = rows(y)
    W = J(n, 0, .)
    if (wv != "") {
        W = st_data(., tokens(wv), touse)
    }
    F = J(n, 0, .)
    if (fev != "") {
        F = st_data(., tokens(fev), touse)
    }
    FE = _csdlp_fesetup(F)
    kn = _csdlp_knots(Z, Jl, min(Z), max(Z))
    Phi = _csdlp_bs(Z, kn)
    nb = cols(Phi)
    st_store(., outy, touse, _csdlp_demean(y, FE))
    if (wv != "") {
        st_store(., tokens(outw), touse, _csdlp_demean(W, FE))
    }
    st_store(., tokens(outp)[(1..nb)], touse, _csdlp_demean(X :* Phi, FE))
    st_numscalar("__csdlp_nbl", nb)
}

// ---------------------------------------------------------------- postest
// evaluate stored sieve / linear fits at arbitrary z: returns (g, se) etc.
real matrix csdlp_evalphi(real colvector z, real rowvector kn, real scalar norm,
                          real rowvector cen)
{
    return(_csdlp_phi(z, kn, norm, cen))
}

real matrix csdlp_evallin(real colvector z, real scalar norm, real scalar zbar)
{
    return(_csdlp_philin(z, norm, zbar))
}

// ---------------------------------------------------------------- postest
real scalar _csdlp_isnorm(real rowvector b, real rowvector kn)
{
    return(cols(b) < cols(kn) - 4)
}

// (d_sieve, se_sieve, d_linear, se_linear) for g_h(za) - g_h(zb)
real rowvector _csdlp_lcdiff(real scalar za, real scalar zb, real scalar h,
                             real scalar scale)
{
    string scalar hs
    real colvector b, bl
    real matrix V, Vl
    real rowvector kn, cen, a, al
    real scalar zbar, norm, d, s, dl, sl
    hs = strofreal(h)
    b   = st_matrix("e(b_h" + hs + ")")'
    V   = st_matrix("e(V_h" + hs + ")")
    kn  = st_matrix("e(kn_h" + hs + ")")
    cen = st_matrix("e(cen_h" + hs + ")")
    bl  = st_matrix("e(bl_h" + hs + ")")'
    Vl  = st_matrix("e(Vl_h" + hs + ")")
    zbar = st_numscalar("e(zbar_h" + hs + ")")
    norm = _csdlp_isnorm(b', kn)
    if (missing(za) | missing(zb)) {
        errprintf("z_a or z_b is missing\n")
        exit(498)
    }
    if (za < kn[1] | za > kn[cols(kn)] | zb < kn[1] | zb > kn[cols(kn)]) {
        printf("{txt}(note: a z value lies outside the h=%g support; evaluated at the boundary)\n", h)
    }
    a  = _csdlp_phi(za, kn, norm, cen) - _csdlp_phi(zb, kn, norm, cen)
    al = _csdlp_philin(za, norm, zbar) - _csdlp_philin(zb, norm, zbar)
    d  = a*b
    s  = sqrt(a*V*a')
    dl = al*bl
    sl = sqrt(al*Vl*al')
    return((d*scale, s*abs(scale), dl*scale, sl*abs(scale)))
}

// capital-share-weighted aggregate responsiveness by period (Sec. 6.2)
void _csdlp_aggm(string scalar zv, string scalar kv, string scalar tv,
                 string scalar touse, real scalar h, real scalar scale,
                 real scalar lev)
{
    string scalar hs
    real colvector Z, Kw, tt, ord, b, bl, sh, A, S, AL, SL, tu, tot, gidx
    real matrix V, Vl, P, PL, info, At, ALt
    real rowvector kn, cen, abar, albar
    real scalar zbar, norm, T, k, zc
    hs = strofreal(h)
    b   = st_matrix("e(b_h" + hs + ")")'
    V   = st_matrix("e(V_h" + hs + ")")
    kn  = st_matrix("e(kn_h" + hs + ")")
    cen = st_matrix("e(cen_h" + hs + ")")
    bl  = st_matrix("e(bl_h" + hs + ")")'
    Vl  = st_matrix("e(Vl_h" + hs + ")")
    zbar = st_numscalar("e(zbar_h" + hs + ")")
    norm = _csdlp_isnorm(b', kn)
    Z  = st_data(., zv, touse)
    Kw = st_data(., kv, touse)
    tt = st_data(., tv, touse)
    ord = order(tt, 1)
    Z = Z[ord]
    Kw = Kw[ord]
    tt = tt[ord]
    info = panelsetup(tt, 1)
    T = rows(info)
    tot  = panelsum(Kw, info)
    gidx = runningsum(_csdlp_starts(info, rows(tt)))
    sh   = Kw :/ tot[gidx]
    P  = _csdlp_phi(Z, kn, norm, cen) :* sh
    PL = _csdlp_philin(Z, norm, zbar) :* sh
    At  = panelsum(P, info)
    ALt = panelsum(PL, info)
    A  = At*b
    AL = ALt*bl
    S  = sqrt(rowsum((At*V) :* At))
    SL = sqrt(rowsum((ALt*Vl) :* ALt))
    zc = invnormal(1 - (1 - lev/100)/2)
    tu = tt[info[., 1]]
    st_matrix("__csdlp_agg", (tu, A*scale, S*abs(scale), (A - zc*S)*scale,
        (A + zc*S)*scale, AL*scale, SL*abs(scale), (AL - zc*SL)*scale,
        (AL + zc*SL)*scale))
    abar  = mean(At)
    albar = mean(ALt)
    st_numscalar("__csdlp_m1", abar*b*scale)
    st_numscalar("__csdlp_m2", sqrt(abar*V*abar')*abs(scale))
    st_numscalar("__csdlp_m3", albar*bl*scale)
    st_numscalar("__csdlp_m4", sqrt(albar*Vl*albar')*abs(scale))
}

// indicator of the first row of each panel (used to expand group sums)
real colvector _csdlp_starts(real matrix info, real scalar n)
{
    real colvector s
    s = J(n, 1, 0)
    s[info[., 1]] = J(rows(info), 1, 1)
    return(s)
}

end
