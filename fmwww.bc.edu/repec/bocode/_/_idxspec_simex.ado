*! version 1.2.2  09nov2026
*! _idxspec_simex: SIMEX correction (Cook and Stefanski 1994) of the quadratic index
*! coefficients for classical measurement error with known standard deviation, with
*! cluster-bootstrap standard errors; controls and fixed effects are partialled out.
program define _idxspec_simex, rclass
    version 14
    syntax varlist(min=2 max=2 numeric) if, SU(real) [WV(string) B(integer 50) REPS(integer 199) ///
        PANEL(string) BVAR(string) LO(real 0) HI(real 0) Level(cilevel) ALPha(real 0.05) noTABle]
    marksample touse
    gettoken y x : varlist
    local x = trim("`x'")
    tempname bs bn V
    mata: _idxnl_simex("`y'", "`x'", "`wv'", "`touse'", "`panel'", "`bvar'", `su', `b', `reps', ///
        "`bs'", "`bn'", "`V'")
    local G = `simexG'
    local df = `G' - 1
    local crit = invttail(`df', (1 - `level'/100)/2)
    local b1 = `bs'[1, 1]
    local b2 = `bs'[1, 2]
    _idxtp_core, b1(`b1') b2(`b2') v11(`=`V'[1,1]') v22(`=`V'[2,2]') v12(`=`V'[1,2]') ///
        lo(`lo') hi(`hi') crit(`crit') df(`df')
    foreach s in tp fieller_lb fieller_ub lm_t lm_p slope_hi t_hi {
        local `s' = r(`s')
    }
    local ftype "`r(fieller_type)'"
    if "`table'" == "" {
        di
        di as txt "SIMEX correction for measurement error in the index (sd = " as res `su' as txt ")"
        di as txt "{hline 78}"
        di as txt "               naive         SIMEX     bootstrap se"
        di as txt "  b(x)    " as res %11.4f `bn'[1,1] %14.4f `b1' %14.4f sqrt(`V'[1,1])
        di as txt "  b(x^2)  " as res %11.4f `bn'[1,2] %14.4f `b2' %14.4f sqrt(`V'[2,2])
        di as txt "  Corrected turning point = " as res %9.4f `tp'
        if "`ftype'" == "bounded" di as txt "  Fieller `level'% CI = [" as res %9.4f `fieller_lb' as txt ", " as res %9.4f `fieller_ub' as txt "]"
        else if "`ftype'" == "union" di as txt "  Fieller `level'% CI = (-inf, " as res %9.4f `fieller_lb' as txt "] U [" as res %9.4f `fieller_ub' as txt ", +inf)"
        else di as txt "  Fieller `level'% CI = " as res "unbounded"
        di as txt "  Lind-Mehlum on S: t = " as res %6.3f `lm_t' as txt ", p = " as res %6.4f `lm_p' ///
            as txt ";  slope at upper bound = " as res %8.4f `slope_hi' as txt " (t = " as res %5.2f `t_hi' as txt ")"
        di as txt "  (" as res `b' as txt " pseudo-samples per lambda in {0.5,1,1.5,2}; quadratic extrapolant; " ///
            as res `reps' as txt " bootstrap replications over " as res `G' as txt " clusters)"
        di as txt "{hline 78}"
    }
    return scalar naive_b1 = `bn'[1,1]
    return scalar naive_b2 = `bn'[1,2]
    return scalar simex_b1 = `b1'
    return scalar simex_b2 = `b2'
    return scalar simex_se1 = sqrt(`V'[1,1])
    return scalar simex_se2 = sqrt(`V'[2,2])
    return scalar simex_tp = `tp'
    return scalar simex_fieller_lb = `fieller_lb'
    return scalar simex_fieller_ub = `fieller_ub'
    return scalar simex_lm_t = `lm_t'
    return scalar simex_lm_p = `lm_p'
    return local simex_fieller_type "`ftype'"
end

version 14
mata:
real matrix _idxnl_wthn(real matrix A, real colvector p)
{
    real matrix R
    real colvector up, sel
    real scalar j
    R = A
    up = uniqrows(p)
    for (j = 1; j <= rows(up); j++) {
        sel = selectindex(p :== up[j])
        R[sel, .] = R[sel, .] :- mean(R[sel, .])
    }
    return(R)
}

real matrix _idxnl_resid(real matrix A, real matrix W, real colvector p, real scalar fe)
{
    real matrix Ad, Wd
    if (fe) {
        Ad = _idxnl_wthn(A, p)
        if (cols(W) == 0) return(Ad)
        Wd = _idxnl_wthn(W, p)
    }
    else {
        Ad = A
        Wd = (cols(W) > 0 ? (W, J(rows(A), 1, 1)) : J(rows(A), 1, 1))
    }
    return(Ad - Wd*(invsym(Wd'Wd)*(Wd'Ad)))
}

real rowvector _idxnl_simex1(real colvector y, real colvector x, real matrix W, real colvector p,
    real scalar fe, real scalar su, real scalar B, real rowvector naive)
{
    real colvector yr, z, ww
    real matrix X, P, D, C
    real scalar i, r, n
    n = rows(y)
    z = (0, 0.5, 1, 1.5, 2)'
    yr = _idxnl_resid(y, W, p, fe)
    P = J(5, 2, 0)
    X = _idxnl_resid((x, x:^2), W, p, fe)
    P[1, .] = (invsym(X'X)*(X'yr))'
    naive = P[1, .]
    for (i = 2; i <= 5; i++) {
        for (r = 1; r <= B; r++) {
            ww = x + sqrt(z[i])*su*rnormal(n, 1, 0, 1)
            X = _idxnl_resid((ww, ww:^2), W, p, fe)
            P[i, .] = P[i, .] + (invsym(X'X)*(X'yr))'/B
        }
    }
    D = (J(5, 1, 1), z, z:^2)
    C = invsym(D'D)*(D'P)
    return((1, -1, 1)*C)
}

void _idxnl_simex(string scalar yv, string scalar xv, string scalar wv, string scalar tu,
    string scalar pv, string scalar bv, real scalar su, real scalar B, real scalar reps,
    string scalar nbs, string scalar nbn, string scalar nV)
{
    real colvector y, x, p, g, ug, pick, rows_, newp, sel
    real matrix W, draws
    real rowvector bs, bn, tmp
    real scalar fe, n, G, r, k
    y = st_data(., yv, tu)
    x = st_data(., xv, tu)
    n = rows(y)
    W = (wv != "" ? st_data(., tokens(wv), tu) : J(n, 0, .))
    fe = (pv != "")
    p = (fe ? st_data(., pv, tu) : J(n, 1, 1))
    g = (bv != "" ? st_data(., bv, tu) : (1::n))
    bn = J(1, 2, .)
    bs = _idxnl_simex1(y, x, W, p, fe, su, B, bn)
    ug = uniqrows(g)
    G = rows(ug)
    draws = J(reps, 2, .)
    for (r = 1; r <= reps; r++) {
        pick = ug[ceil(G*runiform(G, 1))]
        rows_ = J(0, 1, .)
        newp = J(0, 1, .)
        for (k = 1; k <= G; k++) {
            sel = selectindex(g :== pick[k])
            rows_ = rows_ \ sel
            newp = newp \ J(rows(sel), 1, k)
        }
        tmp = J(1, 2, .)
        draws[r, .] = _idxnl_simex1(y[rows_], x[rows_], W[rows_, .], newp, fe, su, B, tmp)
    }
    st_matrix(nbs, bs)
    st_matrix(nbn, bn)
    st_matrix(nV, variance(draws))
    st_local("simexG", strofreal(G))
}
end
