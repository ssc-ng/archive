*! qqardl 1.1.0  25nov2026
*! Quantile-on-Quantile ARDL (QQARDL): Destek et al. (2025); Balci & Dogan (2026)
*! Quantile series (QSER) of Li (2022/2025) ported to Mata from R package qfa
*! Author: Merwan Roudane <merwanroudane920@gmail.com>
*! https://github.com/merwanroudane
*
* Step -> equation map (Destek et al. 2025 numbering; details in help qqardl_methods)
*   S1  QSER of y at tau and of x at theta ............ Li (2022); qfa::qdft/qdft2qser
*         trigonometric quantile regressions at every Fourier frequency (Frisch-Newton LP)
*   S2  bounds-test regression, OLS ........................................ Eq. (1)
*         D.y = c + w1*L.D.y + w2*L.D.x + g1*L.y + g2*L.x + e
*       F test H0: g1 = g2 = 0 vs H1 ......................................... Eqs. (2)-(3)
*         cointegration if p < 0.10 (I(1) bound); Kripfganz-Schneider p-values
*   S3  error-correction form, OLS ............................................ Eq. (4)
*         D.y = a0 + d0*L.y + d1*D.x + b1*L.x + e   (lags fixed at 1, Jordan-Philips 2018)
*   S4  ECT d0 and short run d1 for all pairs; long run (-b1/d0, or b1 with
*       lrtype(beta)) only for cointegrated pairs ................................. p. 4
*   S5  (tau, theta) grid: 0.05 0.10 0.20 ... 0.90 0.95 ............. Eq. (5), fn. 1

