*------------------------------------------------------------------------------
* suradf_example.do -- self-test and demonstration
*
* Series-specific SUR-ADF panel unit root test
* Breuer, McNown & Wallace (2002), OBES 64(5), 527-546
*
* Dr Merwan Roudane  <merwanroudane920@gmail.com>
* https://github.com/merwanroudane
*
* Run this AFTER:   do suradf.ado      (surfaces any Mata compile error with
*                                       the offending line)
* or after:         net install suradf, from("<this folder>") replace
*
* IMPORTANT when re-running after an edit: if suradf is already in memory,
* Stata refuses to redefine it ("program suradf already defined", r(110)) and
* SILENTLY KEEPS THE OLD CODE -- so you end up testing the previous version.
* Always start from a clean slate:
*
*     clear all
*     do suradf.ado
*     do suradf_example.do
*
* Every section prints the TRUTH it generated next to what the command found,
* so a wrong answer is visible without reading the code.
*------------------------------------------------------------------------------

clear                   // NOT clear all -- that would drop a just-loaded suradf
set more off
capture log close _all
capture erase suradf_example.log
capture log using suradf_example.log, replace text
if (_rc) {
    * the usual cause is another Stata session still holding the file open
    local stamp = subinstr("`c(current_time)'", ":", "", .)
    capture log using "suradf_example_`stamp'.log", replace text
    if (_rc) {
        di as txt "note: no log file could be opened (is another Stata session"
        di as txt "holding it?).  Continuing without one -- output goes to screen."
    }
    else {
        di as txt "note: logging to suradf_example_`stamp'.log"
    }
}

di as txt _n "{hline 78}"
di as txt "suradf self-test" _n "{hline 78}"

