*! thregress_estat 1.0.0  01oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Post-estimation suite for thregress.
*!   estat lrplot      LR / LR* threshold profile with the critical-value line
*!   estat regimeplot  data and fitted regime lines against the threshold variable
*!   estat regimes     regime-by-regime summary
*!   estat twostep     slope confidence intervals that account for threshold uncertainty
*!   estat hettest     heteroskedasticity diagnostics, including regime dependence
*!   estat table       publication-ready regime comparison table
*!   estat serial      no error autocorrelation, against the regime design
*!   estat archlm      Engle ARCH LM on the squared residuals
*!   estat mcleodli    McLeod-Li portmanteau on the squared residuals
*!   estat normality   Jarque-Bera, with its skewness and kurtosis components
*!   estat diag        all four of the above in one table

program define thregress_estat, rclass
    version 15
    * every command built on the shared threshold engine posts the same e()
    if !inlist("`e(cmd)'", "thregress", "thtar") {
        display as error "last estimates not found, or not from a THRESHKIT"
        display as error "jump-threshold command ({bf:thregress}, {bf:thtar})"
        exit 301
    }
    gettoken sub rest : 0, parse(" ,")
    local sub = lower("`sub'")
    if "`sub'" == "lrplot" | "`sub'" == "profileplot" {
        LRplot `rest'
    }
    else if "`sub'" == "regimeplot" {
        Regimeplot `rest'
    }
    else if "`sub'" == "regimes" {
        Regimes `rest'
    }
    else if "`sub'" == "twostep" {
        Twostep `rest'
    }
    else if "`sub'" == "hettest" {
        Hettest `rest'
    }
    else if "`sub'" == "table" {
        Rtable `rest'
    }
    else if inlist("`sub'", "skeleton", "skel") {
        Skeleton `rest'
        return add
    }
    else if "`sub'" == "hac" {
        Hac `rest'
        return add
    }
    else if "`sub'" == "girf" {
        if "`e(cmd)'" != "thtar" {
            display as error "{bf:estat girf} needs a time-series fit"
            display as error "({bf:thtar}); after {bf:thregress} the model has"
            display as error "no dynamics to propagate a shock through."
            exit 198
        }
        Ugirf `rest'
        return add
    }
    else if inlist("`sub'", "eqtest", "equality") {
        Eqtest `rest'
        return add
    }
    else if "`sub'" == "gridboot" {
        Gridboot `rest'
        return add
    }
    else if inlist("`sub'", "serial", "archlm", "mcleodli", "normality", "diag") {
        Resdiag "`sub'" `rest'
        return add
    }
    else {
        display as error "unknown {bf:estat} subcommand {bf:`sub'}"
        display as error "valid: lrplot, regimeplot, regimes, twostep, hettest,"
        display as error "       gridboot, eqtest, girf, skeleton, hac, table,"
        display as error "       serial,"
        display as error "       archlm,"
        display as error "       mcleodli, normality, diag"
        exit 198
    }
end

