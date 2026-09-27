*! cointvol_eng_nullcoint 0.1.0  26sep2026
*! Mata engine of -cointvol nullcoint-: KPSS/Shin-type tests of the null of
*! (linear or nonlinear) cointegration with fixed-regressor wild bootstrap
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com) - github.com/merwanroudane
*!
*! Step -> source map
*!   OLS residuals of y on (Z_t, x_t); eta = (T^2 s2)^-1 sum S_t^2, s2 = T^-1 sum u^2
*!       -> Cavaliere & Taylor (2006) eq (6); Shin (1994)
*!   heteroskedastic fixed-regressor wild bootstrap y*_t = u_t z_t, fixed regressors,
*!       p = N^-1 sum 1(eta* >= eta)            -> C&T (2006) Section 4; Hansen (2000)
*!   h(t,x,v) = [1,t,..,t^q]d + g(x,theta)     -> Hanck & Massing (2025) eqs (1)-(3)
*!   NLS (Levenberg-Marquardt)                 -> H&M eq (10)
*!   one-step DNLS, t = K+2..T-K                -> H&M eqs (18)-(21); Choi & Saikkonen (2010)
*!   eta_DNLS = (N^2 w2)^-1 sum S_t^2, N = T-2K-1 -> H&M eq (22)
*!   Bartlett LRV, l = floor(4(T/100)^(1/4))    -> H&M Section 4.1; Kwiatkowski et al. (1992)
*!   bootstrap on DNLS residuals, same LRV, p = 1 - G*(eta) -> H&M Section 3.4, Thm 3, Cor 1
*!   threshold grid search on SSR              -> H&M Section 4.4; Gonzalo & Pitarakis (2006)
*!   sieve wild bootstrap (VAR by AIC)         -> H&M Section 4.6 (exploratory, no theory)
*!   empirical variance profile                -> H&M eq (28)
*!   simulated homoskedastic Shin limit        -> C&T (2006) eq (8); Shin (1994) Thm 1
*!   C, C_mu, C_tau = T^-2 sum S_t^2 / s2(l)    -> Shin (1994) eqs (6), (13)
*!   s2(l) = T^-1 sum e^2 + 2T^-1 sum_s w(s,l) sum_t e_t e_{t-s}, Bartlett
*!                                              -> Shin (1994) Appendix; Sect. 5
*!   DOLS with leads/lags of dZ (K leads, K lags) -> Shin (1994) eqs (10)-(12), Lemma 1
*!   Table 1 critical values (m = 1..5, standard/demeaned/detrended, 15 fractiles)
*!       and interpolated p-values               -> Shin (1994) Table 1, Theorem 2
*!   NLLS / two-step leads-and-lags estimator, t = K+2..T-K, p_t = (dg/dtheta', V_t')'
*!                                              -> Choi & Saikkonen (2010) eqs (7)-(8), Thm A.2
*!   full-residual C_NLLS, C_LL                 -> C&S (2010) eqs (9), (10); Lemma A.3
*!   subresidual C^{b,i}, C^{b,max}, Bonferroni -> C&S (2010) eqs (11)-(12), Thm 1, Sect. 4.2
*!   starting points, M = [T/b]*                 -> C&S (2010) Sect. 4.2.1
*!   minimum-volatility block size, [T^.7, T^.9], m = 2 -> C&S (2010) Sect. 4.2.2
*!   cdf of int W^2                             -> C&S (2010) eq (13), Appendix B
*!   QS kernel, l = [4(b/100)^(1/4)]           -> C&S (2010) Sect. 5; Andrews (1991)

program define cointvol_eng_nullcoint
    version 14.0
end

version 14.0
capture mata: mata drop cvn_*()
capture mata: mata drop cvn_spec()

mata:

string scalar cvn_version()
{
    return("0.1.1")
}

// ---------------------------------------------------------------------------
//  Model specification
//    type 1 : linear in parameters  h = R*par, R = [Z, x, x^2, ..., x^pd]
//    type 2 : logistic smooth transition
//             h = R*b + th2 / (1 + exp(-th4*(s - th3))),  R = [Z, X], s = X[., tidx]
//             par = (b', th2, th3 [, th4])'  (th4 omitted when fixed by slope())
//    type 3 : threshold  h = R*b + (X :* 1(q_{t-1} > th3)) * c,  R = [Z, X]
//             par = (b', c', th3)'
// ---------------------------------------------------------------------------

struct cvn_spec {
    real scalar    type, m, nz, pd, slfix, sl, tidx
    real matrix    Z, X, R
    real colvector s, grid
}

real matrix cvn_det(real scalar T, real scalar qd)
{
    real matrix D
    real colvector tr
    real scalar j
    D = J(T, 0, .)
    if (qd < 0) {
        return(D)
    }
    tr = (1::T)
    D = J(T, 1, 1)
    for (j = 1; j <= qd; j = j + 1) {
        D = D, tr:^j
    }
    return(D)
}

real matrix cvn_poly(real matrix X, real scalar pd)
{
    real matrix P
    real colvector pw
    real scalar i, j
    P = J(rows(X), 0, .)
    for (i = 1; i <= cols(X); i = i + 1) {
        pw = X[., i]
        for (j = 1; j <= pd; j = j + 1) {
            P = P, pw
            pw = pw :* X[., i]
        }
    }
    return(P)
}

void cvn_setx(struct cvn_spec scalar S, real matrix X)
{
    S.X = X
    S.m = cols(X)
    if (S.type == 1) {
        S.R = S.Z, cvn_poly(X, S.pd)
    }
    else {
        S.R = S.Z, X
    }
    if (S.type == 2) {
        S.s = X[., S.tidx]
    }
}

