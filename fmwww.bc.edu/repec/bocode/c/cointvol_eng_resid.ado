*! cointvol_eng_resid 0.2.0  26sep2026
*! Mata engine of -cointvol resid- and -cointvol ecm- (prefix cve_)
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com) - github.com/merwanroudane
*!
*! Step -> source map
*!   EG two-step, DF/ADF t on OLS residuals      -> Engle & Granger (1987); FKM (1994) eqs (5)-(6)
*!   T(a-1), CRDW, tau-White (HC0 DF t)          -> Lee & Tse (1996) sec. 2; White (1980)
*!   TAR / MTAR F (H0 rho1 = rho2 = 0), I = 1{z >= tau}, threshold 0 or Chan (1993)
*!                                               -> Enders & Siklos (2001) eqs (6), (7), (10), (11), (16)
*!   E-S critical values                         -> Enders & Siklos (WP version) Tables 1-2
*!   t_NLEG = t on u(t-1)^3, sigma2 = SSR/T       -> Kapetanios, Shin & Snell (2006; WP 497) eqs (3.4)-(3.6)
*!   t_NLECM (nonlinear STAR ECM t)              -> KSS eqs (3.1)-(3.3), (3.13)-(3.16); Table 1
*!   GH ADF*, Zt*, Za* (level / regime shift)    -> Gregory & Hansen (1996) eqs (2.2)-(2.3), (3.1)-(3.3),
*!                                                  p. 105 (Phillips Z with prewhitened QS LRV); Table 1
*!   HJ ADF*, Zt*, Za*, two regime shifts        -> Hatemi-J (2008) eqs (2)-(9); Table 1
*!   Breitung Lambda_q = T^2 sum lambda_j        -> Breitung (2002; SFB 373 DP 1999) eq (12); Table A.2
*!   null simulation, GARCH(1,1), burn-in 500    -> Lee & Tse (1996) sec. 2; FKM (1994) sec. 3
*!   FKM 5% critical values                      -> FKM (1994) Table 1, eqs (7)-(8)
*!   ECM t (known beta, KED)                     -> Kremers, Ericsson & Dolado (1992) eqs (3), (14)-(18)
*!   ECM t (estimated coefficients, kappa_d(k))  -> Banerjee, Dolado & Mestre (1998) eqs (1'), (3');
*!                                                  Ericsson & MacKinnon (2002) eqs (16), (24)
*!   E&M response surfaces c(p) = th_inf + th1/Ta + th2/Ta^2 + th3/Ta^3, Ta = T - h
*!                                               -> Ericsson & MacKinnon (2002) eq (26), Tables 2-5, sec. 5
*!   BDM critical values                         -> Banerjee, Dolado & Mestre (1998) Table I
*!   wild bootstrap (Mammen), H0 imposed         -> Mantalos (c. 2001) eqs (3)-(5)
*!
*! Running this file (see the loader in cointvol_resid.ado / cointvol_ecm.ado)
*! compiles the Mata functions below.

program define cointvol_eng_resid
    version 14.0
end

version 14.0
capture mata: mata drop cve_*()

mata:

string scalar cve_version()
{
    return("0.2.0")
}

// ---------------------------------------------------------------------------
//  Small utilities
// ---------------------------------------------------------------------------

real matrix cve_det(real scalar T0, real scalar det)
{
    if (det == 1) {
        return(J(T0, 1, 1))
    }
    if (det == 2) {
        return((J(T0, 1, 1), (1::T0)))
    }
    return(J(T0, 0, .))
}

real scalar cve_ssr(real matrix Z, real colvector y)
{
    real colvector e
    if (cols(Z) == 0) {
        return(cross(y, y))
    }
    e = y - Z * (invsym(cross(Z, Z)) * cross(Z, y))
    return(cross(e, e))
}

// OLS t-ratio of column c, s2 = SSR/(n-k) (dfc = 1) or SSR/n (dfc = 0)
real scalar cve_tcol(real matrix Z, real colvector y, real scalar c, real scalar dfc)
{
    real matrix XX
    real colvector b, e
    real scalar n, k, s2
    n  = rows(Z)
    k  = cols(Z)
    XX = invsym(cross(Z, Z))
    b  = XX * cross(Z, y)
    e  = y - Z * b
    s2 = cross(e, e) / n
    if (dfc == 1) {
        s2 = cross(e, e) / (n - k)
    }
    if (s2 <= 0 | XX[c, c] <= 0) {
        return(.)
    }
    return(b[c] / sqrt(s2 * XX[c, c]))
}

// OLS t-ratio of the first regressor (small-sample s2)
real scalar cve_tfirst(real matrix Z, real colvector y)
{
    return(cve_tcol(Z, y, 1, 1))
}

real scalar cve_quant(real colvector x, real scalar q)
{
    real colvector s
    real scalar n, j
    s = sort(select(x, x :< .), 1)
    n = rows(s)
    if (n == 0) {
        return(.)
    }
    j = ceil(q * n)
    if (j < 1) {
        j = 1
    }
    if (j > n) {
        j = n
    }
    return(s[j])
}

// tail < 0: left-tailed (reject for small values); tail > 0: right-tailed
real scalar cve_pv(real colvector x, real scalar s, real scalar tail, real scalar plusone)
{
    real colvector v
    real scalar n, c
    if (missing(s)) {
        return(.)
    }
    v = select(x, x :< .)
    n = rows(v)
    if (n == 0) {
        return(.)
    }
    if (tail < 0) {
        c = sum(v :<= s)
    }
    else {
        c = sum(v :>= s)
    }
    if (plusone == 1) {
        return((c + 1) / (n + 1))
    }
    return(c / n)
}

real colvector cve_mult(real scalar n, string scalar mult)
{
    real scalar a, b, pa
    if (mult == "rademacher") {
        return(2 :* (runiform(n, 1) :> 0.5) :- 1)
    }
    if (mult == "mammen") {
        a  = -(sqrt(5) - 1) / 2
        b  =  (sqrt(5) + 1) / 2
        pa =  (sqrt(5) + 1) / (2 * sqrt(5))
        return(a :+ (b - a) :* (runiform(n, 1) :> pa))
    }
    return(rnormal(n, 1, 0, 1))
}

// ---------------------------------------------------------------------------
//  ADF-type regressions on a residual series u (T0 x 1)
//    du(t) = rho*u(t-1) + sum_{j=1..p} phi_j du(t-j) + e(t),  t in idx
// ---------------------------------------------------------------------------

real matrix cve_adfZ(real colvector u, real colvector idx, real scalar p)
{
    real matrix Z
    real scalar j
    Z = u[idx :- 1]
    for (j = 1; j <= p; j = j + 1) {
        Z = Z, (u[idx :- j] - u[idx :- j :- 1])
    }
    return(Z)
}

// lag choice by information criterion on the common sample t = pmax+2..T0
// ic = 1 AIC, ic = 2 BIC
real scalar cve_sellag(real colvector u, real scalar pmax, real scalar ic)
{
    real colvector idx, dy
    real matrix Z
    real scalar T0, n, p, k, crit, best, bestp, ssr
    T0 = rows(u)
    idx = ((pmax + 2)::T0)
    dy  = u[idx] - u[idx :- 1]
    n   = rows(idx)
    best  = .
    bestp = 0
    for (p = 0; p <= pmax; p = p + 1) {
        Z   = cve_adfZ(u, idx, p)
        ssr = cve_ssr(Z, dy)
        k   = p + 1
        if (ic == 1) {
            crit = ln(ssr / n) + 2 * k / n
        }
        else {
            crit = ln(ssr / n) + k * ln(n) / n
        }
        if (crit < best) {
            best  = crit
            bestp = p
        }
    }
    return(bestp)
}

// general-to-specific t-sig rule (Gregory & Hansen 1996, p. 110; Perron &
// Vogelsang 1992): start at pmax and reduce the lag until the last lagged
// difference is significant at 5% with normal critical values (|t| > 1.96);
// each regression uses its maximal sample.
real scalar cve_seltsig(real colvector u, real scalar pmax)
{
    real colvector idx, dy
    real matrix Z
    real scalar T0, p, tl
    T0 = rows(u)
    for (p = pmax; p >= 1; p = p - 1) {
        idx = ((p + 2)::T0)
        dy  = u[idx] - u[idx :- 1]
        Z   = cve_adfZ(u, idx, p)
        tl  = cve_tcol(Z, dy, p + 1, 1)
        if (abs(tl) > 1.96) {
            if (tl < .) {
                return(p)
            }
        }
    }
    return(0)
}

// lagmode: 0 fixed, 1 AIC, 2 BIC, 3 t-sig
real scalar cve_lagfor(real colvector u, real scalar lagmode, real scalar pfix, real scalar pmax)
{
    if (lagmode == 0) {
        return(pfix)
    }
    if (lagmode == 3) {
        return(cve_seltsig(u, pmax))
    }
    return(cve_sellag(u, pmax, lagmode))
}

// returns (t_OLS, T(a-1) normalised, t_HC0, n)
real rowvector cve_adf(real colvector u, real scalar p)
{
    real colvector idx, dy, b, e
    real matrix Z, XX, M
    real scalar T0, n, k, s2, t, ta, thc, phis
    T0  = rows(u)
    idx = ((p + 2)::T0)
    dy  = u[idx] - u[idx :- 1]
    Z   = cve_adfZ(u, idx, p)
    n   = rows(Z)
    k   = cols(Z)
    XX  = invsym(cross(Z, Z))
    b   = XX * cross(Z, dy)
    e   = dy - Z * b
    s2  = cross(e, e) / (n - k)
    t   = b[1] / sqrt(s2 * XX[1, 1])
    phis = 0
    if (p > 0) {
        phis = sum(b[|2 \ k|])
    }
    ta  = n * b[1] / (1 - phis)
    M   = XX * cross(Z, e :^ 2, Z) * XX
    thc = b[1] / sqrt(M[1, 1])
    return((t, ta, thc, n))
}

// ADF t only (used inside the break-point searches)
real scalar cve_adft(real colvector u, real scalar p)
{
    real colvector idx, dy
    real scalar T0
    T0  = rows(u)
    idx = ((p + 2)::T0)
    dy  = u[idx] - u[idx :- 1]
    return(cve_tfirst(cve_adfZ(u, idx, p), dy))
}

