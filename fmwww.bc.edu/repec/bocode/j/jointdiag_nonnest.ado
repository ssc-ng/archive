*! jointdiag_nonnest 1.0.0  06oct2026
*! Joint test of a non-nested alternative AND a general error
*! specification (serial correlation, heteroskedasticity, non-normality).
*! Author: Merwan Roudane  (merwanroudane920@gmail.com)
*
*  SOURCE
*   Bera, McAleer & Pesaran (1989), BEBR Faculty WP 89-1616
*     H0 : y_t = x_t'beta  + u0t        (the null model)
*     H1 : y_t = z_t'gamma + u1t        (a NON-NESTED alternative)
*     and simultaneously u0t may be serially correlated, heteroskedastic
*     and non-normal.
*     eq.(5) is the locally equivalent alternative; eq.(6) the auxiliary
*     regression
*         y_t = x_t'b + sum_j rho_j u0_{t-j} + sum_i phi_i v_it
*                     + c1 r_t + alpha y1_hat_t + e_t
*     and eq.(7) the joint null
*         H : rho = 0 ,  phi = 0 ,  c1 = 0 ,  alpha = 0
*     where y1_hat_t is the fitted value from H1 (the Davidson-MacKinnon
*     J-test regressor).
*
*     THE TWO VARIANCE CORRECTIONS (their p.12-13).  The ordinary
*     regression formula gives the WRONG variance for two of the blocks:
*       - heteroskedasticity block : the regression omits a factor 2,
*         because Var(u^2 - s2) = 2 s4 but OLS computes s4
*         (Godfrey & Wickens 1982, p.86; Koenker 1981)
*       - skewness/kurtosis block  : the correct asymptotic variance is
*         21 s^8 / 8 while the regression formula gives 3 s^8 / 8,
*         i.e. ONE SEVENTH of the truth
*     so the decomposition is
*         (p0+1) F1  +  (q0/2) F2  +  (1/7) F3   ->d  chi2(p0+q0+2)
*     with F1 for (rho, alpha), F2 for phi and F3 for c1.
*
*     Why it matters: the usual practice is to PRE-TEST the error
*     assumptions and then run a non-nested test.  The joint test is an
*     asymptotic solution to that pre-testing problem.  Note the paper's
*     own caveat: if the joint null is rejected you cannot tell whether
*     it was the non-nested alternative or the error specification.

program define jointdiag_nonnest, rclass
    version 14.0

    syntax anything [if] [in] ,          ///
        Alternative(varlist numeric ts)   ///
        [                                 ///
        Lags(integer 1)                   ///
        HET(varlist numeric ts)           ///
        NOSKew                            ///
        Level(cilevel)                    ///
        NOTABle                           ///
        ]

    gettoken dv iv : anything
    unab dv : `dv'
    if ("`iv'" != "") unab iv : `iv'

    capture qui tsset
    if (_rc) {
        di as err "data must be {bf:tsset}"
        exit 459
    }

    marksample touse, novarlist
    markout `touse' `dv' `iv' `alternative' `het'

    tempname _h
    capture _estimates hold `_h', restore nullok

    *---- H0 fit
    qui regress `dv' `iv' if `touse'
    tempvar u0
    qui predict double `u0' if e(sample), resid
    qui replace `touse' = 0 if missing(`u0')
    local n = e(N)

    *---- H1 fit -> the J-test regressor
    qui regress `dv' `alternative' if `touse'
    tempvar y1
    qui predict double `y1' if `touse', xb

    *---- z variables for the heteroskedasticity block
    local zv "`het'"
    if ("`zv'" == "") {
        tempvar zfit
        qui predict double `zfit' if `touse', xb
        local zv "`zfit'"
        local zlab "fitted values of the alternative"
    }
    else {
        local zlab "`het'"
    }

    tempname B
    mata: _jd_nn_core("`dv'", "`iv'", "`u0'", "`y1'", "`zv'", "`touse'", ///
                      `lags', ("`noskew'" == ""), "`B'")

    local F1  = `B'[1,1]
    local d1  = `B'[1,2]
    local F2  = `B'[2,1]
    local d2  = `B'[2,2]
    local F3  = `B'[3,1]
    local d3  = `B'[3,2]
    local nn  = `B'[4,1]
    local dfr = `B'[4,2]

    local C1 = `d1' * `F1'
    local C2 = (`d2' / 2) * `F2'
    local C3 = `F3' / 7
    if (`d3' == 0) local C3 = 0

    local JT = `C1' + `C2' + `C3'
    local dJ = `d1' + `d2' + `d3'
    local pJ = chi2tail(`dJ', `JT')

    local p1 = Ftail(`d1', `dfr', `F1')
    local p2 = Ftail(`d2', `dfr', `F2')
    local p3 = .
    if (`d3' > 0) local p3 = Ftail(`d3', `dfr', `F3')

    local pC1 = chi2tail(`d1', `C1')
    local pC2 = chi2tail(`d2', `C2')
    local pC3 = .
    if (`d3' > 0) local pC3 = chi2tail(`d3', `C3')

    if ("`notable'" == "") {
        _jd_head "Joint non-nested + general error specification test"     ///
                 "H0: `dv' on `iv'      H1: `dv' on `alternative'"          ///
                 "N = `nn'   AR order = `lags'   het. variables: `zlab'"

        _jd_coln "Block of the auxiliary regression"
        di as txt %-34s "Raw F statistics (eq.6)" " {c |}"
        _jd_row "  F1  (rho, alpha)"   `F1' `d1' `p1' "serial corr. + non-nested"
        _jd_row "  F2  (phi)"          `F2' `d2' `p2' "heteroskedasticity"
        if (`d3' > 0) _jd_row "  F3  (c1)" `F3' `d3' `p3' "skewness/kurtosis"
        di as txt "{hline 35}{c +}{hline 42}"
        di as txt %-34s "Variance-corrected chi-squares" " {c |}"
        _jd_row "  (p0+1) F1"          `C1' `d1' `pC1' "no correction needed"
        _jd_row "  (q0/2) F2"          `C2' `d2' `pC2' "factor 2 (Godfrey-Wickens)"
        if (`d3' > 0) _jd_row "  (1/7) F3" `C3' `d3' `pC3' "factor 7 (see Remarks)"
        di as txt "{hline 35}{c +}{hline 42}"
        _jd_row "  JOINT"              `JT' `dJ' `pJ' "eq.(7)"
        di as txt "{hline 35}{c BT}{hline 42}"
        di as txt "  The corrections are not cosmetic: without the factor 2 the"
        di as txt "  heteroskedasticity block is twice too large, and without the"
        di as txt "  factor 7 the skewness block is seven times too large."
        di as txt "  If the joint null is rejected you cannot say whether it was the"
        di as txt "  non-nested alternative or the error specification (paper, sec.4)."
        _jd_foot ""
    }

    return scalar F1 = `F1'
    return scalar F2 = `F2'
    return scalar F3 = `F3'
    return scalar chi1 = `C1'
    return scalar chi2 = `C2'
    return scalar chi3 = `C3'
    return scalar joint = `JT'
    return scalar df    = `dJ'
    return scalar p     = `pJ'
    return scalar N     = `nn'
    return local  cmd   "jointdiag nonnest"
end



