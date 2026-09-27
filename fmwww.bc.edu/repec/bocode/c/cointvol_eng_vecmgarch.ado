*! cointvol_eng_vecmgarch 0.1.0  26sep2026
*! Mata engine of -cointvol vecmgarch-: joint Gaussian (Q)ML estimation of a cointegrated
*! VAR / VECM with multivariate conditional heteroskedasticity
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com) - github.com/merwanroudane
*!
*! Step -> source map (LLW = Li, Ling & Wong 2001; WLL = Wong, Li & Ling 2005;
*! SML = Sin, Mi & Ling 2024; BDV = Bauwens, Deprins & Vandeuren 1997)
*!   mean dX_t = alpha beta#'Z1_t + Psi Z2_t + e_t, c'beta = I_r        Lee (1994) eq (1); LLW eq (2.1);
*!                                                                     Seo (2007) eq (1); BDV eq (3)-(4)
*!   l_t = -.5[p log 2pi + log|H_t| + e_t'H_t^-1 e_t]                   LLW (4.2); WLL (4.2); Seo (6); SML (3.1)
*!   dbekk: H = C'C + A'ee'A + B'HB + sum_k D_k'D_k x_k^2, A,B diag     Lee (1994) eq (2)
*!   bekk : H = C'C + sum_i A_i'ee'A_i + sum_j G_j'HG_j                BDV (1997) eqs (5)-(7)
*!   ccc  : h_it = w_i + sum a_il e^2 + sum b_il h, V = D Gamma D         SML (2024) eq (2.3)
*!   eccc : h_t = w + A e~^2 + B h, A full, B diagonal, Gamma = I         WLL (2005) eq (2.2)
*!   darch: h_kt = g_k + sum_i s_ki e^2_{k,t-i}, Gamma = I                LLW (2001) eq (4.1)
*!   tri  : e = L u, s2_jt = w_j + psi_j e^2 + phi_j s2, Omega = L^-1 S L^-1'  Seo (2007) eqs (3)-(4)
*!   starting values: Johansen RRR / LS (core engine)                  Seo (2007) Sec 2.2; SML Sec 4.1
*!   two-step: variance on LS/RRR residuals, then mean given variance  LLW Secs 3-4; WLL Secs 3-4
*!   sandwich V = H^-1 (sum s_t s_t') H^-1                             Bollerslev & Wooldridge (1992); Seo Thm 2
*!   BEKK covariance stationarity rho(sum A#A + sum G#G) < 1           BDV (1997) eq (8)
*!   GARCH 4th moment rho(E A_t # A_t) < 1 (3a^2+2ab+b^2 < 1)          Bollerslev (1986); SML Ass. 2.4
*!   partial efficiency gain g_j                                       Seo (2007) eq (21)
*!
*! This file is -run- by cointvol_vecmgarch.ado, cointvol_vecmgarch_p.ado and
*! cointvol_vecmgarch_estat.ado.  It requires the core engine (cointvol_engine.ado).

program define cointvol_eng_vecmgarch
    version 14.0
end

version 14.0
capture mata: st_local("__cvgcore", cv_engine_version())
if _rc {
    capture program drop cointvol_engine
    quietly findfile cointvol_engine.ado
    quietly run `"`r(fn)'"'
}
capture mata: mata drop cvg_*()
capture mata: mata drop cvg_mod()

mata:

string scalar cvg_version()
{
    return("0.1.0")
}

// ---------------------------------------------------------------------------
//  Model structure
// ---------------------------------------------------------------------------

struct cvg_mod {
    real matrix    Z0, Z1, Z2, X2f, S0, Bfix
    real colvector fidx, idx
    real rowvector sref, thfix
    real scalar    n, p, p1, q, r, nx, xect, nbf, km, kv, k, qa, pg, uncon
    string scalar  vm
}

// ---------------------------------------------------------------------------
//  Small utilities
// ---------------------------------------------------------------------------

real scalar cvg_invlogit(real scalar x)
{
    real scalar y
    y = x
    if (y > 30) {
        y = 30
    }
    if (y < -30) {
        y = -30
    }
    return(1 / (1 + exp(-y)))
}

real scalar cvg_logit(real scalar u)
{
    real scalar v
    v = u
    if (v < 1e-10) {
        v = 1e-10
    }
    if (v > 1 - 1e-10) {
        v = 1 - 1e-10
    }
    return(ln(v / (1 - v)))
}

real scalar cvg_cexp(real scalar x)
{
    real scalar y
    y = x
    if (y > 50) {
        y = 50
    }
    if (y < -50) {
        y = -50
    }
    return(exp(y))
}

// upper-triangular p x p matrix from a row-major vector (i <= j)
real matrix cvg_uptri(real rowvector v, real scalar p)
{
    real matrix C
    real scalar i, j, pos
    C = J(p, p, 0)
    pos = 0
    for (i = 1; i <= p; i = i + 1) {
        for (j = i; j <= p; j = j + 1) {
            pos = pos + 1
            C[i, j] = v[pos]
        }
    }
    return(C)
}

real rowvector cvg_vuptri(real matrix C)
{
    real rowvector v
    real scalar i, j, p, pos
    p = rows(C)
    v = J(1, p*(p+1)/2, .)
    pos = 0
    for (i = 1; i <= p; i = i + 1) {
        for (j = i; j <= p; j = j + 1) {
            pos = pos + 1
            v[pos] = C[i, j]
        }
    }
    return(v)
}

// symmetric matrix from its lower triangle stored row-major (i >= j)
real matrix cvg_vech2sym(real rowvector v, real scalar p)
{
    real matrix S
    real scalar i, j, pos
    S = J(p, p, 0)
    pos = 0
    for (i = 1; i <= p; i = i + 1) {
        for (j = 1; j <= i; j = j + 1) {
            pos = pos + 1
            S[i, j] = v[pos]
            S[j, i] = v[pos]
        }
    }
    return(S)
}

real rowvector cvg_sym2vech(real matrix S)
{
    real rowvector v
    real scalar i, j, p, pos
    p = rows(S)
    v = J(1, p*(p+1)/2, .)
    pos = 0
    for (i = 1; i <= p; i = i + 1) {
        for (j = 1; j <= i; j = j + 1) {
            pos = pos + 1
            v[pos] = S[i, j]
        }
    }
    return(v)
}

// correlation matrix from its strictly-lower elements (row-major, i > j)
real matrix cvg_rhomat(real rowvector rho, real scalar p)
{
    real matrix G
    real scalar i, j, pos
    G = I(p)
    pos = 0
    for (i = 2; i <= p; i = i + 1) {
        for (j = 1; j <= i - 1; j = j + 1) {
            pos = pos + 1
            G[i, j] = rho[pos]
            G[j, i] = rho[pos]
        }
    }
    return(G)
}

// unit lower-triangular matrix from strictly-lower elements (row-major)
real matrix cvg_unitlow(real rowvector l, real scalar p)
{
    real matrix Lm
    real scalar i, j, pos
    Lm = I(p)
    pos = 0
    for (i = 2; i <= p; i = i + 1) {
        for (j = 1; j <= i - 1; j = j + 1) {
            pos = pos + 1
            Lm[i, j] = l[pos]
        }
    }
    return(Lm)
}

real rowvector cvg_lowvec(real matrix Lm)
{
    real rowvector l
    real scalar i, j, p, pos
    p = rows(Lm)
    l = J(1, p*(p-1)/2, .)
    pos = 0
    for (i = 2; i <= p; i = i + 1) {
        for (j = 1; j <= i - 1; j = j + 1) {
            pos = pos + 1
            l[pos] = Lm[i, j]
        }
    }
    return(l)
}

// Seo (2007) triangular factor: e = L u has diagonal covariance
real matrix cvg_L0(real matrix S)
{
    real matrix P, Q
    P = cholesky((S + S') / 2)
    if (hasmissing(P)) {
        return(I(rows(S)))
    }
    Q = P :/ diagonal(P)'
    return(solvelower(Q, I(rows(S))))
}

// n x p^2 matrix of vec(e_t e_t')' rows
real matrix cvg_outer(real matrix E)
{
    real matrix O
    real scalar i, j, p
    p = cols(E)
    O = J(rows(E), p*p, .)
    for (j = 1; j <= p; j = j + 1) {
        for (i = 1; i <= p; i = i + 1) {
            O[., (j-1)*p + i] = E[., i] :* E[., j]
        }
    }
    return(O)
}

// X lagged l times; the first l rows are filled with the presample row pre
real matrix cvg_lagl(real matrix X, real scalar l, real rowvector pre)
{
    real scalar n
    n = rows(X)
    if (l >= n) {
        return(J(n, 1, 1) # pre)
    }
    return((J(l, 1, 1) # pre) \ X[|1,1 \ n-l,cols(X)|])
}

// linear recursion h_t = u_t + phi h_{t-1}, h_0 given (vectorised in blocks)
real colvector cvg_filt(real colvector u, real scalar phi, real scalar h0)
{
    real scalar n, L, s, e, m, hp, lp
    real colvector h, pw, cs, jj
    n = rows(u)
    if (phi == 0) {
        return(u)
    }
    if (abs(phi) == 1) {
        L = n
    }
    else {
        L = floor(230 / abs(ln(abs(phi))))
    }
    if (L < 1) {
        L = 1
    }
    if (L > n) {
        L = n
    }
    lp = ln(abs(phi))
    h  = J(n, 1, .)
    hp = h0
    s  = 1
    while (s <= n) {
        e = s + L - 1
        if (e > n) {
            e = n
        }
        m  = e - s + 1
        jj = (1::m)
        pw = exp(jj :* lp)
        if (phi < 0) {
            pw = pw :* (1 :- 2 :* mod(jj, 2))
        }
        cs = runningsum(u[|s \ e|] :/ pw)
        h[|s \ e|] = pw :* (hp :+ cs)
        hp = h[e]
        s = e + 1
    }
    return(h)
}

// log|H_t| and e_t'H_t^-1 e_t for all t, H_t stored as vec rows (vectorised Cholesky)
void cvg_ldq(real matrix VH, real matrix E, real scalar p, real colvector ld, real colvector qd)
{
    real scalar n, i, j, k
    real matrix Lc, W
    real colvector s, d
    n  = rows(E)
    Lc = J(n, p*p, 0)
    ld = J(n, 1, 0)
    for (j = 1; j <= p; j = j + 1) {
        s = VH[., (j-1)*p + j]
        for (k = 1; k < j; k = k + 1) {
            s = s - Lc[., (k-1)*p + j] :^ 2
        }
        if (hasmissing(s)) {
            ld = J(n, 1, .)
            qd = J(n, 1, .)
            return
        }
        if (min(s) <= 0) {
            ld = J(n, 1, .)
            qd = J(n, 1, .)
            return
        }
        d = sqrt(s)
        Lc[., (j-1)*p + j] = d
        ld = ld + 2 :* ln(d)
        for (i = j + 1; i <= p; i = i + 1) {
            s = VH[., (j-1)*p + i]
            for (k = 1; k < j; k = k + 1) {
                s = s - Lc[., (k-1)*p + i] :* Lc[., (k-1)*p + j]
            }
            Lc[., (j-1)*p + i] = s :/ d
        }
    }
    W = J(n, p, 0)
    for (i = 1; i <= p; i = i + 1) {
        s = E[., i]
        for (k = 1; k < i; k = k + 1) {
            s = s - Lc[., (k-1)*p + i] :* W[., k]
        }
        W[., i] = s :/ Lc[., (i-1)*p + i]
    }
    qd = rowsum(W :^ 2)
}

real scalar cvg_kvar(string scalar vm, real scalar p, real scalar qa, real scalar pg, real scalar nx)
{
    real scalar np
    np = p*(p+1)/2
    if (vm == "none") {
        return(np)
    }
    if (vm == "dbekk") {
        return(np + 2*p + nx*np)
    }
    if (vm == "bekk") {
        return(np + (qa + pg)*p*p + nx*np)
    }
    if (vm == "cccgarch") {
        return(p*(1 + qa + pg) + p*(p-1)/2)
    }
    if (vm == "ecccgarch") {
        return(p*(p + 2))
    }
    if (vm == "darch") {
        return(p*(1 + qa))
    }
    if (vm == "trigarch") {
        return(p*(p-1)/2 + 3*p)
    }
    return(.)
}

// ---------------------------------------------------------------------------
//  Reparameterisations (theta <-> natural parameters)
// ---------------------------------------------------------------------------

// univariate GARCH block (omega, c_1..c_k):
//   constrained: persistence = .9999 invlogit(t2), shares = softmax(t3..t_{k+1}, 0),
//                omega = s2 (1 - persistence) exp(t1)
//   unconstrained: every element = exp(t)
real rowvector cvg_g_th2nat(real rowvector th, real scalar s2, real scalar uncon)
{
    real scalar k, pers, j
    real rowvector sh, out
    k   = cols(th) - 1
    out = J(1, k + 1, .)
    if (uncon) {
        for (j = 1; j <= k + 1; j = j + 1) {
            out[j] = cvg_cexp(th[j])
        }
        return(out)
    }
    pers = 0.9999 * cvg_invlogit(th[2])
    sh = J(1, k, 0)
    for (j = 1; j <= k - 1; j = j + 1) {
        sh[j] = th[2 + j]
    }
    sh = exp(sh :- max(sh))
    sh = sh :/ sum(sh)
    out[1] = s2 * (1 - pers) * cvg_cexp(th[1])
    for (j = 1; j <= k; j = j + 1) {
        out[1 + j] = pers * sh[j]
    }
    return(out)
}

real rowvector cvg_g_nat2th(real rowvector v, real scalar s2, real scalar uncon)
{
    real scalar k, pers, j, w
    real rowvector th, cm, sh
    k  = cols(v) - 1
    th = J(1, k + 1, 0)
    if (uncon) {
        for (j = 1; j <= k + 1; j = j + 1) {
            w = v[j]
            if (w < 1e-10) {
                w = 1e-10
            }
            th[j] = ln(w)
        }
        return(th)
    }
    cm = v[|2 \ k+1|]
    cm = cm :* (cm :> 1e-6) + 1e-6 :* (cm :<= 1e-6)
    pers = sum(cm)
    if (pers > 0.9990) {
        cm = cm :* (0.9990 / pers)
        pers = 0.9990
    }
    sh = cm :/ pers
    th[2] = cvg_logit(pers / 0.9999)
    for (j = 1; j <= k - 1; j = j + 1) {
        th[2 + j] = ln(sh[j] / sh[k])
    }
    w = v[1]
    if (w < 1e-12) {
        w = 1e-12
    }
    th[1] = ln(w / (s2 * (1 - pers)))
    return(th)
}

real rowvector cvg_corr_th2nat(real rowvector l, real scalar p)
{
    real matrix Lm, Mm, G
    real colvector d
    Lm = cvg_unitlow(l, p)
    Mm = Lm * Lm'
    d  = sqrt(diagonal(Mm))
    G  = Mm :/ (d * d')
    return(cvg_lowvec(G))
}

real rowvector cvg_corr_nat2th(real rowvector rho, real scalar p)
{
    real matrix G, R
    G = cvg_rhomat(rho, p)
    R = cholesky(G)
    if (hasmissing(R)) {
        G = 0.5 :* G + 0.5 :* I(p)
        R = cholesky(G)
    }
    return(cvg_lowvec(R :/ diagonal(R)))
}

real rowvector cvg_v_th2nat(struct cvg_mod scalar M, real rowvector tv)
{
    real scalar p, np, i, j, pos, pr, s, k
    real rowvector v, blk
    real matrix Lm
    p  = M.p
    np = p*(p+1)/2
    v  = tv
    if (M.vm == "none") {
        Lm = J(p, p, 0)
        pos = 0
        for (i = 1; i <= p; i = i + 1) {
            for (j = 1; j <= i; j = j + 1) {
                pos = pos + 1
                Lm[i, j] = tv[pos]
            }
        }
        v = cvg_sym2vech(Lm * Lm')
    }
    if (M.vm == "dbekk") {
        if (M.uncon == 0) {
            for (i = 1; i <= p; i = i + 1) {
                pr = 0.9999 * cvg_invlogit(tv[np + i])
                s  = cvg_invlogit(tv[np + p + i])
                v[np + i]     = sqrt(pr * s)
                v[np + p + i] = sqrt(pr * (1 - s))
            }
        }
    }
    if (M.vm == "cccgarch" | M.vm == "darch" | M.vm == "trigarch") {
        pos = 0
        if (M.vm == "trigarch") {
            pos = p*(p-1)/2
        }
        k = 1 + M.qa + M.pg
        if (M.vm == "darch") {
            k = 1 + M.qa
        }
        if (M.vm == "trigarch") {
            k = 3
        }
        for (i = 1; i <= p; i = i + 1) {
            blk = cvg_g_th2nat(tv[|pos+1 \ pos+k|], M.sref[i], M.uncon)
            v[|pos+1 \ pos+k|] = blk
            pos = pos + k
        }
        if (M.vm == "cccgarch") {
            v[|pos+1 \ pos+p*(p-1)/2|] = cvg_corr_th2nat(tv[|pos+1 \ pos+p*(p-1)/2|], p)
        }
    }
    if (M.vm == "ecccgarch") {
        pos = 0
        for (i = 1; i <= p; i = i + 1) {
            for (j = 1; j <= p + 1; j = j + 1) {
                v[pos + j] = cvg_cexp(tv[pos + j])
            }
            if (M.uncon) {
                v[pos + p + 2] = cvg_cexp(tv[pos + p + 2])
            }
            else {
                v[pos + p + 2] = 0.9999 * cvg_invlogit(tv[pos + p + 2])
            }
            pos = pos + p + 2
        }
    }
    return(v)
}

real rowvector cvg_v_nat2th(struct cvg_mod scalar M, real rowvector v)
{
    real scalar p, np, i, j, pos, pr, s, a, b, k, w
    real rowvector tv
    real matrix Lm, Sg
    p  = M.p
    np = p*(p+1)/2
    tv = v
    if (M.vm == "none") {
        Sg = cvg_vech2sym(v, p)
        Lm = cholesky(Sg)
        if (hasmissing(Lm)) {
            Lm = cholesky(Sg + 1e-6 :* I(p))
        }
        pos = 0
        for (i = 1; i <= p; i = i + 1) {
            for (j = 1; j <= i; j = j + 1) {
                pos = pos + 1
                tv[pos] = Lm[i, j]
            }
        }
    }
    if (M.vm == "dbekk") {
        if (M.uncon == 0) {
            for (i = 1; i <= p; i = i + 1) {
                a  = v[np + i]
                b  = v[np + p + i]
                pr = a*a + b*b
                if (pr < 1e-4) {
                    pr = 1e-4
                }
                if (pr > 0.9990) {
                    pr = 0.9990
                }
                s = a*a / (a*a + b*b + 1e-300)
                if (s < 1e-4) {
                    s = 1e-4
                }
                if (s > 1 - 1e-4) {
                    s = 1 - 1e-4
                }
                tv[np + i]     = cvg_logit(pr / 0.9999)
                tv[np + p + i] = cvg_logit(s)
            }
        }
    }
    if (M.vm == "cccgarch" | M.vm == "darch" | M.vm == "trigarch") {
        pos = 0
        if (M.vm == "trigarch") {
            pos = p*(p-1)/2
        }
        k = 1 + M.qa + M.pg
        if (M.vm == "darch") {
            k = 1 + M.qa
        }
        if (M.vm == "trigarch") {
            k = 3
        }
        for (i = 1; i <= p; i = i + 1) {
            tv[|pos+1 \ pos+k|] = cvg_g_nat2th(v[|pos+1 \ pos+k|], M.sref[i], M.uncon)
            pos = pos + k
        }
        if (M.vm == "cccgarch") {
            tv[|pos+1 \ pos+p*(p-1)/2|] = cvg_corr_nat2th(v[|pos+1 \ pos+p*(p-1)/2|], p)
        }
    }
    if (M.vm == "ecccgarch") {
        pos = 0
        for (i = 1; i <= p; i = i + 1) {
            for (j = 1; j <= p + 1; j = j + 1) {
                w = v[pos + j]
                if (w < 1e-8) {
                    w = 1e-8
                }
                tv[pos + j] = ln(w)
            }
            w = v[pos + p + 2]
            if (M.uncon) {
                if (w < 1e-8) {
                    w = 1e-8
                }
                tv[pos + p + 2] = ln(w)
            }
            else {
                if (w > 0.9990) {
                    w = 0.9990
                }
                tv[pos + p + 2] = cvg_logit(w / 0.9999)
            }
            pos = pos + p + 2
        }
    }
    return(tv)
}

real rowvector cvg_th2nat(struct cvg_mod scalar M, real rowvector th)
{
    real rowvector nat
    nat = th
    nat[|M.km+1 \ M.k|] = cvg_v_th2nat(M, th[|M.km+1 \ M.k|])
    return(nat)
}

real rowvector cvg_nat2th(struct cvg_mod scalar M, real rowvector nat)
{
    real rowvector th
    th = nat
    th[|M.km+1 \ M.k|] = cvg_v_nat2th(M, nat[|M.km+1 \ M.k|])
    return(th)
}

// ---------------------------------------------------------------------------
//  Mean equation
// ---------------------------------------------------------------------------

void cvg_mean(struct cvg_mod scalar M, real rowvector nat, real matrix bst,
              real matrix al, real matrix Psi)
{
    real scalar i, j, pos, nf
    bst = M.Bfix
    nf  = rows(M.fidx)
    pos = 0
    for (j = 1; j <= M.r; j = j + 1) {
        for (i = 1; i <= nf; i = i + 1) {
            pos = pos + 1
            bst[M.fidx[i], j] = nat[pos]
        }
    }
    al  = J(M.p, M.r, 0)
    Psi = J(M.p, M.q, 0)
    for (i = 1; i <= M.p; i = i + 1) {
        for (j = 1; j <= M.r; j = j + 1) {
            pos = pos + 1
            al[i, j] = nat[pos]
        }
        for (j = 1; j <= M.q; j = j + 1) {
            pos = pos + 1
            Psi[i, j] = nat[pos]
        }
    }
}

real matrix cvg_resid(struct cvg_mod scalar M, real matrix bst, real matrix al, real matrix Psi)
{
    real matrix E
    E = M.Z0
    if (M.r > 0) {
        E = E - (M.Z1 * bst) * al'
    }
    if (M.q > 0) {
        E = E - M.Z2 * Psi'
    }
    return(E)
}

// squared GARCH-X regressors (row t = x_{t-1}^2)
real matrix cvg_x2(struct cvg_mod scalar M, real matrix bst)
{
    real matrix Z
    if (M.nx == 0) {
        return(J(M.n, 0, .))
    }
    if (M.xect) {
        Z = M.Z1 * bst
        return(Z :* Z)
    }
    return(M.X2f)
}

// ---------------------------------------------------------------------------
//  Variance models: log-likelihood contributions (and vec H_t rows if wantH)
// ---------------------------------------------------------------------------

void cvg_vl_none(struct cvg_mod scalar M, real matrix E, real matrix X2, real rowvector v,
                 real colvector ll, real matrix VH, real scalar wantH)
{
    real matrix Sg, Si
    real scalar dt
    Sg = cvg_vech2sym(v, M.p)
    dt = det(Sg)
    if (dt <= 0 | dt >= .) {
        ll = J(M.n, 1, .)
        return
    }
    Si = invsym(Sg)
    ll = -0.5 :* (M.p*ln(2*pi()) + ln(dt) :+ rowsum((E * Si) :* E))
    if (wantH) {
        VH = J(M.n, 1, vec(Sg)')
    }
}

void cvg_vl_dbekk(struct cvg_mod scalar M, real matrix E, real matrix X2, real rowvector v,
                  real colvector ll, real matrix VH, real scalar wantH)
{
    real scalar n, p, np, i, j, k, kk, pos
    real matrix C, CC, DD, Dk, EE, H
    real colvector u, h, ld, qd
    real rowvector a, b
    n  = M.n
    p  = M.p
    np = p*(p+1)/2
    C  = cvg_uptri(v[|1 \ np|], p)
    CC = C' * C
    a  = v[|np+1 \ np+p|]
    b  = v[|np+p+1 \ np+2*p|]
    pos = np + 2*p
    DD = J(M.nx, p*p, 0)
    for (kk = 1; kk <= M.nx; kk = kk + 1) {
        Dk = cvg_uptri(v[|pos+1 \ pos+np|], p)
        DD[kk, .] = vec(Dk' * Dk)'
        pos = pos + np
    }
    EE = cvg_lagl(cvg_outer(E), 1, vec(M.S0)')
    H  = J(n, p*p, .)
    for (i = 1; i <= p; i = i + 1) {
        for (j = i; j <= p; j = j + 1) {
            k = (j-1)*p + i
            u = CC[i, j] :+ (a[i]*a[j]) :* EE[., k]
            if (M.nx > 0) {
                u = u + X2 * DD[., k]
            }
            h = cvg_filt(u, b[i]*b[j], M.S0[i, j])
            H[., k] = h
            H[., (i-1)*p + j] = h
        }
    }
    cvg_ldq(H, E, p, ld, qd)
    ll = -0.5 :* (p*ln(2*pi()) :+ ld + qd)
    if (wantH) {
        VH = H
    }
}

void cvg_vl_bekk(struct cvg_mod scalar M, real matrix E, real matrix X2, real rowvector v,
                 real colvector ll, real matrix VH, real scalar wantH)
{
    real scalar n, p, np, l, j, t, kk, pos, p2
    real matrix C, Om, Am, Gm, Dk, DD, U, EEo, H, G1
    real colvector ld, qd
    real rowvector s0v, h
    pointer(real matrix) rowvector GG
    n  = M.n
    p  = M.p
    p2 = p*p
    np = p*(p+1)/2
    C  = cvg_uptri(v[|1 \ np|], p)
    Om = C' * C
    pos = np
    s0v = vec(M.S0)'
    EEo = cvg_outer(E)
    U   = J(n, 1, vec(Om)')
    for (l = 1; l <= M.qa; l = l + 1) {
        Am = rowshape(v[|pos+1 \ pos+p2|], p)
        U  = U + cvg_lagl(EEo, l, s0v) * (Am # Am)
        pos = pos + p2
    }
    GG = J(1, M.pg, NULL)
    for (j = 1; j <= M.pg; j = j + 1) {
        Gm = rowshape(v[|pos+1 \ pos+p2|], p)
        GG[j] = &(Gm # Gm)
        pos = pos + p2
    }
    if (M.nx > 0) {
        DD = J(M.nx, p2, 0)
        for (kk = 1; kk <= M.nx; kk = kk + 1) {
            Dk = cvg_uptri(v[|pos+1 \ pos+np|], p)
            DD[kk, .] = vec(Dk' * Dk)'
            pos = pos + np
        }
        U = U + X2 * DD
    }
    if (M.pg == 0) {
        H = U
    }
    else if (M.pg == 1) {
        G1 = *GG[1]
        H  = J(n, p2, .)
        h  = s0v
        for (t = 1; t <= n; t = t + 1) {
            h = U[t, .] + h * G1
            H[t, .] = h
        }
    }
    else {
        H = J(n, p2, .)
        for (t = 1; t <= n; t = t + 1) {
            h = U[t, .]
            for (j = 1; j <= M.pg; j = j + 1) {
                if (t - j >= 1) {
                    h = h + H[t-j, .] * (*GG[j])
                }
                else {
                    h = h + s0v * (*GG[j])
                }
            }
            H[t, .] = h
        }
    }
    cvg_ldq(H, E, p, ld, qd)
    ll = -0.5 :* (p*ln(2*pi()) :+ ld + qd)
    if (wantH) {
        VH = H
    }
}

void cvg_vl_ccc(struct cvg_mod scalar M, real matrix E, real matrix X2, real rowvector v,
                real colvector ll, real matrix VH, real scalar wantH)
{
    real scalar n, p, i, j, l, t, pos, dG
    real matrix Aa, Bb, U, E2, H, Gam, Gi, Z
    real rowvector W, s0, h
    n  = M.n
    p  = M.p
    W  = J(1, p, .)
    Aa = J(M.qa, p, .)
    Bb = J(M.pg, p, .)
    pos = 0
    for (i = 1; i <= p; i = i + 1) {
        W[i] = v[pos + 1]
        for (l = 1; l <= M.qa; l = l + 1) {
            Aa[l, i] = v[pos + 1 + l]
        }
        for (l = 1; l <= M.pg; l = l + 1) {
            Bb[l, i] = v[pos + 1 + M.qa + l]
        }
        pos = pos + 1 + M.qa + M.pg
    }
    Gam = cvg_rhomat(v[|pos+1 \ pos+p*(p-1)/2|], p)
    dG  = det(Gam)
    if (dG <= 0 | dG >= .) {
        ll = J(n, 1, .)
        return
    }
    s0 = diagonal(M.S0)'
    E2 = E :* E
    U  = J(n, 1, W)
    for (l = 1; l <= M.qa; l = l + 1) {
        U = U + cvg_lagl(E2, l, s0) :* Aa[l, .]
    }
    if (M.pg == 0) {
        H = U
    }
    else if (M.pg == 1) {
        H = J(n, p, .)
        for (i = 1; i <= p; i = i + 1) {
            H[., i] = cvg_filt(U[., i], Bb[1, i], s0[i])
        }
    }
    else {
        H = J(n, p, .)
        for (t = 1; t <= n; t = t + 1) {
            h = U[t, .]
            for (l = 1; l <= M.pg; l = l + 1) {
                if (t - l >= 1) {
                    h = h + Bb[l, .] :* H[t-l, .]
                }
                else {
                    h = h + Bb[l, .] :* s0
                }
            }
            H[t, .] = h
        }
    }
    if (hasmissing(H)) {
        ll = J(n, 1, .)
        return
    }
    if (min(H) <= 0) {
        ll = J(n, 1, .)
        return
    }
    Z  = E :/ sqrt(H)
    Gi = invsym(Gam)
    ll = -0.5 :* (p*ln(2*pi()) :+ rowsum(ln(H)) :+ ln(dG) :+ rowsum((Z * Gi) :* Z))
    if (wantH) {
        VH = J(n, p*p, .)
        for (j = 1; j <= p; j = j + 1) {
            for (i = 1; i <= p; i = i + 1) {
                VH[., (j-1)*p + i] = Gam[i, j] :* sqrt(H[., i] :* H[., j])
            }
        }
    }
}

void cvg_vl_eccc(struct cvg_mod scalar M, real matrix E, real matrix X2, real rowvector v,
                 real colvector ll, real matrix VH, real scalar wantH)
{
    real scalar n, p, i, j, pos
    real matrix Am, U, E2, H
    real rowvector W, b, s0
    n  = M.n
    p  = M.p
    W  = J(1, p, .)
    b  = J(1, p, .)
    Am = J(p, p, .)
    pos = 0
    for (i = 1; i <= p; i = i + 1) {
        W[i] = v[pos + 1]
        for (j = 1; j <= p; j = j + 1) {
            Am[i, j] = v[pos + 1 + j]
        }
        b[i] = v[pos + p + 2]
        pos = pos + p + 2
    }
    s0 = diagonal(M.S0)'
    E2 = E :* E
    U  = J(n, 1, W) + cvg_lagl(E2, 1, s0) * Am'
    H  = J(n, p, .)
    for (i = 1; i <= p; i = i + 1) {
        H[., i] = cvg_filt(U[., i], b[i], s0[i])
    }
    if (hasmissing(H)) {
        ll = J(n, 1, .)
        return
    }
    if (min(H) <= 0) {
        ll = J(n, 1, .)
        return
    }
    ll = -0.5 :* (p*ln(2*pi()) :+ rowsum(ln(H)) :+ rowsum(E2 :/ H))
    if (wantH) {
        VH = J(n, p*p, 0)
        for (i = 1; i <= p; i = i + 1) {
            VH[., (i-1)*p + i] = H[., i]
        }
    }
}

void cvg_vl_darch(struct cvg_mod scalar M, real matrix E, real matrix X2, real rowvector v,
                  real colvector ll, real matrix VH, real scalar wantH)
{
    real scalar n, p, i, l, pos
    real matrix Aa, E2, H
    real rowvector W, s0
    n  = M.n
    p  = M.p
    W  = J(1, p, .)
    Aa = J(M.qa, p, .)
    pos = 0
    for (i = 1; i <= p; i = i + 1) {
        W[i] = v[pos + 1]
        for (l = 1; l <= M.qa; l = l + 1) {
            Aa[l, i] = v[pos + 1 + l]
        }
        pos = pos + 1 + M.qa
    }
    s0 = diagonal(M.S0)'
    E2 = E :* E
    H  = J(n, 1, W)
    for (l = 1; l <= M.qa; l = l + 1) {
        H = H + cvg_lagl(E2, l, s0) :* Aa[l, .]
    }
    if (hasmissing(H)) {
        ll = J(n, 1, .)
        return
    }
    if (min(H) <= 0) {
        ll = J(n, 1, .)
        return
    }
    ll = -0.5 :* (p*ln(2*pi()) :+ rowsum(ln(H)) :+ rowsum(E2 :/ H))
    if (wantH) {
        VH = J(n, p*p, 0)
        for (i = 1; i <= p; i = i + 1) {
            VH[., (i-1)*p + i] = H[., i]
        }
    }
}

void cvg_vl_tri(struct cvg_mod scalar M, real matrix E, real matrix X2, real rowvector v,
                real colvector ll, real matrix VH, real scalar wantH)
{
    real scalar n, p, i, j, pos, nl
    real matrix Lm, Li, Eo, E2, U, Sg
    real rowvector W, ps, ph, so
    n  = M.n
    p  = M.p
    nl = p*(p-1)/2
    Lm = cvg_unitlow(v[|1 \ nl|], p)
    W  = J(1, p, .)
    ps = J(1, p, .)
    ph = J(1, p, .)
    pos = nl
    for (j = 1; j <= p; j = j + 1) {
        W[j]  = v[pos + 1]
        ps[j] = v[pos + 2]
        ph[j] = v[pos + 3]
        pos = pos + 3
    }
    Eo = E * Lm'
    E2 = Eo :* Eo
    so = diagonal(Lm * M.S0 * Lm')'
    U  = J(n, 1, W) + cvg_lagl(E2, 1, so) :* ps
    Sg = J(n, p, .)
    for (j = 1; j <= p; j = j + 1) {
        Sg[., j] = cvg_filt(U[., j], ph[j], so[j])
    }
    if (hasmissing(Sg)) {
        ll = J(n, 1, .)
        return
    }
    if (min(Sg) <= 0) {
        ll = J(n, 1, .)
        return
    }
    ll = -0.5 :* (p*ln(2*pi()) :+ rowsum(ln(Sg)) :+ rowsum(E2 :/ Sg))
    if (wantH) {
        Li = solvelower(Lm, I(p))
        VH = J(n, p*p, .)
        for (j = 1; j <= p; j = j + 1) {
            for (i = 1; i <= p; i = i + 1) {
                VH[., (j-1)*p + i] = Sg * (Li[i, .] :* Li[j, .])'
            }
        }
    }
}

void cvg_varll(struct cvg_mod scalar M, real matrix E, real matrix X2, real rowvector v,
               real colvector ll, real matrix VH, real scalar wantH)
{
    if (M.vm == "none") {
        cvg_vl_none(M, E, X2, v, ll, VH, wantH)
    }
    else if (M.vm == "dbekk") {
        cvg_vl_dbekk(M, E, X2, v, ll, VH, wantH)
    }
    else if (M.vm == "bekk") {
        cvg_vl_bekk(M, E, X2, v, ll, VH, wantH)
    }
    else if (M.vm == "cccgarch") {
        cvg_vl_ccc(M, E, X2, v, ll, VH, wantH)
    }
    else if (M.vm == "ecccgarch") {
        cvg_vl_eccc(M, E, X2, v, ll, VH, wantH)
    }
    else if (M.vm == "darch") {
        cvg_vl_darch(M, E, X2, v, ll, VH, wantH)
    }
    else {
        cvg_vl_tri(M, E, X2, v, ll, VH, wantH)
    }
}

// observation log likelihood at the natural parameter vector nat
real colvector cvg_llt(struct cvg_mod scalar M, real rowvector nat)
{
    real matrix bst, al, Psi, E, X2, VH
    real colvector ll
    cvg_mean(M, nat, bst, al, Psi)
    E  = cvg_resid(M, bst, al, Psi)
    X2 = cvg_x2(M, bst)
    cvg_varll(M, E, X2, nat[|M.km+1 \ M.k|], ll, VH, 0)
    return(ll)
}

real scalar cvg_sum(struct cvg_mod scalar M, real rowvector nat)
{
    real colvector ll
    ll = cvg_llt(M, nat)
    if (hasmissing(ll)) {
        return(.)
    }
    return(quadsum(ll))
}

// residuals, vec H_t rows and log likelihood contributions
void cvg_fit(struct cvg_mod scalar M, real rowvector nat, real matrix E, real matrix VH,
             real colvector ll)
{
    real matrix bst, al, Psi, X2
    cvg_mean(M, nat, bst, al, Psi)
    E  = cvg_resid(M, bst, al, Psi)
    X2 = cvg_x2(M, bst)
    cvg_varll(M, E, X2, nat[|M.km+1 \ M.k|], ll, VH, 1)
}

// ---------------------------------------------------------------------------
//  Optimisation (Mata optimize(), evaluator type v0)
// ---------------------------------------------------------------------------

void cvg_eval(real scalar todo, real rowvector tsub, struct cvg_mod scalar M,
              real colvector v, real matrix g, real matrix H)
{
    real rowvector th
    th = M.thfix
    th[M.idx'] = tsub
    v = cvg_llt(M, cvg_th2nat(M, th))
    // an infeasible point gets a very low finite value so that it is always rejected
    if (hasmissing(v)) {
        v = J(M.n, 1, -1e10)
    }
}

real scalar cvg_opt(struct cvg_mod scalar M, real rowvector th0, real colvector idx,
                    string scalar tech, real scalar maxit, real scalar trace,
                    real rowvector th, real scalar ll, real scalar conv, real scalar iter)
{
    transmorphic S
    real scalar rc
    M.thfix = th0
    M.idx   = idx
    th   = th0
    ll   = .
    conv = 0
    iter = .
    S = optimize_init()
    optimize_init_evaluator(S, &cvg_eval())
    optimize_init_evaluatortype(S, "v0")
    optimize_init_which(S, "max")
    optimize_init_params(S, th0[idx'])
    optimize_init_argument(S, 1, M)
    optimize_init_technique(S, tech)
    optimize_init_singularHmethod(S, "hybrid")
    if (trace) {
        optimize_init_tracelevel(S, "value")
    }
    else {
        optimize_init_tracelevel(S, "none")
    }
    optimize_init_conv_warning(S, "off")
    optimize_init_conv_maxiter(S, maxit)
    rc = _optimize(S)
    if (rc == 0) {
        th[idx'] = optimize_result_params(S)
        ll   = optimize_result_value(S)
        conv = optimize_result_converged(S)
        iter = optimize_result_iterations(S)
        if (ll <= -1e9 * M.n) {
            ll   = .
            conv = 0
        }
    }
    return(rc)
}

// numerical scores (n x K) and Hessian (K x K) of the log likelihood with respect to
// the natural (reported) parameters
void cvg_numderiv(struct cvg_mod scalar M, real rowvector nat, real scalar wantH,
                  real matrix G, real matrix Hs)
{
    real scalar K, j, l, f0, fpp, fpm, fmp, fmm, hj, tries
    real rowvector h, x, fp1, fm1
    real colvector fp, fm
    K = cols(nat)
    G = J(M.n, K, .)
    for (j = 1; j <= K; j = j + 1) {
        hj = 1e-5 * (abs(nat[j]) + 1e-2)
        for (tries = 1; tries <= 3; tries = tries + 1) {
            x = nat
            x[j] = nat[j] + hj
            fp = cvg_llt(M, x)
            x[j] = nat[j] - hj
            fm = cvg_llt(M, x)
            if (hasmissing(fp) == 0 & hasmissing(fm) == 0) {
                G[., j] = (fp - fm) :/ (2*hj)
                break
            }
            hj = hj / 10
        }
    }
    Hs = J(0, 0, .)
    if (wantH == 0) {
        return
    }
    h   = 1e-4 :* (abs(nat) :+ 1e-2)
    f0  = cvg_sum(M, nat)
    fp1 = J(1, K, .)
    fm1 = J(1, K, .)
    for (j = 1; j <= K; j = j + 1) {
        x = nat
        x[j] = nat[j] + h[j]
        fp1[j] = cvg_sum(M, x)
        x[j] = nat[j] - h[j]
        fm1[j] = cvg_sum(M, x)
    }
    Hs = J(K, K, .)
    for (j = 1; j <= K; j = j + 1) {
        Hs[j, j] = (fp1[j] - 2*f0 + fm1[j]) / (h[j]*h[j])
        for (l = j + 1; l <= K; l = l + 1) {
            x = nat
            x[j] = nat[j] + h[j]
            x[l] = nat[l] + h[l]
            fpp = cvg_sum(M, x)
            x[l] = nat[l] - h[l]
            fpm = cvg_sum(M, x)
            x[j] = nat[j] - h[j]
            fmm = cvg_sum(M, x)
            x[l] = nat[l] + h[l]
            fmp = cvg_sum(M, x)
            Hs[j, l] = (fpp - fpm - fmp + fmm) / (4*h[j]*h[l])
            Hs[l, j] = Hs[j, l]
        }
    }
}

// ---------------------------------------------------------------------------
//  Starting values of the variance parameters (natural scale, scaled data)
//  lev = 0 default, lev = 1 conservative (lower persistence)
// ---------------------------------------------------------------------------

real rowvector cvg_wts(real scalar m)
{
    real rowvector w
    real scalar j
    w = J(1, m, .)
    for (j = 1; j <= m; j = j + 1) {
        w[j] = m + 1 - j
    }
    return(w :/ sum(w))
}

real rowvector cvg_vstart(struct cvg_mod scalar M, real matrix bst, real scalar lev)
{
    real scalar p, np, i, j, l, kk, a2, b2, xm
    real matrix S0, X2, Dm, DDs, Dk, CC, C, Lm, Gm
    real rowvector v, x2m, wa, wg, blk, s
    p  = M.p
    np = p*(p+1)/2
    S0 = M.S0
    a2 = 0.10
    b2 = 0.85
    if (lev == 1) {
        a2 = 0.10
        b2 = 0.50
    }
    if (M.vm == "none") {
        return(cvg_sym2vech(S0))
    }
    if (M.vm == "dbekk" | M.vm == "bekk") {
        X2  = cvg_x2(M, bst)
        Dm  = J(M.nx, np, 0)
        DDs = J(p, p, 0)
        for (kk = 1; kk <= M.nx; kk = kk + 1) {
            xm = mean(X2[., kk])
            if (xm < 1e-8) {
                xm = 1e-8
            }
            Dk = cholesky((0.01 / M.nx) :* S0 :/ xm)'
            if (hasmissing(Dk)) {
                Dk = sqrt((0.01 / M.nx) / xm) :* diag(sqrt(diagonal(S0)))
            }
            Dm[kk, .] = cvg_vuptri(Dk)
            DDs = DDs + (Dk' * Dk) :* xm
        }
        CC = S0 :* (1 - a2 - b2) - DDs
        CC = (CC + CC') / 2
        if (min(symeigenvalues(CC)) <= 1e-10 * max(diagonal(S0))) {
            CC = 0.02 :* S0
        }
        C = cholesky(CC)'
        if (M.vm == "dbekk") {
            v = cvg_vuptri(C), J(1, p, sqrt(a2)), J(1, p, sqrt(b2))
        }
        else {
            v  = cvg_vuptri(C)
            wa = cvg_wts(M.qa)
            for (l = 1; l <= M.qa; l = l + 1) {
                Gm = sqrt(a2 * wa[l]) :* I(p)
                v = v, vec(Gm')'
            }
            if (M.pg > 0) {
                wg = cvg_wts(M.pg)
                for (l = 1; l <= M.pg; l = l + 1) {
                    Gm = sqrt(b2 * wg[l]) :* I(p)
                    v = v, vec(Gm')'
                }
            }
        }
        if (M.nx > 0) {
            v = v, vec(Dm')'
        }
        return(v)
    }
    if (M.vm == "cccgarch") {
        v = J(1, 0, .)
        if (M.pg == 0) {
            a2 = 0.30
            b2 = 0
        }
        else {
            a2 = 0.08
            b2 = 0.88
            if (lev == 1) {
                b2 = 0.50
            }
        }
        wa = cvg_wts(M.qa)
        for (i = 1; i <= p; i = i + 1) {
            blk = S0[i, i] * (1 - a2 - b2), a2 :* wa
            if (M.pg > 0) {
                wg = cvg_wts(M.pg)
                blk = blk, b2 :* wg
            }
            v = v, blk
        }
        s = sqrt(diagonal(S0))
        v = v, cvg_lowvec(S0 :/ (s * s'))
        return(v)
    }
    if (M.vm == "ecccgarch") {
        v = J(1, 0, .)
        b2 = 0.88
        if (lev == 1) {
            b2 = 0.50
        }
        for (i = 1; i <= p; i = i + 1) {
            blk = J(1, p + 2, 0.01)
            blk[1 + i] = 0.08
            blk[p + 2] = b2
            blk[1] = S0[i, i] * (1 - 0.08 - b2)
            for (j = 1; j <= p; j = j + 1) {
                if (j != i) {
                    blk[1] = blk[1] - 0.01 * S0[j, j]
                }
            }
            if (blk[1] < 0.01 * S0[i, i]) {
                blk[1] = 0.01 * S0[i, i]
            }
            v = v, blk
        }
        return(v)
    }
    if (M.vm == "darch") {
        v  = J(1, 0, .)
        wa = cvg_wts(M.qa)
        for (i = 1; i <= p; i = i + 1) {
            v = v, (S0[i, i] * 0.7, 0.3 :* wa)
        }
        return(v)
    }
    // trigarch
    Lm = cvg_L0(S0)
    v  = cvg_lowvec(Lm)
    b2 = 0.88
    if (lev == 1) {
        b2 = 0.50
    }
    for (j = 1; j <= p; j = j + 1) {
        v = v, (M.sref[j] * (1 - 0.08 - b2), 0.08, b2)
    }
    return(v)
}

// map a diagonal-BEKK fit to starting values of a full BEKK(qa, pg)
real rowvector cvg_d2bekk(struct cvg_mod scalar M, real rowvector dv)
{
    real scalar p, np, l
    real rowvector a, b, v, wa, wg
    real matrix Gm
    p  = M.p
    np = p*(p+1)/2
    a  = dv[|np+1 \ np+p|]
    b  = dv[|np+p+1 \ np+2*p|]
    v  = dv[|1 \ np|]
    if (M.pg == 0) {
        a = sqrt(a :^ 2 :+ b :^ 2)
    }
    wa = cvg_wts(M.qa)
    for (l = 1; l <= M.qa; l = l + 1) {
        Gm = diag(a :* sqrt(wa[l]))
        v = v, vec(Gm')'
    }
    if (M.pg > 0) {
        wg = cvg_wts(M.pg)
        for (l = 1; l <= M.pg; l = l + 1) {
            Gm = diag(b :* sqrt(wg[l]))
            v = v, vec(Gm')'
        }
    }
    if (M.nx > 0) {
        v = v, dv[|np+2*p+1 \ cols(dv)|]
    }
    return(v)
}

// sign normalisation of BEKK-type parameters (does not change the likelihood)
real rowvector cvg_signnorm(struct cvg_mod scalar M, real rowvector nat)
{
    real scalar p, np, p2, pos, i, l, kk
    real rowvector v, out
    real matrix C, Am
    if (M.vm != "dbekk" & M.vm != "bekk") {
        return(nat)
    }
    p   = M.p
    np  = p*(p+1)/2
    p2  = p*p
    v   = nat[|M.km+1 \ M.k|]
    C   = cvg_uptri(v[|1 \ np|], p)
    for (i = 1; i <= p; i = i + 1) {
        if (C[i, i] < 0) {
            C[i, .] = -C[i, .]
        }
    }
    v[|1 \ np|] = cvg_vuptri(C)
    pos = np
    if (M.vm == "dbekk") {
        if (v[np + 1] < 0) {
            v[|np+1 \ np+p|] = -v[|np+1 \ np+p|]
        }
        if (v[np + p + 1] < 0) {
            v[|np+p+1 \ np+2*p|] = -v[|np+p+1 \ np+2*p|]
        }
        pos = np + 2*p
    }
    else {
        for (l = 1; l <= M.qa + M.pg; l = l + 1) {
            Am = rowshape(v[|pos+1 \ pos+p2|], p)
            if (Am[1, 1] < 0) {
                Am = -Am
            }
            v[|pos+1 \ pos+p2|] = vec(Am')'
            pos = pos + p2
        }
    }
    for (kk = 1; kk <= M.nx; kk = kk + 1) {
        C = cvg_uptri(v[|pos+1 \ pos+np|], p)
        for (i = 1; i <= p; i = i + 1) {
            if (C[i, i] < 0) {
                C[i, .] = -C[i, .]
            }
        }
        v[|pos+1 \ pos+np|] = cvg_vuptri(C)
        pos = pos + np
    }
    out = nat
    out[|M.km+1 \ M.k|] = v
    return(out)
}

// multiplier: reported (original units) parameter = scaled parameter x mult
real rowvector cvg_mult(struct cvg_mod scalar M, real scalar c, real rowvector cx,
                        real scalar full, real scalar kl)
{
    real rowvector mu
    real scalar pos, i, j, l, kk, p, np, nf, c2
    p   = M.p
    np  = p*(p+1)/2
    nf  = rows(M.fidx)
    c2  = c*c
    mu  = J(1, M.k, 1)
    pos = 0
    for (j = 1; j <= M.r; j = j + 1) {
        for (i = 1; i <= nf; i = i + 1) {
            pos = pos + 1
            if (M.fidx[i] > p) {
                mu[pos] = 1 / c
            }
        }
    }
    for (i = 1; i <= p; i = i + 1) {
        for (j = 1; j <= M.r; j = j + 1) {
            pos = pos + 1
            if (full & j > p) {
                mu[pos] = 1 / c
            }
        }
        for (j = 1; j <= M.q; j = j + 1) {
            pos = pos + 1
            if (j > p*(kl-1)) {
                mu[pos] = 1 / c
            }
        }
    }
    if (M.vm == "none") {
        for (j = 1; j <= np; j = j + 1) {
            mu[pos + j] = 1 / c2
        }
    }
    if (M.vm == "dbekk" | M.vm == "bekk") {
        for (j = 1; j <= np; j = j + 1) {
            mu[pos + j] = 1 / c
        }
        pos = pos + np
        if (M.vm == "dbekk") {
            pos = pos + 2*p
        }
        else {
            pos = pos + (M.qa + M.pg)*p*p
        }
        for (kk = 1; kk <= M.nx; kk = kk + 1) {
            for (j = 1; j <= np; j = j + 1) {
                if (M.xect) {
                    mu[pos + j] = 1
                }
                else {
                    mu[pos + j] = cx[kk] / c
                }
            }
            pos = pos + np
        }
    }
    if (M.vm == "cccgarch") {
        for (i = 1; i <= p; i = i + 1) {
            mu[pos + 1] = 1 / c2
            pos = pos + 1 + M.qa + M.pg
        }
    }
    if (M.vm == "ecccgarch") {
        for (i = 1; i <= p; i = i + 1) {
            mu[pos + 1] = 1 / c2
            pos = pos + p + 2
        }
    }
    if (M.vm == "darch") {
        for (i = 1; i <= p; i = i + 1) {
            mu[pos + 1] = 1 / c2
            pos = pos + 1 + M.qa
        }
    }
    if (M.vm == "trigarch") {
        pos = pos + p*(p-1)/2
        for (l = 1; l <= p; l = l + 1) {
            mu[pos + 1] = 1 / c2
            pos = pos + 3
        }
    }
    return(mu)
}

// ---------------------------------------------------------------------------
//  Coefficient names (equation, name)
// ---------------------------------------------------------------------------

string matrix cvg_stripe(struct cvg_mod scalar M, string rowvector vn, string scalar det,
                         real scalar kl, real scalar full)
{
    string matrix S
    string rowvector d1n, d2n, z1n, z2n
    string scalar eq
    real scalar p, i, j, l, kk, pos, nf
    p   = M.p
    nf  = rows(M.fidx)
    d1n = J(1, 0, "")
    d2n = J(1, 0, "")
    if (det == "rconstant") {
        d1n = "_cons"
    }
    if (det == "rtrend") {
        d1n = "_trend"
        d2n = "_cons"
    }
    if (det == "constant") {
        d2n = "_cons"
    }
    if (det == "trend") {
        d2n = ("_cons", "_trend")
    }
    z1n = vn, d1n
    z2n = J(1, 0, "")
    for (l = 1; l <= kl - 1; l = l + 1) {
        for (i = 1; i <= p; i = i + 1) {
            z2n = z2n, ("L" + strofreal(l) + "D_" + vn[i])
        }
    }
    z2n = z2n, d2n
    S = J(M.k, 2, "")
    pos = 0
    for (j = 1; j <= M.r; j = j + 1) {
        for (i = 1; i <= nf; i = i + 1) {
            pos = pos + 1
            S[pos, 1] = "_ce" + strofreal(j)
            S[pos, 2] = z1n[M.fidx[i]]
        }
    }
    for (i = 1; i <= p; i = i + 1) {
        for (j = 1; j <= M.r; j = j + 1) {
            pos = pos + 1
            S[pos, 1] = "D_" + vn[i]
            if (full) {
                if (j <= p) {
                    S[pos, 2] = "L_" + vn[j]
                }
                else {
                    S[pos, 2] = "L" + z1n[j]
                }
            }
            else {
                S[pos, 2] = "_ce" + strofreal(j)
            }
        }
        for (j = 1; j <= M.q; j = j + 1) {
            pos = pos + 1
            S[pos, 1] = "D_" + vn[i]
            S[pos, 2] = z2n[j]
        }
    }
    if (M.vm == "none") {
        for (i = 1; i <= p; i = i + 1) {
            for (j = 1; j <= i; j = j + 1) {
                pos = pos + 1
                S[pos, 1] = "Sigma"
                S[pos, 2] = "s" + strofreal(i) + "_" + strofreal(j)
            }
        }
    }
    if (M.vm == "dbekk" | M.vm == "bekk") {
        for (i = 1; i <= p; i = i + 1) {
            for (j = i; j <= p; j = j + 1) {
                pos = pos + 1
                S[pos, 1] = "C"
                S[pos, 2] = "c" + strofreal(i) + "_" + strofreal(j)
            }
        }
        if (M.vm == "dbekk") {
            for (i = 1; i <= p; i = i + 1) {
                pos = pos + 1
                S[pos, 1] = "A"
                S[pos, 2] = "a" + strofreal(i)
            }
            for (i = 1; i <= p; i = i + 1) {
                pos = pos + 1
                S[pos, 1] = "B"
                S[pos, 2] = "b" + strofreal(i)
            }
        }
        else {
            for (l = 1; l <= M.qa; l = l + 1) {
                for (i = 1; i <= p; i = i + 1) {
                    for (j = 1; j <= p; j = j + 1) {
                        pos = pos + 1
                        S[pos, 1] = "A" + strofreal(l)
                        S[pos, 2] = "a" + strofreal(i) + "_" + strofreal(j)
                    }
                }
            }
            for (l = 1; l <= M.pg; l = l + 1) {
                for (i = 1; i <= p; i = i + 1) {
                    for (j = 1; j <= p; j = j + 1) {
                        pos = pos + 1
                        S[pos, 1] = "G" + strofreal(l)
                        S[pos, 2] = "g" + strofreal(i) + "_" + strofreal(j)
                    }
                }
            }
        }
        for (kk = 1; kk <= M.nx; kk = kk + 1) {
            eq = "X_D"
            if (M.nx > 1) {
                eq = "X_D" + strofreal(kk)
            }
            for (i = 1; i <= p; i = i + 1) {
                for (j = i; j <= p; j = j + 1) {
                    pos = pos + 1
                    S[pos, 1] = eq
                    S[pos, 2] = "d" + strofreal(i) + "_" + strofreal(j)
                }
            }
        }
    }
    if (M.vm == "cccgarch" | M.vm == "darch") {
        for (i = 1; i <= p; i = i + 1) {
            pos = pos + 1
            S[pos, 1] = "V_" + vn[i]
            S[pos, 2] = "omega"
            for (l = 1; l <= M.qa; l = l + 1) {
                pos = pos + 1
                S[pos, 1] = "V_" + vn[i]
                S[pos, 2] = "arch" + strofreal(l)
            }
            if (M.vm == "cccgarch") {
                for (l = 1; l <= M.pg; l = l + 1) {
                    pos = pos + 1
                    S[pos, 1] = "V_" + vn[i]
                    S[pos, 2] = "garch" + strofreal(l)
                }
            }
        }
        if (M.vm == "cccgarch") {
            for (i = 2; i <= p; i = i + 1) {
                for (j = 1; j <= i - 1; j = j + 1) {
                    pos = pos + 1
                    S[pos, 1] = "Corr"
                    S[pos, 2] = "rho" + strofreal(i) + "_" + strofreal(j)
                }
            }
        }
    }
    if (M.vm == "ecccgarch") {
        for (i = 1; i <= p; i = i + 1) {
            pos = pos + 1
            S[pos, 1] = "V_" + vn[i]
            S[pos, 2] = "omega"
            for (j = 1; j <= p; j = j + 1) {
                pos = pos + 1
                S[pos, 1] = "V_" + vn[i]
                S[pos, 2] = "arch" + strofreal(j)
            }
            pos = pos + 1
            S[pos, 1] = "V_" + vn[i]
            S[pos, 2] = "garch"
        }
    }
    if (M.vm == "trigarch") {
        for (i = 2; i <= p; i = i + 1) {
            for (j = 1; j <= i - 1; j = j + 1) {
                pos = pos + 1
                S[pos, 1] = "Lambda"
                S[pos, 2] = "l" + strofreal(i) + "_" + strofreal(j)
            }
        }
        for (j = 1; j <= p; j = j + 1) {
            pos = pos + 1
            S[pos, 1] = "V_e" + strofreal(j)
            S[pos, 2] = "omega"
            pos = pos + 1
            S[pos, 1] = "V_e" + strofreal(j)
            S[pos, 2] = "psi"
            pos = pos + 1
            S[pos, 1] = "V_e" + strofreal(j)
            S[pos, 2] = "phi"
        }
    }
    for (i = 1; i <= rows(S); i = i + 1) {
        S[i, 1] = substr(S[i, 1], 1, 32)
        S[i, 2] = substr(S[i, 2], 1, 32)
    }
    return(S)
}

// ---------------------------------------------------------------------------
//  Model-specific e() matrices and persistence summary
// ---------------------------------------------------------------------------

void cvg_putm(string scalar nm, real matrix X, string rowvector rn, string rowvector cn)
{
    string scalar s
    s = "__cvg_vm_" + nm
    st_matrix(s, X)
    if (cols(rn) == rows(X)) {
        st_matrixrowstripe(s, (J(rows(X), 1, ""), rn'))
    }
    if (cols(cn) == cols(X)) {
        st_matrixcolstripe(s, (J(cols(X), 1, ""), cn'))
    }
}

void cvg_vmats(struct cvg_mod scalar M, real rowvector v, string rowvector vn)
{
    real scalar p, np, p2, pos, i, j, l, kk
    real matrix C, Am, KK, P, Lm, Wm, Dk
    real rowvector a, b
    real colvector pers
    string rowvector prn, gcn, en
    string scalar lst, nm
    p   = M.p
    np  = p*(p+1)/2
    p2  = p*p
    lst = ""
    pers = J(0, 1, .)
    prn  = J(1, 0, "")
    en   = J(1, 0, "")
    for (j = 1; j <= p; j = j + 1) {
        en = en, ("e" + strofreal(j))
    }
    if (M.vm == "none") {
        cvg_putm("Sigma", cvg_vech2sym(v, p), vn, vn)
        lst = "Sigma"
    }
    if (M.vm == "dbekk" | M.vm == "bekk") {
        C = cvg_uptri(v[|1 \ np|], p)
        cvg_putm("C", C, vn, vn)
        cvg_putm("Omega", C' * C, vn, vn)
        lst = "C Omega"
        pos = np
        if (M.vm == "dbekk") {
            a = v[|np+1 \ np+p|]
            b = v[|np+p+1 \ np+2*p|]
            cvg_putm("A", diag(a), vn, vn)
            cvg_putm("B", diag(b), vn, vn)
            lst = lst + " A B"
            pos = np + 2*p
            pers = (a :^ 2 :+ b :^ 2)'
            prn  = vn
        }
        else {
            KK = J(p2, p2, 0)
            for (l = 1; l <= M.qa; l = l + 1) {
                Am = rowshape(v[|pos+1 \ pos+p2|], p)
                KK = KK + Am # Am
                cvg_putm("A" + strofreal(l), Am, vn, vn)
                lst = lst + " A" + strofreal(l)
                pos = pos + p2
            }
            for (l = 1; l <= M.pg; l = l + 1) {
                Am = rowshape(v[|pos+1 \ pos+p2|], p)
                KK = KK + Am # Am
                cvg_putm("G" + strofreal(l), Am, vn, vn)
                lst = lst + " G" + strofreal(l)
                pos = pos + p2
            }
            pers = max(abs(eigenvalues(KK)))
            prn  = "rho"
        }
        for (kk = 1; kk <= M.nx; kk = kk + 1) {
            nm = "D"
            if (M.nx > 1) {
                nm = "D" + strofreal(kk)
            }
            Dk = cvg_uptri(v[|pos+1 \ pos+np|], p)
            cvg_putm(nm, Dk, vn, vn)
            lst = lst + " " + nm
            pos = pos + np
        }
    }
    if (M.vm == "cccgarch" | M.vm == "darch") {
        kk = 1 + M.qa
        if (M.vm == "cccgarch") {
            kk = kk + M.pg
        }
        gcn = "omega"
        for (l = 1; l <= M.qa; l = l + 1) {
            gcn = gcn, ("arch" + strofreal(l))
        }
        if (M.vm == "cccgarch") {
            for (l = 1; l <= M.pg; l = l + 1) {
                gcn = gcn, ("garch" + strofreal(l))
            }
        }
        P = J(p, kk, .)
        pos = 0
        for (i = 1; i <= p; i = i + 1) {
            P[i, .] = v[|pos+1 \ pos+kk|]
            pos = pos + kk
        }
        cvg_putm("garchpar", P, vn, gcn)
        lst = "garchpar"
        if (M.vm == "cccgarch") {
            cvg_putm("Corr", cvg_rhomat(v[|pos+1 \ pos+p*(p-1)/2|], p), vn, vn)
            lst = lst + " Corr"
        }
        pers = rowsum(P[|1,2 \ p,kk|])
        prn  = vn
    }
    if (M.vm == "ecccgarch") {
        Wm = J(p, 1, .)
        Am = J(p, p, .)
        b  = J(1, p, .)
        pos = 0
        for (i = 1; i <= p; i = i + 1) {
            Wm[i] = v[pos + 1]
            Am[i, .] = v[|pos+2 \ pos+1+p|]
            b[i] = v[pos + p + 2]
            pos = pos + p + 2
        }
        cvg_putm("W", Wm, vn, "omega")
        cvg_putm("A", Am, vn, vn)
        cvg_putm("B", diag(b), vn, vn)
        lst = "W A B"
        pers = max(abs(eigenvalues(Am + diag(b))))
        prn  = "rho"
    }
    if (M.vm == "trigarch") {
        Lm = cvg_unitlow(v[|1 \ p*(p-1)/2|], p)
        cvg_putm("L", Lm, vn, vn)
        P = J(p, 3, .)
        pos = p*(p-1)/2
        for (j = 1; j <= p; j = j + 1) {
            P[j, .] = v[|pos+1 \ pos+3|]
            pos = pos + 3
        }
        cvg_putm("garchpar", P, en, ("omega", "psi", "phi"))
        lst = "L garchpar"
        pers = P[., 2] + P[., 3]
        prn  = en
    }
    st_local("__vmlist", lst)
    if (rows(pers) > 0) {
        st_matrix("__cvg_persist", pers)
        st_matrixrowstripe("__cvg_persist", (J(rows(pers), 1, ""), prn'))
        st_matrixcolstripe("__cvg_persist", ("", "persistence"))
    }
}

// ---------------------------------------------------------------------------
//  Main entry point of -cointvol vecmgarch-
// ---------------------------------------------------------------------------

void cvg_main(string scalar vars, string scalar touse, string scalar esname,
              real scalar kl, string scalar det, string scalar vm,
              real scalar qa, real scalar pg, string scalar rmode, real scalar rr,
              string scalar bvals, string scalar nidxs, string scalar xmode,
              string scalar xvars, string scalar method, string scalar tech,
              real scalar maxit, real scalar starts, string scalar vce,
              real scalar trace, real scalar uncon, real scalar novce,
              string scalar names)
{
    struct cvg_mod scalar M, M2
    struct cv_joh scalar Jd
    real matrix Y, D1, D2, Z0, Z1, Z2, Hm, alJ, phi, Psi0, E0, Nr, bst0, al0
    real matrix Bfix, Xr, G, Hs, Bm, Hn, Voim, Vopg, Vs, Vo, E, VH, bst, al, Psi
    real matrix bsto, alo, Psio, Sd, Lt
    real colvector nidx, fidx, normrows, idxv, idxm, idxa, ll, bfree, llst
    real rowvector bv, natm, natv0, th0, th1, th, ths, thr, nat, mult, cx, bo, dv
    real rowvector tmp, dvd
    real scalar T0, p, p1, q, n, r, c, i, j, pos, nb, ll0, rc, llV, convV, itV
    real scalar llb, convb, itb, llr, convr, itr, s, nsc, llf, K, vmiss, full
    real scalar sv, llM, convM, itM, vsing, conv, iter
    string rowvector vn
    string matrix strp

    vn   = tokens(names)
    full = (rmode == "full")
    Y  = st_data(., tokens(vars), touse)
    T0 = rows(Y)
    p  = cols(Y)
    dv = diagonal(variance(Y[|2,1 \ T0,p|] - Y[|1,1 \ T0-1,p|]))'
    if (hasmissing(dv)) {
        errprintf("missing values in the estimation sample\n")
        exit(error(416))
    }
    if (min(dv) <= 0) {
        errprintf("a series has constant first differences\n")
        exit(error(498))
    }
    // internal scaling: all series multiplied by c (results are reported in original units)
    c = 1 / sqrt(mean(dv'))
    Y = Y :* c
    cv_detmats(T0, det, D1, D2)
    cv_build(Y, kl, D1, D2, Z0, Z1, Z2)
    n  = rows(Z0)
    p1 = cols(Z1)
    q  = cols(Z2)

    // ---------------- structure of beta# -------------------------------------
    fidx     = J(0, 1, .)
    normrows = J(0, 1, .)
    r    = 0
    Bfix = J(p1, 0, 0)
    Hm   = J(p1, 0, 0)
    if (rmode == "est") {
        r = rr
        nidx = strtoreal(tokens(nidxs))'
        Bfix = J(p1, r, 0)
        for (j = 1; j <= r; j = j + 1) {
            Bfix[nidx[j], j] = 1
        }
        for (i = 1; i <= p1; i = i + 1) {
            if (anyof(nidx, i) == 0) {
                fidx = fidx \ i
            }
        }
        Hm = I(p1)
        normrows = nidx
    }
    if (rmode == "fixed") {
        r  = rr
        bv = strtoreal(tokens(bvals))
        nb = cols(bv)
        Bfix = J(p1, r, 0)
        if (nb == p*r) {
            for (j = 1; j <= r; j = j + 1) {
                Bfix[|1,j \ p,j|] = bv[|(j-1)*p+1 \ j*p|]'
            }
            if (p1 > p) {
                fidx = (p+1::p1)
                Hm = blockdiag(Bfix[|1,1 \ p,r|], I(p1-p))
            }
            else {
                Hm = Bfix
            }
        }
        else {
            for (j = 1; j <= r; j = j + 1) {
                Bfix[., j] = bv[|(j-1)*p1+1 \ j*p1|]'
            }
            if (p1 > p) {
                Bfix[|p+1,1 \ p1,r|] = Bfix[|p+1,1 \ p1,r|] :* c
            }
            Hm = Bfix
        }
        normrows = (1::r)
    }
    if (full) {
        r = p1
        Bfix = I(p1)
        Hm   = I(p1)
        normrows = (1::p1)
    }

    // ---------------- Johansen RRR / LS starting values (exact homoskedastic ML)
    if (r > 0) {
        Jd = cv_johansen(Z0, Z1 * Hm, Z2)
        if (Jd.ok == 0) {
            errprintf("moment matrices are singular; check for collinear or constant series\n")
            exit(error(506))
        }
        cv_fitrank(Jd, r, alJ, phi, Psi0, E0, ll0)
        Nr = phi[normrows, .]
        if (rank(Nr) < r) {
            errprintf("normalisation c'beta = I_r fails (singular block); choose other normalize() variables\n")
            exit(error(498))
        }
        phi  = phi * luinv(Nr)
        al0  = alJ * Nr'
        bst0 = Hm * phi
        for (i = 1; i <= p1; i = i + 1) {
            if (anyof(fidx, i) == 0) {
                bst0[i, .] = Bfix[i, .]
            }
        }
    }
    else {
        al0  = J(p, 0, 0)
        bst0 = J(p1, 0, 0)
        if (q > 0) {
            Psi0 = (invsym(cross(Z2, Z2)) * cross(Z2, Z0))'
            E0   = Z0 - Z2 * Psi0'
        }
        else {
            Psi0 = J(p, 0, 0)
            E0   = Z0
        }
        ll0 = -n/2 * ln(det(cross(E0, E0) / n)) - n*p/2 * (1 + ln(2*pi()))
    }

    // ---------------- model structure ---------------------------------------
    M.Z0 = Z0
    M.Z1 = Z1
    M.Z2 = Z2
    M.n  = n
    M.p  = p
    M.p1 = p1
    M.q  = q
    M.r  = r
    M.Bfix = Bfix
    M.fidx = fidx
    M.nbf  = rows(fidx) * r
    M.km   = M.nbf + p*(r + q)
    M.vm   = vm
    M.qa   = qa
    M.pg   = pg
    M.uncon = uncon
    M.nx   = 0
    M.xect = 0
    M.X2f  = J(n, 0, .)
    cx = J(1, 0, .)
    if (xmode == "ect") {
        M.xect = 1
        M.nx   = r
    }
    if (xmode == "vars") {
        Xr = st_data(., tokens(xvars), esname)
        if (rows(Xr) != n) {
            errprintf("garchx(): the lagged X variables do not match the estimation sample\n")
            exit(error(416))
        }
        if (hasmissing(Xr)) {
            errprintf("garchx(): the lagged X variables must be nonmissing over the estimation sample\n")
            exit(error(416))
        }
        Sd = sqrt(diagonal(variance(Xr)))'
        if (min(Sd) <= 0) {
            errprintf("garchx(): an X variable is constant over the estimation sample\n")
            exit(error(498))
        }
        cx = 1 :/ Sd
        M.X2f = (Xr :* cx) :^ 2
        M.nx  = cols(Xr)
    }
    M.kv = cvg_kvar(vm, p, qa, pg, M.nx)
    M.k  = M.km + M.kv
    K    = M.k
    M.S0 = cross(E0, E0) / n
    M.sref = diagonal(M.S0)'
    if (vm == "trigarch") {
        Lt = cvg_L0(M.S0)
        M.sref = diagonal(Lt * M.S0 * Lt')'
    }
    M.thfix = J(1, K, 0)
    M.idx   = (1::K)

    // mean starting values
    natm = J(1, M.km, .)
    pos = 0
    for (j = 1; j <= r; j = j + 1) {
        for (i = 1; i <= rows(fidx); i = i + 1) {
            pos = pos + 1
            natm[pos] = bst0[fidx[i], j]
        }
    }
    for (i = 1; i <= p; i = i + 1) {
        for (j = 1; j <= r; j = j + 1) {
            pos = pos + 1
            natm[pos] = al0[i, j]
        }
        for (j = 1; j <= q; j = j + 1) {
            pos = pos + 1
            natm[pos] = Psi0[i, j]
        }
    }

    // variance starting values
    natv0 = cvg_vstart(M, bst0, 0)
    if (vm == "bekk" & method != "ls") {
        M2 = M
        M2.vm = "dbekk"
        M2.uncon = 0
        M2.kv = cvg_kvar("dbekk", p, 1, 1, M.nx)
        M2.k  = M2.km + M2.kv
        th1 = natm, cvg_v_nat2th(M2, cvg_vstart(M2, bst0, 0))
        if (trace) {
            printf("{txt}\nStage 0: diagonal BEKK variance fit (starting values for the full BEKK)\n")
        }
        rc = cvg_opt(M2, th1, (M2.km+1::M2.k), tech, maxit, trace, ths, llV, convV, itV)
        if (rc == 0 & llV < .) {
            tmp = cvg_th2nat(M2, ths)
            dvd = tmp[|M2.km+1 \ M2.k|]
            natv0 = cvg_d2bekk(M, dvd)
        }
    }
    th0 = natm, cvg_v_nat2th(M, natv0)
    sv  = cvg_sum(M, cvg_th2nat(M, th0))
    if (sv >= .) {
        natv0 = cvg_vstart(M, bst0, 1)
        th0 = natm, cvg_v_nat2th(M, natv0)
        sv  = cvg_sum(M, cvg_th2nat(M, th0))
        if (sv >= .) {
            errprintf("the starting values of the variance model are not feasible\n")
            exit(error(430))
        }
    }

    // ---------------- estimation ------------------------------------------------
    idxv = (M.km+1::K)
    idxa = (1::K)
    convV = 1
    itV   = 0
    conv  = 1
    iter  = 0
    nsc   = 0
    llst  = J(0, 1, .)
    th    = th0
    if (method != "ls") {
        if (trace) {
            printf("{txt}\nStage 1: variance parameters given the LS/RRR mean (two-step estimator)\n")
        }
        rc = cvg_opt(M, th0, idxv, tech, maxit, trace, th1, llV, convV, itV)
        if (rc != 0 | llV >= .) {
            th1 = th0
            convV = 0
        }
        if (method == "qmle") {
            if (trace) {
                printf("{txt}\nStage 2: joint QMLE of all parameters\n")
            }
            rc = cvg_opt(M, th1, idxa, tech, maxit, trace, th, llb, convb, itb)
            if (rc != 0 | llb >= .) {
                th    = th1
                llb   = cvg_sum(M, cvg_th2nat(M, th1))
                convb = 0
                itb   = .
            }
            // random restarts around the two-step point
            if (starts > 0) {
                llst = J(starts, 1, .)
                for (s = 1; s <= starts; s = s + 1) {
                    ths = th1
                    for (j = M.km + 1; j <= K; j = j + 1) {
                        ths[j] = th1[j] + 0.25 * max((abs(th1[j]), 0.2)) * rnormal(1, 1, 0, 1)
                    }
                    if (cvg_sum(M, cvg_th2nat(M, ths)) >= .) {
                        continue
                    }
                    if (trace) {
                        printf("{txt}\nRandom restart %g\n", s)
                    }
                    rc = cvg_opt(M, ths, idxa, tech, maxit, trace, thr, llr, convr, itr)
                    if (rc == 0 & llr < .) {
                        llst[s] = llr
                        if (convr) {
                            nsc = nsc + 1
                        }
                        if ((convr & (convb == 0 | llr > llb)) | (convr == convb & llr > llb)) {
                            th    = thr
                            llb   = llr
                            convb = convr
                            itb   = itr
                        }
                    }
                }
            }
            conv = convb
            iter = itb
        }
        else {
            // two-step: mean parameters by ML with the variance parameters fixed
            convM = 1
            itM   = 0
            th    = th1
            if (M.km > 0) {
                idxm = (1::M.km)
                if (trace) {
                    printf("{txt}\nStage 2: mean parameters given the stage-1 variance parameters\n")
                }
                rc = cvg_opt(M, th1, idxm, tech, maxit, trace, th, llM, convM, itM)
                if (rc != 0 | llM >= .) {
                    th = th1
                    convM = 0
                }
            }
            conv = convV & convM
            iter = itM
        }
    }

    nat = cvg_signnorm(M, cvg_th2nat(M, th))
    llf = cvg_sum(M, nat)
    if (llf >= .) {
        errprintf("the log likelihood cannot be evaluated at the final estimates\n")
        exit(error(430))
    }

    // ---------------- variance matrix -----------------------------------------------
    mult  = cvg_mult(M, c, cx, full, kl)
    bo    = nat :* mult
    strp  = cvg_stripe(M, vn, det, kl, full)
    vmiss = 1
    vsing = 0
    st_matrix("__cvg_b", bo)
    st_matrixcolstripe("__cvg_b", strp)
    if (novce == 0) {
        cvg_numderiv(M, nat, (vce != "opg"), G, Hs)
        if (hasmissing(G) == 0) {
            Bm = cross(G, G)
            if (vce != "opg") {
                if (hasmissing(Hs)) {
                    Hs = J(K, K, .)
                }
            }
            if (method == "twostep" & M.km > 0) {
                Bm[|1,M.km+1 \ M.km,K|] = J(M.km, M.kv, 0)
                Bm[|M.km+1,1 \ K,M.km|] = J(M.kv, M.km, 0)
                if (vce != "opg") {
                    Hs[|1,M.km+1 \ M.km,K|] = J(M.km, M.kv, 0)
                    Hs[|M.km+1,1 \ K,M.km|] = J(M.kv, M.km, 0)
                }
            }
            Vopg = invsym((Bm + Bm') / 2)
            if (vce == "opg") {
                Vs = Vopg
                vsing = diag0cnt(Vopg)
            }
            else {
                Voim = J(K, K, .)
                if (hasmissing(Hs) == 0) {
                    Hn   = -(Hs + Hs') / 2
                    Voim = invsym(Hn)
                    vsing = diag0cnt(Voim)
                }
                if (vce == "oim") {
                    Vs = Voim
                }
                else {
                    Vs = Voim * Bm * Voim
                }
            }
            if (hasmissing(Vs) == 0) {
                vmiss = 0
                Vo = Vs :* (mult' * mult)
                Vo = (Vo + Vo') / 2
                st_matrix("__cvg_V", Vo)
                st_matrixcolstripe("__cvg_V", strp)
                st_matrixrowstripe("__cvg_V", strp)
                Vo = Vopg :* (mult' * mult)
                st_matrix("__cvg_Vopg", (Vo + Vo') / 2)
                st_matrixcolstripe("__cvg_Vopg", strp)
                st_matrixrowstripe("__cvg_Vopg", strp)
                if (vce != "opg") {
                    Vo = Voim :* (mult' * mult)
                    st_matrix("__cvg_Voim", (Vo + Vo') / 2)
                    st_matrixcolstripe("__cvg_Voim", strp)
                    st_matrixrowstripe("__cvg_Voim", strp)
                }
            }
        }
    }

    // ---------------- results in original units -------------------------------------
    cvg_mean(M, nat, bst, al, Psi)
    cvg_fit(M, nat, E, VH, ll)
    VH = VH :/ (c*c)
    if (r > 0) {
        bsto = bst
        alo  = al
        if (full) {
            bsto = I(p1)
            if (p1 > p) {
                alo[|1,p+1 \ p,p1|] = al[|1,p+1 \ p,p1|] :/ c
            }
        }
        else if (p1 > p) {
            bsto[|p+1,1 \ p1,r|] = bst[|p+1,1 \ p1,r|] :/ c
        }
        st_matrix("__cvg_alpha", alo)
        st_matrix("__cvg_beta", bsto)
        st_matrix("__cvg_Pi", alo * bsto')
        bfree = J(p1, 1, 0)
        for (i = 1; i <= rows(fidx); i = i + 1) {
            bfree[fidx[i]] = 1
        }
        st_matrix("__cvg_bfree", bfree)
    }
    if (q > 0) {
        Psio = Psi
        if (q > p*(kl-1)) {
            Psio[|1,p*(kl-1)+1 \ p,q|] = Psi[|1,p*(kl-1)+1 \ p,q|] :/ c
        }
        st_matrix("__cvg_Gamma", Psio)
    }
    st_matrix("__cvg_H", rowshape(VH[n, .], p)')
    st_matrix("__cvg_Hbar", rowshape(mean(VH), p)')
    st_matrix("__cvg_H0", M.S0 :/ (c*c))
    if (rows(llst) > 0) {
        st_matrix("__cvg_llst", llst :+ n*p*ln(c))
    }
    cvg_vmats(M, bo[|M.km+1 \ K|], vn)

    st_numscalar("__cvg_N", n)
    st_numscalar("__cvg_ll", llf + n*p*ln(c))
    st_numscalar("__cvg_ll0", ll0 + n*p*ln(c))
    st_numscalar("__cvg_conv", conv)
    st_numscalar("__cvg_convv", convV)
    st_numscalar("__cvg_iter", iter)
    st_numscalar("__cvg_iterv", itV)
    st_numscalar("__cvg_k", K)
    st_numscalar("__cvg_km", M.km)
    st_numscalar("__cvg_kv", M.kv)
    st_numscalar("__cvg_scale", c)
    st_numscalar("__cvg_rint", r)
    st_numscalar("__cvg_nx", M.nx)
    st_numscalar("__cvg_xect", M.xect)
    st_numscalar("__cvg_nsc", nsc)
    st_numscalar("__cvg_vmiss", vmiss)
    st_numscalar("__cvg_vsing", vsing)
}

// ---------------------------------------------------------------------------
//  Rebuild the model from e() and the data (predict / estat); original units
// ---------------------------------------------------------------------------

struct cvg_mod scalar cvg_fromE(string scalar vars, string scalar win, string scalar es,
                                string scalar xl)
{
    struct cvg_mod scalar M
    real matrix Y, D1, D2, Z0, Z1, Z2, bf, Xr
    real scalar kl
    string scalar det
    Y   = st_data(., tokens(vars), win)
    kl  = st_numscalar("e(lags)")
    det = st_global("e(trend)")
    cv_detmats(rows(Y), det, D1, D2)
    cv_build(Y, kl, D1, D2, Z0, Z1, Z2)
    M.Z0 = Z0
    M.Z1 = Z1
    M.Z2 = Z2
    M.n  = rows(Z0)
    M.p  = cols(Z0)
    M.p1 = cols(Z1)
    M.q  = cols(Z2)
    M.r  = st_numscalar("e(rank_int)")
    M.vm = st_global("e(variance)")
    M.qa = st_numscalar("e(arch)")
    M.pg = st_numscalar("e(garch)")
    M.uncon = 0
    M.nx   = st_numscalar("e(nx)")
    M.xect = st_numscalar("e(xect)")
    M.S0   = st_matrix("e(H0)")
    M.sref = diagonal(M.S0)'
    if (M.r > 0) {
        M.Bfix = st_matrix("e(beta)")
        bf = st_matrix("e(bfree)")
        M.fidx = select((1::M.p1), bf :!= 0)
    }
    else {
        M.Bfix = J(M.p1, 0, 0)
        M.fidx = J(0, 1, .)
    }
    M.nbf = rows(M.fidx) * M.r
    M.km  = st_numscalar("e(k_mean)")
    M.kv  = st_numscalar("e(k_var)")
    M.k   = M.km + M.kv
    M.X2f = J(M.n, 0, .)
    if (M.nx > 0 & M.xect == 0) {
        Xr = st_data(., tokens(xl), es)
        M.X2f = Xr :^ 2
    }
    M.thfix = J(1, M.k, 0)
    M.idx   = (1::M.k)
    if (M.n != st_numscalar("e(N)")) {
        errprintf("the estimation sample cannot be reconstructed from the data in memory\n")
        exit(error(459))
    }
    return(M)
}

void cvg_predict(string scalar vars, string scalar win, string scalar es, string scalar xl,
                 string scalar stat, real scalar i1, real scalar i2, string scalar outv)
{
    struct cvg_mod scalar M
    real matrix bst, al, Psi, E, VH
    real colvector ll, out, h1, h2
    real rowvector nat
    real scalar p
    M   = cvg_fromE(vars, win, es, xl)
    nat = st_matrix("e(b)")
    p   = M.p
    cvg_mean(M, nat, bst, al, Psi)
    cvg_fit(M, nat, E, VH, ll)
    h1 = VH[., (i1-1)*p + i1]
    if (stat == "xb") {
        out = M.Z0[., i1] - E[., i1]
    }
    else if (stat == "residuals") {
        out = E[., i1]
    }
    else if (stat == "stdresid") {
        out = E[., i1] :/ sqrt(h1)
    }
    else if (stat == "variance") {
        out = h1
    }
    else if (stat == "sd") {
        out = sqrt(h1)
    }
    else if (stat == "covariance") {
        out = VH[., (i2-1)*p + i1]
    }
    else if (stat == "correlation") {
        h2  = VH[., (i2-1)*p + i2]
        out = VH[., (i2-1)*p + i1] :/ sqrt(h1 :* h2)
    }
    else if (stat == "ect") {
        out = M.Z1 * bst[., i1]
    }
    else {
        out = ll
    }
    st_store(., outv, es, out)
}

// standardised residuals per equation (orthogonalised errors for trigarch)
void cvg_stdz(struct cvg_mod scalar M, real rowvector nat, real matrix Ev, real matrix S2)
{
    real matrix E, VH, Lm
    real colvector ll
    real scalar p, i, a, b
    p = M.p
    cvg_fit(M, nat, E, VH, ll)
    S2 = J(M.n, p, .)
    if (M.vm == "trigarch") {
        Lm = cvg_unitlow(nat[|M.km+1 \ M.km+p*(p-1)/2|], p)
        Ev = E * Lm'
        for (i = 1; i <= p; i = i + 1) {
            S2[., i] = J(M.n, 1, 0)
            for (a = 1; a <= p; a = a + 1) {
                for (b = 1; b <= p; b = b + 1) {
                    S2[., i] = S2[., i] + Lm[i, a] * Lm[i, b] :* VH[., (b-1)*p + a]
                }
            }
        }
    }
    else {
        Ev = E
        for (i = 1; i <= p; i = i + 1) {
            S2[., i] = VH[., (i-1)*p + i]
        }
    }
}

// own-series ARCH and GARCH coefficients (row i) of univariate-type variance models
void cvg_owncoef(struct cvg_mod scalar M, real rowvector v, real matrix Aa, real matrix Bb)
{
    real scalar p, np, i, pos, l
    p  = M.p
    np = p*(p+1)/2
    Aa = J(p, 0, .)
    Bb = J(p, 0, .)
    if (M.vm == "dbekk") {
        Aa = (v[|np+1 \ np+p|] :^ 2)'
        Bb = (v[|np+p+1 \ np+2*p|] :^ 2)'
    }
    if (M.vm == "cccgarch" | M.vm == "darch") {
        Aa = J(p, M.qa, .)
        if (M.vm == "cccgarch") {
            Bb = J(p, M.pg, .)
        }
        pos = 0
        for (i = 1; i <= p; i = i + 1) {
            for (l = 1; l <= M.qa; l = l + 1) {
                Aa[i, l] = v[pos + 1 + l]
            }
            if (M.vm == "cccgarch") {
                for (l = 1; l <= M.pg; l = l + 1) {
                    Bb[i, l] = v[pos + 1 + M.qa + l]
                }
                pos = pos + 1 + M.qa + M.pg
            }
            else {
                pos = pos + 1 + M.qa
            }
        }
    }
    if (M.vm == "trigarch") {
        Aa = J(p, 1, .)
        Bb = J(p, 1, .)
        pos = p*(p-1)/2
        for (i = 1; i <= p; i = i + 1) {
            Aa[i, 1] = v[pos + 2]
            Bb[i, 1] = v[pos + 3]
            pos = pos + 3
        }
    }
}

// spectral radius of E(A_t # A_t) for a GARCH(pg, qa) with E eta^2 = 1, E eta^4 = kap
real scalar cvg_mom4(real rowvector a, real rowvector b, real scalar kap)
{
    real scalar qa, pg, m, j
    real matrix A0, A1, EK
    qa = cols(a)
    pg = cols(b)
    m  = qa + pg
    A0 = J(m, m, 0)
    A1 = J(m, m, 0)
    A1[1, .] = (a, b)
    for (j = 2; j <= qa; j = j + 1) {
        A0[j, j-1] = 1
    }
    if (pg > 0) {
        A0[qa+1, .] = (a, b)
        for (j = 2; j <= pg; j = j + 1) {
            A0[qa+j, qa+j-1] = 1
        }
    }
    EK = A0 # A0 + A0 # A1 + A1 # A0 + kap :* (A1 # A1)
    return(max(abs(eigenvalues(EK))))
}

void cvg_moments(string scalar vars, string scalar win, string scalar es, string scalar xl)
{
    struct cvg_mod scalar M
    real matrix Ev, S2, Aa, Bb, KK, Am, Su, E, VH, X2, CC, DD, Dk, Lm, Li, bst, al, Psi
    real matrix Mo
    real colvector eg, ll, ev
    real rowvector nat, v, kap, a, b, w, om, x2m
    real scalar p, np, p2, i, j, l, pos, kk, rho
    M   = cvg_fromE(vars, win, es, xl)
    nat = st_matrix("e(b)")
    p   = M.p
    np  = p*(p+1)/2
    p2  = p*p
    v   = nat[|M.km+1 \ M.k|]
    cvg_stdz(M, nat, Ev, S2)
    kap = mean((Ev :^ 2 :/ S2) :^ 2)
    cvg_fit(M, nat, E, VH, ll)
    cvg_mean(M, nat, bst, al, Psi)
    Su = J(p, p, .)
    Mo = J(0, 6, .)
    eg = J(0, 1, .)
    if (M.vm == "dbekk" | M.vm == "bekk") {
        CC = cvg_uptri(v[|1 \ np|], p)
        CC = CC' * CC
        KK = J(p2, p2, 0)
        pos = np
        if (M.vm == "dbekk") {
            a  = v[|np+1 \ np+p|]
            b  = v[|np+p+1 \ np+2*p|]
            KK = diag(a) # diag(a) + diag(b) # diag(b)
            pos = np + 2*p
        }
        else {
            for (l = 1; l <= M.qa + M.pg; l = l + 1) {
                Am = rowshape(v[|pos+1 \ pos+p2|], p)
                KK = KK + Am # Am
                pos = pos + p2
            }
        }
        if (M.nx > 0) {
            X2  = cvg_x2(M, bst)
            x2m = mean(X2)
            for (kk = 1; kk <= M.nx; kk = kk + 1) {
                Dk = cvg_uptri(v[|pos+1 \ pos+np|], p)
                CC = CC + (Dk' * Dk) :* x2m[kk]
                pos = pos + np
            }
        }
        eg  = sort(abs(eigenvalues(KK))', -1)
        rho = eg[1]
        if (rho < 1) {
            w  = vec(CC)' * luinv(I(p2) - KK)
            Su = rowshape(w, p)'
        }
    }
    if (M.vm == "dbekk" | M.vm == "cccgarch" | M.vm == "darch" | M.vm == "trigarch") {
        cvg_owncoef(M, v, Aa, Bb)
        Mo = J(p, 6, .)
        for (i = 1; i <= p; i = i + 1) {
            a = Aa[i, .]
            b = J(1, 0, .)
            if (cols(Bb) > 0) {
                b = Bb[i, .]
            }
            Mo[i, 1] = sum(a)
            Mo[i, 2] = 0
            if (cols(b) > 0) {
                Mo[i, 2] = sum(b)
            }
            Mo[i, 3] = Mo[i, 1] + Mo[i, 2]
            Mo[i, 4] = cvg_mom4(a, b, 3)
            Mo[i, 5] = cvg_mom4(a, b, kap[i])
            Mo[i, 6] = kap[i]
        }
        if (M.vm != "dbekk") {
            eg = Mo[., 3]
            om = J(1, p, .)
            pos = 0
            if (M.vm == "trigarch") {
                pos = p*(p-1)/2
            }
            for (i = 1; i <= p; i = i + 1) {
                om[i] = v[pos + 1]
                if (M.vm == "cccgarch") {
                    pos = pos + 1 + M.qa + M.pg
                }
                else if (M.vm == "darch") {
                    pos = pos + 1 + M.qa
                }
                else {
                    pos = pos + 3
                }
            }
            if (max(Mo[., 3]) < 1) {
                w = om :/ (1 :- Mo[., 3]')
                if (M.vm == "trigarch") {
                    Lm = cvg_unitlow(v[|1 \ p*(p-1)/2|], p)
                    Li = solvelower(Lm, I(p))
                    Su = Li * diag(w) * Li'
                }
                else {
                    Su = diag(w)
                    for (i = 1; i <= p; i = i + 1) {
                        for (j = 1; j <= p; j = j + 1) {
                            if (i != j) {
                                Su[i, j] = .
                            }
                        }
                    }
                }
            }
        }
    }
    if (M.vm == "ecccgarch") {
        om = J(1, p, .)
        Am = J(p, p, .)
        b  = J(1, p, .)
        pos = 0
        for (i = 1; i <= p; i = i + 1) {
            om[i] = v[pos + 1]
            Am[i, .] = v[|pos+2 \ pos+1+p|]
            b[i] = v[pos + p + 2]
            pos = pos + p + 2
        }
        KK = Am + diag(b)
        eg = sort(abs(eigenvalues(KK))', -1)
        if (eg[1] < 1) {
            ev = luinv(I(p) - KK) * om'
            Su = diag(ev)
            for (i = 1; i <= p; i = i + 1) {
                for (j = 1; j <= p; j = j + 1) {
                    if (i != j) {
                        Su[i, j] = .
                    }
                }
            }
        }
    }
    st_matrix("__cvg_eig", eg)
    if (rows(Mo) > 0) {
        st_matrix("__cvg_mom", Mo)
    }
    st_matrix("__cvg_Su", Su)
    st_matrix("__cvg_Se", cross(E, E) / M.n)
    st_matrix("__cvg_kap", kap)
}

// MA(infinity) coefficients nu_k of a(z)/b(z) (variance in terms of lagged squared errors)
real colvector cvg_nu(real rowvector a, real rowvector b, real scalar Kx)
{
    real colvector nu
    real scalar k, l, x, qa, pg
    qa = cols(a)
    pg = cols(b)
    nu = J(Kx, 1, 0)
    for (k = 1; k <= Kx; k = k + 1) {
        x = 0
        if (k <= qa) {
            x = a[k]
        }
        for (l = 1; l <= pg; l = l + 1) {
            if (k - l >= 1) {
                x = x + b[l] * nu[k - l]
            }
        }
        nu[k] = x
    }
    return(nu)
}

// Seo (2007) partial efficiency gains g_j = [s + (kappa-1) H] / [s + 2H]^2
void cvg_effgain(string scalar vars, string scalar win, string scalar es, string scalar xl)
{
    struct cvg_mod scalar M
    real matrix Ev, S2, Aa, Bb, R
    real colvector nu, e, s2
    real rowvector nat, v, b
    real scalar p, j, k, n, Kx, sbar, s, Hj, kap
    M   = cvg_fromE(vars, win, es, xl)
    nat = st_matrix("e(b)")
    p   = M.p
    n   = M.n
    v   = nat[|M.km+1 \ M.k|]
    cvg_stdz(M, nat, Ev, S2)
    cvg_owncoef(M, v, Aa, Bb)
    Kx = n - 2
    if (Kx > 500) {
        Kx = 500
    }
    R = J(p, 5, .)
    for (j = 1; j <= p; j = j + 1) {
        b = J(1, 0, .)
        if (cols(Bb) > 0) {
            b = Bb[j, .]
        }
        nu   = cvg_nu(Aa[j, .], b, Kx)
        e    = Ev[., j]
        s2   = S2[., j]
        sbar = mean(s2)
        s    = sbar * mean(1 :/ s2)
        Hj   = 0
        for (k = 1; k <= Kx; k = k + 1) {
            if (abs(nu[k]) > 1e-12) {
                Hj = Hj + nu[k]^2 * mean(sbar :* (e[|1 \ n-k|] :^ 2) :/ (s2[|k+1 \ n|] :^ 2))
            }
        }
        kap = mean((e :^ 2 :/ s2) :^ 2)
        R[j, 1] = s
        R[j, 2] = Hj
        R[j, 3] = kap
        R[j, 4] = (s + (kap - 1)*Hj) / (s + 2*Hj)^2
        R[j, 5] = 1 / (s + 2*Hj)
    }
    st_matrix("__cvg_eff", R)
}

// ARCH-LM tests on standardised residuals: n R^2 from z^2 on a constant and q lags
void cvg_archlm(string scalar vars, string scalar win, string scalar es, string scalar xl,
                string scalar lagstr)
{
    struct cvg_mod scalar M
    real matrix Ev, S2, X, R
    real colvector y, z2, bh, u
    real rowvector nat, lg
    real scalar p, i, j, l, q, n, m, r2, row
    M   = cvg_fromE(vars, win, es, xl)
    nat = st_matrix("e(b)")
    p   = M.p
    n   = M.n
    cvg_stdz(M, nat, Ev, S2)
    lg  = strtoreal(tokens(lagstr))
    R   = J(p*cols(lg), 5, .)
    row = 0
    for (i = 1; i <= p; i = i + 1) {
        z2 = Ev[., i] :^ 2 :/ S2[., i]
        for (j = 1; j <= cols(lg); j = j + 1) {
            q = lg[j]
            row = row + 1
            R[row, 1] = i
            R[row, 2] = q
            if (q >= n - 10) {
                continue
            }
            m = n - q
            y = z2[|q+1 \ n|]
            X = J(m, 1, 1)
            for (l = 1; l <= q; l = l + 1) {
                X = X, z2[|q+1-l \ n-l|]
            }
            bh = invsym(cross(X, X)) * cross(X, y)
            u  = y - X * bh
            r2 = 1 - cross(u, u) / cross(y :- mean(y), y :- mean(y))
            R[row, 3] = m * r2
            R[row, 4] = q
            R[row, 5] = chi2tail(q, m * r2)
        }
    }
    st_matrix("__cvg_alm", R)
}

// Lee (1994) LM test for GARCH-X: T R^2 (uncentred) of e_i^2 - h_ii on z^2_{t-1}
//   column 1-2: h_ii from the fitted model; column 3-4: constant variance (ARCH[0]-X)
void cvg_lmx(string scalar vars, string scalar win, string scalar es, string scalar xl)
{
    struct cvg_mod scalar M
    real matrix bst, al, Psi, E, VH, X2, R
    real colvector ll, y1, y0, x, e2
    real rowvector nat
    real scalar p, i, j, n, row
    M   = cvg_fromE(vars, win, es, xl)
    nat = st_matrix("e(b)")
    p   = M.p
    n   = M.n
    cvg_mean(M, nat, bst, al, Psi)
    cvg_fit(M, nat, E, VH, ll)
    X2 = (M.Z1 * bst) :^ 2
    R  = J(p*M.r, 6, .)
    row = 0
    for (j = 1; j <= M.r; j = j + 1) {
        x = X2[., j]
        for (i = 1; i <= p; i = i + 1) {
            row = row + 1
            e2 = E[., i] :^ 2
            y1 = e2 - VH[., (i-1)*p + i]
            y0 = e2 :- mean(e2)
            R[row, 1] = i
            R[row, 2] = j
            R[row, 3] = n * cross(x, y1)^2 / (cross(x, x) * cross(y1, y1))
            R[row, 4] = chi2tail(1, R[row, 3])
            R[row, 5] = n * cross(x, y0)^2 / (cross(x, x) * cross(y0, y0))
            R[row, 6] = chi2tail(1, R[row, 5])
        }
    }
    st_matrix("__cvg_lmx", R)
}

end
