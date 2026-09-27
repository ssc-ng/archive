*! cointvol_engine 0.1.0  26sep2026
*! Mata engine of the cointvol package (Johansen RRR, bootstrap VECM simulator,
*! asymptotic Johansen p-values).
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com) - github.com/merwanroudane
*!
*! Calling -cointvol_engine- simply loads this file, which compiles the Mata
*! functions below into memory.  All cointvol commands call it first.

program define cointvol_engine
    version 14.0
end

version 14.0
// module functions that use struct cv_joh must go first, otherwise the struct
// cannot be dropped; each module reloads its own engine when next called
capture mata: mata drop cva_*()
capture mata: mata drop cvr_*()
capture mata: mata drop cvk_*()
capture mata: mata drop cvg_*()
capture mata: mata drop cvd_*()
capture mata: mata drop cv_*()
capture mata: mata drop cv_joh()

mata:

string scalar cv_engine_version()
{
    return("0.1.0")
}

// ---------------------------------------------------------------------------
//  Deterministic-term builders and VECM moment matrices
//  Cases (Johansen 1996, ch. 5; Stata -vec- trend() keywords):
//    none      : Z1 = X(t-1)                Z2 = lagged dX
//    rconstant : Z1 = (X(t-1), 1)           Z2 = lagged dX
//    constant  : Z1 = X(t-1)                Z2 = (lagged dX, 1)
//    rtrend    : Z1 = (X(t-1), t)           Z2 = (lagged dX, 1)
//    trend     : Z1 = X(t-1)                Z2 = (lagged dX, 1, t)
// ---------------------------------------------------------------------------

void cv_detmats(real scalar T0, string scalar det, real matrix D1, real matrix D2)
{
    real colvector tr
    tr = (1::T0)
    D1 = J(T0, 0, .)
    D2 = J(T0, 0, .)
    if (det == "rconstant") {
        D1 = J(T0, 1, 1)
    }
    if (det == "constant") {
        D2 = J(T0, 1, 1)
    }
    if (det == "rtrend") {
        D1 = tr
        D2 = J(T0, 1, 1)
    }
    if (det == "trend") {
        D2 = (J(T0, 1, 1), tr)
    }
}

void cv_build(real matrix Y, real scalar k, real matrix D1, real matrix D2,
              real matrix Z0, real matrix Z1, real matrix Z2)
{
    real scalar T0, p, T, j
    real matrix dY
    T0 = rows(Y)
    p  = cols(Y)
    T  = T0 - k
    dY = J(1, p, 0) \ (Y[|2,1 \ T0,p|] - Y[|1,1 \ T0-1,p|])
    Z0 = dY[|k+1,1 \ T0,p|]
    Z1 = Y[|k,1 \ T0-1,p|]
    if (cols(D1) > 0) {
        Z1 = Z1, D1[|k+1,1 \ T0,cols(D1)|]
    }
    Z2 = J(T, 0, .)
    for (j = 1; j <= k-1; j = j + 1) {
        Z2 = Z2, dY[|k+1-j,1 \ T0-j,p|]
    }
    if (cols(D2) > 0) {
        Z2 = Z2, D2[|k+1,1 \ T0,cols(D2)|]
    }
}

// ---------------------------------------------------------------------------
//  Johansen reduced-rank regression
// ---------------------------------------------------------------------------

struct cv_joh {
    real matrix    Z0, Z1, Z2, S00, S01, S11, M22i, V
    real colvector lam
    real scalar    T, p, p1, q, ok
}

struct cv_joh scalar cv_johansen(real matrix Z0, real matrix Z1, real matrix Z2)
{
    struct cv_joh scalar J
    real matrix R0, R1, L, Li, C, X, S00i
    real rowvector ev
    real colvector idx

