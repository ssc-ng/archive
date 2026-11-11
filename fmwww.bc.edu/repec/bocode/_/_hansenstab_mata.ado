*! _hansenstab_mata  version 1.0.0  21oct2026
*! Mata engine for hansenstab. Loaded on demand with -do- by _hansenstab_load; not a command.

mata:
mata set matastrict off

real scalar hst_loaded()
{
    return(102)
}

// running sums down the columns of F (runningsum() accepts vectors only)
real matrix hst_cumsum(real matrix F)
{
    real matrix S
    real scalar t
    S = F
    for (t = 2; t <= rows(F); t++) S[t, .] = S[t-1, .] + F[t, .]
    return(S)
}

// kernel weight; kern 1 = quadratic spectral, 2 = Bartlett
real scalar hst_kw(real scalar j, real scalar bw, real scalar kern)
{
    real scalar x, z
    if (j == 0) return(1)
    if (bw <= 0) return(0)
    if (kern == 2) {
        x = j / (bw + 1)
        return(max((0, 1 - x)))
    }
    x = j / bw
    z = 6 * pi() * x / 5
    return(25 / (12 * pi()^2 * x^2) * (sin(z) / z - cos(z)))
}

real scalar hst_bw1(real colvector u0, real scalar kern)
{
    real colvector u
    real scalar T, rho, a
    u = u0 :- mean(u0)
    T = rows(u)
    rho = (u[|2 \ T|]' * u[|1 \ T-1|]) / (u[|1 \ T-1|]' * u[|1 \ T-1|])
    if (rho > .97)  rho = .97
    if (rho < -.97) rho = -.97
    if (kern == 1) {
        a = 4 * rho^2 / (1 - rho)^4
        return(1.3221 * (a * T)^(1/5))
    }
    a = 4 * rho^2 / ((1 - rho)^2 * (1 + rho)^2)
    return(1.1447 * (a * T)^(1/3))
}

