*! _tsurcoint_kss 1.0.0  12nov2026   (engine of: tsurcoint fkss | wkss | fwkss | fwadf)
*! Fourier, wavelet and Fourier-wavelet KSS / ADF unit-root tests
*! Author : Dr Merwan Roudane  merwanroudane920@gmail.com
*!          https://github.com/merwanroudane
*! Part of the -tsurcoint- library (ports of GAUSS time-series tests).
*!
*! Faithful port of the GAUSS routines Fourier_KSS, Fourier_KSS_bootstrap,
*!   WKSS, Fourier_WKSS and fourier_wadf (tspdlib 3.0.0) by Saban Nazlioglu.
*!
*! References:
*!   Kapetanios, G., Shin, Y., Snell, A. (2003). Testing for a unit root in the
*!     nonlinear STAR framework. Journal of Econometrics 112: 359-379.
*!     <doi:10.1016/S0304-4076(02)00202-6>
*!   Christopoulos, D. K., Leon-Ledesma, M. A. (2010). Smooth breaks and
*!     non-linear mean reversion: Post-Bretton Woods real exchange rates.
*!     Journal of International Money and Finance 29(6): 1076-1093.
*!     <doi:10.1016/j.jimonfin.2010.02.003>
*!   Aydin, M. (2020). A new nonlinear wavelet-based unit root test with
*!     structural breaks. MPRA Paper 104291.
*!   Aydin, M., Pata, U. K. (2020). Are shocks to disaggregated renewable
*!     energy consumption permanent or temporary for the USA? Wavelet based
*!     unit root test with smooth structural shifts. Energy 207: 118245.
*!     <doi:10.1016/j.energy.2020.118245>
*!
*! Step -> code map (see -help tsurcoint_fkss- etc.):
*!   frequency k* = argmin SSR of y on (1, [t], sin, cos)  -> _tskss_kstar
*!   Haar wavelet scaling coefficients y~_j                -> _tskss_haar
*!   KSS / ADF auxiliary regression + lag selection        -> _tskss_core
*!   Fourier ADF with frequency search (wavelet: sin only)  -> _tskss_fadf
*!   Monte Carlo and residual bootstrap critical values     -> _tskss_run

