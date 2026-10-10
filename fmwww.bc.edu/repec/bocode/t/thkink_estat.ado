*! thkink_estat 1.0.0  01oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Post-estimation for thkink.
*!   estat kinkplot   fitted kinked regression function with the data
*!   estat lrplot     the least-squares criterion / Wald profile over gamma
*!   estat slopetest  test that the slope does not change (kink_above = kink_below)
*!   estat continuity Hansen (2017) note: compare the kink fit with a jump fit
*!   estat serial     no error autocorrelation, against the kink gradient
*!   estat archlm     Engle ARCH LM on the squared residuals
*!   estat mcleodli   McLeod-Li portmanteau on the squared residuals
*!   estat normality  Jarque-Bera, with its skewness and kurtosis components
*!   estat diag       all four of the above in one table

program define thkink_estat, rclass
    version 15
    * thtar, continuous delegates to thkink and keeps e(cmd) == "thtar", so
    * the continuous SETAR must be accepted here too: it IS a thkink fit, on
    * an autoregressive design, and every stored result has the same layout.
    if "`e(cmd)'" != "thkink" & ///
       !("`e(cmd)'" == "thtar" & "`e(model)'" == "setar_continuous") {
        display as error "last estimates not found, or not from {bf:thkink}"
        display as error "or {bf:thtar, continuous}"
        exit 301
    }
    gettoken sub rest : 0, parse(" ,")
    local sub = lower("`sub'")
    if "`sub'" == "kinkplot" | "`sub'" == "regimeplot" {
        Kinkplot `rest'
    }
    else if "`sub'" == "lrplot" | "`sub'" == "profileplot" {
        LRplot `rest'
    }
    else if "`sub'" == "slopetest" {
        Slopetest `rest'
    }
    else if "`sub'" == "continuity" {
        Continuity `rest'
    }
    else if "`sub'" == "pscore" {
        Pscore `rest'
        return add
    }
    else if inlist("`sub'", "serial", "archlm", "mcleodli", "normality", "diag") {
        Resdiag "`sub'" `rest'
        return add
    }
    else {
        display as error "unknown {bf:estat} subcommand {bf:`sub'}"
        display as error "valid: kinkplot, lrplot, slopetest, continuity, pscore,"
        display as error "       serial, archlm, mcleodli, normality, diag"
        exit 198
    }
end

