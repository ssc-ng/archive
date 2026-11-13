*! _xturcoint_cd 1.0.0  11nov2026   (engine of: xturcoint cd)
*! Error cross-sectional dependence tests: Breusch-Pagan (1980) LM,
*! Pesaran-Ullah-Yamagata (2008) bias-adjusted LM, Pesaran (2004, 2021)
*! scaled LM and CD, Baltagi-Feng-Kao (2012) bias-corrected scaled LM
*! Author : Dr Merwan Roudane  merwanroudane920@gmail.com
*!          https://github.com/merwanroudane
*! Part of the -xturcoint- library (ports of GAUSS panel tests).
*!
*! Faithful port of the GAUSS routine pd_getCDError (tspdlib, PD_cdtests.src)
*!   by Saban Nazlioglu.
*!
*! References:
*!   Breusch, T. S., Pagan, A. R. (1980). The Lagrange multiplier test and its
*!     applications to model specification in econometrics. Review of
*!     Economic Studies 47(1): 239-253. <doi:10.2307/2297111>
*!   Pesaran, M. H., Ullah, A., Yamagata, T. (2008). A bias-adjusted LM test of
*!     error cross-section independence. Econometrics Journal 11(1): 105-127.
*!     <doi:10.1111/j.1368-423X.2007.00227.x>
*!   Pesaran, M. H. (2021). General diagnostic tests for cross-sectional
*!     dependence in panels. Empirical Economics 60(1): 13-50.
*!     <doi:10.1007/s00181-020-01875-7>
*!   Baltagi, B. H., Feng, Q., Kao, C. (2012). A Lagrange multiplier test for
*!     cross-sectional dependence in a fixed effects panel data model.
*!     Journal of Econometrics 170(1): 164-177.
*!     <doi:10.1016/j.jeconom.2012.04.004>
*!
*! Step -> code map (see -help xturcoint_cd-):
*!   unit-by-unit OLS residuals e_i = M_i y_i            -> _xtcd_run
*!   pairwise correlations rho_ij                        -> _xtcd_run
*!   LM = T sum rho^2  ~ chi2(N(N-1)/2)                   -> _xtcd_run
*!   LMadj with exact mean/variance of (T-k) rho^2        -> _xtcd_run (tr(M_iM_j))
*!   CDlm, CDlm - N/(2(T-1)), CD                          -> _xtcd_run