* ======================================================================
* Residual diagnostics. The null regressors are the model GRADIENT, which for
* a jump-threshold fit is the regime-split design itself -- the same columns
* the estimator used. Built here as explicitly named variables (NOT tempvars:
* a tempvar dies when the program that allocated it exits, and the worker
* reads them from its own scope) and dropped afterwards.
* ======================================================================
program define Resdiag, rclass
    version 15
    gettoken which 0 : 0
    syntax [, LAGs(integer 4) ]
    if "`which'" == "diag" local which "serial arch mcleodli normality"
    if "`which'" == "archlm" local which "arch"

    capture drop __tkg_*
    quietly generate byte __tkg_touse = e(sample)
    * after thtar, e(indepvars) holds the TEMPORARY variables thtar built for
    * the autoregressive lags, and those are long gone; e(arnames) holds the
    * real time-series expressions, so prefer it
    local xl "`e(indepvars)'"
    if "`e(arnames)'" != "" local xl "`e(arnames)'"
    local zl "`e(invariant)'"
    local tv "`e(threshold_var)'"
    local m  = e(nthresh)
    local hc = cond(e(k_switch) > `: word count `xl'', 1, 0)
    tempname GAM
    matrix `GAM' = e(thresholds)

    * the regime indicators, from the stored thresholds
    forvalues r = 1/`=`m'+1' {
        if `r' == 1 {
            quietly generate byte __tkg_d`r' = (`tv' <= `GAM'[1,1]) if __tkg_touse
        }
        else if `r' == `=`m'+1' {
            quietly generate byte __tkg_d`r' = (`tv' > `GAM'[1,`m']) if __tkg_touse
        }
        else {
            quietly generate byte __tkg_d`r' = ///
                (`tv' > `GAM'[1,`=`r'-1'] & `tv' <= `GAM'[1,`r']) if __tkg_touse
        }
    }
    * the regime-split design: each switching regressor and constant per regime
    local nv 0
    forvalues r = 1/`=`m'+1' {
        foreach v of local xl {
            local ++nv
            quietly generate double __tkg_x`nv' = `v' * __tkg_d`r' if __tkg_touse
        }
        if `hc' {
            local ++nv
            quietly generate double __tkg_x`nv' = __tkg_d`r' if __tkg_touse
        }
    }
    foreach v of local zl {
        local ++nv
        quietly generate double __tkg_x`nv' = `v' if __tkg_touse
    }
    local nullvars ""
    forvalues j = 1/`nv' {
        local nullvars `nullvars' __tkg_x`j'
    }
    quietly predict double __tkg_e if __tkg_touse, residuals

    _tk_resdiag __tkg_e , touse(__tkg_touse) nullvars(`nullvars') ///
        lags(`lags') which("`which'") model("`e(cmd)'")
    return add
    capture drop __tkg_*
end

* ----------------------------------------------------------------------
* LR / LR* profile. The figure Hansen (2000) plots in Figures 2-3:
* the profile with a flat line at c, so the confidence set is read off
* as the region where the curve lies below the line.
program define LRplot
    syntax [, STAT(string) NOCI LEVel(cilevel) SAVing(string asis) ///
              TItle(string asis) * ]
    if "`e(profile)'" == "" {
        display as error "no stored profile: thregress was run with threshold() or on a known threshold"
        exit 198
    }
    if "`stat'" == "" {
        local stat = cond("`e(ci_method)'"=="lr", "lr", "lrstar")
    }
    local col = cond("`stat'"=="lr", 3, 4)
    local ylab = cond("`stat'"=="lr", "LR{sub:n}({&gamma})", "LR*{sub:n}({&gamma})")
    if "`title'" == "" {
        local title "Threshold confidence set: `ylab' and the `=string(e(level),"%4.0f")'% critical value"
    }

    tempname P
    matrix `P' = e(profile)
    local cv   = e(cv)
    local ghat = e(gamma)
    local lo   = e(gamma_lo)
    local hi   = e(gamma_hi)
    local tv   "`e(threshold_var)'"

    preserve
    clear
    quietly svmat double `P', names(col)
    capture confirm variable gamma
    if _rc {
        restore
        display as error "stored profile matrix has unexpected column names"
        exit 198
    }
    tempvar yy
    if `col' == 3 quietly generate double `yy' = LR
    else          quietly generate double `yy' = LRstar
    quietly replace `yy' = . if `yy' >= .
    quietly summarize `yy', meanonly
    local ymax = r(max)
    local ytop = max(`ymax', `cv') * 1.08

    * shade the accepted region
    local shade ""
    if "`noci'" == "" & `lo' < . {
        tempvar lob upb
        quietly generate double `lob' = 0
        quietly generate double `upb' = `ytop' if gamma >= `lo' & gamma <= `hi'
        local shade (rarea `upb' `lob' gamma, color(gs14) lwidth(none))
    }

    twoway `shade'                                                      ///
        (line `yy' gamma, sort lcolor(navy) lwidth(medthick))           ///
        (function y = `cv', range(gamma) lcolor(cranberry)              ///
             lpattern(dash) lwidth(medium)),                            ///
        yscale(range(0 `ytop'))                                         ///
        ytitle("`ylab'") xtitle("`tv'")                                 ///
        title("`title'", size(medium))                                  ///
        subtitle("{&gamma}-hat = `=string(`ghat',"%10.0g")'   confidence set = [`=string(`lo',"%10.0g")', `=string(`hi',"%10.0g")']", size(small)) ///
        xline(`ghat', lcolor(black) lpattern(solid) lwidth(thin))        ///
        legend(order(2 "profile" 3 "critical value c = `=string(`cv',"%5.3f")'") ///
               rows(1) position(6) region(lstyle(none)) size(small))                ///
        graphregion(color(white)) plotregion(color(white) margin(zero))  ///
        note("Confidence set = {&gamma} where the profile lies below the dashed line." ///
             "Hansen (2000), Econometrica 68:575-603, Figures 2-3.", size(vsmall)) ///
        `options'
    if `"`saving'"' != "" _tk_gsave `saving'
    restore
end

* ----------------------------------------------------------------------
* Data and fitted regime lines against the threshold variable.
program define Regimeplot
    syntax [, SAVing(string asis) TItle(string asis) * ]
    local tv "`e(threshold_var)'"
    local dv "`e(depvar)'"
    local ghat = e(gamma)
    tempvar fit reg
    quietly predict double `fit' if e(sample), xb
    quietly generate byte `reg' = (`tv' <= `ghat') if e(sample)
    if "`title'" == "" local title "Fitted values by regime"
    twoway (scatter `dv' `tv' if `reg'==1, mcolor(navy%60) msymbol(O) msize(small))      ///
           (scatter `dv' `tv' if `reg'==0, mcolor(cranberry%60) msymbol(Oh) msize(small)) ///
           (line `fit' `tv' if `reg'==1, sort lcolor(navy) lwidth(medthick))              ///
           (line `fit' `tv' if `reg'==0, sort lcolor(cranberry) lwidth(medthick)),        ///
        xline(`ghat', lcolor(black) lpattern(dash))                                       ///
        ytitle("`dv'") xtitle("`tv'")                                                     ///
        title("`title'", size(medium))                                                    ///
        subtitle("threshold at `tv' = `=string(`ghat',"%10.0g")'", size(small))            ///
        legend(order(1 "regime 1 (`tv' {&le} `=string(`ghat',"%10.0g")')"                  ///
                     2 "regime 2 (`tv' > `=string(`ghat',"%10.0g")')")                     ///
               rows(1) position(6) region(lstyle(none)) size(small))                                   ///
        graphregion(color(white)) plotregion(color(white))                                 ///
        `options'
    if `"`saving'"' != "" _tk_gsave `saving'
end

* ----------------------------------------------------------------------
program define Regimes, rclass
    syntax [, ]
    local tv "`e(threshold_var)'"
    local ghat : display %10.0g e(gamma)
    local ghat = trim("`ghat'")
    display ""
    display as text "Regime summary after thregress" _col(50) "threshold variable: " as result "`tv'"
    display as text "{hline 78}"
    display as text "  Regime" _col(12) "definition" _col(36) "Obs" _col(45) "Share" ///
        _col(55) "SSR" _col(67) "sigma^2"
    display as text "{hline 78}"
    local n = e(N)
    display as text "      1" _col(12) "`tv' <= `ghat'" _col(33) as result %6.0fc e(N_regime1) ///
        _col(43) %6.3f e(N_regime1)/`n' _col(50) %10.0g e(ssr1) ///
        _col(63) %10.0g e(ssr1)/(e(N_regime1)-e(k_switch))
    display as text "      2" _col(12) "`tv' >  `ghat'" _col(33) as result %6.0fc e(N_regime2) ///
        _col(43) %6.3f e(N_regime2)/`n' _col(50) %10.0g e(ssr2) ///
        _col(63) %10.0g e(ssr2)/(e(N_regime2)-e(k_switch))
    display as text "{hline 78}"
    display as text "  Total" _col(33) as result %6.0fc `n' _col(43) %6.3f 1 ///
        _col(50) %10.0g e(ssr)
    display as text "{hline 78}"
    display as text "  No-threshold (pooled) SSR = " as result %10.0g e(ssr0) ///
        as text "   reduction = " as result %5.1f 100*(1-e(ssr)/e(ssr0)) as text "%"
    if e(ci_npoints) < . & e(ci_contiguous) == 0 {
        display as text "  {it:note}: the threshold confidence set is not an interval; see {bf:estat lrplot}."
    }
    return scalar N1 = e(N_regime1)
    return scalar N2 = e(N_regime2)
end

* ----------------------------------------------------------------------
* Two-step slope CIs: Hansen (2000) pp.585-586, the union of the per-regime
* Wald intervals over the rho-level threshold set.
program define Twostep, rclass
    syntax [, ]
    capture confirm matrix e(twostep1)
    if _rc {
        display as error "two-step intervals were not computed (ci(none) or a known threshold)"
        exit 198
    }
    * The driver computes these for ONE threshold only; with several it fills
    * them with missing. Without this guard the table printed a full column of
    * blanks under a footer asserting the intervals account for gamma
    * uncertainty -- a silent failure, and the worst kind, because the footer
    * made a claim about numbers that were not there.
    if e(nthresh) > 1 {
        display as error "{bf:estat twostep} is for a {bf:single} threshold."
        display as error "The union is taken over the confidence set for one"
        display as error "{bf:gamma}; with `=e(nthresh)' thresholds there is no single set"
        display as error "to take it over, and the interval for each threshold"
        display as error "already conditions on the others being known. Refit"
        display as error "with {bf:nthresh(1)} to use this."
        exit 198
    }
    tempname C1 C2
    matrix `C1' = e(twostep1)
    matrix `C2' = e(twostep2)
    if `C1'[1,1] >= . & `C1'[1,2] >= . {
        display as error "two-step intervals are missing for every regressor."
        display as error "This happens when the threshold confidence set is"
        display as error "empty or unbounded; {bf:estat lrplot} will show it."
        exit 198
    }
    local rho = e(rho)
    local lev = e(level)
    display ""
    display as text "Two-step confidence intervals for the slopes"
    display as text "Union over {&gamma} in the " as result %4.2f `rho' as text " threshold confidence set" ///
        as text "  (Hansen 2000, pp.585-586)"
    display as text "{hline 78}"
    display as text "             |" _col(20) "Regime 1" _col(48) "Regime 2"
    display as text "    Variable |" _col(16) "`lev'% lower    upper" _col(44) "`lev'% lower    upper"
    display as text "{hline 13}+{hline 64}"
    local names : rownames `C1'
    local i 0
    foreach v of local names {
        local ++i
        display as text %12s abbrev("`v'",12) " |" as result ///
            _col(16) %11.0g `C1'[`i',1] _col(28) %11.0g `C1'[`i',2] ///
            _col(44) %11.0g `C2'[`i',1] _col(56) %11.0g `C2'[`i',2]
    }
    display as text "{hline 78}"
    display as text "These are wider than the default table: they add the uncertainty about"
    display as text "{&gamma}, which the default intervals condition away (Hansen 2000, eq. 11)."
    return matrix twostep1 = `C1'
    return matrix twostep2 = `C2'
end

* ----------------------------------------------------------------------
* Heteroskedasticity diagnostics, including the REGIME-dependence test that
* Hansen (2000) Assumption 1.5 rules out.
program define Hettest, rclass
    syntax [, ]
    display ""
    display as text "Heteroskedasticity diagnostics after thregress"
    display as text "{hline 78}"
    display as text "  Breusch-Pagan/White on the pooled (no-threshold) fit   p = " ///
        as result %6.4f e(het_p_global)
    display as text "  Breusch-Pagan/White on the threshold fit               p = " ///
        as result %6.4f e(het_p_thresh)

    * regime-dependent variance: Hansen's Assumption 1.5 excludes it, and the
    * LR* confidence set is not justified when it fails.
    * Computed WITHOUT an estimation command: running regress here would
    * overwrite e() and destroy the thregress results the user is inspecting.
    * The two-group mean comparison on e^2 is algebraically the F test from
    * regressing e^2 on the regime dummy (F = t^2).
    tempvar e2 reg
    quietly predict double `e2' if e(sample), residuals
    quietly replace `e2' = `e2'^2
    quietly generate byte `reg' = (`e(threshold_var)' <= e(gamma)) if e(sample)
    quietly summarize `e2' if `reg' == 1
    local m1 = r(mean)
    local v1 = r(Var)
    local n1 = r(N)
    quietly summarize `e2' if `reg' == 0
    local m2 = r(mean)
    local v2 = r(Var)
    local n2 = r(N)
    local df = `n1' + `n2' - 2
    local sp = ((`n1'-1)*`v1' + (`n2'-1)*`v2') / `df'
    local se = sqrt(`sp' * (1/`n1' + 1/`n2'))
    local t  = cond(`se' > 0, (`m1' - `m2') / `se', 0)
    local pr = 2 * ttail(`df', abs(`t'))
    display as text "  Regime dependence of the error variance (F test)       p = " ///
        as result %6.4f `pr'
    display as text "{hline 78}"
    if `pr' < 0.05 {
        display as text "  {bf:Warning.} The error variance differs across regimes."
        display as text "  Hansen (2000) Assumption 1.5 (p.579) requires E(e{sup:2}|q) to be continuous"
        display as text "  at {&gamma}{sub:0} and so {bf:excludes} regime-dependent heteroskedasticity. The"
        display as text "  {&eta}{sup:2}-scaled LR* confidence set is then not justified by the theory."
        display as text "  Report the LR set as well (ci(lr)) and say so in the paper."
    }
    else {
        display as text "  No evidence against Assumption 1.5 (continuity of E(e{sup:2}|q) at {&gamma})."
    }
    return scalar p_regime = `pr'
    return scalar p_global = e(het_p_global)
end

* ----------------------------------------------------------------------
* Publication-ready regime comparison table.
program define Rtable, rclass
    syntax [, FORMat(string) ]
    if "`format'" == "" local format %9.4f
    local tv "`e(threshold_var)'"
    local ghat : display %10.0g e(gamma)
    local ghat = trim("`ghat'")
    tempname b V
    matrix `b' = e(b)
    matrix `V' = e(V)
    local names : colnames `b'
    local k = e(k_regime)
    display ""
    display as text "Threshold regression: `e(depvar)'"
    display as text "Threshold variable `tv'; threshold = `ghat' (`=string(e(level),"%2.0f")'% CI [" ///
        "`=string(e(gamma_lo),"%10.0g")', `=string(e(gamma_hi),"%10.0g")'])"
    display as text "{hline 70}"
    display as text _col(20) "Regime 1" _col(40) "Regime 2" _col(58) "difference"
    display as text _col(20) "`tv' <= `ghat'" _col(40) "`tv' > `ghat'"
    display as text "{hline 70}"
    local nk = e(k)
    local vn : colnames e(twostep1)
    local rn : rownames e(twostep1)
    local i 0
    foreach v of local rn {
        local ++i
        local b1 = `b'[1, `i']
        local b2 = `b'[1, `i' + `=rowsof(e(twostep1))']
        local s1 = sqrt(`V'[`i', `i'])
        local s2 = sqrt(`V'[`i' + `=rowsof(e(twostep1))', `i' + `=rowsof(e(twostep1))'])
        local df = `b1' - `b2'
        local sd = sqrt(`s1'^2 + `s2'^2)
        local z  = `df'/`sd'
        local st = cond(abs(`z')>2.576,"***",cond(abs(`z')>1.96,"**",cond(abs(`z')>1.645,"*","")))
        display as text %14s abbrev("`v'",14) as result ///
            _col(16) `format' `b1' _col(36) `format' `b2' _col(54) `format' `df' "`st'"
        display as text _col(16) as result "(" `format' `s1' ")" ///
            _col(36) "(" `format' `s2' ")" _col(54) "(" `format' `sd' ")"
    }
    display as text "{hline 70}"
    display as text "Observations" as result _col(16) %9.0fc e(N_regime1) _col(36) %9.0fc e(N_regime2) ///
        _col(54) %9.0fc e(N)
    display as text "SSR" as result _col(16) `format' e(ssr1) _col(36) `format' e(ssr2) ///
        _col(54) `format' e(ssr)
    display as text "{hline 70}"
    display as text "Standard errors in parentheses (`e(vcelab)'). The difference column is"
    display as text "the regime contrast with its standard error; * p<.10, ** p<.05, *** p<.01."
    if e(p) < . {
        display as text "Threshold test (`e(teststat)'-" cond("`e(vce)'"=="ols","F","LM") "): " ///
            as result %7.3f e(stat) as text ", bootstrap p = " as result %5.3f e(p) ///
            as text " (`e(boot_reps)' reps)."
    }
