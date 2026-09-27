*! cointvol_eng_stoch 0.1.0  26sep2026
*! Mata engine of -cointvol stoch- and -cointvol hetcoint- (stochastic and
*! heteroskedastic cointegration: AIV, HAC, residual tests, HCI Wald)
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com) - github.com/merwanroudane
*!
*! Step -> source map
*!   cvs_aiv      b_k = (sum X_{t-k} X_t')^-1 sum X_{t-k} y_t, t = k+1..T
*!                -> Harris, McCabe & Leybourne (2002) eq (6) in its IV form;
*!                   McCabe, Leybourne & Harris (2006) eq (7)
*!   cvs_lrsum    sum_t a_t a_t' + sum_j lambda(j)(G_j + G_j'), G_j = sum a_t a_{t-j}'
*!                -> HML (2002) eq (9); MLH (2006) eq (5); Hansen (1992) Thm 3
*!   cvs_nwauto   Newey & West (1994) automatic lag, Bartlett kernel
*!   cvs_snc      S_nc = T^-1/2 sum u_t u_{t-k} / omega(u_t u_{t-k})  -> MLH Thm 1
*!   cvs_shc      S_hc = sqrt(12) T^-3/2 sum t (u_t^2 - s2) / omega(.)  -> MLH Thm 2
*!                (printed factor (1/12)^(1/2) corrected to sqrt(12))
*!   S_hi         cvs_shc applied to Delta y (demeaned if trend)  -> MLH Sec 3.2
*!   cvs_het_main OLS + HAC sandwich (bandwidth B = o(T^1/4)) -> Hansen (1992) Thm 3;
*!                split-sample variance t-test -> Hansen (1992) Table 1
*!
*! Calling this file (quietly run) compiles the functions below.

program define cointvol_eng_stoch
    version 14.0
end

version 14.0
capture mata: mata drop cvs_*()

mata:

string scalar cvs_version()
{
    return("0.1.0")
}

// ---------------------------------------------------------------------------
//  Kernel weights
//    lambda   : HML (2002) / MLH (2006) as printed, lambda(j/l) = 1 - j/l, j < l
//    bartlett : Newey-West (1987) lag-B convention, 1 - j/(B+1), j <= B
//    parzen   : Parzen with x = j/(B+1), j <= B
//    qs       : quadratic spectral with x = j/B, all lags (Andrews 1991)
// ---------------------------------------------------------------------------

real scalar cvs_kw(real scalar j, real scalar bw, string scalar kern)
{
    real scalar x, z
    if (j == 0) {
        return(1)
    }
    if (kern == "lambda") {
        if (bw <= 0) {
            return(0)
        }
        x = j / bw
        if (x >= 1) {
            return(0)
        }
        return(1 - x)
    }
    if (kern == "bartlett") {
        x = j / (bw + 1)
        if (x >= 1) {
            return(0)
        }
        return(1 - x)
    }
    if (kern == "parzen") {
        x = j / (bw + 1)
        if (x >= 1) {
            return(0)
        }
        if (x <= 0.5) {
            return(1 - 6*x*x + 6*x*x*x)
        }
        return(2*(1 - x)*(1 - x)*(1 - x))
    }
    // quadratic spectral
    if (bw <= 0) {
        return(0)
    }
    x = j / bw
    z = 6*pi()*x/5
    return(25/(12*pi()*pi()*x*x) * (sin(z)/z - cos(z)))
}

real scalar cvs_maxlag(real scalar bw, string scalar kern, real scalar n)
{
    real scalar m
    m = 0
    if (kern == "lambda") {
        m = ceil(bw) - 1
    }
    if (kern == "bartlett" | kern == "parzen") {
        m = floor(bw)
    }
    if (kern == "qs") {
        m = n - 1
    }
    if (m > n - 1) {
        m = n - 1
    }
    if (m < 0) {
        m = 0
    }
    return(m)
}

