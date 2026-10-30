*! cointpart 1.0.0  27oct2026
*! Cointegration by Parts -- FIEG, BIEG and GIEG subsample cointegration tests
*! Implements Kvist, O. and Vera-Valdes, J.E. (2026), "Cointegration by Parts:
*! Locating Cointegration in Time", arXiv:2609.10020.
*! Author: Merwan Roudane  (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane
*
* Step -> equation map (full version in: help cointpart methods)
*   cbp_Zwin      Eq. (3.2)            deterministic cases n / c / ct
*   cbp_minwindow Sec. 4.1             minimum window = floor(r0*T), pure fraction
*   cbp_pmaxrule  Schwert (1989)       pmax = floor(12*(n/100)^.25) on the WINDOW
*   cbp_window    Eq. (3.5)-(3.8)      window OLS, window residuals, ADF t-stat
*   cbp_scan      Eq. (3.9),(3.16),(3.17)  FIEG, BIEG, GIEG as infima
*   cbp_surface   Eq. (4.18)           MacKinnon-type response surface, Table 3
*   cbp_simpval   Sec. 4.1 null DGP    independent driftless random walks

program define cointpart, rclass
    version 14.0

    syntax varlist(min=2 numeric ts) [if] [in] [,          ///
        CASe(string)                                        ///
        TRim(real 0.15)                                     ///
        MAXLag(integer -1)                                  ///
        CRITerion(string)                                   ///
        DOFratio(real 4)                                    ///
        REPS(integer 0)                                     ///
        SEed(string)                                        ///
        BETAs                                               ///
        PREfix(string)                                      ///
        GRaph                                               ///
        NAME(string)                                        ///
        noTABle ]

    * ---------------------------------------------------------------
    * time-series setup
    * ---------------------------------------------------------------
    capture qui tsset
    if _rc {
        di as error "data must be {bf:tsset} before using cointpart"
        exit 111
    }
    local tvar "`r(timevar)'"
    local tdel = r(tdelta)
    if ("`tvar'" == "") {
        di as error "cointpart requires a time variable; use {bf:tsset}"
        exit 111
    }
    if (`tdel' == . | `tdel' == 0) local tdel = 1
    local tfmt : format `tvar'

    marksample touse
    markout `touse' `varlist'

    * contiguity: the window logic needs a gap-free stretch
    qui count if `touse'
    local T = r(N)
    if (`T' < 20) {
        di as error "too few observations (`T'); the test needs at least 20"
        exit 2001
    }
    qui summarize `tvar' if `touse', meanonly
    local tmin = r(min)
    local tmax = r(max)
    local span = (`tmax' - `tmin')/`tdel' + 1
    if (abs(`span' - `T') > 1e-6) {
        di as error "the selected sample has gaps: `T' observations spanning `span' periods"
        di as error "cointpart needs a gap-free time span"
        exit 459
    }

    * ---------------------------------------------------------------
    * options
    * ---------------------------------------------------------------
    if ("`case'" == "") local case "c"
    local case = lower(trim("`case'"))
    if !inlist("`case'", "n", "c", "ct") {
        di as error "case() must be n, c or ct"
        exit 198
    }
    local cc = cond("`case'" == "n", 0, cond("`case'" == "c", 1, 2))

    if ("`criterion'" == "") local criterion "bic"
    local criterion = lower(trim("`criterion'"))
    if ("`criterion'" == "sic") local criterion "bic"
    if !inlist("`criterion'", "bic", "aic") {
        di as error "criterion() must be bic (= sic) or aic"
        exit 198
    }
    local aic = ("`criterion'" == "aic")

    if (`trim' <= 0 | `trim' > 0.5) {
        di as error "trim() must lie in (0, 0.5]"
        exit 198
    }
    if (`dofratio' < 0) {
        di as error "dofratio() must be non-negative"
        exit 198
    }
    if (`reps' < 0) {
        di as error "reps() must be non-negative"
        exit 198
    }
    if ("`seed'" != "") set seed `seed'

    gettoken yv xv : varlist
    local N : word count `xv'

    * the engine cost is O(T^2) windows; cap it loudly (see help, Remarks)
    if (`T' > 2000) {
        di as error "T = `T' exceeds the 2000-observation cap"
        di as error "the scan evaluates O(T^2) windows; raise trim() or shorten the sample"
        exit 198
    }

    * ---------------------------------------------------------------
    * run the scan
    * ---------------------------------------------------------------
    mata: cbp_run("`yv' `xv'", "`touse'", `cc', `trim', 0, 12, `dofratio', `aic', `maxlag')

    local m    = scalar(__cbp_m)
    local nwin = scalar(__cbp_nwin)
    local nmis = scalar(__cbp_nmiss)
    local fieg = scalar(__cbp_fieg)
    local bieg = scalar(__cbp_bieg)
    local gieg = scalar(__cbp_gieg)
    local fieg_s = 1
    local fieg_e = scalar(__cbp_fe)
    local bieg_s = scalar(__cbp_bs)
    local bieg_e = `T'
    local gieg_s = scalar(__cbp_gs)
    local gieg_e = scalar(__cbp_ge)

    if (`fieg' == . & `bieg' == . & `gieg' == .) {
        di as error "every window was degenerate; check for collinearity or constant series"
        exit 498
    }

    * calendar labels for the argmin windows
    foreach t in fieg bieg gieg {
        if (``t'_s' == . | ``t'_e' == .) {
            local `t'_t1 = .
            local `t'_t2 = .
            local `t'_win "(none)"
        }
        else {
            local `t'_t1 = `tmin' + (``t'_s' - 1)*`tdel'
            local `t'_t2 = `tmin' + (``t'_e' - 1)*`tdel'
            local a : di `tfmt' ``t'_t1'
            local b : di `tfmt' ``t'_t2'
            local `t'_win "`=trim("`a'")'-`=trim("`b'")'"
        }
    }

    * ---------------------------------------------------------------
    * critical values from the response surfaces (Table 3)
    * valid only for T >= 100, N <= 3, trim = 0.15, case c or ct
    * ---------------------------------------------------------------
    local cvok = 1
    local cvwhy ""
    if (`cc' == 0) {
        local cvok 0
        local cvwhy "Case n is not tabulated"
    }
    else if (`N' > 3) {
        local cvok 0
        local cvwhy "only N <= 3 regressors are tabulated"
    }
    else if (abs(`trim' - 0.15) > 1e-8) {
        local cvok 0
        local cvwhy "the tabulation is indexed by r0 = 0.15"
    }
    else if (`T' < 100) {
        local cvok 0
        local cvwhy "the response surfaces are fitted for T >= 100"
    }

    tempname CV
    matrix `CV' = J(3, 3, .)
    if (`cvok') {
        mata: cbp_fillcv(`cc', `N', `T')
        matrix `CV' = __cbp_cv
    }
    matrix rownames `CV' = FIEG BIEG GIEG
    matrix colnames `CV' = cv1 cv5 cv10

    * ---------------------------------------------------------------
    * optional simulated p-values under the paper's null DGP
    * ---------------------------------------------------------------
    tempname PV
    matrix `PV' = J(3, 1, .)
    if (`reps' > 0) {
        di as text "simulating the null distribution (`reps' replications, T = `T', N = `N') ..."
        mata: cbp_simpval(`T', `N', `cc', `trim', 0, 12, `dofratio', `aic', `maxlag', ///
                          `reps', `fieg', `bieg', `gieg')
        matrix `PV' = __cbp_pv
    }
    matrix rownames `PV' = FIEG BIEG GIEG
    matrix colnames `PV' = pvalue

    * ---------------------------------------------------------------
    * window-by-window betas at the argmin windows (paper's Section 6
    * diagnostic for partial cointegration vs a shifted vector)
    * ---------------------------------------------------------------
    tempname BETA
    matrix `BETA' = __cbp_beta
    local bnames ""
    if (`cc' >= 1) local bnames "_cons"
    if (`cc' == 2) local bnames "`bnames' _trend"
    local bnames "`bnames' `xv'"
    matrix rownames `BETA' = FIEG BIEG GIEG
    matrix colnames `BETA' = `bnames'

    * ---------------------------------------------------------------
    * sequence variables (prefix) and the graph
    * ---------------------------------------------------------------
    if ("`prefix'" != "") {
        capture confirm new variable `prefix'_fieg `prefix'_bieg
        if _rc {
            di as error "`prefix'_fieg / `prefix'_bieg already exist; choose another prefix()"
            exit 110
        }
        qui gen double `prefix'_fieg = .
        qui gen double `prefix'_bieg = .
        label variable `prefix'_fieg "forward-infimum EG sequence"
        label variable `prefix'_bieg "backward-infimum EG sequence"
        mata: cbp_putseq("`prefix'_fieg", "`prefix'_bieg", "`touse'")
        local seqf "`prefix'_fieg"
        local seqb "`prefix'_bieg"
    }
    else if ("`graph'" != "") {
        tempvar sf sb
        qui gen double `sf' = .
        qui gen double `sb' = .
        mata: cbp_putseq("`sf'", "`sb'", "`touse'")
        local seqf "`sf'"
        local seqb "`sb'"
    }

    if ("`graph'" != "") {
        * tolerate both name(foo) and name(foo, replace): the graph is always
        * drawn with replace, so strip anything after the graph name
        local name : subinstr local name "," " ", all
        local name : word 1 of `name'
        if ("`name'" == "") local name "cointpart"
        local cv5 = `CV'[3,2]

        * Stata picks round axis labels and then widens the axis to include
        * them, which on a 1880-2019 sample gives an 1850-2050 axis. Setting
        * the labels inside the sample is the only way to tighten it:
        * xscale(range()) only ever widens an axis, never narrows one.
        local span = `tmax' - `tmin'
        local step = 1
        foreach c in 1 2 5 10 20 25 50 100 200 250 500 1000 2000 5000 {
            local step `c'
            if (`span'/`c' <= 6) continue, break
        }
        local first = ceil(`tmin'/`step')*`step'
        local xlab ""
        forvalues v = `first'(`step')`tmax' {
            local xlab "`xlab' `v'"
        }
        if ("`xlab'" == "") local xlab "`tmin' `tmax'"

        local gline ""
        local gnote ""
        if (`gieg_t1' != . & `gieg_t2' != .) {
            local gline "xline(`gieg_t1' `gieg_t2', lcolor(gs10) lpattern(solid))"
            local gnote "vertical lines: GIEG window `gieg_win'"
        }
        if (`cvok') {
            local cvline "yline(`cv5', lpattern(dash) lcolor(gs7))"
            local cvnote "dashed line: GIEG 5% critical value (`: di %6.3f `cv5'')"
        }
        else {
            local cvline ""
            local cvnote "critical values not available: `cvwhy'"
        }
        twoway                                                                   ///
            (line `seqb' `tvar' if `touse', lcolor(navy) lwidth(medthick))       ///
            (line `seqf' `tvar' if `touse', lcolor(cranberry) lpattern(shortdash)), ///
            `cvline'                                                             ///
            `gline'                                                              ///
            title("Cointegration by Parts: subsample evidence", size(medium))     ///
            subtitle("Case `case', r{subscript:0} = `: di %4.2f `trim''", size(small)) ///
            ytitle("Engle-Granger statistic") xtitle("")                          ///
            xlabel(`xlab', format(`tfmt'))                                        ///
            legend(order(1 "BIEG sequence (min = GIEG)" 2 "FIEG sequence")        ///
                   rows(1) size(small) position(6) ring(1) region(lstyle(none)))  ///
            note("`cvnote'" "`gnote'", size(vsmall))                              ///
            graphregion(color(white)) plotregion(color(white))                    ///
            name(`name', replace)
    }

    * ---------------------------------------------------------------
    * display
    * ---------------------------------------------------------------
    if ("`table'" != "notable") {
        local csname "no deterministic term (Case n)"
        if (`cc' == 1) local csname "constant (Case c)"
        if (`cc' == 2) local csname "constant and trend (Case ct)"

        di ""
        di as text "Cointegration by Parts" _col(56) "Number of obs  = " as result %9.0f `T'
        di as text "Deterministic: `csname'" _col(56) as text "Regressors (N) = " as result %9.0f `N'
        di as text "Lag selection: `=upper("`criterion'")'" _col(56) as text "Minimum window = " as result %9.0f `m'
        di as text "Trimming r0  : " as result %5.3f `trim' _col(56) as text "Windows scanned= " as result %9.0f `nwin'
        if (`nmis' > 0) {
            di as text "Degenerate windows skipped: " as result `nmis'
        }
        di as text "{hline 78}"
        if (`reps' > 0) {
            di as text "  Test" _col(13) "Statistic" _col(26) "p-value" _col(38) "1%" _col(48) "5%" _col(58) "10%" _col(66) "Window"
        }
        else {
            di as text "  Test" _col(13) "Statistic" _col(30) "1%" _col(40) "5%" _col(50) "10%" _col(62) "Window"
        }
        di as text "{hline 78}"

        local i 0
        foreach t in fieg bieg gieg {
            local ++i
            local TT = upper("`t'")
            local st = ``t''
            local c1 = `CV'[`i',1]
            local c5 = `CV'[`i',2]
            local c10 = `CV'[`i',3]
            local star ""
            if (`cvok' & `st' != .) {
                if (`c10' != . & `st' <= `c10') local star "*"
                if (`c5'  != . & `st' <= `c5')  local star "**"
                if (`c1'  != . & `st' <= `c1')  local star "***"
            }
            local win "``t'_win'"
            if (`reps' > 0) {
                local pv = `PV'[`i',1]
                di as text "  `TT'" _col(12) as result %9.3f `st' as text "`star'" ///
                   _col(26) as result %7.4f `pv' ///
                   _col(34) as result %8.3f `c1' _col(44) %8.3f `c5' _col(54) %8.3f `c10' ///
                   _col(64) as result "`win'"
            }
            else {
                di as text "  `TT'" _col(12) as result %9.3f `st' as text "`star'" ///
                   _col(26) as result %8.3f `c1' _col(36) %8.3f `c5' _col(46) %8.3f `c10' ///
                   _col(60) as result "`win'"
            }
        }
        di as text "{hline 78}"
        di as text "  H0: the series do not cointegrate anywhere in the sample"
        di as text "  H1: they cointegrate over some subinterval of length at least r0"
        if (`cvok') {
            di as text "  Critical values: response surfaces of Kvist and Vera-Valdes (2026, Tab. 3)"
            di as text "  * p<.10   ** p<.05   *** p<.01   (left-tailed: reject if stat <= cv)"
        }
        else {
            di as text "  Critical values not reported: `cvwhy'"
        }
        di as text "  Only GIEG is consistent against both break directions; see"
        di as text "  {help cointpart_methods:help cointpart methods} before using FIEG or BIEG."
        if (`reps' > 0) {
            di as text "  p-values simulated from independent driftless random walks (`reps' reps)."
        }

        if ("`betas'" != "") {
            di ""
            di as text "Cointegrating vector re-estimated on each argmin window:"
            matlist `BETA', format(%9.4f) border(rows)
            di as text "  (a rejection is also consistent with a shifted cointegrating vector;"
            di as text "   compare these rows -- Kvist and Vera-Valdes 2026, Section 6)"
        }
    }

    * ---------------------------------------------------------------
    * returns  (graphs/matlist are done; safe to move matrices now)
    * ---------------------------------------------------------------
    return scalar N        = `T'
    return scalar nreg     = `N'
    return scalar trim     = `trim'
    return scalar minwin   = `m'
    return scalar nwindows = `nwin'
    return scalar nmissing = `nmis'
    return scalar reps     = `reps'

    return scalar fieg     = `fieg'
    return scalar bieg     = `bieg'
    return scalar gieg     = `gieg'

    return scalar fieg_t1  = `fieg_t1'
    return scalar fieg_t2  = `fieg_t2'
    return scalar bieg_t1  = `bieg_t1'
    return scalar bieg_t2  = `bieg_t2'
    return scalar gieg_t1  = `gieg_t1'
    return scalar gieg_t2  = `gieg_t2'

    if (`reps' > 0) {
        return scalar p_fieg = `PV'[1,1]
        return scalar p_bieg = `PV'[2,1]
        return scalar p_gieg = `PV'[3,1]
    }

    return local case      "`case'"
    return local criterion "`criterion'"
    return local depvar    "`yv'"
    return local indepvars "`xv'"
    return local timevar   "`tvar'"
    return local cmd       "cointpart"
    return local cmdline   "cointpart `0'"

    return matrix cv      = `CV'
    return matrix beta    = `BETA'
    if (`reps' > 0) {
        return matrix pvalue = `PV'
    }
    return matrix windows = __cbp_W

    capture scalar drop __cbp_m __cbp_nwin __cbp_nmiss __cbp_fieg __cbp_bieg ///
                        __cbp_gieg __cbp_fe __cbp_bs __cbp_gs __cbp_ge
    capture matrix drop __cbp_W __cbp_cv __cbp_pv __cbp_beta
end

* =====================================================================
* Mata engine
* =====================================================================
version 14.0
mata:

// Eq. (3.2): dimension of the deterministic block
real scalar cbp_detdim(real scalar cc)
{
    if (cc == 0) {
        return(0)
    }
    if (cc == 1) {
        return(1)
    }
    return(2)
}

// Schwert (1989) bound applied to the WINDOW length n
real scalar cbp_pmaxrule(real scalar n, real scalar mult)
{
    real scalar v
    v = floor(mult * (n/100)^0.25)
    if (v < 0) {
        v = 0
    }
    return(v)
}

// Section 4.1: minimum window as a PURE fraction of T.  No observation
// floor is imposed: the paper is explicit that a fixed floor lets the
// effective r0 drift with T, so the simulated quantiles stop converging.
// Windows too short to support the ADF regression are instead returned
// as missing by cbp_window and skipped by the scan, exactly as in the
// authors' reference engine.
real scalar cbp_minwindow(real scalar T, real scalar r0, real scalar fl)
{
    real scalar m
    m = floor(r0 * T)
    if (m < fl) {
        m = fl
    }
    return(m)
}

// window regressor matrix Z = [d_t, x_t] over [s,e].
// The trend is scaled by the window length; OLS is invariant to this
// reparameterisation once the constant is present (paper, Section 3).
real matrix cbp_Zwin(real matrix X, real scalar cc, real scalar s, real scalar e)
{
    real scalar n, kd
    real matrix Z
    n = e - s + 1
    kd = cbp_detdim(cc)
    Z = X[|s,1 \ e,.|]
    if (kd == 1) {
        Z = (J(n,1,1), Z)
    }
    if (kd == 2) {
        Z = (J(n,1,1), (1::n):/n, Z)
    }
    return(Z)
}

// Eq. (3.5)-(3.8): window OLS, window residuals, ADF t-statistic.
// Returns (tstat, lag, gamma, se, neff, pmax_used); all missing if degenerate.
real rowvector cbp_window(real colvector y, real matrix X, real scalar cc,
                          real scalar s, real scalar e, real scalar mult,
                          real scalar dof, real scalar aic, real scalar maxl)
{
    real scalar n, nd, pw, need, t2, done, neff, p, kp, rss, acc, dimg
    real scalar bestic, bestp, bestrss, ic, pen, j, sig2, v11, sehat, gam, yy
    real colvector yw, b, eps, dy, lg, bb, ww, e1, rhs
    real matrix Z, D, M, L, Lj

    n = e - s + 1
    // only a structural guard, so that the differencing below is defined.
    // Everything shorter than the ADF regression can carry is rejected by
    // the neff test further down, matching the reference engine.
    if (n < 3) {
        return(J(1,6,.))
    }
    Z = cbp_Zwin(X, cc, s, e)
    yw = y[|s \ e|]
    b = cholsolve(quadcross(Z,Z), quadcross(Z,yw))
    if (hasmissing(b)) {
        return(J(1,6,.))
    }
    eps = yw - Z*b

    nd = n - 1
    dy = eps[|2 \ n|] - eps[|1 \ nd|]
    lg = eps[|1 \ nd|]

    pw = cbp_pmaxrule(n, mult)
    if (maxl >= 0) {
        if (pw > maxl) {
            pw = maxl
        }
    }
    done = 0
    while (pw > 0 & done == 0) {
        need = pw + 3
        t2 = ceil(dof*(pw+1))
        if (t2 > need) {
            need = t2
        }
        if ((nd - pw) < need) {
            pw = pw - 1
        }
        else {
            done = 1
        }
    }
    neff = nd - pw
    if (neff < 3) {
        return(J(1,6,.))
    }

    // all candidate orders are scored on the COMMON sample (Section 4.1)
    dimg = pw + 2
    D = J(neff, dimg, .)
    D[.,1] = lg[|pw+1 \ nd|]
    for (p=1; p<=pw; p++) {
        D[.,1+p] = dy[|pw+1-p \ nd-p|]
    }
    D[.,dimg] = dy[|pw+1 \ nd|]

    M = quadcross(D,D)
    yy = M[dimg,dimg]
    if (yy <= 0) {
        return(J(1,6,.))
    }
    L = cholesky(M)
    if (hasmissing(L)) {
        return(J(1,6,.))
    }

    bestic = .
    bestp = -1
    bestrss = .
    acc = 0
    for (p=0; p<=pw; p++) {
        acc = acc + L[dimg, p+1]^2
        rss = yy - acc
        kp = p + 1
        if (rss > 0 & neff > kp) {
            pen = ln(neff)
            if (aic == 1) {
                pen = 2
            }
            ic = neff*ln(rss/neff) + pen*kp
            if (bestic == .) {
                bestic = ic
                bestp = p
                bestrss = rss
            }
            else {
                if (ic < bestic) {
                    bestic = ic
                    bestp = p
                    bestrss = rss
                }
            }
        }
    }
    if (bestp < 0) {
        return(J(1,6,.))
    }

    j = bestp + 1
    Lj = L[|1,1 \ j,j|]
    rhs = (L[|dimg,1 \ dimg,j|])'
    bb = solveupper(Lj', rhs)
    if (hasmissing(bb)) {
        return(J(1,6,.))
    }
    gam = bb[1]
    e1 = J(j,1,0)
    e1[1] = 1
    ww = solvelower(Lj, e1)
    if (hasmissing(ww)) {
        return(J(1,6,.))
    }
    v11 = sum(ww:^2)
    sig2 = bestrss/(neff - j)
    if (sig2 <= 0 | v11 <= 0) {
        return(J(1,6,.))
    }
    sehat = sqrt(sig2*v11)
    if (sehat <= 0) {
        return(J(1,6,.))
    }
    return((gam/sehat, bestp, gam, sehat, neff, pw))
}

// Eq. (3.9), (3.16), (3.17): one scan yields all three statistics, since
// the FIEG and BIEG window sets are subsets of the GIEG window set.
// Results are returned through Stata scalars / matrices named __cbp_*.
void cbp_scancore(real colvector y, real matrix X, real scalar cc,
                  real scalar m, real scalar mult, real scalar dof,
                  real scalar aic, real scalar maxl,
                  real scalar g, real scalar gs, real scalar ge,
                  real scalar f, real scalar fe,
                  real scalar bk, real scalar bs,
                  real matrix W, real colvector fseq, real colvector bseq,
                  real scalar nmiss)
{
    real scalar T, s, e, nr
    real rowvector r

    T = rows(y)
    nr = 0
    W = J((T-m+1)*(T-m+2)/2, 5, .)
    fseq = J(T,1,.)
    bseq = J(T,1,.)
    g = .
    gs = .
    ge = .
    f = .
    fe = .
    bk = .
    bs = .
    nmiss = 0

    for (s=1; s<=T-m+1; s++) {
        for (e=s+m-1; e<=T; e++) {
            r = cbp_window(y, X, cc, s, e, mult, dof, aic, maxl)
            nr = nr + 1
            W[nr,1] = s
            W[nr,2] = e
            W[nr,3] = e - s + 1
            W[nr,4] = r[1]
            W[nr,5] = r[2]
            if (r[1] == .) {
                nmiss = nmiss + 1
            }
            else {
                if (g == .) {
                    g = r[1]
                    gs = s
                    ge = e
                }
                else {
                    if (r[1] < g) {
                        g = r[1]
                        gs = s
                        ge = e
                    }
                }
                if (bseq[e] == .) {
                    bseq[e] = r[1]
                }
                else {
                    if (r[1] < bseq[e]) {
                        bseq[e] = r[1]
                    }
                }
                if (s == 1) {
                    fseq[e] = r[1]
                    if (f == .) {
                        f = r[1]
                        fe = e
                    }
                    else {
                        if (r[1] < f) {
                            f = r[1]
                            fe = e
                        }
                    }
                }
                if (e == T) {
                    if (bk == .) {
                        bk = r[1]
                        bs = s
                    }
                    else {
                        if (r[1] < bk) {
                            bk = r[1]
                            bs = s
                        }
                    }
                }
            }
        }
    }
    W = W[|1,1 \ nr,5|]
}

// driver called from the ado
void cbp_run(string scalar vlist, string scalar touse, real scalar cc,
             real scalar r0, real scalar floorobs, real scalar mult,
             real scalar dof, real scalar aic, real scalar maxl)
{
    external real colvector __cbp_FSEQ, __cbp_BSEQ
    real matrix V, X, W, B
    real colvector y, fseq, bseq, bw
    real scalar T, N, m, kd
    real scalar g, gs, ge, f, fe, bk, bs, nmiss

    // Mata passes by reference, so these must exist before cbp_scancore
    g = .
    gs = .
    ge = .
    f = .
    fe = .
    bk = .
    bs = .
    nmiss = 0
    W = J(0,5,.)
    fseq = J(0,1,.)
    bseq = J(0,1,.)

    V = st_data(., vlist, touse)
    T = rows(V)
    N = cols(V) - 1
    y = V[.,1]
    X = V[.,(2..cols(V))]
    m = cbp_minwindow(T, r0, floorobs)
    kd = cbp_detdim(cc)

    cbp_scancore(y, X, cc, m, mult, dof, aic, maxl,
                 g, gs, ge, f, fe, bk, bs, W, fseq, bseq, nmiss)

    st_numscalar("__cbp_m", m)
    st_numscalar("__cbp_nwin", rows(W))
    st_numscalar("__cbp_nmiss", nmiss)
    st_numscalar("__cbp_fieg", f)
    st_numscalar("__cbp_bieg", bk)
    st_numscalar("__cbp_gieg", g)
    st_numscalar("__cbp_fe", fe)
    st_numscalar("__cbp_bs", bs)
    st_numscalar("__cbp_gs", gs)
    st_numscalar("__cbp_ge", ge)
    st_matrix("__cbp_W", W)

    // cointegrating vector on each argmin window
    B = J(3, kd + N, .)
    if (fe != .) {
        bw = cholsolve(quadcross(cbp_Zwin(X,cc,1,fe), cbp_Zwin(X,cc,1,fe)),
                       quadcross(cbp_Zwin(X,cc,1,fe), y[|1 \ fe|]))
        if (!hasmissing(bw)) {
            B[1,.] = bw'
        }
    }
    if (bs != .) {
        bw = cholsolve(quadcross(cbp_Zwin(X,cc,bs,T), cbp_Zwin(X,cc,bs,T)),
                       quadcross(cbp_Zwin(X,cc,bs,T), y[|bs \ T|]))
        if (!hasmissing(bw)) {
            B[2,.] = bw'
        }
    }
    if (gs != .) {
        bw = cholsolve(quadcross(cbp_Zwin(X,cc,gs,ge), cbp_Zwin(X,cc,gs,ge)),
                       quadcross(cbp_Zwin(X,cc,gs,ge), y[|gs \ ge|]))
        if (!hasmissing(bw)) {
            B[3,.] = bw'
        }
    }
    st_matrix("__cbp_beta", B)

    // keep the sequences for prefix()/graph
    __cbp_FSEQ = fseq
    __cbp_BSEQ = bseq
}

// write the stored sequences into Stata variables
void cbp_putseq(string scalar vf, string scalar vb, string scalar touse)
{
    external real colvector __cbp_FSEQ, __cbp_BSEQ
    st_store(., vf, touse, __cbp_FSEQ)
    st_store(., vb, touse, __cbp_BSEQ)
}

// Eq. (4.18): MacKinnon-type response surface, coefficients from Table 3.
// Row layout: case (1=c, 2=ct), test (1=FIEG, 2=BIEG, 3=GIEG), N, level%,
// then beta_inf, beta_1, beta_2, beta_3.  A zero beta_3 means the quadratic
// specification was retained for that cell.
real matrix cbp_surftab()
{
    real matrix S
    S = J(54, 8, .)
    S[ 1,.] = (1, 1, 1,  1,   -4.622,    39.11,   -43234.7,   2935669)
    S[ 2,.] = (1, 1, 1,  5,   -4.168,    93.58,   -40067.3,   2418344)
    S[ 3,.] = (1, 1, 1, 10,   -3.889,    77.40,   -31601.4,   1854138)
    S[ 4,.] = (1, 1, 2,  1,   -4.886,  -131.59,    -1806.1,         0)
    S[ 5,.] = (1, 1, 2,  5,   -4.427,   -85.13,    -1815.4,         0)
    S[ 6,.] = (1, 1, 2, 10,   -4.314,    54.05,   -30107.2,   1795004)
    S[ 7,.] = (1, 1, 3,  1,   -5.280,  -114.07,    -5458.9,         0)
    S[ 8,.] = (1, 1, 3,  5,   -4.878,     5.24,   -27195.9,   1628214)
    S[ 9,.] = (1, 1, 3, 10,   -4.703,    76.14,   -38067.7,   2259685)
    S[10,.] = (1, 2, 1,  1,   -4.985,   131.51,   -42867.8,   2264027)
    S[11,.] = (1, 2, 1,  5,   -4.570,   221.50,   -52282.2,   2726703)
    S[12,.] = (1, 2, 1, 10,   -4.343,   224.74,   -45666.3,   2210900)
    S[13,.] = (1, 2, 2,  1,   -5.166,   -47.90,    -7021.9,         0)
    S[14,.] = (1, 2, 2,  5,   -4.836,   133.63,   -41983.0,   2303573)
    S[15,.] = (1, 2, 2, 10,   -4.576,   114.58,   -31056.1,   1587288)
    S[16,.] = (1, 2, 3,  1,   -5.425,  -113.09,    -4008.9,         0)
    S[17,.] = (1, 2, 3,  5,   -4.968,   -53.95,    -3938.5,         0)
    S[18,.] = (1, 2, 3, 10,   -4.830,    64.00,   -27143.5,   1452916)
    S[19,.] = (1, 3, 1,  1,   -5.443,  -217.52,    -8916.9,         0)
    S[20,.] = (1, 3, 1,  5,   -5.028,  -174.92,    -3601.0,         0)
    S[21,.] = (1, 3, 1, 10,   -4.945,    -1.67,   -42770.4,   2708621)
    S[22,.] = (1, 3, 2,  1,   -5.870,  -257.18,    -8133.6,         0)
    S[23,.] = (1, 3, 2,  5,   -5.396,  -223.20,    -1671.0,         0)
    S[24,.] = (1, 3, 2, 10,   -5.172,  -206.65,     -369.2,         0)
    S[25,.] = (1, 3, 3,  1,   -6.333,  -189.99,   -22260.7,         0)
    S[26,.] = (1, 3, 3,  5,   -5.809,  -195.88,    -8688.3,         0)
    S[27,.] = (1, 3, 3, 10,   -5.549,  -203.43,    -4090.8,         0)
    S[28,.] = (2, 1, 1,  1,   -5.043,    15.32,   -42793.3,   2856103)
    S[29,.] = (2, 1, 1,  5,   -4.542,    47.80,   -38713.4,   2458907)
    S[30,.] = (2, 1, 1, 10,   -4.319,    68.30,   -36050.1,   2147638)
    S[31,.] = (2, 1, 2,  1,   -5.436,    15.77,   -40112.1,   2412202)
    S[32,.] = (2, 1, 2,  5,   -4.836,   -21.33,   -23126.6,   1379299)
    S[33,.] = (2, 1, 2, 10,   -4.591,   -22.27,   -17159.3,    983975)
    S[34,.] = (2, 1, 3,  1,   -5.521,  -171.87,    -2468.2,         0)
    S[35,.] = (2, 1, 3,  5,   -5.092,  -118.50,     -828.5,         0)
    S[36,.] = (2, 1, 3, 10,   -4.866,   -96.29,     -980.7,         0)
    S[37,.] = (2, 2, 1,  1,   -5.137,    -0.21,   -33853.3,   1989958)
    S[38,.] = (2, 2, 1,  5,   -4.762,   126.70,   -47937.8,   2734736)
    S[39,.] = (2, 2, 1, 10,   -4.524,   148.47,   -47630.3,   2686792)
    S[40,.] = (2, 2, 2,  1,   -5.292,  -157.50,    -1889.7,         0)
    S[41,.] = (2, 2, 2,  5,   -4.974,    26.54,   -33101.3,   2024194)
    S[42,.] = (2, 2, 2, 10,   -4.764,    60.27,   -32321.0,   1857014)
    S[43,.] = (2, 2, 3,  1,   -5.738,  -115.29,    -4766.6,         0)
    S[44,.] = (2, 2, 3,  5,   -5.225,   -80.73,    -3393.2,         0)
    S[45,.] = (2, 2, 3, 10,   -4.978,   -63.89,    -3036.4,         0)
    S[46,.] = (2, 3, 1,  1,   -5.635,  -456.98,    30907.1,  -2547899)
    S[47,.] = (2, 3, 1,  5,   -5.322,  -267.53,     -849.0,         0)
    S[48,.] = (2, 3, 1, 10,   -5.098,  -250.30,     1552.8,         0)
    S[49,.] = (2, 3, 2,  1,   -6.241,  -227.20,   -18697.5,         0)
    S[50,.] = (2, 3, 2,  5,   -5.626,  -347.95,    20974.4,  -1808307)
    S[51,.] = (2, 3, 2, 10,   -5.494,  -241.75,    -2093.8,         0)
    S[52,.] = (2, 3, 3,  1,   -6.555,  -209.62,   -26860.9,         0)
    S[53,.] = (2, 3, 3,  5,   -6.117,  -207.86,   -13768.7,         0)
    S[54,.] = (2, 3, 3, 10,   -5.876,  -210.87,    -8244.2,         0)
    return(S)
}

real scalar cbp_cvat(real scalar cc, real scalar test, real scalar N,
                     real scalar lev, real scalar T)
{
    real matrix S
    real scalar i, cs
    cs = cc
    S = cbp_surftab()
    for (i=1; i<=54; i++) {
        if (S[i,1] == cs) {
            if (S[i,2] == test) {
                if (S[i,3] == N) {
                    if (S[i,4] == lev) {
                        return(S[i,5] + S[i,6]/T + S[i,7]/T^2 + S[i,8]/T^3)
                    }
                }
            }
        }
    }
    return(.)
}

void cbp_fillcv(real scalar cc, real scalar N, real scalar T)
{
    real matrix C
    real scalar t, k
    real rowvector levs
    levs = (1, 5, 10)
    C = J(3,3,.)
    for (t=1; t<=3; t++) {
        for (k=1; k<=3; k++) {
            C[t,k] = cbp_cvat(cc, t, N, levs[k], T)
        }
    }
    st_matrix("__cbp_cv", C)
}

// Section 4.1 null DGP: independent driftless random walks.
// The simulation repeats the WHOLE statistic, scan included, on every
// replication -- the observed statistic's search advantage must be
// reproduced or the p-value is wrong.
void cbp_simpval(real scalar T, real scalar N, real scalar cc, real scalar r0,
                 real scalar floorobs, real scalar mult, real scalar dof,
                 real scalar aic, real scalar maxl, real scalar reps,
                 real scalar of, real scalar ob, real scalar og)
{
    real matrix Xs, P
    real colvector ys, fseq, bseq
    real matrix W
    real scalar m, i, j, nf, nb, ng, nmiss
    real scalar g, gs, ge, f, fe, bk, bs, step

    m = cbp_minwindow(T, r0, floorobs)
    nf = 0
    nb = 0
    ng = 0
    g = .
    gs = .
    ge = .
    f = .
    fe = .
    bk = .
    bs = .
    nmiss = 0
    W = J(0,5,.)
    fseq = J(0,1,.)
    bseq = J(0,1,.)
    step = ceil(reps/10)
    if (step < 1) {
        step = 1
    }
    for (i=1; i<=reps; i++) {
        ys = runningsum(rnormal(T,1,0,1))
        Xs = J(T,N,.)
        for (j=1; j<=N; j++) {
            Xs[.,j] = runningsum(rnormal(T,1,0,1))
        }
        cbp_scancore(ys, Xs, cc, m, mult, dof, aic, maxl,
                     g, gs, ge, f, fe, bk, bs, W, fseq, bseq, nmiss)
        if (f != . & of != .) {
            if (f <= of) {
                nf = nf + 1
            }
        }
        if (bk != . & ob != .) {
            if (bk <= ob) {
                nb = nb + 1
            }
        }
        if (g != . & og != .) {
            if (g <= og) {
                ng = ng + 1
            }
        }
        if (mod(i, step) == 0) {
            printf(".")
            displayflush()
        }
    }
    printf("\n")
    P = J(3,1,.)
    P[1,1] = nf/reps
    P[2,1] = nb/reps
    P[3,1] = ng/reps
    st_matrix("__cbp_pv", P)
}

end
