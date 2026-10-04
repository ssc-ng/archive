*! _duvm_engel 1.2.0  2026-09-29  Abdelkrim Araar
*! Engel curves after duvm: the parameters of the curves of one good and their
*! linearized covariance. Used by predict (duvm_p) and estat engel.
*!
*!     _duvm_engel, good(#) [novar]
*!
*! The first stage of duvm is linear in ln x within clusters, so at the means of
*! the other regressors the curves are straight lines in ln x:
*!     budget share      w(ln x)    = a0 + b0 ln x,  a0 = wbar - b0 L0
*!     log unit value    ln v(ln x) = a1 + b1 ln x,  a1 = vbar - b1 L1
*! wbar, L0: weighted means of the share and of ln x over the estimation sample;
*! vbar, L1: the same over the households that report the good.
*! r(theta) = (a0, b0, a1, b1); r(V) = their covariance, from the influence
*! functions of the four means and of the two within-cluster slopes, aggregated
*! as duvm aggregates its own (clusters, or PSUs within strata with the FPC).
program define _duvm_engel, rclass
    version 14.2
    syntax , [Good(integer 0) NOVar QSE(string) VMAT(name) REF(real -1e300) SH0(real 0)]
    if "`e(cmd)'" != "duvm" error 301
    * the standard error of the log-quantity curve (the Mata of this file is not
    * visible from other ado-files, so predict and estat engel call it here);
    * with ref() and sh0(), of the curve normalized to 0 at ln x = ref, where
    * the fitted share is sh0
    if "`qse'" != "" {
        tokenize `qse'
        if `ref' == -1e300 mata: _duvme_qse("`1'", "`2'", "`3'", "`4'", st_matrix("`vmat'"), 0, 0, 0)
        else               mata: _duvme_qse("`1'", "`2'", "`3'", "`4'", st_matrix("`vmat'"), 1, `ref', `sh0')
        exit
    }
    local goods `e(goods)'
    local g : word `good' of `goods'
    if "`g'" == "" {
        di as err "good(`good'): there are `: word count `goods'' goods"
        exit 198
    }
    if "`e(expend)'" == "" {
        di as err "these duvm results predate the Engel curves; estimate the model again"
        exit 301
    }
    tempvar wt lnx es
    local wexp = trim(subinstr(`"`e(wexp)'"', "=", "", 1))
    if "`wexp'" == "" qui gen double `wt' = 1
    else              qui gen double `wt' = `wexp'
    qui gen double `lnx' = ln(`e(expend)')
    qui gen byte `es' = e(sample)
    * the share and the unit value as the model used them (nonbuyers())
    tempvar shv uvv
    local mode "`e(nonbuyers)'"
    if "`mode'" == "" local mode "asis"
    _duvm_uv `g', touse(`es') wt(`wt') cluster(`e(clustvar)') mode(`mode') share(`shv') uv(`uvv')

    qui summarize `shv' [aw=`wt'] if `es', meanonly
    local wbar = r(mean)
    qui summarize `lnx' [aw=`wt'] if `es', meanonly
    local L0 = r(mean)
    qui summarize `uvv' [aw=`wt'] if `es' & `uvv' < ., meanonly
    local vbar = r(mean)
    qui summarize `lnx' [aw=`wt'] if `es' & `uvv' < ., meanonly
    local L1 = r(mean)
    local b0 = el(e(beta0), 1, `good')
    local b1 = el(e(beta1), 1, `good')
    tempname theta
    matrix `theta' = (`wbar' - `b0' * `L0', `b0', `vbar' - `b1' * `L1', `b1')
    matrix colnames `theta' = a0 b0 a1 b1
    return scalar wbar = `wbar'
    return scalar vbar = `vbar'
    return scalar L0 = `L0'
    return scalar L1 = `L1'
    return local good "`g'"

    local hasV = ("`novar'" == "" & "`e(vce)'" != "none")
    if `hasV' {
        * the design of the variance: as estimated; the bootstrap is replaced by
        * the linearization on the same design
        local psu "`e(clustvar)'"
        local strata ""
        local fpc ""
        if inlist("`e(vce)'", "svy", "bootstrap") {
            if "`e(bpsu)'" != "" local psu "`e(bpsu)'"
            local strata "`e(bstrata)'"
            local fpc "`e(fpc)'"
        }
        tempvar st fp
        if "`strata'" == "" qui gen byte `st' = 1
        else                qui gen double `st' = `strata'
        if "`fpc'" == "" qui gen byte `fp' = 0
        else             qui gen double `fp' = `fpc'
        * the regressors of the first stage, rebuilt from the names of e(beta0)
        tempname B
        matrix `B' = e(beta0)
        local xn : rownames `B'
        local X ""
        local i 0
        foreach x of local xn {
            local ++i
            tempvar x`i'
            if "`x'" == "lnexp"         qui gen double `x`i'' = `lnx'
            else if "`x'" == "lnhhsize" qui gen double `x`i'' = ln(`e(hhsize)')
            else if strpos("`x'", "==") {
                local v = substr("`x'", 1, strpos("`x'", "==") - 1)
                local val = substr("`x'", strpos("`x'", "==") + 2, .)
                qui gen double `x`i'' = (`v' == `val') if `v' < .
            }
            else qui gen double `x`i'' = `x'
            local X `X' `x`i''
        }
        tempname V Vs chk
        * selection: the unit-value slope is that of the equation with the Mills
        * ratio, and its influence function holds the term of the probit
        * (good by good: selgoods() and the probit-only variables of the good)
        local sel 0
        local sgoods "`e(selgoods)'"
        if "`e(selection)'" != "" local sel : list g in sgoods
        local zg ""
        if `sel' local zg "`e(sel_z_`g')'"
        mata: _duvme_V("`shv'", "`uvv'", "`lnx'", "`X'", "`wt'", "`e(clustvar)'", "`psu'", "`st'", "`fp'", ///
            "`es'", `wbar', `L0', `vbar', `L1', `good', "`V'", "`Vs'", "`chk'", `sel', "`zg'")
        * the slopes recomputed here must be those of duvm
        return scalar dev_b0 = el(`chk', 1, 1)
        return scalar dev_b1 = el(`chk', 1, 2)
        matrix colnames `V' = a0 b0 a1 b1
        matrix rownames `V' = a0 b0 a1 b1
        matrix colnames `Vs' = wbar L0 b0 vbar L1 b1
        matrix rownames `Vs' = wbar L0 b0 vbar L1 b1
        return matrix V = `V'
        return matrix Vs = `Vs'
    }
    return scalar hasV = `hasV'
    return matrix theta = `theta'
end

version 14.2
mata:
mata set matastrict on

// influence functions of (a0, b0, a1, b1), aggregated by the design
void _duvme_V(string scalar wv, string scalar uv, string scalar lxv, string scalar Xv,
              string scalar wtv, string scalar clv, string scalar psuv, string scalar stv,
              string scalar fpv, string scalar esv, real scalar wbar, real scalar L0,
              real scalar vbar, real scalar L1, real scalar good,
              string scalar Vname, string scalar Vsname, string scalar chkname,
              real scalar hasl, string scalar zxv)
{
    real colvector es, w, u, lx, wt, cl, psu, st, fp, ord, sel, dd, lamv, dlam, sw, idx
    real matrix X, Phi, B0, B1, info, Vs, J, Zx, Zp, IFg, mu, DZ, lam
    real rowvector chk
    real scalar n, b0, b1, okp

    es = st_data(., esv)
    sel = selectindex(es :== 1)
    w  = st_data(sel, wv);  u  = st_data(sel, uv);  lx = st_data(sel, lxv)
    X  = st_data(sel, Xv);  wt = st_data(sel, wtv); cl = st_data(sel, clv)
    psu = st_data(sel, psuv); st = st_data(sel, stv); fp = st_data(sel, fpv)
    n = rows(w)
    // households sorted by cluster (row index as the second key: order() is not stable)
    ord = order((cl, (1::n)), (1, 2))
    w = w[ord]; u = u[ord]; lx = lx[ord]; X = X[ord, .]; wt = wt[ord]
    cl = cl[ord]; psu = psu[ord]; st = st[ord]; fp = fp[ord]
    info = panelsetup(cl, 1)
    B0 = st_matrix("e(beta0)"); B1 = st_matrix("e(beta1)")
    chk = J(1, 2, 0)
    // selection: the probit of duvm (same regressors, same algorithm, so the
    // same Mills ratio): constant, x, cluster means of x, probit-only variables
    lam = J(n, 0, .); DZ = J(n, 0, .); IFg = J(n, 0, .)
    if (hasl) {
        if (zxv != "") Zx = st_data(sel, tokens(zxv))[ord, .]
        else           Zx = J(n, 0, .)
        idx = _duvme_expand(info)
        sw = panelsum(wt, info)
        mu = panelsum(X :* wt, info) :/ sw
        Zp = (J(n, 1, 1), X, mu[idx, .], Zx)
        dd = (w :> 0) :& (w :< .)
        (void) _duvme_probit(dd, Zp, wt, lamv, dlam, IFg, okp)
        lam = lamv
        DZ = dlam :* Zp
    }
    // the six statistics (wbar, L0, b0, vbar, L1, b1) and their covariance
    Phi = (_duvme_if(w, J(n, 1, 1), lx, X, wt, info, wbar, L0, B0[1, good], chk, 1, J(n, 0, .), J(n, 0, .), J(n, 0, .)),
           _duvme_if(u, (u :< .), lx, X, wt, info, vbar, L1, B1[1, good], chk, 2, lam, DZ, IFg))
    Vs = _duvme_vagg(Phi, psu, st, fp)
    // (a0, b0, a1, b1): a0 = wbar - b0 L0, a1 = vbar - b1 L1
    b0 = B0[1, good]; b1 = B1[1, good]
    J = (1, -b0, -L0, 0, 0, 0 \ 0, 0, 1, 0, 0, 0 \ 0, 0, 0, 1, -b1, -L1 \ 0, 0, 0, 0, 0, 1)
    st_matrix(Vname, J * Vs * J')
    st_matrix(Vsname, Vs)
    st_matrix(chkname, chk)
}

// one equation: influence functions of the mean of y, the mean of ln x and the
// within-cluster slope b, over the sample marked by m. With a Mills ratio lam
// (selection), the equation holds it as a regressor, and the influence
// function of the slope holds the term of the probit: DZ = dlam z', IFg the
// influence functions of the probit coefficients (as in duvm's _duvm_if)
real matrix _duvme_if(real colvector y, real colvector m, real colvector lx, real matrix X0,
                      real colvector wt, real matrix info, real scalar ybar, real scalar Lbar,
                      real scalar bduvm, real rowvector chk, real scalar slot,
                      real matrix lam, real matrix DZ, real matrix IFg)
{
    real colvector wm, sw, ys, e, ifb, ifm, ifl, bb
    real matrix X, Xt, XX, sx, IF
    real scalar W, b, kk
    X = (X0, lam)
    kk = cols(X)
    wm = wt :* m
    ys = editmissing(y, 0)
    sw = panelsum(wm, info)
    sw = sw :+ (sw :== 0)
    // within-cluster deviations (weighted cluster means over the sample)
    sx = panelsum(X :* wm, info) :/ sw
    Xt = (X - sx[_duvme_expand(info), .]) :* m
    ys = (ys - (panelsum(ys :* wm, info) :/ sw)[_duvme_expand(info)]) :* m
    XX = invsym(quadcross(Xt, wm, Xt))
    bb = XX * quadcross(Xt, wm, ys)
    b = bb[1]
    chk[slot] = abs(b - bduvm) / (1 + abs(bduvm))
    e = (ys - Xt * bb) :* m
    IF = (Xt :* (wm :* e)) * XX
    if (cols(lam)) IF = IF - IFg * (quadcross(Xt, wm, bb[kk] :* DZ)' * XX)
    ifb = IF[., 1]
    W = sum(wm)
    ifm = wm :* (editmissing(y, 0) :- ybar) / W
    ifl = wm :* (lx :- Lbar) / W
    return((ifm, ifl, ifb))
}

// the probit of duvm (_duvm_probit in duvm.ado, same code: the Mata of an
// ado-file is not visible from another)
real colvector _duvme_probit(real colvector dd, real matrix Z, real colvector w,
                             real colvector lam, real colvector dlam, real matrix IF,
                             real scalar ok)
{
    real colvector g, xb, P, f, r, a, step, aq, rq
    real matrix Ii
    real scalar it, n, n1
    n = rows(dd)
    g = J(cols(Z), 1, 0)
    n1 = sum(dd)
    ok = (n1 > 0 & n1 < n)
    if (!ok) {
        lam = J(n, 1, 0); dlam = lam; IF = J(n, cols(Z), 0)
        return(g)
    }
    for (it = 1; it <= 200; it++) {
        xb = Z * g
        P  = rowmin((rowmax((normal(xb), J(n, 1, 1e-15))), J(n, 1, 1 - 1e-15)))
        f  = normalden(xb)
        r  = (dd - P) :* f :/ (P :* (1 :- P))
        a  = (f :^ 2) :/ (P :* (1 :- P))
        Ii = invsym(quadcross(Z, w :* a, Z))
        step = Ii * quadcross(Z, w :* r)
        g = g + step
        if (max(abs(step)) < 1e-11) break
    }
    xb = Z * g
    lam  = exp(lnnormalden(xb) - lnnormal(xb))
    dlam = -lam :* (xb + lam)
    // the influence function with the OBSERVED Hessian (see _duvm_probit)
    aq = 2 :* dd :- 1
    rq = aq :* normalden(aq :* xb) :/ normal(aq :* xb)
    Ii = invsym(quadcross(Z, w :* (rq :* (rq :+ xb)), Z))
    IF = ((w :* rq) :* Z) * Ii
    return(g)
}

real colvector _duvme_expand(real matrix info)
{
    real colvector idx
    real scalar i
    idx = J(info[rows(info), 2], 1, .)
    for (i = 1; i <= rows(info); i++) idx[|info[i, 1] \ info[i, 2]|] = J(info[i, 2] - info[i, 1] + 1, 1, i)
    return(idx)
}

// the aggregation of duvm: PSU totals, centred within strata, (1-f) nh/(nh-1)
real matrix _duvme_vagg(real matrix Phi, real colvector psu, real colvector strat,
                        real colvector fpc)
{
    real matrix Php, V, D, info
    real colvector ord, st, fp, u, sel
    real scalar h, nh, f
    ord = order((psu, (1::rows(psu))), (1, 2))
    info = panelsetup(psu[ord], 1)
    Php = panelsum(Phi[ord, .], info)
    st  = strat[ord][info[., 1]]
    fp  = fpc[ord][info[., 1]]
    V = J(cols(Phi), cols(Phi), 0)
    u = uniqrows(st)
    for (h = 1; h <= rows(u); h++) {
        sel = selectindex(st :== u[h])
        nh = rows(sel)
        if (nh < 2) continue
        f = fp[sel[1]]
        if (f >= .) f = 0
        else if (f >= 1) f = nh / f
        D = Php[sel, .] :- mean(Php[sel, .])
        V = V + (1 - f) * nh / (nh - 1) * quadcross(D, D)
    }
    return((V + V') / 2)
}

// standard error of the log-quantity curve ln(a0 + b0 l) + l - (a1 + b1 l):
// gradient over (a0, b0, a1, b1) = (1/w, l/w, -1, -l); missing where w <= 0
void _duvme_qse(string scalar vn, string scalar shn, string scalar lxn, string scalar tn, real matrix V,
                real scalar norm, real scalar ref, real scalar sh0)
{
    real colvector sh, lx, t, se, ok
    real matrix G
    sh = st_data(., shn); lx = st_data(., lxn); t = st_data(., tn)
    ok = (t :== 1) :& (sh :> 0) :& (sh :< .) :& (lx :< .)
    G = (1 :/ sh, lx :/ sh, J(rows(sh), 1, -1), -lx)
    // normalized: ln q(l) - ln q(ref); a1 cancels, the rest is a difference
    if (norm) G = (1 :/ sh :- 1 / sh0, lx :/ sh :- ref / sh0, J(rows(sh), 1, 0), -(lx :- ref))
    se = sqrt(rowsum((G * V) :* G))
    se = se :/ ok
    st_store(., vn, se)
}
end