// Unnormalised long-run sum of the rows of a (n x p):
//   sum_t a_t a_t' + sum_{j>=1} w_j (G_j + G_j'),  G_j = sum_{t=j+1}^n a_t a_{t-j}'
// Autocovariances are NOT demeaned (HML eq 9, MLH eq 5, Hansen Thm 3).
real matrix cvs_lrsum(real matrix a, real scalar bw, string scalar kern)
{
    real scalar n, p, j, mj, w
    real matrix G, Gj
    n  = rows(a)
    p  = cols(a)
    G  = cross(a, a)
    mj = cvs_maxlag(bw, kern, n)
    for (j = 1; j <= mj; j = j + 1) {
        w = cvs_kw(j, bw, kern)
        if (w != 0) {
            Gj = cross(a[|j+1,1 \ n,p|], a[|1,1 \ n-j,p|])
            G  = G + w * (Gj + Gj')
        }
    }
    return(G)
}

// Newey & West (1994) automatic lag for the Bartlett kernel.
// h: scalar series; Tn: normalising sample size.
// Returns l = floor(gamma * Tn^(1/3)) + 1 so that lambda(j/l) = 1 - j/(m+1)
// reproduces the NW (1994) Bartlett weights with m = floor(gamma Tn^(1/3)).
real scalar cvs_nwauto(real colvector h, real scalar Tn)
{
    real scalar n, nn, j, s0, s1, sj, gam, r
    nn = rows(h)
    n  = floor(4 * (Tn/100)^(2/9))
    if (n > nn - 1) {
        n = nn - 1
    }
    if (n < 1) {
        return(.)
    }
    s0 = cross(h, h) / Tn
    s1 = 0
    for (j = 1; j <= n; j = j + 1) {
        sj = cross(h[|j+1 \ nn|], h[|1 \ nn-j|]) / Tn
        s0 = s0 + 2*sj
        s1 = s1 + 2*j*sj
    }
    if (missing(s0)) {
        return(.)
    }
    if (s0 <= 0) {
        return(.)
    }
    r   = s1 / s0
    gam = 1.1447 * (r*r)^(1/3)
    return(floor(gam * Tn^(1/3)) + 1)
}

real scalar cvs_fixedl(real scalar n)
{
    return(floor(12 * (n/100)^0.25 + 1e-9))
}

// ---------------------------------------------------------------------------
//  AIV estimator: instrument X_{t-k}, regressors X_t, t = k+1..T
//  Residuals returned for ALL t = 1..T (MLH eq 8)
// ---------------------------------------------------------------------------

void cvs_aiv(real colvector y, real matrix X, real scalar k,
             real colvector b, real colvector u)
{
    real scalar T, K
    real matrix Z, Xc
    real colvector yc
    T  = rows(X)
    K  = cols(X)
    Z  = X[|1,1 \ T-k,K|]
    Xc = X[|k+1,1 \ T,K|]
    yc = y[|k+1 \ T|]
    b  = lusolve(cross(Z, Xc), cross(Z, yc))
    if (hasmissing(b)) {
        errprintf("AIV moment matrix sum X(t-k)X(t)' is singular; check the regressors and k()\n")
        exit(error(506))
    }
    u = y - X * b
}

// ---------------------------------------------------------------------------
//  Residual tests, MLH (2006).  Each returns (stat, p, k, l_used, l_adjusted)
// ---------------------------------------------------------------------------

real rowvector cvs_snc(real colvector u, real scalar k, real scalar l,
                       string scalar lrule)
{
    real scalar T, lu, adj, om, st, la
    real colvector a
    T = rows(u)
    a = u[|k+1 \ T|] :* u[|1 \ T-k|]
    lu = l
    if (lrule == "nw") {
        la = cvs_nwauto(a, T)
        if (missing(la)) {
            lu = cvs_fixedl(T)
        }
        else {
            lu = la
        }
    }
    adj = 0
    if (lu >= k) {
        lu  = k - 1
        adj = 1
    }
    om = cvs_lrsum(a, lu, "lambda") / T
    if (om <= 0 | missing(om)) {
        return((., ., k, lu, adj))
    }
    st = sum(a) / sqrt(T) / sqrt(om)
    return((st, 2*normal(-abs(st)), k, lu, adj))
}

// kmax = . : no l < k restriction (used for S_hi)
real rowvector cvs_shc(real colvector u, real scalar l, string scalar lrule,
                       real scalar kmax)
{
    real scalar n, s2, lu, adj, om, st, la
    real colvector e, tt
    n  = rows(u)
    s2 = cross(u, u) / n
    e  = u :* u :- s2
    tt = (1::n)
    lu = l
    if (lrule == "nw") {
        la = cvs_nwauto(e, n)
        if (missing(la)) {
            lu = cvs_fixedl(n)
        }
        else {
            lu = la
        }
    }
    adj = 0
    if (kmax < .) {
        if (lu >= kmax) {
            lu  = kmax - 1
            adj = 1
        }
    }
    om = cvs_lrsum(e, lu, "lambda") / n
    if (om <= 0 | missing(om)) {
        return((., ., kmax, lu, adj))
    }
    // sqrt(12): int_0^1 (s - 1/2)^2 ds = 1/12 (printed (1/12)^(1/2) is a misprint)
    st = sqrt(12) * n^(-1.5) * cross(tt, e) / sqrt(om)
    return((st, 2*normal(-abs(st)), kmax, lu, adj))
}

// ---------------------------------------------------------------------------
//  Main entry point for -cointvol stoch-
//    xv   : regressors (Stata names, possibly temporary)
//    trend: 1 adds t to regressors (and instrument)
//    estim: "aiv" or "ols"
//    k    : instrument lag for the estimator
//    lest : HAC truncation for the estimator covariance, lrule "fixed" | "nw"
//    dotests, kt, lt, ltrule: residual tests (AIV residuals with lag kt)
//    hivars: series on which S_hi is computed
// ---------------------------------------------------------------------------

void cvs_stoch_main(string scalar yv, string scalar xv, string scalar touse,
                    real scalar trend, string scalar estim, real scalar k,
                    real scalar lest, string scalar lrule, real scalar dotests,
                    real scalar kt, real scalar lt, string scalar ltrule,
                    string scalar hivars)
{
    real colvector y, u, ut, dv, b, bt, h
    real matrix x, X, Z, Xc, A, Ai, S, a, V, res, H
    real scalar T, K, i, lu, ladj, la
    real rowvector r

    y = st_data(., yv, touse)
    x = st_data(., tokens(xv), touse)
    T = rows(y)
    X = x
    if (trend) {
        X = X, (1::T)
    }
    X = X, J(T, 1, 1)
    K = cols(X)

    if (estim == "aiv") {
        cvs_aiv(y, X, k, b, u)
        Z  = X[|1,1 \ T-k,K|]
        Xc = X[|k+1,1 \ T,K|]
        A  = cross(Z, Xc)
        Ai = luinv(A)
        a  = Z :* u[|k+1 \ T|]
    }
    else {
        A  = cross(X, X)
        Ai = invsym(A)
        b  = Ai * cross(X, y)
        u  = y - X * b
        a  = X :* u
    }
    if (hasmissing(Ai)) {
        errprintf("moment matrix is singular; check for collinear regressors\n")
        exit(error(506))
    }

    lu   = lest
    ladj = 0
    if (lrule == "nw") {
        if (K > 1) {
            h = rowsum(a[|1,1 \ rows(a),K-1|])
        }
        else {
            h = a[., 1]
        }
        la = cvs_nwauto(h, T)
        if (missing(la)) {
            lu = ceil(T^(1/3) - 1e-9)
        }
        else {
            lu = la
        }
        if (estim == "aiv") {
            if (lu >= k) {
                lu   = k - 1
                ladj = 1
            }
        }
    }
    S = cvs_lrsum(a, lu, "lambda")
    V = Ai * S * Ai'
    V = (V + V') / 2

    res = J(0, 5, .)
    if (dotests) {
        if (estim == "aiv" & kt == k) {
            ut = u
        }
        else {
            cvs_aiv(y, X, kt, bt, ut)
        }
        r   = cvs_snc(ut, kt, lt, ltrule)
        res = res \ r
        r   = cvs_shc(ut, lt, ltrule, kt)
        res = res \ r
        H = st_data(., tokens(hivars), touse)
        for (i = 1; i <= cols(H); i = i + 1) {
            dv = H[|2,i \ T,i|] - H[|1,i \ T-1,i|]
            if (trend) {
                dv = dv :- mean(dv)
            }
            r   = cvs_shc(dv, lt, ltrule, .)
            res = res \ r
        }
    }

    st_matrix("__cvs_b", b')
    st_matrix("__cvs_V", V)
    st_matrix("__cvs_tests", res)
    st_numscalar("__cvs_T", T)
    st_numscalar("__cvs_Neff", rows(a))
    st_numscalar("__cvs_l", lu)
    st_numscalar("__cvs_ladj", ladj)
    st_numscalar("__cvs_s2", cross(u, u) / T)
}

// ---------------------------------------------------------------------------
//  Main entry point for -cointvol hetcoint- (Hansen 1992)
//    OLS with intercept; HAC sandwich (X'X)^-1 G (X'X)^-1 with
//    G = sum_m k_m sum_t a_{t+m} a_t',  a_t = X_t w_t  (no df correction).
//    The slope block equals Hansen's T^-1 M1^-1 V1 M1^-1 (FWL, demeaned x).
//    split: regress w_t^2 on (1, 1{t > floor(T/2)}), Bartlett HAC lag slag.
// ---------------------------------------------------------------------------

void cvs_het_main(string scalar yv, string scalar xv, string scalar touse,
                  real scalar B, string scalar kern, real scalar dosplit,
                  real scalar slag)
{
    real colvector y, w, e2, D, g, rr, b
    real matrix x, X, XXi, a, G, V, Q, Qi, Vs
    real scalar T, h, ts, s1, s2

    y = st_data(., yv, touse)
    x = st_data(., tokens(xv), touse)
    T = rows(y)
    X = x, J(T, 1, 1)
    XXi = invsym(cross(X, X))
    if (diag0cnt(XXi) > 0) {
        errprintf("regressors are collinear\n")
        exit(error(506))
    }
    b = XXi * cross(X, y)
    w = y - X * b
    a = X :* w
    G = cvs_lrsum(a, B, kern)
    V = XXi * G * XXi
    V = (V + V') / 2

    ts = .
    s1 = .
    s2 = .
    if (dosplit) {
        e2 = w :* w
        h  = floor(T / 2)
        D  = J(h, 1, 0) \ J(T - h, 1, 1)
        Q  = J(T, 1, 1), D
        Qi = invsym(cross(Q, Q))
        g  = Qi * cross(Q, e2)
        rr = e2 - Q * g
        Vs = Qi * cvs_lrsum(Q :* rr, slag, "bartlett") * Qi
        s1 = g[1]
        s2 = g[1] + g[2]
        if (Vs[2,2] > 0) {
            ts = g[2] / sqrt(Vs[2,2])
        }
    }

    st_matrix("__cvs_b", b')
    st_matrix("__cvs_V", V)
    st_numscalar("__cvs_T", T)
    st_numscalar("__cvs_s2", cross(w, w) / T)
    st_numscalar("__cvs_st", ts)
    st_numscalar("__cvs_s1", s1)
    st_numscalar("__cvs_s2h", s2)
}

end
