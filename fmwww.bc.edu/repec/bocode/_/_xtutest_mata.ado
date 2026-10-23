*! _xtutest_mata  version 1.3.0  20oct2026
*! Mata engine for xtutest (unit regressions, mean group, shape test, turning points,
*! CD test, pooled comparison). Loaded on demand with -do- by _xtutest_load; not a command.

mata:
mata set matastrict off

real scalar xtu_loaded()
{
    return(130)
}

// quantile and cdf of the reference distribution: t(df) or N(0,1) when df is missing
real scalar xtu_qt(real scalar df, real scalar p)
{
    if (df >= .) return(invnormal(p))
    return(invttail(df, 1 - p))
}

real scalar xtu_cdf(real scalar df, real scalar x)
{
    if (df >= .) return(normal(x))
    return(1 - ttail(df, x))
}

// slopes of the mean curve at xL and xH and the intersection-union statistic
real rowvector xtu_iu(real colvector b, real matrix V, real scalar xL, real scalar xH,
                      real scalar ush, real scalar df)
{
    real colvector gL, gH
    real scalar sL, sH, tL, tH, S
    gL = (1 \ 2 * xL)
    gH = (1 \ 2 * xH)
    sL = b[|1 \ 2|]' * gL
    sH = b[|1 \ 2|]' * gH
    tL = sL / sqrt(gL' * V[|1, 1 \ 2, 2|] * gL)
    tH = sH / sqrt(gH' * V[|1, 1 \ 2, 2|] * gH)
    if (ush) S = min((-tL, tH))
    else     S = min((tL, -tH))
    return((sL, sH, tL, tH, S, 1 - xtu_cdf(df, S)))
}

// Fieller interval for -b1/(2 b2): returns (lo, hi, bounded)
real rowvector xtu_fieller(real colvector b, real matrix V, real scalar level, real scalar df)
{
    real scalar q2, a, bb, c, disc
    q2   = xtu_qt(df, 1 - (1 - level / 100) / 2)^2
    a    = 4 * (b[2]^2 - q2 * V[2, 2])
    bb   = 4 * (b[1] * b[2] - q2 * V[1, 2])
    c    = b[1]^2 - q2 * V[1, 1]
    disc = bb^2 - 4 * a * c
    if (a > 0 & disc > 0) return(((-bb - sqrt(disc)) / (2 * a), (-bb + sqrt(disc)) / (2 * a), 1))
    return((., ., 0))
}

void xtu_run()
{
    // v1.3.0: unbalanced panels. Cross-section averages are taken, period by period, over the
    // units observed in that period; each unit regression uses its own periods.
    external real matrix xtu_B, xtu_E, xtu_V, xtu_Vp
    external real colvector xtu_b, xtu_bp
    string scalar yv, xv, idv, tvn, touse
    string rowvector wv
    real scalar cce, ush, level, df, N, Tn, kw, i, j, xL, xH, c, n, lo, hi, med, alpha, ccep, k
    real scalar tp, dse, cdv, pooled, Ti, Tmin, Tavg, npair, sw
    real matrix Hh, HHi, Xi, MXi, QQ, Psi, Rp, Pinv, W, info, comps, Zbar, Z, A, B, E, D, V
    real matrix Zp, Ap, M, PD, Dm, cnt
    real colvector qsum, di, y, x, id, tv, times, pos, b, g, tps, cv, yi, e, ri, ei, ej, okp
    real rowvector res, fl

    yv    = st_local("depvar")
    xv    = st_local("xvar")
    wv    = tokens(st_local("controls"))
    idv   = st_local("ivar")
    tvn   = st_local("tvar")
    touse = st_local("touse")
    cce   = strtoreal(st_local("cce"))
    ccep  = (st_local("estimator") == "ccep")
    ush   = strtoreal(st_local("ush"))
    level = strtoreal(st_local("level"))
    xL    = strtoreal(st_local("xL"))
    xH    = strtoreal(st_local("xH"))
    pooled = strtoreal(st_local("dopooled"))
    kw    = cols(wv)

    y  = st_data(., yv, touse)
    x  = st_data(., xv, touse)
    id = st_data(., idv, touse)
    tv = st_data(., tvn, touse)
    if (kw > 0) W = st_data(., wv, touse)
    else        W = J(rows(y), 0, .)
    info  = panelsetup(id, 1)
    N     = rows(info)
    times = uniqrows(tv)
    Tn    = rows(times)
    pos   = J(rows(tv), 1, .)
    for (i = 1; i <= rows(tv); i++) pos[i] = sum(times :<= tv[i])
    df    = (strtoreal(st_local("normal")) ? . : N - 1)
    alpha = 1 - level / 100
    Tmin  = min(info[., 2] - info[., 1] :+ 1)
    Tavg  = rows(y) / N

    // cross-section averages by period over the units present
    comps = (y, x, x:^2, W)
    if (cce) {
        Zbar = J(Tn, cols(comps), 0)
        cnt  = J(Tn, 1, 0)
        for (i = 1; i <= rows(y); i++) {
            Zbar[pos[i], .] = Zbar[pos[i], .] + comps[i, .]
            cnt[pos[i]] = cnt[pos[i]] + 1
        }
        Zbar = Zbar :/ cnt
    }
    B  = J(N, 2 + kw, .)
    E  = J(Tn, N, .)
    PD = J(N, 4, .)
    k  = 2 + kw
    if (ccep) {
        QQ   = J(N * k, k, .)
        Psi  = J(k, k, 0)
        qsum = J(k, 1, 0)
    }
    for (i = 1; i <= N; i++) {
        ri = panelsubmatrix(pos, i, info)
        Ti = rows(ri)
        Z = J(Ti, 1, 1), panelsubmatrix(x, i, info), panelsubmatrix(x, i, info):^2
        if (kw > 0) Z = Z, panelsubmatrix(W, i, info)
        if (cce)    Z = Z, Zbar[ri, .]
        yi = panelsubmatrix(y, i, info)
        A  = invsym(cross(Z, Z))
        b  = A * cross(Z, yi)
        B[i, .] = b[|2 \ 3 + kw|]'
        E[ri, i] = yi - Z * b
        PD[i, .] = xtu_udiag(yi, Z, 3 + kw)
        if (ccep) {
            // CCE pooled (Pesaran 2006): M_i = I - H_i(H_i'H_i)^-1 H_i', H_i = (1, averages)
            Hh  = J(Ti, 1, 1), Zbar[ri, .]
            HHi = invsym(cross(Hh, Hh))
            Xi  = Z[|1, 2 \ Ti, 3 + kw|]
            MXi = Xi - Hh * (HHi * cross(Hh, Xi))
            QQ[|(i - 1) * k + 1, 1 \ i * k, k|] = cross(Xi, MXi) / Ti
            Psi  = Psi + cross(Xi, MXi) / Ti
            qsum = qsum + cross(MXi, yi) / Ti
        }
    }
    b = mean(B)'
    D = B :- b'
    V = cross(D, D) / (N * (N - 1))
    if (ccep) {
        // pooled slopes and the nonparametric variance of Pesaran (2006, eq. 69)
        Psi  = Psi / N
        Pinv = invsym(Psi)
        Rp   = J(k, k, 0)
        for (i = 1; i <= N; i++) {
            di = QQ[|(i - 1) * k + 1, 1 \ i * k, k|] * (B[i, .]' - b)
            Rp = Rp + di * di'
        }
        Rp = Rp / (N - 1)
        b  = Pinv * qsum / N
        V  = Pinv * Rp * Pinv / N
    }

    res = xtu_iu(b, V, xL, xH, ush, df)
    tp  = -b[1] / (2 * b[2])
    fl  = xtu_fieller(b, V, level, df)
    g   = (-1 / (2 * b[2]) \ b[1] / (2 * b[2]^2))
    dse = sqrt(g' * V[|1, 1 \ 2, 2|] * g)

    // median unit turning point among units with the relevant curvature
    if (ush) cv = B[., 2] :> 0
    else     cv = B[., 2] :< 0
    n = sum(cv)
    med = .
    lo  = .
    hi  = .
    if (n >= 5) {
        tps = sort(select(-B[., 1] :/ (2 * B[., 2]), cv), 1)
        c = 1
        while (c < n & binomial(n, c, 0.5) <= alpha / 2) c++
        lo  = tps[c]
        hi  = tps[n - c + 1]
        med = 0.5 * (tps[floor((n + 1) / 2)] + tps[floor((n + 2) / 2)])
    }

    // Pesaran CD test on the unit residuals; unbalanced form (Pesaran 2015):
    // CD = sqrt(2/(N(N-1))) sum_{i<j} sqrt(T_ij) rho_ij over the periods both units share
    sw = 0
    npair = 0
    for (i = 1; i < N; i++) {
        for (j = i + 1; j <= N; j++) {
            okp = (E[., i] :< .) :& (E[., j] :< .)
            if (sum(okp) < 3) continue
            ei = select(E[., i], okp)
            ej = select(E[., j], okp)
            ei = ei :- mean(ei)
            ej = ej :- mean(ej)
            sw = sw + sqrt(rows(ei)) * cross(ei, ej) / sqrt(cross(ei, ei) * cross(ej, ej))
            npair++
        }
    }
    cdv = sqrt(2 / (N * (N - 1))) * sw

    xtu_B = B[|1, 1 \ N, 2|], (-B[., 1] :/ (2 * B[., 2])), cv
    xtu_E = E
    xtu_b = b
    xtu_V = V

    st_matrix(st_local("BB"), b')
    st_matrix(st_local("VV"), V)
    st_matrix(st_local("UN"), (uniqrows(id), xtu_B, PD))
    st_matrix(st_local("DG"), xtu_aggr(PD))
    st_matrix(st_local("RES"), (res, tp, fl, tp - xtu_qt(df, 1 - alpha / 2) * dse,
        tp + xtu_qt(df, 1 - alpha / 2) * dse, med, lo, hi, mean(cv), n, cdv,
        2 * (1 - normal(abs(cdv))), N, Tn, df))
    st_local("Tmin", strofreal(Tmin))
    st_local("Tavg", strofreal(Tavg, "%9.2f"))

    // pooled fixed effects (unit effects by demeaning, time effects by dummies), cluster-robust
    if (pooled) {
        Dm = J(rows(y), Tn - 1, 0)
        for (i = 1; i <= rows(y); i++) {
            if (pos[i] > 1) Dm[i, pos[i] - 1] = 1
        }
        M  = xtu_within((y, x, x:^2, W, Dm), info, N)
        Zp = M[|1, 2 \ rows(M), cols(M)|]
        Ap = invsym(cross(Zp, Zp))
        xtu_bp = Ap * cross(Zp, M[., 1])
        e  = M[., 1] - Zp * xtu_bp
        D  = J(cols(Zp), cols(Zp), 0)
        for (i = 1; i <= N; i++) {
            g = cross(panelsubmatrix(Zp, i, info), panelsubmatrix(e, i, info))
            D = D + g * g'
        }
        xtu_Vp = Ap * D * Ap * N / (N - 1)
        res = xtu_iu(xtu_bp, xtu_Vp, xL, xH, ush, .)
        st_matrix(st_local("POOL"), (res, -xtu_bp[1] / (2 * xtu_bp[2]), xtu_bp[1], xtu_bp[2],
            sqrt(xtu_Vp[1, 1]), sqrt(xtu_Vp[2, 2])))
    }
}

// unit demeaning (one-way within transformation); balanced or unbalanced
real matrix xtu_within(real matrix M, real matrix info, real scalar N)
{
    real matrix out, Mi
    real scalar i
    out = M
    for (i = 1; i <= N; i++) {
        Mi = panelsubmatrix(M, i, info)
        out[|info[i, 1], 1 \ info[i, 2], cols(M)|] = Mi - J(rows(Mi), 1, 1) * mean(Mi)
    }
    return(out)
}

// ---- residual diagnostics for one unit regression -------------------------
// returns p-values of: Breusch-Godfrey LM(1), Koenker-Breusch-Pagan (on the unit's own
// regressors: constant, x, x^2, controls = first k0 columns of Z), Jarque-Bera, and the
// CUSUM test of Brown, Durbin and Evans (1975) with the boundary-crossing p-value
// p = 2{1 - Phi(3a) + exp(-4a^2) Phi(a)}
real rowvector xtu_udiag(real colvector y, real matrix Z, real scalar k0)
{
    real scalar n, m, r2, lm, s2, sk, ku, jb, t, nw, sig, a, pc
    real colvector b, e, el, ee, e2, w, cw, rr
    real matrix W, Ai, Zp
    real rowvector zt, out
    n   = rows(Z)
    m   = cols(Z)
    out = J(1, 4, .)
    b   = invsym(cross(Z, Z)) * cross(Z, y)
    e   = y - Z * b
    // Breusch-Godfrey(1)
    el  = 0 \ e[|1 \ n - 1|]
    W   = Z, el
    ee  = e - W * (invsym(cross(W, W)) * cross(W, e))
    r2  = 1 - cross(ee, ee) / cross(e, e)
    out[1] = chi2tail(1, n * r2)
    // Koenker-Breusch-Pagan on the unit's own regressors
    e2  = e :^ 2
    W   = Z[|1, 1 \ n, k0|]
    ee  = e2 - W * (invsym(cross(W, W)) * cross(W, e2))
    r2  = 1 - cross(ee, ee) / cross(e2 :- mean(e2), e2 :- mean(e2))
    out[2] = chi2tail(k0 - 1, n * r2)
    // Jarque-Bera
    s2  = cross(e :- mean(e), e :- mean(e)) / n
    sk  = mean((e :- mean(e)) :^ 3) / s2 ^ 1.5
    ku  = mean((e :- mean(e)) :^ 4) / s2 ^ 2
    jb  = n / 6 * (sk ^ 2 + (ku - 3) ^ 2 / 4)
    out[3] = chi2tail(2, jb)
    // CUSUM of recursive residuals
    nw = n - m
    if (nw >= 3) {
        w = J(nw, 1, .)
        for (t = m + 1; t <= n; t++) {
            Zp = Z[|1, 1 \ t - 1, m|]
            Ai = invsym(cross(Zp, Zp))
            zt = Z[t, .]
            w[t - m] = (y[t] - zt * (Ai * cross(Zp, y[|1 \ t - 1|]))) / sqrt(1 + zt * Ai * zt')
        }
        sig = sqrt(cross(w :- mean(w), w :- mean(w)) / (nw - 1))
        cw  = runningsum(w) / sig
        rr  = (1::nw)
        a   = max(abs(cw) :/ (sqrt(nw) :+ 2 * rr / sqrt(nw)))
        pc  = 2 * (1 - normal(3 * a) + exp(-4 * a^2) * normal(a))
        out[4] = min((1, max((0, pc))))
    }
    return(out)
}

// aggregate unit p-values: share rejecting at 5%, Fisher (Maddala-Wu) and inverse-normal (Choi)
real matrix xtu_aggr(real matrix P)
{
    real matrix out
    real colvector p
    real scalar j, n, fi, z
    out = J(4, 6, .)
    for (j = 1; j <= 4; j++) {
        p = select(P[., j], P[., j] :< .)
        n = rows(p)
        if (n == 0) continue
        p  = rowmax((rowmin((p, J(n, 1, 1 - 1e-12))), J(n, 1, 1e-300)))
        fi = -2 * sum(ln(p))
        z  = sum(invnormal(p)) / sqrt(n)
        out[j, .] = (mean(p :< 0.05), n, fi, chi2tail(2 * n, fi), z, normal(z))
    }
    return(out)
}

// panel residual tests for the pooled estimators: modified Wald test for groupwise
// heteroskedasticity (Greene 2000) and Jarque-Bera on the pooled residuals
void xtu_pdiag(string scalar ev, string scalar iv, string scalar tu)
{
    real colvector e, id, ei, s2, vi
    real matrix info
    real scalar N, i, Ti, W, s2all, sk, ku, jb, n
    e    = st_data(., ev, tu)
    id   = st_data(., iv, tu)
    info = panelsetup(id, 1)
    N    = rows(info)
    s2   = J(N, 1, .)
    vi   = J(N, 1, .)
    for (i = 1; i <= N; i++) {
        ei = panelsubmatrix(e, i, info)
        Ti = rows(ei)
        s2[i] = cross(ei, ei) / Ti
        vi[i] = cross(ei :^ 2 :- s2[i], ei :^ 2 :- s2[i]) / (Ti * (Ti - 1))
    }
    s2all = cross(e, e) / rows(e)
    W  = sum((s2 :- s2all) :^ 2 :/ vi)
    n  = rows(e)
    sk = mean((e :- mean(e)) :^ 3) / (cross(e :- mean(e), e :- mean(e)) / n) ^ 1.5
    ku = mean((e :- mean(e)) :^ 4) / (cross(e :- mean(e), e :- mean(e)) / n) ^ 2
    jb = n / 6 * (sk ^ 2 + (ku - 3) ^ 2 / 4)
    st_matrix(st_local("PDG"), (W, N, chi2tail(N, W)) \ (jb, 2, chi2tail(2, jb)))
}

// shape test, turning point and intervals from a coefficient vector (x, x^2 first) and its
// variance, for the pooled estimators; writes the same RES row layout as xtu_run
void xtu_frombV(string scalar bn, string scalar vn, real scalar xL, real scalar xH,
                real scalar ush, real scalar level, real scalar df, real scalar N, real scalar T)
{
    external real colvector xtu_b
    external real matrix xtu_V
    real colvector b, g
    real matrix V
    real rowvector res, fl
    real scalar tp, dse, q
    b   = st_matrix(bn)'
    V   = st_matrix(vn)
    xtu_b = b
    xtu_V = V
    res = xtu_iu(b, V, xL, xH, ush, df)
    tp  = -b[1] / (2 * b[2])
    fl  = xtu_fieller(b, V, level, df)
    g   = (-1 / (2 * b[2]) \ b[1] / (2 * b[2]^2))
    dse = sqrt(g' * V[|1, 1 \ 2, 2|] * g)
    q   = xtu_qt(df, 1 - (1 - level / 100) / 2)
    st_matrix(st_local("RES"), (res, tp, fl, tp - q * dse, tp + q * dse, ., ., ., ., ., ., ., N, T, df))
}

// two-way within transformation of a balanced panel (rows sorted by unit, then time)
real matrix xtu_twoway(real matrix M, real matrix info, real scalar N, real scalar T)
{
    // y_it - ybar_i - ybar_t + ybar; every term is made T x c, so no colon operators are mixed
    real matrix out, tm, Mi, UM, GM
    real rowvector um, gm
    real colvector one
    real scalar i
    one = J(T, 1, 1)
    gm  = mean(M)
    GM  = one * gm
    tm  = J(T, cols(M), 0)
    for (i = 1; i <= N; i++) tm = tm + panelsubmatrix(M, i, info)
    tm  = tm / N
    out = M
    for (i = 1; i <= N; i++) {
        Mi = panelsubmatrix(M, i, info)
        um = mean(Mi)
        UM = one * um
        out[|info[i, 1], 1 \ info[i, 2], cols(M)|] = ((Mi - UM) - tm) + GM
    }
    return(out)
}

// mean curve and pointwise interval on a grid (for the graph)
void xtu_curve(real scalar lo, real scalar hi, real scalar npts, real scalar level, real scalar df)
{
    external real colvector xtu_b
    external real matrix xtu_V
    real colvector g, f, se
    real matrix G
    real scalar q
    g  = rangen(lo, hi, npts)
    G  = g, g:^2
    f  = G * xtu_b[|1 \ 2|]
    se = sqrt(rowsum((G * xtu_V[|1, 1 \ 2, 2|]) :* G))
    q  = xtu_qt(df, 1 - (1 - level / 100) / 2)
    st_addobs(max((0, npts - st_nobs())))
    st_store((1::npts), st_addvar("double", ("xg", "fg", "flo", "fhi")), (g, f, f - q * se, f + q * se))
}

end
