*! tvpc 1.0.0  21nov2026
*! Time-variant Peter-Clark (TV-PC) causal discovery for multivariate time series
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane
*
* Implements Aung, Zhu, Lee, Guo & Li (2026), "Uncover temporal causal
* interrelationships between key economic indicators through Peter-Clark
* algorithm", Computational Economics, doi:10.1007/s10614-026-11411-x
*
* Step -> paper map (full map in help tvpc_methods)
*   Step 1  standardisation x'' = (x - mu)/sigma ............. Eq. (2.2), Fig. 1
*   Step 2  time-lag inclusion, V = {X(i,t-k)} n(m+1) nodes ... Sec. 2.1.1, Fig. 1
*   Step 3  edge restrictions (no self loops, no lag-lag edges,
*           no current->lag edges) ........................... Sec. 2.1.1
*   Step 4a skeleton: CI tests H0: Xi _||_ Xj | S, |S| = 0,1,..
*           edge removed if p >= alpha ....................... Sec. 2.1.2
*   Step 4b Fisher z test  Z = sqrt(u-|S|-3)*0.5*ln((1+r)/(1-r)) Eq. (2.1)
*   Step 4c orientation: background knowledge, v-structures,
*           Meek rules R1-R4 ................................. Sec. 2.1.3
*   Step 4d return PDAG ...................................... Sec. 2.1.4
* The skeleton search, conditioning-set enumeration order and orientation
* reproduce the gCastle PC implementation used by the authors (Zhang et al.
* 2021) step for step, so the output graph is identical to gCastle's.

