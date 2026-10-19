*! lassour_mata.do   version 1.0.0  17oct2026
*! Mata source for the lassour package, and the script that compiles it into
*! the library llassour.mlib.
*! Dr Merwan Roudane  (merwanroudane920@gmail.com)
*!
*! The Mata engine is shipped as a COMPILED LIBRARY rather than embedded in
*! lassour.ado on purpose: some packages (bootur among them) issue
*! "mata clear", which would drop the functions while leaving the ado program
*! in memory, breaking the next call. Functions resolved from a .mlib on the
*! adopath survive that.
*!
*! To rebuild the library after editing:
*!     do lassour_mata.do
*! It writes llassour.mlib into the PLUS directory and re-indexes.

version 14.0

version 14.0
mata:
mata set matastrict off

// ------------------------------------------------------------------
// Published critical values, AR24 Table 1 (det=0) and Table D1 (det=1,2).
// Rows: T = 50, 75, 100, 150, 250, 500, 1000
// Cols: tau 1%, tau 5%, tau 10%, tauIE 1%, tauIE 5%, tauIE 10%
// ------------------------------------------------------------------
real matrix lsr_cvmat(real scalar det)
{
    real matrix M

    M = J(7, 6, .)
    if (det == 0) {
        M = (7.43, 4.30, 3.07, 15.87, 5.73, 3.06) \
            (7.23, 4.22, 3.03, 15.94, 5.81, 3.11) \
            (7.18, 4.23, 3.03, 16.55, 5.93, 3.15) \
            (7.06, 4.18, 3.00, 16.32, 5.94, 3.17) \
            (7.03, 4.15, 2.99, 16.60, 5.98, 3.20) \
            (7.00, 4.13, 2.97, 16.65, 6.01, 3.20) \
            (6.97, 4.13, 2.97, 16.78, 6.04, 3.22)
    }
    if (det == 1) {
        M = (7.40, 4.28, 3.06, 13.21, 5.32, 3.08) \
            (7.25, 4.23, 3.02, 13.55, 5.40, 3.12) \
            (7.18, 4.21, 3.02, 13.72, 5.49, 3.17) \
            (7.12, 4.19, 3.01, 14.02, 5.59, 3.22) \
            (7.08, 4.16, 2.99, 13.98, 5.58, 3.21) \
            (6.97, 4.15, 2.98, 13.96, 5.62, 3.23) \
            (6.95, 4.15, 2.98, 13.93, 5.65, 3.23)
    }
    if (det == 2) {
        M = (10.97, 7.22, 5.65, 20.15, 10.49, 7.24) \
            (10.65, 7.07, 5.56, 20.85, 10.85, 7.51) \
            (10.51, 7.03, 5.55, 21.41, 11.08, 7.65) \
            (10.37, 6.94, 5.49, 21.68, 11.21, 7.72) \
            (10.21, 6.90, 5.47, 21.84, 11.31, 7.83) \
            (10.15, 6.85, 5.46, 22.06, 11.41, 7.88) \
            (10.13, 6.87, 5.44, 22.25, 11.51, 7.93)
    }
    return(M)
}