// cointegrating-regression Durbin-Watson (Sargan & Bhargava 1983)
real scalar cve_crdw(real colvector u)
{
    real scalar T0
    real colvector d
    T0 = rows(u)
    d  = u[|2 \ T0|] - u[|1 \ T0 - 1|]
    return(cross(d, d) / cross(u, u))
}

// KSS (2006) t_NLEG, eqs (3.4)-(3.6): t on delta in
//   du(t) = delta u(t-1)^3 + sum phi_i du(t-i) + eta(t),  sigma2 = SSR / T
real scalar cve_kss(real colvector u, real scalar p)
{
    real colvector idx, dy
    real matrix Z
    real scalar T0
    T0  = rows(u)
    idx = ((p + 2)::T0)
    dy  = u[idx] - u[idx :- 1]
    Z   = cve_adfZ(u, idx, p)
    Z[., 1] = Z[., 1] :^ 3
    return(cve_tcol(Z, dy, 1, 0))
}

// KSS (2006) t_NLECM, eqs (3.1)-(3.3) with (3.13)-(3.16): the data are
// demeaned (det = 1) or demeaned and detrended (det = 2) first; u = y* - x*'b
// (OLS, no intercept); then
//   dy*(t) = delta u(t-1)^3 + omega' dx*(t) + sum_i gamma_i' dz*(t-i) + e(t),
//   z = (y, x')', sigma2 = SSR / T, t-ratio on delta.
real scalar cve_kssecm(real colvector y, real matrix X, real scalar det, real scalar p)
{
    real matrix D, Xs, Z
    real colvector ys, u, dy, idx
    real scalar T0, j
    T0 = rows(y)
    D  = cve_det(T0, det)
    ys = y
    Xs = X
    if (cols(D) > 0) {
        ys = y - D * (invsym(cross(D, D)) * cross(D, y))
        Xs = X - D * (invsym(cross(D, D)) * cross(D, X))
    }
    u   = ys - Xs * (invsym(cross(Xs, Xs)) * cross(Xs, ys))
    idx = ((p + 2)::T0)
    dy  = ys[idx] - ys[idx :- 1]
    Z   = (u[idx :- 1] :^ 3), (Xs[idx, .] - Xs[idx :- 1, .])
    for (j = 1; j <= p; j = j + 1) {
        Z = Z, (ys[idx :- j] - ys[idx :- j :- 1]), (Xs[idx :- j, .] - Xs[idx :- j :- 1, .])
    }
    return(cve_tcol(Z, dy, 1, 0))
}

// Enders-Siklos (2001) TAR (mtar = 0) / M-TAR (mtar = 1) F statistic for
// H0: rho1 = rho2 = 0 in
//   du(t) = I(t) rho1 u(t-1) + (1 - I(t)) rho2 u(t-1) + sum gamma_i du(t-i) + e(t)
// with I(t) = 1{z(t-1) >= tau}, z = u (TAR, eq 7) or du (M-TAR, eq 11).
// F = [(S0 - S1)/2] / [S1/(n - 2 - p)] (the usual regression F).
// thr = 1: tau = 0 (the attractor, E-S Tables 1-2);
// thr = 0: tau minimises S1 over the trimmed order statistics of z
//          (consistent threshold, Chan 1993).  Returns (F, tau).
real rowvector cve_tar(real colvector u, real scalar p, real scalar trim, real scalar mtar,
                       real scalar thr)
{
    real colvector idx, dy, ul, z, zs, I
    real matrix L, Z
    real scalar T0, s0, n, S0, S1, best, bmu, lo, hi, j, mu, prev, kk
    T0 = rows(u)
    s0 = p + 2
    if (mtar == 1) {
        if (s0 < 3) {
            s0 = 3
        }
    }
    idx = (s0::T0)
    dy  = u[idx] - u[idx :- 1]
    ul  = u[idx :- 1]
    if (mtar == 1) {
        z = u[idx :- 1] - u[idx :- 2]
    }
    else {
        z = ul
    }
    n = rows(idx)
    if (p > 0) {
        L = cve_adfZ(u, idx, p)
        L = L[|1, 2 \ n, p + 1|]
    }
    else {
        L = J(n, 0, .)
    }
    kk = 2 + p
    S0 = cve_ssr(L, dy)
    best = .
    bmu  = .
    if (thr == 1) {
        I    = (z :>= 0)
        Z    = (ul :* I, ul :* (1 :- I)), L
        best = cve_ssr(Z, dy)
        bmu  = 0
    }
    else {
        zs = sort(z, 1)
        lo = ceil(trim * n)
        hi = floor((1 - trim) * n)
        if (lo < 1) {
            lo = 1
        }
        if (hi > n) {
            hi = n
        }
        prev = .
        for (j = lo; j <= hi; j = j + 1) {
            mu = zs[j]
            if (mu == prev) {
                continue
            }
            prev = mu
            I  = (z :>= mu)
            Z  = (ul :* I, ul :* (1 :- I)), L
            S1 = cve_ssr(Z, dy)
            if (S1 < best) {
                best = S1
                bmu  = mu
            }
        }
    }
    if (missing(best) | best <= 0) {
        return((., .))
    }
    return((((S0 - best) / 2) / (best / (n - kk)), bmu))
}

// Long-run variance of v (Gregory & Hansen 1996, p. 105; Hatemi-J 2008 fn. 3):
// AR(1) prewhitening, quadratic-spectral kernel, Andrews (1991) AR(1) plug-in
// bandwidth S = 1.3221 (a2 N)^(1/5), a2 = 4 rho^2/(1 - rho)^4 (Andrews and
// Monahan 1992), recolouring by (1 - phi)^-2.  Autocovariances use the divisor
// n (GH).  The AR coefficients are capped at +-0.97 and the kernel sum is
// truncated where |k(x)| < 0.001 (x > 15).
real scalar cve_lrvqs(real colvector v, real scalar n)
{
    real colvector eta
    real scalar N0, N, phi, rho, a2, S, om, j, x, w, g, JJ, den, pa
    N0 = rows(v)
    if (N0 < 4) {
        return(cross(v, v) / n)
    }
    phi = 0
    den = cross(v[|1 \ N0 - 1|], v[|1 \ N0 - 1|])
    if (den > 0) {
        phi = cross(v[|1 \ N0 - 1|], v[|2 \ N0|]) / den
    }
    if (phi > 0.97) {
        phi = 0.97
    }
    if (phi < -0.97) {
        phi = -0.97
    }
    eta = v[|2 \ N0|] - phi :* v[|1 \ N0 - 1|]
    N   = rows(eta)
    rho = 0
    den = cross(eta[|1 \ N - 1|], eta[|1 \ N - 1|])
    if (den > 0) {
        rho = cross(eta[|1 \ N - 1|], eta[|2 \ N|]) / den
    }
    if (rho > 0.97) {
        rho = 0.97
    }
    if (rho < -0.97) {
        rho = -0.97
    }
    a2 = 4 * rho * rho / ((1 - rho) * (1 - rho) * (1 - rho) * (1 - rho))
    S  = 1.3221 * (a2 * N)^0.2
    om = cross(eta, eta) / n
    if (S > 0) {
        JJ = ceil(15 * S)
        if (JJ > N - 1) {
            JJ = N - 1
        }
        pa = 6 * pi() / 5
        for (j = 1; j <= JJ; j = j + 1) {
            x  = j / S
            w  = 25 / (12 * pi() * pi() * x * x) * (sin(pa * x) / (pa * x) - cos(pa * x))
            g  = cross(eta[|j + 1 \ N|], eta[|1 \ N - j|]) / n
            om = om + 2 * w * g
        }
    }
    return(om / ((1 - phi) * (1 - phi)))
}

// Phillips Z statistics on regression residuals e (t = 1..n), GH (1996) p. 105:
//   rho = sum e(t)e(t+1) / sum e(t)^2, v(t) = e(t) - rho e(t-1),
//   sigma2 = LRV(v) = gamma(0) + 2 lambda,
//   rho* = sum (e(t)e(t+1) - lambda) / sum e(t)^2,
//   Za = n (rho* - 1),  Zt = (rho* - 1)/s,  s^2 = sigma2 / sum e(t)^2.
// Returns (Za, Zt).
real rowvector cve_ppz(real colvector e)
{
    real colvector v
    real scalar n, s11, s01, rho, sig2, g0, lam, rhos
    n   = rows(e)
    s11 = cross(e[|1 \ n - 1|], e[|1 \ n - 1|])
    if (s11 <= 0) {
        return((., .))
    }
    s01  = cross(e[|1 \ n - 1|], e[|2 \ n|])
    rho  = s01 / s11
    v    = e[|2 \ n|] - rho :* e[|1 \ n - 1|]
    sig2 = cve_lrvqs(v, n)
    if (sig2 <= 0) {
        return((., .))
    }
    g0   = cross(v, v) / n
    lam  = (sig2 - g0) / 2
    rhos = (s01 - (n - 1) * lam) / s11
    return((n * (rhos - 1), (rhos - 1) / sqrt(sig2 / s11)))
}

// Gregory-Hansen (1996): for each break date TB = [n tau], tau in [trim, 1-trim],
// OLS of y on D (deterministics), the level-shift dummy phi(t) = 1(t > TB)
// (if det > 0) and x; shift = 1 adds x phi(t) (regime shift C/S, eq 2.3);
// shift = 0 is C (eq 2.2) or C/T (second eq 2.2, det = 2).
// w3 = (ADF, Zt, Za) selection.  Returns 3 x 3: rows ADF*, Zt*, Za*;
// columns (infimum, TB at the infimum, ADF lag at the infimum).
real matrix cve_gh(real colvector y, real matrix X, real matrix D, real scalar det,
                   real scalar lagmode, real scalar pfix, real scalar pmax,
                   real scalar trim, real scalar shift, real rowvector w3)
{
    real scalar T0, lo, hi, tb, p, st
    real colvector tt, Dt, u
    real matrix W, out
    real rowvector z
    T0 = rows(y)
    tt = (1::T0)
    lo = floor(trim * T0)
    hi = floor((1 - trim) * T0)
    if (lo < 2) {
        lo = 2
    }
    if (hi > T0 - 2) {
        hi = T0 - 2
    }
    out = J(3, 3, .)
    for (tb = lo; tb <= hi; tb = tb + 1) {
        Dt = (tt :> tb)
        W  = D, X
        if (det > 0) {
            W = W, Dt
        }
        if (shift == 1) {
            W = W, (X :* Dt)
        }
        u = y - W * (invsym(cross(W, W)) * cross(W, y))
        if (w3[1] == 1) {
            p  = cve_lagfor(u, lagmode, pfix, pmax)
            st = cve_adft(u, p)
            if (st < out[1, 1]) {
                out[1, 1] = st
                out[1, 2] = tb
                out[1, 3] = p
            }
        }
        if (w3[2] + w3[3] > 0) {
            z = cve_ppz(u)
            if (z[2] < out[2, 1]) {
                out[2, 1] = z[2]
                out[2, 2] = tb
            }
            if (z[1] < out[3, 1]) {
                out[3, 1] = z[1]
                out[3, 2] = tb
            }
        }
    }
    return(out)
}

