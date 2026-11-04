*! freeiv_mata 1.0.0  06oct2026  A. Araar
*! Mata engine of freeiv: residuals, moments of orders 2-3-4, the closed forms
*! of model A (bounds, QME, HME), the discriminant test, the covariance of the
*! moment contributions (no weight or aweights, pweights, vce(svy)).
*! Kept in a separate file because an ado-file loaded automatically does not
*! execute its mata: block; freeiv_engine.ado sources it on demand.

cap program drop freeiv_mata
program define freeiv_mata
    version 16
end

version 16
mata:
mata set matastrict off

real scalar _fiv_m(real colvector a, real colvector w, real scalar sw)
{
    return(quadsum(w :* a) / sw)
}

real colvector _fiv_resid(real colvector y, real matrix X, real colvector w)
{
    return(y - X * (invsym(quadcross(X, w, X)) * quadcross(X, w, y)))
}

/* Weighted OLS, returns the coefficient vector */
real colvector _fiv_ols(real colvector y, real matrix X, real colvector w)
{
    return(invsym(quadcross(X, w, X)) * quadcross(X, w, y))
}


/* ------------------------------------------------------------------ *
 * Variance of the moment vector through the stacked influence         *
 * function.  The residuals are themselves estimated, so the variance  *
 * must account for b1 and b2; inverting the block Jacobian of the     *
 * exactly identified system gives                                     *
 *     psi_i = (h_i - m) - D1 Q^-1 X_i xi_i - D2 Q^-1 X_i e2_i         *
 * ------------------------------------------------------------------ */
real matrix _fiv_infl(real colvector xi, real colvector e2, real matrix X,
                      real colvector w, real rowvector mv)
{
    real matrix H, Z1, Z2, Q, Qi, D1, D2
    real colvector z
    real scalar sw
    sw = quadsum(w)
    z  = J(rows(xi), 1, 0)
    H  = (e2:^2, xi:*e2, xi:^2, e2:^3, xi:*e2:^2, xi:^2:*e2, xi:^3,
          e2:^4, xi:*e2:^3, xi:^2:*e2:^2)
    Z1 = (z, e2, 2*xi, z, e2:^2, 2*xi:*e2, 3*xi:^2, z, e2:^3, 2*xi:*e2:^2)
    Z2 = (2*e2, xi, z, 3*e2:^2, 2*xi:*e2, xi:^2, z, 4*e2:^3, 3*xi:*e2:^2,
          2*xi:^2:*e2)
    Q  = quadcross(X, w, X) / sw
    Qi = invsym(Q)
    D1 = quadcross(Z1, w, X) / sw
    D2 = quadcross(Z2, w, X) / sw
    return((H :- mv) - (X :* xi) * (Qi * D1') - (X :* e2) * (Qi * D2'))
}

