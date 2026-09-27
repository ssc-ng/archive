*! cointvol_eng_adaptive 0.1.0  26sep2026
*! Mata engine for -cointvol adaptive- and -cointvol select-: kernel volatility
*! matrices, leave-one-out cross-validation, GLS moments, generalized reduced-rank
*! regression (switching algorithm), adaptive LR bootstrap, information criteria.
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com) - github.com/merwanroudane
*!
*! Step -> source map:
*!   Sigma_t = sum_s K_h((t-s)/n) e_s e_s' / sum_s K_h((t-s)/n), Gaussian K
*!       -> Boswijk & Zu (2022) eq (19); BCDT (2023) eq (3.3)
*!   CV(h) = sum_t || Sigma_t^{-t}(h) - e_t e_t' ||^2 (leave-one-out, Frobenius)
*!       -> Boswijk & Zu (2022) eq (20); BCDT (2023) Sec 3.2
*!   GLS given beta / given alpha (switching algorithm), unrestricted GLS
*!       -> Boswijk & Zu (2022) eqs (9)-(12); Hansen (2003)
*!   ALR(r) = sum_t (e~_t' S_t^-1 e~_t - e^_t' S_t^-1 e^_t)
*!       -> Boswijk & Zu (2022) eq (13); BCDT (2023) eq (3.6)
*!   bootstrap DGP (21) with VBS e*_t = S_t^{1/2} z_t / WBS e*_t = e_t w_t,
*!   Sigma_t NOT re-estimated -> Boswijk & Zu (2022) Sec 4.2; BCDT (2023) (3.7)-(3.8)
*!   IC(k,r) = T log|S00| + T sum_{i<=r} log(1-lam_i) + c_T pi(k,r)
*!       -> Cavaliere, De Angelis, Rahbek & Taylor (2018) eqs (3.1)-(3.13)
*!   ALS-IC(k,r) = -2 l(k,r; Sigma_t) + c_T pi_A(k,r) -> BCDT (2023) eqs (3.4),(3.5),(3.9)
*!   bootstrap PLR with k-hat (restricted estimates, recentred residuals)
*!       -> CDRT (2018) Algorithm 1
*!
*! This file is -run- by the cointvol commands (Mata in an autoloaded ado is
*! private to that file).  It requires the core engine cointvol_engine.ado
*! (struct cv_joh and the cv_ primitives), which is loaded first if absent.

program define cointvol_eng_adaptive
    version 14.0
end

version 14.0
capture mata: st_local("__cvav", cv_engine_version())
if _rc {
    capture program drop cointvol_engine
    quietly findfile cointvol_engine.ado
    quietly run `"`r(fn)'"'
}
capture mata: mata drop cva_*()
capture mata: mata drop cva_mom()

mata:

string scalar cva_version()
{
    return("0.1.0")
}

// ---------------------------------------------------------------------------
//  Small utilities
// ---------------------------------------------------------------------------

// first index of the minimum (missing values ignored)
real scalar cva_argmin(real vector x)
{
    real scalar i, j, m
    j = .
    m = .
    for (i = 1; i <= length(x); i = i + 1) {
        if (x[i] < m) {
            m = x[i]
            j = i
        }
    }
    return(j)
}

