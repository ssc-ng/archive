*! indsat_loop 1.0.0  12nov2026
*! indsat over a grid of target sizes + Jiao-Pretis outlier scaling (sum / sup) tests
*! Author: Dr Merwan Roudane  (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane
*  Port of gets::isat loop and gets::outlierscaletest (Jiao & Pretis 2022)

program define indsat_loop, rclass
    version 14.0
    tempname _indsat_hold
    capture _estimates hold `_indsat_hold', restore nullok
    syntax varlist(min=1 ts numeric fv) [if] [in] [, NUMs(numlist >0) TPvals(numlist >0 <1) ///
        NSIM(integer 10000) SEED(string) GRaph NAME(string) * ]
    if ("`nums'"!="" & "`tpvals'"!="") {
        di as err "specify nums() or tpvals(), not both"
        exit 198
    }
    if ("`nums'"=="" & "`tpvals'"=="") local nums "20(-1)1"
    if ("`name'"=="") local name "indsat loop"
    if ("`seed'"!="") set seed `seed'
    if (strpos(" `options' ", " sis ") | strpos(" `options' ", " tis ")) {
        di as text "note: the scaling tests are derived for IIS; other indicator sets make them indicative"
    }
    * sample size from a first run
    quietly indsat `varlist' `if' `in', iis tpval(0.001) `options' nodates notable noheader
    local n = e(N)
    if ("`nums'"!="") {
        numlist "`nums'"
        local grid ""
        foreach k in `r(numlist)' {
            local grid "`grid' `=`k'/`n''"
        }
    }
    else {
        numlist "`tpvals'"
        local grid "`r(numlist)'"
    }
    * sort grid in decreasing p (as gets::isat loop)
    local grid : list sort grid
    local K : word count `grid'
    tempname G
    matrix `G' = J(`K', 6, .)
    local r 0
    forvalues i = `K'(-1)1 {
        local p : word `i' of `grid'
        local ++r
        quietly indsat `varlist' `if' `in', iis tpval(`p') `options' nodates notable noheader
        local no = e(niis)
        mata: st_numscalar("r(sd)", sqrt(indsatl_vg(`p', `n')))
        local z = (`no'/`n' - `p')/r(sd)
        matrix `G'[`r',1] = `p'
        matrix `G'[`r',2] = `p'*`n'
        matrix `G'[`r',3] = `no'
        matrix `G'[`r',4] = `no'/`n'
        matrix `G'[`r',5] = `z'
        matrix `G'[`r',6] = 2*normal(-abs(`z'))
    }
    matrix colnames `G' = tpval expected retained gauge z p
    mata: indsatl_scale("`G'", `n', `nsim')
    local ssum = r(sum)
    local psum = r(p_sum)
    local ssup = r(sup)
    local psup = r(p_sup)
    di
    di as text "{bf:Indicator saturation over a grid of target sizes} (IIS, T = `n')"
    di as text "{hline 72}"
    di as text %10s "tpval" %12s "E[outliers]" %10s "Retained" %10s "Gauge" %12s "z (prop.)" %10s "p-value"
    di as text "{hline 72}"
    forvalues i = 1/`K' {
        di as res %10.5f `G'[`i',1] %12.2f `G'[`i',2] %10.0f `G'[`i',3] %10.4f `G'[`i',4] %12.3f `G'[`i',5] %10.4f `G'[`i',6]
    }
    di as text "{hline 72}"
    di as text "Jiao-Pretis outlier scaling sum test   z   = " as res %8.4f `ssum' as text "   p-value = " as res %6.4f `psum'
    di as text "Jiao-Pretis outlier scaling sup test   sup = " as res %8.4f `ssup' as text "   p-value = " as res %6.4f `psup' as text "  (`nsim' draws)"
    di as text "{hline 72}"
    di as text "H0: no outliers (retained impulses are false detections at every target size)."
    if ("`graph'"!="") {
        preserve
        qui {
            clear
            svmat double `G', names(col)
            gen double lo = invpoisson(expected, 0.975)
            gen double hi = invpoisson(expected, 0.025)
        }
        twoway (rarea lo hi expected, color(navy%15) lwidth(none)) (line expected expected, lcolor(navy) lpattern(dash)) ///
               (connected retained expected, lcolor(cranberry) mcolor(cranberry) msymbol(O)), ///
               graphregion(color(white)) xtitle("Expected number of false outliers ({&alpha}T)") ytitle("Retained impulses") ///
               legend(order(3 "Retained" 2 "Expected under H0" 1 "95% Poisson band") rows(1) position(6) region(lcolor(white))) ///
               title("Outlier counts across target sizes", size(medsmall)) name(`name', replace)
        restore
    }
    return scalar N = `n'
    return scalar sum = `ssum'
    return scalar p_sum = `psum'
    return scalar sup = `ssup'
    return scalar p_sup = `psup'
    return matrix grid = `G'
end

version 14.0
mata:
real scalar indsatl_vg(real scalar alpha, real scalar T)
{
    real scalar c, fc, psi, tau, chi, rho, k, m, m1, eta1, etag
    m = 1
    c = abs(invnormal(alpha/2))
    fc = normalden(c)
    psi = normal(c) - normal(-c)
    tau = psi - 2*c*fc
    chi = 3*psi - 2*c*(c^2 + 3)*fc
    rho = (c^2 - tau/psi)*c*fc/tau
    k = 3
    m1 = m - 1
    eta1 = (((1 - rho^m1)/((1 - rho)*tau))^2 + 2*((1 - rho^m1)/((1 - rho)*tau))*rho^m1)*(chi - tau^2/psi)/(k - 1) + rho^(2*m1)
    etag = (c*fc)^2*eta1*(k - 1) + 2*c*fc*rho^(m - 1)*(tau - psi)
    return((psi*(1 - psi) + etag)/T)
}

/* gets::outlierscaletest */
void indsatl_scale(string scalar gname, real scalar n, real scalar nsim)
{
    real matrix G, S, L, Z
    real colvector p, prop, c, fc, psi, t2, st
    real scalar K, k, l, s, t, covar, v, sumst, supst, cnt, cf
    G = st_matrix(gname)
    p = G[., 1]
    prop = G[., 4]
    K = rows(p)
    c = invnormal(1 :- p/2)
    fc = normalden(c)
    psi = 1 :- p
    t2 = psi - 2*c:*fc
    st = sqrt(n)*(prop - p)
    sumst = sum(st)
    covar = 0
    for (k=1; k<=K-1; k++) {
        for (l=k+1; l<=K; l++) {
            covar = covar + p[l] - p[k]*p[l]
        }
    }
    cf = sum(c:*fc)
    v = sum(p:*(1 :- p)) + 2*covar + cf^2*(3 - 1) + 2*cf*sum(t2 + p :- 1)
    st_numscalar("r(sum)", sumst/sqrt(v))
    st_numscalar("r(p_sum)", 2*normal(-abs(sumst/sqrt(v))))
    supst = max(abs(st))
    S = J(K, K, .)
    for (s=1; s<=K; s++) {
        for (t=s; t<=K; t++) {
            S[s, t] = p[t]*(1 - p[s]) + c[s]*fc[s]*(t2[t] + p[t] - 1) + c[t]*fc[t]*(t2[s] + p[s] - 1) + c[s]*c[t]*fc[s]*fc[t]*(3 - 1)
            S[t, s] = S[s, t]
        }
    }
    L = cholesky(S)
    if (hasmissing(L)) {
        /* fall back to a symmetric eigen square root if S is not numerically PD */
        L = indsatl_sqrtm(S)
    }
    Z = rnormal(nsim, K, 0, 1)*L'
    cnt = sum(rowmax(abs(Z)) :> supst)
    st_numscalar("r(sup)", supst)
    st_numscalar("r(p_sup)", cnt/nsim)
}

real matrix indsatl_sqrtm(real matrix S)
{
    real matrix X
    real rowvector lam
    symeigensystem(S, X, lam)
    lam = lam :* (lam :> 0)
    return(X*diag(sqrt(lam)))
}
end