// Hatemi-J (2008) two regime shifts, eq (2): D1 = 1(t > TB1), D2 = 1(t > TB2),
// tau1 in [trim, 1 - 2 trim], tau2 in [tau1 + trim, 1 - trim].
// Returns 3 x 4: rows ADF*, Zt*, Za*; columns (infimum, TB1, TB2, ADF lag).
real matrix cve_hj(real colvector y, real matrix X, real matrix D, real scalar det,
                   real scalar lagmode, real scalar pfix, real scalar pmax,
                   real scalar trim, real scalar shift, real rowvector w3)
{
    real scalar T0, lo1, hi1, hi2, gap, t1, t2, p, st
    real colvector tt, D1, D2, u
    real matrix W, out
    real rowvector z
    T0  = rows(y)
    tt  = (1::T0)
    gap = floor(trim * T0)
    if (gap < 1) {
        gap = 1
    }
    lo1 = floor(trim * T0)
    if (lo1 < 2) {
        lo1 = 2
    }
    hi1 = floor((1 - 2 * trim) * T0)
    hi2 = floor((1 - trim) * T0)
    if (hi2 > T0 - 2) {
        hi2 = T0 - 2
    }
    out = J(3, 4, .)
    for (t1 = lo1; t1 <= hi1; t1 = t1 + 1) {
        D1 = (tt :> t1)
        for (t2 = t1 + gap; t2 <= hi2; t2 = t2 + 1) {
            D2 = (tt :> t2)
            W  = D, X
            if (det > 0) {
                W = W, D1, D2
            }
            if (shift == 1) {
                W = W, (X :* D1), (X :* D2)
            }
            u = y - W * (invsym(cross(W, W)) * cross(W, y))
            if (w3[1] == 1) {
                p  = cve_lagfor(u, lagmode, pfix, pmax)
                st = cve_adft(u, p)
                if (st < out[1, 1]) {
                    out[1, 1] = st
                    out[1, 2] = t1
                    out[1, 3] = t2
                    out[1, 4] = p
                }
            }
            if (w3[2] + w3[3] > 0) {
                z = cve_ppz(u)
                if (z[2] < out[2, 1]) {
                    out[2, 1] = z[2]
                    out[2, 2] = t1
                    out[2, 3] = t2
                }
                if (z[1] < out[3, 1]) {
                    out[3, 1] = z[1]
                    out[3, 2] = t1
                    out[3, 3] = t2
                }
            }
        }
    }
    return(out)
}

// Breitung (2002) Lambda_q, eq (12), for H0: r = 0 (q = n stochastic trends):
// Lambda_n = T^2 sum_{j=1..n} lambda_j = T^2 trace(A_T B_T^-1), A = sum z z',
// B = sum Z Z', Z partial sums of z = (y, x')' after mean (det = 1) or trend
// (det = 2) adjustment.  Rejects for large values.
real scalar cve_vr(real colvector y, real matrix X, real matrix D)
{
    real matrix Z, U, A, Bm
    real scalar T0, j
    Z  = y, X
    T0 = rows(Z)
    if (cols(D) > 0) {
        Z = Z - D * (invsym(cross(D, D)) * cross(D, Z))
    }
    U = J(T0, cols(Z), .)
    for (j = 1; j <= cols(Z); j = j + 1) {
        U[., j] = runningsum(Z[., j])
    }
    A  = cross(Z, Z)
    Bm = cross(U, U)
    return(T0 * T0 * trace(A * invsym(Bm)))
}

// ---------------------------------------------------------------------------
//  All requested statistics for one data set.
//  Column order: 1 eg, 2 ta1, 3 crdw, 4 hc0, 5 tar, 6 mtar, 7 kss, 8 gh (ADF*),
//                9 hj (ADF*), 10 vr, 11 kssecm, 12 ghzt, 13 ghza, 14 hjzt, 15 hjza
//  Rows: 1 statistic, 2 lag used, 3 parameter 1 (threshold / TB1), 4 parameter 2 (TB2)
//  Lag selection and every grid search are re-run on each call, so simulated
//  and bootstrap statistics replicate the observed one exactly.
// ---------------------------------------------------------------------------

real matrix cve_stats(real colvector y, real matrix X, real scalar det,
                      real scalar lagmode, real scalar pfix, real scalar pmax,
                      real scalar trim, real scalar shift, real scalar thr,
                      real rowvector w)
{
    real matrix out, D, W, G
    real colvector u
    real rowvector a
    real scalar T0, p, lin
    out = J(4, 15, .)
    T0  = rows(y)
    D   = cve_det(T0, det)
    lin = w[1] + w[2] + w[3] + w[4] + w[5] + w[6] + w[7] + w[11]
    if (lin > 0) {
        W = D, X
        u = y - W * (invsym(cross(W, W)) * cross(W, y))
        p = cve_lagfor(u, lagmode, pfix, pmax)
        if (w[1] + w[2] + w[4] > 0) {
            a = cve_adf(u, p)
            out[1, 1] = a[1]
            out[1, 2] = a[2]
            out[1, 4] = a[3]
            out[2, 1] = p
            out[2, 2] = p
            out[2, 4] = p
        }
        if (w[3] > 0) {
            out[1, 3] = cve_crdw(u)
            out[2, 3] = 0
        }
        if (w[5] > 0) {
            a = cve_tar(u, p, trim, 0, thr)
            out[1, 5] = a[1]
            out[2, 5] = p
            out[3, 5] = a[2]
        }
        if (w[6] > 0) {
            a = cve_tar(u, p, trim, 1, thr)
            out[1, 6] = a[1]
            out[2, 6] = p
            out[3, 6] = a[2]
        }
        if (w[7] > 0) {
            out[1, 7] = cve_kss(u, p)
            out[2, 7] = p
        }
        if (w[11] > 0) {
            out[1, 11] = cve_kssecm(y, X, det, p)
            out[2, 11] = p
        }
    }
    if (w[8] + w[12] + w[13] > 0) {
        G = cve_gh(y, X, D, det, lagmode, pfix, pmax, trim, shift, (w[8], w[12], w[13]))
        out[1, 8]  = G[1, 1]
        out[2, 8]  = G[1, 3]
        out[3, 8]  = G[1, 2]
        out[1, 12] = G[2, 1]
        out[3, 12] = G[2, 2]
        out[1, 13] = G[3, 1]
        out[3, 13] = G[3, 2]
    }
    if (w[9] + w[14] + w[15] > 0) {
        G = cve_hj(y, X, D, det, lagmode, pfix, pmax, trim, shift, (w[9], w[14], w[15]))
        out[1, 9]  = G[1, 1]
        out[2, 9]  = G[1, 4]
        out[3, 9]  = G[1, 2]
        out[4, 9]  = G[1, 3]
        out[1, 14] = G[2, 1]
        out[3, 14] = G[2, 2]
        out[4, 14] = G[2, 3]
        out[1, 15] = G[3, 1]
        out[3, 15] = G[3, 2]
        out[4, 15] = G[3, 3]
    }
    if (w[10] > 0) {
        out[1, 10] = cve_vr(y, X, D)
        out[2, 10] = 0
    }
    return(out)
}

// ---------------------------------------------------------------------------
//  GARCH(1,1) innovations, n independent series, burn-in discarded
//    h(t) = w0 + a e(t-1)^2 + b h(t-1),  e(t) = sqrt(h(t)) z(t),  z iid N(0,1)
//    w0 = 1 - a - b (unit unconditional variance, Lee & Tse 1996) when a+b < 1,
//    w0 = 1 otherwise (FKM 1994 intercept; the statistics are scale invariant)
//    h(0) = 1, e(0) = 0
// ---------------------------------------------------------------------------

real matrix cve_garchsim(real scalar T, real scalar n, real scalar a, real scalar b,
                         real scalar burn)
{
    real matrix Z, E
    real rowvector h, e
    real scalar w0, t
    if (a == 0 & b == 0) {
        return(rnormal(T, n, 0, 1))
    }
    w0 = 1 - a - b
    if (w0 <= 0) {
        w0 = 1
    }
    Z = rnormal(T + burn, n, 0, 1)
    E = J(T + burn, n, .)
    h = J(1, n, 1)
    e = J(1, n, 0)
    for (t = 1; t <= T + burn; t = t + 1) {
        h = w0 :+ a :* (e :^ 2) :+ b :* h
        e = sqrt(h) :* Z[t, .]
        E[t, .] = e
    }
    return(E[|burn + 1, 1 \ T + burn, n|])
}

// Monte Carlo null distribution: m+1 independent random walks
real matrix cve_simnull(real scalar T0, real scalar m, real scalar det,
                        real scalar lagmode, real scalar pfix, real scalar pmax,
                        real scalar trim, real scalar shift, real scalar thr,
                        real rowvector w, real scalar R,
                        real scalar ga, real scalar gb, real scalar dots)
{
    real matrix S, E, Z, st
    real scalar r, j, step
    S = J(R, 15, .)
    step = floor(R / 50)
    if (step < 1) {
        step = 1
    }
    for (r = 1; r <= R; r = r + 1) {
        E = cve_garchsim(T0, m + 1, ga, gb, 500)
        Z = J(T0, m + 1, .)
        for (j = 1; j <= m + 1; j = j + 1) {
            Z[., j] = runningsum(E[., j])
        }
        if (hasmissing(Z)) {
            continue
        }
        st = cve_stats(Z[., 1], Z[|1, 2 \ T0, m + 1|], det, lagmode, pfix, pmax, trim,
                       shift, thr, w)
        S[r, .] = st[1, .]
        if (dots == 1) {
            if (mod(r, step) == 0) {
                printf(".")
                displayflush()
            }
        }
    }
    if (dots == 1) {
        printf("\n")
        displayflush()
    }
    return(S)
}

