*! _tsurcoint_qkss 1.0.0  12nov2026   (engine of: tsurcoint qkss | qfkss | qks)
*! Quantile KSS, quantile Fourier KSS and quantile Kolmogorov-Smirnov unit-root tests
*! Author : Dr Merwan Roudane  merwanroudane920@gmail.com
*!          https://github.com/merwanroudane
*! Part of the -tsurcoint- library (ports of GAUSS time-series tests).
*!
*! Faithful port of the GAUSS routines QR_KSS, QR_Fourier_KSS,
*!   QR_Fourier_KSS_bootstrap, qks_tests and QKS_bootstrap (tspdlib 3.0.0,
*!   with quantileADF and QR_Fourier_ADF) by Saban Nazlioglu. Quantile
*!   regressions use the GAUSS quantileFit interior-point solver, ported to Mata.
*!
*! References:
*!   Koenker, R., Xiao, Z. (2004). Unit root quantile autoregression inference.
*!     Journal of the American Statistical Association 99: 775-787.
*!     <doi:10.1198/016214504000001114>
*!   Li, H., Park, S. Y. (2018). Testing for a unit root in a nonlinear quantile
*!     autoregression framework. Econometric Reviews 37(8): 867-892.
*!     <doi:10.1080/07474938.2016.1222225>
*!   Li, H., Zheng, C. (2018). Unit root quantile autoregression testing with
*!     smooth structural changes. Finance Research Letters 25: 83-89.
*!     <doi:10.1016/j.frl.2017.10.011>
*!   Bahmani-Oskooee, M., Chang, T., Niroomand, F., Ranjbar, O. (2020). Fourier
*!     nonlinear quantile unit root test and PPP in Africa. Bulletin of Economic
*!     Research 72(4): 451-481. <doi:10.1111/boer.12228>
*!
*! Step -> code map (see -help tsurcoint_qkss- etc.):
*!   regression design (KSS: y^3_{t-1}; Fourier sin/cos; lags; trend) -> _tsq_setup
*!   rho(tau), rho(tau +- h): GAUSS quantileFit interior point      -> _tsq_rq / _tsq_h
*!   t_n(tau) = f(tau)/sqrt(tau(1-tau)) sqrt(Y'PxY) rho(tau)         -> _tsq_stat
*!   delta^2 and interpolated Li-Park critical values                -> _tsq_stat
*!   QKS = max_tau |t_n(tau)|, tau in {0.10, 0.11, ..., 0.69}         -> _tsurcoint_qkss
*!   residual bootstrap (AR(1) residuals, random-walk rebuild)        -> _tsq_bootprep

program _tsurcoint_qkss, rclass
    version 14.0
    gettoken test 0 : 0
    syntax varname(numeric ts) [if] [in] [ , ///
        MODel(string)        ///
        TAU(numlist >0 <1)   ///
        Lags(integer 8)      ///
        FReq(integer 3)      ///
        TESTtype(string)     ///
        BOOTstrap(integer 0) ///
        SEED(string)         ]

    marksample touse
    qui tsset
    local tvar "`r(timevar)'"
    if "`r(panelvar)'" != "" {
        di as err "tsurcoint needs a single time series: the data are {bf:xtset}/panel."
        exit 459
    }
    if ("`model'"=="") local model "constant"
    local model = strlower("`model'")
    if inlist("`model'","constant","c","1")        local mod 1
    else if inlist("`model'","trend","ct","t","2") local mod 2
    else {
        di as err "model() must be constant or trend"
        exit 198
    }
    if `lags' < 0 {
        di as err "lags() must be >= 0"
        exit 198
    }
    if `freq' < 1 | `freq' > 5 {
        di as err "freq() must lie in 1..5"
        exit 198
    }
    // which statistic: 1 QADF, 2 QR Fourier ADF, 3 QR KSS, 4 QR Fourier KSS
    if "`test'" == "qkss"  local tt 3
    if "`test'" == "qfkss" local tt 4
    if "`test'" == "qks" {
        if ("`testtype'"=="") local testtype "kss"
        local testtype = strlower("`testtype'")
        if inlist("`testtype'","adf","1")        local tt 1
        else if inlist("`testtype'","fadf","2")  local tt 2
        else if inlist("`testtype'","kss","3")   local tt 3
        else if inlist("`testtype'","fkss","4")  local tt 4
        else {
            di as err "testtype() must be adf, fadf, kss or fkss"
            exit 198
        }
    }
    if "`test'" != "qks" & "`tau'" == "" local tau "0.25 0.5 0.75"
    if "`test'" == "qks" & "`tau'" != "" {
        di as err "tau() is not allowed with {bf:tsurcoint qks}: the statistic uses tau = 0.10(0.01)0.69 as in GAUSS"
        exit 198
    }
    if "`bootstrap'" != "0" & "`test'" == "qkss" {
        di as err "bootstrap() is available for {bf:qfkss} and {bf:qks}; {bf:qkss} uses the Li-Park critical values"
        exit 198
    }
    qui count if `touse'
    local T = r(N)
    qui summ `tvar' if `touse', meanonly
    if (r(max) - r(min) + 1) != `T' {
        di as err "the sample must be contiguous (no gaps or missing values inside the sample)"
        exit 459
    }
    if `T' < `lags' + 20 {
        di as err "too few observations (T = `T') for lags(`lags')"
        exit 2001
    }
    if "`seed'" != "" set seed `seed'
    if "`test'" == "qks" {
        mata: st_local("tau", _tsq_qksgrid())
    }
    local ntau : word count `tau'

    sort `tvar'
    mata: _TSQ_y0 = st_data(., "`varlist'", "`touse'")
    tempname R BOOT
    local B = `bootstrap'
    if `B' > 0 & "`test'"=="qks" di as txt "(bootstrap: `B' replications x 60 quantiles x 3 quantile regressions)"
    mata: _tsq_main(`tt', `mod', `lags', `freq', "`tau'", `B', "`test'", "`R'", "`BOOT'")
    local plag = r(plag)
    local nobs = r(nobs)

    // ---------------- display
    local mlab = cond(`mod'==1, "constant", "constant and trend")
    if `tt'==1 local snm "QR-ADF (Koenker-Xiao 2004)"
    if `tt'==2 local snm "QR Fourier ADF (Li-Zheng 2018)"
    if `tt'==3 local snm "QR KSS (Li-Park 2018)"
    if `tt'==4 local snm "QR Fourier KSS (Bahmani-Oskooee et al. 2020)"
    di
    if "`test'" == "qks" di as txt "Quantile Kolmogorov-Smirnov unit-root test: QKS = max |t_n(tau)| of the `snm'"
    else di as txt "Quantile unit-root test: `snm'"
    di as txt "{hline 76}"
    di as txt "H0: unit root at the quantile(s) considered" _col(48) "Observations" _col(66) "= " as res %6.0f `T'
    di as txt "Deterministics : " as res "`mlab'" _col(48) as txt "Lags" _col(66) "= " as res %6.0f `plag'
    if inlist(`tt',2,4) di as txt "Fourier frequency : " as res "`freq'" as txt " (fixed, as in GAUSS)"
    if `tt'==1 di as txt "(lags selected by the ADF t-sig rule with a constant, max `lags', as in GAUSS quantileADF)"
    di as txt "{hline 76}"
    local tcv = ""
    if "`test'" == "qks" {
        mata: _tsq_qksfind(st_matrix("`R'"))
        local qks = r(qks)
        local qtau = r(qtau)
        di as txt _col(5) "Statistic" _col(30) "Value" _col(42) "tau*" _col(54) "1%" _col(62) "5%" _col(70) "10%"
        di as txt "{hline 76}"
        if `B' > 0 {
            mata: st_matrix("`BOOT'", sort(st_matrix("`BOOT'"),1))
            local c1  = `BOOT'[max(1,round(0.99*`B')),1]
            local c5  = `BOOT'[max(1,round(0.95*`B')),1]
            local c10 = `BOOT'[max(1,round(0.90*`B')),1]
            local st = cond(`qks'>`c1',"***",cond(`qks'>`c5',"**",cond(`qks'>`c10',"*","")))
            di as txt _col(5) "QKS" _col(22) as res %11.4f `qks' _col(40) %6.2f `qtau' _col(50) %7.3f `c1' %8.3f `c5' %8.3f `c10' as txt " `st'"
        }
        else di as txt _col(5) "QKS" _col(22) as res %11.4f `qks' _col(40) %6.2f `qtau'
        di as txt "{hline 76}"
        if `B' > 0 di as txt "Right-tailed; residual bootstrap critical values (`B' replications).  *** 1%, ** 5%, * 10%"
        else di as txt "GAUSS reports no critical values; use {bf:bootstrap(#)} (GAUSS QKS_bootstrap)."
    }
    else {
        di as txt _col(3) "tau" _col(12) "rho(tau)" _col(24) "delta^2" _col(36) "t_n(tau)" _col(52) "1%" _col(60) "5%" _col(68) "10%"
        di as txt "{hline 76}"
        if `B' > 0 & `tt'==4 {
            mata: st_matrix("`BOOT'", sort(st_matrix("`BOOT'"),1))
            local b1  = `BOOT'[max(1,round(0.01*`B')),1]
            local b5  = `BOOT'[max(1,round(0.05*`B')),1]
            local b10 = `BOOT'[max(1,round(0.10*`B')),1]
        }
        forvalues j = 1/`ntau' {
            local s = `R'[`j',4]
            local c1 = `R'[`j',5]
            local c5 = `R'[`j',6]
            local c10 = `R'[`j',7]
            if `B' > 0 & `tt'==4 & `j'==1 {
                local c1 = `b1'
                local c5 = `b5'
                local c10 = `b10'
            }
            if `c1' < . {
                local st = cond(`s'<`c1',"***",cond(`s'<`c5',"**",cond(`s'<`c10',"*","")))
                di as txt _col(3) %4.2f `R'[`j',1] _col(10) as res %10.4f `R'[`j',2] _col(22) %9.4f `R'[`j',3] _col(34) %10.4f `s' _col(48) %7.3f `c1' %8.3f `c5' %8.3f `c10' as txt " `st'"
            }
            else di as txt _col(3) %4.2f `R'[`j',1] _col(10) as res %10.4f `R'[`j',2] _col(22) %9.4f `R'[`j',3] _col(34) %10.4f `s'
        }
        di as txt "{hline 76}"
        if `tt'==3 di as txt "Left-tailed; critical values of Li and Park (2018) interpolated in delta^2.  *** 1%, ** 5%, * 10%"
        if `tt'==4 & `B'==0 di as txt "GAUSS reports no critical values; use {bf:bootstrap(#)} (GAUSS QR_Fourier_KSS_bootstrap)."
        if `tt'==4 & `B'>0 di as txt "Left-tailed; residual bootstrap critical values for tau = " %4.2f `R'[1,1] " (`B' replications)."
    }

    matrix colnames `R' = tau rho delta2 stat cv1 cv5 cv10
    if "`test'" == "qks" {
        return scalar qks = `qks'
        return scalar tau_star = `qtau'
        if `B' > 0 {
            return scalar cv1 = `c1'
            return scalar cv5 = `c5'
            return scalar cv10 = `c10'
        }
        return matrix process = `R'
    }
    else {
        return scalar stat = `R'[1,4]
        return scalar rho = `R'[1,2]
        return matrix results = `R'
        if `B' > 0 {
            return scalar cv1 = `b1'
            return scalar cv5 = `b5'
            return scalar cv10 = `b10'
        }
    }
    return scalar T = `T'
    return scalar lags = `plag'
    if inlist(`tt',2,4) return scalar freq = `freq'
    return local model "`model'"
    return local test "`test'"
    return local varname "`varlist'"
end

mata:

real colvector _tsq_diff(real colvector x)
{
    return(0 \ (x[|2 \ rows(x)|] - x[|1 \ rows(x)-1|]))
}

real colvector _tsq_lag(real colvector x, real scalar j)
{
    return(J(j,1,.) \ x[|1 \ rows(x)-j|])
}

string scalar _tsq_qksgrid()
{
    real scalar q
    string scalar s
    q = 0.1
    s = ""
    while (q <= 0.7) {
        s = s + " " + strofreal(q, "%21.18g")
        q = q + 0.01
    }
    return(s)
}

// GAUSS __get_qr_adf_h + bandwidth (Hall-Sheather, then Bofinger, then tau/1.5)
real scalar _tsq_h(real scalar tau, real scalar n)
{
    real scalar x0, f0, h
    x0 = invnormal(tau)
    f0 = normalden(x0)
    h = n^(-1/3) * invnormal(1-0.05/2)^(2/3) * ((1.5*f0^2)/(2*x0^2+1))^(1/3)
    if (tau <= 0.5 & h > tau) {
        h = n^(-0.2) * ((4.5*f0^4)/(2*x0^2+1)^2)^0.2
        if (h > tau) h = tau/1.5
    }
    if (tau > 0.5 & h > 1-tau) {
        h = n^(-0.2) * ((4.5*f0^4)/(2*x0^2+1)^2)^0.2
        if (h > (1-tau)) h = (1-tau)/1.5
    }
    return(h)
}

// GAUSS ADF(y, 1, pmax, 3): lags selected by the t-sig rule with a constant
real scalar _tsq_adflag(real colvector y, real scalar pmax)
{
    real scalar t, p, j, k, n, ssr
    real colvector dy, ly, dep, b, se, e, tst
    real matrix x, m, L
    t  = rows(y)
    dy = _tsq_diff(y)
    ly = _tsq_lag(y, 1)
    L  = J(t, max((pmax,1)), .)
    for (j=1; j<=pmax; j=j+1) {
        L[., j] = _tsq_lag(dy, j)
    }
    tst = J(pmax+1,1,0)
    for (p=0; p<=pmax; p=p+1) {
        x = ly, J(t,1,1)
        x = x[|p+2,1 \ t,2|]
        if (p > 0) x = x, L[|p+2,1 \ t,p|]
        dep = dy[|p+2 \ t|]
        m = luinv(x'*x)
        b = m*(x'*dep)
        e = dep - x*b
        ssr = e'*e
        n = rows(x)
        k = cols(x)
        se = sqrt(diagonal(m)*(ssr/(n-k)))
        tst[p+1] = abs(b[k]/se[k])
    }
    j = pmax + 1
    while (j >= 1) {
        if (abs(tst[j]) > 1.645) break
        j = j - 1
    }
    if (j == 0) j = 1
    return(j - 1)
}

// build the quantile regression design; leaves _tsq_dep, _tsq_x1..K in memory
void _tsq_setup(real scalar tt, real scalar model, real scalar p, real scalar k, real scalar src)
{
    external real colvector _TSQ_y0, _TSQ_ys
    external real colvector _TSQ_Y1, _TSQ_dep, _TSQ_w
    external real matrix _TSQ_X, _TSQ_XX
    external real scalar _TSQ_n, _TSQ_plag
    real colvector y, dy, y1, tr, s, c
    real matrix x, L
    real scalar T, j, pp, n, tq
    y = _TSQ_y0
    if (src != 0) y = _TSQ_ys
    T  = rows(y)
    dy = _tsq_diff(y)
    pp = p
    if (tt == 1) pp = _tsq_adflag(y, p)
    L  = J(T, max((pp,1)), .)
    for (j=1; j<=pp; j=j+1) {
        L[., j] = _tsq_lag(dy, j)
    }
    if (tt == 3 | tt == 4) {
        // QR_KSS / QR_Fourier_KSS
        y1 = _tsq_lag(y:^3, 1)
        x  = y1
        if (pp > 0) x = x, L[|1,1 \ T,pp|]
        if (tt == 4) {
            tr = (1::T)
            x = x, sin(2*pi()*k*tr/T), cos(2*pi()*k*tr/T)
            if (model == 2) x = x, tr
        }
        x = x[|pp+2,1 \ T,cols(x)|]
        if (tt == 3 & model == 2) x = x, (1::rows(x))
        _TSQ_dep = dy[|pp+2 \ T|]
        _TSQ_Y1  = y1[|pp+2 \ T|]
        _TSQ_X   = x
        _TSQ_XX  = J(rows(x),1,1)
        if (cols(x) > 1) _TSQ_XX = _TSQ_XX, x[|1,2 \ rows(x),cols(x)|]
        _TSQ_w   = _TSQ_dep
        n = T
    }
    if (tt == 1 | tt == 2) {
        // quantileADF / QR_Fourier_ADF: regression of y on its lag
        y1 = _tsq_lag(y, 1)
        _TSQ_dep = y[|pp+2 \ T|]
        _TSQ_Y1  = y1[|pp+2 \ T|]
        x = _TSQ_Y1
        if (pp > 0) x = x, L[|pp+2,1 \ T,pp|]
        tq = rows(_TSQ_dep)
        if (tt == 2) {
            tr = (1::tq)
            x = x, sin(2*pi()*k*tr/tq), cos(2*pi()*k*tr/tq)
        }
        if (model == 2) x = x, (pp+2::T)
        _TSQ_X = x
        _TSQ_XX = J(rows(x),1,1)
        if (tt == 1 & pp > 0) _TSQ_XX = _TSQ_XX, L[|pp+2,1 \ T,pp|]
        if (tt == 2 & cols(x) > 1) _TSQ_XX = _TSQ_XX, x[|1,2 \ rows(x),cols(x)|]
        _TSQ_w = (_tsq_diff(y))[|pp+2 \ T|]
        n = rows(_TSQ_dep)
    }
    _TSQ_n = n
    _TSQ_plag = pp
}

real rowvector _tsq_stat(real scalar tt, real scalar model, real scalar tau, real scalar h,
               real colvector b0, real colvector b1, real colvector b2)
{
    external real colvector _TSQ_Y1, _TSQ_dep, _TSQ_w
    external real matrix _TSQ_X, _TSQ_XX
    external real scalar _TSQ_n, _TSQ_plag
    real colvector mz, res, phi, w
    real matrix Z
    real scalar rho, q1, q2, fz, yPy, stat, cov, d2, r210, ra, rb, wa
    real rowvector cv
    real matrix crt
    rho = b0[2]
    Z  = J(rows(_TSQ_X),1,1), _TSQ_X
    mz = mean(Z)'
    q1 = mz'*b1
    q2 = mz'*b2
    fz = 2*h/(q1 - q2)
    if (fz < 0) fz = 0.01
    yPy = _TSQ_Y1'*_TSQ_Y1 - (_TSQ_Y1'*_TSQ_XX)*luinv(_TSQ_XX'*_TSQ_XX)*(_TSQ_XX'*_TSQ_Y1)
    stat = fz/sqrt(tau*(1-tau))*sqrt(yPy)*(rho - 1)
    if (tt >= 3) stat = fz/sqrt(tau*(1-tau))*sqrt(yPy)*rho
    // delta^2 (GAUSS __get_qr_adf_delta2); Fourier variants use w = residuals
    res = _TSQ_dep - Z*b0
    phi = tau :- (res :< 0)
    w   = _TSQ_w
    if (tt == 2) w = res
    cov = sum((w :- mean(w)):*(phi :- mean(phi)))/(rows(w)-1)
    d2  = (cov/(sqrt(variance(w))*sqrt(tau*(1-tau))))^2
    cv  = (., ., .)
    if (tt == 3) {
        if (model == 1) {
            crt = (-2.83,-2.16,-1.80 \ -2.99,-2.34,-1.99 \ -3.12,-2.46,-2.12 \ -3.22,-2.59,-2.25 \ -3.27,-2.67,-2.34 \
                   -3.34,-2.74,-2.43 \ -3.38,-2.80,-2.49 \ -3.40,-2.85,-2.55 \ -3.42,-2.88,-2.60 \ -3.47,-2.92,-2.65)
        }
        if (model == 2) {
            crt = (-2.97,-2.29,-1.94 \ -3.19,-2.55,-2.20 \ -3.35,-2.73,-2.40 \ -3.51,-2.88,-2.55 \ -3.58,-2.99,-2.66 \
                   -3.68,-3.09,-2.78 \ -3.74,-3.16,-2.87 \ -3.79,-3.26,-2.97 \ -3.87,-3.32,-3.04 \ -3.90,-3.37,-3.10)
        }
        if (d2 < .1) cv = crt[1,.]
        if (d2 >= .1) {
            r210 = d2*10
            if (r210 >= 10) cv = crt[10,.]
            if (r210 < 10) {
                ra = floor(r210)
                rb = ceil(r210)
                wa = rb - r210
                cv = wa*crt[ra,.] + (1-wa)*crt[rb,.]
            }
        }
    }
    return((tau, rho, d2, stat, cv))
}

real scalar _tsq_qksrow(real matrix R)
{
    real scalar i, m
    m = 1
    for (i=2; i<=rows(R); i=i+1) {
        if (abs(R[i,4]) > abs(R[m,4])) m = i
    }
    return(m)
}

void _tsq_qksfind(real matrix R)
{
    real scalar m
    m = _tsq_qksrow(R)
    st_numscalar("r(qks)", abs(R[m,4]))
    st_numscalar("r(qtau)", R[m,1])
}

// statistic(s) for every tau on the current design
real matrix _tsq_evalm(real scalar tt, real scalar model, real colvector taus)
{
    external real colvector _TSQ_dep
    external real matrix _TSQ_X
    external real scalar _TSQ_n
    real matrix R
    real colvector b0, b1, b2
    real scalar j, h, q
    R = J(rows(taus), 7, .)
    for (j=1; j<=rows(taus); j=j+1) {
        q  = taus[j]
        h  = _tsq_h(q, _TSQ_n)
        b0 = _tsq_rq(_TSQ_dep, _TSQ_X, q)
        b1 = _tsq_rq(_TSQ_dep, _TSQ_X, q + h)
        b2 = _tsq_rq(_TSQ_dep, _TSQ_X, q - h)
        R[j,.] = _tsq_stat(tt, model, q, h, b0, b1, b2)
    }
    return(R)
}

void _tsq_main(real scalar tt, real scalar model, real scalar p, real scalar k,
               string scalar taulist, real scalar B, string scalar test,
               string scalar Rn, string scalar Bn)
{
    external real scalar _TSQ_plag
    external real colvector _TSQ_dep
    real colvector taus, boot
    real matrix R, Rb
    real scalar b, plag, nobs
    taus = strtoreal(tokens(taulist))'
    _tsq_setup(tt, model, p, k, 0)
    plag = _TSQ_plag
    nobs = rows(_TSQ_dep)
    R = _tsq_evalm(tt, model, taus)
    st_matrix(Rn, R)
    if (B > 0) {
        _tsq_bootprep(tt, model, p, k, test)
        boot = J(B,1,.)
        for (b=1; b<=B; b=b+1) {
            _tsq_bootdraw()
            _tsq_setup(tt, model, p, k, 1)
            Rb = _tsq_evalm(tt, model, taus)
            if (test == "qks") boot[b] = abs(Rb[_tsq_qksrow(Rb),4])
            if (test != "qks") boot[b] = Rb[1,4]
        }
        st_matrix(Bn, boot)
    }
    st_rclear()
    st_numscalar("r(plag)", plag)
    st_numscalar("r(nobs)", nobs)
}

// ---------------------------------------------------------------------------
// GAUSS quantileFit (quantilefit.src, __quant_level_reg + __Qreg_solveLP1):
// Frisch-Newton interior-point LP, eps = 1e-4, max 50 iterations,
// sigma = 0.9999995; a constant is added as the first regressor.
// ---------------------------------------------------------------------------
real scalar _tsq_tfm(real colvector d, real colvector x)
{
    real scalar m, i
    m = 1e20
    for (i=1; i<=rows(d); i=i+1) {
        if (d[i] < 0) {
            if (-x[i]/d[i] < m) m = -x[i]/d[i]
        }
    }
    return(m)
}

real scalar _tsq_fdelta(real colvector d1, real colvector x1, real colvector d2,
                        real colvector x2, real scalar sigma)
{
    return(min((sigma*_tsq_tfm(d1, x1), sigma*_tsq_tfm(d2, x2), 1)))
}

real colvector _tsq_rq(real colvector yv, real matrix X0, real scalar tau)
{
    real matrix X, A, AqA
    real colvector sv, c, b, u, yd, r, z, w, x, s, q, Aqr, dy, dx, ds, dz, dw,
                   dxdz, dsdw, xinv, sinv, xi
    real scalar N, gap, it, dp, dd, mu, g, sigma
    X  = J(rows(X0),1,1), X0
    N  = rows(X)
    sigma = 0.9999995
    sv = (1-tau)*J(N,1,1)
    c  = -yv
    A  = X'
    b  = X'*sv
    u  = J(N,1,1)
    yd = luinv(X'*X)*(X'*(-yv))
    r  = -yv - X*yd
    z  = r:*(r:>0)
    w  = z - r
    x  = sv
    s  = u - x
    gap = c'*x - b'*yd + u'*w
    it = 1
    while ((it <= 50) & (gap > 0.0001)) {
        q   = 1:/(z:/x + w:/s)
        r   = z - w
        Aqr = A*(q:*r)
        AqA = A*(q:*A')
        dy  = lusolve(AqA, Aqr)
        dx  = q:*(A'*dy - r)
        ds  = -dx
        dz  = (-z:*dx):/x - z
        dw  = (-w:*ds):/s - w
        dp  = _tsq_fdelta(dx, x, ds, s, sigma)
        dd  = _tsq_fdelta(dz, z, dw, w, sigma)
        if (min((dp, dd)) < 1) {
            mu = x'*z + s'*w
            g  = (x + dp*dx)'*(z + dd*dz) + (s + dp*ds)'*(w + dd*dw)
            mu = (g^3)*(mu^(-2))/2/N
            dxdz = dx:*dz
            dsdw = ds:*dw
            xinv = 1:/x
            sinv = 1:/s
            xi   = mu*(xinv - sinv)
            dy = lusolve(AqA, Aqr + (A:*q')*(dxdz - dsdw - xi))
            dx = q:*(A'*dy + xi - r - (dxdz - dsdw))
            ds = -dx
            dz = mu*xinv - z - xinv:*z:*dx - dxdz
            dw = mu*sinv - w - sinv:*w:*ds - dsdw
            dp = _tsq_fdelta(dx, x, ds, s, sigma)
            dd = _tsq_fdelta(dz, z, dw, w, sigma)
        }
        x  = x + dp*dx
        s  = s + dp*ds
        yd = yd + dd*dy
        z  = z + dd*dz
        w  = w + dd*dw
        gap = c'*x - b'*yd + u'*w
        it = it + 1
    }
    return(-yd)
}


// GAUSS QR_Fourier_KSS_bootstrap / QKS_bootstrap: centred AR(1) residuals
void _tsq_bootprep(real scalar tt, real scalar model, real scalar p, real scalar k, string scalar test)
{
    external real colvector _TSQ_y0, _TSQ_mu
    real colvector y, dy, dep, yd, yd1, tr, s, c
    real matrix x, L
    real scalar T, j
    y  = _TSQ_y0
    T  = rows(y)
    tr = (1::T)
    s  = sin(2*pi()*k*tr/T)
    c  = cos(2*pi()*k*tr/T)
    dy = _tsq_diff(y)
    L  = J(T, max((p,1)), .)
    for (j=1; j<=p; j=j+1) {
        L[., j] = _tsq_lag(dy, j)
    }
    x = J(T,1,1)
    if (test == "qfkss") {
        if (model == 2) x = x, tr
        x = x, s, c
        if (p > 0) x = x, L[|1,1 \ T,p|]
        dep = dy[|p+2 \ T|]
    }
    if (test == "qks") {
        if (model == 2) x = x, tr
        if (tt == 2 | tt == 4) x = x, s, c
        if (p > 0) x = x, L[|1,1 \ T,p|]
        dep = y[|p+2 \ T|]
    }
    x  = x[|p+2,1 \ T,cols(x)|]
    if (test == "qks") {
        // GAUSS QKS_bootstrap rebuilds the constant and trend on the trimmed sample
        x[.,1] = J(rows(x),1,1)
        if (model == 2) x[.,2] = (1::rows(x))
    }
    yd = dep - x*(luinv(x'*x)*(x'*dep))
    yd1 = yd[|1 \ rows(yd)-1|]
    yd  = yd[|2 \ rows(yd)|]
    _TSQ_mu = yd - yd1*((yd1'*yd)/(yd1'*yd1))
    _TSQ_mu = _TSQ_mu :- mean(_TSQ_mu)
}

void _tsq_bootdraw()
{
    external real colvector _TSQ_mu, _TSQ_ys
    real scalar n
    n = rows(_TSQ_mu)
    _TSQ_ys = runningsum(_TSQ_mu[ceil(n*runiform(n,1))])
}
end