*==============================================================================
* A helper that builds N cross-correlated series with a chosen persistence
*   rho = 1    -> I(1)
*   rho < 1    -> I(0)
* Errors are drawn jointly so they are correlated ACROSS series at the same t,
* which is the dependence the SUR estimator exploits.
*==============================================================================
capture program drop _mkpanel
program define _mkpanel
    * Two traps here, both already paid for:
    *  - an integer option must carry a default, or the local arrives empty
    *    and the arithmetic below silently collapses to the burn-in alone;
    *  - the option must NOT be named nobs: syntax reads a leading "no" as a
    *    negation, so NOBS parses as no+BS and rejects an argument.
    syntax [, OBS(integer 100) RHO(string) CORR(real 0.75) BURN(integer 50) ]
    if ("`rho'" == "") local rho "1 1 1 1 1 1"
    local N : word count `rho'
    local TT = `obs' + `burn'
    if (`obs' < 10) {
        di as error "obs() must be at least 10"
        exit 198
    }

    clear
    matrix C = J(`N', `N', `corr') + I(`N') * (1 - `corr')
    * "e1-e1" is not a valid newvarlist range, so name the single case directly
    local elist "e1-e`N'"
    if (`N' == 1) local elist "e1"
    drawnorm `elist', corr(C) n(`TT') clear
    gen int t = _n
    tsset t

    forvalues i = 1/`N' {
        local r : word `i' of `rho'
        gen double y`i' = e`i'
        quietly replace y`i' = `r' * L.y`i' + e`i' if _n > 1
    }
    quietly drop if _n <= `burn'
    quietly replace t = _n
    tsset t
    local ylist "y1-y`N'"
    if (`N' == 1) local ylist "y1"
    keep t `ylist'
end

*==============================================================================
* 1. ALL SERIES I(1).  Truth: no series should reject.  This is the size check.
*==============================================================================
di as txt _n "{hline 78}"
di as txt "1. Six I(1) series, cross-correlation 0.75.  TRUTH: all six I(1)."
di as txt "{hline 78}"

set seed 20021128
_mkpanel , obs(120) rho("1 1 1 1 1 1") corr(0.75)
reshape long y, i(t) j(id)
xtset id t

suradf y, reps(1000) seed(101)

di as txt _n "   TRUTH: 6 of 6 are I(1).   suradf found I(1): " as res r(nI1) ///
    as txt " of " as res r(N)

*==============================================================================
* 2. ALL SERIES I(0).  Truth: all should reject.  This is the power check.
*==============================================================================
di as txt _n "{hline 78}"
di as txt "2. Six stationary AR(0.60) series.  TRUTH: all six I(0)."
di as txt "{hline 78}"

set seed 20021128
_mkpanel , obs(120) rho(".6 .6 .6 .6 .6 .6") corr(0.75)
reshape long y, i(t) j(id)
xtset id t

suradf y, reps(1000) seed(102)

di as txt _n "   TRUTH: 6 of 6 are I(0).   suradf found I(0): " as res r(nI0) ///
    as txt " of " as res r(N)

*==============================================================================
* 3. MIXED PANEL.  This is the whole reason the test exists: a joint panel
*    test can only say "not all have a unit root".  suradf must name them.
*    TRUTH: series 1, 2, 3 are I(0); series 4, 5, 6 are I(1).
*==============================================================================
di as txt _n "{hline 78}"
di as txt "3. MIXED panel: y1 y2 y3 stationary AR(0.55), y4 y5 y6 random walks."
di as txt "   TRUTH: I(0) = {1, 2, 3}    I(1) = {4, 5, 6}"
di as txt "{hline 78}"

set seed 20021128
_mkpanel , obs(150) rho(".55 .55 .55 1 1 1") corr(0.75)
reshape long y, i(t) j(id)
xtset id t

suradf y, reps(2000) seed(103) graph

di as txt _n "   TRUTH: I(0) = 3 of 6.   suradf found I(0): " as res r(nI0) ///
    as txt " of " as res r(N)
di as txt "   Check the series-specific block above: it should name 1, 2 and 3."

*==============================================================================
* 4. EVERY OPTION EXERCISED on the mixed panel
*==============================================================================
di as txt _n "{hline 78}"
di as txt "4. Option coverage (same data as section 3)"
di as txt "{hline 78}"

di as txt _n "4a. lags(bmw) -- the paper's Section V rule (default)"
suradf y, lags(bmw) reps(400) seed(1) nodots

di as txt _n "4b. lags(aic)"
suradf y, lags(aic) reps(400) seed(1) nodots

di as txt _n "4c. lags(bic)"
suradf y, lags(bic) reps(400) seed(1) nodots

di as txt _n "4d. lags(1) -- one lag for every equation"
suradf y, lags(1) reps(400) seed(1) nodots

di as txt _n "4e. lags(2 1 0 3 1 2) -- one order per series"
suradf y, lags(2 1 0 3 1 2) reps(400) seed(1) nodots

di as txt _n "4f. isure -- iterated FGLS"
suradf y, isure reps(400) seed(1) nodots

di as txt _n "4g. dfk -- small-sample covariance divisor"
suradf y, dfk reps(400) seed(1) nodots

di as txt _n "4h. dist(bootstrap) -- resampled residuals (extension, not in paper)"
suradf y, dist(bootstrap) reps(400) seed(1) nodots

di as txt _n "4i. trend -- warned extension"
suradf y, trend reps(400) seed(1) nodots

di as txt _n "4ja. adfpretest -- the Breuer-McNown-Wallace (2006) membership rule."
di as txt "    On this MIXED panel it should drop some of y1 y2 y3 (the truly"
di as txt "    stationary ones) and keep the random walks y4 y5 y6."
suradf y, adfpretest reps(400) seed(1) nodots
di as txt "    any series excluded? r(ptdrop) = " as res r(ptdrop) ///
    as txt "   N remaining = " as res r(N)

di as txt _n "4jb. adfpretest at a stricter level -- should exclude fewer"
suradf y, adfpretest ptlevel(1) reps(400) seed(1) nodots
di as txt "    N remaining = " as res r(N)

di as txt _n "4j. reps(0) -- statistics only, no critical values"
suradf y, reps(0)

di as txt _n "4k. savedist + distplot + named graphs"
suradf y, reps(600) seed(1) nodots savedist(SIMDRAWS) graph distplot name(mix)
di as txt "   dimensions of the saved draws:"
matrix list SIMDRAWS, nohalf format(%6.2f) noheader title("")

di as txt _n "4l. stored results"
di as txt "   r(N)      = " as res r(N)
di as txt "   r(T)      = " as res r(T)
di as txt "   r(Teff)   = " as res r(Teff)
di as txt "   r(kmax)   = " as res r(kmax)
di as txt "   r(avecor) = " as res %6.4f r(avecor)
di as txt "   r(lags)   = " as res "`r(lags)'"
matrix RT = r(table)
matrix list RT, format(%8.3f)

*==============================================================================
* 5. WIDE FORM, tsset instead of xtset
*==============================================================================
di as txt _n "{hline 78}"
di as txt "5. Wide form: the same six series as six variables under tsset"
di as txt "{hline 78}"

set seed 20021128
_mkpanel , obs(150) rho(".55 .55 .55 1 1 1") corr(0.75)
suradf y1 y2 y3 y4 y5 y6, reps(600) seed(103) nodots

di as txt _n "   Should match section 3 closely (same data, same seed)."

*==============================================================================
* 6. ERROR PATHS -- each should fail with a clear message, not a crash
*==============================================================================
di as txt _n "{hline 78}"
di as txt "6. Error handling"
di as txt "{hline 78}"

di as txt _n "6a. N too large relative to T (should refuse):"
set seed 7
_mkpanel , obs(14) rho("1 1 1 1 1 1 1 1 1 1 1 1") corr(0.5)
reshape long y, i(t) j(id)
xtset id t
capture noisily suradf y, reps(100) nodots
di as txt "   return code = " as res _rc

di as txt _n "6b. a single series (should point at dfuller):"
set seed 7
_mkpanel , obs(100) rho("1") corr(0.5)
capture noisily suradf y1, reps(100) nodots
di as txt "   return code = " as res _rc

di as txt _n "6c. unbalanced panel (should refuse):"
set seed 7
_mkpanel , obs(100) rho("1 1 1 1") corr(0.5)
reshape long y, i(t) j(id)
xtset id t
quietly drop if id == 3 & t > 60
capture noisily suradf y, reps(100) nodots
di as txt "   return code = " as res _rc

di as txt _n "6d. gap in the time variable (should refuse):"
set seed 7
_mkpanel , obs(100) rho("1 1 1 1") corr(0.5)
reshape long y, i(t) j(id)
quietly drop if inrange(t, 40, 45)
xtset id t
capture noisily suradf y, reps(100) nodots
di as txt "   return code = " as res _rc

*==============================================================================
* 7. MONTE CARLO CALIBRATION
*    A test that runs can still return wrong p-values.  Only this proves the
*    critical values are right.  NOTE the seed VARIES every replication --
*    a fixed seed resets the internal RNG and gives a degenerate answer.
*==============================================================================
di as txt _n "{hline 78}"
di as txt "7. Monte Carlo size and power (nominal 5%, per series)"
di as txt "   This section is slow -- roughly a few minutes."
di as txt "{hline 78}"

capture program drop _mccheck
program define _mccheck, rclass
    syntax [, REPS(integer 40) INNER(integer 400) RHO(string)               ///
        CORR(real 0.5) OBS(integer 100) LABel(string) ]
    local rej = 0
    local tot = 0
    forvalues r = 1/`reps' {
        quietly {
            _mkpanel , obs(`obs') rho(`"`rho'"') corr(`corr')
            reshape long y, i(t) j(id)
            xtset id t
            capture suradf y, reps(`inner') seed(`=90000 + `r'') nodots notable
        }
        if (_rc) continue
        matrix mcT = r(table)
        local n = r(N)
        forvalues i = 1/`n' {
            local ++tot
            if (mcT[`i', 4] <= mcT[`i', 6]) local ++rej
        }
    }
    local rate = `rej' / `tot'
    di as txt %-42s "`label'" as res %7.3f `rate' as txt "   (`rej'/`tot')"
    return scalar rate = `rate'
end

di as txt _n "SIZE  -- all series I(1); should land near 0.050"
_mccheck , reps(40) inner(400) rho("1 1 1 1 1 1") corr(0.25) obs(100) ///
    label("N=6 T=100 corr 0.25")
_mccheck , reps(40) inner(400) rho("1 1 1 1 1 1") corr(0.75) obs(100) ///
    label("N=6 T=100 corr 0.75")

di as txt _n "POWER -- all series AR(0.70); should be well above 0.050"
_mccheck , reps(40) inner(400) rho(".7 .7 .7 .7 .7 .7") corr(0.25) obs(100) ///
    label("N=6 T=100 corr 0.25  AR=0.70")
_mccheck , reps(40) inner(400) rho(".7 .7 .7 .7 .7 .7") corr(0.75) obs(100) ///
    label("N=6 T=100 corr 0.75  AR=0.70")

di as txt _n "{hline 78}"
di as txt "Expected reading:"
di as txt "  - size rows near 0.05 (a little below is fine and safe);"
di as txt "  - power rows clearly higher, and HIGHER at corr 0.75 than at 0.25,"
di as txt "    which is the paper's central finding about where SUR pays off."
di as txt "{hline 78}"

capture log close
di as txt _n "Done."