program _tsurcoint_kss, rclass
    version 14.0
    gettoken test 0 : 0
    syntax varname(numeric ts) [if] [in] [ , ///
        MODel(string)        ///
        PMax(integer 8)      ///
        FMax(integer 5)      ///
        IC(string)           ///
        ADF                  ///
        GAUSS                ///
        PAPer                ///
        SIMulate(integer 0)  ///
        BOOTstrap(integer 0) ///
        SEED(string)         ]

    marksample touse
    qui tsset
    local tvar "`r(timevar)'"
    if "`r(panelvar)'" != "" {
        di as err "tsurcoint needs a single time series: the data are {bf:xtset}/panel. Use {bf:if} to select one unit, or see {help xturcoint}."
        exit 459
    }
    // ---------------- model
    if ("`model'"=="") local model "constant"
    local model = strlower("`model'")
    if inlist("`model'","none","n","0")            local mod 0
    else if inlist("`model'","constant","c","1")   local mod 1
    else if inlist("`model'","trend","ct","t","2") local mod 2
    else {
        di as err "model() must be none, constant or trend"
        exit 198
    }
    if `mod'==0 & "`test'" != "wkss" {
        di as err "model(none) is available only for {bf:tsurcoint wkss}"
        exit 198
    }
    if ("`ic'"=="") local ic "tstat"
    local ic = strlower("`ic'")
    if inlist("`ic'","aic","1")              local icn 1
    else if inlist("`ic'","bic","sic","2")   local icn 2
    else if inlist("`ic'","tstat","t","3")   local icn 3
    else {
        di as err "ic() must be aic, bic or tstat"
        exit 198
    }
    if `pmax' < 0 | `fmax' < 1 | `fmax' > 5 {
        di as err "pmax() must be >= 0 and fmax() must lie in 1..5"
        exit 198
    }
    if "`bootstrap'" != "0" & "`test'" != "fkss" {
        di as err "bootstrap() is available for {bf:tsurcoint fkss} (as in GAUSS Fourier_KSS_bootstrap)"
        exit 198
    }
    // ---------------- sample: contiguous, no gaps
    qui count if `touse'
    local T = r(N)
    qui summ `tvar' if `touse', meanonly
    if (r(max) - r(min) + 1) != `T' {
        di as err "the sample must be contiguous (no gaps or missing values inside the sample)"
        exit 459
    }
    local Tw = `T'
    if inlist("`test'","wkss","fwkss","fwadf") local Tw = floor(`T'/2)
    if `Tw' < `pmax' + 10 {
        di as err "too few observations (`Tw' after the transformation) for pmax(`pmax')"
        exit 2001
    }
    if "`seed'" != "" set seed `seed'

    local tn = cond("`test'"=="fkss",1,cond("`test'"=="wkss",2,cond("`test'"=="fwkss",3,4)))
    local isadf = ("`adf'" != "")
    local gss = ("`gauss'" != "")
    local ppr = ("`paper'" != "")
    sort `tvar'
    mata: _tskss_run("`varlist'", "`touse'", `tn', `mod', `pmax', `fmax', `icn', `isadf', `gss', `ppr', `simulate', `bootstrap')
    local stat = r(stat)
    local lags = r(lags)
    local freq = r(freq)

    // ---------------- display
    if `tn'==1 local ttl = cond(`isadf', "Fourier ADF test on Fourier residuals (Christopoulos and Leon-Ledesma 2010)", "Fourier KSS unit-root test (Christopoulos and Leon-Ledesma 2010)")
    if `tn'==2 local ttl "Wavelet KSS unit-root test (Aydin 2020)"
    if `tn'==3 local ttl "Fourier wavelet KSS unit-root test (Aydin 2020)"
    if `tn'==4 local ttl "Fourier wavelet ADF unit-root test (Aydin and Pata 2020)"
    local mlab = cond(`mod'==0,"none",cond(`mod'==1,"constant","constant and trend"))
    local icl = cond(`icn'==1,"AIC",cond(`icn'==2,"BIC","t-sig (10%)"))
    di
    di as txt "`ttl'"
    di as txt "{hline 70}"
    di as txt "H0: unit root (linear)" _col(44) "Observations" _col(62) "= " as res %6.0f `T'
    if `tn' >= 2 di as txt _col(44) "Wavelet coefficients" _col(62) "= " as res %6.0f `Tw'
    di as txt "Deterministics : " as res "`mlab'" _col(44) as txt "Max lags (" as res "`icl'" as txt ")" _col(62) "= " as res %6.0f `pmax'
    if `tn' != 2 di as txt "Fourier frequency k* : " as res "`freq'" as txt " (max " as res "`fmax'" as txt ", min SSR)"
    di as txt "{hline 70}"
    di as txt _col(5) "Statistic" _col(27) "Value" _col(40) "Lags" _col(52) "1%" _col(60) "5%" _col(68) "10%"
    di as txt "{hline 70}"
    local snm = cond(`tn'==1, cond(`isadf',"FADF (tau)","FKSS (t_NL)"), cond(`tn'==2,"WKSS (t_NL)",cond(`tn'==3,"FWKSS (t_NL)","FWADF (tau)")))
    local hascv = ("`=r(cv1)'" != ".")
    if `hascv' {
        local st = cond(`stat'<r(cv1),"***",cond(`stat'<r(cv5),"**",cond(`stat'<r(cv10),"*","")))
        di as txt _col(5) "`snm'" _col(20) as res %11.4f `stat' _col(38) %5.0f `lags' _col(48) %7.3f r(cv1) %8.3f r(cv5) %8.3f r(cv10) as txt " `st'"
    }
    else {
        di as txt _col(5) "`snm'" _col(20) as res %11.4f `stat' _col(38) %5.0f `lags'
    }
    di as txt "{hline 70}"
    if `hascv' di as txt "Critical values: " as res cond(`bootstrap'>0, "residual bootstrap (`bootstrap' replications)", "Monte Carlo (`simulate' replications)") as txt ".  *** 1%, ** 5%, * 10%"
    else di as txt "GAUSS reports no critical values for this test; use {bf:simulate(#)}" cond(`tn'==1, " or {bf:bootstrap(#)}", "") " to obtain them."
    if `tn' != 2 di as txt "F test of the Fourier terms (H0: no smooth break): F = " as res %7.3f r(Ftrig) as txt "  (standard F p-value = " as res %6.4f r(pF) as txt ")"
    if `tn'==2 & `gss'  di as txt "Formulas: GAUSS (option {bf:gauss}): the KSS regression is run on the detrended series, not on its wavelet transform."
    if `tn'==2 & !`gss' di as txt "Formulas: paper (default): KSS on the Haar wavelet transform of the detrended series. Option {bf:gauss} reproduces GAUSS WKSS."
    if `tn'==4 & `ppr'  di as txt "Formulas: paper (option {bf:paper}): AIC/BIC penalize the number of regressors."
    if `tn'==4 & !`ppr' & `icn' < 3 di as txt "Formulas: GAUSS (default): AIC/BIC penalty uses the Fourier frequency as in GAUSS; option {bf:paper} penalizes the regressors."

    return scalar stat = `stat'
    return scalar lags = `lags'
    if `tn' != 2 {
        return scalar freq = `freq'
        return scalar F_fourier = r(Ftrig)
        return scalar p_F_fourier = r(pF)
    }
    if `hascv' {
        return scalar cv1  = r(cv1)
        return scalar cv5  = r(cv5)
        return scalar cv10 = r(cv10)
    }
    return scalar T = `T'
    return scalar Tw = `Tw'
    return scalar pmax = `pmax'
    return local model "`model'"
    return local ic "`ic'"
    return local test "`test'"
    return local varname "`varlist'"
end

mata:

real colvector _tskss_diff(real colvector x)
{
    return(0 \ (x[|2 \ rows(x)|] - x[|1 \ rows(x)-1|]))
}

real matrix _tskss_lagn(real colvector x, real scalar pmax)
{
    real matrix L
    real scalar j, t
    t = rows(x)
    L = J(t, max((pmax,1)), .)
    for (j=1; j<=pmax; j=j+1) {
        L[., j] = J(j,1,.) \ x[|1 \ t-j|]
    }
    return(L)
}

real colvector _tskss_resid(real colvector y, real matrix z)
{
    return(y - z*(luinv(z'*z)*(z'*y)))
}

real scalar _tskss_getlag(real scalar ic, real scalar pmax, real colvector aicp,
                          real colvector sicp, real colvector tstatp)
{
    real scalar p, j, i
    p = 1
    if (ic == 1 | ic == 2) {
        for (i=2; i<=pmax+1; i=i+1) {
            if (ic == 1) {
                if (aicp[i] < aicp[p]) p = i
            }
            if (ic == 2) {
                if (sicp[i] < sicp[p]) p = i
            }
        }
    }
    if (ic == 3) {
        j = pmax + 1
        while (j >= 1) {
            if (abs(tstatp[j]) > 1.645) break
            j = j - 1
        }
        p = j
        if (p == 0) p = 1
    }
    return(p)
}

// GAUSS KSS / Fourier_KSS regression on residual series v
// cubic = 1: v^3_{t-1} (KSS); cubic = 0: v_{t-1} (ADF).  Returns (tau, lags)
real rowvector _tskss_core(real colvector v, real scalar pmax, real scalar ic, real scalar cubic)
{
    real colvector dv, v1, dep, b, se, e, taup, aicp, sicp, tstatp
    real matrix L, x, m
    real scalar t, p, n, k, LL, ssr, po
    t  = rows(v)
    dv = _tskss_diff(v)
    v1 = . \ v[|1 \ t-1|]
    if (cubic) v1 = . \ (v[|1 \ t-1|]:^3)
    L  = _tskss_lagn(dv, pmax)
    taup = J(pmax+1,1,0)
    aicp = J(pmax+1,1,0)
    sicp = J(pmax+1,1,0)
    tstatp = J(pmax+1,1,0)
    for (p=0; p<=pmax; p=p+1) {
        x = v1
        if (p > 0) x = x, L[|1,1 \ t,p|]
        dep = dv[|p+2 \ t|]
        x   = x[|p+2,1 \ t,cols(x)|]
        m   = luinv(x'*x)
        b   = m*(x'*dep)
        e   = dep - x*b
        ssr = e'*e
        n   = rows(x)
        k   = cols(x)
        se  = sqrt(diagonal(m)*(ssr/(n-k)))
        taup[p+1] = b[1]/se[1]
        LL = -n/2*(1 + ln(2*pi()) + ln(ssr/n))
        aicp[p+1] = (2*k - 2*LL)/n
        sicp[p+1] = (k*ln(n) - 2*LL)/n
        tstatp[p+1] = abs(b[k]/se[k])
    }
    po = _tskss_getlag(ic, pmax, aicp, sicp, tstatp)
    return((taup[po], po-1))
}

real matrix _tskss_det(real scalar t, real scalar model, real scalar k, real scalar usecos)
{
    real matrix z
    real colvector tt
    tt = (1::t)
    z = J(t,1,1)
    if (model == 2) z = z, tt
    if (k > 0) {
        z = z, sin(2*pi()*k*tt/t)
        if (usecos) z = z, cos(2*pi()*k*tt/t)
    }
    return(z)
}

// GAUSS _get_fourier + _get_Ftest: returns (k*, F, pF)
real rowvector _tskss_kstar(real colvector y, real scalar model, real scalar fmax)
{
    real scalar k, best, bssr, ssr, t, rss_r, rss_u, q, df, F
    real colvector e
    real matrix z
    t = rows(y)
    best = 1
    bssr = .
    for (k=1; k<=fmax; k=k+1) {
        e = _tskss_resid(y, _tskss_det(t, model, k, 1))
        ssr = e'*e
        if (k == 1) bssr = ssr
        if (ssr < bssr) {
            bssr = ssr
            best = k
        }
    }
    z = _tskss_det(t, model, best, 1)
    e = _tskss_resid(y, _tskss_det(t, model, 0, 1))
    rss_r = e'*e
    e = _tskss_resid(y, z)
    rss_u = e'*e
    q  = 2
    df = t - cols(z)
    F  = ((rss_r - rss_u)/q)/(rss_u/df)
    return((best, F, Ftail(q, df, F)))
}

// GAUSS __wavelet_transform: Haar scaling coefficients
real colvector _tskss_haar(real colvector y)
{
    real scalar n, j
    real colvector yt
    n  = floor(rows(y)/2)
    yt = J(n,1,.)
    for (j=1; j<=n; j=j+1) {
        yt[j] = (y[2*j] + y[2*j-1])/sqrt(2)
    }
    return(yt)
}

// GAUSS Fourier_KSS(y, model, test, pmax, fmax, ic): returns (stat, k*, lags, F, pF)
real rowvector _tskss_fkss(real colvector y, real scalar model, real scalar pmax,
                           real scalar fmax, real scalar ic, real scalar cubic)
{
    real rowvector ks, r
    real colvector v
    ks = _tskss_kstar(y, model, fmax)
    v  = _tskss_resid(y, _tskss_det(rows(y), model, ks[1], 1))
    r  = _tskss_core(v, pmax, ic, cubic)
    return((r[1], ks[1], r[2], ks[2], ks[3]))
}

// GAUSS Fourier_ADF(y, model, pmax, fmax, ic, wavelet): returns (stat, f, lags)
// paper = 0: AIC/SIC use the frequency k as "number of parameters" (GAUSS _runFourierOLS)
real rowvector _tskss_fadf(real colvector y, real scalar model, real scalar pmax,
                           real scalar k1, real scalar fmax, real scalar ic, real scalar wavelet, real scalar paper)
{
    real scalar t, k, p, n, kk, LL, ssr, po, f
    real colvector dy, ly, dep, b, se, e, taup, aicp, sicp, tstatp, ssrp, ssrk, tauk, keepp, tt
    real matrix L, x, m
    t  = rows(y)
    tt = (1::t)
    dy = _tskss_diff(y)
    ly = . \ y[|1 \ t-1|]
    L  = _tskss_lagn(dy, pmax)
    ssrk = J(fmax,1,0)
    tauk = J(fmax,1,0)
    keepp = J(fmax,1,0)
    for (k=k1; k<=fmax; k=k+1) {
        taup = J(pmax+1,1,0)
        aicp = J(pmax+1,1,0)
        sicp = J(pmax+1,1,0)
        tstatp = J(pmax+1,1,0)
        ssrp = J(pmax+1,1,0)
        for (p=0; p<=pmax; p=p+1) {
            x = ly
            if (model > 0) x = x, J(t,1,1)
            x = x, sin(2*pi()*k*tt/t)
            if (!wavelet) x = x, cos(2*pi()*k*tt/t)
            if (model == 2) x = x, tt
            x = x[|p+2,1 \ t,cols(x)|]
            if (p > 0) x = x, L[|p+2,1 \ t,p|]
            dep = dy[|p+2 \ t|]
            m   = luinv(x'*x)
            b   = m*(x'*dep)
            e   = dep - x*b
            ssr = e'*e
            n   = rows(x)
            kk  = k
            if (paper) kk = cols(x)
            se  = sqrt(diagonal(m)*(ssr/(n-cols(x))))
            taup[p+1] = b[1]/se[1]
            LL = -n/2*(1 + ln(2*pi()) + ln(ssr/n))
            aicp[p+1] = (2*kk - 2*LL)/n
            sicp[p+1] = (kk*ln(n) - 2*LL)/n
            tstatp[p+1] = abs(b[cols(x)]/se[cols(x)])
            ssrp[p+1] = ssr
        }
        po = _tskss_getlag(ic, pmax, aicp, sicp, tstatp)
        keepp[k] = po
        ssrk[k] = ssrp[po]
        tauk[k] = taup[po]
    }
    f = k1
    for (k=k1+1; k<=fmax; k=k+1) {
        if (ssrk[k] < ssrk[f]) f = k
    }
    return((tauk[f], f, keepp[f]-1))
}

real colvector _tskss_detrend(real colvector y, real scalar model)
{
    if (model == 0) return(y)
    if (model == 1) return(y :- mean(y))
    return(_tskss_resid(y, (J(rows(y),1,1), (1::rows(y)))))
}

// one evaluation of the statistic; fixk > 0 fixes the frequency (Monte Carlo)
real rowvector _tskss_stat(real colvector y, real scalar tn, real scalar model, real scalar pmax,
                           real scalar fmax, real scalar ic, real scalar isadf, real scalar gss,
                           real scalar ppr, real scalar fixk)
{
    real rowvector r
    real colvector v, w
    if (tn == 1) {
        if (fixk > 0) {
            v = _tskss_resid(y, _tskss_det(rows(y), model, fixk, 1))
            r = _tskss_core(v, pmax, ic, !isadf)
            return((r[1], fixk, r[2], ., .))
        }
        return(_tskss_fkss(y, model, pmax, fmax, ic, !isadf))
    }
    if (tn == 2) {
        v = _tskss_detrend(y, model)
        if (!gss) v = _tskss_haar(v)
        r = _tskss_core(v, pmax, ic, 1)
        return((r[1], ., r[2], ., .))
    }
    if (tn == 3) {
        w = _tskss_haar(y)
        if (fixk > 0) {
            v = _tskss_resid(w, _tskss_det(rows(w), model, fixk, 1))
            r = _tskss_core(v, pmax, ic, 1)
            return((r[1], fixk, r[2], ., .))
        }
        return(_tskss_fkss(w, model, pmax, fmax, ic, 1))
    }
    w = _tskss_haar(y)
    if (fixk > 0) {
        r = _tskss_fadf(w, model, pmax, fixk, fixk, ic, 1, ppr)
        return((r[1], fixk, r[3], ., .))
    }
    r = _tskss_fadf(w, model, pmax, 1, fmax, ic, 1, ppr)
    return((r[1], r[2], r[3], ., .))
}

void _tskss_run(string scalar vn, string scalar touse, real scalar tn, real scalar model,
                real scalar pmax, real scalar fmax, real scalar ic, real scalar isadf,
                real scalar gss, real scalar ppr, real scalar nsim, real scalar nboot)
{
    real colvector y, sims, yd, yd1, mu, ys, dv, v, x0, bb, kst
    real rowvector r, rr, ks
    real matrix X
    real scalar T, s, kfix, i, Tu, fi, ff
    y = st_data(., vn, touse)
    T = rows(y)
    r = _tskss_stat(y, tn, model, pmax, fmax, ic, isadf, gss, ppr, 0)
    // F test of the Fourier terms on the (transformed) series
    if (tn == 1) {
        ks = _tskss_kstar(y, model, fmax)
        ff = ks[2]
        fi = ks[3]
    }
    if (tn == 3 | tn == 4) {
        ks = _tskss_kstar(_tskss_haar(y), model, fmax)
        ff = ks[2]
        fi = ks[3]
    }
    st_rclear()
    st_numscalar("r(stat)", r[1])
    st_numscalar("r(freq)", r[2])
    st_numscalar("r(lags)", r[3])
    if (tn != 2) {
        st_numscalar("r(Ftrig)", ff)
        st_numscalar("r(pF)", fi)
    }
    st_numscalar("r(cv1)", .)
    st_numscalar("r(cv5)", .)
    st_numscalar("r(cv10)", .)
    // ---- Monte Carlo critical values (GAUSS _get_cv_Fourier_KSS design:
    //      driftless random walk, selected frequency held fixed, no lags)
    if (nsim > 0) {
        sims = J(nsim,1,.)
        kfix = r[2]
        if (kfix == .) kfix = 0
        for (s=1; s<=nsim; s=s+1) {
            ys = runningsum(0 \ rnormal(T-1,1,0,1))
            rr = _tskss_stat(ys, tn, model, 0, fmax, 3, isadf, gss, ppr, kfix)
            sims[s] = rr[1]
        }
        sims = sort(sims, 1)
        st_numscalar("r(cv1)",  sims[max((1,round(0.01*nsim)))])
        st_numscalar("r(cv5)",  sims[max((1,round(0.05*nsim)))])
        st_numscalar("r(cv10)", sims[max((1,round(0.10*nsim)))])
    }
    // ---- residual bootstrap (GAUSS Fourier_KSS_bootstrap), lower-tail quantiles
    if (nboot > 0 & tn == 1) {
        ks = _tskss_kstar(y, model, fmax)
        v  = _tskss_resid(y, _tskss_det(T, model, ks[1], 1))
        dv = _tskss_diff(v)
        X = _tskss_lagn(dv, pmax)
        if (pmax == 0) X = . \ dv[|1 \ T-1|]
        X  = X[|pmax+2,1 \ T,cols(X)|]
        x0 = dv[|pmax+2 \ T|]
        bb = luinv(X'*X)*(X'*x0)
        yd = x0 - X*bb
        yd1 = yd[|1 \ rows(yd)-1|]
        yd  = yd[|2 \ rows(yd)|]
        mu = yd - yd1*((yd1'*yd)/(yd1'*yd1))
        mu = mu :- mean(mu)
        Tu = rows(mu)
        sims = J(nboot,1,.)
        for (s=1; s<=nboot; s=s+1) {
            ys = runningsum(mu[ceil(Tu*runiform(Tu,1))])
            rr = _tskss_stat(ys, 1, model, pmax, fmax, ic, isadf, 0, 0, 0)
            sims[s] = rr[1]
        }
        sims = sort(sims, 1)
        st_numscalar("r(cv1)",  sims[max((1,round(0.01*nboot)))])
        st_numscalar("r(cv5)",  sims[max((1,round(0.05*nboot)))])
        st_numscalar("r(cv10)", sims[max((1,round(0.10*nboot)))])
    }
}
end
