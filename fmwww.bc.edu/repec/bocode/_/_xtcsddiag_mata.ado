*! _xtcsddiag_mata  version 1.0.0  21oct2026
*! Mata engine for xtcsddiag. Loaded on demand with -do- by _xtcsddiag_load; not a command.

mata:
mata set matastrict off

real scalar xcs_loaded()
{
    return(100)
}

// residuals of the columns of Y on the columns of Z (least squares; invsym drops
// collinear columns)
real matrix xcs_res(real matrix Y, real matrix Z)
{
    return(Y - Z * (invsym(Z' * Z) * (Z' * Y)))
}

// rank of Z (number of nonzero diagonal elements of invsym(Z'Z))
real scalar xcs_rank(real matrix Z)
{
    return(sum(diagonal(invsym(Z' * Z)) :!= 0))
}

// ------------------------------------------------------------------------------------
// statistics for each column of E (T x B residual vectors)
//   Z  design that produced the residuals (Breusch-Godfrey auxiliary regression)
//   W  (1, x_i): regressors of the Koenker test and scores of the Hansen test
//   LT lower-triangular matrix of ones (partial sums)
// returns B x 5 matrix: bg bp jb cusum hansen
// ------------------------------------------------------------------------------------
real matrix xcs_stats(real matrix E, real matrix Z, real matrix W, real scalar p,
                      real matrix LT)
{
    real matrix R, L, ML, U, F, Uc, D, S, Fs, Ss, V
    real rowvector ssr0, num, ssr1, m2, m3, m4, s
    real colvector e, ml, c
    real scalar T, B, kz, b, j, df2
    T = rows(E); B = cols(E)
    kz = xcs_rank(Z)
    R = J(B, 5, .)
    // Breusch-Godfrey F(p): FWL, e is already orthogonal to Z
    ssr0 = colsum(E:^2)
    df2 = T - kz - p
    if (p == 1) {
        L = J(1, B, 0) \ E[|1, 1 \ T - 1, B|]
        ML = xcs_res(L, Z)
        num = colsum(ML :* E):^2 :/ colsum(ML:^2)
        ssr1 = ssr0 - num
        R[., 1] = ((num / p) :/ (ssr1 / df2))'
    }
    else {
        for (b = 1; b <= B; b++) {
            e = E[., b]
            L = J(T, p, 0)
            for (j = 1; j <= p; j++) L[|j + 1, j \ T, j|] = e[|1 \ T - j|]
            ML = xcs_res(L, Z)
            c = ML' * e
            num = c' * invsym(ML' * ML) * c
            R[b, 1] = (num / p) / ((ssr0[b] - num) / df2)
        }
    }
    // Koenker (1981) n R^2 of e^2 on W
    U = E:^2
    F = xcs_res(U, W)
    Uc = U :- mean(U)
    R[., 2] = (T * (1 :- colsum(F:^2) :/ colsum(Uc:^2)))'
    // Jarque-Bera
    D = E :- mean(E)
    m2 = mean(D:^2); m3 = mean(D:^3); m4 = mean(D:^4)
    R[., 3] = (T * ((m3 :/ m2:^1.5):^2 / 6 + (m4 :/ m2:^2 :- 3):^2 / 24))'
    // OLS-CUSUM
    S = LT * E
    s = sqrt(mean(E:^2))
    R[., 4] = (colmax(abs(S)) :/ (s * sqrt(T)))'
    // Hansen (1992) joint L on the scores W e
    for (b = 1; b <= B; b++) {
        Fs = W :* E[., b]
        Ss = LT * Fs
        V = Fs' * Fs
        R[b, 5] = sum(rowsum((Ss * invsym(V)) :* Ss)) / T
    }
    return(R)
}

// ------------------------------------------------------------------------------------
// main engine
//   est 1 = cce, 2 = mg, 3 = fe (two-way fixed effects, common slopes)
// Stata matrices written: UNITS (N x 12: id T_i stat x5 ... see below), COMB (5 x 6),
// CDR (1 x 6), BMG (1 x k), INFO (1 x 4)
// ------------------------------------------------------------------------------------
void xcs_run(string scalar yv, string scalar xv, string scalar zv, string scalar idv,
             string scalar tv, string scalar touse, string scalar ev, real scalar est,
             real scalar p, real scalar reps, real scalar chunk,
             string scalar unitsn, string scalar combn, string scalar cdn,
             string scalar bmgn, string scalar infon)
{
    real colvector y, id, tm, e, ei, w, tu, pos, sig
    real matrix X, Zb, info, W, Z, LT, Es, s0, sb, cnt, UN, A, Ab, Eps, PV, BM, Dm
    real scalar N, k, i, a1, a2, Ti, kz, j, done, c, r, nobs, T, t, q
    y  = st_data(., yv, touse)
    X  = st_data(., xv, touse)
    id = st_data(., idv, touse)
    tm = st_data(., tv, touse)
    if (est == 1) Zb = st_data(., zv, touse)
    k = cols(X)
    nobs = rows(y)
    info = panelsetup(id, 1)
    N = rows(info)
    UN = J(N, 12, .)
    PV = J(N, 5, .)
    BM = J(N, k, .)
    e = J(nobs, 1, .)

    if (est <= 2) {
        for (i = 1; i <= N; i++) {
            a1 = info[i, 1]; a2 = info[i, 2]
            Ti = a2 - a1 + 1
            W = J(Ti, 1, 1), X[|a1, 1 \ a2, k|]
            Z = (est == 1 ? (W, Zb[|a1, 1 \ a2, cols(Zb)|]) : W)
            kz = xcs_rank(Z)
            UN[i, 1] = id[a1]; UN[i, 2] = Ti
            if (Ti < kz + p + 3) continue
            A = invsym(Z' * Z)
            Ab = A * (Z' * y[|a1 \ a2|])
            BM[i, .] = Ab[|2 \ k + 1|]'
            ei = y[|a1 \ a2|] - Z * Ab
            e[|a1 \ a2|] = ei
            LT = lowertriangle(J(Ti, Ti, 1))
            s0 = xcs_stats(ei, Z, W, p, LT)
            cnt = J(1, 5, 0)
            done = 0
            while (done < reps) {
                c = min((chunk, reps - done))
                Es = xcs_res(rnormal(Ti, c, 0, 1), Z)
                sb = xcs_stats(Es, Z, W, p, LT)
                cnt = cnt + colsum(sb :>= s0)
                done = done + c
            }
            UN[i, (3..7)] = s0
            PV[i, .] = (cnt :+ 1) / (reps + 1)
        }
    }
    else {
        // two-way fixed effects by FWL: unit-demean y, X and period dummies, then OLS
        tu = uniqrows(tm)
        T = rows(tu)
        pos = J(nobs, 1, .)
        for (r = 1; r <= nobs; r++) {
            for (t = 1; t <= T; t++) {
                if (tu[t] == tm[r]) {
                    pos[r] = t
                    break
                }
            }
        }
        Dm = J(nobs, T - 1, 0)
        for (r = 1; r <= nobs; r++) if (pos[r] > 1) Dm[r, pos[r] - 1] = 1
        A = (X, Dm)
        A = xcs_udm(A, info)
        Ab = invsym(A' * A)
        q = Ab * (A' * xcs_udm(y, info))
        e = xcs_udm(y, info) - A * q
        BM = J(N, 1, 1) # q[|1 \ k|]'
        sig = J(N, 1, .)
        for (i = 1; i <= N; i++) {
            a1 = info[i, 1]; a2 = info[i, 2]
            Ti = a2 - a1 + 1
            UN[i, 1] = id[a1]; UN[i, 2] = Ti
            if (Ti > 1) sig[i] = sqrt(sum(e[|a1 \ a2|]:^2) / (Ti - 1))
        }
        s0 = J(N, 5, .)
        for (i = 1; i <= N; i++) {
            a1 = info[i, 1]; a2 = info[i, 2]
            Ti = a2 - a1 + 1
            W = J(Ti, 1, 1), X[|a1, 1 \ a2, k|]
            if (Ti < xcs_rank(W) + p + 3) continue
            LT = lowertriangle(J(Ti, Ti, 1))
            s0[i, .] = xcs_stats(e[|a1 \ a2|], W, W, p, LT)
        }
        cnt = J(N, 5, 0)
        done = 0
        while (done < reps) {
            c = min((chunk, reps - done))
            Eps = rnormal(nobs, c, 0, 1)
            for (i = 1; i <= N; i++) {
                a1 = info[i, 1]; a2 = info[i, 2]
                Eps[|a1, 1 \ a2, c|] = Eps[|a1, 1 \ a2, c|] * sig[i]
            }
            Eps = xcs_udm(Eps, info)
            Es = Eps - A * (Ab * (A' * Eps))
            for (i = 1; i <= N; i++) {
                if (s0[i, 1] >= .) continue
                a1 = info[i, 1]; a2 = info[i, 2]
                Ti = a2 - a1 + 1
                W = J(Ti, 1, 1), X[|a1, 1 \ a2, k|]
                LT = lowertriangle(J(Ti, Ti, 1))
                sb = xcs_stats(Es[|a1, 1 \ a2, c|], W, W, p, LT)
                cnt[i, .] = cnt[i, .] + colsum(sb :>= s0[i, .])
            }
            done = done + c
        }
        for (i = 1; i <= N; i++) {
            if (s0[i, 1] >= .) continue
            UN[i, (3..7)] = s0[i, .]
            PV[i, .] = (cnt[i, .] :+ 1) / (reps + 1)
        }
    }
    UN[., (8..12)] = PV
    st_store(., ev, touse, e)
    st_matrix(unitsn, UN)
    st_matrix(combn, xcs_combine(PV))
    st_matrix(cdn, xcs_cd(e, id, tm, info, UN[., 3]))
    BM = select(BM, UN[., 3] :< .)
    st_matrix(bmgn, (rows(BM) ? mean(BM) : J(1, k, .)))
    st_matrix(infon, (N, sum(UN[., 3] :< .), min(select(UN[., 2], UN[., 3] :< .)),
                      max(select(UN[., 2], UN[., 3] :< .))))
}

// unit-demean the columns of A (rows grouped by info)
real matrix xcs_udm(real matrix A0, real matrix info)
{
    real matrix A
    real scalar i
    A = A0
    for (i = 1; i <= rows(info); i++) {
        A[|info[i, 1], 1 \ info[i, 2], cols(A)|] =
            A[|info[i, 1], 1 \ info[i, 2], cols(A)|] :- mean(A[|info[i, 1], 1 \ info[i, 2], cols(A)|])
    }
    return(A)
}

// combination of unit p-values; rows bg bp jb cusum hansen;
// columns: units, Fisher, p_Fisher, Z (inverse normal), p_Z, share rejecting at 5%
real matrix xcs_combine(real matrix PV)
{
    real matrix C
    real colvector pv
    real scalar j, n, F, Z
    C = J(5, 6, .)
    for (j = 1; j <= 5; j++) {
        pv = select(PV[., j], PV[., j] :< .)
        n = rows(pv)
        if (n == 0) continue
        F = -2 * sum(ln(pv))
        Z = sum(invnormal(pv)) / sqrt(n)
        C[j, .] = (n, F, chi2tail(2 * n, F), Z, normal(Z), mean(pv :< .05))
    }
    return(C)
}

// Pesaran CD and the weighted CD of Juodis and Reese (2022) on the residuals; pairs use
// their common periods (unbalanced panels). Returns (CD, p, CDw, p, pairs, mean |rho|)
real rowvector xcs_cd(real colvector e, real colvector id, real colvector tm,
                      real matrix info, real colvector ok)
{
    real colvector tu, a, b, m, w, rows_i
    real matrix E
    real scalar N, T, i, j, r, t, s, sw, np, Tij, rho, sa
    tu = uniqrows(tm)
    T = rows(tu)
    N = rows(info)
    E = J(T, N, .)
    for (i = 1; i <= N; i++) {
        if (ok[i] >= .) continue
        for (r = info[i, 1]; r <= info[i, 2]; r++) {
            for (t = 1; t <= T; t++) {
                if (tu[t] == tm[r]) {
                    E[t, i] = e[r]
                    break
                }
            }
        }
    }
    E = select(E, colnonmissing(E) :> 0)
    N = cols(E)
    w = 2 * (runiform(N, 1) :< .5) :- 1
    s = 0; sw = 0; np = 0; sa = 0
    for (i = 1; i < N; i++) {
        for (j = i + 1; j <= N; j++) {
            m = (E[., i] :< .) :& (E[., j] :< .)
            Tij = sum(m)
            if (Tij < 3) continue
            a = select(E[., i], m); b = select(E[., j], m)
            a = a :- mean(a); b = b :- mean(b)
            rho = (a' * b) / sqrt((a' * a) * (b' * b))
            s = s + sqrt(Tij) * rho
            sw = sw + w[i] * w[j] * sqrt(Tij) * rho
            sa = sa + abs(rho)
            np++
        }
    }
    if (np == 0) return(J(1, 6, .))
    s = s / sqrt(np)
    sw = sw / sqrt(np)
    return((s, 2 * normal(-abs(s)), sw, 2 * normal(-abs(sw)), np, sa / np))
}

end