// Wild bootstrap under the null (extended implementation):
//   dy*(t) = (dy(t) - mean(dy)) * w(t),  y*(1) = y(1),  y* = cumulated dy*
//   y* is re-regressed on the ORIGINAL regressors inside cve_stats and the
//   whole statistic (lag choice, threshold / break search) is recomputed.
real matrix cve_bootwild(real colvector y, real matrix X, real scalar det,
                         real scalar lagmode, real scalar pfix, real scalar pmax,
                         real scalar trim, real scalar shift, real scalar thr,
                         real rowvector w, real scalar B,
                         string scalar mult, real scalar dots)
{
    real matrix S, st
    real colvector dy, ys, u
    real scalar T0, b, step
    T0 = rows(y)
    dy = y[|2 \ T0|] - y[|1 \ T0 - 1|]
    dy = dy :- mean(dy)
    S  = J(B, 15, .)
    step = floor(B / 50)
    if (step < 1) {
        step = 1
    }
    for (b = 1; b <= B; b = b + 1) {
        u  = cve_mult(T0 - 1, mult)
        ys = y[1] \ (y[1] :+ runningsum(dy :* u))
        st = cve_stats(ys, X, det, lagmode, pfix, pmax, trim, shift, thr, w)
        S[b, .] = st[1, .]
        if (dots == 1) {
            if (mod(b, step) == 0) {
                printf(".")
                displayflush()
            }
        }
    }
    if (dots == 1) {
        printf("\n")
        displayflush()
    }
    return(S)
}

void cve_fillcv(real matrix res, real matrix S, real rowvector wsel, real scalar Rn)
{
    real scalar j
    for (j = 1; j <= 15; j = j + 1) {
        if (wsel[j] == 0) {
            continue
        }
        if (res[j, 8] < 0) {
            res[j, 2] = cve_quant(S[., j], 0.01)
            res[j, 3] = cve_quant(S[., j], 0.05)
            res[j, 4] = cve_quant(S[., j], 0.10)
        }
        else {
            res[j, 2] = cve_quant(S[., j], 0.99)
            res[j, 3] = cve_quant(S[., j], 0.95)
            res[j, 4] = cve_quant(S[., j], 0.90)
        }
        res[j, 5]  = cve_pv(S[., j], res[j, 1], res[j, 8], 1)
        res[j, 12] = rows(select(S[., j], S[., j] :< .))
    }
}

// ---------------------------------------------------------------------------
//  Franses, Kofman & Moser (1994) 5% critical value of the EG t-test
//  (T = 250, one regressor, constant).  Returns (cv, region, distance):
//    region 1 : a+b <= 0.98, Table 1 nearest (a,b) row if within 0.05,
//               otherwise the no-GARCH fractile -3.38 (FKM: stationary GARCH
//               away from a+b = 1 leaves the fractiles unchanged)
//    region 2 : |a+b-1| < 0.02, IGARCH response surface eq (7)
//    region 3 : a+b >= 1.02, non-covariance-stationary surface eq (8)
// ---------------------------------------------------------------------------

real matrix cve_fkmtab()
{
    real matrix T1
    T1 = J(19, 3, .)
    T1[1, .] = (0.0, 0.00, -3.38)
    T1[2, .] = (0.1, 0.89, -3.35)
    T1[3, .] = (0.1, 0.90, -3.33)
    T1[4, .] = (0.2, 0.79, -3.55)
    T1[5, .] = (0.2, 0.80, -3.54)
    T1[6, .] = (0.3, 0.69, -3.70)
    T1[7, .] = (0.3, 0.70, -3.71)
    T1[8, .] = (0.4, 0.59, -3.81)
    T1[9, .] = (0.4, 0.60, -3.84)
    T1[10, .] = (0.5, 0.49, -3.92)
    T1[11, .] = (0.5, 0.50, -3.94)
    T1[12, .] = (0.6, 0.39, -3.97)
    T1[13, .] = (0.6, 0.40, -4.00)
    T1[14, .] = (0.7, 0.29, -3.98)
    T1[15, .] = (0.7, 0.30, -4.03)
    T1[16, .] = (0.8, 0.19, -4.01)
    T1[17, .] = (0.8, 0.20, -4.03)
    T1[18, .] = (0.9, 0.09, -4.02)
    T1[19, .] = (0.9, 0.10, -4.03)
    return(T1)
}

real rowvector cve_fkm(real scalar a, real scalar b)
{
    real matrix T1
    real scalar s, cv, d, dmin, j, aa
    s = a + b
    if (s >= 1.02) {
        return((-3.428 - 1.79 * a, 3, .))
    }
    if (abs(s - 1) < 0.02) {
        aa = a
        if (aa < 0) {
            aa = 0
        }
        if (aa > 1) {
            aa = 1
        }
        return((-3.20 - 2.02 * aa + 1.25 * aa * aa, 2, .))
    }
    T1 = cve_fkmtab()
    dmin = .
    cv   = .
    for (j = 1; j <= rows(T1); j = j + 1) {
        d = sqrt((a - T1[j, 1]) * (a - T1[j, 1]) + (b - T1[j, 2]) * (b - T1[j, 2]))
        if (d < dmin) {
            dmin = d
            cv   = T1[j, 3]
        }
    }
    if (dmin > 0.05) {
        return((-3.38, 1, dmin))
    }
    return((cv, 1, dmin))
}

// ---------------------------------------------------------------------------
//  Published critical values.  Every function returns
//    (cv01, cv05, cv10, code)
//  where cv01/cv05/cv10 are the critical values for tests at the 1/5/10%
//  levels (lower quantiles for left-tailed tests, upper quantiles for the
//  right-tailed F and Lambda tests) and
//    code 0 = configuration not tabulated
//    code 1 = tabulated value (asymptotic, or the tabulated sample size)
//    code 2 = interpolated linearly in 1/T between tabulated sample sizes
//    code 3 = T outside the tabulated range: nearest tabulated sample size
// ---------------------------------------------------------------------------

// Enders & Siklos (2001, working-paper version) Table 1 (TAR, F) and Table 2
// (M-TAR, F(M)); threshold fixed at zero, constant in the cointegrating
// regression; two-variable (m = 1) and three-variable (m = 2) cases;
// T = 100 and 500; 0, 1 and 4 lagged changes.  Row blocks: (mtar, m, T);
// columns (lag 0: 90 95 99 | lag 1: 90 95 99 | lag 4: 90 95 99).
real rowvector cve_tab_es(real scalar mt, real scalar m, real scalar p, real scalar T)
{
    real matrix A
    real rowvector a1, a5, a
    real scalar r0, lc, w, code
    if (m < 1 | m > 2) {
        return((., ., ., 0))
    }
    lc = .
    if (p == 0) {
        lc = 1
    }
    if (p == 1) {
        lc = 4
    }
    if (p == 4) {
        lc = 7
    }
    if (missing(lc)) {
        return((., ., ., 0))
    }
    A = J(8, 9, .)
    A[1, .] = (5.04, 6.07, 8.20, 4.99, 5.98, 8.21, 4.94, 5.91, 8.22)
    A[2, .] = (4.87, 5.80, 7.89, 4.89, 5.84, 8.04, 4.91, 5.82, 7.95)
    A[3, .] = (6.35, 7.53, 9.94, 6.34, 7.47, 10.00, 6.24, 7.36, 9.79)
    A[4, .] = (6.24, 7.32, 9.70, 6.23, 7.32, 9.64, 6.20, 7.30, 9.64)
    A[5, .] = (5.52, 6.57, 9.04, 5.43, 6.45, 8.75, 5.34, 6.35, 8.73)
    A[6, .] = (5.29, 6.34, 8.54, 5.35, 6.33, 8.61, 5.32, 6.30, 8.53)
    A[7, .] = (6.85, 8.03, 10.56, 6.82, 7.97, 10.60, 6.69, 7.86, 10.35)
    A[8, .] = (6.67, 7.80, 10.22, 6.67, 7.81, 10.14, 6.64, 7.75, 10.15)
    r0 = 4 * mt + 2 * (m - 1) + 1
    a1 = A[|r0, lc \ r0, lc + 2|]
    a5 = A[|r0 + 1, lc \ r0 + 1, lc + 2|]
    if (T <= 100) {
        a = a1
        code = 1
        if (T < 100) {
            code = 3
        }
    }
    else if (T >= 500) {
        a = a5
        code = 1
        if (T > 500) {
            code = 3
        }
    }
    else {
        w = (1 / T - 1 / 500) / (1 / 100 - 1 / 500)
        a = w :* a1 :+ (1 - w) :* a5
        code = 2
    }
    return((a[3], a[2], a[1], code))
}

// Kapetanios, Shin & Snell (2006; WP 497) Table 1: asymptotic critical values
// of t_NLEG (ecm = 0) and t_NLECM (ecm = 1); k = m = 1..5 regressors;
// Case 1 raw data (det 0), Case 2 demeaned (det 1), Case 3 detrended (det 2).
// Columns: (Case 1: 90 95 99 | Case 2: 90 95 99 | Case 3: 90 95 99).
real rowvector cve_tab_kss(real scalar ecm, real scalar m, real scalar det)
{
    real matrix K
    real scalar c0
    if (m < 1 | m > 5 | det < 0 | det > 2) {
        return((., ., ., 0))
    }
    K = J(5, 9, .)
    if (ecm == 0) {
        K[1, .] = (-2.59, -2.85, -3.38, -2.98, -3.28, -3.84, -3.41, -3.71, -4.26)
        K[2, .] = (-3.01, -3.30, -3.89, -3.36, -3.67, -4.23, -3.64, -3.99, -4.53)
        K[3, .] = (-3.34, -3.66, -4.23, -3.63, -3.93, -4.50, -3.90, -4.18, -4.76)
        K[4, .] = (-3.65, -3.95, -4.56, -3.90, -4.19, -4.68, -4.09, -4.39, -4.95)
        K[5, .] = (-3.88, -4.13, -4.75, -4.10, -4.42, -4.97, -4.36, -4.67, -5.23)
    }
    else {
        K[1, .] = (-2.38, -2.66, -3.35, -2.92, -3.22, -3.78, -3.30, -3.59, -4.17)
        K[2, .] = (-2.67, -3.01, -3.59, -3.12, -3.43, -4.00, -3.46, -3.79, -4.40)
        K[3, .] = (-2.95, -3.28, -3.93, -3.32, -3.61, -4.19, -3.62, -3.96, -4.54)
        K[4, .] = (-3.15, -3.47, -4.14, -3.46, -3.77, -4.38, -3.75, -4.07, -4.70)
        K[5, .] = (-3.33, -3.67, -4.31, -3.58, -3.92, -4.53, -3.87, -4.20, -4.85)
    }
    c0 = 3 * det
    return((K[m, c0 + 3], K[m, c0 + 2], K[m, c0 + 1], 1))
}

