*! _xturcoint_panic 1.0.0  11nov2026   (engine of: xturcoint panic)
*! PANIC extensions: Bai-Ng (2010) Pa/Pb/PMSB, Westerlund-Larsson (2009)
*! bias-adjusted Ze/Ze+, and Reese-Westerlund (2016) PANICCA
*! Author : Dr Merwan Roudane  merwanroudane920@gmail.com
*!          https://github.com/merwanroudane
*! Part of the -xturcoint- library (ports of GAUSS panel tests).
*!
*! Faithful port of the GAUSS routines BNG_PANICnew, JWL_PANICadj and
*!   JWR_PANICCA (tspdlib, PD_PANIC.src) by Saban Nazlioglu.
*!
*! References:
*!   Bai, J., Ng, S. (2010). Panel unit root tests with cross-section
*!     dependence: a further investigation. Econometric Theory 26(4):
*!     1088-1114. <doi:10.1017/S0266466609990478>
*!   Westerlund, J., Larsson, R. (2009). A note on the pooling of individual
*!     PANIC unit root tests. Econometric Theory 25(6): 1851-1868.
*!     <doi:10.1017/S0266466609990338>
*!   Reese, S., Westerlund, J. (2016). PANICCA: PANIC on cross-section
*!     averages. Journal of Applied Econometrics 31(6): 961-981.
*!     <doi:10.1002/jae.2487>
*!   Bai, J., Ng, S. (2002). Determining the number of factors in approximate
*!     factor models. Econometrica 70(1): 191-221. <doi:10.1111/1468-0262.00273>
*!
*! Step -> code map (see -help xturcoint_panic-):
*!   first differences, demeaning (trend case)        -> _xtpx_run
*!   number of factors, Bai-Ng (2002) PCp2 / ICp2     -> _xtpx_fnumber
*!   principal components / cross-section averages    -> _xtpx_pca / _xtpx_run
*!   cumulated idiosyncratic component e_it           -> _xtpx_run
*!   pooled Pa, Pb, PMSB (Bai-Ng 2010, p. 1092)       -> _xtpx_papb
*!   Bartlett LRV with automatic bandwidth            -> _xtpx_lrv
*!   individual ADF (no deterministics) + Ze, Ze+     -> _xtpx_adf0 / _xtpx_run

