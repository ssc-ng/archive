*! _tk_resdiag 1.0.0  03oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Shared worker for the residual diagnostics reported by
*!   estat serial / estat archlm / estat normality / estat mcleodli
*! after every single-equation THRESHKIT estimator. It is called by each
*! command's own estat program so there is ONE implementation.
*!
*! It never runs an estimation command, so e() survives untouched.
*!
*! Syntax:
*!   _tk_resdiag <resvar> , TOUSE(varname) NULLvars(varlist) LAGs(#)
*!                          [ ADDCONS WHICH(string) MODEL(string) ]
*!
*! nullvars() must be the model GRADIENT, not the regressors. After a linear
*! threshold fit the gradient IS the regime-split design, so the two coincide;
*! after a smooth transition it does not.

program define _tk_resdiag, rclass
    version 15
    syntax varname , TOUSE(varname) LAGs(integer) ///
        [ NULLvars(varlist) GRADmat(name) ADDCONS WHICH(string) MODEL(string) ]
    if "`nullvars'" == "" & "`gradmat'" == "" {
        display as error "give nullvars() or gradmat(): the diagnostics need the"
        display as error "model gradient as their null regressors"
        exit 198
    }

    if `lags' < 1 {
        display as error "lags() must be 1 or more"
        exit 198
    }
    local resvar  `varlist'
    local touse   `touse'
    local nullvars `nullvars'
    local lagq    `lags'
    local addcons = cond("`addcons'"!="", 1, 0)
    if "`which'" == "" local which "serial arch mcleodli normality"

    _tk_drop __tk_dserial __tk_darch __tk_dml __tk_dnorm
    mata: tk_thdiag()

    tempname SE AR ML NO
    matrix `SE' = __tk_dserial
    matrix `AR' = __tk_darch
    matrix `ML' = __tk_dml
    matrix `NO' = __tk_dnorm
    local nn = __tk_dn
    _tk_drop __tk_dserial __tk_darch __tk_dml __tk_dnorm
    _tk_drop __tk_dn

    matrix colnames `SE' = F df1 df2 p LM chi2_df p_chi2
    matrix colnames `AR' = LM df p F df1 df2 p_F
    matrix colnames `ML' = Q df p
    matrix colnames `NO' = JB p skewness kurtosis z_skew z_kurt

    display _n as text "Residual diagnostics" ///
        cond("`model'"!="", " after `model'", "") _col(52) ///
        "Observations" _col(68) "=" _col(71) as result %9.0fc `nn'
    display as text "  Lag order used" _col(52) ///
        as text "q" _col(68) "=" _col(71) as result %9.0f `lagq'
    display as text "{hline 78}"

    if strpos("`which'", "serial") {
        display as text "  H0: no error autocorrelation to lag `lagq'"
        if `SE'[1,1] < . {
            display as text "     F form" _col(26) as result %10.4f `SE'[1,1] ///
                _col(38) as text "(" as result %3.0f `SE'[1,2] as text "," ///
                as result %6.0f `SE'[1,3] as text ")" _col(52) ///
                as text "p = " as result %8.4f `SE'[1,4]
            display as text "     LM form" _col(26) as result %10.4f `SE'[1,5] ///
                _col(38) as text "chi2(" as result %3.0f `SE'[1,6] as text ")" ///
                _col(52) as text "p = " as result %8.4f `SE'[1,7]
        }
        else display as text "     (not computable at this lag order)"
        display as text "     Added to the model GRADIENT, so this is an LM test and not"
        display as text "     a residual regression. The F form is the one to report."
        display as text "{hline 78}"
    }
    if strpos("`which'", "arch") {
        display as text "  H0: no ARCH to lag `lagq' (Engle 1982, on squared residuals)"
        if `AR'[1,1] < . {
            display as text "     LM" _col(26) as result %10.4f `AR'[1,1] ///
                _col(38) as text "chi2(" as result %3.0f `AR'[1,2] as text ")" ///
                _col(52) as text "p = " as result %8.4f `AR'[1,3]
            display as text "     F form" _col(26) as result %10.4f `AR'[1,4] ///
                _col(38) as text "(" as result %3.0f `AR'[1,5] as text "," ///
                as result %6.0f `AR'[1,6] as text ")" _col(52) ///
                as text "p = " as result %8.4f `AR'[1,7]
        }
        else display as text "     (not computable at this lag order)"
        display as text "{hline 78}"
    }
    if strpos("`which'", "mcleodli") {
        display as text "  H0: no remaining conditional heteroskedasticity"
        display as text "      (McLeod-Li portmanteau on squared residuals; Li 1992 shows"
        display as text "       it stays valid after a nonlinear fit)"
        if `ML'[1,1] < . {
            display as text "     Q(`lagq')" _col(26) as result %10.4f `ML'[1,1] ///
                _col(38) as text "chi2(" as result %3.0f `ML'[1,2] as text ")" ///
                _col(52) as text "p = " as result %8.4f `ML'[1,3]
        }
        else display as text "     (not computable at this lag order)"
        display as text "{hline 78}"
    }
    if strpos("`which'", "normality") {
        display as text "  H0: normal errors (Jarque-Bera)"
        if `NO'[1,1] < . {
            display as text "     JB" _col(26) as result %10.4f `NO'[1,1] ///
                _col(38) as text "chi2(2)" _col(52) ///
                as text "p = " as result %8.4f `NO'[1,2]
            display as text "     skewness" _col(26) as result %10.4f `NO'[1,3] ///
                _col(38) as text "z = " as result %8.3f `NO'[1,5]
            display as text "     kurtosis" _col(26) as result %10.4f `NO'[1,4] ///
                _col(38) as text "z = " as result %8.3f `NO'[1,6]
        }
        else display as text "     (too few observations)"
        display as text "{hline 78}"
    }
    display as text "  A threshold model that is misspecified in its LAG structure fails"
    display as text "  the autocorrelation test first; fix that before concluding"
    display as text "  anything about the regimes. ARCH is common in these series and is"
    display as text "  NOT what a threshold in the mean captures: it argues for a robust"
    display as text "  variance (vce(robust)) or for a model of the variance, not against"
    display as text "  the threshold. Non-normality from excess kurtosis alone leaves the"
    display as text "  least-squares threshold estimator consistent."

    return matrix normality = `NO'
    return matrix mcleodli  = `ML'
    return matrix arch      = `AR'
    return matrix serial    = `SE'
    return scalar N         = `nn'
    return scalar lags      = `lagq'
end