// Gregory & Hansen (1996) Table 1, approximate asymptotic critical values,
// trimming [0.15, 0.85]; st = 1 ADF* and Zt*, st = 2 Za*;
// model 1 = C, 2 = C/T, 3 = C/S; m = 1..4.  Columns (0.01, 0.05, 0.10).
real rowvector cve_tab_gh(real scalar st, real scalar model, real scalar m)
{
    real matrix G
    real scalar r
    if (m < 1 | m > 4 | model < 1 | model > 3) {
        return((., ., ., 0))
    }
    G = J(12, 3, .)
    if (st == 1) {
        G[1, .]  = (-5.13, -4.61, -4.34)
        G[2, .]  = (-5.45, -4.99, -4.72)
        G[3, .]  = (-5.47, -4.95, -4.68)
        G[4, .]  = (-5.44, -4.92, -4.69)
        G[5, .]  = (-5.80, -5.29, -5.03)
        G[6, .]  = (-5.97, -5.50, -5.23)
        G[7, .]  = (-5.77, -5.28, -5.02)
        G[8, .]  = (-6.05, -5.57, -5.33)
        G[9, .]  = (-6.51, -6.00, -5.75)
        G[10, .] = (-6.05, -5.56, -5.31)
        G[11, .] = (-6.36, -5.83, -5.59)
        G[12, .] = (-6.92, -6.41, -6.17)
    }
    else {
        G[1, .]  = (-50.07, -40.48, -36.19)
        G[2, .]  = (-57.28, -47.96, -43.22)
        G[3, .]  = (-57.17, -47.04, -41.85)
        G[4, .]  = (-57.01, -46.98, -42.49)
        G[5, .]  = (-64.77, -53.92, -48.94)
        G[6, .]  = (-68.21, -58.33, -52.85)
        G[7, .]  = (-63.64, -53.58, -48.65)
        G[8, .]  = (-70.27, -59.76, -54.94)
        G[9, .]  = (-80.15, -68.94, -63.42)
        G[10, .] = (-70.18, -59.40, -54.38)
        G[11, .] = (-76.95, -65.44, -60.12)
        G[12, .] = (-90.35, -78.52, -72.56)
    }
    r = 3 * (m - 1) + model
    return((G[r, 1], G[r, 2], G[r, 3], 1))
}

// Hatemi-J (2008) Table 1, two regime shifts, trimming 0.15;
// st = 1 ADF* and Zt*, st = 2 Za*; m = 1..4.  Columns (1%, 5%, 10%).
real rowvector cve_tab_hj(real scalar st, real scalar m)
{
    real matrix H
    if (m < 1 | m > 4) {
        return((., ., ., 0))
    }
    H = J(4, 3, .)
    if (st == 1) {
        H[1, .] = (-6.503, -6.015, -5.653)
        H[2, .] = (-6.928, -6.458, -6.224)
        H[3, .] = (-7.833, -7.352, -7.118)
        H[4, .] = (-8.353, -7.903, -7.705)
    }
    else {
        H[1, .] = (-90.794, -76.003, -52.232)
        H[2, .] = (-99.458, -83.644, -76.806)
        H[3, .] = (-118.577, -104.860, -97.749)
        H[4, .] = (-140.135, -123.870, -116.169)
    }
    return((H[m, 1], H[m, 2], H[m, 3], 1))
}

// Breitung (2002; SFB 373 DP 1999) Table A.2: critical values of Lambda_q
// (T = 500), mean adjusted (det 1) or trend adjusted (det 2); rows q = 1..8
// (the printed row label "r = n - q" is the number of stochastic trends q:
// row 1 equals 1/(T^-2 rho_T) of Table A.1 at T = 500).  Columns (1%, 5%, 10%).
real rowvector cve_tab_br(real scalar q, real scalar det)
{
    real matrix Bm
    if (q < 1 | q > 8 | det < 1 | det > 2) {
        return((., ., ., 0))
    }
    Bm = J(16, 3, .)
    Bm[1, .]  = (185.0, 95.60, 67.89)
    Bm[2, .]  = (505.8, 329.9, 261.0)
    Bm[3, .]  = (1024, 741.1, 627.8)
    Bm[4, .]  = (1702, 1360, 1200)
    Bm[5, .]  = (2761, 2255, 2025)
    Bm[6, .]  = (4045, 3460, 3177)
    Bm[7, .]  = (5905, 5049, 4650)
    Bm[8, .]  = (8032, 7061, 6565)
    Bm[9, .]  = (443.6, 281.1, 222.4)
    Bm[10, .] = (976.1, 713.3, 596.2)
    Bm[11, .] = (1689, 1330, 1158)
    Bm[12, .] = (2699, 2184, 1972)
    Bm[13, .] = (4120, 3429, 3107)
    Bm[14, .] = (5780, 4954, 4572)
    Bm[15, .] = (8012, 6984, 6484)
    Bm[16, .] = (10714, 9388, 8830)
    return((Bm[8 * (det - 1) + q, 1], Bm[8 * (det - 1) + q, 2], Bm[8 * (det - 1) + q, 3], 1))
}

// dispatcher: test column j (see cve_stats), m regressors, det, lag p used by
// the observed statistic, trimming, series length T, shift (1 regime, 0 level)
// and threshold rule thr (1 zero, 0 estimated)
real rowvector cve_tabcv(real scalar j, real scalar m, real scalar det, real scalar p,
                         real scalar trim, real scalar T, real scalar shift,
                         real scalar thr)
{
    real rowvector z
    real scalar model, st, t15
    z = (., ., ., 0)
    t15 = (abs(trim - 0.15) < 1e-8)
    if (j == 5 | j == 6) {
        if (thr == 1 & det == 1) {
            z = cve_tab_es(j - 5, m, p, T)
        }
    }
    if (j == 7) {
        z = cve_tab_kss(0, m, det)
    }
    if (j == 11) {
        z = cve_tab_kss(1, m, det)
    }
    if (j == 8 | j == 12 | j == 13) {
        if (t15 == 1) {
            model = 0
            if (shift == 0 & det == 1) {
                model = 1
            }
            if (shift == 0 & det == 2) {
                model = 2
            }
            if (shift == 1 & det == 1) {
                model = 3
            }
            if (model > 0) {
                st = 1
                if (j == 13) {
                    st = 2
                }
                z = cve_tab_gh(st, model, m)
            }
        }
    }
    if (j == 9 | j == 14 | j == 15) {
        if (t15 == 1 & shift == 1 & det == 1) {
            st = 1
            if (j == 15) {
                st = 2
            }
            z = cve_tab_hj(st, m)
        }
    }
    if (j == 10) {
        z = cve_tab_br(m + 1, det)
    }
    return(z)
}

// ---------------------------------------------------------------------------
//  Main entry point for -cointvol resid-
//  res columns: 1 stat, 2 cv01, 3 cv05, 4 cv10, 5 p_sim, 6 p_boot, 7 lags,
//               8 tail, 9 param1, 10 param2, 11 boot cv05, 12 simreps used,
//               13 table cv01, 14 table cv05, 15 table cv10, 16 table code
//  simmode: 0 no simulation, 1 simulate the tests without a published table,
//           2 simulate every requested test
// ---------------------------------------------------------------------------

void cve_resid_main(string scalar vars, string scalar touse, real scalar det,
                    real scalar lagmode, real scalar pfix, real scalar pmax,
                    real scalar trim, real scalar shift, real scalar thr,
                    string scalar wstr, real scalar simmode, real scalar R1,
                    real scalar R2, real scalar ga, real scalar gb, real scalar B,
                    string scalar mult, real scalar dots)
{
    real matrix Y, X, obs, res, S1, S2, Sb
    real colvector y
    real rowvector w, ws, wl, wg, tail, tc, isb
    real scalar T0, n, m, j
    Y  = st_data(., tokens(vars), touse)
    T0 = rows(Y)
    n  = cols(Y)
    m  = n - 1
    y  = Y[., 1]
    X  = Y[|1, 2 \ T0, n|]
    w  = strtoreal(tokens(wstr))
    tail = (-1, -1, 1, -1, 1, 1, -1, -1, -1, 1, -1, -1, -1, -1, -1)
    isb  = (0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 1, 1, 1)

    obs = cve_stats(y, X, det, lagmode, pfix, pmax, trim, shift, thr, w)
    res = J(15, 16, .)
    res[., 1]  = obs[1, .]'
    res[., 7]  = obs[2, .]'
    res[., 8]  = tail'
    res[., 9]  = obs[3, .]'
    res[., 10] = obs[4, .]'
    res[., 16] = J(15, 1, 0)
    for (j = 1; j <= 15; j = j + 1) {
        if (w[j] == 0) {
            continue
        }
        tc = cve_tabcv(j, m, det, res[j, 7], trim, T0, shift, thr)
        res[j, 13] = tc[1]
        res[j, 14] = tc[2]
        res[j, 15] = tc[3]
        res[j, 16] = tc[4]
    }

    ws = J(1, 15, 0)
    for (j = 1; j <= 15; j = j + 1) {
        if (w[j] == 1) {
            if (simmode == 2) {
                ws[j] = 1
            }
            if (simmode == 1) {
                if (res[j, 16] == 0) {
                    ws[j] = 1
                }
            }
        }
    }
    wl = ws :* (1 :- isb)
    wg = ws :* isb
    if (R1 > 0) {
        if (sum(wl) > 0) {
            if (dots == 1) {
                printf("{txt}Simulating the null distribution (R = %g): ", R1)
                displayflush()
            }
            S1 = cve_simnull(T0, m, det, lagmode, pfix, pmax, trim, shift, thr, wl, R1,
                             ga, gb, dots)
            cve_fillcv(res, S1, wl, R1)
        }
    }
    if (R2 > 0) {
        if (sum(wg) > 0) {
            if (dots == 1) {
                printf("{txt}Simulating the null distribution of the break tests (R = %g): ", R2)
                displayflush()
            }
            S2 = cve_simnull(T0, m, det, lagmode, pfix, pmax, trim, shift, thr, wg, R2,
                             ga, gb, dots)
            cve_fillcv(res, S2, wg, R2)
        }
    }
    if (B > 0) {
        if (dots == 1) {
            printf("{txt}Wild bootstrap (B = %g): ", B)
            displayflush()
        }
        Sb = cve_bootwild(y, X, det, lagmode, pfix, pmax, trim, shift, thr, w, B, mult, dots)
        for (j = 1; j <= 15; j = j + 1) {
            if (w[j] == 0) {
                continue
            }
            res[j, 6] = cve_pv(Sb[., j], res[j, 1], tail[j], 0)
            if (tail[j] < 0) {
                res[j, 11] = cve_quant(Sb[., j], 0.05)
            }
            else {
                res[j, 11] = cve_quant(Sb[., j], 0.95)
            }
        }
        st_matrix("__cve_boot", Sb)
    }
    st_matrix("__cve_res", res)
    st_numscalar("__cve_T", T0)
}

