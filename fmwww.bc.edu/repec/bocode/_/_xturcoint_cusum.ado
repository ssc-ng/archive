*! _xturcoint_cusum 1.0.0  11nov2026   (engine of: xturcoint cusum)
*! Westerlund (2005) panel CUSUM test of the null of cointegration
*! Author : Dr Merwan Roudane  merwanroudane920@gmail.com
*!          https://github.com/merwanroudane
*! Part of the -xturcoint- library (ports of GAUSS panel tests).
*!
*! Faithful port of the GAUSS routine cusum_panel (westerlundlib, cusum_west.src)
*!   by Joakim Westerlund.
*!
*! Reference:
*!   Westerlund, J. (2005). A panel CUSUM test of the null of cointegration.
*!     Oxford Bulletin of Economics and Statistics 67(2): 231-262.
*!     <doi:10.1111/j.1468-0084.2004.00118.x>
*!
*! Step -> code map (see -help xturcoint_cusum-):
*!   unit-by-unit DOLS / FMOLS residuals          -> _xtcus_dols / _xtcus_fmols
*!   Bartlett (Fejer) long-run variance           -> _xtcus_fejer
*!   CUSUM_i = max_t |S_it| / sqrt(T s2_i)        -> _xtcus_cusum
*!   Z = sqrt(N)(mean CUSUM_i - mu)/sqrt(var)     -> _xtcus_run (moments table)

