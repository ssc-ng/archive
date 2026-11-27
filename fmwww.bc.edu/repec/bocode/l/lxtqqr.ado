*! lxtqqr 1.0.0  25nov2026
*! Mata helpers for the xtqqr package (panel quantile-on-quantile family)
*! Author: Dr Merwan Roudane  <merwanroudane920@gmail.com>
*! https://github.com/merwanroudane
*
* This file holds NO Stata program.  Mata functions compiled inside an
* autoloaded ado-file are private to that file, so the user commands of
* the package (xtqqr, xtqqkrls, xtqqplot) load these helpers once per
* session through _xtqqr_load (findfile lxtqqr.ado + quietly do).
*
* The quantile regressions themselves are solved by Stata's -qreg-, and
* the kernel regularized least squares fits by -krls- (Hainmueller &
* Hazlett 2014, SSC).  Mata here only does the bookkeeping:
*   xqq_ecdf()      empirical distribution F_n(x)   (Sim & Zhou 2015, eq. 7)
*   xqq_quant()     empirical quantile (linear interpolation, type 7)
*   xqq_kw()        kernel weights K((F_n(x)-theta)/h)/h
*   xqq_sandwich()  Powell kernel sandwich: iid / robust / clustered
*                   (Powell 1991; Parente & Santos Silva 2016)
*   xqq_wquant()    weighted quantile (for the weighted pseudo-R2)
*   xqq_bootq()     unit-block bootstrap of a quantile of derivatives
*   xqq_parula()    MATLAB R2014b Parula colour map

version 14.0
mata:

real scalar xqq_loaded()
{
    return(1)
}

// check function rho_tau(u)
real colvector xqq_rho(real colvector u, real scalar tau)
{
    return(u :* (tau :- (u :< 0)))
}

// ---------------------------------------------------------------------
// Empirical CDF  F_n(x_i) = (1/n) sum_k 1(x_k < x_i)   (Sim-Zhou eq. 7)
// ties share a value
// ---------------------------------------------------------------------
real colvector xqq_ecdf(real colvector x)
{
    real colvector o, xs, F, Fs
    real scalar n, i, cnt
    n = rows(x)
    o = order(x, 1)
    xs = x[o]
    Fs = J(n, 1, 0)
    cnt = 0
    for (i = 2; i <= n; i++) {
        if (xs[i] > xs[i-1]) {
            cnt = i - 1
        }
        Fs[i] = cnt
    }
    F = J(n, 1, .)
    F[o] = Fs :/ n
    return(F)
}

// unit-specific ECDF (option xref(unit))
real colvector xqq_ecdf_by(real colvector x, real colvector id)
{
    real colvector F, ids, sel
    real scalar g
    F = J(rows(x), 1, .)
    ids = uniqrows(id)
    for (g = 1; g <= rows(ids); g++) {
        sel = selectindex(id :== ids[g])
        F[sel] = xqq_ecdf(x[sel])
    }
    return(F)
}

// empirical quantile, linear interpolation (type 7 = R default)
real scalar xqq_quant(real colvector x0, real scalar p)
{
    real colvector s
    real scalar n, h, lo
    s = sort(select(x0, x0 :< .), 1)
    n = rows(s)
    if (n == 0) return(.)
    if (n == 1) return(s[1])
    h = (n - 1) * p + 1
    lo = floor(h)
    if (lo < 1) return(s[1])
    if (lo >= n) return(s[n])
    return(s[lo] + (h - lo) * (s[lo+1] - s[lo]))
}

// unit-specific quantile, returned at observation level
real colvector xqq_quant_by(real colvector x, real colvector id, real scalar p)
{
    real colvector q, ids, sel
    real scalar g
    q = J(rows(x), 1, .)
    ids = uniqrows(id)
    for (g = 1; g <= rows(ids); g++) {
        sel = selectindex(id :== ids[g])
        q[sel] = J(rows(sel), 1, xqq_quant(x[sel], p))
    }
    return(q)
}

// Kish effective sample size of a weight vector
real scalar xqq_ess(real colvector w)
{
    real scalar s2
    s2 = quadsum(w :* w)
    if (s2 <= 0) return(0)
    return(quadsum(w)^2 / s2)
}

// weighted tau-quantile (minimiser of sum w*rho_tau(y-q))
real scalar xqq_wquant(real colvector y, real colvector w, real scalar tau)
{
    real colvector o, cw
    real scalar i, tot
    o = order(y, 1)
    cw = runningsum(w[o])
    tot = cw[rows(cw)]
    for (i = 1; i <= rows(cw); i++) {
        if (cw[i] >= tau * tot) {
            return(y[o[i]])
        }
    }
    return(y[o[rows(o)]])
}

