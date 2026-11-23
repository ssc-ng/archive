*! tvpcmci 1.0.0  21nov2026
*! PCMCI benchmark (Runge et al. 2019) with partial-correlation CI tests
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane
*
* Benchmark method of Aung et al. (2026, Sec. 5, Table 1).  Reproduces the
* reference implementation tigramite (run_pcmci with ParCorr):
*   Stage 1  PC1 condition selection for every X_j(t) over the lagged
*            candidates X_i(t-tau), tau = max(1,tau_min)..tau_max,
*            one condition combination per dimension (max_combinations = 1),
*            parents re-sorted by min |partial r| after every dimension,
*            parent dropped when p > pc_alpha.
*   Stage 2  MCI test  X_i(t-tau) _||_ X_j(t) | P(X_j(t)) \ {X_i(t-tau)},
*            P(X_i(t-tau)) for tau = tau_min..tau_max; link if p <= alpha.
*   ParCorr  residuals of OLS on Z after per-test standardisation, Pearson r,
*            t = r sqrt(df/(1-r^2)), df = T' - 2 - |Z|, two-sided p.
*   Samples  T' = T - 2 tau_max (tigramite cut_off = '2xtau_max').

program define tvpcmci, eclass
    version 15.0
    if replay() {
        if ("`e(cmd)'" != "tvpcmci") error 301
        _tvpc_display `0'
        exit
    }
    local cmdline `"tvpcmci `0'"'
    syntax varlist(numeric min=2) [if] [in] [,              ///
        TAUMAX(integer 4) TAUMIN(integer 0) LAGStep(integer 1) ///
        Alpha(real 0.05) PCAlpha(real 0.2) MAXConds(integer -1) ///
        TRUTH(name) NOTABle NOEDGEs NOLAGmap NOSUMmary         ///
        GRaph(string asis) * ]

    if (`taumax' < 1) {
        di as err "taumax() must be >= 1"
        exit 198
    }
    if (`taumin' < 0 | `taumin' > `taumax') {
        di as err "taumin() must lie in 0..taumax()"
        exit 198
    }
    if (`lagstep' < 1) {
        di as err "lagstep() must be >= 1"
        exit 198
    }
    if (`alpha' <= 0 | `alpha' >= 1 | `pcalpha' <= 0 | `pcalpha' > 1) {
        di as err "alpha() and pcalpha() must lie in (0,1)"
        exit 198
    }
    local nv : word count `varlist'
    local dup : list dups varlist
    if ("`dup'" != "") {
        di as err "variable(s) `dup' repeated in varlist"
        exit 198
    }
    qui tsset
    local tvar "`r(timevar)'"
    local pvar "`r(panelvar)'"
    if ("`tvar'" == "") {
        di as err "data must be {bf:tsset}"
        exit 111
    }
    if ("`pvar'" != "") {
        di as err "tvpcmci is for a single time series; panel data are not supported"
        exit 198
    }
    marksample touse0

    * array with lags 0..2*taumax (steps), variable-major
    local L2 = 2 * `taumax'
    local cols ""
    local i 0
    foreach v of local varlist {
        local ++i
        forvalues k = 0/`L2' {
            tempvar a`i'_`k'
            local per = `k' * `lagstep'
            qui gen double `a`i'_`k'' = L`per'.`v' if `touse0'
            local cols `cols' `a`i'_`k''
        }
    }
    tempvar touse
    qui gen byte `touse' = `touse0'
    markout `touse' `cols'
    qui count if `touse'
    local N = r(N)
    if (`N' < 10 + `nv' * (`taumax' + 1)) {
        di as err "too few usable observations (`N')"
        exit 2001
    }
    if ("`truth'" != "") {
        capture confirm matrix `truth'
        if (_rc) {
            di as err "truth(): matrix `truth' not found"
            exit 111
        }
    }

    mata: _tvpcmci_main("`cols'", "`touse'", `nv', `taumax', `taumin', ///
        `lagstep', `alpha', `pcalpha', `maxconds')

    local nodenames ""
    foreach v of local varlist {
        forvalues k = 0/`taumax' {
            local per = `k' * `lagstep'
            if (`k' == 0) local nodenames `nodenames' `v'
            else          local nodenames `nodenames' L`per'.`v'
        }
    }
    matrix rownames __tvpc_G = `nodenames'
    matrix colnames __tvpc_G = `nodenames'
    matrix rownames __tvpc_P = `nodenames'
    matrix colnames __tvpc_P = `varlist'
    matrix rownames __tvpc_V = `nodenames'
    matrix colnames __tvpc_V = `varlist'
    matrix colnames __tvpc_links = effect cause lag period type mci_r pc1_r mci_p stab
    matrix rownames __tvpc_lagmap = `varlist'
    matrix colnames __tvpc_lagmap = `varlist'
    matrix rownames __tvpc_deg = `varlist'
    matrix colnames __tvpc_deg = in_links out_links drivers driven own_lags
    matrix colnames __tvpc_par = effect cause lag
    ereturn post, esample(`touse') obs(`N')
    ereturn scalar n_vars    = `nv'
    ereturn scalar lags      = `taumax'
    ereturn scalar tau_min   = `taumin'
    ereturn scalar lagstep   = `lagstep'
    ereturn scalar alpha     = `alpha'
    ereturn scalar pc_alpha  = `pcalpha'
    ereturn scalar nodes     = `nv' * (`taumax' + 1)
    ereturn scalar ntests    = scalar(__tvpc_ntests)
    ereturn scalar n_parents = scalar(__tvpc_npar)
    ereturn scalar n_edges   = scalar(__tvpc_nedges)
    ereturn scalar n_lagged  = scalar(__tvpc_nlag)
    ereturn scalar n_cdir    = scalar(__tvpc_ncdir)
    ereturn scalar n_cund    = scalar(__tvpc_ncund)
    ereturn scalar reps      = 0
    ereturn local varlist   "`varlist'"
    ereturn local nodenames "`nodenames'"
    ereturn local citest    "parcorr"
    ereturn local timevar   "`tvar'"
    ereturn local title     "PCMCI causal discovery (partial correlation)"
    ereturn local cmdline   `"`cmdline'"'
    ereturn local graphcmd  "tvpcgraph"
    ereturn local cmd       "tvpcmci"
    ereturn matrix G       = __tvpc_G
    ereturn matrix pvalue  = __tvpc_P
    ereturn matrix val     = __tvpc_V
    ereturn matrix parents = __tvpc_par
    ereturn matrix links   = __tvpc_links
    ereturn matrix lagmap  = __tvpc_lagmap
    ereturn matrix degree  = __tvpc_deg
    foreach s in ntests npar nedges nlag ncdir ncund {
        capture scalar drop __tvpc_`s'
    }
    if ("`truth'" != "") _tvpc_score, truth(`truth')
    if ("`notable'" == "") _tvpc_display, `noedges' `nolagmap' `nosummary'
    if (`"`graph'"' != "") {
        tvpcgraph, `graph' `options'
    }
    else if (`"`options'"' != "") {
        di as err `"option(s) `options' not allowed"'
        exit 198
    }
