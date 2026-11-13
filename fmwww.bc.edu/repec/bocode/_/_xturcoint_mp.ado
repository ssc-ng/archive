*! _xturcoint_mp 1.0.0  11nov2026   (engine of: xturcoint mp)
*! Moon and Perron (2004) panel unit-root tests with dynamic common factors
*! Author : Dr Merwan Roudane  merwanroudane920@gmail.com
*!          https://github.com/merwanroudane
*! Part of the -xturcoint- library (ports of GAUSS panel tests).
*!
*! Faithful port of the GAUSS routine pu_mp04 (carrionlib, pu_mp.src) by
*!   T. Yamagata, itself based on the MATLAB code of Moon and Perron.
*!
*! Reference:
*!   Moon, H. R., Perron, B. (2004). Testing for a unit root in panels with
*!     dynamic factors. Journal of Econometrics 122(1): 81-126.
*!     <doi:10.1016/j.jeconom.2003.10.020>
*!   Andrews, D. W. K., Monahan, J. C. (1992). An improved heteroskedasticity
*!     and autocorrelation consistent covariance matrix estimator.
*!     Econometrica 60(4): 953-966. <doi:10.2307/2951574>
*!
*! Step -> code map (see -help xturcoint_mp-):
*!   detrending (case trend)                          -> _xtmp_run
*!   pooled OLS rho_hat, residual PCA (m factors)     -> _xtmp_run / _xtmp_ortho
*!   defactored data Z Q_beta                         -> _xtmp_ortho
*!   QS-kernel LRV, AR(1) prewhitening, Andrews bw    -> _xtmp_lrcov
*!   bias-corrected rho*, t*_a and t*_b (p. 92)       -> _xtmp_run