real colvector cvn_thrgrid(real colvector qv, real scalar trim)
{
    real colvector s, g, idx
    real scalar n, lo, hi, i1, i2, ng
    s  = sort(qv, 1)
    n  = rows(s)
    i1 = ceil(trim * n)
    if (i1 < 1) {
        i1 = 1
    }
    i2 = floor((1 - trim) * n)
    if (i2 < i1) {
        i2 = i1
    }
    if (i2 > n) {
        i2 = n
    }
    lo = s[i1]
    hi = s[i2]
    g  = uniqrows(select(s, (s :>= lo) :& (s :<= hi)))
    ng = rows(g)
    if (ng > 200) {
        idx = round((0::199) :* ((ng - 1) / 199)) :+ 1
        g = g[idx]
    }
    return(g)
}

struct cvn_spec scalar cvn_mkspec(real scalar type, real matrix Z, real matrix X,
    real scalar pd, real scalar tidx, real scalar sl, real colvector qv,
    real scalar trim)
{
    struct cvn_spec scalar S
    S.type  = type
    S.Z     = Z
    S.nz    = cols(Z)
    S.pd    = pd
    S.tidx  = tidx
    S.sl    = sl
    S.slfix = (sl < .)
    S.s     = J(0, 1, .)
    S.grid  = J(0, 1, .)
    cvn_setx(S, X)
    if (type == 3) {
        S.s    = qv
        S.grid = cvn_thrgrid(qv, trim)
    }
    return(S)
}

// ---------------------------------------------------------------------------
//  Regression function, logistic transition, Jacobian
// ---------------------------------------------------------------------------

real colvector cvn_G(real colvector sv, real scalar loc, real scalar sl)
{
    real colvector a
    a = -sl :* (sv :- loc)
    a = a :* (abs(a) :<= 700) + 700 :* sign(a) :* (abs(a) :> 700)
    return(1 :/ (1 :+ exp(a)))
}

real colvector cvn_h(struct cvn_spec scalar S, real colvector par, real colvector rows)
{
    real scalar nr, sl, np
    real colvector G, ind
    nr = cols(S.R)
    if (S.type == 1) {
        return(S.R[rows, .] * par)
    }
    if (S.type == 2) {
        sl = S.sl
        if (S.slfix == 0) {
            sl = par[nr+3]
        }
        G = cvn_G(S.s[rows], par[nr+2], sl)
        return(S.R[rows, .] * par[|1 \ nr|] + par[nr+1] :* G)
    }
    np = rows(par)
    ind = (S.s[rows] :> par[np])
    return(S.R[rows, .] * par[|1 \ nr|] + (S.X[rows, .] :* ind) * par[|nr+1 \ nr+S.m|])
}

real matrix cvn_jac(struct cvn_spec scalar S, real colvector par, real colvector rows)
{
    real scalar nr, sl, loc, th2
    real colvector sv, G, dG
    real matrix Jm
    nr = cols(S.R)
    if (S.type != 2) {
        return(S.R[rows, .])
    }
    sl = S.sl
    if (S.slfix == 0) {
        sl = par[nr+3]
    }
    loc = par[nr+2]
    th2 = par[nr+1]
    sv  = S.s[rows]
    G   = cvn_G(sv, loc, sl)
    dG  = G :* (1 :- G)
    Jm  = S.R[rows, .], G, (-th2 * sl) :* dG
    if (S.slfix == 0) {
        Jm = Jm, (th2 :* dG :* (sv :- loc))
    }
    return(Jm)
}

// ---------------------------------------------------------------------------
//  OLS with column scaling (numerically stable for powers of t and x)
//  returns the number of dropped (collinear) columns
// ---------------------------------------------------------------------------

real scalar cvn_ols(real colvector y, real matrix D, real matrix b, real matrix e)
{
    real rowvector sc
    real matrix Ds, XX
    real colvector bs
    sc = sqrt(colsum(D:^2))
    sc = sc + (sc :== 0)
    Ds = D :/ sc
    XX = invsym(cross(Ds, Ds))
    bs = XX * cross(Ds, y)
    b  = bs :/ sc'
    e  = y - Ds * bs
    return(diag0cnt(XX))
}

// ---------------------------------------------------------------------------
//  Long-run variance and the KPSS/Shin statistic
//    lrvt = 0 : s2 = N^-1 sum e^2                 (C&T 2006 eq 6; H&M fn 5)
//    lrvt = 1 : Bartlett, weights 1 - s/(l+1)     (H&M Section 4.1; KPSS 1992)
// ---------------------------------------------------------------------------

real scalar cvn_lrv(real colvector e, real scalar lrvt, real scalar l)
{
    //  lrvt = 2 : quadratic spectral kernel, bandwidth l, all lags
    //             (Andrews 1991; used by Choi & Saikkonen 2010, Sect. 5)
    real scalar N, om, s, x, a, w
    N  = rows(e)
    om = cross(e, e) / N
    if (lrvt == 1) {
        for (s = 1; s <= l; s = s + 1) {
            if (s < N) {
                om = om + 2 * (1 - s/(l+1)) * cross(e[|s+1 \ N|], e[|1 \ N-s|]) / N
            }
        }
    }
    if (lrvt == 2) {
        if (l > 0) {
            for (s = 1; s < N; s = s + 1) {
                x  = s / l
                a  = 6 * pi() * x / 5
                w  = 25 / (12 * pi() * pi() * x * x) * (sin(a) / a - cos(a))
                om = om + 2 * w * cross(e[|s+1 \ N|], e[|1 \ N-s|]) / N
            }
        }
    }
    return(om)
}

