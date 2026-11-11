*! version 1.2.2  09nov2026
*! _idxnl_dkrepost: replace e(V) of the current regress or xtreg, fe results by the
*! Driscoll-Kraay (1998) covariance matrix (Bartlett kernel), and set e(df_r) = T - 1;
*! with option twoway, by the Cameron-Gelbach-Miller (2011) two-way (panel and time) cluster matrix
program define _idxnl_dkrepost, eclass
    version 14
    syntax , Time(varname) [Panel(varname) FE LAG(integer -1) TWOway]
    if !inlist("`e(cmd)'", "regress", "xtreg") {
        di as err "_idxnl_dkrepost requires regress or xtreg, fe results"
        exit 301
    }
    tempvar touse res
    quietly gen byte `touse' = e(sample)
    if "`fe'" != "" {
        quietly predict double `res' if `touse', e
    }
    else {
        quietly predict double `res' if `touse', residuals
    }
    tempname b V0 V
    matrix `b' = e(b)
    matrix `V0' = e(V)
    local cn : colnames `b'
    local k : word count `cn'
    * build a list of usable regressors (skip _cons and omitted terms)
    local use ""
    local pos ""
    local j = 0
    foreach c of local cn {
        local ++j
        if "`c'" == "_cons" continue
        if substr("`c'", 1, 2) == "o." | strpos("`c'", "o.") {
            continue
        }
        local use "`use' `c'"
        local pos "`pos' `j'"
    }
    fvrevar `use' if `touse'
    local tv "`r(varlist)'"
    local icons = colnumb(`b', "_cons")
    * number of estimated slope coefficients (positive variance, excluding _cons) plus one
    local dfk = 1
    forvalues jj = 1/`k' {
        if `V0'[`jj', `jj'] > 0 & !missing(`V0'[`jj', `jj']) & `jj' != `icons' local ++dfk
    }
    mata: _idxnl_dk("`tv'", "`res'", "`time'", "`panel'", "`touse'", ///
        "`fe'" != "", `lag', `dfk', "`pos'", `k', ///
        missing(`icons') ? 0 : `icons', "`V0'", "`V'", "`twoway'" != "")
    matrix rownames `V' = `cn'
    matrix colnames `V' = `cn'
    ereturn repost V = `V'
    if "`twoway'" != "" {
        ereturn scalar df_r = `dkG' - 1
        ereturn local vcetype "2-way clust"
        ereturn local vce "twoway"
    }
    else {
        ereturn scalar df_r = `dkT' - 1
        ereturn scalar dk_lag = `dklag'
        ereturn local vcetype "Drisc/Kraay"
        ereturn local vce "dk"
    }

end

version 14
mata:
void _idxnl_dk(string scalar xv, string scalar ev, string scalar tv, string scalar pv,
    string scalar tu, real scalar fe, real scalar lag, real scalar dfk, string scalar posl,
    real scalar k, real scalar icons, string scalar V0name, string scalar Vname,
    real scalar tw)
{
    real matrix X, H, S, G, XXi, Vs
    real colvector e, t, p, ut, up, sel
    real scalar n, kk, T, j, l, w
    X = st_data(., tokens(xv), tu)
    e = st_data(., ev, tu)
    t = st_data(., tv, tu)
    n = rows(X)
    if (fe) {
        p = st_data(., pv, tu)
        up = uniqrows(p)
        for (j = 1; j <= rows(up); j++) {
            sel = selectindex(p :== up[j])
            X[sel, .] = X[sel, .] :- mean(X[sel, .])
        }
    }
    else {
        X = X, J(n, 1, 1)
    }
    kk = cols(X)
    if (tw) {
        p = st_data(., pv, tu)
        Vs = _idxnl_twV(X, e, p, t, dfk)
        st_local("dkG", strofreal(min((rows(uniqrows(p)), rows(uniqrows(t))))))
        st_local("dkT", strofreal(rows(uniqrows(t))))
        st_local("dklag", "0")
        _idxnl_mapV(Vs, k, icons, fe, V0name, Vname, posl)
        return
    }
    ut = uniqrows(t)
    T = rows(ut)
    if (lag < 0) lag = floor(4*(T/100)^(2/9))
    H = J(T, kk, 0)
    for (j = 1; j <= T; j++) {
        sel = selectindex(t :== ut[j])
        H[j, .] = colsum(X[sel, .] :* e[sel])
    }
    S = H'H
    for (l = 1; l <= lag; l++) {
        w = 1 - l/(lag + 1)
        G = H[(l+1)..T, .]' * H[1..(T-l), .]
        S = S + w*(G + G')
    }
    XXi = invsym(X'X)
    Vs = (n - 1)/(n - dfk) * XXi*S*XXi
    _idxnl_mapV(Vs, k, icons, fe, V0name, Vname, posl)
    st_local("dkT", strofreal(T))
    st_local("dklag", strofreal(lag))
}

void _idxnl_mapV(real matrix Vs, real scalar k, real scalar icons, real scalar fe,
    string scalar V0name, string scalar Vname, string scalar posl)
{
    real matrix V, V0
    real colvector pos
    real scalar i, j, a
    V0 = st_matrix(V0name)
    V = J(k, k, 0)
    pos = strtoreal(tokens(posl))'
    for (i = 1; i <= rows(pos); i++) {
        for (j = 1; j <= rows(pos); j++) {
            V[pos[i], pos[j]] = Vs[i, j]
        }
    }
    if (icons > 0) {
        if (fe) {
            V[icons, icons] = V0[icons, icons]
        }
        else {
            a = cols(Vs)
            for (i = 1; i <= rows(pos); i++) {
                V[pos[i], icons] = Vs[i, a]
                V[icons, pos[i]] = Vs[a, i]
            }
            V[icons, icons] = Vs[a, a]
        }
    }
    st_matrix(Vname, V)
}

real matrix _idxnl_cmeat(real matrix X, real colvector e, real colvector g, real scalar dfk)
{
    real matrix S
    real colvector ug, sel
    real rowvector s
    real scalar j, n, G
    n = rows(X)
    ug = uniqrows(g)
    G = rows(ug)
    S = J(cols(X), cols(X), 0)
    for (j = 1; j <= G; j++) {
        sel = selectindex(g :== ug[j])
        s = colsum(X[sel, .] :* e[sel])
        S = S + s's
    }
    return(G/(G - 1)*(n - 1)/(n - dfk)*S)
}

real matrix _idxnl_twV(real matrix X, real colvector e, real colvector p, real colvector t,
    real scalar dfk)
{
    real matrix XXi, V, Q
    real colvector pt
    real rowvector L
    XXi = invsym(X'X)
    pt = p*1e6 + t
    V = XXi*(_idxnl_cmeat(X, e, p, dfk) + _idxnl_cmeat(X, e, t, dfk) - _idxnl_cmeat(X, e, pt, dfk))*XXi
    V = (V + V')/2
    symeigensystem(V, Q, L)
    if (min(L) < 0) {
        L = L :* (L :> 0)
        V = Q*diag(L)*Q'
    }
    return(V)
}

end