program define tvpc, eclass
    version 15.0
    if replay() {
        if ("`e(cmd)'" != "tvpc") error 301
        _tvpc_display `0'
        exit
    }
    local cmdline `"tvpc `0'"'
    syntax varlist(numeric min=2) [if] [in] [,            ///
        Lags(integer 4) LAGStep(integer 1) Alpha(real 0.05) ///
        VARiant(string) MAXDepth(integer -1)               ///
        NOCONtemp NOSTANDardize                            ///
        TRUTH(name) STRength                               ///
        REPs(integer 0) BLOCKlen(integer 0) SEED(string)   ///
        NOTABle NOEDGEs NOLAGmap NOSUMmary NOLOg           ///
        GRaph(string asis) * ]

    * ---------------------------------------------------------------- checks
    if (`lags' < 1)     {
        di as err "lags() must be a positive integer"
        exit 198
    }
    if (`lagstep' < 1)  {
        di as err "lagstep() must be a positive integer"
        exit 198
    }
    if (`alpha' <= 0 | `alpha' >= 1) {
        di as err "alpha() must lie strictly between 0 and 1"
        exit 198
    }
    if ("`variant'" == "") local variant "original"
    local variant = lower("`variant'")
    if !inlist("`variant'", "original", "stable") {
        di as err "variant() must be original or stable"
        exit 198
    }
    local stable = ("`variant'" == "stable")
    if (`reps' < 0) {
        di as err "reps() must be non-negative"
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
        di as err "data must be {bf:tsset} (time variable needed to build lags)"
        exit 111
    }
    if ("`pvar'" != "") {
        di as err "tvpc is for a single time series; panel data are not supported"
        exit 198
    }

    marksample touse0
    * -------------------------------------------- Step 1: standardisation
    local i 0
    local zlist ""
    foreach v of local varlist {
        local ++i
        tempvar z`i'
        qui summarize `v' if `touse0'
        if (r(N) < 3) {
            di as err "too few observations"
            exit 2001
        }
        if (r(sd) == 0) {
            di as err "variable `v' is constant"
            exit 198
        }
        * population s.d. (ddof = 0), as in the standard scaler of Eq. (2.2)
        local sdp = r(sd) * sqrt((r(N) - 1) / r(N))
        if ("`nostandardize'" != "") {
            qui gen double `z`i'' = `v' if `touse0'
        }
        else {
            qui gen double `z`i'' = (`v' - r(mean)) / `sdp' if `touse0'
        }
        local zlist `zlist' `z`i''
    }

    * ------------------------------------------- Step 2: time-lag inclusion
    * node order (paper Sec. 2.1.1):  X(1,t), X(1,t-1),..,X(1,t-m), ..., X(n,t-m)
    local nodes ""
    local nodenames ""
    local i 0
    foreach v of local varlist {
        local ++i
        forvalues k = 0/`lags' {
            tempvar n`i'_`k'
            local per = `k' * `lagstep'
            qui gen double `n`i'_`k'' = L`per'.`z`i''
            local nodes `nodes' `n`i'_`k''
            if (`k' == 0) local nodenames `nodenames' `v'
            else          local nodenames `nodenames' L`per'.`v'
        }
    }
    tempvar touse
    qui gen byte `touse' = `touse0'
    markout `touse' `nodes'
    qui count if `touse'
    local N = r(N)
    local p = `nv' * (`lags' + 1)
    if (`N' <= `p' + 3) {
        di as err "too few usable observations (`N') for `p' nodes; reduce lags()"
        exit 2001
    }
    if (`blocklen' == 0) local blocklen = max(1, floor(`N'^(1/3)))
    if ("`seed'" != "") set seed `seed'

    * ------------------------------------------- truth matrix (optional)
    if ("`truth'" != "") {
        capture confirm matrix `truth'
        if (_rc) {
            di as err "truth(): matrix `truth' not found"
            exit 111
        }
        if (colsof(`truth') != 3) {
            di as err "truth() must have 3 columns: cause effect lag"
            exit 503
        }
    }

    * ------------------------------------------- Steps 3-4: TV-PC in Mata
    local verbose = ("`nolog'" == "")
    mata: _tvpc_main("`nodes'", "`touse'", `nv', `lags', `lagstep',   ///
        `alpha', `stable', `maxdepth', ("`nocontemp'" != ""), `reps',     ///
        `blocklen', `verbose')

    * names on the node-level matrices
    foreach M in G Skel Pmax Psep Rmarg Rmin {
        matrix rownames __tvpc_`M' = `nodenames'
        matrix colnames __tvpc_`M' = `nodenames'
    }
    if (`reps' > 0) {
        foreach M in Fdir Fadj {
            matrix rownames __tvpc_`M' = `nodenames'
            matrix colnames __tvpc_`M' = `nodenames'
        }
    }
    matrix colnames __tvpc_links = effect cause lag period type r_marg r_min p_max stab
    matrix rownames __tvpc_lagmap = `varlist'
    matrix colnames __tvpc_lagmap = `varlist'
    matrix rownames __tvpc_deg = `varlist'
    matrix colnames __tvpc_deg = in_links out_links drivers driven own_lags

    * ------------------------------------------- post results
    tempvar tousek
    qui gen byte `tousek' = `touse'
    ereturn post, esample(`touse') obs(`N')
    ereturn scalar n_vars   = `nv'
    ereturn scalar lags     = `lags'
    ereturn scalar lagstep  = `lagstep'
    ereturn scalar alpha    = `alpha'
    ereturn scalar nodes    = `p'
    ereturn scalar ntests   = scalar(__tvpc_ntests)
    ereturn scalar depth    = scalar(__tvpc_depth)
    ereturn scalar n_edges  = scalar(__tvpc_nedges)
    ereturn scalar n_lagged = scalar(__tvpc_nlag)
    ereturn scalar n_cdir   = scalar(__tvpc_ncdir)
    ereturn scalar n_cund   = scalar(__tvpc_ncund)
    ereturn scalar n_forbid = scalar(__tvpc_nforbid)
    ereturn scalar reps     = `reps'
    if (`reps' > 0) ereturn scalar blocklen = `blocklen'
    ereturn local  varlist  "`varlist'"
    ereturn local  nodenames "`nodenames'"
    ereturn local  variant  "`variant'"
    ereturn local  citest   "fisherz"
    ereturn local  contemp  = cond("`nocontemp'" != "", "no", "yes")
    ereturn local  timevar  "`tvar'"
    ereturn local  title    "Time-variant Peter-Clark (TV-PC) causal discovery"
    ereturn local  cmdline  `"`cmdline'"'
    ereturn local  graphcmd "tvpcgraph"
    ereturn local  cmd      "tvpc"
    ereturn matrix G      = __tvpc_G
    ereturn matrix Skel   = __tvpc_Skel
    ereturn matrix Pmax   = __tvpc_Pmax
    ereturn matrix Psep   = __tvpc_Psep
    ereturn matrix Rmarg  = __tvpc_Rmarg
    ereturn matrix Rmin   = __tvpc_Rmin
    ereturn matrix links  = __tvpc_links
    ereturn matrix lagmap = __tvpc_lagmap
    ereturn matrix degree = __tvpc_deg
    if (`reps' > 0) {
        ereturn matrix Fdir = __tvpc_Fdir
        ereturn matrix Fadj = __tvpc_Fadj
    }
    foreach s in ntests depth nedges nlag ncdir ncund nforbid {
        capture scalar drop __tvpc_`s'
    }

    * ------------------------------------------- scoring against a truth
    if ("`truth'" != "") {
        _tvpc_score, truth(`truth')
    }

    * ------------------------------------------- strength (extension)
    if ("`strength'" != "") {
        _tvpc_strength `tousek' "`nodes'"
    }

    * ------------------------------------------- display
    if ("`notable'" == "") {
        _tvpc_display, `noedges' `nolagmap' `nosummary'
    }

    * ------------------------------------------- graphs
    if (`"`graph'"' != "") {
        tvpcgraph, `graph' `options'
    }
    else if (`"`options'"' != "") {
        di as err `"option(s) `options' not allowed"'
        exit 198
    }
end

* ======================================================================
* strength of causal links (extension, paper Sec. 6 "future research")
* OLS of each standardised X_j(t) on its directed parents
* ======================================================================
program define _tvpc_strength, eclass
    args touse nodes
    tempname L S row
    matrix `L' = e(links)
    local nv = e(n_vars)
    local m  = e(lags)
    local K = rowsof(`L')
    local nr 0
    if (`L'[1,1] >= .) exit
    tempname hold
    _estimates hold `hold', copy restore
    forvalues j = 1/`nv' {
        local rhs ""
        local cs ""
        local ls ""
        forvalues k = 1/`K' {
            if (`L'[`k',1] == `j' & `L'[`k',5] <= 2) {
                local c  = `L'[`k',2]
                local lg = `L'[`k',3]
                local idx = (`c' - 1) * (`m' + 1) + `lg' + 1
                local nd : word `idx' of `nodes'
                local rhs `rhs' `nd'
                local cs `cs' `c'
                local ls `ls' `lg'
            }
        }
        if ("`rhs'" == "") continue
        local yidx = (`j' - 1) * (`m' + 1) + 1
        local y : word `yidx' of `nodes'
        quietly regress `y' `rhs' if `touse'
        local r2 = e(r2)
        local df = e(df_r)
        local q 0
        foreach x of local rhs {
            local ++q
            local c  : word `q' of `cs'
            local lg : word `q' of `ls'
            local b  = _b[`x']
            local se = _se[`x']
            local t  = `b' / `se'
            local pv = 2 * ttail(`df', abs(`t'))
            matrix `row' = (`j', `c', `lg', `b', `se', `t', `pv', `r2')
            if (`nr' == 0) matrix `S' = `row'
            else matrix `S' = `S' \ `row'
            local ++nr
        }
    }
    _estimates unhold `hold'
    if (`nr' == 0) exit
    matrix colnames `S' = effect cause lag coef se t p r2
    ereturn matrix strength = `S'
end

* ======================================================================
* Mata engine
* ======================================================================
mata:

// ---------------------------------------------------------------------
// CPython set emulation: gCastle enumerates conditioning sets with
// itertools.combinations over a Python set of numpy int64 node indices.
// The iteration order of that set is the hash-table slot order, which
// we reproduce exactly (hash(k) = k for non-negative ints).
// ---------------------------------------------------------------------
void _tvpc_ps_insert(real rowvector tab, real scalar key)
{
    real scalar mask, perturb, i, j
    mask = cols(tab) - 1
    perturb = key
    i = mod(key, mask + 1)
    while (1) {
        if (tab[i + 1] == .) {
            tab[i + 1] = key
            return
        }
        if (i + 9 <= mask) {
            for (j = 1; j <= 9; j++) {
                if (tab[i + j + 1] == .) {
                    tab[i + j + 1] = key
                    return
                }
            }
        }
        perturb = floor(perturb / 32)
        i = mod(i * 5 + 1 + perturb, mask + 1)
    }
}

real rowvector _tvpc_ps_resize(real rowvector tab, real scalar minused)
{
    real scalar newsize, s
    real rowvector nt
    newsize = 8
    while (newsize <= minused) {
        newsize = newsize * 2
    }
    nt = J(1, newsize, .)
    for (s = 1; s <= cols(tab); s++) {
        if (tab[s] != .) {
            _tvpc_ps_insert(nt, tab[s])
        }
    }
    return(nt)
}

// set(iterable) built by successive set_add_entry calls
real rowvector _tvpc_ps_fromiter(real rowvector keys)
{
    real rowvector tab
    real scalar fill, q
    tab = J(1, 8, .)
    fill = 0
    for (q = 1; q <= cols(keys); q++) {
        _tvpc_ps_insert(tab, keys[q])
        fill = fill + 1
        if (fill * 5 >= (cols(tab) - 1) * 3) {
            tab = _tvpc_ps_resize(tab, fill * 4)
        }
    }
    return(tab)
}

// iteration order of  (set) - {key}
real rowvector _tvpc_ps_minus(real rowvector tab, real scalar key)
{
    real scalar used, s, newsize, fill
    real rowvector nt, out
    used = sum(tab :!= .)
    if (floor(used / 4) > 1) {
        // set_copy_and_difference: set_merge into an empty set
        newsize = 8
        if (used * 5 >= 21) {
            while (newsize <= used * 2) {
                newsize = newsize * 2
            }
        }
        if (newsize == cols(tab)) {
            nt = tab
        }
        else {
            nt = J(1, newsize, .)
            for (s = 1; s <= cols(tab); s++) {
                if (tab[s] != .) {
                    _tvpc_ps_insert(nt, tab[s])
                }
            }
        }
    }
    else {
        nt = J(1, 8, .)
        fill = 0
        for (s = 1; s <= cols(tab); s++) {
            if (tab[s] != . & tab[s] != key) {
                _tvpc_ps_insert(nt, tab[s])
                fill = fill + 1
                if (fill * 5 >= (cols(nt) - 1) * 3) {
                    nt = _tvpc_ps_resize(nt, fill * 4)
                }
            }
        }
    }
    out = J(1, 0, .)
    for (s = 1; s <= cols(nt); s++) {
        if (nt[s] != . & nt[s] != key) {
            out = (out, nt[s])
        }
    }
    return(out)
}

// ---------------------------------------------------------------------
// Fisher z conditional-independence test, Eq. (2.1)
// R: correlation matrix of the node data, u: sample size
// returns p-value; r returns the (partial) correlation
// ---------------------------------------------------------------------
real scalar _tvpc_fz(real matrix R, real scalar u, real scalar x,
                     real scalar y, real rowvector S, real scalar r)
{
    real scalar k, z
    real rowvector idx
    real matrix sub, PM
    k = cols(S)
    if (k == 0) {
        r = R[x, y]
    }
    else {
        idx = (x, y, S)
        sub = R[idx, idx]
        PM = luinv(sub)
        if (hasmissing(PM)) {
            PM = pinv(sub)
        }
        r = -PM[1, 2] / sqrt(abs(PM[1, 1] * PM[2, 2]))
    }
    if (r > 0.99999) r = 0.99999
    if (r < -0.99999) r = -0.99999
    z = sqrt(u - k - 3) * 0.5 * ln((1 + r) / (1 - r))
    return(2 * (1 - normal(abs(z))))
}

// gCastle _loop(): continue while some pair i<j has |adj(i)\{j}| >= d
real scalar _tvpc_loop(real matrix sk, real scalar d)
{
    real scalar p, i, j, a
    p = rows(sk)
    for (i = 1; i < p; i++) {
        a = sum(sk[i, .] :!= 0)
        for (j = i + 1; j <= p; j++) {
            if (a - (sk[i, j] != 0) >= d) {
                return(1)
            }
        }
    }
    return(0)
}

// ---------------------------------------------------------------------
// skeleton search (gCastle find_skeleton, variants original / stable)
// ---------------------------------------------------------------------
real matrix _tvpc_skeleton(real matrix R, real scalar u, real matrix forb,
        real scalar alpha, real scalar stable, real scalar maxdepth,
        real matrix SepKeys, real matrix SepSets, real matrix Pmax,
        real matrix Rmin, real matrix Psep, real scalar ntests,
        real scalar depth, real scalar verbose)
{
    real scalar p, i, j, d, nz, pv, r, done, q, t2
    real matrix sk, C
    real rowvector row, keys, tab, z, c, S, sv
    r = 0
    p = rows(R)
    sk = J(p, p, 1) - I(p)
    sk = sk :* (1 :- (forb :* forb'))
    SepKeys = J(0, 2, .)
    SepSets = J(0, p, 0)
    Pmax = J(p, p, .)
    Rmin = J(p, p, .)
    Psep = J(p, p, .)
    ntests = 0
    depth = 0
    d = -1
    C = sk
    while (_tvpc_loop(sk, d)) {
        d = d + 1
        if (maxdepth >= 0 & d > maxdepth) {
            break
        }
        if (verbose) {
            printf("{txt}  conditioning sets |S| = %2.0f : %5.0f edges left, %9.0f tests so far\n",
                   d, sum(sk) / 2, ntests)
            displayflush()
        }
        if (stable) {
            C = sk
        }
        for (i = 1; i < p; i++) {
            for (j = i + 1; j <= p; j++) {
                if (sk[i, j] == 0) {
                    continue
                }
                if (stable) {
                    row = C[i, .]
                }
                else {
                    row = sk[i, .]
                }
                keys = selectindex(row :== 1) :- 1
                tab = _tvpc_ps_fromiter(keys)
                z = _tvpc_ps_minus(tab, j - 1) :+ 1
                nz = cols(z)
                if (nz < d) {
                    continue
                }
                c = (1..d)
                if (d == 0) {
                    c = J(1, 0, .)
                }
                done = 0
                while (!done) {
                    if (d == 0) {
                        S = J(1, 0, .)
                    }
                    else {
                        S = z[c]
                    }
                    pv = _tvpc_fz(R, u, i, j, S, r)
                    ntests = ntests + 1
                    if (d > depth) {
                        depth = d
                    }
                    if (Pmax[i, j] == . | pv > Pmax[i, j]) {
                        Pmax[i, j] = pv
                        Pmax[j, i] = pv
                    }
                    if (Rmin[i, j] == . | abs(r) < Rmin[i, j]) {
                        Rmin[i, j] = abs(r)
                        Rmin[j, i] = abs(r)
                    }
                    if (pv >= alpha) {
                        sk[i, j] = 0
                        sk[j, i] = 0
                        Psep[i, j] = pv
                        Psep[j, i] = pv
                        SepKeys = SepKeys \ (i, j)
                        sv = J(1, p, 0)
                        if (d > 0) {
                            sv[S] = J(1, d, 1)
                        }
                        SepSets = SepSets \ sv
                        done = 1
                    }
                    else {
                        // next combination (lexicographic, itertools order)
                        if (d == 0) {
                            done = 1
                        }
                        else {
                            q = d
                            while (q >= 1) {
                                if (c[q] < nz - d + q) {
                                    break
                                }
                                q = q - 1
                            }
                            if (q < 1) {
                                done = 1
                            }
                            else {
                                c[q] = c[q] + 1
                                for (t2 = q + 1; t2 <= d; t2++) {
                                    c[t2] = c[t2 - 1] + 1
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return(sk)
}

// ---------------------------------------------------------------------
// orientation (gCastle orient(): priori knowledge, v-structures,
// Meek rules 1-4 iterated to a fixed point)
// ---------------------------------------------------------------------
real matrix _tvpc_orient(real matrix sk, real matrix forb,
                         real matrix SepKeys, real matrix SepSets)
{
    real scalar p, nk, q, i, j, k, a, b, pr, l, kk, changed
    real matrix cp, old
    p = rows(sk)
    cp = sk :* (1 :- forb)
    nk = rows(SepKeys)
    // v-structures (colliders)
    for (q = 1; q <= nk; q++) {
        i = SepKeys[q, 1]
        j = SepKeys[q, 2]
        for (k = 1; k <= p; k++) {
            if (k == i | k == j) {
                continue
            }
            if (cp[i, k] + cp[k, i] != 0 & cp[k, j] + cp[j, k] != 0) {
                if (SepSets[q, k] == 0) {
                    if (cp[i, k] + cp[k, i] == 2) {
                        cp[k, i] = 0
                    }
                    if (cp[j, k] + cp[k, j] == 2) {
                        cp[k, j] = 0
                    }
                }
            }
        }
    }
    // Meek rules
    changed = 1
    while (changed) {
        old = cp
        for (i = 1; i < p; i++) {
            for (j = i + 1; j <= p; j++) {
                if (cp[i, j] * cp[j, i] != 1) {
                    continue
                }
                // rule 1
                for (pr = 1; pr <= 2; pr++) {
                    if (pr == 1) {
                        a = i
                        b = j
                    }
                    else {
                        a = j
                        b = i
                    }
                    for (k = 1; k <= p; k++) {
                        if (k == i | k == j) {
                            continue
                        }
                        if (cp[k, a] == 1 & cp[a, k] == 0 & cp[k, b] + cp[b, k] == 0) {
                            cp[b, a] = 0
                        }
                    }
                }
                // rule 2
                for (pr = 1; pr <= 2; pr++) {
                    if (pr == 1) {
                        a = i
                        b = j
                    }
                    else {
                        a = j
                        b = i
                    }
                    for (k = 1; k <= p; k++) {
                        if (k == i | k == j) {
                            continue
                        }
                        if (cp[a, k] == 1 & cp[k, a] == 0 & cp[k, b] == 1 & cp[b, k] == 0) {
                            cp[b, a] = 0
                        }
                    }
                }
                // rule 3
                for (pr = 1; pr <= 2; pr++) {
                    if (pr == 1) {
                        a = i
                        b = j
                    }
                    else {
                        a = j
                        b = i
                    }
                    for (q = 1; q <= nk; q++) {
                        k = SepKeys[q, 1]
                        l = SepKeys[q, 2]
                        if (cp[a, k] == 1 & cp[k, a] == 1 & cp[k, b] == 1 & cp[b, k] == 0 &
                            cp[a, l] == 1 & cp[l, a] == 1 & cp[l, b] == 1 & cp[b, l] == 0) {
                            cp[b, a] = 0
                        }
                    }
                }
                // rule 4
                for (pr = 1; pr <= 2; pr++) {
                    if (pr == 1) {
                        a = i
                        b = j
                    }
                    else {
                        a = j
                        b = i
                    }
                    for (q = 1; q <= nk; q++) {
                        if (SepKeys[q, 1] == b) {
                            kk = SepKeys[q, 2]
                        }
                        else if (SepKeys[q, 2] == b) {
                            kk = SepKeys[q, 1]
                        }
                        else {
                            continue
                        }
                        for (l = 1; l <= p; l++) {
                            if (l == a | l == b | l == kk) {
                                continue
                            }
                            if (cp[kk, l] == 1 & cp[l, kk] == 0 & cp[a, kk] == 1 &
                                cp[kk, a] == 1 & cp[l, b] == 1 & cp[b, l] == 0) {
                                cp[b, a] = 0
                            }
                        }
                    }
                }
            }
        }
        changed = (cp != old)
    }
    return(cp)
}

// forbidden-edge (priori knowledge) matrix, Sec. 2.1.1
real matrix _tvpc_forbid(real scalar nv, real scalar m, real scalar nocontemp)
{
    real scalar p, a, b, ka, kb
    real matrix F
    p = nv * (m + 1)
    F = J(p, p, 0)
    for (a = 1; a <= p; a++) {
        ka = mod(a - 1, m + 1)
        for (b = 1; b <= p; b++) {
            if (a == b) {
                continue
            }
            kb = mod(b - 1, m + 1)
            if (ka > 0 & kb > 0) {
                F[a, b] = 1
            }
            else if (ka == 0 & kb > 0) {
                F[a, b] = 1
            }
            else if (ka == 0 & kb == 0 & nocontemp) {
                F[a, b] = 1
            }
        }
    }
    return(F)
}

// full TV-PC run on a data matrix Z (u x p)
real matrix _tvpc_run(real matrix Z, real matrix forb, real scalar alpha,
        real scalar stable, real scalar maxdepth, real matrix SepKeys,
        real matrix SepSets, real matrix Pmax, real matrix Rmin,
        real matrix Psep, real scalar ntests, real scalar depth,
        real matrix sk, real matrix R, real scalar verbose)
{
    R = correlation(Z)
    sk = _tvpc_skeleton(R, rows(Z), forb, alpha, stable, maxdepth, SepKeys,
                        SepSets, Pmax, Rmin, Psep, ntests, depth, verbose)
    return(_tvpc_orient(sk, forb, SepKeys, SepSets))
}

// links table from a node-level PDAG
// cols: effect cause lag period type r_marg r_min p_max stab
real matrix _tvpc_links(real matrix G, real scalar nv, real scalar m,
        real scalar step, real matrix R, real matrix Rmin, real matrix Pmax,
        real matrix Fdir, real matrix Fadj, real scalar reps)
{
    real scalar j, c, k, a, b, ty, st
    real matrix L
    L = J(0, 9, .)
    for (j = 1; j <= nv; j++) {
        b = (j - 1) * (m + 1) + 1
        for (c = 1; c <= nv; c++) {
            for (k = 0; k <= m; k++) {
                a = (c - 1) * (m + 1) + k + 1
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
                st = .
                if (reps > 0) {
                    if (ty == 3) {
                        st = Fadj[a, b]
                    }
                    else {
                        st = Fdir[a, b]
                    }
                }
                L = L \ (j, c, k, k * step, ty, R[a, b], Rmin[a, b], Pmax[a, b], st)
            }
        }
    }
    if (rows(L) == 0) {
        L = J(1, 9, .)
    }
    return(L)
}

void _tvpc_main(string scalar nodes, string scalar touse, real scalar nv,
        real scalar m, real scalar step, real scalar alpha,
        real scalar stable, real scalar maxdepth, real scalar nocontemp,
        real scalar reps, real scalar blocklen, real scalar verbose)
{
    real matrix Z, forb, SepKeys, SepSets, Pmax, Rmin, Psep, sk, R, G
    real matrix Fdir, Fadj, Zb, Gb, SKb, SSb, Pb, Rb, Psb, skb, Rbb, L
    real matrix LM, D
    real scalar ntests, depth, u, p, b, nb, q, st, ntb, dpb, j, c
    real colvector idx

    ntests = 0
    depth = 0
    ntb = 0
    dpb = 0
    st_view(Z, ., tokens(nodes), touse)
    u = rows(Z)
    p = cols(Z)
    forb = _tvpc_forbid(nv, m, nocontemp)
    if (verbose) {
        printf("{txt}TV-PC skeleton search (%f nodes, u = %f):\n", p, u)
        displayflush()
    }
    G = _tvpc_run(Z, forb, alpha, stable, maxdepth, SepKeys, SepSets, Pmax,
                  Rmin, Psep, ntests, depth, sk, R, verbose)

    // moving-block bootstrap edge stability (extension)
    Fdir = J(p, p, 0)
    Fadj = J(p, p, 0)
    if (reps > 0) {
        nb = ceil(u / blocklen)
        for (b = 1; b <= reps; b++) {
            idx = J(0, 1, .)
            for (q = 1; q <= nb; q++) {
                st = floor(runiform(1, 1) * (u - blocklen + 1)) + 1
                idx = idx \ (st::(st + blocklen - 1))
            }
            idx = idx[1::u]
            Zb = Z[idx, .]
            Gb = _tvpc_run(Zb, forb, alpha, stable, maxdepth, SKb, SSb, Pb,
                           Rb, Psb, ntb, dpb, skb, Rbb, 0)
            if (verbose) {
                if (b == 1) {
                    printf("{txt}Bootstrap replications (%f): ", reps)
                }
                printf("{txt}.")
                if (mod(b, 50) == 0) {
                    printf("{txt}%f\n", b)
                }
                displayflush()
            }
            Fdir = Fdir + (Gb :* (1 :- Gb'))
            Fadj = Fadj + ((Gb + Gb') :> 0)
        }
        if (verbose & mod(reps, 50) != 0) {
            printf("\n")
        }
        Fdir = Fdir / reps
        Fadj = Fadj / reps
    }

    L = _tvpc_links(G, nv, m, step, R, Rmin, Pmax, Fdir, Fadj, reps)

    // lag-link counts and degree summary
    LM = J(nv, nv, 0)
    D = J(nv, 5, 0)
    if (L[1, 1] != .) {
        for (q = 1; q <= rows(L); q++) {
            j = L[q, 1]
            c = L[q, 2]
            LM[c, j] = LM[c, j] + 1
            if (L[q, 5] == 3) {
                LM[j, c] = LM[j, c] + 1
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
    st_matrix("__tvpc_Skel", sk)
    st_matrix("__tvpc_Pmax", Pmax)
    st_matrix("__tvpc_Psep", Psep)
    st_matrix("__tvpc_Rmarg", R)
    st_matrix("__tvpc_Rmin", Rmin)
    st_matrix("__tvpc_links", L)
    st_matrix("__tvpc_lagmap", LM)
    st_matrix("__tvpc_deg", D)
    if (reps > 0) {
        st_matrix("__tvpc_Fdir", Fdir)
        st_matrix("__tvpc_Fadj", Fadj)
    }
    st_numscalar("__tvpc_ntests", ntests)
    st_numscalar("__tvpc_depth", depth)
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
    st_numscalar("__tvpc_nforbid", sum(forb :* forb') / 2)
}

end
