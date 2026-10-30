*! ntcoint_example.do  1.0.0  27oct2026
*! Dr Merwan Roudane  -  merwanroudane920@gmail.com  -  github.com/merwanroudane
*!
*! Self-testing example for -ntcoint-.  Three parts:
*!   A. known-truth Monte Carlo on the paper's own DGP1, all four states of
*!      nature, so size and power can be read off directly;
*!   B. the empirical application, checked against the published Table 4;
*!   C. the option surface, exercised once each.
*!
*! Run with:   do ntcoint_example.do
*! Part A takes a few minutes.  Paste the log back for refereeing.

clear
set more off
version 16

di _n(2) as text "{hline 78}"
di as text "ntcoint example - Hualde & Olmo (2026) test of nontrivial cointegration"
di as text "{hline 78}"

* =====================================================================
* PART A.  Known-truth DGP from the online appendix (DGP1)
* =====================================================================
* Model (P2)-(P3) with mu_t = 0 and zero initial conditions:
*     v_t = 0.8 v_{t-1} + eps_t,   Var(eps_i) = 1,  Cov(eps_1,eps_2) = -0.4
* Four states of nature, exactly as the appendix's Panels (a)-(d):
*     NC  : x1, x2 independent random walks              (H0, size)
*     TC  : x1 stationary, x2 a random walk              (H0, size)
*     FC  : both stationary                              (H0, size)
*     NTC : x1 = x2 + v1, x2 a random walk, b = 1        (H1, power)
* The test must hold its size in the first three and have power in the fourth.

* The AR(1) recursion is built in Mata: a per-observation draw would make v_t
* white noise instead of the persistent process the DGP specifies, and an
* explicit Stata forvalues loop is far too slow inside a Monte Carlo.
mata:
void ntc_dgp1_mata(real scalar T, string scalar sn, real scalar rho,
                   real scalar phi, real scalar burn)
{
    real scalar n, t
    real matrix e, v, x
    n = T + burn
    e = rnormal(n, 2, 0, 1)
    e = e[.,1], (rho :* e[.,1] :+ sqrt(1-rho^2) :* e[.,2])
    v = J(n, 2, 0)
    v[1,.] = e[1,.]
    for (t = 2; t <= n; t++) v[t,.] = phi :* v[t-1,.] + e[t,.]
    if      (sn == "nc")  x = runningsum(v[.,1]), runningsum(v[.,2])
    else if (sn == "tc")  x = v[.,1],             runningsum(v[.,2])
    else if (sn == "fc")  x = v[.,1],             v[.,2]
    else                  x = (runningsum(v[.,2]) :+ v[.,1]), runningsum(v[.,2])
    x = x[|burn+1,1 \ n,.|]
    st_addobs(T)
    st_store(., st_addvar("double", ("x1","x2")), x)
}
end

capture program drop ntc_dgp1
program define ntc_dgp1
    syntax , T(integer) SN(string) [RHO(real -0.4) PHI(real 0.8)]
    if !inlist("`sn'", "nc", "tc", "fc", "ntc") {
        di as error "sn() must be nc, tc, fc or ntc"
        exit 198
    }
    clear
    mata: ntc_dgp1_mata(`t', "`sn'", `rho', `phi', 500)
    quietly generate int t = _n
    tsset t
end

* Runtime switch. The quick settings finish in a couple of minutes and are
* enough to see size control and power; set FULL to 1 to reproduce the
* appendix's precision (5,000 replications), which takes hours.
local FULL 0
if `FULL' {
    local NREP 1000
    local BREP 499
}
else {
    local NREP 50
    local BREP 99
}

di _n as text "{hline 78}"
di as text "A. Rejection frequencies, DGP1, `NREP' replications, nominal 10%"
di as text "   H0 holds under NC, TC and FC (want ~0.10 or below)"
di as text "   H1 holds under NTC          (want power rising to 1 in T)"
di as text "{hline 78}"
di as text %-6s "T" %10s "state" %12s "cons" %12s "plug" %12s "boot"
di as text "{hline 78}"