// ---------------------------------------------------------------------------
//  Single-equation ECM tests
// ---------------------------------------------------------------------------

// Ericsson & MacKinnon (2002) Tables 2-5: response-surface coefficients
// (theta_inf, theta_1, theta_2, theta_3) of eq (26),
//   q(p) = theta_inf + theta_1/Ta + theta_2/Ta^2 + theta_3/Ta^3,
// row = 36 d + 3 (k - 1) + s, d = 0 nc, 1 c, 2 ct, 3 ctt (Tables 2, 3, 4, 5),
// k = 1..12 variables, s = 1, 2, 3 for the 1%, 5%, 10% quantiles.
real matrix cve_emtab()
{
    real matrix E
    E = J(144, 4, .)
    E[1, .] = (-2.5659, -2.19, -3.6, 26)
    E[2, .] = (-1.9408, -0.35, 0.6, -17)
    E[3, .] = (-1.6167, 0.23, -1, -6)
    E[4, .] = (-3.2106, -4.69, -10.5, 48)
    E[5, .] = (-2.5937, -1.53, -0.8, -24)
    E[6, .] = (-2.2643, -0.41, -1.5, -9)
    E[7, .] = (-3.6215, -6.14, -5.3, -67)
    E[8, .] = (-3.0048, -2.11, 2.1, -61)
    E[9, .] = (-2.6744, -0.57, 1.2, -44)
    E[10, .] = (-3.9433, -7.15, -3.1, -69)
    E[11, .] = (-3.3268, -2.04, -6.4, 19)
    E[12, .] = (-2.9942, -0.21, -5.1, 13)
    E[13, .] = (-4.2168, -7.66, -2.1, -87)
    E[14, .] = (-3.5978, -1.92, -3.6, -17)
    E[15, .] = (-3.2637, 0.25, -4.2, -15)
    E[16, .] = (-4.4585, -7.72, -7.2, -57)
    E[17, .] = (-3.8373, -1.38, -7.7, -6)
    E[18, .] = (-3.5022, 1.15, -11.1, 12)
    E[19, .] = (-4.6763, -7.78, -5.1, -73)
    E[20, .] = (-4.0535, -0.76, -10, -7)
    E[21, .] = (-3.7165, 2.04, -14.7, 15)
    E[22, .] = (-4.8772, -7.64, -2.4, -116)
    E[23, .] = (-4.2513, -0.03, -12, -19)
    E[24, .] = (-3.9135, 3.1, -20.3, 25)
    E[25, .] = (-5.0634, -7.13, -6.9, -113)
    E[26, .] = (-4.4363, 1, -18.4, -8)
    E[27, .] = (-4.0974, 4.46, -32.1, 74)
    E[28, .] = (-5.2381, -6.68, -4.7, -149)
    E[29, .] = (-4.6093, 2.11, -25.4, 10)
    E[30, .] = (-4.2693, 5.76, -38.2, 72)
    E[31, .] = (-5.4039, -6.05, -7.1, -163)
    E[32, .] = (-4.7734, 3.37, -35.4, 48)
    E[33, .] = (-4.4324, 7.33, -53.3, 145)
    E[34, .] = (-5.5598, -5.1, -19.4, -75)
    E[35, .] = (-4.9279, 4.77, -48.8, 109)
    E[36, .] = (-4.5864, 8.96, -68, 204)
    E[37, .] = (-3.4307, -6.52, -4.7, -10)
    E[38, .] = (-2.8617, -2.81, -3.2, 37)
    E[39, .] = (-2.5668, -1.56, 2.1, -29)
    E[40, .] = (-3.7948, -7.87, -3.6, -28)
    E[41, .] = (-3.2145, -3.21, -2, 17)
    E[42, .] = (-2.9083, -1.55, 1.9, -25)
    E[43, .] = (-4.0947, -8.59, -2, -65)
    E[44, .] = (-3.5057, -3.27, 1.1, -34)
    E[45, .] = (-3.1924, -1.23, 2.1, -39)
    E[46, .] = (-4.3555, -8.9, -6.7, -31)
    E[47, .] = (-3.7592, -2.92, -3.7, 5)
    E[48, .] = (-3.4412, -0.53, -4.5, 4)
    E[49, .] = (-4.5859, -9.14, -2.5, -78)
    E[50, .] = (-3.9856, -2.5, -1.7, -35)
    E[51, .] = (-3.6635, 0.21, -6, -8)
    E[52, .] = (-4.797, -9.04, -5.6, -66)
    E[53, .] = (-4.1922, -1.73, -7.8, -9)
    E[54, .] = (-3.867, 1.26, -12.7, 14)
    E[55, .] = (-4.9912, -8.85, -5.1, -72)
    E[56, .] = (-4.3831, -0.9, -12.2, 1)
    E[57, .] = (-4.0556, 2.39, -18.8, 27)
    E[58, .] = (-5.1723, -8.58, -2, -113)
    E[59, .] = (-4.5608, 0.02, -15.4, -2)
    E[60, .] = (-4.231, 3.59, -25.6, 44)
    E[61, .] = (-5.3437, -7.86, -7.8, -101)
    E[62, .] = (-4.7287, 1.25, -26, 42)
    E[63, .] = (-4.3975, 5.11, -39.2, 104)
    E[64, .] = (-5.5048, -7.19, -9.8, -102)
    E[65, .] = (-4.8876, 2.46, -31.7, 43)
    E[66, .] = (-4.5543, 6.53, -47.2, 116)
    E[67, .] = (-5.6588, -6.39, -13.7, -105)
    E[68, .] = (-5.0394, 3.88, -45.7, 117)
    E[69, .] = (-4.7055, 8.31, -66.5, 222)
    E[70, .] = (-5.8068, -5.13, -29.2, -15)
    E[71, .] = (-5.1836, 5.33, -55.9, 134)
    E[72, .] = (-4.848, 9.94, -78, 240)
    E[73, .] = (-3.9593, -8.99, -4.9, 39)
    E[74, .] = (-3.4108, -4.38, 4.5, -21)
    E[75, .] = (-3.1272, -2.57, 3.5, -7)
    E[76, .] = (-4.2488, -10.04, -4.1, -1)
    E[77, .] = (-3.6873, -4.56, 2.2, 1)
    E[78, .] = (-3.3927, -2.41, 3.4, -14)
    E[79, .] = (-4.4981, -10.69, 0.6, -58)
    E[80, .] = (-3.9263, -4.47, 5.2, -38)
    E[81, .] = (-3.6249, -1.86, 1.1, -10)
    E[82, .] = (-4.7214, -10.94, 1.6, -77)
    E[83, .] = (-4.1421, -3.99, 2.8, -35)
    E[84, .] = (-3.8342, -1.16, 0.4, -23)
    E[85, .] = (-4.9255, -10.86, 1.2, -94)
    E[86, .] = (-4.3392, -3.37, 1.6, -47)
    E[87, .] = (-4.0271, -0.17, -4.4, -14)
    E[88, .] = (-5.1137, -10.72, 1.4, -96)
    E[89, .] = (-4.5227, -2.52, -2.8, -32)
    E[90, .] = (-4.2067, 0.94, -9.9, 0)
    E[91, .] = (-5.2923, -10.11, -4, -75)
    E[92, .] = (-4.6952, -1.43, -10.6, -5)
    E[93, .] = (-4.3751, 2.18, -16.9, 18)
    E[94, .] = (-5.4565, -9.77, -1.5, -106)
    E[95, .] = (-4.8569, -0.43, -14.4, -3)
    E[96, .] = (-4.5344, 3.52, -24.9, 40)
    E[97, .] = (-5.6149, -9.11, -2, -126)
    E[98, .] = (-5.0108, 0.78, -21.2, 12)
    E[99, .] = (-4.6864, 5.08, -37.2, 88)
    E[100, .] = (-5.7657, -8.28, -5.3, -121)
    E[101, .] = (-5.1582, 2.12, -28.6, 26)
    E[102, .] = (-4.8311, 6.62, -46.2, 103)
    E[103, .] = (-5.9099, -7.41, -6.2, -160)
    E[104, .] = (-5.2992, 3.57, -40, 69)
    E[105, .] = (-4.9707, 8.41, -64.7, 199)
    E[106, .] = (-6.0478, -6.17, -20.6, -74)
    E[107, .] = (-5.4346, 5.22, -54.5, 121)
    E[108, .] = (-5.1046, 10.2, -78.3, 231)
    E[109, .] = (-4.3714, -11.57, 7.4, -66)
    E[110, .] = (-3.8324, -5.9, 9.3, -29)
    E[111, .] = (-3.5534, -3.63, 6.6, -7)
    E[112, .] = (-4.619, -12.44, 11.6, -130)
    E[113, .] = (-4.0683, -5.9, 9.3, -39)
    E[114, .] = (-3.78, -3.28, 7.8, -36)
    E[115, .] = (-4.8399, -12.71, 10.7, -136)
    E[116, .] = (-4.279, -5.56, 9.3, -55)
    E[117, .] = (-3.9833, -2.61, 6.6, -42)
    E[118, .] = (-5.0396, -12.86, 13, -149)
    E[119, .] = (-4.4716, -4.95, 6.9, -50)
    E[120, .] = (-4.1701, -1.72, 3.8, -37)
    E[121, .] = (-5.2256, -12.61, 8.3, -121)
    E[122, .] = (-4.6498, -4.23, 5.7, -58)
    E[123, .] = (-4.3438, -0.64, -1, -27)
    E[124, .] = (-5.3998, -12.12, 4.3, -105)
    E[125, .] = (-4.8177, -3.22, -0.4, -36)
    E[126, .] = (-4.5073, 0.6, -7.7, -7)
    E[127, .] = (-5.5652, -11.31, -4, -71)
    E[128, .] = (-4.9774, -1.96, -9.3, -8)
    E[129, .] = (-4.6629, 2.02, -16.1, 15)
    E[130, .] = (-5.7181, -10.97, 0.8, -108)
    E[131, .] = (-5.1265, -0.96, -10.9, -17)
    E[132, .] = (-4.8098, 3.41, -23.3, 31)
    E[133, .] = (-5.8656, -10.32, 4.3, -151)
    E[134, .] = (-5.2703, 0.33, -16.2, -17)
    E[135, .] = (-4.951, 5.04, -35.4, 74)
    E[136, .] = (-6.0083, -9.26, -4, -117)
    E[137, .] = (-5.4083, 1.8, -26.5, 17)
    E[138, .] = (-5.0863, 6.63, -43.9, 85)
    E[139, .] = (-6.1449, -8.26, -4.7, -158)
    E[140, .] = (-5.5415, 3.38, -39, 60)
    E[141, .] = (-5.2176, 8.54, -63.7, 179)
    E[142, .] = (-6.2746, -7.13, -13.5, -111)
    E[143, .] = (-5.6697, 5.12, -54.1, 117)
    E[144, .] = (-5.3436, 10.36, -76.3, 206)
    return(E)
}

