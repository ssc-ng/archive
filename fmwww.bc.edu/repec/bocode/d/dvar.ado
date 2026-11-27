*! dvar 1.0.0  26nov2026
*! Distributional Vector Autoregression and distributional impulse responses
*! Wang, Oka & Zhu (2025, Journal of Applied Econometrics) -- DR + factorisation
*! Adrian, Boyarchenko & Giannone (2021, International Economic Review) -- kernel
*! Author : Dr Merwan Roudane  (merwanroudane920@gmail.com)
*! GitHub : https://github.com/merwanroudane
*
* Step -> paper map (full map in -help dvar_methods-)
*   _dvar_prep / dvar_lpdata ...... Sec. 2.1, X_jt = (1, Z_t', Y_1t..Y_j-1,t)'; VariablesT.m
*   dvar_grid ...................... thresholds = 99 empirical percentiles (replication code)
*   dvar_fitstd .................... eq. (2), (6): binary DR, logit/probit, optional elastic net
*   dvar_fitsys .................... eq. (1), (8): J conditional marginals of the factorisation
*   dvar_cdfrow .................... eq. (7) + rearrangement (Chernozhukov et al. 2009)
*   dvar_draw ...................... Appendix B.1, Algorithm 1 (sequential inverse-CDF draws)
*   dvar_sandwich .................. Theorem 1: H^-1 Sigma H^-1 with long-run Sigma
*   dvar irf ....................... Sec. 2.2, eqs. (3)-(5): DIR_h, DIR_jh, QIRF, MIRF
*   dvar_mbb ....................... Appendix B.5: moving block bootstrap (Kunsch 1989)
*   dvar forecast .................. Sec. 4.2: PIT (Rossi-Sekhposyan 2019), QS, CRPS, log score
*   dvar kernel .................... Adrian et al. (2021) eqs. (1)-(4), Algorithms 1 and 3

program define dvar
    version 16.0
    gettoken sub 0 : 0, parse(" ,")
    if ("`sub'"=="") {
        di as err "syntax: dvar {fit|joint|irf|forecast|kernel|palette} ..."
        exit 198
    }
    if ("`sub'"=="fit" | "`sub'"=="est" | "`sub'"=="estimate") {
        dvar_fit `0'
    }
    else if ("`sub'"=="joint") {
        dvar_joint `0'
    }
    else if ("`sub'"=="irf" | "`sub'"=="dirf") {
        dvar_irf `0'
    }
    else if ("`sub'"=="forecast" | "`sub'"=="fcast" | "`sub'"=="oos") {
        dvar_forecast `0'
    }
    else if ("`sub'"=="kernel" | "`sub'"=="abg") {
        dvar_kernel `0'
    }
    else if ("`sub'"=="palette" | "`sub'"=="colors" | "`sub'"=="colours") {
        dvar_palette `0'
    }
    else {
        di as err "unknown subcommand {bf:`sub'}"
        di as err "valid subcommands: fit, joint, irf, forecast, kernel, palette"
        exit 198
    }
end

*==============================================================================
* shared helpers
*==============================================================================
program define _dvar_prep, rclass
    syntax varlist(numeric), touse(name)
    capture tsset
    if _rc {
        di as err "data must be {bf:tsset} (time series)"
        exit 111
    }
    qui tsset
    if ("`r(panelvar)'"!="") {
        di as err "{bf:dvar} is for a single time series; panel data are not supported"
        exit 459
    }
    local tvar  "`r(timevar)'"
    local unit  "`r(unit1)'"
    local fmt   "`r(tsfmt)'"
    local delta = r(tdelta)
    qui count if `touse'
    local N = r(N)
    if (`N' < 30) {
        di as err "at least 30 complete observations are required (found `N')"
        exit 2001
    }
    qui su `tvar' if `touse', meanonly
    if ((r(max)-r(min))/`delta' + 1 != `N') {
        di as err "the estimation sample must be a contiguous block of periods"
        di as err "with no missing values in {bf:`varlist'}"
        exit 459
    }
    return local tvar "`tvar'"
    return local unit "`unit'"
    return local fmt  "`fmt'"
    return scalar delta = `delta'
    return scalar tmin  = r(min)
    return scalar tmax  = r(max)
    return scalar N     = `N'
end

