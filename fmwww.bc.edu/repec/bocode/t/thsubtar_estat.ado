*! thsubtar_estat 1.0.0  07oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Post-estimation for thsubtar.
*!   estat trace     the AIC surface over candidate thresholds, with a graph
*!   estat orders    what each regime's own criterion chose, and by how much
*!   estat regimes   the two regimes side by side
*!   estat compare   the symmetric SETAR this nests, and the AIC it costs

program define thsubtar_estat, rclass
    version 15
    if "`e(cmd)'" != "thsubtar" {
        display as error "last estimates not found, or not from {bf:thsubtar}"
        exit 301
    }
    gettoken sub rest : 0, parse(" ,")
    local sub = lower("`sub'")
    if "`sub'" == "trace" {
        Trace `rest'
        return add
    }
    else if "`sub'" == "orders" {
        Orders `rest'
        return add
    }
    else if "`sub'" == "regimes" {
        Regimes `rest'
        return add
    }
    else if "`sub'" == "compare" {
        Compare `rest'
        return add
    }
    else {
        display as error "unknown {bf:estat} subcommand {bf:`sub'}"
        display as error "valid: trace, orders, regimes, compare"
        exit 198
    }
end

* ======================================================================
* estat trace -- the criterion over candidate thresholds.
*
* A selection that reports only its argmin hides whether the surface was
* flat, and a flat surface means the criterion did not decide anything.
* ======================================================================
program define Trace, rclass
    version 15
    syntax [, GRaph SAVing(string asis) * ]

    tempname TR
    matrix `TR' = e(trace)
    local nr = rowsof(`TR')

    display ""
    display as text "AIC over the candidate thresholds, delay " ///
        as result e(delay) as text ", " as result `nr' as text " candidates"
    display as text "{hline 70}"
    display as text "    threshold" _col(20) "AIC" _col(34) "k1" _col(40) "k2" ///
        _col(48) "N1" _col(56) "N2"
    display as text "{hline 70}"
    local amin = `TR'[1,2]
    local amax = `TR'[1,2]
    forvalues r = 1/`nr' {
        if `TR'[`r',2] < `amin' local amin = `TR'[`r',2]
        if `TR'[`r',2] > `amax' local amax = `TR'[`r',2]
    }
    forvalues r = 1/`nr' {
        local star = cond(abs(`TR'[`r',2] - `amin') < 1e-10, " <-- selected", "")
        display as text "    " as result %12.6g `TR'[`r',1] ///
            _col(16) %12.3f `TR'[`r',2] _col(30) %5.0f `TR'[`r',3] ///
            _col(36) %5.0f `TR'[`r',4] _col(44) %7.0f `TR'[`r',5] ///
            _col(52) %7.0f `TR'[`r',6] as text "`star'"
    }
    display as text "{hline 70}"
    display as text "  range of the criterion" _col(32) ///
        as result %12.4f (`amax' - `amin')
    if (`amax' - `amin') < 2 {
        display as text "  That range is small. A difference of less than" ///
            " about 2 in"
        display as text "  an AIC is not usually treated as decisive, so the"
        display as text "  threshold is weakly identified by this criterion"
        display as text "  even though a single value is reported."
    }

    if "`graph'" != "" {
        preserve
        quietly {
            clear
            svmat double `TR', name(tr)
            label variable tr1 "candidate threshold"
            label variable tr2 "AIC (Tong-Lim)"
        }
        twoway line tr2 tr1, sort                                      ///
            title("AIC over candidate thresholds")                     ///
            subtitle("SETAR(2; k1, k2), delay `=e(delay)'")             ///
            xtitle("threshold") ytitle("AIC")                          ///
            yline(`amin', lpattern(dash))                              ///
            note("the dashed line is the minimum; a flat profile means a weakly identified threshold") ///
            `options'
        if `"`saving'"' != "" _tk_gsave `saving'
        restore
    }
    return matrix trace = `TR'
    return scalar range = `amax' - `amin'
end

* ======================================================================
* estat orders -- what each regime's own criterion chose.
*
* The orders are selected by eq (8.3) on each regime SEPARATELY, so the
* evidence for k1 is not the evidence for k2 and the two are worth seeing
* apart. Reported as the criterion at the selected order against the
* alternatives, because "k1 = 7" is not informative without knowing how
* much better 7 was than 6.
* ======================================================================
program define Orders, rclass
    version 15
    syntax [, ]

    display ""
    display as text "Per-regime order selection, Tong-Lim (1980) eq. (8.3)"
    display as text "{hline 70}"
    display as text "  AIC_j(k) = N_j ln(RSS_j(k)/N_j) + 2(k + 1)," ///
        " on regime j's OWN N_j"
    display as text "{hline 70}"
    display as text "  lower regime" _col(22) "order " as result e(k1) ///
        as text _col(38) "N = " as result e(N_regime1) ///
        as text _col(52) "sigma2 = " as result %9.5g e(sigma2_1)
    display as text "  upper regime" _col(22) "order " as result e(k2) ///
        as text _col(38) "N = " as result e(N_regime2) ///
        as text _col(52) "sigma2 = " as result %9.5g e(sigma2_2)
    display as text "{hline 70}"
    if e(k1) != e(k2) {
        display as text "  The orders DIFFER, which is the finding this"
        display as text "  command exists to report: forcing one order on"
        display as text "  both regimes would spend degrees of freedom in"
        display as text "  the " as result cond(e(k1) < e(k2), "lower", "upper") ///
            as text " regime to buy nothing."
    }
    else {
        display as text "  The orders came out EQUAL, so the asymmetry this"
        display as text "  command allows is not needed on these data and"
        display as text "  {bf:thtar} fits the same model."
    }
    local vr = e(sigma2_1)/e(sigma2_2)
    display as text "  variance ratio lower/upper" _col(34) ///
        as result %12.4f `vr'
    if `vr' > 4 | `vr' < 0.25 {
        display as text "  The innovation variances differ by more than a"
        display as text "  factor of 4. The orders were chosen with each"
        display as text "  regime's own variance, which is correct, but a"
        display as text "  total-SSR criterion elsewhere in this package"
        display as text "  would be pulled towards the noisier regime; see"
        display as text "  {bf:thregress, hetvar}."
    }
    return scalar k1 = e(k1)
    return scalar k2 = e(k2)
    return scalar vratio = `vr'
end

* ======================================================================
* estat regimes -- the two fits side by side.
* ======================================================================
program define Regimes, rclass
    version 15
    syntax [, ]

    tempname b V
    matrix `b' = e(b)
    matrix `V' = e(V)
    local k1 = e(k1)
    local k2 = e(k2)
    local hc = e(hascons)
    local depv "`e(depvar)'"

    display ""
    display as text "SETAR(2; `k1', `k2') by regime, threshold " ///
        as result %10.6g e(gamma)
    display as text "{hline 70}"
    display as text "    lag" _col(14) "lower regime" _col(38) "upper regime"
    display as text "{hline 70}"
    local kbig = max(`k1', `k2')
    forvalues i = 1/`kbig' {
        local lo " ."
        local up " ."
        if `i' <= `k1' {
            local lo : display %12.6f `b'[1,`i']
        }
        if `i' <= `k2' {
            local j = `k1' + `hc' + `i'
            local up : display %12.6f `b'[1,`j']
        }
        display as text "    L`i'." _col(12) as result "`lo'" ///
            _col(36) as result "`up'"
    }
    if `hc' {
        local jl = `k1' + 1
        local ju = `k1' + `hc' + `k2' + 1
        display as text "    _cons" _col(12) as result %12.6f `b'[1,`jl'] ///
            _col(36) as result %12.6f `b'[1,`ju']
    }
    display as text "{hline 70}"
    display as text "    obs" _col(12) as result %12.0fc e(N_regime1) ///
        _col(36) as result %12.0fc e(N_regime2)
    display as text "    SSR" _col(12) as result %12.4f e(ssr1) ///
        _col(36) as result %12.4f e(ssr2)
    display as text "    sigma2" _col(12) as result %12.6g e(sigma2_1) ///
        _col(36) as result %12.6g e(sigma2_2)
    display as text "{hline 70}"
    display as text "  A blank means that lag is {bf:not in} that regime's"
    display as text "  model -- not that its coefficient is zero and"
    display as text "  estimated. Nothing was fitted there."
    return scalar k1 = `k1'
    return scalar k2 = `k2'
end

* ======================================================================
* estat compare -- what the symmetric SETAR would have cost.
*
* The asymmetry is only worth reporting if it bought something, so the
* comparison against the common-order model is the natural check, and it
* is the one a referee will ask for.
* ======================================================================
program define Compare, rclass
    version 15
    syntax [, ]

    local k1 = e(k1)
    local k2 = e(k2)
    local kbig = max(`k1', `k2')
    local a_sub = e(aic)

    display ""
    display as text "The asymmetric fit against the symmetric SETAR it nests"
    display as text "{hline 70}"
    display as text "  selected" _col(26) "SETAR(2; `k1', `k2')" ///
        _col(52) as result %12.3f `a_sub'

    if `k1' == `k2' {
        display as text "{hline 70}"
        display as text "  The orders are already equal, so there is nothing"
        display as text "  to compare: this IS the symmetric model."
        return scalar aic_sub = `a_sub'
        return scalar aic_sym = `a_sub'
        return scalar gain = 0
        exit
    }

    * Refit with the common order max(k1,k2) at the SAME delay and the same
    * reserved sample, so only the orders differ between the two numbers.
    *
    * EVERY e() VALUE IS HARVESTED BEFORE THE HOLD. _estimates hold CLEARS
    * e(), so reading e(depvar) after it returns nothing and the refit would
    * be run on an empty variable name -- which is the defect this project
    * already paid for once in estat pscore, where an _rc was read after an
    * inserted hold and the kink variable resolved silently wrongly.
    local depv "`e(depvar)'"
    local d    = e(delay)
    local mp   = e(maxp)
    local tr   = e(trim)
    local hc   = e(hascons)
    local nc   = cond(`hc', "", "noconstant")

    tempname held
    capture _estimates hold `held', restore nullok
    local rch = _rc

    capture quietly thsubtar `depv', maxp(`mp') arlower(`kbig') ///
        arupper(`kbig') delay(`d') trim(`tr') `nc'
    local rc2 = _rc
    if `rc2' == 0 {
        local a_sym = e(aic)
        local g_sym = e(gamma)
    }
    if `rch' == 0 {
        capture _estimates unhold `held'
    }
    if `rc2' {
        display as text "{hline 70}"
        display as error "  the symmetric refit failed (rc=`rc2')"
        exit `rc2'
    }

    display as text "  common order" _col(26) "SETAR(2; `kbig', `kbig')" ///
        _col(52) as result %12.3f `a_sym'
    display as text "{hline 70}"
    local gain = `a_sym' - `a_sub'
    display as text "  AIC saved by the asymmetry" _col(52) ///
        as result %12.3f `gain'
    if `gain' > 2 {
        display as text "  The asymmetry is worth having on these data: more"
        display as text "  than 2 in AIC is the conventional threshold for"
        display as text "  preferring a model, and it is bought by REMOVING"
        display as text "  parameters, not by adding them."
    }
    else if `gain' > 0 {
        display as text "  The asymmetry helps, but by less than 2 in AIC,"
        display as text "  which is not usually treated as decisive. Report"
        display as text "  both models."
    }
    else {
        display as text "  The asymmetry did NOT help. Prefer the symmetric"
        display as text "  model, which {helpb thtar} fits with an interval"
        display as text "  for the threshold as well."
    }
    return scalar aic_sub = `a_sub'
    return scalar aic_sym = `a_sym'
    return scalar gain    = `gain'
end
