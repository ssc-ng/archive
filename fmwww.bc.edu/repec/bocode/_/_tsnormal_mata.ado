*! _tsnormal_mata  version 1.0.0  21oct2026
*! Mata engine for tsnormal. Loaded on demand with -do- by _tsnormal_load; not a command.

mata:
mata set matastrict off

real scalar tsn_loaded()
{
    return(100)
}

// kernel weight at lag j for bandwidth bw; kern 1 = quadratic spectral, 2 = Bartlett
real scalar tsn_kw(real scalar j, real scalar bw, real scalar kern)
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

// Andrews (1991) AR(1) plug-in bandwidth for a scalar series
real scalar tsn_bw(real colvector u0, real scalar kern)
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

// long-run covariance of the columns of U (T x m, centred inside)
real matrix tsn_lrv(real matrix U0, real scalar bw, real scalar kern)
{
    real matrix U, O, G
    real scalar T, j, jmax, w
    U = U0 :- mean(U0)
    T = rows(U)
    O = U' * U / T
    if (bw <= 0) return(O)
    jmax = (kern == 1 ? T - 1 : floor(bw))
    for (j = 1; j <= jmax; j++) {
        w = tsn_kw(j, bw, kern)
        if (w == 0) continue
        G = U[|j+1, 1 \ T, cols(U)|]' * U[|1, 1 \ T-j, cols(U)|] / T
        O = O + w * (G + G')
    }
    return(O)
}

// Bai and Ng (2005): returns (skew, kurt, pi3, p3, pi4, p4, joint, pjoint, bw3, bw4)
real rowvector tsn_bn(real colvector x, real scalar kern, real scalar bwin)
{
    real colvector d, u3, u4
    real scalar T, s2, s, m3, m4, tau, kap, km3, bw3, bw4, bwj, v3, v4, pi3, pi4, joint
    real matrix O
    T = rows(x)
    d = x :- mean(x)
    s2 = mean(d:^2); s = sqrt(s2)
    m3 = mean(d:^3); m4 = mean(d:^4)
    tau = m3 / s^3
    kap = m4 / s2^2
    u3 = d:^3 - 3 * s2 * d
    u4 = (d:^4 :- m4) - 4 * m3 * d - 2 * s2 * kap * (d:^2 :- s2)
    bw3 = (bwin < . ? bwin : tsn_bw(u3, kern))
    bw4 = (bwin < . ? bwin : tsn_bw(u4, kern))
    v3 = tsn_lrv(u3, bw3, kern) / s^6
    v4 = tsn_lrv(u4, bw4, kern) / s^8
    pi3 = sqrt(T) * tau / sqrt(v3)
    pi4 = sqrt(T) * (kap - 3) / sqrt(v4)
    bwj = (bwin < . ? bwin : max((bw3, bw4)))
    O = tsn_lrv((u3 / s^3, u4 / s^4), bwj, kern)
    km3 = kap - 3
    joint = T * (tau, km3) * invsym(O) * (tau \ km3)
    return((tau, kap, pi3, 2 * normal(-abs(pi3)), pi4, 2 * normal(-abs(pi4)),
            joint, chi2tail(2, joint), bw3, bw4))
}

// Lobato and Velasco (2004): returns (G, p, G3, p3, G4, p4)
real rowvector tsn_lv(real colvector x)
{
    real colvector d, g
    real scalar T, m2, m3, m4, F3, F4, t, gT, G3, G4
    T = rows(x)
    d = x :- mean(x)
    m2 = mean(d:^2); m3 = mean(d:^3); m4 = mean(d:^4)
    g = J(T + 1, 1, 0)                  // g[j+1] = gamma(j), j = 0..T; gamma(T) = 0
    for (t = 0; t <= T - 1; t++) g[t+1] = (d[|t+1 \ T|]' * d[|1 \ T-t|]) / T
    F3 = g[1] * (g[1] + g[T+1])^2
    F4 = g[1] * (g[1] + g[T+1])^3
    for (t = 1; t <= T - 1; t++) {
        gT = g[T-t+1]
        F3 = F3 + 2 * g[t+1] * (g[t+1] + gT)^2
        F4 = F4 + 2 * g[t+1] * (g[t+1] + gT)^3
    }
    G3 = T * m3^2 / (6 * F3)
    G4 = T * (m4 - 3 * m2^2)^2 / (24 * F4)
    return((G3 + G4, chi2tail(2, G3 + G4), G3, chi2tail(1, G3), G4, chi2tail(1, G4)))
}

real scalar tsn_jb(real colvector x)
{
    real colvector d
    real scalar T, m2
    T = rows(x)
    d = x :- mean(x)
    m2 = mean(d:^2)
    return(T * ((mean(d:^3) / m2^1.5)^2 / 6 + (mean(d:^4) / m2^2 - 3)^2 / 24))
}

// Anderson-Darling statistic for normality with estimated mean and variance
real scalar tsn_ad(real colvector x)
{
    real colvector z, F, i
    real scalar T
    T = rows(x)
    z = sort((x :- mean(x)) / sqrt(mean((x :- mean(x)):^2)), 1)
    F = normal(z)
    F = rowmax((F, J(T, 1, 1e-12)))
    F = rowmin((F, J(T, 1, 1 - 1e-12)))
    i = (1::T)
    return(-T - mean((2 * i :- 1) :* (ln(F) + ln(1 :- F[T::1]))))
}

// AR(p) by OLS with intercept on observations p+1..T (or pmax+1..T for selection)
real colvector tsn_arfit(real colvector x, real scalar p, real scalar start, real colvector e)
{
    real matrix X
    real colvector y, b
    real scalar T, j
    T = rows(x)
    y = x[|start+1 \ T|]
    X = J(T - start, 1, 1)
    for (j = 1; j <= p; j++) X = (X, x[|start+1-j \ T-j|])
    b = invsym(X' * X) * X' * y
    e = y - X * b
    return(b)
}

real scalar tsn_arorder(real colvector x, real scalar pmax)
{
    real scalar p, best, aic, bp
    real colvector e, b
    best = .
    bp = 0
    for (p = 0; p <= pmax; p++) {
        b = tsn_arfit(x, p, pmax, e)
        aic = ln(mean(e:^2)) + 2 * (p + 1) / rows(e)
        if (aic < best) {
            best = aic
            bp = p
        }
    }
    return(bp)
}

// AR-sieve bootstrap under the Gaussian null; returns (AD, p_AD, p_JB, arp)
real rowvector tsn_sieve(real colvector x, real scalar reps, real scalar pmax0)
{
    real scalar T, pmax, p, sig, burn, r, t, j, ad0, jb0, cad, cjb, acc, it
    real colvector b, e, a, y, eps
    complex rowvector rts
    T = rows(x)
    pmax = (pmax0 < . ? pmax0 : min((floor(10 * log10(T)), floor(T / 4))))
    p = tsn_arorder(x, pmax)
    b = tsn_arfit(x, p, p, e)
    sig = sqrt(mean(e:^2))
    if (p > 0) {
        a = b[|2 \ p+1|]
        // shrink towards stationarity if a root is on or inside the unit circle
        for (it = 1; it <= 200; it++) {
            rts = polyroots((1, -a'))
            if (min(abs(rts)) > 1.005) break
            a = 0.95 * a
        }
    }
    ad0 = tsn_ad(x)
    jb0 = tsn_jb(x)
    burn = 100 + 5 * p
    cad = 0
    cjb = 0
    for (r = 1; r <= reps; r++) {
        eps = rnormal(T + burn, 1, 0, sig)
        y = J(T + burn, 1, 0)
        for (t = 1; t <= T + burn; t++) {
            acc = eps[t]
            for (j = 1; j <= p; j++) {
                if (t - j >= 1) acc = acc + a[j] * y[t-j]
            }
            y[t] = acc
        }
        y = y[|burn+1 \ T+burn|]
        cad = cad + (tsn_ad(y) >= ad0)
        cjb = cjb + (tsn_jb(y) >= jb0)
    }
    return((ad0, (cad + 1) / (reps + 1), (cjb + 1) / (reps + 1), p))
}

// all tests for one series; result row:
// N skew kurt pi3 p_pi3 pi4 p_pi4 bn p_bn lv p_lv lv3 p_lv3 lv4 p_lv4 jb p_jb ad p_ad p_jbb arp bw3 bw4
real rowvector tsn_one(real colvector x, real scalar kern, real scalar bw,
                       real scalar reps, real scalar pmax)
{
    real rowvector bn, lv, sv
    real scalar jb
    bn = tsn_bn(x, kern, bw)
    lv = tsn_lv(x)
    jb = tsn_jb(x)
    if (reps > 0) sv = tsn_sieve(x, reps, pmax)
    else          sv = (tsn_ad(x), ., ., .)
    return((rows(x), bn[|1 \ 8|], lv, jb, chi2tail(2, jb), sv, bn[9], bn[10]))
}

void tsn_run(string scalar vname, string scalar touse, real scalar kern, real scalar bw,
             real scalar reps, real scalar pmax, string scalar resname)
{
    real colvector x
    x = st_data(., vname, touse)
    st_matrix(resname, tsn_one(x, kern, bw, reps, pmax))
}

end