program define _dvar_pos, rclass
    args str unit tmin delta N
    capture confirm number `str'
    if (_rc==0) {
        local t = `str'
    }
    else {
        if inlist("`unit'", "y", "g", ".", "") {
            capture local t = `str'
        }
        else {
            capture local t = t`unit'(`str')
        }
        if (_rc | "`t'"=="" | "`t'"==".") {
            di as err "cannot interpret date {bf:`str'}"
            exit 198
        }
    }
    local pos = (`t' - `tmin')/`delta' + 1
    if (`pos' < 1 | `pos' > `N' | `pos' != int(`pos')) {
        di as err "date {bf:`str'} is outside the estimation sample"
        exit 498
    }
    return scalar t   = `t'
    return scalar pos = `pos'
end

program define _dvar_link, rclass
    args link
    local link = lower("`link'")
    if ("`link'"=="" | "`link'"=="logit" | "`link'"=="logistic") {
        return scalar n = 1
        return local name "logit"
    }
    else if ("`link'"=="probit" | "`link'"=="normal") {
        return scalar n = 2
        return local name "probit"
    }
    else {
        di as err "link() must be logit or probit"
        exit 198
    }
end

program define _dvar_cf, rclass
    gettoken dist rest : 0
    local dist = lower("`dist'")
    if ("`dist'"=="truncnormal" | "`dist'"=="tnorm") local dist "tnormal"
    if ("`dist'"=="truncgamma") local dist "tgamma"
    if ("`dist'"=="mass" | "`dist'"=="dirac") local dist "point"
    local np : word count `rest'
    local need = .
    if inlist("`dist'", "normal", "gamma", "uniform") local need = 2
    if inlist("`dist'", "tnormal", "tgamma") local need = 4
    if inlist("`dist'", "point", "shift", "scale") local need = 1
    if (`need'==.) {
        di as err "cf(): unknown distribution {bf:`dist'}"
        di as err "use normal, tnormal, gamma, tgamma, uniform, point, shift or scale"
        exit 198
    }
    if (`np' != `need') {
        di as err "cf(`dist' ...) needs `need' number(s)"
        exit 198
    }
    foreach x of local rest {
        confirm number `x'
    }
    if inlist("`dist'", "normal", "tnormal") {
        if (`: word 2 of `rest'' <= 0) {
            di as err "cf(): the standard deviation must be positive"
            exit 198
        }
    }
    if inlist("`dist'", "gamma", "tgamma") {
        if (`: word 1 of `rest'' <= 0 | `: word 2 of `rest'' <= 0) {
            di as err "cf(): gamma shape and scale must be positive"
            exit 198
        }
    }
    return local dist "`dist'"
    return local par  "`rest'"
end

program define _dvar_colors, rclass
    args name n
    if ("`name'"=="") local name "parula"
    local nm = lower("`name'")
    if !inlist("`nm'", "parula", "jet", "turbo", "bluered", "blue_red", "sinha", "viridis", "gray", "grey") {
        di as err "colorscale() must be parula, jet, turbo, bluered, sinha, viridis or gray"
        exit 198
    }
    mata: st_local("cl", dvar_palette("`nm'", `n'))
    return local colors `"`cl'"'
end

program define _dvar_stars, rclass
    args b se
    local st ""
    if (`se' < . & `se' > 0) {
        local p = 2*normal(-abs(`b'/`se'))
        if (`p' < 0.10) local st "*"
        if (`p' < 0.05) local st "**"
        if (`p' < 0.01) local st "***"
    }
    return local s "`st'"
end

* filled contour of a long (x, y, f) matrix with the QQR palettes
program define _dvar_contour
    syntax , MATrix(name) COLors(string asis) LEVels(integer) NAME(string) ///
        [ XTitle(string) YTitle(string) TItle(string) HEATmap MARK(numlist) LEGend ]
    preserve
    qui clear
    qui svmat double `matrix', name(cz)
    local mk ""
    if ("`mark'"!="") {
        local mx : word 1 of `mark'
        local my : word 2 of `mark'
        if (`mx' < . & `my' < .) {
            qui gen double cmx = `mx' in 1
            qui gen double cmy = `my' in 1
            local mk "(scatter cmy cmx, msymbol(S) mcolor(red) msize(small))"
        }
    }
    local cl "clegend(off)"
    if ("`legend'"!="") local cl "clegend(on)"
    twoway (contour cz3 cz2 cz1, levels(`levels') ccolors(`colors') `heatmap' `cl') `mk', ///
        xtitle("`xtitle'") ytitle("`ytitle'") title("`title'", size(medsmall)) ///
        legend(off) graphregion(color(white)) plotregion(margin(zero)) aspect(1) ///
        name(`name', replace) nodraw
    restore
end

* distributional IRF table (rows: statistic x {Base, Diff}, cols: h = 0..H)
program define _dvar_irftab
    syntax , TAB(name) VARiable(string) Q(numlist) [ LO(name) HI(name) Level(real 95) ]
    local nq : word count `q'
    local H = colsof(`tab') - 1
    local w = 16 + 9*(`H'+1)
    di
    di as text "{bf:`variable'}"
    di as text "{hline `w'}"
    di as text %-16s "  horizon h" _c
    forvalues h = 0/`H' {
        di as text %9s "`h'" _c
    }
    di
    di as text "{hline `w'}"
    di as text "  Quantiles"
    local rn ""
    forvalues c = 1/`=`nq'+4' {
        if (`c' <= `nq') {
            local lab : word `c' of `q'
            local lab : di %4.2f `lab'
        }
        if (`c'==`nq'+1) {
            di as text "  Moments"
            local lab "Mean"
        }
        if (`c'==`nq'+2) local lab "Std"
        if (`c'==`nq'+3) local lab "Skewness"
        if (`c'==`nq'+4) local lab "Kurtosis"
        di as text %-11s "  `lab'" %-5s "Base" _c
        forvalues h = 0/`H' {
            di as result %9.2f `tab'[2*`c'-1, `h'+1] _c
        }
        di
        di as text %-11s "" %-5s "Diff" _c
        forvalues h = 0/`H' {
            local v = `tab'[2*`c', `h'+1]
            local mk " "
            if ("`lo'"!="") {
                if (`lo'[`c', `h'+1] > 0 | `hi'[`c', `h'+1] < 0) local mk "*"
            }
            di as result %8.2f `v' as text "`mk'" _c
        }
        di
    }
    di as text "{hline `w'}"
end

*==============================================================================
* dvar fit : in-sample distribution regression system
*==============================================================================
program define dvar_fit, eclass
    syntax varlist(numeric min=1) [if] [in] [, Lags(integer 3) Horizon(integer 1) ///
        GRID(integer 99) LAMbda(real 0.0005) ALPha(real 0.2) LINK(string)          ///
        TAUs(numlist >0 <1 sort) HAC(integer -1) Level(cilevel) INSample          ///
        DRAWs(integer 2000) SEED(string) GENerate(name) noGRaph noTABle          ///
        NAME(string) PLOTrange(numlist min=2 max=2 >0 <1) ]
    marksample touse
    _dvar_prep `varlist', touse(`touse')
    local tvar "`r(tvar)'"
    local fmt  "`r(fmt)'"
    local Nobs = r(N)
    local tmin = r(tmin)
    local delta = r(delta)
    _dvar_link "`link'"
    local linkn = r(n)
    local linkname "`r(name)'"
    if (`lags' < 1 | `horizon' < 1) {
        di as err "lags() and horizon() must be positive integers"
        exit 198
    }
    if (`grid' < 9) {
        di as err "grid() must be at least 9"
        exit 198
    }
    if (`lambda' < 0 | `alpha' < 0 | `alpha' > 1) {
        di as err "lambda() must be >= 0 and alpha() must lie in [0,1]"
        exit 198
    }
    if ("`taus'"=="") local taus "0.1 0.25 0.5 0.75 0.9"
    if ("`plotrange'"=="") local plotrange "0.05 0.95"
    if ("`name'"=="") local name "dvar"
    local ins = ("`insample'"!="" | "`generate'"!="")
    if ("`seed'"!="") set seed `seed'
    local J : word count `varlist'
    if (`Nobs' - `lags' - `horizon' + 1 < 3*(1 + `lags'*`J' + `J')) {
        di as err "too few observations for `lags' lags of `J' variables"
        exit 2001
    }
    sort `tvar'
    mata: dvar_fit_main()
    local n = __dv_n
    local hac = __dv_hac
    local dz = 1 + `lags'*`J'
    * ---------------------------------------------------------- names
    local zn "_cons"
    forvalues i = 1/`lags' {
        local L = `lags' - `i' + `horizon'
        foreach v of local varlist {
            local zn `zn' L`L'.`v'
        }
    }
    local zlist "`zn'"
    local j = 0
    foreach v of local varlist {
        local ++j
        local rn`j' "`zlist'"
        if (`j' > 1) {
            forvalues k = 1/`=`j'-1' {
                local rn`j' `rn`j'' `: word `k' of `varlist''
            }
        }
        matrix rownames __dv_b`j' = `rn`j''
        matrix rownames __dv_se`j' = `rn`j''
        matrix rownames __dv_tb`j' = `rn`j''
        matrix rownames __dv_ts`j' = `rn`j''
        local cn ""
        foreach t of local taus {
            local cn `cn' tau=`t'
        }
        matrix colnames __dv_tb`j' = `cn'
        matrix colnames __dv_ts`j' = `cn'
    }
    matrix colnames __dv_G = `varlist'
    matrix colnames __dv_fst = pseudoR2 KS_PIT d
    matrix rownames __dv_fst = `varlist'
    * ---------------------------------------------------------- table
    qui su `tvar' if `touse', meanonly
    local t0 : di `fmt' r(min) + (`lags'+`horizon'-1)*`delta'
    local t1 : di `fmt' r(max)
    if ("`table'"=="") {
        di
        di as text "{bf:Distributional Vector Autoregression}  (Wang, Oka & Zhu 2025)"
        di as text "{hline 78}"
        di as text "Outcomes (ordering)" _col(26) ": " as result "`varlist'"
        di as text "Sample (outcome dates)" _col(26) ": " as result "`t0' - `t1'" ///
            as text "   T = " as result `n'
        di as text "Lags / horizon" _col(26) ": " as result "`lags'" as text " / " as result "`horizon'"
        di as text "Thresholds per equation" _col(26) ": " as result "`grid'" ///
            as text " (empirical percentiles)"
        di as text "Link" _col(26) ": " as result "`linkname'" ///
            as text "    elastic net: lambda = " as result `lambda' as text ", alpha = " as result `alpha'
        di as text "Std. errors" _col(26) ": " as result "sandwich H^-1 Sigma H^-1" ///
            as text ", Bartlett HAC lags = " as result `hac'
        local nt : word count `taus'
        local w = 16 + 11*`nt'
        local j = 0
        foreach v of local varlist {
            local ++j
            local cond = cond(`j'==1, "Z_t", "Z_t, `: word 1 of `varlist''")
            if (`j' > 2) {
                local cond "Z_t, `: word 1 of `varlist''..`: word `=`j'-1' of `varlist''"
            }
            di
            di as text "Equation `j': F(" as result "`v'" as text " <= y | `cond')   " ///
                "coefficients theta_j(y) at y = Q_tau(`v')"
            di as text "{hline `w'}"
            di as text %-16s "  regressor" _c
            foreach t of local taus {
                di as text %11s "tau=`t'" _c
            }
            di
            di as text "{hline `w'}"
            local d = rowsof(__dv_tb`j')
            forvalues r = 1/`d' {
                local lab : word `r' of `rn`j''
                di as text %-16s abbrev("  `lab'", 16) _c
                forvalues c = 1/`nt' {
                    local b  = __dv_tb`j'[`r', `c']
                    local se = __dv_ts`j'[`r', `c']
                    _dvar_stars `b' `se'
                    di as result %8.3f `b' as text %-3s "`r(s)'" _c
                }
                di
                di as text %-16s "" _c
                forvalues c = 1/`nt' {
                    local se = __dv_ts`j'[`r', `c']
                    if (`se' < .) {
                        local ss : di %6.3f `se'
                        di as text %11s "(`=strtrim("`ss'")')" _c
                    }
                    else {
                        di as text %11s "(.)" _c
                    }
                }
                di
            }
            di as text "{hline `w'}"
            local ksd = cond(__dv_fst[`j',2] > 1.34, "reject", "pass")
            di as text "  pseudo-R2 (avg) = " as result %5.3f __dv_fst[`j',1] ///
                as text "   KS(PIT) = " as result %5.3f __dv_fst[`j',2] as text " [`ksd']"
        }
        di as text "{hline 78}"
        di as text "*** p<0.01, ** p<0.05, * p<0.10. Standard errors in parentheses (Theorem 1)."
        di as text "KS(PIT): in-sample Rosenblatt PITs of the factorised conditionals,"
        di as text "sqrt(T) sup|F_T(r) - r|; 5% critical value 1.34 (Rossi & Sekhposyan 2019)."
    }
    * ---------------------------------------------------------- graphs
    local plo : word 1 of `plotrange'
    local phi : word 2 of `plotrange'
    if ("`graph'"=="") {
        local z = invnormal(1 - (100-`level')/200)
        local j = 0
        foreach v of local varlist {
            local ++j
            local d = rowsof(__dv_b`j')
            local rows ""
            forvalues k = 1/`J' {
                local rows `rows' `=1 + (`lags'-1)*`J' + `k''
            }
            if (`j' > 1) {
                forvalues k = `=`dz'+1'/`d' {
                    local rows `rows' `k'
                }
            }
            matrix __dv_pb = (__dv_G[1..., `j'], __dv_b`j'', __dv_se`j'')
            local gl ""
            preserve
            qui clear
            qui svmat double __dv_pb, name(pb)
            qui gen double lev = _n/(`grid'+1)
            qui keep if lev >= `plo' & lev <= `phi'
            foreach r of local rows {
                local lab : word `r' of `rn`j''
                local cb = 1 + `r'
                local cs = 1 + `d' + `r'
                qui gen double lo`r' = pb`cb' - `z'*pb`cs'
                qui gen double hi`r' = pb`cb' + `z'*pb`cs'
                twoway (rarea lo`r' hi`r' lev, color("62 38 168%25") lwidth(none)) ///
                    (line pb`cb' lev, lcolor("62 38 168") lwidth(medthick)),  ///
                    yline(0, lcolor(gs8) lpattern(dash)) legend(off)         ///
                    title("`lab'", size(medsmall)) xtitle("quantile level of threshold") ///
                    ytitle("") graphregion(color(white)) name(__dvc`r', replace) nodraw
                local gl `gl' __dvc`r'
            }
            restore
            graph combine `gl', title("{bf:DR coefficient process: `v'}", size(medium)) ///
                note("Band: `level'% pointwise CI (sandwich, Theorem 1).") ///
                graphregion(color(white)) name(`name'_coef_`j', replace)
            graph drop `gl'
        }
    }
    * ---------------------------------------------------------- in-sample
    if (`ins') {
        matrix __dv_ins = __dv_ins
        local cn "time"
        foreach v of local varlist {
            local cn `cn' mean_`v' q05_`v' q25_`v' q50_`v' q75_`v' q95_`v'
        }
        forvalues a = 1/`=`J'-1' {
            forvalues b = `=`a'+1'/`J' {
                local cn `cn' corr_`a'_`b'
            }
        }
        matrix colnames __dv_ins = `cn'
        if ("`generate'"!="") {
            local ncol = colsof(__dv_ins)
            mata: __M = st_matrix("__dv_ins")
            forvalues c = 2/`ncol' {
                local vn : word `c' of `cn'
                capture drop `generate'_`vn'
                qui gen double `generate'_`vn' = .
                mata: dvar_putcol("`tvar'", "`generate'_`vn'", __M[., 1], __M[., `c'])
            }
            mata: mata drop __M
            di as text "(generated in-sample predictive statistics: `generate'_*)"
        }
        if ("`graph'"=="" & `J' >= 2) {
            preserve
            qui clear
            qui svmat double __dv_ins, name(ins)
            format ins1 `fmt'
            local c = 1 + 6*`J' + 1
            twoway (line ins`c' ins1, lcolor("62 38 168") lwidth(medthick)),  ///
                yline(0, lcolor(gs8) lpattern(dash))                            ///
                title("{bf:In-sample conditional correlation}", size(medium))  ///
                subtitle("`: word 1 of `varlist'' and `: word 2 of `varlist''", size(small)) ///
                xtitle("") ytitle("correlation") graphregion(color(white))      ///
                name(`name'_corr, replace)
            local j = 0
            local gl ""
            foreach v of local varlist {
                local ++j
                local c0 = 1 + (`j'-1)*6
                local cm = `c0' + 1
                local c5 = `c0' + 2
                local c25 = `c0' + 3
                local c50 = `c0' + 4
                local c75 = `c0' + 5
                local c95 = `c0' + 6
                local lg "off"
                if (`j'==`J') local lg `"order(1 "5-95%" 2 "25-75%" 3 "median") rows(1) size(small) pos(6)"'
                twoway (rarea ins`c5' ins`c95' ins1, color("62 38 168%20") lwidth(none)) ///
                    (rarea ins`c25' ins`c75' ins1, color("62 38 168%45") lwidth(none))  ///
                    (line ins`c50' ins1, lcolor("62 38 168") lwidth(medthick)),         ///
                    legend(`lg') ///
                    title("`v'", size(medsmall)) xtitle("") ytitle("")                  ///
                    graphregion(color(white)) name(__dvf`j', replace) nodraw
                local gl `gl' __dvf`j'
            }
            graph combine `gl', cols(1) title("{bf:In-sample one-step predictive distributions}", size(medium)) ///
                graphregion(color(white)) name(`name'_fan, replace)
            graph drop `gl'
            restore
        }
    }
    * ---------------------------------------------------------- e()
    ereturn post, esample(`touse')
    ereturn local cmd "dvar"
    ereturn local subcmd "fit"
    ereturn local depvars "`varlist'"
    ereturn local link "`linkname'"
    ereturn local timevar "`tvar'"
    ereturn local taus "`taus'"
    ereturn scalar N = `n'
    ereturn scalar lags = `lags'
    ereturn scalar horizon = `horizon'
    ereturn scalar grid = `grid'
    ereturn scalar lambda = `lambda'
    ereturn scalar alpha = `alpha'
    ereturn scalar hac = `hac'
    ereturn scalar J = `J'
    forvalues j = 1/`J' {
        ereturn matrix theta`j' = __dv_b`j'
        ereturn matrix se`j' = __dv_se`j'
        ereturn matrix tab_b`j' = __dv_tb`j'
        ereturn matrix tab_se`j' = __dv_ts`j'
    }
    ereturn matrix thresholds = __dv_G
    ereturn matrix fitstats = __dv_fst
    ereturn matrix pit = __dv_pit
    if (`ins') {
        ereturn matrix insample = __dv_ins
    }
    capture scalar drop __dv_n __dv_hac
    capture matrix drop __dv_pb
end

*==============================================================================
* dvar joint : multi-step joint predictive distributions + multimodality
*==============================================================================
program define dvar_joint, rclass
    syntax varlist(numeric min=2) [if] [in], AT(string) [ Lags(integer 3)        ///
        HORizons(numlist integer >0 sort) GRID(integer 99) LAMbda(real 0.0005)   ///
        ALPha(real 0.2) LINK(string) DRAWs(integer 20000) SEED(string)          ///
        PAIR(varlist numeric min=2 max=2) BW(numlist min=2 max=2 >0)             ///
        NGrid(integer 60) LEVels(integer 15) COLorscale(string) HEATmap         ///
        REALtime noGRaph NAME(string) XRange(numlist min=2 max=2 ascending)     ///
        YRange(numlist min=2 max=2 ascending) MODEfrac(real 0.05) noTABle ]
    marksample touse
    _dvar_prep `varlist', touse(`touse')
    local tvar "`r(tvar)'"
    local fmt  "`r(fmt)'"
    local unit "`r(unit)'"
    local tmin = r(tmin)
    local delta = r(delta)
    local Nobs = r(N)
    _dvar_pos `at' `unit' `tmin' `delta' `Nobs'
    local opos = r(pos)
    local tat = r(t)
    _dvar_link "`link'"
    local linkn = r(n)
    if ("`horizons'"=="") local horizons "1 2 3 4"
    if ("`name'"=="") local name "dvar_joint"
    if ("`seed'"!="") set seed `seed'
    if (`opos' - `lags' + 1 < 1) {
        di as err "at() is too early for `lags' lags"
        exit 498
    }
    if ("`pair'"=="") {
        local pv1 : word 1 of `varlist'
        local pv2 : word 2 of `varlist'
    }
    else {
        local pv1 : word 1 of `pair'
        local pv2 : word 2 of `pair'
    }
    local i1 : list posof "`pv1'" in varlist
    local i2 : list posof "`pv2'" in varlist
    if (`i1'==0 | `i2'==0) {
        di as err "pair() variables must be in the varlist"
        exit 198
    }
    local rt = ("`realtime'"!="")
    local ngrid = `ngrid'
    local modefrac = `modefrac'
    sort `tvar'
    mata: dvar_joint_main()
    local nh : word count `horizons'
    local tlab : di `fmt' `tat'
    if ("`table'"=="") {
        di
        di as text "{bf:DVAR joint predictive distributions}   information set ends at " as result "`tlab'"
        di as text "local projections with `lags' lags; " cond(`rt', "real-time estimation sample", "full estimation sample") ///
            "; `draws' draws per horizon"
        di as text "{hline 79}"
        di as text %-11s " h  target" "{c |}" %28s abbrev("`pv1'", 26) "{c |}" %28s abbrev("`pv2'", 26) "{c |}" %5s "corr" %4s "mod"
        di as text %-11s "" "{c |}" %7s "mean" %7s "sd" %7s "q05" %7s "q95" "{c |}" ///
            %7s "mean" %7s "sd" %7s "q05" %7s "q95" "{c |}"
        di as text "{hline 79}"
        forvalues i = 1/`nh' {
            local h = __dv_jst[`i', 1]
            local tg : di `fmt' `tat' + `h'*`delta'
            di as text %-11s " `h'  `tg'" "{c |}" as result ///
                %7.2f __dv_jst[`i',2] %7.2f __dv_jst[`i',3] %7.2f __dv_jst[`i',4] %7.2f __dv_jst[`i',6] ///
                as text "{c |}" as result ///
                %7.2f __dv_jst[`i',7] %7.2f __dv_jst[`i',8] %7.2f __dv_jst[`i',9] %7.2f __dv_jst[`i',11] ///
                as text "{c |}" as result %5.2f __dv_jst[`i',12] %4.0f __dv_jst[`i',13]
        }
        di as text "{hline 79}"
        di as text "modes: local maxima of the bivariate kernel density above `modefrac' x its peak"
        di as text "(Adrian, Boyarchenko & Giannone 2021: more than one mode = multimodality)."
    }
    if ("`graph'"=="") {
        _dvar_colors "`colorscale'" `=`levels'+1'
        local cl `"`r(colors)'"'
        local gl ""
        forvalues i = 1/`nh' {
            local h = __dv_jst[`i', 1]
            local tg : di `fmt' `tat' + `h'*`delta'
            local mk "`=__dv_jst[`i',14]' `=__dv_jst[`i',15]'"
            _dvar_contour, matrix(__dv_kd`i') colors(`cl') levels(`levels') name(__dvj`i') ///
                xtitle("`pv1'") ytitle("`pv2'") title("h = `h'  (`tg')") `heatmap' mark(`mk')
            local gl `gl' __dvj`i'
        }
        local cols = min(`nh', 4)
        local rows = ceil(`nh'/`cols')
        graph combine `gl', cols(`cols') title("{bf:Joint predictive density given information at `tlab'}", size(medium)) ///
            note("Filled contours: bivariate Gaussian KDE of DVAR draws; red square: realisation.") ///
            graphregion(color(white)) xsize(`=1+2.6*`cols'') ysize(`=1+2.8*`rows'') name(`name', replace)
        graph drop `gl'
    }
    matrix colnames __dv_jst = h mean1 sd1 q05_1 q50_1 q95_1 mean2 sd2 q05_2 q50_2 q95_2 corr modes real1 real2 bw1 bw2
    return matrix stats = __dv_jst
    forvalues i = 1/`nh' {
        matrix colnames __dv_kd`i' = x y density
        return matrix density`i' = __dv_kd`i'
    }
    return local pair "`pv1' `pv2'"
    return local horizons "`horizons'"
    return scalar at = `tat'
end

*==============================================================================
* dvar irf : distributional impulse responses (counterfactual analysis)
*==============================================================================
program define dvar_irf, rclass
    syntax varlist(numeric min=2) [if] [in], AT(string) SHock(varname numeric) ///
        CF(string) [ Lags(integer 4) INLags(integer 3) HORizon(integer 4)      ///
        LPEnd(string) GRID(integer 99) LAMbda(real 0.0005) ALPha(real 0.2)     ///
        LINK(string) DRAWs(integer 20000) SEED(string) QUantiles(numlist >0 <1 sort) ///
        REPs(integer 0) BLocklength(integer 8) Level(cilevel) JOINT             ///
        PAIR(varlist numeric min=2 max=2) NGrid(integer 50) LEVels(integer 15)  ///
        COLorscale(string) HEATmap noGRaph NAME(string) noTABle                  ///
        XRange(numlist min=2 max=2 ascending) YRange(numlist min=2 max=2 ascending) ]
    marksample touse
    _dvar_prep `varlist', touse(`touse')
    local tvar "`r(tvar)'"
    local fmt  "`r(fmt)'"
    local unit "`r(unit)'"
    local tmin = r(tmin)
    local delta = r(delta)
    local Nobs = r(N)
    _dvar_pos `at' `unit' `tmin' `delta' `Nobs'
    local opos = r(pos)
    local tat = r(t)
    local lpepos = `Nobs'
    if ("`lpend'"!="") {
        _dvar_pos `lpend' `unit' `tmin' `delta' `Nobs'
        local lpepos = r(pos)
    }
    _dvar_cf `cf'
    local cfdist "`r(dist)'"
    local cfpar  "`r(par)'"
    _dvar_link "`link'"
    local linkn = r(n)
    local sj : list posof "`shock'" in varlist
    if (`sj'==0) {
        di as err "shock() must be one of the outcome variables"
        exit 198
    }
    if ("`quantiles'"=="") local quantiles "0.05 0.25 0.5 0.75 0.95"
    if ("`name'"=="") local name "dvar_irf"
    if ("`seed'"!="") set seed `seed'
    if (`opos' - `inlags' < 1 | `opos' - `lags' + 1 < 1) {
        di as err "at() is too early for the requested lags"
        exit 498
    }
    if (`horizon' < 1) {
        di as err "horizon() must be at least 1"
        exit 198
    }
    if ("`pair'"=="") {
        local pv1 : word 1 of `varlist'
        local pv2 : word 2 of `varlist'
    }
    else {
        local pv1 : word 1 of `pair'
        local pv2 : word 2 of `pair'
    }
    local i1 : list posof "`pv1'" in varlist
    local i2 : list posof "`pv2'" in varlist
    local jnt = ("`joint'"!="")
    local J : word count `varlist'
    sort `tvar'
    if (`reps' > 0) di as text "moving-block bootstrap (`reps' replications, block length `blocklength'):"
    mata: dvar_irf_main()
    local tlab : di `fmt' `tat'
    local H = `horizon'
    if ("`table'"=="") {
        di
        di as text "{bf:Distributional impulse responses}  (Wang, Oka & Zhu 2025, Sec. 2.2)"
        di as text "{hline 78}"
        di as text "Shock date (h = 0)" _col(24) ": " as result "`tlab'" ///
            as text "    shocked variable: " as result "`shock'"
        di as text "Counterfactual G" _col(24) ": " as result "`cfdist'(`cfpar')"
        di as text "h = 0 model" _col(24) ": " as result "F(Y_t | Z_t), `inlags' lags"
        di as text "h >= 1 models" _col(24) ": " as result "F(Y_t+h | Y_t, Z_t), `lags' lags (local projections)"
        di as text "Ordering" _col(24) ": " as result "`varlist'" as text "  (triangular identification)"
        di as text "Draws" _col(24) ": " as result "`draws'" as text "  (common random numbers for Base and CF)"
        di as text "Base = F_{Y_j,t+h|Z_t};  Diff = statistic of F* minus statistic of F (QIRF / MIRF)"
        local j = 0
        foreach v of local varlist {
            local ++j
            if (`reps' > 0) {
                _dvar_irftab, tab(__dv_tab`j') variable(`v') q(`quantiles') lo(__dv_lo`j') hi(__dv_hi`j') level(`level')
            }
            else {
                _dvar_irftab, tab(__dv_tab`j') variable(`v') q(`quantiles')
            }
        }
        if (`reps' > 0) {
            di as text "* `level'% moving-block bootstrap interval excludes zero (`reps' reps, block `blocklength')."
        }
    }
    * ------------------------------------------------------------ graphs
    if ("`graph'"=="") {
        local j = 0
        local gl ""
        foreach v of local varlist {
            local ++j
            preserve
            qui clear
            qui svmat double __dv_den`j', name(dn)
            forvalues h = 0/`H' {
                local cb = 2 + 2*`h'
                local cc = 3 + 2*`h'
                twoway (line dn`cb' dn1, lcolor("0 114 189") lpattern(dash) lwidth(medthick)) ///
                    (line dn`cc' dn1, lcolor("217 83 25") lwidth(medthick)),                  ///
                    legend(off) title("`v', h = `h'", size(small)) xtitle("") ytitle("") ylabel(#3, labsize(small)) ///
                    graphregion(color(white)) name(__dvd`j'_`h', replace) nodraw
            }
            restore
        }
        local gl ""
        forvalues h = 0/`H' {
            forvalues j = 1/`J' {
                local gl `gl' __dvd`j'_`h'
            }
        }
        graph combine `gl', cols(`J') title("{bf:Distributional response to the `shock' impulse at `tlab'}", size(medium)) ///
            note("Blue dashed: baseline F; red solid: counterfactual F*. Rows: h = 0, ..., `H'.") ///
            graphregion(color(white)) ysize(`=2+1.6*(`H'+1)') xsize(`=2+2.6*`J'') name(`name'_density, replace)
        graph drop `gl'
        * DIRF(y) = F*(y) - F(y)
        local j = 0
        foreach v of local varlist {
            local ++j
            preserve
            qui clear
            qui svmat double __dv_dir`j', name(dr)
            local gl ""
            forvalues h = 0/`H' {
                local cd = 2 + 3*`h'
                local cl = 3 + 3*`h'
                local ch = 4 + 3*`h'
                local band ""
                if (`reps' > 0) local band "(rarea dr`cl' dr`ch' dr1, color("217 83 25%25") lwidth(none))"
                twoway `band' (line dr`cd' dr1, lcolor("217 83 25") lwidth(medthick)), ///
                    yline(0, lcolor(gs8) lpattern(dash)) legend(off)                 ///
                    title("h = `h'", size(small)) xtitle("`v'") ytitle("")           ///
                    graphregion(color(white)) name(__dvr`h', replace) nodraw
                local gl `gl' __dvr`h'
            }
            restore
            graph combine `gl', rows(1) title("{bf:DIRF of `v': F*(y) - F(y)}", size(medium)) ///
                graphregion(color(white)) xsize(`=2+2.2*(`H'+1)') ysize(3) name(`name'_dirf_`j', replace)
            graph drop `gl'
        }
        if (`jnt') {
            _dvar_colors "`colorscale'" `=`levels'+1'
            local cl `"`r(colors)'"'
            local gl ""
            forvalues h = 0/`H' {
                _dvar_contour, matrix(__dv_jb`h') colors(`cl') levels(`levels') name(__dvb`h') ///
                    xtitle("`pv1'") ytitle("`pv2'") title("Baseline, h = `h'") `heatmap'
                _dvar_contour, matrix(__dv_jc`h') colors(`cl') levels(`levels') name(__dvc`h') ///
                    xtitle("`pv1'") ytitle("`pv2'") title("Counterfactual, h = `h'") `heatmap'
                local gl `gl' __dvb`h' __dvc`h'
            }
            graph combine `gl', cols(2) title("{bf:Joint distribution: baseline vs counterfactual}", size(medium)) ///
                graphregion(color(white)) ysize(`=2+1.8*(`H'+1)') name(`name'_joint, replace)
            graph drop `gl'
        }
    }
    * ------------------------------------------------------------ r()
    local rn ""
    foreach q of local quantiles {
        local rn `rn' q`=round(100*`q')'_base q`=round(100*`q')'_diff
    }
    local rn `rn' mean_base mean_diff sd_base sd_diff skew_base skew_diff kurt_base kurt_diff
    local cn ""
    forvalues h = 0/`H' {
        local cn `cn' h`h'
    }
    local j = 0
    foreach v of local varlist {
        local ++j
        matrix rownames __dv_tab`j' = `rn'
        matrix colnames __dv_tab`j' = `cn'
        return matrix irf_`v' = __dv_tab`j'
        return matrix dirf_`v' = __dv_dir`j'
        return matrix dens_`v' = __dv_den`j'
        if (`reps' > 0) {
            return matrix lo_`v' = __dv_lo`j'
            return matrix hi_`v' = __dv_hi`j'
        }
    }
    if (`jnt') {
        forvalues h = 0/`H' {
            capture matrix drop __dv_jb`h' __dv_jc`h'
        }
    }
    return local shock "`shock'"
    return local cf "`cfdist' `cfpar'"
    return scalar at = `tat'
    return scalar horizon = `H'
    return scalar reps = `reps'
end

*==============================================================================
* dvar forecast : expanding-window distribution forecasts and evaluation
*==============================================================================
program define dvar_forecast, rclass
    syntax varlist(numeric min=1) [if] [in], START(string) [ Lags(integer 3)  ///
        Horizon(integer 1) GRID(integer 99) LAMbda(real 0.0005) ALPha(real 0.2) ///
        LINK(string) DRAWs(integer 2000) SEED(string) TAUs(numlist >0 <1 sort)  ///
        FULLsample noJOINT GENerate(name) noGRaph NAME(string) noTABle          ///
        EVALend(string) ]
    marksample touse
    _dvar_prep `varlist', touse(`touse')
    local tvar "`r(tvar)'"
    local fmt  "`r(fmt)'"
    local unit "`r(unit)'"
    local tmin = r(tmin)
    local delta = r(delta)
    local Nobs = r(N)
    _dvar_pos `start' `unit' `tmin' `delta' `Nobs'
    local opos = r(pos)
    local evalt = .
    if ("`evalend'"!="") {
        _dvar_pos `evalend' `unit' `tmin' `delta' `Nobs'
        local evalt = r(t)
    }
    _dvar_link "`link'"
    local linkn = r(n)
    if ("`taus'"=="") local taus "0.05 0.1 0.5 0.9 0.95"
    if ("`name'"=="") local name "dvar_fc"
    if ("`seed'"!="") set seed `seed'
    local full = ("`fullsample'"!="")
    local nojoint = ("`joint'"=="nojoint")
    if (`opos' > `Nobs' - `horizon') {
        di as err "start() leaves no forecast targets inside the sample"
        exit 498
    }
    local J : word count `varlist'
    local nt : word count `taus'
    sort `tvar'
    local no = `Nobs' - `horizon' - `opos' + 1
    di as text "expanding-window forecasts: `no' origins (one dot = 10 origins)"
    mata: dvar_fc_main()
    local nc = 10 + `nt'
    local P = rowsof(__dv_fc)
    local kcrit = 1.34
    * ---------------------------------------------------- summaries
    matrix __dv_sum = J(`J', 6 + `nt', .)
    local j = 0
    foreach v of local varlist {
        local ++j
        local cc = 2 + (`j'-1)*`nc'
        preserve
        qui clear
        qui svmat double __dv_fc, name(fc)
        qui gen byte ev = fc1 <= `evalt'
        qui count if ev
        local P = r(N)
        if (`P' < 5) {
            di as err "evalend() leaves fewer than 5 forecasts"
            exit 498
        }
        local cy = `cc' + 1
        local cp = `cc' + 2
        local cm = `cc' + 8
        local cr = `cc' + 9
        local cl = `cc' + 10
        qui gen double se2 = (fc`cm' - fc`cy')^2
        qui su se2 if ev, meanonly
        matrix __dv_sum[`j', 1] = sqrt(r(mean))
        qui su fc`cr' if ev, meanonly
        matrix __dv_sum[`j', 2] = r(mean)
        qui su fc`cl' if ev, meanonly
        matrix __dv_sum[`j', 3] = -r(mean)
        forvalues k = 1/`nt' {
            local cq = `cc' + 10 + `k'
            qui su fc`cq' if ev, meanonly
            matrix __dv_sum[`j', 3+`k'] = r(mean)
        }
        * Rossi-Sekhposyan (2019) KS test on the PIT ECDF
        if (_N < 1001) qui set obs 1001
        qui gen double r = (_n-1)/1000 in 1/1001
        qui gen double ecdf = .
        forvalues i = 1/1001 {
            qui count if fc`cp' <= r[`i'] & fc`cp' < . & ev==1
            qui replace ecdf = r(N)/`P' in `i'
        }
        qui gen double dev = abs(ecdf - r)
        qui su dev, meanonly
        matrix __dv_sum[`j', 4+`nt'] = sqrt(`P')*r(max)
        matrix __dv_sum[`j', 5+`nt'] = (sqrt(`P')*r(max) > `kcrit')
        matrix __dv_sum[`j', 6+`nt'] = `P'
        local Pev = `P' 
        if ("`graph'"=="") {
            qui gen double up = r + `kcrit'/sqrt(`P')
            qui gen double dn = r - `kcrit'/sqrt(`P')
            twoway (line r r, lcolor(black) lwidth(thin))                           ///
                (line up r, lcolor(black) lpattern(dash)) (line dn r, lcolor(black) lpattern(dash)) ///
                (line ecdf r, lcolor("217 83 25") lwidth(medthick)),                ///
                xscale(range(0 1)) yscale(range(0 1)) xlabel(0(.2)1) ylabel(0(.2)1) ///
                legend(off) title("`v'", size(medsmall)) xtitle("") ytitle("")        ///
                graphregion(color(white)) aspect(1) name(__dvp`j', replace) nodraw
            format fc1 `fmt'
            local c5 = `cc' + 3
            local c25 = `cc' + 4
            local c50 = `cc' + 5
            local c75 = `cc' + 6
            local c95 = `cc' + 7
            local lg "off"
            if (`j'==`J') local lg `"order(1 "5-95%" 2 "25-75%" 3 "median" 4 "realised") rows(1) size(small) pos(6)"'
            twoway (rarea fc`c5' fc`c95' fc1, color(gs13) lwidth(none))        ///
                (rarea fc`c25' fc`c75' fc1, color(gs10) lwidth(none))          ///
                (line fc`c50' fc1, lcolor(black) lwidth(medthick))             ///
                (scatter fc`cy' fc1, msymbol(o) msize(vsmall) mcolor("217 83 25")), ///
                legend(`lg') title("`v'", size(medsmall)) xtitle("") ytitle("")   ///
                graphregion(color(white)) name(__dvq`j', replace) nodraw
        }
        restore
    }
    if ("`table'"=="") {
        local P = `Pev'
        local tlo : di `fmt' __dv_fc[1, 1]
        local thi = __dv_fc[rowsof(__dv_fc), 1]
        if (`evalt' < .) local thi = min(`thi', `evalt')
        local thi : di `fmt' `thi'
        di
        di as text "{bf:DVAR out-of-sample distribution forecasts}   h = `horizon'"
        di as text "targets evaluated: " as result "`tlo' - `thi'" as text "  (P = `P')"
        di as text cond(`full', "estimation: full sample (as in the replication code)", ///
            "estimation: expanding window, information up to each origin (no look-ahead)")
        di as text "{hline 66}"
        di as text %-14s "variable" %10s "RMSE" %10s "CRPS" %10s "LogS" %11s "KS(PIT)" %11s "5% test"
        di as text "{hline 66}"
        local j = 0
        foreach v of local varlist {
            local ++j
            local rj = cond(__dv_sum[`j', 5+`nt']==1, "reject", "pass")
            di as text %-14s abbrev("`v'", 14) as result %10.3f __dv_sum[`j',1] %10.3f __dv_sum[`j',2] ///
                %10.3f __dv_sum[`j',3] %11.3f __dv_sum[`j', 4+`nt'] as text %11s "`rj'"
        }
        di as text "{hline 66}"
        local w = 14 + 10*`nt'
        di as text "Quantile (pinball) scores"
        di as text "{hline `w'}"
        di as text %-14s "variable" _c
        foreach t of local taus {
            di as text %10s "tau=`t'" _c
        }
        di
        di as text "{hline `w'}"
        local j = 0
        foreach v of local varlist {
            local ++j
            di as text %-14s abbrev("`v'", 14) _c
            forvalues k = 1/`nt' {
                di as result %10.3f __dv_sum[`j', 3+`k'] _c
            }
            di
        }
        di as text "{hline `w'}"
        qui {
            preserve
            clear
            svmat double __dv_fc, name(fc)
            su fc2 if fc1 <= `evalt', meanonly
            local jls = -r(mean)
            restore
        }
        di as text "joint log score (factorised density, lower is better): " as result %8.3f `jls'
        di as text "LogS = -mean log predictive density; CRPS by trapezoidal integration"
        di as text "over the thresholds. KS(PIT) = sqrt(P) sup|F_P(r) - r|, 5% critical"
        di as text "value 1.34 (Rossi & Sekhposyan 2019; exact for h = 1)."
    }
    if ("`graph'"=="") {
        local gl ""
        forvalues j = 1/`J' {
            local gl `gl' __dvp`j'
        }
        graph combine `gl', rows(1) title("{bf:Empirical CDF of out-of-sample PITs, h = `horizon'}", size(medium)) ///
            note("Dashed: 95% bands of the Rossi-Sekhposyan (2019) test.") ///
            graphregion(color(white)) name(`name'_pit, replace)
        graph drop `gl'
        local gl ""
        forvalues j = 1/`J' {
            local gl `gl' __dvq`j'
        }
        graph combine `gl', cols(1) title("{bf:Out-of-sample predictive distributions, h = `horizon'}", size(medium)) ///
            graphregion(color(white)) name(`name'_fan, replace)
        graph drop `gl'
    }
    * ---------------------------------------------------- variables
    local cn "time jointlogs"
    foreach v of local varlist {
        local cn `cn' y_`v' pit_`v' q05_`v' q25_`v' q50_`v' q75_`v' q95_`v' mean_`v' crps_`v' logs_`v'
        local k = 0
        foreach t of local taus {
            local ++k
            local cn `cn' qs`k'_`v'
        }
    }
    matrix colnames __dv_fc = `cn'
    if ("`generate'"!="") {
        mata: __M = st_matrix("__dv_fc")
        local ncol = colsof(__dv_fc)
        forvalues c = 2/`ncol' {
            local vn : word `c' of `cn'
            if (substr("`vn'", 1, 2)!="y_") {
                capture drop `generate'_`vn'
                qui gen double `generate'_`vn' = .
                mata: dvar_putcol("`tvar'", "`generate'_`vn'", __M[., 1], __M[., `c'])
            }
        }
        mata: mata drop __M
        di as text "(generated forecast variables `generate'_*, dated at the target period)"
    }
    local sn "RMSE CRPS LogS"
    foreach t of local taus {
        local sn `sn' QS`=round(100*`t')'
    }
    local sn `sn' KS_PIT reject5 P
    matrix colnames __dv_sum = `sn'
    matrix rownames __dv_sum = `varlist'
    return matrix summary = __dv_sum
    return matrix forecasts = __dv_fc
    return scalar P = `Pev'
    return scalar horizon = `horizon'
end

*==============================================================================
* dvar kernel : Adrian, Boyarchenko & Giannone (2021) kernel joint dynamics
*==============================================================================
program define dvar_kernel, rclass
    syntax varlist(numeric min=2) [if] [in], AT(string) [ Lags(integer 1)     ///
        C(real 0.5) CVgrid(numlist >0 sort) CVStart(string) HORizon(integer 4) ///
        DRAWs(integer 10000) SEED(string) SHock(varname numeric) CF(string)    ///
        GRID(integer 99) QUantiles(numlist >0 <1 sort) PAIR(varlist numeric min=2 max=2) ///
        NGrid(integer 50) LEVels(integer 15) COLorscale(string) HEATmap         ///
        MODEfrac(real 0.05) noGRaph NAME(string) noTABle                        ///
        XRange(numlist min=2 max=2 ascending) YRange(numlist min=2 max=2 ascending) ]
    marksample touse
    _dvar_prep `varlist', touse(`touse')
    local tvar "`r(tvar)'"
    local fmt  "`r(fmt)'"
    local unit "`r(unit)'"
    local tmin = r(tmin)
    local delta = r(delta)
    local Nobs = r(N)
    _dvar_pos `at' `unit' `tmin' `delta' `Nobs'
    local opos = r(pos)
    local tat = r(t)
    if (`opos' - `lags' < 1) {
        di as err "at() is too early for `lags' lags"
        exit 498
    }
    local cvpos = 0
    if ("`cvgrid'"!="") {
        if ("`cvstart'"=="") {
            local cvpos = max(`lags' + 30, floor(`Nobs'/3))
        }
        else {
            _dvar_pos `cvstart' `unit' `tmin' `delta' `Nobs'
            local cvpos = r(pos)
        }
        if (`cvpos' - `lags' < 20) {
            di as err "cvstart() leaves too few training observations"
            exit 498
        }
    }
    local sj = 0
    local cfdist ""
    local cfpar ""
    if ("`shock'"!="") {
        if (`"`cf'"'=="") {
            di as err "cf() is required with shock()"
            exit 198
        }
        _dvar_cf `cf'
        local cfdist "`r(dist)'"
        local cfpar  "`r(par)'"
        local sj : list posof "`shock'" in varlist
        if (`sj'==0) {
            di as err "shock() must be one of the outcome variables"
            exit 198
        }
    }
    if ("`quantiles'"=="") local quantiles "0.05 0.25 0.5 0.75 0.95"
    if ("`name'"=="") local name "dvar_kernel"
    if ("`seed'"!="") set seed `seed'
    if ("`pair'"=="") {
        local pv1 : word 1 of `varlist'
        local pv2 : word 2 of `varlist'
    }
    else {
        local pv1 : word 1 of `pair'
        local pv2 : word 2 of `pair'
    }
    local i1 : list posof "`pv1'" in varlist
    local i2 : list posof "`pv2'" in varlist
    local jnt = 1
    local J : word count `varlist'
    local H = `horizon'
    sort `tvar'
    mata: dvar_kernel_main()
    local cused = __dv_c
    local tlab : di `fmt' `tat'
    if ("`table'"=="") {
        di
        di as text "{bf:Kernel conditional joint distribution}  (Adrian, Boyarchenko & Giannone 2021)"
        di as text "{hline 79}"
        di as text "h = 0 distribution" _col(24) ": " as result "p(y_t | y_t-1..y_t-`lags'),  t = `tlab'"
        di as text "bandwidths" _col(24) ": " as result "w = c x sd,  c = " %5.3f `cused'
        di as text "multi-step" _col(24) ": " as result "Monte Carlo paths (Algorithm 1), `draws' draws"
        if ("`cvgrid'"!="") {
            di as text "{hline 40}"
            di as text "c selection: out-of-sample one-step log predictive score"
            di as text %10s "c" %14s "avg log score" %8s "P"
            local nc = rowsof(__dv_cv)
            forvalues i = 1/`nc' {
                local mk = cond(__dv_cv[`i',1]==`cused', " <- max", "")
                di as result %10.3f __dv_cv[`i',1] %14.4f __dv_cv[`i',2] %8.0f __dv_cv[`i',3] as text "`mk'"
            }
            di as text "{hline 40}"
        }
        di as text "{hline 79}"
        di as text %-11s " h  date" "{c |}" %28s abbrev("`pv1'", 26) "{c |}" %28s abbrev("`pv2'", 26) "{c |}" %5s "corr" %4s "mod"
        di as text %-11s "" "{c |}" %7s "mean" %7s "sd" %7s "q05" %7s "q95" "{c |}" ///
            %7s "mean" %7s "sd" %7s "q05" %7s "q95" "{c |}"
        di as text "{hline 79}"
        forvalues h = 0/`H' {
            local tg : di `fmt' `tat' + `h'*`delta'
            di as text %-11s " `h'  `tg'" "{c |}" as result ///
                %7.2f __dv_kst[`h'+1,2] %7.2f __dv_kst[`h'+1,3] %7.2f __dv_kst[`h'+1,4] %7.2f __dv_kst[`h'+1,5] ///
                as text "{c |}" as result ///
                %7.2f __dv_kst[`h'+1,6] %7.2f __dv_kst[`h'+1,7] %7.2f __dv_kst[`h'+1,8] %7.2f __dv_kst[`h'+1,9] ///
                as text "{c |}" as result %5.2f __dv_kst[`h'+1,10] %4.0f __dv_kst[`h'+1,11]
        }
        di as text "{hline 79}"
        if (`sj' > 0) {
            di
            di as text "{bf:Density impulse response}: shock to " as result "`shock'" ///
                as text " at h = 0, G = " as result "`cfdist'(`cfpar')"
            local j = 0
            foreach v of local varlist {
                local ++j
                _dvar_irftab, tab(__dv_tab`j') variable(`v') q(`quantiles')
            }
        }
    }
    if ("`graph'"=="") {
        _dvar_colors "`colorscale'" `=`levels'+1'
        local cl `"`r(colors)'"'
        local gl ""
        forvalues h = 0/`H' {
            local tg : di `fmt' `tat' + `h'*`delta'
            local mk ""
            local ob = __dv_kst[`h'+1, 13]
            if (`ob' < .) {
                qui su `pv1' if `touse' & `tvar'==`tat' + `h'*`delta', meanonly
                local m1 = r(mean)
                qui su `pv2' if `touse' & `tvar'==`tat' + `h'*`delta', meanonly
                local mk "`m1' `r(mean)'"
            }
            _dvar_contour, matrix(__dv_jb`h') colors(`cl') levels(`levels') name(__dvk`h') ///
                xtitle("`pv1'") ytitle("`pv2'") title("h = `h' (`tg')") `heatmap' mark(`mk')
            local gl `gl' __dvk`h'
        }
        graph combine `gl', rows(1) title("{bf:Kernel joint predictive density (ABG 2021)}", size(medium)) ///
            note("Information through the period before `tlab'; red square: realisation.") ///
            graphregion(color(white)) xsize(`=2+2.4*(`H'+1)') ysize(3.2) name(`name', replace)
        graph drop `gl'
        if (`sj' > 0) {
            local j = 0
            foreach v of local varlist {
                local ++j
                preserve
                qui clear
                qui svmat double __dv_den`j', name(dn)
                forvalues h = 0/`H' {
                    local cb = 2 + 2*`h'
                    local cc = 3 + 2*`h'
                    twoway (line dn`cb' dn1, lcolor("0 114 189") lpattern(dash) lwidth(medthick)) ///
                        (line dn`cc' dn1, lcolor("217 83 25") lwidth(medthick)),                  ///
                        legend(off) title("`v', h = `h'", size(small)) xtitle("") ytitle("") ylabel(#3, labsize(small)) ///
                        graphregion(color(white)) name(__dvd`j'_`h', replace) nodraw
                }
                restore
            }
            local gl ""
            forvalues h = 0/`H' {
                forvalues j = 1/`J' {
                    local gl `gl' __dvd`j'_`h'
                }
            }
            graph combine `gl', cols(`J') title("{bf:Density impulse response (kernel model)}", size(medium)) ///
                note("Blue dashed: baseline; red solid: counterfactual.") ///
                graphregion(color(white)) ysize(`=2+1.6*(`H'+1)') name(`name'_dir, replace)
            graph drop `gl'
        }
    }
    matrix colnames __dv_kst = h mean1 sd1 q05_1 q95_1 mean2 sd2 q05_2 q95_2 corr modes modes_cf obs
    return matrix stats = __dv_kst
    if ("`cvgrid'"!="") {
        matrix colnames __dv_cv = c avglogscore P
        return matrix cv = __dv_cv
    }
    if (`sj' > 0) {
        local j = 0
        foreach v of local varlist {
            local ++j
            return matrix irf_`v' = __dv_tab`j'
            return matrix dirf_`v' = __dv_dir`j'
            capture matrix drop __dv_den`j'
        }
    }
    forvalues h = 0/`H' {
        capture matrix drop __dv_jb`h' __dv_jc`h'
    }
    return scalar c = `cused'
    return scalar at = `tat'
    return local pair "`pv1' `pv2'"
    capture scalar drop __dv_c __dv_cbest
end

*==============================================================================
* dvar palette : the QQR colour maps
*==============================================================================
program define dvar_palette, rclass
    syntax [anything(name=pal)] [, N(integer 64) noGRaph NAME(string) ]
    if ("`pal'"=="") local pal "parula"
    if ("`name'"=="") local name "dvar_palette"
    _dvar_colors "`pal'" `n'
    local cl `"`r(colors)'"'
    if ("`graph'"=="") {
        preserve
        qui clear
        qui set obs `n'
        qui gen x = _n
        qui gen y = 1
        local plots ""
        forvalues i = 1/`n' {
            local c : word `i' of `cl'
            local plots `plots' (bar y x if x==`i', color("`c'") barwidth(1) lwidth(none))
        }
        twoway `plots', legend(off) yscale(off) xscale(off) ylabel(none) xlabel(none) ///
            title("{bf:`pal'} (`n' colours)") graphregion(color(white)) ysize(1.5) name(`name', replace)
        restore
    }
    di as text "`pal' (`n' colours, RGB):"
    di as result `"`cl'"'
    return local colors `"`cl'"'
end

*==============================================================================
* MATA ENGINE
*==============================================================================
mata:

// ------------------------------------------- outer-product helpers
// (Mata colon operators do not expand a column against a row)
real matrix dvar_od(real colvector a, real rowvector b)
{
    return(a*J(1, cols(b), 1) - J(rows(a), 1, 1)*b)
}

real matrix dvar_ole(real colvector a, real rowvector b)
{
    return((a*J(1, cols(b), 1)) :<= (J(rows(a), 1, 1)*b))
}

// ---------------------------------------------------------------- link
real matrix dvar_lk(real matrix eta, real scalar link)
{
    if (link==2) {
        return(normal(eta))
    }
    return(invlogit(eta))
}

// ------------------------------------------- MATLAB-compatible quantile
// positions (k-0.5)/n with linear interpolation, clamped at min / max
real colvector dvar_mq(real colvector x, real rowvector p)
{
    real colvector s, q
    real scalar n, i, pos, lo, fr
    s = sort(x, 1)
    n = rows(s)
    q = J(cols(p), 1, .)
    for (i=1; i<=cols(p); i++) {
        pos = n*p[i] + 0.5
        if (pos <= 1) {
            q[i] = s[1]
        }
        else if (pos >= n) {
            q[i] = s[n]
        }
        else {
            lo = floor(pos)
            fr = pos - lo
            q[i] = s[lo] + fr*(s[lo+1]-s[lo])
        }
    }
    return(q)
}

// ------------------------------------------- threshold grid (K x J)
real matrix dvar_grid(real matrix D, real scalar K)
{
    real matrix G
    real rowvector pk
    real scalar j
    pk = (1..K)/(K+1)
    G = J(K, cols(D), .)
    for (j=1; j<=cols(D); j++) {
        G[., j] = dvar_mq(D[., j], pk)
    }
    return(G)
}

// ------------------------------- local-projection design (VariablesT.m)
// row r : Y = D[r+p+h-1, .] ; Z = (1, D[r,.], ..., D[r+p-1,.])
void dvar_lpdata(real matrix D, real scalar h, real scalar p,
                 real matrix Y, real matrix Z)
{
    real scalar T, i
    T = rows(D)
    Y = D[|p+h, 1 \ T, cols(D)|]
    Z = J(T-h-p+1, 1, 1)
    for (i=1; i<=p; i++) {
        Z = Z, D[|i, 1 \ T-h-p+i, cols(D)|]
    }
}

// conditioning row whose information set ends at observation o
real rowvector dvar_zrow(real matrix D, real scalar o, real scalar p)
{
    real rowvector z
    real scalar i
    z = 1
    for (i=1; i<=p; i++) {
        z = z, D[o-p+i, .]
    }
    return(z)
}

// -------------------------------------------------------------------------
// One binary-choice DR fit, eq. (6), on STANDARDISED regressors Xt
// (first column = constant).  Elastic-net penalised IRLS with coordinate
// descent on the weighted Gram matrix (objective of MATLAB lassoglm:
//   (1/N) Deviance + lam*[(1-alpha)/2 ||b||^2 + alpha ||b||_1]  ).
// lam = 0 gives the plain maximum-likelihood estimator of eq. (6).
// -------------------------------------------------------------------------
real colvector dvar_fitstd(real matrix Xt, real colvector yb, real scalar lam,
                           real scalar alpha, real scalar link,
                           real colvector bstart)
{
    real scalar n, d, it, ybar, l1, qold, qnew, sh
    real matrix Gm
    real colvector b, bold, eta, p, w, z, c, phi, pen
    n = rows(Xt)
    d = cols(Xt)
    ybar = mean(yb)
    if (ybar<=0 | ybar>=1) {
        b = J(d, 1, 0)
        b[1] = 30
        if (ybar<=0) b[1] = -30
        return(b)
    }
    b = bstart
    if (rows(b)!=d) {
        b = J(d, 1, 0)
        b[1] = logit(ybar)
        if (link==2) b[1] = invnormal(ybar)
    }
    l1 = lam*alpha
    qold = dvar_pobj(Xt, yb, b, lam, alpha, link)
    for (it=1; it<=100; it++) {
        bold = b
        eta = Xt*b
        eta = rowmax((rowmin((eta, J(n,1,30))), J(n,1,-30)))
        if (link==2) {
            p = normal(eta)
            p = rowmax((rowmin((p, J(n,1,1-1e-10))), J(n,1,1e-10)))
            phi = rowmax((normalden(eta), J(n,1,1e-10)))
            w = (phi:^2) :/ (p:*(1:-p))
            z = eta + (yb - p):/phi
        }
        else {
            p = invlogit(eta)
            w = rowmax((p:*(1:-p), J(n,1,1e-5)))
            z = eta + (yb - p):/w
        }
        Gm = cross(Xt, w, Xt)/n
        c  = cross(Xt, w, z)/n
        if (lam<=0) {
            b = invsym(Gm)*c
        }
        else {
            // penalised Newton step; the L1 term enters through its local
            // quadratic approximation |b| ~ b^2/(2|b_old|) (Fan & Li 2001)
            pen = lam*(1-alpha) :+ l1:/(abs(bold):+1e-6)
            pen[1] = 0
            b = invsym(2*Gm + diag(pen))*(2*c)
        }
        // step-halving: accept only steps that lower the penalised objective
        qnew = dvar_pobj(Xt, yb, b, lam, alpha, link)
        sh = 0
        while (qnew > qold + 1e-12 & sh < 30) {
            b = (b + bold)/2
            qnew = dvar_pobj(Xt, yb, b, lam, alpha, link)
            sh = sh + 1
        }
        if (qnew > qold + 1e-12) {
            b = bold
            break
        }
        if (max(abs(b-bold)) < 1e-8 | qold - qnew < 1e-12) {
            break
        }
        qold = qnew
    }
    return(b)
}

// penalised objective (1/N) Deviance + lam*[(1-alpha)/2 ||b||^2 + alpha ||b||_1]
// (intercept unpenalised), the criterion minimised by MATLAB lassoglm
real scalar dvar_pobj(real matrix Xt, real colvector yb, real colvector b,
                      real scalar lam, real scalar alpha, real scalar link)
{
    real colvector p, bs
    real scalar n
    n = rows(Xt)
    p = dvar_lk(Xt*b, link)
    p = rowmax((rowmin((p, J(n,1,1-1e-15))), J(n,1,1e-15)))
    bs = b[|2 \ rows(b)|]
    return(-2*sum(yb:*ln(p) + (1:-yb):*ln(1:-p))/n + lam*((1-alpha)/2*sum(bs:^2) + alpha*sum(abs(bs))))
}

// -------------------------------------------------------------------------
// Whole factorised system, eqs. (1)-(2) and (6)-(8).
// Y (n x J), Z (n x dz, first col = 1), G (K x J thresholds).
// marg = 0 : eq j uses X_j = (Z, Y_1..Y_{j-1})     [joint factorisation]
// marg = 1 : eq j uses Z only                        [marginal DR, Beta1]
// returns TH : dmax x (K*J); eq j occupies columns (j-1)K+1..jK, rows 1..d_j
// -------------------------------------------------------------------------
real matrix dvar_fitsys(real matrix Y, real matrix Z, real matrix G,
                        real scalar lam, real scalar alpha, real scalar link,
                        real scalar marg)
{
    real scalar n, J, K, dz, dmax, j, k, d
    real matrix TH, X, X1, Xs
    real rowvector mu, sd
    real colvector bs, sl
    n  = rows(Y)
    J  = cols(Y)
    K  = rows(G)
    dz = cols(Z)
    dmax = dz + J - 1
    if (marg) dmax = dz
    TH = J(dmax, K*J, 0)
    for (j=1; j<=J; j++) {
        X = Z
        if (!marg & j>1) X = Z, Y[|1,1 \ n,j-1|]
        d  = cols(X)
        X1 = X[|1,2 \ n,d|]
        mu = mean(X1)
        sd = sqrt(diagonal(variance(X1)))'
        sd = sd + (sd:<=1e-12)
        Xs = J(n,1,1), (X1 :- mu):/sd
        bs = J(0,1,.)
        for (k=1; k<=K; k++) {
            bs = dvar_fitstd(Xs, (Y[.,j] :<= G[k,j]), lam, alpha, link, bs)
            sl = bs[|2 \ d|] :/ sd'
            TH[|1,(j-1)*K+k \ d,(j-1)*K+k|] = (bs[1] - mu*sl) \ sl
            if (abs(bs[1])>=30) bs = J(0,1,.)
        }
    }
    return(TH)
}

// coefficient block of equation j (d_j x K)
real matrix dvar_thj(real matrix TH, real scalar j, real scalar K, real scalar d)
{
    return(TH[|1,(j-1)*K+1 \ d,j*K|])
}

// -------------------------------------------------------------------------
// Algorithm 1 (Appendix B.1): sequential draws from the factorised joint.
// Inverse of the rearranged CDF: y = smallest threshold with F >= u.
// Because rearrangement = sorting, #{k : F_k < u} counts the order
// statistics below u, so no explicit sort is needed.
// sj > 0 : coordinate sj is replaced by the counterfactual draws gd
//          (G_{Y_sj|X_sj} in place of F_{Y_sj|X_sj}); later coordinates are
//          re-drawn conditionally on it (triangular identification).
// -------------------------------------------------------------------------
real matrix dvar_draw(real matrix TH, real matrix Zs, real matrix G,
                      real scalar link, real matrix U, real scalar sj,
                      real colvector gd)
{
    real scalar s, J, K, dz, j
    real matrix X, Ys, F
    real colvector idx, y
    s  = rows(Zs)
    J  = cols(G)
    K  = rows(G)
    dz = cols(Zs)
    X  = Zs
    Ys = J(s, J, .)
    for (j=1; j<=J; j++) {
        if (j==sj) {
            y = gd
        }
        else {
            F   = dvar_lk(X*dvar_thj(TH, j, K, dz+j-1), link)
            idx = rowsum(F :< U[.,j]) :+ 1
            idx = rowmin((idx, J(s,1,K)))
            y   = G[idx, j]
        }
        Ys[., j] = y
        X = X, y
    }
    return(Ys)
}

// rearranged CDF (Chernozhukov et al. 2009) of eq j at one covariate row
real rowvector dvar_cdfrow(real matrix TH, real scalar j, real scalar K,
                           real rowvector x, real scalar link)
{
    return(sort(dvar_lk(x*dvar_thj(TH, j, K, cols(x)), link)', 1)')
}

// PIT with the replication-code rule (value of F at the nearest threshold)
real scalar dvar_pit(real rowvector F, real colvector g, real scalar y)
{
    real scalar m, i, dmin
    m = 1
    dmin = abs(g[1]-y)
    for (i=2; i<=rows(g); i++) {
        if (abs(g[i]-y) < dmin) {
            dmin = abs(g[i]-y)
            m = i
        }
    }
    return(F[m])
}

// generalised inverse of a rearranged CDF at level tau
real scalar dvar_qinv(real rowvector F, real colvector g, real scalar tau)
{
    real scalar k
    k = sum(F :< tau) + 1
    if (k > cols(F)) k = cols(F)
    return(g[k])
}

// -------------------------------------------------------- sandwich (Thm 1)
// H^{-1} Omega H^{-1} / n with a Bartlett long-run Omega (L lags)
real matrix dvar_sandwich(real matrix X, real colvector yb, real colvector b,
                          real scalar link, real scalar L)
{
    real scalar n, l
    real matrix S, Om, Gl, Hn, Hi
    real colvector eta, p, phi, g, wh
    n = rows(X)
    eta = X*b
    if (link==2) {
        p   = rowmax((rowmin((normal(eta), J(n,1,1-1e-10))), J(n,1,1e-10)))
        phi = normalden(eta)
        g   = (yb - p):*phi:/(p:*(1:-p))
        wh  = (phi:^2):/(p:*(1:-p))
    }
    else {
        p  = invlogit(eta)
        g  = yb - p
        wh = p:*(1:-p)
    }
    S  = X:*g
    Om = cross(S, S)/n
    for (l=1; l<=L; l++) {
        if (l < n) {
            Gl = cross(S[|l+1,1 \ n,cols(S)|], S[|1,1 \ n-l,cols(S)|])/n
            Om = Om + (1-l/(L+1))*(Gl + Gl')
        }
    }
    Hn = cross(X, wh, X)/n
    Hi = invsym(Hn)
    return(Hi*Om*Hi/n)
}

// ----------------------------------------------------------- statistics
// quantiles (MATLAB rule), mean, sd(n-1), skewness, kurtosis (MATLAB)
real rowvector dvar_mstats(real colvector x, real rowvector q)
{
    real scalar n, m, m2, m3, m4
    real colvector dv
    n  = rows(x)
    m  = mean(x)
    dv = x :- m
    m2 = mean(dv:^2)
    m3 = mean(dv:^3)
    m4 = mean(dv:^4)
    if (m2<=0) {
        return((dvar_mq(x, q)', m, 0, 0, 0))
    }
    return((dvar_mq(x, q)', m, sqrt(m2*n/(n-1)), m3/m2^1.5, m4/(m2*m2)))
}

real scalar dvar_corr(real colvector a, real colvector b)
{
    real matrix C
    C = correlation((a, b))
    return(C[1,2])
}

// --------------------------------------------------------------- kernels
// Silverman rule with the ESTIMATION sample size nT (not the number of
// draws): DVAR draws live on the threshold lattice, so the smoothing must
// reflect estimation precision. At T ~ 200 this is ~0.3 x sd, the choice of
// the replication code (w = 0.3*std).
real scalar dvar_bw1(real colvector x, real scalar nT)
{
    real scalar sd, iq, s
    real colvector q
    sd = sqrt(variance(x))
    q  = dvar_mq(x, (0.25, 0.75))
    iq = (q[2]-q[1])/1.349
    s  = sd
    if (iq>0 & iq<sd) s = iq
    if (s<=0) s = 1
    return(0.9*s*nT^(-0.2))
}

// MATLAB ksdensity 2-D rule  sigma_robust * (4/((d+2)n))^(1/(d+4)), d = 2,
// applied to the observed series with n = estimation sample size; at the
// paper's data this gives about (0.2, 0.9) for (NFCI, GDP), close to the
// fixed (0.25, 0.8) of Figure 4.
real scalar dvar_bw2(real colvector x, real scalar nT)
{
    real scalar s, md
    md = dvar_mq(x, 0.5)
    s = dvar_mq(abs(x :- md), 0.5)/0.6745
    if (s<=0) s = sqrt(variance(x))
    if (s<=0) s = 1
    return(s*nT^(-1/6))
}

real colvector dvar_kde1(real colvector x, real colvector g, real scalar b)
{
    real colvector f
    real scalar i, n0, n1, chunk
    chunk = 5000
    f = J(rows(g), 1, 0)
    for (n0=1; n0<=rows(x); n0=n0+chunk) {
        n1 = min((n0+chunk-1, rows(x)))
        f = f + rowsum(normalden(dvar_od(g, x[|n0 \ n1|]')/b))
    }
    return(f/(rows(x)*b))
}

// f[iy, ix] on the grid gy x gx (product Gaussian kernel)
real matrix dvar_kde2(real colvector x, real colvector y, real colvector gx,
                      real colvector gy, real scalar bx, real scalar by)
{
    real matrix f
    real scalar n0, n1, chunk
    chunk = 5000
    f = J(rows(gy), rows(gx), 0)
    for (n0=1; n0<=rows(x); n0=n0+chunk) {
        n1 = min((n0+chunk-1, rows(x)))
        f = f + normalden(dvar_od(gy, y[|n0 \ n1|]')/by) * normalden(dvar_od(gx, x[|n0 \ n1|]')/bx)'
    }
    return(f/(rows(x)*bx*by))
}

// number of local maxima above frac*max (8-neighbour rule)
real scalar dvar_nmodes(real matrix f, real scalar frac)
{
    real scalar r, c, i, j, v, cnt, top
    real matrix nb
    r = rows(f)
    c = cols(f)
    top = max(f)
    cnt = 0
    for (i=2; i<=r-1; i++) {
        for (j=2; j<=c-1; j++) {
            v = f[i,j]
            if (v >= frac*top) {
                nb = f[|i-1,j-1 \ i+1,j+1|]
                nb[2,2] = -1
                if (v > max(nb)) cnt = cnt + 1
            }
        }
    }
    return(cnt)
}

real colvector dvar_lingrid(real scalar a, real scalar b, real scalar n)
{
    return(a :+ (b-a)*((0..(n-1))'/(n-1)))
}

// long form (x, y, f) of a grid density, for -twoway contour-
real matrix dvar_long(real colvector gx, real colvector gy, real matrix f)
{
    real matrix L
    real scalar i, j, r
    L = J(rows(gx)*rows(gy), 3, .)
    r = 0
    for (i=1; i<=rows(gy); i++) {
        for (j=1; j<=rows(gx); j++) {
            r = r + 1
            L[r, .] = (gx[j], gy[i], f[i,j])
        }
    }
    return(L)
}

// moving-block bootstrap row index (Kunsch 1989), block length bl
real colvector dvar_mbb(real scalar n, real scalar bl)
{
    real colvector idx, st
    real scalar nb, i
    if (bl > n) bl = n
    nb = ceil(n/bl)
    st = floor(runiform(nb,1)*(n-bl+1)) :+ 1
    idx = J(0,1,.)
    for (i=1; i<=nb; i++) {
        idx = idx \ (st[i] :+ (0..(bl-1))')
    }
    return(idx[|1 \ n|])
}

// --------------------------------------------- counterfactual G draws
real colvector dvar_cfdraw(string scalar dist, real rowvector par,
                           real scalar s, real colvector yb)
{
    real colvector u
    real scalar Fa, Fb, m
    u = runiform(s, 1)
    if (dist=="normal") {
        return(par[1] :+ par[2]*invnormal(u))
    }
    if (dist=="tnormal") {
        Fa = normal((par[3]-par[1])/par[2])
        Fb = normal((par[4]-par[1])/par[2])
        return(par[1] :+ par[2]*invnormal(Fa :+ u*(Fb-Fa)))
    }
    if (dist=="gamma") {
        return(par[2]*invgammap(par[1], u))
    }
    if (dist=="tgamma") {
        Fa = gammap(par[1], max((par[3],0))/par[2])
        Fb = gammap(par[1], par[4]/par[2])
        return(par[2]*invgammap(par[1], Fa :+ u*(Fb-Fa)))
    }
    if (dist=="uniform") {
        return(par[1] :+ (par[2]-par[1])*u)
    }
    if (dist=="point") {
        return(J(s, 1, par[1]))
    }
    if (dist=="shift") {
        return(yb :+ par[1])
    }
    if (dist=="scale") {
        m = mean(yb)
        return(m :+ par[1]*(yb :- m))
    }
    _error(198, "unknown counterfactual distribution")
}

// -------------------------------------------- distributional IRF stats
// For each variable j and horizon h = 0..H a block
//   [ q_base(nq) , mom_base(4) , q_diff(nq) , mom_diff(4) , DIR_jh(K) ]
// DIR_jh(y) = F*(y) - F(y), eq. (5), on the threshold grid.
real rowvector dvar_irfflat(real matrix YB, real matrix YC, real matrix G,
                            real rowvector q, real scalar H)
{
    real scalar J, K, j, h, c
    real rowvector out, sb, sc
    J = cols(G)
    K = rows(G)
    out = J(1, 0, .)
    for (j=1; j<=J; j++) {
        for (h=0; h<=H; h++) {
            c  = h*J + j
            sb = dvar_mstats(YB[., c], q)
            sc = dvar_mstats(YC[., c], q)
            out = out, sb, sc - sb, mean(dvar_ole(YC[., c], G[., j]')) - mean(dvar_ole(YB[., c], G[., j]'))
        }
    }
    return(out)
}

// ---------------------------------------------------------- palettes
string scalar dvar_palette(string scalar name, real scalar n)
{
    real matrix S
    real scalar m, i, t, lo, fr
    real rowvector col
    string scalar out
    name = strlower(name)
    if (name=="jet") {
        S = (0,0,144 \ 0,0,255 \ 0,255,255 \ 255,255,0 \ 255,0,0 \ 128,0,0)
    }
    else if (name=="turbo") {
        S = (48,18,59 \ 65,69,171 \ 70,117,237 \ 57,162,252 \ 27,207,212 \
             36,234,167 \ 97,252,108 \ 164,252,60 \ 209,232,52 \ 243,198,58 \
             254,155,45 \ 243,99,21 \ 217,56,6 \ 169,18,1 \ 122,4,3)
    }
    else if (name=="bluered" | name=="blue_red") {
        S = (5,48,97 \ 33,102,172 \ 146,197,222 \ 247,247,247 \ 244,165,130 \
             178,24,43 \ 103,0,31)
    }
    else if (name=="sinha" | name=="red_yellow_black") {
        S = (0,0,0 \ 74,14,0 \ 178,34,34 \ 255,140,0 \ 255,255,102)
    }
    else if (name=="viridis") {
        S = (68,1,84 \ 72,40,120 \ 62,74,137 \ 49,104,142 \ 38,130,142 \
             31,158,137 \ 53,183,121 \ 109,205,89 \ 180,222,44 \ 253,231,37)
    }
    else if (name=="gray" | name=="grey") {
        S = (255,255,255 \ 0,0,0)
    }
    else {
        // MATLAB R2014b Parula, 64 stops (same as the QQR packages)
        S = (0.2422,0.1504,0.6603 \ 0.2504,0.1650,0.7076 \ 0.2578,0.1818,0.7511 \
             0.2647,0.1978,0.7952 \ 0.2706,0.2147,0.8364 \ 0.2751,0.2342,0.8710 \
             0.2783,0.2559,0.8991 \ 0.2803,0.2782,0.9221 \ 0.2813,0.3006,0.9414 \
             0.2810,0.3228,0.9579 \ 0.2795,0.3447,0.9717 \ 0.2760,0.3667,0.9829 \
             0.2699,0.3892,0.9906 \ 0.2602,0.4123,0.9952 \ 0.2440,0.4358,0.9988 \
             0.2206,0.4603,0.9973 \ 0.1963,0.4847,0.9892 \ 0.1834,0.5074,0.9798 \
             0.1786,0.5289,0.9682 \ 0.1764,0.5499,0.9520 \ 0.1687,0.5703,0.9359 \
             0.1540,0.5902,0.9218 \ 0.1460,0.6091,0.9079 \ 0.1380,0.6276,0.8973 \
             0.1248,0.6459,0.8883 \ 0.1113,0.6635,0.8763 \ 0.0952,0.6798,0.8598 \
             0.0689,0.6948,0.8394 \ 0.0297,0.7082,0.8163 \ 0.0036,0.7203,0.7917 \
             0.0067,0.7312,0.7660 \ 0.0433,0.7411,0.7394 \ 0.0964,0.7500,0.7120 \
             0.1408,0.7584,0.6842 \ 0.1717,0.7670,0.6554 \ 0.1938,0.7758,0.6251 \
             0.2161,0.7843,0.5923 \ 0.2470,0.7918,0.5567 \ 0.2906,0.7973,0.5188 \
             0.3406,0.8008,0.4789 \ 0.3909,0.8029,0.4354 \ 0.4456,0.8024,0.3909 \
             0.5044,0.7993,0.3480 \ 0.5616,0.7942,0.3045 \ 0.6174,0.7876,0.2612 \
             0.6720,0.7793,0.2227 \ 0.7242,0.7698,0.1910 \ 0.7738,0.7598,0.1646 \
             0.8203,0.7498,0.1535 \ 0.8634,0.7406,0.1596 \ 0.9035,0.7330,0.1774 \
             0.9393,0.7288,0.2100 \ 0.9728,0.7298,0.2394 \ 0.9956,0.7434,0.2371 \
             0.9970,0.7659,0.2199 \ 0.9952,0.7893,0.2028 \ 0.9892,0.8129,0.1885 \
             0.9786,0.8360,0.1766 \ 0.9676,0.8587,0.1643 \ 0.9610,0.8806,0.1537 \
             0.9597,0.9023,0.1423 \ 0.9628,0.9234,0.1330 \ 0.9691,0.9438,0.1241 \
             0.9769,0.9839,0.0805)
        S = S*255
    }
    m = rows(S)
    out = ""
    for (i=1; i<=n; i++) {
        t = 1
        if (n>1) t = 1 + (m-1)*(i-1)/(n-1)
        lo = floor(t)
        if (lo >= m) lo = m - 1
        fr = t - lo
        col = round(S[lo,.]*(1-fr) + S[lo+1,.]*fr)
        out = out + char(34) + strofreal(col[1]) + " " + strofreal(col[2]) + " " + strofreal(col[3]) + char(34) + " "
    }
    return(out)
}

end

*==============================================================================
* MATA DRIVERS (one per subcommand)
*==============================================================================
mata:

real scalar dvar_lnum(string scalar nm)
{
    return(strtoreal(st_local(nm)))
}

real rowvector dvar_lvec(string scalar nm)
{
    string rowvector t
    t = tokens(st_local(nm))
    if (cols(t)==0) return(J(1,0,.))
    return(strtoreal(t))
}

// plotting window: user range, else 1%-99% of the pooled draws + 8% margins
real colvector dvar_window(real colvector x, real rowvector r, real scalar ng)
{
    real colvector qq
    if (cols(r)==2) {
        return(dvar_lingrid(r[1], r[2], ng))
    }
    qq = dvar_mq(x, (0.01, 0.99))
    return(dvar_lingrid(qq[1]-0.08*(qq[2]-qq[1]), qq[2]+0.08*(qq[2]-qq[1]), ng))
}

// =================================================================== FIT
void dvar_fit_main()
{
    string rowvector vars
    string scalar touse, tvar
    real scalar p, h, K, lam, alpha, link, L, ins, s, T, J, n, dz, j, k, d, t
    real scalar ll, ll0, yb0, pr2, npr, ks, i1, i2, c, np
    real matrix D, G, Y, Z, TH, X, Bj, SEj, V, U, Ys, INS, FST, PIT
    real colvector tv, yb, pp, r
    real rowvector taus, kt, F, sts
    vars  = tokens(st_local("varlist"))
    touse = st_local("touse")
    tvar  = st_local("tvar")
    p = dvar_lnum("lags")
    h = dvar_lnum("horizon")
    K = dvar_lnum("grid")
    lam = dvar_lnum("lambda")
    alpha = dvar_lnum("alpha")
    link = dvar_lnum("linkn")
    L = dvar_lnum("hac")
    ins = dvar_lnum("ins")
    s = dvar_lnum("draws")
    taus = dvar_lvec("taus")
    D  = st_data(., vars, touse)
    tv = st_data(., tvar, touse)
    T = rows(D)
    J = cols(D)
    G = dvar_grid(D, K)
    dvar_lpdata(D, h, p, Y=., Z=.)
    n  = rows(Y)
    dz = cols(Z)
    if (L < 0) L = floor(4*(n/100)^(2/9))
    TH = dvar_fitsys(Y, Z, G, lam, alpha, link, 0)
    kt = round(taus*(K+1))
    kt = rowmax((rowmin((kt', J(cols(kt),1,K))), J(cols(kt),1,1)))'
    FST = J(J, 3, .)
    PIT = J(n, J, .)
    r = (0..1000)'/1000
    for (j=1; j<=J; j++) {
        d = dz + j - 1
        X = Z
        if (j>1) X = Z, Y[|1,1 \ n,j-1|]
        Bj  = dvar_thj(TH, j, K, d)
        SEj = J(d, K, .)
        pr2 = 0
        npr = 0
        for (k=1; k<=K; k++) {
            yb  = (Y[., j] :<= G[k, j])
            yb0 = mean(yb)
            if (yb0>0 & yb0<1) {
                V = dvar_sandwich(X, yb, Bj[., k], link, L)
                SEj[., k] = sqrt(diagonal(V))
                pp = dvar_lk(X*Bj[., k], link)
                pp = rowmax((rowmin((pp, J(n,1,1-1e-12))), J(n,1,1e-12)))
                ll  = sum(yb:*ln(pp) + (1:-yb):*ln(1:-pp))
                ll0 = n*(yb0*ln(yb0) + (1-yb0)*ln(1-yb0))
                pr2 = pr2 + 1 - ll/ll0
                npr = npr + 1
            }
        }
        for (t=1; t<=n; t++) {
            F = sort(dvar_lk(X[t, .]*Bj, link)', 1)'
            PIT[t, j] = dvar_pit(F, G[., j], Y[t, j])
        }
        ks = sqrt(n)*max(abs(mean(dvar_ole(PIT[., j], r')) - r'))
        FST[j, .] = (pr2/max((npr,1)), ks, d)
        st_matrix("__dv_b" + strofreal(j), Bj)
        st_matrix("__dv_se" + strofreal(j), SEj)
        st_matrix("__dv_tb" + strofreal(j), Bj[., kt])
        st_matrix("__dv_ts" + strofreal(j), SEj[., kt])
    }
    st_matrix("__dv_G", G)
    st_matrix("__dv_fst", FST)
    st_matrix("__dv_pit", (tv[|p+h \ T|], PIT))
    st_numscalar("__dv_n", n)
    st_numscalar("__dv_hac", L)
    if (ins) {
        np = J*(J-1)/2
        INS = J(n, 1 + 6*J + np, .)
        INS[., 1] = tv[|p+h \ T|]
        for (t=1; t<=n; t++) {
            U  = runiform(s, J)
            Ys = dvar_draw(TH, J(s,1,1)#Z[t, .], G, link, U, 0, .)
            for (j=1; j<=J; j++) {
                sts = dvar_mq(Ys[., j], (0.05, 0.25, 0.5, 0.75, 0.95))'
                INS[|t,1+(j-1)*6+1 \ t,1+j*6|] = (mean(Ys[., j]), sts)
            }
            c = 1 + 6*J
            for (i1=1; i1<=J-1; i1++) {
                for (i2=i1+1; i2<=J; i2++) {
                    c = c + 1
                    INS[t, c] = dvar_corr(Ys[., i1], Ys[., i2])
                }
            }
        }
        st_matrix("__dv_ins", INS)
    }
}

// ================================================================= JOINT
void dvar_joint_main()
{
    string rowvector vars
    string scalar touse
    real scalar p, K, lam, alpha, link, s, o, i1, i2, rt, ng, mf, T, J
    real scalar nh, ih, h, n, nr, bx, by, xa, xb, ya, yb, a1, b1
    real matrix D, G, Y, Z, TH, Ys, YS, ST, f
    real colvector sel, gx, gy, qq
    real rowvector hs, zr, bw, xr, yr
    vars  = tokens(st_local("varlist"))
    touse = st_local("touse")
    p = dvar_lnum("lags")
    K = dvar_lnum("grid")
    lam = dvar_lnum("lambda")
    alpha = dvar_lnum("alpha")
    link = dvar_lnum("linkn")
    s  = dvar_lnum("draws")
    o  = dvar_lnum("opos")
    i1 = dvar_lnum("i1")
    i2 = dvar_lnum("i2")
    rt = dvar_lnum("rt")
    ng = dvar_lnum("ngrid")
    mf = dvar_lnum("modefrac")
    hs = dvar_lvec("horizons")
    bw = dvar_lvec("bw")
    xr = dvar_lvec("xrange")
    yr = dvar_lvec("yrange")
    D = st_data(., vars, touse)
    T = rows(D)
    J = cols(D)
    G = dvar_grid(D, K)
    zr = dvar_zrow(D, o, p)
    nh = cols(hs)
    YS = J(0, 2, .)
    ST = J(nh, 17, .)
    for (ih=1; ih<=nh; ih++) {
        h = hs[ih]
        dvar_lpdata(D, h, p, Y=., Z=.)
        n = rows(Y)
        sel = (1::n)
        if (rt) {
            nr = o - p - h + 1
            if (nr < 20) _error(2001, "too few observations before the forecast origin")
            sel = (1::nr)
        }
        TH = dvar_fitsys(Y[sel, .], Z[sel, .], G, lam, alpha, link, 0)
        Ys = dvar_draw(TH, J(s,1,1)#zr, G, link, runiform(s, J), 0, .)
        YS = YS \ (Ys[., i1], Ys[., i2])
        qq = dvar_mq(Ys[., i1], (0.05, 0.5, 0.95))
        ST[ih, 1..6] = h, mean(Ys[., i1]), sqrt(variance(Ys[., i1])), qq'
        qq = dvar_mq(Ys[., i2], (0.05, 0.5, 0.95))
        ST[ih, 7..11] = mean(Ys[., i2]), sqrt(variance(Ys[., i2])), qq'
        ST[ih, 12] = dvar_corr(Ys[., i1], Ys[., i2])
        if (o + h <= T) {
            ST[ih, 14] = D[o+h, i1]
            ST[ih, 15] = D[o+h, i2]
        }
    }
    // common plotting window across horizons
    qq = dvar_mq(YS[., 1], (0.002, 0.998))
    xa = qq[1] - 0.08*(qq[2]-qq[1])
    xb = qq[2] + 0.08*(qq[2]-qq[1])
    qq = dvar_mq(YS[., 2], (0.002, 0.998))
    ya = qq[1] - 0.08*(qq[2]-qq[1])
    yb = qq[2] + 0.08*(qq[2]-qq[1])
    if (cols(xr)==2) {
        xa = xr[1]
        xb = xr[2]
    }
    if (cols(yr)==2) {
        ya = yr[1]
        yb = yr[2]
    }
    gx = dvar_lingrid(xa, xb, ng)
    gy = dvar_lingrid(ya, yb, ng)
    for (ih=1; ih<=nh; ih++) {
        a1 = (ih-1)*s + 1
        b1 = ih*s
        bx = dvar_bw2(D[., i1], T)
        by = dvar_bw2(D[., i2], T)
        if (cols(bw)==2) {
            bx = bw[1]
            by = bw[2]
        }
        f = dvar_kde2(YS[|a1,1 \ b1,1|], YS[|a1,2 \ b1,2|], gx, gy, bx, by)
        ST[ih, 13] = dvar_nmodes(f, mf)
        ST[ih, 16] = bx
        ST[ih, 17] = by
        st_matrix("__dv_kd" + strofreal(ih), dvar_long(gx, gy, f))
    }
    st_matrix("__dv_jst", ST)
}

// ================================================================== IRF
void dvar_irf_main()
{
    string rowvector vars
    string scalar touse, dist
    real scalar p, p0, H, sj, s, K, lam, alpha, link, reps, bl, lpe, o, T, J
    real scalar i1, i2, jnt, ng, dz, h, n, nr, nq, nb, j, b, c, a1, xa, xb, ya, yb
    real scalar bx, by, nb0, bs, nT
    real matrix D, G, Y0, Z0, TH0, YB, YC, UU, Y, Z, THh, XB, XC, BS, TAB, DIR
    real matrix DEN, f, TB, TC, Yb, Yc
    real colvector gd, sel, gx, gy, gq, xb0, xc0, idx
    real rowvector par, q, z0, zr, flat, flb, lo, hi, qq
    pointer(real matrix) rowvector PTH
    vars  = tokens(st_local("varlist"))
    touse = st_local("touse")
    dist  = st_local("cfdist")
    par = dvar_lvec("cfpar")
    p  = dvar_lnum("lags")
    p0 = dvar_lnum("inlags")
    H  = dvar_lnum("horizon")
    sj = dvar_lnum("sj")
    s  = dvar_lnum("draws")
    K  = dvar_lnum("grid")
    lam = dvar_lnum("lambda")
    alpha = dvar_lnum("alpha")
    link = dvar_lnum("linkn")
    reps = dvar_lnum("reps")
    bl  = dvar_lnum("blocklength")
    lpe = dvar_lnum("lpepos")
    o   = dvar_lnum("opos")
    i1 = dvar_lnum("i1")
    i2 = dvar_lnum("i2")
    jnt = dvar_lnum("jnt")
    ng = dvar_lnum("ngrid")
    q  = dvar_lvec("quantiles")
    D = st_data(., vars, touse)
    T = rows(D)
    J = cols(D)
    G = dvar_grid(D, K)
    nq = cols(q)
    // ---- h = 0 : F_{Y_t|Z_t} and counterfactual G_{Y_t|Z_t}
    dvar_lpdata(D, 1, p0, Y0=., Z0=.)
    TH0 = dvar_fitsys(Y0, Z0, G, lam, alpha, link, 0)
    nT = rows(Y0)
    z0 = dvar_zrow(D, o-1, p0)
    UU = runiform(s, J*(H+1))
    YB = J(s, J*(H+1), .)
    YC = J(s, J*(H+1), .)
    YB[|1,1 \ s,J|] = dvar_draw(TH0, J(s,1,1)#z0, G, link, UU[|1,1 \ s,J|], 0, .)
    gd = dvar_cfdraw(dist, par, s, YB[., sj])
    YC[|1,1 \ s,J|] = dvar_draw(TH0, J(s,1,1)#z0, G, link, UU[|1,1 \ s,J|], sj, gd)
    // ---- h >= 1 : local projections F_{Y_t+h | Y_t, Z_t}
    zr = dvar_zrow(D, o, p)
    dz = cols(zr)
    PTH = J(1, H, NULL)
    for (h=1; h<=H; h++) {
        dvar_lpdata(D, h, p, Y=., Z=.)
        n  = rows(Y)
        nr = min((n, lpe - p - h + 1))
        if (nr < 20) _error(2001, "too few observations for the local projections")
        PTH[h] = &(dvar_fitsys(Y[|1,1 \ nr,J|], Z[|1,1 \ nr,dz|], G, lam, alpha, link, 0))
        XB = J(s,1,1)#zr[|1 \ dz-J|], YB[|1,1 \ s,J|]
        XC = J(s,1,1)#zr[|1 \ dz-J|], YC[|1,1 \ s,J|]
        YB[|1,h*J+1 \ s,(h+1)*J|] = dvar_draw(*PTH[h], XB, G, link, UU[|1,h*J+1 \ s,(h+1)*J|], 0, .)
        YC[|1,h*J+1 \ s,(h+1)*J|] = dvar_draw(*PTH[h], XC, G, link, UU[|1,h*J+1 \ s,(h+1)*J|], 0, .)
    }
    flat = dvar_irfflat(YB, YC, G, q, H)
    nb = 2*nq + 8 + K
    // ---- moving-block bootstrap: re-estimate every DR system on resampled
    //      rows, re-draw with the same uniforms (common random numbers)
    if (reps > 0) {
        BS = J(reps, cols(flat), .)
        n  = rows(Y0)
        for (b=1; b<=reps; b++) {
            idx = dvar_mbb(n, bl)
            TB  = dvar_fitsys(Y0[idx, .], Z0[idx, .], G, lam, alpha, link, 0)
            Yb = J(s, J*(H+1), .)
            Yc = J(s, J*(H+1), .)
            Yb[|1,1 \ s,J|] = dvar_draw(TB, J(s,1,1)#z0, G, link, UU[|1,1 \ s,J|], 0, .)
            if (dist=="shift" | dist=="scale") {
                gd = dvar_cfdraw(dist, par, s, Yb[., sj])
            }
            Yc[|1,1 \ s,J|] = dvar_draw(TB, J(s,1,1)#z0, G, link, UU[|1,1 \ s,J|], sj, gd)
            for (h=1; h<=H; h++) {
                dvar_lpdata(D, h, p, Y=., Z=.)
                nr  = min((rows(Y), lpe - p - h + 1))
                idx = dvar_mbb(nr, bl)
                TC  = dvar_fitsys(Y[idx, .], Z[idx, .], G, lam, alpha, link, 0)
                XB = J(s,1,1)#zr[|1 \ dz-J|], Yb[|1,1 \ s,J|]
                XC = J(s,1,1)#zr[|1 \ dz-J|], Yc[|1,1 \ s,J|]
                Yb[|1,h*J+1 \ s,(h+1)*J|] = dvar_draw(TC, XB, G, link, UU[|1,h*J+1 \ s,(h+1)*J|], 0, .)
                Yc[|1,h*J+1 \ s,(h+1)*J|] = dvar_draw(TC, XC, G, link, UU[|1,h*J+1 \ s,(h+1)*J|], 0, .)
            }
            BS[b, .] = dvar_irfflat(Yb, Yc, G, q, H)
            printf(".")
            if (mod(b, 50)==0) printf(" %g\n", b)
            displayflush()
        }
        printf("\n")
        lo = J(1, cols(flat), .)
        hi = J(1, cols(flat), .)
        a1 = (100 - dvar_lnum("level"))/200
        for (c=1; c<=cols(flat); c++) {
            qq = dvar_mq(BS[., c], (a1, 1-a1))'
            lo[c] = qq[1]
            hi[c] = qq[2]
        }
    }
    // ---- unpack into tables (rows: stat x {Base, Diff}; cols: h = 0..H)
    for (j=1; j<=J; j++) {
        TAB = J(2*(nq+4), H+1, .)
        DIR = J(K, 1 + 3*(H+1), .)
        DIR[., 1] = G[., j]
        for (h=0; h<=H; h++) {
            nb0 = ((j-1)*(H+1) + h)*nb
            for (c=1; c<=nq+4; c++) {
                TAB[2*c-1, h+1] = flat[nb0 + c]
                TAB[2*c,   h+1] = flat[nb0 + nq + 4 + c]
            }
            DIR[., 2+3*h] = flat[|nb0+2*nq+9 \ nb0+nb|]'
            if (reps > 0) {
                DIR[., 3+3*h] = lo[|nb0+2*nq+9 \ nb0+nb|]'
                DIR[., 4+3*h] = hi[|nb0+2*nq+9 \ nb0+nb|]'
            }
        }
        st_matrix("__dv_tab" + strofreal(j), TAB)
        st_matrix("__dv_dir" + strofreal(j), DIR)
        if (reps > 0) {
            TB = J(nq+4, H+1, .)
            TC = J(nq+4, H+1, .)
            for (h=0; h<=H; h++) {
                nb0 = ((j-1)*(H+1) + h)*nb
                for (c=1; c<=nq+4; c++) {
                    TB[c, h+1] = lo[nb0 + nq + 4 + c]
                    TC[c, h+1] = hi[nb0 + nq + 4 + c]
                }
            }
            st_matrix("__dv_lo" + strofreal(j), TB)
            st_matrix("__dv_hi" + strofreal(j), TC)
        }
        // marginal densities, baseline vs counterfactual
        xb0 = J(0,1,.)
        for (h=0; h<=H; h++) {
            xb0 = xb0 \ YB[., h*J+j] \ YC[., h*J+j]
        }
        qq = dvar_mq(xb0, (0.005, 0.995))'
        gq = dvar_lingrid(qq[1]-0.1*(qq[2]-qq[1]), qq[2]+0.1*(qq[2]-qq[1]), 200)
        DEN = gq
        for (h=0; h<=H; h++) {
            bs = dvar_bw1(YB[., h*J+j], nT)
            DEN = DEN, dvar_kde1(YB[., h*J+j], gq, bs), dvar_kde1(YC[., h*J+j], gq, bs)
        }
        st_matrix("__dv_den" + strofreal(j), DEN)
    }
    // ---- joint contours of the pair, baseline and counterfactual
    if (jnt) {
        xb0 = J(0,1,.)
        xc0 = J(0,1,.)
        for (h=0; h<=H; h++) {
            xb0 = xb0 \ YB[., h*J+i1] \ YC[., h*J+i1]
            xc0 = xc0 \ YB[., h*J+i2] \ YC[., h*J+i2]
        }
        gx = dvar_window(xb0, dvar_lvec("xrange"), ng)
        gy = dvar_window(xc0, dvar_lvec("yrange"), ng)
        for (h=0; h<=H; h++) {
            bx = dvar_bw2(D[., i1], T)
            by = dvar_bw2(D[., i2], T)
            f = dvar_kde2(YB[., h*J+i1], YB[., h*J+i2], gx, gy, bx, by)
            st_matrix("__dv_jb" + strofreal(h), dvar_long(gx, gy, f))
            f = dvar_kde2(YC[., h*J+i1], YC[., h*J+i2], gx, gy, bx, by)
            st_matrix("__dv_jc" + strofreal(h), dvar_long(gx, gy, f))
        }
    }
}

// ============================================================= FORECAST
void dvar_fc_main()
{
    string rowvector vars
    string scalar touse, tvar
    real scalar p, h, K, lam, alpha, link, s, os, full, nojoint, T, J, n, dz
    real scalar no, io, o, nr, c0, j, nc, jl, y, k, cc, mb
    real matrix D, G, Y, Z, TH, TH1, Ys, R, X1
    real colvector tv, f, u, idx, ysd
    real rowvector taus, zr, yo, F1, F, wy, x
    vars  = tokens(st_local("varlist"))
    touse = st_local("touse")
    tvar  = st_local("tvar")
    p = dvar_lnum("lags")
    h = dvar_lnum("horizon")
    K = dvar_lnum("grid")
    lam = dvar_lnum("lambda")
    alpha = dvar_lnum("alpha")
    link = dvar_lnum("linkn")
    s  = dvar_lnum("draws")
    os = dvar_lnum("opos")
    full = dvar_lnum("full")
    nojoint = dvar_lnum("nojoint")
    taus = dvar_lvec("taus")
    D  = st_data(., vars, touse)
    tv = st_data(., tvar, touse)
    T = rows(D)
    J = cols(D)
    G = dvar_grid(D, K)
    dvar_lpdata(D, h, p, Y=., Z=.)
    n  = rows(Y)
    dz = cols(Z)
    no = T - h - os + 1
    nc = 10 + cols(taus)
    R = J(no, 2 + J*nc, .)
    if (full) {
        TH  = dvar_fitsys(Y, Z, G, lam, alpha, link, 0)
        TH1 = dvar_fitsys(Y, Z, G, lam, alpha, link, 1)
    }
    for (io=1; io<=no; io++) {
        o  = os + io - 1
        nr = o - p - h + 1
        if (nr < 20) _error(2001, "too few observations before the first forecast origin")
        if (!full) {
            TH  = dvar_fitsys(Y[|1,1 \ nr,J|], Z[|1,1 \ nr,dz|], G, lam, alpha, link, 0)
            TH1 = dvar_fitsys(Y[|1,1 \ nr,J|], Z[|1,1 \ nr,dz|], G, lam, alpha, link, 1)
        }
        else {
            nr = n
        }
        zr = dvar_zrow(D, o, p)
        yo = D[o+h, .]
        c0 = 1.06*nr^(-1/(5+dz))
        ysd = sqrt(diagonal(variance(Y[|1,1 \ nr,J|])))
        wy = c0*ysd'
        if (!nojoint) {
            Ys = dvar_draw(TH, J(s,1,1)#zr, G, link, runiform(s, J), 0, .)
        }
        R[io, 1] = tv[o+h]
        jl = 0
        x  = zr
        for (j=1; j<=J; j++) {
            cc = 2 + (j-1)*nc
            y  = yo[j]
            F1 = dvar_cdfrow(TH1, j, K, zr, link)
            R[io, cc+1] = y
            R[io, cc+2] = dvar_pit(F1, G[., j], y)
            R[io, cc+3] = dvar_qinv(F1, G[., j], 0.05)
            R[io, cc+4] = dvar_qinv(F1, G[., j], 0.25)
            R[io, cc+5] = dvar_qinv(F1, G[., j], 0.50)
            R[io, cc+6] = dvar_qinv(F1, G[., j], 0.75)
            R[io, cc+7] = dvar_qinv(F1, G[., j], 0.95)
            f = (F1' - (y :< G[., j])):^2
            R[io, cc+9] = sum((G[|2,j \ K,j|] - G[|1,j \ K-1,j|]):*(f[|2 \ K|] + f[|1 \ K-1|])/2)
            if (!nojoint) {
                R[io, cc+8]  = mean(Ys[., j])
                R[io, cc+10] = ln(max((dvar_kde1(Ys[., j], y, wy[j]), 1e-10)))
            }
            else {
                idx = rowsum(J(s,1,1)#F1 :< runiform(s,1)) :+ 1
                idx = rowmin((idx, J(s,1,K)))
                R[io, cc+8]  = mean(G[idx, j])
                R[io, cc+10] = ln(max((dvar_kde1(G[idx, j], y, wy[j]), 1e-10)))
            }
            for (k=1; k<=cols(taus); k++) {
                mb = dvar_qinv(F1, G[., j], taus[k])
                R[io, cc+10+k] = (y - mb)*(taus[k] - (y < mb))
            }
            // joint log predictive score via the factorisation
            F = dvar_lk(x*dvar_thj(TH, j, K, cols(x)), link)
            idx = rowsum(J(s,1,1)#F :< runiform(s,1)) :+ 1
            idx = rowmin((idx, J(s,1,K)))
            jl = jl + ln(max((dvar_kde1(G[idx, j], y, wy[j]), 1e-10)))
            x = x, y
        }
        R[io, 2] = jl
        if (mod(io, 10)==0) printf(".")
        displayflush()
    }
    printf("\n")
    st_matrix("__dv_fc", R)
}

// shared unpacking of the IRF statistics (no bootstrap) + densities
void dvar_irfout(real matrix YB, real matrix YC, real matrix G, real rowvector q,
                 real scalar H, real scalar J, real scalar K, real scalar nT)
{
    real scalar nq, nb, j, h, c, nb0, bs
    real matrix TAB, DIR, DEN
    real rowvector flat, qq
    real colvector xb0, gq
    nq = cols(q)
    nb = 2*nq + 8 + K
    flat = dvar_irfflat(YB, YC, G, q, H)
    for (j=1; j<=J; j++) {
        TAB = J(2*(nq+4), H+1, .)
        DIR = J(K, 1 + 3*(H+1), .)
        DIR[., 1] = G[., j]
        for (h=0; h<=H; h++) {
            nb0 = ((j-1)*(H+1) + h)*nb
            for (c=1; c<=nq+4; c++) {
                TAB[2*c-1, h+1] = flat[nb0 + c]
                TAB[2*c,   h+1] = flat[nb0 + nq + 4 + c]
            }
            DIR[., 2+3*h] = flat[|nb0+2*nq+9 \ nb0+nb|]'
        }
        st_matrix("__dv_tab" + strofreal(j), TAB)
        st_matrix("__dv_dir" + strofreal(j), DIR)
        xb0 = J(0,1,.)
        for (h=0; h<=H; h++) {
            xb0 = xb0 \ YB[., h*J+j] \ YC[., h*J+j]
        }
        qq = dvar_mq(xb0, (0.005, 0.995))'
        gq = dvar_lingrid(qq[1]-0.1*(qq[2]-qq[1]), qq[2]+0.1*(qq[2]-qq[1]), 200)
        DEN = gq
        for (h=0; h<=H; h++) {
            bs = dvar_bw1(YB[., h*J+j], nT)
            DEN = DEN, dvar_kde1(YB[., h*J+j], gq, bs), dvar_kde1(YC[., h*J+j], gq, bs)
        }
        st_matrix("__dv_den" + strofreal(j), DEN)
    }
}

// write values vv into variable nv at the observations whose time = tt
void dvar_putcol(string scalar tvar, string scalar nv, real colvector tt,
                 real colvector vv)
{
    real colvector t, r
    real scalar i
    t = st_data(., tvar)
    for (i=1; i<=rows(tt); i++) {
        r = selectindex(t :== tt[i])
        if (rows(r) > 0) st_store(r[1], nv, vv[i])
    }
}

// =============================================================== KERNEL
// Adrian, Boyarchenko & Giannone (2021): eq. (1)-(3) with Gaussian product
// kernels, bandwidth w = c * sd; exact sampling from the kernel mixture.
real matrix dvar_kdraw(real matrix Xc, real matrix Ytr, real matrix Xtr,
                       real rowvector wy, real rowvector wx, real colvector U,
                       real matrix E, real matrix Yfix)
{
    real scalar s, n, k0, n0, n1, k, chunk
    real matrix Y, D2, W, C, Tri
    real colvector idx
    s  = rows(Xc)
    n  = rows(Ytr)
    k0 = cols(Yfix)
    Y  = J(s, cols(Ytr), .)
    Tri = uppertriangle(J(n,n,1))
    chunk = 2000
    for (n0=1; n0<=s; n0=n0+chunk) {
        n1 = min((n0+chunk-1, s))
        D2 = J(n1-n0+1, n, 0)
        for (k=1; k<=cols(Xtr); k++) {
            D2 = D2 + (dvar_od(Xc[|n0,k \ n1,k|], Xtr[., k]')/wx[k]):^2
        }
        for (k=1; k<=k0; k++) {
            D2 = D2 + (dvar_od(Yfix[|n0,k \ n1,k|], Ytr[., k]')/wy[k]):^2
        }
        W = exp(-0.5*(D2 :- rowmin(D2)))
        C = W*Tri
        idx = rowsum(C :< (U[|n0 \ n1|] :* C[., n])) :+ 1
        idx = rowmin((idx, J(n1-n0+1, 1, n)))
        Y[|n0,1 \ n1,cols(Ytr)|] = Ytr[idx, .] + E[|n0,1 \ n1,cols(Ytr)|]:*wy
    }
    if (k0 > 0) Y[|1,1 \ s,k0|] = Yfix
    return(Y)
}

// log of the kernel conditional joint density (1) at one point
real scalar dvar_klogd(real rowvector y, real rowvector x, real matrix Ytr,
                       real matrix Xtr, real rowvector wy, real rowvector wx)
{
    real colvector lx, ly, m
    real scalar k
    lx = J(rows(Xtr), 1, 0)
    for (k=1; k<=cols(Xtr); k++) {
        lx = lx + ln(normalden((x[k] :- Xtr[., k])/wx[k])/wx[k])
    }
    ly = J(rows(Ytr), 1, 0)
    for (k=1; k<=cols(Ytr); k++) {
        ly = ly + ln(normalden((y[k] :- Ytr[., k])/wy[k])/wy[k])
    }
    m = max(lx)
    return(ln(sum(exp(lx + ly :- m))) - ln(sum(exp(lx :- m))))
}

void dvar_kernel_main()
{
    string rowvector vars
    string scalar touse, dist
    real scalar p, c, H, s, o, sj, K, i1, i2, ng, T, J, ntr, i, h, ic, oo, nt, ls, best
    real scalar cvs, jnt, mf, bx, by, nq
    real matrix D, G, Ytr, Xtr, YB, YC, XB, XC, CV, E, Ytmp, f, ST
    real colvector U, gd, gq, xb0, xc0, gx, gy
    real rowvector sdY, wy, wx, x0, cg, par, q, qq, flat, xx
    vars  = tokens(st_local("varlist"))
    touse = st_local("touse")
    dist  = st_local("cfdist")
    par = dvar_lvec("cfpar")
    p = dvar_lnum("lags")
    c = dvar_lnum("c")
    H = dvar_lnum("horizon")
    s = dvar_lnum("draws")
    o = dvar_lnum("opos")
    sj = dvar_lnum("sj")
    K = dvar_lnum("grid")
    i1 = dvar_lnum("i1")
    i2 = dvar_lnum("i2")
    ng = dvar_lnum("ngrid")
    cvs = dvar_lnum("cvpos")
    jnt = dvar_lnum("jnt")
    mf  = dvar_lnum("modefrac")
    cg = dvar_lvec("cvgrid")
    q  = dvar_lvec("quantiles")
    nq = cols(q)
    D = st_data(., vars, touse)
    T = rows(D)
    J = cols(D)
    G = dvar_grid(D, K)
    ntr = T - p
    Ytr = D[|p+1,1 \ T,J|]
    Xtr = J(ntr, 0, .)
    for (i=1; i<=p; i++) {
        Xtr = Xtr, D[|p+1-i,1 \ T-i,J|]
    }
    sdY = sqrt(diagonal(variance(D)))'
    // ---- bandwidth constant by out-of-sample log predictive score
    if (cols(cg) > 0) {
        CV = J(cols(cg), 3, .)
        for (ic=1; ic<=cols(cg); ic++) {
            wy = cg[ic]*sdY
            wx = J(1, p, 1)#wy
            ls = 0
            nt = 0
            for (oo=cvs; oo<=T-1; oo++) {
                xx = J(1, 0, .)
                for (i=1; i<=p; i++) {
                    xx = xx, D[oo+1-i, .]
                }
                ls = ls + dvar_klogd(D[oo+1, .], xx, Ytr[|1,1 \ oo-p,J|], Xtr[|1,1 \ oo-p,cols(Xtr)|], wy, wx)
                nt = nt + 1
            }
            CV[ic, .] = (cg[ic], ls/nt, nt)
        }
        best = 1
        for (ic=2; ic<=rows(CV); ic++) {
            if (CV[ic, 2] > CV[best, 2]) best = ic
        }
        c = CV[best, 1]
        st_matrix("__dv_cv", CV)
        st_numscalar("__dv_cbest", c)
    }
    wy = c*sdY
    wx = J(1, p, 1)#wy
    // ---- h = 0 : one-step-ahead joint p(y_t | x_t), information up to t-1
    x0 = J(1, 0, .)
    for (i=1; i<=p; i++) {
        x0 = x0, D[o-i, .]
    }
    YB = J(s, J*(H+1), .)
    YC = J(s, J*(H+1), .)
    U  = runiform(s, 1)
    E  = rnormal(s, J, 0, 1)
    YB[|1,1 \ s,J|] = dvar_kdraw(J(s,1,1)#x0, Ytr, Xtr, wy, wx, U, E, J(s,0,.))
    YC[|1,1 \ s,J|] = YB[|1,1 \ s,J|]
    // perturbation rho(y_t|x_t): variables ordered before the shocked one keep
    // their draws, the shocked one is drawn from G, later ones are re-drawn
    // from the kernel conditional p(y_later | y_earlier, y_shock, x)  (eq. 4)
    if (sj > 0) {
        gd = dvar_cfdraw(dist, par, s, YB[., sj])
        if (sj > 1) {
            Ytmp = YB[|1,1 \ s,sj-1|], gd
        }
        else {
            Ytmp = gd
        }
        if (sj < J) {
            YC[|1,1 \ s,J|] = dvar_kdraw(J(s,1,1)#x0, Ytr, Xtr, wy, wx, U, E, Ytmp)
        }
        else {
            YC[|1,1 \ s,J|] = Ytmp
        }
    }
    // ---- propagate h = 1..H with the baseline kernel model (Algorithm 3)
    XB = J(s,1,1)#x0
    XC = XB
    for (h=1; h<=H; h++) {
        XB = YB[|1,(h-1)*J+1 \ s,h*J|], XB
        XC = YC[|1,(h-1)*J+1 \ s,h*J|], XC
        XB = XB[|1,1 \ s,p*J|]
        XC = XC[|1,1 \ s,p*J|]
        U = runiform(s, 1)
        E = rnormal(s, J, 0, 1)
        YB[|1,h*J+1 \ s,(h+1)*J|] = dvar_kdraw(XB, Ytr, Xtr, wy, wx, U, E, J(s,0,.))
        if (sj > 0) {
            YC[|1,h*J+1 \ s,(h+1)*J|] = dvar_kdraw(XC, Ytr, Xtr, wy, wx, U, E, J(s,0,.))
        }
        else {
            YC[|1,h*J+1 \ s,(h+1)*J|] = YB[|1,h*J+1 \ s,(h+1)*J|]
        }
    }
    // ---- term-structure summary of the pair + modes
    ST = J(H+1, 13, .)
    xb0 = J(0,1,.)
    xc0 = J(0,1,.)
    for (h=0; h<=H; h++) {
        xb0 = xb0 \ YB[., h*J+i1] \ YC[., h*J+i1]
        xc0 = xc0 \ YB[., h*J+i2] \ YC[., h*J+i2]
    }
    gx = dvar_window(xb0, dvar_lvec("xrange"), ng)
    gy = dvar_window(xc0, dvar_lvec("yrange"), ng)
    for (h=0; h<=H; h++) {
        qq = dvar_mq(YB[., h*J+i1], (0.05, 0.5, 0.95))'
        ST[h+1, 1..5] = h, mean(YB[., h*J+i1]), sqrt(variance(YB[., h*J+i1])), qq[1], qq[3]
        qq = dvar_mq(YB[., h*J+i2], (0.05, 0.5, 0.95))'
        ST[h+1, 6..9] = mean(YB[., h*J+i2]), sqrt(variance(YB[., h*J+i2])), qq[1], qq[3]
        ST[h+1, 10] = dvar_corr(YB[., h*J+i1], YB[., h*J+i2])
        bx = dvar_bw2(D[., i1], T)
        by = dvar_bw2(D[., i2], T)
        f = dvar_kde2(YB[., h*J+i1], YB[., h*J+i2], gx, gy, bx, by)
        ST[h+1, 11] = dvar_nmodes(f, mf)
        st_matrix("__dv_jb" + strofreal(h), dvar_long(gx, gy, f))
        if (sj > 0) {
            f = dvar_kde2(YC[., h*J+i1], YC[., h*J+i2], gx, gy, bx, by)
            ST[h+1, 12] = dvar_nmodes(f, mf)
            st_matrix("__dv_jc" + strofreal(h), dvar_long(gx, gy, f))
        }
        if (o + h <= T) {
            ST[h+1, 13] = o + h
        }
    }
    st_matrix("__dv_kst", ST)
    st_numscalar("__dv_c", c)
    // ---- distributional IRF tables (same layout as dvar irf)
    if (sj > 0) {
        dvar_irfout(YB, YC, G, q, H, J, K, ntr)
    }
}


end