// ---------------------------------------------------------------------
// Kernel weights of Sim & Zhou (2015):  K((F_n(x)-theta)/h) / h
//   ktype 1 = Gaussian (paper), 2 = Epanechnikov, 3 = uniform
// ---------------------------------------------------------------------
real colvector xqq_kw(real colvector F, real scalar theta, real scalar h,
                      real scalar ktype)
{
    real colvector u
    u = (F :- theta) :/ h
    if (ktype == 2) {
        return(0.75 :* (1 :- u:^2) :* (abs(u) :< 1) :/ h)
    }
    if (ktype == 3) {
        return(0.5 :* (abs(u) :<= 1) :/ h)
    }
    return(normalden(u) :/ h)
}

// Stata wrapper: create kernel-weight / centred-x variables for theta
//   F is stored in variable Fv, x in xv; xq (scalar or by-unit) in xqv
void xqq_cellvars(string scalar Fv, string scalar xv, string scalar xqv,
                  string scalar touse, real scalar theta, real scalar h,
                  real scalar ktype, string scalar wv, string scalar xcv)
{
    real colvector F, x, xq, w
    real scalar wmax
    F  = st_data(., Fv, touse)
    x  = st_data(., xv, touse)
    xq = st_data(., xqv, touse)
    w  = xqq_kw(F, theta, h, ktype)
    wmax = max(w)
    // weights below 1e-8 of the maximum are numerically zero: drop them
    w = w :* (w :>= 1e-8 * wmax)
    st_store(., wv, touse, w)
    st_store(., xcv, touse, x - xq)
}

// ---------------------------------------------------------------------
// Powell (1991) kernel sandwich for a (kernel-)weighted linear QR
//   V = H^{-1} J H^{-1}
//   H = (1/(2c)) sum w_i 1(|u_i|<=c) x_i x_i'
//   J = sum_g s_g s_g',   s_g = sum_{i in g} w_i psi_i x_i
//   psi_i = tau - 1(u_i<0)
//   vtype 1 = iid (common sparsity), 2 = robust, 3 = cluster
//   (cluster = Parente & Santos Silva 2016, J. Econometric Methods)
//   bandwidth c: Hall-Sheather rule with Koenker's scale, as in qreg
// Arguments are Stata names; X = varlist (constant appended here).
// Returns the full V in Stata matrix Vname.
// ---------------------------------------------------------------------
void xqq_sandwich(string scalar yv, string scalar xvars, string scalar bname,
                  real scalar tau, string scalar wv, real scalar vtype,
                  string scalar clv, string scalar touse, string scalar Vname)
{
    real colvector y, w, b, u, psi, k, cl, info
    real matrix X, H, Jm, S, Hi, sg, sel
    real scalar n, hn, cc, zz, sdu, iqru, fdens, alpha

    w  = st_data(., wv, touse)
    sel = selectindex(w :> 0)
    w  = w[sel]
    y  = st_data(., yv, touse)
    y  = y[sel]
    X  = st_data(., tokens(xvars), touse)
    X  = X[sel, .], J(rows(sel), 1, 1)
    b  = st_matrix(bname)'
    n  = rows(y)
    u  = y - X * b

    alpha = 0.05
    zz = invnormal(1 - alpha / 2)
    hn = n^(-1/3) * zz^(2/3) *
         ((1.5 * normalden(invnormal(tau))^2) /
          (2 * invnormal(tau)^2 + 1))^(1/3)
    if (tau + hn >= 1 | tau - hn <= 0) {
        hn = min((tau, 1 - tau)) / 2
    }
    sdu  = sqrt(variance(u, w))
    iqru = xqq_quant(u, 0.75) - xqq_quant(u, 0.25)
    cc = min((sdu, iqru / 1.34)) * (invnormal(tau + hn) - invnormal(tau - hn))
    if (cc <= 0 | cc >= .) {
        cc = sdu * 0.5
    }
    if (cc <= 0 | cc >= .) {
        cc = 1e-4
    }
    k   = (abs(u) :<= cc)
    psi = tau :- (u :< 0)

    if (vtype == 1) {
        fdens = quadsum(w :* k) / (2 * cc * quadsum(w))
        if (fdens <= 0) {
            fdens = 1e-8
        }
        H  = fdens :* quadcross(X, w, X)
        Jm = tau * (1 - tau) :* quadcross(X, w :* w, X)
    }
    else {
        H = quadcross(X, w :* k, X) :/ (2 * cc)
        if (vtype == 2) {
            Jm = quadcross(X, (w :* psi):^2, X)
        }
        else {
            cl = st_data(., clv, touse)
            cl = cl[sel]
            S = X :* (w :* psi)
            info = order(cl, 1)
            S = S[info, .]
            sg = panelsum(S, panelsetup(cl[info], 1))
            Jm = quadcross(sg, sg)
        }
    }
    Hi = invsym(H)
    st_matrix(Vname, Hi * Jm * Hi)
}

