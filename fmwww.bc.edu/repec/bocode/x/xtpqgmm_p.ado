*! xtpqgmm_p 1.0.0  14oct2026
*! predict after xtpqgmm.  Reached through e(predict); never called directly.
*!
*! Author: Dr Merwan Roudane <merwanroudane920@gmail.com>
*!
*! WHAT IS DELIBERATELY NOT HERE.  There is no probability-style statistic and
*! no `pr' option.  The smoothed indicator G_h((alpha_i + x'beta - y)/h) that
*! the estimator evaluates looks like a conditional CDF and is not one: the
*! fourth-order kernel of Section 6 takes NEGATIVE values, so G_h leaves [0,1]
*! -- the package's own t01 measures G(-1/sqrt(3)) = -0.0533.  Offering it as
*! "the predicted probability that y <= the fit" would hand the user a number
*! that can be negative or exceed one.  It is a device for making the moment
*! condition differentiable, nothing more.

program xtpqgmm_p
    version 17.0

    if `"`e(cmd)'"' != "xtpqgmm" {
        error 301
    }

    syntax newvarname [if] [in] ,                      ///
        [ XB ALpha XBA Residuals                        ///
          EQuation(string) Quantile(real -1) SCores ]

    if ("`scores'" != "") {
        di as error "{bf:scores} is not available after {bf:xtpqgmm}"
        di as error "{p 4 4 2}The estimator is GMM on a profiled moment," ///
            " not maximum likelihood, so there is no score to predict." ///
            "  The moment vector at the estimate is in {bf:e(mvec)} and" ///
            " its long-run variance in {bf:e(Omega)}.{p_end}"
        exit 198
    }

    local nopt : word count `xb' `alpha' `xba' `residuals'
    if (`nopt' > 1) {
        di as error "only one statistic may be requested"
        exit 198
    }
    if (`nopt' == 0) {
        local xba xba
        di as text "(option {bf:xba} assumed; fitted conditional quantile)"
    }

    * ------------------------------------------------- which quantile is meant
    local nq = e(n_q)
    local qs `e(quantiles)'
    local col 1
    if (`nq' > 1) {
        if (`"`equation'"' != "") {
            local eqn = subinstr(`"`equation'"', "#", "", .)
            local eqn = trim("`eqn'")
            local ens `e(eqnames)'
            local col 0
            local j 0
            foreach en of local ens {
                local ++j
                if ("`en'" == "`eqn'") local col `j'
            }
            if (`col' == 0) {
                di as error "equation {bf:`equation'} is not in this fit"
                di as error "{p 4 4 2}The equations are: `ens'.{p_end}"
                exit 198
            }
        }
        else if (`quantile' >= 0) {
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
        else {
            di as error "this fit has `nq' quantiles; say which one"
            di as error "{p 4 4 2}Use {bf:equation(}{it:q50}{bf:)} or" ///
                " {bf:quantile(50)}.  The quantiles are: `qs'.{p_end}"
            exit 198
        }
    }
    local tau : word `col' of `qs'

    * ------------------------------------------------------------- the pieces
    marksample touse, novarlist
    quietly replace `touse' = 0 if !e(sample)

    tempvar idx
    if ("`alpha'" == "") {
        * x'beta for the chosen quantile, built from e(b) by hand because
        * _predict would use the whole stacked vector across quantiles
        tempname bb
        matrix `bb' = e(b)
        local vn : colnames e(b)
        local d  = e(df_m)
        local lo = (`col'-1)*`d' + 1
        quietly generate double `idx' = 0 if `touse'
        forvalues j = 1/`d' {
            local pos = `lo' + `j' - 1
            local v : word `pos' of `vn'
            * Time-series operators survive in the coefficient names, so the
            * variable has to be rebuilt rather than looked up.  fvrevar has
            * no generate() option -- it names the temporary itself and
            * reports it in r(varlist) -- and for a plain variable it hands
            * back that same variable, which is what we want.
            quietly fvrevar `v'
            local tv `r(varlist)'
            quietly replace `idx' = `idx' + `bb'[1,`pos']*`tv' if `touse'
        }
    }

    if ("`alpha'" != "" | "`xba'" != "" | "`residuals'" != "") {
        tempname A
        matrix `A' = e(alpha)
        tempvar nid av
        quietly egen long `nid' = group(`e(idvar)') if e(sample)
        quietly generate double `av' = . if `touse'
        local n = rowsof(`A')
        forvalues i = 1/`n' {
            quietly replace `av' = `A'[`i',`col'] if `nid' == `i' & `touse'
        }
    }

    * ------------------------------------------------------------- the answer
    if ("`xb'" != "") {
        generate double `varlist' = `idx' if `touse'
        label variable `varlist' "xb, tau = `tau'"
    }
    else if ("`alpha'" != "") {
        generate double `varlist' = `av' if `touse'
        label variable `varlist' "alpha-hat_i, tau = `tau'"
    }
    else if ("`xba'" != "") {
        generate double `varlist' = `av' + `idx' if `touse'
        label variable `varlist' "fitted Q(`tau'), xtpqgmm"
    }
    else {
        quietly generate double `varlist' = `e(depvar)' - `av' - `idx' if `touse'
        label variable `varlist' "residual at tau = `tau'"
        quietly count if `varlist' <= 0 & `touse'
        local below = r(N)
        quietly count if `touse'
        local tot = r(N)
        di as text "{p 0 2 2}" as result %5.3f `below'/`tot' as text ///
            " of the estimation sample lies at or below the fitted" ///
            " quantile; the target is " as result `tau' as text "." ///
            "  The two need not match: equation (8) imposes the quantile" ///
            " restriction {it:within} each unit through the smoothed" ///
            " indicator, not as an unconditional proportion.{p_end}"
    }
end
