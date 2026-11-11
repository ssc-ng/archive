*! csdlp_example.do -- self-test and worked examples for csdlp
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane
*
* Part A: the Monte Carlo DGP of David, Giacomini, Jiao & Wang (2026, Sec. 5)
*         -> truth known: g_h(z) = 0.8^h (0.5z + 0.3z^2 - 0.25z^3)
* Part B: an Ottonello-Winberry-style firm panel with a hump-shaped
*         exposure to a monetary shock, sector-time FE, cumulative
*         investment, 25bp cut, differential and aggregate responses.
* Every code path of csdlp / csdlp_diff / csdlp_agg / csdlp_graph is run.

version 15.0
clear
set more off
set seed 20261109

* =====================================================================
* PART A.  Paper DGP (eq. 22-23), N = 300, T = 150
* =====================================================================
local N 300
local T 150
local B 500
local TT = `T' + `B'
tempfile xs
qui {
    set obs `TT'
    gen t = _n
    gen double x = rnormal()
    save `xs'
    clear
    set obs `N'
    gen id = _n
    gen double mu = rnormal(0, sqrt(3))
    expand `TT'
    bysort id: gen t = _n
    merge m:1 t using `xs', nogen
    gen double v = rnormal()
    gen double e = rnormal()
    sort id t
    gen double xi = v if t==1
    by id: replace xi = 0.8*xi[_n-1] + sqrt(1-0.8^2)*v if t>1
    gen double z = mu + xi
    gen double y = e if t==1
    by id: replace y = (0.5*z[_n-1] + 0.3*z[_n-1]^2 - 0.25*z[_n-1]^3)*x ///
        + 0.8*y[_n-1] + e if t>1
    drop if t <= `B'
    replace t = t - `B'
    drop v e xi mu
}
xtset id t

* A1. baseline: exactly the paper's LP (no constant, control L.y), AIC
csdlp y, shock(x) state(L.z) controls(L.y) horizons(0 4 8 12) noconstant ///
    seed(1) saving(csdlp_A_irf)

* A2. truth versus estimate on the grid
preserve
clear
matrix M = e(irf)
qui svmat double M, names(col)
gen double truth = 0.8^h*(0.5*z + 0.3*z^2 - 0.25*z^3)
gen byte covered = truth >= u_lo & truth <= u_hi
gen double err_sieve  = (g    - truth)^2
gen double err_linear = (glin - truth)^2
collapse (min) covered (mean) err_sieve err_linear, by(h)
gen rimse_sieve  = sqrt(err_sieve)
gen rimse_linear = sqrt(err_linear)
di _n as txt "{bf:Part A: truth vs estimate (95% uniform band covers truth on the whole grid?)}"
list h covered rimse_sieve rimse_linear, noobs sep(0)
di as txt "  (one draw: a 0 can occur -- finite-sample uniform coverage is about"
di as txt "   0.85-0.90 at this N,T; paper Table 3. Run csdlp_mc.do for coverage rates.)"
restore

* A3. alternative selectors, oracle J, VCEs, intermediate shocks
csdlp y, shock(x) state(L.z) controls(L.y) horizons(0 4) noconstant ///
    select(gcv) vce(hlag) seed(1) nograph
csdlp y, shock(x) state(L.z) controls(L.y) horizons(0 4) noconstant ///
    nbasis(4) vce(cluster) seed(1) nograph notable
matrix list e(summary), format(%9.3f)
csdlp y, shock(x) state(L.z) controls(L.y) horizons(0 2) noconstant ///
    nbasis(6) intermediate seed(1) nograph notable
matrix list e(summary), format(%9.3f)
if c(stata_version) >= 16 {
    csdlp y, shock(x) state(L.z) controls(L.y) horizons(0) noconstant ///
        select(lasso) seed(1) nograph notable
    matrix list e(J)
}

* A4. graphs: Lemma 1 diagnostic and response surface
qui csdlp y, shock(x) state(L.z) controls(L.y) horizons(0/8) noconstant ///
    seed(1) nograph notable
csdlp_graph, lemma saving(csdlp_A)
csdlp_graph, surface saving(csdlp_A)
csdlp_graph, horizons(2) pointwise

* =====================================================================
* PART B.  Firm panel: hump-shaped exposure to a monetary shock
*   inv_it = a(d2d_{i,t-1}) mp_t + s_{sector,t} + 0.5 inv_{i,t-1} + e_it
*   a(z)   = -4 exp(-z^2/2)   (a rate rise lowers investment most for
*                              firms near the mean distance to default)
*   lnk_t  = lnk_{t-1} + inv_t ;  cumulative LP outcome lnk_{t+h}-lnk_{t-1}
*   truth: g_h(z) = a(z) * sum_{j=0..h} 0.5^j (before normalisation)
* =====================================================================
clear
local N 400
local T 100
local TT = `T' + 50
tempfile mp st
qui {
    set obs `TT'
    gen t = _n
    gen double mp = 0.25*rnormal()
    save `mp'
    clear
    set obs `=10*`TT''
    gen sector = mod(_n-1, 10) + 1
    gen t = ceil(_n/10)
    gen double s_st = 0.02*rnormal()
    save `st'
    clear
    set obs `N'
    gen firm = _n
    gen sector = mod(_n, 10) + 1
    gen double mu = 0.6*rnormal()
    expand `TT'
    bysort firm: gen t = _n
    merge m:1 t using `mp', nogen
    merge m:1 sector t using `st', nogen keep(match)
    sort firm t
    gen double xi = rnormal() if t==1
    by firm: replace xi = 0.85*xi[_n-1] + sqrt(1-0.85^2)*rnormal() if t>1
    gen double d2d = mu + xi
    gen double inv = 0 if t==1
    by firm: replace inv = -4*exp(-(d2d[_n-1]^2)/2)*mp + s_st ///
        + 0.5*inv[_n-1] + 0.02*rnormal() if t>1
    gen double lnk = 3 + rnormal() if t==1
    by firm: replace lnk = lnk[_n-1] + inv if t>1
    gen double capital = exp(lnk)
    drop if t <= 50
    replace t = t - 50
    egen sd_d2d = std(d2d)
    replace d2d = sd_d2d
    drop sd_d2d xi mu
    format t %tq
}
xtset firm t

* B1. the standard linear-interaction LP vs the sieve LP,
*     sector-time FE (normalised g_h), response to a 25bp cut
csdlp lnk, shock(mp) state(L.d2d) controls(L.inv L.d2d) horizons(0/8) ///
    cumulative absorb(sector#t) scale(-0.25) level(90) level2(68)   ///
    range(2 98) seed(7) ghorizons(0 2 4 8) saving(csdlp_B_irf)

* B2. differential responses (paper Fig. 4): p50 vs p5 and p95 vs p50
csdlp_diff, at(50 5) saving(csdlp_B_diff_50_5)
csdlp_diff, at(95 50) saving(csdlp_B_diff_95_50)

* B3. aggregate responsiveness with capital shares (paper Fig. 5)
csdlp_agg L.capital, horizon(0) saving(csdlp_B_agg)
return list

* B4. replay
csdlp

di _n as txt "{bf:csdlp_example.do finished without error.}"
