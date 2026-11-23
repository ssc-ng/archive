*! comfactest v1.23.7 - November 2026
*! Testing common factor (COMFAC) restrictions for EGLS estimation with AR(1) to AR(4) errors
*! lr: likelihood ratio statistic T*ln(SSRr/SSRu) (Sargan 1964; Hendry and Mizon 1978; log-likelihood and LR test as defined in PcGive); SSRr is the smallest error sum of squares of the restricted model over the stationary region (grid search over the partial autocorrelations, then simplex search); lrnogrid adds the statistic whose restricted model is estimated without a grid search, by Cochrane-Orcutt started from OLS and iterated to full convergence
*! ftest: asymptotic F test of Davidson and MacKinnon (1999), F = ((SSRr-SSRu)/r)/(SSRu/(T-K)), with SSRr the smallest error sum of squares of the restricted model over the stationary region (grid search over the partial autocorrelations, then simplex search)
*! ftestco (ar(1) only): the same F with the restricted model estimated by Cochrane-Orcutt, a faithful port of gretl "ar1" followed by "modtest --comfac"
*! wald: Wald test of Sargan (1980, Econometrica 48, 879-897), determinantal constraints from the row-reduction algorithm of sections 3-4 and Appendix B; reproduces the COMFAC Wald test table of PcGive 17 to the five digits PcGive prints
*! Source: gretl 2026e-git (commit 7515c74, 18 Nov 2026), lib/src/compare.c comfac_test() and lib/src/estimate.c estimate_rho(), ar1_lsq(), XTX_XTy(), cholbeta(), autores(), rhohat(), hilu_search(), ar_model()
*! Author of the port: H. Ozan Eruygur

