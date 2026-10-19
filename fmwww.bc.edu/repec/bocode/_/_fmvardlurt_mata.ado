*! _fmvardlurt_mata  version 1.0.0  13oct2026
*! Mata engine for fmvardlurt: design, joint (p, q, frequency) search, statistics,
*! joint-null bootstrap, diagnostics, CUSUM, predict support.
*! Loaded on demand with -do- by _fmvardlurt_load; it is not a Stata command.
*! (Mata functions defined inside an autoloaded ado-file are not kept in memory
*!  after the program returns, so they live in this separate file.)

mata:
mata set matastrict off

real scalar fmv_loaded()
{
    return(100)
}

real colvector fmv_lag(real colvector v, real scalar j)
{
    real scalar T
    T = rows(v)
    if (j == 0) return(v)
    if (j >= T) return(J(T, 1, .))
    return(J(j, 1, .) \ v[|1 \ T-j|])
}

real rowvector fmv_seq(real scalar a, real scalar b)
{
    if (a > b) return(J(1, 0, .))
    return(a..b)
}

// number of deterministic columns at the end of the design
real scalar fmv_ndet(real scalar cs, real scalar fk)
{
    return((cs >= 3) + (cs == 5) + 2 * (fk > 0))
}

// regressors, rows s..T:
// L.y | L.x1..L.xk | L1..Lp D.y | L1..Lq_i D.x_i | [D.x] | const | [trend] | [sin | cos]
real matrix fmv_design(real colvector y, real matrix X, real scalar p,
                       real rowvector q, real scalar contemp, real scalar cs,
                       real scalar fk, real scalar s)
{
    real scalar T, k, i, j
    real colvector dy, tt
    real matrix Z, dX
    T  = rows(y)
    k  = cols(X)
    tt = (1::T)
    dy = y - fmv_lag(y, 1)
    dX = J(T, k, .)
    for (i = 1; i <= k; i++) dX[., i] = X[., i] - fmv_lag(X[., i], 1)
    Z = fmv_lag(y, 1)
    for (i = 1; i <= k; i++) Z = Z, fmv_lag(X[., i], 1)
    for (j = 1; j <= p; j++) Z = Z, fmv_lag(dy, j)
    for (i = 1; i <= k; i++) {
        for (j = 1; j <= q[i]; j++) Z = Z, fmv_lag(dX[., i], j)
    }
    if (contemp) Z = Z, dX
    if (cs >= 3) Z = Z, J(T, 1, 1)
    if (cs == 5) Z = Z, tt
    if (fk > 0)  Z = Z, sin(2 * pi() * fk * tt / T), cos(2 * pi() * fk * tt / T)
    return(Z[|s, 1 \ T, cols(Z)|])
}

string rowvector fmv_names(string scalar dv, string rowvector xv, real scalar p,
                           real rowvector q, real scalar contemp, real scalar cs,
                           real scalar fk)
{
    real scalar k, i, j
    string rowvector nm
    string scalar pre
    k  = cols(xv)
    nm = ("L." + dv)
    for (i = 1; i <= k; i++) nm = nm, ("L." + xv[i])
    for (j = 1; j <= p; j++) {
        pre = (j == 1 ? "LD." : "L" + strofreal(j) + "D.")
        nm = nm, (pre + dv)
    }
    for (i = 1; i <= k; i++) {
        for (j = 1; j <= q[i]; j++) {
            pre = (j == 1 ? "LD." : "L" + strofreal(j) + "D.")
            nm = nm, (pre + xv[i])
        }
    }
    if (contemp) {
        for (i = 1; i <= k; i++) nm = nm, ("D." + xv[i])
    }
    if (cs >= 3) nm = nm, "_cons"
    if (cs == 5) nm = nm, "_trend"
    if (fk > 0)  nm = nm, "_sin", "_cos"
    return(nm)
}

