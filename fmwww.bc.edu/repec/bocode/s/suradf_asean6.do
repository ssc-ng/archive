*------------------------------------------------------------------------------
* suradf_asean6.do -- applied walkthrough
*
* Series-specific SUR-ADF unit root tests on six ASEAN economies, 1990-2024.
* Variables: renewable energy consumption, real GDP per capita, FDI inflows,
*            trade openness.
*
* This file is written as a decision guide: each step states what question is
* being asked and what the answer licenses you to conclude.
*
* Dr Merwan Roudane  <merwanroudane920@gmail.com>
* https://github.com/merwanroudane
*------------------------------------------------------------------------------

clear
set more off

use suradf_asean6, clear
xtset country year

*==============================================================================
* STEP 0.  Do the preconditions hold?
*==============================================================================
* SURADF is a small-N large-T procedure.  Feasible GLS has to estimate an
* N x N error covariance matrix from the usable sample, so T must comfortably
* exceed N.  Check that first -- before looking at any result.

xtdescribe

quietly levelsof country, local(cs)
local N : word count `cs'
quietly levelsof year, local(ys)
local T : word count `ys'
di as txt _n "N = " as res `N' as txt "   T = " as res `T' ///
    as txt "   T/N = " as res %4.1f `T'/`N'

* T/N is near 6 here, which is workable but not generous.  Annual data with
* T = 35 is a SHORT sample for this test: expect low power, and read a
* failure to reject as "cannot reject", never as "there is a unit root".
*
* Because the data are annual, do NOT leave maxlags at its default of 8 --
* that is calibrated to the paper's quarterly data and would throw away nine
* observations out of thirty-five.  Three is the conventional annual ceiling.

local MAXL 3

*==============================================================================
* STEP 1.  Transform
*==============================================================================
gen double lrec = ln(rec)
gen double lgdp = ln(gdp)
gen double lto  = ln(to)
label variable lrec "log renewable energy consumption"
label variable lgdp "log real GDP per capita"
label variable lto  "log trade openness"

* fdi contains non-positive values (net outflow years), so it stays in levels.
label variable fdi  "FDI inflows, % of GDP"

*==============================================================================
* STEP 2.  The test, on log GDP per capita
*==============================================================================
di as txt _n(2) "{hline 78}"
di as txt "log real GDP per capita -- levels"
di as txt "{hline 78}"

suradf lgdp, maxlags(`MAXL') reps(5000) seed(20021128) graph name(gdp_lev)

* HOW TO READ THIS
*
* 1. AVECOR first.  These six economies are highly integrated, so the residual
*    cross-correlations are substantial.  That is exactly the case in which
*    SURADF buys real power over equation-by-equation dfuller -- and also the
*    case in which the critical values move furthest from the Dickey-Fuller
*    table.  Compare the "Panel average" line with the "Dickey-Fuller 5%" line
*    printed underneath it.
*
* 2. Then the verdict block.  It names which economies reject and which do not.
*    That naming is the entire reason to use this test instead of a joint one.
*
* 3. Then k.  If any series sits at the maxlags ceiling, the search was
*    truncated; raise the ceiling and check the verdict does not move.

*==============================================================================
* STEP 3.  What a JOINT panel test would have told you instead
*==============================================================================
di as txt _n(2) "{hline 78}"
di as txt "The same data under joint-hypothesis panel tests"
di as txt "{hline 78}"

* Im-Pesaran-Shin and Fisher both test "ALL series have a unit root" against
* "at least one does not".  Whatever they return, they cannot tell you WHICH.
capture noisily xtunitroot ips lgdp, lags(1)
capture noisily xtunitroot fisher lgdp, dfuller lags(1)

* And the single-equation benchmark, which ignores the cross-correlation
* altogether.  The ADF column in the suradf table is this same statistic.
foreach c of local cs {
    local lbl : label (country) `c'
    di as txt _n "dfuller, `lbl':"
    capture noisily dfuller lgdp if country == `c', lags(1)
}

*==============================================================================
* STEP 4.  Is it I(1) or I(2)?  Re-run on first differences.
*==============================================================================
* A series is I(1) only if the LEVEL fails to reject and the DIFFERENCE does.
* Skipping this step is the most common error in applied work.
di as txt _n(2) "{hline 78}"
di as txt "log real GDP per capita -- first differences"
di as txt "{hline 78}"

gen double dlgdp = D.lgdp
suradf dlgdp, maxlags(`=`MAXL'-1') reps(5000) seed(20021128)

* If the differences reject and the levels do not, the series are I(1) and may
* enter a cointegrating / ARDL specification.  If the differences ALSO fail to
* reject, do not conclude I(2) from this test alone at T = 35 -- that is far
* more likely to be low power than a second unit root.

*==============================================================================
* STEP 5.  The other three variables
*==============================================================================
foreach v in lrec fdi lto {
    local lbl : variable label `v'
    di as txt _n(2) "{hline 78}"
    di as txt "`lbl' (`v') -- levels"
    di as txt "{hline 78}"
    suradf `v', maxlags(`MAXL') reps(5000) seed(20021128) nodots
}