program _xturcoint_panic, rclass
    version 14.0
    syntax varname(numeric ts) [if] [in] [ , ///
        METHod(string)       ///
        MODel(string)        ///
        KMax(integer 5)      ///
        FCrit(string)        ///
        PMax(integer 8)      ///
        IC(string)           ///
        PAPer                ]

    marksample touse
    qui xtset
    local ivar "`r(panelvar)'"
    local tvar "`r(timevar)'"
    if ("`ivar'"=="" | "`tvar'"=="") {
        di as err "data must be {bf:xtset} with a panel and a time variable"
        exit 459
    }
    if ("`method'"=="") local method "bn2010"
    local method = strlower("`method'")
    if inlist("`method'","bn2010","bn","bainng","pc")              local meth 1
    else if inlist("`method'","wl2009","wl","westerlundlarsson")   local meth 2
    else if inlist("`method'","ca","panicca","rw2016","rw")        local meth 3
    else {
        di as err "method() must be bn2010, wl2009 or panicca"
        exit 198
    }
    if ("`model'"=="") local model "constant"
    local model = strlower("`model'")
    if inlist("`model'","constant","c")        local mod 1
    else if inlist("`model'","trend","ct","t") local mod 2
    else {
        di as err "model() must be constant or trend"
        exit 198
    }
    if ("`fcrit'"=="") local fcrit "pcp"
    local fcrit = strlower("`fcrit'")
    if inlist("`fcrit'","pcp","pc","1")        local fic 1
    else if inlist("`fcrit'","icp","ic","2")   local fic 2
    else {
        di as err "fcrit() must be pcp or icp"
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
    if `kmax' < 1 {
        di as err "kmax() must be >= 1"
        exit 198
    }
    if `pmax' < 0 {
        di as err "pmax() must be >= 0"
        exit 198
    }
    tempvar cnt
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
    if `meth' < 3 & `kmax' >= min(`N', `T'-1) {
        di as err "kmax() must be smaller than min(N, T-1)"
        exit 198
    }
    sort `ivar' `tvar'
    tempname ADF
    local ppr = ("`paper'" != "")
    mata: _xtpx_run("`varlist'", "`touse'", `N', `T', `meth', `mod', `kmax', `fic', `pmax', `icn', `ppr')
    local nf = r(nf)

    local mlab = cond(`mod'==1, "constant", "constant and trend")
    local flab = cond(`fic'==1, "PCp2", "ICp2")
    if `meth'==1 local ttl "Bai and Ng (2010) PANIC pooled tests (principal components)"
    if `meth'==2 local ttl "Westerlund and Larsson (2009) pooled PANIC ADF tests"
    if `meth'==3 local ttl "Reese and Westerlund (2016) PANICCA (cross-section averages)"
    di
    di as txt "`ttl'"
    di as txt "{hline 70}"
    di as txt "H0: all idiosyncratic components have a unit root" _col(52) "N  = " as res %6.0f `N'
    di as txt "H1: some are stationary" _col(52) as txt "T  = " as res %6.0f `T'
    di as txt "Deterministics : " as res "`mlab'"
    if `meth' < 3 di as txt "Common factors : " as res "`nf'" as txt " (Bai-Ng `flab', kmax = `kmax')"
    if `meth' == 3 di as txt "Common factor  : cross-section average of first differences"
    if `meth' == 2 di as txt "ADF lags       : max " as res "`pmax'" as txt " (" cond(`icn'==1,"AIC",cond(`icn'==2,"BIC","t-sig")) ")"
    di as txt "{hline 70}"
    di as txt _col(5) "Statistic" _col(26) "Value" _col(42) "p-value"
    di as txt "{hline 70}"
    if `meth'==2 local slist "Ze Ze_plus"
    else local slist "Pa Pb PMSB"
    foreach s of local slist {
        local v = r(`s')
        local pv = normal(`v')
        local p_`s' = `pv'
        local v_`s' = `v'
        local st = cond(`pv'<.01,"***",cond(`pv'<.05,"**",cond(`pv'<.10,"*","")))
        local lab "`s'"
        if "`s'"=="Ze_plus" local lab "Ze+ (bias-adj.)"
        di as txt _col(5) "`lab'" _col(20) as res %11.4f `v' _col(38) %9.4f `pv' as txt " `st'"
    }
    di as txt "{hline 70}"
    di as txt "Left-tailed N(0,1) tests.  *** p<0.01, ** p<0.05, * p<0.10"
    if `meth' != 2 {
        if `ppr' di as txt "Formulas: Bai and Ng (2010) paper (option {bf:paper})."
        else     di as txt "Formulas: GAUSS tspdlib (default). Option {bf:paper} gives the Bai-Ng (2010) formulas."
    }
    if `meth'==2 {
        matrix `ADF' = r(adf)
        matrix colnames `ADF' = ADF lags
        matrix rownames `ADF' = `units'
    }
    foreach s of local slist {
        return scalar `s'   = `v_`s''
        return scalar p_`s' = `p_`s''
    }
    if `meth' < 3 return scalar nfactors = `nf'
    return scalar N = `N'
    return scalar T = `T'
    return local method "`method'"
    return local model "`model'"
    return local varname "`varlist'"
    if `meth' != 2 return local formulas = cond(`ppr', "paper", "gauss")
    if `meth'==2 return matrix adf = `ADF'
end

mata:

