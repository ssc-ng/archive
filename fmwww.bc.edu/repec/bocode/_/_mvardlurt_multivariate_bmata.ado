*! _mvardlurt_multivariate_bmata  version 1.1.2  03oct2026
*! Mata part of the residual bootstrap (mvu_boot, mvu_boot_run, mvu_q).
*! Loaded on demand with -do- by _mvardlurt_multivariate_load; not a Stata command.
*! Uses mvu_lag, mvu_seq and mvu_stats from _mvardlurt_multivariate_mata.ado.

mata:
mata set matastrict off

real scalar mvu_bloaded()
{
    return(1)
}

real scalar mvu_q(real colvector sorted, real scalar prob)
{
    real scalar B, idx
    B   = rows(sorted)
    idx = ceil(prob * B)
    if (idx < 1) idx = 1
    if (idx > B) idx = B
    return(sorted[idx])
}

// bt: t draws (beta1 = 0 imposed); bf: F draws (beta2 = 0 imposed)
void mvu_boot(real colvector y, real matrix Z, real colvector dep,
              real scalar p, real scalar k, real scalar s,
              real colvector bt, real colvector bf)
{
    real scalar T, n, m, mt, mf, r, t, j, row, v, tt, ff, b1f
    real rowvector fxt, fxf, keepf
    real colvector dy, et, ef, bR, bF, fpt, fpf, phit, phif, idx, e, ys, dys, dyb
    real matrix Zt, Zf, Zs

    T  = rows(y)
    n  = rows(Z)
    m  = cols(Z)
    dy = y - mvu_lag(y, 1)
    tt = 0
    ff = 0

    // t-test model: L.y dropped
    Zt = Z[|1, 2 \ n, m|]
    mt = cols(Zt)
    bR = invsym(cross(Zt, Zt)) * cross(Zt, dep)
    et = dep - Zt * bR
    et = (et :- mean(et)) * sqrt(n / (n - mt))
    fxt = mvu_seq(1, k), mvu_seq(k + p + 1, mt)
    fpt = Zt[., fxt] * bR[fxt']
    phit = J(p, 1, 0)
    for (j = 1; j <= p; j++) phit[j] = bR[k + j]

    // F-test model: L.x1..L.xk dropped
    keepf = 1, mvu_seq(k + 2, m)
    Zf = Z[., keepf]
    mf = cols(Zf)
    bF = invsym(cross(Zf, Zf)) * cross(Zf, dep)
    ef = dep - Zf * bF
    ef = (ef :- mean(ef)) * sqrt(n / (n - mf))
    b1f = bF[1]
    fxf = mvu_seq(p + 2, mf)
    if (cols(fxf) > 0) fpf = Zf[., fxf] * bF[fxf']
    else               fpf = J(n, 1, 0)
    phif = J(p, 1, 0)
    for (j = 1; j <= p; j++) phif[j] = bF[1 + j]

    for (r = 1; r <= rows(bt); r++) {

        idx = floor(n * runiform(n, 1)) :+ 1
        idx = idx - (idx :> n)

        // t-test draw
        e   = et[idx]
        ys  = y
        dys = dy
        for (t = s; t <= T; t++) {
            row = t - s + 1
            v = fpt[row] + e[row]
            for (j = 1; j <= p; j++) v = v + phit[j] * dys[t - j]
            dys[t] = v
            ys[t]  = ys[t - 1] + v
        }
        Zs = Z
        Zs[., 1] = ys[|s - 1 \ T - 1|]
        for (j = 1; j <= p; j++) Zs[., k + 1 + j] = dys[|s - j \ T - j|]
        dyb = dys[|s \ T|]
        mvu_stats(dyb, Zs, k, tt, ff)
        bt[r] = tt

        // F-test draw
        e   = ef[idx]
        ys  = y
        dys = dy
        for (t = s; t <= T; t++) {
            row = t - s + 1
            v = fpf[row] + b1f * ys[t - 1] + e[row]
            for (j = 1; j <= p; j++) v = v + phif[j] * dys[t - j]
            dys[t] = v
            ys[t]  = ys[t - 1] + v
        }
        Zs = Z
        Zs[., 1] = ys[|s - 1 \ T - 1|]
        for (j = 1; j <= p; j++) Zs[., k + 1 + j] = dys[|s - j \ T - j|]
        dyb = dys[|s \ T|]
        mvu_stats(dyb, Zs, k, tt, ff)
        bf[r] = ff
    }
}

// run B replications, compute critical values and bootstrap p-values
void mvu_boot_run()
{
    external real matrix    mvu_Z
    external real colvector mvu_dep, mvu_bt, mvu_bf, mvu_y
    external real scalar    mvu_p, mvu_k, mvu_s
    real scalar reps, alpha, tst, fst, Bt, Bf, pt, pf, i
    real colvector tb, fb
    real rowvector pr
    real matrix cv

    if (rows(mvu_Z) == 0) {
        st_local("mvu_err", "1")
        return
    }
    reps  = strtoreal(st_local("reps"))
    alpha = strtoreal(st_local("alpha"))
    tst   = strtoreal(st_local("tstat"))
    fst   = strtoreal(st_local("fstat"))

    tb = J(reps, 1, .)
    fb = J(reps, 1, .)
    mvu_boot(mvu_y, mvu_Z, mvu_dep, mvu_p, mvu_k, mvu_s, tb, fb)
    tb = select(tb, tb :< .)
    fb = select(fb, fb :< .)
    if (rows(tb) < 50 | rows(fb) < 50) {
        st_local("mvu_err", "4")
        return
    }
    mvu_bt = tb
    mvu_bf = fb
    Bt = rows(tb)
    Bf = rows(fb)
    tb = sort(tb, 1)
    fb = sort(fb, 1)

    cv = J(2, 5, .)
    pr = (.10, .05, .025, .01, alpha)
    for (i = 1; i <= 5; i++) {
        cv[1, i] = mvu_q(tb, pr[i])
        cv[2, i] = mvu_q(fb, 1 - pr[i])
    }
    pt = (1 + sum(mvu_bt :<= tst)) / (Bt + 1)
    pf = (1 + sum(mvu_bf :>= fst)) / (Bf + 1)

    st_matrix(st_local("CVB"),  cv)
    st_matrix(st_local("INFO"), (Bt, Bf, pt, pf))
}

end
