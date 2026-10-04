*! _mvardlurt_multivariate_mata  version 1.1.2  03oct2026
*! Mata engine for mvardlurt_multivariate (regression, lag search, diagnostics,
*! CUSUM, predict support). This file is loaded on demand with -do- by
*! _mvardlurt_multivariate_load; it is not a Stata command.
*! Reason: Mata functions defined inside an autoloaded ado-file are not kept in
*! memory after the ado program returns, so they are kept in their own file.

mata:
mata set matastrict off

real scalar mvu_loaded()
{
    return(1)
}

real colvector mvu_lag(real colvector v, real scalar j)
{
    real scalar T
    T = rows(v)
    if (j == 0) return(v)
    if (j >= T) return(J(T, 1, .))
    return(J(j, 1, .) \ v[|1 \ T-j|])
}

real rowvector mvu_seq(real scalar a, real scalar b)
{
    if (a > b) return(J(1, 0, .))
    return(a..b)
}

// regressors, rows s..T:
// L.y | L.x1..L.xk | L1..Lp D.y | L1..Lq_i D.x_i | [D.x] | const | trend
real matrix mvu_design(real colvector y, real matrix X, real scalar p,
                       real rowvector q, real scalar contemp, real scalar cs,
                       real scalar s)
{
    real scalar T, k, i, j
    real colvector dy
    real matrix Z, dX
    T  = rows(y)
    k  = cols(X)
    dy = y - mvu_lag(y, 1)
    dX = J(T, k, .)
    for (i = 1; i <= k; i++) dX[., i] = X[., i] - mvu_lag(X[., i], 1)
    Z = mvu_lag(y, 1)
    for (i = 1; i <= k; i++) Z = Z, mvu_lag(X[., i], 1)
    for (j = 1; j <= p; j++) Z = Z, mvu_lag(dy, j)
    for (i = 1; i <= k; i++) {
        for (j = 1; j <= q[i]; j++) Z = Z, mvu_lag(dX[., i], j)
    }
    if (contemp) Z = Z, dX
    if (cs >= 3) Z = Z, J(T, 1, 1)
    if (cs == 5) Z = Z, (1::T)
    return(Z[|s, 1 \ T, cols(Z)|])
}

string rowvector mvu_names(string scalar dv, string rowvector xv, real scalar p,
                           real rowvector q, real scalar contemp, real scalar cs)
{
    real scalar k, i, j
    string rowvector nm
    string scalar pre
    k  = cols(xv)
    nm = ("L." + dv)
    for (i = 1; i <= k; i++) nm = nm, ("L." + xv[i])
    for (j = 1; j <= p; j++) {
        if (j == 1) pre = "LD."
        else        pre = "L" + strofreal(j) + "D."
        nm = nm, (pre + dv)
    }
    for (i = 1; i <= k; i++) {
        for (j = 1; j <= q[i]; j++) {
            if (j == 1) pre = "LD."
            else        pre = "L" + strofreal(j) + "D."
            nm = nm, (pre + xv[i])
        }
    }
    if (contemp) {
        for (i = 1; i <= k; i++) nm = nm, ("D." + xv[i])
    }
    if (cs >= 3) nm = nm, "_cons"
    if (cs == 5) nm = nm, "_trend"
    return(nm)
}