program _xturcoint_cd, rclass
    version 14.0
    syntax varlist(min=1 numeric ts) [if] [in] [ , ///
        noCONStant TREnd PAPer ]

    marksample touse
    qui xtset
    local ivar "`r(panelvar)'"
    local tvar "`r(timevar)'"
    if ("`ivar'"=="" | "`tvar'"=="") {
        di as err "data must be {bf:xtset} with a panel and a time variable"
        exit 459
    }
    gettoken dv xv : varlist
    local xv = strtrim("`xv'")
    tempvar cnt one trd
    qui bysort `ivar' (`tvar'): gen long `cnt' = sum(`touse')
    qui bysort `ivar' (`tvar'): replace `cnt' = `cnt'[_N]
    qui summ `cnt' if `touse', meanonly
    if r(min) != r(max) {
        di as err "the panel must be balanced over the estimation sample"
        exit 459
    }
    local T = r(max)
    qui levelsof `ivar' if `touse', local(units)
    local N : word count `units'
    if `N' < 2 {
        di as err "at least two panel units are required"
        exit 2001
    }
    local X "`xv'"
    if "`constant'" == "" {
        qui gen double `one' = 1
        local X "`one' `X'"
    }
    if "`trend'" != "" {
        qui bysort `ivar' (`tvar'): gen double `trd' = sum(`touse')
        local X "`X' `trd'"
    }
    local k : word count `X'
    if `k' == 0 {
        di as err "no regressors: drop {bf:noconstant} or add independent variables"
        exit 198
    }
    if `T' - `k' <= 8 {
        di as err "T - k must exceed 8 for the Pesaran-Ullah-Yamagata moments (T = `T', k = `k')"
        exit 2001
    }
    sort `ivar' `tvar'
    tempname RHO
    mata: _xtcd_run("`dv'", "`X'", "`touse'", `N', `T', `k', "`paper'"!="")
    matrix `RHO' = r(rho)
    matrix rownames `RHO' = `units'
    matrix colnames `RHO' = `units'
    local df = `N'*(`N'-1)/2
    local s1 = r(LM)
    local s2 = r(LMadj)
    local s3 = r(CDlm)
    local s4 = r(CDlmadj)
    local s5 = r(CD)
    local p1 = chi2tail(`df', `s1')
    local p2 = 2*normal(-abs(`s2'))
    local p3 = 2*normal(-abs(`s3'))
    local p4 = 2*normal(-abs(`s4'))
    local p5 = 2*normal(-abs(`s5'))
    local rbar = r(rbar)
    local arbar = r(arbar)

    local dlab = cond("`constant'"=="", "constant", "none")
    if "`trend'"!="" local dlab "`dlab' + trend"
    di
    di as txt "Cross-sectional dependence tests on unit-by-unit OLS residuals"
    di as txt "{hline 74}"
    di as txt "H0: cross-sectional independence (Cov(e_it, e_jt) = 0 for all i != j)"
    di as txt "Regressors : " as res "`xv'" as txt "  [deterministics: `dlab']" _col(52) "N = " as res %5.0f `N' as txt "   T = " as res %5.0f `T'
    di as txt "{hline 74}"
    di as txt _col(3) "Test" _col(42) "Statistic" _col(58) "p-value"
    di as txt "{hline 74}"
    local n1 "LM     Breusch-Pagan (1980)"
    local n2 "LMadj  Pesaran-Ullah-Yamagata (2008)"
    local n3 "CDlm   Pesaran (2004, 2021)"
    local n4 "CDlm+  Baltagi-Feng-Kao (2012)"
    local n5 "CD     Pesaran (2004, 2021)"
    forvalues j = 1/5 {
        local st = cond(`p`j''<.01,"***",cond(`p`j''<.05,"**",cond(`p`j''<.10,"*","")))
        di as txt _col(3) "`n`j''" _col(40) as res %11.4f `s`j'' _col(54) %9.4f `p`j'' as txt " `st'"
    }
    di as txt "{hline 74}"
    di as txt "LM ~ chi2(" as res `df' as txt "); others N(0,1), two-sided p-values.  *** p<0.01, ** p<0.05, * p<0.10"
    di as txt "Average correlation = " as res %7.4f `rbar' as txt "   average |correlation| = " as res %7.4f `arbar'
    if "`paper'" == "" {
        di as txt "Formulas: GAUSS tspdlib (default). GAUSS scales CD by T; the Pesaran (2021) paper"
        di as txt "          formula (scaled by sqrt(T)) gives CD = " as res %9.4f `=r(CDpaper)' as txt " (p = " as res %6.4f `=2*normal(-abs(r(CDpaper)))' as txt "); option {bf:paper} reports it."
    }
    else di as txt "Formulas: Pesaran (2021) paper for CD (option {bf:paper}); the other four tests are unchanged."

    return scalar LM      = `s1'
    return scalar p_LM    = `p1'
    return scalar df_LM   = `df'
    return scalar LMadj   = `s2'
    return scalar p_LMadj = `p2'
    return scalar CDlm    = `s3'
    return scalar p_CDlm  = `p3'
    return scalar CDlmadj   = `s4'
    return scalar p_CDlmadj = `p4'
    return scalar CD      = `s5'
    return scalar p_CD    = `p5'
    return scalar CD_paper = r(CDpaper)
    return scalar rbar    = `rbar'
    return scalar arbar   = `arbar'
    return scalar N = `N'
    return scalar T = `T'
    return scalar k = `k'
    return local formulas = cond("`paper'"!="", "paper", "gauss")
    return local depvar "`dv'"
    return local indepvars "`xv'"
    return matrix rho = `RHO'
end

mata:
void _xtcd_run(string scalar dv, string scalar xv, string scalar touse,
               real scalar N, real scalar T, real scalar k, real scalar paper)
{
    real matrix Y, X, xi, E, R, Mi, Mj, MM
    pointer(real matrix) colvector M
    real colvector yi
    real scalar i, j, TR, mu, a2, a1, v2, pij, lmbp, lmadj, cdlm, cd, cdp,
                LMadj, CDlm, CDlmadj, CD, CDp, sr, sar, np
    Y = st_data(., dv, touse)
    X = st_data(., tokens(xv), touse)
    E = J(T, N, .)
    M = J(N, 1, NULL)
    for (i=1; i<=N; i=i+1) {
        yi = Y[|(i-1)*T+1 \ i*T|]
        xi = X[|(i-1)*T+1,1 \ i*T,k|]
        M[i] = &(I(T) - xi*luinv(xi'*xi)*xi')
        E[., i] = (*M[i])*yi
    }
    R = correlation(E)
    lmbp = 0
    lmadj = 0
    cdlm = 0
    cd = 0
    cdp = 0
    sr = 0
    sar = 0
    np = 0
    a2 = 3*(((T-k-8)*(T-k+2)+24)/((T-k+2)*(T-k-2)*(T-k-4)))^2
    a1 = a2 - 1/(T-k)^2
    for (i=1; i<=N-1; i=i+1) {
        for (j=i+1; j<=N; j=j+1) {
            MM  = (*M[i])*(*M[j])
            TR  = trace(MM)
            mu  = TR/(T-k)
            v2  = (TR^2)*a1 + 2*trace(MM*MM)*a2
            pij = R[i,j]
            lmbp  = lmbp + T*pij^2
            lmadj = lmadj + ((T-k)*(pij^2) - mu)/sqrt(v2)
            cdlm  = cdlm + (T*pij^2 - 1)
            cd    = cd + T*pij
            cdp   = cdp + sqrt(T)*pij
            sr  = sr + pij
            sar = sar + abs(pij)
            np  = np + 1
        }
    }
    LMadj   = sqrt(2/(N*(N-1)))*lmadj
    CDlm    = sqrt(1/(N*(N-1)))*cdlm
    CDlmadj = CDlm - N/(2*(T-1))
    CD      = sqrt(2/(N*(N-1)))*cd
    CDp     = sqrt(2/(N*(N-1)))*cdp
    if (paper) CD = CDp
    st_rclear()
    st_numscalar("r(LM)", lmbp)
    st_numscalar("r(LMadj)", LMadj)
    st_numscalar("r(CDlm)", CDlm)
    st_numscalar("r(CDlmadj)", CDlmadj)
    st_numscalar("r(CD)", CD)
    st_numscalar("r(CDpaper)", CDp)
    st_numscalar("r(rbar)", sr/np)
    st_numscalar("r(arbar)", sar/np)
    st_matrix("r(rho)", R)
}
end
