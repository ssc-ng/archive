*! xtpqgmm_estat 1.0.0  14oct2026
*! Postestimation diagnostics for xtpqgmm.
*! Reached as `estat ...' through e(estat_cmd); never called directly.
*!
*! Author: Dr Merwan Roudane <merwanroudane920@gmail.com>

program xtpqgmm_estat, rclass
    version 17.0

    if `"`e(cmd)'"' != "xtpqgmm" {
        error 301
    }

    gettoken sub rest : 0, parse(" ,")
    local sub = lower(`"`sub'"')

    if ("`sub'" == "") {
        di as error "estat requires a subcommand"
        di as error "{p 4 4 2}After {bf:xtpqgmm}: {bf:overid}," ///
            " {bf:diagnostics}, {bf:alpha}, or any of the standard" ///
            " {helpb estat} subcommands ({bf:vce}, {bf:summarize})." ///
            "{p_end}"
        exit 198
    }

    if ("`sub'" == substr("overid", 1, max(5, length("`sub'")))) {
        _xtpq_overid `rest'
        return add
        exit
    }
    if ("`sub'" == substr("diagnostics", 1, max(4, length("`sub'")))) {
        _xtpq_diag `rest'
        return add
        exit
    }
    if ("`sub'" == substr("alpha", 1, max(5, length("`sub'")))) {
        _xtpq_alpha `rest'
        return add
        exit
    }

    * everything else -- vce, summarize, ... -- is Stata's own
    estat_default `0'
    return add
end


* ===========================================================================
* estat overid -- Hansen's J
* ===========================================================================
program _xtpq_overid, rclass
    version 17.0
    syntax [, Level(cilevel) ]

    tempname J
    capture matrix `J' = e(jtable)
    if (_rc) {
        di as error "no over-identification table was stored"
        di as error "{p 4 4 2}Refit with this version of {bf:xtpqgmm}." ///
            "{p_end}"
        exit 301
    }
    local df = `J'[1,3]

    di ""
    di as text "Over-identifying restrictions (Hansen's J)"
    if (`df' <= 0) {
        di as text "{p 0 2 2}The model is exactly identified:" ///
            " e(n_inst) = " as result e(n_inst) as text " instrument(s) for" ///
            " e(df_m) = " as result e(df_m) as text " parameter(s), so the" ///
            " moment conditions hold at the estimate by construction and" ///
            " there is nothing to test.  Add an excluded instrument to get" ///
            " a testable restriction.{p_end}"
        return scalar df = 0
        exit
    }

    di as text "  H0: all " as result e(n_inst) as text ///
        " moment conditions hold.  df = " as result `df'
    di as text "  {hline 44}"
    di as text "  quantile" _col(18) "J" _col(32) "p-value"
    di as text "  {hline 44}"
    local nq = e(n_q)
    forvalues i = 1/`nq' {
        di as text "  " %8.2f `J'[`i',1] ///
            as result _col(14) %9.4f `J'[`i',2] _col(30) %9.4f `J'[`i',4]
    }
    di as text "  {hline 44}"

    if ("`e(estimator)'" != "Two-step SP-GMM (eq. 11), Bartlett HAC weighting") {
        di as text "{p 0 2 2}Note: this fit is {bf:not} the two-step" ///
            " estimator, so {it:beta}-hat does not minimise the quadratic" ///
            " form this statistic evaluates.  J is then conservative --" ///
            " it is computed at a non-minimising point, so it is larger" ///
            " than the two-step J would be and the test over-rejects" ///
            " nothing.  Refit without {bf:mm}/{bf:onestep} for the usual" ///
            " statistic.{p_end}"
    }
    di as text "{p 0 2 2}The paper does not state this test; it is the" ///
        " standard GMM statistic built from its own Section 5 objects," ///
        " with {it:Omega}-hat taken at the reported estimate.  A small" ///
        " p-value says the instruments and the quantile restriction are" ///
        " not jointly consistent -- it does {bf:not} say which" ///
        " instrument is at fault.{p_end}"
    if (e(T_bar) < 20) {
        di as text "{p 0 2 2}Note: T-bar = " as result %4.1f e(T_bar) ///
            as text ".  The smoothing bias is O({it:h}^4) and is not" ///
            " removed before this statistic is formed, so on short panels" ///
            " J can reject for bandwidth reasons rather than instrument" ///
            " reasons.  Re-run with a smaller {bf:bandwidth()} before" ///
            " believing a rejection.{p_end}"
    }

    * `return matrix' MOVES the matrix, so read the scalars out of it first
    local jv = `J'[1,2]
    local pv = `J'[1,4]
    return matrix jtable = `J'
    return scalar df = `df'
    if (`nq' == 1) {
        return scalar J = `jv'
        return scalar p = `pv'
    }