end

* ======================================================================
* estat gridboot -- the grid bootstrap confidence interval for the
* threshold (Hidalgo, Lee and Seo 2019; Hansen 1999 for the test-inversion
* idea).
*
* The interval thregress reports by default inverts the QLR statistic
* against ONE asymptotic critical value. Two things are wrong with that in
* a finite sample. The approximation is poor -- Hansen (2000) says so about
* his own interval -- and the error is not the same at every candidate
* threshold, so the interval can be too short at one end and too long at
* the other. This replaces the single number by a FUNCTION of gamma,
* obtained by bootstrapping the statistic under the hypothesis that the
* threshold IS gamma, and inverts the test pointwise.
*
* It is NOT a bootstrap for gamma-hat. Yu (2014) shows that resampling
* gamma-hat and reading off its quantiles is invalid, which is why
* thregress refuses ci(boot). Inverting a test whose null fixes gamma is
* valid, and that is what happens here.
* ======================================================================
program define Gridboot, rclass
    version 15
    syntax [, REPS(integer 99) POints(integer 9) Level(cilevel)    ///
              WILD(string) BWidth(real 0) SEED(string)              ///
              GRaph SAVing(string asis) * ]

    if `reps' < 20 {
        display as error "reps() below 20 cannot support a tail quantile:"
        display as error "the critical value would be the second or third"
        display as error "largest draw and would move with the seed"
        exit 198
    }
    if `points' < 3 {
        display as error "points() must be at least 3: the quantile function"
        display as error "is interpolated between the anchor points, and two"
        display as error "points can only draw a straight line through it"
        exit 198
    }
    if "`wild'" == "" local wild rademacher
    local wtypen = .
    if "`wild'" == "rademacher" local wtypen 1
    if "`wild'" == "normal"     local wtypen 2
    if "`wild'" == "mammen"     local wtypen 3
    if `wtypen' == . {
        display as error "wild() must be rademacher, normal or mammen"
        exit 198
    }
    if "`seed'" != "" set seed `seed'
    * the Mata driver reads npts; the option is called points(). Without this
    * line npts is MISSING, and in Mata a missing value is larger than any
    * number, so tk_ci_anchor's "npts >= G" test was true and it bootstrapped
    * EVERY grid point instead of points() of them -- correct answers, at
    * twenty times the cost.
    local npts = `points'

    if e(nthresh) > 1 {
        display as error "{bf:estat gridboot} is for a SINGLE threshold."
        display as error "With `=e(nthresh)' thresholds the statistic inverted here is not"
        display as error "the right one: each threshold would need its own"
        display as error "null with the others held fixed, and the joint"
        display as error "confidence set is not the product of the separate"
        display as error "intervals. Refit with one threshold to use this."
        exit 198
    }

    local depv  "`e(depvar)'"
    local zvars "`e(invariant)'"
    local trim   = e(trim)
    local gridn  = e(gridn)
    local hascons = e(hascons)
    local midpoint = cond("`e(point_est)'" == "midpoint", 1, 0)
    local wascmd "`e(cmd)'"
    local arl    "`e(arlags)'"
    local dly    = e(delay)
    local emodel "`e(model)'"
    local qname  "`e(threshold_var)'"
    local xstore "`e(indepvars)'"

    tempvar touse
    quietly generate byte `touse' = e(sample)

    * ---- the design.
    *
    * After thregress the switching regressors are real variables and
    * e(indepvars) names them. After thtar they are NOT: thtar builds the
    * lags as tempvars, calls thregress on them, and those tempvars are gone
    * by the time any estat runs, so e(indepvars) holds names like __000002
    * that no longer exist. Rebuilding them from e(arlags) and e(delay) is
    * the only way this can work after thtar, and it is exact -- the lags are
    * a deterministic function of the dependent variable.
    if "`wascmd'" == "thtar" {
        if "`arl'" == "" {
            display as error "{bf:estat gridboot} cannot rebuild the design:"
            display as error "{bf:e(arlags)} is empty"
            exit 498
        }
        local xvars ""
        foreach j of local arl {
            tempvar a`j'
            quietly generate double `a`j'' = L`j'.`depv' if `touse'
            local xvars `xvars' `a`j''
        }
        if "`emodel'" == "setar" {
            * the threshold variable is the delay-th lag of the series
            tempvar qv
            quietly generate double `qv' = L`dly'.`depv' if `touse'
            local qvar `qv'
            local qname "L`dly'.`depv'"
            * q is among the regressors exactly when the delay is one of the
            * autoregressive lags, which for a SETAR is a real and checkable
            * condition rather than a matter of the user's variable list
            local qinx = 0
            foreach j of local arl {
                if `j' == `dly' local qinx = 1
            }
        }
        else {
            * thvar() was used, so the threshold variable is a real variable
            * (possibly time-series operated); resolve it to something the
            * Mata driver can read
            capture tsrevar `qname'
            if _rc {
                display as error "{bf:estat gridboot} cannot resolve the"
                display as error "threshold variable {bf:`qname'}"
                exit 498
            }
            local qvar "`r(varlist)'"
            local qinx = 0
        }
        markout `touse' `xvars' `qvar'
    }
    else {
        local xvars "`xstore'"
        capture tsrevar `qname'
        local qvar = cond(_rc, "`qname'", "`r(varlist)'")
        * every stored name must still exist, or the Mata driver would fail
        * with a bare st_data() error that says nothing useful
        local missv ""
        foreach v of local xvars {
            capture confirm numeric variable `v'
            if _rc local missv `missv' `v'
        }
        capture confirm numeric variable `qvar'
        if _rc local missv `missv' `qvar'
        if "`missv'" != "" {
            local nmiss : word count `missv'
            display as error "{bf:estat gridboot} needs the fitted design, and"
            display as error "`nmiss' of its variable(s) no longer exist."
            display as error "That happens when the regressors were temporary."
            display as error "Create them as permanent variables and refit."
            exit 498
        }
        * ---- is the kink case nested? The robustness claim rests on it.
        *      If q is not among the switching regressors there is no
        *      continuous alternative inside the model, so the rescaling has
        *      nothing to adapt to. Say so rather than letting the user infer
        *      a robustness the model does not have.
        local qinx = 0
        foreach v of local xvars {
            if "`v'" == "`qvar'" local qinx = 1
        }
    }

    mata: tk_thgridboot()

    if __tk_gbfail == 1 {
        _tk_drop
        display as error "the trimmed grid has fewer than 3 points"
        exit 498
    }
    if __tk_gbfail == 2 {
        _tk_drop
        display as error "the model could not be refitted on the stored sample"
        exit 498
    }
    if __tk_gbfail == 3 {
        _tk_drop
        display as error "the scale factor xi could not be estimated. That"
        display as error "usually means the fitted jump is numerically zero,"
        display as error "in which case the threshold is not identified and"
        display as error "no interval for it is meaningful. Check"
        display as error "{bf:estat profile} and the no-threshold test first."
        exit 498
    }
    if __tk_gbfail == 4 {
        _tk_drop
        display as error "fewer than two anchor points produced a usable"
        display as error "bootstrap quantile; raise {bf:reps()}"
        exit 498
    }

    tempname PATH ANCH GH XI LO HI CT ALO AHI ACT ACV NN NG NA NF
    matrix `PATH' = __tk_gbpath
    matrix `ANCH' = __tk_gbanch
    scalar `GH'  = __tk_gbgamma
    scalar `XI'  = __tk_gbxi
    scalar `LO'  = __tk_gblo
    scalar `HI'  = __tk_gbhi
    scalar `CT'  = __tk_gbcontig
    scalar `ALO' = __tk_gbalo
    scalar `AHI' = __tk_gbahi
    scalar `ACT' = __tk_gbacontig
    scalar `ACV' = __tk_gbacv
    scalar `NN'  = __tk_gbn
    scalar `NG'  = __tk_gbng
    scalar `NA'  = __tk_gbnanch
    scalar `NF'  = __tk_gbnfail
    _tk_drop

    matrix colnames `PATH' = gamma lr_star cv_boot accepted
    matrix colnames `ANCH' = gamma cv_boot

    display _n as text "Grid bootstrap confidence interval for the threshold"
    display as text "{hline 72}"
    display as text "  observations" _col(50) as result %20.0f `NN'
    display as text "  grid points inverted" _col(50) as result %20.0f `NG'
    display as text "  anchor points bootstrapped" _col(50) as result %20.0f `NA'
    display as text "  replications at each anchor" _col(50) as result %20.0f `reps'
    display as text "  multipliers" _col(50) as result %20s "`wild'"
    display as text "  confidence level" _col(50) as result %20.0f `level'
    display as text "{hline 72}"
    display as text "  threshold estimate" _col(50) as result %20.6g `GH'
    display as text "  scale factor xi-hat" _col(50) as result %20.6g `XI'
    display as text "{hline 72}"
    display as text "  grid bootstrap interval" _col(44) ///
        as result %12.6g `LO' "  " %12.6g `HI'
    display as text "  asymptotic interval (same statistic)" _col(44) ///
        as result %12.6g `ALO' "  " %12.6g `AHI'
    display as text "  asymptotic critical value" _col(50) as result %20.6g `ACV'
    display as text "{hline 72}"

    if `CT' == 0 {
        display as text "  The bootstrap confidence SET is not an interval: at"
        display as text "  least one threshold strictly inside the reported"
        display as error "  range was rejected."
        display as text "  Read the accepted column of r(path) rather than the"
        display as text "  two endpoints. A set with holes is a real finding --"
        display as text "  it means the criterion has more than one local"
        display as text "  minimum, which usually points to more than one"
        display as text "  threshold ({helpb thselect}) or to weak"
        display as text "  identification."
    }
    if `ACT' == 0 {
        display as text "  (the asymptotic set has holes too)"
    }

    if `NF' > 0 {
        display as text "  `=`NF'' anchor point(s) produced no usable quantile and"
        display as text "  were dropped before interpolation."
    }

    display _n as text "  The two intervals answer the same question with"
    display as text "  different critical values. If they disagree materially,"
    display as text "  prefer this one: the asymptotic value is a single number"
    display as text "  for every gamma, and its error is known not to be"
    display as text "  uniform in gamma."
    display as text ""
    if `qinx' {
        display as text "  {bf:Valid under a kink as well as a jump.} The threshold"
        display as text "  variable is among the switching regressors, so the"
        display as text "  continuous (kink) specification is nested in the"
        display as text "  model fitted. Hidalgo, Lee and Seo (2019) show the"
        display as text "  QLR statistic has the same limit in both cases up to"
        display as text "  the scale factor above, and that xi-hat converges to"
        display as text "  the right factor either way without being told"
        display as text "  which. So this interval does not require you to"
        display as text "  decide first whether the mean jumps or kinks."
    }
    else {
        display as text "  {bf:This interval assumes a JUMP.} The threshold"
        display as text "  variable (`qname') is NOT among the switching"
        display as text "  regressors, so the continuous (kink) specification"
        display as text "  is not nested in what was fitted and there is"
        display as text "  nothing for the scale factor to adapt to. To get"
        display as text "  the kink-robust interval, include `qname' in the"
        display as text "  switching regressors and refit. If you are"
        display as text "  confident the relationship is continuous, fit"
        display as text "  {helpb thkink} instead, where gamma is root-n"
        display as text "  normal and a Wald interval applies."
    }
    display as text ""
    display as text "  The threshold still has no standard error under either"
    display as text "  specification: its limit distribution is not normal in"
    display as text "  the jump case and the convergence rate is the cube root"
    display as text "  in the kink case. Report the interval, never an"
    display as text "  estimate plus or minus something."

    return scalar gamma    = `GH'
    return scalar xi       = `XI'
    return scalar lo       = `LO'
    return scalar hi       = `HI'
    return scalar contiguous = `CT'
    return scalar lo_asym  = `ALO'
    return scalar hi_asym  = `AHI'
    return scalar contiguous_asym = `ACT'
    return scalar cv_asym  = `ACV'
    return scalar N        = `NN'
    return scalar n_grid   = `NG'
    return scalar n_anchor = `NA'
    return scalar reps     = `reps'
    return scalar level    = `level'
    return scalar kink_nested = `qinx'
    return local  wild     "`wild'"
    return matrix anchors  = `ANCH', copy
    return matrix path     = `PATH', copy

    if "`graph'" != "" {
        preserve
            quietly {
                clear
                svmat double `PATH', names(gb)
                keep if gb1 < .
                label variable gb1 "threshold"
                label variable gb2 "rescaled QLR"
                label variable gb3 "bootstrap critical value"
                generate double gbacv = `ACV'
            }
            twoway (line gb2 gb1, lcolor(navy) lwidth(medthick))        ///
                   (line gb3 gb1, lcolor(cranberry) lpattern(dash))     ///
                   (line gbacv gb1, lcolor(gs8) lpattern(shortdash))    ///
                 , xline(`=`GH'', lcolor(gs10))                         ///
                   xtitle("candidate threshold")                        ///
                   ytitle("QLR / xi-hat")                               ///
                   title("Grid bootstrap test inversion")               ///
                   subtitle("accepted where the solid line is below the dashed one") ///
                   legend(order(1 "QLR / xi-hat" 2 "bootstrap c.v."     ///
                                3 "asymptotic c.v.") rows(1) size(small)) ///
                   `options'
            if `"`saving'"' != "" _tk_gsave `saving'
        restore
    }
