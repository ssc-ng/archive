*! xtmvardlurt_multivariate_example.do  v1.0.6  11oct2026
*! Examples for xtmvardlurt_multivariate (panel multivariate ARDL unit root /
*! cointegration test).  Run section by section.

clear all
set more off

* =============================================================================
* 0. Check the installation against the supplied test data (deterministic part)
*    Compare columns t-stat and F-stat with xtmvardlurt_multivariate_expected.txt
* =============================================================================
* import delimited using xtmvardlurt_multivariate_testdata.csv, clear
* xtset id t
* xtmvardlurt_multivariate y x1 x2 x3, fixlag(1 1) case(3) reps(99) units

* =============================================================================
* 1. Simulate a panel: 20 units, 60 periods, 3 I(1) covariates,
*    a common factor (cross-sectional dependence)
* =============================================================================
set seed 2026
local N 20
local T 60
set obs `=`N'*`T''
gen id = ceil(_n/`T')
bysort id: gen t = _n
xtset id t

sort t id
by t: gen f = rnormal() if _n == 1
by t: replace f = f[1]
sort id t

gen ey = 0.8*f + rnormal()
foreach v in x1 x2 x3 {
	gen e_`v' = rnormal()
	by id: gen `v' = sum(e_`v')
}
by id: gen y_rw = sum(ey)                           // unit root, no cointegration
by id: gen u = ey if _n == 1
by id: replace u = 0.5*u[_n-1] + ey if _n > 1
gen y_coint = 1 + 0.6*x1 - 0.4*x2 + 0.3*x3 + u      // cointegrated
gen y_stat  = 1 + u                                  // stationary

* =============================================================================
* 2. Basic usage (BIC lag selection, re-selected in every bootstrap draw)
* =============================================================================
xtmvardlurt_multivariate y_coint x1 x2 x3, reps(499)
xtmvardlurt_multivariate y_rw    x1 x2 x3, reps(499)
xtmvardlurt_multivariate y_stat  x1 x2 x3, reps(499)

* =============================================================================
* 3. Options
* =============================================================================
* fixed lags: p own lags, q lags of each covariate difference
xtmvardlurt_multivariate y_coint x1 x2 x3, fixlag(1 1) reps(499)

* AIC instead of BIC, longer search
xtmvardlurt_multivariate y_coint x1 x2 x3, ic(aic) maxlag(4) reps(499)

* trend cases: 4 = restricted trend, 5 = unrestricted trend
xtmvardlurt_multivariate y_coint x1 x2 x3, case(5) fixlag(1 1) reps(499)

* cross-sectional dependence: auto (default), on, off
xtmvardlurt_multivariate y_coint x1 x2 x3, csd(on)  fixlag(1 1) reps(499)
xtmvardlurt_multivariate y_coint x1 x2 x3, csd(off) fixlag(1 1) reps(499)

* significance level of the decision, list every unit, save graphs
xtmvardlurt_multivariate y_coint x1 x2 x3, level(90) units reps(499) graph

* =============================================================================
* 4. Stored results and graphs
* =============================================================================
xtmvardlurt_multivariate y_coint x1 x2 x3, fixlag(1 1) reps(499) nodisplay
ereturn list
matrix list e(panel)
matrix list e(unit)
display "t-bar = " e(tbar) "   bootstrap p = " e(p_tbar)
xtmvardlurt_multivariate_graph

* =============================================================================
* 4b. Diagnostics: residual serial-correlation check (Breusch-Godfrey, order 1)
*     The bootstrap needs serially uncorrelated residuals. The output prints a
*     "Residual check" line, shows a "BG p" column in Table 3 (option units), and
*     adds a note when the test rejects in 30% or more of the units.
* =============================================================================
* no lags: with serially uncorrelated errors (as here) rejections stay near 5%;
* with autocorrelated errors and too few lags, expect many rejections and a note
xtmvardlurt_multivariate y_rw x1 x2 x3, fixlag(0 0) reps(199) units
display "units rejecting BG at 5%: " e(bg_n) " of " e(N_units)

* adequate lags: rejections close to the 5% expected by chance
xtmvardlurt_multivariate y_rw x1 x2 x3, fixlag(1 1) reps(199) units
display "units rejecting BG at 5%: " e(bg_n) " of " e(N_units)
* per-unit p-values are in the last column of e(unit)
matrix list e(unit)

* =============================================================================
* 4c. Post-estimation (estat)
* =============================================================================
xtmvardlurt_multivariate y_coint x1 x2 x3, fixlag(1 1) reps(499) nodisplay
estat diagnostics
matrix list e(diag)
estat paneltests
estat collinearity
matrix list e(pdiag)
estat cases
estat lags
estat unitdata, saving(unit_results) replace

* =============================================================================
* 5. Unbalanced panel (different start/end dates) - works without changes
* =============================================================================
drop if id <= 5 & t <= 10
drop if id > 15 & t > 50
xtmvardlurt_multivariate y_coint x1 x2 x3, fixlag(1 1) reps(499) nounits