// inverse of a symmetric p.s.d. matrix after diagonal scaling (robust to
// badly scaled regressors such as trends next to small GLS-weighted levels)
real matrix cva_sinv(real matrix A)
{
    real colvector d
    real matrix B
    if (rows(A) == 0) {
        return(J(0, 0, .))
    }
    d = sqrt(abs(diagonal(A)))
    d = 1 :/ (d + (d :== 0))
    B = (A :* d) :* d'
    B = (B + B') / 2
    B = invsym(B)
    return((B :* d) :* d')
}

// full-sample subsample starting at row K-k+1 (common effective sample t=K+1..T0)
void cva_subsample(real matrix Y, real matrix D1, real matrix D2, real scalar K,
                   real scalar k, real matrix Yk, real matrix D1k, real matrix D2k)
{
    real scalar T0, s
    T0 = rows(Y)
    s  = K - k + 1
    Yk = Y[|s,1 \ T0,cols(Y)|]
    if (cols(D1) > 0) {
        D1k = D1[|s,1 \ T0,cols(D1)|]
    }
    else {
        D1k = J(T0-s+1, 0, .)
    }
    if (cols(D2) > 0) {
        D2k = D2[|s,1 \ T0,cols(D2)|]
    }
    else {
        D2k = J(T0-s+1, 0, .)
    }
}

// ---------------------------------------------------------------------------
//  Nonparametric volatility matrix (BZ 2022 eq 19) and LOO-CV (eq 20)
//  E2: T x p^2, row t = vec(e_t e_t')'.  h is a FRACTION of the sample
//  (Gaussian weights phi(|t-s|/(n h))), i.e. h_obs = n*h observations.
// ---------------------------------------------------------------------------

real matrix cva_e2(real matrix E)
{
    real scalar T, p, a, b
    real matrix E2
    T  = rows(E)
    p  = cols(E)
    E2 = J(T, p*p, .)
    for (b = 1; b <= p; b = b + 1) {
        for (a = 1; a <= p; a = a + 1) {
            E2[., (b-1)*p + a] = E[., a] :* E[., b]
        }
    }
    return(E2)
}

// S2 (T x p^2): kernel estimates; wd (T x 1): own weight w_tt of the
// row-normalised kernel (used for the leave-one-out identity)
void cva_smooth(real matrix E2, real scalar h, real matrix S2, real colvector wd)
{
    real scalar n, t, sw
    real matrix W
    real colvector w, sv, idx
    n = rows(E2)
    if (n <= 2500) {
        W  = (1::n) * J(1, n, 1) - J(n, 1, 1) * (1..n)
        W  = normalden(abs(W) :/ (n*h))
        sv = rowsum(W)
        S2 = (W * E2) :/ sv
        wd = normalden(0) :/ sv
    }
    else {
        S2  = J(n, cols(E2), .)
        wd  = J(n, 1, .)
        idx = (1::n)
        for (t = 1; t <= n; t = t + 1) {
            w  = normalden(abs(idx :- t) :/ (n*h))
            sw = sum(w)
            S2[t, .] = (w' * E2) :/ sw
            wd[t] = normalden(0) / sw
        }
    }
}

// leave-one-out CV criterion (mean over t of the squared Frobenius distance):
// e_te_t' - Sigma_t^{-t} = (e_te_t' - Sigma_t)/(1 - w_tt)
real scalar cva_cvcrit(real matrix E2, real scalar h)
{
    real matrix S2, D
    real colvector wd
    cva_smooth(E2, h, S2, wd)
    D = (E2 - S2) :/ (1 :- wd)
    return(sum(D :* D) / rows(E2))
}

// bandwidth by CV: log-grid on [1/n, 1] then golden-section refinement
real rowvector cva_bwcv(real matrix E2, real scalar ng)
{
    real scalar n, lo, hi, j, jm, a, b, gc, gd, fc, fd, g, it, lb, fb
    real colvector lh, cr
    n  = rows(E2)
    lo = ln(1/n)
    hi = 0
    lh = lo :+ (0::ng-1) :* ((hi - lo) / (ng - 1))
    cr = J(ng, 1, .)
    for (j = 1; j <= ng; j = j + 1) {
        cr[j] = cva_cvcrit(E2, exp(lh[j]))
    }
    jm = cva_argmin(cr)
    if (jm >= .) {
        return((., .))
    }
    a  = lh[max((1, jm-1))]
    b  = lh[min((ng, jm+1))]
    g  = (sqrt(5) - 1) / 2
    gc = b - g*(b - a)
    gd = a + g*(b - a)
    fc = cva_cvcrit(E2, exp(gc))
    fd = cva_cvcrit(E2, exp(gd))
    for (it = 1; it <= 30; it = it + 1) {
        if (fc < fd) {
            b  = gd
            gd = gc
            fd = fc
            gc = b - g*(b - a)
            fc = cva_cvcrit(E2, exp(gc))
        }
        else {
            a  = gc
            gc = gd
            fc = fd
            gd = a + g*(b - a)
            fd = cva_cvcrit(E2, exp(gd))
        }
    }
    lb = (a + b) / 2
    fb = cva_cvcrit(E2, exp(lb))
    if (cr[jm] < fb) {
        return((exp(lh[jm]), cr[jm]))
    }
    return((exp(lb), fb))
}

// Sigma_t^{-1/2} (Ai) and Sigma_t^{1/2} (Sh), symmetric roots, stored as
// rows vec(.)'; ldet = sum_t log|Sigma_t|. Returns 0, or the first t at which
// Sigma_t is not positive definite.
real scalar cva_volmats(real matrix S2, real scalar p, real matrix Ai,
                        real matrix Sh, real scalar ldet)
{
    real scalar n, t
    real matrix Sg, X, R
    real rowvector L
    n    = rows(S2)
    Ai   = J(n, p*p, .)
    Sh   = J(n, p*p, .)
    ldet = 0
    for (t = 1; t <= n; t = t + 1) {
        Sg = rowshape(S2[t, .], p)
        Sg = (Sg + Sg') / 2
        symeigensystem(Sg, X, L)
        if (hasmissing(L)) {
            return(t)
        }
        if (min(L) <= 1e-12 * max((max(L), 1e-300))) {
            return(t)
        }
        R = X * diag(L :^ (-0.5)) * X'
        Ai[t, .] = vec(R)'
        R = X * diag(sqrt(L)) * X'
        Sh[t, .] = vec(R)'
        ldet = ldet + sum(ln(L))
    }
    return(0)
}

// vech(Sigma_t)' for every t (T x p(p+1)/2)
real matrix cva_vech(real matrix S2, real scalar p)
{
    real scalar n, t
    real matrix V, Sg
    n = rows(S2)
    V = J(n, p*(p+1)/2, .)
    for (t = 1; t <= n; t = t + 1) {
        Sg = rowshape(S2[t, .], p)
        V[t, .] = vech((Sg + Sg') / 2)'
    }
    return(V)
}

// ---------------------------------------------------------------------------
//  GLS moments for the model  Z0_t = Pi Z1_t + Psi Z2_t + e_t, Var(e_t)=Sigma_t
//  Coefficient vector pi = vec(Pi') (row-wise Pi), psi = vec(Psi').
//  After concentrating out Psi:  J = LXS'M LXS, S = LXS'M DXS, dc = DXS'M DXS
//  (M: annihilator of the GLS-transformed Z2).  For any pi the minimised
//  weighted SSR is  Q(pi) = dc - 2 ll(pi),  ll(pi) = pi'S - pi'J pi/2.
// ---------------------------------------------------------------------------

struct cva_mom {
    real matrix J, Ji, S, JLW, WWi, SW
    real scalar dc, Qp, p, p1, q, T, ok
}

struct cva_mom scalar cva_moments(real matrix Z0, real matrix Z1, real matrix Z2,
                                  real matrix Ai)
{
    struct cva_mom scalar M
    real scalar T, p, p1, q, a, b, dd
    real matrix JLL, JLW, JWW, La, Wa
    real colvector SL, SW, dxa, ab

    T  = rows(Z0)
    p  = cols(Z0)
    p1 = cols(Z1)
    q  = cols(Z2)
    M.T  = T
    M.p  = p
    M.p1 = p1
    M.q  = q
    M.ok = 1
    JLL = J(p*p1, p*p1, 0)
    SL  = J(p*p1, 1, 0)
    dd  = 0
    if (q > 0) {
        JLW = J(p*p1, p*q, 0)
        JWW = J(p*q, p*q, 0)
        SW  = J(p*q, 1, 0)
    }
    for (a = 1; a <= p; a = a + 1) {
        dxa = J(T, 1, 0)
        La  = J(T, p*p1, .)
        if (q > 0) {
            Wa = J(T, p*q, .)
        }
        for (b = 1; b <= p; b = b + 1) {
            ab  = Ai[., (b-1)*p + a]
            dxa = dxa + ab :* Z0[., b]
            La[|1,(b-1)*p1+1 \ T,b*p1|] = ab :* Z1
            if (q > 0) {
                Wa[|1,(b-1)*q+1 \ T,b*q|] = ab :* Z2
            }
        }
        JLL = JLL + cross(La, La)
        SL  = SL + cross(La, dxa)
        dd  = dd + cross(dxa, dxa)
        if (q > 0) {
            JLW = JLW + cross(La, Wa)
            JWW = JWW + cross(Wa, Wa)
            SW  = SW + cross(Wa, dxa)
        }
    }
    if (q > 0) {
        M.WWi = cva_sinv(JWW)
        M.JLW = JLW
        M.SW  = SW
        M.J   = JLL - JLW * M.WWi * JLW'
        M.S   = SL - JLW * (M.WWi * SW)
        M.dc  = dd - SW' * M.WWi * SW
    }
    else {
        M.WWi = J(0, 0, .)
        M.JLW = J(p*p1, 0, .)
        M.SW  = J(0, 1, .)
        M.J   = JLL
        M.S   = SL
        M.dc  = dd
    }
    M.J  = (M.J + M.J') / 2
    M.Ji = cva_sinv(M.J)
    if (hasmissing(M.Ji)) {
        M.ok = 0
    }
    else {
        if (diag0cnt(M.Ji) > 0) {
            M.ok = 0
        }
    }
    M.Qp = M.dc - M.S' * M.Ji * M.S
    return(M)
}

// ---------------------------------------------------------------------------
//  Generalized reduced-rank regression under rank r (switching algorithm):
//    alpha-step: vec(alpha') = (G'JG)^-1 G'S,  G = I_p # beta
//    beta-step : vec(beta)   = (H'JH)^-1 H'S,  H = alpha # I_p1
//  iterated from the Johansen eigenvectors V0 until the concentrated
//  log-likelihood changes by less than tol (BZ 2022 eqs 9-10; Hansen 2003).
//  r = 0: Pi = 0; r = p: unrestricted GLS (eqs 11-12).
//  Returns 1 if converged; Qr = sum_t e~_t' Sigma_t^-1 e~_t.
// ---------------------------------------------------------------------------

real scalar cva_grrr(struct cva_mom scalar M, real scalar r, real matrix V0,
                     real scalar tol, real scalar maxit, real matrix alpha,
                     real matrix beta, real matrix Pi, real matrix Psi,
                     real scalar Qr, real scalar iter)
{
    real scalar p, p1, ll, ll0, it, conv
    real matrix G, H
    real colvector th, vp, psi

    p    = M.p
    p1   = M.p1
    iter = 0
    conv = 1
    if (r <= 0) {
        vp    = J(p*p1, 1, 0)
        ll    = 0
        alpha = J(p, 0, .)
        beta  = J(p1, 0, .)
    }
    else if (r >= p) {
        vp    = M.Ji * M.S
        ll    = vp' * M.S - 0.5 * vp' * M.J * vp
        alpha = I(p)
        beta  = rowshape(vp', p)'
    }
    else {
        beta = V0[|1,1 \ p1,r|]
        beta = beta * matpowersym(beta' * beta, -0.5)
        ll0  = .
        for (it = 1; it <= maxit; it = it + 1) {
            G     = I(p) # beta
            th    = cva_sinv(G' * M.J * G) * (G' * M.S)
            alpha = rowshape(th', p)
            H     = alpha # I(p1)
            th    = cva_sinv(H' * M.J * H) * (H' * M.S)
            beta  = rowshape(th', r)'
            vp    = vec(beta * alpha')
            ll    = vp' * M.S - 0.5 * vp' * M.J * vp
            iter  = it
            if (ll0 < .) {
                if (abs(ll - ll0) < tol) {
                    break
                }
            }
            ll0  = ll
            beta = beta * matpowersym(beta' * beta, -0.5)
        }
        if (iter >= maxit) {
            conv = 0
        }
    }
    Qr = M.dc - 2*ll
    Pi = rowshape(vp', p)
    if (M.q > 0) {
        psi = M.WWi * (M.SW - M.JLW' * vp)
        Psi = rowshape(psi', p)
    }
    else {
        Psi = J(p, 0, .)
    }
    return(conv)
}

// ---------------------------------------------------------------------------
//  Johansen trace + adaptive LR for a list of ranks, with volatility (VBS)
//  and wild (WBS) bootstrap p-values (BZ 2022 Sec 4.2; BCDT 2023 (3.7)-(3.8)).
//  One bootstrap DGP per rank, used for both statistics (as in the authors'
//  code):  dgp = "adaptive" (GRRR restricted estimates, BZ eq 21 / Ox
//  TermStructure) or "johansen" (RRR restricted estimates, BCDT eq 3.7).
//  Wild residuals: wres = "unrestricted" (OLS residuals e_t of H(p), BZ) or
//  "restricted" (residuals of the DGP estimates, BCDT).
//  Sigma_t (Ai, Sh) is never re-estimated in the bootstrap.
//  res columns: 1 r, 2 eigenvalue, 3 trace, 4 asy p, 5 PLR-VBS p, 6 PLR-WBS p,
//  7 ALR, 8 ALR-VBS p, 9 ALR-WBS p, 10 GRRR iterations, 11 redrawn samples,
//  12 # explosive roots of the bootstrap DGP.  p-values: share of Q* > Q.
// ---------------------------------------------------------------------------

real matrix cva_rankcore(real matrix Y, real scalar k, real matrix D1, real matrix D2,
        string scalar dcase, real matrix Ai, real matrix Sh, real matrix EU,
        real colvector rr, real scalar dovbs, real scalar dowild,
        string scalar dgp, string scalar wres, real scalar B, real scalar tol,
        real scalar maxit, real scalar dots)
{
    struct cv_joh scalar Jd, Jb
    struct cva_mom scalar M, Mb
    real matrix Z0, Z1, Z2, Zb0, Zb1, Zb2, al, be, Pi, Psi, aJ, bJ, PsiJ, EJ
    real matrix PiB, PsiB, EW, eps, zz, Ys, Gm, res, a2, b2, P2, S2
    real colvector mods
    real scalar p, T, ntests, i, r, qt, lr, Qr, it, it2, conv, ll, m, b, a
    real scalar nrt, nra, fails, qb, lb, Qb, bad
    real rowvector ap

    cv_build(Y, k, D1, D2, Z0, Z1, Z2)
    Jd = cv_johansen(Z0, Z1, Z2)
    if (Jd.ok == 0) {
        errprintf("moment matrices are singular; check for collinear or constant series\n")
        exit(error(506))
    }
    p = Jd.p
    T = Jd.T
    M = cva_moments(Z0, Z1, Z2, Ai)
    if (M.ok == 0) {
        errprintf("GLS moment matrix is singular\n")
        exit(error(506))
    }
    ntests = rows(rr)
    res = J(ntests, 12, .)
    fails = 0
    for (i = 1; i <= ntests; i = i + 1) {
        r = rr[i]
        res[i, 1] = r
        res[i, 2] = Jd.lam[r+1]
        qt = cv_trace(Jd.lam, r, p, T)
        res[i, 3] = qt
        ap = cv_asyp(qt, p - r, dcase, 1)
        res[i, 4] = ap[1]
        conv = cva_grrr(M, r, Jd.V, tol, maxit, al, be, Pi, Psi, Qr, it)
        lr = Qr - M.Qp
        res[i, 7]  = lr
        res[i, 10] = it
        if (B <= 0) {
            continue
        }
        // ---- bootstrap DGP under H(r) ----
        cv_fitrank(Jd, r, aJ, bJ, PsiJ, EJ, ll)
        if (dgp == "johansen") {
            if (r > 0) {
                PiB = aJ * bJ'
            }
            else {
                PiB = J(p, Jd.p1, 0)
            }
            PsiB = PsiJ
            EW   = EJ
        }
        else {
            PiB  = Pi
            PsiB = Psi
            EW   = Z0 - Z1 * Pi'
            if (Jd.q > 0) {
                EW = EW - Z2 * Psi'
            }
        }
        if (wres != "restricted") {
            EW = EU
        }
        if (k > 1) {
            Gm = PsiB[|1,1 \ p,p*(k-1)|]
        }
        else {
            Gm = J(p, 0, .)
        }
        mods = cv_roots(PiB[|1,1 \ p,p|], Gm, k)
        res[i, 12] = sum(mods :> 1 + 1e-6)
        fails = 0
        for (m = 1; m <= 2; m = m + 1) {
            if (m == 1 & dovbs == 0) {
                continue
            }
            if (m == 2 & dowild == 0) {
                continue
            }
            nrt = 0
            nra = 0
            if (dots) {
                if (m == 1) {
                    printf("{txt}H0: r = %g (VBS) ", r)
                }
                else {
                    printf("{txt}H0: r = %g (WBS) ", r)
                }
                displayflush()
            }
            for (b = 1; b <= B; b = b + 1) {
                if (m == 1) {
                    zz  = rnormal(T, p, 0, 1)
                    eps = J(T, p, .)
                    for (a = 1; a <= p; a = a + 1) {
                        eps[., a] = rowsum(zz :* Sh[|1,(a-1)*p+1 \ T,a*p|])
                    }
                }
                else {
                    eps = EW :* rnormal(T, 1, 0, 1)
                }
                Ys = cv_simvecm(Y[|1,1 \ k,p|], PiB, PsiB, eps, D1, D2, k)
                cv_build(Ys, k, D1, D2, Zb0, Zb1, Zb2)
                Jb = cv_johansen(Zb0, Zb1, Zb2)
                bad = 0
                if (Jb.ok == 0) {
                    bad = 1
                }
                else {
                    if (hasmissing(Jb.lam)) {
                        bad = 1
                    }
                    else {
                        if (max(Jb.lam) >= 1) {
                            bad = 1
                        }
                    }
                }
                if (bad == 0) {
                    qb = cv_trace(Jb.lam, r, p, T)
                    Mb = cva_moments(Zb0, Zb1, Zb2, Ai)
                    if (Mb.ok == 0) {
                        bad = 1
                    }
                    else {
                        conv = cva_grrr(Mb, r, Jb.V, tol, maxit, a2, b2, P2, S2, Qb, it2)
                        lb = Qb - Mb.Qp
                        if (missing(lb) | missing(qb)) {
                            bad = 1
                        }
                    }
                }
                if (bad) {
                    fails = fails + 1
                    if (fails > 10*B) {
                        errprintf("bootstrap failed repeatedly (explosive or singular samples)\n")
                        exit(error(430))
                    }
                    b = b - 1
                    continue
                }
                if (qb > qt) {
                    nrt = nrt + 1
                }
                if (lb > lr) {
                    nra = nra + 1
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
            if (m == 1) {
                res[i, 5] = nrt / B
                res[i, 8] = nra / B
            }
            else {
                res[i, 6] = nrt / B
                res[i, 9] = nra / B
            }
        }
        res[i, 11] = fails
    }
    return(res)
}

// ---------------------------------------------------------------------------
//  Main entry point for -cointvol adaptive-
// ---------------------------------------------------------------------------

void cva_adaptive_main(string scalar vars, string scalar touse, real scalar k,
        string scalar dcase, real scalar bw, real scalar B, real scalar dovbs,
        real scalar dowild, string scalar dgp, real scalar level, real scalar dots,
        string scalar rlist, real scalar tol, real scalar maxit)
{
    struct cv_joh scalar Jd
    real matrix Y, D1, D2, Z0, Z1, Z2, aU, bU, PsiU, EU, E2, S2, Ai, Sh, res
    real colvector wd, rr
    real rowvector hv, sel
    real scalar T0, p, T, h, cvv, bad, ldet, llU, eta, ntests

    Y  = st_data(., tokens(vars), touse)
    T0 = rows(Y)
    cv_detmats(T0, dcase, D1, D2)
    cv_build(Y, k, D1, D2, Z0, Z1, Z2)
    Jd = cv_johansen(Z0, Z1, Z2)
    if (Jd.ok == 0) {
        errprintf("moment matrices are singular; check for collinear or constant series\n")
        exit(error(506))
    }
    p = Jd.p
    T = Jd.T
    eta = 1 - level/100
    // unrestricted OLS residuals e_t of H(p) (BZ 2022 Sec 4.1)
    cv_fitrank(Jd, p, aU, bU, PsiU, EU, llU)
    E2 = cva_e2(EU)
    if (bw > 0 & bw < .) {
        h   = bw
        cvv = cva_cvcrit(E2, h)
    }
    else {
        hv  = cva_bwcv(E2, 40)
        h   = hv[1]
        cvv = hv[2]
    }
    if (h >= .) {
        errprintf("cross-validation of the bandwidth failed\n")
        exit(error(430))
    }
    cva_smooth(E2, h, S2, wd)
    bad = cva_volmats(S2, p, Ai, Sh, ldet)
    if (bad > 0) {
        errprintf("estimated volatility matrix not positive definite at obs. %g; increase bw()\n", bad)
        exit(error(506))
    }
    rr = strtoreal(tokens(rlist))'
    ntests = rows(rr)
    res = cva_rankcore(Y, k, D1, D2, dcase, Ai, Sh, EU, rr, dovbs, dowild,
                       dgp, "unrestricted", B, tol, maxit, dots)
    // sequential selection (first non-rejection) when r = 0..p-1 were tested
    sel = J(1, 5, .)
    if (ntests == p) {
        if (rr == (0::p-1)) {
            sel[1] = cv_seqsel(res[., 4], p, eta)
            if (B > 0) {
                if (dovbs) {
                    sel[2] = cv_seqsel(res[., 5], p, eta)
                    sel[4] = cv_seqsel(res[., 8], p, eta)
                }
                if (dowild) {
                    sel[3] = cv_seqsel(res[., 6], p, eta)
                    sel[5] = cv_seqsel(res[., 9], p, eta)
                }
            }
        }
    }
    st_matrix("__cva_res", res)
    st_matrix("__cva_sel", sel)
    st_matrix("__cva_vol", cva_vech(S2, p))
    st_matrix("__cva_lam", Jd.lam')
    st_numscalar("__cva_T", T)
    st_numscalar("__cva_h", h)
    st_numscalar("__cva_cv", cvv)
    st_numscalar("__cva_ldet", ldet)
}

// ---------------------------------------------------------------------------
//  Sequential (bootstrap) Johansen trace tests with lag k: CDRT (2018)
//  Algorithm 1 (restricted H(r) estimates, recentred residuals, data initial
//  values, deterministics in the recursion); meth = plr (asymptotic only),
//  iid or wild.  res columns: 1 r, 2 trace, 3 asy p, 4 bootstrap p.
// ---------------------------------------------------------------------------

real matrix cva_plrseq(real matrix Y, real scalar k, real matrix D1, real matrix D2,
                       string scalar dcase, string scalar meth, string scalar mult,
                       real scalar B, real scalar dots)
{
    struct cv_joh scalar Jd, Jb
    real matrix Z0, Z1, Z2, al, bs, Psi, E, Pi, Eb, eps, Ys, res
    real scalar p, T, r, qt, qb, b, nrej, fails, ll, bad
    real rowvector ap

    cv_build(Y, k, D1, D2, Z0, Z1, Z2)
    Jd = cv_johansen(Z0, Z1, Z2)
    if (Jd.ok == 0) {
        errprintf("moment matrices are singular; check for collinear or constant series\n")
        exit(error(506))
    }
    p = Jd.p
    T = Jd.T
    res = J(p, 4, .)
    for (r = 0; r <= p-1; r = r + 1) {
        qt = cv_trace(Jd.lam, r, p, T)
        ap = cv_asyp(qt, p - r, dcase, 1)
        res[r+1, 1] = r
        res[r+1, 2] = qt
        res[r+1, 3] = ap[1]
        if (meth == "plr" | B <= 0) {
            continue
        }
        cv_fitrank(Jd, r, al, bs, Psi, E, ll)
        if (r > 0) {
            Pi = al * bs'
        }
        else {
            Pi = J(p, Jd.p1, 0)
        }
        Eb = E :- mean(E)
        nrej  = 0
        fails = 0
        if (dots) {
            printf("{txt}k = %g, H0: r = %g  ", k, r)
            displayflush()
        }
        for (b = 1; b <= B; b = b + 1) {
            if (meth == "iid") {
                eps = Eb[ceil(runiform(T, 1) :* T), .]
            }
            else {
                eps = Eb :* cv_mult(T, mult)
            }
            Ys = cv_simvecm(Y[|1,1 \ k,p|], Pi, Psi, eps, D1, D2, k)
            cv_build(Ys, k, D1, D2, Z0, Z1, Z2)
            Jb = cv_johansen(Z0, Z1, Z2)
            bad = 0
            if (Jb.ok == 0) {
                bad = 1
            }
            else {
                if (hasmissing(Jb.lam)) {
                    bad = 1
                }
                else {
                    if (max(Jb.lam) >= 1) {
                        bad = 1
                    }
                }
            }
            if (bad) {
                fails = fails + 1
                if (fails > 10*B) {
                    errprintf("bootstrap failed repeatedly (explosive or singular samples)\n")
                    exit(error(430))
                }
                b = b - 1
                continue
            }
            qb = cv_trace(Jb.lam, r, p, T)
            if (qb > qt) {
                nrej = nrej + 1
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
        res[r+1, 4] = nrej / B
    }
    return(res)
}

// ---------------------------------------------------------------------------
//  Main entry point for -cointvol select-
//  Common effective sample t = K+1..T0 for every (k, r).
//  Standard IC (CDRT 2018 eq 3.3):
//     T log|S00(k)| + T sum_{i<=r} log(1-lam_i(k)) + c_T pi(k,r)
//     pi(k,r) = r(2p - r + n1) + p n2 + p(p+1)/2 + p^2 (k-1)
//  Adaptive IC (BCDT 2023 eq 3.4, fn 1):
//     sum_t log|Sigma_t| + sum_t e'_(k,r),t Sigma_t^-1 e_(k,r),t + c_T pi_A(k,r)
//     pi_A(k,r) = r(2p - r + n1) + p n2 + p^2 (k-1)
//  (n1 / n2 = number of restricted / unrestricted deterministic terms)
//  SEL columns: 1 c_T, 2 k joint, 3 r joint, 4 k-hat seq, 5 r-hat IC(k-hat),
//               6 r-hat IC(1,r) (Cheng-Phillips), 7 r-hat test sequence
// ---------------------------------------------------------------------------

void cva_select_main(string scalar vars, string scalar touse, real scalar K,
        string scalar dcase, string scalar icl, real scalar adapt, real scalar bw,
        string scalar rankm, real scalar B, string scalar mult, real scalar level,
        real scalar dots, real scalar tol, real scalar maxit)
{
    struct cv_joh scalar Jk
    struct cva_mom scalar Mk
    real matrix Y, D1, D2, Yk, D1k, D2k, Z0, Z1, Z2, aU, bU, PsiU, EU, E2, S2
    real matrix Ai, Sh, BASE, PEN, IC, SEL, TST, res, al, be, Pi, Psi
    real colvector wd, icol
    real rowvector hv, kl, rts, irow
    real scalar T0, T, p, n1, n2, k, r, h, cvv, ldet, bad, llU, ci, ncr, cT
    real scalar jk, jr, best, ks, rs, rcp, conv, Qr, it, nk, j, eta, kk
    string rowvector crs

    Y   = st_data(., tokens(vars), touse)
    T0  = rows(Y)
    p   = cols(Y)
    T   = T0 - K
    eta = 1 - level/100
    cv_detmats(T0, dcase, D1, D2)
    n1 = cols(D1)
    n2 = cols(D2)
    BASE = J(K, p+1, .)
    PEN  = J(K, p+1, .)
    h    = .
    cvv  = .
    ldet = .
    Ai   = J(0, 0, .)
    Sh   = J(0, 0, .)

    if (adapt) {
        // Sigma_t from the unrestricted VAR(K) residuals (BCDT 2023, Sec 3.2)
        cva_subsample(Y, D1, D2, K, K, Yk, D1k, D2k)
        cv_build(Yk, K, D1k, D2k, Z0, Z1, Z2)
        Jk = cv_johansen(Z0, Z1, Z2)
        if (Jk.ok == 0) {
            errprintf("moment matrices are singular for k = %g\n", K)
            exit(error(506))
        }
        cv_fitrank(Jk, p, aU, bU, PsiU, EU, llU)
        E2 = cva_e2(EU)
        if (bw > 0 & bw < .) {
            h   = bw
            cvv = cva_cvcrit(E2, h)
        }
        else {
            hv  = cva_bwcv(E2, 40)
            h   = hv[1]
            cvv = hv[2]
        }
        if (h >= .) {
            errprintf("cross-validation of the bandwidth failed\n")
            exit(error(430))
        }
        cva_smooth(E2, h, S2, wd)
        bad = cva_volmats(S2, p, Ai, Sh, ldet)
        if (bad > 0) {
            errprintf("estimated volatility matrix not positive definite at obs. %g; increase bw()\n", bad)
            exit(error(506))
        }
    }

    for (k = 1; k <= K; k = k + 1) {
        cva_subsample(Y, D1, D2, K, k, Yk, D1k, D2k)
        cv_build(Yk, k, D1k, D2k, Z0, Z1, Z2)
        Jk = cv_johansen(Z0, Z1, Z2)
        if (Jk.ok == 0) {
            errprintf("moment matrices are singular for k = %g\n", k)
            exit(error(506))
        }
        if (adapt) {
            Mk = cva_moments(Z0, Z1, Z2, Ai)
            if (Mk.ok == 0) {
                errprintf("GLS moment matrix is singular for k = %g\n", k)
                exit(error(506))
            }
        }
        for (r = 0; r <= p; r = r + 1) {
            if (adapt) {
                conv = cva_grrr(Mk, r, Jk.V, tol, maxit, al, be, Pi, Psi, Qr, it)
                BASE[k, r+1] = ldet + Qr
                PEN[k, r+1]  = r*(2*p - r + n1) + p*n2 + p*p*(k-1)
            }
            else {
                BASE[k, r+1] = T * ln(det(Jk.S00))
                if (r > 0) {
                    BASE[k, r+1] = BASE[k, r+1] + T * sum(ln(1 :- Jk.lam[|1 \ r|]))
                }
                PEN[k, r+1] = r*(2*p - r + n1) + p*n2 + p*(p+1)/2 + p*p*(k-1)
            }
        }
    }

    crs = tokens(icl)
    ncr = cols(crs)
    SEL = J(ncr, 7, .)
    for (ci = 1; ci <= ncr; ci = ci + 1) {
        cT = 2
        if (crs[ci] == "bic") {
            cT = ln(T)
        }
        if (crs[ci] == "hqc") {
            cT = 2 * ln(ln(T))
        }
        IC = BASE + cT :* PEN
        st_matrix("__cva_IC" + strofreal(ci), IC)
        // joint argmin (CDRT 2018 eq 3.7; BCDT 2023 eq 3.4)
        jk   = .
        jr   = .
        best = .
        for (k = 1; k <= K; k = k + 1) {
            for (r = 0; r <= p; r = r + 1) {
                if (IC[k, r+1] < best) {
                    best = IC[k, r+1]
                    jk   = k
                    jr   = r
                }
            }
        }
        // sequential: k-hat from the unrestricted model (column r = p)
        icol = IC[., p+1]
        ks   = cva_argmin(icol)
        irow = IC[ks, .]
        rs   = cva_argmin(irow) - 1
        irow = IC[1, .]
        rcp  = cva_argmin(irow) - 1
        SEL[ci, 1] = cT
        SEL[ci, 2] = jk
        SEL[ci, 3] = jr
        SEL[ci, 4] = ks
        SEL[ci, 5] = rs
        SEL[ci, 6] = rcp
    }

    if (rankm == "plr" | rankm == "iid" | rankm == "wild" | rankm == "vbs") {
        kl = J(1, 0, .)
        for (ci = 1; ci <= ncr; ci = ci + 1) {
            if (anyof(kl, SEL[ci, 4]) == 0) {
                kl = kl, SEL[ci, 4]
            }
        }
        nk  = cols(kl)
        TST = J(p, 1 + 2*nk, .)
        TST[., 1] = (0::p-1)
        rts = J(1, nk, .)
        for (j = 1; j <= nk; j = j + 1) {
            kk = kl[j]
            cva_subsample(Y, D1, D2, K, kk, Yk, D1k, D2k)
            if (adapt) {
                res = cva_rankcore(Yk, kk, D1k, D2k, dcase, Ai, Sh, J(0, 0, .),
                                   (0::p-1), (rankm == "vbs"), (rankm == "wild"),
                                   "johansen", "restricted", B, tol, maxit, dots)
                TST[., 2*j] = res[., 7]
                if (rankm == "vbs") {
                    TST[., 2*j+1] = res[., 8]
                }
                else {
                    TST[., 2*j+1] = res[., 9]
                }
            }
            else {
                res = cva_plrseq(Yk, kk, D1k, D2k, dcase, rankm, mult, B, dots)
                TST[., 2*j] = res[., 2]
                if (rankm == "plr") {
                    TST[., 2*j+1] = res[., 3]
                }
                else {
                    TST[., 2*j+1] = res[., 4]
                }
            }
            rts[j] = cv_seqsel(TST[., 2*j+1], p, eta)
        }
        for (ci = 1; ci <= ncr; ci = ci + 1) {
            for (j = 1; j <= nk; j = j + 1) {
                if (kl[j] == SEL[ci, 4]) {
                    SEL[ci, 7] = rts[j]
                }
            }
        }
        st_matrix("__cva_tst", TST)
        st_matrix("__cva_kl", kl)
    }
    st_matrix("__cva_sel", SEL)
    st_numscalar("__cva_T", T)
    st_numscalar("__cva_h", h)
    st_numscalar("__cva_cv", cvv)
}

end