    J.Z0 = Z0
    J.Z1 = Z1
    J.Z2 = Z2
    J.T  = rows(Z0)
    J.p  = cols(Z0)
    J.p1 = cols(Z1)
    J.q  = cols(Z2)
    J.ok = 1
    if (J.q > 0) {
        J.M22i = invsym(cross(Z2, Z2))
        R0 = Z0 - Z2 * (J.M22i * cross(Z2, Z0))
        R1 = Z1 - Z2 * (J.M22i * cross(Z2, Z1))
    }
    else {
        J.M22i = J(0, 0, .)
        R0 = Z0
        R1 = Z1
    }
    J.S00 = cross(R0, R0) / J.T
    J.S01 = cross(R0, R1) / J.T
    J.S11 = cross(R1, R1) / J.T
    L = cholesky(J.S11)
    S00i = invsym(J.S00)
    if (hasmissing(L) | hasmissing(S00i) | diag0cnt(S00i) > 0) {
        J.ok  = 0
        J.lam = J(J.p1, 1, .)
        J.V   = J(J.p1, J.p1, .)
        return(J)
    }
    Li = solvelower(L, I(J.p1))
    C  = Li * J.S01' * S00i * J.S01 * Li'
    C  = (C + C') / 2
    symeigensystem(C, X, ev)
    idx   = order(-ev', 1)
    J.lam = ev[idx]'
    J.V   = Li' * X[., idx]
    return(J)
}

// Estimates under H(r): alpha (p x r), bstar (p1 x r), Psi (p x q), residuals E
void cv_fitrank(struct cv_joh scalar J, real scalar r, real matrix alpha,
                real matrix bstar, real matrix Psi, real matrix E, real scalar ll)
{
    real matrix Yr
    real scalar s
    if (r > 0) {
        bstar = J.V[., 1..r]
        alpha = J.S01 * bstar
        Yr    = J.Z0 - J.Z1 * bstar * alpha'
        s     = sum(ln(1 :- J.lam[1..r]))
    }
    else {
        bstar = J(J.p1, 0, .)
        alpha = J(J.p, 0, .)
        Yr    = J.Z0
        s     = 0
    }
    if (J.q > 0) {
        Psi = (J.M22i * cross(J.Z2, Yr))'
        E   = Yr - J.Z2 * Psi'
    }
    else {
        Psi = J(J.p, 0, .)
        E   = Yr
    }
    ll = -J.T/2 * (ln(det(J.S00)) + s) - J.T*J.p/2 * (1 + ln(2*pi()))
}

real scalar cv_trace(real colvector lam, real scalar r, real scalar p, real scalar T)
{
    return(-T * sum(ln(1 :- lam[r+1..p])))
}

real scalar cv_maxeig(real colvector lam, real scalar r, real scalar T)
{
    return(-T * ln(1 - lam[r+1]))
}

// ---------------------------------------------------------------------------
//  Companion matrix of the VECM implied by (Pi_x, Gamma); returns moduli
//  Pi_x is the p x p levels part of alpha*bstar'
// ---------------------------------------------------------------------------

real colvector cv_roots(real matrix Pix, real matrix G, real scalar k)
{
    real scalar p, j
    real matrix A, Cm
    complex rowvector ev
    p = rows(Pix)
    Cm = J(p*k, p*k, 0)
    // levels VAR: A1 = I + Pi + G1, Aj = Gj - G(j-1), Ak = -G(k-1)
    for (j = 1; j <= k; j = j + 1) {
        A = J(p, p, 0)
        if (j == 1) {
            A = I(p) + Pix
        }
        if (j <= k-1) {
            A = A + G[., (j-1)*p+1..j*p]
        }
        if (j >= 2) {
            A = A - G[., (j-2)*p+1..(j-1)*p]
        }
        Cm[|1,(j-1)*p+1 \ p,j*p|] = A
    }
    if (k > 1) {
        Cm[|p+1,1 \ p*k,p*(k-1)|] = I(p*(k-1))
    }
    ev = eigenvalues(Cm)
    return(sort(abs(ev)', -1))
}

// ---------------------------------------------------------------------------
//  Recursive VECM simulator (bootstrap DGP)
//    dY*(t) = Pi*(Y*(t-1)',D1(t)')' + sum_j G_j dY*(t-j) + Phi D2(t) + e*(t)
//  initialised at the first k observations of the data; iterated in the
//  equivalent levels-VAR form Y*(t) = sum_j A_j Y*(t-j) + c(t)
// ---------------------------------------------------------------------------

real matrix cv_simvecm(real matrix Yinit, real matrix Pi, real matrix Psi,
                       real matrix E, real matrix D1, real matrix D2, real scalar k)
{
    real scalar T, p, T0, t, j, nd1, nd2
    real matrix Y, C, A, Gj, Gm
    real rowvector y
    pointer(real matrix) rowvector At
    T   = rows(E)
    p   = cols(E)
    T0  = T + k
    nd1 = cols(D1)
    nd2 = cols(D2)
    Y   = J(T0, p, 0)
    Y[|1,1 \ k,p|] = Yinit
    // exogenous part: errors + deterministic terms, rows k+1..T0
    C = E
    if (nd1 > 0) {
        C = C + D1[|k+1,1 \ T0,nd1|] * Pi[., p+1..p+nd1]'
    }
    if (nd2 > 0) {
        C = C + D2[|k+1,1 \ T0,nd2|] * Psi[., p*(k-1)+1..p*(k-1)+nd2]'
    }
    // levels VAR: A1 = I + Pi_x + G1, Aj = Gj - G(j-1), Ak = -G(k-1); stored transposed
    At = J(1, k, NULL)
    for (j = 1; j <= k; j = j + 1) {
        A = J(p, p, 0)
        if (j == 1) {
            A = I(p) + Pi[., 1..p]
        }
        if (j <= k-1) {
            Gj = Psi[., (j-1)*p+1..j*p]
            A = A + Gj
        }
        if (j >= 2) {
            Gm = Psi[., (j-2)*p+1..(j-1)*p]
            A = A - Gm
        }
        At[j] = &(A')
    }
    if (k == 1) {
        A = *At[1]
        for (t = 2; t <= T0; t = t + 1) {
            Y[t,.] = Y[t-1,.] * A + C[t-1,.]
        }
        return(Y)
    }
    for (t = k+1; t <= T0; t = t + 1) {
        y = C[t-k,.] + Y[t-1,.] * (*At[1])
        for (j = 2; j <= k; j = j + 1) {
            y = y + Y[t-j,.] * (*At[j])
        }
        Y[t,.] = y
    }
    return(Y)
}

// ---------------------------------------------------------------------------
//  Wild-bootstrap multipliers
// ---------------------------------------------------------------------------

real colvector cv_mult(real scalar T, string scalar mult)
{
    real scalar a, b, pa
    if (mult == "rademacher") {
        return(2 :* (runiform(T, 1) :> 0.5) :- 1)
    }
    if (mult == "mammen") {
        a  = -(sqrt(5) - 1) / 2
        b  =  (sqrt(5) + 1) / 2
        pa =  (sqrt(5) + 1) / (2 * sqrt(5))
        return(a :+ (b - a) :* (runiform(T, 1) :> pa))
    }
    return(rnormal(T, 1, 0, 1))
}

// ---------------------------------------------------------------------------
//  Asymptotic Johansen p-values: Gamma approximation (Doornik 1998) with
//  first two moments of the limiting distributions obtained by simulation
//  (cv_asysim below; T = 1000, 20,000 replications per cell).
//  Table rows: m = p - r = 1..12. Columns: trace mean, trace var,
//  maxeig mean, maxeig var.
// ---------------------------------------------------------------------------

real matrix cv_asysim(real scalar m, string scalar det, real scalar R, real scalar T)
{
    real matrix out, e, Bm, Bl, F, D, S, Q
    real colvector ul
    real scalar i, j
    out = J(R, 2, .)
    ul  = (0::T-1) / T
    for (i = 1; i <= R; i = i + 1) {
        e  = rnormal(T, m, 0, 1)
        Bm = J(T, m, .)
        for (j = 1; j <= m; j = j + 1) {
            Bm[., j] = runningsum(e[., j])
        }
        Bl = J(1, m, 0) \ Bm[|1,1 \ T-1,m|]
        if (det == "none") {
            F = Bl
        }
        if (det == "rconstant") {
            F = Bl, J(T, 1, 1)
        }
        if (det == "constant") {
            if (m > 1) {
                F = Bl[., 1..m-1], ul
            }
            else {
                F = ul
            }
            F = F :- mean(F)
        }
        if (det == "rtrend") {
            F = Bl, ul
            F = F :- mean(F)
        }
        if (det == "trend") {
            if (m > 1) {
                F = Bl[., 1..m-1], ul:^2
            }
            else {
                F = ul:^2
            }
            D = J(T, 1, 1), ul
            F = F - D * (invsym(cross(D, D)) * cross(D, F))
        }
        S = cross(F, e)
        Q = S' * invsym(cross(F, F)) * S
        Q = (Q + Q') / 2
        out[i, 1] = trace(Q)
        out[i, 2] = max(symeigenvalues(Q))
    }
    return(out)
}

real matrix cv_asytab(string scalar det)
{
    // placeholder, replaced by the generated table (see cv_asytab_data)
    return(cv_asytab_data(det))
}

real rowvector cv_asymom(real scalar m, string scalar det)
{
    real matrix Tb
    Tb = cv_asytab(det)
    if (m < 1 | m > rows(Tb)) {
        return(J(1, 4, .))
    }
    return(Tb[m, .])
}

// which = 1 trace, 2 maxeig ; returns (p-value, 95% cv, 99% cv)
real rowvector cv_asyp(real scalar stat, real scalar m, string scalar det, real scalar which)
{
    real rowvector mo
    real scalar mu, v, a, sc
    mo = cv_asymom(m, det)
    if (which == 1) {
        mu = mo[1]
        v  = mo[2]
    }
    else {
        mu = mo[3]
        v  = mo[4]
    }
    if (missing(mu) | missing(v) | v <= 0) {
        return((., ., .))
    }
    a  = mu*mu / v
    sc = v / mu
    return((1 - gammap(a, stat/sc), invgammap(a, 0.95)*sc, invgammap(a, 0.99)*sc))
}

// ---------------------------------------------------------------------------
//  Main entry point for -cointvol rank-
// ---------------------------------------------------------------------------

void cv_rank_main(string scalar vars, string scalar touse, real scalar k,
                  string scalar det, string scalar method, string scalar algo,
                  string scalar mult, real scalar B, string scalar pvtype,
                  real scalar level, real scalar dots, string scalar rlist)
{
    struct cv_joh scalar Jd, Jb
    real matrix Y, D1, D2, Z0, Z1, Z2, alpha, bstar, Psi, E, aU, bU, PsiU, EU
    real matrix Pi, PsiB, Eb, eps, Ys, QT, QM, res, Gm
    real colvector w, rr, mods
    real scalar p, T, T0, r, ll, llU, b, i, qt, qm, fails, nexp, nunit
    real scalar m, recentre, eta, rsel_at, rsel_bt, rsel_am, rsel_bm, ntests
    real rowvector ap

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
    rr = strtoreal(tokens(rlist))'
    ntests = rows(rr)
    eta = 1 - level/100

    // columns: 1 r, 2 eig, 3 trace, 4 asy p, 5 boot p, 6 asy cv95, 7 boot cv95,
    //          8 maxeig, 9 asy p, 10 boot p, 11 asy cv95, 12 boot cv95,
    //          13 #explosive roots of H(r) bootstrap DGP, 14 #failed draws
    res = J(ntests, 14, .)
    QT  = J(B, ntests, .)
    QM  = J(B, ntests, .)
    if (method != "asy") {
        cv_fitrank(Jd, p, aU, bU, PsiU, EU, llU)
    }
    for (i = 1; i <= ntests; i = i + 1) {
        r = rr[i]
        m = p - r
        qt = cv_trace(Jd.lam, r, p, T)
        qm = cv_maxeig(Jd.lam, r, T)
        res[i, 1] = r
        res[i, 2] = Jd.lam[r+1]
        res[i, 3] = qt
        res[i, 8] = qm
        ap = cv_asyp(qt, m, det, 1)
        res[i, 4] = ap[1]
        res[i, 6] = ap[2]
        ap = cv_asyp(qm, m, det, 2)
        res[i, 9]  = ap[1]
        res[i, 11] = ap[2]
        if (method == "asy") {
            continue
        }
        // ---- bootstrap DGP under H(r) ----
        cv_fitrank(Jd, r, alpha, bstar, Psi, E, ll)
        if (r > 0) {
            Pi = alpha * bstar'
        }
        else {
            Pi = J(p, Jd.p1, 0)
        }
        recentre = 1
        if (algo == "crt10") {
            PsiB = PsiU
            Eb   = EU
            if (method == "wild") {
                recentre = 0
            }
        }
        else {
            PsiB = Psi
            Eb   = E
        }
        if (recentre) {
            Eb = Eb :- mean(Eb)
        }
        // companion roots of the bootstrap DGP
        if (k > 1) {
            Gm = PsiB[., 1..p*(k-1)]
        }
        else {
            Gm = J(p, 0, .)
        }
        mods  = cv_roots(Pi[., 1..p], Gm, k)
        nexp  = sum(mods :> 1 + 1e-6)
        res[i, 13] = nexp
        fails = 0
        if (dots) {
            printf("{txt}H0: r = %g  ", r)
            displayflush()
        }
        for (b = 1; b <= B; b = b + 1) {
            if (method == "iid") {
                eps = Eb[ceil(runiform(T, 1) :* T), .]
            }
            else {
                w   = cv_mult(T, mult)
                eps = Eb :* w
            }
            Ys = cv_simvecm(Y[|1,1 \ k,p|], Pi, PsiB, eps, D1, D2, k)
            cv_build(Ys, k, D1, D2, Z0, Z1, Z2)
            Jb = cv_johansen(Z0, Z1, Z2)
            if (Jb.ok == 0 | hasmissing(Jb.lam) | max(Jb.lam) >= 1) {
                fails = fails + 1
                if (fails > 10*B) {
                    errprintf("bootstrap failed repeatedly (explosive or singular samples)\n")
                    exit(error(430))
                }
                b = b - 1
                continue
            }
            QT[b, i] = cv_trace(Jb.lam, r, p, T)
            QM[b, i] = cv_maxeig(Jb.lam, r, T)
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
        res[i, 14] = fails
        if (pvtype == "plusone") {
            res[i, 5]  = (sum(QT[., i] :>= qt) + 1) / (B + 1)
            res[i, 10] = (sum(QM[., i] :>= qm) + 1) / (B + 1)
        }
        else {
            res[i, 5]  = mean(QT[., i] :> qt)
            res[i, 10] = mean(QM[., i] :> qm)
        }
        res[i, 7]  = cv_quantile(QT[., i], 1 - eta)
        res[i, 12] = cv_quantile(QM[., i], 1 - eta)
    }

    // sequential selection (only meaningful when r = 0..p-1 were all tested)
    rsel_at = .
    rsel_bt = .
    rsel_am = .
    rsel_bm = .
    if (ntests == p) {
        if (rr == (0::p-1)) {
            rsel_at = cv_seqsel(res[., 4], p, eta)
            rsel_am = cv_seqsel(res[., 9], p, eta)
            if (method != "asy") {
                rsel_bt = cv_seqsel(res[., 5], p, eta)
                rsel_bm = cv_seqsel(res[., 10], p, eta)
            }
        }
    }

    st_matrix("__cv_res", res)
    st_matrix("__cv_lam", Jd.lam')
    st_matrix("__cv_beta", Jd.V)
    st_numscalar("__cv_T", T)
    st_numscalar("__cv_p", p)
    st_numscalar("__cv_rat", rsel_at)
    st_numscalar("__cv_rbt", rsel_bt)
    st_numscalar("__cv_ram", rsel_am)
    st_numscalar("__cv_rbm", rsel_bm)
    if (method != "asy") {
        st_matrix("__cv_QT", QT)
        st_matrix("__cv_QM", QM)
    }
}

real scalar cv_seqsel(real colvector pv, real scalar p, real scalar eta)
{
    real scalar i
    if (hasmissing(pv)) {
        return(.)
    }
    for (i = 1; i <= p; i = i + 1) {
        if (pv[i] > eta) {
            return(i - 1)
        }
    }
    return(p)
}

real scalar cv_quantile(real colvector x, real scalar q)
{
    real colvector s
    real scalar n, j
    s = sort(select(x, x :< .), 1)
    n = rows(s)
    if (n == 0) {
        return(.)
    }
    j = ceil(q * n)
    if (j < 1) {
        j = 1
    }
    if (j > n) {
        j = n
    }
    return(s[j])
}

real matrix cv_asytab_data(string scalar det)
{
    // Moments of the limiting Johansen trace / max-eigenvalue statistics,
    // m = p - r = 1..12 (rows). Columns: trace mean, trace var, maxeig mean,
    // maxeig var. Simulated by cv_asysim (T = 1000, R = 20,000 per cell,
    // seed 20260926; dev/gen_asytab.do). Used with the Gamma approximation.
    real matrix M
    M = J(12, 4, .)
    if (det == "none") {
        M = (1.139448214, 2.202091022, 1.139448214, 2.202091022 \
             6.129758019, 10.94626587, 5.454837237, 9.388705062 \
             15.0390755, 24.85935589, 10.41743598, 15.25224832 \
             27.87958861, 45.10139218, 15.56993599, 21.33396634 \
             44.76936049, 71.46165747, 20.88761683, 26.22381114 \
             65.64336682, 104.2936091, 26.27741493, 31.08637883 \
             90.32256401, 142.189384, 31.66688573, 36.06944655 \
             119.1378376, 185.9895402, 37.11864811, 40.4369849 \
             151.5976174, 235.2414422, 42.61850906, 44.74504154 \
             188.2398555, 289.0996083, 47.99068193, 48.03017288 \
             228.4776718, 353.5880657, 53.42384521, 52.93350435 \
             272.6477051, 424.5865877, 58.92799329, 56.64019427)
    }
    if (det == "rconstant") {
        M = (4.037282303, 6.913328719, 4.037282303, 6.913328719 \
             11.93631248, 18.74237079, 8.900326248, 12.96956774 \
             23.99048357, 38.50742588, 14.13822663, 19.37684818 \
             39.85282288, 62.02154869, 19.4109146, 24.77037313 \
             59.60260099, 93.29624921, 24.66896658, 30.06770532 \
             83.35740683, 127.4281803, 30.08774931, 34.67781602 \
             111.1493997, 169.7174893, 35.60015228, 38.99569095 \
             142.6114086, 219.0513331, 40.9021242, 42.92131858 \
             178.0440439, 270.8745495, 46.3253713, 47.15374812 \
             217.4749051, 333.8561967, 51.93445667, 52.05288295 \
             260.6089564, 396.1694494, 57.26791746, 54.52675731 \
             308.053096, 471.9424393, 62.82346234, 58.43510906)
    }
    if (det == "constant") {
        M = (0.9900656931, 1.968500533, 0.9900656931, 1.968500533 \
             8.31224409, 14.31402056, 7.524808711, 12.45124754 \
             19.49564837, 32.03386692, 13.06811799, 19.04664079 \
             34.45478239, 55.39725422, 18.40448848, 24.43442848 \
             53.4525468, 83.67943778, 23.84850612, 29.61241726 \
             76.30940399, 117.8449281, 29.28080707, 33.9800035 \
             103.0506542, 156.0196889, 34.73849519, 37.95238533 \
             133.4317344, 200.2746539, 40.10486495, 43.64448616 \
             168.141584, 252.8395935, 45.60714701, 47.1811859 \
             206.2637901, 307.1187169, 50.95869225, 50.49805017 \
             248.5196956, 382.7461885, 56.55323922, 56.17729415 \
             294.4683632, 442.199382, 61.88620966, 58.33695943)
    }
    if (det == "rtrend") {
        M = (6.301307051, 10.4909919, 6.301307051, 10.4909919 \
             16.46701717, 26.28501808, 11.6822518, 17.06048442 \
             30.45592402, 46.65356012, 16.95423915, 22.21763766 \
             48.41363326, 74.01174207, 22.34508901, 27.92680615 \
             70.15781793, 105.8352665, 27.69463539, 32.46308245 \
             95.99297223, 144.3408852, 33.10778265, 37.06339082 \
             125.4722271, 187.23704, 38.54113471, 41.67657192 \
             159.0928295, 235.3814692, 44.05446033, 46.41358195 \
             196.3769607, 295.9987068, 49.43752287, 51.06329131 \
             237.4391739, 348.5711404, 54.82896473, 53.30326608 \
             282.6977785, 427.2791482, 60.36896617, 56.78080839 \
             331.7100743, 495.7529733, 65.82496036, 59.90116765)
    }
    if (det == "trend") {
        M = (1.003058077, 2.029106804, 1.003058077, 2.029106804 \
             10.35447743, 17.63673694, 9.515953648, 15.6694783 \
             23.58528011, 38.53361937, 15.47439728, 22.34304847 \
             40.68551301, 64.17555959, 21.11614312, 27.74325885 \
             61.55292691, 95.19608754, 26.57747517, 32.28428185 \
             86.46080014, 129.8751257, 32.0610078, 36.67146187 \
             115.1491369, 174.0770474, 37.58294949, 41.11084843 \
             147.8503026, 224.9627781, 43.09497188, 46.20262315 \
             184.0113322, 272.7579481, 48.49017661, 50.07219396 \
             224.3937662, 328.8181765, 53.98927673, 53.84272778 \
             268.6765236, 403.400977, 59.42104731, 57.03259649 \
             316.7129201, 467.9590224, 64.98877048, 60.866354)
    }
    return(M)
}

end