end

mata:

// ParCorr test of A[.,x] _||_ A[.,y] | A[.,Z]; returns p, val in v
real scalar _tvpcmci_test(real matrix A, real scalar x, real scalar y,
                          real rowvector Z, real scalar v)
{
    real matrix M, Zm
    real colvector rx, ry
    real rowvector mu, sd, idx
    real scalar T, k, df, t, j, num, den
    idx = (x, y, Z)
    M = A[., idx]
    T = rows(M)
    k = cols(Z)
    mu = mean(M)
    M = M :- mu
    sd = sqrt(colsum(M :* M) / T)
    for (j = 1; j <= cols(M); j++) {
        if (sd[j] != 0) {
            M[., j] = M[., j] / sd[j]
        }
    }
    rx = M[., 1]
    ry = M[., 2]
    if (k > 0) {
        Zm = M[., 3..cols(M)]
        rx = rx - Zm * qrsolve(Zm, rx)
        ry = ry - Zm * qrsolve(Zm, ry)
    }
    rx = rx :- mean(rx)
    ry = ry :- mean(ry)
    num = sum(rx :* ry)
    den = sqrt(sum(rx :* rx) * sum(ry :* ry))
    v = 0
    if (den > 0) {
        v = num / den
    }
    df = T - 2 - k
    if (df < 1) {
        return(.)
    }
    if (abs(v) >= 1) {
        return(0)
    }
    t = v * sqrt(df / (1 - v * v))
    return(2 * ttail(df, abs(t)))
}