void lsr_cvtable(real scalar det, string scalar rmat)
{
    real matrix M
    real rowvector Tg
    real scalar i

    M  = lsr_cvmat(det)
    Tg = (50, 75, 100, 150, 250, 500, 1000)
    for (i = 1; i <= 7; i++) {
        printf("{res}%8.0f{txt} {c |}{res}%13.2f%10.2f%10.2f%10.2f%10.2f%10.2f\n",
               Tg[i], M[i, 1], M[i, 2], M[i, 3], M[i, 4], M[i, 5], M[i, 6])
    }
    st_matrix(rmat, M)
    st_matrixrowstripe(rmat, (J(7, 1, ""), strofreal(Tg')))
    st_matrixcolstripe(rmat, (J(6, 1, ""),
        ("tau_1" \ "tau_5" \ "tau_10" \ "tauIE_1" \ "tauIE_5" \ "tauIE_10")))
}

// Interpolate a published critical value linearly in T.
real scalar lsr_cvget(real scalar det, real scalar stat, real scalar level,
                      real scalar T)
{
    real matrix M
    real rowvector Tg
    real colvector col
    real scalar j, cix, w

    M  = lsr_cvmat(det)
    Tg = (50, 75, 100, 150, 250, 500, 1000)

    cix = 2
    if (abs(level - 99) < 1e-8) cix = 1
    if (abs(level - 95) < 1e-8) cix = 2
    if (abs(level - 90) < 1e-8) cix = 3
    if (stat == 2) cix = cix + 3
    col = M[., cix]

    if (T <= Tg[1]) return(col[1])
    if (T >= Tg[7]) return(col[7])
    for (j = 1; j <= 6; j++) {
        if (T >= Tg[j]) {
            if (T <= Tg[j + 1]) {
                w = (T - Tg[j]) / (Tg[j + 1] - Tg[j])
                return(col[j] + w * (col[j + 1] - col[j]))
            }
        }
    }
    return(col[7])
}

// ------------------------------------------------------------------
// FD (Schmidt-Phillips) detrending.  det: 0 none, 1 constant, 2 trend
//   constant : y_t - y_1
//   trend    : y_t - y_1 - ((t-1)/(N-1)) * (y_N - y_1)
// ------------------------------------------------------------------
real colvector lsr_fd(real colvector y, real scalar det)
{
    real scalar N
    real colvector tt

    N = rows(y)
    if (det == 0) return(y)
    if (det == 1) return(y :- y[1])
    tt = (1::N)
    return(y :- y[1] :- ((tt :- 1) :/ (N - 1)) :* (y[N] - y[1]))
}

// OLS adjustment for deterministics (used for the J statistic)
real colvector lsr_olsadj(real colvector y, real scalar det)
{
    real scalar N
    real matrix Z
    real colvector tt

    N = rows(y)
    if (det == 0) return(y)
    tt = (1::N)
    Z = J(N, 1, 1)
    if (det == 2) Z = J(N, 1, 1), tt
    return(y - Z * (invsym(quadcross(Z, Z)) * quadcross(Z, y)))
}

// ------------------------------------------------------------------
// ADF(p) design with ZERO-PADDED initial lags, as [T] Algorithm 1
// step 2 prescribes: (Dy_{-1},...,Dy_{-p}) := 0.  Yields T rows from
// N = T+1 observations, so the bootstrap series keeps full length.
// ------------------------------------------------------------------
void lsr_adf(real colvector y, real scalar p, real colvector dyout,
             real matrix X)
{
    real scalar N, T, j, i
    real colvector dy, c

    N  = rows(y)
    T  = N - 1
    dy = y[2::N] :- y[1::(N - 1)]
    dyout = dy
    X = y[1::T]
    for (j = 1; j <= p; j++) {
        c = J(T, 1, 0)
        for (i = j + 1; i <= T; i++) {
            c[i] = dy[i - j]
        }
        X = X, c
    }
}

real scalar lsr_quant(real colvector srt, real scalar q)
{
    real scalar n, h, lo

    n  = rows(srt)
    if (n < 1) return(.)
    h  = (n - 1) * q + 1
    lo = floor(h)
    if (lo < 1) lo = 1
    if (lo >= n) return(srt[n])
    return(srt[lo] + (h - lo) * (srt[lo + 1] - srt[lo]))
}

// ------------------------------------------------------------------
// LARS-Lasso homotopy.  Objective ||Y - Xb||^2 + 2*lambda*sum w_i|b_i|.
// Scaling Xt_i = X_i/w_i makes the entry condition |Xt_i'r| = lambda,
// so lambda comes out directly in the units of AR24 Definition 1.
// Returns the first (largest) lambda at which column 1 activates.
// rec == 0 stops as soon as column 1 activates (what the test needs, and
// what keeps the bootstrap affordable).
// rec == 1 keeps walking the path and records it in PATH (col 1 lambda,
// cols 2.. coefficients on the ORIGINAL scale) so the solution-path figure
// is informative; the returned knot is identical either way.
// ------------------------------------------------------------------
real scalar lsr_knot1(real colvector Y, real matrix X, real colvector w,
                      real scalar rec, real matrix PATH)
{
    real scalar k, lam, i, j, nA, l1, l2, lnew, best, dj, ej, step, maxstep
    real scalar jbest, dropbest, tiny, knotlam
    real matrix Xt, G, Gi
    real colvector c, sA, bols, gdir, dvec, evec, absc, A, idx, fit
    real rowvector brow

    tiny = 1e-11
    k    = cols(X)
    Xt   = X
    for (j = 1; j <= k; j++) {
        Xt[., j] = X[., j] :/ w[j]
    }

    A       = J(k, 1, 0)
    sA      = J(k, 1, 0)
    knotlam = .
    if (rec == 1) PATH = J(0, k + 1, .)

    // ---- step 0: nothing active, residual = Y
    c     = quadcross(Xt, Y)
    absc  = abs(c)
    lam   = max(absc)
    jbest = 0
    for (j = 1; j <= k; j++) {
        if (jbest == 0) {
            if (absc[j] >= lam - tiny) jbest = j
        }
    }
    A[jbest]  = 1
    sA[jbest] = sign(c[jbest])
    if (rec == 1) PATH = PATH \ (lam, J(1, k, 0))
    if (jbest == 1) {
        knotlam = lam
        if (rec == 0) return(lam)
    }

    maxstep = 10 * k + 60
    for (step = 1; step <= maxstep; step++) {

        nA  = colsum(A)
        if (nA < 1) return(.)
        idx = J(nA, 1, 0)
        i   = 0
        for (j = 1; j <= k; j++) {
            if (A[j] == 1) {
                i = i + 1
                idx[i] = j
            }
        }

        G    = quadcross(Xt[., idx], Xt[., idx])
        Gi   = invsym(G)
        bols = Gi * quadcross(Xt[., idx], Y)
        gdir = Gi * sA[idx]
        fit  = Xt[., idx] * bols

        dvec = J(k, 1, .)
        evec = J(k, 1, .)
        for (j = 1; j <= k; j++) {
            if (A[j] == 0) {
                dvec[j] = quadcross(Xt[., j], Y - fit)
                evec[j] = quadcross(Xt[., j], Xt[., idx] * gdir)
            }
        }

        best     = -1
        jbest    = 0
        dropbest = 0

        // ---- join events
        for (j = 1; j <= k; j++) {
            if (A[j] == 0) {
                dj = dvec[j]
                ej = evec[j]
                if (abs(1 - ej) > tiny) {
                    l1 = dj / (1 - ej)
                    if (l1 < lam - tiny) {
                        if (l1 > best) {
                            best     = l1
                            jbest    = j
                            dropbest = 0
                        }
                    }
                }
                if (abs(1 + ej) > tiny) {
                    l2 = -dj / (1 + ej)
                    if (l2 < lam - tiny) {
                        if (l2 > best) {
                            best     = l2
                            jbest    = j
                            dropbest = 0
                        }
                    }
                }
            }
        }

        // ---- lasso drop events (sign change): Efron et al. (2004) sec. 3.1
        for (i = 1; i <= nA; i++) {
            if (abs(gdir[i]) > tiny) {
                lnew = bols[i] / gdir[i]
                if (lnew < lam - tiny) {
                    if (lnew > best) {
                        best     = lnew
                        jbest    = idx[i]
                        dropbest = 1
                    }
                }
            }
        }

        if (best <= tiny) return(knotlam)
        if (jbest == 0)   return(knotlam)

        lam = best

        if (rec == 1) {
            brow = J(1, k, 0)
            for (i = 1; i <= nA; i++) {
                brow[idx[i]] = (bols[i] - lam * gdir[i]) / w[idx[i]]
            }
            PATH = PATH \ (lam, brow)
        }

        if (dropbest == 1) {
            A[jbest]  = 0
            sA[jbest] = 0
        }
        else {
            A[jbest]  = 1
            sA[jbest] = -1
            if (abs(1 - evec[jbest]) > tiny) {
                if (abs(dvec[jbest] / (1 - evec[jbest]) - lam) < 1e-7) {
                    sA[jbest] = 1
                }
            }
            if (jbest == 1) {
                if (knotlam == .) knotlam = lam
                if (rec == 0) return(lam)
            }
        }
    }
    return(knotlam)
}

// ------------------------------------------------------------------
// Nadaraya-Watson (local constant) variance estimator.
// Cavaliere, Phillips, Smeekes & Taylor (2015) eq. (6), after Beare (2008).
// Same formulation as bootur's bu_npve().
// ------------------------------------------------------------------
real colvector lsr_npve(real colvector z, real scalar h)
{
    real scalar n
    real colvector r
    real matrix xm, kk

    n  = rows(z)
    r  = (1::n) / n
    xm = (r * J(1, n, 1) - J(n, 1, 1) * r') / h
    kk = normalden(xm)
    return((kk * (z :^ 2)) :/ rowsum(kk))
}

// Rescale by the estimated volatility; CPST (2015) eq. (7):
//   ytilde_t = sum_{s<=t} Dy^d_s / sigmahat_s ,  ytilde_0 = 0
real colvector lsr_rescale(real colvector yd, real scalar m, real scalar h)
{
    real colvector dy, e, sh, b
    real matrix X
    real scalar i, ns

    lsr_adf(yd, m, dy = ., X = .)
    b  = invsym(quadcross(X, X)) * quadcross(X, dy)
    e  = dy - X * b
    sh = sqrt(lsr_npve(e, h))
    ns = rows(sh)
    for (i = 1; i <= ns; i++) {
        if (sh[i] <= 0) sh[i] = 1
        if (sh[i] == .) sh[i] = 1
    }
    return(0 \ runningsum(dy :/ sh))
}

// Information criterion.  CPST (2015) / Ng & Perron (2001).
// ic: 11 AIC, 12 BIC, 13 MAIC, 14 MBIC; 3/4 = rescaled MAIC/MBIC.
real scalar lsr_ic(real scalar ic, real colvector e, real scalar k,
                   real scalar n, real scalar b0, real colvector ylag)
{
    real scalar s2, tk, base

    s2 = quadcross(e, e) / n
    if (s2 <= 0) return(.)
    base = ic
    if (base == 3) base = 13
    if (base == 4) base = 14

    if (base == 11) return(log(s2) + k * 2 / n)
    if (base == 12) return(log(s2) + k * log(n) / n)

    tk = quadcross(ylag, ylag) * (b0 * b0) / s2
    if (base == 13) return(log(s2) + (k + tk) * 2 / n)
    return(log(s2) + (k + tk) * log(n) / n)
}

// ------------------------------------------------------------------
// Lag order selection.  RS variants apply the criterion to the
// volatility-rescaled series.  The comparison sample is held fixed at
// t = pmax+1..T so criteria are comparable across k (Ng & Perron 2001).
// NB: local copies -- Mata passes arguments by reference.
// ------------------------------------------------------------------
real scalar lsr_lagsel(real colvector yd, real scalar pmin0,
                       real scalar pmax0, real scalar ic, real scalar h)
{
    real colvector yin, dy, b, e, es, yl
    real matrix X
    real scalar k, bestv, bestk, v, T, n, pmin, pmax

    pmin = pmin0
    pmax = pmax0

    yin = yd
    if (ic == 3 | ic == 4) yin = lsr_rescale(yd, 0, h)

    T = rows(yin) - 1
    n = T - pmax
    if (n < 10) {
        pmax = T - 12
        if (pmax < 0) pmax = 0
        n = T - pmax
    }
    if (pmin > pmax) pmin = pmax

    bestv = .
    bestk = pmin
    for (k = pmin; k <= pmax; k++) {
        lsr_adf(yin, k, dy = ., X = .)
        b  = invsym(quadcross(X, X)) * quadcross(X, dy)
        e  = dy - X * b
        es = e[(pmax + 1)::T]
        yl = X[(pmax + 1)::T, 1]
        v  = lsr_ic(ic, es, k, n, b[1], yl)
        if (v < bestv) {
            bestv = v
            bestk = k
        }
    }
    return(bestk)
}

// ------------------------------------------------------------------
// J_alpha range statistic.  AR24 Algorithm 1; Herwartz & Siedenburg (2010).
// y must already be OLS-adjusted for deterministics.
// Vectorised by Frisch-Waugh: zeta^(r) = (xt_r'yt)/(xt_r'xt_r).
// ------------------------------------------------------------------
real scalar lsr_J(real colvector y, real scalar alpha, real scalar R,
                  real scalar kl)
{
    real scalar N, om2, s2k, sumd, lo, hi, rr
    real colvector ys, e, tt, srt, yt, num, den, zeta, dy, bb
    real matrix Z, Xr, XW, XT, P, EE

    N = rows(y)

    // ---- step 1: LRV by the autoregressive estimator at lag kl
    lsr_adf(y, kl, dy = ., Xr = .)
    bb   = invsym(quadcross(Xr, Xr)) * quadcross(Xr, dy)
    e    = dy - Xr * bb
    s2k  = quadcross(e, e) / rows(e)
    sumd = 0
    if (kl > 0) sumd = colsum(bb[2::(kl + 1)])
    om2 = s2k / ((1 - sumd) ^ 2)
    if (om2 <= 0) om2 = s2k
    if (om2 == .) om2 = s2k
    if (om2 <= 0) om2 = 1

    // ---- step 2: scale by omegahat^{-1}
    ys = y :/ sqrt(om2)

    // ---- step 3: R Gaussian random walks with zero initial condition
    EE = rnormal(N - 1, R, 0, 1)
    XW = J(N, R, 0)
    for (rr = 1; rr <= R; rr++) {
        XW[2::N, rr] = runningsum(EE[., rr])
    }

    tt = (1::N)
    Z  = J(N, 1, 1), tt
    P  = invsym(quadcross(Z, Z)) * Z'
    XT = XW - Z * (P * XW)
    yt = ys - Z * (P * ys)

    num  = quadcross(XT, yt)
    den  = (colsum(XT :* XT))'
    zeta = num :/ den

    srt = sort(zeta, 1)
    lo  = lsr_quant(srt, alpha / 2)
    hi  = lsr_quant(srt, 1 - alpha / 2)
    return(hi - lo)
}

// ------------------------------------------------------------------
// Core statistics for one series.
// Returns (tau, tauIE, rho, sigma2, J, lambda, lambdaIE)
// ------------------------------------------------------------------
real rowvector lsr_stats(real colvector y, real scalar det, real scalar p,
                         real scalar alpha, real scalar R, real scalar kl,
                         real scalar dotau, real scalar doie,
                         real scalar rec, real matrix PATH)
{
    real colvector yd, dy, b, e, w, wb, yoa
    real matrix X, Pdum
    real scalar rho, s2, lam, lamb, Jv, j, tau, taub, T

    yd = lsr_fd(y, det)
    lsr_adf(yd, p, dy = ., X = .)
    T = rows(dy)

    b   = invsym(quadcross(X, X)) * quadcross(X, dy)
    e   = dy - X * b
    rho = b[1]
    s2  = quadcross(e, e) / (T - p - 1)          // AR24 eq. (22)

    if (rho == .) rho = 1e-10
    if (abs(rho) < 1e-12) rho = 1e-12
    if (s2 <= 0)  s2 = 1e-12
    if (s2 == .)  s2 = 1e-12

    // ---- adaptive weights: w1 = 1/|rho|, w2j = 1/|theta_j|
    w    = J(p + 1, 1, .)
    w[1] = 1 / abs(rho)
    for (j = 1; j <= p; j++) {
        if (b[j + 1] == .) {
            w[j + 1] = 1e12
        }
        else {
            if (abs(b[j + 1]) < 1e-12) w[j + 1] = 1e12
            else w[j + 1] = 1 / abs(b[j + 1])
        }
    }

    tau  = .
    lam  = .
    taub = .
    lamb = .
    Jv   = .

    if (dotau == 1) {
        lam = lsr_knot1(dy, X, w, rec, PATH)
        tau = lam / s2
    }

    if (doie == 1) {
        yoa = lsr_olsadj(y, det)
        Jv  = lsr_J(yoa, alpha, R, kl)
        if (Jv <= 0) Jv = 1e-10
        if (Jv == .) Jv = 1e-10
        wb    = w
        wb[1] = Jv / abs(rho)            // enriched weight; see help methods
        if (rec == 1 & dotau == 0) {
            lamb = lsr_knot1(dy, X, wb, 1, PATH)
        }
        else {
            lamb = lsr_knot1(dy, X, wb, 0, Pdum = .)
        }
        taub = lamb / s2
    }

    return((tau, taub, rho, s2, Jv, lam, lamb))
}

// ------------------------------------------------------------------
// Sieve wild bootstrap, [T] Algorithm 1.
// ------------------------------------------------------------------
real matrix lsr_boot(real colvector y, real scalar det, real scalar p,
                     real scalar q, real scalar pmin, real scalar pmax,
                     real scalar ic, real scalar h, real scalar B,
                     real scalar alpha, real scalar R, real scalar kl,
                     real scalar dotau, real scalar doie, real scalar dots,
                     real scalar icdet)
{
    real colvector yd, dy, b, eps, ustar, ystar, epsstar, eta
    real matrix X, OUT, Pdum
    real rowvector stb
    real scalar T, bb, t, j, ps, acc

    // ---- steps 1-2: detrend, fit the sieve ADF(q), keep residuals
    yd = lsr_fd(y, det)
    lsr_adf(yd, q, dy = ., X = .)
    T   = rows(dy)
    b   = invsym(quadcross(X, X)) * quadcross(X, dy)
    eps = dy - X * b
    eps = eps :- mean(eps)                 // recentre: Chatterjee & Lahiri (2011)

    OUT = J(B, 2, .)

    if (dots == 1) {
        printf("{txt}Bootstrap replications ({res}%g{txt})\n", B)
        printf("{txt}{hline 4}{c +}{hline 3} 1 {hline 3}{c +}{hline 3} 2 ")
        printf("{hline 3}{c +}{hline 3} 3 {hline 3}{c +}{hline 3} 4 ")
        printf("{hline 3}{c +}{hline 3} 5 \n")
    }

    for (bb = 1; bb <= B; bb++) {

        // ---- step 3: Gaussian wild innovations ([T] Remark 3)
        eta     = rnormal(T, 1, 0, 1)
        epsstar = eta :* eps

        // ---- step 4: recolour with the estimated sieve dynamics
        ustar = J(T, 1, 0)
        for (t = 1; t <= T; t++) {
            acc = epsstar[t]
            for (j = 1; j <= q; j++) {
                if (t - j >= 1) acc = acc + b[j + 1] * ustar[t - j]
            }
            ustar[t] = acc
        }
        ystar = 0 \ runningsum(ustar)       // y*_0 = 0

        // ---- step 5: re-detrend, RE-SELECT the lag, recompute
        ps = p
        if (pmax > pmin) {
            // re-select on the bootstrap sample using the same IC input
            // transform as the observed statistic (icdet: 0 = FD, 1 = OLS)
            if (icdet == 1) {
                ps = lsr_lagsel(lsr_olsadj(ystar, det), pmin, pmax, ic, h)
            }
            else {
                ps = lsr_lagsel(lsr_fd(ystar, det), pmin, pmax, ic, h)
            }
        }

        stb = lsr_stats(ystar, det, ps, alpha, R, kl, dotau, doie, 0, Pdum = .)
        OUT[bb, 1] = stb[1]
        OUT[bb, 2] = stb[2]

        if (dots == 1) {
            if (mod(bb, 50) == 0) printf("{txt}.{res} %5.0f\n", bb)
            else printf("{txt}.")
        }
    }
    if (dots == 1) printf("\n")
    return(OUT)
}

// ------------------------------------------------------------------
// Write the FD-detrended series into a Stata variable (graph Panel A).
// ------------------------------------------------------------------
void lsr_putfd(string scalar yv, string scalar tv, real scalar det,
               string scalar outv)
{
    real colvector y, yd, idx

    y   = st_data(., yv, tv)
    idx = selectindex(st_data(., tv) :!= 0)
    yd  = lsr_fd(y, det)
    st_store(idx, outv, yd)
}

// ------------------------------------------------------------------
// Driver
// ------------------------------------------------------------------
void lsr_main(string scalar yv, string scalar tv, real scalar det,
              real scalar lags, real scalar pmin0, real scalar pmax0,
              real scalar ic, real scalar sievelags, real scalar dotau,
              real scalar doie, real scalar boot, real scalar B,
              real scalar alpha, real scalar R, real scalar lrvlags,
              real scalar h, real scalar level, real scalar dots,
              real scalar icdet,
              string scalar rRES, string scalar rBOOT, string scalar rPATH,
              string scalar rVOL)
{
    real colvector y, yd, yic, dy, e, b, sh, bt, bi
    real matrix X, PATH, BOOT, VOL
    real scalar p, q, kl, T, N, tau, tauie, tcv, icv, tp, ip, pmin, pmax
    real rowvector st

    pmin = pmin0
    pmax = pmax0

    y = st_data(., yv, tv)
    y = select(y, y :!= .)
    N = rows(y)
    T = N - 1

    // ---- lag order p
    // The test itself always uses FD detrending.  The information criterion
    // may be fed either the OLS-detrended series (icdet 1, the default,
    // following Perron & Qu 2007 as adopted by CPST 2015, whose RSMAIC [T]
    // uses) or the FD-detrended series the test itself uses (icdet 0).  The
    // source paper does not say which; empirical size and power are
    // equivalent.  See "help lassour methods".
    yd  = lsr_fd(y, det)
    yic = yd
    if (icdet == 1) yic = lsr_olsadj(y, det)
    if (lags >= 0) {
        p    = lags
        pmin = lags
        pmax = lags
    }
    else {
        p = lsr_lagsel(yic, pmin, pmax, ic, h)
    }

    // ---- sieve lag q (default q = p, [T] Remark 1)
    q = p
    if (sievelags >= 0) q = sievelags

    // ---- LRV lag k for Algorithm 1 step 1 (paper: "for suitable k")
    kl = p
    if (lrvlags >= 0) kl = lrvlags

    // ---- observed statistics, recording the solution path
    PATH = J(0, 0, .)
    st   = lsr_stats(y, det, p, alpha, R, kl, dotau, doie, 1, PATH)
    tau   = st[1]
    tauie = st[2]

    // ---- critical values / p-values
    tcv  = .
    icv  = .
    tp   = .
    ip   = .
    BOOT = J(0, 2, .)

    if (boot == 1) {
        BOOT = lsr_boot(y, det, p, q, pmin, pmax, ic, h, B, alpha, R, kl,
                        dotau, doie, dots, icdet)
        if (dotau == 1) {
            bt = select(BOOT[., 1], BOOT[., 1] :!= .)
            if (rows(bt) > 0) {
                tcv = lsr_quant(sort(bt, 1), level / 100)
                tp  = sum(bt :>= tau) / rows(bt)
            }
        }
        if (doie == 1) {
            bi = select(BOOT[., 2], BOOT[., 2] :!= .)
            if (rows(bi) > 0) {
                icv = lsr_quant(sort(bi, 1), level / 100)
                ip  = sum(bi :>= tauie) / rows(bi)
            }
        }
    }
    else {
        if (dotau == 1) tcv = lsr_cvget(det, 1, level, T)
        if (doie  == 1) icv = lsr_cvget(det, 2, level, T)
    }

    // ---- volatility profile (graph Panel D)
    lsr_adf(yd, p, dy = ., X = .)
    b  = invsym(quadcross(X, X)) * quadcross(X, dy)
    e  = dy - X * b
    sh = sqrt(lsr_npve(e, h))
    VOL = ((1::rows(sh)) :/ rows(sh)), sh

    // ---- hand back
    st_matrix(rRES, (tau, tauie, st[3], st[4], st[5], p, q, tcv, icv,
                     tp, ip, rows(dy), kl, st[6], st[7]))
    if (rows(BOOT) > 0) st_matrix(rBOOT, BOOT)
    if (rows(PATH) > 0) st_matrix(rPATH, PATH)
    st_matrix(rVOL, VOL)
}
end

* ---------------------------------------------------------------------
* Compile into the library llassour.mlib
* ---------------------------------------------------------------------
capture mata: mata mlib index
mata: mata mlib create llassour, dir(PLUS) replace
mata: mata mlib add llassour lsr_*(), dir(PLUS)
mata: mata mlib index
di as result "llassour.mlib built."
mata: mata describe using llassour
