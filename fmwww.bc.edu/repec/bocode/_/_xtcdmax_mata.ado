*! _xtcdmax_mata  version 1.0.0  21oct2026
*! Mata engine for xtcdmax. Loaded on demand with -do- by _xtcdmax_load; not a command.

mata:
mata set matastrict off

real scalar xcd_loaded()
{
    return(100)
}

real scalar xcd_gumbelp(real scalar y)
{
    if (y >= .) return(.)
    return(1 - exp(-exp(-y / 2) / sqrt(8 * pi())))
}

// T x N matrix of the variable (missing where unobserved); data sorted by id, time
real matrix xcd_wide(real colvector e, real colvector id, real colvector tm,
                     real colvector uid, real colvector utm)
{
    real matrix E
    real scalar r, i, t
    E = J(rows(utm), rows(uid), .)
    for (r = 1; r <= rows(e); r++) {
        i = xcd_find(uid, id[r])
        t = xcd_find(utm, tm[r])
        E[t, i] = e[r]
    }
    return(E)
}

// position of v in the sorted vector u (binary search)
real scalar xcd_find(real colvector u, real scalar v)
{
    real scalar lo, hi, mid
    lo = 1; hi = rows(u)
    while (lo < hi) {
        mid = floor((lo + hi) / 2)
        if (u[mid] < v) lo = mid + 1
        else hi = mid
    }
    return(lo)
}

// autocorrelations 1..M of a demeaned, unit-length series
real rowvector xcd_acf(real colvector v, real scalar M)
{
    real rowvector a
    real scalar h, T
    T = rows(v)
    a = J(1, M, 0)
    for (h = 1; h <= M; h++) {
        if (h < T) a[h] = v[|h+1 \ T|]' * v[|1 \ T-h|]
    }
    return(a)
}