// finite-sample E&M critical values (1%, 5%, 10%) for kappa_d(k) at adjusted
// sample size Ta = T - h (E&M sec. 5: h = number of regressors incl. deterministics)
real rowvector cve_emcv(real scalar k, real scalar det, real scalar Ta)
{
    real matrix E
    real rowvector c
    real scalar s, r
    if (missing(k) | missing(det) | missing(Ta)) {
        return((., ., .))
    }
    if (k < 1 | k > 12 | det < 0 | det > 3 | Ta <= 0) {
        return((., ., .))
    }
    E = cve_emtab()
    c = J(1, 3, .)
    for (s = 1; s <= 3; s = s + 1) {
        r = 36 * det + 3 * (k - 1) + s
        c[s] = E[r, 1] + E[r, 2] / Ta + E[r, 3] / (Ta * Ta) + E[r, 4] / (Ta * Ta * Ta)
    }
    return(c)
}

// approximate p-value from the three E&M quantiles c = (c01, c05, c10):
// probit interpolation z(t) = Phi^-1(p) through (c_s, Phi^-1(s)), s = .01,.05,.10
// (quadratic Newton form; linear end-segment extrapolation where the quadratic
// is not increasing).  Extended implementation: E&M's own p-values come from
// their program, which is not printed in the paper.
real scalar cve_emp(real scalar t, real rowvector c)
{
    real rowvector z
    real scalar d1, d2, g2, zq, der, zz
    if (missing(t) | hasmissing(c)) {
        return(.)
    }
    z  = (invnormal(0.01), invnormal(0.05), invnormal(0.10))
    d1 = (z[2] - z[1]) / (c[2] - c[1])
    d2 = (z[3] - z[2]) / (c[3] - c[2])
    g2 = (d2 - d1) / (c[3] - c[1])
    zq = z[1] + d1 * (t - c[1]) + g2 * (t - c[1]) * (t - c[2])
    der = d1 + g2 * ((t - c[1]) + (t - c[2]))
    if (der > 0.5 * min((d1, d2))) {
        zz = zq
    }
    else {
        if (t < c[2]) {
            zz = z[1] + d1 * (t - c[1])
        }
        else {
            zz = z[3] + d2 * (t - c[3])
        }
    }
    return(normal(zz))
}

// Banerjee, Dolado & Mestre (1998) Table I, critical values of the t-ratio ECM
// test (signs restored); rows: 25 (det - 1) + 5 (mb - 1) + i, det 1 constant,
// 2 constant and trend, mb = 1..5 regressors, i = 1..5 for T = 25, 50, 100,
// 500, infinity; columns (1%, 5%, 10%, 25%).
real matrix cve_bdmtab()
{
    real matrix A
    A = J(50, 4, .)
    A[1, .]  = (4.12, 3.35, 2.95, 2.36)
    A[2, .]  = (3.94, 3.28, 2.93, 2.38)
    A[3, .]  = (3.92, 3.27, 2.94, 2.40)
    A[4, .]  = (3.82, 3.23, 2.90, 2.40)
    A[5, .]  = (3.78, 3.19, 2.89, 2.41)
    A[6, .]  = (4.53, 3.64, 3.24, 2.60)
    A[7, .]  = (4.29, 3.57, 3.20, 2.63)
    A[8, .]  = (4.22, 3.56, 3.22, 2.67)
    A[9, .]  = (4.11, 3.50, 3.10, 2.66)
    A[10, .] = (4.06, 3.48, 3.19, 2.65)
    A[11, .] = (4.92, 3.91, 3.46, 2.76)
    A[12, .] = (4.59, 3.82, 3.45, 2.84)
    A[13, .] = (4.49, 3.82, 3.47, 2.90)
    A[14, .] = (4.47, 3.77, 3.45, 2.90)
    A[15, .] = (4.46, 3.74, 3.42, 2.89)
    A[16, .] = (5.27, 4.18, 3.68, 2.90)
    A[17, .] = (4.85, 4.05, 3.64, 3.03)
    A[18, .] = (4.71, 4.03, 3.67, 3.10)
    A[19, .] = (4.62, 3.99, 3.67, 3.11)
    A[20, .] = (4.57, 3.97, 3.66, 3.10)
    A[21, .] = (5.53, 4.46, 3.82, 2.99)
    A[22, .] = (5.04, 4.43, 3.82, 3.18)
    A[23, .] = (4.92, 4.30, 3.85, 3.28)
    A[24, .] = (4.81, 4.39, 3.86, 3.32)
    A[25, .] = (4.70, 4.27, 3.82, 3.29)
    A[26, .] = (4.77, 3.89, 3.48, 2.88)
    A[27, .] = (4.48, 3.78, 3.44, 2.92)
    A[28, .] = (4.35, 3.75, 3.43, 2.91)
    A[29, .] = (4.30, 3.71, 3.41, 2.91)
    A[30, .] = (4.27, 3.69, 3.39, 2.89)
    A[31, .] = (5.12, 4.18, 3.72, 3.04)
    A[32, .] = (4.76, 4.04, 3.66, 3.09)
    A[33, .] = (4.60, 3.98, 3.66, 3.11)
    A[34, .] = (4.54, 3.94, 3.64, 3.11)
    A[35, .] = (4.51, 3.91, 3.62, 3.10)
    A[36, .] = (5.42, 4.39, 3.89, 3.16)
    A[37, .] = (5.04, 4.25, 3.86, 3.25)
    A[38, .] = (4.86, 4.19, 3.86, 3.30)
    A[39, .] = (4.76, 4.15, 3.84, 3.31)
    A[40, .] = (4.72, 4.12, 3.82, 3.29)
    A[41, .] = (5.79, 4.56, 4.04, 3.26)
    A[42, .] = (5.21, 4.43, 4.03, 3.39)
    A[43, .] = (5.07, 4.38, 4.02, 3.46)
    A[44, .] = (4.93, 4.34, 4.02, 3.47)
    A[45, .] = (4.89, 4.30, 4.00, 3.45)
    A[46, .] = (6.18, 4.76, 4.16, 3.31)
    A[47, .] = (5.37, 4.60, 4.19, 3.53)
    A[48, .] = (5.24, 4.55, 4.19, 3.66)
    A[49, .] = (5.15, 4.54, 4.20, 3.69)
    A[50, .] = (5.11, 4.52, 4.18, 3.67)
    return(-A)
}

// BDM critical values (1%, 5%, 10%, code) for mb regressors, det 1 or 2 and
// sample size T, linear interpolation in 1/T between the tabulated sizes
real rowvector cve_bdmcv(real scalar mb, real scalar det, real scalar T)
{
    real matrix A
    real rowvector iv, a
    real scalar r0, x, i, w, code
    if (mb < 1 | mb > 5 | det < 1 | det > 2 | missing(T)) {
        return((., ., ., 0))
    }
    A  = cve_bdmtab()
    iv = (1 / 25, 1 / 50, 1 / 100, 1 / 500, 0)
    r0 = 25 * (det - 1) + 5 * (mb - 1)
    x  = 1 / T
    if (x >= iv[1]) {
        a = A[r0 + 1, .]
        code = 1
        if (T < 25) {
            code = 3
        }
        return((a[1], a[2], a[3], code))
    }
    for (i = 1; i <= 4; i = i + 1) {
        if (x <= iv[i]) {
            if (x >= iv[i + 1]) {
                w = (x - iv[i + 1]) / (iv[i] - iv[i + 1])
                a = w :* A[r0 + i, .] :+ (1 - w) :* A[r0 + i + 1, .]
                code = 2
                if (abs(x - iv[i]) < 1e-12) {
                    code = 1
                }
                if (abs(x - iv[i + 1]) < 1e-12) {
                    code = 1
                }
                return((a[1], a[2], a[3], code))
            }
        }
    }
    return((., ., ., 0))
}