program define qqardl, rclass
    version 15.0
    syntax varlist(min=2 max=2 numeric ts) [if] [in] [,          ///
        TAU(numlist >0 <1 sort)                                   ///
        THETA(numlist >0 <1 sort)                                 ///
        LAGs(numlist integer min=2 max=2 >0)                      ///
        VCE(string)                                               ///
        Level(cilevel)                                            ///
        GENqser(name)                                             ///
        SAVing(string asis)                                       ///
        noGRaph                                                   ///
        COLormap(string)                                          ///
        GRAPHName(name)                                           ///
        noTABle                                                   ///
        VALues                                                    ///
        BTest(string)                                             ///
        BTLags(numlist integer min=2 max=2 >=0)                   ///
        LRType(string)                                            ///
        LRALL                                                     ///
        noBOUNDSpval ]

    // ---- defaults ------------------------------------------------------
    if "`tau'"   == "" local tau   "0.05 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 0.95"
    if "`theta'" == "" local theta "`tau'"
    if "`lags'"  == "" local lags  "1 1"
    if "`vce'"   == "" local vce   "ols"
    if "`colormap'" == "" local colormap "parula"
    if "`graphname'" == "" local graphname "qqardl"
    local vce = lower("`vce'")
    if !inlist("`vce'", "ols", "robust") {
        di as err "vce() must be {bf:ols} or {bf:robust}"
        exit 198
    }
    gettoken p q : lags
    local q = trim("`q'")
    if "`btest'" == "" local btest "eq1"
    local btest = lower("`btest'")
    if !inlist("`btest'", "eq1", "ecm") {
        di as err "btest() must be {bf:eq1} (Destek et al. 2025, Eq. 1) or {bf:ecm} (Eq. 4)"
        exit 198
    }
    if "`btlags'" == "" local btlags "1 1"
    gettoken ba bb : btlags
    local bb = trim("`bb'")
    if "`lrtype'" == "" local lrtype "multiplier"
    local lrtype = lower("`lrtype'")
    if !inlist("`lrtype'", "multiplier", "beta") {
        di as err "lrtype() must be {bf:multiplier} (-b1/d0) or {bf:beta} (b1 of Eq. 4)"
        exit 198
    }

    // ---- data checks ---------------------------------------------------
    qui tsset
    local tvar "`r(timevar)'"
    if "`r(panelvar)'" != "" {
        di as err "qqardl is a time-series command; the data are xtset as a panel"
        exit 459
    }
    marksample touse
    tokenize `varlist'
    local y `1'
    local x `2'
    qui count if `touse'
    local n = r(N)
    if `n' < 30 {
        di as err "at least 30 observations are required (found `n')"
        exit 2001
    }
    // contiguous time span (QSER needs an equally spaced series without gaps)
    qui su `tvar' if `touse', meanonly
    tempvar tt
    qui gen double `tt' = `tvar' if `touse'
    qui su `tt', meanonly
    local tmin = r(min)
    local tmax = r(max)
    qui tsset
    local delta = r(tdelta)
    if ((`tmax' - `tmin') / `delta' + 1) != `n' {
        di as err "the estimation sample must be a contiguous time span without gaps"
        exit 459
    }

    local ntau : word count `tau'
    local nth  : word count `theta'
    tempname TAU THETA
    mata: st_matrix("`TAU'",   strtoreal(tokens(st_local("tau"))))
    mata: st_matrix("`THETA'", strtoreal(tokens(st_local("theta"))))

    // ---- S1-S4 in Mata ---------------------------------------------------
    tempname F FT ECT ECTSE LR LRSE SR SRSE R2 NOBS QY QX
    di as txt _n "Computing quantile series (QSER) and `=`ntau'*`nth'' ARDL(`p',`q') regressions ..."
    mata: _qqa_main("`y'", "`x'", "`touse'", "`TAU'", "`THETA'", `p', `q', "`vce'", ///
        "`F'", "`FT'", "`ECT'", "`ECTSE'", "`LR'", "`LRSE'", "`SR'", "`SRSE'",   ///
        "`R2'", "`NOBS'", "`QY'", "`QX'", "`btest'", `ba', `bb', "`lrtype'")
    local N = `NOBS'[1,1]
    local NB = `NOBS'[1,2]
    local kx = 1
    // short-run coefficients of the bounds-test regression (for ardlbounds)
    local sr = `ba' + `bb'
    if "`btest'" == "ecm" local sr = (`p' - 1) + `q'

    // ---- p-values ----------------------------------------------------------
    tempname FP TP ECTP LRP SRP
    matrix `FP'   = J(`nth', `ntau', .)
    matrix `TP'   = J(`nth', `ntau', .)
    matrix `ECTP' = J(`nth', `ntau', .)
    matrix `LRP'  = J(`nth', `ntau', .)
    matrix `SRP'  = J(`nth', `ntau', .)
    local df = `N' - (3 + (`p' - 1) + `q')
    local havebounds = 0
    if "`boundspval'" != "noboundspval" {
        capture which ardlbounds
        if !_rc local havebounds = 1
    }
    forvalues i = 1/`nth' {
        forvalues j = 1/`ntau' {
            local tE = `ECT'[`i',`j'] / `ECTSE'[`i',`j']
            matrix `ECTP'[`i',`j'] = 2*ttail(`df', abs(`tE'))
            matrix `LRP'[`i',`j']  = 2*ttail(`df', abs(`LR'[`i',`j'] / `LRSE'[`i',`j']))
            matrix `SRP'[`i',`j']  = 2*ttail(`df', abs(`SR'[`i',`j'] / `SRSE'[`i',`j']))
            if `havebounds' {
                capture quietly ardlbounds, case(3) k(`kx') n(`NB') sr(`sr') stat(F) pvalue(`=`F'[`i',`j']')
                if !_rc matrix `FP'[`i',`j'] = el(r(cvmat),1,8)
                capture quietly ardlbounds, case(3) k(`kx') n(`NB') sr(`sr') stat(t) pvalue(`=`FT'[`i',`j']')
                if !_rc matrix `TP'[`i',`j'] = el(r(cvmat),1,8)
            }
        }
    }
    local pvsource "Kripfganz-Schneider (2020) I(1) p-values"
    if !`havebounds' local pvsource "PSS (2001) asymptotic I(1) bounds, case III"

    // cointegration decision (Destek et al. 2025, p. 4): p < 0.10, i.e.
    // F above the 10% I(1) critical value
    tempname COINT
    matrix `COINT' = J(`nth', `ntau', 0)
    forvalues i = 1/`nth' {
        forvalues j = 1/`ntau' {
            if `havebounds' {
                if `FP'[`i',`j'] < 0.10 matrix `COINT'[`i',`j'] = 1
            }
            else {
                if `F'[`i',`j'] > 4.78 matrix `COINT'[`i',`j'] = 1
            }
        }
    }
    // long run reported only for cointegrated pairs unless lrall
    tempname LRD
    matrix `LRD' = `LR'
    if "`lrall'" == "" {
        forvalues i = 1/`nth' {
            forvalues j = 1/`ntau' {
                if `COINT'[`i',`j'] == 0 matrix `LRD'[`i',`j'] = .
            }
        }
    }
    local lrtitle "Long-run coefficient  LR = -b1/d0"
    if "`lrtype'" == "beta" local lrtitle "Long-run coefficient  b1 (Eq. 4)"
    if "`lrall'" == "" local lrtitle "`lrtitle'  [cointegrated pairs only]"
    local bttitle "Bounds test F-statistic, Eq. (1) (H0: no cointegration)"
    if "`btest'" == "ecm" local bttitle "Bounds test F-statistic, Eq. (4) (H0: no cointegration)"

    // ---- labels -----------------------------------------------------------
    local rn ""
    foreach t of local theta {
        local rn `rn' th`=subinstr(string(`t',"%4.2f"),"0.","",1)'
    }
    local cn ""
    foreach t of local tau {
        local cn `cn' tau`=subinstr(string(`t',"%4.2f"),"0.","",1)'
    }
    foreach M in F FT FP TP ECT ECTSE ECTP LR LRSE LRP SR SRSE SRP R2 COINT LRD {
        matrix rownames ``M'' = `rn'
        matrix colnames ``M'' = `cn'
    }

    // ---- tables --------------------------------------------------------------
    if "`table'" != "notable" {
        _qqa_header "`y'" "`x'" `N' `p' `q' "`vce'" "`pvsource'" `ntau' `nth'
        _qqa_grid "`bttitle'" `F' `FP' `havebounds' F `NB' `sr'
        _qqa_grid "`lrtitle'" `LRD' `LRP' 1 coef `N' `sr'
        _qqa_grid "Short-run coefficient  d1 on D.x (Eq. 4)" `SR' `SRP' 1 coef `N' `sr'
        _qqa_grid "Error-correction term  d0 on L.y (Eq. 4)" `ECT' `ECTP' 1 coef `N' `sr'
        di as txt "{hline 78}"
        di as txt "Rows: quantiles (theta) of `x'; columns: quantiles (tau) of `y'."
        di as txt "*** p<0.01, ** p<0.05, * p<0.10. Bounds test: `pvsource'; N = `NB'."
        di as txt "Coefficients: t(`df') with `=cond("`vce'"=="robust","HC1 robust","OLS")' standard errors" ///
            cond("`lrtype'"=="multiplier", "; LR SE by the delta method.", ".")
        qui mata: st_local("ncoint", strofreal(sum(st_matrix("`COINT'"))))
        di as txt "Cointegrated pairs (p<0.10): " as res `ncoint' as txt " of " as res `=`ntau'*`nth''
    }

    // ---- long-format results (for saving and graphs) ------------------------
    if `"`saving'"' != "" | "`graph'" != "nograph" {
        preserve
        qui {
            clear
            set obs `=`ntau'*`nth''
            gen double theta = .
            gen double tau = .
            gen byte coint = .
            foreach v in F F_p t_bdm t_p ect ect_se ect_p lr lr_se lr_p sr sr_se sr_p r2 {
                gen double `v' = .
            }
            local r = 0
            forvalues i = 1/`nth' {
                forvalues j = 1/`ntau' {
                    local r = `r' + 1
                    replace theta  = `THETA'[1,`i']   in `r'
                    replace tau    = `TAU'[1,`j']     in `r'
                    replace F      = `F'[`i',`j']     in `r'
                    replace F_p    = `FP'[`i',`j']    in `r'
                    replace t_bdm  = `FT'[`i',`j']    in `r'
                    replace t_p    = `TP'[`i',`j']    in `r'
                    replace ect    = `ECT'[`i',`j']   in `r'
                    replace ect_se = `ECTSE'[`i',`j'] in `r'
                    replace ect_p  = `ECTP'[`i',`j']  in `r'
                    replace lr     = `LR'[`i',`j']    in `r'
                    replace lr_se  = `LRSE'[`i',`j']  in `r'
                    replace lr_p   = `LRP'[`i',`j']   in `r'
                    replace sr     = `SR'[`i',`j']    in `r'
                    replace sr_se  = `SRSE'[`i',`j']  in `r'
                    replace sr_p   = `SRP'[`i',`j']   in `r'
                    replace r2     = `R2'[`i',`j']    in `r'
                    replace coint  = `COINT'[`i',`j'] in `r'
                }
            }
            if !`havebounds' {
                // PSS (2001) case III, k=1, asymptotic I(1) bounds: F 4.78/5.73/7.84
                replace F_p = cond(F > 7.84, 0.005, cond(F > 5.73, 0.025, cond(F > 4.78, 0.075, 0.5)))
            }
            label var theta "quantile of `x'"
            label var tau   "quantile of `y'"
        }
        if "`graph'" != "nograph" {
            _qqa_graphs, map(`colormap') name(`graphname') yname(`y') xname(`x') `values' `lrall'
        }
        if `"`saving'"' != "" {
            qui save `saving'
            gettoken savefn : saving, parse(",")
            di as txt "Results saved to " as res `"`savefn'"'
        }
        restore
    }

    // ---- quantile series as new variables -----------------------------------
    if "`genqser'" != "" {
        forvalues j = 1/`ntau' {
            local nm `genqser'_y`=subinstr(string(`TAU'[1,`j'],"%4.2f"),"0.","",1)'
            capture confirm new variable `nm'
            if _rc {
                di as txt "note: `nm' already exists; not replaced"
                continue
            }
            qui gen double `nm' = .
            mata: _qqa_store("`nm'", "`touse'", st_matrix("`QY'")[., `j'])
        }
        forvalues i = 1/`nth' {
            local nm `genqser'_x`=subinstr(string(`THETA'[1,`i'],"%4.2f"),"0.","",1)'
            capture confirm new variable `nm'
            if _rc {
                di as txt "note: `nm' already exists; not replaced"
                continue
            }
            qui gen double `nm' = .
            mata: _qqa_store("`nm'", "`touse'", st_matrix("`QX'")[., `i'])
        }
        di as txt "Quantile series stored as " as res "`genqser'_y*" as txt " and " as res "`genqser'_x*"
    }

    // ---- returns --------------------------------------------------------------
    return scalar N    = `N'
    return scalar p    = `p'
    return scalar q    = `q'
    return scalar df_r = `df'
    return scalar N_bt = `NB'
    return local depvar   "`y'"
    return local indepvar "`x'"
    return local tau      "`tau'"
    return local theta    "`theta'"
    return local vce      "`vce'"
    return local pvsource "`pvsource'"
    return local cmd      "qqardl"
    return local btest    "`btest'"
    return local lrtype   "`lrtype'"
    return matrix coint  = `COINT'
    return matrix qser_x = `QX'
    return matrix qser_y = `QY'
    return matrix r2     = `R2'
    return matrix sr_p   = `SRP'
    return matrix sr_se  = `SRSE'
    return matrix sr     = `SR'
    return matrix lr_p   = `LRP'
    return matrix lr_se  = `LRSE'
    return matrix lr     = `LR'
    return matrix ect_p  = `ECTP'
    return matrix ect_se = `ECTSE'
    return matrix ect    = `ECT'
    return matrix t_p    = `TP'
    return matrix t_bdm  = `FT'
    return matrix F_p    = `FP'
    return matrix F      = `F'
end

// ---------------------------------------------------------------------------
program define _qqa_header
    args y x N p q vce pvsource ntau nth
    di as txt _n "{hline 78}"
    di as txt "Quantile-on-Quantile ARDL (QQARDL)" _col(50) "Number of obs   = " as res %8.0f `N'
    di as txt "Destek et al. (2025); QSER of Li (2025)" _col(50) "ARDL order      = " as res "(`p',`q')"
    di as txt "Dependent: " as res "`y'" as txt "   Regressor: " as res "`x'" _col(50) "Quantile pairs  = " as res %8.0f `=`ntau'*`nth''
    di as txt "{hline 78}"