real scalar cvn_eta(real colvector e, real scalar lrvt, real scalar l, real scalar om2)
{
    real scalar N
    real colvector S
    N   = rows(e)
    S   = runningsum(e)
    om2 = cvn_lrv(e, lrvt, l)
    if (om2 <= 0 | om2 >= .) {
        return(.)
    }
    return(cross(S, S) / (N * N * om2))
}

// ---------------------------------------------------------------------------
//  Leads and lags  V_t = (dx_{t+Kf}', ..., dx_{t-Kb}')',  t = Kb+2..T-Kf
//  (Kf leads, Kb lags; Kf = Kb = K is Shin 1994 eqs 10-12 and H&M eq 18)
//  dX has T rows, row 1 missing. Returns (T-Kf-Kb-1) x m(Kf+Kb+1).
// ---------------------------------------------------------------------------

real matrix cvn_leadlag(real matrix dX, real scalar Kf, real scalar Kb)
{
    real scalar T, m, N, j, c
    real matrix V
    T = rows(dX)
    m = cols(dX)
    N = T - Kf - Kb - 1
    V = J(N, m*(Kf+Kb+1), .)
    c = 0
    for (j = -Kf; j <= Kb; j = j + 1) {
        V[|1, c*m+1 \ N, (c+1)*m|] = dX[|Kb+2-j, 1 \ T-Kf-j, m|]
        c = c + 1
    }
    return(V)
}

// ---------------------------------------------------------------------------
//  Nonlinear least squares for the smooth-transition model
//  (Levenberg-Marquardt; start values from a location x slope grid with the
//   linear parameters concentrated out by OLS)
// ---------------------------------------------------------------------------

real colvector cvn_strstart(struct cvn_spec scalar S, real colvector y, real colvector rows)
{
    real colvector sv, qs, sls, b, e, G, best, yy
    real matrix Rr
    real scalar i, j, n, sd, loc, ssr, bssr, ix
    sv = S.s[rows]
    yy = y[rows]
    Rr = S.R[rows, .]
    n  = rows(sv)
    qs = sort(sv, 1)
    sd = sqrt(variance(sv))
    if (sd <= 0 | sd >= .) {
        sd = 1
    }
    if (S.slfix) {
        sls = S.sl
    }
    else {
        sls = (0.5 \ 1 \ 2 \ 4 \ 8 \ 16) :/ sd
    }
    bssr = .
    best = J(0, 1, .)
    for (i = 2; i <= 18; i = i + 1) {
        ix = round(i * 0.05 * n)
        if (ix < 1) {
            ix = 1
        }
        if (ix > n) {
            ix = n
        }
        loc = qs[ix]
        for (j = 1; j <= rows(sls); j = j + 1) {
            G = cvn_G(sv, loc, sls[j])
            (void) cvn_ols(yy, (Rr, G), b, e)
            ssr = cross(e, e)
            if (ssr < bssr) {
                bssr = ssr
                best = b \ loc
                if (S.slfix == 0) {
                    best = best \ sls[j]
                }
            }
        }
    }
    return(best)
}

real scalar cvn_lm(struct cvn_spec scalar S, real colvector y, real colvector rows,
                   real colvector par0, real matrix par)
{
    real colvector yy, r, rn, g, d, pn, dA
    real matrix Jm, A
    real scalar ssr, ssrn, lam, it, acc, conv, rel
    yy  = y[rows]
    par = par0
    if (rows(par) == 0) {
        return(0)
    }
    r   = yy - cvn_h(S, par, rows)
    ssr = cross(r, r)
    if (ssr >= .) {
        return(0)
    }
    lam  = 1e-3
    conv = 0
    ssrn = ssr
    d    = J(rows(par), 1, 0)
    for (it = 1; it <= 300; it = it + 1) {
        if (ssr <= 0) {
            conv = 1
            break
        }
        Jm = cvn_jac(S, par, rows)
        A  = cross(Jm, Jm)
        g  = cross(Jm, r)
        dA = diagonal(A) :+ 1e-12
        acc = 0
        while (lam < 1e12) {
            d    = invsym(A + lam * diag(dA)) * g
            pn   = par + d
            rn   = yy - cvn_h(S, pn, rows)
            ssrn = cross(rn, rn)
            if (ssrn < ssr) {
                acc = 1
                break
            }
            lam = lam * 10
        }
        if (acc == 0) {
            // no further decrease possible: stationary point of the SSR
            conv = 1
            break
        }
        rel = (ssr - ssrn) / ssr
        par = pn
        r   = rn
        ssr = ssrn
        lam = lam / 10
        if (lam < 1e-12) {
            lam = 1e-12
        }
        if (rel < 1e-12) {
            conv = 1
            break
        }
        if (max(abs(d) :/ (abs(par) :+ 1e-8)) < 1e-9) {
            conv = 1
            break
        }
    }
    if (hasmissing(par)) {
        conv = 0
    }
    return(conv)
}

// ---------------------------------------------------------------------------
//  Threshold model: grid search of th3 on the SSR, other parameters by OLS
// ---------------------------------------------------------------------------

void cvn_thrfit(struct cvn_spec scalar S, real colvector y, real colvector rows,
                real matrix par, real matrix e)
{
    real colvector yy, b, eb, ind, sv
    real matrix Rr, Xr
    real scalar i, ssr, bssr
    yy   = y[rows]
    Rr   = S.R[rows, .]
    Xr   = S.X[rows, .]
    sv   = S.s[rows]
    bssr = .
    par  = J(0, 1, .)
    e    = J(0, 1, .)
    for (i = 1; i <= rows(S.grid); i = i + 1) {
        ind = (sv :> S.grid[i])
        (void) cvn_ols(yy, (Rr, Xr :* ind), b, eb)
        ssr = cross(eb, eb)
        if (ssr < bssr) {
            bssr = ssr
            par  = b \ S.grid[i]
            e    = eb
        }
    }
}