program _xturcoint_cusum, rclass
    version 14.0
    syntax varlist(min=2 numeric ts) [if] [in] [ , ///
        MODel(string)        ///
        ESTimator(string)    ///
        Lags(integer 2)      ///
        BWidth(integer -1)   ///
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
        di as err "at most 5 regressors are allowed (Westerlund 2005 moment table)"
        exit 198
    }

    if ("`model'"=="") local model "constant"
    local model = strlower("`model'")
    if inlist("`model'","none","nothing","n")       local mod 0
    else if inlist("`model'","constant","c")        local mod 1
    else if inlist("`model'","trend","ct","t")      local mod 2
    else {
        di as err "model() must be none, constant or trend"
        exit 198
    }
    if ("`estimator'"=="") local estimator "dols"
    local estimator = strlower("`estimator'")
    if !inlist("`estimator'","dols","fmols") {
        di as err "estimator() must be dols or fmols"
        exit 198
    }
    local fm = ("`estimator'"=="fmols")
    if `lags' < 0 {
        di as err "lags() must be >= 0"
        exit 198
    }

    // ---- balanced panel check -------------------------------------
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
    if `bwidth' < 0 local bwidth = int(`T'^(1/3))
    if `fm'==0 & (`T' - 2*`lags' - 1) <= (`k'*(2*`lags'+1) + `mod' + `k') {
        di as err "too few time periods for DOLS with lags(`lags')"
        exit 2001
    }

    sort `ivar' `tvar'
    tempname stat pval ind
    mata: _xtcus_run("`dv'", "`xv'", "`touse'", `N', `T', `k', `mod', `fm', `lags', `bwidth')
    scalar `stat' = r(Z)
    scalar `pval' = 1 - normal(`stat')
    matrix `ind' = r(cusum)
    matrix colnames `ind' = CUSUM
    matrix rownames `ind' = `units'

    // ---- display ---------------------------------------------------
    local mlab "constant"
    if `mod'==0 local mlab "none"
    if `mod'==2 local mlab "constant and trend"
    local elab = cond(`fm', "FMOLS (bandwidth `bwidth')", "DOLS (`lags' leads)")
    di
    di as txt "Westerlund (2005) panel CUSUM test for cointegration"
    di as txt "{hline 66}"
    di as txt "H0: all panels are cointegrated" _col(42) "Number of panels" _col(60) "= " as res %5.0f `N'
    di as txt "H1: some panels are not cointegrated" _col(42) "Number of periods" _col(60) "= " as res %5.0f `T'
    di as txt "Deterministics : " as res "`mlab'" _col(42) as txt "Regressors (k)" _col(60) "= " as res %5.0f `k'
    di as txt "Estimator      : " as res "`elab'"
    di as txt "LRV bandwidth  : " as res "`bwidth'" as txt " (Bartlett)"
    di as txt "{hline 66}"
    di as txt _col(5) "Statistic" _col(26) "Value" _col(42) "p-value"
    di as txt "{hline 66}"
    local st = cond(`pval'<.01,"***",cond(`pval'<.05,"**",cond(`pval'<.10,"*","")))
    di as txt _col(5) "Z(CUSUM)" _col(20) as res %11.4f `stat' _col(38) %9.4f `pval' as txt " `st'"
    di as txt "{hline 66}"
    di as txt "Right-tailed N(0,1) test; large values reject cointegration."
    di as txt "*** p<0.01, ** p<0.05, * p<0.10"
    if "`table'"=="" {
        di
        di as txt "Unit-specific CUSUM statistics"
        di as txt "{hline 30}"
        di as txt _col(3) "`ivar'" _col(18) "CUSUM_i"
        di as txt "{hline 30}"
        forvalues i = 1/`N' {
            local u : word `i' of `units'
            di as txt _col(3) "`u'" _col(14) as res %11.4f `ind'[`i',1]
        }
        di as txt "{hline 30}"
    }

    return scalar Z      = `stat'
    return scalar p      = `pval'
    return scalar mu     = r(mu)
    return scalar var    = r(var)
    return scalar N      = `N'
    return scalar T      = `T'
    return scalar k      = `k'
    return scalar lags   = `lags'
    return scalar bwidth = `bwidth'
    return local  model     "`model'"
    return local  estimator "`estimator'"
    return local  depvar    "`dv'"
    return local  indepvars "`xv'"
    return matrix cusum  = `ind'
end

mata:

real matrix _xtcus_lagn(real matrix x, real scalar i)
{
    real matrix z
    z = J(i, cols(x), .) \ x[|1,1 \ rows(x)-i, cols(x)|]
    return(z)
}

// GAUSS fejer(uv,k): sum_{i=1..k} (1-i/(k+1)) * u(t)'u(t-i)  / rows(u)
real matrix _xtcus_fejer(real matrix uv, real scalar k)
{
    real scalar i, T
    real matrix a, t1, t2
    T = rows(uv)
    a = J(cols(uv), cols(uv), 0)
    if (k == 0) return(a)
    for (i=1; i<=k; i=i+1) {
        t1 = uv[|i+1,1 \ T,cols(uv)|]
        t2 = uv[|1,1 \ T-i,cols(uv)|]
        a = a + (1 - i/(k+1)) * (t1'*t2)
    }
    return(a/T)
}

real matrix _xtcus_detc(real scalar mod, real scalar t)
{
    real matrix z
    z = J(t,1,1)
    if (mod==2 | mod==4) z = J(t,1,1), (1::t)
    return(z)
}

// GAUSS dols(y,x,mod,p) (westerlundlib util_west.src)
real colvector _xtcus_dols(real colvector y, real matrix x, real scalar mod, real scalar p)
{
    real scalar t, k, j, nr
    real matrix dx, xi, z, b
    real colvector yi, u
    t = rows(y)
    k = cols(x)
    nr = t - 2*p - 1
    dx = J(nr, k*(2*p+1), 0)
    for (j=1; j<=2*p+1; j=j+1) {
        dx[|1,1+(j-1)*k \ nr,j*k|] = x[|2*p+3-j,1 \ t+1-j,k|] - x[|2*p+2-j,1 \ t-j,k|]
    }
    xi = x[|1,1 \ nr,k|]
    yi = y[|1 \ nr|]
    z  = I(nr) - dx*invsym(dx'*dx)*dx'
    if (mod != 0) xi = _xtcus_detc(mod, nr), xi
    xi = z*xi
    yi = z*yi
    b  = invsym(xi'*xi)*xi'*yi
    u  = yi - xi*b
    return(u)
}

// GAUSS fmols(y,x,mod,q) (westerlundlib util_west.src)
real colvector _xtcus_fmols(real colvector y, real matrix x, real scalar mod, real scalar q)
{
    real scalar t, k
    real matrix w, xd, d, b, dx, e, io, s, sig, del, s21, s12, del21, xk, ixx
    real colvector u, ys
    t = rows(y)
    k = cols(x)
    if (mod == 0) {
        w  = x
        xd = x
    } else {
        d  = _xtcus_detc(mod, t)
        w  = x, d
        xd = x - d*luinv(d'*d)*d'*x
    }
    b  = luinv(w'*w)*w'*y
    u  = y - w*b
    dx = xd[|2,1 \ t,k|] - xd[|1,1 \ t-1,k|]
    e  = u[|2 \ t|], dx
    io = _xtcus_fejer(e, q)
    s  = (e'*e)/rows(e)
    sig = s + io + io'
    del = s + io'
    s21 = luinv(sig[|2,2 \ 1+k,1+k|])*sig[|2,1 \ 1+k,1|]
    s12 = sig[1,1] - sig[|1,2 \ 1,1+k|]*s21
    del21 = t*(del[|2,1 \ 1+k,1|] - del[|2,2 \ 1+k,1+k|]*s21)
    if (mod != 0) del21 = del21 \ J(cols(d),1,0)
    ys  = y[|2 \ t|] - dx*s21
    xk  = w[|2,1 \ t,cols(w)|]
    ixx = luinv(xk'*xk)
    b   = ixx*((xk'*ys) - del21)
    u   = ys - xk*b
    return(u)
}

real scalar _xtcus_cusum(real colvector u, real scalar q)
{
    real scalar t, s
    real matrix io
    t  = rows(u)
    io = _xtcus_fejer(u, q)
    s  = (u'*u)/t
    s  = s + io + io'
    return(max(abs(runningsum(u)) :/ sqrt(t*s)))
}

void _xtcus_run(string scalar dv, string scalar xv, string scalar touse,
                real scalar N, real scalar T, real scalar k, real scalar mod,
                real scalar fm, real scalar p, real scalar q)
{
    real matrix Y, X, mu, var, xi
    real colvector cus, yi, u
    real scalar i, Z, m, v
    Y = st_data(., dv, touse)
    X = st_data(., tokens(xv), touse)
    cus = J(N,1,.)
    for (i=1; i<=N; i=i+1) {
        yi = Y[|(i-1)*T+1 \ i*T|]
        xi = X[|(i-1)*T+1,1 \ i*T,k|]
        if (fm == 0) u = _xtcus_dols(yi, xi, mod, p)
        if (fm != 0) u = _xtcus_fmols(yi, xi, mod, q)
        cus[i] = _xtcus_cusum(u, q)
    }
    mu = (1.063552, 0.930258, 0.843500, 0.771490, 0.727086 \
          0.751281, 0.676628, 0.619667, 0.573433, 0.539597 \
          0.584626, 0.553611, 0.521820, 0.499409, 0.477681)
    var = (0.183683, 0.126593, 0.093796, 0.070758, 0.059383 \
           0.050239, 0.037289, 0.028520, 0.021072, 0.017286 \
           0.018457, 0.015716, 0.013679, 0.012123, 0.010621)
    m = mu[mod+1, k]
    v = var[mod+1, k]
    Z = sqrt(N)*(sum(cus)/N - m)/sqrt(v)
    st_rclear()
    st_numscalar("r(Z)", Z)
    st_numscalar("r(mu)", m)
    st_numscalar("r(var)", v)
    st_matrix("r(cusum)", cus)
}
end