program define comfactest, rclass
    version 14
    syntax varlist(min=2 ts numeric) [if] [in] [, AR(integer 1) LRNOGRID FTEST FTESTCO REG PRINT]

    * order of the autoregressive error: ar(1) (default), ar(2), ar(3) or ar(4)
    if `ar' < 1 | `ar' > 4 {
        display as error "ar() must be 1, 2, 3 or 4"
        exit 198
    }

    * the Wald test of Sargan (1980) and the likelihood ratio test are always reported
    * ftest adds the asymptotic F test of Davidson and MacKinnon (1999); ftestco adds the gretl F test (Cochrane-Orcutt)
    local dowald = 1
    local dolr = 1
    local dodm = ("`ftest'" != "")
    * lrnogrid adds the likelihood ratio test whose restricted model is estimated without a grid search
    local dong = ("`lrnogrid'" != "")
    local doftest = ("`ftestco'" != "")

    * the Cochrane-Orcutt F test is the gretl test, which exists only for AR(1) errors
    if `doftest' == 1 & `ar' > 1 {
        display as error "ftestco is available only with ar(1)"
        exit 198
    }
    * time-series setup
    quietly tsset
    local tvar `r(timevar)'
    local pvar `r(panelvar)'
    local tdelta = r(tdelta)
    local tunit "`r(unit1)'"
    local tfmt : format `tvar'
    if "`pvar'" != "" {
        display as error "comfactest is for a single time series; panel data are not supported"
        exit 198
    }

    gettoken dep indep : varlist
    local hascons = 1
    * estimation sample: no gaps and no missing values inside it (gretl stops in that case)
    marksample touse
    sort `tvar'
    quietly count if `touse'
    local N = r(N)
    if `N' < 3 + `ar' {
        display as error "insufficient observations"
        exit 2001
    }
    summarize `tvar' if `touse', meanonly
    local span = (r(max) - r(min)) / `tdelta' + 1
    if `span' != `N' {
        display as error "missing values or gaps inside the sample range are not allowed"
        exit 498
    }

    * resolve time-series operators into temporary variables
    tsrevar `dep'
    local ydata `r(varlist)'
    tsrevar `indep'
    local xdata `r(varlist)'

    * the gretl refinements hilu, nocorc and loose are not offered; only the test results are shown unless reg is specified
    local dohilu = 0
    local nocorc = 0
    local doloose = 0
    local doquiet = ("`reg'" == "")
    * reg shows the unrestricted regression, the restricted models and, for ar(2) to ar(4), the sequence of Wald tests
    local dodetail = ("`reg'" != "")

    * first and last observation of the augmented regression sample
    summarize `tvar' if `touse', meanonly
    local tfirst = r(min) + `ar' * `tdelta'
    local tlast = r(max)
    local obs1 = strtrim(string(`tfirst', "`tfmt'"))
    local obs2 = strtrim(string(`tlast', "`tfmt'"))

    * print: the two models and the common factor restrictions in symbols:
    * restricted model with beta0, beta1, ... and rho; unrestricted model with lambda1, lambda2, ... in the order
    * constant, lags of the dependent variable, regressors, first lags of the regressors, second lags, ...
    if "`print'" != "" {
        local nx : word count `indep'
        local nres = `ar' * `nx'
        local T ""
        local R ""
        local U ""
        local E ""
        local m = 0
        if `hascons' {
            local m = 1
            local T "|+ lambda1"
            local R "|+ beta0"
            local E "|lambda1 = beta0*(1"
        }
        forvalues l = 1/`ar' {
            local rl "rho`l'"
            if `ar' == 1 {
                local rl "rho"
            }
            local m = `m' + 1
            local my`l' = `m'
            local T "`T'|+ lambda`m'*`dep'(-`l')"
            local U "`U'|+ `rl'*u(-`l')"
            if `hascons' {
                local E "`E' - `rl'"
            }
        }
        if `hascons' {
            local E "`E'),"
        }
        forvalues l = 1/`ar' {
            local rl "rho`l'"
            if `ar' == 1 {
                local rl "rho"
            }
            local E "`E'|lambda`my`l'' = `rl',"
        }
        local j = 0
        foreach x of local indep {
            local j = `j' + 1
            local m = `m' + 1
            local mx`j' = `m'
            local T "`T'|+ lambda`m'*`x'"
            local R "`R'|+ beta`j'*`x'"
            local E "`E'|lambda`m' = beta`j'"
            if `j' < `nx' {
                local E "`E',"
            }
        }
        forvalues l = 1/`ar' {
            local j = 0
            foreach x of local indep {
                local j = `j' + 1
                local m = `m' + 1
                local mx`j'_`l' = `m'
                local T "`T'|+ lambda`m'*`x'(-`l')"
            }
        }
        local T = substr("`T'", 4, .)
        local R = substr("`R'", 4, .)
        local U = substr("`U'", 4, .)
        local E = substr("`E'", 2, .)
        display ""
        display as text "Restricted model (static regression with AR(`ar') errors):"
        _cft_wrap "  `dep' =" "`R'|+ u"
        _cft_wrap "  u =" "`U'|+ e"
        display ""
        display as text "Unrestricted model (lags 1 to `ar' of every variable):"
        _cft_wrap "  `dep' =" "`T'|+ e"
        display ""
        display as text "Common factor restrictions (`nres'):"
        forvalues l = 1/`ar' {
            forvalues j = 1/`nx' {
                display as text "  lambda`mx`j'_`l'' = -lambda`my`l''*lambda`mx`j''"
            }
        }
        display ""
        display as text "H0:"
        forvalues l = 1/`ar' {
            forvalues j = 1/`nx' {
                display as text "  lambda`mx`j'_`l'' + lambda`my`l''*lambda`mx`j'' = 0"
            }
        }
        display ""
        display as text "Under H0:"
        _cft_wrap " " "`E'"
    }

    tempname bu wtab
    local lrfail = 0
    local lrrc = 0
    local cofail = 0
    local dmfail = 0
    local ngfail = 0
    local ngrc = 0
    mata: _cft_main("`ydata'", "`xdata'", "`touse'", `hascons', `ar', `doftest', `dowald', `dolr', `dohilu', `nocorc', `doloose', `doquiet', "`dep'", "`indep'", "`bu'", `dodetail', "`wtab'", `dodm', `dong')

    return add
    if `dowald' == 1 {
        matrix colnames `wtab' = factors chi2 df p chi2_incr df_incr p_incr
        return matrix wald = `wtab', copy
    }
    return matrix b_aug = `bu'

    * augmented regression shown as a regress coefficient table; the stored estimates of the user are kept
    if `doquiet' == 0 {
        local laglist
        forvalues l = 1/`ar' {
            local laglist `laglist' L`l'.`dep'
            foreach v of local indep {
                local laglist `laglist' L`l'.`v'
            }
        }
        tempvar touse2
        quietly generate byte `touse2' = `touse' & `tvar' >= `tfirst'
        tempname hold
        _estimates hold `hold', nullok restore
        display
        display as text "Augmented regression for common factor test"
        display as text "Sample: " as result "`obs1'" as text " thru " as result "`obs2'" as text "{col 49}Number of obs{col 67}= " as result %10.0fc return(N)
        display
        capture noisily regress `dep' `indep' `laglist' if `touse2', noheader
        _estimates unhold `hold'
        display as text "Sum of squared residuals = " as result %15.10g return(ssr_u)
    }

    * test results
    display
    display as text "Test of common factor restrictions for EGLS with AR(`ar') errors"
    display
    display as text "H0: the common factor restrictions are valid (EGLS with AR(`ar') errors can be used)"
    display
    * the df2 column is shown only when an F test is requested
    local twod = (`dodm' == 1 | `doftest' == 1)
    local hw = 36
    local gap ""
    local dfhead %8s "df"
    if `twod' == 1 {
        local hw = 44
        local gap %8s ""
        local dfhead %8s "df1" %8s "df2"
    }
    display as text "{hline 13}{c TT}{hline `hw'}"
    display as text %12s "Test" " {c |}" %12s "Statistic" `dfhead' %12s "p-value"
    display as text "{hline 13}{c +}{hline `hw'}"
    if `dowald' == 1 {
        display as text %12s "Wald chi2" " {c |}" as result %12.4f return(chi2) %8.0f return(df_chi2) `gap' %12.4f return(p_chi2)
    }
    if `dolr' == 1 & `lrfail' == 1 {
        display as text %12s "LR chi2" " {c |}" as result %12s "." %8s "." `gap' %12s "."
    }
    if `dolr' == 1 & `lrfail' == 0 {
        display as text %12s "LR chi2" " {c |}" as result %12.4f return(lr) %8.0f return(df_lr) `gap' %12.4f return(p_lr)
    }
    if `dong' == 1 & `ngfail' == 0 {
        display as text %12s "LR (no grid)" " {c |}" as result %12.4f return(lr_nogrid) %8.0f return(df_lr_nogrid) `gap' %12.4f return(p_lr_nogrid)
    }
    if `dong' == 1 & `ngfail' != 0 {
        display as text %12s "LR (no grid)" " {c |}" as result %12s "." %8s "." `gap' %12s "."
    }
    if `dodm' == 1 & `dmfail' == 0 {
        display as text %12s "F" " {c |}" as result %12.4f return(F) %8.0f return(df_n) %8.0f return(df_d) %12.4f return(p)
    }
    if `dodm' == 1 & `dmfail' != 0 {
        display as text %12s "F" " {c |}" as result %12s "." %8s "." %8s "." %12s "."
    }
    if `doftest' == 1 & `cofail' == 0 {
        display as text %12s "F (CO)" " {c |}" as result %12.4f return(F_co) %8.0f return(df_n_co) %8.0f return(df_d_co) %12.4f return(p_co)
    }
    if `doftest' == 1 & `cofail' != 0 {
        display as text %12s "F (CO)" " {c |}" as result %12s "." %8s "." %8s "." %12s "."
    }
    display as text "{hline 13}{c BT}{hline `hw'}"
    if `dowald' == 1 {
        display as text "- Wald (Sargan, 1980) is the main test; it uses the unrestricted model only."
    }
    if `dolr' == 1 {
        display as text "- LR (Sargan, 1964) needs the restricted model, which is estimated with a"
        display as text "  grid search."
    }
    if `dowald' == 1 & `dolr' == 1 {
        display as text "- If the two tests (Wald and LR) disagree at the 5% level, a Wald test that"
        display as text "  does not reject is not by itself evidence that the common factor"
        display as text "  restrictions hold (Mizon and Hendry, 1980)."
    }
    if `dong' == 1 {
        display as text "- LR (no grid) is the same test without a grid search; PcGive computes the"
        display as text "  LR test in a similar way. Its disadvantage is that the iteration can stop"
        display as text "  at a local minimum, which makes the statistic too large and the p-value"
        display as text "  too small."
    }
    if `dodm' == 1 {
        display as text "- F is an additional asymptotic F test (Davidson and MacKinnon, 1999) with"
        display as text "  a grid search: it uses the same restricted model as LR. The usual exact F"
        display as text "  test does not apply because the restrictions are nonlinear (Dougherty,"
        display as text "  2006)."
    }
    if `doftest' == 1 {
        display as text "- F (CO) is the same F test without a grid search: the restricted model is"
        display as text "  estimated by Cochrane-Orcutt as in gretl. Its disadvantage is that the"
        display as text "  iteration can stop at a local minimum, which makes the statistic too"
        display as text "  large and the p-value too small."
    }
    if `dodm' == 1 & `dmfail' != 0 {
        display as text "- F was not computed: the restricted model could not be estimated."
    }
    if `doftest' == 1 & `cofail' != 0 {
        local cowhy "numerical error in the Cochrane-Orcutt iteration"
        if `cofail' == 1 {
            local cowhy "Cochrane-Orcutt did not converge in 100 iterations; gretl stops too"
        }
        if `cofail' == 2 {
            local cowhy "Cochrane-Orcutt gives a rho outside (-1, 1); gretl stops too"
        }
        display as text "- F (CO) was not computed: the restricted model could not be estimated"
        display as text "  (`cowhy')."
    }
    if `dolr' == 1 & `lrfail' == 1 {
        display as text "- LR was not computed: the restricted model could not be estimated."
    }
    if `dong' == 1 & `ngfail' != 0 {
        local ngwhy "numerical error"
        if `ngrc' == 1 {
            local ngwhy "dependent variable is zero after transformation"
        }
        if `ngrc' == 3 {
            local ngwhy "exact or near collinearity in the Cochrane-Orcutt iteration"
        }
        if `ngrc' == 4 {
            local ngwhy "error sum of squares is not > 0"
        }
        if `ngrc' == 5 {
            local ngwhy "convergence not achieved in 10000 iterations"
        }
        display as text "- LR (no grid) was not computed: the restricted model could not be estimated"
        display as text "  (`ngwhy')."
    }
    if `dowald' == 1 & `ar' > 1 & `dodetail' == 1 {
        display
        display as text "Sequence of Wald tests (Sargan, 1980), 1 to `ar' common factors"
        display
        display as text "{hline 13}{c TT}{hline 31}{c TT}{hline 30}"
        display as text %12s "Common" " {c |}" %20s "Cumulative" %10s "" " {c |}" %20s "Incremental"
        display as text %12s "factors" " {c |}" %12s "chi2" %6s "df" %12s "p-value" " {c |}" %12s "chi2" %6s "df" %12s "p-value"
        display as text "{hline 13}{c +}{hline 31}{c +}{hline 30}"
        forvalues i = 1/`ar' {
            display as text %12.0f `wtab'[`i',1] " {c |}" as result %12.4f `wtab'[`i',2] %6.0f `wtab'[`i',3] %12.4f `wtab'[`i',4] as text " {c |}" as result %12.4f `wtab'[`i',5] %6.0f `wtab'[`i',6] %12.4f `wtab'[`i',7]
        }
        display as text "{hline 13}{c BT}{hline 31}{c BT}{hline 30}"
    }
