*! _tvpc_score 1.0.0  21nov2026
*! Accuracy of an estimated time-lagged PDAG against a ground truth
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane
*
* Conventions follow gCastle's MetricsDAG (Zhang et al. 2021), the metric used
* for Table 1 of Aung et al. (2026):
*   undirected edges count in both directions in nnz,
*   precision = TP/nnz, recall = TP/#true, F1 = 2PR/(P+R),
*   SHD = extra + missing (skeleton) + reversed.
* truth() is a K x 3 matrix (cause effect lag): variable positions in the
* varlist and the lag in steps (0 = contemporaneous cause -> effect).
* True links with lag > e(lags) lie outside the node graph and are ignored.

program define _tvpc_score, eclass
    version 15.0
    syntax , TRUTH(name)
    if !inlist("`e(cmd)'", "tvpc", "tvpcmci") error 301
    capture confirm matrix `truth'
    if (_rc) {
        di as err "matrix `truth' not found"
        exit 111
    }
    if (colsof(`truth') != 3) {
        di as err "truth() must have 3 columns: cause effect lag"
        exit 503
    }
    tempname G T
    matrix `G' = e(G)
    matrix `T' = `truth'
    mata: _tvpc_score_m("`G'", "`T'", `=e(n_vars)', `=e(lags)')
    foreach s in n_true nnz TP FP reversed precision recall F1 shd F1_skel {
        ereturn scalar `s' = scalar(__tvpcs_`s')
        scalar drop __tvpcs_`s'
    }
    ereturn matrix truth = `T'
end

mata:
void _tvpc_score_m(string scalar gname, string scalar tname, real scalar nv,
                   real scalar m)
{
    real matrix G, T, B, Bs, Gs, Ed, Bt
    real scalar p, q, a, b, TP, nnz, ntrue, prec, rec, f1, extra, miss
    real scalar rev, i, j, tps, ps, rs, fp
    G = st_matrix(gname)
    T = st_matrix(tname)
    p = rows(G)
    B = J(p, p, 0)
    for (q = 1; q <= rows(T); q++) {
        if (T[q, 1] < 1 | T[q, 1] > nv | T[q, 2] < 1 | T[q, 2] > nv) {
            errprintf("truth(): variable index out of range in row %f\n", q)
            exit(498)
        }
        if (T[q, 3] < 0) {
            errprintf("truth(): negative lag in row %f\n", q)
            exit(498)
        }
        // true links beyond the estimated lag window cannot be found:
        // they are not part of the node graph and are ignored
        if (T[q, 3] > m) {
            continue
        }
        a = (T[q, 1] - 1) * (m + 1) + T[q, 3] + 1
        b = (T[q, 2] - 1) * (m + 1) + 1
        B[a, b] = 1
    }
    G = G :* (1 :- I(p))
    ntrue = sum(B)
    TP = sum((G + B) :== 2)
    nnz = sum(G)
    prec = 0
    rec = 0
    f1 = 0
    if (nnz > 0) {
        prec = TP / nnz
    }
    if (ntrue > 0) {
        rec = TP / ntrue
    }
    if (prec + rec > 0) {
        f1 = 2 * prec * rec / (prec + rec)
    }
    // false positives (edges absent from the true skeleton)
    Bs = (B + B') :> 0
    Gs = (G + G') :> 0
    fp = 0
    extra = 0
    miss = 0
    rev = 0
    tps = 0
    for (i = 1; i < p; i++) {
        for (j = i + 1; j <= p; j++) {
            if (Gs[i, j] & !Bs[i, j]) {
                extra = extra + 1
            }
            if (!Gs[i, j] & Bs[i, j]) {
                miss = miss + 1
            }
            if (Gs[i, j] & Bs[i, j]) {
                tps = tps + 1
            }
        }
    }
    // reversed: estimated directed edge whose reverse is true
    for (i = 1; i <= p; i++) {
        for (j = 1; j <= p; j++) {
            if (G[i, j] == 1 & G[j, i] == 0 & B[i, j] == 0 & B[j, i] == 1) {
                rev = rev + 1
            }
        }
    }
    ps = 0
    rs = 0
    if (sum(Gs) > 0) {
        ps = tps / (sum(Gs) / 2)
    }
    if (sum(Bs) > 0) {
        rs = tps / (sum(Bs) / 2)
    }
    st_numscalar("__tvpcs_n_true", ntrue)
    st_numscalar("__tvpcs_nnz", nnz)
    st_numscalar("__tvpcs_TP", TP)
    st_numscalar("__tvpcs_FP", extra)
    st_numscalar("__tvpcs_reversed", rev)
    st_numscalar("__tvpcs_precision", prec)
    st_numscalar("__tvpcs_recall", rec)
    st_numscalar("__tvpcs_F1", f1)
    st_numscalar("__tvpcs_shd", extra + miss + rev)
    if (ps + rs > 0) {
        st_numscalar("__tvpcs_F1_skel", 2 * ps * rs / (ps + rs))
    }
    else {
        st_numscalar("__tvpcs_F1_skel", 0)
    }
}
end