// long-run covariance (divisor T) of the columns of F; F has mean zero by construction
real matrix hst_lrv(real matrix F, real scalar kern, real scalar bw)
{
    real matrix O, G
    real scalar T, j, jmax, w
    T = rows(F)
    O = F' * F / T
    if (kern == 0 | bw <= 0) return(O)
    jmax = (kern == 1 ? T - 1 : floor(bw))
    for (j = 1; j <= jmax; j++) {
        w = hst_kw(j, bw, kern)
        if (w == 0) continue
        G = F[|j+1, 1 \ T, cols(F)|]' * F[|1, 1 \ T-j, cols(F)|] / T
        O = O + w * (G + G')
    }
    return(O)
}

real scalar hst_autobw(real matrix F, real scalar kern)
{
    real scalar j, s
    s = 0
    for (j = 1; j <= cols(F); j++) s = s + hst_bw1(F[., j], kern)
    return(s / cols(F))
}

// Hansen (1992) statistics. Returns row: (L_1..L_m, L_b, L_c, bw); b and e are filled.
// m = k (+1 with the variance).  kern: 0 none, 1 QS, 2 Bartlett; bwin missing = automatic
real rowvector hst_stats(real colvector y, real matrix X, real scalar kern, real scalar bwin,
                         real scalar dovar, real colvector b, real colvector e)
{
    real matrix F, S, V, Vi, Vb
    real rowvector L
    real scalar T, k, m, bw, s2, Lc, Lb, t
    T = rows(X); k = cols(X)
    b = invsym(X' * X) * X' * y
    e = y - X * b
    s2 = mean(e:^2)
    F = X :* e
    if (dovar) F = (F, e:^2 :- s2)
    m = cols(F)
    S = hst_cumsum(F)
    bw = 0
    if (kern > 0) bw = (bwin < . ? bwin : hst_autobw(F, kern))
    V = T * hst_lrv(F, kern, bw)
    L = colsum(S:^2) :/ (T * diagonal(V)')
    Vi = invsym(V)
    Lc = sum(rowsum((S * Vi) :* S)) / T
    Lb = .
    if (dovar) {
        Vb = invsym(V[|1, 1 \ k, k|])
        Lb = sum(rowsum((S[|1, 1 \ T, k|] * Vb) :* S[|1, 1 \ T, k|])) / T
    }
    else Lb = Lc
    return((L, Lb, Lc, bw))
}

// P(Q > x), Q = sum_j lambda_j chi2_k(j), lambda_j = 1/(j pi)^2: the limit of the
// Nyblom-Hansen statistic with k degrees of freedom. Imhof (1961) inversion with
// J = 40 terms and a first-order correction for the rest; Simpson's rule with step
// 0.5, integrand truncated where it falls below 1e-8 (absolute error below 1e-5).
real scalar hst_pval(real scalar x, real scalar k)
{
    real colvector lam, u, th, lr, f, w
    real scalar J, tail, U, n, h, I, i
    if (x >= .) return(.)
    if (x <= 0) return(1)
    J = 40
    lam = 1 :/ ((1::J) * pi()):^2
    tail = 1/6 - sum(lam)
    U = 10
    while (1) {
        if (-ln(U) - (k / 4) * sum(ln(1 :+ (lam * U):^2)) < ln(1e-8) | U > 1e7) break
        U = U * 1.5
    }
    h = 0.5
    n = ceil(U / h)
    n = n + mod(n, 2)
    h = U / n
    u = (1::n) * h
    th = J(n, 1, 0)
    lr = J(n, 1, 0)
    for (i = 1; i <= J; i++) {
        th = th + atan(u * lam[i])
        lr = lr + ln(1 :+ (u * lam[i]):^2)
    }
    th = 0.5 * k * (th + tail * u) - 0.5 * x * u
    lr = (k / 4) * lr
    f = (0.5 * (k / 6 - x)) \ (sin(th) :/ (u :* exp(lr)))
    w = J(n + 1, 1, 2)
    for (i = 2; i <= n; i = i + 2) w[i] = 4
    w[1] = 1
    w[n + 1] = 1
    I = h / 3 * (w' * f)
    return(min((1, max((0, 0.5 + I / pi())))))
}

// bootstrap: wild (Rademacher, kern 0) or dependent wild (Shao 2010; Bartlett-type
// multipliers with block length l = ceil(bw) + 1) under the fixed-regressor design.
// Returns the bootstrap p-values for (L_1..L_m, L_b, L_c).
real rowvector hst_boot(real colvector y, real matrix X, real scalar kern, real scalar bw,
                        real scalar dovar, real scalar reps, real rowvector L0)
{
    real colvector b, e, bb, eb, v, z, yhat
    real rowvector Lb, cnt
    real scalar T, r, l, dwb, t
    T = rows(X)
    (void) hst_stats(y, X, kern, bw, dovar, b, e)
    yhat = X * b
    dwb = (kern > 0)
    l = max((2, ceil(bw) + 1))
    cnt = J(1, cols(L0) - 1, 0)
    for (r = 1; r <= reps; r++) {
        if (dwb) {
            z = rnormal(T + l - 1, 1, 0, 1)
            z = runningsum(z)
            v = (z[|l \ T + l - 1|] - (0 \ z[|1 \ T - 1|])) / sqrt(l)
        }
        else v = 2 * (runiform(T, 1) :< .5) :- 1
        Lb = hst_stats(yhat + e :* v, X, kern, bw, dovar, bb, eb)
        cnt = cnt + (Lb[|1 \ cols(Lb) - 1|] :>= L0[|1 \ cols(L0) - 1|])
    }
    return((cnt :+ 1) / (reps + 1))
}

void hst_run(string scalar yv, string scalar xv, string scalar touse, real scalar cons,
             real scalar kern, real scalar bwin, real scalar dovar, real scalar reps,
             string scalar resname, string scalar bwname, string scalar bname)
{
    real colvector y, b, e
    real matrix X, R
    real rowvector L, pv, pb
    real scalar k, m, j
    y = st_data(., yv, touse)
    if (strtrim(xv) != "") X = st_data(., xv, touse)
    else X = J(rows(y), 0, .)
    if (cons) X = (X, J(rows(X), 1, 1))
    k = cols(X)
    L = hst_stats(y, X, kern, bwin, dovar, b, e)
    m = k + dovar
    // asymptotic p-values: individual (1 df), coefficients jointly (k df), all (m df)
    pv = J(1, m + 2, .)
    for (j = 1; j <= m; j++) pv[j] = hst_pval(L[j], 1)
    pv[m + 1] = hst_pval(L[m + 1], k)
    pv[m + 2] = hst_pval(L[m + 2], m)
    pb = J(1, m + 2, .)
    if (reps > 0) pb = hst_boot(y, X, kern, L[m + 3], dovar, reps, L)
    R = (L[|1 \ m + 2|]' , pv', pb')
    st_matrix(resname, R)
    st_numscalar(bwname, L[m + 3])
    st_matrix(bname, b')
}

end