end


* ===========================================================================
* estat diagnostics -- everything the fit knows about itself
* ===========================================================================
program _xtpq_diag, rclass
    version 17.0
    syntax

    di ""
    di as text "Fit diagnostics for {bf:xtpqgmm}"
    di as text "{hline 68}"
    di as text "Estimator" _col(34) as result "`e(estimator)'"
    di as text "Kernel order" _col(34) as result %8.0f e(korder)
    di as text "Bandwidth h" _col(34) as result %12.6g e(bwidth)
    di as text "Bartlett lag" _col(34) as result %8.0f e(haclag)
    di as text "  lag^2 log(nT)/(T h^2) comfortable?" _col(34) ///
        as result cond(e(haclagok) == 1, "yes", "NO")
    di as text "Panel" _col(34) as result %8.0f e(N_g) as text " units, T in [" ///
        as result e(T_min) as text ", " as result e(T_max) as text "], T-bar = " ///
        as result %5.1f e(T_bar)
    di as text "n / T-bar" _col(34) as result %12.4f e(n_over_T)
    di as text "{hline 68}"
    di as text "Optimiser"
    di as text "  iterations" _col(34) as result %8.0f e(ic)
    di as text "  converged" _col(34) as result cond(e(converged)==1,"yes","NO")
    di as text "  ||D'Wm|| at the optimum" _col(34) as result %12.3e e(gnorm)
    di as text "  ||m|| at the optimum" _col(34) as result %12.3e e(mnorm)
    di as text "  criterion Q" _col(34) as result %12.3e e(Qval)
    di as text "{hline 68}"
    di as text "Profiling (equation 8)"
    di as text "  unit-evaluations with no root" _col(34) as result %8.0f e(n_profilefail)
    di as text "  units with multiple roots" _col(34) as result %8.0f e(n_multiroot)
    di as text "  max |A_i| at the solution" _col(34) as result %12.3e e(maxA)
    di as text "{hline 68}"

    * --- the readings, in plain words -------------------------------------
    if (e(converged) != 1 & e(gnorm) >= 1e-6) {
        di as error "{p 0 2 2}The criterion did not converge.  Treat the" ///
            " estimates as provisional.{p_end}"
    }
    if (e(n_profilefail) > 0) {
        di as error "{p 0 2 2}Equation (8) had no root in " ///
            as result e(n_profilefail) as error " unit-evaluation(s)." ///
            "  Those units fell back to the unsmoothed quantile, which is" ///
            " consistent but not the estimator in the paper.  It usually" ///
            " means a unit is too short, or {it:h} is too small for it." ///
            "{p_end}"
    }
    if (e(maxA) > 1e-6) {
        di as error "{p 0 2 2}max |A_i| = " as result %9.2e e(maxA) ///
            as error ", which is large: the profile restriction is not" ///
            " satisfied to working precision at the reported estimate." ///
            "  Something is wrong; do not report these numbers.{p_end}"
    }
    if (e(n_over) > 0) {
        local jp = e(jstat_p)
        if ("`jp'" != "" & e(n_q) == 1) {
            di as text "{p 0 2 2}Over-identification: J = " as result ///
                %7.3f e(jstat) as text " on " as result e(jstat_df) ///
                as text " df, p = " as result %6.4f e(jstat_p) as text ///
                ".  {bf:estat overid} prints the full table.{p_end}"
        }
        else {
            di as text "{p 0 2 2}The model is over-identified by " ///
                as result e(n_over) as text " restriction(s); see" ///
                " {bf:estat overid}.{p_end}"
        }
    }
    if (e(n_over_T) >= 1) {
        di as text "{p 0 2 2}n/T-bar = " as result %5.2f e(n_over_T) ///
            as text ".  Theorem 4.1 assumes n/T -> 0 and the" ///
            " incidental-parameter bias is O(sqrt(n/T)); it is {bf:not}" ///
            " corrected.  See {help xtpqgmm_methods##nT:[methods] The n/T" ///
            " condition}.{p_end}"
    }

    return scalar converged = e(converged)
    return scalar gnorm     = e(gnorm)
    return scalar maxA      = e(maxA)