*==============================================================================
* STEP 6.  Robustness that is worth reporting
*==============================================================================
di as txt _n(2) "{hline 78}"
di as txt "Robustness on lgdp"
di as txt "{hline 78}"

di as txt _n "6a. Lag rule: does the verdict survive a different selector?"
suradf lgdp, maxlags(`MAXL') lags(aic) reps(2000) seed(20021128) nodots
suradf lgdp, maxlags(`MAXL') lags(bic) reps(2000) seed(20021128) nodots

di as txt _n "6b. Drop the normality assumption on the innovations"
suradf lgdp, maxlags(`MAXL') dist(bootstrap) reps(2000) seed(20021128) nodots

di as txt _n "6c. Iterated rather than two-step FGLS"
suradf lgdp, maxlags(`MAXL') isure reps(2000) seed(20021128) nodots

* If a verdict flips across 6a-6c, say so in the paper. A result that only
* survives one lag rule is not a result.

*==============================================================================
* STEP 7.  THE COMPOSITION WARNING, demonstrated
*==============================================================================
* Ford, Jackson and Kline (2006) objected that SURADF outcomes are sensitive to
* which members are in the panel.  They are right about the mechanism: the
* critical values are a function of the covariance matrix of the WHOLE system,
* so removing one country changes the critical value of every other country.
*
* Below, the same five countries are tested twice -- once inside the six-country
* panel, once on their own.  Watch the critical values move.

di as txt _n(2) "{hline 78}"
di as txt "Composition sensitivity: the same five countries, two panels"
di as txt "{hline 78}"

quietly suradf lgdp, maxlags(`MAXL') reps(5000) seed(20021128) nodots notable
matrix SIX = r(cv)
di as txt _n "5% critical values inside the SIX-country panel:"
matrix list SIX, format(%8.3f)

quietly suradf lgdp if country != 6, maxlags(`MAXL') reps(5000) seed(20021128) nodots notable
matrix FIVE = r(cv)
di as txt _n "5% critical values with Vietnam removed (FIVE-country panel):"
matrix list FIVE, format(%8.3f)

* The statistics themselves also change, because the SUR weights change.
* THE LESSON: fix your panel membership on economic grounds BEFORE you look at
* results, state those grounds in the paper, and never present statistics from
* one panel against critical values from another.

*==============================================================================
* STEP 8.  A reporting-ready summary table
*==============================================================================
di as txt _n(2) "{hline 78}"
di as txt "Summary for the paper"
di as txt "{hline 78}"

tempname OUT
matrix `OUT' = J(1, 4, .)
local rn ""
foreach v in lgdp lrec fdi lto {
    quietly suradf `v', maxlags(`MAXL') reps(5000) seed(20021128) nodots notable
    matrix `OUT' = `OUT' \ (r(N), r(nI0), r(nI1), r(avecor))
    local rn "`rn' `v'"
}
matrix `OUT' = `OUT'[2..., 1...]
matrix rownames `OUT' = `rn'
matrix colnames `OUT' = N I0_at_5pct I1_at_5pct avg_resid_corr
di as txt _n "Series-specific verdicts at the 5% level:"
matlist `OUT', format(%9.3f) border(rows) twidth(16)

di as txt _n "{p 0 2}Report alongside this: the lag rule and chosen k per series,"
di as txt "reps() and seed(), the AVECOR column, and the SERIES-SPECIFIC critical"
di as txt "values -- without them the statistics cannot be interpreted, since no"
di as txt "published table applies to this panel.{p_end}"
