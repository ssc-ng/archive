*! cointvol_eng_restrict 0.1.0  26sep2026
*! Mata engine of -cointvol restrict-: PML estimation of the cointegrated VAR under
*! linear restrictions on alpha and beta, PLR and sandwich-Wald tests, Bartlett
*! correction and wild / iid bootstrap (Boswijk, Cavaliere, Rahbek & Taylor 2016).
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com) - github.com/merwanroudane
*!
*! Step -> source map
*!   normalisation c'beta = I_r, beta# = c# + cperp# beta2#      -> BCRT (2016) Sec. 2.2
*!   H0b: R_b vec beta2# = q_b ; H0a: R_a vec alpha' = q_a         -> BCRT (2016) eq (5)
*!   vec beta# = H phi + h, vec alpha' = G psi + g, H = Q_perp,
*!     Q = [(I_r x c#),(I_r x cperp#)R_b'], G = (R_a')_perp       -> BCRT (2016) eq (6)
*!   concentrated moments S_ij, pseudo log-likelihood             -> BCRT (2016) eqs (7)-(9)
*!   switching algorithm phi|psi,Omega ; psi|phi,Omega ;
*!     Omega|psi,phi (explicit GLS steps, likelihood stopping)     -> Boswijk & Doornik (2004) Sec. 3.2, Sec. 4.4
*!                                                                   eq (39) and the three steps below it
*!   identification: numerical rank of J(theta) =
*!     [(I_p x beta)G : (alpha x I_p1)H] at the restricted MLE     -> Boswijk & Doornik (2004) eqs (20), (40);
*!                                                                   rank rule of Doornik (1995, Def. 1)
*!   Johansen form beta# = H phi: eigenproblem on H'S11H          -> Johansen (1996, Thm 7.2); B&D (2004) Sec. 4.2
*!   LR_T = T log(|Sigma~|/|Sigma^|)                               -> BCRT (2016) Sec. 3.1; B&D (2004) eq (27)
*!   sandwich Wald, J = [(alpha x cperp#),(I_p x beta#)], Hessian H,
*!     OPG I, Var = (I 0)H^-1 I H^-1(I 0)'                        -> BCRT (2016) eq (18)
*!   Bartlett factor for beta# = H phi                            -> Johansen (2000) Cor. 6 (from Thm 4),
*!     P, Q eq (30); Sigma = Var(Y_t) eq (31); V eq (34)-(35);       evaluated at the restricted (H0) estimates
*!     v, c, c_d Thm 4; c_d = n_d v (p. 757)
*!   wild bootstrap: restricted estimates, recentred restricted
*!     residuals, data initial values, deterministics in the
*!     recursion, statistic re-estimated, p = mean(S* > S)        -> BCRT (2016) Algorithm 1, eq (21)
*!
*! This file is -run- by cointvol_restrict.ado (and cointvol_restrict_p.ado) so that
*! its Mata functions are compiled globally.  It requires the core engine
*! (cointvol_engine.ado: struct cv_joh, cv_johansen(), cv_build(), cv_simvecm(), ...).

program define cointvol_eng_restrict
    version 14.0
end

version 14.0
capture mata: st_local("__cvrcore", cv_engine_version())
if _rc {
    capture program drop cointvol_engine
    quietly findfile cointvol_engine.ado
    quietly run `"`r(fn)'"'
}
capture mata: mata drop cvr_*()
capture mata: mata drop cvr_hyp()
capture mata: mata drop cvr_fit()

mata:

string scalar cvr_version()
{
    return("0.1.0")
}

// ---------------------------------------------------------------------------
//  Structures
// ---------------------------------------------------------------------------

// one hypothesis in the parameterisation of BCRT (2016) eq (6)
struct cvr_hyp {
    real matrix    H, h, G, g, R, q, Hj
    real scalar    hasb, hasa, rb, ra, df, jform, s, lphi, lpsi
}

// one set of PML estimates
struct cvr_fit {
    real matrix    a, b, Psi, E, Sig
    real scalar    ld, iter, conv, ok
}

// ---------------------------------------------------------------------------
//  Small linear-algebra helpers
// ---------------------------------------------------------------------------

// orthogonal complement A_perp (n x (n - rank A)), A_perp'A = 0
real matrix cvr_perp(real matrix A)
{
    real matrix X, M
    real rowvector ev
    real colvector idx
    real scalar n, tol
    n = rows(A)
    if (cols(A) == 0) {
        return(I(n))
    }
    M = A * A'
    M = (M + M') / 2
    symeigensystem(M, X, ev)
    tol = 1e-9 * max((1, max(abs(ev))))
    idx = select((1::n), (abs(ev') :<= tol))
    if (rows(idx) == 0) {
        return(J(n, 0, .))
    }
    return(X[., idx])
}

// append an identity block for the restricted deterministic rows
real matrix cvr_addd1(real matrix Hm, real scalar d1)
{
    if (d1 == 0) {
        return(Hm)
    }
    return(blockdiag(Hm, I(d1)))
}

// selection matrices c# (p1 x r) and cperp# = diag(c_perp, I_d1) (p1 x (p1-r))
void cvr_normmats(real scalar p, real scalar d1, real rowvector nidx,
                  real matrix c, real matrix cp)
{
    real scalar p1, r, j, m
    real rowvector isn
    p1  = p + d1
    r   = cols(nidx)
    c   = J(p1, r, 0)
    isn = J(1, p1, 0)
    for (j = 1; j <= r; j = j + 1) {
        c[nidx[j], j] = 1
        isn[nidx[j]]  = 1
    }
    cp = J(p1, p1 - r, 0)
    m  = 0
    for (j = 1; j <= p1; j = j + 1) {
        if (isn[j] == 0) {
            m = m + 1
            cp[j, m] = 1
        }
    }
}

// ---------------------------------------------------------------------------
//  Hypothesis builder: BCRT (2016) eqs (5)-(6)
//    jform = 1: beta# = Hj phi (Johansen form), converted to
//               R_b = I_r x (Hj_perp' cperp#), q_b = -vec(Hj_perp' c#)
// ---------------------------------------------------------------------------

struct cvr_hyp scalar cvr_mkhyp(real scalar p, real scalar p1, real scalar r,
    real matrix c, real matrix cp, real scalar useb, real scalar usea,
    real scalar jform, real matrix Hj, real matrix Rb0, real matrix qb0,
    real matrix Ra0, real matrix qa0)
{
    struct cvr_hyp scalar Hy
    real matrix Hp, M, Q, Rb, Ra, qb, qa
    real colvector rhs
    real scalar nb

    nb      = (p1 - r) * r
    Hy.hasb = useb
    Hy.hasa = usea
    Hy.jform = 0
    Hy.s    = .
    Hy.Hj   = J(0, 0, .)
    Rb = J(0, nb, .)
    qb = J(0, 1, .)
    Ra = J(0, p*r, .)
    qa = J(0, 1, .)

    if (useb) {
        if (jform) {
            Hy.jform = 1
            Hy.Hj    = Hj
            Hy.s     = cols(Hj)
            Hp = cvr_perp(Hj)
            M  = Hp' * cp
            if (rank(M) < rows(M)) {
                errprintf("the normalisation in normalize() is incompatible with the hypothesis on beta;\n")
                errprintf("choose normalising variables whose coefficients are not restricted by H\n")
                exit(198)
            }
            Rb = I(r) # M
            qb = -vec(Hp' * c)
        }
        else {
            Rb = Rb0
            qb = qb0
        }
        if (rank(Rb) < rows(Rb)) {
            errprintf("the restrictions on beta are linearly dependent (R_b has deficient row rank)\n")
            exit(198)
        }
    }
    if (usea) {
        Ra = Ra0
        qa = qa0
        if (rank(Ra) < rows(Ra)) {
            errprintf("the restrictions on alpha are linearly dependent (R_a has deficient row rank)\n")
            exit(198)
        }
    }

    // beta#: vec beta# = H phi + h
    if (rows(Rb) > 0) {
        Q = (I(r) # c, (I(r) # cp) * Rb')
        if (rank(Q) < cols(Q)) {
            errprintf("the restrictions on beta conflict with the normalisation c'beta = I_r;\n")
            errprintf("choose other normalising variables with normalize()\n")
            exit(198)
        }
        rhs  = vec(I(r)) \ qb
        Hy.H = cvr_perp(Q)
        Hy.h = Q * (invsym(Q' * Q) * rhs)
    }
    else {
        Hy.H = I(r) # cp
        Hy.h = vec(c)
    }
    // alpha: vec alpha' = G psi + g
    if (rows(Ra) > 0) {
        Hy.G = cvr_perp(Ra')
        Hy.g = Ra' * (invsym(Ra * Ra') * qa)
    }
    else {
        Hy.G = I(p*r)
        Hy.g = J(p*r, 1, 0)
    }
    Hy.rb = rows(Rb)
    Hy.ra = rows(Ra)
    Hy.df = Hy.rb + Hy.ra
    M = J(Hy.df, nb + p*r, 0)
    if (Hy.rb > 0) {
        M[|1, 1 \ Hy.rb, nb|] = Rb
    }
    if (Hy.ra > 0) {
        M[|Hy.rb+1, nb+1 \ Hy.df, nb+p*r|] = Ra
    }
    Hy.R = M
    Hy.q    = qb \ qa
    Hy.lphi = cols(Hy.H)
    Hy.lpsi = cols(Hy.G)
    return(Hy)
}

// ---------------------------------------------------------------------------
//  Estimation pieces
// ---------------------------------------------------------------------------

// Sigma(alpha, beta#) = S00 - a b'S10 - S01 b a' + a b'S11 b a'   (BCRT eq 8)
real matrix cvr_sig(struct cv_joh scalar Jh, real matrix a, real matrix b)
{
    real matrix S
    S = Jh.S00 - a * (b' * Jh.S01') - (Jh.S01 * b) * a' + a * (b' * Jh.S11 * b) * a'
    return((S + S') / 2)
}

// Psi (short-run + unrestricted deterministics) by OLS given alpha, beta#,
// residuals, PML Sigma and log|Sigma|
void cvr_finish(struct cv_joh scalar Jh, struct cvr_fit scalar F)
{
    real matrix Yr
    Yr = Jh.Z0 - Jh.Z1 * F.b * F.a'
    if (Jh.q > 0) {
        F.Psi = (Jh.M22i * cross(Jh.Z2, Yr))'
        F.E   = Yr - Jh.Z2 * F.Psi'
    }
    else {
        F.Psi = J(Jh.p, 0, .)
        F.E   = Yr
    }
    F.Sig = cross(F.E, F.E) / Jh.T
    F.Sig = (F.Sig + F.Sig') / 2
    F.ld  = ln(det(F.Sig))
}

// unrestricted PML under H(r), normalised c#'beta# = I_r  (BCRT Sec. 3.1)
real scalar cvr_unres(struct cv_joh scalar Jh, real scalar r, real matrix c,
                      struct cvr_fit scalar F)
{
    real matrix bu, cb
    bu = Jh.V[., 1..r]
    cb = c' * bu
    if (rank(cb) < r) {
        return(0)
    }
    F.b = bu * luinv(cb)
    F.a = Jh.S01 * F.b * invsym(F.b' * Jh.S11 * F.b)
    cvr_finish(Jh, F)
    F.iter = 0
    F.conv = 1
    F.ok   = 1
    if (missing(F.ld)) {
        F.ok = 0
        return(0)
    }
    return(1)
}

// closed-form restricted PML under beta# = Hj phi, alpha unrestricted
// (Johansen 1996, Thm 7.2; Kurita 2009 eq 6): |l Hj'S11Hj - Hj'S10 S00^-1 S01 Hj| = 0
real scalar cvr_closedH(struct cv_joh scalar Jh, real matrix Hj, real scalar r,
                        real matrix c, struct cvr_fit scalar F)
{
    real matrix A11, A01, L, Li, C, X, S00i, V, bu, cb
    real rowvector ev
    real colvector idx
    real scalar s
    s   = cols(Hj)
    A11 = Hj' * Jh.S11 * Hj
    A11 = (A11 + A11') / 2
    A01 = Jh.S01 * Hj
    L   = cholesky(A11)
    S00i = invsym(Jh.S00)
    if (hasmissing(L)) {
        return(0)
    }
    Li = solvelower(L, I(s))
    C  = Li * A01' * S00i * A01 * Li'
    C  = (C + C') / 2
    symeigensystem(C, X, ev)
    idx = order(-ev', 1)
    V   = Li' * X[., idx]
    bu  = Hj * V[., 1..r]
    cb  = c' * bu
    if (rank(cb) < r) {
        return(0)
    }
    F.b = bu * luinv(cb)
    F.a = Jh.S01 * F.b * invsym(F.b' * Jh.S11 * F.b)
    cvr_finish(Jh, F)
    F.iter = 0
    F.conv = 1
    F.ok   = 1
    if (missing(F.ld)) {
        F.ok = 0
        return(0)
    }
    return(1)
}

// switching algorithm of Boswijk & Doornik (2004, Sec. 4.4, eq. 39 and the three
// explicit steps that follow it) for vec beta# = H phi + h, vec alpha' = G psi + g.
// Starting values in F.a, F.b; Omega_0 = Omega(alpha_0, beta_0).
// With pi = vec(beta# alpha'), the Omega-conditional log-likelihood is
// pi'Sv - pi'Jm pi/2, Jm = T (Omega^-1 x S11), Sv = T vec(S10 Omega^-1), and
// pi = (alpha x I) vec beta# = (I_p x beta#) vec alpha'.  Hence
//   phi step:   phi = [H'(a'O^-1 a x S11)H]^-1 H'[vec(S10 O^-1 a) - (a'O^-1 a x S11)h]
//   psi step:   psi = [G'(O^-1 x b'S11 b)G]^-1 G'[vec(b'S10 O^-1) - (O^-1 x b'S11 b)g]
//   Omega step: Omega = S00 - S01 b a' - a b'S10 + a b'S11 b a'
// which are B&D's steps with vec(Pi'_LS) = vec(S11^-1 S10) substituted
// (identical for g = 0; g != 0 is the affine alpha restriction, the
// non-homogeneous extension B&D attribute to Hansen 2002).  Order as in B&D:
// phi_j = phi(psi_(j-1), Omega_(j-1)), psi_j = psi(phi_j, Omega_(j-1)),
// Omega_j = Omega(psi_j, phi_j); stop when log|Omega| (= -2/T times the
// concentrated log-likelihood, B&D eq. 22) changes by less than tol (B&D
// Sec. 3.2: iterate "until the value of the likelihood function converges").
// No line search is used (none in B&D).
void cvr_switch(struct cv_joh scalar Jh, struct cvr_hyp scalar Hy,
                struct cvr_fit scalar F, real scalar tol, real scalar maxit)
{
    real matrix a, b, Sig, Si, Jm, A, M
    real colvector Sv, av, v
    real scalar p, p1, r, T, it, ld, ld0, nit

    p   = Jh.p
    p1  = Jh.p1
    r   = cols(F.b)
    T   = Jh.T
    a   = F.a
    b   = F.b
    Sig = cvr_sig(Jh, a, b)
    ld0 = ln(det(Sig))
    F.conv = 0
    F.ok   = 1
    nit    = 0
    for (it = 1; it <= maxit; it = it + 1) {
        nit = it
        Si  = invsym(Sig)
        Jm  = T * (Si # Jh.S11)
        Sv  = T * vec(Jh.S01' * Si)
        // beta step: partial maximiser of beta# given (alpha, Sigma)
        if (Hy.lphi > 0) {
            A  = (a # I(p1)) * Hy.H
            av = (a # I(p1)) * Hy.h
            M  = A' * Jm * A
            M  = (M + M') / 2
            v  = Hy.H * (invsym(M) * (A' * (Sv - Jm * av))) + Hy.h
        }
        else {
            v = Hy.h
        }
        b = colshape(v', p1)'
        // alpha step: partial maximiser of alpha given (beta#, Sigma)
        if (Hy.lpsi > 0) {
            A  = (I(p) # b) * Hy.G
            av = (I(p) # b) * Hy.g
            M  = A' * Jm * A
            M  = (M + M') / 2
            v  = Hy.G * (invsym(M) * (A' * (Sv - Jm * av))) + Hy.g
        }
        else {
            v = Hy.g
        }
        a = colshape(v', r)
        // Sigma step
        Sig = cvr_sig(Jh, a, b)
        ld  = ln(det(Sig))
        if (missing(ld)) {
            F.ok = 0
            break
        }
        if (abs(ld - ld0) < tol) {
            F.conv = 1
            break
        }
        ld0 = ld
    }
    F.iter = nit
    F.a = a
    F.b = b
    cvr_finish(Jh, F)
    if (missing(F.ld)) {
        F.ok = 0
    }
}

// ---------------------------------------------------------------------------
//  Sandwich Wald test, BCRT (2016) eq (18)
//    theta = ((vec beta2#)', (vec alpha')')', gamma = (theta', (vec Psi')')'
//    Jd = d vec(beta# alpha')/d theta' = [(alpha x cperp#), (I_p x beta#)]
//    Hs = T [Jd'(Si x M11)Jd, Jd'(Si x M12); (Si x M21)Jd, Si x M22]
//    Iop = sum_t s_t s_t',  s_t = (Jd'(Si e_t x Z1t) ; (Si e_t x Z2t))
//    Var(theta) = (I_l 0) Hs^-1 Iop Hs^-1 (I_l 0)'
// ---------------------------------------------------------------------------

real scalar cvr_wald(struct cv_joh scalar Jh, struct cvr_fit scalar F,
                     real matrix cp, real matrix R, real matrix q,
                     real matrix th, real matrix Vth)
{
    real matrix Si, Jd, Z1, Z2, M11, M12, M22, H11, H12, H22, Hs, Hi
    real matrix U, Spi, Sps, Sc, Iop, RVR
    real colvector d
    real scalar p, p1, r, qd, T, i, l, lb

    p  = Jh.p
    p1 = Jh.p1
    r  = cols(F.b)
    qd = Jh.q
    T  = Jh.T
    Z1 = Jh.Z1
    Z2 = Jh.Z2
    Si = invsym(F.Sig)
    Jd = (F.a # cp, I(p) # F.b)
    lb = (p1 - r) * r
    l  = lb + p * r
    th = vec(cp' * F.b) \ vec(F.a')

    M11 = cross(Z1, Z1) / T
    U   = F.E * Si
    Spi = J(T, p * p1, .)
    for (i = 1; i <= p; i = i + 1) {
        Spi[|1, (i-1)*p1+1 \ T, i*p1|] = U[., i] :* Z1
    }
    H11 = T * (Jd' * (Si # M11) * Jd)
    if (qd > 0) {
        M12 = cross(Z1, Z2) / T
        M22 = cross(Z2, Z2) / T
        H12 = T * (Jd' * (Si # M12))
        H22 = T * (Si # M22)
        Hs  = (H11, H12 \ H12', H22)
        Sps = J(T, p * qd, .)
        for (i = 1; i <= p; i = i + 1) {
            Sps[|1, (i-1)*qd+1 \ T, i*qd|] = U[., i] :* Z2
        }
        Sc = (Spi * Jd, Sps)
    }
    else {
        Hs = H11
        Sc = Spi * Jd
    }
    Hs  = (Hs + Hs') / 2
    Hi  = invsym(Hs)
    Iop = cross(Sc, Sc)
    Vth = Hi * Iop * Hi
    Vth = Vth[|1, 1 \ l, l|]
    Vth = (Vth + Vth') / 2
    if (rows(R) == 0) {
        return(.)
    }
    d   = R * th - q
    RVR = R * Vth * R'
    RVR = (RVR + RVR') / 2
    return(d' * invsym(RVR) * d)
}

// ---------------------------------------------------------------------------
//  Bartlett correction factor, Johansen (2000), Econometric Theory 16, 740-778.
//  Test of M1: beta = H tau (H n x s, rho free) in M0, Corollary 6:
//   E[-2logLR]/(r(n-s)) = 1 + T^-1 [ (n+s-r+1+2nD)/2 + nd + kn ]
//                           + (Tr)^-1 [ (2n+s-3r-1+2nD) v(a) + 2(c(a) + cd(a)) ]
//  n = p variables, nD = d1 restricted and nd unrestricted deterministic terms,
//  k = lag order of the levels VAR.  Corollary 6 is the difference of Theorem 4
//  evaluated at n_a = p# - r (M0) and n_a = s# - r (M1) with n_v = r,
//  n_z = (k-1)p; in terms of the number s# = s + nD of columns of the p# x s#
//  matrix H# = blockdiag(H, I_nD) used by this command it reads
//   BC = 1 + T^-1 [ (p+s#-r+1+nD)/2 + nd + kp ]
//          + (Tr)^-1 [ (2p+s#-3r-1+nD) v + 2(c + cd) ],
//  which is also the Theorem 4 value for a general p# x s# matrix H#.
//  Theorem 4 coefficients (all at the restricted H0 estimates):
//   Y_t = (X_t'beta, dX_t', ..., dX_(t-k+2)')' = P Y_(t-1) + Q e_t      eq (30)
//   Sigma = Var(Y_t) = sum_v P^v Q Omega Q' P'^v                         eq (31)
//   V = kt kt' Sigma^-1, kt = (I_r, 0)'(a'Omega^-1 a)^(-1/2)            eqs (34)-(35)
//   v = tr V = tr{(a'Omega^-1 a)^-1 Sigma_bb.z^-1}
//   c = tr{P(I+P)^-1 V} + tr{[P x (I-P)V][I x I - P x P]^-1}
//   cd = tr{[M x (I-P)V][I x I - M x P]^-1} = nd v  for d_t = 1 or (1,t)'
//        (Johansen 2000, p. 757), which covers all trend() cases here.
// ---------------------------------------------------------------------------

// P and Q of Johansen (2000) eq (30); Gm = (Gamma_1, ..., Gamma_(k-1)) (p x (k-1)p)
void cvr_jpq(real matrix a, real matrix bl, real matrix Gm, real matrix P, real matrix Q)
{
    real scalar p, r, k, m, j
    real matrix Gj
    p = rows(a)
    r = cols(a)
    k = cols(Gm) / p + 1
    m = r + (k - 1) * p
    P = J(m, m, 0)
    Q = J(m, p, 0)
    P[|1, 1 \ r, r|] = I(r) + bl' * a
    Q[|1, 1 \ r, p|] = bl'
    if (k > 1) {
        P[|r+1, 1 \ r+p, r|] = a
        Q[|r+1, 1 \ r+p, p|] = I(p)
        for (j = 1; j <= k - 1; j = j + 1) {
            Gj = Gm[|1, (j-1)*p+1 \ p, j*p|]
            P[|1, r+(j-1)*p+1 \ r, r+j*p|]     = bl' * Gj
            P[|r+1, r+(j-1)*p+1 \ r+p, r+j*p|] = Gj
        }
        for (j = 1; j <= k - 2; j = j + 1) {
            P[|r+j*p+1, r+(j-1)*p+1 \ r+(j+1)*p, r+j*p|] = I(p)
        }
    }
}

// Sigma = sum_v P^v C P'^v (stable P) by the doubling algorithm
real matrix cvr_lyap(real matrix P, real matrix C)
{
    real matrix S, A
    real scalar it
    S = C
    A = P
    for (it = 1; it <= 80; it = it + 1) {
        S = S + A * S * A'
        A = A * A
        if (max(abs(A)) < 1e-15) {
            break
        }
    }
    return((S + S') / 2)
}

// Theorem 4 coefficients at (alpha, beta, Gamma, Omega): returns (v, c, rho(P));
// v and c are missing when P is not stable (the I(1) assumption fails).
real rowvector cvr_bcparts(real matrix a, real matrix bl, real matrix Gm, real matrix Om)
{
    real matrix P, Q, Sg, Sgi, K2, Vx, Im, A, W, Pv
    complex rowvector ev
    real scalar r, m, rho, v, c1, c2, it, term

    r = cols(a)
    cvr_jpq(a, bl, Gm, P, Q)
    m   = rows(P)
    if (hasmissing(P) | hasmissing(Om)) {
        return((., ., .))
    }
    ev  = eigenvalues(P)
    rho = max(abs(ev))
    if (missing(rho)) {
        return((., ., .))
    }
    if (rho >= 1 - 1e-8) {
        return((., ., rho))
    }
    Sg  = cvr_lyap(P, Q * Om * Q')
    Sgi = invsym(Sg)
    K2  = invsym(a' * invsym(Om) * a)
    if (hasmissing(Sgi) | hasmissing(K2)) {
        return((., ., rho))
    }
    Vx = J(m, m, 0)
    Vx[|1, 1 \ r, m|] = K2 * Sgi[|1, 1 \ r, m|]
    Im = I(m)
    v  = trace(Vx)
    c1 = trace(P * luinv(Im + P) * Vx)
    A  = (Im - P) * Vx
    if (m <= 40) {
        W  = luinv(I(m*m) - P # P)
        c2 = trace((P # A) * W)
    }
    else {
        // [I x I - P x P]^-1 = sum_v P^v x P^v, so the trace is
        // sum_v tr(P^(v+1)) tr(A P^v)
        c2 = 0
        Pv = Im
        for (it = 0; it <= 200000; it = it + 1) {
            term = trace(Pv * P) * trace(A * Pv)
            c2 = c2 + term
            Pv = Pv * P
            if (max(abs(Pv)) < 1e-14) {
                break
            }
        }
    }
    if (missing(v) | missing(c1) | missing(c2)) {
        return((., ., rho))
    }
    return((v, c1 + c2, rho))
}

// Corollary 6 in terms of s# = cols(H#) (see the block comment above)
real scalar cvr_bcformula(real scalar v, real scalar c, real scalar p, real scalar r,
                          real scalar sh, real scalar nD, real scalar nd,
                          real scalar k, real scalar T)
{
    real scalar cd, b1, b2
    if (missing(v) | missing(c)) {
        return(.)
    }
    cd = nd * v
    b1 = 0.5 * (p + sh - r + 1 + nD) + nd + k * p
    b2 = (2 * p + sh - 3 * r - 1 + nD) * v + 2 * (c + cd)
    return(1 + b1 / T + b2 / (T * r))
}

// BC at the estimates F (restricted H0 estimates): returns (BC, v, c, rho(P))
real rowvector cvr_bartlett(struct cv_joh scalar Jh, struct cvr_fit scalar F,
                            real scalar k, real scalar sh)
{
    real matrix bl, Gm
    real rowvector pr
    real scalar p, r, nD, nd, bc

    p  = Jh.p
    r  = cols(F.b)
    nD = Jh.p1 - Jh.p
    nd = Jh.q - (k - 1) * p
    bl = F.b[|1, 1 \ p, r|]
    if (k > 1) {
        Gm = F.Psi[|1, 1 \ p, (k-1)*p|]
    }
    else {
        Gm = J(p, 0, .)
    }
    pr = cvr_bcparts(F.a, bl, Gm, F.Sig)
    bc = cvr_bcformula(pr[1], pr[2], p, r, sh, nD, nd, k, Jh.T)
    return((bc, pr))
}

// ---------------------------------------------------------------------------
//  Identification check, Boswijk & Doornik (2004) Theorem 1 / eq (20) with the
//  linear Jacobian eq (40): J(theta) = [(I_p x beta#) G : (alpha x I_p1) H]
//  (here with the normalisation built into H, h).  Numerical rank by Doornik
//  (1995, Def. 1) as quoted in B&D Sec. 3.1: singular values
//  w_i > 1e4 eps_m max_i sum_j |a_ij|.  Returns (rank, number of columns l).
// ---------------------------------------------------------------------------

real rowvector cvr_rankJ(struct cvr_hyp scalar Hy, struct cvr_fit scalar F)
{
    real matrix Jm
    real colvector sv
    real scalar p, p1, tol
    p  = rows(F.a)
    p1 = rows(F.b)
    Jm = J(p * p1, 0, .)
    if (Hy.lpsi > 0) {
        Jm = Jm, (I(p) # F.b) * Hy.G
    }
    if (Hy.lphi > 0) {
        Jm = Jm, (F.a # I(p1)) * Hy.H
    }
    if (cols(Jm) == 0) {
        return((0, 0))
    }
    if (hasmissing(Jm)) {
        return((., cols(Jm)))
    }
    sv  = svdsv(Jm)
    tol = 1e4 * epsilon(1) * max(rowsum(abs(Jm)))
    return((sum(sv :> tol), cols(Jm)))
}

// ---------------------------------------------------------------------------
//  Statistics on one data set (original or bootstrap): unrestricted PML,
//  restricted PML, LR_T and sandwich Wald.  Returns 0 on failure.
// ---------------------------------------------------------------------------

real scalar cvr_stats(struct cv_joh scalar Jh, struct cvr_hyp scalar Hy,
                      real matrix c, real matrix cp, real scalar r,
                      real scalar tol, real scalar maxit,
                      struct cvr_fit scalar Fu, struct cvr_fit scalar Fr,
                      real scalar lr, real scalar wd,
                      real matrix th, real matrix Vth)
{
    real scalar got
    lr = .
    wd = .
    if (cvr_unres(Jh, r, c, Fu) == 0) {
        return(0)
    }
    got = 0
    if (Hy.jform == 1) {
        got = cvr_closedH(Jh, Hy.Hj, r, c, Fr)
    }
    if (Hy.jform == 0 | Hy.hasa == 1 | got == 0) {
        if (got == 0) {
            Fr.a = Fu.a
            Fr.b = Fu.b
        }
        cvr_switch(Jh, Hy, Fr, tol, maxit)
    }
    if (Fr.ok == 0) {
        return(0)
    }
    if (missing(Fr.ld)) {
        return(0)
    }
    lr = Jh.T * (Fr.ld - Fu.ld)
    wd = cvr_wald(Jh, Fu, cp, Hy.R, Hy.q, th, Vth)
    return(1)
}

// ---------------------------------------------------------------------------
//  Bootstrap, BCRT (2016) Algorithm 1 (wild) and its iid variant
// ---------------------------------------------------------------------------

void cvr_boot(real matrix Y, real scalar k, real matrix D1, real matrix D2,
              struct cv_joh scalar Jd, struct cvr_hyp scalar Hy,
              struct cvr_fit scalar Fr, real matrix c, real matrix cp,
              string scalar method, string scalar mult, real scalar B,
              real scalar tol, real scalar maxit, real scalar dots,
              real matrix LRb, real matrix Wb, real scalar fails,
              real scalar nexp, real scalar nonconv)
{
    struct cv_joh scalar Jb
    struct cvr_fit scalar Fub, Frb
    real matrix Pi, Ec, Gm, eps, Ys, Z0, Z1, Z2, Vb
    real colvector w, mods
    real matrix thb
    real scalar p, T, r, ib, okb, lrb, wdb

    p  = Jd.p
    T  = Jd.T
    r  = cols(Fr.b)
    thb = J(0, 1, .)
    Vb  = J(0, 0, .)
    lrb = .
    wdb = .
    // (i) restricted estimates and recentred restricted residuals
    Pi = Fr.a * Fr.b'
    Ec = Fr.E :- mean(Fr.E)
    if (k > 1) {
        Gm = Fr.Psi[|1, 1 \ p, p*(k-1)|]
    }
    else {
        Gm = J(p, 0, .)
    }
    mods = cv_roots(Pi[., 1..p], Gm, k)
    nexp = sum(mods :> 1 + 1e-6)
    LRb  = J(B, 1, .)
    Wb   = J(B, 1, .)
    fails   = 0
    nonconv = 0
    for (ib = 1; ib <= B; ib = ib + 1) {
        if (method == "iid") {
            eps = Ec[ceil(runiform(T, 1) :* T), .]
        }
        else {
            w   = cv_mult(T, mult)
            eps = Ec :* w
        }
        // (ii) recursion with data initial values and deterministics
        Ys = cv_simvecm(Y[|1, 1 \ k, p|], Pi, Fr.Psi, eps, D1, D2, k)
        cv_build(Ys, k, D1, D2, Z0, Z1, Z2)
        Jb  = cv_johansen(Z0, Z1, Z2)
        okb = 0
        lrb = .
        wdb = .
        if (Jb.ok == 1) {
            if (hasmissing(Jb.lam) == 0) {
                if (max(Jb.lam) < 1) {
                    // (iii) statistic re-computed exactly as on the data
                    okb = cvr_stats(Jb, Hy, c, cp, r, tol, maxit, Fub, Frb, lrb, wdb, thb, Vb)
                }
            }
        }
        if (okb == 1) {
            if (missing(lrb) | missing(wdb)) {
                okb = 0
            }
        }
        if (okb == 0) {
            fails = fails + 1
            if (fails > 10 * B) {
                errprintf("bootstrap failed repeatedly (singular or explosive bootstrap samples)\n")
                exit(430)
            }
            ib = ib - 1
            continue
        }
        LRb[ib] = lrb
        Wb[ib]  = wdb
        if (Frb.conv == 0) {
            nonconv = nonconv + 1
        }
        if (dots) {
            if (mod(ib, 50) == 0) {
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

// ---------------------------------------------------------------------------
//  Main entry point for -cointvol restrict-
//  Options are read from the calling ado's locals.
// ---------------------------------------------------------------------------

void cvr_main(string scalar vars, string scalar touse, real scalar k,
              string scalar dcase, real scalar r, string scalar nlist)
{
    struct cv_joh scalar Jd
    struct cvr_hyp scalar Hy
    struct cvr_fit scalar Fu, Fr
    real matrix Y, D1, D2, Z0, Z1, Z2, c, cp, Hj, Hm, B0, Rb0, Ra0, Ra1, rw
    real matrix res, LRB, WB, Vth, seB, seA, qb0, qa0, qa1, th, LRb, Wb
    real colvector sv
    real rowvector nidx, eidx, v, bcv, rkj
    real scalar p, p1, d1, T, B, tol, maxit, dots, bart, sep, eta
    real scalar hasb, hasa, jform, nh, ih, useb, usea, lr, wd, bc
    real scalar fails, nexp, nonconv, i, j, n, m, ref, lb
    string scalar method, mult, pvtype, btype, bm1, bm2, am1, am2
    string rowvector hl

    method = st_local("method")
    mult   = st_local("multiplier")
    pvtype = st_local("pvalue")
    B      = strtoreal(st_local("reps"))
    tol    = strtoreal(st_local("tolerance"))
    maxit  = strtoreal(st_local("iterate"))
    dots   = strtoreal(st_local("dots"))
    bart   = (st_local("bartlett") != "")
    sep    = (st_local("separate") != "")
    eta    = 1 - strtoreal(st_local("level")) / 100
    btype  = st_local("__btype")
    bm1    = st_local("__bm1")
    bm2    = st_local("__bm2")
    am1    = st_local("__am1")
    am2    = st_local("__am2")
    eidx   = strtoreal(tokens(st_local("__eidx")))
    if (method == "asy") {
        B = 1
    }
    lr  = .
    wd  = .
    bc  = .
    th  = J(0, 1, .)
    Vth = J(0, 0, .)
    LRb = J(0, 1, .)
    Wb  = J(0, 1, .)
    fails   = 0
    nexp    = 0
    nonconv = 0

    // ---- data, moment matrices and unrestricted RRR --------------------
    Y = st_data(., tokens(vars), touse)
    cv_detmats(rows(Y), dcase, D1, D2)
    cv_build(Y, k, D1, D2, Z0, Z1, Z2)
    Jd = cv_johansen(Z0, Z1, Z2)
    if (Jd.ok == 0) {
        errprintf("moment matrices are singular; check for collinear or constant series\n")
        exit(506)
    }
    p  = Jd.p
    p1 = Jd.p1
    d1 = p1 - p
    T  = Jd.T
    nidx = strtoreal(tokens(nlist))
    cvr_normmats(p, d1, nidx, c, cp)

    // ---- hypothesis on beta --------------------------------------------
    hasb  = (btype != "none")
    jform = 0
    Hj  = J(0, 0, .)
    Rb0 = J(0, (p1 - r) * r, .)
    qb0 = J(0, 1, .)
    if (btype == "spreads") {
        ref = strtoreal(st_local("__sref"))
        Hm  = J(p, p - 1, 0)
        m   = 0
        for (i = 1; i <= p; i = i + 1) {
            if (i != ref) {
                m = m + 1
                Hm[i, m]   = 1
                Hm[ref, m] = -1
            }
        }
        Hj    = cvr_addd1(Hm, d1)
        jform = 1
    }
    if (btype == "knownnum" | btype == "knownmat") {
        if (btype == "knownnum") {
            v = strtoreal(tokens(bm1))
            n = cols(v)
            B0 = J(0, 0, .)
            if (n == p * r) {
                B0 = colshape(v, p)'
            }
            if (d1 > 0) {
                if (n == p1 * r) {
                    B0 = colshape(v, p1)'
                }
            }
            if (rows(B0) == 0) {
                errprintf("known(): expected %g (or %g) numbers, found %g\n", p*r, p1*r, n)
                exit(198)
            }
        }
        else {
            B0 = st_matrix(bm1)
        }
        if (cols(B0) != r | (rows(B0) != p & rows(B0) != p1)) {
            errprintf("known(): beta must be %g x %g (levels) or %g x %g (with restricted deterministics)\n", p, r, p1, r)
            exit(198)
        }
        if (rows(B0) == p) {
            Hj = cvr_addd1(B0, d1)
        }
        else {
            Hj = B0
        }
        jform = 1
    }
    if (btype == "H") {
        Hm = st_matrix(bm1)
        if (rows(Hm) != p & rows(Hm) != p1) {
            errprintf("hmatrix(): H must have %g rows (levels) or %g rows (with restricted deterministics)\n", p, p1)
            exit(198)
        }
        if (rows(Hm) == p) {
            Hj = cvr_addd1(Hm, d1)
        }
        else {
            Hj = Hm
        }
        jform = 1
    }
    if (jform == 1) {
        if (rank(Hj) < cols(Hj)) {
            errprintf("the matrix H of beta# = H*phi does not have full column rank\n")
            exit(198)
        }
        if (cols(Hj) < r) {
            errprintf("beta# = H*phi needs at least r = %g columns in H (found %g)\n", r, cols(Hj))
            exit(198)
        }
        if (cols(Hj) >= p1) {
            errprintf("beta# = H*phi with %g columns imposes no restriction (p# = %g)\n", cols(Hj), p1)
            exit(198)
        }
        if (rank(c' * Hj) < r) {
            errprintf("the normalisation in normalize() is incompatible with beta# = H*phi;\n")
            errprintf("choose normalising variables that are not excluded by H\n")
            exit(198)
        }
    }
    if (btype == "R") {
        Rb0 = st_matrix(bm1)
        if (cols(Rb0) != (p1 - r) * r) {
            errprintf("bconstraints(): R_b must have (p#-r)r = %g columns (found %g)\n", (p1-r)*r, cols(Rb0))
            exit(198)
        }
        if (bm2 != "") {
            qb0 = st_matrix(bm2)
            if (rows(qb0) == 1 & cols(qb0) > 1) {
                qb0 = qb0'
            }
        }
        else {
            qb0 = J(rows(Rb0), 1, 0)
        }
        if (rows(qb0) != rows(Rb0) | cols(qb0) != 1) {
            errprintf("bconstraints(): q_b must be a vector with as many elements as R_b has rows\n")
            exit(198)
        }
    }

    // ---- hypothesis on alpha (vec alpha' = rows of alpha stacked) ------
    Ra0 = J(0, p * r, .)
    qa0 = J(0, 1, .)
    for (i = 1; i <= cols(eidx); i = i + 1) {
        for (j = 1; j <= r; j = j + 1) {
            rw = J(1, p * r, 0)
            rw[1, (eidx[i] - 1) * r + j] = 1
            Ra0 = Ra0 \ rw
            qa0 = qa0 \ 0
        }
    }
    if (am1 != "") {
        Ra1 = st_matrix(am1)
        if (cols(Ra1) != p * r) {
            errprintf("aconstraints(): R_a must have p*r = %g columns (found %g)\n", p*r, cols(Ra1))
            exit(198)
        }
        if (am2 != "") {
            qa1 = st_matrix(am2)
            if (rows(qa1) == 1 & cols(qa1) > 1) {
                qa1 = qa1'
            }
        }
        else {
            qa1 = J(rows(Ra1), 1, 0)
        }
        if (rows(qa1) != rows(Ra1) | cols(qa1) != 1) {
            errprintf("aconstraints(): q_a must be a vector with as many elements as R_a has rows\n")
            exit(198)
        }
        Ra0 = Ra0 \ Ra1
        qa0 = qa0 \ qa1
    }
    hasa = (rows(Ra0) > 0)
    if (hasb == 0 & hasa == 0) {
        errprintf("no hypothesis specified\n")
        exit(198)
    }

    // ---- list of hypotheses ---------------------------------------------
    nh = 1
    if (hasb == 1 & hasa == 1 & sep == 1) {
        nh = 3
    }
    hl = J(1, nh, "")
    // columns: 1 df, 2 LR, 3 p asy, 4 p boot, 5 boot cv LR, 6 BC, 7 LR/BC,
    //   8 p(LR/BC), 9 Wald, 10 p asy, 11 p boot, 12 boot cv Wald, 13 iter,
    //   14 converged, 15 explosive roots of bootstrap DGP, 16 redrawn, 17 non-conv,
    //   18 rank of J(theta) at the restricted MLE, 19 free parameters l
    //   (Boswijk & Doornik 2004, eqs 20, 40), 20 v(alpha), 21 c(alpha) of the
    //   Bartlett factor (Johansen 2000, Thm 4).
    res = J(nh, 21, .)
    LRB = J(B, nh, .)
    WB  = J(B, nh, .)
    for (ih = 1; ih <= nh; ih = ih + 1) {
        useb = hasb
        usea = hasa
        if (nh == 3) {
            if (ih == 1) {
                usea = 0
            }
            if (ih == 2) {
                useb = 0
            }
        }
        if (useb == 1 & usea == 1) {
            hl[ih] = "joint"
        }
        if (useb == 1 & usea == 0) {
            hl[ih] = "beta"
        }
        if (useb == 0 & usea == 1) {
            hl[ih] = "alpha"
        }
        Hy = cvr_mkhyp(p, p1, r, c, cp, useb, usea, jform, Hj, Rb0, qb0, Ra0, qa0)
        if (cvr_stats(Jd, Hy, c, cp, r, tol, maxit, Fu, Fr, lr, wd, th, Vth) == 0) {
            errprintf("PML estimation failed (normalisation not identified or singular estimates);\n")
            errprintf("try other normalising variables with normalize()\n")
            exit(430)
        }
        res[ih, 1]  = Hy.df
        res[ih, 2]  = lr
        res[ih, 3]  = chi2tail(Hy.df, max((lr, 0)))
        res[ih, 9]  = wd
        res[ih, 10] = chi2tail(Hy.df, max((wd, 0)))
        res[ih, 13] = Fr.iter
        res[ih, 14] = Fr.conv
        rkj = cvr_rankJ(Hy, Fr)
        res[ih, 18] = rkj[1]
        res[ih, 19] = rkj[2]
        if (bart == 1 & Hy.jform == 1 & Hy.hasa == 0) {
            bcv = cvr_bartlett(Jd, Fr, k, Hy.s)
            bc  = bcv[1]
            res[ih, 6]  = bc
            res[ih, 20] = bcv[2]
            res[ih, 21] = bcv[3]
            if (bc < . & bc > 0) {
                res[ih, 7] = lr / bc
                res[ih, 8] = chi2tail(Hy.df, max((lr / bc, 0)))
            }
        }
        if (method != "asy") {
            if (dots) {
                printf("{txt}H0 (%s): ", hl[ih])
                displayflush()
            }
            cvr_boot(Y, k, D1, D2, Jd, Hy, Fr, c, cp, method, mult, B, tol, maxit, dots, LRb, Wb, fails, nexp, nonconv)
            LRB[., ih] = LRb
            WB[., ih]  = Wb
            if (pvtype == "plusone") {
                res[ih, 4]  = (sum(LRb :>= lr) + 1) / (B + 1)
                res[ih, 11] = (sum(Wb :>= wd) + 1) / (B + 1)
            }
            else {
                res[ih, 4]  = mean(LRb :> lr)
                res[ih, 11] = mean(Wb :> wd)
            }
            res[ih, 5]  = cv_quantile(LRb, 1 - eta)
            res[ih, 12] = cv_quantile(Wb, 1 - eta)
            res[ih, 15] = nexp
            res[ih, 16] = fails
            res[ih, 17] = nonconv
        }
    }

    // ---- export (Fr = estimates under the last (main) hypothesis) -------
    lb  = (p1 - r) * r
    sv  = sqrt(diagonal(Vth))
    seB = cp * colshape(sv[|1 \ lb|]', p1 - r)'
    for (j = 1; j <= r; j = j + 1) {
        seB[nidx[j], .] = J(1, r, .)
    }
    seA = colshape(sv[|lb+1 \ lb+p*r|]', r)

    st_matrix("__cvr_res", res)
    st_matrix("__cvr_alpha", Fu.a)
    st_matrix("__cvr_beta", Fu.b)
    st_matrix("__cvr_Pi", Fu.a * Fu.b')
    st_matrix("__cvr_Sig", Fu.Sig)
    st_matrix("__cvr_seA", seA)
    st_matrix("__cvr_seB", seB)
    st_matrix("__cvr_theta", th')
    st_matrix("__cvr_V", Vth)
    st_matrix("__cvr_lam", Jd.lam')
    st_matrix("__cvr_alpha_r", Fr.a)
    st_matrix("__cvr_beta_r", Fr.b)
    st_matrix("__cvr_Pi_r", Fr.a * Fr.b')
    st_matrix("__cvr_Sig_r", Fr.Sig)
    if (cols(Fu.Psi) > 0) {
        st_matrix("__cvr_Psi", Fu.Psi)
        st_matrix("__cvr_Psi_r", Fr.Psi)
    }
    if (method != "asy") {
        st_matrix("__cvr_LRB", LRB)
        st_matrix("__cvr_WB", WB)
    }
    st_numscalar("__cvr_T", T)
    st_numscalar("__cvr_nh", nh)
    st_numscalar("__cvr_ll", -T / 2 * (p * (1 + ln(2 * pi())) + Fu.ld))
    st_numscalar("__cvr_ll_r", -T / 2 * (p * (1 + ln(2 * pi())) + Fr.ld))
    st_numscalar("__cvr_vmiss", hasmissing(Vth))
    st_numscalar("__cvr_s", Hy.s)
    st_local("__hlabels", invtokens(hl))
}

end