// main: returns (in the Stata matrix res) one row:
//  1 N  2 T  3 pairs  4 CD  5 pCD  6 CDlr  7 pCDlr  8 MAXlr  9 pMAXlr  10 FISHERlr  11 pFISHERlr
// 12 SN 13 pSN 14 balanced 15 M 16 id_i 17 id_j 18 rho_ij at the max 19 mean |rho| 20 T_min pair
void xcd_run(string scalar ev, string scalar idv, string scalar tv, string scalar touse,
             real scalar Min, real scalar mint, string scalar resname)
{
    real colvector e, id, tm, uid, utm, mk, a, b, rho, Tij, z, ii, jj
    real matrix E, V, C, A, LR, U, S, St, Uh, th, keep, den
    real rowvector w, ra, rb
    real scalar N, T, i, j, k, np, t, M, lr, CD, CDlr, c, MAXlr, pm, pc, F, bal
    real scalar SN, s2, zS, MAX, Teff, Fw, pS, pM, trS, PN, thr, q, best
    real colvector ws, aa, bb, dS
    e  = st_data(., ev, touse)
    id = st_data(., idv, touse)
    tm = st_data(., tv, touse)
    uid = uniqrows(id)
    utm = uniqrows(tm)
    E = xcd_wide(e, id, tm, uid, utm)
    // drop units with too few observations
    keep = (colnonmissing(E) :>= mint)
    E = select(E, keep)
    uid = select(uid, keep')
    N = cols(E); T = rows(E)
    bal = (missing(E) == 0)
    k = N * (N - 1) / 2
    rho = J(k, 1, .); Tij = J(k, 1, .); z = J(k, 1, .); ii = J(k, 1, .); jj = J(k, 1, .)
    np = 0
    if (bal) {
        V = E :- mean(E)
        V = V :/ sqrt(colsum(V:^2))
        C = V' * V
        M = (Min < . ? Min : floor(4 * (T / 100)^(2/9)))
        LR = J(N, N, 1)
        if (M > 0) {
            A = J(N, M, 0)
            for (i = 1; i <= N; i++) A[i, .] = xcd_acf(V[., i], M)
            w = 1 :- (1..M) / (M + 1)
            LR = 1 :+ 2 * (A :* w) * A'
        }
        LR = LR :* (LR :>= 0.1) + 0.1 * (LR :< 0.1)
        for (i = 1; i < N; i++) {
            for (j = i + 1; j <= N; j++) {
                np++
                rho[np] = C[i, j]; Tij[np] = T
                z[np] = sqrt(T) * C[i, j] / sqrt(LR[i, j])
                ii[np] = i; jj[np] = j
            }
        }
    }
    else {
        M = Min
        for (i = 1; i < N; i++) {
            for (j = i + 1; j <= N; j++) {
                mk = (E[., i] :< .) :& (E[., j] :< .)
                t = sum(mk)
                if (t < mint) continue
                a = select(E[., i], mk); b = select(E[., j], mk)
                a = a :- mean(a); b = b :- mean(b)
                a = a / sqrt(a' * a); b = b / sqrt(b' * b)
                np++
                rho[np] = a' * b; Tij[np] = t
                q = (Min < . ? Min : floor(4 * (t / 100)^(2/9)))
                lr = 1
                if (q > 0) {
                    ra = xcd_acf(a, q); rb = xcd_acf(b, q)
                    lr = 1 + 2 * sum((1 :- (1..q) / (q + 1)) :* ra :* rb)
                }
                if (lr < 0.1) lr = 0.1
                z[np] = sqrt(t) * rho[np] / sqrt(lr)
                ii[np] = i; jj[np] = j
            }
        }
        if (np < 1) {
            st_matrix(resname, J(1, 20, .))
            return
        }
        rho = rho[|1 \ np|]; Tij = Tij[|1 \ np|]; z = z[|1 \ np|]
        ii = ii[|1 \ np|]; jj = jj[|1 \ np|]
    }
    if (np < 1) {
        st_matrix(resname, J(1, 20, .))
        return
    }
    CD = sum(sqrt(Tij) :* rho) / sqrt(np)
    CDlr = sum(z) / sqrt(np)
    // max-type test: smallest pairwise p-value from the Beta(1/2, (T_ij - 2)/2) law of a
    // squared correlation, applied to the long-run standardized correlation z_ij/sqrt(T_ij),
    // with the Sidak correction for the number of pairs
    best = 1
    pmin = 1
    for (k = 1; k <= np; k++) {
        q = ibetatail(0.5, (Tij[k] - 2) / 2, min((z[k]^2 / Tij[k], 1)))
        if (q < pmin) {
            pmin = q
            best = k
        }
    }
    MAXlr = z[best]^2
    if (pmin * np < 1e-8) pm = pmin * np
    else pm = 1 - exp(np * ln(1 - pmin))
    pc = 2 * normal(-abs(CDlr))
    F = -2 * ln(max((pc, 1e-300))) - 2 * ln(max((pm, 1e-300)))
    // sum test with the variance of Wang et al.: balanced panels only
    SN = .; pS = .; zS = .
    if (bal & N > 2) {
        SN = sqrt(2 / (N * (N - 1))) * sum(rho)
        ws = rowsum(C)
        aa = rho - (ws[jj] - rho :- 1) / (N - 2)
        bb = rho - (ws[ii] - rho :- 1) / (N - 2)
        s2 = 2 / (N * (N - 1)) * sum(aa :* bb)
        zS = (s2 > 0 ? SN / sqrt(s2) : .)
        pS = (zS < . ? 1 - normal(zS) : .)
    }
    st_matrix(resname, (N, T, np, CD, 2 * normal(-abs(CD)), CDlr, pc, MAXlr, pm, F, chi2tail(4, F),
        zS, pS, bal, M, uid[ii[best]], uid[jj[best]], rho[best], mean(abs(rho)), min(Tij)))
}

// unit-by-unit OLS residuals of y on [1, X]; data sorted by id
void xcd_unitols(string scalar yv, string scalar xv, string scalar idv, string scalar touse,
                 string scalar outv)
{
    real colvector y, id, r, b
    real matrix X, info, Xg
    real scalar g
    y = st_data(., yv, touse)
    X = st_data(., xv, touse)
    id = st_data(., idv, touse)
    info = panelsetup(id, 1)
    r = J(rows(y), 1, .)
    for (g = 1; g <= rows(info); g++) {
        Xg = (J(info[g, 2] - info[g, 1] + 1, 1, 1), X[|info[g, 1], 1 \ info[g, 2], cols(X)|])
        if (rows(Xg) <= cols(Xg) + 2) continue
        b = qrsolve(Xg, y[|info[g, 1] \ info[g, 2]|])
        r[|info[g, 1] \ info[g, 2]|] = y[|info[g, 1] \ info[g, 2]|] - Xg * b
    }
    st_store(., outv, touse, r)
}

end