program _xturcoint_mp, rclass
    version 14.0
    syntax varname(numeric ts) [if] [in] [ , ///
        MODel(string)       ///
        Factors(integer 1)  ]

    marksample touse
    qui xtset
    local ivar "`r(panelvar)'"
    local tvar "`r(timevar)'"
    if ("`ivar'"=="" | "`tvar'"=="") {
        di as err "data must be {bf:xtset} with a panel and a time variable"
        exit 459
    }
    if ("`model'"=="") local model "constant"
    local model = strlower("`model'")
    if inlist("`model'","constant","c","none","n") local case 2
    else if inlist("`model'","trend","ct","t")    local case 3
    else {
        di as err "model() must be constant or trend"
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
    local T1 = r(max)
    local T  = `T1' - 1
    qui levelsof `ivar' if `touse', local(units)
    local N : word count `units'
    if `factors' < 0 | `factors' >= min(`N', `T') {
        di as err "factors() must lie in [0, min(N,T)-1]"
        exit 198
    }
    sort `ivar' `tvar'
    mata: _xtmp_run("`varlist'", "`touse'", `N', `T1', `factors', `case')
    local ta = r(ta)
    local tb = r(tb)
    local pa = normal(`ta')
    local pb = normal(`tb')

    local mlab = cond(`case'==3, "trend", "no trend (constant)")
    di
    di as txt "Moon and Perron (2004) panel unit-root tests with common factors"
    di as txt "{hline 66}"
    di as txt "H0: all panels contain a unit root" _col(42) "Number of panels" _col(60) "= " as res %5.0f `N'
    di as txt "H1: some panels are stationary"     _col(42) "Periods used (T+1)" _col(60) "= " as res %5.0f `T1'
    di as txt "Deterministics : " as res "`mlab'" _col(42) as txt "Common factors" _col(60) "= " as res %5.0f `factors'
    di as txt "Long-run variance: QS kernel, AR(1) prewhitening, Andrews-Monahan bandwidth"
    di as txt "{hline 66}"
    di as txt _col(5) "Statistic" _col(26) "Value" _col(42) "p-value"
    di as txt "{hline 66}"
    foreach s in a b {
        local pv = `p`s''
        local st = cond(`pv'<.01,"***",cond(`pv'<.05,"**",cond(`pv'<.10,"*","")))
        di as txt _col(5) "t*_`s'" _col(20) as res %11.4f `t`s'' _col(38) %9.4f `pv' as txt " `st'"
    }
    di as txt "{hline 66}"
    di as txt "Left-tailed N(0,1) tests.  *** p<0.01, ** p<0.05, * p<0.10"

    return scalar t_a = `ta'
    return scalar t_b = `tb'
    return scalar p_a = `pa'
    return scalar p_b = `pb'
    return scalar rhostar = r(rhostar)
    return scalar factors = `factors'
    return scalar N = `N'
    return scalar T = `T'
    return local model "`model'"
    return local varname "`varlist'"
end

mata:

real matrix _xtmp_ortho(real matrix y, real matrix yhat, real matrix v, real scalar k)
{
    real scalar t, n
    real matrix loadings, factors, betahat, nrm, qbeta
    t = rows(y)
    n = cols(y)
    if (k == 0) return(y)
    if (n <= t) {
        loadings = sqrt(n)*v[|1,n-k+1 \ rows(v),n|]
        betahat  = (yhat'*yhat)*loadings/(n*t)
    }
    if (n > t) {
        factors  = sqrt(t)*v[|1,t-k+1 \ rows(v),t|]
        loadings = yhat'*factors/t
        nrm      = loadings'*loadings/n
        betahat  = loadings*cholesky(nrm)'
    }
    qbeta = I(n) - betahat*luinv(betahat'*betahat)*betahat'
    return(y*qbeta)
}

// GAUSS LRcov(x, 1, 999) for a single series: returns omega
real scalar _xtmp_lrcov(real colvector x)
{
    real scalar t, a, b, s4, sdeux, szero, delta, L, j, gama, v, w, qs, omega, dinv
    real colvector xt, xl, xpw, res
    t  = rows(x)
    xt = x[|2 \ t|]
    xl = x[|1 \ t-1|]
    a  = (xt'*xl)/(xl'*xl)
    if (a > 0.97 | a < -0.97) a = 0.97*(2*(a>1)-1)
    xpw = xt - xl*a
    omega = (xpw'*xpw)/t
    xt = xpw[|2 \ t-1|]
    xl = xpw[|1 \ t-2|]
    b  = (xt'*xl)/(xl'*xl)
    res = xt - xl*b
    s4 = ((res'*res)/t)^2
    sdeux = 4*(b^2)*s4/((1-b)^8)
    szero = s4/((1-b)^4)
    delta = 1.3221*(sdeux/szero)^(0.2)
    L = delta*t^(0.2)
    for (j=1; j<=t-2; j=j+1) {
        gama = (xpw[|j+1 \ t-1|]'*xpw[|1 \ t-j-1|])/t
        v  = j/L
        w  = 6*pi()*v/5
        qs = (25/(12*((pi()*v)^2)))*((sin(w)/w) - cos(w))
        omega = omega + qs*(2*gama)
    }
    dinv = 1/(1-a)
    return(dinv*omega*dinv)
}

void _xtmp_run(string scalar vn, string scalar touse, real scalar N,
               real scalar T1, real scalar m, real scalar cs)
{
    real matrix Y, z, x1, ztl, ztt, yhat, vec, zqb, zqbl, res
    real colvector vals, sig, omega
    real scalar i, t, rhohat, sigsq, omsq, lambda, phi4, trzq, trzql, rhostar, NT, ta, tb
    Y = st_data(., vn, touse)
    z = J(T1, N, .)
    for (i=1; i<=N; i=i+1) {
        z[., i] = Y[|(i-1)*T1+1 \ i*T1|]
    }
    t = T1 - 1
    if (cs == 3) {
        x1 = J(T1,1,1), (1::T1)
        z  = z - x1*luinv(x1'*x1)*x1'*z
    }
    ztt = z[|2,1 \ T1,N|]
    ztl = z[|1,1 \ t,N|]
    rhohat = sum(ztl:*ztt)/sum(ztl:*ztl)
    yhat = ztt - rhohat*ztl
    if (N <= t) symeigensystem(yhat'*yhat, vec, vals)
    if (N > t)  symeigensystem(yhat*yhat', vec, vals)
    // symeigensystem returns descending eigenvalues; GAUSS eighv ascending
    vec = vec[., cols(vec)..1]
    zqb  = _xtmp_ortho(ztt, yhat, vec, m)
    zqbl = _xtmp_ortho(ztl, yhat, vec, m)
    res  = zqb - rhohat*zqbl
    sig  = colsum(abs(res):^2)'/t
    sigsq = sum(sig)/N
    omega = J(N,1,.)
    for (i=1; i<=N; i=i+1) {
        omega[i] = _xtmp_lrcov(res[., i])
    }
    omsq   = mean(omega)
    lambda = 0.5*(omsq - sigsq)
    phi4   = (omega'*omega)/N
    trzq   = sum(zqbl:*zqb)
    trzql  = sum(zqbl:*zqbl)
    NT = sqrt(N)*t
    if (cs != 3) {
        rhostar = (trzq - N*t*lambda)/trzql
        ta = NT*(rhostar-1)/sqrt(2*phi4/omsq^2)
        tb = NT*(rhostar-1)*sqrt(trzql/(N*t^2))*sqrt(omsq/phi4)
    }
    if (cs == 3) {
        rhostar = (trzq + 0.5*N*t*mean(sig))/trzql
        ta = NT*(rhostar-1)/sqrt((15/4)*phi4/omsq^2)
        tb = NT*(rhostar-1)*sqrt(trzql/(N*t^2))*sqrt(4*omsq/phi4)
    }
    st_rclear()
    st_numscalar("r(ta)", ta)
    st_numscalar("r(tb)", tb)
    st_numscalar("r(rhostar)", rhostar)
}
end