// weighted pseudo-R2  1 - sum w rho(res) / sum w rho(y - q_w)
real scalar xqq_pr2(string scalar yv, string scalar xvars, string scalar bname,
                    real scalar tau, string scalar wv, string scalar touse)
{
    real colvector y, w, b, sel
    real matrix X
    real scalar r1, r0
    w  = st_data(., wv, touse)
    sel = selectindex(w :> 0)
    w = w[sel]
    y = st_data(., yv, touse)
    y = y[sel]
    X = st_data(., tokens(xvars), touse)
    X = X[sel, .], J(rows(sel), 1, 1)
    b = st_matrix(bname)'
    r1 = quadsum(w :* xqq_rho(y - X * b, tau))
    r0 = quadsum(w :* xqq_rho(y :- xqq_wquant(y, w, tau), tau))
    if (r0 <= 0) return(.)
    return(max((0, 1 - r1 / r0)))
}

// ---------------------------------------------------------------------
// QQKRLS:  beta(tau,theta) = tau-quantile of the KRLS pointwise
// derivatives on the theta-subset; unit-block bootstrap SE ("fast")
//   dv   : variable holding the pointwise derivatives
//   idv  : panel identifier (clusters)
//   TAU  : column of tau levels
//   Output Stata matrix  [tau, beta, se, p]
// ---------------------------------------------------------------------
void xqq_bootq(string scalar dv, string scalar idv, string scalar touse,
               real colvector TAU, real scalar reps, string scalar Dname)
{
    real colvector d, id, ids, info, pick, idx, bq
    real matrix D, P, B
    real scalar M, i, r, G, g, nb, se

    d  = st_data(., dv, touse)
    id = st_data(., idv, touse)
    M  = rows(TAU)
    D  = J(M, 4, .)
    D[., 1] = TAU
    for (i = 1; i <= M; i++) {
        D[i, 2] = xqq_quant(d, TAU[i])
    }
    if (reps > 0) {
        info = order(id, 1)
        d  = d[info]
        id = id[info]
        P  = panelsetup(id, 1)
        G  = rows(P)
        B  = J(reps, M, .)
        for (r = 1; r <= reps; r++) {
            pick = ceil(runiform(G, 1) :* G)
            nb = 0
            for (g = 1; g <= G; g++) {
                nb = nb + P[pick[g], 2] - P[pick[g], 1] + 1
            }
            idx = J(nb, 1, .)
            nb = 0
            for (g = 1; g <= G; g++) {
                idx[(nb + 1)::(nb + P[pick[g], 2] - P[pick[g], 1] + 1)] =
                    (P[pick[g], 1]::P[pick[g], 2])
                nb = nb + P[pick[g], 2] - P[pick[g], 1] + 1
            }
            bq = d[idx]
            for (i = 1; i <= M; i++) {
                B[r, i] = xqq_quant(bq, TAU[i])
            }
        }
        for (i = 1; i <= M; i++) {
            se = sqrt(variance(select(B[., i], B[., i] :< .)))
            D[i, 3] = se
            if (se > 0 & se < .) {
                D[i, 4] = 2 * normal(-abs(D[i, 2] / se))
            }
        }
    }
    st_matrix(Dname, D)
}