// Regressors of the single-equation conditional ECM, t = p+2..T0:
//   mode 0 (known beta, KED eq 3):  [dx | y(t-1) - beta x(t-1) | det | lags]
//   mode 1 (estimated coefficients, BDM eq 1', E&M eqs 16, 24):
//                                   [dx | y(t-1), x(t-1)' | det | lags]
//   det: 0 none, 1 constant, 2 + trend, 3 + trend^2 (trend scaled by 1/T0;
//   the t-ratio is invariant to this scaling); lags: (dy(t-j), dx(t-j)'), j = 1..p.
//   The tested coefficient is in column m + 1.
void cve_ecmZ(real colvector y, real matrix X, real scalar mode, real scalar beta,
              real scalar det, real scalar p, real matrix Z, real colvector dy,
              real scalar nlev)
{
    real colvector idx, tt
    real scalar T0, j
    T0  = rows(y)
    idx = ((p + 2)::T0)
    dy  = y[idx] - y[idx :- 1]
    Z   = X[idx, .] - X[idx :- 1, .]
    if (mode == 0) {
        Z = Z, (y[idx :- 1] - beta :* X[idx :- 1, 1])
        nlev = 1
    }
    else {
        Z = Z, y[idx :- 1], X[idx :- 1, .]
        nlev = 1 + cols(X)
    }
    tt = idx :/ T0
    if (det >= 1) {
        Z = Z, J(rows(idx), 1, 1)
    }
    if (det >= 2) {
        Z = Z, tt
    }
    if (det >= 3) {
        Z = Z, (tt :* tt)
    }
    for (j = 1; j <= p; j = j + 1) {
        Z = Z, (y[idx :- j] - y[idx :- j :- 1]), (X[idx :- j, .] - X[idx :- j :- 1, .])
    }
}

// OLS; returns (s2, n, k) and fills bb, se, e
real rowvector cve_ols(real matrix Z, real colvector yv, real colvector bb,
                       real colvector se, real colvector e)
{
    real matrix XX
    real scalar n, k, s2
    n  = rows(Z)
    k  = cols(Z)
    XX = invsym(cross(Z, Z))
    bb = XX * cross(Z, yv)
    e  = yv - Z * bb
    s2 = cross(e, e) / (n - k)
    se = sqrt(s2 :* diagonal(XX))
    return((s2, n, k))
}

// ECM t-ratio for one data set
real scalar cve_ecmstat(real colvector y, real matrix X, real scalar mode, real scalar beta,
                        real scalar det, real scalar p)
{
    real matrix Z
    real colvector dy
    real scalar nlev
    Z  = .
    dy = .
    nlev = .
    cve_ecmZ(y, X, mode, beta, det, p, Z, dy, nlev)
    return(cve_tcol(Z, dy, cols(X) + 1, 1))
}

// ARCH-LM(1): T R^2 from e(t)^2 on (1, e(t-1)^2); returns (LM, p)
real rowvector cve_archlm(real colvector e)
{
    real colvector s, yv, r, yc
    real matrix Z
    real scalar n, R2, lm
    s  = e :^ 2
    n  = rows(s)
    yv = s[|2 \ n|]
    Z  = J(n - 1, 1, 1), s[|1 \ n - 1|]
    r  = yv - Z * (invsym(cross(Z, Z)) * cross(Z, yv))
    yc = yv :- mean(yv)
    R2 = 1 - cross(r, r) / cross(yc, yc)
    lm = (n - 1) * R2
    return((lm, chi2tail(1, lm)))
}

// Main entry point for -cointvol ecm-
//   res rows: 1 wild bootstrap, 2 simulated null, 3 N(0,1), 4 E&M response
//             surface, 5 BDM Table I, 6 KED with q = q^ (simulated)
//   res cols: cv01 cv05 cv10 p
void cve_ecm_main(string scalar vars, string scalar touse, real scalar mode,
                  real scalar beta, real scalar det, real scalar p, real scalar B,
                  string scalar mult, real scalar restr, real scalar R,
                  real scalar dots)
{
    real matrix Y, X, Z, Zr, res, Xs
    real colvector y, dy, bb, se, e, br, ser, er, gfull, gz, phi, eb, g, dys, ys, u
    real colvector tb, ts, tk
    real rowvector f, fr, lm, em, bd
    real scalar T0, m, n, h, nlev, pos, t, q, k, Ta, i, j, jj, step, tt, v, bdcode
    Y  = st_data(., tokens(vars), touse)
    T0 = rows(Y)
    y  = Y[., 1]
    X  = Y[|1, 2 \ T0, cols(Y)|]
    m  = cols(X)
    Z  = .
    dy = .
    nlev = .
    cve_ecmZ(y, X, mode, beta, det, p, Z, dy, nlev)
    bb = .
    se = .
    e  = .
    f  = cve_ols(Z, dy, bb, se, e)
    n  = rows(Z)
    h  = cols(Z)
    pos = m + 1
    t  = bb[pos] / se[pos]
    lm = cve_archlm(e)
    q  = .
    if (mode == 0) {
        // KED eq (16): q = -(a - beta) s, s = sd(dx) / sigma_eps
        q = (beta - bb[1]) * sqrt(variance(Z[., 1])) / sqrt(f[1])
    }
    res = J(6, 4, .)

    // Ericsson-MacKinnon finite-sample critical values, Ta = T - h
    k = 1
    if (mode == 1) {
        k = m + 1
    }
    Ta = n - h
    em = cve_emcv(k, det, Ta)
    res[4, 1] = em[1]
    res[4, 2] = em[2]
    res[4, 3] = em[3]
    res[4, 4] = cve_emp(t, em)

    // Banerjee-Dolado-Mestre Table I (estimated coefficients, c or ct)
    bdcode = 0
    if (mode == 1) {
        bd = cve_bdmcv(m, det, n)
        res[5, 1] = bd[1]
        res[5, 2] = bd[2]
        res[5, 3] = bd[3]
        bdcode = bd[4]
    }

    // wild bootstrap with the null imposed (Mantalos eqs 4-5, generalised to
    // deterministics and lags; lagged dy* generated recursively)
    if (B > 0) {
        gfull = J(h, 1, 0)
        if (restr == 1) {
            Zr = Z[|1, 1 \ n, m|]
            if (h > m + nlev) {
                Zr = Zr, Z[|1, m + nlev + 1 \ n, h|]
            }
            br  = .
            ser = .
            er  = .
            fr  = cve_ols(Zr, dy, br, ser, er)
            for (j = 1; j <= m; j = j + 1) {
                gfull[j] = br[j]
            }
            for (j = m + nlev + 1; j <= h; j = j + 1) {
                gfull[j] = br[j - nlev]
            }
            eb = er
        }
        else {
            gfull = bb
            for (j = m + 1; j <= m + nlev; j = j + 1) {
                gfull[j] = 0
            }
            eb = e
        }
        phi = J(p + 1, 1, 0)
        gz  = gfull
        for (j = 1; j <= p; j = j + 1) {
            jj = m + nlev + det + (j - 1) * (1 + m) + 1
            phi[j] = gfull[jj]
            gz[jj] = 0
        }
        g  = Z * gz
        tb = J(B, 1, .)
        step = floor(B / 50)
        if (step < 1) {
            step = 1
        }
        if (dots == 1) {
            printf("{txt}Wild bootstrap (B = %g): ", B)
            displayflush()
        }
        for (i = 1; i <= B; i = i + 1) {
            u   = cve_mult(n, mult)
            dys = J(T0, 1, 0)
            if (p > 0) {
                dys[|2 \ p + 1|] = y[|2 \ p + 1|] - y[|1 \ p|]
                for (jj = 1; jj <= n; jj = jj + 1) {
                    tt = p + 1 + jj
                    v  = g[jj] + eb[jj] * u[jj]
                    for (j = 1; j <= p; j = j + 1) {
                        v = v + phi[j] * dys[tt - j]
                    }
                    dys[tt] = v
                }
            }
            else {
                dys[|2 \ T0|] = g :+ eb :* u
            }
            ys = y[1] \ (y[1] :+ runningsum(dys[|2 \ T0|]))
            tb[i] = cve_ecmstat(ys, X, mode, beta, det, p)
            if (dots == 1) {
                if (mod(i, step) == 0) {
                    printf(".")
                    displayflush()
                }
            }
        }
        if (dots == 1) {
            printf("\n")
            displayflush()
        }
        res[1, 1] = cve_quant(tb, 0.01)
        res[1, 2] = cve_quant(tb, 0.05)
        res[1, 3] = cve_quant(tb, 0.10)
        res[1, 4] = cve_pv(tb, t, -1, 0)
        st_matrix("__cve_ecmboot", tb)
    }

    // simulated null distributions, same regression, deterministics and lags
    //   mode 0: q = 0 (KED DF-type case): y = beta x + w, w and x independent
    //           random walks;  KED plug-in: dy = (beta - q^) dx + eps
    //   mode 1: E&M DGP (23): independent standard random walks
    if (R > 0) {
        ts = J(R, 1, .)
        tk = J(R, 1, .)
        for (i = 1; i <= R; i = i + 1) {
            if (mode == 0) {
                u  = rnormal(T0, 1, 0, 1)
                Xs = runningsum(u)
                ys = beta :* Xs :+ runningsum(rnormal(T0, 1, 0, 1))
                ts[i] = cve_ecmstat(ys, Xs, mode, beta, det, p)
                if (q < .) {
                    ys = runningsum((beta - q) :* u :+ rnormal(T0, 1, 0, 1))
                    tk[i] = cve_ecmstat(ys, Xs, mode, beta, det, p)
                }
            }
            else {
                ys = runningsum(rnormal(T0, 1, 0, 1))
                Xs = J(T0, m, .)
                for (j = 1; j <= m; j = j + 1) {
                    Xs[., j] = runningsum(rnormal(T0, 1, 0, 1))
                }
                ts[i] = cve_ecmstat(ys, Xs, mode, beta, det, p)
            }
        }
        res[2, 1] = cve_quant(ts, 0.01)
        res[2, 2] = cve_quant(ts, 0.05)
        res[2, 3] = cve_quant(ts, 0.10)
        res[2, 4] = cve_pv(ts, t, -1, 1)
        if (mode == 0) {
            if (q < .) {
                res[6, 1] = cve_quant(tk, 0.01)
                res[6, 2] = cve_quant(tk, 0.05)
                res[6, 3] = cve_quant(tk, 0.10)
                res[6, 4] = cve_pv(tk, t, -1, 1)
            }
        }
    }
    res[3, 1] = invnormal(0.01)
    res[3, 2] = invnormal(0.05)
    res[3, 3] = invnormal(0.10)
    res[3, 4] = normal(t)

    st_matrix("__cve_ecmres", res)
    st_matrix("__cve_ecmfit", (t, bb[pos], se[pos], f[1], n, h, Ta, lm, q, k, bdcode))
    st_matrix("__cve_ecmcoef", (bb' \ se'))
}

end