// GAUSS pca(): returns ehat; loadings into lam (N x nf), factors into F
real matrix _xtpx_pca(real matrix X, real scalar nf, real matrix lam)
{
    real scalar T, N
    real matrix vec, F, ehat
    real colvector val
    T = rows(X)
    N = cols(X)
    if (T < N) {
        symeigensystem(X*X', vec, val)
        F   = sqrt(T)*vec[|1,1 \ T,nf|]
        lam = (luinv(F'*F)*F'*X)'
        ehat = X - F*lam'
    } else {
        symeigensystem(X'*X, vec, val)
        lam = sqrt(N)*vec[|1,1 \ N,nf|]
        F   = X*lam/N
        ehat = X - F*lam'
    }
    return(ehat)
}

real scalar _xtpx_fnumber(real matrix X, real scalar kmax, real scalar ic)
{
    real scalar T, N, k, sigma2, V, best, bestv, crit
    real matrix e, lam
    T = rows(X)
    N = cols(X)
    lam = .
    e = _xtpx_pca(X, kmax, lam)
    sigma2 = sum(e:^2)/(N*T)
    best = 1
    bestv = .
    for (k=1; k<=kmax; k=k+1) {
        e = _xtpx_pca(X, k, lam)
        V = sum(e:^2)/(N*T)
        if (ic == 1) crit = V + k*sigma2*(N+T)/(N*T)*ln(min((N,T)))
        if (ic == 2) crit = ln(V) + k*(N+T)/(N*T)*ln(min((N,T)))
        if (k == 1) {
            bestv = crit
            best = 1
        }
        if (crit < bestv) {
            bestv = crit
            best = k
        }
    }
    return(best)
}

// GAUSS _get_lrv(e, 0): returns (sigma2, omega2, lambda2) columns
// window v(1..T-j-1)'v(j+1..T-1) as in GAUSS and in the Reese-Westerlund code
real matrix _xtpx_lrv(real matrix e0, real scalar paper)
{
    real matrix e, e1, v
    real scalar rho, T, N, i, j, k, alpha, temp, ri, si
    real colvector topi, boti, u, sigma2, omega2, lambda2, w
    e1 = e0[|1,1 \ rows(e0)-1,cols(e0)|]
    e  = e0[|2,1 \ rows(e0),cols(e0)|]
    rho = sum(e1:*e)/sum(e1:*e1)
    v = e - e1*rho
    T = rows(v)
    N = cols(v)
    topi = J(N,1,0)
    boti = J(N,1,0)
    for (i=1; i<=N; i=i+1) {
        ri = (v[|2,i \ T,i|]'*v[|1,i \ T-1,i|])/(v[|2,i \ T,i|]'*v[|2,i \ T,i|])
        u  = v[|2,i \ T,i|] - ri*v[|1,i \ T-1,i|]
        si = (u'*u)/(T-1)
        topi[i] = 4*(ri^2)*si^2/(((1-ri)^6)*(1+ri)^2)
        boti[i] = si^2/((1-ri)^4)
    }
    alpha = sum(topi)/sum(boti)
    k = ceil(1.1447*(alpha*T)^(1/3))
    w = J(k,1,0)
    for (j=1; j<=k; j=j+1) {
        w[j] = 1 - j/(k+1)
    }
    sigma2 = J(N,1,0)
    omega2 = J(N,1,0)
    lambda2 = J(N,1,0)
    for (i=1; i<=N; i=i+1) {
        sigma2[i] = (v[.,i]'*v[.,i])/T
        omega2[i] = sigma2[i]
        for (j=1; j<=k; j=j+1) {
            temp = (v[|1,i \ T-j-1,i|]'*v[|j+1,i \ T-1,i|])/T
            omega2[i] = omega2[i] + 2*w[j]*temp
            lambda2[i] = lambda2[i] + w[j]*temp
        }
    }
    return((sigma2, omega2, lambda2))
}

// GAUSS PaPbPMSB(e, model); paper = 1 uses the Bai-Ng (2010, p. 1092) formulas
real rowvector _xtpx_papb(real matrix e0, real scalar model, real scalar paper)
{
    real matrix L, e, e1, ee
    real scalar sigma2, omega2, phi4, lambda, rho, T, N, rho1, s, Pa, Pb, PMSB, tr11, tr10
    L = _xtpx_lrv(e0, paper)
    omega2 = mean(L[.,2])
    sigma2 = mean(L[.,1])
    // GAUSS computes phi4 from the already-averaged omega2;
    // Bai and Ng (2010) define phi4 as the average of omega_i^4
    phi4   = omega2*omega2
    if (paper != 0) phi4 = mean(L[.,2]:^2)
    lambda = mean(L[.,3])
    e1 = e0[|1,1 \ rows(e0)-1,cols(e0)|]
    e  = e0[|2,1 \ rows(e0),cols(e0)|]
    tr10 = sum(e1:*e)
    tr11 = sum(e1:*e1)
    rho = tr10/tr11
    T = rows(e)
    N = cols(e)
    s = sqrt(N)*T
    if (model == 1) {
        rho1 = (tr10 - N*T*lambda)/tr11
        Pa = s*(rho1-1)/sqrt(2*phi4/(omega2^2))
        Pb = s*(rho1-1)*sqrt(tr11/s^2)*(omega2/phi4)
        if (paper != 0) Pb = s*(rho1-1)*sqrt((tr11/s^2)*(omega2/phi4))
        PMSB = sqrt(N)*(sum(e:*e)/(N*T^2) - 0.5*omega2)/sqrt(phi4/3)
    }
    if (model == 2) {
        rho1 = rho + 3/T*sigma2/omega2
        Pa = s*(rho1-1)/sqrt(36/5*phi4*sigma2^2/(omega2^4))
        Pb = s*(rho1-1)*sqrt(tr11/(s^2)*(5/6*omega2^3/(phi4*sigma2^2)))
        PMSB = sqrt(N)*(sum(e:*e)/(N*T^2) - omega2/6)/sqrt(phi4/45)
    }
    return((Pa, Pb, PMSB))
}

// GAUSS ADF(y, 0, pmax, ic): no deterministics; returns (tau, lags)
real rowvector _xtpx_adf0(real colvector y, real scalar pmax, real scalar ic)
{
    real scalar t, p, j, n, k, LL, ssr, ps
    real colvector dy, ly, dep, b, se, ee, taup, aicp, sicp, tstatp
    real matrix lmat, x, m
    t  = rows(y)
    dy = 0 \ (y[|2 \ t|] - y[|1 \ t-1|])
    ly = . \ y[|1 \ t-1|]
    lmat = J(t, max((pmax,1)), .)
    for (j=1; j<=pmax; j=j+1) {
        lmat[., j] = J(j,1,.) \ dy[|1 \ t-j|]
    }
    taup = J(pmax+1,1,0)
    aicp = J(pmax+1,1,0)
    sicp = J(pmax+1,1,0)
    tstatp = J(pmax+1,1,0)
    for (p=0; p<=pmax; p=p+1) {
        dep = dy[|p+2 \ t|]
        x = ly[|p+2 \ t|]
        if (p > 0) x = x, lmat[|p+2,1 \ t,p|]
        m  = luinv(x'*x)
        b  = m*(x'*dep)
        ee = dep - x*b
        ssr = ee'*ee
        se = sqrt(diagonal(m)*(ssr/(rows(dep)-cols(x))))
        n = rows(x)
        k = cols(x)
        taup[p+1] = b[1]/se[1]
        LL = -n/2*(1 + ln(2*pi()) + ln(ssr/n))
        aicp[p+1] = (2*k - 2*LL)/n
        sicp[p+1] = (k*ln(n) - 2*LL)/n
        tstatp[p+1] = abs(b[k]/se[k])
    }
    ps = _xtpx_getlag(ic, pmax, aicp, sicp, tstatp)
    return((taup[ps], ps-1))
}

real scalar _xtpx_getlag(real scalar ic, real scalar pmax, real colvector aicp,
                         real colvector sicp, real colvector tstatp)
{
    real scalar p, j, i
    if (ic == 1 | ic == 2) {
        p = 1
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

void _xtpx_run(string scalar vn, string scalar touse, real scalar N, real scalar T,
               real scalar meth, real scalar model, real scalar kmax, real scalar fic,
               real scalar pmax, real scalar ic, real scalar paper)
{
    real matrix Y, y, x, lam, ehat, e, de, adf, Fp, Ci
    real colvector de0, del, aN
    real rowvector r
    real scalar i, nf, rho, djwj, j, wj, EB, varB, Ze, Zeb
    Y = st_data(., vn, touse)
    y = J(T, N, .)
    for (i=1; i<=N; i=i+1) {
        y[., i] = Y[|(i-1)*T+1 \ i*T|]
    }
    x = y[|2,1 \ T,N|] - y[|1,1 \ T-1,N|]
    if (model == 2) x = x :- mean(x)
    st_rclear()
    if (meth == 1 | meth == 2) {
        nf = _xtpx_fnumber(x, kmax, fic)
        lam = .
        ehat = _xtpx_pca(x, nf, lam)
        e = runningsum(ehat[.,1])
        for (i=2; i<=N; i=i+1) {
            e = e, runningsum(ehat[.,i])
        }
        st_numscalar("r(nf)", nf)
    }
    if (meth == 1) {
        r = _xtpx_papb(e, model, paper)
        st_numscalar("r(Pa)", r[1])
        st_numscalar("r(Pb)", r[2])
        st_numscalar("r(PMSB)", r[3])
    }
    if (meth == 2) {
        adf = J(N, 2, .)
        for (i=1; i<=N; i=i+1) {
            adf[i,.] = _xtpx_adf0(e[.,i], pmax, ic)
        }
        aN = J(N,1,0)
        for (i=1; i<=N; i=i+1) {
            aN[i] = lam[i,.]*luinv(lam'*lam)*lam[i,.]'
        }
        de  = e[|2,1 \ rows(e),N|] - e[|1,1 \ rows(e)-1,N|]
        de0 = vec(de[|2,1 \ rows(de),N|])
        del = vec(de[|1,1 \ rows(de)-1,N|])
        rho = (del'*de0)/(del'*del)
        djwj = -1.669
        for (j=1; j<=100; j=j+1) {
            wj = 1.04605 - 5.54336*(j/T) + 19.4018*(j/T)^2 - 52.384*(j/T)^3 + 131.95*(j/T)^4 - 317.697*(j/T)^5
            djwj = djwj + (rho^j)*wj
        }
        EB = -0.431
        varB = 0.929
        Ze  = sqrt(N)*(mean(adf[.,1]) - EB)/sqrt(varB)
        Zeb = Ze - djwj*sum(aN)/(sqrt(varB)*sqrt(N))
        st_numscalar("r(Ze)", Ze)
        st_numscalar("r(Ze_plus)", Zeb)
        st_matrix("r(adf)", adf)
    }
    if (meth == 3) {
        Fp = rowsum(x)/N
        Ci = luinv(Fp'*Fp)*Fp'*x
        e  = x - Fp*Ci
        for (i=1; i<=N; i=i+1) {
            e[., i] = runningsum(e[., i])
        }
        r = _xtpx_papb(e, model, paper)
        st_numscalar("r(Pa)", r[1])
        st_numscalar("r(Pb)", r[2])
        st_numscalar("r(PMSB)", r[3])
    }
}
end
