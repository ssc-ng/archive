*! _tk_mvdiag 1.0.0  03oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Shared worker for the multivariate residual diagnostics reported by
*!   estat serial / estat archlm / estat normality / estat diag
*! after thtvar, thstvar and thtvecm. One implementation, three callers.
*!
*! It never runs an estimation command, so e() survives untouched.
*!
*! Syntax:
*!   _tk_mvdiag , EMat(name) XMat(name) LAGs(#) EQnames(string) [ WHICH(string) MODEL(string) ]

program define _tk_mvdiag, rclass
    version 15
    syntax , EMat(name) XMat(name) LAGs(integer) EQnames(string) ///
        [ WHICH(string) MODEL(string) ]

    if `lags' < 1 {
        display as error "lags() must be 1 or more"
        exit 198
    }
    local emat `emat'
    local xmat `xmat'
    local lagq `lags'
    if "`which'" == "" local which "serial arch normality"

    _tk_drop __tk_mvser __tk_mvarch __tk_mvnorm
    mata: tk_thmvdiag()

    tempname SE AR NO
    matrix `SE' = __tk_mvser
    matrix `AR' = __tk_mvarch
    matrix `NO' = __tk_mvnorm
    local nn = __tk_mvn
    local kk = __tk_mvk
    _tk_drop __tk_mvser __tk_mvarch __tk_mvnorm
    _tk_drop __tk_mvn __tk_mvk

    matrix colnames `SE' = LM LR F df1 df2 chi2_df p_LM p_LR p_F
    matrix colnames `AR' = LM LR F df1 df2 chi2_df p_LM p_LR p_F
    matrix colnames `NO' = JB p skewness kurtosis z_skew z_kurt df
    local rn ""
    foreach v of local eqnames {
        local rn `rn' `v'
    }
    capture matrix rownames `NO' = `rn' system

    display _n as text "Multivariate residual diagnostics" ///
        cond("`model'"!="", " after `model'", "") _col(52) ///
        "Observations" _col(68) "=" _col(71) as result %9.0fc `nn'
    display as text "  Equations" _col(52) "k" _col(68) "=" _col(71) ///
        as result %9.0f `kk'
    display as text "  Lag order used" _col(52) "q" _col(68) "=" _col(71) ///
        as result %9.0f `lagq'
    display as text "{hline 78}"

    if strpos("`which'", "serial") {
        display as text "  H0: no residual autocorrelation to lag `lagq' (system LM)"
        if `SE'[1,3] < . {
            display as text "     F form" _col(24) as result %10.4f `SE'[1,3] ///
                _col(36) as text "(" as result %3.0f `SE'[1,4] as text "," ///
                as result %6.0f `SE'[1,5] as text ")" _col(50) ///
                as text "p = " as result %8.4f `SE'[1,9]
            display as text "     LM" _col(24) as result %10.4f `SE'[1,1] ///
                _col(36) as text "chi2(" as result %4.0f `SE'[1,6] as text ")" ///
                _col(50) as text "p = " as result %8.4f `SE'[1,7]
            display as text "     Wilks LR" _col(24) as result %10.4f `SE'[1,2] ///
                _col(36) as text "chi2(" as result %4.0f `SE'[1,6] as text ")" ///
                _col(50) as text "p = " as result %8.4f `SE'[1,8]
        }
        else display as text "     (not computable at this lag order)"
        display as text "     Tested against the model's own design, so this is an LM"
        display as text "     test. Report the F version: the chi-square forms of"
        display as text "     multivariate LM statistics are heavily oversized here."
        display as text "{hline 78}"
    }
    if strpos("`which'", "arch") {
        display as text "  H0: no multivariate ARCH to lag `lagq'"
        display as text "      (Lutkepohl: the vech of e_t e_t' on q of its own lags)"
        if `AR'[1,3] < . {
            display as text "     F form" _col(24) as result %10.4f `AR'[1,3] ///
                _col(36) as text "(" as result %3.0f `AR'[1,4] as text "," ///
                as result %6.0f `AR'[1,5] as text ")" _col(50) ///
                as text "p = " as result %8.4f `AR'[1,9]
            display as text "     LM" _col(24) as result %10.4f `AR'[1,1] ///
                _col(36) as text "chi2(" as result %4.0f `AR'[1,6] as text ")" ///
                _col(50) as text "p = " as result %8.4f `AR'[1,7]
        }
        else display as text "     (not computable at this lag order)"
        display as text "{hline 78}"
    }
    if strpos("`which'", "normality") {
        display as text "  H0: normal errors (Jarque-Bera on the Cholesky-orthogonalised"
        display as text "      residuals, so the per-equation statistics add up)"
        display as text "     equation" _col(22) "JB" _col(34) "p" ///
            _col(44) "skewness" _col(58) "kurtosis"
        local i 0
        foreach v of local eqnames {
            local ++i
            if `NO'[`i',1] < . {
                display as text "     " as result %-14s abbrev("`v'", 14) ///
                    _col(19) %10.4f `NO'[`i',1] _col(31) %8.4f `NO'[`i',2] ///
                    _col(43) %10.4f `NO'[`i',3] _col(57) %10.4f `NO'[`i',4]
            }
        }
        local sysr = rowsof(`NO')
        if `NO'[`sysr',1] < . {
            display as text "     " as result %-14s "system" _col(19) ///
                %10.4f `NO'[`sysr',1] _col(31) %8.4f `NO'[`sysr',2] ///
                _col(43) as text "chi2(" as result %3.0f `NO'[`sysr',7] as text ")"
        }
        display as text "{hline 78}"
    }
    display as text "  A nonlinear VAR that is misspecified in its LAG structure fails"
    display as text "  the autocorrelation test first; fix that before reading anything"
    display as text "  into the regimes. Multivariate ARCH is normal in these series and"
    display as text "  is NOT what a threshold in the conditional mean captures."

    return matrix normality = `NO'
    return matrix arch      = `AR'
    return matrix serial    = `SE'
    return scalar N         = `nn'
    return scalar k_eq      = `kk'
    return scalar lags      = `lagq'
end