end

* ======================================================================
* estat eqtest -- Chow-type Wald tests that a coefficient, or the whole
* coefficient vector, is the SAME in every regime.
*
* READ THE CAVEAT. This conditions on gamma-hat. Under the null of NO
* threshold the threshold is not identified, so this Wald statistic does
* NOT have a chi-squared distribution and a small p-value here is not
* evidence against linearity. The test that answers that question is
* thtest (or thtar, test), which bootstraps the sup over the whole grid.
*
* What this IS good for: given that a threshold exists, which coefficients
* actually move across it. That is a different and often more interesting
* question than "is anything nonlinear", and the coefficient table only
* answers it informally, one regime at a time, without a joint test.
* ======================================================================
program define Eqtest, rclass
    version 15
    syntax [, Level(cilevel) NOJoint ]

    tempname B V
    matrix `B' = e(b)
    matrix `V' = e(V)
    local k = colsof(`B')
    if `k' < 2 {
        display as error "nothing to compare"
        exit 498
    }

    local eqs : coleq `B'
    local nms : colnames `B'

    * the distinct regime equations, in the order they appear
    local regs ""
    foreach e of local eqs {
        local seen : list e in regs
        if !`seen' local regs `regs' `e'
    }
    local nreg : word count `regs'
    if `nreg' < 2 {
        display as error "{bf:estat eqtest} needs at least two regime"
        display as error "equations in e(b); this fit has `nreg'"
        exit 498
    }

    * the distinct coefficient names, in the order they appear
    local cns ""
    forvalues j = 1/`k' {
        local c : word `j' of `nms'
        local seen : list c in cns
        if !`seen' local cns `cns' `c'
    }

    display _n as text "Regime equality tests (conditional on the estimated threshold)"
    display as text "{hline 72}"
    display as text "  regimes compared" _col(50) as result %20.0f `nreg'
    display as text "{hline 72}"
    display as text "  coefficient" _col(30) "chi2" _col(44) "df" _col(56) "p"
    display as text "{hline 72}"

    local allcon ""
    local nc = 0
    foreach c of local cns {
        * build the equality constraints for this coefficient across regimes
        local r1 : word 1 of `regs'
        local con ""
        local nin = 0
        forvalues i = 2/`nreg' {
            local ri : word `i' of `regs'
            * both sides must actually exist in e(b)
            if colnumb(`B', "`r1':`c'") < . & colnumb(`B', "`ri':`c'") < . {
                local con `"`con' (["`r1'"]`c' = ["`ri'"]`c')"'
                local nin = `nin' + 1
            }
        }
        if `nin' == 0 continue
        capture quietly test `con'
        if _rc {
            display as text "  " %-26s "`c'" as text "   (not testable)"
            continue
        }
        local nc = `nc' + 1
        display as text "  " %-26s "`c'" ///
            as result %12.4f r(chi2) %8.0f r(df) %12.4f r(p)
        return scalar chi2_`nc' = r(chi2)
        return scalar p_`nc'    = r(p)
        local allcon `"`allcon' `con'"'
        local lastname "`c'"
    }
    display as text "{hline 72}"

    if "`nojoint'" == "" & `"`allcon'"' != "" {
        capture quietly test `allcon'
        if !_rc {
            display as text "  JOINT: every coefficient equal in every regime"
            display as text "    chi2(" as result r(df) as text ") = " ///
                as result %10.4f r(chi2) as text "    p = " ///
                as result %8.4f r(p)
            return scalar chi2 = r(chi2)
            return scalar df   = r(df)
            return scalar p    = r(p)
        }
        else {
            display as error "  the joint test could not be formed"
        }
        display as text "{hline 72}"
    }

    display as text "  {bf:These condition on the estimated threshold.} Under the"
    display as text "  null of NO threshold the threshold is not identified, so"
    display as text "  this Wald statistic is {bf:not} chi-squared and a small"
    display as text "  p-value here is {bf:not} evidence against linearity. For"
    display as text "  that question use {helpb thtest} (or {bf:thtar, test}),"
    display as text "  which bootstraps the sup over the whole grid."
    display as text ""
    display as text "  What these answer is the other question: GIVEN that a"
    display as text "  threshold is there, which coefficients actually move"
    display as text "  across it. A model in which only one coefficient"
    display as text "  switches is a much stronger claim than one in which"
    display as text "  everything does, and it is worth reporting which."

    return local  regimes "`regs'"
    return local  coefs   "`cns'"
    return scalar n_regime = `nreg'
end

* ======================================================================
* estat girf -- the generalised impulse response of Koop, Pesaran and
* Potter (1996) for a UNIVARIATE threshold model.
*
* A nonlinear model has no single impulse response. The response depends on
* the HISTORY the shock arrives into, on the SIGN of the shock, and on its
* SIZE -- responses do not scale. So the object simulated here is
*
*   GIRF(h, delta, omega) = E[y_t+h | e_t = delta, omega] - E[y_t+h | omega]
*
* with both expectations simulated and the two paths sharing the SAME
* future shocks. Without those common random numbers the difference of two
* independent averages would be swamped by Monte Carlo error.
*
* Three responses are reported together, and the comparison is the point:
* the response to +delta, the response to -delta, and the response split by
* the regime the shock arrives into. In a LINEAR model the first two would
* be exact mirror images and the last two identical. Where they are not,
* that difference IS the nonlinearity.
* ======================================================================
program define Ugirf, rclass
    version 15
    syntax [, SIZE(real 1) Horizon(integer 12) REPS(integer 200)       ///
              HISTories(integer 150) BOOT(string) SEED(string)          ///
              GRaph SAVing(string asis) * ]

    if `horizon' < 1 {
        display as error "horizon() must be at least 1"
        exit 198
    }
    if `reps' < 20 {
        display as error "reps() below 20 cannot average out the shock draws"
        exit 198
    }
    if "`boot'" == "" local boot resample
    if !inlist("`boot'", "resample", "normal") {
        display as error "boot() must be resample or normal"
        exit 198
    }
    local boottype `boot'
    if "`seed'" != "" set seed `seed'

    local depv  "`e(depvar)'"
    local hascons = e(hascons)
    tempvar touse
    quietly generate byte `touse' = e(sample)

    * ---- which model, and its pieces
    tempname BB
    matrix `BB' = e(b)
    local kindn = .
    if inlist("`e(cmd)'", "thtar") & "`e(model)'" != "setar_continuous" {
        local kindn 1
    }
    if inlist("`e(cmd)'", "thstar", "thstr") local kindn 2
    if `kindn' == . {
        display as error "{bf:estat girf} is for {bf:thtar} (SETAR) and"
        display as error "{bf:thstar} (STAR). After {bf:thtar, continuous}"
        display as error "the model is a kink, not a regime switch, and its"
        display as error "response is not computed here."
        exit 198
    }

    * ---- the delay must be a MODEL lag, or the system cannot simulate its
    *      own transition variable forward and the GIRF is not defined
    local delayn = e(delay)
    if `delayn' >= . | `delayn' <= 0 {
        display as error "{bf:estat girf} needs a self-exciting model: the"
        display as error "transition variable must be a lag of the dependent"
        display as error "variable, so that the simulation can compute it"
        display as error "forward. This fit used an exogenous threshold"
        display as error "variable, whose future path is unknown, and"
        display as error "freezing it would answer a different question."
        exit 198
    }

    local arl "`e(arlags)'"
    if "`arl'" == "" {
        display as error "{bf:e(arlags)} is empty; refit"
        exit 498
    }
    local maxlag = 0
    foreach L of local arl {
        if `L' > `maxlag' local maxlag = `L'
    }
    if `delayn' > `maxlag' {
        display as error "the delay (`delayn') exceeds the largest"
        display as error "autoregressive lag (`maxlag'), so the transition"
        display as error "variable is not part of the state the model"
        display as error "propagates and cannot be simulated forward."
        exit 198
    }

    * ---- the coefficient matrix, one row per regime (SETAR) or the linear
    *      and transition blocks (STAR), columns in the order the simulator
    *      builds its regressor row: the ar() lags then the constant
    local nl : word count `arl'
    local kw = `nl' + `hascons'
    tempname UB
    if `kindn' == 1 {
        local nreg = e(k_regime)
        local nrow = colsof(`BB')/`kw'
        matrix `UB' = J(`nrow', `kw', 0)
        forvalues r = 1/`nrow' {
            forvalues j = 1/`kw' {
                matrix `UB'[`r',`j'] = `BB'[1, (`r'-1)*`kw' + `j']
            }
        }
        tempname GG
        capture confirm matrix e(gammas)
        if !_rc  matrix `GG' = e(gammas)
        else {
            matrix `GG' = J(1,1,0)
            matrix `GG'[1,1] = e(gamma)
        }
        local gammav = e(gamma)
        local c1v = 0
        local c2v = 0
        local typen = 1
        local szv = 1
    }
    else {
        matrix `UB' = J(2, `kw', 0)
        forvalues j = 1/`kw' {
            matrix `UB'[1,`j'] = `BB'[1, `j']
            matrix `UB'[2,`j'] = `BB'[1, `kw' + `j']
        }
        tempname GG
        matrix `GG' = J(1,1,0)
        local gammav = e(gamma)
        local c1v  = e(c)
        local c2v  = cond(e(c2) < ., e(c2), 0)
        local typen = e(typenum)
        local szv  = cond(e(zscale) < ., e(zscale), 1)
        matrix `GG'[1,1] = `c1v'
    }

    * ---- the lag list as a matrix for the engine
    tempname LAGS
    matrix `LAGS' = J(1, `nl', 0)
    local j 0
    foreach L of local arl {
        local ++j
        matrix `LAGS'[1,`j'] = `L'
    }

    * ---- the residuals: the shock pool
    tempvar resv
    capture quietly predict double `resv' if `touse', residuals
    if _rc {
        display as error "could not recover the residuals for the shock pool"
        exit 498
    }
    quietly replace `touse' = 0 if missing(`resv')

    local deltav = `size'
    matrix __tk_ugB    = `UB'
    matrix __tk_uglags = `LAGS'
    matrix __tk_uggam  = `GG'
    local maxhist = `histories'
    local resvar "`resv'"

    mata: tk_thugirf()

    if __tk_ugfail == 1 {
        _tk_drop
        display as error "the residual standard deviation is zero or missing"
        exit 498
    }
    if __tk_ugfail == 2 {
        _tk_drop
        display as error "too few usable histories to average over"
        exit 498
    }

    tempname G N1 N2 NH SIG
    matrix `G' = __tk_uggirf
    scalar `N1' = __tk_ugn1
    scalar `N2' = __tk_ugn2
    scalar `NH' = __tk_ugnh
    scalar `SIG' = __tk_ugsig
    _tk_drop
    matrix colnames `G' = h pos neg regime1 regime2

    display _n as text "Generalised impulse response (Koop-Pesaran-Potter)"
    display as text "{hline 74}"
    display as text "  shock size" _col(50) as result %20.4f `deltav'
    display as text "  residual s.d. for comparison" _col(50) as result %20.4f `SIG'
    display as text "  horizons" _col(50) as result %20.0f `horizon'
    display as text "  replications per history" _col(50) as result %20.0f `reps'
    display as text "  histories averaged" _col(50) as result %20.0f `NH'
    display as text "    of which regime 1 / regime 2" _col(50) ///
        as result %10.0f `N1' %10.0f `N2'
    display as text "  shock pool" _col(50) as result %20s "`boot'"
    display as text "{hline 74}"
    display as text "     h      to +delta     to -delta    from reg 1    from reg 2"
    display as text "{hline 74}"
    forvalues i = 1/`=rowsof(`G')' {
        display as text %6.0f `G'[`i',1] ///
            as result %14.6f `G'[`i',2] %14.6f `G'[`i',3] ///
            %14.6f `G'[`i',4] %14.6f `G'[`i',5]
    }
    display as text "{hline 74}"
    display as text "  {bf:Read the columns against each other, not alone.}"
    display as text "  In a LINEAR model the first two would be exact mirror"
    display as text "  images and the last two identical. Where they are not,"
    display as text "  that difference IS the nonlinearity, and it is the only"
    display as text "  part of this table a linear model could not produce."
    display as text ""
    display as text "  Responses here do NOT scale: the answer to a shock of"
    display as text "  2 sigma is not twice the answer to 1 sigma. Report the"
    display as text "  size you used, and if the conclusion matters, report"
    display as text "  more than one."

    return matrix girf = `G', copy
    return scalar size     = `deltav'
    return scalar horizon  = `horizon'
    return scalar reps     = `reps'
    return scalar n_hist   = `NH'
    return scalar n_hist1  = `N1'
    return scalar n_hist2  = `N2'
    return scalar sigma    = `SIG'
    return local  boot     "`boottype'"

    if "`graph'" != "" {
        preserve
            quietly {
                clear
                svmat double `G', names(gi)
                keep if gi1 < .
            }
            twoway (line gi2 gi1, lcolor(navy) lwidth(medthick))           ///
                   (line gi3 gi1, lcolor(cranberry) lpattern(dash))        ///
                   (line gi4 gi1, lcolor(forest_green) lpattern(shortdash)) ///
                   (line gi5 gi1, lcolor(orange) lpattern(longdash))       ///
                 , yline(0, lcolor(gs10))                                  ///
                   xtitle("horizon") ytitle("response")                    ///
                   title("Generalised impulse response")                   ///
                   subtitle("shock size `=string(`deltav',"%6.3f")'", size(small)) ///
                   legend(order(1 "+delta" 2 "-delta" 3 "from regime 1"    ///
                                4 "from regime 2") rows(2) size(small))    ///
                   `options'
            if `"`saving'"' != "" _tk_gsave `saving'
        restore
    }
end

* ======================================================================
* estat skeleton -- the DETERMINISTIC SKELETON of the fitted model, its
* per-regime roots, and the limit cycle it settles into if it has one.
*
*   Tong and Lim (1980) JRSS-B 42:245-292,
*     doi:10.1111/j.2517-6161.1980.tb01126.x
*
* The skeleton is the model iterated forward with the errors set to ZERO.
* It is the model's own dynamics with the noise stripped out, and it is
* where the interesting nonlinear behaviour lives: a threshold model can
* settle to a point, cycle forever between a few values, or diverge, and
* which of those it does is a property of the coefficients that no amount of
* staring at the coefficient table reveals.
*
* THREE THINGS THIS REPORTS, AND WHY EACH MATTERS
*
* 1. The per-regime roots. Each regime is a linear AR, so it has its own
*    companion eigenvalues. A regime with a modulus of 1 or more is LOCALLY
*    EXPLOSIVE -- and that is not a defect of the fit: a threshold model can
*    be globally stationary with an explosive inner regime, because the
*    system is thrown out of it before it can run away. Reporting the roots
*    without saying this invites the reader to conclude the model is broken.
*
* 2. The skeleton's long-run behaviour, found by iterating. A FIXED POINT
*    means the deterministic model converges; a LIMIT CYCLE of period k
*    means it settles into k repeating values and never converges. Tong's
*    whole point was that threshold models produce limit cycles, which a
*    linear model cannot.
*
* 3. The half-life of a shock, measured on the skeleton from each regime
*    separately. In a linear model the half-life is one number. In a
*    threshold model it is not, and the difference between the regimes is
*    usually the economically interesting quantity.
*
* The skeleton is NOT a forecast. Clements and Smith (1997) show the
* deterministic path differs from E[y_t+h] for a nonlinear model, and the
* gap does not shrink with the sample. For forecasts use thforecast, which
* says the same thing in its own output.
* ======================================================================
program define Skeleton, rclass
    version 15
    syntax [, Horizon(integer 60) TOLerance(real 1e-8) MAXCycle(integer 24) ///
              START(numlist) GRaph SAVing(string asis) * ]

    if `horizon' < 10 {
        display as error "horizon() must be at least 10 for the skeleton to"
        display as error "settle"
        exit 198
    }

    local depv  "`e(depvar)'"
    local arl   "`e(arlags)'"
    local hascons = e(hascons)
    local delayn  = e(delay)

    local kindn = .
    if "`e(cmd)'" == "thtar" & "`e(model)'" != "setar_continuous" local kindn 1
    if inlist("`e(cmd)'", "thstar", "thstr") local kindn 2
    if `kindn' == . {
        display as error "{bf:estat skeleton} is for {bf:thtar} (SETAR) and"
        display as error "{bf:thstar} (STAR)."
        exit 198
    }
    if "`arl'" == "" | `delayn' >= . | `delayn' <= 0 {
        display as error "{bf:estat skeleton} needs a self-exciting model:"
        display as error "the transition variable must be a lag of the"
        display as error "dependent variable, or there is no autonomous"
        display as error "recursion to iterate."
        exit 198
    }

    local nl : word count `arl'
    local maxlag = 0
    foreach L of local arl {
        if `L' > `maxlag' local maxlag = `L'
    }
    local kw = `nl' + `hascons'

    * ---- the coefficient matrix in the simulator's column order
    tempname BB UB LAGS GG
    matrix `BB' = e(b)
    if `kindn' == 1 {
        local nrow = colsof(`BB')/`kw'
        matrix `UB' = J(`nrow', `kw', 0)
        forvalues r = 1/`nrow' {
            forvalues j = 1/`kw' {
                matrix `UB'[`r',`j'] = `BB'[1, (`r'-1)*`kw' + `j']
            }
        }
        matrix `GG' = J(1,1,0)
        matrix `GG'[1,1] = e(gamma)
        local gammav = e(gamma)
        local c1v = 0
        local c2v = 0
        local typen = 1
        local szv = 1
    }
    else {
        matrix `UB' = J(2, `kw', 0)
        forvalues j = 1/`kw' {
            matrix `UB'[1,`j'] = `BB'[1, `j']
            matrix `UB'[2,`j'] = `BB'[1, `kw' + `j']
        }
        matrix `GG' = J(1,1,0)
        local gammav = e(gamma)
        local c1v  = e(c)
        local c2v  = cond(e(c2) < ., e(c2), 0)
        local typen = e(typenum)
        local szv  = cond(e(zscale) < ., e(zscale), 1)
        matrix `GG'[1,1] = `c1v'
    }
    matrix `LAGS' = J(1, `nl', 0)
    local j 0
    foreach L of local arl {
        local ++j
        matrix `LAGS'[1,`j'] = `L'
    }

    * ---- starting value: the user's, or the sample mean of the series
    if "`start'" == "" {
        quietly summarize `depv' if e(sample), meanonly
        local y0 = r(mean)
        local startsrc "the sample mean"
    }
    else {
        local y0 : word 1 of `start'
        local startsrc "user supplied"
    }

    matrix __tk_skB    = `UB'
    matrix __tk_sklags = `LAGS'
    matrix __tk_skgam  = `GG'
    local maxlagn = `maxlag'

    mata: tk_thskel()

    if __tk_skfail == 1 {
        _tk_drop
        display as error "the coefficient matrix could not be read"
        exit 498
    }

    tempname PATH ROOTS FIX CYC MOD1 MOD2 HL1 HL2 DIV
    matrix `PATH'  = __tk_skpath
    matrix `ROOTS' = __tk_skroots
    scalar `FIX'  = __tk_skfix
    scalar `CYC'  = __tk_skcyc
    scalar `MOD1' = __tk_skmod1
    scalar `MOD2' = __tk_skmod2
    scalar `HL1'  = __tk_skhl1
    scalar `HL2'  = __tk_skhl2
    scalar `DIV'  = __tk_skdiv
    _tk_drop
    matrix colnames `PATH'  = t y
    matrix colnames `ROOTS' = regime modulus

    display _n as text "Deterministic skeleton of the fitted model"
    display as text "{hline 72}"
    display as text "  iterated from" _col(46) as result %24s "`startsrc'"
    display as text "  starting value" _col(46) as result %24.6f `y0'
    display as text "  horizons iterated" _col(46) as result %24.0f `horizon'
    display as text "{hline 72}"
    display as text "  largest root modulus, regime 1" _col(46) ///
        as result %24.6f `MOD1'
    display as text "  largest root modulus, regime 2" _col(46) ///
        as result %24.6f `MOD2'
    display as text "{hline 72}"

    if `DIV' == 1 {
        display as error "  The skeleton DIVERGES from this starting value."
        display as text  "  That does not by itself mean the model is"
        display as text  "  misspecified: a threshold model can be globally"
        display as text  "  stationary with a locally explosive regime,"
        display as text  "  because the system is thrown out of that regime"
        display as text  "  before it can run away. But check the regime"
        display as text  "  moduli above, and try other starting values with"
        display as text  "  {bf:start()} -- divergence from every start is a"
        display as text  "  different matter from divergence from one."
    }
    else if `CYC' > 1 {
        display as text "  The skeleton settles into a {bf:LIMIT CYCLE} of"
        display as text "  period " as result `CYC' as text "."
        display as text ""
        display as text "  This is what Tong's work was about, and a linear"
        display as text "  model CANNOT produce it: the deterministic path"
        display as text "  does not converge to a point but repeats " ///
            as result `CYC' as text " values"
        display as text "  forever. If your series shows persistent cycles"
        display as text "  that a linear model fits only with a long lag"
        display as text "  structure, this is the mechanism to report."
    }
    else if `FIX' < . {
        display as text "  The skeleton converges to a {bf:FIXED POINT} at"
        display as text "  y = " as result %12.6f `FIX'
        display as text ""
        display as text "  The deterministic model settles, so the series'"
        display as text "  movement comes from the shocks rather than from"
        display as text "  the model's own dynamics."
    }
    else {
        display as text "  The skeleton neither converged nor closed a cycle"
        display as text "  within `horizon' steps and did not diverge. Raise"
        display as text "  {bf:horizon()} or {bf:maxcycle()}; a long cycle"
        display as text "  needs both."
    }

    display as text "{hline 72}"
    display as text "  half-life of a shock on the skeleton:"
    if `HL1' < . display as text "    starting in regime 1" _col(46) ///
        as result %24.2f `HL1'
    else         display as text "    starting in regime 1" _col(46) ///
        as result %24s "does not halve"
    if `HL2' < . display as text "    starting in regime 2" _col(46) ///
        as result %24.2f `HL2'
    else         display as text "    starting in regime 2" _col(46) ///
        as result %24s "does not halve"
    display as text "{hline 72}"
    display as text "  In a LINEAR model the half-life is one number. Here it"
    display as text "  is not, and the difference between the regimes is"
    display as text "  usually the economically interesting quantity -- it is"
    display as text "  how long the system takes to forget a shock depending"
    display as text "  on where it was when the shock arrived."
    display as text ""
    display as text "  {bf:The skeleton is not a forecast.} Clements and Smith"
    display as text "  (1997) show the deterministic path differs from"
    display as text "  E[y(t+h)] for a nonlinear model, and the gap does not"
    display as text "  shrink with the sample. Use {helpb thforecast} for"
    display as text "  forecasts; it simulates, and says so."

    return matrix path  = `PATH', copy
    return matrix roots = `ROOTS', copy
    return scalar modulus1 = `MOD1'
    return scalar modulus2 = `MOD2'
    return scalar fixedpoint = `FIX'
    return scalar cycle    = `CYC'
    return scalar halflife1 = `HL1'
    return scalar halflife2 = `HL2'
    return scalar diverges = `DIV'
    return scalar start    = `y0'

    if "`graph'" != "" {
        preserve
            quietly {
                clear
                svmat double `PATH', names(sk)
                keep if sk1 < .
            }
            twoway (line sk2 sk1, lcolor(navy) lwidth(medthick))     ///
                 , xtitle("iteration") ytitle("`depv'")              ///
                   title("Deterministic skeleton")                   ///
                   subtitle(`"`=cond(`CYC'>1, "limit cycle of period " + string(`CYC'), cond(`DIV'==1, "diverges", "converges to a fixed point"))'"', size(small)) ///
                   `options'
            if `"`saving'"' != "" _tk_gsave `saving'
        restore
    }