* ----------------------------------------------------------------------
* Residual diagnostics. The gradient of the kink model
*     y = b1 (q - g)_- + b2 (q - g)_+ + x'd + e
* is  [ (q-g)_- , (q-g)_+ , x , -b1 1{q<=g} - b2 1{q>g} ].
* The derivative with respect to gamma is the last column, and leaving it out
* would make the test condition on gamma being known.
* ----------------------------------------------------------------------
program define Resdiag, rclass
    version 15
    gettoken which 0 : 0
    syntax [, LAGs(integer 4) ]
    if "`which'" == "diag"   local which "serial arch mcleodli normality"
    if "`which'" == "archlm" local which "arch"

    capture drop __tkg_*
    quietly generate byte __tkg_touse = e(sample)
    * After thtar, continuous the kink variable is a TIME-SERIES EXPRESSION
    * (L1.y), which is valid in an expression but NOT in a varlist, a sort()
    * or a twoway plot. Resolve it to a real variable once, here, and use
    * that everywhere below; kvname keeps the readable form for labels.
    local kvname "`e(kink_var)'"
    capture tsrevar `kvname'
    local kv = cond(_rc, "`kvname'", "`r(varlist)'")
    local zl "`e(indepvars)'"
    tempname b GAM B1 B2
    matrix `b' = e(b)
    scalar `GAM' = e(gamma)
    scalar `B1'  = `b'[1,1]
    scalar `B2'  = `b'[1,2]

    quietly generate double __tkg_lo = cond(`kv' - `GAM' < 0, `kv' - `GAM', 0) ///
        if __tkg_touse
    quietly generate double __tkg_hi = cond(`kv' - `GAM' > 0, `kv' - `GAM', 0) ///
        if __tkg_touse
    local nullvars __tkg_lo __tkg_hi
    local j 0
    foreach v of local zl {
        local ++j
        quietly generate double __tkg_x`j' = `v' if __tkg_touse
        local nullvars `nullvars' __tkg_x`j'
    }
    quietly generate double __tkg_dg = ///
        -(`B1'*(`kv' <= `GAM') + `B2'*(`kv' > `GAM')) if __tkg_touse
    local nullvars `nullvars' __tkg_dg
    quietly predict double __tkg_e if __tkg_touse, residuals

    * the constant is in e(b) but not in e(indepvars), so add it here
    _tk_resdiag __tkg_e , touse(__tkg_touse) nullvars(`nullvars') addcons ///
        lags(`lags') which("`which'") model("thkink")
    return add
    capture drop __tkg_*
end

* ----------------------------------------------------------------------
program define Kinkplot
    syntax [, SAVing(string asis) TItle(string asis) * ]
    * After thtar, continuous the kink variable is a TIME-SERIES EXPRESSION
    * (L1.y), which is valid in an expression but NOT in a varlist, a sort()
    * or a twoway plot. Resolve it to a real variable once, here, and use
    * that everywhere below; kvname keeps the readable form for labels.
    local kvname "`e(kink_var)'"
    capture tsrevar `kvname'
    local kv = cond(_rc, "`kvname'", "`r(varlist)'")
    local dv "`e(depvar)'"
    local g  = e(gamma)
    tempvar fit
    quietly predict double `fit' if e(sample), xb
    if "`title'" == "" local title "Fitted regression kink"
    local glo = e(gamma_lo)
    local ghi = e(gamma_hi)
    twoway (scatter `dv' `kv' if e(sample), mcolor(navy%45) msymbol(O) msize(small)) ///
           (line `fit' `kv' if e(sample) & `kv' <= `g', sort lcolor(cranberry) lwidth(medthick)) ///
           (line `fit' `kv' if e(sample) & `kv' >  `g', sort lcolor(cranberry) lwidth(medthick)), ///
        xline(`g', lcolor(black) lpattern(dash))                                  ///
        ytitle("`dv'") xtitle("`kvname'")                                             ///
        title("`title'", size(medium))                                            ///
        subtitle("kink at `kvname' = `=string(`g',"%10.0g")'   `=string(e(level),"%2.0f")'% CI [`=string(`glo',"%8.0g")', `=string(`ghi',"%8.0g")']", size(small)) ///
        legend(order(1 "data" 2 "fitted kink") rows(1) position(6)                ///
               region(lstyle(none)) size(small))                                  ///
        graphregion(color(white)) plotregion(color(white))                        ///
        note("The fitted function is continuous at the kink; only its slope changes." ///
             "Hansen (2017), JBES 35:228-240.", size(vsmall))                     ///
        `options'
    if `"`saving'"' != "" _tk_gsave `saving'
end

* ----------------------------------------------------------------------
program define LRplot
    syntax [, SAVing(string asis) TItle(string asis) * ]
    if "`e(profile)'" == "" {
        display as error "no stored profile"
        exit 198
    }
    tempname P
    matrix `P' = e(profile)
    local g  = e(gamma)
    local cv = e(crit)
    * After thtar, continuous the kink variable is a TIME-SERIES EXPRESSION
    * (L1.y), which is valid in an expression but NOT in a varlist, a sort()
    * or a twoway plot. Resolve it to a real variable once, here, and use
    * that everywhere below; kvname keeps the readable form for labels.
    local kvname "`e(kink_var)'"
    capture tsrevar `kvname'
    local kv = cond(_rc, "`kvname'", "`r(varlist)'")
    if "`title'" == "" local title "Least-squares criterion over the kink point"
    preserve
    clear
    quietly svmat double `P', names(col)
    local extra ""
    if `cv' < . {
        local extra (function y = `cv', range(gamma) lcolor(cranberry) lpattern(dash))
    }
    twoway (line wald gamma, sort lcolor(navy) lwidth(medthick)) `extra',      ///
        ytitle("Wald({&gamma})") xtitle("`kvname'")                                 ///
        title("`title'", size(medium))                                          ///
        subtitle("{&gamma}-hat = `=string(`g',"%10.0g")'", size(small))         ///
        xline(`g', lcolor(black) lwidth(thin))                                  ///
        legend(off) graphregion(color(white)) plotregion(color(white))          ///
        note("Hansen (2017), Figure 3. The dashed line, when shown, is the" ///
             "bootstrap critical value for the no-kink test.", size(vsmall))    ///
        `options'
    if `"`saving'"' != "" _tk_gsave `saving'
    restore
end

* ----------------------------------------------------------------------
program define Slopetest, rclass
    syntax [, Level(cilevel) ]
    if "`level'" == "" local level = e(level)
    display ""
    display as text "Test that the slope in `e(kink_var)' does not change at the kink"
    display as text "  H0: kink_above = kink_below"
    quietly lincom kink_above - kink_below, level(`level')
    display as text "{hline 62}"
    display as text "  slope change" _col(20) as result %10.6f r(estimate) ///
        as text "   s.e. " as result %9.6f r(se)
    display as text "  z" _col(20) as result %10.4f r(estimate)/r(se) ///
        as text "   p    " as result %9.4f 2*normal(-abs(r(estimate)/r(se)))
    display as text "  `level'% CI" _col(20) as result ///
        "[" %8.5f r(lb) ", " %8.5f r(ub) "]"
    display as text "{hline 62}"
    display as text "  This is NOT a test for the existence of a kink: gamma is not"
    display as text "  identified under that null. For that use {bf:thkink, test}."
    return scalar b  = r(estimate)
    return scalar se = r(se)
    return scalar p  = 2*normal(-abs(r(estimate)/r(se)))
end

* ----------------------------------------------------------------------
program define Continuity, rclass
    syntax [, ]
    display ""
    display as text "Continuous (kink) versus discontinuous (jump) threshold"
    display as text "{hline 70}"
    * After thtar, continuous the kink variable is a TIME-SERIES EXPRESSION
    * (L1.y), which is valid in an expression but NOT in a varlist, a sort()
    * or a twoway plot. Resolve it to a real variable once, here, and use
    * that everywhere below; kvname keeps the readable form for labels.
    local kvname "`e(kink_var)'"
    capture tsrevar `kvname'
    local kv = cond(_rc, "`kvname'", "`r(varlist)'")
    local dv "`e(depvar)'"
    local zl "`e(indepvars)'"
    local kssr = e(ssr)
    local n    = e(N)
    tempvar esamp
    quietly generate byte `esamp' = e(sample)
    * thregress REPLACES the stored estimates, which would leave thkink's own
    * e() gone and every later estat failing with "not valid". _estimates hold
    * with restore puts them back when this program ends, error or not.
    tempname ESTH
    _estimates hold `ESTH', restore
    quietly thregress `dv' `kv' `zl' if `esamp', threshvar(`kv') ci(none)
    local jssr = e(ssr)
    local jg   = e(gamma)
    display as text "  kink fit   SSR = " as result %12.5f `kssr'
    display as text "  jump fit   SSR = " as result %12.5f `jssr' ///
        as text "   (gamma = " as result %8.0g `jg' as text ")"
    display as text "{hline 70}"
    display as text "  The jump model nests the kink model, so its SSR is always smaller."
    display as text "  A LARGE gap is evidence against continuity; a small one means the"
    display as text "  kink restriction costs little and should be kept (it is estimated"
    display as text "  more precisely and gamma is asymptotically normal)."
    display as text "  A formal continuity test needs Hidalgo, Lee, Lee & Seo; the paper is"
    display as text "  in the project folder and the test is scheduled for the next release."
    return scalar ssr_kink = `kssr'
    return scalar ssr_jump = `jssr'
    return scalar ratio    = `jssr'/`kssr'
end

* ======================================================================
* estat pscore -- the pseudo-score test for the EXISTENCE of a breakpoint.
*
*   Muggeo, V. M. R. (2016) "Testing with a nuisance parameter present only
*   under the alternative: a score-based approach with application to
*   segmented modelling", Journal of Statistical Computation and
*   Simulation 86:3059-3067, doi:10.1080/00949655.2016.1149855
*   (local copy muggeo2016.pdf; DOI verified via Crossref 2026-10-07)
*
*   Contrasted in the help with Conniffe, D. (2001) "Score tests when a
*   nuisance parameter is unidentified under the null hypothesis", Journal
*   of Statistical Planning and Inference 97:67-83,
*   doi:10.1016/S0378-3758(00)00346-3
*   (DOI verified via Crossref 2026-10-07, title and pages matched;
*   cited for contrast only, nothing from it is implemented)
*
* WHY THIS IS NOT ANOTHER SUP TEST, and why that matters.
*
* Every other test of a threshold in this package faces the same obstacle:
* the threshold does not exist under the null, so the statistic is computed
* over a grid and the supremum is taken, and the limit of that supremum is
* not standard. Hence Davies' analytic bound, or a bootstrap.
*
* Muggeo takes a different route. Rather than MAXIMISING over the
* unidentified parameter, he AVERAGES over it. The term phi(x,psi) that is
* undefined under H0 is replaced by
*
*     phibar_i = (1/K) sum_k phi(x_i, psi_k)
*
* for K fixed values of psi spanning the admissible range. The averaged
* term no longer depends on psi at all, so an ordinary score test can be
* computed, and it has a CONVENTIONAL reference distribution.
*
* The justification is not hand-waving: it comes from de Finetti's
* extended definition of a conditional quantity, under which E(X | B) is
* what stands in for X when the conditioning event B is false. Here B is
* the event that the breakpoint coefficient is non-zero. The paper notes
* the construction has a Bayesian flavour -- equally spaced psi_k amount to
* a uniform prior on psi -- while involving no prior-to-posterior step.
*
* THE STATISTIC. With A the hat matrix of the NULL (linear) fit:
*
*   one term (a pure KINK, phi = (x-psi)_+):
*       s0 = phibar'(I-A)y / [ sigma * {phibar'(I-A)phibar}^(1/2) ]
*     referred to a t distribution.
*
*   two terms (a JUMP and a KINK, phi1 = 1(x>psi), phi2 = (x-psi)_+):
*       s0 = [Y'(I-A)y]' [Y'(I-A)Y]^-1 [Y'(I-A)y] / sigma^2
*     with Y the n x 2 matrix of averaged terms, referred to chi2(2).
*
* WHICH SIGMA. The paper is explicit: sigma-hat under H0 and under H1 are
* both consistent, so either gives the right size, but sigma-hat0 LOSES
* POWER. It recommends the alternative-model estimate, which is what the
* default uses; sigma0 is available for comparison. The resulting statistic
* is not EXACTLY t, because the numerator and sigma-hat are not independent,
* but being linear in y it is close to one even in small samples, and the
* paper's simulations bear that out.
*
* WHY NOT CONNIFFE'S PSEUDO-SCORE, which looks similar: that one plugs the
* UNCONSTRAINED estimate psi-hat into the null residuals. Under the null
* psi does not exist, so psi-hat has an unknown distribution and so does
* the statistic -- and the paper notes this does not vanish asymptotically.
* Averaging avoids estimating the nuisance at all, which is the whole point.
* ======================================================================
program define Pscore, rclass
    version 15
    syntax [, K(integer 20) TRIM(real 0.10) ONEterm SIGma0 Level(cilevel) ]

    if `k' < 2 | `k' > 500 {
        display as error "{bf:k()} must be between 2 and 500"
        exit 198
    }
    if `trim' < 0 | `trim' >= 0.5 {
        display as error "{bf:trim()} must be in [0, 0.5)"
        exit 198
    }
    if "`level'" == "" local level = c(level)

    * EVERYTHING needed from e() is harvested HERE, before any internal
    * regression runs. Three defects in an earlier draft of this program all
    * came from not doing that:
    *   - the alternative-model sigma was read with e(rmse) AFTER the
    *     internal regressions, so it was the rmse of regressing the
    *     averaged term on the null design -- a meaningless number shown to
    *     the user as the recommended one;
    *   - thkink stores neither e(rmse) nor e(sigma2), only e(ssr), so that
    *     read could never have worked anyway; and
    *   - e() was not protected, so the command DESTROYED the fit it was
    *     called after and a second invocation answered "not valid".
    local depv  "`e(depvar)'"
    local zl    "`e(indepvars)'"
    local kvraw "`e(kink_var)'"
    if "`kvraw'" == "" {
        display as error "{bf:e(kink_var)} is empty; refit {bf:thkink}"
        exit 498
    }
    tempname SSR1 NFIT KFIT
    scalar `SSR1' = e(ssr)
    scalar `NFIT' = e(N)
    tempname BB
    capture matrix `BB' = e(b)
    scalar `KFIT' = cond(_rc, 2, colsof(`BB'))

    tempvar touse
    quietly generate byte `touse' = e(sample)
    * the kink variable may be a time-series EXPRESSION (L1.y), which is
    * legal in an expression but not in a varlist
    capture tsrevar `kvraw'
    * _rc must be read IMMEDIATELY: anything in between -- including the
    * _estimates hold below -- overwrites it, and then the kink variable
    * silently resolves to the wrong thing.
    local kv = cond(_rc, "`kvraw'", "`r(varlist)'")
    * now protect the caller's results: everything below runs regress
    tempname _eh
    _estimates hold `_eh', restore nullok
    markout `touse' `depv' `kv' `zl'
    quietly count if `touse'
    local n = r(N)
    if `n' < 20 {
        display as error "too few observations: `n'"
        exit 2001
    }

    * ---- the admissible range for psi, and the K fixed points in it.
    * The paper says the NUMBER and LOCATION of these are negligible in
    * practice, and that equally spaced values amount to a uniform prior
    * on psi. Trimming keeps the extreme order statistics out, where
    * (x - psi)_+ is almost constant and contributes nothing.
    * trim(0) means the FULL range, and it has to be handled BEFORE
    * _pctile is called: percentiles(0 100) is rejected outright, so
    * branching afterwards -- as an earlier version did -- left trim(0)
    * erroring on a value the option validation explicitly allows.
    if `trim' == 0 {
        quietly summarize `kv' if `touse', meanonly
        local lo = r(min)
        local hi = r(max)
    }
    else {
        quietly _pctile `kv' if `touse', ///
            percentiles(`=100*`trim'' `=100*(1-`trim')')
        local lo = r(r1)
        local hi = r(r2)
    }
    if `hi' <= `lo' {
        display as error "the kink variable has no range after trim(`trim')"
        exit 498
    }

    * ---- the averaged terms phibar
    tempvar pk pj
    quietly generate double `pk' = 0 if `touse'
    local oneterm = cond("`oneterm'" != "", 1, 0)
    if !`oneterm' {
        quietly generate double `pj' = 0 if `touse'
    }
    forvalues j = 1/`k' {
        local psi = `lo' + (`hi' - `lo')*(`j' - 1)/(`k' - 1)
        quietly replace `pk' = `pk' + cond(`kv' > `psi', `kv' - `psi', 0) ///
            if `touse'
        if !`oneterm' {
            quietly replace `pj' = `pj' + (`kv' > `psi') if `touse'
        }
    }
    quietly replace `pk' = `pk'/`k' if `touse'
    if !`oneterm' {
        quietly replace `pj' = `pj'/`k' if `touse'
    }

    * ---- the NULL fit: y on the kink variable and the other regressors,
    * with NO break. (I - A) is its residual-maker, so (I-A)v is just the
    * residual of v regressed on the same design -- which is how the
    * quadratic forms below are computed without ever forming A.
    tempvar r_y r_pk r_pj
    quietly regress `depv' `kv' `zl' if `touse'
    local df0 = e(df_r)
    quietly predict double `r_y' if `touse', residuals
    local ssr0 = e(rss)
    local s2_0 = `ssr0'/`df0'

    quietly regress `pk' `kv' `zl' if `touse'
    quietly predict double `r_pk' if `touse', residuals
    if !`oneterm' {
        quietly regress `pj' `kv' `zl' if `touse'
        quietly predict double `r_pj' if `touse', residuals
    }

    * ---- sigma. The paper is explicit: the H0 and H1 variance estimates
    * are both consistent, so either gives the right SIZE, but the null one
    * LOSES POWER, so the alternative-model estimate is recommended.
    *
    * thkink stores e(ssr) but no variance, so the H1 estimate is formed
    * from it here, with the degrees of freedom counting the posted
    * coefficients AND the estimated threshold -- gamma costs a degree of
    * freedom even though it is not in e(b). Any consistent estimate
    * satisfies the paper; this one is stated rather than left implicit.
    tempname S2
    scalar `S2' = `s2_0'
    local siglab "null fit (sigma0)"
    if "`sigma0'" == "" {
        if `SSR1' < . & `SSR1' > 0 & `NFIT' > `KFIT' + 2 {
            scalar `S2' = `SSR1'/(`NFIT' - `KFIT' - 1)
            local siglab "fitted kink model (recommended)"
        }
        else {
            display as error "  the fitted model's SSR is unusable; falling"
            display as error "  back on the null estimate, which is"
            display as error "  consistent but less powerful."
        }
    }

    * ---- the quadratic forms
    quietly generate double __tkps_a = `r_pk'*`r_y' if `touse'
    quietly summarize __tkps_a if `touse', meanonly
    local num1 = r(sum)
    quietly replace __tkps_a = `r_pk'*`r_pk' if `touse'
    quietly summarize __tkps_a if `touse', meanonly
    local den1 = r(sum)

    if `oneterm' {
        if `den1' <= 0 {
            capture drop __tkps_a
            capture _estimates unhold `_eh'
            display as error "the averaged term is degenerate"
            exit 498
        }
        local stat = `num1'/(sqrt(`S2')*sqrt(`den1'))
        local pv   = 2*ttail(`df0', abs(`stat'))
        local dist "t(`df0')"
        local dfr  = `df0'
    }
    else {
        quietly replace __tkps_a = `r_pj'*`r_y' if `touse'
        quietly summarize __tkps_a if `touse', meanonly
        local num2 = r(sum)
        quietly replace __tkps_a = `r_pj'*`r_pj' if `touse'
        quietly summarize __tkps_a if `touse', meanonly
        local d22 = r(sum)
        quietly replace __tkps_a = `r_pj'*`r_pk' if `touse'
        quietly summarize __tkps_a if `touse', meanonly
        local d12 = r(sum)

        tempname G V Vi ST
        matrix `G' = (`num2' \ `num1')
        matrix `V' = (`d22', `d12' \ `d12', `den1')
        capture matrix `Vi' = invsym(`V')
        if _rc | `V'[1,1] <= 0 | `V'[2,2] <= 0 {
            capture drop __tkps_a
            capture _estimates unhold `_eh'
            display as error "the two averaged terms are collinear"
            exit 498
        }
        matrix `ST' = `G''*`Vi'*`G'
        local stat = `ST'[1,1]/`S2'
        local pv   = chi2tail(2, `stat')
        local dist "chi2(2)"
        local dfr  = 2
    }
    capture drop __tkps_a
    capture _estimates unhold `_eh'

    * ---- display
    display _n as text ///
        "Pseudo-score test for the existence of a breakpoint"
    display as text "{hline 72}"
    display as text "  H0: no breakpoint in " as result "`kvraw'"
    display as text "  form tested" _col(44) as result %28s ///
        cond(`oneterm', "kink only", "jump AND kink")
    display as text "  averaging points K" _col(44) as result %28.0f `k'
    display as text "  psi averaged over" _col(44) as result %28s ///
        "[`=string(`lo',"%9.4f")', `=string(`hi',"%9.4f")']"
    display as text "  sigma taken from" _col(44) as result %28s "`siglab'"
    display as text "  observations" _col(44) as result %28.0f `n'
    display as text "{hline 72}"
    display as text "  statistic" _col(44) as result %28.4f `stat'
    display as text "  reference distribution" _col(44) as result %28s "`dist'"
    display as text "  p-value" _col(44) as result %28.4f `pv'
    display as text "{hline 72}"

    display as text "  This test AVERAGES over the unidentified breakpoint"
    display as text "  instead of maximising over it, which is why it has a"
    display as text "  conventional reference distribution and needs NO"
    display as text "  bootstrap and NO grid search. Compare it with"
    display as text "  {bf:thtest, davies} and with the bootstrap p-values"
    display as text "  elsewhere in the package: they answer the same"
    display as text "  question by a different route and can disagree."
    if `oneterm' {
        display as text ""
        display as text "  {bf:kink only.} This tests a change of SLOPE at a"
        display as text "  continuous join. If the function may also JUMP,"
        display as text "  drop {bf:oneterm}: the two-term form tests both"
        display as text "  and is the one to use when continuity is in doubt."
    }
    if "`sigma0'" != "" {
        display as text ""
        display as text "  {bf:sigma0} uses the NULL variance. Both estimates"
        display as text "  give the right size, but the paper shows the null"
        display as text "  one LOSES POWER, which is why it is not the"
        display as text "  default."
    }

    return scalar stat  = `stat'
    return scalar p     = `pv'
    return scalar df    = `dfr'
    return scalar K     = `k'
    return scalar psi_lo = `lo'
    return scalar psi_hi = `hi'
    return scalar N     = `n'
    return scalar sigma2 = `S2'
    return local  dist  "`dist'"
    return local  form  = cond(`oneterm', "kink", "jump+kink")
end