void _tvpcmci_main(string scalar cols, string scalar touse, real scalar nv,
        real scalar tmax, real scalar tmin, real scalar step,
        real scalar alpha, real scalar pca, real scalar maxconds)
{
    real matrix A, cand, P, V, G, L, LM, D, PAR, pv1, sg
    real scalar W, tmin1, nc, j, cd, q, pa, pv, v, mcd, ntests, i, tau
    real scalar a, b, k, c, st, r, x, y, ok, ty, pmx
    real rowvector par, others, nonsig, Zc, keep, vmin, pmax
    real colvector o
    pointer(real matrix) colvector parents
    st_view(A, ., tokens(cols), touse)
    W = 2 * tmax + 1
    tmin1 = max((1, tmin))
    v = 0
    ntests = 0
    // candidate lagged parents, order i outer, lag inner (tigramite)
    cand = J(0, 2, .)
    for (i = 1; i <= nv; i++) {
        for (tau = tmin1; tau <= tmax; tau++) {
            cand = cand \ (i, tau)
        }
    }
    nc = rows(cand)
    mcd = maxconds
    if (mcd < 0) {
        mcd = nv * (tmax - tmin1 + 1)
    }
    parents = J(nv, 1, NULL)
    pv1 = J(nc, nv, .)
    // ---------------- stage 1: PC1
    for (j = 1; j <= nv; j++) {
        y = (j - 1) * W + 1
        par = (1..nc)
        vmin = J(1, nc, .)
        pmax = J(1, nc, .)
        for (cd = 0; cd <= mcd; cd++) {
            if (cols(par) - 1 < cd) {
                break
            }
            nonsig = J(1, 0, .)
            for (q = 1; q <= cols(par); q++) {
                pa = par[q]
                others = select(par, par :!= pa)
                if (cols(others) < cd) {
                    continue
                }
                Zc = J(1, 0, .)
                for (k = 1; k <= cd; k++) {
                    Zc = (Zc, (cand[others[k], 1] - 1) * W + cand[others[k], 2] + 1)
                }
                x = (cand[pa, 1] - 1) * W + cand[pa, 2] + 1
                pv = _tvpcmci_test(A, x, y, Zc, v)
                ntests = ntests + 1
                if (vmin[pa] == . | abs(v) < vmin[pa]) {
                    vmin[pa] = abs(v)
                }
                if (pmax[pa] == . | pv > pmax[pa]) {
                    pmax[pa] = pv
                }
                if (pv > pca) {
                    nonsig = (nonsig, pa)
                }
            }
            keep = par
            for (q = 1; q <= cols(nonsig); q++) {
                keep = select(keep, keep :!= nonsig[q])
            }
            // sort by min |val| (descending), ties by insertion order
            if (cols(keep) > 0) {
                o = order((-vmin[keep]', keep'), (1, 2))
                par = keep[o']
            }
            else {
                par = J(1, 0, .)
            }
        }
        if (cols(par) > 0) {
            parents[j] = &(cand[par', .])
            for (q = 1; q <= cols(par); q++) {
                pv1[par[q], j] = vmin[par[q]]
            }
        }
        else {
            parents[j] = &(J(0, 2, .))
        }
    }
    // ---------------- stage 2: MCI
    P = J(nv * (tmax + 1), nv, 1)
    V = J(nv * (tmax + 1), nv, 0)
    for (j = 1; j <= nv; j++) {
        y = (j - 1) * W + 1
        for (i = 1; i <= nv; i++) {
            for (tau = tmin; tau <= tmax; tau++) {
                if (i == j & tau == 0) {
                    continue
                }
                // conditions of Y without (i, tau)
                sg = J(0, 2, .)
                for (q = 1; q <= rows(*parents[j]); q++) {
                    if (!((*parents[j])[q, 1] == i & (*parents[j])[q, 2] == tau)) {
                        sg = sg \ (*parents[j])[q, .]
                    }
                }
                // conditions of X shifted by tau, not already present
                for (q = 1; q <= rows(*parents[i]); q++) {
                    a = (*parents[i])[q, 1]
                    b = (*parents[i])[q, 2] + tau
                    ok = 1
                    for (r = 1; r <= rows(sg); r++) {
                        if (sg[r, 1] == a & sg[r, 2] == b) {
                            ok = 0
                        }
                    }
                    if (ok) {
                        sg = sg \ (a, b)
                    }
                }
                Zc = J(1, 0, .)
                for (q = 1; q <= rows(sg); q++) {
                    Zc = (Zc, (sg[q, 1] - 1) * W + sg[q, 2] + 1)
                }
                x = (i - 1) * W + tau + 1
                pv = _tvpcmci_test(A, x, y, Zc, v)
                ntests = ntests + 1
                P[(i - 1) * (tmax + 1) + tau + 1, j] = pv
                V[(i - 1) * (tmax + 1) + tau + 1, j] = v
            }
        }
    }
    // ---------------- graph on the TV-PC node layout
    G = J(nv * (tmax + 1), nv * (tmax + 1), 0)
    for (j = 1; j <= nv; j++) {
        b = (j - 1) * (tmax + 1) + 1
        for (i = 1; i <= nv; i++) {
            for (tau = tmin; tau <= tmax; tau++) {
                a = (i - 1) * (tmax + 1) + tau + 1
                if (a == b) {
                    continue
                }
                if (P[a, j] <= alpha) {
                    G[a, b] = 1
                }
            }
        }
    }
    // links table: effect cause lag period type r pc1 p stab
    L = J(0, 9, .)
    PAR = J(0, 3, .)
    for (j = 1; j <= nv; j++) {
        b = (j - 1) * (tmax + 1) + 1
        for (q = 1; q <= rows(*parents[j]); q++) {
            PAR = PAR \ (j, (*parents[j])[q, .])
        }
        for (c = 1; c <= nv; c++) {
            for (k = 0; k <= tmax; k++) {
                a = (c - 1) * (tmax + 1) + k + 1
                if (a == b) {
                    continue
                }
                if (G[a, b] == 1 & G[b, a] == 0) {
                    ty = 1
                    if (k == 0) {
                        ty = 2
                    }
                }
                else if (G[a, b] == 1 & G[b, a] == 1 & c < j) {
                    ty = 3
                }
                else {
                    continue
                }
                pmx = P[a, j]
                if (k == 0) {
                    pmx = max((P[a, j], P[b, c]))
                }
                st = .
                if (k > 0) {
                    st = pv1[(c - 1) * (tmax - tmin1 + 1) + k - tmin1 + 1, j]
                }
                L = L \ (j, c, k, k * step, ty, V[a, j], st, pmx, .)
            }
        }
    }
    if (rows(L) == 0) {
        L = J(1, 9, .)
    }
    if (rows(PAR) == 0) {
        PAR = J(1, 3, .)
    }
    LM = J(nv, nv, 0)
    D = J(nv, 5, 0)
    if (L[1, 1] != .) {
        for (q = 1; q <= rows(L); q++) {
            LM[L[q, 2], L[q, 1]] = LM[L[q, 2], L[q, 1]] + 1
            if (L[q, 5] == 3) {
                LM[L[q, 1], L[q, 2]] = LM[L[q, 1], L[q, 2]] + 1
            }
        }
    }
    for (j = 1; j <= nv; j++) {
        D[j, 1] = sum(LM[., j]) - LM[j, j]
        D[j, 2] = sum(LM[j, .]) - LM[j, j]
        D[j, 3] = sum(LM[., j] :> 0) - (LM[j, j] > 0)
        D[j, 4] = sum(LM[j, .] :> 0) - (LM[j, j] > 0)
        D[j, 5] = LM[j, j]
    }
    st_matrix("__tvpc_G", G)
    st_matrix("__tvpc_P", P)
    st_matrix("__tvpc_V", V)
    st_matrix("__tvpc_par", PAR)
    st_matrix("__tvpc_links", L)
    st_matrix("__tvpc_lagmap", LM)
    st_matrix("__tvpc_deg", D)
    st_numscalar("__tvpc_ntests", ntests)
    if (PAR[1, 1] == .) {
        st_numscalar("__tvpc_npar", 0)
    }
    else {
        st_numscalar("__tvpc_npar", rows(PAR))
    }
    if (L[1, 1] == .) {
        st_numscalar("__tvpc_nedges", 0)
        st_numscalar("__tvpc_nlag", 0)
        st_numscalar("__tvpc_ncdir", 0)
        st_numscalar("__tvpc_ncund", 0)
    }
    else {
        st_numscalar("__tvpc_nedges", rows(L))
        st_numscalar("__tvpc_nlag", sum(L[., 5] :== 1))
        st_numscalar("__tvpc_ncdir", sum(L[., 5] :== 2))
        st_numscalar("__tvpc_ncund", sum(L[., 5] :== 3))
    }
}

end