foreach T in 100 200 {
    foreach sn in nc tc fc ntc {
        local rc = 0
        local rp = 0
        local rb = 0
        forvalues rep = 1/`NREP' {
            * vary the seed every replication: a fixed seed makes the internal
            * bootstrap RNG reset and the size estimate degenerate
            set seed `=20260000 + 1000*`rep' + `T''
            quietly ntc_dgp1, t(`T') sn("`sn'")
            quietly ntcoint x1 x2, level(90) reps(`BREP')
            local rc = `rc' + r(rej_cons)
            local rp = `rp' + r(rej_plug)
            local rb = `rb' + r(rej_boot)
        }
        di as text %-6.0f `T' %10s "`=upper("`sn'")'"                       ///
           as result %12.3f `rc'/`NREP' %12.3f `rp'/`NREP' %12.3f `rb'/`NREP'
    }
}
di as text "{hline 78}"

* =====================================================================
* PART B.  The empirical application, against the published Table 4
* =====================================================================
* The dataset is an ancillary file: net install does not place it on the
* adopath, so it must be fetched into the working directory first.
capture confirm file "ntcoint_ecbyields.dta"
if _rc {
    capture findfile ntcoint_ecbyields.dta
    if _rc {
        di as error "ntcoint_ecbyields.dta not found in the working directory."
        di as error "Fetch the ancillary files first, then rerun:"
        di as error "    . net get ntcoint"
        exit 601
    }
    local dta "`r(fn)'"
}
else local dta "ntcoint_ecbyields.dta"

use "`dta'", clear

di _n as text "{hline 78}"
di as text "B. Euro-area yields, 6 Sep 2004 - 7 Apr 2025, T = `=_N'"
di as text "{hline 78}"

* 21 pairs x `BREP' bootstrap replications on T = 5,263; the paper uses 500
ntcoint y3m y1y y2y y5y y7y y10y y30y, level(90) reps(`BREP') seed(20261027)

di _n as text "   Table 4 of the paper, for comparison (r = short-run, rho = long-run):"
di as text "     pair          r      rho"
di as text "     3m  / 1y   0.989    0.454"
di as text "     5y  / 7y   0.993    0.976"
di as text "     10y / 30y  0.987    0.824"
di as text "     2y  / 5y   0.964    0.880"

* single pair, with the identification plot
quietly ntcoint y10y y30y, level(90) reps(`BREP') seed(20261027)
di _n as text "   single pair y10y / y30y:"
di as text "     SCR      = " as result %8.4f r(scr)
di as text "     cv cons  = " as result %8.4f r(cv_cons)
di as text "     cv plug  = " as result %8.4f r(cv_plug)
di as text "     boot p   = " as result %8.4f r(p_boot)
di as text "     T        = " as result %8.0f r(T)

* =====================================================================
* PART C.  Option surface
* =====================================================================
di _n as text "{hline 78}"
di as text "C. Every code path exercised once"
di as text "{hline 78}"

di _n as text "C1. linear trend specification"
ntcoint y10y y30y, trend level(90) nobootstrap

di _n as text "C2. the replication package's critical values"
ntcoint y10y y30y, cvtable(authors) level(90) nobootstrap

di _n as text "C3. alternative bandwidth pairs (1/4,1/5) and (1/6,1/7)"
ntcoint y10y y30y, lambda(0.25 0.2)      level(90) nobootstrap
ntcoint y10y y30y, lambda(0.1666667 0.1428571) level(90) nobootstrap

di _n as text "C4. alternative kernels (a warning is expected)"
ntcoint y10y y30y, kernel(bartlett) level(90) nobootstrap

di _n as text "C5. the fast bootstrap variant, which is NOT the paper's algorithm"
ntcoint y10y y30y, btype(2) reps(`BREP') seed(1) level(90)

di _n as text "C6. 1% level"
ntcoint y10y y30y, level(99) nobootstrap

di _n as text "C7. if/in restriction"
ntcoint y10y y30y if t <= 2000, level(90) nobootstrap

di _n as text "C8. the diagnostic plots"
capture graph drop _all
ntcoint y10y y30y, level(90) reps(`BREP') seed(11) plot(all) name(ex)
* grab the matrices FIRST: -graph dir- is rclass and would wipe r()
matrix cvc = r(cvcurve)
matrix bw  = r(bwscan)
quietly graph dir
di as text "  graphs drawn: " as result "`r(list)'"
di as text "  r(cvcurve) is " as result rowsof(cvc) as text " x " ///
   as result colsof(cvc) as text " (rho, cv)"
di as text "  bandwidth scan (lambda1 lambda2 K1 K2 SCR cv_cons cv_plug):"
matrix list bw, format(%8.4f) noheader

capture graph drop _all
* with the bootstrap, so the map counts all three SCR tests (0-3), not two
ntcoint y3m y1y y2y y5y y7y y10y y30y, level(90) reps(`BREP') seed(12) plot(pairs)
matrix dm = r(decmap)
quietly graph dir
di as text "  pairs map drawn: " as result "`r(list)'"
di as text "  decision map (0-3 SCR tests rejecting):"
matrix list dm, format(%3.0f) noheader

di _n as text "C9. errors that should be caught (a nonzero rc here is the point)"
local bad 0
foreach bad_call in "lambda(0.1 0.2)" "level(80)" "kernel(quadratic)" ///
                    "plot(nonsense)" "nobootstrap plot(boot)" {
    capture noisily ntcoint y10y y30y, `bad_call'
    if _rc == 0 {
        di as error "  !! ntcoint y10y y30y, `bad_call' should have failed"
        local bad = `bad' + 1
    }
}
capture noisily ntcoint y10y y30y if t <= 15
if _rc == 0 {
    di as error "  !! a 15-observation sample should have been refused"
    local bad = `bad' + 1
}
di as text "  unguarded cases: " as result `bad'
* leave _rc clean so a successful run of this file exits with 0
capture confirm number 1

di _n as text "{hline 78}"
di as text "example complete"
di as text "{hline 78}"
