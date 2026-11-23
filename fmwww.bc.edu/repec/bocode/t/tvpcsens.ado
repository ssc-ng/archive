*! tvpcsens 1.0.0  21nov2026
*! Sensitivity of TV-PC causal graphs to the number of lags and to alpha
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane
*
* Reproduces the two robustness exercises of Aung et al. (2026):
*   Sec. 4.4 / Fig. 12  total lags m = 3, 4, 5 (quarterly steps)
*   Sec. 5 / Table 1    F1 of TV-PC vs PCMCI over p = alpha values
* For every (m, alpha) it re-runs tvpc (and optionally tvpcmci) and reports
* edge counts, Jaccard similarity to the baseline graph, and F1 against a
* ground truth when one is supplied.

program define tvpcsens, rclass
    version 15.0
    syntax varlist(numeric min=2) [if] [in] [,                ///
        LAGSlist(numlist integer >0 sort) ALPHAs(numlist >0 <1 sort) ///
        LAGStep(integer 1) VARiant(string) NOCONtemp             ///
        TARGet(varname) TRUTH(name) PCMCI PCAlpha(real 0.2)      ///
        GRaph NAME(string) ]
    if ("`lagslist'" == "") local lagslist 4
    if ("`alphas'" == "")   local alphas 0.05
    if ("`variant'" == "")  local variant original
    if ("`name'" == "")     local name tvpcsens
    if ("`target'" != "") {
        local tpos : list posof "`target'" in varlist
        if (`tpos' == 0) {
            di as err "target() must be one of the analysed variables"
            exit 198
        }
    }
    if ("`truth'" != "") {
        capture confirm matrix `truth'
        if (_rc) {
            di as err "truth(): matrix `truth' not found"
            exit 111
        }
        local tr "truth(`truth')"
    }
    marksample touse, novarlist
    local minlag : word 1 of `lagslist'

    tempname hold R B0 Lk row
    _estimates hold `hold', restore nullok

    local nl : word count `lagslist'
    local na : word count `alphas'
    local r 0
    local maps ""
    foreach m of local lagslist {
        foreach a of local alphas {
            local ++r
            qui tvpc `varlist' if `touse', lags(`m') lagstep(`lagstep') alpha(`a') ///
                variant(`variant') `nocontemp' `tr' notable
            matrix `Lk' = e(links)
            if (`r' == 1) matrix `B0' = `Lk'
            mata: _tvpcsens_jac("`B0'", "`Lk'", `minlag')
            local f1 = .
            local pr = .
            local rc = .
            if ("`truth'" != "") {
                local f1 = e(F1)
                local pr = e(precision)
                local rc = e(recall)
            }
            matrix `row' = (`m', `a', e(N), e(n_edges), e(n_lagged), e(n_cdir), ///
                e(n_cund), e(ntests), `jvar', `jlag', `pr', `rc', `f1')
            * Fig. 12: drivers of the target at the first alpha
            if ("`target'" != "" & "`a'" == "`: word 1 of `alphas''") {
                mata: _tvpcsens_drv("`Lk'", `tpos', "`varlist'")
                local drv`m' "`drivers'"
                local drn`m' "`driven'"
            }
            if ("`pcmci'" != "") {
                qui tvpcmci `varlist' if `touse', taumax(`m') lagstep(`lagstep') ///
                    alpha(`a') pcalpha(`pcalpha') `tr' notable
                local pf1 = .
                if ("`truth'" != "") local pf1 = e(F1)
                matrix `row' = (`row', e(n_edges), `pf1')
            }
            if (`r' == 1) matrix `R' = `row'
            else          matrix `R' = `R' \ `row'
        }
    }
    local cn m alpha N edges lagged cdir cund ntests jac_var jac_lag precision recall F1
    if ("`pcmci'" != "") local cn `cn' pcmci_edges pcmci_F1
    matrix colnames `R' = `cn'
    local rn ""
    forvalues i = 1/`=rowsof(`R')' {
        local rn `rn' run`i'
    }
    matrix rownames `R' = `rn'

    * ------------------------------------------------------------ table
    di
    di as text "{bf:Table S1. Sensitivity of the TV-PC causal graph to lags (m) and alpha}"
    di as text "Aung et al. (2026, Sec. 4.4 and Table 1); baseline = first row"
    local w = 70
    if ("`truth'" != "") local w = `w' + 8
    if ("`pcmci'" != "") local w = `w' + 10
    di as text "{hline `w'}"
    di as text %4s "m" %9s "alpha" %6s "N" %7s "Edges" %7s "Lagged" %6s "C.dir" ///
        %6s "C.und" %7s "Tests" %8s "J(var)" %8s "J(lag)" _c
    if ("`truth'" != "") di as text %8s "F1" _c
    if ("`pcmci'" != "" & "`truth'" != "") di as text %10s "F1 PCMCI" _c
    else if ("`pcmci'" != "") di as text %10s "PCMCI e." _c
    di
    di as text "{hline `w'}"
    forvalues i = 1/`=rowsof(`R')' {
        di as res %4.0f `R'[`i',1] %9.4g `R'[`i',2] %6.0f `R'[`i',3] %7.0f `R'[`i',4] ///
            %7.0f `R'[`i',5] %6.0f `R'[`i',6] %6.0f `R'[`i',7] %7.0f `R'[`i',8] ///
            %8.3f `R'[`i',9] %8.3f `R'[`i',10] _c
        if ("`truth'" != "") di as res %8.4f `R'[`i',13] _c
        if ("`pcmci'" != "" & "`truth'" != "") di as res %10.4f `R'[`i',15] _c
        else if ("`pcmci'" != "") di as res %10.0f `R'[`i',14] _c
        di
    }
    di as text "{hline `w'}"
    di as text "J(var): Jaccard similarity of cause->effect variable pairs with the baseline;"
    di as text "J(lag): Jaccard similarity of (cause, effect, lag) links with lag <= `minlag'."
    if ("`truth'" != "") di as text "F1: gCastle MetricsDAG F1 against truth(`truth')."

    if ("`target'" != "") {
        di
        di as text "{bf:Table S2. Causal relationship map of `target' across lag choices (cf. Fig. 12), alpha = `: word 1 of `alphas''}"
        di as text "{hline `w'}"
        foreach m of local lagslist {
            di as text "m = `m'" _col(10) "drivers of `target'(t): " as res "`drv`m''"
            di as text _col(10) "`target' lags drive:   " as res "`drn`m''"
        }
        di as text "{hline `w'}"
    }

    * ------------------------------------------------------------ graph
    if ("`graph'" != "") {
        preserve
        qui {
            clear
            svmat double `R', name(sv)
            rename sv1 m
            rename sv2 alpha
            rename sv4 edges
            rename sv13 F1
            gen lalpha = log10(alpha)
        }
        local plots ""
        local leg ""
        local q 0
        local pal `""33 102 172" "214 96 77" "27 158 119" "117 112 179" "230 171 2""'
        local yv = cond("`truth'" != "", "F1", "edges")
        foreach m of local lagslist {
            local ++q
            local col : word `=mod(`q' - 1, 5) + 1' of `pal'
            local plots `plots' (connected `yv' lalpha if m == `m', lcolor("`col'") mcolor("`col'") msymbol(O))
            local leg `leg' `q' "TV-PC, m = `m'"
            if ("`pcmci'" != "" & "`truth'" != "") {
                local ++q
                local plots `plots' (connected sv15 lalpha if m == `m', lcolor("`col'") mcolor("`col'") msymbol(Th) lpattern(dash))
                local leg `leg' `q' "PCMCI, m = `m'"
            }
        }
        local xl ""
        foreach a of local alphas {
            local xl `xl' `=log10(`a')' "`a'"
        }
        local yt = cond("`truth'" != "", "F1 score", "Number of edges")
        twoway `plots', xlabel(`xl', labsize(small)) xtitle("alpha (log scale)", size(small)) ///
            ytitle("`yt'", size(small)) legend(order(`leg') size(small) region(lcolor(white))) ///
            title("Sensitivity of the causal graph", size(medium) color(black)) ///
            graphregion(color(white)) plotregion(color(white)) name(`name', replace)
        restore
    }
    return matrix table = `R'
    return local lagslist "`lagslist'"
    return local alphas "`alphas'"
end

mata:
// Jaccard similarity between two links tables
void _tvpcsens_jac(string scalar an, string scalar bn, real scalar mlag)
{
    real matrix A, B
    real scalar nv, i, j, ia, ib, inter, uni, ka, kb
    real matrix VA, VB
    A = st_matrix(an)
    B = st_matrix(bn)
    nv = 0
    if (A[1, 1] != .) {
        nv = max((nv, max(A[., 1..2])))
    }
    if (B[1, 1] != .) {
        nv = max((nv, max(B[., 1..2])))
    }
    if (nv == 0) {
        st_local("jvar", "1")
        st_local("jlag", "1")
        return
    }
    VA = J(nv, nv, 0)
    VB = J(nv, nv, 0)
    if (A[1, 1] != .) {
        for (i = 1; i <= rows(A); i++) {
            VA[A[i, 2], A[i, 1]] = 1
        }
    }
    if (B[1, 1] != .) {
        for (i = 1; i <= rows(B); i++) {
            VB[B[i, 2], B[i, 1]] = 1
        }
    }
    inter = sum(VA :* VB)
    uni = sum((VA + VB) :> 0)
    if (uni > 0) {
        st_local("jvar", strofreal(inter / uni, "%18.0g"))
    }
    else {
        st_local("jvar", "1")
    }
    // lag-level, lags <= mlag
    inter = 0
    ka = 0
    kb = 0
    if (A[1, 1] != .) {
        ka = sum(A[., 3] :<= mlag)
    }
    if (B[1, 1] != .) {
        kb = sum(B[., 3] :<= mlag)
    }
    if (A[1, 1] != . & B[1, 1] != .) {
        for (ia = 1; ia <= rows(A); ia++) {
            if (A[ia, 3] > mlag) {
                continue
            }
            for (ib = 1; ib <= rows(B); ib++) {
                if (A[ia, 1] == B[ib, 1] & A[ia, 2] == B[ib, 2] & A[ia, 3] == B[ib, 3]) {
                    inter = inter + 1
                }
            }
        }
    }
    uni = ka + kb - inter
    if (uni > 0) {
        st_local("jlag", strofreal(inter / uni, "%18.0g"))
    }
    else {
        st_local("jlag", "1")
    }
}

// drivers / driven text for one target
void _tvpcsens_drv(string scalar ln, real scalar tg, string scalar vlist)
{
    real matrix L
    string rowvector vn
    string scalar s1, s2
    real scalar q
    L = st_matrix(ln)
    vn = tokens(vlist)
    s1 = ""
    s2 = ""
    if (L[1, 1] != .) {
        for (q = 1; q <= rows(L); q++) {
            if (L[q, 1] == tg) {
                if (L[q, 3] == 0) {
                    s1 = s1 + vn[L[q, 2]] + "(t) "
                }
                else {
                    s1 = s1 + vn[L[q, 2]] + "(t-" + strofreal(L[q, 3]) + ") "
                }
            }
            if (L[q, 2] == tg & L[q, 1] != tg & L[q, 3] > 0) {
                s2 = s2 + vn[L[q, 1]] + "<-t-" + strofreal(L[q, 3]) + " "
            }
        }
    }
    if (s1 == "") {
        s1 = "(none)"
    }
    if (s2 == "") {
        s2 = "(none)"
    }
    st_local("drivers", s1)
    st_local("driven", s2)
}
end