end

* displays "lead term term ..." wrapped at 78 columns; the terms are separated by |
program define _cft_wrap
    version 14
    args lead terms
    local line "`lead'"
    local pad = strlen("`line'")
    local rest "`terms'"
    while "`rest'" != "" {
        gettoken t rest : rest, parse("|")
        if "`t'" != "|" {
            if strlen("`line'") + strlen("`t'") + 1 > 78 & strlen("`line'") > `pad' {
                display as text "`line'"
                local line : display _dup(`pad') " "
            }
            local line "`line' `t'"
        }
    }
    display as text "`line'"
end

version 14
mata:

// X'X (packed upper triangle, row by row), X'y, sum of y and y'y
// literal port of XTX_XTy() in gretl lib/src/estimate.c (no weights, no Prais-Winsten)
// returns 0 if fine, 1 if y'y <= 0, 2 if a diagonal element of X'X is below DBL_EPSILON (column index in badcol)
real scalar _cft_xtxy(real colvector y, real matrix X, real scalar rho, real colvector xpx, real colvector xpy, real scalar ysum, real scalar ypy, real scalar badcol)
{
    real scalar n, k, qdiff, t1, t, i, j, m, x

    n = rows(y)
    k = cols(X)
    qdiff = (rho != 0)
    t1 = (qdiff ? 2 : 1)
    badcol = 0

    ysum = 0
    ypy = 0
    for (t=t1; t<=n; t++) {
        x = y[t]
        if (qdiff) {
            x = x - rho * y[t-1]
        }
        ysum = ysum + x
        ypy = ypy + x * x
    }
    if (ypy <= 0) {
        return(1)
    }

    xpx = J(k*(k+1)/2, 1, 0)
    xpy = J(k, 1, 0)
    m = 0

    for (i=1; i<=k; i++) {
        for (j=i; j<=k; j++) {
            x = 0
            if (qdiff) {
                for (t=t1; t<=n; t++) {
                    x = x + (X[t,i] - rho * X[t-1,i]) * (X[t,j] - rho * X[t-1,j])
                }
            }
            else {
                for (t=t1; t<=n; t++) {
                    x = x + X[t,i] * X[t,j]
                }
            }
            if (i == j & x < epsilon(1)) {
                badcol = i
                return(2)
            }
            m = m + 1
            xpx[m] = x
        }
        x = 0
        if (qdiff) {
            for (t=t1; t<=n; t++) {
                x = x + (y[t] - rho * y[t-1]) * (X[t,i] - rho * X[t-1,i])
            }
        }
        else {
            for (t=t1; t<=n; t++) {
                x = x + y[t] * X[t,i]
            }
        }
        xpy[i] = x
    }

    return(0)
}

// Cholesky solution; literal port of cholbeta() in gretl lib/src/estimate.c
// all C arrays are 0-based, so every index below carries a +1
// returns 0 if fine, 9999 if xpx[0] <= 0, otherwise the (1-based) column at which the singularity test fails
real scalar _cft_cholbeta(real colvector xpx, real colvector xpy, real scalar nc, real colvector b, real scalar rss)
{
    real scalar i, j, k, kk, l, jm1, e, d, d1, d2, test, xx

    if (xpx[1] <= 0) {
        return(9999)
    }

    e = 1 / sqrt(xpx[1])
    xpx[1] = e
    xpy[1] = xpy[1] * e
    for (i=1; i<nc; i++) {
        xpx[i+1] = xpx[i+1] * e
    }

    kk = nc

    for (j=1; j<nc; j++) {
        // diagonal elements
        d = 0
        d1 = 0
        k = j
        jm1 = j
        for (l=1; l<=jm1; l++) {
            xx = xpx[k+1]
            d1 = d1 + xx * xpy[l]
            d = d + xx * xx
            k = k + nc - l
        }
        d2 = xpx[kk+1] - d
        test = d2 / xpx[kk+1]
        // check for singularity (TINY = 8.0e-09 in gretl)
        if (test < 8.0e-09) {
            rss = -1
            return(j+1)
        }
        e = 1 / sqrt(d2)
        xpx[kk+1] = e
        xpy[j+1] = (xpy[j+1] - d1) * e
        // off-diagonal elements
        for (i=j+1; i<nc; i++) {
            kk = kk + 1
            d = 0
            k = j
            for (l=1; l<=jm1; l++) {
                d = d + xpx[k+1] * xpx[k-j+i+1]
                k = k + nc - l
            }
            xpx[kk+1] = (xpx[kk+1] - d) * e
        }
        kk = kk + 1
    }

    kk = kk - 1

    // regression sum of squares
    d = 0
    for (j=0; j<nc; j++) {
        d = d + xpy[j+1] * xpy[j+1]
    }
    rss = d

    // back-solve for the coefficients
    b = J(nc, 1, 0)
    b[nc] = xpy[nc] * xpx[kk+1]
    for (j=nc-2; j>=0; j--) {
        d = xpy[j+1]
        for (i=nc-1; i>j; i--) {
            kk = kk - 1
            d = d - b[i+1] * xpx[kk+1]
        }
        kk = kk - 1
        b[j+1] = d * xpx[kk+1]
    }

    return(0)
}

// least squares with optional quasi-differencing; port of ar1_lsq() + regress() in gretl
// rho != 0: first observation is dropped and ESS = y'y - regression sum of squares (as in gretl)
// rho == 0: ESS is the sum of squared residuals (make_ess() in gretl)
// returns 0 if fine, 1 = zero dependent variable, 3 = singular (column in badcol), 4 = negative ESS, 9999 = numerical error
real scalar _cft_lsq(real colvector y, real matrix X, real scalar rho, real colvector b, real scalar ess, real scalar nobs, real scalar badcol)
{
    real colvector xpx, xpy
    real scalar ysum, ypy, rss, rc, n, k, t, i, yhat, ut

    n = rows(y)
    k = cols(X)
    badcol = 0
    nobs = n - (rho != 0)

    rc = _cft_xtxy(y, X, rho, xpx, xpy, ysum, ypy, badcol)
    if (rc == 1) {
        return(1)
    }
    if (rc == 2) {
        return(3)
    }

    rc = _cft_cholbeta(xpx, xpy, k, b, rss)
    if (rc == 9999) {
        return(9999)
    }
    if (rc > 0) {
        badcol = rc
        return(3)
    }

    if (rho != 0) {
        ess = ypy - rss
    }
    else {
        ess = 0
        for (t=1; t<=n; t++) {
            yhat = 0
            for (i=1; i<=k; i++) {
                yhat = yhat + b[i] * X[t,i]
            }
            ut = y[t] - yhat
            ess = ess + ut * ut
        }
    }

    // ESSZERO = 1.0e-22 in gretl
    if (abs(ess) < 1.0e-22) {
        ess = 0
    }
    else if (ess < 0) {
        return(4)
    }

    return(0)
}

// first-order autocorrelation of OLS residuals; port of hatvars() + rhohat() in gretl
real scalar _cft_rhohat(real colvector y, real matrix X, real colvector b)
{
    real colvector u
    real scalar n, k, t, i, yhat, num, den, rho

    n = rows(y)
    k = cols(X)
    u = J(n, 1, 0)
    for (t=1; t<=n; t++) {
        yhat = 0
        for (i=1; i<=k; i++) {
            yhat = yhat + b[i] * X[t,i]
        }
        u[t] = y[t] - yhat
    }
    num = 0
    den = 0
    for (t=2; t<=n; t++) {
        num = num + u[t] * u[t-1]
        den = den + u[t-1] * u[t-1]
    }
    if (den < epsilon(1)) {
        return(.)
    }
    rho = num / den
    if (rho > 1 | rho < -1) {
        // gretl switches to altrho(): the correlation of u(t) and u(t-1)
        // this branch is NOT a literal port of gretl_corr(); it uses Mata correlation()
        rho = correlation((u[|2 \ n|], u[|1 \ n-1|]))[2,1]
    }
    return(rho)
}

// rho from the residuals of the untransformed equation; literal port of autores() in gretl
real scalar _cft_autores(real colvector y, real matrix X, real colvector b)
{
    real colvector u
    real scalar n, k, t, i, ut, num, den

    n = rows(y)
    k = cols(X)
    u = J(n, 1, 0)
    num = 0
    den = 0
    for (t=1; t<=n; t++) {
        ut = y[t]
        for (i=1; i<=k; i++) {
            ut = ut - b[i] * X[t,i]
        }
        u[t] = ut
        if (t > 1) {
            num = num + u[t] * u[t-1]
            den = den + u[t-1] * u[t-1]
        }
    }
    return(num / den)
}

// generalized Cochrane-Orcutt for AR(p) errors with lags 1..p; port of ar_model() in gretl lib/src/estimate.c
// tight = 0, as in gretl: at most 20 iterations, stopping when the percentage change in ESS is not above 0.005
// tight = 1, for the likelihood ratio test: the same iteration carried on until the percentage change in ESS
//            is not above 1.0e-11 (at most 10000 iterations); niter returns the number of iterations done
// each pass minimizes the same sum of squares, first over rho given the coefficients, then over the
// coefficients given rho, so the ESS cannot increase from one pass to the next
// returns 0 if fine, 5 if tight = 1 and no convergence, otherwise the error code of _cft_lsq()
real scalar _cft_arp(real colvector y, real matrix X, real scalar p, real colvector b, real colvector rho, real scalar ess, real scalar nobs, real scalar quiet, real scalar tight, real scalar niter)
{
    real colvector u, uu, ys
    real matrix U, Xs
    real scalar n, k, t, j, i, xx, rc, badcol, diff, essnew, essrho, nr, iter, maxit, tol

    maxit = (tight ? 10000 : 20)
    tol = (tight ? 1.0e-11 : 0.005)
    niter = 0

    n = rows(y)
    k = cols(X)

    // first pass: OLS on the full sample
    rc = _cft_lsq(y, X, 0, b, essnew, nobs, badcol)
    if (rc) {
        return(rc)
    }

    if (!quiet & !tight) {
        printf("\n{txt}Generalized Cochrane-Orcutt estimation\n\n")
        printf("{txt}                 ITER             ESS           %% CHANGE\n\n")
    }

    diff = 1.0e6
    ess = 0
    u = J(n, 1, 0)
    U = J(n-p, p, 0)
    ys = J(n-p, 1, 0)
    Xs = J(n-p, k, 0)

    for (iter=1; iter<=maxit & diff>tol; iter++) {
        // residuals of the untransformed equation
        for (t=1; t<=n; t++) {
            xx = y[t]
            for (j=1; j<=k; j++) {
                xx = xx - b[j] * X[t,j]
            }
            u[t] = xx
        }
        // estimate the rho terms: OLS of u(t) on u(t-1), ..., u(t-p), no constant
        uu = u[|p+1 \ n|]
        for (i=1; i<=p; i++) {
            for (t=p+1; t<=n; t++) {
                U[t-p,i] = u[t-i]
            }
        }
        rc = _cft_lsq(uu, U, 0, rho, essrho, nr, badcol)
        if (rc) {
            return(rc)
        }
        // rho-transform the data
        for (t=p+1; t<=n; t++) {
            xx = y[t]
            for (j=1; j<=p; j++) {
                xx = xx - rho[j] * y[t-j]
            }
            ys[t-p] = xx
        }
        for (i=1; i<=k; i++) {
            for (t=p+1; t<=n; t++) {
                xx = X[t,i]
                for (j=1; j<=p; j++) {
                    xx = xx - rho[j] * X[t-j,i]
                }
                Xs[t-p,i] = xx
            }
        }
        // estimate the transformed model
        rc = _cft_lsq(ys, Xs, 0, b, essnew, nobs, badcol)
        if (rc) {
            return(rc)
        }
        if (iter > 1) {
            diff = abs(100 * (essnew - ess) / ess)
        }
        ess = essnew
        niter = iter
        if (!quiet & !tight) {
            if (iter > 1) {
                printf("{res}                %3.0f %20.6f %13.3f\n", iter, ess, diff)
            }
            else {
                printf("{res}                %3.0f %20.6f\n", iter, ess)
            }
        }
    }

    if (tight & diff > tol) {
        return(5)
    }

    return(0)
}

void _cft_fail(real scalar rc, string scalar where)
{
    if (rc == 1) {
        errprintf("%s: dependent variable is zero after transformation\n", where)
    }
    else if (rc == 3) {
        errprintf("%s: exact or near collinearity among the regressors\n", where)
    }
    else if (rc == 4) {
        errprintf("%s: error sum of squares is not > 0\n", where)
    }
    else if (rc == 5) {
        errprintf("%s: convergence not achieved in 10000 iterations\n", where)
    }
    else {
        errprintf("%s: numerical error\n", where)
    }
    exit(498)
}

// coefficient table
void _cft_table(string rowvector names, real colvector b)
{
    real scalar i

    printf("{txt}{hline 17}{c TT}{hline 22}\n")
    printf("{txt}%16s {c |} coefficient\n", "")
    printf("{txt}{hline 17}{c +}{hline 22}\n")
    for (i=1; i<=rows(b); i++) {
        printf("{txt}%16s {c |} {res}%18.10g\n", substr(names[i], 1, 16), b[i])
    }
    printf("{txt}{hline 17}{c BT}{hline 22}\n")
}

// names that are safe as matrix column names
string rowvector _cft_stripe(string rowvector names)
{
    real scalar i
    string rowvector s

    s = names
    for (i=1; i<=cols(s); i++) {
        s[i] = subinstr(subinstr(subinstr(s[i], ".", "_"), "(-", "_"), ")", "")
        s[i] = substr(s[i], 1, 32)
    }
    return(s)
}

// constraint functions for r common factors among the n lag polynomials in the rows of Psi (each of degree f)
// algorithm of Sargan (1980), sections 3-4 and Appendix B, equal lag lengths (cases of type 1):
//   the rows of Psi and their right-shifted copies are stacked (k+1 blocks, k the smallest integer with (n-1)k >= f-r)
//   and the first f+k+n-r rows are reduced by elementary row operations; a row left with only r elements that are
//   not zero by construction is a vanishing row and is never used as a pivot; when a row changes, every later
//   right-shifted copy of the same polynomial is replaced by the shifted new row; the reduction stops with n-1
//   vanishing rows, whose r(n-1) elements, each multiplied by the product of the pivots used up to the stage at
//   which its row vanished (determinantal form), are the constraints
// returns a column vector of r(n-1) values, or J(0,1,.) if a pivot is zero or the reduction fails
// the arithmetic is complex so that exact derivatives can be taken by the complex-step method (see _cft_swald)
complex colvector _cft_sargan(complex matrix Psi, real scalar r)
{
    complex matrix M
    complex colvector pivat, g
    complex scalar piv
    real colvector pol, shf, lo, hi, van, used, cand
    real scalar n, f, k, nr, ncol, i, j, s, t, c, pr, nc, ii, sh, m

    n = rows(Psi)
    f = cols(Psi) - 1
    k = 0
    while ((n - 1) * k < f - r) {
        k = k + 1
    }
    nr = f + k + n - r
    ncol = f + k + 1
    M = J(nr, ncol, C(0))
    pol = J(nr, 1, 0)
    shf = J(nr, 1, 0)
    lo = J(nr, 1, 0)
    hi = J(nr, 1, 0)
    s = 0
    for (i=0; i<=k; i++) {
        for (j=1; j<=n; j++) {
            s = s + 1
            if (s <= nr) {
                M[|s, i+1 \ s, i+f+1|] = Psi[j,]
                pol[s] = j
                shf[s] = i
                lo[s] = i + 1
                hi[s] = i + f + 1
            }
        }
    }
    van = J(nr, 1, 0)
    used = J(nr, 1, 0)
    pivat = J(nr, 1, C(1))
    piv = C(1)

    for (c=1; c<=ncol; c++) {
        if (sum(van) == n - 1) {
            break
        }
        cand = J(0, 1, .)
        for (s=1; s<=nr; s++) {
            if (!van[s] & !used[s] & lo[s] == c) {
                cand = cand \ s
            }
        }
        nc = rows(cand)
        if (nc == 0) {
            continue
        }
        pr = cand[1]
        used[pr] = 1
        if (M[pr,c] == 0) {
            return(J(0, 1, C(.)))
        }
        piv = piv * M[pr,c]
        for (ii=2; ii<=nc; ii++) {
            s = cand[ii]
            M[s,] = M[s,] - (M[s,c] / M[pr,c]) * M[pr,]
            M[s,c] = 0
            lo[s] = c + 1
            if (hi[s] - lo[s] + 1 <= r) {
                van[s] = 1
                pivat[s] = piv
            }
            for (t=s+1; t<=nr; t++) {
                if (pol[t] == pol[s] & !used[t] & !van[t]) {
                    sh = shf[t] - shf[s]
                    M[t,] = (J(1, sh, C(0)), M[|s, 1 \ s, ncol-sh|])
                    lo[t] = lo[s] + sh
                }
            }
        }
    }

    if (sum(van) != n - 1) {
        return(J(0, 1, C(.)))
    }
    g = J(r * (n - 1), 1, C(0))
    m = 0
    for (s=1; s<=nr; s++) {
        if (van[s]) {
            if (hi[s] - lo[s] + 1 != r) {
                return(J(0, 1, C(.)))
            }
            for (c=lo[s]; c<=hi[s]; c++) {
                m = m + 1
                g[m] = M[s,c] * pivat[s]
            }
        }
    }
    return(g)
}

// lag polynomials of the augmented regression, one per row: the regressors in reverse order, then the dependent variable
// (this ordering reproduces PcGive); regressor j: b(0,j), b(1,j), ..., b(p,j); dependent variable: 1, -c(1), ..., -c(p)
complex matrix _cft_psi(complex colvector bu, real scalar p, real scalar nx, real scalar k, real scalar hascons)
{
    complex matrix Psi
    real scalar i, l, pyl

    Psi = J(nx + 1, p + 1, C(0))
    for (i=1; i<=nx; i++) {
        Psi[nx+1-i, 1] = bu[hascons+i]
    }
    Psi[nx+1, 1] = 1
    for (l=1; l<=p; l++) {
        pyl = k + (l - 1) * (1 + nx) + 1
        Psi[nx+1, l+1] = -bu[pyl]
        for (i=1; i<=nx; i++) {
            Psi[nx+1-i, l+1] = bu[pyl+i]
        }
    }
    return(Psi)
}

// Wald statistic for r common factors: W = g'(G V G')^(-1) g, G the derivative matrix of the constraints
// derivatives: exact, by the complex-step method: coefficient i is given an imaginary part h and the derivative of
// each constraint is the imaginary part of its value divided by h; there is no subtraction, so no rounding error
// returns missing if the constraints cannot be formed or G V G' is singular
real scalar _cft_swald(real colvector bu, real matrix V, real scalar p, real scalar nx, real scalar k, real scalar hascons, real scalar r)
{
    real colvector g, d, gs
    complex colvector bc, gc
    real matrix G, S, Si
    real scalar K, q, i, h

    K = rows(bu)
    gc = _cft_sargan(_cft_psi(C(bu), p, nx, k, hascons), r)
    q = rows(gc)
    if (q == 0) {
        return(.)
    }
    g = Re(gc)
    G = J(q, K, 0)
    for (i=1; i<=K; i++) {
        h = 1e-30 * max((abs(bu[i]), 1e-10))
        bc = C(bu)
        bc[i] = C(bu[i], h)
        gc = _cft_sargan(_cft_psi(bc, p, nx, k, hascons), r)
        if (rows(gc) != q) {
            return(.)
        }
        G[,i] = Im(gc) / h
    }
    S = G * V * G'
    d = 1 :/ sqrt(diagonal(S))
    if (missing(d)) {
        return(.)
    }
    S = (d * d') :* S
    S = (S + S') / 2
    Si = invsym(S)
    if (diag0cnt(Si) > 0) {
        return(.)
    }
    gs = d :* g
    return(gs' * Si * gs)
}

// error sum of squares of the quasi-differenced regression for a given rho (first observation dropped)
// returns missing if the regression cannot be computed
real scalar _cft_essrho(real colvector y, real matrix X, real scalar rho, real colvector b)
{
    real colvector ys
    real matrix Xs
    real scalar n, k, ess, nobs, badcol, rc

    n = rows(y)
    k = cols(X)
    ys = y[|2 \ n|] - rho * y[|1 \ n-1|]
    Xs = X[|2,1 \ n,k|] - rho * X[|1,1 \ n-1,k|]
    rc = _cft_lsq(ys, Xs, 0, b, ess, nobs, badcol)
    if (rc) {
        return(.)
    }
    return(ess)
}

// Cochrane-Orcutt iteration for AR(1) errors started from a given rho, iterated until the percentage change
// in the error sum of squares is not above 1.0e-11 (at most 10000 iterations)
// returns 1 if converged, 0 otherwise
real scalar _cft_ar1from(real colvector y, real matrix X, real scalar rho0, real colvector b, real scalar rho, real scalar ess, real scalar niter)
{
    real colvector u, bb
    real scalar n, iter, e, eold, diff, num, den, r, t

    n = rows(y)
    r = rho0
    eold = .
    for (iter=1; iter<=10000; iter++) {
        e = _cft_essrho(y, X, r, bb)
        if (e >= .) {
            return(0)
        }
        b = bb
        rho = r
        ess = e
        niter = iter
        if (iter > 1) {
            diff = abs(100 * (e - eold) / eold)
            if (diff <= 1.0e-11) {
                return(1)
            }
        }
        eold = e
        u = y - X * bb
        num = 0
        den = 0
        for (t=2; t<=n; t++) {
            num = num + u[t] * u[t-1]
            den = den + u[t-1] * u[t-1]
        }
        r = num / den
    }
    return(0)
}

// AR coefficients from partial autocorrelations (Durbin-Levinson recursion); every partial autocorrelation
// inside (-1, 1) gives a stationary AR process and every stationary AR process is obtained in this way
real colvector _cft_pac2ar(real colvector pac)
{
    real scalar p, k, j
    real colvector phi, nw

    p = rows(pac)
    phi = J(p, 1, 0)
    for (k=1; k<=p; k++) {
        nw = phi
        nw[k] = pac[k]
        for (j=1; j<k; j++) {
            nw[j] = phi[j] - pac[k] * phi[k-j]
        }
        phi = nw
    }
    return(phi)
}

// error sum of squares of the restricted model for given partial autocorrelations of the AR(p) error
// (each one kept inside [-0.9999, 0.9999]); observations p+1..n, coefficients by least squares on the
// quasi-differenced data; returns 1.0e300 if the regression cannot be computed
real scalar _cft_essar(real colvector y, real matrix X, real colvector pac, real colvector b, real colvector rho)
{
    real scalar n, k, p, l
    real colvector ys, e, pc
    real matrix Xs, Xn, A
    real rowvector s

    n = rows(y)
    k = cols(X)
    p = rows(pac)
    pc = pac
    for (l=1; l<=p; l++) {
        if (pc[l] > 0.9999) {
            pc[l] = 0.9999
        }
        if (pc[l] < -0.9999) {
            pc[l] = -0.9999
        }
    }
    rho = _cft_pac2ar(pc)
    ys = y[|p+1 \ n|]
    Xs = X[|p+1,1 \ n,k|]
    for (l=1; l<=p; l++) {
        ys = ys - rho[l] * y[|p+1-l \ n-l|]
        Xs = Xs - rho[l] * X[|p+1-l,1 \ n-l,k|]
    }
    s = sqrt(colsum(Xs :* Xs))
    if (min(s) <= 0 | hasmissing(s)) {
        return(1.0e300)
    }
    Xn = Xs :/ s
    A = invsym(quadcross(Xn, Xn))
    if (diag0cnt(A) > 0) {
        b = qrsolve(Xn, ys)
    }
    else {
        b = A * quadcross(Xn, ys)
    }
    if (hasmissing(b)) {
        return(1.0e300)
    }
    e = ys - Xn * b
    b = b :/ s'
    return(quadcross(e, e))
}

// Nelder-Mead simplex search for the minimum of _cft_essar() started from x0 with initial step "step"
real scalar _cft_nm(real colvector y, real matrix X, real colvector x0, real scalar step, real colvector xbest)
{
    real scalar p, i, it, fr, fe, fc, l
    real matrix S
    real colvector fv, o, c, xr, xe, xc, bb, rr, v

    p = rows(x0)
    S = J(p+1, p, 0)
    fv = J(p+1, 1, 0)
    S[1,] = x0'
    for (i=1; i<=p; i++) {
        v = x0
        v[i] = v[i] + (v[i] + step <= 0.9999 ? step : -step)
        S[i+1,] = v'
    }
    for (i=1; i<=p+1; i++) {
        fv[i] = _cft_essar(y, X, S[i,]', bb, rr)
    }
    for (it=1; it<=5000; it++) {
        o = order(fv, 1)
        S = S[o,]
        fv = fv[o]
        if (abs(fv[p+1] - fv[1]) <= 1.0e-15 * abs(fv[1]) & max(abs(S[p+1,] - S[1,])) < 1.0e-10) {
            break
        }
        c = (colsum(S[|1,1 \ p,p|]) / p)'
        xr = c + (c - S[p+1,]')
        fr = _cft_essar(y, X, xr, bb, rr)
        if (fr < fv[1]) {
            xe = c + 2 * (c - S[p+1,]')
            fe = _cft_essar(y, X, xe, bb, rr)
            if (fe < fr) {
                S[p+1,] = xe'
                fv[p+1] = fe
            }
            else {
                S[p+1,] = xr'
                fv[p+1] = fr
            }
        }
        else if (fr < fv[p]) {
            S[p+1,] = xr'
            fv[p+1] = fr
        }
        else {
            if (fr < fv[p+1]) {
                xc = c + 0.5 * (xr - c)
            }
            else {
                xc = c + 0.5 * (S[p+1,]' - c)
            }
            fc = _cft_essar(y, X, xc, bb, rr)
            if (fc < min((fr, fv[p+1]))) {
                S[p+1,] = xc'
                fv[p+1] = fc
            }
            else {
                for (i=2; i<=p+1; i++) {
                    S[i,] = S[1,] + 0.5 * (S[i,] - S[1,])
                    fv[i] = _cft_essar(y, X, S[i,]', bb, rr)
                }
            }
        }
    }
    o = order(fv, 1)
    xbest = S[o[1],]'
    for (l=1; l<=p; l++) {
        if (xbest[l] > 0.9999) {
            xbest[l] = 0.9999
        }
        if (xbest[l] < -0.9999) {
            xbest[l] = -0.9999
        }
    }
    return(fv[o[1]])
}

// smallest error sum of squares of the restricted model with AR(p) errors over the stationary region:
// grid over the partial autocorrelations, then simplex search from the (at most five) best local minima of the grid
// returns the minimum (1.0e300 if nothing could be computed), with coefficients b and AR coefficients rho
real scalar _cft_minar(real colvector y, real matrix X, real scalar p, real colvector b, real colvector rho)
{
    real rowvector g
    real colvector V, idx, x, xb, bb, rr, pw
    real matrix L
    real scalar m, tot, lin, a, i, ok, nb, best, f, nl, nstart

    if (p == 1) {
        g = ((-99..99) / 100, 0.999, 0.9999, -0.999, -0.9999)
    }
    else if (p == 2) {
        g = ((-19..19) / 20, 0.99, 0.999, 0.9999, -0.99, -0.999, -0.9999)
    }
    else if (p == 3) {
        g = ((-9..9) / 10, 0.99, 0.999, 0.9999, -0.99, -0.999, -0.9999)
    }
    else {
        g = ((-4..4) / 5, 0.95, 0.99, 0.9999, -0.95, -0.99, -0.9999)
    }
    g = sort(g', 1)'
    m = cols(g)
    tot = m^p
    pw = J(p, 1, 1)
    for (a=2; a<=p; a++) {
        pw[a] = pw[a-1] * m
    }
    V = J(tot, 1, 0)
    idx = J(p, 1, 1)
    x = J(p, 1, 0)
    for (lin=1; lin<=tot; lin++) {
        for (a=1; a<=p; a++) {
            x[a] = g[idx[a]]
        }
        V[lin] = _cft_essar(y, X, x, bb, rr)
        // next grid point (the first index runs fastest)
        for (a=1; a<=p; a++) {
            if (idx[a] < m) {
                idx[a] = idx[a] + 1
                break
            }
            idx[a] = 1
        }
    }
    // local minima of the grid: no neighbour along any axis has a smaller value
    L = J(0, 2, .)
    idx = J(p, 1, 1)
    for (lin=1; lin<=tot; lin++) {
        ok = (V[lin] < 1.0e300)
        for (a=1; a<=p; a++) {
            if (idx[a] > 1) {
                nb = lin - pw[a]
                if (V[nb] < V[lin]) {
                    ok = 0
                }
            }
            if (idx[a] < m) {
                nb = lin + pw[a]
                if (V[nb] < V[lin]) {
                    ok = 0
                }
            }
        }
        if (ok) {
            L = L \ (V[lin], lin)
        }
        for (a=1; a<=p; a++) {
            if (idx[a] < m) {
                idx[a] = idx[a] + 1
                break
            }
            idx[a] = 1
        }
    }
    nl = rows(L)
    if (nl == 0) {
        return(1.0e300)
    }
    L = sort(L, (1, 2))
    nstart = (nl < 5 ? nl : 5)
    best = 1.0e300
    for (i=1; i<=nstart; i++) {
        lin = L[i,2] - 1
        for (a=1; a<=p; a++) {
            x[a] = g[mod(lin, m) + 1]
            lin = floor(lin / m)
        }
        f = _cft_nm(y, X, x, 0.02, xb)
        x = xb
        f = _cft_nm(y, X, x, 0.002, xb)
        if (f < best) {
            best = f
            x = xb
            best = _cft_essar(y, X, xb, b, rho)
        }
    }
    return(best)
}

void _cft_main(string scalar yname, string scalar xnames, string scalar touse, real scalar hascons, real scalar p, real scalar doftest, real scalar dowald, real scalar dolr, real scalar hilu, real scalar nocorc, real scalar loose, real scalar quiet, string scalar depname, string scalar indepnames, string scalar buname, real scalar detail, string scalar wtabname, real scalar dodm, real scalar dong)
{
    real scalar rq, cofail, dmfail, essdm, Fdm, pdm, dfndm, Fco, pco, ngfail, ngrc, LRng, png, qng
    real colvector bdm, rhodm
    real colvector blr, rholr
    real scalar esslr, nobslr, dfdlr, qlr, LR, plr, itlr, itdummy
    real colvector bg, bb, b2
    real scalar essg, rg, eg, r2, e2, it2, gi, cook, lrbound, lrlocal, rholoc, essloc, lrfail, lrrc
    real colvector y, b, bu, yu, rhov, g
    real matrix X, XU, XK, V, G
    real rowvector keep
    real scalar n, k, rc, ess, nobs, badcol, rho, rho0, ess0, r, essmin, hl, iter, conv
    real matrix wtab, XS, VU
    real rowvector sc
    real scalar rdsmall, edsmall, essr, dfdr, essu, dfdu, nobsu, dfn, F, pval, i, l, nx, K
    real scalar waldok, q, W, pchi, px0, pyl, pxl, row
    string rowvector xn, un, coln
    string scalar dn

    // the restricted models are printed only with the detail option
    rq = (quiet | !detail)

    y = st_data(., yname, touse)
    n = rows(y)
    X = st_data(., tokens(xnames), touse)
    xn = tokens(indepnames)
    dn = depname
    nx = cols(X)
    // gretl places the constant first among the regressors
    if (hascons) {
        X = (J(n, 1, 1), X)
        coln = ("const", xn)
    }
    else {
        coln = xn
    }
    k = cols(X)

    if (n - p - k * (p + 1) - p + (hascons ? p : 0) <= 0) {
        errprintf("insufficient degrees of freedom\n")
        exit(2001)
    }

    st_rclear()

    // =====================================================================
    // restricted model (only needed for the F test)
    // =====================================================================
    cofail = 0
    dmfail = 0
    if (doftest & p == 1) {
        // ---------- estimate_rho() ----------
        if (hilu) {
            // Hildreth-Lu grid: the grid value is accumulated exactly as in the C loop
            essmin = 1.0e200
            hl = 0
            iter = 0
            for (r = -0.99; r < 1.0; r = r + .01) {
                rc = _cft_lsq(y, X, r, b, ess, nobs, badcol)
                if (rc) {
                    _cft_fail(rc, "Hildreth-Lu search")
                }
                if (iter == 0 | ess < essmin) {
                    essmin = ess
                    hl = r
                }
                iter = iter + 1
            }
            if (hl > 0.989) {
                for (r = 0.99; r <= 0.999; r = r + .001) {
                    rc = _cft_lsq(y, X, r, b, ess, nobs, badcol)
                    if (rc) {
                        _cft_fail(rc, "Hildreth-Lu search")
                    }
                    if (ess < essmin) {
                        essmin = ess
                        hl = r
                    }
                }
            }
            if (hl > 0.9989) {
                for (r = 0.9991; r <= 0.9999; r = r + .0001) {
                    rc = _cft_lsq(y, X, r, b, ess, nobs, badcol)
                    if (rc) {
                        _cft_fail(rc, "Hildreth-Lu search")
                    }
                    if (ess < essmin) {
                        essmin = ess
                        hl = r
                    }
                }
            }
            rho = hl
            if (!rq) {
                printf("\n{txt}ESS is minimized for rho = {res}%g\n", rho)
            }
            // "ess" now holds the ESS of the last grid model, which is what gretl
            // carries into the Cochrane-Orcutt fine-tuning as the starting ESS
        }
        else {
            rc = _cft_lsq(y, X, 0, b, ess, nobs, badcol)
            if (rc) {
                _cft_fail(rc, "initial OLS")
            }
            if (n - k == 0) {
                errprintf("insufficient degrees of freedom\n")
                exit(2001)
            }
            rho = _cft_rhohat(y, X, b)
            if (rho >= .) {
                errprintf("could not compute the residual autocorrelation\n")
                exit(498)
            }
        }

        if (!hilu | !nocorc) {
            edsmall = 5.0e-8
            ess0 = ess
            rho0 = rho
            rdsmall = (loose ? 0.001 : 1.0e-6)
            iter = 0
            conv = 0
            if (!rq) {
                if (hilu) {
                    printf("\n{txt}Fine-tune rho using the CORC procedure...\n\n")
                }
                else {
                    printf("\n{txt}Performing iterative calculation of rho...\n\n")
                }
                printf("{txt}                 ITER       RHO        ESS\n")
            }
            while (1) {
                iter = iter + 1
                if (iter > 100 | conv) {
                    break
                }
                rc = _cft_lsq(y, X, rho, b, ess, nobs, badcol)
                if (rc) {
                    cofail = 3
                    break
                }
                if (!rq) {
                    printf("{res}          %10.0f %12.5f   %9.6g\n", iter, rho, ess)
                }
                rho = _cft_autores(y, X, b)
                if (ess == 0) {
                    conv = 1
                }
                else if ((ess0 - ess) / ess0 < edsmall) {
                    conv = 1
                }
                else if (abs(rho - rho0) < rdsmall) {
                    conv = 1
                }
                ess0 = ess
                rho0 = rho
            }
            // gretl stops with an error in these cases; here the F (CO) row is left empty and the other tests are shown
            if (!cofail & conv & (rho >= 1 | rho <= -1)) {
                cofail = 2
            }
            if (!cofail & !conv) {
                cofail = 1
            }
            if (!rq & !cofail) {
                printf("{res}          %10.0f %12.5f   %9.6g\n", iter, rho, ess)
            }
        }

        // ---------- final AR(1) model: ar1_lsq(list, dset, AR1, opt, rho) ----------
        if (!cofail) {
            rc = _cft_lsq(y, X, rho, b, essr, nobs, badcol)
            if (rc) {
                cofail = 3
            }
            else {
                dfdr = nobs - k
                rhov = rho
            }
        }
    }
    else if (doftest) {
        // ---------- AR(p) model: ar_model() ----------
        rc = _cft_arp(y, X, p, b, rhov, essr, nobs, rq, 0, itdummy)
        if (rc) {
            _cft_fail(rc, "AR(p) model")
        }
        dfdr = nobs - k
    }

    // =====================================================================
    // restricted model without a grid search (lrnogrid): Cochrane-Orcutt started from OLS and iterated to full convergence
    // =====================================================================
    lrfail = 0
    lrrc = 0
    ngfail = 0
    ngrc = 0
    if (dong) {
        rc = _cft_arp(y, X, p, blr, rholr, esslr, nobslr, rq, 1, itlr)
        if (rc) {
            // the command goes on and the LR (no grid) row is left empty
            ngfail = 1
            ngrc = rc
        }
        else {
            dfdlr = nobslr - k
        }
    }

    // =====================================================================
    // unrestricted model: original regressors plus lags 1..p of the dependent
    // variable and of every non-constant regressor, over observations p+1..n
    // =====================================================================
    yu = y[|p+1 \ n|]
    XU = X[|p+1,1 \ n,k|]
    un = coln
    for (l=1; l<=p; l++) {
        XU = (XU, y[|p+1-l \ n-l|])
        un = (un, dn + "_" + strofreal(l))
        for (i=1; i<=nx; i++) {
            XU = (XU, X[|p+1-l,hascons+i \ n-l,hascons+i|])
            un = (un, xn[i] + "_" + strofreal(l))
        }
    }
    K = cols(XU)
    keep = 1..K
    // redundant terms: a column that fails the gretl singularity test is dropped and the regression redone
    while (1) {
        rc = _cft_lsq(yu, XU[,keep], 0, bu, essu, nobsu, badcol)
        if (rc == 3 & badcol > 0 & cols(keep) > 1) {
            if (!quiet) {
                printf("{txt}note: %s omitted from the lag regression because of collinearity\n", un[keep[badcol]])
            }
            keep = select(keep, (1..cols(keep)) :!= badcol)
            continue
        }
        break
    }
    if (rc) {
        _cft_fail(rc, "unrestricted lag regression")
    }
    dfdu = nobsu - cols(keep)
    if (dfdu <= 0) {
        errprintf("insufficient degrees of freedom\n")
        exit(2001)
    }

    // =====================================================================
    // F test (gretl comfac_test() construction)
    // =====================================================================
    if (doftest & !cofail) {
        if (nobsu != nobs | essu > essr | dfdu >= dfdr) {
            cofail = 4
        }
        else {
            // the p accounts for the autoregressive coefficients
            dfn = dfdr - dfdu - p
            if (dfn <= 0) {
                cofail = 4
            }
            else {
                Fco = ((essr - essu) / dfn) / (essu / dfdu)
                pco = Ftail(dfn, dfdu, Fco)
            }
        }
    }

    // =====================================================================
    // smallest restricted sum of squares over the stationary region of the AR coefficients (grid search over the
    // partial autocorrelations, then simplex search); both models use observations p+1..n
    // likelihood ratio test: LR = T * ln(SSRr / SSRu), chi-squared with as many degrees of freedom as restrictions
    // F test of Davidson and MacKinnon (1999): F = ((SSRr - SSRu) / r) / (SSRu / (T - K))
    // =====================================================================
    if (dolr | dodm) {
        essdm = _cft_minar(y, X, p, bdm, rhodm)
        // number of restrictions: coefficients of the unrestricted regression less those of the restricted model (k and p)
        dfndm = cols(keep) - k - p
        if (essdm < 1.0e300 & essdm < essu & essdm > essu * (1 - 1.0e-10)) {
            essdm = essu
        }
        if (essdm >= 1.0e300 | dfndm <= 0 | essdm < essu) {
            dmfail = 1
            lrfail = 1
            lrrc = 9
        }
        else {
            qlr = dfndm
            LR = nobsu * ln(essdm / essu)
            plr = chi2tail(qlr, LR)
            Fdm = ((essdm - essu) / dfndm) / (essu / dfdu)
            pdm = Ftail(dfndm, dfdu, Fdm)
        }
    }

    // =====================================================================
    // likelihood ratio test without a grid search
    // =====================================================================
    if (dong & !ngfail) {
        qng = dfdlr - dfdu - p
        if (nobsu != nobslr | essu > esslr | qng <= 0) {
            ngfail = 1
            ngrc = 9
        }
        else {
            LRng = nobsu * ln(esslr / essu)
            png = chi2tail(qng, LRng)
        }
    }

    // =====================================================================
    // Wald tests of 1, 2, ..., p common factors (Sargan 1980); the test of AR(p) errors is the one for p common factors
    // =====================================================================
    waldok = 0
    if (dowald) {
        if (cols(keep) != K) {
            errprintf("Wald test not available: a lagged term is redundant, so the restrictions are not defined\n")
            exit(498)
        }
        // coefficient variance matrix; the columns are scaled to unit length before inversion
        sc = sqrt(colsum(XU :* XU))
        XS = XU :/ sc
        V = (essu / dfdu) * (invsym(quadcross(XS, XS)) :/ (sc' * sc))
        wtab = J(p, 7, .)
        for (l=1; l<=p; l++) {
            W = _cft_swald(bu, V, p, nx, k, hascons, l)
            if (W >= . & l == p) {
                errprintf("Wald test: the constraints for %g common factor(s) could not be formed (zero pivot or singular variance matrix)\n", l)
                exit(498)
            }
            wtab[l,1] = l
            wtab[l,3] = l * nx
            wtab[l,6] = nx
            if (W >= .) {
                // an intermediate row that cannot be computed is left empty; the test of AR(p) errors does not use it
                printf("{txt}note: Wald test for %g common factor(s) could not be computed (the variance matrix of the constraints is singular); that row is left empty\n", l)
                continue
            }
            wtab[l,2] = W
            wtab[l,4] = chi2tail(l * nx, W)
            if (l == 1) {
                wtab[l,5] = W
            }
            else if (wtab[l-1,2] < .) {
                wtab[l,5] = W - wtab[l-1,2]
            }
            if (wtab[l,5] < .) {
                wtab[l,7] = (wtab[l,5] >= 0 ? chi2tail(nx, wtab[l,5]) : .)
            }
        }
        q = p * nx
        W = wtab[p,2]
        pchi = wtab[p,4]
        waldok = 1
        st_matrix(wtabname, wtab)
    }

    // =====================================================================
    // output
    // =====================================================================
    if (!rq) {
        if ((dolr | dodm) & !lrfail) {
            printf("\n{txt}Restricted model, AR(%g) errors (grid search, smallest sum of squared residuals), dependent variable: {res}%s\n", p, dn)
            _cft_table(coln, bdm)
            for (l=1; l<=p; l++) {
                printf("{txt}rho(%g) = {res}%18.15g\n", l, rhodm[l])
            }
            printf("{txt}Sum squared resid = {res}%18.15g{txt}   T = {res}%g\n", essdm, nobsu)
        }
        if (dong & !ngfail) {
            printf("\n{txt}Restricted model, AR(%g) errors (no grid search, Cochrane-Orcutt started from OLS), dependent variable: {res}%s\n", p, dn)
            _cft_table(coln, blr)
            for (l=1; l<=p; l++) {
                printf("{txt}rho(%g) = {res}%18.15g\n", l, rholr[l])
            }
            printf("{txt}Sum squared resid = {res}%18.15g{txt}   T = {res}%g\n", esslr, nobslr)
        }
        if (doftest & !cofail) {
            printf("\n{txt}AR(1) model for the F (CO) test (Cochrane-Orcutt as in gretl), dependent variable: {res}%s\n", dn)
            _cft_table(coln, b)
            printf("{txt}rho = {res}%18.15g\n", rhov[1])
            printf("{txt}Sum squared resid = {res}%18.15g{txt}   T = {res}%g{txt}   df = {res}%g\n", essr, nobs, dfdr)
        }
    }

    // =====================================================================
    // returned results
    // =====================================================================
    st_numscalar("r(ar)", p)
    st_numscalar("r(N)", nobsu)
    st_numscalar("r(ssr_u)", essu)
    if (dodm & !dmfail) {
        st_numscalar("r(F)", Fdm)
        st_numscalar("r(p)", pdm)
        st_numscalar("r(df_n)", dfndm)
        st_numscalar("r(df_d)", dfdu)
    }
    if (doftest & !cofail) {
        st_numscalar("r(F_co)", Fco)
        st_numscalar("r(p_co)", pco)
        st_numscalar("r(df_n_co)", dfn)
        st_numscalar("r(df_d_co)", dfdu)
    }
    st_local("cofail", strofreal(cofail))
    st_local("dmfail", strofreal(dmfail))
    st_local("lrfail", strofreal(lrfail))
    st_local("lrrc", strofreal(lrrc))
    st_local("ngfail", strofreal(ngfail))
    st_local("ngrc", strofreal(ngrc))
    if (dolr & !lrfail) {
        st_numscalar("r(lr)", LR)
        st_numscalar("r(p_lr)", plr)
        st_numscalar("r(df_lr)", qlr)
        st_numscalar("r(ssr_r_lr)", essdm)
    }
    if (dong & !ngfail) {
        st_numscalar("r(lr_nogrid)", LRng)
        st_numscalar("r(p_lr_nogrid)", png)
        st_numscalar("r(df_lr_nogrid)", qng)
    }
    if (waldok) {
        st_numscalar("r(chi2)", W)
        st_numscalar("r(p_chi2)", pchi)
        st_numscalar("r(df_chi2)", q)
    }
    st_matrix(buname, bu')
    st_matrixcolstripe(buname, (J(cols(keep), 1, ""), _cft_stripe(un[keep])'))
}

end
