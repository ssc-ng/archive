*! _xturcoint_adfmin 1.0.0  11nov2026   (engine of: xturcoint adfmin)
*! Westerlund (2006) panel cointegration tests allowing for a level break
*! Author : Dr Merwan Roudane  merwanroudane920@gmail.com
*!          https://github.com/merwanroudane
*! Part of the -xturcoint- library (ports of GAUSS panel tests).
*!
*! Faithful port of the GAUSS routine adfmin_west (westerlundlib, adfmin.src)
*!   by Joakim Westerlund.
*!
*! Reference:
*!   Westerlund, J. (2006). Testing for panel cointegration with a level break.
*!     Economics Letters 91(1): 27-33. <doi:10.1016/j.econlet.2005.10.007>
*!
*! Step -> code map (see -help xturcoint_adfmin-):
*!   residuals of y on (1, DU(Tb), [t], x) for every Tb   -> _xtadfm_resid
*!   semiparametric Z_t / Z_rho (Phillips)                -> _xtadfm_adfs
*!   parametric ADF_t / ADF_rho (p-1 augmentation lags)   -> _xtadfm_adfp
*!   unit-wise minimum over Tb in [tau T, (1-tau) T]      -> _xtadfm_run
*!   Z = sqrt(N)(mean min_i - mu)/sqrt(var)               -> moment table

program _xturcoint_adfmin, rclass
    version 14.0
    syntax varlist(min=2 numeric ts) [if] [in] [ , ///
        MODel(string)       ///
        Lags(integer 1)     ///
        TRIM(real 0.10)     ///
        GAUSSfirstx         ///
        noTABle ]

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
    local k : word count `xv'
    if `k' > 5 {
        di as err "at most 5 regressors are allowed (Westerlund 2006 moment table)"
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
    if `lags' < 1 {
        di as err "lags() must be >= 1 (GAUSS convention: p-1 augmentation lags, p = Bartlett bandwidth)"
        exit 198
    }
    if `trim' <= 0 | `trim' >= 0.5 {
        di as err "trim() must lie in (0, 0.5)"
        exit 198
    }

    tempvar cnt
    qui bysort `ivar' (`tvar'): gen long `cnt' = sum(`touse')
    qui bysort `ivar' (`tvar'): replace `cnt' = `cnt'[_N]
    qui summ `cnt' if `touse', meanonly
    if r(min) != r(max) {
        di as err "the panel must be balanced (same T for every unit) over the estimation sample"
        exit 459
    }
    local T = r(max)
    qui levelsof `ivar' if `touse', local(units)
    local N : word count `units'
    if `N' < 2 {
        di as err "at least two panel units are required"
        exit 2001
    }
    local useX "`xv'"
    if "`gaussfirstx'" != "" {
        gettoken useX : xv
    }

    sort `ivar' `tvar'
    tempname S P B tv
    mata: _xtadfm_run("`dv'", "`useX'", "`touse'", `N', `T', `k', `mod', `lags', `trim')
    matrix `S' = r(stat)
    matrix `B' = r(brk)
    // map break observation index -> time value
    qui levelsof `tvar' if `touse', local(tlev)
    matrix `P' = J(1,4,.)
    forvalues j = 1/4 {
        matrix `P'[1,`j'] = normal(`S'[1,`j'])
    }
    mata: st_matrix("`tv'", strtoreal(tokens(st_local("tlev")))')

    // ---- display ---------------------------------------------------
    local mlab = cond(`mod'==1, "level break in the constant", "level break, constant and trend")
    di
    di as txt "Westerlund (2006) panel cointegration tests with a level break"
    di as txt "{hline 70}"
    di as txt "H0: no cointegration in any panel" _col(44) "Number of panels" _col(62) "= " as res %5.0f `N'
    di as txt "H1: cointegration with a level break" _col(44) "Number of periods" _col(62) "= " as res %5.0f `T'
    di as txt "Model : " as res "`mlab'" _col(44) as txt "Regressors (k)" _col(62) "= " as res %5.0f `k'
    di as txt "Lags  : " as res "`lags'" as txt "   Trimming: " as res %4.2f `trim' _col(44) as txt "Break search" _col(62) "= " as res round(`trim'*`T') as txt "-" as res round((1-`trim')*`T')
    if "`gaussfirstx'"!="" di as txt "(GAUSS compatibility: only the first regressor enters the residual regression)"
    di as txt "{hline 70}"
    di as txt _col(3) "Statistic" _col(26) "Z-value" _col(42) "p-value" _col(54) "Type"
    di as txt "{hline 70}"
    local nm1 "Z_tau (semip.)"
    local nm2 "Z_rho (semip.)"
    local nm3 "ADF_tau (param.)"
    local nm4 "ADF_rho (param.)"
    forvalues j = 1/4 {
        local pv = `P'[1,`j']
        local st = cond(`pv'<.01,"***",cond(`pv'<.05,"**",cond(`pv'<.10,"*","")))
        di as txt _col(3) "`nm`j''" _col(20) as res %11.4f `S'[1,`j'] _col(38) %9.4f `pv' as txt " `st'" _col(54) cond(`j'<=2,"Phillips Z","ADF")
    }
    di as txt "{hline 70}"
    di as txt "Left-tailed N(0,1) tests; large negative values reject H0."
    di as txt "*** p<0.01, ** p<0.05, * p<0.10"

    // break dates in time units
    tempname BD
    matrix `BD' = `B'
    forvalues i = 1/`N' {
        forvalues j = 1/4 {
            local ix = `B'[`i',`j']
            matrix `BD'[`i',`j'] = `tv'[`ix',1]
        }
    }
    matrix colnames `BD' = Z_tau Z_rho ADF_tau ADF_rho
    matrix rownames `BD' = `units'
    matrix colnames `B'  = Z_tau Z_rho ADF_tau ADF_rho
    matrix rownames `B'  = `units'
    if "`table'"=="" {
        di
        di as txt "Estimated break dates (last period of the first regime, `tvar')"
        di as txt "{hline 58}"
        di as txt _col(3) "`ivar'" _col(16) "Z_tau" _col(27) "Z_rho" _col(37) "ADF_tau" _col(48) "ADF_rho"
        di as txt "{hline 58}"
        forvalues i = 1/`N' {
            local u : word `i' of `units'
            di as txt _col(3) "`u'" _col(12) as res %9.0g `BD'[`i',1] _col(23) %9.0g `BD'[`i',2] _col(35) %9.0g `BD'[`i',3] _col(46) %9.0g `BD'[`i',4]
        }
        di as txt "{hline 58}"
    }
    matrix colnames `S' = Z_tau Z_rho ADF_tau ADF_rho
    matrix colnames `P' = Z_tau Z_rho ADF_tau ADF_rho

    return scalar Z_tau     = `S'[1,1]
    return scalar Z_rho     = `S'[1,2]
    return scalar ADF_tau   = `S'[1,3]
    return scalar ADF_rho   = `S'[1,4]
    return scalar p_Z_tau   = `P'[1,1]
    return scalar p_Z_rho   = `P'[1,2]
    return scalar p_ADF_tau = `P'[1,3]
    return scalar p_ADF_rho = `P'[1,4]
    return scalar N    = `N'
    return scalar T    = `T'
    return scalar k    = `k'
    return scalar lags = `lags'
    return scalar trim = `trim'
    return local  model "`model'"
    return local  depvar "`dv'"
    return local  indepvars "`xv'"
    return matrix stat   = `S'
    return matrix pvalue = `P'
    return matrix breakobs  = `B'
    return matrix breakdate = `BD'
