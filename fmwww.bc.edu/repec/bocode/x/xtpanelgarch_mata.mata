*! xtpanelgarch_mata 1.0.0  06nov2026
*! Mata engine for the xtpanelgarch suite
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane
*
* Build:   do xtpanelgarch_mata.mata      (creates lxtpanelgarch.mlib in the current dir)

version 14.0
mata:
mata clear

// ------------------------------------------------------------------------
// Cermeño-Grier (2001, 2006) panel GARCH / DPD-CCV data container
// ------------------------------------------------------------------------
struct xtpg_cg {
    real scalar N, T, k, q, p, meanfe, varfe, archm, tarch, m, cov, egarch
    real scalar dist, np, npair
    real matrix Y, X, Z, pairs, SelD, SelO
    real colvector off, pa, pb
}

// parameter layout -------------------------------------------------------
// mean     : mu (1 or N) | beta (k)
// ARCHM    : kappa (archm>0)
// variance : alpha (1 or N) | gamma (q) | delta (p) | lambda (tarch) | theta (m)
// cov      : common: eta, rho, lam ; pair: eta_ij (npair), rho, lam ;
//            ccc: r_ij (npair)
// dist     : t -> df
real rowvector _xtpg_cg_layout(struct xtpg_cg scalar D)
{
    real rowvector L
    real scalar nmu, nal, ncv
    nmu = D.N
    if (D.meanfe == 0) nmu = 1
    nal = D.N
    if (D.varfe == 0) nal = 1
    ncv = 0
    if (D.cov == 1) ncv = 3
    if (D.cov == 2) ncv = D.npair + 2
    if (D.cov == 3) ncv = D.npair
    // L = (nmu, k, archm?, nal, q, p, tarch, m, ncv, dist)
    L = (nmu, D.k, (D.archm > 0), nal, D.q, D.p, D.tarch, D.m, ncv, (D.dist == 2))
    return(L)
}

real colvector _xtpg_cg_offsets(real rowvector L)
{
    real colvector o
    real scalar j
    o = J(cols(L) + 1, 1, 0)
    o[1] = 0
    for (j = 1; j <= cols(L); j = j + 1) {
        o[j + 1] = o[j] + L[j]
    }
    return(o)
}

