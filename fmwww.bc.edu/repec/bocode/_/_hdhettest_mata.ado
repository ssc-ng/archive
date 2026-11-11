*! _hdhettest_mata  version 1.1.0  10nov2026
*! Mata engine for hdhettest. Loaded on demand with -do- by _hdhettest_load; not a command.

mata:
mata set matastrict off

real scalar hdh_loaded()
{
    return(110)
}

// statistics for each column of E (n x B residual vectors); returns B x 5, or B x 6
// when indicator variables are given: cvt alrt bp(regressors) bp(fitted) jb
// [bp(indicators)].  Xb: kept rows of the design (with constant), XtXi = invsym(Xb'Xb);
// yh: fitted values (n x 1); Zb, ZtZi: kept rows of the indicator matrix (with
// constant) and invsym(Zb'Zb), or 0 x 0 when there are no indicators
real matrix hdh_stats(real matrix E, real matrix Xb, real matrix XtXi, real colvector yh,
                      real matrix Zb, real matrix ZtZi)
{
    real matrix R, U, F, Uc, D, H, G
    real rowvector m, m2, m3, m4, sst, b1, ssr1
    real scalar n, B
    n = rows(E); B = cols(E)
    R = J(B, (cols(Zb) > 0 ? 6 : 5), .)
    U = E:^2
    m = mean(U)
    R[., 1] = (mean((U :- m):^2) :/ m:^2)'
    R[., 2] = (ln(m) - mean(ln(U)))'
    Uc = U :- m
    sst = colsum(Uc:^2)
    F = U - Xb * (XtXi * (Xb' * U))
    R[., 3] = (n * (1 :- colsum(F:^2) :/ sst))'
    // fitted values: R^2 of e^2 on (1, yhat)
    H = yh :- mean(yh)
    b1 = (H' * Uc) / (H' * H)
    ssr1 = colsum((Uc - H * b1):^2)
    R[., 4] = (n * (1 :- ssr1 :/ sst))'
    D = E :- mean(E)
    m2 = mean(D:^2); m3 = mean(D:^3); m4 = mean(D:^4)
    R[., 5] = (n * ((m3 :/ m2:^1.5):^2 / 6 + (m4 :/ m2:^2 :- 3):^2 / 24))'
    // Koenker statistic on the indicator variables
    if (cols(Zb) > 0) {
        G = U - Zb * (ZtZi * (Zb' * U))
        R[., 6] = (n * (1 :- colsum(G:^2) :/ sst))'
    }
    return(R)
}

// indicator matrix: mode 1 the variables in zv, 2 the regressors and their squares,
// 3 the regressors, their squares and cross-products (White 1980); columns scaled
// to unit maximum, constant appended
real matrix hdh_indicators(string scalar xv, string scalar zv, string scalar touse,
                           real scalar mode)
{
    real matrix X0, Z, sc
    real scalar k, i, j
    if (mode == 1) Z = st_data(., zv, touse)
    else {
        X0 = st_data(., xv, touse)
        k = cols(X0)
        Z = X0, X0:^2
        if (mode == 3) {
            for (i = 1; i < k; i++) {
                for (j = i + 1; j <= k; j++) Z = Z, X0[., i] :* X0[., j]
            }
        }
    }
    sc = colmax(abs(Z))
    sc = sc + (sc :== 0)
    Z = Z :/ sc
    return((Z, J(rows(Z), 1, 1)))
}

// exact moments for the CVT under homoskedastic normal errors (Bai, Pan and Yin 2018
// centring; delta-method variance from Gaussian quadratic-form moments); also returns
// sum m_ii^2 and sum m_ij^4 for the kurtosis estimator.  Blockwise over rows of M.
real rowvector hdh_moments(real matrix Xb, real matrix XtXi, real scalar p)
{
    real matrix A, Mb, M2
    real colvector d
    real scalar n, s, e, trMoM, dMd, m4, np_, a, EA, EB, EB2, gA, gB, VA, VB, CAB, b, blk
    n = rows(Xb)
    A = Xb * XtXi
    d = 1 :- rowsum(A :* Xb)
    trMoM = sum(d:^2)
    dMd = 0; m4 = 0
    blk = 500
    for (s = 1; s <= n; s = s + blk) {
        e = min((s + blk - 1, n))
        Mb = -A[|s, 1 \ e, cols(A)|] * Xb'
        Mb[., (s..e)] = Mb[., (s..e)] + I(e - s + 1)
        M2 = Mb:^2
        dMd = dMd + d[|s \ e|]' * (M2 * d)
        m4 = m4 + sum(M2:^2)
    }
    np_ = (n - p)^2 + 2 * (n - p)
    a = 3 * n * trMoM / np_ - 1
    EA = 3 * trMoM / n
    EB = (n - p) / n
    EB2 = np_ / n^2
    gA = 1 / EB2
    gB = -2 * EA / (EB2 * EB)
    VA = (72 * dMd + 24 * m4) / n^2
    VB = 2 * (n - p) / n^2
    CAB = 12 * trMoM / n^2
    b = gA^2 * VA + gB^2 * VB + 2 * gA * gB * CAB
    return((a, b, trMoM, m4))
}

// main routine
//   dist 1 = Gaussian errors (exact), 2 = Student-t errors with the estimated excess
//   kurtosis (robust option)
// writes RES (5 x 4: statistic, df, asymptotic p, Monte Carlo p; rows cvt alrt bp bpf jb)
// and INFO (n_used, p, n_dropped, nu4, df_t, cvt_mean, cvt_sd)
void hdh_run(string scalar yv, string scalar xv, string scalar touse, real scalar reps,
             real scalar dist, real scalar chunk, real scalar domom,
             string scalar resn, string scalar infon, string scalar zv, real scalar zmode)
{
    real colvector y, d, keep, e, yh, bh
    real matrix X, XtXi, Xb, Xbi, s0, sb, cnt, Eps, Es, R, Zb, ZtZi
    real rowvector mom
    real scalar n0, n, p, q, done, c, nu4, s2, dft, rk, qz, nt
    y = st_data(., yv, touse)
    X = st_data(., xv, touse), J(rows(y), 1, 1)
    n0 = rows(y)
    XtXi = invsym(X' * X)
    p = sum(diagonal(XtXi) :!= 0)
    bh = XtXi * (X' * y)
    e = y - X * bh
    yh = X * bh
    d = 1 :- rowsum((X * XtXi) :* X)
    keep = (d :> 1e-8)
    n = sum(keep)
    Xb = select(X, keep)
    Xbi = invsym(Xb' * Xb)
    rk = sum(diagonal(Xbi) :!= 0)
    q = rk - 1
    e = select(e, keep)
    yh = select(yh, keep)
    Zb = J(0, 0, .); ZtZi = J(0, 0, .); qz = .
    if (zmode > 0) {
        Zb = select(hdh_indicators(xv, zv, touse, zmode), keep)
        ZtZi = invsym(Zb' * Zb)
        qz = sum(diagonal(ZtZi) :!= 0) - 1
    }
    nt = (zmode > 0 ? 6 : 5)
    s0 = hdh_stats(e, Xb, Xbi, yh, Zb, ZtZi)
    mom = J(1, 4, .)
    if (domom) mom = hdh_moments(Xb, Xbi, p)
    nu4 = .; dft = .
    if (dist == 2) {
        if (!domom) mom = hdh_moments(Xb, Xbi, p)
        s2 = (e' * e) / (n - p)
        nu4 = (sum(e:^4) / s2^2 - 3 * mom[3]) / mom[4]
        if (nu4 > 0.05) dft = 4 + 6 / nu4
    }
    cnt = J(1, nt, 0)
    done = 0
    while (done < reps) {
        c = min((chunk, reps - done))
        if (dft < .) Eps = rt(n0, c, dft)
        else Eps = rnormal(n0, c, 0, 1)
        Es = Eps - X * (XtXi * (X' * Eps))
        Es = select(Es, keep)
        sb = hdh_stats(Es, Xb, Xbi, yh, Zb, ZtZi)
        cnt = cnt + colsum(sb :>= s0)
        done = done + c
    }
    R = J(nt, 4, .)
    R[., 1] = s0'
    R[., 4] = ((cnt :+ 1) / (reps + 1))'
    // asymptotic p-values
    if (mom[1] < .) R[1, 3] = 1 - normal((s0[1] - mom[1]) / sqrt(mom[2]))
    R[2, 3] = 1 - normal((s0[2] - (ln(2) - digamma(1))) / sqrt((pi()^2 / 2 - 2) / n))
    R[3, 2] = q
    R[3, 3] = chi2tail(q, s0[3])
    R[4, 2] = 1
    R[4, 3] = chi2tail(1, s0[4])
    R[5, 2] = 2
    R[5, 3] = chi2tail(2, s0[5])
    if (nt == 6) {
        R[6, 2] = qz
        R[6, 3] = chi2tail(qz, s0[6])
    }
    st_matrix(resn, R)
    st_matrix(infon, (n, p, n0 - n, nu4, dft, mom[1], sqrt(mom[2])))
}

end