real scalar _fiv_se(real rowvector g, real matrix V, real scalar n)
{
    real scalar v
    if (missing(g)) return(.)
    v = (g * V * g') / n
    return(v > 0 ? sqrt(v) : .)
}

/* ------------------------------------------------------------------ *
 * The covariance of the moment contributions.  Every standard error  *
 * of freeiv is a delta method on Vm/n, Vm being the covariance of the *
 * influence values of the moments, so the weights and vce() enter     *
 * through this one function:                                          *
 *   no design set   sum w psi psi' / sum w   (no weight, aweights)    *
 *   design set      n times the design-based variance of the moment   *
 *                   means: pweights alone are a design in which every *
 *                   observation is its own primary unit (the          *
 *                   sandwich); vce(svy) brings the strata, the PSUs   *
 *                   and the fpc of svyset (Taylor linearization,      *
 *                   first stage)                                       *
 * freeiv.ado sets the design before the engines run and clears it     *
 * after, so freeivmenu and the other commands never see a stale one.  *
 * ------------------------------------------------------------------ */
/* the strata and PSU identifiers as numbers: a string identifier becomes
   the rank of its distinct values, computed here so that the data in
   memory are never re-sorted                                            */
real colvector _fiv_codes(string scalar v, string scalar tousev)
{
    string colvector s
    real colvector   o, c
    real scalar      i, k
    if (!st_isstrvar(v)) return(st_data(., v, tousev))
    s = st_sdata(., v, tousev)
    c = J(rows(s), 1, .)
    if (rows(s) == 0) return(c)
    o = order(s, 1)
    k = 1
    c[o[1]] = 1
    for (i = 2; i <= rows(s); i++) {
        if (s[o[i]] != s[o[i - 1]]) k++
        c[o[i]] = k
    }
    return(c)
}

void _fiv_vset(string scalar strv, string scalar psuv, string scalar fpcv,
               string scalar tousev, real scalar certainty)
{
    pointer(real matrix) scalar p
    real colvector s, u, f
    real scalar n
    rmexternal("__fiv_vdesign")
    rmexternal("__fiv_vcert")
    n = rows(st_data(., tousev, tousev))
    if (strv != "") s = _fiv_codes(strv, tousev)
    else            s = J(n, 1, 1)
    if (psuv != "") u = _fiv_codes(psuv, tousev)
    else            u = (1::n)
    if (fpcv != "") f = st_data(., fpcv, tousev)
    else            f = J(n, 1, 0)
    p  = crexternal("__fiv_vdesign")
    *p = (s, u, f)
    p  = crexternal("__fiv_vcert")
    *p = certainty
}

void _fiv_vclear()
{
    rmexternal("__fiv_vdesign")
    rmexternal("__fiv_vcert")
}

/* (number of strata, number of PSUs, strata with a single PSU) of the
   design currently set; missing when none is                           */
real rowvector _fiv_vinfo()
{
    pointer(real matrix) scalar p
    real matrix    D, info, infoh
    real colvector o, s, u, g, sp
    real scalar    n, h, ns
    p = findexternal("__fiv_vdesign")
    if (p == NULL) return((., ., .))
    D = *p
    n = rows(D)
    if (n == 0) return((., ., .))
    o = order((D[., 1..2], (1::n)), (1, 2, 3))
    s = D[o, 1]
    u = D[o, 2]
    if (n > 1) g = runningsum(1 \ ((s[2::n] :!= s[1::n-1]) :| (u[2::n] :!= u[1::n-1])))
    else       g = 1
    info  = panelsetup(g, 1)
    sp    = s[info[., 1]]
    infoh = panelsetup(sp, 1)
    ns = 0
    for (h = 1; h <= rows(infoh); h++) {
        if (infoh[h, 2] == infoh[h, 1]) ns++
    }
    return((rows(infoh), rows(info), ns))
}

/* the design-based variance of the weighted means of the columns of P:
   linearized values u_i = w_i P_i / sum w, totals by PSU, deviations from
   the stratum mean, (1 - f_h) n_h/(n_h - 1) per stratum.  A stratum with a
   single PSU makes the variance missing (svyset's default) unless the
   design says singleunit(certainty), which drops its contribution.       */
real matrix _fiv_dvar(real matrix P, real colvector w, real matrix D,
                      real scalar cert)
{
    real matrix    U, Z, V, info, infoh, Zh, dev
    real colvector o, s, u, f, g, sp, fp
    real scalar    n, k, h, nh, fh
    n  = rows(P)
    k  = cols(P)
    U  = (w :* P) / quadsum(w)
    /* the observations of a PSU are ties of this sort, and order() does not
       keep ties in a fixed order: the sums by PSU then ran in an order that
       changed from one call to the next, a difference of 1e-16 that the
       search of the profiled GMM amplified to 1e-6 (the lock of 1.0.0 saw
       it).  The position of the observation, as last key, fixes the order. */
    o  = order((D[., 1..2], (1::n)), (1, 2, 3))
    U  = U[o, .]
    s  = D[o, 1]
    u  = D[o, 2]
    f  = D[o, 3]
    if (n > 1) g = runningsum(1 \ ((s[2::n] :!= s[1::n-1]) :| (u[2::n] :!= u[1::n-1])))
    else       g = 1
    info = panelsetup(g, 1)
    Z    = panelsum(U, info)
    sp   = s[info[., 1]]
    fp   = f[info[., 1]]
    infoh = panelsetup(sp, 1)
    V = J(k, k, 0)
    for (h = 1; h <= rows(infoh); h++) {
        Zh = panelsubmatrix(Z, h, infoh)
        nh = rows(Zh)
        if (nh < 2) {
            if (cert == 1) continue
            return(J(k, k, .))
        }
        /* svyset's convention: an fpc at most 1 is a sampling rate, above
           1 it is the number of PSUs in the stratum                       */
        fh = fp[infoh[h, 1]]
        if (fh > 1)      fh = nh / fh
        else if (fh < 0) fh = 0
        dev = Zh :- mean(Zh)
        V   = V + (1 - fh) * nh / (nh - 1) * quadcross(dev, dev)
    }
    return(V)
}

real matrix _fiv_cov(real matrix P, real colvector w)
{
    pointer(real matrix) scalar p, pc
    p = findexternal("__fiv_vdesign")
    if (p == NULL) return(quadcross(P, w, P) / quadsum(w))
    if (rows(*p) != rows(P)) return(quadcross(P, w, P) / quadsum(w))
    pc = findexternal("__fiv_vcert")
    return(rows(P) * _fiv_dvar(P, w, *p, (pc == NULL ? 0 : *pc)))
}

end

version 16
mata:
mata set matastrict off

void _freeiv_all(string scalar y1v, string scalar y2v, string scalar xv,
                 string scalar wv, string scalar tousev,
                 string scalar xiv, string scalar e2v)
{
    real colvector y1, y2, w, xi, e2, dvec
    real matrix    X, Pm, Pc, Sm, Zq, res
    real scalar    n, sw, cc
    real scalar    m02, m11, m20, m03, m12, m21, m30, m04, m13, m22
    real scalar    m02c, m11c, m20c, gt, sk2, lo, hi
    real scalar    D, Dse, Dz, vertex, rst, r1, r2, nin, ss
    real scalar    qme, hme, olsg, theta, sV2, sV1, csh, gref, atv
    real scalar    se_gt, se_lo, se_qme, se_hme, se_ver
    real scalar    den, rr, cc2, AA, BB, muu
    real rowvector mv, gv, gv2, gq, gh
    real matrix    Pinf, Vm
    string rowvector cn

    y1 = st_data(., y1v, tousev)
    y2 = st_data(., y2v, tousev)
    n  = rows(y1)
    if (xv != "") X = st_data(., tokens(xv), tousev)
    else          X = J(n, 0, .)
    X = J(n, 1, 1), X
    if (wv != "") w = st_data(., wv, tousev)
    else          w = J(n, 1, 1)
    w  = w * n / quadsum(w)
    sw = quadsum(w)

    xi = _fiv_resid(y1, X, w)
    e2 = _fiv_resid(y2, X, w)
    if (xiv != "") st_store(., xiv, tousev, xi)
    if (e2v != "") st_store(., e2v, tousev, e2)

    m02 = _fiv_m(e2:^2, w, sw)
    m11 = _fiv_m(xi :* e2, w, sw)
    m20 = _fiv_m(xi:^2, w, sw)
    m03 = _fiv_m(e2:^3, w, sw)
    m12 = _fiv_m(xi :* e2:^2, w, sw)
    m21 = _fiv_m(xi:^2 :* e2, w, sw)
    m30 = _fiv_m(xi:^3, w, sw)
    m04 = _fiv_m(e2:^4, w, sw)
    m13 = _fiv_m(xi :* e2:^3, w, sw)
    m22 = _fiv_m(xi:^2 :* e2:^2, w, sw)

    cc   = sw / (sw - 1)
    m02c = m02 * cc
    m11c = m11 * cc
    m20c = m20 * cc
    gt   = m11c / m02c
    sk2  = m03 / m02c^1.5
    lo   = (gt >= 0 ? gt / 2 : gt)
    hi   = (gt >= 0 ? gt : gt / 2)

    /* ---- discriminant test: D = 9 m12^2 - 8 m03 m21 -------------------- */
    D    = 9 * m12^2 - 8 * m03 * m21
    Pm   = e2:^3, xi :* e2:^2, xi:^2 :* e2
    Pc   = Pm :- (m03, m12, m21)
    Sm   = _fiv_cov(Pc, w)
    dvec = (-8 * m21 \ 18 * m12 \ -8 * m03)
    ss   = (dvec' * Sm * dvec) / n
    Dse  = (ss > 0 ? sqrt(ss) : .)
    Dz   = (Dse < . ? D / Dse : .)
    vertex = (m03 != 0 ? 3 * m12 / (4 * m03) : .)
    rst    = (m03 * m21 != 0 ? m12^2 / (m03 * m21) : .)

    /* ---- QME ---------------------------------------------------------- */
    r1 = .
    r2 = .
    nin = 0
    qme = .
    if (abs(m03) > 1e-12 & D >= 0) {
        r1 = (3 * m12 - sqrt(D)) / (4 * m03)
        r2 = (3 * m12 + sqrt(D)) / (4 * m03)
        nin = (r1 >= lo & r1 <= hi) + (r2 >= lo & r2 <= hi)
        if (nin == 1) qme = (r1 >= lo & r1 <= hi ? r1 : r2)
        else if (nin == 2) qme = (abs(r1 - 0.75 * gt) <= abs(r2 - 0.75 * gt) ? r1 : r2)
        else qme = (abs(r1 - 0.75 * gt) <= abs(r2 - 0.75 * gt) ? r1 : r2)
    }

    /* ---- HME: the cube root under symmetric V1 and V2 -------------------
       m30/m03 = 8 gamma^3 when V1 and V2 are symmetric, so the ratio has the
       sign of gamma, which is the sign of gamma-tilde (c >= 0): the real
       cube root, negative for a negative effect.  A ratio of the other sign
       cannot come from that model, and the route then returns nothing.    */
    hme = .
    if (abs(m03) >= 1e-6) {
        rr = m30 / m03
        if (rr * gt > 0) hme = 0.5 * sign(rr) * abs(rr)^(1 / 3)
    }

    /* ---- OLS of y1 on (1, X, y2) --------------------------------------- */
    Zq   = X, y2
    res  = _fiv_ols(y1, Zq, w)
    olsg = res[rows(res), 1]

    /* ---- what the retained third-order value implies ---------------------
       m03 = A + B and m12 = gamma (2A + B) give A = m12/gamma - m03 and
       B = 2 m03 - m12/gamma.  B = 0 is the symmetry assumption of the HME,
       and mu = A/(A+B) is the confounder's share of the third moment.  The
       second-order system then gives theta, sV2, sV1 and the share
       c = theta/(theta + sV2) = theta/m02, the one number the second order
       cannot give: gamma = gamma-tilde/(1 + c).  They are evaluated at the
       QME root, or at the vertex when the discriminant is negative -- the
       value the default route retains then (atv = 1), where B = 2A by
       construction.                                                       */
    gref = (qme < . ? qme : (D < 0 ? vertex : .))
    atv  = (qme < . ? 0 : (gref < . ? 1 : .))
    AA = .; BB = .; muu = .
    theta = .; sV2 = .; sV1 = .; csh = .
    if (gref < . & gref != 0) {
        AA    = m12 / gref - m03
        BB    = 2 * m03 - m12 / gref
        muu   = (m03 != 0 ? AA / m03 : .)
        theta = m02c * (gt - gref) / gref
        sV2   = m02c - theta
        sV1   = m20c - gref^2 * m02c - 3 * gref^2 * theta
        csh   = (m02c != 0 ? theta / m02c : .)
    }

    /* ---- analytic standard errors --------------------------------------
       Every closed form is a smooth function of the same moment vector, so
       one covariance matrix V serves them all -- and the gradients are kept
       so that freeivtest can compare any two routes: the difference of two
       estimators has variance (g_a - g_b)' V (g_a - g_b) / n.            */
    mv   = (m02, m11, m20, m03, m12, m21, m30, m04, m13, m22)
    Pinf = _fiv_infl(xi, e2, X, w, mv)
    Vm   = _fiv_cov(Pinf, w)
    gq = J(1, 10, .); gh = J(1, 10, .)

    gv    = J(1, 10, 0)
    gv[2] = 1 / m02
    gv[1] = -m11 / m02^2
    se_gt = _fiv_se(gv, Vm, n)
    se_lo = _fiv_se(gv / 2, Vm, n)

    se_qme = .
    if (qme < .) {
        den = 4 * m03 * qme - 3 * m12
        if (den != 0) {
            gq    = J(1, 10, 0)
            gq[4] = -2 * qme^2 / den
            gq[5] =  3 * qme / den
            gq[6] = -1 / den
            se_qme = _fiv_se(gq, Vm, n)
        }
    }

    gv2    = J(1, 10, 0)
    gv2[5] = 3 / (4 * m03)
    gv2[4] = -3 * m12 / (4 * m03^2)
    se_ver = _fiv_se(gv2, Vm, n)

    /* d/dr of sign(r)|r|^(1/3)/2 is |r|^(-2/3)/6 on either side of zero */
    se_hme = .
    if (hme < . & m03 != 0) {
        rr     = m30 / m03
        cc2    = (1 / 6) * abs(rr)^(-2 / 3)
        gh     = J(1, 10, 0)
        gh[7]  = cc2 / m03
        gh[4]  = -cc2 * m30 / m03^2
        se_hme = _fiv_se(gh, Vm, n)
    }

    /* ---- V and the gradients, for freeivtest ---------------------------- */
    st_matrix("__freeiv_V", Vm)
    st_matrix("__freeiv_G", (gv \ gv / 2 \ gq \ gh \ gv2))
    cn = ("m02", "m11", "m20", "m03", "m12", "m21", "m30", "m04", "m13", "m22")
    st_matrixcolstripe("__freeiv_V", (J(10, 1, ""), cn'))
    st_matrixrowstripe("__freeiv_V", (J(10, 1, ""), cn'))
    st_matrixcolstripe("__freeiv_G", (J(10, 1, ""), cn'))
    cn = ("ols", "lo", "qme", "hme", "vertex")
    st_matrixrowstripe("__freeiv_G", (J(5, 1, ""), cn'))

    st_matrix("__freeiv_M",
        (n, sw, m02, m11, m20, m03, m12, m21, m30, m04, m13, m22,
         m02c, m11c, m20c, gt, sk2, lo, hi,
         D, Dse, Dz, vertex, rst, r1, r2, nin,
         qme, hme, olsg,
         theta, sV2, sV1, csh, AA, BB, muu, atv,
         se_gt, se_lo, se_qme, se_hme, se_ver))
    cn = ("n", "sum_w", "m02", "m11", "m20", "m03", "m12", "m21", "m30",
          "m04", "m13", "m22", "m02c", "m11c", "m20c", "gt", "skew2",
          "lo", "hi", "disc", "disc_se", "disc_z", "vertex", "rstar",
          "root1", "root2", "nroots", "qme", "hme", "ols",
          "theta", "sV2", "sV1", "cshare", "A", "B", "mu", "at_vertex",
          "se_gt", "se_lo", "se_qme", "se_hme", "se_vertex")
    st_matrixcolstripe("__freeiv_M", (J(cols(cn), 1, ""), cn'))
}

end

version 16
mata:
mata set matastrict off

/* ------------------------------------------------------------------ *
 * Model B (ARAARP4): two endogenous regressors sharing one latent     *
 * confounder.                                                         *
 *     Y2 = X'b2 + a2 U + V2                                           *
 *     Y3 = X'b3 + a3 U + V3                                           *
 *     Y1 = X'b1 + g2 Y2 + g3 Y3 + a1 U + V1      (a1 free)            *
 * Theorem 1 in closed form, with the three guards of Proposition 1.   *
 * ------------------------------------------------------------------ */

/* Theorem 1 as a pure function of the eight moments, so that the delta
   method can differentiate it numerically.  Returns
   (g2, g3, a1, a2, a3, mu3, s2, s3, cond, sc, guard); guard is 0 when the
   estimate exists, and 1, 2, 3 or 4 for the guard that fired.          */
real rowvector _fivp_cf(real rowvector mv)
{
    real scalar m22, m33, m23, mx2, mx3, m223, m233, mx23
    real scalar ratio, a2, a3, s2, s3, mu3
    real matrix A
    real colvector sol
    real rowvector out

    out  = J(1, 11, .)
    m22  = mv[1]; m33  = mv[2]; m23  = mv[3]; mx2  = mv[4]
    mx3  = mv[5]; m223 = mv[6]; m233 = mv[7]; mx23 = mv[8]

    if (m223 * m233 <= 0 | abs(m233) < 1e-12) {
        out[11] = 1
        return(out)
    }
    ratio = m223 / m233
    if (m23 * ratio <= 0) {
        out[11] = 2
        return(out)
    }
    a2 = sqrt(m23 * ratio)
    a3 = sqrt(m23 / ratio)
    s2 = m22 - a2^2
    s3 = m33 - a3^2
    if (s2 <= 0 | s3 <= 0) {
        out[11] = 3
        return(out)
    }
    mu3 = m223 / (a2^2 * a3)
    A   = (m22, m23, a2 \ m23, m33, a3 \ m223, m233, a2 * a3 * mu3)
    sol = lusolve(A, (mx2 \ mx3 \ mx23))
    if (hasmissing(sol)) {
        out[11] = 4
        return(out)
    }

    out[1]  = sol[1]; out[2] = sol[2]; out[3] = sol[3]
    out[4]  = a2;     out[5] = a3;     out[6] = mu3
    out[7]  = s2;     out[8] = s3
    out[9]  = cond(A)
    out[10] = sol[1] * a2 + sol[2] * a3
    out[11] = 0
    return(out)
}

/* Stacked influence function, three first-stage equations instead of two */
real matrix _fivp_infl(real colvector e2, real colvector e3, real colvector xi,
                       real matrix X, real colvector w, real rowvector mv)
{
    real matrix H, D2m, D3m, D1m, Q, Qi, P
    real colvector z
    real scalar sw
    sw = quadsum(w)
    z  = J(rows(e2), 1, 0)
    H   = (e2:^2, e3:^2, e2:*e3, xi:*e2, xi:*e3, e2:^2:*e3, e2:*e3:^2,
           xi:*e2:*e3)
    D2m = (2*e2, z, e3, xi, z, 2*e2:*e3, e3:^2, xi:*e3)
    D3m = (z, 2*e3, e2, z, xi, e2:^2, 2*e2:*e3, xi:*e2)
    D1m = (z, z, z, e2, e3, z, z, e2:*e3)
    Q  = quadcross(X, w, X) / sw
    Qi = invsym(Q)
    P  = H :- mv
    P  = P - (X :* e2) * (Qi * (quadcross(D2m, w, X) / sw)')
    P  = P - (X :* e3) * (Qi * (quadcross(D3m, w, X) / sw)')
    P  = P - (X :* xi) * (Qi * (quadcross(D1m, w, X) / sw)')
    return(P)
}

void _freeiv_proxy(string scalar y1v, string scalar y2v, string scalar y3v,
                   string scalar xv, string scalar wv, string scalar tousev)
{
    real colvector y1, y2, y3, w, e2, e3, xi
    real matrix    X, Pinf, Vm, Jc, C
    real rowvector mv, o, up, dn, fu, fd
    real scalar    n, sw, j, step, rho, tr, R1, R2, R3, q, ivg
    string rowvector cn

    y1 = st_data(., y1v, tousev)
    y2 = st_data(., y2v, tousev)
    y3 = st_data(., y3v, tousev)
    n  = rows(y1)
    if (xv != "") X = st_data(., tokens(xv), tousev)
    else          X = J(n, 0, .)
    X = J(n, 1, 1), X
    if (wv != "") w = st_data(., wv, tousev)
    else          w = J(n, 1, 1)
    w  = w * n / quadsum(w)
    sw = quadsum(w)

    e2 = _fiv_resid(y2, X, w)
    e3 = _fiv_resid(y3, X, w)
    xi = _fiv_resid(y1, X, w)

    mv = (_fiv_m(e2:^2, w, sw), _fiv_m(e3:^2, w, sw), _fiv_m(e2:*e3, w, sw),
          _fiv_m(xi:*e2, w, sw), _fiv_m(xi:*e3, w, sw),
          _fiv_m(e2:^2:*e3, w, sw), _fiv_m(e2:*e3:^2, w, sw),
          _fiv_m(xi:*e2:*e3, w, sw))
    o = _fivp_cf(mv)

    /* ---- delta method: numeric Jacobian of Theorem 1 on the moments ---- */
    C = J(3, 3, .)
    if (o[11] == 0) {
        Pinf = _fivp_infl(e2, e3, xi, X, w, mv)
        Vm   = _fiv_cov(Pinf, w)
        Jc   = J(3, 8, .)
        for (j = 1; j <= 8; j++) {
            step = 1e-6 * max((abs(mv[j]), 1))
            up = mv; dn = mv
            up[j] = up[j] + step
            dn[j] = dn[j] - step
            fu = _fivp_cf(up)
            fd = _fivp_cf(dn)
            if (fu[11] == 0 & fd[11] == 0) {
                Jc[1, j] = (fu[1] - fd[1]) / (2 * step)
                Jc[2, j] = (fu[2] - fd[2]) / (2 * step)
                Jc[3, j] = (fu[3] - fd[3]) / (2 * step)
            }
        }
        if (!hasmissing(Jc)) C = (Jc * Vm * Jc') / n
    }

    /* ---- one-factor check: three estimates of a2/a3 (eq. 15) ----------- */
    R1 = _fiv_m(e2:^2:*e3, w, sw) / _fiv_m(e2:*e3:^2, w, sw)
    q  = _fiv_m(xi:*e2:^2, w, sw) / _fiv_m(xi:*e3:^2, w, sw)
    R2 = sign(q) * sqrt(abs(q))
    R3 = _fiv_m(xi:^2:*e2, w, sw) / _fiv_m(xi:^2:*e3, w, sw)

    /* ---- what y3 used as an instrument for y2 would return ------------- */
    ivg = _fiv_m(e3:*xi, w, sw) / _fiv_m(e2:*e3, w, sw)

    rho = mv[3] / sqrt(mv[1] * mv[2])
    tr  = (abs(rho) < 1 ? rho * sqrt(n - 2) / sqrt(1 - rho^2) : .)

    st_matrix("__freeiv_P",
        (n, sw, mv,
         o[1], o[2], o[3], o[4], o[5], o[6], o[7], o[8], o[9], o[10], o[11],
         (C[1,1] > 0 ? sqrt(C[1,1]) : .),
         (C[2,2] > 0 ? sqrt(C[2,2]) : .),
         (C[3,3] > 0 ? sqrt(C[3,3]) : .),
         R1, R2, R3, abs(R3 / R1 - 1), ivg, tr))
    cn = ("n", "sum_w", "m22", "m33", "m23", "mx2", "mx3", "m223", "m233",
          "mx23", "g2", "g3", "a1", "a2", "a3", "mu3", "s2", "s3", "cnum",
          "sc", "guard", "se_g2", "se_g3", "se_a1", "R1", "R2", "R3",
          "disc_R", "ivgap", "t_rho")
    st_matrixcolstripe("__freeiv_P", (J(cols(cn), 1, ""), cn'))
    st_matrix("__freeiv_PV", C)
}

end

version 16
mata:
mata set matastrict off

/* ------------------------------------------------------------------ *
 * Brick 5: the instrument-free estimators of the literature, for      *
 * comparison.  They are NOT peers of the routes above: each buys its  *
 * point identification with an assumption of its own, and the value   *
 * of putting them here is that the identification bounds judge them   *
 * all on the same data.                                               *
 * ------------------------------------------------------------------ */

/* Average ranks, ties shared, as scipy's rankdata does -- the discrete
   regressors of real data make this matter. */
real colvector _fivl_rank(real colvector v)
{
    real colvector ord, sv, rnk
    real scalar n, i, j, k, avg, more
    n   = rows(v)
    ord = order(v, 1)
    sv  = v[ord]
    rnk = J(n, 1, .)
    i   = 1
    while (i <= n) {
        /* Mata's & does NOT short-circuit, so the bound test and the tie
           test cannot share one condition: at j = n the second operand
           would subscript sv[n+1].                                       */
        j    = i
        more = 1
        while (more == 1) {
            if (j >= n) {
                more = 0
            }
            else if (sv[j + 1] != sv[i]) {
                more = 0
            }
            else {
                j++
            }
        }
        avg = (i + j) / 2
        for (k = i; k <= j; k++) {
            rnk[ord[k]] = avg
        }
        i = j + 1
    }
    return(rnk)
}

/* Two-stage least squares: y2 on (Xm, Z), then y1 on (Xm, y2hat) */
real scalar _fivl_2sls(real colvector y1, real colvector y2, real matrix Xm,
                       real matrix Z, real colvector w)
{
    real matrix Zf, W2
    real colvector y2h, b
    Zf  = Xm, Z
    y2h = Zf * _fiv_ols(y2, Zf, w)
    W2  = Xm, y2h
    b   = _fiv_ols(y1, W2, w)
    return(b[rows(b), 1])
}

real scalar _fivl_r2(real colvector y, real matrix Z, real colvector w)
{
    real colvector r
    real scalar sw, ybar, ss
    sw   = quadsum(w)
    r    = y - Z * _fiv_ols(y, Z, w)
    ybar = quadsum(w :* y) / sw
    ss   = quadsum(w :* (y :- ybar):^2)
    return(ss > 0 ? 1 - quadsum(w :* r:^2) / ss : .)
}

void _freeiv_lit(string scalar y1v, string scalar y2v, string scalar xv,
                 string scalar wv, string scalar tousev,
                 real scalar delta, real scalar rmaxin)
{
    real colvector y1, y2, w, e2, xi, ctrl, b
    real matrix    X, Xm, Zc, Zf, Xc
    real scalar    n, sw, olsg, lew, cop, rnkg
    real scalar    ost, b0, b1, R0, R1, rmax
    string rowvector cn

    y1 = st_data(., y1v, tousev)
    y2 = st_data(., y2v, tousev)
    n  = rows(y1)
    if (xv != "") X = st_data(., tokens(xv), tousev)
    else          X = J(n, 0, .)
    Xm = J(n, 1, 1), X
    if (wv != "") w = st_data(., wv, tousev)
    else          w = J(n, 1, 1)
    w  = w * n / quadsum(w)
    sw = quadsum(w)

    e2 = _fiv_resid(y2, Xm, w)
    xi = _fiv_resid(y1, Xm, w)

    /* ---- OLS ----------------------------------------------------------- */
    Zf   = Xm, y2
    b    = _fiv_ols(y1, Zf, w)
    olsg = b[rows(b), 1]

    /* ---- Lewbel (2012): Z = (X - mean X) * eps2 ------------------------ */
    lew = .
    if (cols(X) > 0) {
        Xc  = X :- (quadcross(w, X) / sw)
        lew = _fivl_2sls(y1, y2, Xm, Xc :* e2, w)
    }

    /* ---- Park & Gupta (2012): control invnormal(F(y2)) ----------------- */
    ctrl = invnormal(_fivl_rank(y2) / (n + 1))
    Zc   = Xm, y2, ctrl
    b    = _fiv_ols(y1, Zc, w)
    cop  = b[rows(b) - 1, 1]

    /* ---- Breitung, Mayer & Wied (2024): rank of the first-stage residual */
    rnkg = .
    if (cols(X) > 0) {
        ctrl = invnormal(_fivl_rank(e2) / (n + 1))
        Zc   = Xm, y2, ctrl
        b    = _fiv_ols(y1, Zc, w)
        rnkg = b[rows(b) - 1, 1]
    }

    /* ---- Oster (2019): coefficient stability --------------------------- */
    ost = .; b0 = .; b1 = .; R0 = .; R1 = .; rmax = .
    if (cols(X) > 0) {
        Zc = J(n, 1, 1), y2
        b  = _fiv_ols(y1, Zc, w)
        b0 = b[rows(b), 1]
        R0 = _fivl_r2(y1, Zc, w)
        b1 = olsg
        R1 = _fivl_r2(y1, Zf, w)
        rmax = (rmaxin < . ? rmaxin : min((1.3 * R1, 1)))
        if (R1 != R0) ost = b1 - delta * (b0 - b1) * (rmax - R1) / (R1 - R0)
    }

    st_matrix("__freeiv_L",
        (n, olsg, lew, cop, rnkg, ost, b0, b1, R0, R1, rmax, delta))
    cn = ("n", "ols", "lewbel12", "copula", "rank", "oster", "ost_b0",
          "ost_b1", "ost_R0", "ost_R1", "ost_rmax", "ost_delta")
    st_matrixcolstripe("__freeiv_L", (J(cols(cn), 1, ""), cn'))
}

end

version 16
mata:
mata set matastrict off

/* ------------------------------------------------------------------ *
 * Brick 6a: the GMM on the moments of orders 2, 3 and 4, in profiled  *
 * form.  Given gamma, five of the nine restrictions determine five    *
 * parameters exactly,                                                 *
 *     theta = m11/g - m02        sV2 = m02 - theta                    *
 *     sV1   = m20 - g^2 m02 - 3 g^2 theta                             *
 *     A     = m12/g - m03        B   = m03 - A                        *
 * leaving four residuals in three unknowns (gamma, A4, B4), hence one *
 * over-identifying restriction and a J with 1 df, as in ARAARP3.      *
 *                                                                     *
 * Two consequences of writing it this way.  Substituting A into the   *
 * fifth residual gives m21 - 3 g m12 + 2 g^2 m03, which IS the QME    *
 * quadratic: the third-order route is the part of this GMM that the   *
 * fourth moments then reweight.  And theta >= 0 with sV2 >= 0 confine *
 * gamma to [gt/2, gt], so the search domain is the identified set and *
 * the estimate can never leave it.                                    *
 * ------------------------------------------------------------------ */

real rowvector _fivg_r4(real rowvector mv, real scalar g,
                        real scalar A4, real scalar B4)
{
    real scalar m02, m03, m11, m20, m12, m21, m04, m13, m22
    real scalar th, sV2, sV1, A, ts
    m02 = mv[1]; m11 = mv[2]; m20 = mv[3]; m03 = mv[4]; m12 = mv[5]
    m21 = mv[6]; m04 = mv[8]; m13 = mv[9]; m22 = mv[10]
    th  = m11 / g - m02
    sV2 = m02 - th
    sV1 = m20 - g^2 * m02 - 3 * g^2 * th
    A   = m12 / g - m03
    ts  = th * sV2
    return((m21 - g^2 * (3 * A + m03),
            m04 - (A4 + 6 * ts + B4),
            m13 - g * (2 * A4 + 9 * ts + B4),
            m22 - (g^2 * (4 * A4 + 13 * ts + B4) + sV1 * m02)))
}

/* A4 and B4 minimise r'Wr for a given gamma: a two-column linear solve.
   Returns (A4, B4, criterion) and writes the residual into rout.        */
real rowvector _fivg_conc(real rowvector mv, real scalar g, real matrix W,
                          real rowvector rout)
{
    real rowvector c, r
    real matrix D, DW, M
    real colvector b
    c = _fivg_r4(mv, g, 0, 0)
    D = (0, 0 \ 1, 1 \ 2 * g, g \ 4 * g^2, g^2)
    DW = D' * W
    M  = DW * D
    if (det(M) == 0) {
        rout = J(1, 4, .)
        return((., ., .))
    }
    b = lusolve(M, DW * c')
    r = c - (D * b)'
    rout = r
    return((b[1], b[2], (r * W * r')))
}

real scalar _fivg_obj(real rowvector mv, real scalar g, real matrix W)
{
    real rowvector r, o
    r = J(1, 4, .)
    o = _fivg_conc(mv, g, W, r)
    return(o[3] < . ? o[3] : 1e300)
}

real scalar _fivg_search(real rowvector mv, real scalar lo, real scalar hi,
                         real matrix W)
{
    real scalar i, k, best, v, a, b, c, d, phi, ng, step
    ng   = 400
    step = (hi - lo) / (ng - 1)
    best = 1e300
    k    = 1
    for (i = 1; i <= ng; i++) {
        v = _fivg_obj(mv, lo + (i - 1) * step, W)
        if (v < best) {
            best = v
            k    = i
        }
    }
    a   = lo + (max((k - 2, 0))) * step
    b   = lo + (min((k, ng - 1))) * step
    phi = (sqrt(5) - 1) / 2
    c   = b - phi * (b - a)
    d   = a + phi * (b - a)
    for (i = 1; i <= 200; i++) {
        if (_fivg_obj(mv, c, W) < _fivg_obj(mv, d, W)) {
            b = d
            d = c
            c = b - phi * (b - a)
        }
        else {
            a = c
            c = d
            d = a + phi * (b - a)
        }
        if (abs(b - a) < 1e-13) {
            i = 201
        }
    }
    return((a + b) / 2)
}

/* B kurt_U - A kurt_V2: the second factor of the determinant of the
   UNRESTRICTED model's Jacobian (tau free).  That determinant is
        -(gamma - tau)^5 * (B kurt_U - A kurt_V2)
   with kurt_U = A4 - 3 theta^2 and kurt_V2 = B4 - 3 sV2^2, so tau = 2 gamma
   is a testable restriction, and the J has power against it, everywhere
   except where this factor vanishes.  A normal V2 sits exactly there.
   Its MAGNITUDE is not a calibrated measure of power -- a determinant is not
   scale free -- only its vanishing is meaningful.                         */
real scalar _fivg_idfac(real rowvector mv, real scalar g,
                        real scalar A4, real scalar B4)
{
    real scalar th, sV2, A, B
    th  = mv[2] / g - mv[1]
    sV2 = mv[1] - th
    A   = mv[5] / g - mv[4]
    B   = mv[4] - A
    return(B * (A4 - 3 * th^2) - A * (B4 - 3 * sV2^2))
}

void _freeiv_gmm(string scalar y1v, string scalar y2v, string scalar xv,
                 string scalar wv, string scalar tousev)
{
    real colvector y1, y2, w, xi, e2
    real matrix    X, Vm, Pinf, W, Jm, Om, Gp, Vp
    real rowvector mv, r, o, up, dn, ru, rd, dfdm, dfdp, tot
    real scalar    n, sw, gt, lo, hi, g, A4, B4, i, s, eps
    real scalar    th, sV2, sV1, A, JJ, cc, fac, sefac, zfac, vfac
    real matrix    dpdm
    string rowvector cn

    y1 = st_data(., y1v, tousev)
    y2 = st_data(., y2v, tousev)
    n  = rows(y1)
    if (xv != "") X = st_data(., tokens(xv), tousev)
    else          X = J(n, 0, .)
    X = J(n, 1, 1), X
    if (wv != "") w = st_data(., wv, tousev)
    else          w = J(n, 1, 1)
    w  = w * n / quadsum(w)
    sw = quadsum(w)

    xi = _fiv_resid(y1, X, w)
    e2 = _fiv_resid(y2, X, w)
    mv = (_fiv_m(e2:^2, w, sw), _fiv_m(xi:*e2, w, sw), _fiv_m(xi:^2, w, sw),
          _fiv_m(e2:^3, w, sw), _fiv_m(xi:*e2:^2, w, sw),
          _fiv_m(xi:^2:*e2, w, sw), _fiv_m(xi:^3, w, sw),
          _fiv_m(e2:^4, w, sw), _fiv_m(xi:*e2:^3, w, sw),
          _fiv_m(xi:^2:*e2:^2, w, sw))
    cc = sw / (sw - 1)
    gt = (mv[2] * cc) / (mv[1] * cc)
    eps = 1e-4 * max((abs(gt), 1))
    if (gt >= 0) {
        lo = gt / 2 + eps
        hi = gt - eps
    }
    else {
        lo = gt + eps
        hi = gt / 2 - eps
    }

    Pinf = _fiv_infl(xi, e2, X, w, mv)
    Vm   = _fiv_cov(Pinf, w)

    /* textbook two step: identity weight, then the efficient weight built
       at the step-one estimates, with J evaluated under that same weight.
       A design whose variance is missing -- a stratum with a single PSU
       under singleunit(missing) -- leaves that weight undefined: the GMM
       then has no estimate, and returns missing values rather than a
       point no criterion could rank.                                      */
    W  = I(4)
    r  = J(1, 4, .)
    g  = .
    A4 = .
    B4 = .
    if (!hasmissing(Vm)) {
        g = _fivg_search(mv, lo, hi, W)
        o = _fivg_conc(mv, g, W, r)
        A4 = o[1]
        B4 = o[2]
    }
    Jm = J(4, 10, 0)
    if (A4 < .) {
        for (s = 1; s <= 10; s++) {
            up = mv
            dn = mv
            up[s] = up[s] + 1e-6 * max((abs(mv[s]), 1))
            dn[s] = dn[s] - 1e-6 * max((abs(mv[s]), 1))
            ru = _fivg_r4(up, g, A4, B4)
            rd = _fivg_r4(dn, g, A4, B4)
            Jm[., s] = ((ru - rd) / (2e-6 * max((abs(mv[s]), 1))))'
        }
        W  = invsym(Jm * Vm * Jm' + 1e-12 * I(4))
        g  = _fivg_search(mv, lo, hi, W)
        o  = _fivg_conc(mv, g, W, r)
        A4 = o[1]
        B4 = o[2]
    }

    th = .; sV2 = .; sV1 = .; A = .; JJ = .; Vp = J(3, 3, .)
    fac = .; sefac = .; zfac = .
    if (A4 < .) {
        JJ = n * (r * W * r')
        th  = mv[2] / g - mv[1]
        sV2 = mv[1] - th
        sV1 = mv[3] - g^2 * mv[1] - 3 * g^2 * th
        A   = mv[5] / g - mv[4]
        dfdm = J(1, 10, 0)
        Gp  = J(4, 3, 0)
        s   = 1e-7 * max((abs(g), 1))
        Gp[., 1] = ((_fivg_r4(mv, g + s, A4, B4)
                   - _fivg_r4(mv, g - s, A4, B4)) / (2 * s))'
        Gp[., 2] = ((_fivg_r4(mv, g, A4 + 1e-7, B4)
                   - _fivg_r4(mv, g, A4 - 1e-7, B4)) / 2e-7)'
        Gp[., 3] = ((_fivg_r4(mv, g, A4, B4 + 1e-7)
                   - _fivg_r4(mv, g, A4, B4 - 1e-7)) / 2e-7)'
        Vp = invsym(Gp' * W * Gp) / n

        /* the identification factor and its standard error: the estimator
           solves Gp' W r = 0, so d(g,A4,B4)/dm = -(Gp'WGp)^-1 Gp'W Jm, and
           the factor's total derivative is the direct partial plus the
           indirect one through the estimator                              */
        for (s = 1; s <= 10; s++) {
            up = mv
            dn = mv
            up[s] = up[s] + 1e-6 * max((abs(mv[s]), 1))
            dn[s] = dn[s] - 1e-6 * max((abs(mv[s]), 1))
            Jm[., s] = ((_fivg_r4(up, g, A4, B4)
                       - _fivg_r4(dn, g, A4, B4))
                       / (2e-6 * max((abs(mv[s]), 1))))'
            dfdm[s] = (_fivg_idfac(up, g, A4, B4)
                     - _fivg_idfac(dn, g, A4, B4)) / (2e-6 * max((abs(mv[s]), 1)))
        }
        dpdm = -invsym(Gp' * W * Gp) * (Gp' * W * Jm)
        dfdp = (( _fivg_idfac(mv, g + 1e-7, A4, B4)
                - _fivg_idfac(mv, g - 1e-7, A4, B4)) / 2e-7,
                ( _fivg_idfac(mv, g, A4 + 1e-7, B4)
                - _fivg_idfac(mv, g, A4 - 1e-7, B4)) / 2e-7,
                ( _fivg_idfac(mv, g, A4, B4 + 1e-7)
                - _fivg_idfac(mv, g, A4, B4 - 1e-7)) / 2e-7)
        tot   = dfdm + dfdp * dpdm
        fac   = _fivg_idfac(mv, g, A4, B4)
        vfac  = (tot * Vm * tot') / n
        sefac = (vfac > 0 ? sqrt(vfac) : .)
        zfac  = (sefac < . ? fac / sefac : .)
    }

    st_matrix("__freeiv_G4",
        (n, g, (Vp[1,1] > 0 ? sqrt(Vp[1,1]) : .), JJ, chi2tail(1, JJ), 1,
         th, sV2, sV1, A, mv[4] - A, A4, B4, fac, sefac, zfac,
         (Vp[2,2] > 0 ? sqrt(Vp[2,2]) : .),
         (Vp[3,3] > 0 ? sqrt(Vp[3,3]) : .), lo, hi))
    cn = ("n", "g_pgmm", "se_pgmm", "J_pgmm", "p_pgmm", "df_pgmm",
          "pgmm_theta", "pgmm_sV2", "pgmm_sV1", "pgmm_A", "pgmm_B",
          "pgmm_A4", "pgmm_B4", "idfac", "se_idfac",
          "z_idfac", "se_pgmm_A4", "se_pgmm_B4",
          "g_lo", "g_hi")
    st_matrixcolstripe("__freeiv_G4", (J(cols(cn), 1, ""), cn'))
}

end

version 16
mata:
mata set matastrict off

/* ------------------------------------------------------------------ *
 * Brick 6b: Lewbel, Schennach & Zhang (2024), as implemented by the   *
 * published command trigmm, with p(0 1).                              *
 *                                                                     *
 *     Y = X'b1 + U + V ,   W = X'b2 + gamma Y + beta U + R            *
 *                                                                     *
 * beta is FREE: nothing ties it to gamma, which is exactly what        *
 * separates this route from scale consistency.  With p(0 1) and k      *
 * exogenous variables the system has 5 + 2(k+1) parameters and as many *
 * moments, so it is JUST IDENTIFIED: the estimate is the root of the   *
 * moment vector and does not depend on the optimiser.  That is what    *
 * makes a Mata port reproduce trigmm exactly -- a damped Newton from   *
 * trigmm's own deterministic start reaches the same root as its        *
 * Gauss-Newton.  p(0 1 2) over-identifies, its criterion has several   *
 * local minima and trigmm needs a multi-start there; the ado does not  *
 * attempt it and says so.                                              *
 *                                                                     *
 * The coefficients of X are parameters of the system, not partialled   *
 * out beforehand: pre-residualising gives a different estimator.       *
 * ------------------------------------------------------------------ */

real matrix _fivz_h(real colvector p, real colvector W, real colvector Y,
                    real matrix Xm)
{
    real scalar k, gam, beta, su, sv, sr, j
    real colvector i1, i2, Yt, Wt, Q, P
    real matrix H
    k    = cols(Xm)
    gam  = p[1]
    beta = exp(p[2])
    su   = exp(p[3])
    sv   = exp(p[4])
    sr   = exp(p[5])
    i1   = Xm * p[(6)::(5 + k)]
    i2   = Xm * p[(6 + k)::(5 + 2 * k)]
    Yt   = Y - i1
    Wt   = W - i2 - gam * i1
    Q    = W - gam * Y - i2
    P    = W - (gam + beta) * Y + beta * i1 - i2

    H = (Yt :* Wt :- (beta * su + gam * (su + sv)),
         Yt:^2 :- (su + sv),
         Q:^2 :- (beta^2 * su + sr),
         Q :* P :* Yt,
         Q :* P :* (Yt:^2 :- (su + sv)) - 2 * beta * su * (P :* Yt))
    for (j = 1; j <= k; j++) {
        H = H, (Q :* Xm[., j])
    }
    for (j = 1; j <= k; j++) {
        H = H, (Yt :* Xm[., j])
    }
    return(H)
}

real colvector _fivz_g(real colvector p, real colvector W, real colvector Y,
                       real matrix Xm, real colvector w, real scalar sw,
                       real colvector sc)
{
    real colvector q
    /* the log-parameters are clipped so that exp() cannot overflow during a
       trial step: a missing criterion would otherwise stall the line search */
    q = p
    q[2] = max((min((q[2], 30)), -30))
    q[3] = max((min((q[3], 30)), -30))
    q[4] = max((min((q[4], 30)), -30))
    q[5] = max((min((q[5], 30)), -30))
    return(((quadcross(w, _fivz_h(q, W, Y, Xm)) / sw)') :/ sc)
}

/* trigmm's own default start (the num_x > 0 branch of the ado) */
real colvector _fivz_start(real colvector W, real colvector Y, real matrix Xm,
                           real colvector w, real scalar sw, real scalar sgn)
{
    real colvector b1, r1, c2, r2, xb1, xb2, p0
    real matrix Z2
    real scalar V1, V2, gam0
    b1 = _fiv_ols(Y, Xm, w)
    r1 = Y - Xm * b1
    V1 = quadsum(w :* (r1 :- quadsum(w :* r1) / sw):^2) / (sw - 1)
    Z2 = Y, Xm
    c2 = _fiv_ols(W, Z2, w)
    gam0 = c2[1]
    xb2  = c2[2::rows(c2)]
    r2 = W - Z2 * c2
    V2 = quadsum(w :* (r2 :- quadsum(w :* r2) / sw):^2) / (sw - 1)
    xb1 = (sgn < 0 ? -b1 : b1)
    if (sgn < 0) {
        gam0 = -gam0
    }
    p0 = (gam0 \ log(0.01) \ log(V1 / 2) \ log(V1 / 2) \ log(V2))
    return(p0 \ xb1 \ xb2)
}

void _freeiv_lsz(string scalar y1v, string scalar y2v, string scalar xv,
                 string scalar wv, string scalar tousev, real scalar sgn)
{
    real colvector Wv, Yv, w, p, gvec, step, pn, gn, sc, dg, bb
    real matrix    X, Xm, Gm, Om, Hc, Vp, AA
    real scalar    n, sw, k, npar, it, cr, crn, lam, ok, j, h, conv, dec
    real scalar    nit
    real scalar    gam, beta, su, sv, sr, segam
    string rowvector cn

    Wv = st_data(., y1v, tousev)
    Yv = st_data(., y2v, tousev)
    n  = rows(Wv)
    if (xv != "") X = st_data(., tokens(xv), tousev)
    else          X = J(n, 0, .)
    Xm = J(n, 1, 1), X
    if (wv != "") w = st_data(., wv, tousev)
    else          w = J(n, 1, 1)
    w  = w * n / quadsum(w)
    sw = quadsum(w)
    k  = cols(Xm)
    npar = 5 + 2 * k

    p    = _fivz_start(Wv, Yv, Xm, w, sw, sgn)

    /* Row scaling.  The nine moments differ by orders of magnitude -- one is a
       second moment, another a fifth -- and although a square system's root is
       invariant to row scaling, the line search on ||g||^2 is not.  Scaling
       each moment by the standard deviation of its own contribution is the
       single change that turns a solver which crawls into one that reaches
       trigmm's root.                                                       */
    Hc = _fivz_h(p, Wv, Yv, Xm)
    sc = J(npar, 1, 1)
    for (j = 1; j <= npar; j++) {
        h = quadsum(w :* (Hc[., j] :- quadsum(w :* Hc[., j]) / sw):^2) / (sw - 1)
        if (h > 0) {
            sc[j] = sqrt(h)
        }
    }

    gvec = _fivz_g(p, Wv, Yv, Xm, w, sw, sc)
    cr   = gvec' * gvec
    conv = 0
    nit  = 0
    lam  = 1e-6

    /* Levenberg-Marquardt on the scaled square system */
    for (it = 1; it <= 400; it++) {
        Gm = J(npar, npar, 0)
        for (j = 1; j <= npar; j++) {
            h  = 1e-7 * max((abs(p[j]), 1))
            pn = p
            pn[j] = pn[j] + h
            gn = _fivz_g(pn, Wv, Yv, Xm, w, sw, sc)
            pn = p
            pn[j] = pn[j] - h
            Gm[., j] = (gn - _fivz_g(pn, Wv, Yv, Xm, w, sw, sc)) / (2 * h)
        }
        nit = nit + 1
        if (hasmissing(Gm)) {
            it = 401
        }
        else {
            AA = Gm' * Gm
            bb = Gm' * gvec
            dg = diagonal(AA)
            for (j = 1; j <= npar; j++) {
                if (dg[j] <= 0) {
                    dg[j] = 1
                }
            }
            ok  = 0
            dec = 0
            for (j = 1; j <= 60; j++) {
                step = lusolve(AA + lam * diag(dg), bb)
                if (hasmissing(step)) {
                    lam = min((lam * 10, 1e16))
                }
                else {
                    pn  = p - step
                    gn  = _fivz_g(pn, Wv, Yv, Xm, w, sw, sc)
                    crn = gn' * gn
                    if (hasmissing(gn)) {
                        lam = min((lam * 10, 1e16))
                    }
                    else if (crn < cr) {
                        dec  = cr - crn
                        p    = pn
                        gvec = gn
                        cr   = crn
                        lam  = max((lam / 10, 1e-16))
                        ok   = 1
                        j    = 61
                    }
                    else {
                        lam = min((lam * 10, 1e16))
                    }
                }
            }
            if (ok == 0) {
                it = 401
            }
            else if (cr < 1e-22) {
                conv = 1
                it   = 401
            }
            else if (dec < 1e-16 * max((cr, 1e-14))) {
                conv = 1
                it   = 401
            }
        }
    }
    p[2] = max((min((p[2], 30)), -30))
    p[3] = max((min((p[3], 30)), -30))
    p[4] = max((min((p[4], 30)), -30))
    p[5] = max((min((p[5], 30)), -30))

    gam  = p[1]
    beta = exp(p[2])
    su   = exp(p[3])
    sv   = exp(p[4])
    sr   = exp(p[5])

    /* Just-identified GMM sandwich.  Row scaling cancels: with G -> DG and
       Omega -> D Omega D', (G' Omega^-1 G)^-1 is unchanged, so the scaled
       Jacobian and the scaled contributions may be used directly.          */
    segam = .
    Hc = _fivz_h(p, Wv, Yv, Xm) :/ sc'
    Hc = Hc :- (quadcross(w, Hc) / sw)
    Om = _fiv_cov(Hc, w)
    if (!hasmissing(Gm)) {
        Vp = invsym(Gm' * invsym(Om + 1e-14 * I(npar)) * Gm) / n
        if (Vp[1, 1] > 0) {
            segam = sqrt(Vp[1, 1])
        }
    }

    st_matrix("__freeiv_LSZ",
        (n, (sgn < 0 ? -gam : gam), segam, (sgn < 0 ? -beta : beta),
         su, sv, sr, cr, conv, nit, npar, npar, sgn))
    cn = ("n", "lsz", "se_lsz", "lsz_beta", "lsz_var_u", "lsz_var_v",
          "lsz_var_r", "lsz_crit", "lsz_conv", "lsz_iter", "lsz_nmom",
          "lsz_npar", "lsz_sign")
    st_matrixcolstripe("__freeiv_LSZ", (J(cols(cn), 1, ""), cn'))
}

end

version 16
mata:
mata set matastrict off

/* ------------------------------------------------------------------ *
 * Brick 7a: the two tests model A cannot perform, on the twelve       *
 * moments of model B.                                                 *
 *                                                                     *
 * SCALE CONSISTENCY.  Model A imposes alpha1 = gamma1 alpha2.  With    *
 * two endogenous regressors the same statement is a1 = g2 a2 + g3 a3,  *
 * and d = a1 - (g2 a2 + g3 a3) is identically zero under it, with no   *
 * side condition.  Here a1 is free and separately identified by        *
 * Theorem 1, so d is estimable -- which is exactly what model A lacks. *
 *                                                                     *
 * ONE FACTOR.  R1 = m223/m233 equals a2/a3 under one factor with NO    *
 * side condition, but R3 = mxx2/mxx3 equals it only when V2 and V3 are *
 * symmetric (E[V2^3] = E[V3^3] = 0).  The gap R1 - R3 therefore tests  *
 * "one factor AND symmetric idiosyncratic errors" jointly, and that    *
 * must be said when it rejects.  All of this is derived in             *
 * python/verify_symbolic.py, sections 7, 7b and 7c.                    *
 * ------------------------------------------------------------------ */

real matrix _fivt_h12(real colvector e2, real colvector e3, real colvector xi)
{
    return((e2:^2, e3:^2, e2:*e3, xi:*e2, xi:*e3, e2:^2:*e3, e2:*e3:^2,
            xi:*e2:*e3, xi:*e2:^2, xi:*e3:^2, xi:^2:*e2, xi:^2:*e3))
}

real scalar _fivt_sc(real rowvector mv)
{
    real rowvector o
    o = _fivp_cf(mv[1..8])
    if (o[11] != 0) {
        return(.)
    }
    return(o[3] - (o[1] * o[4] + o[2] * o[5]))
}

real scalar _fivt_of(real rowvector mv)
{
    if (mv[7] == 0 | mv[12] == 0) {
        return(.)
    }
    return(mv[6] / mv[7] - mv[11] / mv[12])
}

void _freeiv_ptests(string scalar y1v, string scalar y2v, string scalar y3v,
                    string scalar xv, string scalar wv, string scalar tousev)
{
    real colvector y1, y2, y3, w, e2, e3, xi, z
    real matrix    X, Xm, H, Q, Qi, P, Vm, D
    real rowvector mv, up, dn, gr
    real scalar    n, sw, j, s, sc, ofv, vs, vo, ses, seo, z223, z233
    string rowvector cn

    y1 = st_data(., y1v, tousev)
    y2 = st_data(., y2v, tousev)
    y3 = st_data(., y3v, tousev)
    n  = rows(y1)
    if (xv != "") X = st_data(., tokens(xv), tousev)
    else          X = J(n, 0, .)
    Xm = J(n, 1, 1), X
    if (wv != "") w = st_data(., wv, tousev)
    else          w = J(n, 1, 1)
    w  = w * n / quadsum(w)
    sw = quadsum(w)

    e2 = _fiv_resid(y2, Xm, w)
    e3 = _fiv_resid(y3, Xm, w)
    xi = _fiv_resid(y1, Xm, w)
    H  = _fivt_h12(e2, e3, xi)
    mv = quadcross(w, H) / sw

    /* stacked influence function, three first-stage equations */
    z  = J(n, 1, 0)
    Q  = quadcross(Xm, w, Xm) / sw
    Qi = invsym(Q)
    P  = H :- mv
    D  = (2*e2, z, e3, xi, z, 2*e2:*e3, e3:^2, xi:*e3, 2*xi:*e2, z, xi:^2, z)
    P  = P - (Xm :* e2) * (Qi * (quadcross(D, w, Xm) / sw)')
    D  = (z, 2*e3, e2, z, xi, e2:^2, 2*e2:*e3, xi:*e2, z, 2*xi:*e3, z, xi:^2)
    P  = P - (Xm :* e3) * (Qi * (quadcross(D, w, Xm) / sw)')
    D  = (z, z, z, e2, e3, z, z, e2:*e3, e2:^2, e3:^2, 2*xi:*e2, 2*xi:*e3)
    P  = P - (Xm :* xi) * (Qi * (quadcross(D, w, Xm) / sw)')
    Vm = _fiv_cov(P, w)

    sc  = _fivt_sc(mv)
    ofv = _fivt_of(mv)

    ses = .
    if (sc < .) {
        gr = J(1, 12, 0)
        for (j = 1; j <= 12; j++) {
            s  = 1e-6 * max((abs(mv[j]), 1))
            up = mv
            dn = mv
            up[j] = up[j] + s
            dn[j] = dn[j] - s
            gr[j] = (_fivt_sc(up) - _fivt_sc(dn)) / (2 * s)
        }
        if (!hasmissing(gr)) {
            vs = (gr * Vm * gr') / n
            if (vs > 0) {
                ses = sqrt(vs)
            }
        }
    }

    seo = .
    if (ofv < .) {
        gr = J(1, 12, 0)
        gr[6]  =  1 / mv[7]
        gr[7]  = -mv[6] / mv[7]^2
        gr[11] = -1 / mv[12]
        gr[12] =  mv[11] / mv[12]^2
        vo = (gr * Vm * gr') / n
        if (vo > 0) {
            seo = sqrt(vo)
        }
    }

    /* the z of the two third-order cross-moments, as freeivmenu prints
       them: mean over sd/sqrt(n) of the product, sd with n - 1 as
       -summarize- computes it.  The one-factor verdict is read only when
       both exceed 2, since R2 and R3 divide by these moments */
    vs = quadcross(w, (H[., 6] :- mv[6]):^2) / (n - 1)
    z223 = (vs > 0 ? mv[6] / sqrt(vs / n) : .)
    vs = quadcross(w, (H[., 7] :- mv[7]):^2) / (n - 1)
    z233 = (vs > 0 ? mv[7] / sqrt(vs / n) : .)

    st_matrix("__freeiv_PT",
        (n, mv, sc, ses, (ses < . ? sc / ses : .),
         ofv, seo, (seo < . ? ofv / seo : .), z223, z233))
    cn = ("n", "t_m22", "t_m33", "t_m23", "t_mx2", "t_mx3", "t_m223",
          "t_m233", "t_mx23", "t_mx22", "t_mx33", "t_mxx2", "t_mxx3",
          "sc_d", "se_sc", "z_sc", "of_d", "se_of", "z_of",
          "z_m223", "z_m233")
    st_matrixcolstripe("__freeiv_PT", (J(cols(cn), 1, ""), cn'))
}

end

version 16
mata:
mata set matastrict off

/* ------------------------------------------------------------------ *
 * Brick 7b: the over-identified GMM of ARAARP4 on model B.            *
 * Sixteen moments of orders two and three for twelve parameters       *
 * (g2, g3, a1, a2, a3, mu, s1, s2, s3, k1, k2, k3, where mu = E[U^3]  *
 * and k_j = E[V_j^3]), hence four over-identifying restrictions and a *
 * J with 4 df.                                                         *
 *                                                                     *
 * The start is the closed form of Theorem 1, deterministic, and the    *
 * weighting scales each moment by its own dispersion, so the criterion *
 * is well conditioned from the outset -- the row-scaling lesson of the *
 * LSZ port is already built into the weight matrix here.               *
 * ------------------------------------------------------------------ */

real matrix _fivq_h16(real colvector e2, real colvector e3, real colvector xi)
{
    return((e2:^2, e3:^2, e2:*e3, xi:*e2, xi:*e3, xi:^2,
            e2:^3, e3:^3, e2:^2:*e3, e2:*e3:^2,
            xi:*e2:^2, xi:*e3:^2, xi:*e2:*e3,
            xi:^2:*e2, xi:^2:*e3, xi:^3))
}

real colvector _fivq_model16(real colvector p)
{
    real scalar g2, g3, a1, a2, a3, mu, s1, s2, s3, k1, k2, k3, c
    g2 = p[1]; g3 = p[2]; a1 = p[3]; a2 = p[4]; a3 = p[5]; mu = p[6]
    s1 = p[7]; s2 = p[8]; s3 = p[9]; k1 = p[10]; k2 = p[11]; k3 = p[12]
    c  = g2 * a2 + g3 * a3 + a1
    return((a2^2 + s2 \ a3^2 + s3 \ a2 * a3 \
            c * a2 + g2 * s2 \ c * a3 + g3 * s3 \
            c^2 + g2^2 * s2 + g3^2 * s3 + s1 \
            a2^3 * mu + k2 \ a3^3 * mu + k3 \
            a2^2 * a3 * mu \ a2 * a3^2 * mu \
            c * a2^2 * mu + g2 * k2 \ c * a3^2 * mu + g3 * k3 \
            c * a2 * a3 * mu \
            c^2 * a2 * mu + g2^2 * k2 \ c^2 * a3 * mu + g3^2 * k3 \
            c^3 * mu + g2^3 * k2 + g3^3 * k3 + k1))
}

/* Levenberg-Marquardt on the scaled residual L'(model16(p) - m) */
real colvector _fivq_lm(real colvector p0, real colvector mv, real matrix L,
                        real scalar maxit, real rowvector info)
{
    real colvector p, rr, pn, rn, st, dg, bb
    real matrix    G, Jr, AA
    real scalar    cr, crn, lam, it, j, s, ok, dec, nit
    p   = p0
    rr  = L' * (_fivq_model16(p) - mv)
    cr  = rr' * rr
    lam = 1e-6
    nit = 0
    for (it = 1; it <= maxit; it++) {
        nit = nit + 1
        G = J(16, 12, 0)
        for (j = 1; j <= 12; j++) {
            s  = 1e-7 * max((abs(p[j]), 1))
            pn = p
            pn[j] = pn[j] + s
            rn = _fivq_model16(pn)
            pn = p
            pn[j] = pn[j] - s
            G[., j] = (rn - _fivq_model16(pn)) / (2 * s)
        }
        Jr = L' * G
        AA = Jr' * Jr
        bb = Jr' * rr
        dg = diagonal(AA)
        for (j = 1; j <= 12; j++) {
            if (dg[j] <= 0) {
                dg[j] = 1
            }
        }
        ok  = 0
        dec = 0
        for (j = 1; j <= 60; j++) {
            st = lusolve(AA + lam * diag(dg), bb)
            if (hasmissing(st)) {
                lam = min((lam * 10, 1e16))
            }
            else {
                pn  = p - st
                rn  = L' * (_fivq_model16(pn) - mv)
                crn = rn' * rn
                if (hasmissing(rn)) {
                    lam = min((lam * 10, 1e16))
                }
                else if (crn < cr) {
                    dec = cr - crn
                    p   = pn
                    rr  = rn
                    cr  = crn
                    lam = max((lam / 10, 1e-16))
                    ok  = 1
                    j   = 61
                }
                else {
                    lam = min((lam * 10, 1e16))
                }
            }
        }
        if (ok == 0) {
            it = maxit + 1
        }
        else if (dec < 1e-16 * max((cr, 1e-14))) {
            it = maxit + 1
        }
    }
    info[1] = cr
    info[2] = nit
    return(p)
}

void _freeiv_gmm16(string scalar y1v, string scalar y2v, string scalar y3v,
                   string scalar xv, string scalar wv, string scalar tousev)
{
    real colvector y1, y2, y3, w, e2, e3, xi, mv, p, se, dgv
    real matrix    X, Xm, H, Hc, S, L1, L2, G, Jr, Vq
    real rowvector o, info
    real scalar    n, sw, j, s, c0, s10, JJ, conv
    string rowvector cn

    y1 = st_data(., y1v, tousev)
    y2 = st_data(., y2v, tousev)
    y3 = st_data(., y3v, tousev)
    n  = rows(y1)
    if (xv != "") X = st_data(., tokens(xv), tousev)
    else          X = J(n, 0, .)
    Xm = J(n, 1, 1), X
    if (wv != "") w = st_data(., wv, tousev)
    else          w = J(n, 1, 1)
    w  = w * n / quadsum(w)
    sw = quadsum(w)

    e2 = _fiv_resid(y2, Xm, w)
    e3 = _fiv_resid(y3, Xm, w)
    xi = _fiv_resid(y1, Xm, w)
    H  = _fivq_h16(e2, e3, xi)
    mv = (quadcross(w, H) / sw)'
    Hc = H :- mv'
    /* the sample covariance (sw - 1), or the design-based one under
       pweights or vce(svy)                                          */
    if (findexternal("__fiv_vdesign") == NULL)
        S = quadcross(Hc, w, Hc) / (sw - 1) + 1e-12 * I(16)
    else
        S = _fiv_cov(Hc, w) + 1e-12 * I(16)

    /* start: the closed form of Theorem 1 */
    o = _fivp_cf((_fiv_m(e2:^2, w, sw), _fiv_m(e3:^2, w, sw),
                  _fiv_m(e2:*e3, w, sw), _fiv_m(xi:*e2, w, sw),
                  _fiv_m(xi:*e3, w, sw), _fiv_m(e2:^2:*e3, w, sw),
                  _fiv_m(e2:*e3:^2, w, sw), _fiv_m(xi:*e2:*e3, w, sw)))
    cn = ("n", "q_J", "q_pJ", "q_df", "q_conv", "q_iter",
          "q_g2", "q_g3", "q_a1", "q_a2", "q_a3", "q_mu3",
          "q_s1", "q_s2", "q_s3", "q_k1", "q_k2", "q_k3",
          "q_se_g2", "q_se_g3", "q_se_a1", "q_se_a2", "q_se_a3", "q_se_mu3",
          "q_se_s1", "q_se_s2", "q_se_s3", "q_se_k1", "q_se_k2", "q_se_k3")
    /* no closed form to start from, or a design whose variance is missing
       (a stratum with a single PSU): no weight, no GMM */
    if (o[11] != 0 | hasmissing(S)) {
        st_matrix("__freeiv_Q16", (n, J(1, 29, .)))
        st_matrixcolstripe("__freeiv_Q16", (J(cols(cn), 1, ""), cn'))
        return
    }
    c0  = o[1] * o[4] + o[2] * o[5] + o[3]
    s10 = max((_fiv_m(xi:^2, w, sw) - o[1]^2 * o[7] - o[2]^2 * o[8] - c0^2, 0.05))
    p   = (o[1] \ o[2] \ o[3] \ o[4] \ o[5] \ o[6] \ s10 \ o[7] \ o[8] \ 0 \ 0 \ 0)

    /* step one: diagonal weight; step two: the efficient weight */
    dgv = J(16, 1, 1)
    for (j = 1; j <= 16; j++) {
        if (S[j, j] > 0) {
            dgv[j] = 1 / sqrt(S[j, j])
        }
    }
    L1 = diag(dgv)
    info = J(1, 2, .)
    p  = _fivq_lm(p, mv, L1, 200, info)
    L2 = cholesky(invsym(S))
    p  = _fivq_lm(p, mv, L2, 200, info)

    JJ   = n * info[1]
    conv = (info[1] < . ? 1 : 0)

    /* standard errors: (G' S^-1 G)^-1 / n */
    G = J(16, 12, 0)
    for (j = 1; j <= 12; j++) {
        s = 1e-7 * max((abs(p[j]), 1))
        Jr = p
        Jr[j] = Jr[j] + s
        G[., j] = (_fivq_model16(Jr) - _fivq_model16(p - (Jr - p))) / (2 * s)
    }
    Vq = invsym(G' * invsym(S) * G) / n
    se = J(12, 1, .)
    for (j = 1; j <= 12; j++) {
        if (Vq[j, j] > 0) {
            se[j] = sqrt(Vq[j, j])
        }
    }

    st_matrix("__freeiv_Q16",
        (n, JJ, chi2tail(4, JJ), 4, conv, info[2], p', se'))
    st_matrixcolstripe("__freeiv_Q16", (J(cols(cn), 1, ""), cn'))
}

end

version 16
mata:
mata set matastrict off

/* ------------------------------------------------------------------ *
 * Brick 6c: the JOINT nine-moment GMM of ARAARP3 v7.                  *
 *                                                                     *
 * Nine residuals in eight free parameters                             *
 *     p = (gamma, theta, sV1, sV2, A, B, A4, B4),                     *
 * so one over-identifying restriction and a J with 1 df.  This is the *
 * estimator of the paper; method(pgmm) is the profiled variant, which *
 * sets h1..h5 to zero exactly and is a DIFFERENT estimator.           *
 *                                                                     *
 * How it is minimised.  Fix gamma AND theta: the only non-linearity   *
 * left is the product theta*sV2, and fixing theta removes it, so the  *
 * nine residuals become LINEAR in the six remaining parameters,       *
 *     h = c(gamma,theta) - D(gamma,theta) * (sV1,sV2,A,B,A4,B4)'.     *
 * The eight-parameter problem is therefore a two-dimensional profile  *
 * with a bounded linear least squares step at each node, and a two-   *
 * dimensional surface can be gridded.  We grid it and refine.  There  *
 * is no seed and no starting value: the same data give the same       *
 * number.  Multi-start over the eight parameters does NOT: it returns *
 * a local minimum on most of the datasets of the paper.               *
 * ------------------------------------------------------------------ */

/* the nine moments the paper uses, in its own order, out of freeiv's ten */
real rowvector _fivj_q(real rowvector mv)
{
    return((mv[1], mv[2], mv[3], mv[4], mv[5], mv[6], mv[8], mv[9], mv[10]))
}

real colvector _fivj_c(real rowvector q, real scalar g, real scalar th)
{
    return((q[1] - th \
            q[2] - g * (q[1] + th) \
            q[3] - g^2 * q[1] - 3 * g^2 * th \
            q[4] \
            q[5] - g * q[4] \
            q[6] - g^2 * q[4] \
            q[7] \
            q[8] \
            q[9]))
}

real matrix _fivj_D(real rowvector q, real scalar g, real scalar th)
{
    real matrix D
    D = J(9, 6, 0)
    D[1, 2] = 1
    D[3, 1] = 1
    D[4, 3] = 1
    D[4, 4] = 1
    D[5, 3] = g
    D[6, 3] = 3 * g^2
    D[7, 2] = 6 * th
    D[7, 5] = 1
    D[7, 6] = 1
    D[8, 2] = 9 * g * th
    D[8, 5] = 2 * g
    D[8, 6] = g
    D[9, 1] = q[1]
    D[9, 2] = 13 * g^2 * th
    D[9, 5] = 4 * g^2
    D[9, 6] = g^2
    return(D)
}

/* Bounded least squares by a small active set: solve on the free
   coordinates, clamp whichever bound is most violated, repeat.  Six
   coordinates, so this ends in at most six passes.                    */
real colvector _fivj_bls(real matrix D, real colvector c, real matrix W,
                         real colvector bl, real colvector bu)
{
    real colvector p, act, sub, viol, sol
    real matrix    Df, M
    real scalar    i, k, worst, wi, nf, ii
    real rowvector fr
    act = J(6, 1, 0)
    p   = J(6, 1, 0)
    for (k = 1; k <= 7; k++) {
        nf = 0
        fr = J(1, 6, 0)
        for (i = 1; i <= 6; i++) {
            if (act[i] == 0) {
                nf = nf + 1
                fr[nf] = i
            }
        }
        if (nf == 0) return(p)
        Df = J(9, nf, 0)
        for (i = 1; i <= nf; i++) Df[., i] = D[., fr[i]]
        /* residual of the clamped part */
        sub = c
        for (i = 1; i <= 6; i++) {
            if (act[i] != 0) sub = sub - D[., i] * p[i]
        }
        M = Df' * W * Df
        /* lusolve returns missing on a singular system, which is the test
           that matters here; det() underflows to zero on well-scaled
           matrices and would reject good nodes.                          */
        sol = lusolve(M, Df' * W * sub)
        if (missing(sol)) return(J(6, 1, .))
        for (i = 1; i <= nf; i++) {
            ii = fr[i]
            p[ii] = sol[i]
        }
        viol  = J(6, 1, 0)
        for (i = 1; i <= 6; i++) {
            if (act[i] == 0) {
                if (p[i] < bl[i]) viol[i] = bl[i] - p[i]
                if (p[i] > bu[i]) viol[i] = p[i] - bu[i]
            }
        }
        worst = max(viol)
        if (worst <= 0) return(p)
        wi = 1
        for (i = 1; i <= 6; i++) if (viol[i] == worst) wi = i
        p[wi]   = (p[wi] < bl[wi] ? bl[wi] : bu[wi])
        act[wi] = 1
    }
    return(p)
}

/* criterion at one node; writes the six solved parameters into pout */
real scalar _fivj_at(real rowvector q, real scalar g, real scalar th,
                     real matrix W, real colvector bl, real colvector bu,
                     real colvector pout)
{
    real colvector c, p, h
    real matrix D
    c = _fivj_c(q, g, th)
    D = _fivj_D(q, g, th)
    p = _fivj_bls(D, c, W, bl, bu)
    if (missing(p)) {
        pout = J(6, 1, .)
        return(1e300)
    }
    h = c - D * p
    pout = p
    return((h' * W * h))
}

/* grid then refine, in (gamma, log theta), never leaving the box */
real rowvector _fivj_min(real rowvector q, real matrix W,
                         real scalar lo, real scalar hi,
                         real scalar tlo, real scalar thi,
                         real colvector bl, real colvector bu,
                         real colvector pout)
{
    real scalar i, j, k, ng, nt, gg, tt, v, bv, bg, bt, a, b, c2, d2, step, ls, hs
    real colvector p
    ng = 80
    nt = 80
    bv = 1e300
    bg = lo
    bt = tlo
    ls = log(tlo)
    hs = log(thi)
    for (i = 1; i <= ng; i++) {
        gg = lo + (hi - lo) * (i - 1) / (ng - 1)
        for (j = 1; j <= nt; j++) {
            tt = exp(ls + (hs - ls) * (j - 1) / (nt - 1))
            v  = _fivj_at(q, gg, tt, W, bl, bu, p)
            if (v < bv) {
                bv = v
                bg = gg
                bt = tt
                pout = p
            }
        }
    }
    /* six refinement passes, each shrinking the window by eight */
    a = lo
    b = hi
    c2 = ls
    d2 = hs
    for (i = 1; i <= 6; i++) {
        step = (b - a) / 8
        a = max((lo, bg - step))
        b = min((hi, bg + step))
        step = (d2 - c2) / 8
        c2 = max((ls, log(bt) - step))
        d2 = min((hs, log(bt) + step))
        for (j = 1; j <= 21; j++) {
            gg = a + (b - a) * (j - 1) / 20
            for (k = 1; k <= 21; k++) {
                tt = exp(c2 + (d2 - c2) * (k - 1) / 20)
                v  = _fivj_at(q, gg, tt, W, bl, bu, p)
                if (v < bv) {
                    bv = v
                    bg = gg
                    bt = tt
                    pout = p
                }
            }
        }
    }
    return((bv, bg, bt))
}

/* dh/dm, 9x9.  Not the identity: h2, h3, h5, h6 and h9 carry observed
   moments on the model side as well.                                  */
real matrix _fivj_Jm(real rowvector q, real scalar g, real scalar sV1)
{
    real matrix Jm
    Jm = I(9)
    Jm[2, 1] = -g
    Jm[3, 1] = -g^2
    Jm[5, 4] = -g
    Jm[6, 4] = -g^2
    Jm[9, 1] = -sV1
    return(Jm)
}

/* dh/dp, 9x8, p = (g, th, sV1, sV2, A, B, A4, B4) */
real matrix _fivj_G(real rowvector q, real colvector p)
{
    real matrix G
    real scalar g, th, sV1, sV2, A, B, A4, B4, ts
    g = p[1]
    th = p[2]
    sV1 = p[3]
    sV2 = p[4]
    A = p[5]
    B = p[6]
    A4 = p[7]
    B4 = p[8]
    ts = th * sV2
    G = J(9, 8, 0)
    G[1, 2] = -1
    G[1, 4] = -1
    G[2, 1] = -(q[1] + th)
    G[2, 2] = -g
    G[3, 1] = -(2 * g * q[1] + 6 * g * th)
    G[3, 2] = -3 * g^2
    G[3, 3] = -1
    G[4, 5] = -1
    G[4, 6] = -1
    G[5, 1] = -(A + q[4])
    G[5, 5] = -g
    G[6, 1] = -2 * g * (3 * A + q[4]); G[6, 5] = -3 * g^2
    G[7, 2] = -6 * sV2
    G[7, 4] = -6 * th
    G[7, 7] = -1
    G[7, 8] = -1
    G[8, 1] = -(2 * A4 + 9 * ts + B4); G[8, 2] = -9 * g * sV2
    G[8, 4] = -9 * g * th
    G[8, 7] = -2 * g
    G[8, 8] = -g
    G[9, 1] = -2 * g * (4 * A4 + 13 * ts + B4)
    G[9, 2] = -13 * g^2 * sV2
    G[9, 3] = -q[1]
    G[9, 4] = -13 * g^2 * th
    G[9, 7] = -4 * g^2
    G[9, 8] = -g^2
    return(G)
}

/* one place builds the returned matrix, so the two exits cannot drift */
void _fivj_post(real scalar n, real scalar g, real scalar se, real scalar JJ,
                real scalar th, real colvector pp, real scalar kurt,
                real scalar arlo, real scalar arhi, real scalar arfrac,
                real scalar weak, real scalar bnd,
                real scalar lo, real scalar hi)
{
    real rowvector r
    string rowvector cn
    r = J(1, 21, 0)
    r[1]  = n
    r[2]  = g
    r[3]  = se
    r[4]  = JJ
    r[5]  = chi2tail(1, JJ)
    r[6]  = 1
    r[7]  = th
    r[8]  = pp[4]
    r[9]  = pp[3]
    r[10] = pp[5]
    r[11] = pp[6]
    r[12] = pp[7]
    r[13] = pp[8]
    r[14] = kurt
    r[15] = arlo
    r[16] = arhi
    r[17] = arfrac
    r[18] = weak
    r[19] = bnd
    r[20] = lo
    r[21] = hi
    st_matrix("__freeiv_G9", r)
    cn = J(1, 21, "")
    cn[1]  = "n"
    cn[2]  = "g_gmm"
    cn[3]  = "se_gmm"
    cn[4]  = "J_gmm"
    cn[5]  = "p_gmm"
    cn[6]  = "df_gmm"
    cn[7]  = "gmm_theta"
    cn[8]  = "gmm_sV2"
    cn[9]  = "gmm_sV1"
    cn[10] = "gmm_A"
    cn[11] = "gmm_B"
    cn[12] = "gmm_A4"
    cn[13] = "gmm_B4"
    cn[14] = "gmm_kurt"
    cn[15] = "ar_lo"
    cn[16] = "ar_hi"
    cn[17] = "ar_frac"
    cn[18] = "gmm_weak"
    cn[19] = "gmm_bound"
    cn[20] = "g_lo"
    cn[21] = "g_hi"
    st_matrixcolstripe("__freeiv_G9", (J(21, 1, ""), cn'))
}

void _freeiv_jgmm(string scalar y1v, string scalar y2v, string scalar xv,
                  string scalar wv, string scalar tousev, real scalar doar)
{
    real colvector y1, y2, w, xi, e2, p6, pp, bl, bu, prof
    real matrix    X, Pinf, Vm, W, Jm, G, V
    real rowvector mv, q, o
    real scalar    n, sw, gt, lo, hi, tlo, thi, eps, cc
    real scalar    g, th, JJ, i, j, bv, v, Jmin, ng, nt, arlo, arhi
    real scalar    se, kurt, weak, bnd
    real scalar    k, gg, ls, hs, st, bj, c0, wd, bc, tt

    y1 = st_data(., y1v, tousev)
    y2 = st_data(., y2v, tousev)
    n  = rows(y1)
    if (xv != "") X = st_data(., tokens(xv), tousev)
    else          X = J(n, 0, .)
    X = J(n, 1, 1), X
    if (wv != "") w = st_data(., wv, tousev)
    else          w = J(n, 1, 1)
    w  = w * n / quadsum(w)
    sw = quadsum(w)

    xi = _fiv_resid(y1, X, w)
    e2 = _fiv_resid(y2, X, w)
    mv = (_fiv_m(e2:^2, w, sw), _fiv_m(xi:*e2, w, sw), _fiv_m(xi:^2, w, sw),
          _fiv_m(e2:^3, w, sw), _fiv_m(xi:*e2:^2, w, sw),
          _fiv_m(xi:^2:*e2, w, sw), _fiv_m(xi:^3, w, sw),
          _fiv_m(e2:^4, w, sw), _fiv_m(xi:*e2:^3, w, sw),
          _fiv_m(xi:^2:*e2:^2, w, sw))
    q  = _fivj_q(mv)
    cc = sw / (sw - 1)
    gt = (mv[2] * cc) / (mv[1] * cc)
    eps = 1e-6 * max((abs(gt), 1))
    if (gt >= 0) {
        lo = gt / 2 + eps
        hi = gt - eps
    }
    else {
        lo = gt + eps
        hi = gt / 2 - eps
    }
    tlo = 0.001
    thi = 100 * q[1]

    /* influence-function variance of the nine moments */
    Pinf = _fiv_infl(xi, e2, X, w, mv)
    Pinf = Pinf[., (1, 2, 3, 4, 5, 6, 8, 9, 10)]
    Vm   = _fiv_cov(Pinf, w)

    /* a design whose variance is missing (a stratum with a single PSU under
       singleunit(missing)) leaves the weight matrix undefined: no estimate,
       missing values rather than the first point of a grid nothing ranks */
    if (hasmissing(Vm)) {
        _fivj_post(n, ., ., ., ., J(8, 1, .), ., ., ., ., ., ., lo, hi)
        return
    }

    bl = (0.001 \ 0.001 \ -1000 \ -1000 \ 0.001 \ 0.001)
    bu = (100 * q[3] \ 100 * q[1] \ 1000 \ 1000 \ 10000 \ 10000)

    /* step one: weight by the moment variance itself */
    W  = invsym(Vm + 1e-12 * I(9))
    p6 = J(6, 1, .)
    o  = _fivj_min(q, W, lo, hi, tlo, thi, bl, bu, p6)
    g = o[2]
    th = o[3]
    /* step two: Omega = (dh/dm) Vm (dh/dm)' at the step-one estimate */
    Jm = _fivj_Jm(q, g, p6[1])
    W  = invsym(Jm * Vm * Jm' + 1e-12 * I(9))
    o  = _fivj_min(q, W, lo, hi, tlo, thi, bl, bu, p6)
    g = o[2]
    th = o[3]
    JJ = n * o[1]

    pp = (g \ th \ p6[1] \ p6[2] \ p6[3] \ p6[4] \ p6[5] \ p6[6])
    G  = _fivj_G(q, pp)
    V  = invsym(G' * W * G + 1e-12 * I(8)) / n
    se = (V[1,1] > 0 ? sqrt(V[1,1]) : .)
    kurt = (th > 0.05 ? pp[7] / th^2 : .)
    weak = (th < 0.05)
    bnd = 0
    if (abs(g - lo)  < 1e-5 * max((abs(hi), 1))) bnd = 1
    if (abs(g - hi)  < 1e-5 * max((abs(hi), 1))) bnd = 1
    if (abs(th - tlo) < 1e-9)                    bnd = 1

    /* the profile-J region: profile J over gamma, keep the values within
       3.84 of the minimum.  It rests on no standard error, which the
       boundary leaves undefined, and its share of the interval shows how
       flat the criterion is.                                            */
    arlo = .
    arhi = .
    if (doar == 0) {
        _fivj_post(n, g, se, JJ, th, pp, kurt, arlo, arhi, ., weak, bnd,
                   lo, hi)
        return
    }
    /* 1.0.0: the profile at each gamma was the minimum over a grid of 120
       values of log theta, about 15% apart, with no refinement, while the
       point is refined.  Where the criterion is flat that is enough; where
       it is steep (large n, strong identification) the grid overstated the
       profile unevenly, and the region came out narrower than the standard
       error says and could miss the estimate itself (n = 100,000: gamma
       0.4007 outside [0.4014, 0.4048]).  Now each gamma refines log theta
       as the point does, four passes of ten steps, each window a fifth of
       the last, the minimum is the J of the estimate when that is lower,
       and the estimate belongs to its own region.                         */
    ng = 241
    nt = 120
    prof = J(ng, 1, .)
    ls = log(tlo)
    hs = log(thi)
    st = (hs - ls) / (nt - 1)
    for (i = 1; i <= ng; i++) {
        gg = lo + (hi - lo) * (i - 1) / (ng - 1)
        bv = 1e300
        bj = 1
        for (j = 1; j <= nt; j++) {
            v = _fivj_at(q, gg, exp(ls + st * (j - 1)), W, bl, bu, p6)
            if (v < bv) {
                bv = v
                bj = j
            }
        }
        c0 = ls + st * (bj - 1)
        wd = st
        for (k = 1; k <= 4; k++) {
            bc = c0
            for (j = -5; j <= 5; j++) {
                if (j == 0) continue
                tt = c0 + wd * j / 5
                if (tt < ls | tt > hs) continue
                v = _fivj_at(q, gg, exp(tt), W, bl, bu, p6)
                if (v < bv) {
                    bv = v
                    bc = tt
                }
            }
            c0 = bc
            wd = wd / 5
        }
        prof[i] = n * bv
    }
    Jmin = min(prof)
    if (JJ < Jmin) Jmin = JJ
    for (i = 1; i <= ng; i++) {
        if (prof[i] - Jmin <= 3.841459) {
            v = lo + (hi - lo) * (i - 1) / (ng - 1)
            if (arlo >= .) arlo = v
            arhi = v
        }
    }
    if (JJ - Jmin <= 3.841459) {
        if (arlo >= . | g < arlo) arlo = g
        if (arhi >= . | g > arhi) arhi = g
    }

    _fivj_post(n, g, se, JJ, th, pp, kurt, arlo, arhi,
               (arhi - arlo) / (hi - lo), weak, bnd, lo, hi)
}

end