// ---------------------------------------------------------------------------
//  Estimation driver
//    rN : rows of the static (OLS/NLS) stage; rD : rows of the DNLS stage
//    dn : 1 = dynamic (leads/lags V aligned with rD), 0 = static
//    start : NLS start values (0 rows -> grid)
//  returns 1 on success, 0 on failure (NLS non-convergence)
// ---------------------------------------------------------------------------

real scalar cvn_estimate(struct cvn_spec scalar S, real colvector y, real colvector rN,
    real colvector rD, real scalar dn, real matrix V, real colvector start,
    real matrix par, real matrix e)
{
    real colvector b, u, p0, ps
    real matrix P
    real scalar nr, k, conv
    nr = cols(S.R)
    if (S.type == 1) {
        if (dn) {
            (void) cvn_ols(y[rD], (S.R[rD, .], V), b, e)
            par = b[|1 \ nr|]
        }
        else {
            (void) cvn_ols(y[rN], S.R[rN, .], b, e)
            par = b
        }
        return(1)
    }
    if (S.type == 3) {
        cvn_thrfit(S, y, rN, par, e)
        if (rows(par) == 0) {
            return(0)
        }
        return(1)
    }
    // smooth transition: NLS (H&M eq 10)
    if (rows(start) == 0) {
        p0 = cvn_strstart(S, y, rN)
    }
    else {
        p0 = start
    }
    conv = cvn_lm(S, y, rN, p0, ps)
    par  = ps
    if (conv == 0) {
        e = J(0, 1, .)
        return(0)
    }
    if (dn == 0) {
        e = y[rN] - cvn_h(S, ps, rN)
        return(1)
    }
    // one Gauss-Newton step from (theta_NLS, 0) on (dh/dtheta, V_t), H&M eq (20)
    k = rows(ps)
    u = y[rD] - cvn_h(S, ps, rD)
    P = cvn_jac(S, ps, rD), V
    (void) cvn_ols(u, P, b, e)
    par = ps + b[|1 \ k|]
    e   = y[rD] - cvn_h(S, par, rD) - V * b[|k+1 \ rows(b)|]
    if (hasmissing(e)) {
        return(0)
    }
    return(1)
}

// ---------------------------------------------------------------------------
//  Sieve: VAR(p) with intercept on w_t = (e_t, dx_t')', AIC selection
// ---------------------------------------------------------------------------

void cvn_varfit(real matrix w, real scalar p, real matrix Bc, real matrix E)
{
    real scalar n, k, j
    real matrix D, Y
    n = rows(w)
    k = cols(w)
    Y = w[|p+1, 1 \ n, k|]
    D = J(n-p, 1, 1)
    for (j = 1; j <= p; j = j + 1) {
        D = D, w[|p+1-j, 1 \ n-j, k|]
    }
    Bc = invsym(cross(D, D)) * cross(D, Y)
    E  = Y - D * Bc
}

real scalar cvn_varaic(real matrix w, real scalar pmax0)
{
    real scalar n, k, p, j, ne, best, aic, pb, pmax
    real matrix D, Y, Bc, E
    n = rows(w)
    k = cols(w)
    pmax = pmax0
    while (pmax > 0 & (n - pmax) <= (k*pmax + k + 10)) {
        pmax = pmax - 1
    }
    best = .
    pb   = 0
    for (p = 0; p <= pmax; p = p + 1) {
        Y  = w[|pmax+1, 1 \ n, k|]
        ne = rows(Y)
        D  = J(ne, 1, 1)
        for (j = 1; j <= p; j = j + 1) {
            D = D, w[|pmax+1-j, 1 \ n-j, k|]
        }
        Bc  = invsym(cross(D, D)) * cross(D, Y)
        E   = Y - D * Bc
        aic = ln(det(cross(E, E) / ne)) + 2 * k * (1 + k*p) / ne
        if (aic < best) {
            best = aic
            pb   = p
        }
    }
    return(pb)
}

real matrix cvn_vargen(real matrix w, real scalar p, real matrix Bc, real matrix Ec,
                       string scalar mult)
{
    real scalar n, k, i, j
    real matrix wb, eps
    real rowvector d
    n  = rows(w)
    k  = cols(w)
    wb = J(n, k, 0)
    if (p > 0) {
        wb[|1, 1 \ p, k|] = w[|1, 1 \ p, k|]
    }
    eps = Ec :* cv_mult(n - p, mult)
    for (i = p+1; i <= n; i = i + 1) {
        d = Bc[1, .]
        for (j = 1; j <= p; j = j + 1) {
            d = d + wb[i-j, .] * Bc[|2+(j-1)*k, 1 \ 1+j*k, k|]
        }
        wb[i, .] = d + eps[i-p, .]
    }
    return(wb)
}

// ---------------------------------------------------------------------------
//  Empirical variance profile, H&M eq (28), at s = 0, 1/N, ..., 1
// ---------------------------------------------------------------------------

real matrix cvn_profile(real colvector e)
{
    real scalar N
    real colvector c
    N = rows(e)
    c = runningsum(e:^2)
    return(((0::N) :/ N), (0 \ (c :/ c[N])))
}

// ---------------------------------------------------------------------------
//  Main entry point for -cointvol nullcoint-
// ---------------------------------------------------------------------------

