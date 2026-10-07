*! jointdiag_mata.do 1.0.0  06oct2026
*! Mata engine for the jointdiag package.
*! Author: Merwan Roudane  (merwanroudane920@gmail.com)
*
*  Build the library with:   do jointdiag_mata.do
*  which creates ljointdiag.mlib in the current directory.
*
*  Every Mata function lives here, in ONE place.  A Mata function compiled
*  inside an ado-file is only available once that file has been executed,
*  and Stata executes an ado-file only when the command matching its name
*  is called.  A .mlib is auto-loaded from the adopath, so the functions
*  are always available to every subcommand.

version 14.0
mata:
mata set matastrict off
mata set matalnum on

// ===== from jointdiag.ado =====
mata set matalnum on

// ---------------------------------------------------------------
// jd_ols : plain OLS with a generalised inverse fallback.
//   returns b; passes back residuals and (X'X)^-1 by reference.
// ---------------------------------------------------------------
real colvector jd_ols(real matrix X, real colvector y,
                      real colvector e, real matrix XXi)
{
    real matrix XX
    real colvector b

    XX  = quadcross(X, X)
    XXi = invsym(XX)
    b   = XXi * quadcross(X, y)
    e   = y - X * b
    return(b)
}

// ---------------------------------------------------------------
// jd_nR2 : uncentred n*R^2 from regressing a vector of ones on G.
//   This is the Chesher (1983, EL 13) / Lancaster (1984) form of
//   any LM / IM statistic written as a score outer product.
// ---------------------------------------------------------------
real scalar jd_nR2(real matrix G)
{
    real scalar n, R2
    real colvector one, fit, e
    real matrix Gi

    n   = rows(G)
    one = J(n, 1, 1)
    Gi  = invsym(quadcross(G, G))
    fit = G * (Gi * quadcross(G, one))
    e   = one - fit
    R2  = n - quadcross(e, e)
    return(R2)
}