// quantiles of a variable at TAU (used by the -refit- bootstrap)
void xqq_qvec(string scalar dv, string scalar touse, real colvector TAU,
              string scalar Qname)
{
    real colvector d, q
    real scalar i
    d = st_data(., dv, touse)
    q = J(rows(TAU), 1, .)
    for (i = 1; i <= rows(TAU); i++) {
        q[i] = xqq_quant(d, TAU[i])
    }
    st_matrix(Qname, q')
}

// ---------------------------------------------------------------------
// Results display: M x L matrix with significance stars, in blocks
// ---------------------------------------------------------------------
void xqq_print(string scalar Bn, string scalar Pn, real colvector tau,
               real colvector theta, real scalar blocksize, string scalar fmt)
{
    real matrix B, P
    real scalar M, L, j0, j1, i, j, p
    string scalar st
    B = st_matrix(Bn)
    P = st_matrix(Pn)
    M = rows(B)
    L = cols(B)
    for (j0 = 1; j0 <= L; j0 = j0 + blocksize) {
        j1 = min((j0 + blocksize - 1, L))
        printf("\n{txt}{space 2}tau \\ theta {c |}")
        for (j = j0; j <= j1; j++) {
            printf("{space 3}%6.2f ", theta[j])
        }
        printf("\n{txt}{hline 14}{c +}{hline %g}\n", 10 * (j1 - j0 + 1))
        for (i = 1; i <= M; i++) {
            printf("{txt}{space 6}%6.2f {c |}", tau[i])
            for (j = j0; j <= j1; j++) {
                p = P[i, j]
                st = "   "
                if (p < 0.10) st = "*  "
                if (p < 0.05) st = "** "
                if (p < 0.01) st = "***"
                if (B[i, j] >= .) {
                    printf("{res}%7s%3s", ".", "   ")
                }
                else {
                    printf("{res}" + fmt + "{txt}%3s", B[i, j], st)
                }
            }
            printf("\n")
        }
        printf("{txt}{hline 14}{c BT}{hline %g}\n", 10 * (j1 - j0 + 1))
    }
}

// summary statistics of a result matrix (non-missing cells)
void xqq_summary(string scalar Bn, string scalar Pn, string scalar Sname)
{
    real colvector b, p
    real matrix B, P
    real scalar nb, sdb
    B = st_matrix(Bn)
    P = st_matrix(Pn)
    b = vec(B)
    p = vec(P)
    p = select(p, b :< .)
    b = select(b, b :< .)
    nb = rows(b)
    if (nb == 0) {
        st_matrix(Sname, J(1, 9, .))
        return
    }
    sdb = 0
    if (nb > 1) {
        sdb = sqrt(variance(b))
    }
    st_matrix(Sname, (mean(b), xqq_quant(b, 0.5), min(b), max(b),
              sdb, sum(p :< 0.10),
              sum(p :< 0.05), sum(p :< 0.01), nb))
}

// ---------------------------------------------------------------------
// MATLAB Parula colour map: n colours, R2014b 64-stop table
// ---------------------------------------------------------------------
string colvector xqq_parula(real scalar n)
{
    real matrix P
    real scalar i, t, lo, fr
    real rowvector c
    string colvector out
    P = (0.2422,0.1504,0.6603 \ 0.2504,0.1650,0.7076 \ 0.2578,0.1818,0.7511 \
         0.2647,0.1978,0.7952 \ 0.2706,0.2147,0.8364 \ 0.2751,0.2342,0.8710 \
         0.2783,0.2559,0.8991 \ 0.2803,0.2782,0.9221 \ 0.2813,0.3006,0.9414 \
         0.2810,0.3228,0.9579 \ 0.2795,0.3447,0.9717 \ 0.2760,0.3667,0.9829 \
         0.2699,0.3892,0.9906 \ 0.2602,0.4123,0.9952 \ 0.2440,0.4358,0.9988 \
         0.2206,0.4603,0.9973 \ 0.1963,0.4847,0.9892 \ 0.1834,0.5074,0.9798 \
         0.1786,0.5289,0.9682 \ 0.1764,0.5499,0.9520 \ 0.1687,0.5703,0.9359 \
         0.1540,0.5902,0.9218 \ 0.1460,0.6091,0.9079 \ 0.1380,0.6276,0.8973 \
         0.1248,0.6459,0.8883 \ 0.1113,0.6635,0.8763 \ 0.0952,0.6798,0.8598 \
         0.0689,0.6948,0.8394 \ 0.0297,0.7082,0.8163 \ 0.0036,0.7203,0.7917 \
         0.0067,0.7312,0.7660 \ 0.0433,0.7411,0.7394 \ 0.0964,0.7500,0.7120 \
         0.1408,0.7584,0.6842 \ 0.1717,0.7670,0.6554 \ 0.1938,0.7758,0.6251 \
         0.2161,0.7843,0.5923 \ 0.2470,0.7918,0.5567 \ 0.2906,0.7973,0.5188 \
         0.3406,0.8008,0.4789 \ 0.3909,0.8029,0.4354 \ 0.4456,0.8024,0.3909 \
         0.5044,0.7993,0.3480 \ 0.5616,0.7942,0.3045 \ 0.6174,0.7876,0.2612 \
         0.6720,0.7793,0.2227 \ 0.7242,0.7698,0.1910 \ 0.7738,0.7598,0.1646 \
         0.8203,0.7498,0.1535 \ 0.8634,0.7406,0.1596 \ 0.9035,0.7330,0.1774 \
         0.9393,0.7288,0.2100 \ 0.9728,0.7298,0.2394 \ 0.9956,0.7434,0.2371 \
         0.9970,0.7659,0.2199 \ 0.9952,0.7893,0.2028 \ 0.9892,0.8136,0.1885 \
         0.9786,0.8386,0.1766 \ 0.9676,0.8639,0.1643 \ 0.9610,0.8890,0.1537 \
         0.9597,0.9135,0.1423 \ 0.9628,0.9373,0.1265 \ 0.9691,0.9606,0.1064 \
         0.9769,0.9839,0.0805)
    out = J(n, 1, "")
    for (i = 1; i <= n; i++) {
        t = 1
        if (n > 1) {
            t = 1 + (i - 1) * 63 / (n - 1)
        }
        lo = floor(t)
        if (lo >= 64) {
            lo = 63
        }
        fr = t - lo
        c = (1 - fr) :* P[lo, .] + fr :* P[lo + 1, .]
        c = round(255 :* c)
        out[i] = strofreal(c[1]) + " " + strofreal(c[2]) + " " + strofreal(c[3])
    }
    return(out)
}

// diverging blue-white-red map
string colvector xqq_bwr(real scalar n)
{
    real scalar i, t
    real rowvector c
    real matrix A
    real scalar lo, fr
    string colvector out
    // same anchors as the qqardl package
    A = (49, 104, 176 \ 145, 182, 222 \ 255, 255, 255 \ 240, 150, 140 \ 200, 30, 40)
    out = J(n, 1, "")
    for (i = 1; i <= n; i++) {
        t = 1
        if (n > 1) {
            t = 1 + (i - 1) * 4 / (n - 1)
        }
        lo = floor(t)
        if (lo >= 5) {
            lo = 4
        }
        fr = t - lo
        c = round((1 - fr) :* A[lo, .] + fr :* A[lo + 1, .])
        out[i] = strofreal(c[1]) + " " + strofreal(c[2]) + " " + strofreal(c[3])
    }
    return(out)
}

// MATLAB jet
string colvector xqq_jet(real scalar n)
{
    real matrix P
    real scalar i, t, lo, fr
    real rowvector c
    string colvector out
    P = (0,0,143 \ 0,0,255 \ 0,127,255 \ 0,255,255 \ 127,255,127 \
         255,255,0 \ 255,127,0 \ 255,0,0 \ 127,0,0)
    out = J(n, 1, "")
    for (i = 1; i <= n; i++) {
        t = 1
        if (n > 1) {
            t = 1 + (i - 1) * 8 / (n - 1)
        }
        lo = floor(t)
        if (lo >= 9) {
            lo = 8
        }
        fr = t - lo
        c = round((1 - fr) :* P[lo, .] + fr :* P[lo + 1, .])
        out[i] = strofreal(c[1]) + " " + strofreal(c[2]) + " " + strofreal(c[3])
    }
    return(out)
}

// n x 3 RGB matrix (0-255) for the tile heatmap
real matrix xqq_palette(string scalar map, real scalar n)
{
    string colvector cc
    real matrix out
    real scalar i
    if (map == "bwr") {
        cc = xqq_bwr(n)
    }
    else if (map == "jet") {
        cc = xqq_jet(n)
    }
    else {
        cc = xqq_parula(n)
    }
    out = J(n, 3, .)
    for (i = 1; i <= n; i++) {
        out[i, .] = strtoreal(tokens(cc[i]))
    }
    return(out)
}

void xqq_colors_to_local(string scalar map, real scalar n, string scalar lname)
{
    string colvector cc
    string scalar s
    real scalar i
    if (map == "bwr") {
        cc = xqq_bwr(n)
    }
    else if (map == "jet") {
        cc = xqq_jet(n)
    }
    else {
        cc = xqq_parula(n)
    }
    s = ""
    for (i = 1; i <= n; i++) {
        s = s + `"""' + cc[i] + `"""' + " "
    }
    st_local(lname, s)
}

end