void cvn_main(string scalar yv, string scalar xv, string scalar qv, string scalar touse,
    real scalar type, real scalar pd, real scalar tidx, real scalar sl,
    real scalar trim, real scalar qd, real scalar dn, real scalar K,
    real scalar Kb, real scalar lrvt, real scalar bw, string scalar boot,
    string scalar mult, real scalar B, string scalar pvtype, real scalar dots,
    real scalar pmax, real scalar csf, real scalar bfix, real scalar bmin,
    real scalar bmax, real scalar mvm, real scalar cc)
{
    // csf = 1: also compute the Choi & Saikkonen (2010) subresidual test
    //          (block size bfix, or minimum-volatility rule over [bmin, bmax])
    // K = number of leads, Kb = number of lags of dx (dynamic estimators)
    struct cvn_spec scalar S, Sb
    real colvector y, qvec, rN, rD, rR, par, e, etab, z, yb, hb, eb, pb, yr
    real colvector G, ef, efb
    real matrix X, Z, dX, V, D, Ds, H, w, Bc, Ev, wb, Xb, dXb, Vb
    real rowvector sc, st
    real scalar T, m, N, conv, eta, om2, omb, b, fails, ok, psel, t, i, nw, pv

    y = st_data(., yv, touse)
    X = st_data(., tokens(xv), touse)
    T = rows(y)
    m = cols(X)
    Z = cvn_det(T, qd)
    qvec = J(0, 1, .)
    if (qv != "") {
        qvec = st_data(., qv, touse)
    }
    S  = cvn_mkspec(type, Z, X, pd, tidx, sl, qvec, trim)
    dX = J(1, m, .) \ (X[|2, 1 \ T, m|] - X[|1, 1 \ T-1, m|])
    rN = (1::T)
    rD = J(0, 1, .)
    V  = J(0, 0, .)
    rR = rN
    if (dn) {
        rD = ((Kb+2)::(T-K))
        V  = cvn_leadlag(dX, K, Kb)
        rR = rD
    }

    // ---- estimation and observed statistic ----
    conv = cvn_estimate(S, y, rN, rD, dn, V, J(0, 1, .), par, e)
    if (conv == 0 | rows(e) == 0) {
        errprintf("nonlinear least squares did not converge; try slope(), another\n")
        errprintf("transition variable, or a different model\n")
        exit(error(430))
    }
    if (hasmissing(e)) {
        errprintf("missing residuals; check the regressors for collinearity\n")
        exit(error(504))
    }
    N   = rows(e)
    eta = cvn_eta(e, lrvt, bw, om2)

    // ---- bootstrap ----
    etab  = J(0, 1, .)
    fails = 0
    psel  = .
    if (boot != "none") {
        etab = J(B, 1, .)
        hb   = J(N, 1, 0)
        if (type != 1) {
            hb = cvn_h(S, par, rR)
        }
        if (type == 1 & boot == "frwild") {
            // fixed regressors: residual maker precomputed once
            D = S.R[rR, .]
            if (dn) {
                D = D, V
            }
            sc = sqrt(colsum(D:^2))
            sc = sc + (sc :== 0)
            Ds = D :/ sc
            H  = Ds * invsym(cross(Ds, Ds))
        }
        if (boot == "sieve") {
            G  = select(rR, rR :>= 2)
            ef = J(T, 1, .)
            ef[rR] = e
            w  = ef[G], dX[G, .]
            nw = rows(w)
            psel = cvn_varaic(w, pmax)
            cvn_varfit(w, psel, Bc, Ev)
            Ev = Ev :- mean(Ev)
        }
        if (dots) {
            printf("{txt}")
            displayflush()
        }
        for (b = 1; b <= B; b = b + 1) {
            ok = 1
            if (boot == "frwild") {
                z = cv_mult(N, mult)
                if (type == 1) {
                    yr = e :* z
                    eb = yr - H * cross(Ds, yr)
                }
                else {
                    yb = J(T, 1, .)
                    yb[rR] = hb + e :* z
                    ok = cvn_estimate(S, yb, rR, rR, dn, V, par, pb, eb)
                }
            }
            else {
                // sieve wild bootstrap (exploratory, H&M Section 4.6)
                wb  = cvn_vargen(w, psel, Bc, Ev, mult)
                dXb = dX
                for (i = 1; i <= nw; i = i + 1) {
                    dXb[G[i], .] = wb[|i, 2 \ i, cols(wb)|]
                }
                Xb = X
                for (t = 2; t <= T; t = t + 1) {
                    Xb[t, .] = Xb[t-1, .] + dXb[t, .]
                }
                efb = J(T, 1, .)
                efb[G] = wb[., 1]
                if (rR[1] == 1) {
                    efb[1] = ef[1]
                }
                Sb = S
                cvn_setx(Sb, Xb)
                yb = J(T, 1, .)
                yb[rR] = cvn_h(Sb, par, rR) + efb[rR]
                Vb = J(0, 0, .)
                if (dn) {
                    Vb = cvn_leadlag(dXb, K, Kb)
                }
                ok = cvn_estimate(Sb, yb, rR, rD, dn, Vb, par, pb, eb)
            }
            if (ok == 1) {
                if (rows(eb) != N) {
                    ok = 0
                }
                else if (hasmissing(eb)) {
                    ok = 0
                }
            }
            if (ok == 1) {
                etab[b] = cvn_eta(eb, lrvt, bw, omb)
                if (etab[b] >= .) {
                    ok = 0
                }
            }
            if (ok == 0) {
                fails = fails + 1
                if (fails > 5*B) {
                    errprintf("bootstrap failed repeatedly (non-convergence or singular samples)\n")
                    exit(error(430))
                }
                b = b - 1
                continue
            }
            if (dots) {
                if (mod(b, 50) == 0) {
                    printf(".")
                    displayflush()
                }
            }
        }
        if (dots) {
            printf("\n")
            displayflush()
        }
    }

    // ---- p-value and bootstrap critical values ----
    pv = .
    st = J(1, 4, .)
    if (boot != "none") {
        pv = mean(etab :>= eta)
        if (pvtype == "strict") {
            pv = mean(etab :> eta)
        }
        if (pvtype == "plusone") {
            pv = (sum(etab :>= eta) + 1) / (B + 1)
        }
        st[1] = cv_quantile(etab, 0.90)
        st[2] = cv_quantile(etab, 0.95)
        st[3] = cv_quantile(etab, 0.975)
        st[4] = cv_quantile(etab, 0.99)
        st_matrix("__cvn_boot", etab)
    }

    st_matrix("__cvn_b", par')
    st_matrix("__cvn_bcv", st)
    st_matrix("__cvn_prof", cvn_profile(e))
    st_numscalar("__cvn_eta", eta)
    st_numscalar("__cvn_pb", pv)
    st_numscalar("__cvn_om2", om2)
    st_numscalar("__cvn_N", N)
    st_numscalar("__cvn_T", T)
    st_numscalar("__cvn_ssr", cross(e, e))
    st_numscalar("__cvn_fails", fails)
    st_numscalar("__cvn_psel", psel)
    if (csf) {
        cvn_cs(e, bfix, bmin, bmax, mvm, lrvt, cc)
    }
}

// ---------------------------------------------------------------------------
//  Simulated homoskedastic null distribution of the Shin (1994) statistic
//  (C&T 2006 eq 8): iid N(0,1) errors, m independent random walks, the same
//  deterministic polynomial; OLS residuals, s2 normalisation.
//  Writes __cvn_asy = (p, cv10%, cv5%, cv2.5%, cv1%).
// ---------------------------------------------------------------------------

void cvn_asy(real scalar eta, real scalar m, real scalar qd, real scalar R, real scalar Ta)
{
    real matrix Z, E, Xs
    real colvector sims, u, b, e, S
    real rowvector res
    real scalar r, j
    Z = cvn_det(Ta, qd)
    sims = J(R, 1, .)
    for (r = 1; r <= R; r = r + 1) {
        u  = rnormal(Ta, 1, 0, 1)
        E  = rnormal(Ta, m, 0, 1)
        Xs = J(Ta, m, .)
        for (j = 1; j <= m; j = j + 1) {
            Xs[., j] = runningsum(E[., j])
        }
        (void) cvn_ols(u, (Z, Xs), b, e)
        S = runningsum(e)
        sims[r] = cross(S, S) / (Ta * cross(e, e))
    }
    res = J(1, 5, .)
    res[1] = mean(sims :>= eta)
    res[2] = cv_quantile(sims, 0.90)
    res[3] = cv_quantile(sims, 0.95)
    res[4] = cv_quantile(sims, 0.975)
    res[5] = cv_quantile(sims, 0.99)
    st_matrix("__cvn_asy", res)
}

// ---------------------------------------------------------------------------
//  Shin (1994), Table 1: asymptotic critical values of C (standard, no
//  deterministics), C_mu (demeaned, intercept) and C_tau (detrended, intercept
//  and linear trend) for m = 1,...,5 I(1) regressors. Rows = fractiles
//  0.010, 0.025, 0.050, 0.100, 0.200, ..., 0.900, 0.950, 0.975, 0.990;
//  columns = m. Entered exactly as printed (Monte Carlo, T = 2000, 50,000
//  replications for m <= 3 and 20,000 for m = 4, 5). Note: the printed value
//  0.046 at fractile 0.500 of C_mu, m = 5 is out of order (0.031 at 0.400,
//  0.041 at 0.600) and is presumably a misprint; it is kept as printed and is
//  never used by the p-value, which only uses the 0.900-0.990 fractiles.
// ---------------------------------------------------------------------------

real colvector cvn_shinfrac()
{
    return((0.010 \ 0.025 \ 0.050 \ 0.100 \ 0.200 \ 0.300 \ 0.400 \ 0.500 \
            0.600 \ 0.700 \ 0.800 \ 0.900 \ 0.950 \ 0.975 \ 0.990))
}

real matrix cvn_shintab(real scalar qd)
{
    real matrix C
    if (qd < 0) {
        // Standard (C): regression (1), no intercept, no trend
        C = ( 0.027, 0.023, 0.021, 0.018, 0.016 \
              0.034, 0.029, 0.025, 0.022, 0.020 \
              0.043, 0.035, 0.030, 0.026, 0.023 \
              0.057, 0.046, 0.038, 0.033, 0.029 \
              0.083, 0.065, 0.053, 0.045, 0.039 \
              0.113, 0.087, 0.070, 0.058, 0.050 \
              0.150, 0.115, 0.090, 0.074, 0.063 \
              0.199, 0.150, 0.117, 0.096, 0.081 \
              0.267, 0.199, 0.154, 0.125, 0.104 \
              0.368, 0.271, 0.209, 0.167, 0.139 \
              0.527, 0.391, 0.295, 0.236, 0.198 \
              0.841, 0.624, 0.475, 0.374, 0.307 \
              1.199, 0.895, 0.682, 0.537, 0.433 \
              1.601, 1.190, 0.926, 0.715, 0.580 \
              2.126, 1.623, 1.305, 1.003, 0.781 )
        return(C)
    }
    if (qd == 0) {
        // Demeaned (C_mu): regression (2), intercept
        C = ( 0.020, 0.017, 0.015, 0.014, 0.013 \
              0.024, 0.021, 0.018, 0.016, 0.015 \
              0.029, 0.024, 0.021, 0.019, 0.017 \
              0.035, 0.029, 0.025, 0.022, 0.019 \
              0.046, 0.037, 0.031, 0.027, 0.024 \
              0.057, 0.045, 0.037, 0.031, 0.027 \
              0.069, 0.053, 0.043, 0.036, 0.031 \
              0.083, 0.063, 0.050, 0.042, 0.046 \
              0.101, 0.074, 0.059, 0.048, 0.041 \
              0.125, 0.090, 0.070, 0.057, 0.047 \
              0.161, 0.115, 0.088, 0.069, 0.057 \
              0.231, 0.163, 0.121, 0.094, 0.075 \
              0.314, 0.221, 0.159, 0.121, 0.097 \
              0.407, 0.285, 0.203, 0.153, 0.120 \
              0.533, 0.380, 0.271, 0.208, 0.158 )
        return(C)
    }
    if (qd == 1) {
        // Detrended (C_tau): regression (3), intercept and linear trend
        C = ( 0.015, 0.014, 0.012, 0.011, 0.011 \
              0.017, 0.016, 0.014, 0.013, 0.012 \
              0.020, 0.018, 0.016, 0.015, 0.014 \
              0.024, 0.021, 0.019, 0.017, 0.016 \
              0.030, 0.026, 0.023, 0.021, 0.019 \
              0.035, 0.030, 0.027, 0.024, 0.021 \
              0.040, 0.035, 0.030, 0.027, 0.024 \
              0.046, 0.040, 0.034, 0.030, 0.027 \
              0.053, 0.045, 0.039, 0.034, 0.030 \
              0.062, 0.052, 0.045, 0.039, 0.034 \
              0.075, 0.063, 0.054, 0.046, 0.040 \
              0.097, 0.081, 0.069, 0.056, 0.050 \
              0.121, 0.101, 0.085, 0.073, 0.061 \
              0.147, 0.122, 0.102, 0.088, 0.072 \
              0.184, 0.150, 0.126, 0.109, 0.087 )
        return(C)
    }
    return(J(15, 5, .))
}

// critical value at fractile q by linear interpolation between the tabulated
// fractiles (exact at the tabulated fractiles); missing outside [0.01, 0.99]
real scalar cvn_shinq(real colvector c, real colvector f, real scalar q)
{
    real scalar i, n, v
    n = rows(f)
    if (q < f[1] | q > f[n] | q >= .) {
        return(.)
    }
    for (i = 1; i <= n; i = i + 1) {
        if (abs(q - f[i]) < 1e-12) {
            return(c[i])
        }
    }
    v = .
    for (i = 1; i < n; i = i + 1) {
        if (q > f[i]) {
            if (q < f[i+1]) {
                v = c[i] + (c[i+1] - c[i]) * (q - f[i]) / (f[i+1] - f[i])
                break
            }
        }
    }
    return(v)
}

// Writes
//   __cvn_shin    = (p, bound, cv10%, cv5%, cv2.5%, cv1%, cv at level)
//   __cvn_shintab = 15 x 6 (fractile, m = 1..5) panel of Table 1 for case qd
// p = 1 - F(eta), F linear between the fractiles 0.900, 0.950, 0.975, 0.990;
// bound = 0 interpolated; 1: eta below the 90% value, p > 0.10 (p set to 0.10);
// -1: eta above the 99% value, p < 0.01 (p set to 0.01).
void cvn_shin(real scalar eta, real scalar m, real scalar qd, real scalar lev)
{
    real matrix C
    real colvector f, c
    real rowvector res
    real scalar p, bd, i
    f = cvn_shinfrac()
    C = cvn_shintab(qd)
    res = J(1, 7, .)
    if (m >= 1) {
        if (m <= 5) {
            c  = C[., m]
            p  = .
            bd = .
            if (eta < .) {
                if (eta < c[12]) {
                    p  = 0.10
                    bd = 1
                }
                else if (eta > c[15]) {
                    p  = 0.01
                    bd = -1
                }
                else {
                    bd = 0
                    for (i = 12; i <= 14; i = i + 1) {
                        if (eta >= c[i]) {
                            if (eta <= c[i+1]) {
                                p = 1 - (f[i] + (f[i+1] - f[i]) * (eta - c[i]) / (c[i+1] - c[i]))
                                break
                            }
                        }
                    }
                }
            }
            res[1] = p
            res[2] = bd
            res[3] = c[12]
            res[4] = c[13]
            res[5] = c[14]
            res[6] = c[15]
            res[7] = cvn_shinq(c, f, lev / 100)
        }
    }
    st_matrix("__cvn_shin", res)
    st_matrix("__cvn_shintab", (f, C))
}

// ---------------------------------------------------------------------------
//  Choi & Saikkonen (2010): subresidual-based KPSS tests with Bonferroni
// ---------------------------------------------------------------------------

// cdf of int_0^1 W(s)^2 ds, C&S (2010) eq (13):
//   cdf(z) = sqrt(2) sum_n Gamma(n+1/2)/(n! Gamma(1/2)) (-1)^n [1 - Erf(u/(2 sqrt z))],
//   u = sqrt(2)/2 + 2n sqrt(2);  1 - Erf(x) = 2 Phi(-x sqrt(2)).
// 101 terms (C&S use 11; identical to 1e-9 for z <= 10); cdf = 1 for z > 50.
real scalar cvn_w2cdf(real scalar z)
{
    real scalar s, n, c, u, sg
    if (z >= .) {
        return(.)
    }
    if (z <= 0) {
        return(0)
    }
    if (z > 50) {
        return(1)
    }
    s  = 0
    sg = 1
    for (n = 0; n <= 100; n = n + 1) {
        c  = exp(lngamma(n + 0.5) - lngamma(n + 1) - lngamma(0.5))
        u  = sqrt(2) / 2 + 2 * n * sqrt(2)
        s  = s + sg * c * 2 * normal(-u / sqrt(2 * z))
        sg = -sg
    }
    s = sqrt(2) * s
    if (s > 1) {
        s = 1
    }
    if (s < 0) {
        s = 0
    }
    return(s)
}

// upper-tail critical value c_a: P(int W^2 >= c_a) = a (bisection)
real scalar cvn_w2inv(real scalar a)
{
    real scalar lo, hi, mid, it
    if (a <= 0 | a >= 1 | a >= .) {
        return(.)
    }
    lo = 1e-6
    hi = 50
    for (it = 1; it <= 80; it = it + 1) {
        mid = (lo + hi) / 2
        if (1 - cvn_w2cdf(mid) > a) {
            lo = mid
        }
        else {
            hi = mid
        }
    }
    return((lo + hi) / 2)
}

// KPSS statistic of one block of residuals, C&S eqs (11)/(12):
//   b^-2 w_b^-2 sum_t (sum_{j<=t} r_j)^2, partial sums within the block,
//   w_b^2 from the block residuals with bandwidth floor(cc (b/100)^(1/4))
real scalar cvn_csstat(real colvector r, real scalar lrvt, real scalar cc)
{
    real scalar b, l, om
    real colvector S
    b  = rows(r)
    l  = floor(cc * (b / 100)^0.25)
    om = cvn_lrv(r, lrvt, l)
    if (om <= 0 | om >= .) {
        return(.)
    }
    S = runningsum(r)
    return(cross(S, S) / (b * b * om))
}

// starting points, C&S Sect. 4.2.1: M = ceil(n/b), i1 = 1, i2 = n-b+1, i3 = b+1,
// i4 = n-2b+1, ...  (n = T for NLLS residuals, n = T-2K-1 for leads-and-lags)
real colvector cvn_csstarts(real scalar n, real scalar b)
{
    real scalar M, k
    real colvector st
    M  = ceil(n / b)
    st = J(M, 1, .)
    for (k = 1; k <= M; k = k + 1) {
        if (mod(k, 2) == 1) {
            st[k] = ((k - 1) / 2) * b + 1
        }
        else {
            st[k] = n - (k / 2) * b + 1
        }
    }
    return(st)
}

// C^{b,max} = max_k C^{b,i_k}; blk = (start, end, statistic) for each block
real scalar cvn_csmax(real colvector e, real scalar b, real scalar lrvt, real scalar cc,
                      real matrix blk)
{
    real scalar n, M, k, i0, c, cmax
    real colvector st
    n   = rows(e)
    st  = cvn_csstarts(n, b)
    M   = rows(st)
    blk = J(M, 3, .)
    cmax = .
    for (k = 1; k <= M; k = k + 1) {
        i0 = st[k]
        c  = cvn_csstat(e[|i0 \ i0+b-1|], lrvt, cc)
        blk[k, 1] = i0
        blk[k, 2] = i0 + b - 1
        blk[k, 3] = c
        if (c < .) {
            if (cmax >= .) {
                cmax = c
            }
            else if (c > cmax) {
                cmax = c
            }
        }
    }
    return(cmax)
}

// Full C&S procedure. bfix < . : fixed block size; otherwise the minimum-
// volatility rule (Sect. 4.2.2): for b in [bmin, bmax], SC(b) = sd of
// C^{b-mvm,max}, ..., C^{b+mvm,max}; b = argmin SC(b) (first minimiser).
// Writes __cvn_cs = (Cmax, p, p_bonf, b, M, bandwidth, c_{.10/M}, c_{.05/M},
//   c_{.025/M}, c_{.01/M}), __cvn_csblk = (start, end, stat, p) per block,
//   __cvn_csmv = (b, SC(b)) (one row (b, .) with a fixed block size).
void cvn_cs(real colvector e, real scalar bfix, real scalar bmin, real scalar bmax,
            real scalar mvm, real scalar lrvt, real scalar cc)
{
    real scalar b, j, nb, best, sc, M, cmax, p, pb, k
    real colvector cm, w
    real matrix blk, mv, res
    mv = (bfix, .)
    b  = bfix
    if (bfix >= .) {
        nb = (bmax + mvm) - (bmin - mvm) + 1
        cm = J(nb, 1, .)
        for (j = 1; j <= nb; j = j + 1) {
            cm[j] = cvn_csmax(e, bmin - mvm + j - 1, lrvt, cc, blk)
        }
        mv   = J(bmax - bmin + 1, 2, .)
        best = .
        b    = bmin
        for (j = 1; j <= bmax - bmin + 1; j = j + 1) {
            w  = cm[|j \ j + 2*mvm|]
            sc = .
            if (hasmissing(w) == 0) {
                sc = sqrt(variance(w))
            }
            mv[j, 1] = bmin + j - 1
            mv[j, 2] = sc
            if (sc < .) {
                if (best >= .) {
                    best = sc
                    b    = bmin + j - 1
                }
                else if (sc < best) {
                    best = sc
                    b    = bmin + j - 1
                }
            }
        }
    }
    cmax = cvn_csmax(e, b, lrvt, cc, blk)
    M    = rows(blk)
    blk  = blk, J(M, 1, .)
    for (k = 1; k <= M; k = k + 1) {
        if (blk[k, 3] < .) {
            blk[k, 4] = 1 - cvn_w2cdf(blk[k, 3])
        }
    }
    p  = .
    pb = .
    if (cmax < .) {
        p  = 1 - cvn_w2cdf(cmax)
        pb = M * p
        if (pb > 1) {
            pb = 1
        }
    }
    res = (cmax, p, pb, b, M, floor(cc * (b / 100)^0.25), cvn_w2inv(0.10 / M),
           cvn_w2inv(0.05 / M), cvn_w2inv(0.025 / M), cvn_w2inv(0.01 / M))
    st_matrix("__cvn_cs", res)
    st_matrix("__cvn_csblk", blk)
    st_matrix("__cvn_csmv", mv)
}

end