end

* ======================================================================
* estat hac -- heteroskedasticity- and autocorrelation-consistent standard
* errors for the regime coefficients, conditional on the estimated
* threshold.
*
*   Newey and West (1987) Econometrica 55:703-708, doi:10.2307/1913610
*   Andrews (1991) Econometrica 59:817-858, doi:10.2307/2938229
*
* The package's vce(robust) is HC: it lets the error variance differ across
* observations but assumes they are UNCORRELATED. On a time series that is
* usually wrong, and a threshold model is fitted to time series more often
* than not. Serially correlated errors leave the coefficients consistent
* and make the HC standard errors too small -- often badly so, and always
* in the direction that makes a result look stronger than it is.
*
* WHAT THIS DOES NOT FIX. These are the standard errors of the SLOPES
* conditional on gamma-hat. They carry no uncertainty about the threshold.
* A HAC standard error is not a licence to treat the threshold as known; it
* only stops the slope's own standard error being wrong for a second,
* separate reason. For the threshold use estat gridboot; for slope
* intervals that do not condition on gamma-hat use estat twostep.
* ======================================================================
program define Hac, rclass
    version 15
    syntax [, LAGS(integer -1) RULE(string) NODFadj Level(cilevel) ]

    if "`rule'" == "" local rule neweywest
    if !inlist("`rule'", "neweywest", "nw", "andrews") {
        display as error "rule() must be neweywest or andrews"
        exit 198
    }
    local rulen = cond("`rule'"=="andrews", 2, 1)
    if `lags' >= 0 {
        local rulen 0
        local laglen `lags'
        local rulelab "fixed at `lags'"
    }
    else {
        local laglen -1
        local rulelab = cond(`rulen'==2, "Andrews (1991) automatic", ///
                                         "Newey-West plug-in")
    }
    local nodfadj = cond("`nodfadj'"!="", 1, 0)

    local depv  "`e(depvar)'"
    local zvars "`e(invariant)'"
    local hascons = e(hascons)
    local m = e(nthresh)
    if `m' >= . local m 1

    * the thresholds, and the design. After thtar the stored regressor names
    * are tempvars that are gone, so the lags are rebuilt from e(arlags) --
    * exactly as estat gridboot does, and for the same reason.
    tempvar touse
    quietly generate byte `touse' = e(sample)
    local wascmd "`e(cmd)'"

    if "`wascmd'" == "thtar" {
        local arl "`e(arlags)'"
        local dly = e(delay)
        if "`arl'" == "" {
            display as error "{bf:e(arlags)} is empty; refit"
            exit 498
        }
        local xvars ""
        foreach j of local arl {
            tempvar a`j'
            quietly generate double `a`j'' = L`j'.`depv' if `touse'
            local xvars `xvars' `a`j''
        }
        if "`e(model)'" == "setar" {
            tempvar qv
            quietly generate double `qv' = L`dly'.`depv' if `touse'
            local qvar `qv'
        }
        else {
            capture tsrevar `e(threshold_var)'
            local qvar = cond(_rc, "`e(threshold_var)'", "`r(varlist)'")
        }
        markout `touse' `xvars' `qvar'
    }
    else {
        local xvars "`e(indepvars)'"
        capture tsrevar `e(threshold_var)'
        local qvar = cond(_rc, "`e(threshold_var)'", "`r(varlist)'")
        local missv ""
        foreach v of local xvars {
            capture confirm numeric variable `v'
            if _rc local missv `missv' `v'
        }
        capture confirm numeric variable `qvar'
        if _rc local missv `missv' `qvar'
        if "`missv'" != "" {
            local nmiss : word count `missv'
            display as error "{bf:estat hac} needs the fitted design, and"
            display as error "`nmiss' of its variable(s) no longer exist."
            display as error "Create them as permanent variables and refit."
            exit 498
        }
    }

    * the thresholds as a list
    local gammas ""
    capture confirm matrix e(gammas)
    if !_rc {
        tempname GG
        matrix `GG' = e(gammas)
        forvalues j = 1/`=colsof(`GG')' {
            local gj = `GG'[1,`j']
            local gammas `gammas' `gj'
        }
    }
    else {
        tempname G1
        scalar `G1' = e(gamma)
        local gammas = `G1'
    }

    mata: tk_thhac()

    if __tk_hacfail == 1 {
        _tk_drop
        display as error "the design could not be rebuilt"
        exit 498
    }
    if __tk_hacfail == 2 {
        _tk_drop
        display as error "the regime design is singular or too small"
        exit 498
    }

    tempname B V LAG RHO NN KK
    matrix `B' = __tk_hacb
    matrix `V' = __tk_hacV
    scalar `LAG' = __tk_haclag
    scalar `RHO' = __tk_hacrho
    scalar `NN'  = __tk_hacn
    scalar `KK'  = __tk_hack
    _tk_drop

    * name the columns as the fit does, so the table is readable
    tempname EB
    matrix `EB' = e(b)
    if colsof(`EB') == colsof(`B') {
        local cn : colnames `EB'
        local ce : coleq `EB'
        matrix colnames `B' = `cn'
        matrix coleq    `B' = `ce'
        matrix colnames `V' = `cn'
        matrix coleq    `V' = `ce'
        matrix rownames `V' = `cn'
        matrix roweq    `V' = `ce'
    }

    display _n as text "HAC standard errors for the regime coefficients"
    display as text "{hline 72}"
    display as text "  observations" _col(48) as result %24.0f `NN'
    display as text "  coefficients" _col(48) as result %24.0f `KK'
    display as text "  bandwidth rule" _col(48) as result %24s "`rulelab'"
    display as text "  Bartlett lags used" _col(48) as result %24.0f `LAG'
    display as text "  largest AR(1) in the scores" _col(48) as result %24.4f `RHO'
    display as text "  small-sample adjustment" _col(48) as result %24s ///
        cond(`nodfadj', "none", "n/(n-k)")
    display as text "{hline 72}"

    if `LAG' == 0 {
        display as text "  {bf:Zero lags} means this reduces to the HC"
        display as text "  sandwich -- the same thing {bf:vce(robust)} gives."
        display as text "  With `NN' observations the plug-in rule returns 0;"
        display as text "  if you have reason to expect serial correlation,"
        display as text "  set {bf:lags()} yourself."
    }
    if `RHO' >= 0.9 & `RHO' < . {
        display as error "  WARNING. The scores have an AR(1) coefficient of" ///
            " `=string(`RHO',"%4.2f")'."
        display as text  "  That is close to a unit root, and NO HAC estimate"
        display as text  "  is reliable there however the bandwidth is chosen"
        display as text  "  -- the autocovariances are not summable. The right"
        display as text  "  response is to model the dynamics rather than to"
        display as text  "  correct the variance for them: add lags, or use"
        display as text  "  {helpb thunitroot} to check whether the series is"
        display as text  "  stationary at all."
    }

    ereturn display, level(`level')

    display as text "  {bf:These condition on gamma-hat.} They carry no"
    display as text "  uncertainty about the threshold, and a HAC standard"
    display as text "  error is not a licence to treat the threshold as known"
    display as text "  -- it only stops the slope's own standard error being"
    display as text "  wrong for a second, separate reason. For the threshold"
    display as text "  use {bf:estat gridboot}; for slope intervals that do"
    display as text "  not condition on gamma-hat, {bf:estat twostep}."
    display as text ""
    display as text "  Report the bandwidth. A HAC standard error without its"
    display as text "  lag length is not reproducible, and the number changes"
    display as text "  the answer."

    return matrix b   = `B', copy
    return matrix V   = `V', copy
    return scalar lags   = `LAG'
    return scalar maxrho = `RHO'
    return scalar N      = `NN'
    return scalar k      = `KK'
    return local  rule   "`rule'"
end
