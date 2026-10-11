*! surardl_asean6.do 1.0.1  10oct2026
*! The empirical application of Arif & Furuoka (2026, section 5):
*! renewable energy and economic growth in six ASEAN countries, 1990-2024.
*! Dr Merwan Roudane -- merwanroudane920@gmail.com
*! github.com/merwanroudane
*!
*! The specification below reproduces the paper's Table 9 (the residual
*! correlation matrix), the Breusch-Pagan and Pesaran CD statistics quoted
*! in section 5, and both the OLS and SUR columns of Table 10.
*!
*! It was identified by matching the published tables, because the draft
*! does not state the transformations. FDI enters as ln(FDI + 4) since the
*! series takes negative values; the deterministic specification is case 3,
*! an unrestricted constant and no trend.

version 14.0
clear all
set more off

use surardl_asean6, clear

* -------------------------------------------------------------------
* Transformations
* -------------------------------------------------------------------
generate double lrec = ln(rec)
generate double lgdp = ln(gdp)
generate double lfdi = ln(fdi + 4)
generate double lto  = ln(to)

label variable lrec "ln renewable energy consumption"
label variable lgdp "ln GDP per capita"
label variable lfdi "ln(FDI + 4)"
label variable lto  "ln trade openness"

xtset country year

* -------------------------------------------------------------------
* Step 0. Integration orders. The bounds approach is valid for any mix
* of I(0) and I(1), but no variable may be I(2) (Assumption 2(iii)).
* -------------------------------------------------------------------
display _n(2) "{hline 78}"
display "Step 0: unit-root pre-tests (Assumption 2)"
display "{hline 78}"
display "  variable  country          ADF level      ADF first difference"
foreach v of varlist lrec lgdp lfdi lto {
    forvalues i = 1/6 {
        quietly dfuller `v' if country == `i', lags(1) regress
        local a = r(Zt)
        quietly dfuller D.`v' if country == `i', lags(1) regress
        local b = r(Zt)
        local lab : label (country) `i'
        display "  " %-9s "`v'" %-14s "`lab'" %12.3f `a' %22.3f `b'
    }
}
display "  5% critical value is about -2.98. No variable should need"
display "  differencing twice to become stationary."

* -------------------------------------------------------------------
* Step 1. Single-equation benchmark, country by country.
* -------------------------------------------------------------------
display _n(2) "{hline 78}"
display "Step 1: equation-by-equation OLS benchmark (Table 10, OLS rows)"
display "{hline 78}"
surardl lrec lgdp lfdi lto, case(3) lags(1) method(ols) ///
    noctable nodiagnostics

* -------------------------------------------------------------------
* Step 2. The SUR-ARDL system.
* -------------------------------------------------------------------
display _n(2) "{hline 78}"
display "Step 2: SUR-ARDL system (Table 10, SUR rows)"
display "{hline 78}"
surardl lrec lgdp lfdi lto, case(3) lags(1)

estimates store sur

* -------------------------------------------------------------------
* Step 3. Was system estimation warranted?
* -------------------------------------------------------------------
display _n(2) "{hline 78}"
display "Step 3: cross-sectional dependence (Table 9)"
display "{hline 78}"
estat sigma

* -------------------------------------------------------------------
* Step 4. Is the lag structure long enough for Assumption 1(iii)?
* -------------------------------------------------------------------
display _n(2) "{hline 78}"
display "Step 4: serial correlation in the conditional errors"
display "{hline 78}"
estat serial, lags(2)
display "  Where this rejects, the ARDL(1,1,1,1) specification adopted by the"
display "  paper is too short for that country. Re-run with lags(2) or use"
display "  maxlags() to see how much the conclusions move."

* -------------------------------------------------------------------
* Step 5. Bounds test with SUR-specific critical values.
* -------------------------------------------------------------------
display _n(2) "{hline 78}"
display "Step 5: bounds test with SUR residual-bootstrap critical values"
display "{hline 78}"
display "  The tabulated PSS and Narayan bounds are calibrated for the"
display "  single-equation OLS F statistic and are liberal for the SUR"
display "  statistic at T = 34. The bootstrap is the right comparison."
surardl lrec lgdp lfdi lto, case(3) lags(1) bootstrap(999) seed(20261010) ///
    noctable nolrtable nodiagnostics

* -------------------------------------------------------------------
* Step 6. Long-run elasticities, with an interval that survives a weak
* speed of adjustment.
* -------------------------------------------------------------------
display _n(2) "{hline 78}"
display "Step 6: long-run elasticities"
display "{hline 78}"
estimates restore sur
estat longrun, fieller

* -------------------------------------------------------------------
* Step 7. The cross-equation evidence, which is what the system buys.
* -------------------------------------------------------------------
display _n(2) "{hline 78}"
display "Step 7: cross-equation hypotheses (section 5)"
display "{hline 78}"
display _n "  (a) Do the countries adjust at a common speed?"
estat ecequal, mtest(holm)

display _n "  (b) Is the long-run growth elasticity common?"
estat lrequal lgdp

display _n "  (c) Poolability of the long-run level coefficients"
estat poolability

display _n "  (d) How much precision did the system buy?"
estat efficiency

* -------------------------------------------------------------------
* Step 8. Figures.
* -------------------------------------------------------------------
display _n(2) "{hline 78}"
display "Step 8: figures"
display "{hline 78}"
estat graph

display _n "  surardl_lambda      adjustment speeds, sorted: the two clusters"
display "  surardl_bounds      bounds statistics against the PSS bands"
display "  surardl_longrun     long-run growth elasticity by country"
display "  surardl_sigma       cross-equation residual correlations"
display "  surardl_efficiency  precision gained over OLS"

display _n(2) "{hline 78}"
display "End of the ASEAN-6 application."
display "{hline 78}"