// ---------------------------------------------------------------
// jd_lmhet : Breusch-Pagan (1979) LM for heteroskedasticity.
//   f_i = u_i^2 / mu2 - 1 ;  LM_H = 0.5 f'Z(Z'M1 Z)^-1 Z'f
//   Bera & Jarque (1982) eq.(4) second term.
//   studentise=1 -> Koenker (1981): divide by n^-1 sum (u^2-mu2)^2 / mu2^2
//                   instead of the factor 2 (= Godfrey-Wickens correction)
// ---------------------------------------------------------------
real scalar jd_lmhet(real colvector u, real matrix Z, real scalar studentise)
{
    real scalar n, mu2, lm, kap
    real colvector f, zb
    real matrix Zc, M

    n   = rows(u)
    mu2 = quadcross(u, u) / n
    f   = (u :* u) :/ mu2 :- 1

    // Z in deviations from its mean  (= M1 Z with M1 = I - 1(1'1)^-1 1')
    Zc = Z :- (J(n, 1, 1) * (colsum(Z) :/ n))

    M  = invsym(quadcross(Zc, Zc))
    zb = quadcross(Zc, f)
    lm = 0.5 * (zb' * M * zb)

    if (studentise == 1) {
        // Koenker: replace 2*mu2^2 by the empirical 4th-moment scale
        kap = quadcross((u:*u) :- mu2, (u:*u) :- mu2) / n
        lm  = lm * (2 * mu2 * mu2) / kap
    }
    return(lm)
}

// ---------------------------------------------------------------
// jd_lmnorm : Jarque & Bera (1980 EL; 1987 ISR) normality LM.
//   LM_N = n [ b1/6 + (b2-3)^2/24 ],  b1 = (mu3/mu2^1.5)^2
//   dfadj=1 uses n-k instead of n in the moment denominators.
// ---------------------------------------------------------------
real scalar jd_lmnorm(real colvector u, real scalar nk, real scalar dfadj,
                      real scalar sk, real scalar ku)
{
    real scalar n, d, m2, m3, m4

    n = rows(u)
    d = n
    if (dfadj == 1) d = nk

    m2 = quadcross(u, u) / d
    m3 = quadsum(u :^ 3) / d
    m4 = quadsum(u :^ 4) / d

    sk = m3 / (m2 ^ 1.5)
    ku = m4 / (m2 * m2)

    return(n * (sk * sk / 6 + (ku - 3) ^ 2 / 24))
}

// ---------------------------------------------------------------
// jd_lmser : Breusch (1978) / Godfrey (1978b) serial-correlation LM.
//   Bera & Jarque (1982) eq.(4) third term, n * r'r with
//   r_j = sum_t u_t u_{t-j} / sum_t u_t^2.
//   full=1 runs the Breusch-Godfrey auxiliary regression instead
//   (valid with lagged dependent variables).
// ---------------------------------------------------------------
real scalar jd_lmser(real colvector u, real matrix X, real scalar p,
                     real scalar full)
{
    real scalar n, j, t, ss, lm, r
    real matrix L, XL
    real colvector uu, e2
    real matrix dum

    n  = rows(u)
    ss = quadcross(u, u)

    if (full == 0) {
        lm = 0
        for (j = 1; j <= p; j++) {
            r = 0
            for (t = j + 1; t <= n; t++) {
                r = r + u[t] * u[t - j]
            }
            r  = r / ss
            lm = lm + n * r * r
        }
        return(lm)
    }

    // Breusch-Godfrey auxiliary regression: u on X and p lags of u
    L = J(n, p, 0)
    for (j = 1; j <= p; j++) {
        for (t = j + 1; t <= n; t++) {
            L[t, j] = u[t - j]
        }
    }
    XL = (X, L)
    uu = J(n, 1, 0)
    dum = J(0, 0, .)
    (void) jd_ols(XL, u, uu, dum)
    e2 = uu
    lm = n * (1 - quadcross(e2, e2) / ss)
    return(lm)
}

// ---------------------------------------------------------------
// jd_lmfunc : functional-form / omitted-variable LM.
//   Bera & Jarque (1982) footnote 3 reduced form:
//     LM_F = u'W (W' M_D W)^-1 W' u / mu2        (Engle 1979)
//   W = the added regressors (RESET powers, Thursby-Schmidt, or user).
// ---------------------------------------------------------------
real scalar jd_lmfunc(real colvector u, real matrix X, real matrix W)
{
    real scalar n, mu2, lm
    real matrix MW, A
    real colvector wb, r
    real matrix XXi
    real colvector tmp

    n   = rows(u)
    mu2 = quadcross(u, u) / n

    // M_X W  : residualise W on X
    XXi = invsym(quadcross(X, X))
    MW  = W - X * (XXi * quadcross(X, W))

    A  = invsym(quadcross(MW, MW))
    wb = quadcross(MW, u)
    lm = (wb' * A * wb) / mu2
    return(lm)
}

// ---------------------------------------------------------------
// jd_resetpow : build RESET / Thursby-Schmidt power regressors.
//   kind = 1 : powers 2..d of the fitted values (Ramsey 1969)
//   kind = 2 : powers 2..d of each regressor    (Thursby-Schmidt 1977;
//              this is what Ghali & Snow (1987) eq.(27) uses)
//   Columns are residualised later by jd_lmfunc.
// ---------------------------------------------------------------
real matrix jd_resetpow(real matrix X, real colvector yhat,
                        real scalar kind, real scalar d)
{
    real scalar j, c, k
    real matrix W
    real colvector v

    if (kind == 1) {
        W = J(rows(yhat), 0, .)
        for (j = 2; j <= d; j++) {
            W = (W, yhat :^ j)
        }
        return(W)
    }

    k = cols(X)
    W = J(rows(X), 0, .)
    for (c = 1; c <= k; c++) {
        v = X[., c]
        // skip a constant column
        if (max(v) - min(v) > 1e-10) {
            for (j = 2; j <= d; j++) {
                W = (W, v :^ j)
            }
        }
    }
    return(W)
}

// ---------------------------------------------------------------
// jd_archlm : Engle (1982) LM test for ARCH(q) on a residual vector.
//   Also = component T2 of Bera & Lee (1993) when phi = 0 and the
//   covariance matrix of the random AR coefficients is diagonal.
// ---------------------------------------------------------------
real scalar jd_archlm(real colvector u, real scalar q)
{
    real scalar n, j, t, s2, lm
    real matrix Z
    real colvector u2, e
    real matrix dum

    n  = rows(u)
    u2 = u :* u
    s2 = mean(u2)

    Z = J(n, q + 1, 0)
    Z[., 1] = J(n, 1, 1)
    for (j = 1; j <= q; j++) {
        for (t = j + 1; t <= n; t++) {
            Z[t, j + 1] = u2[t - j]
        }
    }

    e = J(n, 1, 0)
    dum = J(0, 0, .)
    (void) jd_ols(Z[(q + 1)::n, .], u2[(q + 1)::n], e, dum)

    lm = (n - q) * (1 - quadcross(e, e) /
         quadcross(u2[(q+1)::n] :- mean(u2[(q+1)::n]),
                   u2[(q+1)::n] :- mean(u2[(q+1)::n])))
    return(lm)
}

// ---------------------------------------------------------------
// jd_aarchlm : Bera & Lee (1993) sec.3 / Bera, Higgins & Lee (1992)
//   augmented ARCH.  Regress u^2 on a constant, the q lagged squares
//   AND the q(q-1)/2 distinct cross-products of lagged residuals.
//   Returns n*R^2 ~ chi2( q + q(q-1)/2 ).
// ---------------------------------------------------------------
real scalar jd_aarchlm(real colvector u, real scalar q, real scalar df)
{
    real scalar n, i, j, t, lm, m, c
    real matrix Z
    real colvector u2, e, y
    real matrix dum

    n  = rows(u)
    u2 = u :* u

    m = q + q * (q - 1) / 2
    Z = J(n, m + 1, 0)
    Z[., 1] = J(n, 1, 1)

    // lagged squares
    for (j = 1; j <= q; j++) {
        for (t = j + 1; t <= n; t++) {
            Z[t, j + 1] = u2[t - j]
        }
    }
    // distinct cross-products  u_{t-i} u_{t-j}, i<j
    c = q + 1
    for (i = 1; i <= q - 1; i++) {
        for (j = i + 1; j <= q; j++) {
            c = c + 1
            for (t = j + 1; t <= n; t++) {
                Z[t, c] = u[t - i] * u[t - j]
            }
        }
    }

    y = u2[(q + 1)::n]
    e = J(rows(y), 1, 0)
    dum = J(0, 0, .)
    (void) jd_ols(Z[(q + 1)::n, .], y, e, dum)

    lm = (n - q) * (1 - quadcross(e, e) /
         quadcross(y :- mean(y), y :- mean(y)))
    df = m
    return(lm)
}

// ---------------------------------------------------------------
// jd_wphi : Bera, Higgins & Lee (1992) sec.2 stationarity weight.
//   For an AR(p) + ARCH(p) process the second-order stationarity
//   condition is  w(phi) * sum_j gamma_j < 1, where w(phi) is the
//   last element of the last column of (I - M (x) M)^-1 with M the
//   companion matrix of phi (Proposition 1(b), Andel 1976).
// ---------------------------------------------------------------
real scalar jd_wphi(real colvector phi)
{
    real scalar p, p2
    real matrix M, K, A, Ai
    real colvector a

    p = rows(phi)
    M = J(p, p, 0)
    M[1, .] = phi'
    if (p > 1) {
        M[|2, 1 \ p, p - 1|] = I(p - 1)
    }

    p2 = p * p
    K  = M # M
    A  = I(p2) - K
    Ai = invsym(A)
    a  = Ai[., p2]          // last column
    return(a[p2])           // the (p^2,p^2) element = w(phi)
}

// ---------------------------------------------------------------
// jd_compmax : max modulus of the eigenvalues of the AR companion
//   matrix (stationarity part (a) of Proposition 1).
// ---------------------------------------------------------------
real scalar jd_compmax(real colvector phi)
{
    real scalar p
    real matrix M
    complex colvector ev

    p = rows(phi)
    M = J(p, p, 0)
    M[1, .] = phi'
    if (p > 1) {
        M[|2, 1 \ p, p - 1|] = I(p - 1)
    }
    ev = eigenvalues(M)'
    return(max(abs(ev)))
}

// ---------------------------------------------------------------
// jd_acf : lag-l autocorrelation of a (centred) series
// ---------------------------------------------------------------
real colvector jd_acf(real colvector z, real scalar m, real scalar centre)
{
    real scalar n, l, t, s, d
    real colvector x, r

    n = rows(z)
    x = z
    if (centre == 1) x = z :- mean(z)

    d = quadcross(x, x)
    r = J(m, 1, 0)
    for (l = 1; l <= m; l++) {
        s = 0
        for (t = l + 1; t <= n; t++) {
            s = s + x[t] * x[t - l]
        }
        r[l] = s / d
    }
    return(r)
}

// ---------------------------------------------------------------
// jd_ccf : lag-l cross-correlation between two centred series,
//   r^{(1,2)}(l) = n^-1 sum_t a_t b_{t-l} / sqrt(c_aa(0) c_bb(0))
//   Mahdi (2024) eq.(3.1).
// ---------------------------------------------------------------
real colvector jd_ccf(real colvector a, real colvector b, real scalar m)
{
    real scalar n, l, t, s, da, db
    real colvector x, y, r

    n = rows(a)
    x = a :- mean(a)
    y = b :- mean(b)
    da = quadcross(x, x) / n
    db = quadcross(y, y) / n

    r = J(m, 1, 0)
    for (l = 1; l <= m; l++) {
        s = 0
        for (t = l + 1; t <= n; t++) {
            s = s + x[t] * y[t - l]
        }
        r[l] = (s / n) / sqrt(da * db)
    }
    return(r)
}


// ===== from jointdiag_lm.ado =====

// ---------------------------------------------------------------
// _jd_lm_core : compute the four LM components and pack them into
//   a 6x2 Stata matrix.
//     row1 = (LM_N, df) ; row2 = (LM_H, df) ; row3 = (LM_I, df)
//     row4 = (LM_F, df) ; row5 = (skew, kurt) ; row6 = (n, .)
// ---------------------------------------------------------------
void _jd_lm_core(string scalar dv, string scalar iv, string scalar zv,
                 string scalar fv, string scalar touse,
                 string scalar resv, string scalar yhv,
                 real scalar p, real scalar d,
                 real scalar tspow, real scalar stud,
                 real scalar dfadj, real scalar fullbg,
                 string scalar outname)
{
    real matrix X, Z, W, B
    real colvector y, u, yh
    real scalar n, k, lmN, lmH, lmI, lmF, sk, ku
    real scalar q, r

    y  = st_data(., dv, touse)
    n  = rows(y)

    if (strtrim(iv) != "") {
        X = st_data(., tokens(iv), touse)
    }
    else {
        X = J(n, 0, .)
    }
    X = (X, J(n, 1, 1))
    k = cols(X)

    u  = st_data(., resv, touse)
    yh = st_data(., yhv,  touse)

    // ---- LM_N : Jarque-Bera
    sk = 0
    ku = 0
    lmN = jd_lmnorm(u, n - k, dfadj, sk, ku)

    // ---- LM_H : Breusch-Pagan (studentised if asked)
    if (strtrim(zv) != "") {
        Z = st_data(., tokens(zv), touse)
    }
    else {
        Z = yh
    }
    q   = cols(Z)
    lmH = jd_lmhet(u, Z, stud)

    // ---- LM_I : Breusch(1978)/Godfrey(1978)
    lmI = jd_lmser(u, X, p, fullbg)

    // ---- LM_F : Engle (1979) / RESET
    if (strtrim(fv) != "") {
        W = st_data(., tokens(fv), touse)
    }
    else {
        if (tspow == 1) {
            W = jd_resetpow(X, yh, 2, d)
        }
        else {
            W = jd_resetpow(X, yh, 1, d)
        }
    }
    r   = cols(W)
    lmF = jd_lmfunc(u, X, W)

    B = J(6, 2, .)
    B[1, 1] = lmN ; B[1, 2] = 2
    B[2, 1] = lmH ; B[2, 2] = q
    B[3, 1] = lmI ; B[3, 2] = p
    B[4, 1] = lmF ; B[4, 2] = r
    B[5, 1] = sk  ; B[5, 2] = ku
    B[6, 1] = n   ; B[6, 2] = k

    st_matrix(outname, B)
}

// ---------------------------------------------------------------
// _jd_lm_sim : finite-sample critical values for the MCP.
//   Bera & Jarque (1982) sec.5 steps (i)-(iii): generate N(0,1)
//   errors on the SAME design matrix, recompute the four statistics,
//   take the (1-alpha_j) empirical quantile of each.
//   The statistics are scale invariant, so sigma = 1 is WLOG
//   (their footnote 12).
// ---------------------------------------------------------------
void _jd_lm_sim(string scalar dv, string scalar iv, string scalar zv,
                string scalar fv, string scalar touse,
                real scalar p, real scalar d,
                real scalar tspow, real scalar stud, real scalar dfadj,
                real scalar fullbg, real scalar reps, real scalar aj,
                string scalar outname)
{
    real matrix X, Z, W, S, XXi, Wfix
    real colvector ys, us, yhs, srt
    real scalar n, k, i, q, r, sk, ku, pos
    real colvector b
    real matrix CV

    if (strtrim(iv) != "") {
        X = st_data(., tokens(iv), touse)
    }
    else {
        X = st_data(., dv, touse) :* 0
        X = J(rows(X), 0, .)
    }
    n = rows(st_data(., dv, touse))
    X = (X, J(n, 1, 1))
    k = cols(X)

    if (strtrim(zv) != "") {
        Z = st_data(., tokens(zv), touse)
    }
    else {
        Z = J(n, 0, .)
    }
    Wfix = J(n, 0, .)
    if (strtrim(fv) != "") {
        Wfix = st_data(., tokens(fv), touse)
    }

    S   = J(reps, 4, .)
    XXi = invsym(quadcross(X, X))

    for (i = 1; i <= reps; i++) {
        ys  = rnormal(n, 1, 0, 1)
        b   = XXi * quadcross(X, ys)
        us  = ys - X * b
        yhs = X * b

        sk = 0
        ku = 0
        S[i, 1] = jd_lmnorm(us, n - k, dfadj, sk, ku)

        if (cols(Z) > 0) {
            S[i, 2] = jd_lmhet(us, Z, stud)
        }
        else {
            S[i, 2] = jd_lmhet(us, yhs, stud)
        }

        S[i, 3] = jd_lmser(us, X, p, fullbg)

        if (cols(Wfix) > 0) {
            W = Wfix
        }
        else {
            if (tspow == 1) {
                W = jd_resetpow(X, yhs, 2, d)
            }
            else {
                W = jd_resetpow(X, yhs, 1, d)
            }
        }
        S[i, 4] = jd_lmfunc(us, X, W)
    }

    CV  = J(4, 1, .)
    pos = ceil(reps * (1 - aj))
    if (pos < 1)    pos = 1
    if (pos > reps) pos = reps
    for (i = 1; i <= 4; i++) {
        srt = sort(S[., i], 1)
        CV[i, 1] = srt[pos]
    }
    st_matrix(outname, CV)
}


// ===== from jointdiag_im.ado =====

// ---------------------------------------------------------------
// jd_imblock : Chesher (1983) n*R^2 for one block of the indicator
//   vector, conditioning on the full score.  Equivalent to the
//   quadratic form d_b' [V_b]^-1 d_b because V(d) is block diagonal.
// ---------------------------------------------------------------
// ---------------------------------------------------------------
// jd_qform : Hall (1987) block statistic.
//   T = [sum_t g_t m_t']' [ sum_t m_t m_t' ]^-1 [sum_t g_t m_t'] / c
//   where g_t is the scalar "moment" (u^2 - s2, u^3, ...), m_t the
//   conditioning vector (centred), and c the normalising constant
//   from the fourth / sixth moment of a normal (2 s2^2, 6 s2^3, ...).
//   Degrees of freedom = rank of sum m m'.
//   This is the SAME algebra Stata uses for -estat imtest-, so the
//   two agree numerically; see the Remarks in the help file.
// ---------------------------------------------------------------
real scalar jd_qform(real colvector g, real matrix M, real scalar cnorm,
                     real scalar df)
{
    real scalar n, T
    real colvector one, s, gc
    real matrix Mc, A

    df = 0
    if (cols(M) == 0) return(.)

    n   = rows(g)
    one = J(n, 1, 1)
    Mc  = M :- (one * (colsum(M) :/ n))
    gc  = g :- mean(g)

    A  = invsym(quadcross(Mc, Mc))
    df = rank(quadcross(Mc, Mc))
    if (df <= 0) return(.)

    s = quadcross(Mc, gc)
    T = (s' * A * s) / cnorm
    return(T)
}

// ---------------------------------------------------------------
// jd_prod : all distinct products z_i z_j (i <= j) plus the levels
//   z_i, i.e. the "psi_t" vector of Hall (1987) obtained from
//   vech(x_t x_t') when x_t contains a constant.  These are exactly
//   White's (1980) auxiliary regressors.
// ---------------------------------------------------------------
// ---------------------------------------------------------------
// jd_auxnR2 : n * R^2 (centred) from regressing g on a constant and
//   the columns of M.  This is the "constructive" form every one of
//   Engle (1982), Breusch-Pagan (1979) and White (1980) uses, and the
//   form Stata's estat commands report.
// ---------------------------------------------------------------
real scalar jd_auxnR2(real colvector g, real matrix M, real scalar df)
{
    real scalar n, tss, rss
    real colvector e, gc
    real matrix A, XXi

    df = 0
    if (cols(M) == 0) return(.)

    n   = rows(g)
    A   = (M, J(n, 1, 1))
    df  = rank(quadcross(M :- (J(n,1,1) * (colsum(M) :/ n)),
                         M :- (J(n,1,1) * (colsum(M) :/ n))))
    if (df <= 0) return(.)

    e   = J(n, 1, 0)
    XXi = J(0, 0, .)
    (void) jd_ols(A, g, e, XXi)

    gc  = g :- mean(g)
    tss = quadcross(gc, gc)
    rss = quadcross(e, e)
    if (tss <= 0) return(.)
    return(n * (1 - rss / tss))
}

real matrix jd_prod(real matrix Z)
{
    real scalar k, i, j
    real matrix P

    k = cols(Z)
    P = Z
    for (i = 1; i <= k; i++) {
        for (j = i; j <= k; j++) {
            P = (P, Z[., i] :* Z[., j])
        }
    }
    return(P)
}

// ---------------------------------------------------------------
// _jd_im_core
//   Builds the score matrix and the six indicator blocks of
//   Bera & Lee (1993) eq.(5), then returns a 7x3 matrix:
//     rows 1..6 = (T_i, df_i, .)   row 7 = (., ., n)
// ---------------------------------------------------------------
void _jd_im_core(string scalar dv, string scalar iv, string scalar touse,
                 string scalar resv, real scalar p, real scalar q,
                 real scalar aarch, real scalar stud, string scalar outname)
{
    real matrix X, Z, S, D1, D2, D3, D4, D5, D6, E, XL, B
    real colvector u, u2, u3, u4, one, w, gk
    real scalar n, k, kz, s2, i, j, t, vk, vs, L
    real scalar T1, T2, T3, T4, T5, T6
    real scalar f1, f2, f3, f4, f5, f6

    u  = st_data(., resv, touse)
    n  = rows(u)
    if (strtrim(iv) != "") {
        X = st_data(., tokens(iv), touse)
    }
    else {
        X = J(n, 0, .)
    }
    k   = cols(X)
    one = J(n, 1, 1)

    s2 = quadcross(u, u) / n
    u2 = u :* u
    u3 = u2 :* u
    u4 = u2 :* u2

    // Z = the regressor matrix INCLUDING the constant.  For an AR(p)
    // null fitted by prais/arima the residual u is already the
    // innovation, so Z plays the role of the quasi-differenced
    // regressor z_t = x_t - x~_t'phi of Bera & Lee (1993).
    Z  = (X, one)
    kz = cols(Z)

    // lagged residuals matrix E (n x L), L = max(p,q)
    L = max((p, q, 1))
    E = J(n, L, 0)
    for (j = 1; j <= L; j++) {
        for (t = j + 1; t <= n; t++) {
            E[t, j] = u[t - j]
        }
    }
    // lagged regressors, needed for the extra term in d4
    XL = J(n, max((p, 1)), 0)
    if (p > 0 & k > 0) {
        for (j = 1; j <= p; j++) {
            for (t = j + 1; t <= n; t++) {
                XL[t, j] = X[t - j, 1]
            }
        }
    }

    // ---------------- score  (beta, phi, sigma2) ----------------
    //   dl/dbeta  = u z / s2
    //   dl/dphi_j = u eps_{t-j} / s2
    //   dl/ds2    = (u^2 - s2) / (2 s2^2)
    S = (u :* Z) :/ s2
    if (p > 0) {
        for (j = 1; j <= p; j++) {
            S = (S, (u :* E[., j]) :/ s2)
        }
    }
    S = (S, (u2 :- s2) :/ (2 * s2 * s2))

    // ---------------- the six block statistics ------------------
    //  Each is a Hall (1987) quadratic form: moment g_t conditioned on
    //  m_t, scaled by the Gaussian normalising constant.  Written this
    //  way every block has an exact Stata counterpart:
    //    T1 (studentised) == estat imtest / White's direct test
    //    T2              == estat archlm (Engle 1982)
    //    T3              == the kurtosis half of Jarque-Bera
    //    T5              == the skewness half of Jarque-Bera

    w  = u2 :- s2
    f1 = 0 ; f2 = 0 ; f3 = 0 ; f4 = 0 ; f5 = 0 ; f6 = 0

    // ---- T1 : static heteroskedasticity  (d1 block)
    //      g = u^2 - s2 ,  m = psi_t = {x_i , x_i x_j}
    D1 = jd_prod(X)
    if (k == 0) {
        T1 = .
    }
    else {
        T1 = jd_qform(w, D1, 2 * s2 * s2, f1)
        if (stud == 1 & T1 < .) {
            T1 = T1 * (2 * s2 * s2) / (quadcross(w, w) / n)
        }
    }

    // ---- T2 : conditional heteroskedasticity = ARCH / AARCH (d2)
    //      g = u^2 - s2 ,  m = {eps^2_{t-j}}  (+ cross products if AARCH)
    D2 = J(n, 0, .)
    if (q > 0) {
        for (j = 1; j <= q; j++) {
            D2 = (D2, E[., j] :* E[., j])
        }
        if (aarch == 1) {
            for (i = 1; i <= q - 1; i++) {
                for (j = i + 1; j <= q; j++) {
                    D2 = (D2, E[., i] :* E[., j])
                }
            }
        }
        // Engle's (1982) LM is exactly n_eff * R^2 from the auxiliary
        // regression of u^2 on a constant and the lagged squares, run
        // on t = q+1,...,n.  Written this way T2 reproduces Stata's
        // -estat archlm- to the last digit when the null model is OLS,
        // which is the numerical statement of Bera & Lee (1993) eq.(7).
        T2 = jd_auxnR2(u2[(q+1)::n], D2[(q+1)::n, .], f2)
    }
    else {
        T2 = .
        D2 = J(n, 0, .)
    }

    // ---- T3 : kurtosis     n (b2 - 3)^2 / 24
    //      stud=1 replaces the Gaussian constant 24 s2^4 by the
    //      empirical variance of (u^4 - 3 s2^2) (Hall 1987 sec.4,
    //      following Koenker 1981).  That robustified form is what
    //      Stata's -estat imtest- reports.
    T3 = n * (mean(u4) / (s2 * s2) - 3) ^ 2 / 24
    f3 = 1
    D3 = u4
    if (stud == 1) {
        gk = u4 :- 3 * s2 * s2
        vk = quadcross(gk :- mean(gk), gk :- mean(gk)) / n
        if (vk > 0) T3 = n * mean(gk) ^ 2 / vk
    }

    // ---- T4 : interaction x~_i * eps_{t-j}   (d4 block)
    D4 = J(n, 0, .)
    if (p > 0 & k > 0) {
        for (i = 1; i <= k; i++) {
            for (j = 1; j <= p; j++) {
                D4 = (D4, X[., i] :* E[., j])
            }
        }
        T4 = jd_qform(w[(p+1)::n], D4[(p+1)::n, .], 2 * s2 * s2, f4)
    }
    else {
        T4 = .
    }

    // ---- T5 : static heteroclicity / skewness   (d5 block)
    //      g = u^3 , m = x_i  (constant only  ->  n b1 / 6)
    if (k > 0) {
        T5 = jd_qform(u3, X, 6 * s2 ^ 3, f5)
        if (stud == 1 & T5 < .) {
            vs = quadcross(u3 :- mean(u3), u3 :- mean(u3)) / n
            if (vs > 0) T5 = T5 * (6 * s2 ^ 3) / vs
        }
    }
    else {
        T5 = .
    }
    //  the pure-constant (Jarque-Bera) skewness piece, reported too
    D5 = u3

    // ---- T6 : conditional heteroclicity        (d6 block)
    if (p > 0) {
        T6 = jd_qform(u3[(p+1)::n], E[(p+1)::n, .], 6 * s2 ^ 3, f6)
    }
    else {
        T6 = .
    }
    D6 = J(n, 0, .)

    B = J(8, 3, .)
    B[1,1] = T1 ; B[1,2] = f1
    B[2,1] = T2 ; B[2,2] = f2
    B[3,1] = T3 ; B[3,2] = f3
    B[4,1] = T4 ; B[4,2] = f4
    B[5,1] = T5 ; B[5,2] = f5
    B[6,1] = T6 ; B[6,2] = f6
    B[7,3] = n
    // row 8: the pure Jarque-Bera pieces, for reference
    B[8,1] = n * (mean(u3) / (s2 ^ 1.5)) ^ 2 / 6
    B[8,2] = mean(u3) / (s2 ^ 1.5)
    B[8,3] = mean(u4) / (s2 * s2)

    st_matrix(outname, B)
}


// ===== from jointdiag_arch.ado =====

// ---------------------------------------------------------------
// _jd_arch_naive : ARCH/AARCH LM and AR LM from one residual series.
//   row1 = (LM_arch, df) ; row2 = (LM_ar, df) ; row3 = (n, .)
// ---------------------------------------------------------------
void _jd_arch_naive(string scalar resv, string scalar touse,
                    real scalar p, real scalar q, real scalar aa,
                    real scalar robust, string scalar outname)
{
    real colvector u, u2
    real matrix Z, L, B
    real scalar n, i, j, t, L0, lma, lmr, fa, fr

    u  = st_data(., resv, touse)
    u  = select(u, u :< .)
    n  = rows(u)
    u2 = u :* u

    L0 = max((p, q))

    // ---- ARCH / AARCH block
    Z = J(n, 0, .)
    for (j = 1; j <= q; j++) {
        Z = (Z, jd_lagv(u2, j))
    }
    if (aa == 1) {
        for (i = 1; i <= q - 1; i++) {
            for (j = i + 1; j <= q; j++) {
                Z = (Z, jd_lagv(u, i) :* jd_lagv(u, j))
            }
        }
    }
    fa  = 0
    lma = jd_auxnR2(u2[(q+1)::n], Z[(q+1)::n, .], fa)
    if (robust == 1) {
        lma = jd_robustlm(u2[(q+1)::n] :- mean(u2[(q+1)::n]),
                          Z[(q+1)::n, .], fa)
    }

    // ---- AR block : regress u_t on its own p lags (plus constant)
    L = J(n, 0, .)
    for (j = 1; j <= p; j++) {
        L = (L, jd_lagv(u, j))
    }
    fr  = 0
    lmr = jd_auxnR2(u[(p+1)::n], L[(p+1)::n, .], fr)
    if (robust == 1) {
        lmr = jd_robustlm(u[(p+1)::n], L[(p+1)::n, .], fr)
    }

    B = J(3, 2, .)
    B[1,1] = lma ; B[1,2] = fa
    B[2,1] = lmr ; B[2,2] = fr
    B[3,1] = n
    st_matrix(outname, B)
}

// ---------------------------------------------------------------
// _jd_arch_arpart : AR LM on standardised residuals
// ---------------------------------------------------------------
void _jd_arch_arpart(string scalar gv, string scalar touse,
                     real scalar p, real scalar robust,
                     string scalar outname)
{
    real colvector g
    real matrix L, B
    real scalar n, j, lm, f

    g = st_data(., gv, touse)
    g = select(g, g :< .)
    n = rows(g)

    L = J(n, 0, .)
    for (j = 1; j <= p; j++) {
        L = (L, jd_lagv(g, j))
    }
    f  = 0
    lm = jd_auxnR2(g[(p+1)::n], L[(p+1)::n, .], f)
    if (robust == 1) {
        lm = jd_robustlm(g[(p+1)::n], L[(p+1)::n, .], f)
    }

    B = J(2, 2, .)
    B[1,1] = lm ; B[1,2] = f
    B[2,1] = n
    st_matrix(outname, B)
}

// ---------------------------------------------------------------
// _jd_arch_wphi : stationarity quantities from a string of phis
//   row1 = w(phi) ; row2 = max |eigenvalue| of the companion matrix
// ---------------------------------------------------------------
void _jd_arch_wphi(string scalar phistr, string scalar outname)
{
    real colvector phi
    real matrix B

    phi = strtoreal(tokens(phistr))'
    B = J(2, 1, .)
    if (rows(phi) > 0) {
        B[1,1] = jd_wphi(phi)
        B[2,1] = jd_compmax(phi)
    }
    st_matrix(outname, B)
}

// ---------------------------------------------------------------
// jd_lagv : lag a column vector by j, zero-filled
// ---------------------------------------------------------------
real colvector jd_lagv(real colvector v, real scalar j)
{
    real scalar n, t
    real colvector w

    n = rows(v)
    w = J(n, 1, 0)
    for (t = j + 1; t <= n; t++) {
        w[t] = v[t - j]
    }
    return(w)
}

// ---------------------------------------------------------------
// jd_robustlm : Wooldridge (1990, ET 6) robust regression-based LM.
//   Given a "residual" r_t under H0 and the test regressors M,
//   partial M on nothing (already done by the caller) and compute
//       LM = n - SSR  from regressing 1 on  r_t * M_t
//   which is robust to heteroskedasticity / misspecified variance.
// ---------------------------------------------------------------
real scalar jd_robustlm(real colvector r, real matrix M, real scalar df)
{
    real scalar n
    real matrix G
    real colvector one

    df = 0
    if (cols(M) == 0) return(.)
    n   = rows(r)
    one = J(n, 1, 1)
    // centre the test regressors, then form the products r_t * m_t
    G  = (M :- (one * (colsum(M) :/ n))) :* r
    df = rank(quadcross(G, G))
    if (df <= 0) return(.)
    return(jd_nR2(G))
}


// ===== from jointdiag_bilinear.ado =====

// ---------------------------------------------------------------
// _jd_bil_core
//   row1 = (LM_ARCH, q) ; row2 = (LM_BILIN, d) ; row3 = (n, .)
//   fform = 1 -> the Bera & Higgins (1997) eq.(3.4) artificial
//   regression with the factor-2 correction on the ARCH block.
// ---------------------------------------------------------------
void _jd_bil_core(string scalar resv, string scalar touse,
                  real scalar q, real scalar r, real scalar s,
                  real scalar fform, string scalar outname)
{
    real colvector e, e2, y
    real matrix A, Bm, Out, All
    real scalar n, s2, i, j, L, fa, fb, lma, lmb, ssr0, ssr1, ssrA, ssrB
    real colvector r0, r1
    real matrix dum

    e  = st_data(., resv, touse)
    e  = select(e, e :< .)
    n  = rows(e)
    e2 = e :* e
    s2 = quadcross(e, e) / n

    L = max((q, r, s))

    // ---- ARCH block : e_{t-i}^2 - s2 ,  i = 1..q
    A = J(n, 0, .)
    for (i = 1; i <= q; i++) {
        A = (A, jd_lagv(e2, i) :- s2)
    }

    // ---- bilinear block : e_{t-i} e_{t-j} , i = 1..r, j = 1..s, i >= j
    //      (b_ij = 0 for i < j, Saikkonen & Luukkonen 1988)
    Bm = J(n, 0, .)
    for (i = 1; i <= r; i++) {
        for (j = 1; j <= s; j++) {
            if (i >= j) {
                Bm = (Bm, jd_lagv(e, i) :* jd_lagv(e, j))
            }
        }
    }

    y = e[(L+1)::n]

    if (fform == 0) {
        // the plain LM: n R^2 of e on each block
        fa  = 0
        lma = jd_auxnR2(y, A[(L+1)::n, .], fa)
        fb  = 0
        lmb = jd_auxnR2(y, Bm[(L+1)::n, .], fb)
        // the ARCH block regresses the SQUARED residual, not the level
        fa  = 0
        lma = jd_auxnR2(e2[(L+1)::n], A[(L+1)::n, .], fa)
    }
    else {
        // Bera & Higgins (1997) eq.(3.4): one artificial regression,
        // two F tests, with the ARCH F halved.
        All = (A, Bm)[(L+1)::n, .]
        r0  = J(rows(y), 1, 0)
        dum = J(0, 0, .)
        (void) jd_ols(J(rows(y), 1, 1), y, r0, dum)
        ssr0 = quadcross(r0, r0)

        r1 = J(rows(y), 1, 0)
        (void) jd_ols((All, J(rows(y), 1, 1)), y, r1, dum)
        ssr1 = quadcross(r1, r1)

        // ARCH block only
        r1 = J(rows(y), 1, 0)
        (void) jd_ols((A[(L+1)::n, .], J(rows(y), 1, 1)), y, r1, dum)
        ssrA = quadcross(r1, r1)
        // bilinear block only
        r1 = J(rows(y), 1, 0)
        (void) jd_ols((Bm[(L+1)::n, .], J(rows(y), 1, 1)), y, r1, dum)
        ssrB = quadcross(r1, r1)

        fa = cols(A)
        fb = cols(Bm)
        // chi2 forms; the ARCH piece is divided by 2 (Godfrey-Wickens)
        lma = 0.5 * rows(y) * (ssr0 - ssrA) / ssr0
        lmb =       rows(y) * (ssr0 - ssrB) / ssr0
    }

    Out = J(3, 2, .)
    Out[1,1] = lma ; Out[1,2] = fa
    Out[2,1] = lmb ; Out[2,2] = fb
    Out[3,1] = n
    st_matrix(outname, Out)
}


// ===== from jointdiag_bc.ado =====

// ---------------------------------------------------------------
// jd_bcy : Box-Cox transform of a strictly positive vector
// ---------------------------------------------------------------
real colvector jd_bcy(real colvector y, real scalar lam)
{
    if (abs(lam) < 1e-9) return(ln(y))
    return((y :^ lam :- 1) :/ lam)
}

// ---------------------------------------------------------------
// jd_bcll : concentrated log likelihood of the general model
//   Ghali & Snow (1987) eq.(25).
//   Applies, in this order (their eq.(19)-(21)):
//     1. the Box-Cox transform to y
//     2. the Prais-Winsten AR(1) transform with rho
//     3. the heteroskedasticity weights z^(-delta/2)
//   then OLS, and adds the three Jacobian terms.
// ---------------------------------------------------------------
real scalar jd_bcll(real colvector y, real matrix X, real colvector z,
                    real scalar lam, real scalar rho, real scalar del,
                    real scalar hasz)
{
    real scalar n, t, s2, ll, c
    real colvector yl, ys, w, e, lny
    real matrix Xs
    real matrix XXi

    n   = rows(y)
    lny = ln(y)
    yl  = jd_bcy(y, lam)

    // --- AR(1) Prais-Winsten transform
    ys = J(n, 1, 0)
    Xs = J(n, cols(X), 0)
    c  = sqrt(1 - rho * rho)
    if (c <= 0) return(.)
    ys[1]    = c * yl[1]
    Xs[1, .] = c * X[1, .]
    for (t = 2; t <= n; t++) {
        ys[t]    = yl[t]   - rho * yl[t-1]
        Xs[t, .] = X[t, .] - rho * X[t-1, .]
    }

    // --- heteroskedasticity weights
    if (hasz == 1 & abs(del) > 1e-12) {
        w  = z :^ (-del / 2)
        ys = ys :* w
        Xs = Xs :* w
    }

    e   = J(n, 1, 0)
    XXi = J(0, 0, .)
    (void) jd_ols(Xs, ys, e, XXi)
    s2 = quadcross(e, e) / n
    if (s2 <= 0) return(.)

    ll = -(n / 2) * (ln(2 * pi()) + 1) - (n / 2) * ln(s2) + 0.5 * ln(1 - rho * rho) + (lam - 1) * quadsum(lny)
    if (hasz == 1 & abs(del) > 1e-12) {
        ll = ll - (del / 2) * quadsum(ln(z))
    }
    return(ll)
}

// ---------------------------------------------------------------
// jd_bcmax : maximise jd_bcll over the FREE parameters, by a coarse
//   grid followed by golden-section refinement on each coordinate
//   (the "zig-zag" of Oberhofer & Kmenta 1974 that Lahiri & Egy use).
//   freeL/freeR/freeD say which of lambda, rho, delta move.
//   Returns the log likelihood; passes the argmax back by reference.
// ---------------------------------------------------------------
real scalar jd_bcmax(real colvector y, real matrix X, real colvector z,
                     real scalar hasz,
                     real scalar freeL, real scalar freeR, real scalar freeD,
                     real scalar lam0,
                     real scalar lmin, real scalar lmax, real scalar ng,
                     real scalar lamo, real scalar rhoo, real scalar delo)
{
    real scalar best, cur, i, it, lo, hi, step, v
    real scalar L, R, D

    L = lam0
    R = 0
    D = 0
    best = jd_bcll(y, X, z, L, R, D, hasz)

    // ---- coarse grid on lambda
    if (freeL == 1) {
        step = (lmax - lmin) / (ng - 1)
        for (i = 1; i <= ng; i++) {
            v   = lmin + (i - 1) * step
            cur = jd_bcll(y, X, z, v, R, D, hasz)
            if (cur < . & cur > best) {
                best = cur
                L    = v
            }
        }
    }

    // ---- zig-zag refinement
    for (it = 1; it <= 40; it++) {
        if (freeR == 1) {
            lo = -0.98
            hi =  0.98
            R  = jd_gold(y, X, z, L, D, hasz, lo, hi, 2)
        }
        if (freeD == 1) {
            lo = -4
            hi =  6
            D  = jd_gold(y, X, z, L, R, hasz, lo, hi, 3)
        }
        if (freeL == 1) {
            lo = max((lmin, L - 0.75))
            hi = min((lmax, L + 0.75))
            L  = jd_gold(y, X, z, R, D, hasz, lo, hi, 1)
        }
        cur = jd_bcll(y, X, z, L, R, D, hasz)
        if (cur < . & abs(cur - best) < 1e-9) {
            best = cur
            break
        }
        if (cur < .) best = cur
    }

    lamo = L
    rhoo = R
    delo = D
    return(best)
}

// ---------------------------------------------------------------
// jd_gold : golden-section maximisation of jd_bcll in ONE coordinate.
//   which = 1 (lambda), 2 (rho), 3 (delta); the other two come in
//   through a and b in the natural order.
// ---------------------------------------------------------------
real scalar jd_gold(real colvector y, real matrix X, real colvector z,
                    real scalar a, real scalar b, real scalar hasz,
                    real scalar lo, real scalar hi, real scalar which)
{
    real scalar gr, c, d, fc, fd, i, aa, bb

    gr = (sqrt(5) - 1) / 2
    aa = lo
    bb = hi
    for (i = 1; i <= 60; i++) {
        c = bb - gr * (bb - aa)
        d = aa + gr * (bb - aa)
        fc = jd_bcpick(y, X, z, a, b, hasz, c, which)
        fd = jd_bcpick(y, X, z, a, b, hasz, d, which)
        if (fc >= fd) bb = d
        else          aa = c
        if (abs(bb - aa) < 1e-7) break
    }
    return((aa + bb) / 2)
}

real scalar jd_bcpick(real colvector y, real matrix X, real colvector z,
                      real scalar a, real scalar b, real scalar hasz,
                      real scalar v, real scalar which)
{
    real scalar r

    r = .
    if (which == 1) r = jd_bcll(y, X, z, v, a, b, hasz)
    if (which == 2) r = jd_bcll(y, X, z, a, v, b, hasz)
    if (which == 3) r = jd_bcll(y, X, z, a, b, v, hasz)
    if (r >= .) r = -1e100
    return(r)
}

// ---------------------------------------------------------------
// _jd_bc_core : fit the six (seven) models and build the profile.
// ---------------------------------------------------------------
void _jd_bc_core(string scalar dv, string scalar iv, string scalar wv,
                 string scalar zv, string scalar touse,
                 real scalar lam0, real scalar useR, real scalar useD,
                 real scalar useB,
                 real scalar lmin, real scalar lmax, real scalar ng,
                 string scalar outname, string scalar profname)
{
    real colvector y, z
    real matrix X, XW, B, P
    real scalar n, hasz, i, step, v
    real scalar lamU, rhoU, delU, llU
    real scalar la, ra, da, ll
    real scalar kw

    y = st_data(., dv, touse)
    n = rows(y)

    X = J(n, 0, .)
    if (strtrim(iv) != "") X = st_data(., tokens(iv), touse)
    X = (X, J(n, 1, 1))

    XW = X
    kw = 0
    if (useB == 1 & strtrim(wv) != "") {
        XW = (X, st_data(., tokens(wv), touse))
        kw = cols(XW) - cols(X)
    }

    hasz = 0
    z    = J(n, 1, 1)
    if (strtrim(zv) != "") {
        z    = st_data(., zv, touse)
        hasz = 1
    }

    B = J(8, 5, .)

    // --- 1. unrestricted
    lamU = 0 ; rhoU = 0 ; delU = 0
    llU = jd_bcmax(y, XW, z, hasz, 1, useR, useD, lam0, lmin, lmax, ng,
                   lamU, rhoU, delU)
    B[1,1] = lamU ; B[1,2] = rhoU ; B[1,3] = delU ; B[1,4] = llU

    // --- 2. lambda = lam0, others free
    la = lam0 ; ra = 0 ; da = 0
    ll = jd_bcmax(y, XW, z, hasz, 0, useR, useD, lam0, lmin, lmax, ng,
                  la, ra, da)
    B[2,1] = la ; B[2,2] = ra ; B[2,3] = da ; B[2,4] = ll

    // --- 3. rho = 0, others free
    la = lam0 ; ra = 0 ; da = 0
    ll = jd_bcmax(y, XW, z, hasz, 1, 0, useD, lam0, lmin, lmax, ng,
                  la, ra, da)
    B[3,1] = la ; B[3,2] = 0 ; B[3,3] = da ; B[3,4] = ll

    // --- 4. delta = 0, others free
    la = lam0 ; ra = 0 ; da = 0
    ll = jd_bcmax(y, XW, z, hasz, 1, useR, 0, lam0, lmin, lmax, ng,
                  la, ra, da)
    B[4,1] = la ; B[4,2] = ra ; B[4,3] = 0 ; B[4,4] = ll

    // --- 5. beta* = 0 (drop the Thursby-Schmidt columns), others free
    la = lam0 ; ra = 0 ; da = 0
    ll = jd_bcmax(y, X, z, hasz, 1, useR, useD, lam0, lmin, lmax, ng,
                  la, ra, da)
    B[5,1] = la ; B[5,2] = ra ; B[5,3] = da ; B[5,4] = ll

    // --- 6. fully restricted
    B[6,1] = lam0 ; B[6,2] = 0 ; B[6,3] = 0
    B[6,4] = jd_bcll(y, X, z, lam0, 0, 0, hasz)

    // --- 7. lambda = lam0 and rho = 0 (delta free)
    la = lam0 ; ra = 0 ; da = 0
    ll = jd_bcmax(y, XW, z, hasz, 0, 0, useD, lam0, lmin, lmax, ng,
                  la, ra, da)
    B[7,1] = lam0 ; B[7,2] = 0 ; B[7,3] = da ; B[7,4] = ll

    B[8,1] = n ; B[8,2] = cols(X) ; B[8,3] = kw

    st_matrix(outname, B)

    // --- the lambda profile for the graph (other parameters re-optimised)
    P    = J(ng, 2, .)
    step = (lmax - lmin) / (ng - 1)
    for (i = 1; i <= ng; i++) {
        v  = lmin + (i - 1) * step
        la = v ; ra = 0 ; da = 0
        ll = jd_bcmax(y, XW, z, hasz, 0, useR, useD, v, lmin, lmax, ng,
                      la, ra, da)
        P[i, 1] = v
        P[i, 2] = ll
    }
    st_matrix(profname, P)
}

// ---------------------------------------------------------------
// _jd_bc_lm : Tse (1984) / Yang & Tse (2008) LM tests, evaluated at
//   the restricted MLE so no unrestricted fit is needed.
//   row1 = (LM_lambda, 1) ; row2 = (LM_joint, df)
//
//   Tse eq.(10): the score w.r.t. lambda is  c = sum ln y_t + <OLS part>
//   and the LM statistic is the square of the standardised score.
//   We build it from the artificial regression of the restricted
//   residual on the model regressors AND the extra column
//        w_t = f(y_t)  -  sum_j f(x_jt) b_j
//   of Tse's eq.(9), which is the derivative of the transformation.
// ---------------------------------------------------------------
void _jd_bc_lm(string scalar dv, string scalar iv, string scalar zv,
               string scalar touse, real scalar lam0,
               real scalar useR, real scalar useD, real scalar stud,
               string scalar outname)
{
    real colvector y, u, w, lny, yl, e, g, zz
    real matrix X, A, B, M
    real scalar n, s2, lmL, lmJ, dfJ, kap
    real matrix XXi

    y   = st_data(., dv, touse)
    n   = rows(y)
    lny = ln(y)

    X = J(n, 0, .)
    if (strtrim(iv) != "") X = st_data(., tokens(iv), touse)
    X = (X, J(n, 1, 1))

    yl  = jd_bcy(y, lam0)
    e   = J(n, 1, 0)
    XXi = J(0, 0, .)
    (void) jd_ols(X, yl, e, XXi)
    u  = e
    s2 = quadcross(u, u) / n

    // derivative of the Box-Cox transform w.r.t. lambda at lam0
    //   d y^(lam)/d lam = [ lam y^lam ln y - (y^lam - 1) ] / lam^2
    //   at lam = 0 it is (ln y)^2 / 2
    if (abs(lam0) < 1e-9) {
        w = (lny :^ 2) :/ 2
    }
    else {
        w = (lam0 :* (y :^ lam0) :* lny :- (y :^ lam0 :- 1)) :/ (lam0 ^ 2)
    }

    // LM for lambda alone: add w to the regression of u on X
    A   = (X, w)
    lmL = jd_auxnR2_sc(u, A, X, s2)

    // joint LM: add w, the lagged residual (rho) and the z-score (delta)
    M = (X, w)
    dfJ = 1
    if (useR == 1) {
        M   = (M, jd_lagv(u, 1))
        dfJ = dfJ + 1
    }
    if (useD == 1 & strtrim(zv) != "") {
        zz  = ln(st_data(., zv, touse))
        g   = ((u :* u) :/ s2 :- 1) :* zz
        M   = (M, g)
        dfJ = dfJ + 1
    }
    lmJ = jd_auxnR2_sc(u, M, X, s2)

    if (stud == 1) {
        kap = quadcross((u:*u) :- s2, (u:*u) :- s2) / n
        if (kap > 0) {
            lmL = lmL * (2 * s2 * s2) / kap
            lmJ = lmJ * (2 * s2 * s2) / kap
        }
    }

    B = J(2, 2, .)
    B[1,1] = lmL ; B[1,2] = 1
    B[2,1] = lmJ ; B[2,2] = dfJ
    st_matrix(outname, B)
}

// ---------------------------------------------------------------
// jd_auxnR2_sc : score-type LM = (ESS of u on A) - (ESS of u on X),
//   divided by s2.  Equals n R^2 of the Engle (1979) artificial
//   regression when X spans the null model.
// ---------------------------------------------------------------
real scalar jd_auxnR2_sc(real colvector u, real matrix A, real matrix X,
                         real scalar s2)
{
    real colvector e1, e0
    real matrix d1, d0

    e1 = J(rows(u), 1, 0)
    e0 = J(rows(u), 1, 0)
    d1 = J(0, 0, .)
    d0 = J(0, 0, .)
    (void) jd_ols(A, u, e1, d1)
    (void) jd_ols(X, u, e0, d0)
    return((quadcross(e0, e0) - quadcross(e1, e1)) / s2)
}


// ===== from jointdiag_score.ado =====

// ---------------------------------------------------------------
// _jd_score_core
//   row1 = (S1, 1)    Tsai's autocorrelation component
//   row2 = (S2, q)    Tsai's variance component
//   row3 = (SCa, 1)   Liu-Wei-Wang bilinearity
//   row4 = (SCb, p+1) Liu-Wei-Wang correlation + bilinearity
//   row5 = (n, rho_hat)
// ---------------------------------------------------------------
void _jd_score_core(string scalar resv, string scalar zv, string scalar touse,
                    real scalar p, real scalar bil, real scalar uselog,
                    string scalar outname)
{
    real colvector e, V, one, bv, ub
    real matrix D, Dc, B, Z, M, Ldum
    real scalar n, s2, rho, S1, S2, SCa, SCb, q, j, t, num, den, f

    e  = st_data(., resv, touse)
    e  = select(e, e :< .)
    n  = rows(e)
    s2 = quadcross(e, e) / n

    // ---- Tsai eq.(2-5) : rho_hat = sum' e_t e_{t-1} / sum e_t^2
    num = 0
    for (t = 2; t <= n; t++) {
        num = num + e[t] * e[t-1]
    }
    den = quadcross(e, e)
    rho = num / den

    // ---- S1 = (T rho_hat)^2 / (T - 1)
    S1 = (n * rho) ^ 2 / (n - 1)

    // ---- S2 = 0.5 V' Dbar (Dbar'Dbar)^-1 Dbar' V,  V_t = e_t^2 / s2
    Z = st_data(., tokens(zv), touse)
    Z = Z[(1::n), .]
    D = Z
    if (uselog == 1) {
        // w(z,lambda) = exp(z'lambda)  ->  D = z ; log form keeps z as is
        D = Z
    }
    one = J(n, 1, 1)
    Dc  = D :- (one * (colsum(D) :/ n))
    V   = (e :* e) :/ s2
    q   = cols(Dc)

    M  = invsym(quadcross(Dc, Dc))
    bv = quadcross(Dc, V)
    S2 = 0.5 * (bv' * M * bv)

    // ---- Liu, Wei & Wang (2003) score tests
    //   SCa : the bilinear term  u_{t-1} e_{t-1}
    //         score  = (1/s2) sum_t e_t e_{t-1} u_{t-1}
    //         under H0 u = e, so this is sum e_t e_{t-1}^2
    SCa = .
    SCb = .
    if (bil == 1) {
        B = J(n, 0, .)
        for (j = 1; j <= p; j++) {
            B = (B, jd_lagv(e, j))
        }
        // the bilinear regressor
        bv = jd_lagv(e, 1) :* jd_lagv(e, 1)
        f  = 0
        SCa = jd_auxnR2(e[(p+1)::n], bv[(p+1)::n], f)
        // SCb : phi = 0 AND psi = 0 jointly
        f   = 0
        SCb = jd_auxnR2(e[(p+1)::n], (B, bv)[(p+1)::n, .], f)
    }

    Ldum = J(5, 2, .)
    Ldum[1,1] = S1  ; Ldum[1,2] = 1
    Ldum[2,1] = S2  ; Ldum[2,2] = q
    Ldum[3,1] = SCa ; Ldum[3,2] = 1
    Ldum[4,1] = SCb ; Ldum[4,2] = p + 1
    Ldum[5,1] = n   ; Ldum[5,2] = rho

    st_matrix(outname, Ldum)
}


// ===== from jointdiag_port.ado =====

// ---------------------------------------------------------------
// _jd_port_rho : stack the M mean autocorrelations of g and the M
//   autocorrelations of g^2 into a (2M x 1) Stata matrix.
// ---------------------------------------------------------------
void _jd_port_rho(string scalar gv, string scalar touse, real scalar M,
                  string scalar outname)
{
    real colvector g, g2, rho, r

    g  = st_data(., gv, touse)
    g  = select(g, g :< .)
    g2 = g :* g

    rho = jd_acf(g,  M, 1)
    r   = jd_acf(g2, M, 1)
    st_matrix(outname, (rho \ r))
}

// ---------------------------------------------------------------
// jd_vwtransform : Velasco & Wang (2015) sec.2 recursive projection.
//   Qt  : (2m x 1) standardised autocorrelation pairs stacked as
//         (rho_1, r_1, rho_2, r_2, ...) -> handled as m pairs
//   Cd  : (2m x k) derivative blocks, pair i occupying rows 2i-1, 2i
//   Returns the (2(m-k)) x 1 vector of transformed pairs.
// ---------------------------------------------------------------
real colvector jd_vwtransform(real matrix Qp, real matrix Cd, real scalar k)
{
    real scalar m, i, j, nk
    real matrix A, Ai, Ci, Lam, S, Sv
    real colvector out, q, qq
    real matrix Ei

    m  = rows(Qp)
    nk = m - k
    if (nk < 1) return(J(0, 1, .))

    out = J(0, 1, .)
    for (i = 1; i <= nk; i++) {
        // A = sum_{j>i} Cd(j)' Cd(j)
        A = J(cols(Cd), cols(Cd), 0)
        S = J(cols(Cd), 1, 0)
        for (j = i + 1; j <= m; j++) {
            Ci = (Cd[(2*j-1)::(2*j), .])'          // k x 2
            A  = A + Ci * Ci'
            S  = S + Ci * (Qp[j, .])'              // k x 1
        }
        Ai = invsym(A)
        Ci = (Cd[(2*i-1)::(2*i), .])'              // k x 2

        q  = (Qp[i, .])' - Ci' * (Ai * S)
        // standardisation factor Lam(i) = [I2 + Ci'(A)^-1 Ci]^-1/2
        Lam = I(2) + Ci' * Ai * Ci
        Sv  = jd_invsqrt(Lam)
        qq  = Sv * q
        out = (out \ qq)
    }
    return(out)
}

// ---------------------------------------------------------------
// jd_invsqrt : symmetric inverse square root of a small PD matrix
// ---------------------------------------------------------------
real matrix jd_invsqrt(real matrix A)
{
    real matrix V, L, W
    real colvector d
    real scalar i

    symeigensystem(A, V = ., d = .)
    L = J(rows(A), rows(A), 0)
    for (i = 1; i <= rows(A); i++) {
        if (d[i] > 1e-12) L[i, i] = 1 / sqrt(d[i])
        else              L[i, i] = 0
    }
    W = V * L * V'
    return(W)
}

// ---------------------------------------------------------------
// _jd_port_core : all the statistics
// ---------------------------------------------------------------
void _jd_port_core(string scalar gv, string scalar touse,
                   real scalar M, real scalar L0, real scalar kder,
                   string scalar dername, string scalar outname)
{
    real colvector g, g2, rho, r, c12, c21, nu
    real matrix B, D, Xq, Xr, R, A, Om, Qp, Cd, V, I2
    real scalar n, l, qlb, qml, qs, q1m, qm, s2u, ku
    real scalar vwj, vwm, vwv, cc12, cc21, i, dvw
    real colvector w

    g  = st_data(., gv, touse)
    g  = select(g, g :< .)
    n  = rows(g)
    g2 = g :* g

    rho = jd_acf(g,  M, 1)
    r   = jd_acf(g2, M, 1)
    c12 = jd_ccf(g,  g2, M)
    c21 = jd_ccf(g2, g,  M)

    // ---------- marginal Ljung-Box / Li-Mak ----------
    qlb = 0
    qml = 0
    for (l = 1; l <= M; l++) {
        qlb = qlb + n * (n + 2) * rho[l] ^ 2 / (n - l)
        qml = qml + n * (n + 2) * r[l]   ^ 2 / (n - l)
    }

    // ---------- Wong & Ling (2005) eq.(12) : Q_S ----------
    qs = qlb + qml

    // ---------- Q1M : n sum_{l>=L0} rho^2 + corrected variance part
    q1m = 0
    for (l = L0; l <= M; l++) {
        q1m = q1m + n * rho[l] ^ 2
    }

    // the Li-Mak correction  I - 0.25 Xr R^-1 Xr'  needs derivatives.
    // Without them the uncorrected n*r'r is used and flagged.
    qm  = .
    vwj = .
    vwm = .
    vwv = .
    dvw = 0

    if (kder > 0) {
        D  = st_matrix(dername)              // k x 2M
        Xq = D[., 1::M]'                     // M x k   d rho / d theta
        Xr = D[., (M+1)::(2*M)]'             // M x k   d r   / d theta

        // Wong & Ling Theorem 1:  V = [ I  0  -Xq ; 0  I  -Xr/su ]
        // with the sandwich  V Omega V'.  Under conditional normality
        // Omega reduces to the identity in the first 2M block and the
        // information matrix R in the parameter block, so
        //   Var(rho) = I - Xq R^-1 Xq'
        //   Var(r)   = I - 0.25 Xr R^-1 Xr'
        //   Cov      = -0.5 Xr R^-1 Xq'
        R = quadcross(Xq, Xq) + 0.25 * quadcross(Xr, Xr)
        A = invsym(R)

        Om = J(2 * M, 2 * M, 0)
        Om[|1,1 \ M,M|]             = I(M) - Xq * A * Xq'
        Om[|M+1,M+1 \ 2*M,2*M|]     = I(M) - 0.25 * Xr * A * Xr'
        Om[|1,M+1 \ M,2*M|]         = -0.5 * Xq * A * Xr'
        Om[|M+1,1 \ 2*M,M|]         = -0.5 * Xr * A * Xq'

        w  = (rho \ r)
        qm = n * (w' * invsym(Om) * w)

        // Q1M variance part with the Li-Mak correction
        V   = I(M) - 0.25 * Xr * A * Xr'
        q1m = q1m + n * (r' * invsym(V) * r)

        // ---------- Velasco & Wang recursive transform ----------
        // stack as m pairs: row i = (rho_i, r_i)
        Qp = J(M, 2, 0)
        Cd = J(2 * M, cols(Xq), 0)
        for (i = 1; i <= M; i++) {
            Qp[i, 1] = sqrt(n) * rho[i]
            Qp[i, 2] = sqrt(n) * r[i]
            Cd[2*i-1, .] = Xq[i, .]
            Cd[2*i,   .] = Xr[i, .]
        }
        nu = jd_vwtransform(Qp, Cd, cols(Xq))
        if (rows(nu) > 0) {
            vwj = quadcross(nu, nu)
            dvw = rows(nu)
            vwm = 0
            vwv = 0
            for (i = 1; i <= rows(nu) / 2; i++) {
                vwm = vwm + nu[2*i-1] ^ 2
                vwv = vwv + nu[2*i]   ^ 2
            }
        }
    }
    else {
        q1m = q1m + n * quadcross(r, r)
    }

    // ---------- Mahdi (2024) auto-and-cross ----------
    // C_rs = n [ R11' R22' R(r,s)' ] Om_rs^-1 [ ... ]  ; under the
    // simplification Om_rs = I (no estimation effect) this is the sum
    // of three Ljung-Box-type blocks.  With derivatives available the
    // mean and variance blocks use the corrected variances above.
    cc12 = 0
    cc21 = 0
    for (l = 1; l <= M; l++) {
        cc12 = cc12 + n * (n + 2) * c12[l] ^ 2 / (n - l)
        cc21 = cc21 + n * (n + 2) * c21[l] ^ 2 / (n - l)
    }
    cc12 = qlb + qml + cc12
    cc21 = qlb + qml + cc21

    // ---------- pack ----------
    B = J(11, 2, .)
    B[1,1]  = qlb  ; B[1,2]  = M
    B[2,1]  = qml  ; B[2,2]  = M
    B[3,1]  = qs   ; B[3,2]  = 2 * M
    B[4,1]  = q1m  ; B[4,2]  = 2 * M - L0 + 1
    B[5,1]  = qm   ; B[5,2]  = 2 * M
    B[6,1]  = vwj  ; B[6,2]  = dvw
    B[7,1]  = vwm  ; B[7,2]  = dvw / 2
    B[8,1]  = vwv  ; B[8,2]  = dvw / 2
    B[9,1]  = cc12 ; B[9,2]  = 3 * M
    B[10,1] = cc21 ; B[10,2] = 3 * M
    B[11,1] = n

    st_matrix(outname, B)
}


// ===== from jointdiag_spec.ado =====

// ---------------------------------------------------------------
// _jd_spec_stat : the CvM statistics of Escanciano (2008) eq.(9)
//   for both weight families, in one pass.
//   Returns a 6 x 1 Stata matrix:
//     1 exp joint, 2 exp mean, 3 exp var,
//     4 ind joint, 5 ind mean, 6 ind var
// ---------------------------------------------------------------
void _jd_spec_stat(string scalar e1v, string scalar e2v, string scalar yv,
                   string scalar touse, string scalar wtype,
                   string scalar outname)
{
    real colvector e1, e2, y, v1, v2
    real matrix B, KE, KI, Ks
    real scalar n, j, m, nj, s1, s2, cj, cm, cv, ij, im, iv
    real scalar a1, a2, fac, J

    e1 = st_data(., e1v, touse)
    e2 = st_data(., e2v, touse)
    y  = st_data(., yv,  touse)
    n  = rows(e1)

    s1 = quadcross(e1, e1) / n
    s2 = quadcross(e2, e2) / n
    if (s1 <= 0 | s2 <= 0) {
        st_matrix(outname, J(6, 1, .))
        return
    }
    if (n > 3000) {
        // the weight matrix is n x n; refuse rather than thrash
        st_matrix(outname, J(6, 1, .))
        return
    }

    cj = . ; cm = . ; cv = . ; ij = . ; im = . ; iv = .

    // the 1/(j pi)^2 weight makes lags past ~25 contribute < 0.2 %
    J = min((n - 2, 25))

    // ---------- exponential weight : K[t,s] = exp(-.5 (y_t - y_s)^2) ----
    if (wtype == "exp" | wtype == "both") {
        KE = exp(-0.5 :* ((y * J(1, n, 1)) :- (J(n, 1, 1) * y')) :^ 2)
        cm = 0
        cv = 0
        for (j = 1; j <= J; j++) {
            m  = n - j
            if (m < 2) continue
            nj  = m + 1
            fac = 1 / (nj * (j * pi()) ^ 2)
            Ks  = KE[|1, 1 \ m, m|]
            v1  = e1[|(j + 1) \ n|]
            v2  = e2[|(j + 1) \ n|]
            a1  = v1' * (Ks * v1)
            a2  = v2' * (Ks * v2)
            cm  = cm + fac * a1 / s1
            cv  = cv + fac * a2 / s2
        }
        cj = cm + cv
    }

    // ---------- indicator weight : K[t,s] = 1(y_t <= y_s) --------------
    if (wtype == "ind" | wtype == "both") {
        KI = ((y * J(1, n, 1)) :<= (J(n, 1, 1) * y'))
        im = 0
        iv = 0
        for (j = 1; j <= J; j++) {
            m  = n - j
            if (m < 2) continue
            nj  = m + 1
            fac = 1 / (nj * (j * pi()) ^ 2)
            Ks  = KI[|1, 1 \ m, m|]
            v1  = e1[|(j + 1) \ n|]
            v2  = e2[|(j + 1) \ n|]
            a1  = v1' * (Ks * v1)
            a2  = v2' * (Ks * v2)
            im  = im + fac * a1 / s1
            iv  = iv + fac * a2 / s2
        }
        ij = im + iv
    }

    B = J(6, 1, .)
    B[1,1] = cj ; B[2,1] = cm ; B[3,1] = cv
    B[4,1] = ij ; B[5,1] = im ; B[6,1] = iv
    st_matrix(outname, B)
}

// ---------------------------------------------------------------
// _jd_spec_pv : bootstrap p-values  (proportion of replications at
//   or above the observed statistic, the usual +1/+1 correction)
// ---------------------------------------------------------------
void _jd_spec_pv(string scalar obsname, string scalar bootname,
                 string scalar outname)
{
    real matrix O, Bm, P
    real scalar i, b, c, r, nb

    O  = st_matrix(obsname)
    Bm = st_matrix(bootname)
    nb = rows(Bm)
    P  = J(6, 1, .)

    for (i = 1; i <= 6; i++) {
        if (O[i,1] >= .) continue
        c = 0
        r = 0
        for (b = 1; b <= nb; b++) {
            if (Bm[b,i] < .) {
                r = r + 1
                if (Bm[b,i] >= O[i,1]) c = c + 1
            }
        }
        if (r > 0) P[i,1] = (c + 1) / (r + 1)
    }
    st_matrix(outname, P)
}


// ===== from jointdiag_mpi.ado =====

// ---------------------------------------------------------------
// jd_imhof : Pr[ sum lambda_i chi2_1 <= q ] by Imhof (1961)
//   P = 1/2 - (1/pi) Int_0^inf sin(theta(u)) / (u rho(u)) du
//   theta(u) = 0.5 sum atan(lam_i u) - 0.5 q u
//   rho(u)   = prod (1 + lam_i^2 u^2)^(1/4)
// ---------------------------------------------------------------
real scalar jd_imhof(real colvector lam, real scalar q)
{
    real scalar U, ng, h, s, i, u, th, lrh, f, it
    real colvector l

    l = select(lam, abs(lam) :> 1e-12)
    if (rows(l) == 0) return(.)

    // ---- find an upper limit where the integrand has died.
    //  ln rho(u) = 0.25 sum ln(1 + lam_i^2 u^2) grows without bound, so
    //  1/rho(u) vanishes; integrate until ln rho > 40 (e^-40 ~ 4e-18).
    U = 1 / max(abs(l))
    for (it = 1; it <= 200; it++) {
        lrh = 0.25 * quadsum(ln(1 :+ (l :* U) :^ 2))
        if (lrh > 40) break
        U = U * 1.6
    }

    ng = 20000
    h  = U / ng
    s  = 0
    for (i = 1; i <= ng; i++) {
        u   = (i - 0.5) * h
        th  = 0.5 * quadsum(atan(l :* u)) - 0.5 * q * u
        lrh = 0.25 * quadsum(ln(1 :+ (l :* u) :^ 2))
        // work in logs: an exp() here overflows once rows(l) is large
        if (lrh > 700) {
            f = 0
        }
        else {
            f = sin(th) * exp(-lrh) / u
        }
        s = s + f * h
    }
    s = 0.5 - s / pi()
    if (s < 0) s = 0
    if (s > 1) s = 1
    return(s)
}

// ---------------------------------------------------------------
// jd_mpicrit : the r* solving Pr[ sum (v_i - r*) xi^2 < 0 ] = alpha
//   found by bisection on Imhof's probability.
// ---------------------------------------------------------------
real scalar jd_mpicrit(real colvector v, real scalar alpha)
{
    real scalar lo, hi, mid, p, i

    lo = min(v)
    hi = max(v)
    for (i = 1; i <= 80; i++) {
        mid = (lo + hi) / 2
        p   = jd_imhof(v :- mid, 0)
        if (p >= .) return(.)
        if (p > alpha) hi = mid
        else           lo = mid
        if (hi - lo < 1e-9) break
    }
    return((lo + hi) / 2)
}

// ---------------------------------------------------------------
// _jd_mpi_core
//   row1 = r statistic ; row2 = critical value ; row3 = p-value
//   row4 = n ; row5 = E[r] ; row6 = Var[r]
// ---------------------------------------------------------------
void _jd_mpi_core(string scalar dv, string scalar iv, string scalar zv,
                  string scalar touse, real scalar rho1, real scalar alpha,
                  string scalar outname)
{
    real colvector y, z, e, ys, ev, lam, dd
    real matrix X, Xs, M, Ms, Rm, K, B
    real scalar n, k, t, c, num, den, rstat, rc, pv, m, Er, Vr
    real matrix XXi
    real colvector resid

    y = st_data(., dv, touse)
    n = rows(y)
    X = J(n, 0, .)
    if (strtrim(iv) != "") X = st_data(., tokens(iv), touse)
    X = (X, J(n, 1, 1))
    k = cols(X)

    z = J(n, 1, 1)
    if (strtrim(zv) != "") z = st_data(., zv, touse)

    // ---- OLS residual, denominator
    resid = J(n, 1, 0)
    XXi   = J(0, 0, .)
    (void) jd_ols(X, y, resid, XXi)
    den = quadcross(resid, resid)

    // ---- the transformation R(rho) = D^(-1/2) G(rho)^-1
    //   row 1 : sqrt(1-rho^2)/sqrt(z_1) * y_1
    //   row t : (y_t - rho y_{t-1}) / sqrt(z_t)
    c  = sqrt(1 - rho1 * rho1)
    ys = J(n, 1, 0)
    Xs = J(n, k, 0)
    ys[1]    = c * y[1] / sqrt(z[1])
    Xs[1, .] = c * X[1, .] / sqrt(z[1])
    for (t = 2; t <= n; t++) {
        ys[t]    = (y[t]    - rho1 * y[t-1])    / sqrt(z[t])
        Xs[t, .] = (X[t, .] - rho1 * X[t-1, .]) / sqrt(z[t])
    }

    ev  = J(n, 1, 0)
    XXi = J(0, 0, .)
    (void) jd_ols(Xs, ys, ev, XXi)
    num = quadcross(ev, ev)

    rstat = num / den

    // ---- eigenvalues of K = R' M* R restricted to the OLS residual space
    //   Durbin-Watson lemma: r = sum v_i xi^2 / sum xi^2 with v_i the
    //   non-zero eigenvalues of M R' M* R M  (m = n - k of them).
    M  = I(n) - X * (invsym(quadcross(X, X)) * X')
    Rm = J(n, n, 0)
    Rm[1, 1] = c / sqrt(z[1])
    for (t = 2; t <= n; t++) {
        Rm[t, t]     =  1 / sqrt(z[t])
        Rm[t, t - 1] = -rho1 / sqrt(z[t])
    }
    Ms = I(n) - Xs * (invsym(quadcross(Xs, Xs)) * Xs')
    K  = M * (Rm' * Ms * Rm) * M

    dd  = Re(eigenvalues(K)')
    lam = sort(select(dd, dd :> 1e-9), -1)
    m   = n - k
    if (rows(lam) > m) lam = lam[1::m]

    // ---- exact critical value and p-value (Imhof)
    rc = jd_mpicrit(lam, alpha)
    pv = jd_imhof(lam :- rstat, 0)

    // ---- Henshaw (1966) moments
    Er = quadsum(lam) / m
    Vr = 2 * (m * quadsum(lam :^ 2) - quadsum(lam) ^ 2) / (m * m * (m + 2))

    B = J(6, 1, .)
    B[1,1] = rstat
    B[2,1] = rc
    B[3,1] = pv
    B[4,1] = n
    B[5,1] = Er
    B[6,1] = Vr
    st_matrix(outname, B)
}


// ===== from jointdiag_nonnest.ado =====

// ---------------------------------------------------------------
// _jd_nn_core : the auxiliary regression (6) and its three F blocks
//   row1 = (F1, df1) rho and alpha
//   row2 = (F2, df2) phi
//   row3 = (F3, df3) c1
//   row4 = (n, df_resid)
// ---------------------------------------------------------------
void _jd_nn_core(string scalar dv, string scalar iv, string scalar uv,
                 string scalar y1v, string scalar zv, string scalar touse,
                 real scalar p, real scalar doskew, string scalar outname)
{
    real colvector y, u, y1, rt, e0, e1
    real matrix X, Z, L, V, A, Bm, Out
    real scalar n, j, s2, ssr0, ssrF, ssr1, ssr2, ssr3, dfr
    real scalar F1, F2, F3, d1, d2, d3, kfull
    real matrix dum

    y  = st_data(., dv, touse)
    u  = st_data(., uv, touse)
    y1 = st_data(., y1v, touse)
    n  = rows(y)

    X = J(n, 0, .)
    if (strtrim(iv) != "") X = st_data(., tokens(iv), touse)
    X = (X, J(n, 1, 1))

    s2 = quadcross(u, u) / n

    // ---- block 1 : p lags of u0, plus the J-test regressor y1_hat
    L = J(n, 0, .)
    for (j = 1; j <= p; j++) {
        L = (L, jd_lagv(u, j))
    }
    L = (L, y1)
    d1 = cols(L)

    // ---- block 2 : (u^2/s2 - 1) * v_it
    Z  = st_data(., tokens(zv), touse)
    V  = ((u :* u) :/ s2 :- 1) :* Z
    d2 = cols(V)

    // ---- block 3 : the non-normality regressor of eq.(5)
    //   r_t = (u_t^3 - 3 s2 u_t) / (4 s2^(3/2))
    //   its score u_t r_t / s2 has asymptotic variance 21 s2^4 / 8
    //   while the OLS formula returns 3 s2^4 / 8  (factor 7).
    d3 = 0
    rt = J(n, 1, 0)
    if (doskew == 1) {
        rt = (u :^ 3 :- 3 * s2 :* u) :/ (4 * s2 ^ 1.5)
        d3 = 1
    }

    // ---- the restricted (null) regression : y on X
    e0  = J(n, 1, 0)
    dum = J(0, 0, .)
    (void) jd_ols(X, y, e0, dum)
    ssr0 = quadcross(e0, e0)

    // ---- the full auxiliary regression
    A = (X, L, V)
    if (d3 > 0) A = (A, rt)
    kfull = cols(A)
    e1 = J(n, 1, 0)
    (void) jd_ols(A, y, e1, dum)
    ssrF = quadcross(e1, e1)
    dfr  = n - kfull

    // ---- partial F for each block : drop it from the full model
    Bm = (X, V)
    if (d3 > 0) Bm = (Bm, rt)
    e1 = J(n, 1, 0)
    (void) jd_ols(Bm, y, e1, dum)
    ssr1 = quadcross(e1, e1)
    F1 = ((ssr1 - ssrF) / d1) / (ssrF / dfr)

    Bm = (X, L)
    if (d3 > 0) Bm = (Bm, rt)
    e1 = J(n, 1, 0)
    (void) jd_ols(Bm, y, e1, dum)
    ssr2 = quadcross(e1, e1)
    F2 = ((ssr2 - ssrF) / d2) / (ssrF / dfr)

    F3 = .
    if (d3 > 0) {
        Bm = (X, L, V)
        e1 = J(n, 1, 0)
        (void) jd_ols(Bm, y, e1, dum)
        ssr3 = quadcross(e1, e1)
        F3 = ((ssr3 - ssrF) / d3) / (ssrF / dfr)
    }

    Out = J(4, 2, .)
    Out[1,1] = F1 ; Out[1,2] = d1
    Out[2,1] = F2 ; Out[2,2] = d2
    Out[3,1] = F3 ; Out[3,2] = d3
    Out[4,1] = n  ; Out[4,2] = dfr
    st_matrix(outname, Out)
}


end

mata: mata mlib create ljointdiag, dir(".") replace
mata: mata mlib add ljointdiag *(), dir(".")
mata: mata mlib index
display "ljointdiag.mlib built"