// t on column 1, Wald/k on columns 2..k+1, Wald/2 on the last two columns (if fk > 0)
void fmv_stats(real colvector y, real matrix Z, real scalar k, real scalar fk,
               real scalar tst, real scalar fst, real scalar ffs)
{
    real scalar n, m, s2
    real colvector b, b2, r
    real matrix XXi
    n   = rows(Z)
    m   = cols(Z)
    XXi = invsym(cross(Z, Z))
    b   = XXi * cross(Z, y)
    r   = y - Z * b
    s2  = cross(r, r) / (n - m)
    tst = b[1] / sqrt(s2 * XXi[1, 1])
    b2  = b[|2 \ k+1|]
    fst = (b2' * invsym(s2 * XXi[|2, 2 \ k+1, k+1|]) * b2) / k
    ffs = .
    if (fk > 0) {
        b2  = b[|m-1 \ m|]
        ffs = (b2' * invsym(s2 * XXi[|m-1, m-1 \ m, m|]) * b2) / 2
    }
}

// Joint search over (p, q, frequency).
// manual = 0: p, q = 0..maxlag (common q) on the common sample s = maxlag + 2, by AIC/BIC.
// manual = 1: lags fixed at (fp, fq); only the frequency is searched (= minimum SSR).
// kset: frequencies to try (a single 0 = no Fourier terms).
// tab: information criteria, rows (p, q) in the order searched, columns = frequencies.
void fmv_search(real colvector y, real matrix X, real scalar manual,
                real scalar fp, real rowvector fq, real scalar maxlag,
                real scalar icsel, real scalar contemp, real scalar cs,
                real rowvector kset, real scalar bp, real rowvector bq,
                real scalar bk, real matrix tab)
{
    real scalar T, k, p, q, s, n, m, rss, ll, ic, best, ik, row, np
    real matrix Z
    real colvector dy, dep, b, r
    real rowvector qv
    T  = rows(y)
    k  = cols(X)
    dy = y - fmv_lag(y, 1)
    if (manual) {
        s  = max((2, fp + 2, max(fq) + 2))
        np = 1
    }
    else {
        s  = maxlag + 2
        np = (maxlag + 1)^2
    }
    dep  = dy[|s \ T|]
    tab  = J(np, cols(kset), .)
    best = .
    bp   = -1
    bq   = J(1, k, -1)
    bk   = -1
    row  = 0
    for (p = 0; p <= (manual ? 0 : maxlag); p++) {
        for (q = 0; q <= (manual ? 0 : maxlag); q++) {
            row++
            if (manual) qv = fq
            else        qv = J(1, k, q)
            for (ik = 1; ik <= cols(kset); ik++) {
                Z = fmv_design(y, X, (manual ? fp : p), qv, contemp, cs, kset[ik], s)
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
                tab[row, ik] = ic
                if (best >= . | ic < best - 1e-12) {
                    best = ic
                    bp   = (manual ? fp : p)
                    bq   = qv
                    bk   = kset[ik]
                }
            }
        }
    }
}

// main routine: reads Stata locals, writes Stata matrices and locals
void fmv_run()
{
    external real matrix    fmv_Z, fmv_X
    external real colvector fmv_dep, fmv_b, fmv_y, fmv_bt, fmv_bf, fmv_bff
    external real scalar    fmv_p, fmv_k, fmv_s, fmv_fk, fmv_cs, fmv_contemp
    external real scalar    fmv_maxlag, fmv_icsel, fmv_manual
    external real rowvector fmv_qv, fmv_kset
    string scalar dv, touse, esname
    string rowvector xv
    real scalar k, cs, contemp, maxlag, icsel, manual, fp, kmax, freq
    real scalar T, p, fk, s, n, m, rss, ll, tss, r2, r2a, df, s2, aic, bic
    real scalar tst, fst, ffs
    real colvector sel, fr, y, dy, dep, b, res, tvv
    real matrix X, Z, XXi, V, ict
    real rowvector qv, fq, kset

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
    kmax    = strtoreal(st_local("kmax"))
    freq    = strtoreal(st_local("freq"))
    if (freq < .) kset = freq
    else          kset = (1..kmax)

    sel = select((1::st_nobs()), st_data(., touse))
    y   = st_data(sel, dv)
    X   = st_data(sel, xv)
    T   = rows(y)

    tvv = st_data(sel, st_local("timevar"))
    if (T > 1) {
        if (any((tvv[|2 \ T|] - tvv[|1 \ T-1|]) :!= strtoreal(st_local("tdelta")))) {
            st_local("fmv_err", "1")
            return
        }
    }

    fp = 0
    fq = J(1, k, 0)
    if (manual) {
        fp = strtoreal(st_local("fix_p"))
        fq = strtoreal(tokens(st_local("fix_q")))
    }
    fmv_search(y, X, manual, fp, fq, maxlag, icsel, contemp, cs, kset, p, qv, fk, ict)
    if (p < 0) {
        st_local("fmv_err", "2")
        return
    }

    s = max((2, p + 2, max(qv) + 2))
    Z   = fmv_design(y, X, p, qv, contemp, cs, fk, s)
    dy  = y - fmv_lag(y, 1)
    dep = dy[|s \ T|]
    n   = rows(Z)
    m   = cols(Z)
    if (n - m < 5) {
        st_local("fmv_err", "3")
        return
    }

    XXi = invsym(cross(Z, Z))
    b   = XXi * cross(Z, dep)
    res = dep - Z * b
    rss = cross(res, res)
    df  = n - m
    s2  = rss / df
    V   = s2 * XXi
    fmv_stats(dep, Z, k, fk, tst, fst, ffs)

    if (cs == 1 & fk == 0) tss = cross(dep, dep)
    else                   tss = cross(dep :- mean(dep), dep :- mean(dep))
    r2  = 1 - rss / tss
    r2a = 1 - (1 - r2) * (n - (cs >= 3)) / df
    ll  = -0.5 * n * (ln(2 * pi()) + 1 + ln(rss / n))
    aic = -2 * ll + 2 * m
    bic = -2 * ll + m * ln(n)

    fr = sel[|s \ T|]
    st_store(fr, esname, J(rows(fr), 1, 1))

    fmv_Z   = Z
    fmv_dep = dep
    fmv_b   = b
    fmv_y   = y
    fmv_X   = X
    fmv_p   = p
    fmv_qv  = qv
    fmv_k   = k
    fmv_s   = s
    fmv_fk  = fk
    fmv_cs  = cs
    fmv_contemp = contemp
    fmv_maxlag  = maxlag
    fmv_icsel   = icsel
    fmv_manual  = manual
    fmv_kset    = kset
    fmv_bt  = J(0, 1, .)
    fmv_bf  = J(0, 1, .)
    fmv_bff = J(0, 1, .)

    st_matrix(st_local("BB"),  b')
    st_matrix(st_local("VV"),  V)
    st_matrix(st_local("ICT"), ict)
    st_matrix(st_local("RES"), (tst, fst, ffs, n, m, rss, ll, aic, bic, r2, r2a, df, s))
    st_local("opt_p", strofreal(p))
    st_local("opt_q", invtokens(strofreal(qv)))
    st_local("opt_k", strofreal(fk))
    st_local("cnames", invtokens(fmv_names(dv, xv, p, qv, contemp, cs, fk)))
}

// ---- bootstrap -------------------------------------------------------------
// Joint null pi = 0 and delta = 0 in one restricted model; the intercept, trend and
// Fourier terms are left out of the generating process (no drift, no Fourier component);
// residuals centred and rescaled by sqrt(n/(n-mr)); covariates held at their observed
// values; with resel = 1 the (p, q, frequency) search is repeated on every bootstrap sample.
void fmv_boot(real colvector bt, real colvector bf, real colvector bff, real scalar resel)
{
    external real matrix    fmv_Z, fmv_X
    external real colvector fmv_dep, fmv_y
    external real scalar    fmv_p, fmv_k, fmv_s, fmv_fk, fmv_cs, fmv_contemp
    external real scalar    fmv_maxlag, fmv_icsel, fmv_manual
    external real rowvector fmv_qv, fmv_kset
    real scalar T, n, m, mr, nd, r, t, j, row, v, tt, ff, fs, bp, bk, s2, k, p, s
    real rowvector stoch, bq
    real colvector y, dy, er, br, fp, phi, idx, e, ys, dys, dyb
    real matrix Z, Zr, Zs, tab

    y  = fmv_y
    Z  = fmv_Z
    k  = fmv_k
    p  = fmv_p
    s  = fmv_s
    T  = rows(y)
    n  = rows(Z)
    m  = cols(Z)
    dy = y - fmv_lag(y, 1)

    Zr = Z[|1, k + 2 \ n, m|]
    mr = cols(Zr)
    br = invsym(cross(Zr, Zr)) * cross(Zr, fmv_dep)
    er = fmv_dep - Zr * br
    er = (er :- mean(er)) * sqrt(n / (n - mr))
    phi = J(p, 1, 0)
    for (j = 1; j <= p; j++) phi[j] = br[j]
    nd    = fmv_ndet(fmv_cs, fmv_fk)
    stoch = fmv_seq(p + 1, mr - nd)
    if (cols(stoch) > 0) fp = Zr[., stoch] * br[stoch']
    else                 fp = J(n, 1, 0)

    for (r = 1; r <= rows(bt); r++) {
        idx = floor(n * runiform(n, 1)) :+ 1
        idx = idx - (idx :> n)
        e   = er[idx]
        ys  = y
        dys = dy
        for (t = s; t <= T; t++) {
            row = t - s + 1
            v = fp[row] + e[row]
            for (j = 1; j <= p; j++) v = v + phi[j] * dys[t - j]
            dys[t] = v
            ys[t]  = ys[t - 1] + v
        }
        if (resel) {
            fmv_search(ys, fmv_X, fmv_manual, fmv_p, fmv_qv, fmv_maxlag, fmv_icsel,
                       fmv_contemp, fmv_cs, fmv_kset, bp, bq, bk, tab)
            if (bp < 0) {
                bt[r]  = .
                bf[r]  = .
                bff[r] = .
                continue
            }
            s2  = max((2, bp + 2, max(bq) + 2))
            Zs  = fmv_design(ys, fmv_X, bp, bq, fmv_contemp, fmv_cs, bk, s2)
            dyb = dys[|s2 \ T|]
            fmv_stats(dyb, Zs, k, bk, tt, ff, fs)
        }
        else {
            Zs = Z
            Zs[., 1] = ys[|s - 1 \ T - 1|]
            for (j = 1; j <= p; j++) Zs[., k + 1 + j] = dys[|s - j \ T - j|]
            dyb = dys[|s \ T|]
            fmv_stats(dyb, Zs, k, fmv_fk, tt, ff, fs)
        }
        bt[r]  = tt
        bf[r]  = ff
        bff[r] = fs
    }
}

real scalar fmv_q(real colvector sorted, real scalar prob)
{
    real scalar B, i
    B = rows(sorted)
    i = ceil(prob * B)
    if (i < 1) i = 1
    if (i > B) i = B
    return(sorted[i])
}

void fmv_boot_run()
{
    external real matrix    fmv_Z
    external real colvector fmv_bt, fmv_bf, fmv_bff
    external real scalar    fmv_fk
    real scalar reps, alpha, tst, fst, ffs, B, pt, pf, pff, i, resel
    real colvector tb, fb, ffb, ok
    real rowvector pr
    real matrix cv

    if (rows(fmv_Z) == 0) {
        st_local("fmv_err", "1")
        return
    }
    reps  = strtoreal(st_local("reps"))
    alpha = strtoreal(st_local("alpha"))
    tst   = strtoreal(st_local("tstat"))
    fst   = strtoreal(st_local("fstat"))
    ffs   = strtoreal(st_local("ffstat"))
    resel = strtoreal(st_local("reselect"))

    tb  = J(reps, 1, .)
    fb  = J(reps, 1, .)
    ffb = J(reps, 1, .)
    fmv_boot(tb, fb, ffb, resel)
    ok  = (tb :< .) :& (fb :< .)
    tb  = select(tb, ok)
    fb  = select(fb, ok)
    ffb = select(ffb, ok)
    if (rows(tb) < 50) {
        st_local("fmv_err", "4")
        return
    }
    fmv_bt  = tb
    fmv_bf  = fb
    fmv_bff = ffb
    B   = rows(tb)
    pt  = (1 + sum(tb :<= tst)) / (B + 1)
    pf  = (1 + sum(fb :>= fst)) / (B + 1)
    pff = .
    if (fmv_fk > 0) pff = (1 + sum((ffb :< .) :& (ffb :>= ffs))) / (B + 1)
    tb  = sort(tb, 1)
    fb  = sort(fb, 1)
    ffb = sort(editmissing(ffb, 0), 1)

    cv = J(3, 5, .)
    pr = (.10, .05, .025, .01, alpha)
    for (i = 1; i <= 5; i++) {
        cv[1, i] = fmv_q(tb, pr[i])
        cv[2, i] = fmv_q(fb, 1 - pr[i])
        if (fmv_fk > 0) cv[3, i] = fmv_q(ffb, 1 - pr[i])
    }
    st_matrix(st_local("CVB"),  cv)
    st_matrix(st_local("INFO"), (B, pt, pf, pff))
}

// ---- diagnostics: BG(1), RESET, Breusch-Pagan (Koenker), ARCH(1), JB ------
real matrix fmv_diag(real matrix Z, real colvector y)
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
    if (fmv_hascons(Z)) W = Z
    else                W = Z, J(n, 1, 1)
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

// 1 if Z contains a constant column
real scalar fmv_hascons(real matrix Z)
{
    real scalar j
    for (j = 1; j <= cols(Z); j++) {
        if (min(Z[., j]) == 1 & max(Z[., j]) == 1) return(1)
    }
    return(0)
}

// CUSUM of recursive residuals (Brown, Durbin and Evans 1975)
real colvector fmv_cusum(real matrix Z, real colvector y)
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

real colvector fmv_pad(real colvector v, real scalar nobs)
{
    if (rows(v) >= nobs) return(v)
    return(v \ J(nobs - rows(v), 1, .))
}

// Fourier component of the fitted D.y equation, rows s..T
real colvector fmv_fourfit()
{
    external real matrix    fmv_Z
    external real colvector fmv_b
    external real scalar    fmv_fk
    real scalar m
    m = cols(fmv_Z)
    if (fmv_fk == 0) return(J(rows(fmv_Z), 1, 0))
    return(fmv_Z[|1, m-1 \ rows(fmv_Z), m|] * fmv_b[|m-1 \ m|])
}

// push residual, bootstrap, CUSUM and Fourier series into the (empty) dataset
void fmv_to_data()
{
    external real matrix    fmv_Z
    external real colvector fmv_dep, fmv_b, fmv_bt, fmv_bf, fmv_bff
    real scalar n, m, nw, nobs, a
    real colvector fit, res, cs, r, ub, lb, o, co
    real matrix idx
    n = rows(fmv_Z)
    if (n == 0) {
        st_local("fmv_err", "1")
        return
    }
    m   = cols(fmv_Z)
    fit = fmv_Z * fmv_b
    res = fmv_dep - fit
    nw  = n - m
    cs  = fmv_cusum(fmv_Z, fmv_dep)
    a   = 0.948
    r   = (1::nw)
    ub  =  a * sqrt(nw) * (1 :+ 2 * r / nw)
    lb  = -a * sqrt(nw) * (1 :+ 2 * r / nw)
    o   = (1::n)
    co  = r :+ m
    nobs = max((n, nw, rows(fmv_bt)))
    st_addobs(nobs)
    idx = st_addvar("double", ("obs", "dy", "fit", "res", "four", "cobs", "cusum", "ub", "lb", "tboot", "fboot", "ffboot"))
    st_store(., idx[1],  fmv_pad(o, nobs))
    st_store(., idx[2],  fmv_pad(fmv_dep, nobs))
    st_store(., idx[3],  fmv_pad(fit, nobs))
    st_store(., idx[4],  fmv_pad(res, nobs))
    st_store(., idx[5],  fmv_pad(fmv_fourfit(), nobs))
    st_store(., idx[6],  fmv_pad(co, nobs))
    st_store(., idx[7],  fmv_pad(cs, nobs))
    st_store(., idx[8],  fmv_pad(ub, nobs))
    st_store(., idx[9],  fmv_pad(lb, nobs))
    st_store(., idx[10], fmv_pad(fmv_bt, nobs))
    st_store(., idx[11], fmv_pad(fmv_bf, nobs))
    st_store(., idx[12], fmv_pad(fmv_bff, nobs))
}

void fmv_predict(string scalar esn, string scalar vn, real scalar mode)
{
    external real matrix    fmv_Z
    external real colvector fmv_dep, fmv_b
    real colvector sel, fit
    if (rows(fmv_Z) == 0) {
        st_local("fmv_err", "1")
        return
    }
    sel = select((1::st_nobs()), st_data(., esn))
    if (rows(sel) != rows(fmv_Z)) {
        st_local("fmv_err", "2")
        return
    }
    fit = fmv_Z * fmv_b
    if (mode == 1)      st_store(sel, vn, fit)
    else if (mode == 2) st_store(sel, vn, fmv_dep - fit)
    else                st_store(sel, vn, fmv_fourfit())
}

void fmv_diag_run()
{
    external real matrix    fmv_Z
    external real colvector fmv_dep
    if (rows(fmv_Z) == 0) {
        st_local("fmv_err", "1")
        return
    }
    st_matrix(st_local("DG"), fmv_diag(fmv_Z, fmv_dep))
}

end