end


* ===========================================================================
* estat alpha -- the profiled-out fixed effects
* ===========================================================================
program _xtpq_alpha, rclass
    version 17.0
    syntax [, GENerate(name) Quantile(real -1) DETail ]

    tempname A
    capture matrix `A' = e(alpha)
    if (_rc) {
        di as error "e(alpha) is not available"
        exit 301
    }
    local nq = e(n_q)
    local qs `e(quantiles)'
    local col 1
    if (`nq' > 1) {
        if (`quantile' < 0) {
            di as error "this fit has `nq' quantiles; say which one"
            di as error "{p 4 4 2}For example {bf:estat alpha," ///
                " quantile(50)}.  The quantiles are: `qs'." ///
                "{p_end}"
            exit 198
        }
        local tau = `quantile'
        if (`tau' >= 1) local tau = `tau'/100
        local col 0
        local j 0
        foreach tt of local qs {
            local ++j
            if (abs(`tt' - `tau') < 1e-9) local col `j'
        }
        if (`col' == 0) {
            di as error "quantile `quantile' was not fitted"
            di as error "{p 4 4 2}This fit has: `qs'.{p_end}"
            exit 198
        }
    }

    tempname a
    matrix `a' = `A'[1..., `col']
    local n = rowsof(`a')

    di ""
    di as text "Profiled fixed effects, " as result "`e(idvar)'" ///
        as text ", " as result `n' as text " units"
    if (`nq' > 1) {
        di as text "Quantile: " as result "`: word `col' of `qs''"
    }

    * summarise without disturbing the user's data
    preserve
    quietly {
        clear
        svmat double `a', names(__alpha)
        rename __alpha1 alpha
    }
    if ("`detail'" != "") {
        summarize alpha, detail
    }
    else {
        summarize alpha
    }
    restore

    di as text "{p 0 2 2}These are {it:alpha}-hat_i({it:tau}), the solution" ///
        " of the profile restriction (8) at the reported {it:beta}-hat." ///
        "  Each is estimated from that unit's own T observations, so each" ///
        " is noisy: they are consistent as T grows, not as n grows, and" ///
        " their dispersion is {bf:not} an estimate of the dispersion of" ///
        " the true effects.  Do not read them as a second-stage" ///
        " regressand.{p_end}"

    if ("`generate'" != "") {
        capture confirm new variable `generate'
        if (_rc) {
            di as error "variable {bf:`generate'} already exists"
            exit 110
        }
        tempvar nid
        quietly egen long `nid' = group(`e(idvar)') if e(sample)
        quietly generate double `generate' = .
        forvalues i = 1/`n' {
            quietly replace `generate' = `a'[`i',1] if `nid' == `i'
        }
        label variable `generate' "alpha-hat_i, xtpqgmm"
        di as text "{p 0 2 2}{bf:`generate'} created: the unit's own" ///
            " alpha-hat on every row of e(sample).{p_end}"
    }

    return matrix alpha = `a'
    return scalar N_g = `n'
end