// t on column 1 and Wald/k F on columns 2..k+1
void mvu_stats(real colvector y, real matrix Z, real scalar k,
               real scalar tst, real scalar fst)
{
    real scalar n, m, rss, s2
    real colvector b, b2, r
    real matrix XXi, V22
    n   = rows(Z)
    m   = cols(Z)
    XXi = invsym(cross(Z, Z))
    b   = XXi * cross(Z, y)
    r   = y - Z * b
    rss = cross(r, r)
    s2  = rss / (n - m)
    tst = b[1] / sqrt(s2 * XXi[1, 1])
    b2  = b[|2 \ k+1|]
    V22 = s2 * XXi[|2, 2 \ k+1, k+1|]
    fst = (b2' * invsym(V22) * b2) / k
}

// ARDL(p,q) search on a common sample, common q for all covariates
void mvu_search(real colvector y, real matrix X, real scalar maxlag,
                real scalar icsel, real scalar contemp, real scalar cs,
                real scalar bp, real scalar bq, real matrix tab)
{
    real scalar T, k, p, q, s, n, m, rss, ll, ic, best
    real matrix Z
    real colvector dy, dep, b, r
    T   = rows(y)
    k   = cols(X)
    s   = maxlag + 2
    dy  = y - mvu_lag(y, 1)
    dep = dy[|s \ T|]
    tab = J(maxlag + 1, maxlag + 1, .)
    best = .
    bp = -1
    bq = -1
    for (p = 0; p <= maxlag; p++) {
        for (q = 0; q <= maxlag; q++) {
            Z = mvu_design(y, X, p, J(1, k, q), contemp, cs, s)
            n = rows(Z)
            m = cols(Z)
            if (n - m < 5) continue
            b   = invsym(cross(Z, Z)) * cross(Z, dep)
            r   = dep - Z * b
            rss = cross(r, r)
            if (rss <= 0) continue
            ll = -0.5 * n * (ln(2 * pi()) + 1 + ln(rss / n))
            if (icsel == 1) ic = -2 * ll + 2 * m
            else            ic = -2 * ll + m * ln(n)
            tab[p + 1, q + 1] = ic
            if (best >= . | ic < best) {
                best = ic
                bp   = p
                bq   = q
            }
        }
    }
}

// main routine: reads Stata locals, writes Stata matrices / locals
void mvu_run()
{
    external real matrix    mvu_Z
    external real colvector mvu_dep, mvu_b, mvu_bt, mvu_bf, mvu_y
    external real scalar    mvu_p, mvu_k, mvu_s
    string scalar dv, touse, esname
    string rowvector xv
    real scalar k, cs, contemp, maxlag, icsel, manual
    real scalar T, p, bq, s, n, m, rss, ll, tss, r2, r2a, df, s2, aic, bic, i
    real scalar tst, fst
    real colvector sel, fr, y, dy, dep, b, b2, res, tvv
    real matrix X, Z, XXi, V, V22, ict, cv
    real rowvector qv

    dv      = st_local("depvar")
    xv      = tokens(st_local("indepvars"))
    touse   = st_local("touse")
    esname  = st_local("esamp")
    k       = cols(xv)
    cs      = strtoreal(st_local("case"))
    contemp = (st_local("contemp") != "")
    maxlag  = strtoreal(st_local("maxlag"))
    icsel   = (st_local("ic") == "bic") + 1
    manual  = (st_local("manual") == "1")

    sel = select((1::st_nobs()), st_data(., touse))
    y   = st_data(sel, dv)
    X   = st_data(sel, xv)
    T   = rows(y)

    tvv = st_data(sel, st_local("timevar"))
    if (T > 1) {
        if (any((tvv[|2 \ T|] - tvv[|1 \ T-1|]) :!= strtoreal(st_local("tdelta")))) {
            st_local("mvu_err", "1")
            return
        }
    }

    p   = 0
    bq  = 0
    ict = .
    if (manual) {
        p  = strtoreal(st_local("fix_p"))
        qv = strtoreal(tokens(st_local("fix_q")))
    }
    else {
        mvu_search(y, X, maxlag, icsel, contemp, cs, p, bq, ict)
        if (p < 0) {
            st_local("mvu_err", "2")
            return
        }
        qv = J(1, k, bq)
    }

    s = max((2, p + 2, max(qv) + 2))
    if (s + 6 > T) {
        st_local("mvu_err", "3")
        return
    }
    Z   = mvu_design(y, X, p, qv, contemp, cs, s)
    dy  = y - mvu_lag(y, 1)
    dep = dy[|s \ T|]
    n   = rows(Z)
    m   = cols(Z)
    if (n - m < 5) {
        st_local("mvu_err", "3")
        return
    }

    XXi = invsym(cross(Z, Z))
    b   = XXi * cross(Z, dep)
    res = dep - Z * b
    rss = cross(res, res)
    df  = n - m
    s2  = rss / df
    V   = s2 * XXi
    tst = b[1] / sqrt(V[1, 1])
    b2  = b[|2 \ k+1|]
    V22 = V[|2, 2 \ k+1, k+1|]
    fst = (b2' * invsym(V22) * b2) / k

    if (cs == 1) tss = cross(dep, dep)
    else         tss = cross(dep :- mean(dep), dep :- mean(dep))
    r2  = 1 - rss / tss
    if (cs == 1) r2a = 1 - (1 - r2) * n / df
    else         r2a = 1 - (1 - r2) * (n - 1) / df
    ll  = -0.5 * n * (ln(2 * pi()) + 1 + ln(rss / n))
    aic = -2 * ll + 2 * m
    bic = -2 * ll + m * ln(n)

    fr = sel[|s \ T|]
    st_store(fr, esname, J(rows(fr), 1, 1))

    // kept for predict / diag / graph
    mvu_Z   = Z
    mvu_dep = dep
    mvu_b   = b

    // kept for the bootstrap (_mvardlurt_multivariate_boot.ado)
    mvu_y  = y
    mvu_p  = p
    mvu_k  = k
    mvu_s  = s
    mvu_bt = J(0, 1, .)
    mvu_bf = J(0, 1, .)
    cv = J(2, 5, .)

    st_matrix(st_local("BB"),  b')
    st_matrix(st_local("VV"),  V)
    st_matrix(st_local("CV"),  cv)
    st_matrix(st_local("ICT"), ict)
    st_matrix(st_local("RES"), (tst, fst, n, m, rss, ll, aic, bic, r2, r2a, df, s, ., ., ., .))
    st_local("opt_p", strofreal(p))
    st_local("opt_q", invtokens(strofreal(qv)))
    st_local("cnames", invtokens(mvu_names(dv, xv, p, qv, contemp, cs)))
}

// ---- diagnostics: BG(1), RESET, Breusch-Pagan (Koenker), ARCH(1), JB ------
real matrix mvu_diag(real matrix Z, real colvector y, real scalar cs)
{
    real scalar n, m, r2, lm, df2, F, rss0, rss1, tss, s2, sk, ku, jb
    real colvector b, e, e2, yh, a, ee, el, y2, x2
    real matrix out, W
    n   = rows(Z)
    m   = cols(Z)
    out = J(5, 3, .)
    b   = invsym(cross(Z, Z)) * cross(Z, y)
    yh  = Z * b
    e   = y - yh

    el  = 0 \ e[|1 \ n-1|]
    W   = Z, el
    a   = invsym(cross(W, W)) * cross(W, e)
    ee  = e - W * a
    r2  = 1 - cross(ee, ee) / cross(e, e)
    lm  = n * r2
    out[1, .] = (lm, 1, chi2tail(1, lm))

    rss0 = cross(e, e)
    W    = Z, yh :^ 2, yh :^ 3, yh :^ 4
    a    = invsym(cross(W, W)) * cross(W, y)
    ee   = y - W * a
    rss1 = cross(ee, ee)
    df2  = n - m - 3
    if (df2 > 0 & rss1 > 0) {
        F = ((rss0 - rss1) / 3) / (rss1 / df2)
        out[2, .] = (F, 3, Ftail(3, df2, F))
    }

    e2 = e :^ 2
    if (cs == 1) W = Z, J(n, 1, 1)
    else         W = Z
    a   = invsym(cross(W, W)) * cross(W, e2)
    ee  = e2 - W * a
    tss = cross(e2 :- mean(e2), e2 :- mean(e2))
    r2  = 1 - cross(ee, ee) / tss
    lm  = n * r2
    df2 = cols(W) - 1
    out[3, .] = (lm, df2, chi2tail(df2, lm))

    y2  = e2[|2 \ n|]
    x2  = e2[|1 \ n-1|]
    W   = J(n - 1, 1, 1), x2
    a   = invsym(cross(W, W)) * cross(W, y2)
    ee  = y2 - W * a
    tss = cross(y2 :- mean(y2), y2 :- mean(y2))
    r2  = 1 - cross(ee, ee) / tss
    lm  = (n - 1) * r2
    out[4, .] = (lm, 1, chi2tail(1, lm))

    s2 = cross(e :- mean(e), e :- mean(e)) / n
    sk = mean((e :- mean(e)) :^ 3) / s2 ^ 1.5
    ku = mean((e :- mean(e)) :^ 4) / s2 ^ 2
    jb = n / 6 * (sk ^ 2 + (ku - 3) ^ 2 / 4)
    out[5, .] = (jb, 2, chi2tail(2, jb))
    return(out)
}

// CUSUM of recursive residuals (Brown, Durbin and Evans 1975)
real colvector mvu_cusum(real matrix Z, real colvector y)
{
    real scalar n, m, t, nw, sig
    real colvector w, b
    real matrix Ai, Zp
    real rowvector zt
    n  = rows(Z)
    m  = cols(Z)
    nw = n - m
    w  = J(nw, 1, .)
    for (t = m + 1; t <= n; t++) {
        Zp = Z[|1, 1 \ t - 1, m|]
        Ai = invsym(cross(Zp, Zp))
        b  = Ai * cross(Zp, y[|1 \ t - 1|])
        zt = Z[t, .]
        w[t - m] = (y[t] - zt * b) / sqrt(1 + zt * Ai * zt')
    }
    sig = sqrt(cross(w :- mean(w), w :- mean(w)) / (nw - 1))
    return(runningsum(w) / sig)
}

real colvector mvu_pad(real colvector v, real scalar nobs)
{
    if (rows(v) >= nobs) return(v)
    return(v \ J(nobs - rows(v), 1, .))
}

// push residual / bootstrap / CUSUM series into the (empty) dataset
void mvu_to_data()
{
    external real matrix    mvu_Z
    external real colvector mvu_dep, mvu_b, mvu_bt, mvu_bf
    real scalar n, m, nw, nobs, a
    real colvector fit, res, cs, r, ub, lb, o, co
    real matrix idx
    n = rows(mvu_Z)
    if (n == 0) {
        st_local("mvu_err", "1")
        return
    }
    m   = cols(mvu_Z)
    fit = mvu_Z * mvu_b
    res = mvu_dep - fit
    nw  = n - m
    cs  = mvu_cusum(mvu_Z, mvu_dep)
    a   = 0.948
    r   = (1::nw)
    ub  =  a * sqrt(nw) * (1 :+ 2 * r / nw)
    lb  = -a * sqrt(nw) * (1 :+ 2 * r / nw)
    o   = (1::n)
    co  = r :+ m
    nobs = max((n, nw, rows(mvu_bt), rows(mvu_bf)))
    st_addobs(nobs)
    idx = st_addvar("double", ("obs", "fit", "res", "cobs", "cusum", "ub", "lb", "tboot", "fboot"))
    st_store(., idx[1], mvu_pad(o,  nobs))
    st_store(., idx[2], mvu_pad(fit, nobs))
    st_store(., idx[3], mvu_pad(res, nobs))
    st_store(., idx[4], mvu_pad(co,  nobs))
    st_store(., idx[5], mvu_pad(cs,  nobs))
    st_store(., idx[6], mvu_pad(ub,  nobs))
    st_store(., idx[7], mvu_pad(lb,  nobs))
    st_store(., idx[8], mvu_pad(mvu_bt, nobs))
    st_store(., idx[9], mvu_pad(mvu_bf, nobs))
}

void mvu_predict(string scalar esn, string scalar vn, real scalar mode)
{
    external real matrix    mvu_Z
    external real colvector mvu_dep, mvu_b
    real colvector sel, fit
    if (rows(mvu_Z) == 0) {
        st_local("mvu_err", "1")
        return
    }
    sel = select((1::st_nobs()), st_data(., esn))
    if (rows(sel) != rows(mvu_Z)) {
        st_local("mvu_err", "2")
        return
    }
    fit = mvu_Z * mvu_b
    if (mode == 1) st_store(sel, vn, fit)
    else           st_store(sel, vn, mvu_dep - fit)
}

void mvu_diag_run()
{
    external real matrix    mvu_Z
    external real colvector mvu_dep
    if (rows(mvu_Z) == 0) {
        st_local("mvu_err", "1")
        return
    }
    st_matrix(st_local("DG"), mvu_diag(mvu_Z, mvu_dep, strtoreal(st_local("case"))))
}

end