// one-period-ahead recursion; returns log-likelihood contributions per t
// U : T x N residuals, S2 : T x N variances, CV : T x npair covariances
real colvector _xtpg_cg_ll(struct xtpg_cg scalar D, real rowvector b,
    real matrix U, real matrix S2, real matrix CV)
{
    real rowvector L, mu, beta, alpha, gam, del, theta, eta, rr, AL, h, e, S0, Cv0, lamv, lh, zz
    real colvector o, ll, xb, zt
    real matrix LH, ZZ
    real scalar kap, lam, rho, lcv, nu, j, t, l, s
    real matrix E, Om, Ch, R, ZT, U2
    real scalar lc2pi, ldet, qform

    L = _xtpg_cg_layout(D)
    o = _xtpg_cg_offsets(L)
    lc2pi = ln(2 * pi())

    mu = b[(o[1] + 1)..o[2]]
    beta = J(1, 0, .)
    if (L[2] > 0) beta = b[(o[2] + 1)..o[3]]
    kap = 0
    if (L[3] > 0) kap = b[o[3] + 1]
    alpha = b[(o[4] + 1)..o[5]]
    gam = J(1, 0, .)
    if (L[5] > 0) gam = b[(o[5] + 1)..o[6]]
    del = J(1, 0, .)
    if (L[6] > 0) del = b[(o[6] + 1)..o[7]]
    lam = 0
    if (L[7] > 0) lam = b[o[7] + 1]
    lamv = J(1, 0, .)
    if (L[7] > 0) lamv = b[(o[7] + 1)..o[8]]
    theta = J(1, 0, .)
    if (L[8] > 0) theta = b[(o[8] + 1)..o[9]]
    eta = J(1, 0, .)
    rho = 0
    lcv = 0
    rr = J(1, 0, .)
    if (D.cov == 1) {
        eta = J(1, D.npair, b[o[9] + 1])
        rho = b[o[9] + 2]
        lcv = b[o[9] + 3]
    }
    if (D.cov == 2) {
        eta = b[(o[9] + 1)..(o[9] + D.npair)]
        rho = b[o[9] + D.npair + 1]
        lcv = b[o[9] + D.npair + 2]
    }
    if (D.cov == 3) {
        rr = b[(o[9] + 1)..(o[9] + D.npair)]
    }
    nu = .
    if (L[10] > 0) {
        nu = b[o[10] + 1]
        if (nu <= 2) return(J(D.T, 1, .))
    }

    // mean residuals without the in-mean term -> presample values
    xb = J(D.N * D.T, 1, mu[1])
    if (D.meanfe) xb = mu' # J(D.T, 1, 1)
    if (D.k > 0) xb = xb + D.X * beta'
    E = D.Y - rowshape(xb, D.N)'
    S0 = colsum(E :* E) / D.T
    Cv0 = J(1, D.npair, 0)
    if (D.npair > 0) Cv0 = colsum(E[., D.pa] :* E[., D.pb]) / D.T

    AL = J(1, D.N, alpha[1])
    if (D.varfe) AL = alpha
    ZT = J(D.T, D.N, 0)
    if (D.m > 0) ZT = rowshape(D.Z * theta', D.N)'

    U = J(D.T, D.N, .)
    S2 = J(D.T, D.N, .)
    CV = J(D.T, D.npair, .)
    ll = J(D.T, 1, .)
    U2 = J(D.T, D.N, .)

    if (D.cov == 3) {
        R = I(D.N)
        for (j = 1; j <= D.npair; j = j + 1) {
            R[D.pa[j], D.pb[j]] = rr[j]
            R[D.pb[j], D.pa[j]] = rr[j]
        }
        Ch = cholesky(R)
        if (hasmissing(Ch)) return(J(D.T, 1, .))
    }

    if (D.egarch) {
        LH = J(D.T, D.N, .)
        ZZ = J(D.T, D.N, .)
    }
    for (t = 1; t <= D.T; t = t + 1) {
        h = AL + ZT[t, .]
        if (D.egarch) {
            // Nelson (1991): ln h = w + sum[th z + g(|z| - sqrt(2/pi))] + sum d ln h ; presample z = 0, ln h = ln S0
            lh = h
            for (l = 1; l <= D.q; l = l + 1) {
                s = t - l
                if (s >= 1) {
                    lh = lh + lamv[l] * ZZ[s, .] + gam[l] * (abs(ZZ[s, .]) :- sqrt(2 / pi()))
                }
            }
            for (l = 1; l <= D.p; l = l + 1) {
                s = t - l
                if (s >= 1) {
                    lh = lh + del[l] * LH[s, .]
                }
                else {
                    lh = lh + del[l] * ln(S0)
                }
            }
            if (max(abs(lh)) > 700) return(J(D.T, 1, .))
            LH[t, .] = lh
            h = exp(lh)
        }
        else {
        for (l = 1; l <= D.q; l = l + 1) {
            s = t - l
            if (s >= 1) {
                h = h + gam[l] * U2[s, .]
            }
            else {
                h = h + gam[l] * S0
            }
        }
        for (l = 1; l <= D.p; l = l + 1) {
            s = t - l
            if (s >= 1) {
                h = h + del[l] * S2[s, .]
            }
            else {
                h = h + del[l] * S0
            }
        }
        if (D.tarch) {
            if (t >= 2) {
                h = h + lam * (U[t - 1, .] :< 0) :* U2[t - 1, .]
            }
            else {
                h = h + lam * S0 / 2
            }
        }
        }
        if (min(h) <= 0) return(J(D.T, 1, .))
        if (hasmissing(h)) return(J(D.T, 1, .))
        S2[t, .] = h
        e = E[t, .]
        if (D.archm == 1) e = e - kap * sqrt(h)
        if (D.archm == 2) e = e - kap * h
        if (D.archm == 3) e = e - kap * ln(h)
        U[t, .] = e
        U2[t, .] = e :* e
        if (D.egarch) ZZ[t, .] = e :/ sqrt(h)
        if (D.cov == 1 | D.cov == 2) {
            if (t >= 2) {
                CV[t, .] = eta + rho * (U[t - 1, D.pa] :* U[t - 1, D.pb]) + lcv * CV[t - 1, .]
            }
            else {
                CV[t, .] = eta + (rho + lcv) * Cv0
            }
        }
        if (D.cov == 3) {
            CV[t, .] = rr :* sqrt(h[D.pa] :* h[D.pb])
        }
        if (D.cov > 0) {
            Om = colshape(D.SelD * h' + D.SelO * CV[t, .]', D.N)
            Ch = cholesky(Om)
            if (hasmissing(Ch)) return(J(D.T, 1, .))
            ldet = 2 * sum(ln(diagonal(Ch)))
            zt = solvelower(Ch, e')
            qform = cross(zt, zt)
            if (D.dist == 1) {
                ll[t] = -0.5 * (D.N * lc2pi + ldet + qform)
            }
            else {
                ll[t] = lngamma((nu + D.N) / 2) - lngamma(nu / 2) - (D.N / 2) * ln(pi() * (nu - 2)) -
                    0.5 * ldet - ((nu + D.N) / 2) * ln(1 + qform / (nu - 2))
            }
        }
    }
    if (D.cov == 0) {
        if (D.dist == 1) {
            ll = -0.5 * rowsum(lc2pi :+ ln(S2) + U2 :/ S2)
        }
        else {
            ll = rowsum((lngamma((nu + 1) / 2) - lngamma(nu / 2) - 0.5 * ln(pi() * (nu - 2))) :-
                0.5 * ln(S2) :- ((nu + 1) / 2) * ln(1 :+ U2 :/ (S2 * (nu - 2))))
        }
    }
    return(ll)
}

void _xtpg_cg_eval(real scalar todo, real rowvector b, struct xtpg_cg scalar D,
    real colvector lnf, real matrix g, real matrix H)
{
    real matrix U, S2, CV
    lnf = _xtpg_cg_ll(D, b, U, S2, CV)
}

// driver called from the ado ---------------------------------------------
void _xtpg_cg_fit(string scalar yname, string scalar xnames, string scalar znames,
    string scalar touse, real scalar N, real scalar T,
    real scalar q, real scalar p, real scalar meanfe, real scalar varfe,
    real scalar archm, real scalar tarch, real scalar cov, real scalar dist,
    string scalar b0name, string scalar tech, real scalar maxit,
    string scalar vcetype, real scalar showlog, real scalar search)
{
    struct xtpg_cg scalar D
    real colvector y, ll
    real matrix X, Z, U, S2, CV, V
    real rowvector b0, b, bbest, bfb
    real matrix CAND
    real scalar i, j, c, S, best, nfail
    transmorphic Sopt, Sbest

    y = st_data(., yname, touse)
    D.N = N
    D.T = T
    // y is unit-major (unit 1: t=1..T, unit 2: ...) -> N x T, transposed to T x N
    D.Y = rowshape(y, N)'
    D.k = 0
    D.X = J(N * T, 0, .)
    if (xnames != "") {
        X = st_data(., tokens(xnames), touse)
        D.X = X
        D.k = cols(X)
    }
    D.m = 0
    D.Z = J(N * T, 0, .)
    if (znames != "") {
        Z = st_data(., tokens(znames), touse)
        D.Z = Z
        D.m = cols(Z)
    }
    D.off = (0::(N - 1)) * T
    D.q = q
    D.p = p
    D.meanfe = meanfe
    D.varfe = varfe
    D.archm = archm
    D.tarch = tarch
    D.egarch = 0
    if (tarch < 0) {
        D.egarch = 1
        D.tarch = -tarch
    }
    D.cov = cov
    D.dist = dist
    D.npair = 0
    D.pairs = J(0, 2, .)
    if (cov > 0) {
        D.npair = N * (N - 1) / 2
        D.pairs = J(D.npair, 2, .)
        c = 0
        for (i = 1; i <= N - 1; i = i + 1) {
            for (j = i + 1; j <= N; j = j + 1) {
                c = c + 1
                D.pairs[c, .] = (i, j)
            }
        }
    }
    b0 = st_matrix(b0name)
    D.np = cols(b0)
    D.pa = J(0, 1, .)
    D.pb = J(0, 1, .)
    D.SelD = J(N * N, N, 0)
    D.SelO = J(N * N, 0, 0)
    for (i = 1; i <= N; i = i + 1) D.SelD[(i - 1) * N + i, i] = 1
    if (D.npair > 0) {
        D.pa = D.pairs[., 1]
        D.pb = D.pairs[., 2]
        D.SelO = J(N * N, D.npair, 0)
        for (j = 1; j <= D.npair; j = j + 1) {
            D.SelO[(D.pb[j] - 1) * N + D.pa[j], j] = 1
            D.SelO[(D.pa[j] - 1) * N + D.pb[j], j] = 1
        }
    }

    // phase 1: screen starting values (cheap grid on the likelihood),
    //          short BFGS runs from the best `search' candidates
    CAND = b0
    if (search > 0) CAND = _xtpg_cg_search(D, b0, search)
    best = -1e300
    bbest = b0
    nfail = 0
    if (rows(CAND) > 1) {
        for (c = 1; c <= rows(CAND); c = c + 1) {
            ll = _xtpg_cg_ll(D, CAND[c, .], U, S2, CV)
            if (hasmissing(ll)) continue
            Sopt = optimize_init()
            optimize_init_evaluator(Sopt, &_xtpg_cg_eval())
            optimize_init_evaluatortype(Sopt, "gf0")
            optimize_init_argument(Sopt, 1, D)
            optimize_init_params(Sopt, CAND[c, .])
            optimize_init_technique(Sopt, "bfgs")
            optimize_init_conv_maxiter(Sopt, 25)
            optimize_init_conv_warning(Sopt, "off")
            optimize_init_singularHmethod(Sopt, "hybrid")
            optimize_init_tracelevel(Sopt, "none")
            S = _optimize(Sopt)
            if (S != 0) {
                nfail = nfail + 1
                continue
            }
            if (showlog == 1) {
                printf("{txt}screening start %g of %g: log likelihood = {res}%12.4f\n", c, rows(CAND), optimize_result_value(Sopt))
            }
            if (optimize_result_value(Sopt) > best) {
                best = optimize_result_value(Sopt)
                bbest = optimize_result_params(Sopt)
            }
        }
    }
    else {
        ll = _xtpg_cg_ll(D, b0, U, S2, CV)
        if (!hasmissing(ll)) best = sum(ll)
    }
    if (best <= -1e300) {
        errprintf("initial values give an infeasible likelihood from every start; supply from()\n")
        st_numscalar("__xtpg_rc", 430)
        return
    }

    // phase 2: full optimisation from the best screened point
    Sopt = optimize_init()
    optimize_init_evaluator(Sopt, &_xtpg_cg_eval())
    optimize_init_evaluatortype(Sopt, "gf0")
    optimize_init_argument(Sopt, 1, D)
    optimize_init_params(Sopt, bbest)
    optimize_init_technique(Sopt, tech)
    optimize_init_conv_maxiter(Sopt, maxit)
    optimize_init_singularHmethod(Sopt, "hybrid")
    optimize_init_tracelevel(Sopt, "none")
    if (showlog == 1) optimize_init_tracelevel(Sopt, "value")
    S = _optimize(Sopt)
    // fallbacks: Newton-Raphson, then BHHH, from the best point reached
    if (S != 0) {
        bfb = bbest
        if (!hasmissing(optimize_result_params(Sopt))) {
            ll = _xtpg_cg_ll(D, optimize_result_params(Sopt), U, S2, CV)
            if (!hasmissing(ll)) bfb = optimize_result_params(Sopt)
        }
        printf("{txt}(%s failed: %s; switching to nr)\n", tech, optimize_result_errortext(Sopt))
        optimize_init_params(Sopt, bfb)
        optimize_init_technique(Sopt, "nr")
        S = _optimize(Sopt)
    }
    if (S != 0) {
        printf("{txt}(nr failed; switching to bhhh)\n")
        optimize_init_params(Sopt, bbest)
        optimize_init_technique(Sopt, "bhhh")
        S = _optimize(Sopt)
    }
    if (S != 0) {
        errprintf("{p}optimization error: %s{p_end}\n", optimize_result_errortext(Sopt))
        st_numscalar("__xtpg_rc", S)
        return
    }
    Sbest = Sopt
    Sopt = Sbest
    st_numscalar("__xtpg_rc", 0)
    b = optimize_result_params(Sopt)
    if (vcetype == "opg") V = optimize_result_V_opg(Sopt)
    else if (vcetype == "robust") V = optimize_result_V_robust(Sopt)
    else V = optimize_result_V_oim(Sopt)
    st_matrix("__xtpg_b", b)
    st_matrix("__xtpg_V", V)
    st_numscalar("__xtpg_ll", optimize_result_value(Sopt))
    st_numscalar("__xtpg_conv", optimize_result_converged(Sopt))
    st_numscalar("__xtpg_iter", optimize_result_iterations(Sopt))
    ll = _xtpg_cg_ll(D, b, U, S2, CV)
    st_matrix("__xtpg_ll_t", ll)
    st_matrix("__xtpg_U", U)
    st_matrix("__xtpg_S2", S2)
    if (D.npair > 0) {
        st_matrix("__xtpg_CV", CV)
        st_matrix("__xtpg_pairs", D.pairs)
        st_numscalar("__xtpg_minpd", _xtpg_minpd(D, S2, CV))
    }
}

// grid search over the variance dynamics for starting values ---------------
real matrix _xtpg_cg_search(struct xtpg_cg scalar D, real rowvector b0, real scalar ns)
{
    real rowvector L, best, b, w, gs, ds
    real matrix CAND
    real colvector CLL, ord
    real colvector o, ll
    real matrix U, S2, CV
    real scalar pold, pnew, bestll, v, ig, id, iw, l, nw, gg, dd

    L = _xtpg_cg_layout(D)
    o = _xtpg_cg_offsets(L)
    if (D.q == 0) return(b0)
    if (D.egarch) return(b0)
    CAND = b0
    pold = 0
    for (l = 1; l <= D.q; l = l + 1) pold = pold + b0[o[5] + l]
    for (l = 1; l <= D.p; l = l + 1) pold = pold + b0[o[6] + l]
    best = b0
    ll = _xtpg_cg_ll(D, b0, U, S2, CV)
    bestll = -1e300
    if (!hasmissing(ll)) bestll = sum(ll)
    CLL = bestll
    if (D.p > 0) {
        gs = (0.03, 0.05, 0.10, 0.15, 0.20, 0.30)
        ds = (0.00, 0.40, 0.60, 0.75, 0.85, 0.92)
    }
    else {
        gs = (0.10, 0.20, 0.30, 0.50, 0.70, 0.90, 1.10, 1.40)
        ds = (0)
    }
    nw = 1
    if (D.q > 1) nw = 3
    for (ig = 1; ig <= cols(gs); ig = ig + 1) {
        for (id = 1; id <= cols(ds); id = id + 1) {
            gg = gs[ig]
            dd = ds[id]
            if (D.p > 0 & gg + dd >= 0.995) continue
            for (iw = 1; iw <= nw; iw = iw + 1) {
                // lag weights: equal, first-lag heavy, last-lag heavy
                w = J(1, D.q, 1 / D.q)
                if (iw == 2) {
                    w = J(1, D.q, 0.2 / max((D.q - 1, 1)))
                    w[1] = 0.8
                }
                if (iw == 3) {
                    w = J(1, D.q, 0.2 / max((D.q - 1, 1)))
                    w[D.q] = 0.8
                }
                b = b0
                for (l = 1; l <= D.q; l = l + 1) b[o[5] + l] = gg * w[l]
                for (l = 1; l <= D.p; l = l + 1) b[o[6] + l] = dd / D.p
                pnew = gg + dd
                for (l = o[4] + 1; l <= o[5]; l = l + 1) {
                    b[l] = b0[l] * max((1 - pnew, 0.05)) / max((1 - pold, 0.05))
                }
                ll = _xtpg_cg_ll(D, b, U, S2, CV)
                if (hasmissing(ll)) continue
                v = sum(ll)
                CAND = CAND \ b
                CLL = CLL \ v
            }
        }
    }
    ord = order(-CLL, 1)
    CAND = CAND[ord, .]
    if (rows(CAND) > ns) CAND = CAND[1..ns, .]
    return(CAND)
}

// smallest eigenvalue of Omega_t over t (positive-definiteness report)
real scalar _xtpg_minpd(struct xtpg_cg scalar D, real matrix S2, real matrix CV)
{
    real scalar t, j, mn, ev
    real matrix Om
    real colvector L
    mn = .
    for (t = 1; t <= D.T; t = t + 1) {
        Om = diag(S2[t, .])
        for (j = 1; j <= D.npair; j = j + 1) {
            Om[D.pairs[j, 1], D.pairs[j, 2]] = CV[t, j]
            Om[D.pairs[j, 2], D.pairs[j, 1]] = CV[t, j]
        }
        L = symeigenvalues(Om)'
        ev = min(L)
        if (ev < mn) mn = ev
    }
    return(mn)
}

// delta-method helper: value and se of a linear combination a'b
void _xtpg_lincom(string scalar bname, string scalar Vname, string scalar aname)
{
    real rowvector b, a
    real matrix V
    b = st_matrix(bname)
    V = st_matrix(Vname)
    a = st_matrix(aname)
    st_numscalar("__xtpg_lc", a * b')
    st_numscalar("__xtpg_lcse", sqrt(a * V * a'))
}

// residual cross-moment (cor = 0) or correlation (cor = 1) matrix, N x N
void _xtpg_rescov(string scalar rname, string scalar touse, real scalar N,
    real scalar T, string scalar outname, real scalar cor)
{
    real colvector r
    real matrix E, C, s
    r = st_data(., rname, touse)
    E = rowshape(r, N)'
    C = (E' * E) / T
    if (cor) {
        s = sqrt(diagonal(C))
        C = C :/ (s * s')
    }
    st_matrix(outname, C)
}

// ------------------------------------------------------------------------
// pre-tests (Cermeño-Grier 2001 sec.5, 2006 sec.10.3)
// ------------------------------------------------------------------------
// pooled OLS of y on [1 X] (optionally unit dummies instead of constant)
// returns b, se, rss in globals of the caller via pointers
void _xtpg_ols(real colvector y, real matrix X, real colvector b,
    real colvector se, real scalar rss, real scalar df)
{
    real matrix XX, iXX
    real colvector e
    XX = cross(X, X)
    iXX = invsym(XX)
    b = iXX * cross(X, y)
    e = y - X * b
    rss = cross(e, e)
    df = rows(X) - rank(XX)
    se = sqrt(diagonal(iXX) * rss / df)
}

// PACF + LM-ARCH on a T x N matrix of (squared) residual series W,
// pooled across units; lags K. Also individual-effects F test in the
// AR(1) [or AR(K)] regression with/without unit intercepts.
void _xtpg_pre_ar(real matrix W, real scalar K, string scalar outpac,
    string scalar outlm, string scalar outfe, real scalar arfe)
{
    real scalar N, T, k, i, l, rss, df, rss0, df0, rss1, df1, n, F, q
    real colvector y, b, se, e
    real matrix X, PAC, LM, D, Xd
    N = cols(W)
    T = rows(W)
    PAC = J(K, 3, .)
    LM = J(K, 3, .)
    for (k = 1; k <= K; k = k + 1) {
        y = J(0, 1, .)
        X = J(0, k, .)
        for (i = 1; i <= N; i = i + 1) {
            y = y \ W[(k + 1)..T, i]
            Xd = J(T - k, k, .)
            for (l = 1; l <= k; l = l + 1) Xd[., l] = W[(k + 1 - l)..(T - l), i]
            X = X \ Xd
        }
        n = rows(y)
        _xtpg_ols(y, (J(n, 1, 1), X), b, se, rss, df)
        PAC[k, .] = (b[k + 1], b[k + 1] / se[k + 1], 1 - normal(b[k + 1] / se[k + 1]))
        // Engle LM: n * R^2
        e = y :- mean(y)
        LM[k, .] = (n * (1 - rss / cross(e, e)), k, chi2tail(k, n * (1 - rss / cross(e, e))))
    }
    st_matrix(outpac, PAC)
    st_matrix(outlm, LM)
    // individual effects in the AR(arfe) regression of W
    k = arfe
    y = J(0, 1, .)
    X = J(0, k, .)
    D = J(0, N, .)
    for (i = 1; i <= N; i = i + 1) {
        y = y \ W[(k + 1)..T, i]
        Xd = J(T - k, k, .)
        for (l = 1; l <= k; l = l + 1) Xd[., l] = W[(k + 1 - l)..(T - l), i]
        X = X \ Xd
        Xd = J(T - k, N, 0)
        Xd[., i] = J(T - k, 1, 1)
        D = D \ Xd
    }
    n = rows(y)
    _xtpg_ols(y, (J(n, 1, 1), X), b, se, rss0, df0)
    _xtpg_ols(y, (D, X), b, se, rss1, df1)
    q = N - 1
    F = ((rss0 - rss1) / q) / (rss1 / df1)
    st_matrix(outfe, (F, q, df1, Ftail(q, df1, F), q * F, chi2tail(q, q * F)))
}

// cross-section diagnostics on residual matrix E (T x N)
void _xtpg_pre_xs(real matrix E, real scalar K, string scalar outxs,
    string scalar outcp, string scalar outcpfe)
{
    real scalar N, T, i, j, c, np, LRg, LRc, BP, CD, s2, rss, df, rss0, df0, rss1, df1, n, F, q, l, k
    real matrix S, R, P, X, Xd, D, CP
    real colvector s2i, y, b, se
    N = cols(E)
    T = rows(E)
    S = cross(E, E) / T
    s2i = diagonal(S)
    s2 = sum(E :* E) / (N * T)
    // LR groupwise heteroskedasticity: H0 sigma_i^2 = sigma^2, chi2(N-1)
    LRg = N * T * ln(s2) - T * sum(ln(s2i))
    // LR cross-sectional correlation: H0 Sigma diagonal, chi2(N(N-1)/2)
    LRc = T * (sum(ln(s2i)) - ln(det(S)))
    R = S :/ sqrt(s2i * s2i')
    BP = 0
    CD = 0
    for (i = 1; i <= N - 1; i = i + 1) {
        for (j = i + 1; j <= N; j = j + 1) {
            BP = BP + R[i, j] * R[i, j]
            CD = CD + R[i, j]
        }
    }
    np = N * (N - 1) / 2
    BP = T * BP
    CD = sqrt(2 * T / (N * (N - 1))) * CD
    st_matrix(outxs, (LRg, N - 1, chi2tail(N - 1, LRg) \
                      LRc, np, chi2tail(np, LRc) \
                      BP, np, chi2tail(np, BP) \
                      CD, ., 2 * normal(-abs(CD))))
    if (N < 2) return
    // cross products u_it u_jt : pooled AR(K) and pair effects
    P = J(T, np, .)
    c = 0
    for (i = 1; i <= N - 1; i = i + 1) {
        for (j = i + 1; j <= N; j = j + 1) {
            c = c + 1
            P[., c] = E[., i] :* E[., j]
        }
    }
    k = K
    y = J(0, 1, .)
    X = J(0, k, .)
    D = J(0, np, .)
    for (i = 1; i <= np; i = i + 1) {
        y = y \ P[(k + 1)..T, i]
        Xd = J(T - k, k, .)
        for (l = 1; l <= k; l = l + 1) Xd[., l] = P[(k + 1 - l)..(T - l), i]
        X = X \ Xd
        Xd = J(T - k, np, 0)
        Xd[., i] = J(T - k, 1, 1)
        D = D \ Xd
    }
    n = rows(y)
    _xtpg_ols(y, (J(n, 1, 1), X), b, se, rss0, df0)
    CP = J(k, 3, .)
    for (l = 1; l <= k; l = l + 1) {
        CP[l, .] = (b[l + 1], b[l + 1] / se[l + 1], 2 * ttail(df0, abs(b[l + 1] / se[l + 1])))
    }
    st_matrix(outcp, CP)
    _xtpg_ols(y, (D, X), b, se, rss1, df1)
    q = np - 1
    if (q >= 1) {
        F = ((rss0 - rss1) / q) / (rss1 / df1)
        st_matrix(outcpfe, (F, q, df1, Ftail(q, df1, F)))
    }
}

void _xtpg_getE(string scalar rname, string scalar touse, real scalar N, string scalar Ename)
{
    real colvector r
    r = st_data(., rname, touse)
    st_matrix(Ename, rowshape(r, N)')
}

// ------------------------------------------------------------------------
// predict helpers
// ------------------------------------------------------------------------
void _xtpg_fillvar(string scalar vname, string scalar uix, string scalar tix,
    string scalar touse, real matrix M, real scalar dosqrt)
{
    real colvector u, t, v
    real scalar r
    st_view(u = ., ., uix, touse)
    st_view(t = ., ., tix, touse)
    st_view(v = ., ., vname, touse)
    for (r = 1; r <= rows(v); r = r + 1) {
        if (u[r] >= 1 & u[r] <= cols(M)) {
            if (t[r] >= 1 & t[r] <= rows(M)) {
                v[r] = M[t[r], u[r]]
                if (dosqrt) v[r] = sqrt(v[r])
            }
        }
    }
}

// conditional covariance / correlation between panels ia < ib at each t
void _xtpg_fillcov(string scalar vname, string scalar tix, string scalar touse,
    real scalar ia, real scalar ib, real scalar docorr)
{
    real matrix S2, CV, P
    real colvector t, v, c
    real scalar r, j, N
    S2 = st_matrix("e(sigma2)")
    N = cols(S2)
    if (ia == ib) {
        c = S2[., ia]
        if (docorr) c = J(rows(S2), 1, 1)
    }
    else {
        CV = st_matrix("e(covt)")
        P = st_matrix("e(pairs)")
        j = 0
        for (r = 1; r <= rows(P); r = r + 1) {
            if (P[r, 1] == ia) {
                if (P[r, 2] == ib) j = r
            }
        }
        if (j == 0) {
            errprintf("pair not found in e(pairs)\n")
            exit(198)
        }
        c = CV[., j]
        if (docorr) c = c :/ sqrt(S2[., ia] :* S2[., ib])
    }
    st_view(t = ., ., tix, touse)
    st_view(v = ., ., vname, touse)
    for (r = 1; r <= rows(v); r = r + 1) {
        if (t[r] >= 1 & t[r] <= rows(c)) v[r] = c[t[r]]
    }
}

// ------------------------------------------------------------------------
// estat helpers
// ------------------------------------------------------------------------
real scalar _xtpg_q(real colvector x, real scalar K)
{
    real scalar T, k, q, d, r
    real colvector e
    T = rows(x)
    e = x :- mean(x)
    d = cross(e, e)
    q = 0
    for (k = 1; k <= K; k = k + 1) {
        r = cross(e[(k + 1)..T], e[1..(T - k)]) / d
        q = q + r * r / (T - k)
    }
    return(T * (T + 2) * q)
}

real scalar _xtpg_lmarch(real colvector z, real scalar K)
{
    real scalar T, l, rss, df
    real colvector y, b, se, e
    real matrix X
    real colvector z2
    T = rows(z)
    z2 = z :* z
    y = z2[(K + 1)..T]
    X = J(T - K, 1, 1)
    for (l = 1; l <= K; l = l + 1) X = X, z2[(K + 1 - l)..(T - l)]
    _xtpg_ols(y, X, b, se, rss, df)
    e = y :- mean(y)
    return((T - K) * (1 - rss / cross(e, e)))
}

void _xtpg_lbq(real matrix Z, real scalar K, string scalar outname)
{
    real scalar N, i, q1, q2, lm, s1, s2, s3
    real matrix Q
    N = cols(Z)
    Q = J(N + 1, 6, .)
    s1 = 0
    s2 = 0
    s3 = 0
    for (i = 1; i <= N; i = i + 1) {
        q1 = _xtpg_q(Z[., i], K)
        q2 = _xtpg_q(Z[., i] :* Z[., i], K)
        lm = _xtpg_lmarch(Z[., i], K)
        Q[i, .] = (q1, chi2tail(K, q1), q2, chi2tail(K, q2), lm, chi2tail(K, lm))
        s1 = s1 + q1
        s2 = s2 + q2
        s3 = s3 + lm
    }
    Q[N + 1, .] = (s1, chi2tail(N * K, s1), s2, chi2tail(N * K, s2), s3, chi2tail(N * K, s3))
    st_matrix(outname, Q)
}

void _xtpg_pdreport()
{
    real matrix S2, CV, P, Om
    real scalar t, j, mn, ev, nb
    S2 = st_matrix("e(sigma2)")
    CV = st_matrix("e(covt)")
    P = st_matrix("e(pairs)")
    mn = .
    nb = 0
    for (t = 1; t <= rows(S2); t = t + 1) {
        Om = diag(S2[t, .])
        for (j = 1; j <= rows(P); j = j + 1) {
            Om[P[j, 1], P[j, 2]] = CV[t, j]
            Om[P[j, 2], P[j, 1]] = CV[t, j]
        }
        ev = min(symeigenvalues(Om))
        if (ev < mn) mn = ev
        if (ev <= 0) nb = nb + 1
    }
    st_numscalar("r(mineig)", mn)
    st_numscalar("r(nbad)", nb)
}

void _xtpg_corrmat(string scalar outname)
{
    real matrix S2, CV, P, R
    real scalar j
    S2 = st_matrix("e(sigma2)")
    CV = st_matrix("e(covt)")
    P = st_matrix("e(pairs)")
    R = J(rows(CV), cols(CV), .)
    for (j = 1; j <= rows(P); j = j + 1) {
        R[., j] = CV[., j] :/ sqrt(S2[., P[j, 1]] :* S2[., P[j, 2]])
    }
    st_matrix(outname, R)
}

// ------------------------------------------------------------------------
// Asai (2023): feasible panel GARCH, three-step variance targeting
//   H_t = (1-g-f) Sigma + g u_{t-1}u_{t-1}' + f H_{t-1}        eq.(14)/(17)
//   CCP: h_ii,t = (1-g-f) s_ii + g u_i^2 + f h_ii,t-1,
//        h_ij,t = r_ij sqrt(h_ii h_jj)                          eq.(27)
// ------------------------------------------------------------------------
real colvector _xtpg_vt_llt(real matrix U, real matrix Sig, real rowvector lam,
    real scalar ccp)
{
    real scalar T, N, g, f, t, c2
    real matrix H, Ch, R, Dg
    real colvector ll, z, h, s
    T = rows(U)
    N = cols(U)
    g = lam[1]
    f = lam[2]
    if (g < 0 | f < 0 | g + f >= 1) return(J(T, 1, .))
    ll = J(T, 1, .)
    c2 = N * ln(2 * pi())
    if (ccp == 0) {
        H = Sig
        for (t = 1; t <= T; t = t + 1) {
            if (t >= 2) H = (1 - g - f) * Sig + g * (U[t - 1, .]' * U[t - 1, .]) + f * H
            Ch = cholesky(H)
            if (hasmissing(Ch)) return(J(T, 1, .))
            z = solvelower(Ch, U[t, .]')
            ll[t] = -0.5 * (c2 + 2 * sum(ln(diagonal(Ch))) + cross(z, z))
        }
    }
    else {
        s = diagonal(Sig)
        R = Sig :/ sqrt(s * s')
        Ch = cholesky(R)
        if (hasmissing(Ch)) return(J(T, 1, .))
        h = s
        for (t = 1; t <= T; t = t + 1) {
            if (t >= 2) h = (1 - g - f) * s + g * (U[t - 1, .]' :* U[t - 1, .]') + f * h
            z = solvelower(Ch, U[t, .]' :/ sqrt(h))
            ll[t] = -0.5 * (c2 + sum(ln(h)) + 2 * sum(ln(diagonal(Ch))) + cross(z, z))
        }
    }
    return(ll)
}

// conditional covariance path of the fitted VT model (T x npair) and variances
void _xtpg_vt_paths(real matrix U, real matrix Sig, real rowvector lam, real scalar ccp,
    real matrix S2, real matrix CV, real matrix P)
{
    real scalar T, N, g, f, t, j, np, a, c
    real matrix H, R
    real colvector h, s
    T = rows(U)
    N = cols(U)
    g = lam[1]
    f = lam[2]
    np = N * (N - 1) / 2
    P = J(np, 2, .)
    j = 0
    for (a = 1; a <= N - 1; a = a + 1) {
        for (c = a + 1; c <= N; c = c + 1) {
            j = j + 1
            P[j, .] = (a, c)
        }
    }
    S2 = J(T, N, .)
    CV = J(T, np, .)
    H = Sig
    s = diagonal(Sig)
    R = Sig :/ sqrt(s * s')
    for (t = 1; t <= T; t = t + 1) {
        if (t >= 2) H = (1 - g - f) * Sig + g * (U[t - 1, .]' * U[t - 1, .]) + f * H
        if (ccp) {
            h = diagonal(H)
            H = R :* sqrt(h * h')
        }
        S2[t, .] = diagonal(H)'
        for (j = 1; j <= np; j = j + 1) CV[t, j] = H[P[j, 1], P[j, 2]]
    }
}

real matrix _xtpg_vech2sig(real colvector v, real scalar N)
{
    real matrix S
    real scalar i, j, c
    S = J(N, N, 0)
    c = 0
    for (j = 1; j <= N; j = j + 1) {
        for (i = j; i <= N; i = i + 1) {
            c = c + 1
            S[i, j] = v[c]
            S[j, i] = v[c]
        }
    }
    return(S)
}

void _xtpg_vt_eval(real scalar todo, real rowvector lam, real matrix U, real matrix Sig,
    real scalar ccp, real colvector lnf, real matrix g, real matrix H)
{
    lnf = _xtpg_vt_llt(U, Sig, lam, ccp)
}

// per-t numerical score of l_t wrt lam, at given Sigma (T x 2)
real matrix _xtpg_vt_score(real matrix U, real matrix Sig, real rowvector lam, real scalar ccp)
{
    real matrix G
    real rowvector lp, lm
    real scalar k, hh
    G = J(rows(U), 2, .)
    for (k = 1; k <= 2; k = k + 1) {
        hh = 1e-5 * max((abs(lam[k]), 1e-2))
        lp = lam
        lm = lam
        lp[k] = lam[k] + hh
        lm[k] = lam[k] - hh
        G[., k] = (_xtpg_vt_llt(U, Sig, lp, ccp) - _xtpg_vt_llt(U, Sig, lm, ccp)) / (2 * hh)
    }
    return(G)
}

// step 3 + Prop. 4 variance; U : T x N first-step residuals
void _xtpg_vt_fit(string scalar Uname, real scalar ccp, string scalar outb,
    string scalar outV, string scalar outSig)
{
    real matrix U, Sig, Gt, Xl, Xs, Ov, W, P0, V, Sp, Sm, S2, CV, Pr
    real rowvector lam, best, lp, lm, cand, gv, fv
    real colvector sig, ll, sp, sm, gbar
    real scalar T, N, ns, k, j, hh, bestll, v, ig, if1
    transmorphic S
    U = st_matrix(Uname)
    T = rows(U)
    N = cols(U)
    Sig = cross(U, U) / T                                        // eq.(20)
    // grid for starting values
    best = (0.05, 0.90)
    bestll = -1e300
    gv = (0.02, 0.05, 0.08, 0.12, 0.20, 0.30)
    fv = (0.10, 0.40, 0.60, 0.80, 0.90, 0.95)
    for (ig = 1; ig <= 6; ig = ig + 1) {
        for (if1 = 1; if1 <= 6; if1 = if1 + 1) {
            cand = (gv[ig], fv[if1])
            if (cand[1] + cand[2] >= 0.995) continue
            ll = _xtpg_vt_llt(U, Sig, cand, ccp)
            if (hasmissing(ll)) continue
            v = sum(ll)
            if (v > bestll) {
                bestll = v
                best = cand
            }
        }
    }
    S = optimize_init()
    optimize_init_evaluator(S, &_xtpg_vt_eval())
    optimize_init_evaluatortype(S, "gf0")
    optimize_init_argument(S, 1, U)
    optimize_init_argument(S, 2, Sig)
    optimize_init_argument(S, 3, ccp)
    optimize_init_params(S, best)
    optimize_init_technique(S, "nr")
    optimize_init_tracelevel(S, "none")
    optimize_init_singularHmethod(S, "hybrid")
    (void) _optimize(S)
    lam = optimize_result_params(S)                              // eq.(21)

    // Prop. 4: Var(lam) = P0 Omega_v P0' / T, in vech(Sigma) coordinates
    sig = vech(Sig)
    ns = rows(sig)
    Gt = _xtpg_vt_score(U, Sig, lam, ccp)
    // Xi_lambda = (1/T) sum d2 l_t / dlam dlam'
    Xl = J(2, 2, .)
    for (k = 1; k <= 2; k = k + 1) {
        hh = 1e-4 * max((abs(lam[k]), 1e-2))
        lp = lam
        lm = lam
        lp[k] = lam[k] + hh
        lm[k] = lam[k] - hh
        Xl[., k] = (colsum(_xtpg_vt_score(U, Sig, lp, ccp)) - colsum(_xtpg_vt_score(U, Sig, lm, ccp)))' / (2 * hh * T)
    }
    Xl = (Xl + Xl') / 2
    // Xi_sigma = (1/T) sum d2 l_t / dlam dsigma'
    Xs = J(2, ns, .)
    for (j = 1; j <= ns; j = j + 1) {
        hh = 1e-4 * max((abs(sig[j]), 1e-3))
        sp = sig
        sm = sig
        sp[j] = sig[j] + hh
        sm[j] = sig[j] - hh
        Sp = _xtpg_vech2sig(sp, N)
        Sm = _xtpg_vech2sig(sm, N)
        Xs[., j] = (colsum(_xtpg_vt_score(U, Sp, lam, ccp)) - colsum(_xtpg_vt_score(U, Sm, lam, ccp)))' / (2 * hh * T)
    }
    // omega_v,t = ( vech(u_t u_t') - sigma ; dl_t/dlam )
    W = J(T, ns + 2, .)
    for (k = 1; k <= T; k = k + 1) {
        W[k, .] = ((vech(U[k, .]' * U[k, .]) - sig)', Gt[k, .])
    }
    Ov = cross(W, W) / T
    P0 = (invsym(-Xl) * Xs, invsym(-Xl))
    V = P0 * Ov * P0' / T
    st_matrix(outb, lam)
    st_matrix(outV, V)
    st_matrix(outSig, Sig)
    st_numscalar("__xtpg_ll", optimize_result_value(S))
    st_numscalar("__xtpg_conv", optimize_result_converged(S))
    _xtpg_vt_paths(U, Sig, lam, ccp, S2, CV, Pr)
    st_matrix("__xtpg_S2", S2)
    st_matrix("__xtpg_CV", CV)
    st_matrix("__xtpg_pairs", Pr)
    st_matrix("__xtpg_U", U)
}

// full QML of the feasible panel GARCH (Asai 2023, Remark 3.3 and Table 5), started at the VT estimates
// psi = (theta, alpha, vech(chol Sigma), gamma, phi); quasi log likelihood eq.(22)
struct xtpg_vq {
    real scalar N, T, k, ccp, nl
    real matrix Y, Z
}

void _xtpg_vq_unpack(struct xtpg_vq scalar D, real rowvector p, real colvector th,
    real rowvector al, real matrix Sig, real rowvector lam)
{
    real matrix L
    real scalar i, j, c, o
    th = p[1..D.k]'
    al = p[(D.k + 1)..(D.k + D.N)]
    o = D.k + D.N
    L = J(D.N, D.N, 0)
    c = 0
    for (j = 1; j <= D.N; j = j + 1) {
        for (i = j; i <= D.N; i = i + 1) {
            c = c + 1
            L[i, j] = p[o + c]
        }
    }
    Sig = L * L'
    lam = p[(o + D.nl + 1)..(o + D.nl + 2)]
}

void _xtpg_vq_eval(real scalar todo, real rowvector p, struct xtpg_vq scalar D,
    real colvector lnf, real matrix g, real matrix H)
{
    real colvector th
    real rowvector al, lam
    real matrix Sig, U
    _xtpg_vq_unpack(D, p, th, al, Sig, lam)
    U = D.Y - J(D.T, 1, al) - rowshape(D.Z * th, D.N)'
    lnf = _xtpg_vt_llt(U, Sig, lam, D.ccp)
}

void _xtpg_vt_qml(string scalar yname, string scalar znames, string scalar touse, real scalar N,
    real scalar T, real scalar ccp, string scalar b1name, string scalar Signame, string scalar lamname,
    string scalar outb, string scalar outV, string scalar outSig)
{
    struct xtpg_vq scalar D
    real colvector y, th
    real rowvector b1, lam0, p0, p, al, lam
    real matrix Z, Sig0, L0, V, Sig, U, S2, CV, Pr
    real scalar i, j, c, k, np
    transmorphic S
    y = st_data(., yname, touse)
    Z = st_data(., tokens(znames), touse)
    D.N = N
    D.T = T
    D.k = cols(Z)
    D.ccp = ccp
    D.Y = rowshape(y, N)'
    D.Z = Z
    D.nl = N * (N + 1) / 2
    b1 = st_matrix(b1name)
    Sig0 = st_matrix(Signame)
    lam0 = st_matrix(lamname)
    L0 = cholesky(Sig0)
    p0 = b1
    for (j = 1; j <= N; j = j + 1) {
        for (i = j; i <= N; i = i + 1) p0 = p0, L0[i, j]
    }
    p0 = p0, lam0
    S = optimize_init()
    optimize_init_evaluator(S, &_xtpg_vq_eval())
    optimize_init_evaluatortype(S, "gf0")
    optimize_init_argument(S, 1, D)
    optimize_init_params(S, p0)
    optimize_init_technique(S, "bfgs")
    optimize_init_conv_maxiter(S, 1000)
    optimize_init_singularHmethod(S, "hybrid")
    optimize_init_tracelevel(S, "none")
    if (_optimize(S) != 0) {
        optimize_init_params(S, p0)
        optimize_init_technique(S, "nr")
        if (_optimize(S) != 0) {
            errprintf("QML refinement failed: %s; VT estimates kept\n", optimize_result_errortext(S))
            st_numscalar("__xtpg_qmlrc", 1)
            return
        }
    }
    st_numscalar("__xtpg_qmlrc", 0)
    p = optimize_result_params(S)
    V = optimize_result_V_robust(S)                              // Bollerslev-Wooldridge sandwich
    _xtpg_vq_unpack(D, p, th, al, Sig, lam)
    // keep (theta, alpha, gamma, phi); Cholesky elements of Sigma are reported through e(Sigma)
    np = cols(p)
    k = D.k + N
    st_matrix(outb, (p[1..k], p[(np - 1)..np]))
    st_matrix(outV, (V[1..k, 1..k], V[1..k, (np - 1)..np] \ V[(np - 1)..np, 1..k], V[(np - 1)..np, (np - 1)..np]))
    st_matrix(outSig, Sig)
    st_numscalar("__xtpg_ll", optimize_result_value(S))
    U = D.Y - J(D.T, 1, al) - rowshape(D.Z * th, D.N)'
    _xtpg_vt_paths(U, Sig, lam, ccp, S2, CV, Pr)
    st_matrix("__xtpg_S2", S2)
    st_matrix("__xtpg_CV", CV)
    st_matrix("__xtpg_U", U)
}

// step-1 FE estimator and its two covariance estimators, eqs.(18),(19),(25),(26)
// Z : NT x (k+1) unit-major regressors (z_it = (y_i,t-1, x_it)), y : NT
void _xtpg_vt_step1(string scalar yname, string scalar znames, string scalar touse,
    real scalar N, real scalar T, string scalar outb, string scalar outVr, string scalar Uname)
{
    real colvector y, th, al, ui
    real matrix Z, Zt, Yt, Zb, Qz, iQ, U, W, Om, Ztt, Zbar, Sm
    real scalar k, i, t
    y = st_data(., yname, touse)
    Z = st_data(., tokens(znames), touse)
    k = cols(Z)
    // within transformation
    Yt = J(N * T, 1, .)
    Zt = J(N * T, k, .)
    Zbar = J(N, k, .)
    for (i = 1; i <= N; i = i + 1) {
        Zbar[i, .] = mean(Z[((i - 1) * T + 1)..(i * T), .])
        Zt[((i - 1) * T + 1)..(i * T), .] = Z[((i - 1) * T + 1)..(i * T), .] :- Zbar[i, .]
        Yt[((i - 1) * T + 1)..(i * T)] = y[((i - 1) * T + 1)..(i * T)] :- mean(y[((i - 1) * T + 1)..(i * T)])
    }
    Qz = cross(Zt, Zt) / T
    iQ = invsym(Qz)
    th = iQ * cross(Zt, Yt) / T                                  // eq.(18)
    al = J(N, 1, .)
    for (i = 1; i <= N; i = i + 1) {
        al[i] = mean(y[((i - 1) * T + 1)..(i * T)]) - Zbar[i, .] * th   // eq.(19)
    }
    U = J(T, N, .)
    for (i = 1; i <= N; i = i + 1) {
        U[., i] = y[((i - 1) * T + 1)..(i * T)] :- al[i] :- Z[((i - 1) * T + 1)..(i * T), .] * th
    }
    // robust Omega_m, eq.(25): omega_t = ( Qz^-1 Ztil_t' u_t ; (I - Zbar Qz^-1 Ztil_t') u_t )
    W = J(T, k + N, .)
    for (t = 1; t <= T; t = t + 1) {
        Ztt = J(N, k, .)
        for (i = 1; i <= N; i = i + 1) Ztt[i, .] = Zt[(i - 1) * T + t, .]
        W[t, .] = ((iQ * Ztt' * U[t, .]')', ((I(N) - Zbar * iQ * Ztt') * U[t, .]')')
    }
    Om = cross(W, W) / T
    st_matrix(outb, (th', al'))
    st_matrix(outVr, Om / T)
    st_matrix(Uname, U)
    st_matrix("__xtpg_Zt", Zt)
    st_matrix("__xtpg_Zbar", Zbar)
    st_matrix("__xtpg_iQ", iQ)
}

// model-based Omega_m, eq.(26), with H_t from the fitted model
void _xtpg_vt_modelV(real scalar N, real scalar T, string scalar outV)
{
    real matrix Zt, Zbar, iQ, S2, CV, P, H, Ztt, A, Om
    real scalar k, t, i, j
    Zt = st_matrix("__xtpg_Zt")
    Zbar = st_matrix("__xtpg_Zbar")
    iQ = st_matrix("__xtpg_iQ")
    S2 = st_matrix("__xtpg_S2")
    CV = st_matrix("__xtpg_CV")
    P = st_matrix("__xtpg_pairs")
    k = cols(Zt)
    Om = J(k + N, k + N, 0)
    for (t = 1; t <= T; t = t + 1) {
        Ztt = J(N, k, .)
        for (i = 1; i <= N; i = i + 1) Ztt[i, .] = Zt[(i - 1) * T + t, .]
        H = diag(S2[t, .])
        for (j = 1; j <= rows(P); j = j + 1) {
            H[P[j, 1], P[j, 2]] = CV[t, j]
            H[P[j, 2], P[j, 1]] = CV[t, j]
        }
        A = (iQ * Ztt' \ (I(N) - Zbar * iQ * Ztt'))
        Om = Om + A * H * A'
    }
    st_matrix(outV, Om / (T * T))
}

// ------------------------------------------------------------------------
// Pakel, Shephard & Sheppard (2011): composite likelihood GARCH panel
//   sigma2_it = g_i (1-a-b) + a y2_{i,t-1} + b sigma2_{i,t-1}      eq.(2.3)
//   g_i = T^-1 sum_t y_it^2 (MM)                                  eq.(2.6)
//   sigma2_i0 = mean of first floor(T^1/2) y_it^2                 p.309
// Y : T x N, returns T x N log-density matrix
// ------------------------------------------------------------------------
real matrix _xtpg_cl_llit(real matrix Y, real rowvector th, real rowvector gam,
    real scalar dist, real scalar nu)
{
    real scalar T, N, a, b, t, m
    real matrix S2, Y2, L
    real rowvector h
    T = rows(Y)
    N = cols(Y)
    a = th[1]
    b = th[2]
    if (a < 0 | b < 0 | a + b >= 1) return(J(T, N, .))
    Y2 = Y :* Y
    m = floor(sqrt(T))
    if (m < 1) m = 1
    S2 = J(T, N, .)
    h = colsum(Y2[1..m, .]) / m
    for (t = 1; t <= T; t = t + 1) {
        if (t >= 2) h = gam * (1 - a - b) + a * Y2[t - 1, .] + b * h
        S2[t, .] = h
    }
    if (min(S2) <= 0) return(J(T, N, .))
    if (dist == 1) {
        L = -0.5 * (ln(2 * pi()) :+ ln(S2) + Y2 :/ S2)
    }
    else {
        L = (lngamma((nu + 1) / 2) - lngamma(nu / 2) - 0.5 * ln(pi() * (nu - 2))) :- 0.5 * ln(S2) :-
            ((nu + 1) / 2) * ln(1 :+ Y2 :/ (S2 * (nu - 2)))
    }
    return(L)
}

real matrix _xtpg_cl_s2(real matrix Y, real rowvector th, real rowvector gam)
{
    real scalar T, a, b, t, m
    real matrix S2, Y2
    real rowvector h
    T = rows(Y)
    a = th[1]
    b = th[2]
    Y2 = Y :* Y
    m = max((floor(sqrt(T)), 1))
    S2 = J(T, cols(Y), .)
    h = colsum(Y2[1..m, .]) / m
    for (t = 1; t <= T; t = t + 1) {
        if (t >= 2) h = gam * (1 - a - b) + a * Y2[t - 1, .] + b * h
        S2[t, .] = h
    }
    return(S2)
}

void _xtpg_cl_eval(real scalar todo, real rowvector th, real matrix Y, real rowvector gam,
    real scalar dist, real colvector lnf, real matrix g, real matrix H)
{
    real scalar nu
    real rowvector ab
    nu = .
    ab = th[1..2]
    if (dist == 2) {
        nu = th[3]
        if (nu <= 2) {
            lnf = J(rows(Y), 1, .)
            return
        }
    }
    lnf = rowsum(_xtpg_cl_llit(Y, ab, gam, dist, nu)) / cols(Y)  // eq.(2.5)
}

// fit CL (eq. 2.9) + sandwich with nuisance correction and Newey-West HAC
void _xtpg_cl_fit(string scalar Yname, real scalar dist, real scalar hac,
    string scalar outb, string scalar outV, string scalar outVn)
{
    real matrix Y, Lp, Lm, Sit, Sa, Sb, Gc, Z, J0, I0, Gm, V, Vn, Sg
    real rowvector gam, th, best, cand, gv, bv, tp, tm, gp, gm
    real colvector ll
    real scalar T, N, k, hh, j, l, w, bestll, v, ig, ib, nu, kk
    transmorphic S
    Y = st_matrix(Yname)
    T = rows(Y)
    N = cols(Y)
    gam = colsum(Y :* Y) / T                                     // eq.(2.6)
    gv = (0.02, 0.05, 0.08, 0.12, 0.20)
    bv = (0.50, 0.70, 0.80, 0.90, 0.93, 0.97)
    best = (0.05, 0.90)
    bestll = -1e300
    for (ig = 1; ig <= cols(gv); ig = ig + 1) {
        for (ib = 1; ib <= cols(bv); ib = ib + 1) {
            cand = (gv[ig], bv[ib])
            if (cand[1] + cand[2] >= 0.995) continue
            v = sum(_xtpg_cl_llit(Y, cand, gam, 1, .))
            if (v > bestll) {
                bestll = v
                best = cand
            }
        }
    }
    if (dist == 2) best = (best, 8)
    S = optimize_init()
    optimize_init_evaluator(S, &_xtpg_cl_eval())
    optimize_init_evaluatortype(S, "gf0")
    optimize_init_argument(S, 1, Y)
    optimize_init_argument(S, 2, gam)
    optimize_init_argument(S, 3, dist)
    optimize_init_params(S, best)
    optimize_init_technique(S, "nr")
    optimize_init_tracelevel(S, "none")
    optimize_init_singularHmethod(S, "hybrid")
    (void) _optimize(S)
    th = optimize_result_params(S)
    k = cols(th)
    nu = .
    if (dist == 2) nu = th[3]

    // per-(i,t) numerical scores wrt theta: Sit[k] is T x N
    Gm = J(T, k, 0)                       // naive CL score per t (avg over i)
    Gc = J(T, k, 0)                       // nuisance-corrected z_{t,N}
    for (j = 1; j <= k; j = j + 1) {
        hh = 1e-5 * max((abs(th[j]), 1e-2))
        tp = th
        tm = th
        tp[j] = th[j] + hh
        tm[j] = th[j] - hh
        Lp = _xtpg_cl_llit(Y, tp[1..2], gam, dist, _xtpg_pick(tp, 3, nu))
        Lm = _xtpg_cl_llit(Y, tm[1..2], gam, dist, _xtpg_pick(tm, 3, nu))
        Sit = (Lp - Lm) / (2 * hh)
        // cross derivative wrt own gamma_i: perturb all gammas at once
        gp = gam :* (1 + 1e-4)
        gm = gam :* (1 - 1e-4)
        Sg = (((_xtpg_cl_llit(Y, tp[1..2], gp, dist, _xtpg_pick(tp, 3, nu)) - _xtpg_cl_llit(Y, tm[1..2], gp, dist, _xtpg_pick(tm, 3, nu))) -
              (_xtpg_cl_llit(Y, tp[1..2], gm, dist, _xtpg_pick(tp, 3, nu)) - _xtpg_cl_llit(Y, tm[1..2], gm, dist, _xtpg_pick(tm, 3, nu)))) /
              (2 * hh)) :/ (2e-4 * gam)
        // influence of gamma_i-hat: (1/T) sum_s d2 l_is / dth dg_i  x  (y_it^2 - g_i)
        Gm[., j] = rowsum(Sit) / N
        Gc[., j] = rowsum(Sit + (colsum(Sg) / T) :* (Y :* Y :- gam)) / N
    }
    // J: average Hessian of the CL contribution
    J0 = J(k, k, .)
    for (j = 1; j <= k; j = j + 1) {
        hh = 1e-4 * max((abs(th[j]), 1e-2))
        tp = th
        tm = th
        tp[j] = th[j] + hh
        tm[j] = th[j] - hh
        J0[., j] = (_xtpg_cl_avgscore(Y, tp, gam, dist) - _xtpg_cl_avgscore(Y, tm, gam, dist))' / (2 * hh)
    }
    J0 = (J0 + J0') / 2
    I0 = _xtpg_nw(Gc, hac)
    V = (-invsym(-J0)) * I0 * (-invsym(-J0)) / T
    Vn = (-invsym(-J0)) * _xtpg_nw(Gm, hac) * (-invsym(-J0)) / T
    st_matrix(outb, th)
    st_matrix(outV, V)
    st_matrix(outVn, Vn)
    st_numscalar("__xtpg_ll", optimize_result_value(S))
    st_numscalar("__xtpg_conv", optimize_result_converged(S))
    st_matrix("__xtpg_S2", _xtpg_cl_s2(Y, th[1..2], gam))
    st_matrix("__xtpg_gam", gam)
}

real scalar _xtpg_pick(real rowvector v, real scalar j, real scalar dflt)
{
    if (cols(v) >= j) return(v[j])
    return(dflt)
}

real rowvector _xtpg_cl_avgscore(real matrix Y, real rowvector th, real rowvector gam, real scalar dist)
{
    real rowvector s, tp, tm
    real scalar j, hh, T, N
    T = rows(Y)
    N = cols(Y)
    s = J(1, cols(th), .)
    for (j = 1; j <= cols(th); j = j + 1) {
        hh = 1e-5 * max((abs(th[j]), 1e-2))
        tp = th
        tm = th
        tp[j] = th[j] + hh
        tm[j] = th[j] - hh
        s[j] = (sum(_xtpg_cl_llit(Y, tp[1..2], gam, dist, _xtpg_pick(tp, 3, .))) -
                sum(_xtpg_cl_llit(Y, tm[1..2], gam, dist, _xtpg_pick(tm, 3, .)))) / (2 * hh * T * N)
    }
    return(s)
}

// Newey-West long-run variance of the rows of G (T x k), Bartlett, lag L
real matrix _xtpg_nw(real matrix G, real scalar L)
{
    real matrix Gc, Om, Gl
    real scalar T, l, w
    T = rows(G)
    Gc = G :- mean(G)
    Om = cross(Gc, Gc) / T
    for (l = 1; l <= L; l = l + 1) {
        w = 1 - l / (L + 1)
        Gl = cross(Gc[(l + 1)..T, .], Gc[1..(T - l), .]) / T
        Om = Om + w * (Gl + Gl')
    }
    return(Om)
}

// MacGyver (Engle 2009) blend: per-unit QMLE with g_i fixed, median
void _xtpg_cl_macgyver(string scalar Yname, string scalar outname)
{
    real matrix Y, R
    real rowvector gam, th
    real scalar N, i
    transmorphic S
    Y = st_matrix(Yname)
    N = cols(Y)
    gam = colsum(Y :* Y) / rows(Y)
    R = J(N, 3, .)
    for (i = 1; i <= N; i = i + 1) {
        S = optimize_init()
        optimize_init_evaluator(S, &_xtpg_cl_eval())
        optimize_init_evaluatortype(S, "gf0")
        optimize_init_argument(S, 1, Y[., i])
        optimize_init_argument(S, 2, gam[i])
        optimize_init_argument(S, 3, 1)
        optimize_init_params(S, (0.05, 0.90))
        optimize_init_technique(S, "nr")
        optimize_init_tracelevel(S, "none")
        optimize_init_conv_warning(S, "off")
        if (_optimize(S) == 0) {
            th = optimize_result_params(S)
            R[i, .] = (th, optimize_result_converged(S))
        }
    }
    st_matrix(outname, R)
}

// ------------------------------------------------------------------------
// VaR backtests: Kupiec (1995), Christoffersen (1998), DQ of Engle and Manganelli (2004)
// ------------------------------------------------------------------------
real rowvector _xtpg_bt1(real colvector y, real colvector q, real scalar tau)
{
    real colvector I, Hd, b
    real matrix X
    real scalar n, n1, p, luc, n00, n01, n10, n11, t, p01, p11, lind, l0, l1, dq, nl, pp
    I = (y :< q)
    n = rows(I)
    n1 = sum(I)
    p = n1 / n
    luc = 0
    if (n1 > 0 & n1 < n) luc = -2 * ((n - n1) * ln(1 - tau) + n1 * ln(tau) - (n - n1) * ln(1 - p) - n1 * ln(p))
    else if (n1 == 0) luc = -2 * (n * ln(1 - tau))
    else luc = -2 * (n * ln(tau))
    n00 = 0
    n01 = 0
    n10 = 0
    n11 = 0
    for (t = 2; t <= n; t = t + 1) {
        if (I[t - 1] == 0 & I[t] == 0) n00 = n00 + 1
        if (I[t - 1] == 0 & I[t] == 1) n01 = n01 + 1
        if (I[t - 1] == 1 & I[t] == 0) n10 = n10 + 1
        if (I[t - 1] == 1 & I[t] == 1) n11 = n11 + 1
    }
    p01 = n01 / max((n00 + n01, 1))
    p11 = n11 / max((n10 + n11, 1))
    pp = (n01 + n11) / max((n00 + n01 + n10 + n11, 1))
    l0 = (n00 + n10) * ln(max((1 - pp, 1e-300))) + (n01 + n11) * ln(max((pp, 1e-300)))
    l1 = n00 * ln(max((1 - p01, 1e-300))) + n01 * ln(max((p01, 1e-300))) + n10 * ln(max((1 - p11, 1e-300))) + n11 * ln(max((p11, 1e-300)))
    lind = -2 * (l0 - l1)
    // DQ: Hit_t on (1, Hit_t-1..Hit_t-4, VaR_t), chi2(6)
    nl = 4
    Hd = I :- tau
    X = J(n - nl, 1, 1), Hd[4..(n - 1)], Hd[3..(n - 2)], Hd[2..(n - 3)], Hd[1..(n - 4)], q[(nl + 1)..n]
    b = invsym(cross(X, X)) * cross(X, Hd[(nl + 1)..n])
    dq = (b' * cross(X, X) * b) / (tau * (1 - tau))
    return((p, luc, lind, luc + lind, dq))
}

void _xtpg_backtest(string scalar Yname, string scalar Qname, real scalar tau, string scalar outname)
{
    real matrix Y, Q, R
    real scalar N, i
    Y = st_matrix(Yname)
    Q = st_matrix(Qname)
    N = cols(Y)
    R = J(N + 1, 5, .)
    for (i = 1; i <= N; i = i + 1) R[i, .] = _xtpg_bt1(Y[., i], Q[., i], tau)
    R[N + 1, .] = (mean(vec(Y :< Q)), colsum(R[1..N, 2..5]))
    st_matrix(outname, R)
}

// h-step variance forecasts for GARCH(p,q)-type recursions, unit by unit
// Ul: q x N last squared residuals (most recent last), Hl: p x N last variances,
// om: 1 x N intercepts, a: q ARCH, b: p GARCH, lamt: GJR term (0 if none), neg: 1 x N 1(u_T<0)
real matrix _xtpg_fcast(real matrix Ul, real matrix Hl, real rowvector om, real rowvector a,
    real rowvector b, real scalar lamt, real rowvector neg, real scalar H)
{
    real matrix F, E2, HH
    real scalar q, p, h, l, s, N
    real rowvector f
    q = cols(a)
    p = cols(b)
    N = cols(om)
    // extended arrays: past values followed by forecasts
    E2 = Ul \ J(H, N, .)
    HH = Hl \ J(H, N, .)
    F = J(H, N, .)
    for (h = 1; h <= H; h = h + 1) {
        f = om
        for (l = 1; l <= q; l = l + 1) {
            s = q + h - l
            f = f + a[l] * E2[s, .]
        }
        for (l = 1; l <= p; l = l + 1) {
            s = p + h - l
            f = f + b[l] * HH[s, .]
        }
        if (lamt != 0) {
            if (h == 1) f = f + lamt * neg :* E2[q, .]
            else f = f + (lamt / 2) * E2[q + h - 1, .]
        }
        F[h, .] = f
        E2[q + h, .] = f
        HH[p + h, .] = f
    }
    return(F)
}

// forecast dispatcher reading e()
void _xtpg_fc_dispatch(real scalar H, string scalar outname)
{
    string scalar sc
    string matrix cs
    real rowvector b, a, bb, om, neg
    real matrix U, S2, Ul, Hl, F, G, VP, Sig
    real scalar j, q, p, lamt, N, T, nal, l
    sc = st_global("e(subcmd)")
    b = st_matrix("e(b)")
    cs = st_matrixcolstripe("e(b)")
    U = st_matrix("e(resid)")
    S2 = st_matrix("e(sigma2)")
    T = rows(U)
    N = cols(U)
    a = J(1, 0, .)
    bb = J(1, 0, .)
    lamt = 0
    om = J(1, N, .)
    if (sc == "cg") {
        if (st_global("e(het)") != "") {
            errprintf("estat forecast does not support het() variance regressors\n")
            exit(198)
        }
        nal = 0
        for (j = 1; j <= cols(b); j = j + 1) {
            if (cs[j, 1] == "variance") {
                if (cs[j, 2] == "_cons") om = J(1, N, b[j])
                else if (substr(cs[j, 2], 1, 5) == "alpha") {
                    nal = nal + 1
                    om[nal] = b[j]
                }
                else if (strpos(cs[j, 2], ".tarch")) lamt = b[j]
                else if (strpos(cs[j, 2], ".garch")) bb = bb, b[j]
                else if (strpos(cs[j, 2], ".arch")) a = a, b[j]
            }
        }
    }
    if (sc == "armagarch") {
        VP = st_matrix("e(varpi)")
        om = VP[., 1]'
        for (j = 1; j <= cols(b); j = j + 1) {
            if (cs[j, 1] == "variance") {
                if (strpos(cs[j, 2], ".garch")) bb = bb, b[j]
                else if (strpos(cs[j, 2], ".arch")) a = a, b[j]
            }
        }
    }
    if (sc == "cl") {
        G = st_matrix("e(gamma)")
        a = b[1]
        bb = b[2]
        om = G * (1 - a - bb)
    }
    if (sc == "vt") {
        Sig = st_matrix("e(Sigma)")
        a = b[cols(b) - 1]
        bb = b[cols(b)]
        om = diagonal(Sig)' * (1 - a - bb)
    }
    q = cols(a)
    p = cols(bb)
    Ul = J(q, N, .)
    for (l = 1; l <= q; l = l + 1) Ul[l, .] = U[T - q + l, .] :^ 2
    Hl = J(p, N, .)
    for (l = 1; l <= p; l = l + 1) Hl[l, .] = S2[T - p + l, .]
    neg = (U[T, .] :< 0)
    F = _xtpg_fcast(Ul, Hl, om, a, bb, lamt, neg, H)
    st_matrix(outname, F)
}

real scalar _xtpg_median(real colvector x)
{
    real colvector y
    real scalar n
    y = select(x, x :< .)
    n = rows(y)
    if (n == 0) return(.)
    y = sort(y, 1)
    if (mod(n, 2) == 1) return(y[(n + 1) / 2])
    return((y[n / 2] + y[n / 2 + 1]) / 2)
}

real scalar _xtpg_mcolmed(string scalar mname, real scalar j)
{
    real matrix M
    M = st_matrix(mname)
    return(_xtpg_median(M[., j]))
}

// ------------------------------------------------------------------------
// Su & Zhu (2024): panel ARMA(P,Q)-GARCH(L,K), large N and T
//   y_it = mu_i + x_it'b + sum phi_p y_i,t-p + sum psi_q u_i,t-q + u_it   (2.1a)
//   h_it = w_i(1 - sum tau - sum nu) + sum tau_l u2 + sum nu_k h        (2.6)
// Step 1: concentrated LS (2.4)-(2.5), presample y = u = 0
// Step 2: VT-QML (2.9) with w_i-hat = T^-1 sum u_it^2
// ------------------------------------------------------------------------
struct xtpg_ag {
    real scalar N, T, k, P, Q, L, K
    real matrix Y
    pointer(real matrix) rowvector X
}

// concentrated residuals U (T x N) and mu-hat (1 x N) for lam = (b, phi, psi)
real matrix _xtpg_ag_resid(struct xtpg_ag scalar D, real rowvector lam, real rowvector mu,
    real scalar zl2)
{
    real matrix V, Z, U
    real colvector zl
    real rowvector b, phi, psi
    real scalar t, p, q, c, s
    b = J(1, 0, .)
    if (D.k > 0) b = lam[1..D.k]
    phi = J(1, 0, .)
    if (D.P > 0) phi = lam[(D.k + 1)..(D.k + D.P)]
    psi = J(1, 0, .)
    if (D.Q > 0) psi = lam[(D.k + D.P + 1)..(D.k + D.P + D.Q)]
    V = D.Y
    for (p = 1; p <= D.P; p = p + 1) {
        V[(p + 1)..D.T, .] = V[(p + 1)..D.T, .] - phi[p] * D.Y[1..(D.T - p), .]
    }
    for (c = 1; c <= D.k; c = c + 1) V = V - b[c] * (*D.X[c])
    // inverse MA filter B_psi^-1: z_t = v_t - sum psi_q z_{t-q}
    Z = V
    zl = J(D.T, 1, 1)
    if (D.Q > 0) {
        for (t = 2; t <= D.T; t = t + 1) {
            for (q = 1; q <= D.Q; q = q + 1) {
                s = t - q
                if (s >= 1) {
                    Z[t, .] = Z[t, .] - psi[q] * Z[s, .]
                    zl[t] = zl[t] - psi[q] * zl[s]
                }
            }
        }
    }
    zl2 = cross(zl, zl)
    mu = (zl' * Z) / zl2                                         // eq.(2.4)
    U = Z - zl * mu
    return(U)
}

real scalar _xtpg_ag_ok(struct xtpg_ag scalar D, real rowvector lam)
{
    real rowvector phi, psi
    real colvector r
    if (D.P > 0) {
        phi = lam[(D.k + 1)..(D.k + D.P)]
        r = polyroots((1, -phi))
        if (min(abs(r)) <= 1.001) return(0)
    }
    if (D.Q > 0) {
        psi = lam[(D.k + D.P + 1)..(D.k + D.P + D.Q)]
        r = polyroots((1, psi))
        if (min(abs(r)) <= 1.001) return(0)
    }
    return(1)
}

void _xtpg_ag_eval1(real scalar todo, real rowvector lam, struct xtpg_ag scalar D,
    real scalar v, real rowvector g, real matrix H)
{
    real rowvector mu
    real scalar zl2
    real matrix U
    if (!_xtpg_ag_ok(D, lam)) {
        v = .
        return
    }
    U = _xtpg_ag_resid(D, lam, mu, zl2)
    v = -sum(U :* U) / (D.N * D.T)                               // -Q_lambda (2.5)
}

// GARCH variances (T x N), presample u2 = h = w_i (reproduces h_i1 = w_i of the authors' code)
real matrix _xtpg_ag_h(real matrix U, real rowvector om, real rowvector zeta, real scalar L, real scalar K)
{
    real scalar T, t, l, s, sz
    real matrix H, U2
    real rowvector h, tau, nu
    T = rows(U)
    tau = zeta[1..L]
    nu = J(1, 0, .)
    if (K > 0) nu = zeta[(L + 1)..(L + K)]
    sz = sum(zeta)
    U2 = U :* U
    H = J(T, cols(U), .)
    for (t = 1; t <= T; t = t + 1) {
        h = om * (1 - sz)
        for (l = 1; l <= L; l = l + 1) {
            s = t - l
            if (s >= 1) {
                h = h + tau[l] * U2[s, .]
            }
            else {
                h = h + tau[l] * om
            }
        }
        for (l = 1; l <= K; l = l + 1) {
            s = t - l
            if (s >= 1) {
                h = h + nu[l] * H[s, .]
            }
            else {
                h = h + nu[l] * om
            }
        }
        H[t, .] = h
    }
    return(H)
}

real matrix _xtpg_ag_llit(real matrix U, real rowvector om, real rowvector zeta, real scalar L, real scalar K)
{
    real matrix H
    if (min(zeta) < 0 | sum(zeta) >= 1) return(J(rows(U), cols(U), .))
    H = _xtpg_ag_h(U, om, zeta, L, K)
    if (min(H) <= 0) return(J(rows(U), cols(U), .))
    return(-0.5 * (ln(2 * pi()) :+ ln(H) + (U :* U) :/ H))
}

// zeta = exp(a) / (1 + sum exp(a)): keeps tau, nu > 0 and sum < 1
real rowvector _xtpg_ag_soft(real rowvector a)
{
    real rowvector e
    e = exp(a)
    return(e / (1 + sum(e)))
}

void _xtpg_ag_eval2(real scalar todo, real rowvector a, real matrix U, real rowvector om,
    real scalar L, real scalar K, real colvector lnf, real matrix g, real matrix H)
{
    lnf = rowsum(_xtpg_ag_llit(U, om, _xtpg_ag_soft(a), L, K))
}

real rowvector _xtpg_ag_step1(struct xtpg_ag scalar D, real rowvector lam0)
{
    transmorphic S
    S = optimize_init()
    optimize_init_evaluator(S, &_xtpg_ag_eval1())
    optimize_init_evaluatortype(S, "d0")
    optimize_init_argument(S, 1, D)
    optimize_init_params(S, lam0)
    optimize_init_technique(S, "nr")
    optimize_init_tracelevel(S, "none")
    optimize_init_singularHmethod(S, "hybrid")
    optimize_init_conv_warning(S, "off")
    if (_optimize(S) != 0) {
        optimize_init_technique(S, "bfgs")
        optimize_init_params(S, lam0)
        (void) _optimize(S)
    }
    return(optimize_result_params(S))
}

real rowvector _xtpg_ag_step2(real matrix U, real rowvector om, real scalar L, real scalar K)
{
    transmorphic S
    real rowvector z0, best, tv, nv
    real scalar bestll, v, i, j, a, c
    tv = (0.05, 0.10, 0.20, 0.30)
    nv = (0.00, 0.20, 0.40, 0.60, 0.80)
    best = J(1, L + K, 0.05)
    bestll = -1e300
    for (i = 1; i <= cols(tv); i = i + 1) {
        for (j = 1; j <= cols(nv); j = j + 1) {
            if (K == 0 & j > 1) continue
            z0 = (J(1, L, tv[i] / L), J(1, K, nv[j] / max((K, 1))))
            if (sum(z0) >= 0.99) continue
            if (K > 0) {
                if (nv[j] == 0) z0[(L + 1)..(L + K)] = J(1, K, 0.01)
            }
            v = sum(_xtpg_ag_llit(U, om, z0, L, K))
            if (v > bestll) {
                bestll = v
                best = z0
            }
        }
    }
    S = optimize_init()
    optimize_init_evaluator(S, &_xtpg_ag_eval2())
    optimize_init_evaluatortype(S, "gf0")
    optimize_init_argument(S, 1, U)
    optimize_init_argument(S, 2, om)
    optimize_init_argument(S, 3, L)
    optimize_init_argument(S, 4, K)
    optimize_init_params(S, ln(best :/ (1 - sum(best))))
    optimize_init_technique(S, "nr")
    optimize_init_tracelevel(S, "none")
    optimize_init_singularHmethod(S, "hybrid")
    optimize_init_conv_warning(S, "off")
    if (_optimize(S) != 0) {
        optimize_init_params(S, ln(best :/ (1 - sum(best))))
        optimize_init_technique(S, "bfgs")
        (void) _optimize(S)
    }
    return(_xtpg_ag_soft(optimize_result_params(S)))
}

// numerical d vec(U) / d lam' (NT x d), unit-major stacking
real matrix _xtpg_ag_dU(struct xtpg_ag scalar D, real rowvector lam)
{
    real matrix Dm, Up, Um
    real rowvector lp, lm, mu
    real scalar j, hh, zl2
    Dm = J(D.N * D.T, cols(lam), .)
    for (j = 1; j <= cols(lam); j = j + 1) {
        hh = 1e-6 * max((abs(lam[j]), 1))
        lp = lam
        lm = lam
        lp[j] = lam[j] + hh
        lm[j] = lam[j] - hh
        Up = _xtpg_ag_resid(D, lp, mu, zl2)
        Um = _xtpg_ag_resid(D, lm, mu, zl2)
        Dm[., j] = vec((Up - Um) / (2 * hh))
    }
    return(Dm)
}

// per-(i,t) scores of l_it wrt zeta: returns NT x (L+K), unit-major
real matrix _xtpg_ag_gz(real matrix U, real rowvector om, real rowvector zeta, real scalar L, real scalar K)
{
    real matrix G, Lp, Lm
    real rowvector zp, zm
    real scalar j, hh
    G = J(rows(U) * cols(U), cols(zeta), .)
    for (j = 1; j <= cols(zeta); j = j + 1) {
        hh = 1e-5 * max((abs(zeta[j]), 1e-2))
        zp = zeta
        zm = zeta
        zp[j] = zeta[j] + hh
        zm[j] = zeta[j] - hh
        if (zm[j] < 0) zm[j] = 0
        Lp = _xtpg_ag_llit(U, om, zp, L, K)
        Lm = _xtpg_ag_llit(U, om, zm, L, K)
        G[., j] = vec((Lp - Lm) / (zp[j] - zm[j]))
    }
    return(G)
}

// full fit: estimates, sandwich variances, unit effects, optional jackknife
void _xtpg_ag_fit(string scalar yname, string scalar xnames, string scalar touse,
    real scalar N, real scalar T, real scalar P, real scalar Q, real scalar L, real scalar K,
    string scalar lam0name, real scalar jack)
{
    struct xtpg_ag scalar D, D1, D2
    real colvector y
    real matrix Xall, U, H, Dm, A, Vl, G, Gc, Gw, Lp, Lm, Pi, IF, Z, Vz, Gam, Up, Um, Uj, E
    real rowvector lam, lam0, zeta, om, mu, lp, lm, zp, zm, omp, lam1, lam2, lamJ, zetaJ, z1, z2, mu1, kap
    real scalar c, j, hh, zl2, NT, d, dz, n2, s1, s2
    real matrix MU, OM, VP
    y = st_data(., yname, touse)
    D.N = N
    D.T = T
    D.P = P
    D.Q = Q
    D.L = L
    D.K = K
    D.Y = rowshape(y, N)'
    D.k = 0
    D.X = J(1, 0, NULL)
    if (xnames != "") {
        Xall = st_data(., tokens(xnames), touse)
        D.k = cols(Xall)
        D.X = J(1, D.k, NULL)
        for (c = 1; c <= D.k; c = c + 1) {
            D.X[c] = &(rowshape(Xall[., c], N)')
        }
    }
    NT = N * T
    lam0 = st_matrix(lam0name)
    lam = _xtpg_ag_step1(D, lam0)                                 // eq.(2.5)
    U = _xtpg_ag_resid(D, lam, mu, zl2)
    om = colsum(U :* U) / T
    zeta = _xtpg_ag_step2(U, om, L, K)                            // eq.(2.9)
    H = _xtpg_ag_h(U, om, zeta, L, K)

    // ---- Var(lam): Gauss-Newton sandwich on the concentrated residuals (Thm 4.1, MDS errors)
    d = cols(lam)
    Dm = _xtpg_ag_dU(D, lam)
    A = invsym(cross(Dm, Dm))
    Vl = A * cross(Dm, vec(U :* U), Dm) * A

    // ---- Var(zeta): Gamma2^-1 Omega2 Gamma2^-1 / NT with estimation effects of w and lam (Thm 4.4)
    dz = cols(zeta)
    G = _xtpg_ag_gz(U, om, zeta, L, K)
    Gam = J(dz, dz, .)
    for (j = 1; j <= dz; j = j + 1) {
        hh = 1e-4 * max((abs(zeta[j]), 1e-2))
        zp = zeta
        zm = zeta
        zp[j] = zeta[j] + hh
        zm[j] = zeta[j] - hh
        if (zm[j] < 0) zm[j] = 0
        Gam[., j] = -(colsum(_xtpg_ag_gz(U, om, zp, L, K)) - colsum(_xtpg_ag_gz(U, om, zm, L, K)))' / ((zp[j] - zm[j]) * NT)
    }
    Gam = (Gam + Gam') / 2
    // effect of w_i-hat: (1/T) sum_s d g_is / d w_i  x  (u_it^2 - w_i)
    Gw = J(N, dz, .)
    omp = om :* (1 + 1e-4)
    Lp = _xtpg_ag_gz(U, omp, zeta, L, K)
    omp = om :* (1 - 1e-4)
    Lm = _xtpg_ag_gz(U, omp, zeta, L, K)
    Gc = G
    for (j = 1; j <= dz; j = j + 1) {
        A = rowshape((Lp[., j] - Lm[., j]), N)' :/ (2e-4 * om)    // T x N
        Gc[., j] = G[., j] + vec((colsum(A) / T) :* (U :* U :- om))
    }
    // effect of lam-hat: Pi = (1/NT) d sum g / d lam' (total, w re-estimated)
    Pi = J(dz, d, .)
    for (j = 1; j <= d; j = j + 1) {
        hh = 1e-5 * max((abs(lam[j]), 1))
        lp = lam
        lm = lam
        lp[j] = lam[j] + hh
        lm[j] = lam[j] - hh
        Up = _xtpg_ag_resid(D, lp, mu1, zl2)
        Um = _xtpg_ag_resid(D, lm, mu1, zl2)
        Pi[., j] = (colsum(_xtpg_ag_gz(Up, colsum(Up :* Up) / T, zeta, L, K)) -
                    colsum(_xtpg_ag_gz(Um, colsum(Um :* Um) / T, zeta, L, K)))' / (2 * hh * NT)
    }
    IF = -(Dm :* vec(U)) * (invsym(cross(Dm, Dm) / NT))'          // influence of lam-hat, NT x d
    Z = Gc + IF * Pi'
    Vz = invsym(Gam) * (cross(Z, Z) / NT) * invsym(Gam) / NT

    // ---- unit effects: mu_i (Thm 4.2), w_i and varpi_i (Thm 4.5)
    E = U :/ sqrt(H)
    kap = mean(vec(E :^ 4))
    s1 = 1
    if (K > 0) s1 = 1 - sum(zeta[(L + 1)..(L + K)])
    s2 = 1 - sum(zeta)
    MU = (mu', sqrt(om' / zl2))
    OM = (om', (s1 / s2) * sqrt((kap - 1) * colsum(H :* H)' / T / T))
    VP = ((om * s2)', s1 * sqrt((kap - 1) * colsum(H :* H)' / T / T))

    st_matrix("__xtpg_lam", lam)
    st_matrix("__xtpg_zeta", zeta)
    st_matrix("__xtpg_Vl", Vl)
    st_matrix("__xtpg_Vz", Vz)
    st_matrix("__xtpg_MU", MU)
    st_matrix("__xtpg_OM", OM)
    st_matrix("__xtpg_VP", VP)
    st_matrix("__xtpg_U", U)
    st_matrix("__xtpg_S2", H)
    st_numscalar("__xtpg_Qls", sum(U :* U))
    st_numscalar("__xtpg_ll", sum(_xtpg_ag_llit(U, om, zeta, L, K)))
    st_numscalar("__xtpg_kappa", kap)

    // ---- half-panel jackknife (4.4), (4.11): needs T >= 2*(P+Q+10)
    if (jack) {
        n2 = floor(T / 2)
        D1 = D
        D2 = D
        D1.T = n2
        D2.T = T - n2
        D1.Y = D.Y[1..n2, .]
        D2.Y = D.Y[(n2 + 1)..T, .]
        if (D.k > 0) {
            D1.X = J(1, D.k, NULL)
            D2.X = J(1, D.k, NULL)
            for (c = 1; c <= D.k; c = c + 1) {
                D1.X[c] = &((*D.X[c])[1..n2, .])
                D2.X[c] = &((*D.X[c])[(n2 + 1)..T, .])
            }
        }
        lam1 = _xtpg_ag_step1(D1, lam)
        lam2 = _xtpg_ag_step1(D2, lam)
        lamJ = 2 * lam - (lam1 + lam2) / 2
        Uj = _xtpg_ag_resid(D, lamJ, mu1, zl2)
        z1 = _xtpg_ag_step2(Uj, colsum(Uj :* Uj) / T, L, K)       // zeta-star
        z2 = _xtpg_ag_step2(Uj[1..n2, .], colsum(Uj[1..n2, .] :^ 2) / n2, L, K)
        zp = _xtpg_ag_step2(Uj[(n2 + 1)..T, .], colsum(Uj[(n2 + 1)..T, .] :^ 2) / (T - n2), L, K)
        zetaJ = 2 * z1 - (z2 + zp) / 2
        st_matrix("__xtpg_lamJ", lamJ)
        st_matrix("__xtpg_zetaJ", zetaJ)
        st_matrix("__xtpg_halves", (lam1, z2 \ lam2, zp))
        st_matrix("__xtpg_muJ", mu1)
    }
}

// ------------------------------------------------------------------------
// Zhu, Li, Zhang & Li (2026): panel quantile GARCH under homogeneity
//   Q_tau(y_it|F) = w_i + a_i sum_{j<t} b_i^{j-1} |y_i,t-j|      eq.(3), y_{t<=0} = 0
// Stage I  self-weighted CQE per unit                             eq.(5), weights eq.(9)
// Stage II binary segmentation on sorted estimates, CUSUM (6), BIC3 threshold
// Stage III pooled self-weighted CQE under the detected groups    eq.(7)
// ------------------------------------------------------------------------
real scalar _xtpg_q7(real colvector x, real scalar p)
{
    real colvector s
    real scalar n, h, lo
    s = sort(select(x, x :< .), 1)
    n = rows(s)
    if (n == 0) return(.)
    h = (n - 1) * p + 1
    lo = floor(h)
    if (lo >= n) return(s[n])
    return(s[lo] + (h - lo) * (s[lo + 1] - s[lo]))
}

// self-weights (He and Yi 2021), authors' weight_function_HeYi2021_cpp
real matrix _xtpg_qg_weights(real matrix Y)
{
    real scalar T, N, i, s, m, M
    real rowvector c
    real matrix A, W
    real colvector kern, tail
    T = rows(Y)
    N = cols(Y)
    c = J(1, N, .)
    for (i = 1; i <= N; i = i + 1) c[i] = _xtpg_q7(Y[., i], 0.95)
    A = (abs(Y) :< c) + (abs(Y) :/ c) :* (abs(Y) :>= c)
    M = min((T - 1, 450))
    W = J(T, N, .)
    if (M < 1) return(J(T, N, 1))
    kern = exp(-(ln(1::M) :^ 2))
    tail = J(M + 1, 1, 0)
    for (s = M; s >= 1; s = s - 1) tail[s] = tail[s + 1] + kern[s]
    for (s = 1; s <= T; s = s + 1) {
        m = min((s - 1, M))
        W[s, .] = J(1, N, 0)
        if (m >= 1) W[s, .] = kern[1..m]' * A[((s - 1)::(s - m)), .]
        if (s <= M) W[s, .] = W[s, .] :+ tail[s]
        W[s, .] = W[s, .] :^ (-3)
    }
    return(W)
}

// conditional quantiles (T x N) for unit parameters PH (N x 3)
real matrix _xtpg_qg_q(real matrix Y, real matrix PH)
{
    external real matrix __xtpg_QF
    real scalar T, t, K
    real matrix S, Ay, Q
    real rowvector b
    T = rows(Y)
    Ay = abs(Y)
    b = PH[., 3]'
    S = J(T, cols(Y), 0)
    for (t = 2; t <= T; t = t + 1) S[t, .] = Ay[t - 1, .] + b :* S[t - 1, .]
    Q = PH[., 1]' :+ PH[., 2]' :* S
    K = cols(PH)
    // factor QGARCH, eq.(10): + lambda_i' f_t  (f_t common, T x r)
    if (K > 3) Q = Q + __xtpg_QF * PH[., 4..K]'
    return(Q)
}

void _xtpg_qg_factormat(string scalar vars, string scalar touse, real scalar T, string scalar outname)
{
    real matrix F
    F = st_data(., tokens(vars), touse)
    st_matrix(outname, F[1..T, .])
}

void _xtpg_qg_setF(string scalar fname)
{
    external real matrix __xtpg_QF
    if (fname == "") __xtpg_QF = J(0, 0, .)
    else __xtpg_QF = st_matrix(fname)
}

real rowvector _xtpg_qg_loss(real matrix Y, real matrix W, real matrix PH, real scalar tau)
{
    real matrix E
    E = Y - _xtpg_qg_q(Y, PH)
    return(colsum(W :* E :* (tau :- (E :<= 0))))
}

void _xtpg_qg_eval1(real scalar todo, real rowvector p, real colvector y, real colvector w,
    real scalar tau, real scalar v, real rowvector g, real matrix H)
{
    if (p[3] < 1e-3 | p[3] > 1 - 1e-3) {
        v = .
        return
    }
    v = -_xtpg_qg_loss(y, w, p, tau)
}

// GARCH(1,1) Gaussian QMLE, zero mean, for starting values (authors' Init_par)
void _xtpg_qg_garch_eval(real scalar todo, real rowvector p, real colvector r, real scalar v,
    real rowvector g, real matrix H)
{
    real scalar T, t, h
    real colvector hh
    if (p[1] <= 0 | p[2] < 0 | p[3] < 0 | p[2] + p[3] >= 1) {
        v = .
        return
    }
    T = rows(r)
    hh = J(T, 1, .)
    h = mean(r :* r)
    for (t = 1; t <= T; t = t + 1) {
        if (t >= 2) h = p[1] + p[2] * r[t - 1] * r[t - 1] + p[3] * h
        hh[t] = h
    }
    v = -0.5 * sum(ln(hh) + (r :* r) :/ hh)
}

real rowvector _xtpg_qg_start(real colvector y, real scalar tau)
{
    real colvector r, hh, e
    real rowvector p
    real scalar T, t, h, Qt
    transmorphic S
    r = sqrt(abs(y)) :* ((y :>= 0) - (y :< 0))
    S = optimize_init()
    optimize_init_evaluator(S, &_xtpg_qg_garch_eval())
    optimize_init_evaluatortype(S, "d0")
    optimize_init_argument(S, 1, r)
    optimize_init_params(S, (0.1 * mean(r :* r), 0.1, 0.8))
    optimize_init_technique(S, "nr")
    optimize_init_tracelevel(S, "none")
    optimize_init_conv_warning(S, "off")
    optimize_init_singularHmethod(S, "hybrid")
    if (_optimize(S) != 0) return((_xtpg_q7(y, tau), 0.1 * sign(tau - 0.5), 0.8))
    p = optimize_result_params(S)
    T = rows(r)
    hh = J(T, 1, .)
    h = mean(r :* r)
    for (t = 1; t <= T; t = t + 1) {
        if (t >= 2) h = p[1] + p[2] * r[t - 1] * r[t - 1] + p[3] * h
        hh[t] = h
    }
    e = r :/ sqrt(hh)
    Qt = _xtpg_q7((e :* e) :* ((e :> 0) - (e :<= 0)), tau)
    return((p[1] / (1 - p[3]) * Qt, p[2] * Qt, min((max((p[3], 0.01)), 0.99))))
}

real rowvector _xtpg_qg_nm(real colvector y, real colvector w, real scalar tau, real rowvector p0)
{
    transmorphic S
    real rowvector dl
    S = optimize_init()
    optimize_init_evaluator(S, &_xtpg_qg_eval1())
    optimize_init_evaluatortype(S, "d0")
    optimize_init_argument(S, 1, y)
    optimize_init_argument(S, 2, w)
    optimize_init_argument(S, 3, tau)
    optimize_init_params(S, p0)
    optimize_init_technique(S, "nm")
    dl = 0.1 * abs(p0) :+ 0.05
    dl[3] = 0.05
    optimize_init_nmsimplexdeltas(S, dl)
    optimize_init_conv_maxiter(S, 2000)
    optimize_init_tracelevel(S, "none")
    optimize_init_conv_warning(S, "off")
    if (_optimize(S) != 0) return(J(1, cols(p0), .))
    return(optimize_result_params(S))
}

// Stage I: initial estimates (N x 3), with multistart (GARCH start + best grid points)
real matrix _xtpg_qg_stage1(real matrix Y, real matrix W, real scalar tau)
{
    real scalar N, i, a, b, c, k, best, v
    real matrix PH, G, Lg
    real rowvector p, pb, q
    real colvector ord, lv, gq
    external real matrix __xtpg_QF
    real scalar r
    real rowvector ld
    real matrix Fx
    N = cols(Y)
    r = cols(__xtpg_QF)
    PH = J(N, 3 + r, .)
    gq = invnormal((1::9) / 10)
    G = J(729, 3, .)
    k = 0
    for (a = 1; a <= 9; a = a + 1) {
        for (b = 1; b <= 9; b = b + 1) {
            for (c = 1; c <= 9; c = c + 1) {
                k = k + 1
                G[k, .] = (gq[a], gq[b], c / 10)
            }
        }
    }
    for (i = 1; i <= N; i = i + 1) {
        p = _xtpg_qg_start(Y[., i], tau)
        ld = J(1, 0, .)
        if (r > 0) {
            Fx = J(rows(Y), 1, 1), __xtpg_QF
            ld = (invsym(cross(Fx, Fx)) * cross(Fx, Y[., i]))'
            ld = ld[2..(r + 1)]
            p = p, ld
        }
        pb = _xtpg_qg_nm(Y[., i], W[., i], tau, p)
        best = 1e300
        if (!hasmissing(pb)) best = _xtpg_qg_loss(Y[., i], W[., i], pb, tau)
        // grid (fit1_optim_grid): evaluate the loss at 729 points, refine the 3 best
        lv = J(729, 1, .)
        for (k = 1; k <= 729; k = k + 1) lv[k] = _xtpg_qg_loss(Y[., i], W[., i], (G[k, .], ld), tau)
        ord = order(lv, 1)
        for (k = 1; k <= 3; k = k + 1) {
            q = _xtpg_qg_nm(Y[., i], W[., i], tau, (G[ord[k], .], ld))
            if (hasmissing(q)) continue
            v = _xtpg_qg_loss(Y[., i], W[., i], q, tau)
            if (v < best) {
                best = v
                pb = q
            }
        }
        PH[i, .] = pb
    }
    return(PH)
}

// binary segmentation on a sorted vector, returns ascending change points incl. j
real colvector _xtpg_bs(real colvector v, real scalar i, real scalar j, real scalar delta)
{
    real scalar h, hb, D, Db
    real colvector out
    if (j - i + 1 < 2) return(j)
    Db = -1
    hb = i
    for (h = i; h <= j - 1; h = h + 1) {
        D = sqrt((j - h) * (h - i + 1) / (j - i + 1)) * abs(mean(v[(h + 1)..j]) - mean(v[i..h]))   // eq.(6)
        if (D > Db) {
            Db = D
            hb = h
        }
    }
    if (Db <= delta) return(j)
    out = (j \ hb \ _xtpg_bs(v, i, hb, delta) \ _xtpg_bs(v, hb + 1, j, delta))
    return(uniqrows(out))
}

// unit-level parameter matrix from group values theta and labels LAB (N x 3)
real matrix _xtpg_qg_expand(real rowvector theta, real matrix LAB, real rowvector g)
{
    real matrix PH
    real scalar l, off
    PH = J(rows(LAB), cols(LAB), .)
    off = 0
    for (l = 1; l <= cols(LAB); l = l + 1) {
        PH[., l] = theta[off :+ LAB[., l]]'
        off = off + g[l]
    }
    return(PH)
}

// group labels (1..g, ascending in value) from change points over the sorted order
real colvector _xtpg_qg_labels(real colvector x, real colvector cp)
{
    real colvector ord, lab
    real scalar k, s, e
    ord = order(x, 1)
    lab = J(rows(x), 1, .)
    s = 1
    for (k = 1; k <= rows(cp); k = k + 1) {
        e = cp[k]
        lab[ord[s..e]] = J(e - s + 1, 1, k)
        s = e + 1
    }
    return(lab)
}

void _xtpg_qg_evalp(real scalar todo, real rowvector th, real matrix Y, real matrix W,
    real scalar tau, real matrix LAB, real rowvector g, real matrix PHfix, real scalar lonly,
    real scalar v, real rowvector gr, real matrix H)
{
    real matrix PH
    real rowvector full, bb
    real scalar off
    if (lonly == 0) {
        bb = th[(g[1] + g[2] + 1)..(g[1] + g[2] + g[3])]
        if (min(bb) < 0 | max(bb) > 1 - 1e-3) {
            v = .
            return
        }
        PH = _xtpg_qg_expand(th, LAB, g)
    }
    else {
        PH = PHfix
        PH[., lonly] = th[LAB[., lonly]]'
        if (lonly == 3) {
            if (min(th) < 0 | max(th) > 1 - 1e-3) {
                v = .
                return
            }
        }
    }
    v = -sum(_xtpg_qg_loss(Y, W, PH, tau)) / (rows(Y) * cols(Y))
}

real rowvector _xtpg_qg_optp(real matrix Y, real matrix W, real scalar tau, real matrix LAB,
    real rowvector g, real matrix PHfix, real scalar lonly, real rowvector th0)
{
    transmorphic S
    real rowvector dl, th, thn
    real scalar v, vn, r
    S = optimize_init()
    optimize_init_evaluator(S, &_xtpg_qg_evalp())
    optimize_init_evaluatortype(S, "d0")
    optimize_init_argument(S, 1, Y)
    optimize_init_argument(S, 2, W)
    optimize_init_argument(S, 3, tau)
    optimize_init_argument(S, 4, LAB)
    optimize_init_argument(S, 5, g)
    optimize_init_argument(S, 6, PHfix)
    optimize_init_argument(S, 7, lonly)
    optimize_init_technique(S, "nm")
    optimize_init_conv_maxiter(S, 5000)
    optimize_init_tracelevel(S, "none")
    optimize_init_conv_warning(S, "off")
    // Nelder-Mead with restarts from the point reached (simplex re-expanded) until no gain
    th = th0
    v = .
    for (r = 1; r <= 12; r = r + 1) {
        dl = 0.10 * abs(th) :+ 0.02
        if (r > 1) dl = dl / r
        optimize_init_params(S, th)
        optimize_init_nmsimplexdeltas(S, dl)
        if (_optimize(S) != 0) break
        thn = optimize_result_params(S)
        vn = -optimize_result_value(S)
        if (v < .) {
            if (v - vn < 1e-9 * (1 + abs(v))) {
                if (vn < v) th = thn
                break
            }
        }
        th = thn
        v = vn
    }
    return(th)
}

// segment means of the sorted initial values (alternative start)
real rowvector _xtpg_qg_th0m(real colvector x, real colvector cp)
{
    real colvector s
    real rowvector m
    real scalar k, a
    s = sort(x, 1)
    m = J(1, rows(cp), .)
    a = 1
    for (k = 1; k <= rows(cp); k = k + 1) {
        m[k] = mean(s[a..cp[k]])
        a = cp[k] + 1
    }
    return(m)
}

// sorted initial values at the change points (authors' fr_theta_initial_IN_optim)
real rowvector _xtpg_qg_th0(real colvector x, real colvector cp)
{
    real colvector s
    s = sort(x, 1)
    return(s[cp]')
}

// BIC3 for threshold delta on parameter l (others at their unit-level initial values)
real scalar _xtpg_qg_bic(real matrix Y, real matrix W, real scalar tau, real matrix PH0,
    real scalar l, real scalar delta, real colvector cp, real colvector lab)
{
    real colvector s
    real rowvector th, g
    real matrix LAB, PH
    real scalar N, v1, v2
    N = rows(PH0)
    s = sort(PH0[., l], 1)
    cp = _xtpg_bs(s, 1, N, delta)
    lab = _xtpg_qg_labels(PH0[., l], cp)
    LAB = J(N, cols(PH0), 1)
    LAB[., l] = lab
    g = J(1, cols(PH0), 1)
    g[l] = rows(cp)
    th = _xtpg_qg_optp(Y, W, tau, LAB, g, PH0, l, _xtpg_qg_th0(PH0[., l], cp))
    PH = PH0
    PH[., l] = th[lab]'
    v1 = sum(_xtpg_qg_loss(Y, W, PH, tau))
    th = _xtpg_qg_optp(Y, W, tau, LAB, g, PH0, l, _xtpg_qg_th0m(PH0[., l], cp))
    PH[., l] = th[lab]'
    v2 = sum(_xtpg_qg_loss(Y, W, PH, tau))
    return(min((v1, v2)) + rows(cp) * ln(N))                                 // BIC3
}

// adaptive grid search for delta_l (authors' fc3_select_delta_l_tau_BIC)
real scalar _xtpg_qg_selectdelta(real matrix Y, real matrix W, real scalar tau, real matrix PH0,
    real scalar l, real scalar lo, real scalar hi, real scalar ncand, real scalar tol)
{
    real colvector cand, bic, cp, lab, idx
    real scalar it, j, mn, mnlast, fi, la, dhat
    cand = rangen(lo, hi, ncand)
    mn = 0
    it = 0
    do {
        mnlast = mn
        bic = J(ncand, 1, .)
        for (j = 1; j <= ncand; j = j + 1) bic[j] = _xtpg_qg_bic(Y, W, tau, PH0, l, cand[j], cp, lab)
        mn = min(bic)
        idx = selectindex(abs(bic :- mn) :<= 1e-12)
        fi = min(idx)
        la = max(idx)
        dhat = cand[fi]
        it = it + 1
        if (fi == 1 & la == ncand) break
        if (it >= 25) break
        if (fi == 1) {
            cand = rangen(cand[1], cand[la + 1], ncand + 1)
            cand = cand[1..ncand]
        }
        else if (la == ncand) {
            cand = rangen(cand[fi - 1], cand[ncand], ncand + 1)
            cand = cand[2..(ncand + 1)]
        }
        else {
            cand = rangen(cand[fi - 1], cand[la + 1], ncand + 2)
            cand = cand[2..(ncand + 1)]
        }
    } while (abs(mn - mnlast) > tol)
    return(dhat)
}

// derivative of q_it wrt the unit parameters: returns 3 matrices T x N via pointers
void _xtpg_qg_qdot(real matrix Y, real matrix PH, real matrix S, real matrix dS)
{
    real scalar T, t
    real matrix Ay
    real rowvector b
    T = rows(Y)
    Ay = abs(Y)
    b = PH[., 3]'
    S = J(T, cols(Y), 0)
    dS = J(T, cols(Y), 0)
    for (t = 2; t <= T; t = t + 1) {
        S[t, .] = Ay[t - 1, .] + b :* S[t - 1, .]
        dS[t, .] = S[t - 1, .] + b :* dS[t - 1, .]
    }
}

void _xtpg_qg_fit(string scalar yname, string scalar touse, real scalar N, real scalar T,
    real scalar tau, string scalar grp, real scalar dlo, real scalar dhi, real scalar ncand,
    real scalar tol, real scalar bwtype, real scalar showlog)
{
    real matrix Y, W, PH0, LAB, PH, Qm, Qp, Qn, S, dS, F, O0, O1, V, Gd
    real rowvector g, th, th0, th0m, delta, thp, thn, gr, qd
    real colvector cp, lab, s
    real scalar l, off, n, z, ell, i, t, d, j, k, NT, KK
    external real matrix __xtpg_QF
    Y = st_data(., yname, touse)
    Y = rowshape(Y, N)'
    NT = N * T
    W = _xtpg_qg_weights(Y)
    if (showlog) printf("{txt}Stage I: self-weighted CQE for %g units\n", N)
    PH0 = _xtpg_qg_stage1(Y, W, tau)
    if (hasmissing(PH0)) {
        errprintf("Stage I failed for some units\n")
        exit(430)
    }
    // Stage II
    KK = cols(PH0)
    LAB = J(N, KK, .)
    g = J(1, KK, .)
    delta = J(1, KK, .)
    th0 = J(1, 0, .)
    th0m = J(1, 0, .)
    for (l = 1; l <= KK; l = l + 1) {
        if (substr(grp, l, 1) == "1") {
            if (showlog) printf("{txt}Stage II: threshold for parameter %g\n", l)
            delta[l] = _xtpg_qg_selectdelta(Y, W, tau, PH0, l, dlo, dhi, ncand, tol)
            s = sort(PH0[., l], 1)
            cp = _xtpg_bs(s, 1, N, delta[l])
        }
        else {
            cp = (1::N)
        }
        LAB[., l] = _xtpg_qg_labels(PH0[., l], cp)
        g[l] = rows(cp)
        th0 = th0, _xtpg_qg_th0(PH0[., l], cp)
        th0m = th0m, _xtpg_qg_th0m(PH0[., l], cp)
    }
    // Stage III
    if (showlog) printf("{txt}Stage III: pooled CQE with %g groups in total\n", sum(g))
    th = _xtpg_qg_optp(Y, W, tau, LAB, g, PH0, 0, th0)
    thp = _xtpg_qg_optp(Y, W, tau, LAB, g, PH0, 0, th0m)
    if (sum(_xtpg_qg_loss(Y, W, _xtpg_qg_expand(thp, LAB, g), tau)) < sum(_xtpg_qg_loss(Y, W, _xtpg_qg_expand(th, LAB, g), tau))) th = thp
    PH = _xtpg_qg_expand(th, LAB, g)
    Qm = _xtpg_qg_q(Y, PH)
    // covariance (JBES supplement S.51 ff.): difference-quotient density, bandwidth on n = NT
    n = NT
    z = invnormal(1 - 0.05 / 2)
    if (bwtype == 1) ell = n^(-1 / 3) * z^(2 / 3) * ((1.5 * normalden(invnormal(tau))^2) / (2 * invnormal(tau)^2 + 1))^(1 / 3)
    else ell = n^(-1 / 5) * ((4.5 * normalden(invnormal(tau))^4) / (2 * invnormal(tau)^2 + 1)^2)^(1 / 5)
    if (tau - ell <= 0) ell = tau / 2
    if (tau + ell >= 1) ell = (1 - tau) / 2
    thp = _xtpg_qg_optp(Y, W, tau + ell, LAB, g, PH0, 0, th)
    thn = _xtpg_qg_optp(Y, W, tau - ell, LAB, g, PH0, 0, th)
    Qp = _xtpg_qg_q(Y, _xtpg_qg_expand(thp, LAB, g))
    Qn = _xtpg_qg_q(Y, _xtpg_qg_expand(thn, LAB, g))
    F = 2 * ell :/ abs(Qp - Qn)
    F = F :* (F :< .)
    _xtpg_qg_qdot(Y, PH, S, dS)
    d = cols(th)
    O0 = J(d, d, 0)
    O1 = J(d, d, 0)
    for (i = 1; i <= N; i = i + 1) {
        Gd = J(T, d, 0)
        Gd[., LAB[i, 1]] = J(T, 1, 1)
        Gd[., g[1] + LAB[i, 2]] = S[., i]
        Gd[., g[1] + g[2] + LAB[i, 3]] = PH[i, 2] * dS[., i]
        off = g[1] + g[2] + g[3]
        for (l = 4; l <= KK; l = l + 1) {
            Gd[., off + LAB[i, l]] = __xtpg_QF[., l - 3]
            off = off + g[l]
        }
        O0 = O0 + cross(Gd, W[., i] :^ 2, Gd)
        O1 = O1 + cross(Gd, F[., i] :* W[., i], Gd)
    }
    O0 = tau * (1 - tau) * O0 / NT
    O1 = O1 / NT
    V = invsym(O1) * O0 * invsym(O1) / NT
    st_matrix("__xtpg_th", th)
    st_matrix("__xtpg_V", V)
    st_matrix("__xtpg_g", g)
    st_matrix("__xtpg_delta", delta)
    st_matrix("__xtpg_lab", LAB)
    st_matrix("__xtpg_ph0", PH0)
    st_matrix("__xtpg_ph", PH)
    st_matrix("__xtpg_q", Qm)
    st_matrix("__xtpg_w", W)
    st_numscalar("__xtpg_loss", sum(_xtpg_qg_loss(Y, W, PH, tau)))
    st_numscalar("__xtpg_ell", ell)
    st_numscalar("__xtpg_hit", mean(vec(Y :< Qm)))
}

// ------------------------------------------------------------------------
// Brownlees (2019): Hierarchical GARCH
//  Level I : r_it = b_i rF_t + e_it,  h_it = (1-p_i) h_i + p_i [l_i e2_i,t-1 + (1-l_i) h_i,t-1]   (1)-(2)
//  Level II: b_i = d_b'x_i + u_b, ln h_i = d_h'x_i + u_h, Phi^-1(l_i) = d_l'x_i + u_l,
//            Phi^-1(p_i) = d_p'x_i + u_p, u ~ N(0, tau^2)                                       (3)-(6)
//  SML     : Q = sum_i log S^-1 sum_s f_T(r_i | u_s)   with common draws u_s                       (7)-(9)
// ------------------------------------------------------------------------
struct xtpg_hg {
    real scalar N, T, p, S, hasf, fixpi, pifix
    real matrix R, X, Z
    real colvector F
}

// level-I coefficients (N x S each) for hyper-parameter vector th
void _xtpg_hg_coef(struct xtpg_hg scalar D, real rowvector th, real matrix B, real matrix Hb,
    real matrix Lm, real matrix Pm)
{
    real scalar p, o, k
    real rowvector tau
    real colvector db, dh, dl, dp
    p = D.p
    o = 0
    db = J(p, 1, 0)
    if (D.hasf) {
        db = th[(o + 1)..(o + p)]'
        o = o + p
    }
    dh = th[(o + 1)..(o + p)]'
    o = o + p
    dl = th[(o + 1)..(o + p)]'
    o = o + p
    dp = J(p, 1, 0)
    if (!D.fixpi) {
        dp = th[(o + 1)..(o + p)]'
        o = o + p
    }
    k = 2 + D.hasf + (!D.fixpi)
    tau = exp(th[(o + 1)..(o + k)])
    // draws Z : S x 4 (columns b, h, l, p)
    o = 0
    B = J(D.N, D.S, 0)
    if (D.hasf) {
        o = o + 1
        B = (D.X * db) * J(1, D.S, 1) + J(D.N, 1, 1) * (tau[o] * D.Z[., 1]')
    }
    o = o + 1
    Hb = exp((D.X * dh) * J(1, D.S, 1) + J(D.N, 1, 1) * (tau[o] * D.Z[., 2]'))
    o = o + 1
    Lm = normal((D.X * dl) * J(1, D.S, 1) + J(D.N, 1, 1) * (tau[o] * D.Z[., 3]'))
    if (D.fixpi) {
        Pm = J(D.N, D.S, D.pifix)
    }
    else {
        o = o + 1
        Pm = normal((D.X * dp) * J(1, D.S, 1) + J(D.N, 1, 1) * (tau[o] * D.Z[., 4]'))
    }
}

// N x S matrix of log f_T(r_i | u_s)
real matrix _xtpg_hg_llis(struct xtpg_hg scalar D, real rowvector th)
{
    real matrix B, Hb, Lm, Pm, H, E2, L
    real rowvector e, hv, pv, lv, bv, c0, c1, c2
    real scalar t, NS
    _xtpg_hg_coef(D, th, B, Hb, Lm, Pm)
    NS = D.N * D.S
    // vectorise (N x S) -> 1 x NS, unit-major within draw blocks
    hv = vec(Hb)'
    pv = vec(Pm)'
    lv = vec(Lm)'
    bv = vec(B)'
    c0 = (1 :- pv) :* hv
    c1 = pv :* lv
    c2 = pv :* (1 :- lv)
    H = hv
    L = J(1, NS, 0)
    E2 = H
    for (t = 1; t <= D.T; t = t + 1) {
        if (t >= 2) H = c0 + c1 :* E2 + c2 :* H
        e = J(1, D.S, D.R[t, .]) - (D.hasf * D.F[t]) * bv
        E2 = e :* e
        L = L - 0.5 * (ln(2 * pi()) :+ ln(H) + E2 :/ H)
    }
    return(colshape(L, D.N)')
}

real colvector _xtpg_hg_q(struct xtpg_hg scalar D, real rowvector th, real matrix Lis)
{
    real colvector mx
    Lis = _xtpg_hg_llis(D, th)
    mx = rowmax(Lis)
    return(mx + ln(rowsum(exp(Lis :- mx)) / D.S))                        // eq.(9)
}

void _xtpg_hg_eval(real scalar todo, real rowvector th, struct xtpg_hg scalar D,
    real colvector lnf, real matrix g, real matrix H)
{
    real matrix Lis
    lnf = _xtpg_hg_q(D, th, Lis)
    if (hasmissing(lnf)) lnf = J(D.N, 1, .)
}

// naive per-series ML of (b, ln h, Phi^-1 l, Phi^-1 p) for start values
void _xtpg_hg_unit_eval(real scalar todo, real rowvector c, real colvector r, real colvector f,
    real scalar hasf, real scalar fixpi, real scalar pifix, real scalar v, real rowvector g, real matrix H)
{
    real scalar t, T, b, hb, l, pp, h, e2, o
    T = rows(r)
    o = 0
    b = 0
    if (hasf) {
        b = c[1]
        o = 1
    }
    hb = exp(c[o + 1])
    l = normal(c[o + 2])
    pp = pifix
    if (!fixpi) pp = normal(c[o + 3])
    h = hb
    e2 = hb
    v = 0
    for (t = 1; t <= T; t = t + 1) {
        if (t >= 2) h = (1 - pp) * hb + pp * (l * e2 + (1 - l) * h)
        e2 = (r[t] - b * f[t])^2
        v = v - 0.5 * (ln(2 * pi()) + ln(h) + e2 / h)
    }
}

void _xtpg_hg_fit(string scalar Rname, string scalar Xname, string scalar Fname,
    real scalar S, real scalar fixpi, real scalar pifix, real scalar seed,
    string scalar vcetype, real scalar showlog)
{
    struct xtpg_hg scalar D
    real matrix R, X, C, Lis, W, B, Hb, Lm, Pm, V, G, Zs
    real colvector f, q
    real rowvector th0, th, c0, c, tau2, dd
    real scalar N, T, p, i, k, nc, o, j
    transmorphic Sopt
    R = st_matrix(Rname)
    X = st_matrix(Xname)
    T = rows(R)
    N = cols(R)
    p = cols(X)
    D.N = N
    D.T = T
    D.p = p
    D.S = S
    D.R = R
    D.X = X
    D.hasf = (Fname != "")
    D.F = J(T, 1, 0)
    if (D.hasf) D.F = st_matrix(Fname)
    D.fixpi = fixpi
    D.pifix = pifix
    rseed(seed)
    D.Z = rnormal(S, 4, 0, 1)
    // ---- naive estimator: series-by-series ML, then OLS of level II (paper sec. 3)
    nc = D.hasf + 2 + (!fixpi)
    C = J(N, nc, .)
    for (i = 1; i <= N; i = i + 1) {
        c0 = J(1, 0, .)
        if (D.hasf) c0 = c0, cross(D.F, R[., i]) / cross(D.F, D.F)
        c0 = c0, ln(variance(R[., i] - D.hasf * D.F * cross(D.F, R[., i]) / max((cross(D.F, D.F), 1e-12)))), invnormal(0.1)
        if (!fixpi) c0 = c0, invnormal(0.95)
        Sopt = optimize_init()
        optimize_init_evaluator(Sopt, &_xtpg_hg_unit_eval())
        optimize_init_evaluatortype(Sopt, "d0")
        optimize_init_argument(Sopt, 1, R[., i])
        optimize_init_argument(Sopt, 2, D.F)
        optimize_init_argument(Sopt, 3, D.hasf)
        optimize_init_argument(Sopt, 4, fixpi)
        optimize_init_argument(Sopt, 5, pifix)
        optimize_init_params(Sopt, c0)
        optimize_init_technique(Sopt, "nr")
        optimize_init_tracelevel(Sopt, "none")
        optimize_init_conv_warning(Sopt, "off")
        optimize_init_singularHmethod(Sopt, "hybrid")
        if (_optimize(Sopt) == 0) C[i, .] = optimize_result_params(Sopt)
        else C[i, .] = c0
    }
    th0 = J(1, 0, .)
    tau2 = J(1, nc, .)
    for (k = 1; k <= nc; k = k + 1) {
        dd = (invsym(cross(X, X)) * cross(X, C[., k]))'
        th0 = th0, dd
        tau2[k] = max((variance(C[., k] - X * dd'), 1e-4))
    }
    th0 = th0, 0.5 * ln(tau2)
    st_matrix("__xtpg_naive", C)
    st_matrix("__xtpg_th0", th0)
    // ---- simulated ML (7)-(9)
    Sopt = optimize_init()
    optimize_init_evaluator(Sopt, &_xtpg_hg_eval())
    optimize_init_evaluatortype(Sopt, "gf0")
    optimize_init_argument(Sopt, 1, D)
    optimize_init_params(Sopt, th0)
    optimize_init_technique(Sopt, "bhhh 10 bfgs")
    optimize_init_conv_maxiter(Sopt, 500)
    optimize_init_singularHmethod(Sopt, "hybrid")
    optimize_init_tracelevel(Sopt, "none")
    if (showlog) optimize_init_tracelevel(Sopt, "value")
    if (_optimize(Sopt) != 0) {
        optimize_init_params(Sopt, th0)
        optimize_init_technique(Sopt, "nr")
        if (_optimize(Sopt) != 0) {
            errprintf("simulated ML failed: %s\n", optimize_result_errortext(Sopt))
            exit(430)
        }
    }
    th = optimize_result_params(Sopt)
    if (vcetype == "robust") V = optimize_result_V_robust(Sopt)
    else if (vcetype == "opg") V = optimize_result_V_opg(Sopt)
    else V = optimize_result_V_oim(Sopt)
    // ---- shrinkage estimates of the random coefficients, eqs.(10)-(12)
    q = _xtpg_hg_q(D, th, Lis)
    W = exp(Lis :- rowmax(Lis))
    W = W :/ rowsum(W)
    _xtpg_hg_coef(D, th, B, Hb, Lm, Pm)
    G = (rowsum(W :* B), sqrt(rowsum(W :* B :^ 2) - rowsum(W :* B) :^ 2),
         rowsum(W :* Hb), sqrt(rowsum(W :* Hb :^ 2) - rowsum(W :* Hb) :^ 2),
         rowsum(W :* Lm), sqrt(rowsum(W :* Lm :^ 2) - rowsum(W :* Lm) :^ 2),
         rowsum(W :* Pm), sqrt(rowsum(W :* Pm :^ 2) - rowsum(W :* Pm) :^ 2))
    st_matrix("__xtpg_b", th)
    st_matrix("__xtpg_V", V)
    st_matrix("__xtpg_coef", G)
    st_matrix("__xtpg_ess", 1 :/ rowsum(W :^ 2))
    st_numscalar("__xtpg_ll", sum(q))
    st_numscalar("__xtpg_conv", optimize_result_converged(Sopt))
}

void _xtpg_firstT(string scalar v, string scalar touse, real scalar T, string scalar outname)
{
    real colvector f
    f = st_data(., v, touse)
    st_matrix(outname, f[1..T])
}

real scalar _xtpg_mcolmean(string scalar mname, real scalar j)
{
    real matrix M
    M = st_matrix(mname)
    return(mean(M[., j]))
}

// time-invariant characteristics: first row of each panel, plus a constant (N x (p+1))
void _xtpg_hg_xi(string scalar vars, string scalar touse, real scalar N, real scalar T, string scalar outname)
{
    real matrix Xa, X
    real scalar i
    Xa = st_data(., tokens(vars), touse)
    X = J(N, cols(Xa) + 1, 1)
    for (i = 1; i <= N; i = i + 1) X[i, 1..cols(Xa)] = Xa[(i - 1) * T + 1, .]
    st_matrix(outname, X)
}

// ------------------------------------------------------------------------
// Bauwens & Rombouts (2007): Bayesian clustering of many GARCH models
//  y_jt ~ N(0, h_jt), h_jt = (1 - a_g - b_g) w_j + a_g y2_j,t-1 + b_g h_j,t-1   (30)-(31), VT w_j
//  Gibbs: S_j (13) | eta ~ Dir(a0 + x) (14)-(15) | theta_g griddy-Gibbs (16)-(17)
//  priors: uniform on [a_lo,a_hi] x [b_lo,b_hi] truncated to a + b < 1 (sec. 5.1)
//  marginal likelihood: Chib (1995) as in eq.(28)
// ------------------------------------------------------------------------
// log-likelihoods of all series (cols of Y) for M parameter pairs: returns N x M
real matrix _xtpg_br_llm(real matrix Y2, real rowvector om, real rowvector a, real rowvector b)
{
    real scalar T, N, M, t
    real rowvector H, L, Y2p, om2, aa, bb, cc
    T = rows(Y2)
    N = cols(Y2)
    M = cols(a)
    // layout: (series j, point m) -> (m-1)N + j
    om2 = J(1, M, om)
    aa = a # J(1, N, 1)
    bb = b # J(1, N, 1)
    cc = (1 :- aa :- bb) :* om2
    H = om2
    L = J(1, N * M, 0)
    for (t = 1; t <= T; t = t + 1) {
        if (t >= 2) H = cc + aa :* J(1, M, Y2[t - 1, .]) + bb :* H
        L = L - 0.5 * (ln(2 * pi()) :+ ln(H) + J(1, M, Y2[t, .]) :/ H)
    }
    return(colshape(L, N)')
}

// draw from a density known on a grid (griddy-Gibbs, Ritter-Tanner): inverse cdf, linear interpolation
real scalar _xtpg_griddy(real colvector x, real colvector lp)
{
    real colvector p, cdf
    real scalar u, k, n
    n = rows(x)
    p = exp(lp :- max(lp))
    cdf = J(n, 1, 0)
    for (k = 2; k <= n; k = k + 1) cdf[k] = cdf[k - 1] + 0.5 * (p[k] + p[k - 1]) * (x[k] - x[k - 1])
    if (cdf[n] <= 0) return(x[1] + runiform(1, 1) * (x[n] - x[1]))
    u = runiform(1, 1) * cdf[n]
    for (k = 2; k <= n; k = k + 1) {
        if (cdf[k] >= u) {
            if (cdf[k] - cdf[k - 1] <= 0) return(x[k])
            return(x[k - 1] + (u - cdf[k - 1]) / (cdf[k] - cdf[k - 1]) * (x[k] - x[k - 1]))
        }
    }
    return(x[n])
}

// Dirichlet draw in log space: Gamma(a) = Gamma(a+1) U^(1/a), exact for any a > 0
real rowvector _xtpg_rdirichlet(real rowvector a)
{
    real rowvector lg, g
    real scalar k
    lg = J(1, cols(a), .)
    for (k = 1; k <= cols(a); k = k + 1) {
        lg[k] = ln(rgamma(1, 1, a[k] + 1, 1)) + ln(runiform(1, 1)) / a[k]
    }
    g = exp(lg :- max(lg))
    g = g / sum(g)
    g = colmax((g \ J(1, cols(g), 1e-12)))
    return(g / sum(g))
}

// safe categorical draw from (possibly unnormalised, possibly degenerate) weights
real scalar _xtpg_rcat(real colvector w)
{
    real colvector p
    real colvector c
    real scalar k
    p = editmissing(w, 0)
    p = p :* (p :> 0)
    if (sum(p) <= 0 | sum(p) >= .) p = J(rows(w), 1, 1)
    c = runningsum(p / sum(p))
    k = sum(c :< runiform(1, 1)) + 1
    if (k > rows(p)) k = rows(p)
    return(k)
}

real scalar _xtpg_ldirichlet(real rowvector x, real rowvector a)
{
    return(lngamma(sum(a)) - sum(lngamma(a)) + sum((a :- 1) :* ln(x)))
}

// area of the trapezium [alo,ahi]x[blo,bhi] cut by a + b < 1 (numerical, fine grid)
real scalar _xtpg_br_area(real scalar alo, real scalar ahi, real scalar blo, real scalar bhi)
{
    real colvector a
    real scalar A, k, n, w
    n = 2001
    a = rangen(alo, ahi, n)
    A = 0
    for (k = 1; k <= n; k = k + 1) {
        w = min((bhi, 1 - a[k])) - blo
        if (w < 0) w = 0
        if (k == 1 | k == n) A = A + 0.5 * w
        else A = A + w
    }
    return(A * (ahi - alo) / (n - 1))
}

// group log marginal likelihood m(y_g) by 2-D trapezoid quadrature over the trapezium, eq.(25)
real scalar _xtpg_br_lnm(real matrix Y2, real rowvector om, real scalar alo, real scalar ahi,
    real scalar blo, real scalar bhi, real scalar M)
{
    real colvector ag, bg, w
    real rowvector av, bv, ww
    real matrix L
    real colvector s
    real scalar i, j, k, da, db, mx, area
    ag = rangen(alo, ahi, M)
    bg = rangen(blo, bhi, M)
    da = (ahi - alo) / (M - 1)
    db = (bhi - blo) / (M - 1)
    av = J(1, 0, .)
    bv = J(1, 0, .)
    ww = J(1, 0, .)
    for (i = 1; i <= M; i = i + 1) {
        for (j = 1; j <= M; j = j + 1) {
            if (ag[i] + bg[j] < 1) {
                av = av, ag[i]
                bv = bv, bg[j]
                ww = ww, (1 - 0.5 * (i == 1 | i == M)) * (1 - 0.5 * (j == 1 | j == M)) * da * db
            }
        }
    }
    if (cols(av) == 0) return(.)
    area = _xtpg_br_area(alo, ahi, blo, bhi)
    L = _xtpg_br_llm(Y2, om, av, bv)
    s = colsum(L)'
    mx = max(s)
    return(mx + ln(sum(ww' :* exp(s :- mx))) - ln(area))
}

void _xtpg_br_fit(string scalar Yname, real scalar G, string scalar PRname, string scalar a0name,
    real scalar burn, real scalar draws, real scalar M, real scalar seed, real scalar doml,
    real scalar mlreps, real scalar showlog)
{
    real matrix Y, Y2, PR, Lg, ETA, TH, ALLOC, LL
    real rowvector om, a0, eta, al, be, cnt, pp, av, bv, etas, als, bes, lme, lms, lpost
    real colvector S, x, lp, idx, lv
    real scalar N, T, it, j, g, k, ng, keep, mx, lo, hi, ti, l1, l2, l3, l4, lt
    Y = st_matrix(Yname)
    T = rows(Y)
    N = cols(Y)
    Y2 = Y :* Y
    om = colsum(Y2) / T                                          // variance targeting
    PR = st_matrix(PRname)                                       // G x 4: alo ahi blo bhi
    a0 = st_matrix(a0name)
    rseed(seed)
    // initial values: centre of each prior box (feasible)
    al = J(1, G, .)
    be = J(1, G, .)
    for (g = 1; g <= G; g = g + 1) {
        al[g] = (PR[g, 1] + PR[g, 2]) / 2
        be[g] = min(((PR[g, 3] + PR[g, 4]) / 2, 0.99 - al[g]))
    }
    eta = J(1, G, 1 / G)
    S = J(N, 1, 1)
    ETA = J(draws, G, .)
    TH = J(draws, 2 * G, .)
    ALLOC = J(N, G, 0)
    LL = J(N, G, .)
    keep = 0
    for (it = 1; it <= burn + draws; it = it + 1) {
        // (13): allocations
        Lg = _xtpg_br_llm(Y2, om, al, be)
        for (j = 1; j <= N; j = j + 1) {
            lv = (Lg[j, .] + ln(eta))'
            pp = exp(lv' :- max(lv))
            pp = pp / sum(pp)
            S[j] = rdiscrete(1, 1, pp')
        }
        // (14)-(15): group probabilities
        cnt = J(1, G, 0)
        for (g = 1; g <= G; g = g + 1) cnt[g] = sum(S :== g)
        eta = _xtpg_rdirichlet(a0 + cnt)
        // (16)-(17): griddy-Gibbs on (alpha_g, beta_g)
        for (g = 1; g <= G; g = g + 1) {
            idx = selectindex(S :== g)
            // alpha | beta
            lo = PR[g, 1]
            hi = min((PR[g, 2], 1 - be[g] - 1e-6))
            if (hi <= lo) hi = lo + 1e-6
            x = rangen(lo, hi, M)
            if (rows(idx) > 0) lp = colsum(_xtpg_br_llm(Y2[., idx], om[idx'], x', J(1, M, be[g])))'
            else lp = J(M, 1, 0)
            al[g] = _xtpg_griddy(x, lp)
            // beta | alpha
            lo = PR[g, 3]
            hi = min((PR[g, 4], 1 - al[g] - 1e-6))
            if (hi <= lo) hi = lo + 1e-6
            x = rangen(lo, hi, M)
            if (rows(idx) > 0) lp = colsum(_xtpg_br_llm(Y2[., idx], om[idx'], J(1, M, al[g]), x'))'
            else lp = J(M, 1, 0)
            be[g] = _xtpg_griddy(x, lp)
        }
        if (it > burn) {
            keep = keep + 1
            ETA[keep, .] = eta
            TH[keep, .] = (al, be)
            for (j = 1; j <= N; j = j + 1) ALLOC[j, S[j]] = ALLOC[j, S[j]] + 1
        }
        if (showlog) {
            if (mod(it, 250) == 0) printf("{txt}  iteration %g of %g\n", it, burn + draws)
        }
    }
    ALLOC = ALLOC / draws
    st_matrix("__xtpg_eta", ETA)
    st_matrix("__xtpg_th", TH)
    st_matrix("__xtpg_alloc", ALLOC)
    st_matrix("__xtpg_om", om)

    // ---- Chib (1995) marginal likelihood, eq.(28)
    if (doml) {
        etas = mean(ETA)
        als = mean(TH[., 1..G])
        bes = mean(TH[., (G + 1)..(2 * G)])
        Lg = _xtpg_br_llm(Y2, om, als, bes)
        l1 = 0
        for (j = 1; j <= N; j = j + 1) {
            mx = max(Lg[j, .] + ln(etas))
            l1 = l1 + mx + ln(sum(exp(Lg[j, .] + ln(etas) :- mx)))
        }
        l2 = 0
        for (g = 1; g <= G; g = g + 1) l2 = l2 - ln(_xtpg_br_area(PR[g, 1], PR[g, 2], PR[g, 3], PR[g, 4]))
        l3 = _xtpg_ldirichlet(etas, a0)
        // (23): average Dirichlet ordinate over the main-run allocations (re-draw S at stored params)
        lme = J(1, 0, .)
        lms = J(1, 0, .)
        al = als
        be = bes
        S = J(N, 1, 1)
        for (it = 1; it <= mlreps; it = it + 1) {
            // reduced run with eta fixed at eta*: S | theta, eta*  and theta | S  (eq. 24)
            Lg = _xtpg_br_llm(Y2, om, al, be)
            for (j = 1; j <= N; j = j + 1) {
                lv = (Lg[j, .] + ln(etas))'
                pp = exp(lv' :- max(lv))
                pp = pp / sum(pp)
                S[j] = rdiscrete(1, 1, pp')
            }
            lt = 0
            for (g = 1; g <= G; g = g + 1) {
                idx = selectindex(S :== g)
                if (rows(idx) > 0) {
                    lt = lt + sum(_xtpg_br_llm(Y2[., idx], om[idx'], als[g], bes[g])) -
                        ln(_xtpg_br_area(PR[g, 1], PR[g, 2], PR[g, 3], PR[g, 4])) -
                        _xtpg_br_lnm(Y2[., idx], om[idx'], PR[g, 1], PR[g, 2], PR[g, 3], PR[g, 4], 21)
                }
                lo = PR[g, 1]
                hi = min((PR[g, 2], 1 - be[g] - 1e-6))
                if (hi <= lo) hi = lo + 1e-6
                x = rangen(lo, hi, M)
                if (rows(idx) > 0) lp = colsum(_xtpg_br_llm(Y2[., idx], om[idx'], x', J(1, M, be[g])))'
                else lp = J(M, 1, 0)
                al[g] = _xtpg_griddy(x, lp)
                lo = PR[g, 3]
                hi = min((PR[g, 4], 1 - al[g] - 1e-6))
                if (hi <= lo) hi = lo + 1e-6
                x = rangen(lo, hi, M)
                if (rows(idx) > 0) lp = colsum(_xtpg_br_llm(Y2[., idx], om[idx'], J(1, M, al[g]), x'))'
                else lp = J(M, 1, 0)
                be[g] = _xtpg_griddy(x, lp)
            }
            lms = lms, lt
        }
        // Dirichlet ordinate (23) over the stored main-run draws of the allocation counts
        // (allocations re-simulated from each stored (eta, theta) draw)
        for (it = 1; it <= rows(ETA); it = it + max((1, floor(rows(ETA) / mlreps)))) {
            Lg = _xtpg_br_llm(Y2, om, TH[it, 1..G], TH[it, (G + 1)..(2 * G)])
            cnt = J(1, G, 0)
            for (j = 1; j <= N; j = j + 1) {
                lv = (Lg[j, .] + ln(ETA[it, .]))'
                pp = exp(lv' :- max(lv))
                pp = pp / sum(pp)
                k = rdiscrete(1, 1, pp')
                cnt[k] = cnt[k] + 1
            }
            lme = lme, _xtpg_ldirichlet(etas, a0 + cnt)
        }
        mx = max(lme)
        l4 = mx + ln(mean(exp(lme :- mx)'))
        mx = max(lms)
        ti = mx + ln(mean(exp(lms :- mx)'))
        st_numscalar("__xtpg_lnml", l1 + l2 + l3 - l4 - ti)
        st_matrix("__xtpg_mlparts", (l1, l2, l3, l4, ti))
    }
}

// automatic prior supports: per-series grid estimates of (alpha, beta), alpha supports split at quantiles
void _xtpg_br_auto(string scalar Yname, real scalar G, string scalar outname)
{
    real matrix Y, Y2, L, PR
    real rowvector om, av, bv
    real colvector ah, s
    real scalar N, T, i, j, k, g, q0, q1, m
    Y = st_matrix(Yname)
    Y2 = Y :* Y
    T = rows(Y)
    N = cols(Y)
    om = colsum(Y2) / T
    av = J(1, 0, .)
    bv = J(1, 0, .)
    for (i = 1; i <= 25; i = i + 1) {
        for (j = 1; j <= 25; j = j + 1) {
            if (0.01 * i + 0.04 * j < 0.999) {
                av = av, 0.01 * i
                bv = bv, 0.04 * j
            }
        }
    }
    L = _xtpg_br_llm(Y2, om, av, bv)
    ah = J(N, 1, .)
    for (k = 1; k <= N; k = k + 1) {
        m = _xtpg_whichmax(L[k, .])
        ah[k] = av[m]
    }
    s = sort(ah, 1)
    PR = J(G, 4, .)
    for (g = 1; g <= G; g = g + 1) {
        q0 = 0.001
        if (g > 1) q0 = (s[max((1, floor((g - 1) * N / G)))] + s[min((N, floor((g - 1) * N / G) + 1))]) / 2
        q1 = 0.30
        if (g < G) q1 = (s[max((1, floor(g * N / G)))] + s[min((N, floor(g * N / G) + 1))]) / 2
        if (q1 <= q0) q1 = q0 + 0.01
        PR[g, .] = (q0, q1, 0.05, 0.995)
    }
    st_matrix(outname, PR)
}

real scalar _xtpg_whichmax(real rowvector x)
{
    real scalar k, m
    m = 1
    for (k = 2; k <= cols(x); k = k + 1) {
        if (x[k] > x[m]) m = k
    }
    return(m)
}

void _xtpg_br_post(string scalar Ename, string scalar THname, string scalar bname, string scalar Vname)
{
    real matrix D
    D = (st_matrix(Ename), st_matrix(THname))
    st_matrix(bname, mean(D))
    st_matrix(Vname, variance(D))
}

void _xtpg_br_summ(string scalar mname, real scalar j, real scalar lo, real scalar hi)
{
    real matrix M
    real colvector x
    M = st_matrix(mname)
    x = M[., j]
    st_numscalar("r(m)", mean(x))
    st_numscalar("r(s)", sqrt(variance(x)))
    st_numscalar("r(l)", _xtpg_q7(x, lo))
    st_numscalar("r(u)", _xtpg_q7(x, hi))
}

void _xtpg_br_nmap(string scalar mname, real scalar g)
{
    real matrix A
    real scalar i, n
    A = st_matrix(mname)
    n = 0
    for (i = 1; i <= rows(A); i = i + 1) {
        if (_xtpg_whichmax(A[i, .]) == g) n = n + 1
    }
    st_numscalar("r(n)", n)
}

// ------------------------------------------------------------------------
// Casarin, Costantini & Osuntuyi (2024): Bayesian nonparametric panel MS-GARCH
//  y_it = mu_i(s_it) + sigma_it e_it,  sigma2_it = g_i(s) + a_i(s) u2_i,t-1 + b_i(s) sigma2_i,t-1   (1)-(2)
//  s_it K-state Markov chain, rows of P_i ~ Dir(phi r_k), r_k ~ Dir(d)                           (3),(6)-(7)
//  first stage: mu ~ N(mu*, s), g/c ~ Be(r g*/c, r(1-g*/c)), a ~ Be(r a*, .), b ~ Be(r b*, .)    (8)-(9)
//  second stage: theta*_ik ~ G_k, G_k ~ PY(nu, psi, H0), slice sampler                            (10)-(16), (24)-(25)
//  Gibbs steps 1-6 of sec. 3 with Appendix A full conditionals; paths by MH with a
//  Klaassen-collapsed FFBS proposal (Billio, Casarin and Osuntuyi 2016, sec. 3.2.5)
// ------------------------------------------------------------------------
// exact path-dependent log likelihood of unit i given a state path s (T x 1)
real scalar _xtpg_ms_ll(real colvector y, real colvector s, real rowvector mu, real rowvector g,
    real rowvector a, real rowvector b, real scalar v0)
{
    real scalar T, t, h, u2, ll, k
    T = rows(y)
    u2 = v0
    h = v0
    ll = 0
    for (t = 1; t <= T; t = t + 1) {
        k = s[t]
        h = g[k] + a[k] * u2 + b[k] * h
        if (h <= 0) return(-1e300)
        u2 = (y[t] - mu[k])^2
        ll = ll - 0.5 * (ln(2 * pi()) + ln(h) + u2 / h)
    }
    return(ll)
}

real colvector _xtpg_ms_hpath(real colvector y, real colvector s, real rowvector mu, real rowvector g,
    real rowvector a, real rowvector b, real scalar v0)
{
    real scalar T, t, h, u2, k
    real colvector H
    T = rows(y)
    H = J(T, 1, .)
    u2 = v0
    h = v0
    for (t = 1; t <= T; t = t + 1) {
        k = s[t]
        h = g[k] + a[k] * u2 + b[k] * h
        if (h <= 1e-10) h = 1e-10
        H[t] = h
        u2 = (y[t] - mu[k])^2
    }
    return(H)
}

// Klaassen (2002) collapsed forward filter: returns T x K filtered probabilities
real matrix _xtpg_ms_filter(real colvector y, real rowvector mu, real rowvector g, real rowvector a,
    real rowvector b, real matrix P, real scalar v0)
{
    real scalar T, K, t, i, m, den, mb, sb
    real matrix F
    real rowvector pred, sg, sgn, f, w, lik
    T = rows(y)
    K = cols(mu)
    F = J(T, K, .)
    f = J(1, K, 1 / K)
    sg = J(1, K, v0)
    lik = J(1, K, .)
    sgn = J(1, K, .)
    for (t = 1; t <= T; t = t + 1) {
        pred = f * P
        for (i = 1; i <= K; i = i + 1) {
            if (t == 1) {
                sgn[i] = g[i] + (a[i] + b[i]) * v0
            }
            else {
                w = f :* P[., i]'
                den = sum(w)
                if (den <= 0) w = J(1, K, 1 / K)
                else w = w / den
                mb = sum(mu :* w)
                sb = sum((mu :^ 2 + sg) :* w) - mb^2
                sgn[i] = g[i] + a[i] * (y[t - 1] - mb)^2 + b[i] * sb
            }
            if (sgn[i] <= 0) sgn[i] = 1e-8
            lik[i] = normalden(y[t], mu[i], sqrt(sgn[i]))
        }
        f = lik :* pred
        den = sum(f)
        if (den <= 0 | den >= .) f = pred
        else f = f / den
        F[t, .] = f
        sg = sgn
    }
    return(F)
}

// backward sampling from the filter; also log q of the sampled path
real colvector _xtpg_ms_bs(real matrix F, real matrix P, real scalar lq)
{
    real scalar T, K, t
    real colvector s
    real rowvector pr
    T = rows(F)
    K = cols(F)
    s = J(T, 1, .)
    pr = F[T, .]
    s[T] = _xtpg_rcat(pr')
    lq = ln(max((pr[s[T]] / sum(pr), 1e-300)))
    for (t = T - 1; t >= 1; t = t - 1) {
        pr = F[t, .] :* P[., s[t + 1]]'
        if (sum(pr) <= 0 | hasmissing(pr)) pr = J(1, K, 1)
        pr = pr / sum(pr)
        s[t] = _xtpg_rcat(pr')
        lq = lq + ln(max((pr[s[t]], 1e-300)))
    }
    return(s)
}

real scalar _xtpg_ms_lq(real matrix F, real matrix P, real colvector s)
{
    real scalar T, t, lq
    real rowvector pr
    T = rows(F)
    lq = ln(F[T, s[T]])
    for (t = T - 1; t >= 1; t = t - 1) {
        pr = F[t, .] :* P[., s[t + 1]]'
        lq = lq + ln(pr[s[t]] / sum(pr))
    }
    return(lq)
}

real scalar _xtpg_ms_lpath(real colvector s, real matrix P)
{
    real scalar t, v
    v = 0
    for (t = 2; t <= rows(s); t = t + 1) v = v + ln(P[s[t - 1], s[t]])
    return(v)
}

real scalar _xtpg_lbeta(real scalar x, real scalar p, real scalar q)
{
    if (x <= 0 | x >= 1 | p <= 0 | q <= 0) return(-1e300)
    return(lngamma(p + q) - lngamma(p) - lngamma(q) + (p - 1) * ln(x) + (q - 1) * ln(1 - x))
}

// first-stage log prior of unit-regime parameters given its atom (eqs. 8-9)
real scalar _xtpg_ms_lp1(real scalar mu, real scalar g, real scalar a, real scalar b,
    real rowvector at, real scalar s, real scalar r, real scalar c)
{
    return(ln(normalden(mu, at[1], s)) + _xtpg_lbeta(g / c, r * at[2] / c, r * (1 - at[2] / c)) - ln(c) +
        _xtpg_lbeta(a, r * at[3], r * (1 - at[3])) + _xtpg_lbeta(b, r * at[4], r * (1 - at[4])))
}

// Nakatsuma (1998) / Ardia (2008) linearised proposal for (g_1..g_K, a_1..a_K, b_1..b_K), eqs.(41)-(50)
void _xtpg_ms_naka(real colvector y, real colvector s, real rowvector mu, real rowvector th,
    real scalar K, real scalar v0, real colvector m, real matrix S)
{
    real scalar T, t, k, w, wl, e2, e2l, h
    real rowvector gr, grl
    real matrix A
    real colvector bvec, rr
    T = rows(y)
    A = J(3 * K, 3 * K, 0)
    bvec = J(3 * K, 1, 0)
    wl = 0
    e2l = v0
    h = v0
    grl = J(1, 3 * K, 0)
    for (t = 1; t <= T; t = t + 1) {
        k = s[t]
        e2 = (y[t] - mu[k])^2
        w = e2 - th[k] - th[K + k] * e2l - th[2 * K + k] * (e2l - wl)          // (44)
        gr = th[2 * K + k] * grl                                                // (47)
        gr[k] = gr[k] - 1
        gr[K + k] = gr[K + k] - e2l
        gr[2 * K + k] = gr[2 * K + k] - (e2l - wl)
        h = th[k] + th[K + k] * e2l + th[2 * K + k] * h                         // sigma**2
        if (h <= 1e-10) h = 1e-10
        rr = w - gr * th'
        A = A + gr' * gr / (2 * h * h)                                           // (48)
        bvec = bvec + gr' * rr / (2 * h * h)
        wl = w
        e2l = e2
        grl = gr
    }
    S = invsym(A)                                                               // (50)
    m = -S * bvec
}

real scalar _xtpg_ldmvn(real colvector x, real colvector m, real matrix S)
{
    real matrix C
    real colvector z
    C = cholesky(S)
    if (hasmissing(C)) return(-1e300)
    z = solvelower(C, x - m)
    return(-0.5 * (rows(x) * ln(2 * pi()) + 2 * sum(ln(diagonal(C))) + cross(z, z)))
}

real colvector _xtpg_rmvn(real colvector m, real matrix S)
{
    real matrix C
    C = cholesky(S)
    if (hasmissing(C)) C = diag(sqrt(abs(diagonal(S))))
    return(m + C * rnormal(rows(m), 1, 0, 1))
}

// log of the 0.05 N(m(x0),S) + 0.95 N(x0,S) mixture proposal density at x
real scalar _xtpg_ms_lmix(real colvector x, real colvector x0, real colvector m, real matrix S)
{
    real scalar l1, l2, mx
    l1 = ln(0.05) + _xtpg_ldmvn(x, m, S)
    l2 = ln(0.95) + _xtpg_ldmvn(x, x0, S)
    mx = max((l1, l2))
    return(mx + ln(exp(l1 - mx) + exp(l2 - mx)))
}

// griddy draw of an atom component with exact beta full conditional (Appendix A.3, eqs. 36-37)
real scalar _xtpg_ms_atom_beta(real colvector x, real scalar r, real scalar c)
{
    real colvector gr, lp
    real scalar k, j
    gr = rangen(0.002, 0.998, 200) * c
    lp = J(rows(gr), 1, 0)
    for (k = 1; k <= rows(gr); k = k + 1) {
        for (j = 1; j <= rows(x); j = j + 1) lp[k] = lp[k] + _xtpg_lbeta(x[j] / c, r * gr[k] / c, r * (1 - gr[k] / c))
    }
    return(_xtpg_griddy(gr, lp))
}

void _xtpg_ms_fit(string scalar Yname, real scalar K, real scalar burn, real scalar draws,
    real scalar thin, real scalar seed, real scalar nu, real scalar psi, real scalar phi,
    real scalar s1, real scalar r1, real scalar showlog)
{
    real matrix Y, Sst, MU, GA, AL, BE, PR, F, TH1, Spr, Dk, ATM, RK, PM, SM, CO, NCL, Smat
    real colvector y, s, snew, mprop, mrev, xold, xnew, Wv, U, idx, lp, pr, hst, csc, accw
    real rowvector v0, mu, g, a, b, th, thn, mun, rk, cnt, ap, atom, ar, Vk, Wk
    real scalar N, T, i, k, it, t, keep, lq1, lq0, lt1, lt0, lnacc, c, ms, ss, h, Dst, Nst, Umin
    real scalar acc_s, acc_m, acc_v, j, l, nn, cK, kk, dd, nc, sumw, m1, okc
    real matrix Ssig, Snew, Smu, P
    pointer(real matrix) rowvector Pm
    pointer(real matrix) rowvector ATOMS, VV
    Y = st_matrix(Yname)
    T = rows(Y)
    N = cols(Y)
    rseed(seed)
    v0 = colsum((Y :- mean(Y)) :^ 2) / T
    c = 2 * max(v0)                                              // support of g: (0, c)
    ms = mean(vec(Y))
    ss = 2 * sqrt(variance(vec(Y)))
    dd = 1 / K
    // ---- initial values
    MU = J(N, K, .)
    GA = J(N, K, .)
    AL = J(N, K, 0.05)
    BE = J(N, K, 0.85)
    for (i = 1; i <= N; i = i + 1) {
        for (k = 1; k <= K; k = k + 1) {
            MU[i, k] = mean(Y[., i]) + (K + 1 - 2 * k) / max((K - 1, 1)) * 0.5 * sqrt(v0[i])
            GA[i, k] = 0.10 * v0[i]
        }
    }
    Pm = J(1, N, NULL)
    for (i = 1; i <= N; i = i + 1) Pm[i] = &(0.95 * I(K) + 0.05 / max((K - 1, 1)) * (J(K, K, 1) - I(K)))
    if (K == 1) {
        for (i = 1; i <= N; i = i + 1) Pm[i] = &(J(1, 1, 1))
    }
    RK = J(K, K, 1 / K)
    Sst = J(T, N, 1)
    for (i = 1; i <= N; i = i + 1) {
        F = _xtpg_ms_filter(Y[., i], MU[i, .], GA[i, .], AL[i, .], BE[i, .], *Pm[i], v0[i])
        Sst[., i] = _xtpg_ms_bs(F, *Pm[i], lq1)
    }
    // atoms: one cluster per regime to start; atom rows (mu*, g*, a*, b*)
    ATOMS = J(1, K, NULL)
    VV = J(1, K, NULL)
    Dk = J(N, K, 1)
    for (k = 1; k <= K; k = k + 1) {
        ATOMS[k] = &((mean(MU[., k]), mean(GA[., k]), mean(AL[., k]), mean(BE[., k])))
        VV[k] = &(J(1, 1, 0.5))
    }
    // storage
    PM = J(N, 4 * K, 0)
    SM = J(T, N * K, 0)
    NCL = J(draws, K, .)
    CO = J(N * K, N, 0)
    TH1 = J(draws, 4 * K, .)
    keep = 0
    acc_s = 0
    acc_m = 0
    acc_v = 0
    csc = J(N, 1, 1)
    accw = J(N, 1, 0)
    for (it = 1; it <= burn + draws * thin; it = it + 1) {
        for (k = 1; k <= K; k = k + 1) {
            // ---- step 1: stick-breaking V and slice U (A.1)
            Dst = max(Dk[., k])
            Vk = J(1, Dst, .)
            for (l = 1; l <= Dst; l = l + 1) {
                nn = sum(Dk[., k] :== l)
                Vk[l] = rbeta(1, 1, 1 - nu + nn, psi + nu * l + sum(Dk[., k] :> l))
            }
            Wk = _xtpg_sticks(Vk)
            U = J(N, 1, .)
            for (i = 1; i <= N; i = i + 1) U[i] = runiform(1, 1) * Wk[Dk[i, k]]
            Umin = min(U)
            while (sum(Wk) <= 1 - Umin) {
                Vk = Vk, rbeta(1, 1, 1 - nu, psi + nu * (cols(Vk) + 1))
                Wk = _xtpg_sticks(Vk)
            }
            Nst = cols(Wk)
            // ---- step 3: atoms (A.3): occupied ones from full conditionals, others from H0
            ATM = J(Nst, 4, .)
            for (h = 1; h <= Nst; h = h + 1) {
                idx = selectindex(Dk[., k] :== h)
                if (rows(idx) == 0) {
                    ATM[h, .] = (ms + ss * rnormal(1, 1, 0, 1), c * runiform(1, 1), runiform(1, 1), runiform(1, 1))
                }
                else {
                    sumw = 1 / (1 / ss^2 + rows(idx) / s1^2)
                    m1 = sumw * (ms / ss^2 + sum(MU[idx, k]) / s1^2)
                    ATM[h, 1] = m1 + sqrt(sumw) * rnormal(1, 1, 0, 1)                    // (35)
                    ATM[h, 2] = _xtpg_ms_atom_beta(GA[idx, k], r1, c)                     // (36)
                    ATM[h, 3] = _xtpg_ms_atom_beta(AL[idx, k], r1, 1)                     // (37)
                    ATM[h, 4] = _xtpg_ms_atom_beta(BE[idx, k], r1, 1)
                }
            }
            // ---- step 6: allocations D (A.6)
            for (i = 1; i <= N; i = i + 1) {
                ap = J(1, Nst, -1e300)
                for (h = 1; h <= Nst; h = h + 1) {
                    if (U[i] < Wk[h]) ap[h] = _xtpg_ms_lp1(MU[i, k], GA[i, k], AL[i, k], BE[i, k], ATM[h, .], s1, r1, c)
                }
                pr = (exp(ap :- max(ap)) :* (Wk :> U[i]))'
                Dk[i, k] = _xtpg_rcat(pr)
            }
            // relabel occupied clusters 1..M
            Smat = uniqrows(Dk[., k])
            for (h = 1; h <= rows(Smat); h = h + 1) {
                idx = selectindex(Dk[., k] :== Smat[h])
                Dk[idx, k] = J(rows(idx), 1, h)
            }
            ATM = ATM[Smat, .]
            ATOMS[k] = &(ATM[., .])
        }
        for (i = 1; i <= N; i = i + 1) {
            y = Y[., i]
            P = *Pm[i]
            s = Sst[., i]
            // ---- step 5: state path, MH with Klaassen FFBS proposal (A.5)
            F = _xtpg_ms_filter(y, MU[i, .], GA[i, .], AL[i, .], BE[i, .], P, v0[i])
            snew = _xtpg_ms_bs(F, P, lq1)
            lq0 = _xtpg_ms_lq(F, P, s)
            lt1 = _xtpg_ms_ll(y, snew, MU[i, .], GA[i, .], AL[i, .], BE[i, .], v0[i]) + _xtpg_ms_lpath(snew, P)
            lt0 = _xtpg_ms_ll(y, s, MU[i, .], GA[i, .], AL[i, .], BE[i, .], v0[i]) + _xtpg_ms_lpath(s, P)
            lnacc = lt1 - lt0 + lq0 - lq1
            if (ln(runiform(1, 1)) < lnacc) {
                s = snew
                acc_s = acc_s + 1
            }
            Sst[., i] = s
            // ---- step 2: transition probabilities (A.2), eq.(31)
            if (K > 1) {
                for (k = 1; k <= K; k = k + 1) {
                    cnt = J(1, K, 0)
                    for (t = 2; t <= T; t = t + 1) {
                        if (s[t - 1] == k) cnt[s[t]] = cnt[s[t]] + 1
                    }
                    P[k, .] = _xtpg_rdirichlet(phi * RK[k, .] + cnt)
                }
                Pm[i] = &(P[., .])
            }
            // ---- step 4a: regime means, MH with normal mixture proposal (39)
            mu = MU[i, .]
            Smu = J(K, K, 0)
            mprop = J(K, 1, 0)
            hst = _xtpg_ms_hpath(y, s, mu, GA[i, .], AL[i, .], BE[i, .], v0[i])   // sigma*2 of (39)
            for (k = 1; k <= K; k = k + 1) {
                ATM = *ATOMS[k]
                idx = selectindex(s :== k)
                sumw = 1 / s1^2
                m1 = ATM[Dk[i, k], 1] / s1^2
                if (rows(idx) > 0) {
                    sumw = sumw + sum(1 :/ hst[idx])
                    m1 = m1 + sum(y[idx] :/ hst[idx])
                }
                Smu[k, k] = 1 / sumw
                mprop[k] = m1 / sumw
            }
            xold = mu'
            if (runiform(1, 1) < 0.05) xnew = _xtpg_rmvn(mprop, Smu)
            else xnew = _xtpg_rmvn(xold, Smu)
            okc = 1
            for (k = 2; k <= K; k = k + 1) {
                if (xnew[k - 1] <= xnew[k]) okc = 0                     // identification mu_i1 > mu_i2 > ...
            }
            if (okc) {
                mun = xnew'
                lt1 = _xtpg_ms_ll(y, s, mun, GA[i, .], AL[i, .], BE[i, .], v0[i])
                lt0 = _xtpg_ms_ll(y, s, mu, GA[i, .], AL[i, .], BE[i, .], v0[i])
                for (k = 1; k <= K; k = k + 1) {
                    ATM = *ATOMS[k]
                    lt1 = lt1 + ln(normalden(mun[k], ATM[Dk[i, k], 1], s1))
                    lt0 = lt0 + ln(normalden(mu[k], ATM[Dk[i, k], 1], s1))
                }
                lnacc = lt1 - lt0 + _xtpg_ms_lmix(xold, xnew, mprop, Smu) - _xtpg_ms_lmix(xnew, xold, mprop, Smu)
                if (ln(runiform(1, 1)) < lnacc) {
                    MU[i, .] = mun
                    acc_m = acc_m + 1
                }
            }
            // ---- step 4b: volatility parameters, Nakatsuma-Ardia proposal (40)-(50)
            th = (GA[i, .], AL[i, .], BE[i, .])
            _xtpg_ms_naka(y, s, MU[i, .], th, K, v0[i], mprop, Ssig)
            if (!hasmissing(Ssig) & !hasmissing(mprop)) {
                xold = th'
                Ssig = csc[i] * Ssig
                if (runiform(1, 1) < 0.05) xnew = _xtpg_rmvn(mprop, Ssig)
                else xnew = _xtpg_rmvn(xold, Ssig)
                thn = xnew'
                okc = (min(thn) > 0 & max(thn[(K + 1)..(3 * K)]) < 1 & max(thn[1..K]) < c)
                if (okc) {
                    _xtpg_ms_naka(y, s, MU[i, .], thn, K, v0[i], mrev, Snew)
                    Snew = csc[i] * Snew
                    if (!hasmissing(Snew) & !hasmissing(mrev)) {
                        lt1 = _xtpg_ms_ll(y, s, MU[i, .], thn[1..K], thn[(K + 1)..(2 * K)], thn[(2 * K + 1)..(3 * K)], v0[i])
                        lt0 = _xtpg_ms_ll(y, s, MU[i, .], th[1..K], th[(K + 1)..(2 * K)], th[(2 * K + 1)..(3 * K)], v0[i])
                        for (k = 1; k <= K; k = k + 1) {
                            ATM = *ATOMS[k]
                            atom = ATM[Dk[i, k], .]
                            lt1 = lt1 + _xtpg_ms_lp1(MU[i, k], thn[k], thn[K + k], thn[2 * K + k], atom, s1, r1, c) - ln(normalden(MU[i, k], atom[1], s1))
                            lt0 = lt0 + _xtpg_ms_lp1(MU[i, k], th[k], th[K + k], th[2 * K + k], atom, s1, r1, c) - ln(normalden(MU[i, k], atom[1], s1))
                        }
                        lnacc = lt1 - lt0 + _xtpg_ms_lmix(xold, xnew, mrev, Snew) - _xtpg_ms_lmix(xnew, xold, mprop, Ssig)
                        if (ln(runiform(1, 1)) < lnacc) {
                            GA[i, .] = thn[1..K]
                            AL[i, .] = thn[(K + 1)..(2 * K)]
                            BE[i, .] = thn[(2 * K + 1)..(3 * K)]
                            acc_v = acc_v + 1
                            accw[i] = accw[i] + 1
                        }
                    }
                }
            }
        }
        // adaptive scaling of the GARCH-block proposal during burn-in only (target acceptance 0.25)
        if (it <= burn) {
            if (mod(it, 50) == 0) {
                csc = csc :* exp(accw / 50 :- 0.25)
                csc = rowmin((rowmax((csc, J(N, 1, 1e-4))), J(N, 1, 10)))
                accw = J(N, 1, 0)
            }
        }
        // ---- step 2b: r_k by MH with independent Dir(d + m_k) proposal, eq.(34)
        if (K > 1) {
            for (k = 1; k <= K; k = k + 1) {
                // m_kh = #units with at least one k -> h transition
                cnt = J(1, K, 0)
                for (i = 1; i <= N; i = i + 1) {
                    for (kk = 1; kk <= K; kk = kk + 1) {
                        nn = 0
                        for (t = 2; t <= T; t = t + 1) {
                            if (Sst[t - 1, i] == k) {
                                if (Sst[t, i] == kk) nn = 1
                            }
                        }
                        cnt[kk] = cnt[kk] + nn
                    }
                }
                rk = _xtpg_rdirichlet(dd :+ cnt)
                lt1 = 0
                lt0 = 0
                for (i = 1; i <= N; i = i + 1) {
                    P = *Pm[i]
                    lt1 = lt1 + lngamma(phi) - sum(lngamma(phi * rk)) + sum((phi * rk :- 1) :* ln(P[k, .]))
                    lt0 = lt0 + lngamma(phi) - sum(lngamma(phi * RK[k, .])) + sum((phi * RK[k, .] :- 1) :* ln(P[k, .]))
                }
                lt1 = lt1 + _xtpg_ldirichlet(rk, J(1, K, dd)) - _xtpg_ldirichlet(rk, dd :+ cnt)
                lt0 = lt0 + _xtpg_ldirichlet(RK[k, .], J(1, K, dd)) - _xtpg_ldirichlet(RK[k, .], dd :+ cnt)
                if (ln(runiform(1, 1)) < lt1 - lt0) RK[k, .] = rk
            }
        }
        if (it == burn) {
            acc_s = 0
            acc_m = 0
            acc_v = 0
        }
        // ---- storage
        if (it > burn) {
            if (mod(it - burn, thin) == 0) {
                keep = keep + 1
                PM = PM + (MU, GA, AL, BE)
                for (k = 1; k <= K; k = k + 1) {
                    SM[., ((k - 1) * N + 1)..(k * N)] = SM[., ((k - 1) * N + 1)..(k * N)] + (Sst :== k)
                    NCL[keep, k] = rows(uniqrows(Dk[., k]))
                    for (i = 1; i <= N; i = i + 1) {
                        CO[(k - 1) * N + i, .] = CO[(k - 1) * N + i, .] + (Dk[., k]' :== Dk[i, k])
                    }
                }
                TH1[keep, .] = (mean(MU), mean(GA), mean(AL), mean(BE))
            }
        }
        if (showlog) {
            if (mod(it, 100) == 0) printf("{txt}  iteration %g of %g\n", it, burn + draws * thin)
        }
    }
    PM = PM / keep
    SM = SM / keep
    CO = CO / keep
    PR = J(N, K * K, .)
    for (i = 1; i <= N; i = i + 1) PR[i, .] = vec((*Pm[i])')'
    st_matrix("__xtpg_post", PM)
    st_matrix("__xtpg_sprob", SM)
    st_matrix("__xtpg_ncl", NCL)
    st_matrix("__xtpg_cocl", CO)
    st_matrix("__xtpg_avg", TH1)
    st_matrix("__xtpg_P", PR)
    st_matrix("__xtpg_acc", (acc_s, acc_m, acc_v) / (N * draws * thin))
}

real rowvector _xtpg_sticks(real rowvector V)
{
    real rowvector W
    real scalar l, rem
    W = J(1, cols(V), .)
    rem = 1
    for (l = 1; l <= cols(V); l = l + 1) {
        W[l] = V[l] * rem
        rem = rem * (1 - V[l])
    }
    return(W)
}

void _xtpg_ms_ncl(string scalar mname, real scalar k)
{
    real matrix M
    real colvector x, u
    real scalar j, best, bc, c
    M = st_matrix(mname)
    x = M[., k]
    u = uniqrows(x)
    best = u[1]
    bc = 0
    for (j = 1; j <= rows(u); j = j + 1) {
        c = sum(x :== u[j])
        if (c > bc) {
            bc = c
            best = u[j]
        }
    }
    st_numscalar("r(map)", best)
    st_numscalar("r(mean)", mean(x))
    st_numscalar("r(pmap)", bc / rows(x))
}

void _xtpg_subvec(string scalar bname, real scalar n)
{
    real matrix b
    b = st_matrix(bname)
    st_matrix(bname, b[1, 1..n])
}

void _xtpg_submat(string scalar vname, real scalar n)
{
    real matrix V
    V = st_matrix(vname)
    st_matrix(vname, V[1..n, 1..n])
}

mata mlib create lxtpanelgarch, dir(".") replace
mata mlib add lxtpanelgarch _xtpg_*() xtpg_cg() xtpg_ag() xtpg_hg() xtpg_vq()
mata mlib index
end