end

program define _qqa_grid
    args title V P havep kind N sr
    tempname M PP
    matrix `M' = `V'
    matrix `PP' = `P'
    local nr = rowsof(`M')
    local nc = colsof(`M')
    local rn : rownames `M'
    local cn : colnames `M'
    di as txt _n "{bf:`title'}"
    local line "{txt}{ralign 9:theta\tau} {c |}"
    foreach c of local cn {
        local lab = "." + subinstr("`c'", "tau", "", 1)
        local line "`line'{ralign 7:`lab'}   "
    }
    di "`line'"
    di as txt "{hline 10}{c +}{hline `=10*`nc''}"
    forvalues i = `nr'(-1)1 {
        local lab : word `i' of `rn'
        local lab = "." + subinstr("`lab'", "th", "", 1)
        local line "{txt}{ralign 9:`lab'} {c |}"
        forvalues j = 1/`nc' {
            local v = `M'[`i',`j']
            local pv = `PP'[`i',`j']
            local st ""
            if `havep' & `pv' < . {
                if `pv' < 0.10 local st "*"
                if `pv' < 0.05 local st "**"
                if `pv' < 0.01 local st "***"
            }
            if "`kind'" == "F" & !`havep' {
                if `v' > 4.78 local st "*"
                if `v' > 5.73 local st "**"
                if `v' > 7.84 local st "***"
            }
            if `v' >= . local st ""
            local s : display %7.3f `v'
            local line "`line'{res}{ralign 7:`s'}{txt}{lalign 3:`st'}"
        }
        di "`line'"
    }
end

// Tile heatmaps (one exact cell per quantile pair) with a colour bar, in the
// layout of Balci & Dogan (2026, Figs. 3-6): tau of y on the x-axis, theta of x
// on the y-axis, * p<0.10 and ** p<0.05 printed in the cells.
program define _qqa_graphs
    syntax , MAP(string) NAME(name) YNAME(string) XNAME(string) [ VALues LRALL ]
    local nb = 16
    tempvar ix iy y0 y1 bin star lab
    qui egen `ix' = group(tau)
    qui egen `iy' = group(theta)
    qui su `ix', meanonly
    local nx = r(max)
    qui su `iy', meanonly
    local ny = r(max)
    qui gen double `y0' = `iy' - 0.5
    qui gen double `y1' = `iy' + 0.5
    qui gen int `bin' = .
    qui gen str3 `star' = ""
    qui gen str12 `lab' = ""
    // axis labels from the quantile values
    local xl ""
    forvalues k = 1/`nx' {
        qui su tau if `ix' == `k', meanonly
        local v : display %4.2f r(mean)
        local xl `"`xl' `k' "`v'""'
    }
    local yl ""
    forvalues k = 1/`ny' {
        qui su theta if `iy' == `k', meanonly
        local v : display %4.2f r(mean)
        local yl `"`yl' `k' "`v'""'
    }
    tempname COL
    mata: st_matrix("`COL'", _qqa_palette("`map'", `nb'))
    local xb0 = `nx' + 0.9
    local xb1 = `nx' + 1.4
    local panels ""
    foreach m in F lr sr ect {
        if "`m'" == "F"   local ttl "Bounds test F-statistic"
        if "`m'" == "lr"  local ttl "Long-run coefficient"
        if "`m'" == "sr"  local ttl "Short-run coefficient"
        if "`m'" == "ect" local ttl "Error-correction term"
        qui replace `star' = ""
        qui replace `star' = "*"  if `m'_p < 0.10
        qui replace `star' = "**" if `m'_p < 0.05
        // long run only where cointegrated (white, unlabelled cells otherwise)
        local keep "1"
        if "`m'" == "lr" & "`lrall'" == "" {
            local keep "coint == 1"
            qui replace `star' = "" if coint != 1
        }
        qui su `m' if `keep', meanonly
        local zmin = r(min)
        local zmax = r(max)
        if `zmin' >= . {
            local zmin = 0
            local zmax = 1
        }
        if "`map'" == "bwr" {
            local za = max(abs(`zmin'), abs(`zmax'))
            local zmin = -`za'
            local zmax = `za'
        }
        if `zmax' <= `zmin' {
            local zmax = `zmin' + 1
        }
        qui replace `bin' = min(`nb', 1 + floor(`nb' * (`m' - `zmin') / (`zmax' - `zmin')))
        qui replace `bin' = . if !(`keep')
        local layers `"(rbar `y0' `y1' `ix', barwidth(1) fcolor(white) lcolor(gs13) lwidth(vthin))"'
        forvalues b = 1/`nb' {
            local rgb = string(`COL'[`b',1]) + " " + string(`COL'[`b',2]) + " " + string(`COL'[`b',3])
            qui count if `bin' == `b'
            if r(N) > 0 {
                local layers `"`layers' (rbar `y0' `y1' `ix' if `bin' == `b', barwidth(1) fcolor("`rgb'") fintensity(100) lcolor(white) lwidth(vthin))"'
            }
            // colour-bar segment
            local cb0 = 0.5 + (`b' - 1) * `ny' / `nb'
            local cb1 = 0.5 + `b' * `ny' / `nb'
            local layers `"`layers' (scatteri `cb0' `xb0' `cb1' `xb0' `cb1' `xb1' `cb0' `xb1' `cb0' `xb0', recast(area) fcolor("`rgb'") lcolor("`rgb'") lwidth(none) nodropbase)"'
        }
        local t0 : display %9.3g `zmin'
        local t1 : display %9.3g (`zmin' + `zmax') / 2
        local t2 : display %9.3g `zmax'
        local tx = `xb1' + 0.15
        local ymid = (`ny' + 1) / 2
        local txt `"text(0.5 `tx' "`=trim("`t0'")'", place(e) size(vsmall)) text(`ymid' `tx' "`=trim("`t1'")'", place(e) size(vsmall)) text(`=`ny'+0.5' `tx' "`=trim("`t2'")'", place(e) size(vsmall))"'
        if "`values'" != "" {
            qui replace `lab' = string(`m', "%5.2f") + `star'
            qui replace `lab' = "" if !(`keep')
            local mark "mlabel(`lab') mlabsize(tiny)"
        }
        else {
            local mark "mlabel(`star') mlabsize(small)"
        }
        capture twoway `layers'                                                  ///
            (scatter `iy' `ix', msymbol(none) `mark' mlabposition(0) mlabcolor(black)), ///
            `txt' title("`ttl'", size(medsmall))                                   ///
            xtitle("Quantiles of `yname' ({&tau})", size(small))                   ///
            ytitle("Quantiles of `xname' ({&theta})", size(small))                 ///
            xlabel(`xl', labsize(vsmall) angle(45) noticks nogrid)                        ///
            ylabel(`yl', labsize(vsmall) angle(0) noticks nogrid)                  ///
            xscale(range(0.5 `=`nx'+2.4') noline) yscale(range(0.5 `=`ny'+0.5') noline) ///
            legend(off) graphregion(color(white)) plotregion(margin(zero) style(none)) ///
            aspectratio(0.85) name(`name'_`m', replace) nodraw
        if !_rc local panels "`panels' `name'_`m'"
    }
    if "`panels'" != "" {
        graph combine `panels', cols(2) graphregion(color(white)) imargin(tiny) xsize(9) ysize(8)     ///
            title("QQARDL: `yname' on `xname'", size(medsmall))                   ///
            note("Cells: * p<0.10, ** p<0.05. Bounds test: H0 no level relationship.", size(vsmall)) ///
            name(`name', replace)
    }
    else {
        di as txt "note: graphs could not be drawn"
    }
end

// ===========================================================================
//                                   Mata
// ===========================================================================
mata:

// Frisch-Newton interior-point quantile regression (Koenker & Ng 2005;
// port of quantreg's rq.fit.fnb / lp.fnm).  Returns the coefficient vector.
real colvector _qqa_rqfn(real matrix X, real colvector yv, real scalar tau)
{
    real scalar n, it, gap, fp, fd, mu, g, beta, small, maxit
    real colvector c, b, u, xx, s, yd, r, z, w, q, sq, rhs, dy, dx, ds, dz, dw
    real colvector dxdz, dsdw, xinv, sinv, xi
    real matrix XQ, M

    n = rows(X)
    beta = 0.99995
    small = 1e-8
    maxit = 100
    c = -yv
    b = (1 - tau) :* colsum(X)'
    u = J(n, 1, 1)
    xx = J(n, 1, 1 - tau)
    s = u - xx
    yd = invsym(cross(X, X)) * cross(X, c)
    r = c - X * yd
    z = r :* (r :> 0)
    w = z - r
    gap = c' * xx - b' * yd + w' * u
    it = 0
    while ((gap > small) & (it < maxit)) {
        it = it + 1
        q = 1 :/ (z :/ xx + w :/ s)
        r = z - w
        sq = sqrt(q)
        XQ = X :* sq
        M = invsym(cross(XQ, XQ))
        rhs = sq :* r
        dy = M * cross(XQ, rhs)
        dx = q :* (X * dy - r)
        ds = -dx
        dz = -z :* (dx :/ xx :+ 1)
        dw = -w :* (ds :/ s :+ 1)
        fp = min((_qqa_bound(xx, dx), _qqa_bound(s, ds)))
        fd = min((_qqa_bound(w, dw), _qqa_bound(z, dz)))
        fp = min((beta * fp, 1))
        fd = min((beta * fd, 1))
        if (min((fp, fd)) < 1) {
            mu = z' * xx + w' * s
            g = (z + fd * dz)' * (xx + fp * dx) + (w + fd * dw)' * (s + fp * ds)
            mu = mu * (g / mu)^3 / (2 * n)
            dxdz = dx :* dz
            dsdw = ds :* dw
            xinv = 1 :/ xx
            sinv = 1 :/ s
            xi = mu :* (xinv - sinv)
            rhs = rhs + sq :* (dxdz - dsdw - xi)
            dy = M * cross(XQ, rhs)
            dx = q :* (X * dy + xi - r - dxdz + dsdw)
            ds = -dx
            dz = mu :* xinv - z - xinv :* z :* dx - dxdz
            dw = mu :* sinv - w - sinv :* w :* ds - dsdw
            fp = min((_qqa_bound(xx, dx), _qqa_bound(s, ds)))
            fd = min((_qqa_bound(w, dw), _qqa_bound(z, dz)))
            fp = min((beta * fp, 1))
            fd = min((beta * fd, 1))
        }
        xx = xx + fp * dx
        s = s + fp * ds
        yd = yd + fd * dy
        w = w + fd * dw
        z = z + fd * dz
        gap = c' * xx - b' * yd + w' * u
    }
    return(-yd)
}

real scalar _qqa_bound(real colvector v, real colvector dv)
{
    real colvector sel
    sel = selectindex(dv :< 0)
    if (rows(sel) == 0) {
        return(1e20)
    }
    return(min(-v[sel] :/ dv[sel]))
}

// Sample quantile, R type 7 (default of stats::quantile).
real scalar _qqa_q7(real colvector yv, real scalar tau)
{
    real colvector ys
    real scalar n, h, lo, hi
    ys = sort(yv, 1)
    n = rows(ys)
    h = (n - 1) * tau + 1
    lo = floor(h)
    hi = ceil(h)
    if (lo < 1) {
        lo = 1
    }
    if (hi > n) {
        hi = n
    }
    return(ys[lo] + (h - lo) * (ys[hi] - ys[lo]))
}

// Quantile series of Li (2025), exactly as qfa::qser (qdft -> inverse FFT).
real matrix _qqa_qser(real colvector yv, real rowvector taus)
{
    real scalar n, nt, k, j, half, f0
    real colvector tt, ph, cc, ss, bb
    real matrix out, X

    n = rows(yv)
    nt = cols(taus)
    tt = (1::n)
    ph = (0::(n - 1))
    out = J(n, nt, 0)
    for (j = 1; j <= nt; j = j + 1) {
        out[., j] = J(n, 1, _qqa_q7(yv, taus[j]))
    }
    half = floor((n - 1) / 2)
    for (k = 1; k <= half; k = k + 1) {
        f0 = k / n
        X = (J(n, 1, 1), cos(2 * pi() * f0 :* tt), sin(2 * pi() * f0 :* tt))
        cc = cos(2 * pi() * f0 :* ph)
        ss = sin(2 * pi() * f0 :* ph)
        for (j = 1; j <= nt; j = j + 1) {
            bb = _qqa_rqfn(X, yv, taus[j])
            out[., j] = out[., j] + bb[2] :* cc + bb[3] :* ss
        }
    }
    if (mod(n, 2) == 0) {
        X = (J(n, 1, 1), cos(pi() :* tt))
        cc = cos(pi() :* ph)
        for (j = 1; j <= nt; j = j + 1) {
            bb = _qqa_rqfn(X, yv, taus[j])
            out[., j] = out[., j] + bb[2] :* cc
        }
    }
    return(out)
}

// ARDL(p,q) error-correction regression by OLS.  Returns
// (a1, se(a1), b1, d0, se(d0), F, t_bdm, LR, se(LR), R2, N)
real rowvector _qqa_ecm(real colvector yv, real colvector xv, real scalar p,
                        real scalar q, string scalar vce)
{
    real scalar n, t0, N, k, i, s2, F, a1, b1, va, vb, cab, lr, vlr
    real colvector Y, e, bhat, idx
    real matrix X, V, XXi, R, Rb
    real rowvector g

    n = rows(yv)
    t0 = max((p, q)) + 1
    idx = (t0::n)
    N = rows(idx)
    Y = yv[idx] - yv[idx :- 1]
    X = (J(N, 1, 1), yv[idx :- 1], xv[idx :- 1])
    for (i = 1; i <= p - 1; i = i + 1) {
        X = (X, yv[idx :- i] - yv[idx :- i :- 1])
    }
    for (i = 0; i <= q - 1; i = i + 1) {
        X = (X, xv[idx :- i] - xv[idx :- i :- 1])
    }
    k = cols(X)
    XXi = invsym(cross(X, X))
    bhat = XXi * cross(X, Y)
    e = Y - X * bhat
    s2 = cross(e, e) / (N - k)
    if (vce == "robust") {
        V = XXi * cross(X :* e, X :* e) * XXi * (N / (N - k))
    }
    else {
        V = s2 :* XXi
    }
    // Wald F on (a1, b1), always with the classical variance (PSS bounds test)
    R = J(2, k, 0)
    R[1, 2] = 1
    R[2, 3] = 1
    Rb = R * bhat
    F = (Rb' * invsym(R * (s2 :* XXi) * R') * Rb) / 2
    a1 = bhat[2]
    b1 = bhat[3]
    va = V[2, 2]
    vb = V[3, 3]
    cab = V[2, 3]
    lr = -b1 / a1
    g = (b1 / (a1 * a1), -1 / a1)
    vlr = g * (va, cab \ cab, vb) * g'
    return((a1, sqrt(va), b1, bhat[3 + p], sqrt(V[3 + p, 3 + p]), F,
            a1 / sqrt(s2 * XXi[2, 2]), lr, sqrt(vlr),
            1 - cross(e, e) / cross(Y :- mean(Y), Y :- mean(Y)), N, sqrt(vb)))
}

// Bounds-test regression of Destek et al. (2025), Eq. (1):
// D.Y = c + sum_{i=1..a} w_i L(i)D.Y + sum_{j=1..b} v_j L(j)D.X + g1 L.Y + g2 L.X + e
// Returns (F for g1 = g2 = 0, t on g1, N).
real rowvector _qqa_btest(real colvector yv, real colvector xv, real scalar a,
                          real scalar b)
{
    real scalar n, t0, N, k, i, s2, F
    real colvector Y, e, bhat, idx
    real matrix X, XXi, R, Rb

    n = rows(yv)
    t0 = max((a, b)) + 2
    idx = (t0::n)
    N = rows(idx)
    Y = yv[idx] - yv[idx :- 1]
    X = (J(N, 1, 1), yv[idx :- 1], xv[idx :- 1])
    for (i = 1; i <= a; i = i + 1) {
        X = (X, yv[idx :- i] - yv[idx :- i :- 1])
    }
    for (i = 1; i <= b; i = i + 1) {
        X = (X, xv[idx :- i] - xv[idx :- i :- 1])
    }
    k = cols(X)
    XXi = invsym(cross(X, X))
    bhat = XXi * cross(X, Y)
    e = Y - X * bhat
    s2 = cross(e, e) / (N - k)
    R = J(2, k, 0)
    R[1, 2] = 1
    R[2, 3] = 1
    Rb = R * bhat
    F = (Rb' * invsym(R * (s2 :* XXi) * R') * Rb) / 2
    return((F, bhat[2] / sqrt(s2 * XXi[2, 2]), N))
}

void _qqa_main(string scalar yn, string scalar xn, string scalar touse,
               string scalar tauM, string scalar thM, real scalar p, real scalar q,
               string scalar vce, string scalar Fn, string scalar FTn,
               string scalar ECTn, string scalar ECTSEn, string scalar LRn,
               string scalar LRSEn, string scalar SRn, string scalar SRSEn,
               string scalar R2n, string scalar Nn, string scalar QYn, string scalar QXn,
               string scalar btest, real scalar ba, real scalar bb, string scalar lrtype)
{
    real colvector yv, xv
    real rowvector taus, ths, res, bt
    real matrix QY, QX, F, FT, ECT, ECTSE, LR, LRSE, SR, SRSE, R2
    real scalar i, j, nt, nh, N, NB

    yv = st_data(., yn, touse)
    xv = st_data(., xn, touse)
    taus = st_matrix(tauM)
    ths = st_matrix(thM)
    nt = cols(taus)
    nh = cols(ths)
    QY = _qqa_qser(yv, taus)
    QX = _qqa_qser(xv, ths)
    F = J(nh, nt, .)
    FT = F
    ECT = F
    ECTSE = F
    LR = F
    LRSE = F
    SR = F
    SRSE = F
    R2 = F
    N = .
    NB = .
    for (i = 1; i <= nh; i = i + 1) {
        for (j = 1; j <= nt; j = j + 1) {
            res = _qqa_ecm(QY[., j], QX[., i], p, q, vce)
            ECT[i, j] = res[1]
            ECTSE[i, j] = res[2]
            SR[i, j] = res[4]
            SRSE[i, j] = res[5]
            if (lrtype == "beta") {
                LR[i, j] = res[3]
                LRSE[i, j] = res[12]
            }
            else {
                LR[i, j] = res[8]
                LRSE[i, j] = res[9]
            }
            R2[i, j] = res[10]
            N = res[11]
            if (btest == "ecm") {
                F[i, j] = res[6]
                FT[i, j] = res[7]
                NB = N
            }
            else {
                bt = _qqa_btest(QY[., j], QX[., i], ba, bb)
                F[i, j] = bt[1]
                FT[i, j] = bt[2]
                NB = bt[3]
            }
        }
    }
    st_matrix(Fn, F)
    st_matrix(FTn, FT)
    st_matrix(ECTn, ECT)
    st_matrix(ECTSEn, ECTSE)
    st_matrix(LRn, LR)
    st_matrix(LRSEn, LRSE)
    st_matrix(SRn, SR)
    st_matrix(SRSEn, SRSE)
    st_matrix(R2n, R2)
    st_matrix(Nn, (N, NB))
    st_matrix(QYn, QY)
    st_matrix(QXn, QX)
}

void _qqa_store(string scalar vn, string scalar touse, real colvector v)
{
    st_store(., vn, touse, v)
}

// n colours (rows, RGB 0-255) interpolated along a colour map.
// parula: MATLAB R2014b anchors; jet; viridis; redblue (diverging).
real matrix _qqa_palette(string scalar map, real scalar n)
{
    real matrix A, out
    real scalar i, pos, lo, w, m

    map = strlower(map)
    if (map == "jet") {
        A = (0, 0, 143 \ 0, 0, 255 \ 0, 255, 255 \ 255, 255, 0 \ 255, 0, 0 \ 128, 0, 0)
    }
    else if (map == "viridis") {
        A = (68, 1, 84 \ 59, 82, 139 \ 33, 145, 140 \ 94, 201, 98 \ 253, 231, 37)
    }
    else if (map == "bwr") {
        A = (49, 104, 176 \ 145, 182, 222 \ 255, 255, 255 \ 240, 150, 140 \ 200, 30, 40)
    }
    else if (map == "redblue") {
        A = (5, 48, 97 \ 33, 102, 172 \ 146, 197, 222 \ 247, 247, 247 \ 244, 165, 130 \ 178, 24, 43 \ 103, 0, 31)
    }
    else {
        A = (0.2422, 0.1504, 0.6603 \ 0.2803, 0.2782, 0.9221 \ 0.2206, 0.4603, 0.9973 \
             0.1380, 0.6276, 0.8973 \ 0.0433, 0.7411, 0.7394 \ 0.3406, 0.8008, 0.4789 \
             0.7738, 0.7598, 0.1646 \ 0.9952, 0.7893, 0.2028 \ 0.9769, 0.9839, 0.0805) :* 255
    }
    m = rows(A)
    out = J(n, 3, .)
    for (i = 1; i <= n; i = i + 1) {
        pos = 1 + (m - 1) * (i - 1) / max((n - 1, 1))
        lo = floor(pos)
        if (lo >= m) {
            lo = m - 1
        }
        w = pos - lo
        out[i, .] = round((1 - w) :* A[lo, .] + w :* A[lo + 1, .])
    }
    return(out)
}
end
