*! _xtcollin_mata  version 1.0.0  21oct2026
*! Mata engine for xtcollin. Loaded on demand with -do- by _xtcollin_load; not a command.

mata:
mata set matastrict off

real scalar xtc_loaded()
{
    return(101)
}

// variance inflation factors; addcons = 1 adds an intercept to each auxiliary regression
real rowvector xtc_vif(real matrix X, real scalar addcons)
{
    real scalar n, k, j, sst, r2
    real matrix Z
    real colvector y, e, b
    real rowvector v
    n = rows(X); k = cols(X)
    v = J(1, k, 1)
    for (j = 1; j <= k; j++) {
        y = X[., j]
        Z = (j > 1 ? X[|1, 1 \ n, j-1|] : J(n, 0, .))
        if (j < k) Z = (Z, X[|1, j+1 \ n, k|])
        if (addcons) {
            Z = (J(n, 1, 1), Z)
            sst = sum((y :- mean(y)):^2)
        }
        else sst = y' * y
        if (cols(Z) == 0 | sst <= 0) {
            v[j] = (sst <= 0 ? . : 1)
            continue
        }
        b = qrsolve(Z, y)
        e = y - Z * b
        r2 = 1 - (e' * e) / sst
        v[j] = (r2 < 1 - 1e-14 ? 1 / (1 - r2) : .)
    }
    return(v)
}

// Belsley-Kuh-Welsch condition indices (ascending) and variance-decomposition
// proportions (rows: condition indices; columns: [_cons,] variables)
void xtc_belsley(real matrix X, real scalar addcons, real colvector ci, real matrix P)
{
    real matrix Z, U, Vt, V, phi, s
    real rowvector nrm, sv
    real colvector o
    Z = (addcons ? (J(rows(X), 1, 1), X) : X)
    nrm = sqrt(colsum(Z:^2))
    Z = Z :/ nrm
    svd(Z, U, s, Vt)
    sv = rowshape(s, 1)
    V = Vt'
    // phi[j, l] = v_jl^2 / s_l^2 ; P[l, j] = phi[j, l] / sum_l phi[j, l]
    phi = (V:^2) :/ (sv:^2)
    P = (phi :/ rowsum(phi))'
    ci = (max(sv) :/ sv)'
    o = order(ci, 1)
    ci = ci[o]
    P = P[o, .]
}

// within (one-way) transformation by unit; data sorted by unit
real matrix xtc_within(real matrix X, real colvector id)
{
    real matrix W, info
    real scalar g
    W = X
    info = panelsetup(id, 1)
    for (g = 1; g <= rows(info); g++) {
        W[|info[g, 1], 1 \ info[g, 2], cols(X)|] =
            X[|info[g, 1], 1 \ info[g, 2], cols(X)|] :- mean(X[|info[g, 1], 1 \ info[g, 2], cols(X)|])
    }
    return(W)
}

real matrix xtc_quasi(real matrix X, real colvector id, real scalar theta)
{
    real matrix W, info
    real scalar g
    W = X
    info = panelsetup(id, 1)
    for (g = 1; g <= rows(info); g++) {
        W[|info[g, 1], 1 \ info[g, 2], cols(X)|] =
            X[|info[g, 1], 1 \ info[g, 2], cols(X)|] :- theta * mean(X[|info[g, 1], 1 \ info[g, 2], cols(X)|])
    }
    return(W)
}

real matrix xtc_between(real matrix X, real colvector id)
{
    real matrix B, info
    real scalar g
    info = panelsetup(id, 1)
    B = J(rows(info), cols(X), .)
    for (g = 1; g <= rows(info); g++) B[g, .] = mean(X[|info[g, 1], 1 \ info[g, 2], cols(X)|])
    return(B)
}

// two-way within transformation by alternating projections (valid for unbalanced panels)
real matrix xtc_twoway(real matrix X, real colvector id, real colvector tm)
{
    real matrix W, old, tinfo
    real colvector o, tsort, inv
    real scalar it, g
    W = xtc_within(X, id)
    o = order(tm, 1)
    tsort = tm[o]
    tinfo = panelsetup(tsort, 1)
    inv = invorder(o)
    for (it = 1; it <= 1000; it++) {
        old = W
        W = W[o, .]
        for (g = 1; g <= rows(tinfo); g++) {
            W[|tinfo[g, 1], 1 \ tinfo[g, 2], cols(X)|] =
                W[|tinfo[g, 1], 1 \ tinfo[g, 2], cols(X)|] :- mean(W[|tinfo[g, 1], 1 \ tinfo[g, 2], cols(X)|])
        }
        W = W[inv, .]
        W = xtc_within(W, id)
        if (max(abs(W - old)) < 1e-10) break
    }
    return(W)
}

// first differences within units (consecutive periods only)
real matrix xtc_fd(real matrix X, real colvector id, real colvector tm)
{
    real matrix D
    real colvector keep
    real scalar n
    n = rows(X)
    if (n < 2) return(J(0, cols(X), .))
    keep = (id[|2 \ n|] :== id[|1 \ n-1|]) :& (tm[|2 \ n|] - tm[|1 \ n-1|] :== 1)
    D = X[|2, 1 \ n, cols(X)|] - X[|1, 1 \ n-1, cols(X)|]
    return(select(D, keep))
}

// period-by-period cross-section averages, aligned with the rows
real matrix xtc_csavg(real matrix V, real colvector tm)
{
    real matrix A, Vs, tinfo
    real colvector o, inv
    real scalar g
    o = order(tm, 1)
    Vs = V[o, .]
    tinfo = panelsetup(tm[o], 1)
    A = J(rows(V), cols(V), .)
    for (g = 1; g <= rows(tinfo); g++) {
        A[|tinfo[g, 1], 1 \ tinfo[g, 2], cols(V)|] =
            J(tinfo[g, 2] - tinfo[g, 1] + 1, 1, mean(Vs[|tinfo[g, 1], 1 \ tinfo[g, 2], cols(V)|]))
    }
    inv = invorder(o)
    return(A[inv, .])
}

// unit by unit: residuals of each column on [1, cross-section averages]
real matrix xtc_cce(real matrix X, real colvector id, real matrix Zbar)
{
    real matrix W, info, Z, Xg
    real scalar g
    W = X
    info = panelsetup(id, 1)
    for (g = 1; g <= rows(info); g++) {
        Xg = X[|info[g, 1], 1 \ info[g, 2], cols(X)|]
        Z = (J(rows(Xg), 1, 1), Zbar[|info[g, 1], 1 \ info[g, 2], cols(Zbar)|])
        W[|info[g, 1], 1 \ info[g, 2], cols(X)|] = Xg - Z * qrsolve(Z, Xg)
    }
    return(W)
}

// main routine. how: 0 none, 1 within, 2 twoway, 3 fd, 4 quasi, 5 between, 6 cce
// Results: VIF (k x 2: raw, transformed), within share (k x 1), condition indices and
// VDP of the transformed design, per-unit results (id, condition number, VIFs).
void xtc_run(string scalar xv, string scalar idv, string scalar tv, string scalar zv,
             string scalar touse, real scalar how, real scalar theta, real scalar dounits,
             real scalar nocons, string scalar outnames)
{
    real matrix X, W, P, Zbar, info, U, Xg, Z
    real colvector id, tm, ci, cig
    real rowvector vr, vt, ws
    real scalar k, c, g, Ti
    real matrix Pg
    string rowvector on
    on = tokens(outnames)
    X = st_data(., xv, touse)
    k = cols(X)
    if (idv != "") id = st_data(., idv, touse)
    if (tv  != "") tm = st_data(., tv, touse)
    vr = xtc_vif(X, !nocons)
    if (how == 0) {
        W = X
        c = !nocons
    }
    else if (how == 1) {
        W = xtc_within(X, id); c = 0
    }
    else if (how == 2) {
        W = xtc_twoway(X, id, tm); c = 0
    }
    else if (how == 3) {
        W = xtc_fd(X, id, tm); c = !nocons
    }
    else if (how == 4) {
        W = xtc_quasi(X, id, theta); c = 1
    }
    else if (how == 5) {
        W = xtc_between(X, id); c = 1
    }
    else {
        Zbar = xtc_csavg(st_data(., zv, touse), tm)
        W = xtc_cce(X, id, Zbar); c = 0
    }
    vt = xtc_vif(W, c)
    xtc_belsley(W, c, ci, P)
    st_matrix(on[1], (vr' , vt'))
    st_matrix(on[2], ci)
    st_matrix(on[3], P)
    st_numscalar(on[4], rows(W))
    st_numscalar(on[5], c)
    xtc_belsley(X, !nocons, cig, Pg)
    st_numscalar(on[6], max(cig))
    st_numscalar(on[7], max(ci))
    if (idv != "") {
        Xg = xtc_within(X, id)
        ws = colsum(Xg:^2) :/ colsum((X :- mean(X)):^2)
        st_matrix(on[8], ws')
    }
    if (dounits & idv != "") {
        info = panelsetup(id, 1)
        if (how == 6 & rows(Zbar) == 0) Zbar = xtc_csavg(st_data(., zv, touse), tm)
        U = J(rows(info), 2 + k, .)
        for (g = 1; g <= rows(info); g++) {
            Xg = X[|info[g, 1], 1 \ info[g, 2], k|]
            Ti = rows(Xg)
            U[g, 1] = id[info[g, 1]]
            if (how == 6) {
                Z = (J(Ti, 1, 1), Zbar[|info[g, 1], 1 \ info[g, 2], cols(Zbar)|])
                if (Ti <= cols(Z) + k) continue
                Xg = Xg - Z * qrsolve(Z, Xg)
                U[|g, 3 \ g, 2 + k|] = xtc_vif(Xg, 0)
                xtc_belsley(Xg, 0, cig, Pg)
            }
            else {
                if (Ti <= k + 1) continue
                U[|g, 3 \ g, 2 + k|] = xtc_vif(Xg, 1)
                xtc_belsley(Xg, 1, cig, Pg)
            }
            U[g, 2] = max(cig)
        }
        st_matrix(on[9], U)
    }
}

real scalar _xtc_median(real colvector v)
{
    real colvector s
    real scalar n
    s = sort(v, 1)
    n = rows(s)
    return(mod(n, 2) ? s[(n + 1) / 2] : (s[n / 2] + s[n / 2 + 1]) / 2)
}

void _xtc_unitsum(string scalar un, real scalar k, string scalar out)
{
    real matrix U, S
    real colvector v
    real scalar j
    U = st_matrix(un)
    S = J(k + 1, 3, .)
    for (j = 1; j <= k; j++) {
        v = select(U[., 2 + j], U[., 2 + j] :< .)
        if (rows(v)) S[j, .] = (_xtc_median(v), max(v), mean(v :> 10))
    }
    v = select(U[., 2], U[., 2] :< .)
    if (rows(v)) S[k + 1, .] = (_xtc_median(v), max(v), mean(v :> 30))
    st_matrix(out, S)
}

end
