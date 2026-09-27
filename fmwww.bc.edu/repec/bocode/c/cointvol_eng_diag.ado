*! cointvol_eng_diag 0.1.0  26sep2026
*! Mata engine of -cointvol diag- (VECM residual diagnostics) and
*! -cointvol simulate- (Monte Carlo DGP generators)
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com) - github.com/merwanroudane
*!
*! Step -> source map (diagnostics)
*!   cvd_archr2   R2 of e2_t on (1, e2_{t-1..t-h})         -> Engle (1982)
*!   cvd_stdz     W = E (L')^-1, LL' = E'E/T (Cholesky)     -> Catani & Ahlgren (2017); SRC25
*!   cvd_march    0.5 N K(K+1) - N tr(Om_res Om_0^-1) on vech(w_t w_t')
*!                -> Lutkepohl (2006, s.16.5); SRC25 computeMARCH (algorithm only)
*!   cvd_etlm     LM = s' I^-1 s, score/information of CCC-ARCH(h) at H0
*!                -> Eklund & Terasvirta (2007); SRC25 computeET_LM (algorithm only)
*!   cvd_aclm     LM (Breusch-Godfrey form) and HC0-HC3 Wald-type AC statistics
*!                -> Ahlgren & Catani (2017) eqs (6),(8),(9),(11); SRC25 ACtest
*!   cvd_portm    Q_h = T sum tr(C_j'C_0^-1 C_j C_0^-1), adjusted T^2 sum ./(T-j)
*!                -> Lutkepohl (2006, s.4.4.3, s.8.4.1)
*!   cvd_vprof    eta_i(u) = sum_{t<=Tu} e_it^2 / sum_t e_it^2 -> CRT (2010, JoE) s.6
*!   cvd_diag_main  VECM under H(r) via core engine (cv_build, cv_johansen, cv_fitrank);
*!                parametric bootstrap (Catani-Ahlgren Algorithm 1), recursive and
*!                fixed-design wild bootstrap (Ahlgren-Catani Algorithms 1-2)
*! Step -> source map (simulation)
*!   cvd_uvol     GARCH / GJR / AGARCH / EGARCH (1,1), optional CCC correlation
*!                -> Lee & Tse (1996) s.2, Table 6; CRT (2010, ET) models A-E;
*!                   CDRT (2018) case A; Maki (2013) eqs (32)-(33)
*!   cvd_draw     N(0,1), standardised t, Hansen (1994) skewed t
*!   cvd_sv       e = v exp(h), h_t = lam h_{t-1} + 0.5 xi_t -> CRT (2010, ET) model F
*!   cvd_figarch  h_t = c + b h_{t-1} + [1 - bL - (1 - phi L)(1-L)^d] e_t^2, lag 1000
*!                -> Maki (2013) eqs (43)-(45) (Brunetti & Gilbert 2000)
*!   cvd_bekk     H_t = C + A e e' A' + B H B'  -> Maki (2013) eqs (37)-(38); Kurita (2009) eq (2)
*!   cvd_breakpath / cvd_oupath / cvd_applyvol  variance breaks and OU volatility
*!                -> CRT (2010, JoE) s.5; CDRT (2018) case C; BCDT (2022) s.5;
*!                   Cavaliere & Taylor (2006) eq (9); Boswijk & Zu (2022) s.5 case 4
*!   cvd_vecmlev  dX_t = a(b'X_{t-1} + rho') + sum G_j dX_{t-j} + mu + e_t
*!   cvd_hml / cvd_mlh  Harris, McCabe & Leybourne (2002) s.4; McCabe, Leybourne & Harris (2006) eq (10)
*!   cvd_hci      Hansen (1992) eqs (1)-(4)
*!
*! Running this file (quietly run) compiles the functions below. It needs the core
*! engine (struct cv_joh), which is loaded first if absent.

program define cointvol_eng_diag
    version 14.0
end

version 14.0
capture mata: st_local("__cvd0", cv_engine_version())
if _rc {
    capture program drop cointvol_engine
    quietly findfile cointvol_engine.ado
    quietly run `"`r(fn)'"'
}
capture mata: mata drop cvd_*()

mata:

string scalar cvd_version()
{
    return("0.1.0")
}

// ===========================================================================
//  Utilities
// ===========================================================================

real matrix cvd_resid(real matrix Y, real matrix X)
{
    if (cols(X) == 0) {
        return(Y)
    }
    return(Y - X * (invsym(cross(X, X)) * cross(X, Y)))
}

// Cholesky-standardised residuals: W = E (L')^-1 with L L' = E'E/T
real matrix cvd_stdz(real matrix E)
{
    real matrix L, W
    L = cholesky(cross(E, E) / rows(E))
    if (hasmissing(L)) {
        return(J(rows(E), cols(E), .))
    }
    W = solvelower(L, E')
    return(W')
}

// lag j of the rows of X with zero pre-sample padding
real matrix cvd_lagz(real matrix X, real scalar j)
{
    real scalar n, c
    n = rows(X)
    c = cols(X)
    if (j >= n) {
        return(J(n, c, 0))
    }
    if (j <= 0) {
        return(X)
    }
    return(J(j, c, 0) \ X[|1,1 \ n-j,c|])
}

// ===========================================================================
//  ARCH-type tests
// ===========================================================================

// R2 of the Engle (1982) auxiliary regression e2_t on (1, e2_{t-1},...,e2_{t-h})
real scalar cvd_archr2(real colvector e2, real scalar h)
{
    real scalar n, j, ssr, sst
    real colvector y, u, yc
    real matrix X
    n = rows(e2)
    if (n <= h + 3) {
        return(.)
    }
    y = e2[|h+1 \ n|]
    X = J(n-h, 1, 1)
    for (j = 1; j <= h; j = j + 1) {
        X = X, e2[|h+1-j \ n-j|]
    }
    u   = y - X * (invsym(cross(X, X)) * cross(X, y))
    ssr = cross(u, u)
    yc  = y :- mean(y)
    sst = cross(yc, yc)
    if (sst <= 0) {
        return(.)
    }
    return(1 - ssr/sst)
}

// Multivariate ARCH-LM (Lutkepohl 2006, s.16.5): all N rows used, lags zero-padded
real scalar cvd_march(real matrix W, real scalar h)
{
    real scalar N, K, m, i, j, c, l
    real matrix V, X, U, Vd
    N = rows(W)
    K = cols(W)
    m = K*(K+1)/2
    V = J(N, m, .)
    c = 0
    for (i = 1; i <= K; i = i + 1) {
        for (j = i; j <= K; j = j + 1) {
            c = c + 1
            V[., c] = W[., i] :* W[., j]
        }
    }
    X = J(N, 1, 1)
    for (l = 1; l <= h; l = l + 1) {
        X = X, cvd_lagz(V, l)
    }
    U  = cvd_resid(V, X)
    Vd = V :- mean(V)
    return(0.5*N*K*(K+1) - N*trace(cross(U, U) * invsym(cross(Vd, Vd))))
}

// Eklund-Terasvirta (2007) LM test of constant covariance against CCC-ARCH(h)
// parameters: (a0_i, a_i1..a_ih), i = 1..K, then correlations rho_rc (r > c)
real scalar cvd_etlm(real matrix W, real scalar h)
{
    real scalar n, K, np, nt, i, j, a, b, c, d, m1, m2, cb
    real matrix Cv, P, Pv, F1d, F2p, F3, X, W2, Wt, Z, G, Iaa, Iar, Irr, Inf, M, pr
    real colvector Dv, sa, sr, s
    real rowvector cs

    n  = rows(W)
    K  = cols(W)
    nt = n - h
    if (nt <= K*(h+1) + 2) {
        return(.)
    }
    Cv = variance(W)
    Dv = sqrt(diagonal(Cv))
    P  = correlation(W)
    Pv = invsym(P)
    np = K*(K-1)/2
    pr = J(max((np, 1)), 2, .)
    m1 = 0
    for (j = 1; j <= K; j = j + 1) {
        for (i = j+1; i <= K; i = i + 1) {
            m1 = m1 + 1
            pr[m1, 1] = i
            pr[m1, 2] = j
        }
    }
    // information blocks (expected information at H0)
    F1d = diag(Dv:^2) + Pv :* Cv
    W2  = W:^2
    X   = J(nt, K*(h+1), .)
    for (i = 1; i <= K; i = i + 1) {
        cb = (i-1)*(h+1)
        X[., cb+1] = J(nt, 1, 1)
        for (j = 1; j <= h; j = j + 1) {
            X[., cb+1+j] = W2[|h+1-j, i \ n-j, i|]
        }
        X[|1,cb+1 \ nt,cb+h+1|] = X[|1,cb+1 \ nt,cb+h+1|] :* (-0.5 / (Dv[i]^3))
    }
    Iaa = cross(X, X) :* (F1d # J(h+1, h+1, 1))
    // score for the ARCH block: g_it = D_i - e_it (P^-1 z_t)_i, z = D^-1 e
    Wt = W[|h+1,1 \ n,K|]
    Z  = Wt :/ Dv'
    G  = Dv' :- Wt :* (Z * Pv)
    sa = J(K*(h+1), 1, .)
    for (i = 1; i <= K; i = i + 1) {
        cb = (i-1)*(h+1)
        sa[|cb+1 \ cb+h+1|] = cross(X[|1,cb+1 \ nt,cb+h+1|], G[., i])
    }
    if (np == 0) {
        return(sa' * invsym(Iaa) * sa)
    }
    F2p = J(K, np, 0)
    for (m1 = 1; m1 <= np; m1 = m1 + 1) {
        a = pr[m1, 1]
        b = pr[m1, 2]
        F2p[b, m1] = Dv[b] * Pv[b, a]
        F2p[a, m1] = Dv[a] * Pv[a, b]
    }
    F3 = J(np, np, .)
    for (m1 = 1; m1 <= np; m1 = m1 + 1) {
        for (m2 = 1; m2 <= np; m2 = m2 + 1) {
            a = pr[m1, 1]
            b = pr[m1, 2]
            c = pr[m2, 1]
            d = pr[m2, 2]
            F3[m1, m2] = Pv[a, c]*Pv[b, d] + Pv[a, d]*Pv[b, c]
        }
    }
    cs  = colsum(X)
    Iar = -(cs' :* (F2p # J(h+1, 1, 1)))
    Irr = nt :* F3
    // score for the correlation block: sum_t (P^-1 z z' P^-1 - P^-1)_rc
    M  = Pv * cross(Z, Z) * Pv - nt :* Pv
    sr = J(np, 1, .)
    for (m1 = 1; m1 <= np; m1 = m1 + 1) {
        sr[m1] = M[pr[m1, 1], pr[m1, 2]]
    }
    s   = sa \ sr
    Inf = (Iaa, Iar \ Iar', Irr)
    Inf = (Inf + Inf') / 2
    return(s' * invsym(Inf) * s)
}

// Eklund & Terasvirta (2007) LM statistic (14) built from Theorem 1, eqs (12)-(13),
// with h_i = identity in (2): omega_iit = phi_i'v_it, constant correlations (3), (8).
//   E : n x K residuals on the estimation sample of the auxiliary likelihood
//   V : n x K*q1 regressors; block i = v_it' = (1, v_i1t, ..., v_i(q1-1)t)
// dvec(D_t^-1)/dphi_i' = -0.5 omega_ii^(-3/2) v_it' (Appendix B, eq (B.3)).
// Nuisance parameters (sigma_i^2, rho) take their ML values under H0 on the same
// sample, Omega = E'E/n, so that their scores vanish exactly (eq (14)).
// Asymptotic chi2 with K (q1 - 1) degrees of freedom.
real scalar cvd_etgen(real matrix E, real matrix V, real scalar q1)
{
    real scalar n, K, np, i, j, a, b, c, d, m1, m2, cb
    real matrix Om, P, Pv, F1d, F2p, F3, X, Z, G, Iaa, Iar, Irr, Inf, M, pr
    real colvector Dv, sa, sr, s
    real rowvector cs

    n  = rows(E)
    K  = cols(E)
    if (n <= K*q1 + 2) {
        return(.)
    }
    Om = cross(E, E) / n
    Dv = sqrt(diagonal(Om))
    if (min(Dv) <= 0) {
        return(.)
    }
    P  = Om :/ (Dv * Dv')
    Pv = invsym(P)
    np = K*(K-1)/2
    pr = J(max((np, 1)), 2, .)
    m1 = 0
    for (j = 1; j <= K; j = j + 1) {
        for (i = j+1; i <= K; i = i + 1) {
            m1 = m1 + 1
            pr[m1, 1] = i
            pr[m1, 2] = j
        }
    }
    // (13), first block: dvecD^-1' {D (x) D + (P^-1 (x) Om)/2 + (Om (x) P^-1)/2} dvecD^-1
    F1d = diag(Dv:^2) + Pv :* Om
    X   = V
    for (i = 1; i <= K; i = i + 1) {
        cb = (i-1)*q1
        X[|1,cb+1 \ n,cb+q1|] = X[|1,cb+1 \ n,cb+q1|] :* (-0.5 / (Dv[i]^3))
    }
    Iaa = cross(X, X) :* (F1d # J(q1, q1, 1))
    // (12), first term: element (i,i) of D - e e'D^-1P^-1/2 - P^-1D^-1 e e'/2
    Z  = E :/ Dv'
    G  = Dv' :- E :* (Z * Pv)
    sa = J(K*q1, 1, .)
    for (i = 1; i <= K; i = i + 1) {
        cb = (i-1)*q1
        sa[|cb+1 \ cb+q1|] = cross(X[|1,cb+1 \ n,cb+q1|], G[., i])
    }
    if (np == 0) {
        return(sa' * invsym(Iaa) * sa)
    }
    // (13), cross block -dvecD^-1'(D (x) P^-1 + P^-1 (x) D) dvecP/2
    F2p = J(K, np, 0)
    for (m1 = 1; m1 <= np; m1 = m1 + 1) {
        a = pr[m1, 1]
        b = pr[m1, 2]
        F2p[b, m1] = Dv[b] * Pv[b, a]
        F2p[a, m1] = Dv[a] * Pv[a, b]
    }
    // (13), last block dvecP'(P^-1 (x) P^-1) dvecP/2
    F3 = J(np, np, .)
    for (m1 = 1; m1 <= np; m1 = m1 + 1) {
        for (m2 = 1; m2 <= np; m2 = m2 + 1) {
            a = pr[m1, 1]
            b = pr[m1, 2]
            c = pr[m2, 1]
            d = pr[m2, 2]
            F3[m1, m2] = Pv[a, c]*Pv[b, d] + Pv[a, d]*Pv[b, c]
        }
    }
    cs  = colsum(X)
    Iar = -(cs' :* (F2p # J(q1, 1, 1)))
    Irr = n :* F3
    // (12), second term: dvecP' vec(P^-1 z z' P^-1 - P^-1)/2
    M  = Pv * cross(Z, Z) * Pv - n :* Pv
    sr = J(np, 1, .)
    for (m1 = 1; m1 <= np; m1 = m1 + 1) {
        sr[m1] = M[pr[m1, 1], pr[m1, 2]]
    }
    s   = sa \ sr
    Inf = (Iaa, Iar \ Iar', Irr)
    Inf = (Inf + Inf') / 2
    return(s' * invsym(Inf) * s)
}

// ET against CCC-ARCH(h), eq (6)/(23): v_it = (1, e2_i,t-1, ..., e2_i,t-h)',
// t = h+1..n (the first h residuals serve as presample), df K h
real scalar cvd_etarch(real matrix E, real scalar h)
{
    real scalar n, K, nt, i, j, cb
    real matrix E2, V
    n  = rows(E)
    K  = cols(E)
    nt = n - h
    if (nt <= K*(h+1) + 2) {
        return(.)
    }
    E2 = E:^2
    V  = J(nt, K*(h+1), 1)
    for (i = 1; i <= K; i = i + 1) {
        cb = (i-1)*(h+1)
        for (j = 1; j <= h; j = j + 1) {
            V[., cb+1+j] = E2[|h+1-j, i \ n-j, i|]
        }
    }
    return(cvd_etgen(E[|h+1,1 \ n,K|], V, h+1))
}

// ET against smoothly time-varying variances, s.5.3, eqs (24), (27)-(29) with
// tau_t = t/T: v_it = (1, tau_t)' (order 1, df K); order s > 1 uses the polynomial
// (1, tau_t, ..., tau_t^s)' suggested on p. 762 (df K s)
real scalar cvd_etst(real matrix E, real scalar ord)
{
    real scalar n, K, i, j, cb
    real matrix V
    real colvector tau
    n   = rows(E)
    K   = cols(E)
    tau = (1::n) / n
    V   = J(n, K*(ord+1), 1)
    for (i = 1; i <= K; i = i + 1) {
        cb = (i-1)*(ord+1)
        for (j = 1; j <= ord; j = j + 1) {
            V[., cb+1+j] = tau:^j
        }
    }
    return(cvd_etgen(E, V, ord+1))
}

// ===========================================================================
//  Ling & Li (1997) portmanteau test on q_t = e_t' V_t^-1 e_t
// ===========================================================================

// q_t = e_t' V_t^-1 e_t; Vv = T x K(K+1)/2 (vech of V_t, one row per t) or empty,
// in which case V_t = E'E/T (unconditional ML covariance). Missing on failure.
real colvector cvd_llq(real matrix E, real matrix Vv)
{
    real scalar T, K, t
    real matrix Si, Vt
    real colvector q, x
    T = rows(E)
    K = cols(E)
    if (cols(Vv) == 0) {
        Si = invsym(cross(E, E) / T)
        return(rowsum((E * Si) :* E))
    }
    q = J(T, 1, .)
    for (t = 1; t <= T; t = t + 1) {
        Vt = invvech(Vv[t, .]')
        x  = cholsolve(Vt, E[t, .]')
        if (hasmissing(x)) {
            return(J(T, 1, .))
        }
        q[t] = E[t, .] * x
    }
    return(q)
}

// R_l, l = 1..M, of eq (2.11): sum_{t>l} (q_t - K)(q_{t-l} - K) / sum_t (q_t - K)^2
real rowvector cvd_llacf(real colvector q, real scalar K, real scalar M)
{
    real scalar n, l, den
    real colvector qd
    real rowvector R
    n  = rows(q)
    qd = q :- K
    R  = J(1, M, .)
    den = cross(qd, qd)
    if (den <= 0) {
        return(R)
    }
    for (l = 1; l <= M; l = l + 1) {
        R[l] = cross(qd[|l+1 \ n|], qd[|1 \ n-l|]) / den
    }
    return(R)
}

// ===========================================================================
//  Residual autocorrelation tests
// ===========================================================================

// returns (LM, HC0, HC1, HC2, HC3) for AC of order h; Zr = model regressors
real rowvector cvd_aclm(real matrix Zr, real matrix E, real scalar h)
{
    real scalar T, K, m, l
    real matrix El, Sc, X, A, Bh, At, G, G2
    real colvector cv, psi, lev
    real rowvector out

    T  = rows(E)
    K  = cols(E)
    m  = cols(Zr)
    El = J(T, 0, .)
    for (l = 1; l <= h; l = l + 1) {
        El = El, cvd_lagz(E, l)
    }
    out = J(1, 5, .)
    if (m > 0) {
        Sc = cross(El, El) - cross(El, Zr) * invsym(cross(Zr, Zr)) * cross(Zr, El)
    }
    else {
        Sc = cross(El, El)
    }
    cv = vec(cross(E, El))
    out[1] = cv' * (invsym(Sc) # invsym(cross(E, E) / T)) * cv
    // HCCME versions: sandwich (X'X)^-1 [sum x x' (x) e e'] (X'X)^-1, psi block
    X   = Zr, El
    A   = invsym(cross(X, X))
    Bh  = (A * cross(X, E))'
    psi = vec(Bh[|1,m+1 \ K,m+K*h|])
    At  = X * A
    At  = At[|1,m+1 \ T,m+K*h|]
    if (m > 0) {
        lev = rowsum((Zr * invsym(cross(Zr, Zr))) :* Zr)
    }
    else {
        lev = J(T, 1, 0)
    }
    G = J(T, K*K*h, .)
    for (l = 1; l <= K*h; l = l + 1) {
        G[|1,(l-1)*K+1 \ T,l*K|] = At[., l] :* E
    }
    out[2] = psi' * invsym(cross(G, G)) * psi
    out[3] = out[2] * (T - m) / T
    G2 = G :/ sqrt(1 :- lev)
    out[4] = psi' * invsym(cross(G2, G2)) * psi
    G2 = G :/ (1 :- lev)
    out[5] = psi' * invsym(cross(G2, G2)) * psi
    return(out)
}

// multivariate portmanteau: (Q_h, adjusted Q_h)
real rowvector cvd_portm(real matrix E, real scalar h)
{
    real scalar T, K, j, q, qa, tr
    real matrix C0i, Cj
    T   = rows(E)
    K   = cols(E)
    C0i = invsym(cross(E, E) / T)
    q   = 0
    qa  = 0
    for (j = 1; j <= h; j = j + 1) {
        Cj = cross(E[|j+1,1 \ T,K|], E[|1,1 \ T-j,K|]) / T
        tr = trace(Cj' * C0i * Cj * C0i)
        q  = q + tr
        qa = qa + tr / (T - j)
    }
    return((T*q, T*T*qa))
}

// variance profiles (T x K)
real matrix cvd_vprof(real matrix E)
{
    real scalar T, K, i
    real matrix E2, VP
    T  = rows(E)
    K  = cols(E)
    E2 = E:^2
    VP = J(T, K, .)
    for (i = 1; i <= K; i = i + 1) {
        VP[., i] = runningsum(E2[., i]) / sum(E2[., i])
    }
    return(VP)
}

// p-value (#{x* >= x} + 1)/(#valid + 1), missing draws ignored
real scalar cvd_bootp(real colvector xs, real scalar x)
{
    real scalar nv
    if (missing(x)) {
        return(.)
    }
    nv = sum(xs :< .)
    if (nv == 0) {
        return(.)
    }
    return((sum((xs :>= x) :& (xs :< .)) + 1) / (nv + 1))
}

// ===========================================================================
//  Main entry point for -cointvol diag-
// ===========================================================================

void cvd_diag_main(string scalar vars, string scalar touse, real scalar k,
                   string scalar det, real scalar r, real scalar harch,
                   real scalar hmarch, real scalar hca, real scalar het,
                   real scalar hac, real scalar hport, real scalar doboot,
                   real scalar B, string scalar mult, real scalar wbrec,
                   real scalar wbfix, real scalar dots, string scalar ectn,
                   string scalar vpn, real scalar etchol, real scalar hst,
                   real scalar hll, real scalar llr, string scalar llvn)
{
    struct cv_joh scalar Jd, Jb
    real matrix Y, D1, D2, Z0, Z1, Z2, alpha, bstar, Psi, E, Zr, W, L, U, Eb, Wb
    real matrix Pi, Gm, Ys, Z0b, Z1b, Z2b, ab, bb, Psib, Zrb, VP, ect, bn, cc
    real matrix archm, multi, cam, acm, ACr, ACf, CAb, vpm, lltab, llacf, Vv
    real colvector mods, w, idx, MAb, ETb, STb, dev, uu, qll
    real rowvector ac0, pm, port, Rll
    real scalar T0, T, p, i, b, j, ll, llb, r2, fa, fw, gLM, nunit, nexp
    real scalar df, runboot, m, loc, lstab, ssq, fac
    string rowvector nms, vnms

    Y  = st_data(., tokens(vars), touse)
    T0 = rows(Y)
    cv_detmats(T0, det, D1, D2)
    cv_build(Y, k, D1, D2, Z0, Z1, Z2)
    Jd = cv_johansen(Z0, Z1, Z2)
    if (Jd.ok == 0) {
        errprintf("moment matrices are singular; check for collinear or constant series\n")
        exit(error(506))
    }
    p = Jd.p
    T = Jd.T
    cv_fitrank(Jd, r, alpha, bstar, Psi, E, ll)
    if (r > 0) {
        Zr = (Z1 * bstar), Z2
        Pi = alpha * bstar'
    }
    else {
        Zr = Z2
        Pi = J(p, Jd.p1, 0)
    }
    W  = cvd_stdz(E)
    fa = 0
    fw = 0
    // observation numbers of the residual rows t = k+1..T0 of the estimation sample
    idx = selectindex(st_data(., touse))
    idx = idx[|k+1 \ T0|]

    // ---- (1) univariate Engle ARCH-LM on raw residuals ------------------
    archm = J(p, 4, .)
    if (harch > 0) {
        for (i = 1; i <= p; i = i + 1) {
            r2 = cvd_archr2(E[., i]:^2, harch)
            archm[i, 1] = (T - harch) * r2
            archm[i, 2] = harch
            archm[i, 3] = chi2tail(harch, archm[i, 1])
            archm[i, 4] = r2
        }
    }

    // ---- (2) multivariate ARCH tests: rows MARCH, ET, CA, ET-ST ----------
    multi = J(4, 4, .)
    cam   = J(p, 4, .)
    gLM   = .
    if (hmarch > 0) {
        multi[1, 1] = cvd_march(W, hmarch)
        multi[1, 2] = p*p*(p+1)*(p+1)*hmarch/4
        multi[1, 3] = chi2tail(multi[1, 2], multi[1, 1])
    }
    if (het > 0) {
        // Eklund & Terasvirta (2007) eq (14) on the model residuals (default), or the
        // VARtests variant on Cholesky-standardised residuals (option etchol)
        if (etchol) {
            multi[2, 1] = cvd_etlm(W, het)
        }
        else {
            multi[2, 1] = cvd_etarch(E, het)
        }
        multi[2, 2] = p*het
        multi[2, 3] = chi2tail(multi[2, 2], multi[2, 1])
    }
    if (hst > 0) {
        multi[4, 1] = cvd_etst(E, hst)
        multi[4, 2] = p*hst
        multi[4, 3] = chi2tail(multi[4, 2], multi[4, 1])
    }
    if (hca > 0) {
        for (i = 1; i <= p; i = i + 1) {
            cam[i, 1] = T * cvd_archr2(W[., i]:^2, hca)
            cam[i, 2] = hca
            cam[i, 3] = chi2tail(hca, cam[i, 1])
        }
        multi[3, 1] = max(cam[., 1])
        multi[3, 2] = hca
        gLM = 1 - min(cam[., 3])
    }
    runboot = 0
    if (hca > 0) {
        runboot = 1
    }
    if (doboot) {
        if (hmarch > 0 | het > 0 | hst > 0) {
            runboot = 1
        }
    }
    if (runboot) {
        // Catani & Ahlgren (2017) Algorithm 1: Y* = Z b + W* S, fixed design
        L   = cholesky(cross(E, E) / T)
        CAb = J(B, p, .)
        MAb = J(B, 1, .)
        ETb = J(B, 1, .)
        STb = J(B, 1, .)
        if (dots) {
            printf("{txt}ARCH-test parametric bootstrap (%g draws): ", B)
            displayflush()
        }
        for (b = 1; b <= B; b = b + 1) {
            U  = rnormal(T, p, 0, 1) * L'
            Eb = cvd_resid(U, Zr)
            Wb = cvd_stdz(Eb)
            if (hasmissing(Wb)) {
                fa = fa + 1
                if (fa > 10*B) {
                    errprintf("parametric bootstrap failed repeatedly (singular draws)\n")
                    exit(error(430))
                }
                b = b - 1
                continue
            }
            if (hca > 0) {
                for (i = 1; i <= p; i = i + 1) {
                    CAb[b, i] = T * cvd_archr2(Wb[., i]:^2, hca)
                }
            }
            if (doboot) {
                if (hmarch > 0) {
                    MAb[b] = cvd_march(Wb, hmarch)
                }
                if (het > 0) {
                    if (etchol) {
                        ETb[b] = cvd_etlm(Wb, het)
                    }
                    else {
                        ETb[b] = cvd_etarch(Eb, het)
                    }
                }
                if (hst > 0) {
                    STb[b] = cvd_etst(Eb, hst)
                }
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
        if (hca > 0) {
            for (i = 1; i <= p; i = i + 1) {
                cam[i, 4] = cvd_bootp(CAb[., i], cam[i, 1])
            }
            multi[3, 4] = cvd_bootp(rowmax(CAb), multi[3, 1])
        }
        if (doboot) {
            if (hmarch > 0) {
                multi[1, 4] = cvd_bootp(MAb, multi[1, 1])
            }
            if (het > 0) {
                multi[2, 4] = cvd_bootp(ETb, multi[2, 1])
            }
            if (hst > 0) {
                multi[4, 4] = cvd_bootp(STb, multi[4, 1])
            }
        }
    }

    // ---- (3) residual autocorrelation: rows LM, HC0..HC3 ----------------
    // cols: statistic, df, asy p, recursive-WB p, fixed-WB p
    acm = J(5, 5, .)
    if (hac > 0) {
        ac0 = cvd_aclm(Zr, E, hac)
        df  = hac*p*p
        for (i = 1; i <= 5; i = i + 1) {
            acm[i, 1] = ac0[i]
            acm[i, 2] = df
            acm[i, 3] = chi2tail(df, ac0[i])
        }
        if (doboot) {
            ACr = J(B, 5, .)
            ACf = J(B, 5, .)
            if (dots) {
                printf("{txt}AC-test wild bootstrap (%g draws): ", B)
                displayflush()
            }
            for (b = 1; b <= B; b = b + 1) {
                w = cv_mult(T, mult)
                U = E :* w
                if (wbfix) {
                    Eb = cvd_resid(U, Zr)
                    ACf[b, .] = cvd_aclm(Zr, Eb, hac)
                }
                if (wbrec) {
                    Ys = cv_simvecm(Y[|1,1 \ k,p|], Pi, Psi, U, D1, D2, k)
                    cv_build(Ys, k, D1, D2, Z0b, Z1b, Z2b)
                    Jb = cv_johansen(Z0b, Z1b, Z2b)
                    if (Jb.ok == 0 | hasmissing(Jb.lam)) {
                        fw = fw + 1
                        if (fw > 10*B) {
                            errprintf("wild bootstrap failed repeatedly (explosive or singular samples)\n")
                            exit(error(430))
                        }
                        b = b - 1
                        continue
                    }
                    cv_fitrank(Jb, r, ab, bb, Psib, Eb, llb)
                    if (r > 0) {
                        Zrb = (Z1b * bb), Z2b
                    }
                    else {
                        Zrb = Z2b
                    }
                    ACr[b, .] = cvd_aclm(Zrb, Eb, hac)
                    if (hasmissing(ACr[b, .])) {
                        fw = fw + 1
                        if (fw > 10*B) {
                            errprintf("wild bootstrap failed repeatedly (explosive or singular samples)\n")
                            exit(error(430))
                        }
                        b = b - 1
                        continue
                    }
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
            for (i = 1; i <= 5; i = i + 1) {
                if (wbrec) {
                    acm[i, 4] = cvd_bootp(ACr[., i], ac0[i])
                }
                if (wbfix) {
                    acm[i, 5] = cvd_bootp(ACf[., i], ac0[i])
                }
            }
        }
    }

    // ---- (4) portmanteau ----------------------------------------------
    port = J(1, 5, .)
    if (hport > 0) {
        pm = cvd_portm(E, hport)
        df = p*p*(hport - k + 1) - p*r
        port[1] = pm[1]
        port[2] = pm[2]
        port[3] = df
        if (df > 0) {
            port[4] = chi2tail(df, pm[1])
            port[5] = chi2tail(df, pm[2])
        }
    }

    // ---- (4b) Ling & Li (1997) portmanteau on q_t = e_t' V_t^-1 e_t --------
    // rows Q(M) (3.10), Q(M) finite-sample (4.6), Q(r,M) (3.11), Q(r,M) (4.6);
    // cols statistic, df, p. V_t = E'E/T (X = 0, Omega = I_M) or user-supplied vech(V_t).
    lltab = J(4, 3, .)
    llacf = J(max((hll, 1)), 3, .)
    if (hll > 0) {
        Vv = J(T, 0, .)
        if (llvn != "") {
            Vv = st_data(idx, tokens(llvn))
            if (hasmissing(Vv)) {
                errprintf("llvcov(): missing values in the estimation sample\n")
                exit(error(416))
            }
        }
        qll = cvd_llq(E, Vv)
        if (hasmissing(qll)) {
            errprintf("llvcov(): V_t is not positive definite for some t\n")
            exit(error(506))
        }
        Rll = cvd_llacf(qll, p, hll)
        fac = T - hll - 2*p - k - llr + 1
        ssq = sum(Rll:^2)
        lltab[1, 1] = T*ssq
        lltab[1, 2] = hll
        lltab[1, 3] = chi2tail(hll, lltab[1, 1])
        if (fac > 0) {
            lltab[2, 1] = fac*ssq
            lltab[2, 2] = hll
            lltab[2, 3] = chi2tail(hll, lltab[2, 1])
        }
        if (llr > 0) {
            ssq = sum(Rll[|llr+1 \ hll|]:^2)
            lltab[3, 1] = T*ssq
            lltab[3, 2] = hll - llr
            lltab[3, 3] = chi2tail(hll - llr, lltab[3, 1])
            if (fac > 0) {
                lltab[4, 1] = fac*ssq
                lltab[4, 2] = hll - llr
                lltab[4, 3] = chi2tail(hll - llr, lltab[4, 1])
            }
        }
        for (j = 1; j <= hll; j = j + 1) {
            llacf[j, 1] = Rll[j]
            llacf[j, 2] = 1/sqrt(T)
            llacf[j, 3] = Rll[j]*sqrt(T)
        }
    }

    // ---- (5) variance profiles ------------------------------------------
    VP  = cvd_vprof(E)
    uu  = (1::T) / T
    vpm = J(p, 3, .)
    for (i = 1; i <= p; i = i + 1) {
        dev = VP[., i] - uu
        m   = 0
        loc = 1
        for (j = 1; j <= T; j = j + 1) {
            if (abs(dev[j]) > m) {
                m   = abs(dev[j])
                loc = j
            }
        }
        vpm[i, 1] = m
        vpm[i, 2] = loc / T
        vpm[i, 3] = dev[loc]
    }

    // ---- (6) companion roots --------------------------------------------
    if (k > 1) {
        Gm = Psi[|1,1 \ p,p*(k-1)|]
    }
    else {
        Gm = J(p, 0, .)
    }
    mods  = cv_roots(Pi[|1,1 \ p,p|], Gm, k)
    nunit = sum(abs(mods :- 1) :< 1e-5)
    nexp  = sum(mods :> 1 + 1e-5)
    lstab = .
    for (j = 1; j <= rows(mods); j = j + 1) {
        if (mods[j] < 1 - 1e-5) {
            lstab = mods[j]
            break
        }
    }

    // ---- (7) error-correction terms for spreadgarch; profile variables ---
    if (vpn != "") {
        vnms = tokens(vpn)
        for (j = 1; j <= cols(vnms); j = j + 1) {
            if (j <= p) {
                st_store(idx, vnms[j], VP[., j])
            }
        }
    }
    if (ectn != "") {
        if (r > 0) {
            bn = bstar
            cc = bn[|1,1 \ r,r|]
            if (abs(det(cc)) > 1e-10) {
                bn = bn * luinv(cc)
            }
            ect = Z1 * bn
            nms = tokens(ectn)
            for (j = 1; j <= cols(nms); j = j + 1) {
                if (j <= r) {
                    st_store(idx, nms[j], ect[., j])
                }
            }
            st_matrix("__cvd_bnorm", bn)
        }
    }

    st_matrix("__cvd_archlm", archm)
    st_matrix("__cvd_multi", multi)
    st_matrix("__cvd_ca", cam)
    st_matrix("__cvd_ac", acm)
    st_matrix("__cvd_port", port)
    st_matrix("__cvd_lltab", lltab)
    st_matrix("__cvd_llacf", llacf)
    if (T <= c("matsize")) {
        st_matrix("__cvd_vp", VP)
    }
    st_matrix("__cvd_vpmax", vpm)
    st_matrix("__cvd_roots", mods)
    if (r > 0) {
        st_matrix("__cvd_alpha", alpha)
        st_matrix("__cvd_beta", bstar)
    }
    st_numscalar("__cvd_T", T)
    st_numscalar("__cvd_ll", ll)
    st_numscalar("__cvd_gLM", gLM)
    st_numscalar("__cvd_nunit", nunit)
    st_numscalar("__cvd_nexp", nexp)
    st_numscalar("__cvd_lstab", lstab)
    st_numscalar("__cvd_fa", fa)
    st_numscalar("__cvd_fw", fw)
}

// ===========================================================================
//  Simulation: innovation distributions
// ===========================================================================

// Hansen (1994) skewed t constants, eqs (11)-(13): returns (a, b, c)
real rowvector cvd_skt_abc(real scalar eta, real scalar lam)
{
    real scalar a, b, c
    c = exp(lngamma((eta+1)/2) - lngamma(eta/2)) / sqrt(pi()*(eta-2))
    a = 4*lam*c*(eta-2)/(eta-1)
    b = sqrt(1 + 3*lam*lam - a*a)
    return((a, b, c))
}

// quantile function of the unit-variance Student t: q = s F_eta^-1(p), s = ((eta-2)/eta)^1/2
real matrix cvd_qinv(real matrix pp, real scalar eta)
{
    real matrix lo, hi, tl, tu
    lo = (pp :< 0.5)
    hi = 1 :- lo
    tl = -invttail(eta, lo :* pp :+ hi :* 0.5)
    tu = invttail(eta, hi :* (1 :- pp) :+ lo :* 0.5)
    return(sqrt((eta-2)/eta) :* (lo :* tl :+ hi :* tu))
}

// Exact inverse-CDF draws from Hansen's (1994) density (10). With y = b z + a,
// G(z) = (1-lam) F_q(y/(1-lam)) for y < 0 and (1-lam)/2 + (1+lam)(F_q(y/(1+lam)) - 1/2)
// for y >= 0 (F_q: unit-variance t cdf), so for u ~ U(0,1)
//   y = (1-lam) F_q^-1(u/(1-lam))                       if u < (1-lam)/2
//   y = (1+lam) F_q^-1(1/2 + (u - (1-lam)/2)/(1+lam))  otherwise;  z = (y - a)/b
real matrix cvd_skt_draw(real scalar n, real scalar p, real scalar eta, real scalar lam)
{
    real matrix U, w, pp, sc
    real rowvector abc
    real scalar p0
    abc = cvd_skt_abc(eta, lam)
    p0  = (1 - lam)/2
    U   = runiform(n, p)
    U   = U :+ (U :<= 0) :* 1e-16
    w   = (U :< p0)
    pp  = w :* (U :/ (1 - lam)) :+ (1 :- w) :* (0.5 :+ (U :- p0) :/ (1 + lam))
    pp  = pp :* (pp :< 1) :+ (pp :>= 1) :* (1 - 1e-16)
    sc  = w :* (1 - lam) :+ (1 :- w) :* (1 + lam)
    return(((sc :* cvd_qinv(pp, eta)) :- abc[1]) :/ abc[2])
}

// kappa = E[z^2 1(z < 0)] for Hansen's skewed t (1/2 when lam = 0), closed form from
// the truncated moments of the unit-variance t, M_k(x) = int_{-inf}^x v^k f_q(v) dv:
//   M0 = F_eta(x/s), M1 = -c(eta-2)/(eta-1) (1 + x^2/(eta-2))^{-(eta-1)/2},
//   M2 = (eta-1) F_{eta-2}(x) - (eta-2) F_eta(x/s)
// Used for the GJR unit-variance normalisation omega = 1 - a - g kappa - b.
real scalar cvd_skt_kappa(real scalar eta, real scalar lam)
{
    real scalar a, b, c, s, x1, x2, tot, m0, m1, m2, d0, d1, d2
    real rowvector abc
    abc = cvd_skt_abc(eta, lam)
    a = abc[1]
    b = abc[2]
    c = abc[3]
    s = sqrt((eta-2)/eta)
    x1 = min((0, a)) / (1 - lam)
    m0 = ttail(eta, -x1/s)
    m1 = -c*(eta-2)/(eta-1) * (1 + x1*x1/(eta-2))^(-(eta-1)/2)
    m2 = (eta-1)*ttail(eta-2, -x1) - (eta-2)*ttail(eta, -x1/s)
    tot = (1-lam) * ((1-lam)*(1-lam)*m2 - 2*a*(1-lam)*m1 + a*a*m0)
    if (a > 0) {
        x2 = a / (1 + lam)
        d0 = ttail(eta, -x2/s) - 0.5
        d1 = -c*(eta-2)/(eta-1) * ((1 + x2*x2/(eta-2))^(-(eta-1)/2) - 1)
        d2 = (eta-1)*(ttail(eta-2, -x2) - 0.5) - (eta-2)*(ttail(eta, -x2/s) - 0.5)
        tot = tot + (1+lam) * ((1+lam)*(1+lam)*d2 - 2*a*(1+lam)*d1 + a*a*d0)
    }
    return(tot / (b*b))
}

// standardised draws: normal, Student t (unit variance), Hansen (1994) skewed t
real matrix cvd_draw(real scalar n, real scalar p, string scalar dist,
                     real scalar df, real scalar lam)
{
    real matrix Q
    if (dist == "t") {
        Q = rnormal(n, p, 0, 1) :/ sqrt(rgamma(n, p, df/2, 2) :/ df)
        return(Q :* sqrt((df - 2) / df))
    }
    if (dist == "skewt") {
        return(cvd_skt_draw(n, p, df, lam))
    }
    return(rnormal(n, p, 0, 1))
}

// correlation matrix of a covariance matrix
real matrix cvd_tocorr(real matrix S)
{
    real colvector d
    d = sqrt(diagonal(S))
    return(S :/ (d * d'))
}

// ===========================================================================
//  Simulation: conditional-volatility recursions (rows: burn+1 discarded)
// ===========================================================================

// typ: garch  par = (omega, a, b)
//      gjr    par = (omega, a, g, b[, kappa]) h = w + a e2 + g 1(e<0) e2 + b h, kappa = E z2 1(z<0)
//      agarch par = (omega, a, g, b)          h = w + a (e - g)^2 + b h
//      egarch par = (omega, a, th, b, cen, sq) ln h = w + a(|z| - cen E|z|) + th z + b ln h
// Lr: Cholesky factor of the constant conditional correlation matrix
void cvd_uvol(string scalar typ, real rowvector par, real matrix Z, real matrix Lr,
              real scalar burn, real matrix E, real matrix H)
{
    real scalar N, p, t, om, a, b, g, th, cen, sq, h0, ez, kap
    real matrix U, EE, HH
    real rowvector h, e, zz, m

    N  = rows(Z)
    p  = cols(Z)
    U  = Z * Lr'
    EE = J(N, p, .)
    HH = J(N, p, .)
    om = par[1]
    ez = sqrt(2/pi())
    a  = 0
    b  = 0
    g  = 0
    th = 0
    cen = 1
    sq  = 0
    h0 = 1
    if (typ == "garch") {
        a = par[2]
        b = par[3]
        if (a + b < 1) {
            h0 = om / (1 - a - b)
        }
    }
    if (typ == "gjr") {
        a = par[2]
        g = par[3]
        b = par[4]
        kap = 0.5
        if (cols(par) >= 5) {
            kap = par[5]
        }
        if (a + g*kap + b < 1) {
            h0 = om / (1 - a - g*kap - b)
        }
    }
    if (typ == "agarch") {
        a = par[2]
        g = par[3]
        b = par[4]
        if (a + b < 1) {
            h0 = (om + a*g*g) / (1 - a - b)
        }
    }
    if (typ == "egarch") {
        a   = par[2]
        th  = par[3]
        b   = par[4]
        cen = par[5]
        sq  = par[6]
        if (abs(b) < 1) {
            if (sq) {
                h0 = exp((om + a*(1 - cen)) / (1 - b))
            }
            else {
                h0 = exp((om + a*ez*(1 - cen)) / (1 - b))
            }
        }
    }
    if (missing(h0)) {
        h0 = 1
    }
    if (h0 <= 0) {
        h0 = 1
    }
    h = J(1, p, h0)
    e = sqrt(h) :* U[1, .]
    EE[1, .] = e
    HH[1, .] = h
    for (t = 2; t <= N; t = t + 1) {
        if (typ == "garch") {
            h = om :+ a :* (e:^2) :+ b :* h
        }
        if (typ == "gjr") {
            h = om :+ a :* (e:^2) :+ g :* (e :< 0) :* (e:^2) :+ b :* h
        }
        if (typ == "agarch") {
            h = om :+ a :* ((e :- g):^2) :+ b :* h
        }
        if (typ == "egarch") {
            zz = U[t-1, .]
            if (sq) {
                m = zz:^2 :- cen
            }
            else {
                m = abs(zz) :- cen*ez
            }
            h = exp(om :+ a :* m :+ th :* zz :+ b :* ln(h))
        }
        e = sqrt(h) :* U[t, .]
        EE[t, .] = e
        HH[t, .] = h
    }
    E = EE[|burn+2,1 \ N,p|]
    H = HH[|burn+2,1 \ N,p|]
}

// AR(1) stochastic volatility: e_t = v_t exp(h_t), h_t = lam h_{t-1} + 0.5 xi_t
void cvd_sv(real scalar lam, real scalar sxi, real matrix Z, real matrix Lr,
            real scalar burn, real matrix E, real matrix H)
{
    real scalar N, p, t
    real matrix U, X, hs
    N  = rows(Z)
    p  = cols(Z)
    U  = Z * Lr'
    X  = rnormal(N, p, 0, sxi)
    hs = J(N, p, 0)
    hs[1, .] = 0.5 :* X[1, .]
    for (t = 2; t <= N; t = t + 1) {
        hs[t, .] = lam :* hs[t-1, .] :+ 0.5 :* X[t, .]
    }
    E = U :* exp(hs)
    H = exp(2 :* hs)
    E = E[|burn+2,1 \ N,p|]
    H = H[|burn+2,1 \ N,p|]
}

// CCC-FIGARCH(1,d,1) truncated at trunc lags; par = (c, d, phi, b)
void cvd_figarch(real rowvector par, real scalar trunc, real matrix Z,
                 real matrix Lr, real scalar burn, real matrix E, real matrix H,
                 real scalar nneg)
{
    real scalar c, d, phi, b, N, p, t, kk
    real colvector pk, lamv, lamr
    real matrix U, e2, EE, HH
    real rowvector h, hprev, e, bad

    c   = par[1]
    d   = par[2]
    phi = par[3]
    b   = par[4]
    pk  = J(trunc+1, 1, .)
    pk[1] = 1
    for (kk = 1; kk <= trunc; kk = kk + 1) {
        pk[kk+1] = pk[kk] * (kk - 1 - d) / kk
    }
    lamv = J(trunc, 1, .)
    for (kk = 1; kk <= trunc; kk = kk + 1) {
        lamv[kk] = -(pk[kk+1] - phi*pk[kk])
    }
    lamv[1] = lamv[1] - b
    lamr = lamv[(trunc::1)]
    N  = rows(Z)
    p  = cols(Z)
    U  = Z * Lr'
    e2 = J(trunc + N, p, 1)
    EE = J(N, p, .)
    HH = J(N, p, .)
    hprev = J(1, p, 1)
    nneg  = 0
    for (t = 1; t <= N; t = t + 1) {
        h   = c :+ b :* hprev :+ lamr' * e2[|t,1 \ trunc+t-1,p|]
        bad = (h :<= 1e-8)
        nneg = nneg + sum(bad)
        h   = h :* (1 :- bad) :+ 1e-8 :* bad
        e   = sqrt(h) :* U[t, .]
        e2[trunc+t, .] = e:^2
        EE[t, .] = e
        HH[t, .] = h
        hprev = h
    }
    E = EE[|burn+2,1 \ N,p|]
    H = HH[|burn+2,1 \ N,p|]
}

// BEKK(1,1): H_t = C + A e_{t-1} e_{t-1}' A' + B H_{t-1} B'
void cvd_bekk(real matrix C, real matrix A, real matrix Bm, real matrix Z,
              real scalar burn, real matrix E, real matrix H, real matrix Hc)
{
    real scalar N, p, t, i, j, c, rho
    real matrix Ht, Lt, EE, HH, HC, M
    real colvector hv
    real rowvector e
    complex rowvector ev

    N  = rows(Z)
    p  = cols(Z)
    ev  = eigenvalues(A#A + Bm#Bm)
    rho = max(abs(ev))
    Ht  = C
    if (rho < 1) {
        M  = I(p*p) - A#A - Bm#Bm
        hv = luinv(M) * vec(C)
        Ht = colshape(hv', p)'
        Ht = (Ht + Ht') / 2
    }
    EE = J(N, p, .)
    HH = J(N, p, .)
    HC = J(N, max((p*(p-1)/2, 1)), .)
    Lt = cholesky(Ht)
    if (hasmissing(Lt)) {
        Lt = cholesky(C)
    }
    e = (Lt * Z[1, .]')'
    for (t = 1; t <= N; t = t + 1) {
        if (t > 1) {
            Ht = C + A * (e' * e) * A' + Bm * Ht * Bm'
            Ht = (Ht + Ht') / 2
            Lt = cholesky(Ht)
            if (hasmissing(Lt)) {
                errprintf("BEKK recursion produced a non-positive-definite H_t\n")
                exit(error(506))
            }
            e = (Lt * Z[t, .]')'
        }
        EE[t, .] = e
        HH[t, .] = diagonal(Ht)'
        c = 0
        for (i = 1; i <= p; i = i + 1) {
            for (j = i+1; j <= p; j = j + 1) {
                c = c + 1
                HC[t, c] = Ht[i, j]
            }
        }
    }
    E  = EE[|burn+2,1 \ N,p|]
    H  = HH[|burn+2,1 \ N,p|]
    Hc = HC[|burn+2,1 \ N,cols(HC)|]
}

// ===========================================================================
//  Simulation: deterministic / exogenous volatility paths
// ===========================================================================

// bs rows: (series, tau, variance ratio); variance = base before, base*ratio after floor(tau n)
real matrix cvd_breakpath(real scalar n, real scalar p, real matrix bs, real scalar base)
{
    real scalar j, s, tb
    real matrix V
    V = J(n, p, base)
    if (rows(bs) > 1) {
        bs = sort(bs, 2)
    }
    for (j = 1; j <= rows(bs); j = j + 1) {
        s  = bs[j, 1]
        tb = floor(bs[j, 2] * n)
        if (s >= 1) {
            if (s <= p) {
                if (tb < n) {
                    V[|tb+1,s \ n,s|] = J(n - tb, 1, base * bs[j, 3])
                }
            }
        }
    }
    return(V)
}

// Euler OU: H_t = (1 - kappa/n) H_{t-1} + zeta n^-1/2 eta_t, H_0 = 0; returns exp(2H)
real colvector cvd_oupath(real colvector eta, real scalar kap, real scalar zet)
{
    real scalar n, t, prev
    real colvector Hh
    n    = rows(eta)
    Hh   = J(n, 1, 0)
    prev = 0
    for (t = 1; t <= n; t = t + 1) {
        prev  = (1 - kap/n)*prev + zet*sqrt(1/n)*eta[t]
        Hh[t] = prev
    }
    return(exp(2 :* Hh))
}

// vcase 2: Sigma_t = D_t S D_t, D_t = diag(sqrt(v_t)); vcase 3: Sigma_t = diag(v_t - 1) + S
real matrix cvd_applyvol(real matrix Z, real matrix V, real matrix S,
                         real scalar vcase, real matrix H)
{
    real scalar n, p, t
    real matrix E, Ls, Lt
    n = rows(Z)
    p = cols(Z)
    if (vcase == 3) {
        E = J(n, p, .)
        for (t = 1; t <= n; t = t + 1) {
            Lt = cholesky(diag(V[t, .] :- 1) + S)
            if (hasmissing(Lt)) {
                errprintf("vcase(3): diag(v_t - 1) + Sigma is not positive definite at t = %g\n", t)
                exit(error(506))
            }
            E[t, .] = Z[t, .] * Lt'
        }
        H = (V :- 1) :+ diagonal(S)'
        return(E)
    }
    Ls = cholesky(S)
    E  = sqrt(V) :* (Z * Ls')
    H  = V :* diagonal(S)'
    return(E)
}

// ===========================================================================
//  Simulation: levels
// ===========================================================================

// dX_t = al (be' X_{t-1} + rc') + sum_j Ga_j dX_{t-j} + mu + e_t, X_0 = 0, dX_{<=0} = 0
real matrix cvd_vecmlev(real matrix E, real matrix al, real matrix be,
                        real matrix Ga, real matrix rc, real matrix mu)
{
    real scalar n, p, kk, t, j
    real matrix X, DX
    real rowvector d
    n  = rows(E)
    p  = cols(E)
    kk = cols(Ga) / p
    X  = J(n+1, p, 0)
    DX = J(n+1, p, 0)
    for (t = 2; t <= n+1; t = t + 1) {
        d = X[t-1, .] * be * al'
        if (cols(rc) > 0) {
            d = d + rc * al'
        }
        for (j = 1; j <= kk; j = j + 1) {
            if (t - j >= 1) {
                d = d + DX[t-j, .] * Ga[|1,(j-1)*p+1 \ p,j*p|]'
            }
        }
        if (cols(mu) > 0) {
            d = d + mu
        }
        d = d + E[t-1, .]
        DX[t, .] = d
        X[t, .]  = X[t-1, .] + d
    }
    return(X[|2,1 \ n+1,p|])
}

real colvector cvd_ar1(real colvector e, real scalar phi)
{
    real scalar t
    real colvector x
    x = e
    for (t = 2; t <= rows(e); t = t + 1) {
        x[t] = phi*x[t-1] + e[t]
    }
    return(x)
}

// Harris, McCabe & Leybourne (2002) s.4: par = (phi, piy, pix, rho34, vsd)
void cvd_hml(real scalar n, real scalar burn, real rowvector par, real matrix Y,
             real colvector w)
{
    real scalar N, r34
    real colvector e4, e1, e2, e3, ey, ex, vx, y, x
    real matrix u
    N   = n + burn
    r34 = par[4]
    e4  = rnormal(N, 1, 0, 1)
    u   = rnormal(N, 3, 0, 1)
    e1  = 0.5 :* e4 :+ sqrt(0.75) :* u[., 1]
    e2  = 0.5 :* e4 :+ sqrt(0.75) :* u[., 2]
    e3  = r34 :* e4 :+ sqrt(1 - r34*r34) :* u[., 3]
    ey  = cvd_ar1(e1, par[1])
    ex  = cvd_ar1(e2, par[1])
    vx  = cvd_ar1(par[5] :* e3, par[1])
    w   = runningsum(e4)
    y   = par[2] :* w :+ ey
    x   = par[3] :* w :+ vx :* w :+ ex
    Y   = (y, x)
    Y   = Y[|burn+1,1 \ N,2|]
    w   = w[|burn+1 \ N|]
}

// McCabe, Leybourne & Harris (2006) eq (10): par = (d1, d2, d3, fey, fex, fvy, fvx)
void cvd_mlh(real scalar n, real scalar burn, real rowvector par, real matrix Y,
             real colvector w)
{
    real scalar N
    real matrix ep
    real colvector ey, ex, nuy, nux, w2, h1, h2, y, x
    N   = n + burn
    ep  = rnormal(N, 8, 0, 1)
    ey  = cvd_ar1(ep[., 1], par[4])
    ex  = cvd_ar1(ep[., 2], par[5])
    nuy = cvd_ar1(par[2] :* ep[., 3], par[6])
    nux = cvd_ar1(par[3] :* ep[., 4], par[7])
    w   = runningsum(ep[., 5])
    w2  = runningsum(ep[., 6])
    h1  = runningsum(ep[., 7])
    h2  = runningsum(ep[., 8])
    y   = w :+ ey :+ nuy :* h1
    x   = w :+ par[1] :* w2 :+ ex :+ nux :* h2
    Y   = (y, x)
    Y   = Y[|burn+1,1 \ N,2|]
    w   = w[|burn+1 \ N|]
}

// Hansen (1992) eqs (1)-(4): par = (b0, b1, sigma0, s2, r12, r13, r23)
void cvd_hci(real scalar n, real scalar nx, real rowvector par, real matrix Y,
             real colvector wv, real colvector hv)
{
    real scalar m, j
    real matrix Om, L, U, X
    real colvector sg
    m  = 2 + nx
    Om = I(m)
    Om[2, 2] = par[4]*par[4]
    Om[1, 2] = par[5]*par[4]
    Om[2, 1] = Om[1, 2]
    for (j = 1; j <= nx; j = j + 1) {
        Om[1, 2+j] = par[6]
        Om[2+j, 1] = par[6]
        Om[2, 2+j] = par[7]*par[4]
        Om[2+j, 2] = Om[2, 2+j]
    }
    L = cholesky(Om)
    if (hasmissing(L)) {
        errprintf("hci: the implied covariance of (u1, u2, u3) is not positive definite\n")
        exit(error(506))
    }
    U = rnormal(n, m, 0, 1) * L'
    X = J(n, nx, .)
    for (j = 1; j <= nx; j = j + 1) {
        X[., j] = runningsum(U[., 2+j])
    }
    sg = par[3] :+ runningsum(U[., 2])
    wv = sg :* U[., 1]
    hv = sg:^2
    Y  = (par[1] :+ par[2] :* rowsum(X) :+ wv), X
}

// ===========================================================================
//  Main entry point for -cointvol simulate- (reads the caller's locals)
// ===========================================================================

void cvd_innov(string scalar it, real scalar n, real scalar p, real scalar burn,
               real matrix S, real matrix E, real matrix H, real matrix Hc,
               real scalar nneg)
{
    string scalar dist
    real scalar df, lam, vcase, kap
    real matrix Z, Lr, V, bs, Cm, Am, Bm
    real colvector v, eta
    real rowvector par
    pointer() scalar pe

    dist = st_local("distribution")
    df   = strtoreal(st_local("df"))
    lam  = strtoreal(st_local("skew"))
    nneg = 0
    Hc   = J(0, 0, .)
    if (it == "iid") {
        Z = cvd_draw(n, p, dist, df, lam)
        E = Z * cholesky(S)'
        H = J(n, 1, diagonal(S)')
        return
    }
    if (it == "garch" | it == "ccc" | it == "gjr" | it == "agarch" | it == "egarch") {
        Z  = cvd_draw(n + burn + 1, p, dist, df, lam)
        Lr = cholesky(cvd_tocorr(S))
        if (it == "garch" | it == "ccc") {
            par = (strtoreal(st_local("P_omega")), strtoreal(st_local("P_arch")),
                   strtoreal(st_local("P_garch")))
            cvd_uvol("garch", par, Z, Lr, burn, E, H)
        }
        if (it == "gjr") {
            // kappa = E[z^2 1(z<0)]: 1/2 for symmetric shocks, closed form for skewed t
            kap = 0.5
            if (dist == "skewt") {
                kap = cvd_skt_kappa(df, lam)
            }
            par = (strtoreal(st_local("P_omega")), strtoreal(st_local("P_arch")),
                   strtoreal(st_local("P_asym")), strtoreal(st_local("P_garch")), kap)
            cvd_uvol("gjr", par, Z, Lr, burn, E, H)
        }
        if (it == "agarch") {
            par = (strtoreal(st_local("P_omega")), strtoreal(st_local("P_arch")),
                   strtoreal(st_local("P_shift")), strtoreal(st_local("P_garch")))
            cvd_uvol("agarch", par, Z, Lr, burn, E, H)
        }
        if (it == "egarch") {
            par = (strtoreal(st_local("P_omega")), strtoreal(st_local("P_arch")),
                   strtoreal(st_local("P_theta")), strtoreal(st_local("P_garch")),
                   strtoreal(st_local("P_center")), strtoreal(st_local("P_sq")))
            cvd_uvol("egarch", par, Z, Lr, burn, E, H)
        }
        return
    }
    if (it == "sv") {
        Z  = cvd_draw(n + burn + 1, p, dist, df, lam)
        Lr = cholesky(cvd_tocorr(S))
        cvd_sv(strtoreal(st_local("P_lambda")), strtoreal(st_local("P_sigxi")),
               Z, Lr, burn, E, H)
        return
    }
    if (it == "figarch") {
        Z   = cvd_draw(n + burn + 1, p, dist, df, lam)
        Lr  = cholesky(cvd_tocorr(S))
        par = (strtoreal(st_local("P_fconst")), strtoreal(st_local("P_fracd")),
               strtoreal(st_local("P_fphi")), strtoreal(st_local("P_garch")))
        cvd_figarch(par, strtoreal(st_local("P_trunc")), Z, Lr, burn, E, H, nneg)
        return
    }
    if (it == "bekk") {
        Cm = st_matrix(st_local("P_C"))
        Am = st_matrix(st_local("P_A"))
        Bm = st_matrix(st_local("P_B"))
        Z  = cvd_draw(n + burn + 1, p, dist, df, lam)
        cvd_bekk(Cm, Am, Bm, Z, burn, E, H, Hc)
        return
    }
    vcase = strtoreal(st_local("P_vcase"))
    if (it == "break") {
        bs = st_matrix(st_local("P_bspec"))
        V  = cvd_breakpath(n, p, bs, strtoreal(st_local("P_base")))
        Z  = cvd_draw(n, p, dist, df, lam)
        E  = cvd_applyvol(Z, V, S, vcase, H)
        return
    }
    if (it == "oupath") {
        if (st_local("P_oufix") == "1") {
            pe  = findexternal("__cvd_oueta")
            eta = *pe
        }
        else {
            eta = rnormal(n, 1, 0, 1)
        }
        v = cvd_oupath(eta, strtoreal(st_local("P_kappa")), strtoreal(st_local("P_zeta")))
        V = v * J(1, p, 1)
        Z = cvd_draw(n, p, dist, df, lam)
        E = cvd_applyvol(Z, V, S, vcase, H)
        return
    }
    errprintf("unknown innovation model %s\n", it)
    exit(error(198))
}

void cvd_sim_main()
{
    string scalar dgp, it, pre, epre, hpre
    real scalar n, p, burn, pres, ntot, nneg, i, nx
    real matrix S, E, H, Hc, Y, al, be, Ga, rc, mu, Pm
    real colvector w, wv, hv, mods
    real rowvector par, idx
    string rowvector nms

    dgp  = st_local("dgp")
    n    = strtoreal(st_local("nobs"))
    p    = strtoreal(st_local("nvars"))
    burn = strtoreal(st_local("burnin"))
    pres = strtoreal(st_local("presample"))
    pre  = st_local("prefix")
    epre = st_local("eprefix")
    hpre = st_local("hprefix")
    nneg = 0
    Hc   = J(0, 0, .)

    if (dgp == "stochcoint") {
        if (st_local("type") == "mlh") {
            par = (strtoreal(st_local("d1")), strtoreal(st_local("d2")),
                   strtoreal(st_local("d3")), strtoreal(st_local("phiey")),
                   strtoreal(st_local("phiex")), strtoreal(st_local("phivy")),
                   strtoreal(st_local("phivx")))
            cvd_mlh(n, burn, par, Y, w)
        }
        else {
            par = (strtoreal(st_local("phi")), strtoreal(st_local("piy")),
                   strtoreal(st_local("pix")), strtoreal(st_local("rho34")),
                   strtoreal(st_local("vsd")))
            cvd_hml(n, burn, par, Y, w)
        }
        idx = st_addvar("double", (pre + "1", pre + "2", pre + "_w"))
        st_store(., idx, (Y, w))
        return
    }
    if (dgp == "hci") {
        nx  = p - 1
        par = (strtoreal(st_local("b0")), strtoreal(st_local("b1")),
               strtoreal(st_local("sigma0")), strtoreal(st_local("s2")),
               strtoreal(st_local("r12")), strtoreal(st_local("r13")),
               strtoreal(st_local("r23")))
        cvd_hci(n, nx, par, Y, wv, hv)
        nms = J(1, p, "")
        for (i = 1; i <= p; i = i + 1) {
            nms[i] = pre + strofreal(i)
        }
        idx = st_addvar("double", nms)
        st_store(., idx, Y)
        idx = st_addvar("double", (epre + "1", hpre + "1"))
        st_store(., idx, (wv, hv))
        return
    }

    S    = st_matrix(st_local("Smat"))
    it   = st_local("innov")
    ntot = n + pres
    cvd_innov(it, ntot, p, burn, S, E, H, Hc, nneg)
    if (dgp == "vecm") {
        al = st_matrix(st_local("P_al"))
        be = st_matrix(st_local("P_be"))
        Ga = J(p, 0, .)
        rc = J(1, 0, .)
        mu = J(1, 0, .)
        if (st_local("P_ga") != "") {
            Ga = st_matrix(st_local("P_ga"))
        }
        if (st_local("P_rc") != "") {
            rc = st_matrix(st_local("P_rc"))
        }
        if (st_local("P_mu") != "") {
            mu = st_matrix(st_local("P_mu"))
        }
        Y = cvd_vecmlev(E, al, be, Ga, rc, mu)
        Pm = al * be'
        if (cols(Ga) > 0) {
            mods = cv_roots(Pm, Ga, cols(Ga)/p + 1)
        }
        else {
            mods = cv_roots(Pm, J(p, 0, .), 1)
        }
        st_matrix("__cvd_simroots", mods)
    }
    else {
        Y = J(ntot, p, .)
        for (i = 1; i <= p; i = i + 1) {
            Y[., i] = runningsum(E[., i])
        }
    }
    if (pres > 0) {
        Y = Y[|pres+1,1 \ ntot,p|]
        E = E[|pres+1,1 \ ntot,p|]
        H = H[|pres+1,1 \ ntot,p|]
        if (rows(Hc) > 0) {
            Hc = Hc[|pres+1,1 \ ntot,cols(Hc)|]
        }
    }
    nms = J(1, p, "")
    for (i = 1; i <= p; i = i + 1) {
        nms[i] = pre + strofreal(i)
    }
    idx = st_addvar("double", nms)
    st_store(., idx, Y)
    for (i = 1; i <= p; i = i + 1) {
        nms[i] = epre + strofreal(i)
    }
    idx = st_addvar("double", nms)
    st_store(., idx, E)
    for (i = 1; i <= p; i = i + 1) {
        nms[i] = hpre + strofreal(i)
    }
    idx = st_addvar("double", nms)
    st_store(., idx, H)
    if (it == "bekk") {
        if (p == 2) {
            idx = st_addvar("double", hpre + "12")
            st_store(., idx, Hc[., 1])
        }
    }
    st_numscalar("__cvd_nneg", nneg)
}

end