end

mata:

real matrix _xtadfm_fejer(real matrix uv, real scalar k)
{
    real scalar i, T
    real matrix a
    T = rows(uv)
    a = J(cols(uv), cols(uv), 0)
    if (k == 0) return(a)
    for (i=1; i<=k; i=i+1) {
        a = a + (1 - i/(k+1)) * (uv[|i+1,1 \ T,cols(uv)|]'*uv[|1,1 \ T-i,cols(uv)|])
    }
    return(a/T)
}

real colvector _xtadfm_resid(real colvector y, real matrix x, real scalar br, real scalar mod)
{
    real scalar t
    real matrix v
    t = rows(y)
    v = J(t,1,1)
    if (br > 0) v = v, (J(br,1,0) \ J(t-br,1,1))
    if (mod == 2) v = v, (1::t)
    v = v, x
    return(y - v*(invsym(v'*v)*(v'*y)))
}

// GAUSS adfs(): semiparametric (Phillips) Z_t and Z_alpha
real rowvector _xtadfm_adfs(real colvector w, real scalar p)
{
    real scalar t, b, s, io, zt, za
    real colvector wl, dw, e
    t  = rows(w)
    wl = w[|1 \ t-1|]
    dw = w[|2 \ t|] - wl
    b  = (wl'*dw)/(wl'*wl)
    e  = dw - wl*b
    s  = (e'*e)/rows(e)
    io = 0
    if (p > 0) io = _xtadfm_fejer(e, p)
    s  = s + 2*io
    zt = (wl'*dw - t*io)/sqrt((wl'*wl)*s)
    b  = (wl'*dw - t*io)/(wl'*wl)
    za = t*b
    return((zt, za))
}

// GAUSS lagp2(x, p): p lagged first differences
real matrix _xtadfm_lagp2(real colvector x, real scalar p)
{
    real scalar t, i
    real matrix xl, dx
    t  = rows(x)
    xl = J(t-p, p+1, 0)
    for (i=0; i<=p; i=i+1) {
        xl[., i+1] = x[|p+1-i \ t-i|]
    }
    dx = J(t-p, p, 0)
    for (i=1; i<=p; i=i+1) {
        dx[., i] = xl[., i] - xl[., i+1]
    }
    return(dx)
}

// GAUSS adfp(): parametric ADF t and rho with p-1 lagged differences
real rowvector _xtadfm_adfp(real colvector w, real scalar p)
{
    real scalar t, b, s, zt, za
    real colvector wl, dw, e
    real matrix m, v
    t  = rows(w)
    wl = w[|p \ t-1|]
    dw = w[|p+1 \ t|] - wl
    if (p == 1) {
        e  = dw - wl*((wl'*dw)/(wl'*wl))
        b  = (wl'*dw)/(wl'*wl)
        s  = (e'*e)/rows(e)
        zt = sqrt((wl'*wl)/s)*b
    }
    if (p > 1) {
        v  = _xtadfm_lagp2(w[|1 \ t-1|], p-1)
        m  = I(rows(v)) - v*invsym(v'*v)*v'
        b  = (wl'*m*dw)/(wl'*m*wl)
        e  = m*dw - m*wl*b
        s  = (e'*e)/rows(e)
        zt = sqrt((wl'*m*wl)/s)*b
    }
    za = t*b
    return((zt, za))
}

// first index of the minimum (GAUSS minpr)
real scalar _xtadfm_argmin(real colvector x)
{
    real scalar i, m, d
    m = 1
    d = x[1]
    for (i=2; i<=rows(x); i=i+1) {
        if (x[i] < d) {
            d = x[i]
            m = i
        }
    }
    return(m)
}

void _xtadfm_run(string scalar dv, string scalar xv, string scalar touse,
                 real scalar N, real scalar T, real scalar k, real scalar mod,
                 real scalar p, real scalar t0)
{
    real matrix Y, X, A1, A2, brk, mu1, mu2, var1, var2
    real colvector yi, w
    real matrix xi
    real rowvector acc, stat
    real scalar i, j, t1, t2, kx, nb, m1, m2, v1, v2
    Y  = st_data(., dv, touse)
    X  = st_data(., tokens(xv), touse)
    kx = cols(X)
    t1 = round(t0*T)
    t2 = round((1-t0)*T)
    nb = t2 - t1 + 1
    acc = J(1,4,0)
    brk = J(N,4,.)
    for (i=1; i<=N; i=i+1) {
        yi = Y[|(i-1)*T+1 \ i*T|]
        xi = X[|(i-1)*T+1,1 \ i*T,kx|]
        A1 = J(nb,2,.)
        A2 = J(nb,2,.)
        for (j=t1; j<=t2; j=j+1) {
            w = _xtadfm_resid(yi, xi, j, mod)
            A1[j-t1+1,.] = _xtadfm_adfs(w, p)
            A2[j-t1+1,.] = _xtadfm_adfp(w, p)
        }
        acc = acc + (colmin(A1), colmin(A2))
        brk[i,1] = _xtadfm_argmin(A1[.,1]) + t1 - 1
        brk[i,2] = _xtadfm_argmin(A1[.,2]) + t1 - 1
        brk[i,3] = _xtadfm_argmin(A2[.,1]) + t1 - 1
        brk[i,4] = _xtadfm_argmin(A2[.,2]) + t1 - 1
    }
    mu1  = (-3.49890, -3.85190, -4.18972, -4.51141, -4.76502 \
            -3.95088, -4.24887, -4.55330, -4.75105, -4.99327)
    mu2  = (-25.00168, -30.29004, -35.68431, -41.31450, -46.09029 \
            -31.54225, -36.59367, -41.98604, -46.05167, -50.97382)
    var1 = (0.39038, 0.36498, 0.36336, 0.35969, 0.32972 \
            0.33317, 0.34686, 0.32819, 0.34866, 0.33897)
    var2 = (72.38729, 83.39962, 99.14725, 115.23283, 117.25124 \
            78.17861, 96.40939, 104.02695, 125.02231, 132.19716)
    m1 = mu1[mod,k]
    m2 = mu2[mod,k]
    v1 = var1[mod,k]
    v2 = var2[mod,k]
    stat = J(1,4,.)
    stat[1] = sqrt(N)*(acc[1]/N - m1)/sqrt(v1)
    stat[2] = sqrt(N)*(acc[2]/N - m2)/sqrt(v2)
    stat[3] = sqrt(N)*(acc[3]/N - m1)/sqrt(v1)
    stat[4] = sqrt(N)*(acc[4]/N - m2)/sqrt(v2)
    st_rclear()
    st_matrix("r(stat)", stat)
    st_matrix("r(brk)", brk)
}
end
