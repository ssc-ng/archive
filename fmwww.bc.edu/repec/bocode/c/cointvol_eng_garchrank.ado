*! cointvol_eng_garchrank 0.1.0  26sep2026
*! Mata engine of -cointvol garchrank-: cointegration-rank tests with CCC-GARCH errors
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com) - github.com/merwanroudane
*!
*! Step -> source map (SML = Sin, Mi & Ling 2024, CMR 40(1); SIN = Sin c.2004 WP)
*!   CCC-GARCH(p,q) recursion h_{i,t-1}, V_{t-1} = D Gamma D           SML (2.3); SIN (1.3)-(1.4)
*!   per-equation Gaussian QMLE, Gamma = corr(standardised resid)      SML Sec 3 (initial est.)
*!   full-rank LS, one-step FR QMLE with expected Hessian F_t          SML (3.2), (3.4)
*!   derivative recursion grad_phi h (a(z)/b(z) expansion)             SML (B.1), (B.3)
*!   Johansen RRR initial reduced-rank estimator                       SML Sec 4.1
*!   one-step RR QMLE for alpha_1 = vec(B), alpha_2 = vec(A,Phi*)      SML (4.5)-(4.8)
*!   LR_G = (phi_dot - phi_ddot)'(-sum F_t)(phi_dot - phi_ddot)         SML (5.4)
*!   H_G with F^H_t = -(XX' # A_p(A_p'O1^-1 O1* O1^-1 A_p)^-1 A_p')     SML (5.5)-(5.6)
*!   EV, A_perp, xi_t recursion, Omega_1, Omega*_1, Delta, lambda      SML Sec 6; Thm 5.1, 5.2
*!   limit tr{[zeta(I-L)^.5 + Phi L^.5]'[.]}, zeta / demeaned zeta     SML (6.1)-(6.4)
*!   critical values                                                   SML Tables 1-3; SIN A.1-A.2
*!   one-step FR WLS (= FGLS), RR WLS, W_G, W*_G, lambda, lambda*      SIN (3.3)-(3.4), (4.5)-(4.10),
*!                                                                     (5.2)-(5.5), Cor 5.1
*!
*! Running this file compiles the functions below.  It first makes sure the core
*! engine (struct cv_joh, cv_johansen(), cv_fitrank(), ...) is in memory.

program define cointvol_eng_garchrank
    version 14.0
end

version 14.0
capture mata: st_local("__cvkcore", cv_engine_version())
if _rc {
    capture program drop cointvol_engine
    quietly findfile cointvol_engine.ado
    quietly run `"`r(fn)'"'
}
capture mata: mata drop cvk_*()

mata:

string scalar cvk_version()
{
    return("0.1.0")
}

// ---------------------------------------------------------------------------
//  Small utilities
// ---------------------------------------------------------------------------

real scalar cvk_invlogit(real scalar x)
{
    return(1 / (1 + exp(-x)))
}

// symmetric matrix power S^pw via the spectral decomposition
real matrix cvk_sympow(real matrix S, real scalar pw)
{
    real matrix V
    real rowvector L
    real scalar fl
    symeigensystem((S + S') / 2, V, L)
    fl = max(abs(L)) * 1e-14
    if (fl <= 0) {
        fl = 1e-300
    }
    L = L :* (L :> fl) + fl :* (L :<= fl)
    return((V :* (L :^ pw)) * V')
}

// solve S x = b for a symmetric positive definite S
real colvector cvk_solve(real matrix S, real colvector b)
{
    real colvector x
    real matrix Si
    x = cholsolve((S + S') / 2, b)
    if (hasmissing(x)) {
        Si = invsym((S + S') / 2)
        if (diag0cnt(Si) > 0) {
            errprintf("information matrix is singular in the one-step update\n")
            exit(error(506))
        }
        x = Si * b
    }
    return(x)
}

real matrix cvk_corr(real matrix Z)
{
    real matrix S
    real colvector d
    S = cross(Z, Z) / rows(Z)
    d = sqrt(diagonal(S))
    S = S :/ (d * d')
    return((S + S') / 2)
}

// ---------------------------------------------------------------------------
//  CCC-GARCH(p,q):  h_it = a_i0 + sum_{l=1}^q a_il e_{i,t-l}^2 + sum_{l=1}^p b_il h_{i,t-l}
//  (row t of H = conditional variance of e_t, i.e. h_{i,t-1} in SML (2.3)).
//  P is m x (1+q+p): (a0, a1..aq, b1..bp).  Pre-sample e^2 and h are set to
//  the sample mean of e^2 (they do not depend on the mean parameters).
// ---------------------------------------------------------------------------

real matrix cvk_hrec(real matrix E, real matrix P, real scalar q, real scalar p)
{
    real scalar n, m, t, l
    real matrix H, E2
    real rowvector s2, h
    n  = rows(E)
    m  = cols(E)
    E2 = E :* E
    s2 = mean(E2)
    H  = J(n, m, .)
    for (t = 1; t <= n; t = t + 1) {
        h = P[., 1]'
        for (l = 1; l <= q; l = l + 1) {
            if (t - l >= 1) {
                h = h + P[., 1+l]' :* E2[t-l, .]
            }
            else {
                h = h + P[., 1+l]' :* s2
            }
        }
        for (l = 1; l <= p; l = l + 1) {
            if (t - l >= 1) {
                h = h + P[., 1+q+l]' :* H[t-l, .]
            }
            else {
                h = h + P[., 1+q+l]' :* s2
            }
        }
        h = h :* (h :> 1e-12) + 1e-12 :* (h :<= 1e-12)
        H[t, .] = h
    }
    return(H)
}

// xi_t = sum_{l>=1} diag(nu_l .* e_{t-l}) computed recursively (SML Sec 6):
//   xi_t = sum_{l=1}^q diag(a_l .* e_{t-l}) + sum_{l=1}^p xi_{t-l} diag(b_l), xi_0 = ... = 0
// returned as an n x m matrix of the diagonals
real matrix cvk_xirec(real matrix E, real matrix P, real scalar q, real scalar p)
{
    real scalar n, m, t, l
    real matrix XI
    real rowvector x
    n  = rows(E)
    m  = cols(E)
    XI = J(n, m, 0)
    for (t = 1; t <= n; t = t + 1) {
        x = J(1, m, 0)
        for (l = 1; l <= q; l = l + 1) {
            if (t - l >= 1) {
                x = x + P[., 1+l]' :* E[t-l, .]
            }
        }
        for (l = 1; l <= p; l = l + 1) {
            if (t - l >= 1) {
                x = x + P[., 1+q+l]' :* XI[t-l, .]
            }
        }
        XI[t, .] = x
    }
    return(XI)
}

// parameter map theta -> (a0, a_1..a_q, b_1..b_p):
//   persistence  = 0.999 * invlogit(theta_2)
//   shares       = softmax(theta_3, ..., theta_{q+p+1}, 0)
//   a0           = s2 * (1 - persistence) * exp(theta_1)
real rowvector cvk_th2par(real rowvector th, real scalar q, real scalar p, real scalar s2)
{
    real scalar k, pers, j
    real rowvector sh, par
    k    = q + p
    pers = 0.999 * cvk_invlogit(th[2])
    sh   = J(1, k, 0)
    for (j = 1; j <= k - 1; j = j + 1) {
        sh[j] = th[2 + j]
    }
    sh  = exp(sh :- max(sh))
    sh  = sh :/ sum(sh)
    par = J(1, 1 + k, .)
    par[1] = s2 * (1 - pers) * exp(th[1])
    for (j = 1; j <= k; j = j + 1) {
        par[1 + j] = pers * sh[j]
    }
    return(par)
}

void cvk_garch_ev(real scalar todo, real rowvector th, real colvector e,
                  real scalar q, real scalar p, real scalar s2,
                  real scalar v, real rowvector g, real matrix Hs)
{
    real rowvector par
    real colvector h
    par = cvk_th2par(th, q, p, s2)
    h   = cvk_hrec(e, par, q, p)
    v   = -0.5 * sum(ln(h) + (e :* e) :/ h)
}

real scalar cvk_garchopt(real colvector e, real scalar q, real scalar p,
                         real scalar s2, real rowvector th0, string scalar tech,
                         real rowvector th, real scalar v)
{
    transmorphic S
    real scalar rc
    S = optimize_init()
    optimize_init_evaluator(S, &cvk_garch_ev())
    optimize_init_evaluatortype(S, "d0")
    optimize_init_which(S, "max")
    optimize_init_params(S, th0)
    optimize_init_argument(S, 1, e)
    optimize_init_argument(S, 2, q)
    optimize_init_argument(S, 3, p)
    optimize_init_argument(S, 4, s2)
    optimize_init_technique(S, tech)
    optimize_init_singularHmethod(S, "hybrid")
    optimize_init_tracelevel(S, "none")
    optimize_init_conv_warning(S, "off")
    optimize_init_conv_maxiter(S, 300)
    rc = _optimize(S)
    th = th0
    v  = .
    if (rc == 0) {
        th = optimize_result_params(S)
        v  = optimize_result_value(S)
        if (optimize_result_converged(S) == 0) {
            rc = 430
        }
    }
    return(rc)
}

// univariate Gaussian QMLE of a GARCH(p,q); conv = 0 if both optimisers failed
real rowvector cvk_garch1(real colvector e, real scalar q, real scalar p, real scalar conv)
{
    real scalar s2, k, j, pers, atot, btot, rc1, rc2, v1, v2, v0
    real rowvector par0, th0, th1, th2, w, best
    real colvector h0
    k  = q + p
    s2 = mean(e :* e)
    atot = 0.5
    btot = 0
    if (p > 0) {
        atot = 0.1
        btot = 0.8
    }
    par0 = J(1, 1 + k, 0)
    for (j = 1; j <= q; j = j + 1) {
        par0[1 + j] = atot / q
    }
    for (j = 1; j <= p; j = j + 1) {
        par0[1 + q + j] = btot / p
    }
    pers = atot + btot
    par0[1] = s2 * (1 - pers)
    th0 = J(1, 1 + k, 0)
    th0[2] = ln(pers / 0.999) - ln(1 - pers / 0.999)
    w = J(1, k, 0)
    for (j = 1; j <= k; j = j + 1) {
        w[j] = par0[1 + j] / pers
    }
    for (j = 1; j <= k - 1; j = j + 1) {
        th0[2 + j] = ln(w[j] / w[k])
    }
    conv = 1
    rc1 = cvk_garchopt(e, q, p, s2, th0, "nr", th1, v1)
    if (rc1 == 0) {
        return(cvk_th2par(th1, q, p, s2))
    }
    rc2 = cvk_garchopt(e, q, p, s2, th0, "bfgs", th2, v2)
    if (rc2 == 0) {
        return(cvk_th2par(th2, q, p, s2))
    }
    // neither converged: keep the best available point
    conv = 0
    h0 = cvk_hrec(e, cvk_th2par(th0, q, p, s2), q, p)
    v0 = -0.5 * sum(ln(h0) + (e :* e) :/ h0)
    best = th0
    if (v1 < .) {
        if (v1 > v0) {
            best = th1
            v0 = v1
        }
    }
    if (v2 < .) {
        if (v2 > v0) {
            best = th2
        }
    }
    return(cvk_th2par(best, q, p, s2))
}

// CCC-GARCH fitted to the residual matrix E: equation-by-equation QMLE,
// Gamma = correlation matrix of the standardised residuals (Bollerslev 1990)
void cvk_garchfit(real matrix E, real scalar q, real scalar p, real matrix P,
                  real matrix Gam, real matrix H, real scalar nf)
{
    real scalar m, j, cv
    m = cols(E)
    P = J(m, 1 + q + p, .)
    for (j = 1; j <= m; j = j + 1) {
        cv = 1
        P[j, .] = cvk_garch1(E[., j], q, p, cv)
        if (cv == 0) {
            nf = nf + 1
        }
    }
    H   = cvk_hrec(E, P, q, p)
    Gam = cvk_corr(E :/ sqrt(H))
}

// ---------------------------------------------------------------------------
//  Generic one-step score / expected Hessian (SML (3.2)-(3.6), (4.5)-(4.8);
//  SIN (3.3)-(3.4), (4.5)-(4.6)).
//  The residual depends on the parameter theta through e_t = ... - Z_t' theta,
//    mode 1: Z_t = x_t # I_m      (theta = vec(Pi),   x_t = row t of Xr)
//    mode 2: Z_t = y_t # A'       (theta = vec(B),    y_t = row t of Xr)
//  full = 1: QMLE score and F_t including the GARCH channel via grad h
//            grad h_t = -2 sum_l Z_{t-l} diag(a_l .* e_{t-l}) + sum_l grad h_{t-l} diag(b_l)
//  full = 0: WLS score (Z_t V_t^-1 e_t) and F_t = -Z_t V_t^-1 Z_t'
//  Hfix: if non-empty the conditional variances are held fixed at Hfix.
//  Returns ssum = sum score (k x 1) and Fsum = sum F_t (k x k, negative definite).
// ---------------------------------------------------------------------------

real matrix cvk_Z(real rowvector x, real matrix Am, real scalar mode, real scalar m)
{
    if (mode == 2) {
        return(x' # Am')
    }
    return(x' # I(m))
}

void cvk_step(real matrix E, real matrix Xr, real matrix Am, real scalar mode,
              real matrix P, real matrix Gam, real scalar q, real scalar p,
              real scalar full, real matrix Hfix, real colvector ssum,
              real matrix Fsum)
{
    real scalar n, m, k, t, l
    real matrix H, Gi, Mw, Vi, Z, Zl, Gt, Gh, GD
    real colvector e, Ve, w, hinv, d, al
    n = rows(E)
    m = cols(E)
    k = cols(Xr) * m
    if (mode == 2) {
        k = cols(Xr) * cols(Am)
    }
    H = Hfix
    if (rows(Hfix) == 0) {
        H = cvk_hrec(E, P, q, p)
    }
    Gi   = invsym(Gam)
    Mw   = Gi :* Gam + I(m)
    ssum = J(k, 1, 0)
    Fsum = J(k, k, 0)
    Gh   = J(k, max((m * p, 1)), 0)
    for (t = 1; t <= n; t = t + 1) {
        d    = sqrt(H[t, .])'
        Vi   = Gi :/ (d * d')
        e    = E[t, .]'
        Ve   = Vi * e
        Z    = cvk_Z(Xr[t, .], Am, mode, m)
        ssum = ssum + Z * Ve
        Fsum = Fsum - Z * Vi * Z'
        if (full) {
            Gt = J(k, m, 0)
            for (l = 1; l <= q; l = l + 1) {
                if (t - l >= 1) {
                    Zl = cvk_Z(Xr[t-l, .], Am, mode, m)
                    al = P[., 1+l] :* E[t-l, .]'
                    Gt = Gt - 2 :* (Zl :* al')
                }
            }
            for (l = 1; l <= p; l = l + 1) {
                Gt = Gt + Gh[|1, (l-1)*m+1 \ k, l*m|] :* P[., 1+q+l]'
            }
            if (p > 1) {
                Gh = Gt, Gh[|1, 1 \ k, m*(p-1)|]
            }
            if (p == 1) {
                Gh = Gt
            }
            w    = e :* Ve
            hinv = 1 :/ H[t, .]'
            ssum = ssum - 0.5 :* (Gt * ((1 :- w) :* hinv))
            GD   = Gt :* hinv'
            Fsum = Fsum - 0.25 :* (GD * Mw * GD')
        }
    }
    Fsum = (Fsum + Fsum') / 2
}

// ---------------------------------------------------------------------------
//  Nuisance quantities (SML Sec 6), evaluated at the full-rank one-step
//  residuals E with conditional variances H and CCC-GARCH parameters (P, Gam):
//    EV    = n^-1 sum V_{t-1}
//    Om1   = n^-1 sum V^-1 + n^-1 sum xi D^-2 (Gam^-1 .* Gam + I) D^-2 xi
//    Om1s  = n^-1 sum V^-1 + n^-1 sum xi D^-2 (Delta - ii') D^-2 xi
//    Delta = n^-1 sum w(eta eta' Gam^-1) w(eta eta' Gam^-1)'
// ---------------------------------------------------------------------------

void cvk_nuis(real matrix E, real matrix H, real matrix P, real matrix Gam,
              real scalar q, real scalar p, real matrix EV, real matrix Om1,
              real matrix Om1s, real matrix Dl)
{
    real scalar n, m, t
    real matrix Gi, Mw, XI, Vim, O1b, O1sb, ETA, xx
    real colvector d, et, w
    real rowvector x
    n  = rows(E)
    m  = cols(E)
    Gi = invsym(Gam)
    Mw = Gi :* Gam + I(m)
    XI = cvk_xirec(E, P, q, p)
    ETA = E :/ sqrt(H)
    EV  = J(m, m, 0)
    Vim = J(m, m, 0)
    Dl  = J(m, m, 0)
    for (t = 1; t <= n; t = t + 1) {
        d   = sqrt(H[t, .])'
        EV  = EV + Gam :* (d * d')
        Vim = Vim + Gi :/ (d * d')
        et  = ETA[t, .]'
        w   = et :* (Gi * et)
        Dl  = Dl + w * w'
    }
    Dl   = Dl / n
    O1b  = J(m, m, 0)
    O1sb = J(m, m, 0)
    for (t = 1; t <= n; t = t + 1) {
        x    = XI[t, .] :/ H[t, .]
        xx   = x' * x
        O1b  = O1b + xx :* Mw
        O1sb = O1sb + xx :* (Dl :- 1)
    }
    EV   = EV / n
    Om1  = (Vim + O1b) / n
    Om1s = (Vim + O1sb) / n
    EV   = (EV + EV') / 2
    Om1  = (Om1 + Om1') / 2
    Om1s = (Om1s + Om1s') / 2
}

real matrix cvk_meanVi(real matrix H, real matrix Gam)
{
    real scalar n, t
    real matrix Gi, S
    real colvector d
    n  = rows(H)
    Gi = invsym(Gam)
    S  = J(cols(H), cols(H), 0)
    for (t = 1; t <= n; t = t + 1) {
        d = sqrt(H[t, .])'
        S = S + Gi :/ (d * d')
    }
    S = S / n
    return((S + S') / 2)
}

// WLS robust pieces (SIN (5.4), Cor 5.1) at residuals E, fixed weights H:
//   Sst = sum y y' # V^-1 e e' V^-1   (= -sum F*_t, Y block)
//   Os1 = n^-1 sum V^-1 e e' V^-1     (Omega*_1),   Vs = n^-1 sum e e' (V_*)
void cvk_wlsstar(real matrix Y1, real matrix E, real matrix H, real matrix Gam,
                 real matrix Sst, real matrix Os1, real matrix Vs)
{
    real scalar n, m, t
    real matrix Gi, uu
    real colvector d, u
    n   = rows(E)
    m   = cols(E)
    Gi  = invsym(Gam)
    Sst = J(cols(Y1) * m, cols(Y1) * m, 0)
    Os1 = J(m, m, 0)
    for (t = 1; t <= n; t = t + 1) {
        d   = sqrt(H[t, .])'
        u   = (Gi :/ (d * d')) * E[t, .]'
        uu  = u * u'
        Sst = Sst + (Y1[t, .]' * Y1[t, .]) # uu
        Os1 = Os1 + uu
    }
    Sst = (Sst + Sst') / 2
    Os1 = Os1 / n
    Os1 = (Os1 + Os1') / 2
    Vs  = cross(E, E) / n
}

// A_perp estimate (SML Sec 6; Johansen 1995 p.48):
//   (I_m - c c'A (A'c c'A)^-1 A') c_perp,  c = (I_r, 0)', c_perp = (0, I_d)'
// falls back to the orthonormal complement of A when c'A is singular
// (the eigenvalues lambda are invariant to the choice of basis of sp(A_perp))
real matrix cvk_aperp(real matrix A, real scalar m, real scalar r)
{
    real matrix c, cp, M, Mi, Ap, U, Vt
    real colvector sv
    real scalar bad
    if (r == 0) {
        return(I(m))
    }
    c   = I(r) \ J(m - r, r, 0)
    cp  = J(r, m - r, 0) \ I(m - r)
    M   = A' * c * c' * A
    Mi  = invsym(M)
    bad = (diag0cnt(Mi) > 0)
    Ap  = J(m, m - r, .)
    if (bad == 0) {
        Ap = (I(m) - c * c' * A * Mi * A') * cp
        if (hasmissing(Ap)) {
            bad = 1
        }
    }
    if (bad == 0) {
        if (rank(Ap) < m - r) {
            bad = 1
        }
    }
    if (bad) {
        fullsvd(A, U, sv, Vt)
        Ap = U[|1, r+1 \ m, m|]
    }
    return(Ap)
}

// nuisance eigenvalues, ascending
//   Os empty : eig{ I_d - (A'Om^-1 A)^.5 (A'EV A)^-1 (A'Om^-1 A)^.5 }       SML Thm 5.2; SIN Thm 5.1
//   Os given : eig{ I_d - T^-.5 (A'Om^-1 A)(A'EV A)^-1(A'Om^-1 A) T^-.5 },
//              T = A'Om^-1 Os Om^-1 A                                     SML Thm 5.1
real colvector cvk_lam(real matrix Ap, real matrix Om, real matrix EVm, real matrix Os)
{
    real matrix Oi, S, Sh, Ei, Mx, Tm, Th
    real scalar d
    d  = cols(Ap)
    Oi = invsym(Om)
    S  = Ap' * Oi * Ap
    Ei = invsym(Ap' * EVm * Ap)
    if (rows(Os) == 0) {
        Sh = cvk_sympow(S, 0.5)
        Mx = I(d) - Sh * Ei * Sh
    }
    else {
        Tm = Ap' * Oi * Os * Oi * Ap
        Th = cvk_sympow(Tm, -0.5)
        Mx = I(d) - Th * S * Ei * S * Th
    }
    Mx = (Mx + Mx') / 2
    return(sort(symeigenvalues(Mx)', 1))
}

// ---------------------------------------------------------------------------
//  Simulation of the limit distributions (SML (6.1)-(6.4), SIN App. A):
//    stat = tr{[zeta (I-L)^.5 + Phi L^.5]'[zeta (I-L)^.5 + Phi L^.5]}
//    zeta = (n^-2 sum y_{t-1}y_{t-1}')^-.5 (n^-1 sum y_{t-1} e_t'), y = random walk
//    (y_{t-1} demeaned for the model with a constant), Phi d x d iid N(0,1)
//  cvk_simdraws stores (vec zeta, vec Phi) per replication so that the statistic
//  can be evaluated for any lambda with common random numbers.
// ---------------------------------------------------------------------------

real matrix cvk_simdraws(real scalar d, real scalar dm, real scalar R, real scalar nn)
{
    real matrix out, e, y, yl, Syy, Sye, zeta, Phi
    real scalar b, j
    out = J(R, 2 * d * d, .)
    for (b = 1; b <= R; b = b + 1) {
        e = rnormal(nn, d, 0, 1)
        y = J(nn, d, 0)
        for (j = 1; j <= d; j = j + 1) {
            y[., j] = runningsum(e[., j])
        }
        yl = J(1, d, 0) \ y[|1, 1 \ nn-1, d|]
        if (dm) {
            yl = yl :- mean(yl)
        }
        Syy  = cross(yl, yl) / (nn * nn)
        Sye  = cross(yl, e) / nn
        zeta = cvk_sympow(Syy, -0.5) * Sye
        Phi  = rnormal(d, d, 0, 1)
        out[b, .] = vec(zeta)', vec(Phi)'
    }
    return(out)
}

real colvector cvk_simstats(real matrix Ds, real scalar d, real colvector lam)
{
    real rowvector s1, s2
    real matrix Q
    real scalar i, j, ix
    s1 = J(1, d * d, .)
    s2 = J(1, d * d, .)
    for (j = 1; j <= d; j = j + 1) {
        for (i = 1; i <= d; i = i + 1) {
            ix = (j - 1) * d + i
            s1[ix] = sqrt(1 - lam[j])
            s2[ix] = sqrt(lam[j])
        }
    }
    Q = Ds[|1, 1 \ rows(Ds), d*d|] :* s1 + Ds[|1, d*d+1 \ rows(Ds), 2*d*d|] :* s2
    return(rowsum(Q :* Q))
}

// quantiles qv of the limit for given d, lambda (row vector, length d)
real rowvector cvk_simquant(real scalar d, real scalar dm, real rowvector lam,
                            real rowvector qv, real scalar R, real scalar nn)
{
    real matrix Ds
    real colvector st
    real rowvector out
    real scalar j
    Ds  = cvk_simdraws(d, dm, R, nn)
    st  = cvk_simstats(Ds, d, lam')
    out = J(1, cols(qv), .)
    for (j = 1; j <= cols(qv); j = j + 1) {
        out[j] = cv_quantile(st, qv[j])
    }
    return(out)
}

// ---------------------------------------------------------------------------
//  Tabulated critical values and bilinear interpolation in lambda
//    method qmle         : SML Tables 1-3 (lambda 0..0.9); for trend none the
//                          lambda = 1.0 edge is taken from SIN Tables A.1-A.2
//    method wls, none    : SIN Tables A.1-A.2 (lambda 0..1.0)
//    method wls, rconst. : SML Tables 1-3, constant blocks (same functional)
// ---------------------------------------------------------------------------

real scalar cvk_sincol(real scalar lev)
{
    if (lev == 50) {
        return(1)
    }
    if (lev == 75) {
        return(2)
    }
    if (lev == 80) {
        return(3)
    }
    if (lev == 85) {
        return(4)
    }
    if (lev == 90) {
        return(5)
    }
    if (lev == 95) {
        return(6)
    }
    if (lev == 97.5) {
        return(7)
    }
    if (lev == 99) {
        return(8)
    }
    return(.)
}

real matrix cvk_utri(real rowvector v, real scalar G)
{
    real matrix T
    real scalar i, j, ix
    T  = J(G, G, .)
    ix = 0
    for (i = 1; i <= G; i = i + 1) {
        for (j = i; j <= G; j = j + 1) {
            ix = ix + 1
            T[i, j] = v[ix]
            T[j, i] = v[ix]
        }
    }
    return(T)
}

real matrix cvk_sin2(real scalar ci)
{
    real matrix S, T
    real scalar i, a, b
    S = cvk_sin2raw()
    T = J(11, 11, .)
    for (i = 1; i <= rows(S); i = i + 1) {
        a = round(S[i, 1] * 10) + 1
        b = round(S[i, 2] * 10) + 1
        T[a, b] = S[i, 2 + ci]
        T[b, a] = S[i, 2 + ci]
    }
    return(T)
}

real matrix cvk_grid(real scalar d, string scalar det, string scalar method, real scalar lev)
{
    real matrix S, Tb
    real colvector v
    real scalar ci
    ci = cvk_sincol(lev)
    if (det == "none" & method == "wls") {
        if (d == 1) {
            S = cvk_sin1()
            return(S[., ci])
        }
        return(cvk_sin2(ci))
    }
    if (d == 1) {
        v = cvk_sml1(det, lev)'
        if (det == "none") {
            S = cvk_sin1()
            v = v \ S[11, ci]
        }
        return(v)
    }
    Tb = cvk_utri(cvk_sml2(det, lev), 10)
    if (det == "none") {
        S  = cvk_sin2(ci)
        Tb = (Tb, S[|1, 11 \ 10, 11|]) \ S[11, .]
    }
    return(Tb)
}

// bilinear interpolation on the uniform grid 0, 0.1, ..., (G-1)/10
real scalar cvk_interp(real matrix Tb, real colvector lam)
{
    real scalar G, gmax, x1, x2, i, j, w1, w2, v1, v2
    G    = rows(Tb)
    gmax = (G - 1) / 10
    x1   = lam[1]
    if (x1 < 0) {
        x1 = 0
    }
    if (x1 > gmax) {
        x1 = gmax
    }
    i = floor(x1 * 10 + 1e-9)
    if (i > G - 2) {
        i = G - 2
    }
    w1 = x1 * 10 - i
    if (cols(Tb) == 1) {
        return((1 - w1) * Tb[i+1] + w1 * Tb[i+2])
    }
    x2 = lam[2]
    if (x2 < 0) {
        x2 = 0
    }
    if (x2 > gmax) {
        x2 = gmax
    }
    j = floor(x2 * 10 + 1e-9)
    if (j > G - 2) {
        j = G - 2
    }
    w2 = x2 * 10 - j
    v1 = (1 - w1) * (1 - w2) * Tb[i+1, j+1] + w1 * (1 - w2) * Tb[i+2, j+1]
    v2 = (1 - w1) * w2 * Tb[i+1, j+2] + w1 * w2 * Tb[i+2, j+2]
    return(v1 + v2)
}

// returns (cv at level, p-value, cv90, cv95, cv99, clip flag)
real rowvector cvk_cvset(real scalar stat, real colvector lam, real scalar d,
                         string scalar det, string scalar method, real scalar level,
                         real scalar usetab, real matrix Ds)
{
    real rowvector out, levs
    real colvector lc, st
    real matrix Tb
    real scalar j, gmax
    out = J(1, 6, .)
    lc  = lam
    for (j = 1; j <= rows(lc); j = j + 1) {
        if (lc[j] < 0) {
            lc[j] = 0
        }
        if (lc[j] > 1) {
            lc[j] = 1
        }
    }
    if (usetab) {
        levs = (90, 95, 99)
        for (j = 1; j <= 3; j = j + 1) {
            Tb = cvk_grid(d, det, method, levs[j])
            out[2 + j] = cvk_interp(Tb, lc)
            if (level == levs[j]) {
                out[1] = out[2 + j]
            }
        }
        gmax = (rows(Tb) - 1) / 10
        out[6] = (max(lc) > gmax + 1e-12)
    }
    else {
        st = cvk_simstats(Ds, d, lc)
        out[1] = cv_quantile(st, level / 100)
        out[2] = mean(st :>= stat)
        out[3] = cv_quantile(st, 0.90)
        out[4] = cv_quantile(st, 0.95)
        out[5] = cv_quantile(st, 0.99)
        out[6] = 0
    }
    return(out)
}

real scalar cvk_seqsel(real colvector st, real colvector cv, real scalar m)
{
    real scalar i
    if (hasmissing(st) | hasmissing(cv)) {
        return(.)
    }
    for (i = 1; i <= m; i = i + 1) {
        if (st[i] <= cv[i]) {
            return(i - 1)
        }
    }
    return(m)
}

// ---------------------------------------------------------------------------
//  Main entry point for -cointvol garchrank-
//    det    : none | rconstant (constant estimated freely in the FR and RR
//             models, no linear trend in the data: SML (2.7), (5.9))
//    method : qmle (SML) | wls (SIN)
//    gp, gq : GARCH orders (p lagged h, q lagged e^2)
// ---------------------------------------------------------------------------

void cvk_main(string scalar vars, string scalar touse, real scalar k,
              string scalar det, string scalar method, real scalar gp,
              real scalar gq, string scalar cvmode, real scalar R,
              real scalar nn, real scalar level, string scalar rlist,
              real scalar dots)
{
    struct cv_joh scalar Jo
    real matrix Y, D1, D2, Z0, Z1, Z2, X, SXX, PiLS, ELS, P0, G0, H0, PiFR, EFR
    real matrix Pd, Gd, Hd, F, SFR, SY, EV, Om1, Om1s, Dl, Om1i
    real matrix alpha, bstar, Psi, ER, Ahat, Bdot, Adot, U, A2, PiRR, Dm, Dm1
    real matrix ERR, Ap, res, LAM1, LAM2, Hf, Kh, Tm, Sst, Cdot, Cs, Bs, Ds
    real matrix Vs, Os1, F1, F2, Pw, Gw
    real colvector s, s1, s2, a2, phi, rr, vb, lam0, lam1, lam2, vCs
    real rowvector c0, c1, c2, sel
    real scalar T0, m, n, q2, K, full, nf, i, r, d, ll, st0, st1, st2
    real scalar ntests, dm, usetab, nsim, nclip
    string scalar edet

    Y  = st_data(., tokens(vars), touse)
    T0 = rows(Y)
    edet = "none"
    if (det == "rconstant") {
        edet = "constant"
    }
    cv_detmats(T0, edet, D1, D2)
    cv_build(Y, k, D1, D2, Z0, Z1, Z2)
    Jo = cv_johansen(Z0, Z1, Z2)
    if (Jo.ok == 0) {
        errprintf("moment matrices are singular; check for collinear or constant series\n")
        exit(error(506))
    }
    m    = cols(Y)
    n    = rows(Z0)
    q2   = cols(Z2)
    X    = Z1, Z2
    K    = cols(X)
    full = (method == "qmle")
    dm   = (det == "rconstant")
    SXX  = cross(X, X)
    nf   = 0

    // (1) full-rank LS estimator and CCC-GARCH on its residuals
    PiLS = (invsym(SXX) * cross(X, Z0))'
    ELS  = Z0 - X * PiLS'
    cvk_garchfit(ELS, gq, gp, P0, G0, H0, nf)

    // (2) one-step full-rank estimator: SML (3.2)/(3.4) or SIN (3.3)-(3.4)
    cvk_step(ELS, X, J(0, 0, .), 1, P0, G0, gq, gp, full, H0, s, F)
    phi  = vec(PiLS) + cvk_solve(-F, s)
    PiFR = colshape(phi', m)'
    EFR  = Z0 - X * PiFR'

    // (3) variance parameters and weights used from here on
    if (full) {
        // delta_dot: CCC-GARCH re-estimated on the one-step FR residuals
        cvk_garchfit(EFR, gq, gp, Pd, Gd, Hd, nf)
        cvk_step(EFR, X, J(0, 0, .), 1, Pd, Gd, gq, gp, 1, Hd, s, F)
        SFR = -F
        cvk_nuis(EFR, Hd, Pd, Gd, gq, gp, EV, Om1, Om1s, Dl)
        Pw = Pd
        Gw = Gd
        Hf = J(0, 0, .)
    }
    else {
        // WLS: weights V_hat_t fixed at the LS/GARCH stage (feasible GLS)
        Pd = P0
        Gd = G0
        Hd = H0
        cvk_step(EFR, Z1, J(0, 0, .), 1, P0, G0, gq, gp, 0, H0, s, F)
        SY  = -F
        Om1 = cvk_meanVi(H0, G0)
        Pw  = P0
        Gw  = G0
        Hf  = H0
    }

    rr     = strtoreal(tokens(rlist))'
    ntests = rows(rr)
    // columns: 1 r, 2 d, 3 LR_NG, 4 cv, 5 p, 6 stat1, 7 cv, 8 p, 9 stat2, 10 cv, 11 p,
    //          12 source (1 table, 2 simulation), 13-15 LR_NG cv90/95/99,
    //          16-18 stat1 cv90/95/99, 19-21 stat2 cv90/95/99, 22 lambda clipped
    res   = J(ntests, 22, .)
    LAM1  = J(ntests, m, .)
    LAM2  = J(ntests, m, .)
    nsim  = 0
    nclip = 0
    for (i = 1; i <= ntests; i = i + 1) {
        r = rr[i]
        d = m - r
        // Johansen trace statistic (LR_NG)
        st0 = cv_trace(Jo.lam, r, m, n)
        // (4) Johansen RRR initial reduced-rank estimator under H0: rank = r
        cv_fitrank(Jo, r, alpha, bstar, Psi, ER, ll)
        // (5) one-step reduced-rank estimator: SML (4.5)-(4.8) / SIN (4.9)-(4.10)
        if (r > 0) {
            Ahat = alpha
            cvk_step(ER, Z1, Ahat, 2, Pw, Gw, gq, gp, full, Hf, s1, F1)
            vb   = vec(bstar') + cvk_solve(-F1, s1)
            Bdot = colshape(vb', r)'
            U    = (Z1 * bstar), Z2
            a2   = vec((Ahat, Psi))
        }
        else {
            Bdot = J(0, m, .)
            U    = Z2
            a2   = vec(Psi)
        }
        A2 = J(m, 0, .)
        if (cols(U) > 0) {
            cvk_step(ER, U, J(0, 0, .), 1, Pw, Gw, gq, gp, full, Hf, s2, F2)
            a2 = a2 + cvk_solve(-F2, s2)
            A2 = colshape(a2', m)'
        }
        PiRR = J(m, m, 0)
        Adot = J(m, 0, .)
        if (r > 0) {
            Adot = A2[|1, 1 \ m, r|]
            PiRR = Adot * Bdot
        }
        if (q2 > 0) {
            PiRR = PiRR, A2[|1, r+1 \ m, r+q2|]
        }
        Dm  = PiFR - PiRR
        ERR = Z0 - X * PiRR'
        Ap  = cvk_aperp(Adot, m, r)

        // (6) test statistics and nuisance eigenvalues
        if (full) {
            st1  = vec(Dm)' * SFR * vec(Dm)
            lam1 = cvk_lam(Ap, Om1, EV, J(0, 0, .))
            lam2 = cvk_lam(Ap, Om1, EV, Om1s)
            Om1i = invsym(Om1)
            Tm   = Ap' * Om1i * Om1s * Om1i * Ap
            Kh   = Ap * invsym((Tm + Tm') / 2) * Ap'
            st2  = trace(Kh * Dm * SXX * Dm')
        }
        else {
            Dm1  = Dm[|1, 1 \ m, m|]
            st1  = vec(Dm1)' * SY * vec(Dm1)
            cvk_wlsstar(Z1, ERR, H0, G0, Sst, Os1, Vs)
            lam1 = cvk_lam(Ap, Om1, Vs, J(0, 0, .))
            lam2 = cvk_lam(Ap, Os1, Vs, J(0, 0, .))
            Cdot = PiFR[|1, 1 \ m, m|]
            vCs  = cvk_solve(Sst, SY * vec(Cdot))
            Cs   = colshape(vCs', m)'
            if (r > 0) {
                Bs = invsym(Adot' * Os1 * Adot) * (Adot' * Om1 * Adot) * Bdot
                Cs = Cs - Adot * Bs
            }
            st2 = vec(Cs)' * Sst * vec(Cs)
        }

        // (7) critical values / p-values
        usetab = (cvmode == "table") & (d <= 2)
        Ds = J(0, 0, .)
        if (usetab == 0) {
            if (dots) {
                printf("{txt}simulating the limit distribution for d = %g ", d)
                displayflush()
            }
            Ds   = cvk_simdraws(d, dm, R, nn)
            nsim = nsim + 1
            if (dots) {
                printf("{txt}done\n")
                displayflush()
            }
        }
        lam0 = J(d, 1, 0)
        c0 = cvk_cvset(st0, lam0, d, det, method, level, usetab, Ds)
        c1 = cvk_cvset(st1, lam1, d, det, method, level, usetab, Ds)
        c2 = cvk_cvset(st2, lam2, d, det, method, level, usetab, Ds)
        res[i, 1]  = r
        res[i, 2]  = d
        res[i, 3]  = st0
        res[i, 4]  = c0[1]
        res[i, 5]  = c0[2]
        res[i, 6]  = st1
        res[i, 7]  = c1[1]
        res[i, 8]  = c1[2]
        res[i, 9]  = st2
        res[i, 10] = c2[1]
        res[i, 11] = c2[2]
        res[i, 12] = 2 - usetab
        res[i, 13] = c0[3]
        res[i, 14] = c0[4]
        res[i, 15] = c0[5]
        res[i, 16] = c1[3]
        res[i, 17] = c1[4]
        res[i, 18] = c1[5]
        res[i, 19] = c2[3]
        res[i, 20] = c2[4]
        res[i, 21] = c2[5]
        res[i, 22] = max((c1[6], c2[6]))
        nclip = nclip + res[i, 22]
        LAM1[|i, 1 \ i, d|] = lam1'
        LAM2[|i, 1 \ i, d|] = lam2'
        if (r > 0) {
            st_matrix("__cvk_A" + strofreal(r), Adot)
            st_matrix("__cvk_B" + strofreal(r), Bdot)
        }
    }

    // (8) sequential rank selection (only when r = 0..m-1 were all tested)
    sel = (., ., .)
    if (ntests == m) {
        if (rr == (0::m-1)) {
            sel[1] = cvk_seqsel(res[., 3], res[., 4], m)
            sel[2] = cvk_seqsel(res[., 6], res[., 7], m)
            sel[3] = cvk_seqsel(res[., 9], res[., 10], m)
        }
    }

    st_matrix("__cvk_res", res)
    st_matrix("__cvk_lam1", LAM1)
    st_matrix("__cvk_lam2", LAM2)
    st_matrix("__cvk_jlam", Jo.lam')
    st_matrix("__cvk_PiLS", PiLS)
    st_matrix("__cvk_PiFR", PiFR)
    st_matrix("__cvk_garch0", P0)
    st_matrix("__cvk_Gamma0", G0)
    st_matrix("__cvk_garch", Pd)
    st_matrix("__cvk_Gamma", Gd)
    st_matrix("__cvk_Om1", Om1)
    if (full) {
        st_matrix("__cvk_EV", EV)
        st_matrix("__cvk_Om1s", Om1s)
        st_matrix("__cvk_Delta", Dl)
    }
    st_numscalar("__cvk_T", n)
    st_numscalar("__cvk_K", K)
    st_numscalar("__cvk_nfail", nf)
    st_numscalar("__cvk_nsim", nsim)
    st_numscalar("__cvk_nclip", nclip)
    st_numscalar("__cvk_sel0", sel[1])
    st_numscalar("__cvk_sel1", sel[2])
    st_numscalar("__cvk_sel2", sel[3])
}

// ---------------------------------------------------------------------------
//  Embedded critical-value tables
//  SML Tables 1-3 (90/95/99%): d = 1 row (lambda 0..0.9) and d = 2 upper
//  triangle (rows lambda_1, columns lambda_2 >= lambda_1), for the model
//  without constant ("none") and with constant ("rconstant").
//  SIN Tables A.1-A.2 (no constant): quantiles .50 .75 .80 .85 .90 .95 .975 .99,
//  lambda 0..1.0; A.2 rows are (lambda_1, lambda_2, 8 quantiles), lambda_1 <= lambda_2.
// ---------------------------------------------------------------------------

real rowvector cvk_sml1(string scalar det, real scalar lev)
{
    if (det == "none" & lev == 90) {
        return((2.995, 2.978, 2.964, 2.941, 2.914, 2.883, 2.845, 2.811, 2.782, 2.746))
    }
    if (det == "rconstant" & lev == 90) {
        return((6.588, 6.327, 6.051, 5.767, 5.457, 5.113, 4.715, 4.272, 3.794, 3.270))
    }
    if (det == "none" & lev == 95) {
        return((4.153, 4.140, 4.138, 4.108, 4.083, 4.043, 4.013, 3.963, 3.920, 3.867))
    }
    if (det == "rconstant" & lev == 95) {
        return((8.167, 7.932, 7.656, 7.373, 7.049, 6.679, 6.251, 5.763, 5.220, 4.576))
    }
    if (det == "none" & lev == 99) {
        return((7.018, 6.941, 6.939, 6.931, 6.929, 6.895, 6.842, 6.839, 6.774, 6.718))
    }
    if (det == "rconstant" & lev == 99) {
        return((11.690, 11.469, 11.291, 11.027, 10.727, 10.293, 9.817, 9.316, 8.655, 7.789))
    }
    return(J(1, 10, .))
}

real rowvector cvk_sml2(string scalar det, real scalar lev)
{
    real rowvector v
    v = J(1, 55, .)
    if (det == "none" & lev == 90) {
        v = (10.479, 10.386, 10.312, 10.234, 10.119, 10.003, 9.906, 9.796, 9.680, 9.551)
        v = v, (10.295, 10.217, 10.125, 10.018, 9.919, 9.808, 9.679, 9.561, 9.455)
        v = v, (10.116, 10.028, 9.916, 9.819, 9.691, 9.579, 9.453, 9.322)
        v = v, (9.931, 9.816, 9.693, 9.565, 9.442, 9.310, 9.163)
        v = v, (9.707, 9.576, 9.440, 9.313, 9.176, 9.018)
        v = v, (9.444, 9.310, 9.177, 9.030, 8.866)
        v = v, (9.153, 9.015, 8.857, 8.698)
        v = v, (8.847, 8.688, 8.520)
        v = v, (8.526, 8.345)
        v = v, (8.166)
    }
    if (det == "rconstant" & lev == 90) {
        v = (15.842, 15.578, 15.270, 14.955, 14.630, 14.277, 13.913, 13.537, 13.132, 12.712)
        v = v, (15.264, 14.977, 14.650, 14.326, 13.984, 13.616, 13.219, 12.808, 12.393)
        v = v, (14.661, 14.341, 13.985, 13.630, 13.259, 12.861, 12.457, 12.034)
        v = v, (14.000, 13.658, 13.310, 12.919, 12.515, 12.087, 11.666)
        v = v, (13.306, 12.961, 12.572, 12.152, 11.709, 11.264)
        v = v, (12.595, 12.191, 11.774, 11.309, 10.850)
        v = v, (11.780, 11.356, 10.897, 10.412)
        v = v, (10.921, 10.456, 9.956)
        v = v, (9.963, 9.466)
        v = v, (8.942)
    }
    if (det == "none" & lev == 95) {
        v = (12.286, 12.237, 12.158, 12.073, 11.987, 11.887, 11.789, 11.676, 11.559, 11.446)
        v = v, (12.140, 12.071, 11.987, 11.902, 11.818, 11.692, 11.578, 11.434, 11.284)
        v = v, (11.973, 11.879, 11.791, 11.691, 11.566, 11.433, 11.293, 11.141)
        v = v, (11.752, 11.669, 11.570, 11.432, 11.296, 11.158, 11.010)
        v = v, (11.557, 11.438, 11.310, 11.171, 11.024, 10.847)
        v = v, (11.322, 11.176, 11.049, 10.854, 10.693)
        v = v, (11.035, 10.894, 10.713, 10.529)
        v = v, (10.719, 10.555, 10.353)
        v = v, (10.342, 10.144)
        v = v, (9.932)
    }
    if (det == "rconstant" & lev == 95) {
        v = (18.064, 17.783, 17.508, 17.201, 16.877, 16.516, 16.137, 15.739, 15.332, 14.908)
        v = v, (17.530, 17.212, 16.897, 16.564, 16.206, 15.833, 15.439, 15.004, 14.561)
        v = v, (16.917, 16.583, 16.246, 15.894, 15.495, 15.094, 14.650, 14.178)
        v = v, (16.253, 15.906, 15.539, 15.147, 14.736, 14.277, 13.806)
        v = v, (15.556, 15.153, 14.747, 14.345, 13.888, 13.372)
        v = v, (14.741, 14.352, 13.919, 13.470, 12.958)
        v = v, (13.924, 13.484, 13.018, 12.479)
        v = v, (13.031, 12.553, 11.975)
        v = v, (12.045, 11.429)
        v = v, (10.861)
    }
    if (det == "none" & lev == 99) {
        v = (16.278, 16.144, 16.041, 15.986, 15.895, 15.802, 15.716, 15.623, 15.530, 15.435)
        v = v, (16.105, 15.991, 15.920, 15.806, 15.643, 15.552, 15.482, 15.337, 15.247)
        v = v, (15.898, 15.812, 15.647, 15.556, 15.405, 15.319, 15.191, 15.023)
        v = v, (15.702, 15.609, 15.471, 15.318, 15.202, 15.021, 14.870)
        v = v, (15.510, 15.374, 15.231, 15.087, 14.928, 14.747)
        v = v, (15.298, 15.115, 14.954, 14.820, 14.612)
        v = v, (14.993, 14.809, 14.622, 14.480)
        v = v, (14.668, 14.435, 14.259)
        v = v, (14.255, 14.064)
        v = v, (13.770)
    }
    if (det == "rconstant" & lev == 99) {
        v = (22.745, 22.477, 22.192, 21.901, 21.541, 21.236, 20.842, 20.390, 19.987, 19.498)
        v = v, (22.311, 22.013, 21.670, 21.346, 20.978, 20.528, 20.137, 19.640, 19.157)
        v = v, (21.739, 21.389, 21.052, 20.695, 20.250, 19.815, 19.281, 18.757)
        v = v, (21.093, 20.787, 20.360, 19.921, 19.441, 18.904, 18.329)
        v = v, (20.385, 20.004, 19.548, 19.072, 18.549, 17.907)
        v = v, (19.545, 19.122, 18.639, 18.047, 17.429)
        v = v, (18.673, 18.199, 17.607, 16.943)
        v = v, (17.617, 17.093, 16.376)
        v = v, (16.478, 15.794)
        v = v, (15.178)
    }
    return(v)
}

real matrix cvk_sin1()
{
    real matrix S
    S = (0.602, 1.550, 1.891, 2.343, 2.995, 4.153, 5.357, 7.018)
    S = S \ (0.575, 1.539, 1.869, 2.315, 2.978, 4.140, 5.365, 6.941)
    S = S \ (0.553, 1.511, 1.850, 2.308, 2.964, 4.138, 5.362, 6.939)
    S = S \ (0.533, 1.489, 1.824, 2.282, 2.941, 4.108, 5.305, 6.921)
    S = S \ (0.515, 1.462, 1.800, 2.254, 2.914, 4.083, 5.286, 6.929)
    S = S \ (0.499, 1.441, 1.770, 2.223, 2.883, 4.043, 5.242, 6.895)
    S = S \ (0.490, 1.414, 1.743, 2.197, 2.845, 4.013, 5.225, 6.824)
    S = S \ (0.481, 1.385, 1.718, 2.171, 2.811, 3.963, 5.174, 6.839)
    S = S \ (0.470, 1.364, 1.693, 2.139, 2.782, 3.920, 5.097, 6.774)
    S = S \ (0.461, 1.354, 1.674, 2.105, 2.746, 3.867, 5.047, 6.718)
    S = S \ (0.455, 1.326, 1.649, 2.078, 2.711, 3.827, 5.068, 6.633)
    return(S)
}

real matrix cvk_sin2raw()
{
    real matrix S
    S = (0.0, 0.0, 5.508, 7.844, 8.522, 9.365, 10.479, 12.286, 14.065, 16.278)
    S = S \ (0.0, 0.1, 5.405, 7.739, 8.413, 9.267, 10.386, 12.237, 13.971, 16.144)
    S = S \ (0.0, 0.2, 5.298, 7.645, 8.313, 9.159, 10.312, 12.158, 13.886, 16.041)
    S = S \ (0.0, 0.3, 5.189, 7.541, 8.210, 9.062, 10.234, 12.073, 13.793, 15.986)
    S = S \ (0.0, 0.4, 5.068, 7.440, 8.112, 8.959, 10.119, 11.987, 13.722, 15.895)
    S = S \ (0.0, 0.5, 4.952, 7.330, 8.008, 8.865, 10.003, 11.887, 13.659, 15.802)
    S = S \ (0.0, 0.6, 4.839, 7.216, 7.909, 8.744, 9.906, 11.789, 13.542, 15.716)
    S = S \ (0.0, 0.7, 4.726, 7.112, 7.783, 8.647, 9.796, 11.676, 13.440, 15.623)
    S = S \ (0.0, 0.8, 4.619, 6.981, 7.668, 8.525, 9.680, 11.559, 13.354, 15.530)
    S = S \ (0.0, 0.9, 4.504, 6.867, 7.542, 8.410, 9.551, 11.446, 13.230, 15.435)
    S = S \ (0.0, 1.0, 4.393, 6.745, 7.417, 8.268, 9.443, 11.306, 13.172, 15.450)
    S = S \ (0.1, 0.1, 5.287, 7.635, 8.325, 9.172, 10.295, 12.140, 13.885, 16.105)
    S = S \ (0.1, 0.2, 5.178, 7.534, 8.229, 9.079, 10.217, 12.071, 13.817, 15.991)
    S = S \ (0.1, 0.3, 5.058, 7.440, 8.123, 8.979, 10.125, 11.987, 13.736, 15.920)
    S = S \ (0.1, 0.4, 4.945, 7.341, 8.023, 8.865, 10.018, 11.902, 13.612, 15.806)
    S = S \ (0.1, 0.5, 4.832, 7.224, 7.920, 8.750, 9.919, 11.818, 13.539, 15.643)
    S = S \ (0.1, 0.6, 4.718, 7.108, 7.791, 8.643, 9.808, 11.692, 13.422, 15.552)
    S = S \ (0.1, 0.7, 4.605, 6.987, 7.677, 8.533, 9.679, 11.578, 13.296, 15.482)
    S = S \ (0.1, 0.8, 4.498, 6.856, 7.559, 8.413, 9.561, 11.434, 13.179, 15.337)
    S = S \ (0.1, 0.9, 4.382, 6.749, 7.430, 8.290, 9.455, 11.284, 13.064, 15.247)
    S = S \ (0.1, 1.0, 4.278, 6.627, 7.307, 8.157, 9.307, 11.147, 12.950, 15.229)
    S = S \ (0.2, 0.2, 5.070, 7.445, 8.137, 8.987, 10.116, 11.973, 13.707, 15.898)
    S = S \ (0.2, 0.3, 4.945, 7.336, 8.037, 8.881, 10.028, 11.879, 13.601, 15.812)
    S = S \ (0.2, 0.4, 4.828, 7.225, 7.916, 8.761, 9.916, 11.791, 13.501, 15.647)
    S = S \ (0.2, 0.5, 4.711, 7.111, 7.807, 8.658, 9.819, 11.691, 13.383, 15.556)
    S = S \ (0.2, 0.6, 4.596, 6.998, 7.682, 8.532, 9.691, 11.566, 13.298, 15.405)
    S = S \ (0.2, 0.7, 4.488, 6.881, 7.560, 8.415, 9.579, 11.433, 13.191, 15.319)
    S = S \ (0.2, 0.8, 4.383, 6.753, 7.435, 8.288, 9.453, 11.293, 13.027, 15.191)
    S = S \ (0.2, 0.9, 4.266, 6.621, 7.309, 8.165, 9.322, 11.141, 12.902, 15.023)
    S = S \ (0.2, 1.0, 4.160, 6.502, 7.190, 8.031, 9.182, 10.985, 12.768, 15.020)
    S = S \ (0.3, 0.3, 4.830, 7.232, 7.929, 8.781, 9.931, 11.752, 13.491, 15.702)
    S = S \ (0.3, 0.4, 4.717, 7.118, 7.809, 8.657, 9.816, 11.669, 13.411, 15.609)
    S = S \ (0.3, 0.5, 4.598, 7.001, 7.688, 8.540, 9.693, 11.570, 13.285, 15.471)
    S = S \ (0.3, 0.6, 4.489, 6.877, 7.570, 8.415, 9.565, 11.432, 13.179, 15.318)
    S = S \ (0.3, 0.7, 4.369, 6.758, 7.442, 8.281, 9.442, 11.296, 13.051, 15.202)
    S = S \ (0.3, 0.8, 4.263, 6.636, 7.302, 8.160, 9.310, 11.158, 12.897, 15.021)
    S = S \ (0.3, 0.9, 4.152, 6.505, 7.187, 8.042, 9.163, 11.010, 12.743, 14.870)
    S = S \ (0.3, 1.0, 4.052, 6.374, 7.045, 7.882, 9.046, 10.819, 12.592, 14.853)
    S = S \ (0.4, 0.4, 4.600, 7.006, 7.695, 8.549, 9.707, 11.557, 13.290, 15.510)
    S = S \ (0.4, 0.5, 4.486, 6.877, 7.577, 8.420, 9.576, 11.438, 13.180, 15.374)
    S = S \ (0.4, 0.6, 4.373, 6.760, 7.444, 8.287, 9.440, 11.310, 13.061, 15.231)
    S = S \ (0.4, 0.7, 4.255, 6.631, 7.318, 8.148, 9.313, 11.171, 12.881, 15.087)
    S = S \ (0.4, 0.8, 4.150, 6.506, 7.179, 8.012, 9.176, 11.024, 12.733, 14.928)
    S = S \ (0.4, 0.9, 4.040, 6.378, 7.050, 7.883, 9.018, 10.847, 12.567, 14.747)
    S = S \ (0.4, 1.0, 3.941, 6.233, 6.911, 7.735, 8.875, 10.678, 12.395, 14.651)
    S = S \ (0.5, 0.5, 4.376, 6.751, 7.437, 8.298, 9.444, 11.322, 13.053, 15.298)
    S = S \ (0.5, 0.6, 4.261, 6.625, 7.299, 8.171, 9.310, 11.176, 12.919, 15.115)
    S = S \ (0.5, 0.7, 4.151, 6.497, 7.178, 8.016, 9.177, 11.049, 12.759, 14.954)
    S = S \ (0.5, 0.8, 4.036, 6.362, 7.039, 7.870, 9.030, 10.854, 12.567, 14.820)
    S = S \ (0.5, 0.9, 3.937, 6.235, 6.907, 7.727, 8.866, 10.693, 12.398, 14.612)
    S = S \ (0.5, 1.0, 3.836, 6.098, 6.758, 7.588, 8.685, 10.541, 12.202, 14.486)
    S = S \ (0.6, 0.6, 4.152, 6.495, 7.161, 8.015, 9.153, 11.035, 12.781, 14.993)
    S = S \ (0.6, 0.7, 4.045, 6.356, 7.027, 7.874, 9.015, 10.894, 12.580, 14.809)
    S = S \ (0.6, 0.8, 3.930, 6.214, 6.890, 7.719, 8.857, 10.713, 12.401, 14.622)
    S = S \ (0.6, 0.9, 3.828, 6.086, 6.749, 7.577, 8.698, 10.529, 12.218, 14.480)
    S = S \ (0.6, 1.0, 3.733, 5.959, 6.612, 7.428, 8.512, 10.358, 12.002, 14.298)
    S = S \ (0.7, 0.7, 3.936, 6.213, 6.885, 7.721, 8.847, 10.719, 12.432, 14.668)
    S = S \ (0.7, 0.8, 3.827, 6.082, 6.738, 7.564, 8.688, 10.555, 12.247, 14.435)
    S = S \ (0.7, 0.9, 3.724, 5.933, 6.598, 7.413, 8.520, 10.353, 12.036, 14.259)
    S = S \ (0.7, 1.0, 3.630, 5.811, 6.464, 7.251, 8.347, 10.151, 11.794, 14.091)
    S = S \ (0.8, 0.8, 3.728, 5.934, 6.586, 7.400, 8.526, 10.342, 12.053, 14.255)
    S = S \ (0.8, 0.9, 3.626, 5.791, 6.434, 7.240, 8.345, 10.144, 11.857, 14.064)
    S = S \ (0.8, 1.0, 3.528, 5.666, 6.303, 7.084, 8.154, 9.952, 11.588, 13.825)
    S = S \ (0.9, 0.9, 3.531, 5.655, 6.286, 7.071, 8.166, 9.932, 11.656, 13.770)
    S = S \ (0.9, 1.0, 3.446, 5.521, 6.142, 6.913, 7.972, 9.703, 11.390, 13.553)
    S = S \ (1.0, 1.0, 3.359, 5.378, 5.977, 6.734, 7.777, 9.471, 11.120, 13.264)
    return(S)
}

end
