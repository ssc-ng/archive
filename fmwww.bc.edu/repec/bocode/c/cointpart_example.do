*! cointpart_example.do  1.0.0  27oct2026
*! Worked demonstration and self-test for cointpart.
*! Author: Merwan Roudane  (merwanroudane920@gmail.com)
*
* Run it after installing the package:
*     net get cointpart
*     do cointpart_example.do
*
* Six parts:
*   1. the paper's application, reproducing its table 5
*   2. a known-truth DGP: cointegration in a middle window only
*   3. directional consistency (proposition A.1) -- the key claim
*   4. empirical size under the null
*   5. every option exercised
*   6. the validity guards
*
* Parts 3 and 4 run short Monte Carlo loops and take a minute or two.

clear
set more off
version 14.0

di as text "{hline 78}"
di as text "cointpart -- worked example and self-test"
di as text "{hline 78}"

*=======================================================================
* 1. The paper's application: sea level and surface temperature
*=======================================================================
di ""
di as text "{hline 78}"
di as text "1. Application: global mean sea level and temperature, 1880-2019"
di as text "{hline 78}"

capture use cointpart_sealevel, clear
if _rc {
    di as error "cointpart_sealevel.dta not found."
    di as error "Retrieve the ancillary files with:  net get cointpart"
    exit 601
}
tsset year

di ""
di as text "Integration-order pre-tests. The framework assumes both series are I(1);"
di as text "check that before anything else."
di ""
dfuller sea_level, lags(1)
dfuller temperature, lags(3)
dfuller D.sea_level, lags(0)
dfuller D.temperature, lags(2)
di as text "-> levels give no evidence against a unit root; differences reject"
di as text "   decisively. Both series are treated as I(1)."

di ""
di as text "Both series drift, so Case ct is the appropriate specification."
di as text "Temperature is the regressand, following the weak-exogeneity result"
di as text "of Schmith, Johansen and Thejll (2012)."
di ""
cointpart temperature sea_level, case(ct) betas

di ""
di as text "Expected from the paper's table 5, panel B:"
di as text "   FIEG -5.620 over 1880-2019,  BIEG -6.213 over 1967-2019,"
di as text "   GIEG -7.414 over 1947-1967."
di as text "Obtained:"
di as text "   FIEG " as result %7.3f r(fieg) as text " over " ///
   as result r(fieg_t1) as text "-" as result r(fieg_t2)
di as text "   BIEG " as result %7.3f r(bieg) as text " over " ///
   as result r(bieg_t1) as text "-" as result r(bieg_t2)
di as text "   GIEG " as result %7.3f r(gieg) as text " over " ///
   as result r(gieg_t1) as text "-" as result r(gieg_t2)

di ""
di as text "The GIEG window 1947-1967 covers the two decades after the wartime"
di as text "change in sea surface temperature measurement documented by Thompson"
di as text "et al. (2008). The procedure locates where the question has to be"
di as text "settled; it cannot say whether the episode is physical or an artefact"
di as text "of the instrument record."

di ""
di as text "The window is exactly as long as the trimming admits, so check that:"
di ""
foreach r in 0.10 0.15 0.20 {
    qui cointpart temperature sea_level, case(ct) trim(`r')
    di as text "   trim(`r')  GIEG = " as result %7.3f r(gieg) ///
       as text "  window " as result r(gieg_t1) as text "-" as result r(gieg_t2)
}
di as text "-> the GIEG result moves with trim(); report it as suggestive."

di ""
di as text "The normalization matters. Reversed, nothing rejects:"
di ""
cointpart sea_level temperature, case(ct)

*=======================================================================
* 2. Known truth: cointegration in a middle window only
*=======================================================================
di ""
di as text "{hline 78}"
di as text "2. Known-truth DGP: cointegrated only over observations 51-150"
di as text "{hline 78}"

clear
set seed 20260907
set obs 200
gen int t = _n
tsset t

local T1 = 50
local T2 = 150

gen double ux = rnormal()
gen double u  = rnormal()
gen double x  = sum(ux)

* rho = 0.3 inside the cointegrated stretch, 1 (a unit root) outside
gen double rho = 1
replace rho = 0.3 if t > `T1' & t <= `T2'

* build the AR error recursively: a row-by-row replace reads the
* already-updated previous row through L.
gen double e = u if t == 1
replace e = rho*L.e + u if t > 1

gen double y = x + e
label variable y "y = x + e, e stationary only over 51-150"

di ""
di as text "True cointegrated window: 51-150 (fractions 0.25 to 0.75)."
di as text "The relation neither begins at the start of the sample nor runs to"
di as text "its end, so by proposition A.1 only GIEG should have power here."
di ""
cointpart y x, case(c) graph name(cbp_window)

di ""
di as text "GIEG window found: " as result r(gieg_t1) as text "-" as result r(gieg_t2) ///
   as text "   (truth 51-150)"
* overlap with the truth, as intersection over union: containment is not
* the right criterion, and the paper's own figure 1 shows a minimizing
* window that merely sits "almost squarely" within the cointegrated stretch
local lo = max(r(gieg_t1), `T1'+1)
local hi = min(r(gieg_t2), `T2')
local inter = max(0, `hi' - `lo' + 1)
local lo2 = min(r(gieg_t1), `T1'+1)
local hi2 = max(r(gieg_t2), `T2')
local union = `hi2' - `lo2' + 1
di as text "-> overlap with the true window: " as result %4.2f `inter'/`union' ///
   as text "  (intersection over union)"
di as text "   The minimizing window need not be contained in the truth, and"
di as text "   usually is not: what matters is that it locates the stationary"
di as text "   stretch rather than some unrelated part of the record."

*=======================================================================
* 3. Directional consistency (proposition A.1)
*=======================================================================
di ""
di as text "{hline 78}"
di as text "3. Directional consistency: choosing the wrong direction kills power"
di as text "{hline 78}"
di ""
di as text "Under a FORWARD break (I(0) then I(1)) FIEG should reject often and"
di as text "BIEG almost never. Under a REVERSE break the roles swap. Against a"
di as text "window in the middle of the sample neither one-sided statistic is"
di as text "consistent, and GIEG should be the best of the three."
di as text "60 replications at T = 120, 5% nominal."
di ""

capture program drop _cbpsim
program define _cbpsim, rclass
    * direction: 0 = forward (I(0) then I(1)), 1 = reverse, 2 = middle window
    args T tau rho direction
    clear
    qui set obs `T'
    qui gen int t = _n
    qui tsset t
    qui gen double ux = rnormal()
    qui gen double u  = rnormal()
    qui gen double x  = sum(ux)
    local tb = floor(`tau'*`T')
    qui gen double rho = 1
    if (`direction' == 0) qui replace rho = `rho' if t <= `tb'
    if (`direction' == 1) qui replace rho = `rho' if t >  `tb'
    if (`direction' == 2) qui replace rho = `rho' if t > floor(0.25*`T') & t <= floor(0.75*`T')
    qui gen double e = u if t == 1
    qui replace e = rho*L.e + u if t > 1
    qui gen double y = x + e
    qui cointpart y x, case(c) notable
    return scalar fieg = r(fieg)
    return scalar bieg = r(bieg)
    return scalar gieg = r(gieg)
    tempname C
    matrix `C' = r(cv)
    return scalar cf = `C'[1,2]
    return scalar cb = `C'[2,2]
    return scalar cg = `C'[3,2]
end

local NR  = 60
local TT  = 120
foreach d in 0 1 2 {
    local nf 0
    local nb 0
    local ng 0
    forvalues i = 1/`NR' {
        qui _cbpsim `TT' 0.5 0.3 `d'
        if (r(fieg) <= r(cf)) local ++nf
        if (r(bieg) <= r(cb)) local ++nb
        if (r(gieg) <= r(cg)) local ++ng
    }
    local lab "forward break"
    if (`d' == 1) local lab "reverse break"
    if (`d' == 2) local lab "middle window"
    di as text "   " %-16s "`lab'" ///
       "  FIEG " as result %5.2f `nf'/`NR' ///
       as text "  BIEG " as result %5.2f `nb'/`NR' ///
       as text "  GIEG " as result %5.2f `ng'/`NR'
}
di as text ""
di as text "-> Read the first two rows across. FIEG rejects for the forward break"
di as text "   and almost never for the reverse; BIEG does the reverse. That is"
di as text "   proposition A.1 showing up in a finite sample: the wrong direction"
di as text "   does not merely lose power, it has none to lose."
di as text ""
di as text "   Now read what the table does NOT say. In each one-sided statistic's"
di as text "   own favourable direction, GIEG is the WEAKER test, because it pays a"
di as text "   much larger critical-value penalty for searching both endpoints."
di as text "   Consistency is an asymptotic property; it is not finite-sample power."
di as text "   GIEG wins only in the third row, where no one-sided search set"
di as text "   contains a clean window."
di as text ""
di as text "   And even in that third row FIEG and BIEG retain some power, because"
di as text "   at T = 120 their windows still overlap much of the stationary"
di as text "   stretch. Inconsistency bites as T grows, not at every sample size."
di as text ""
di as text "   Practical reading: use GIEG when the direction is genuinely in"
di as text "   doubt, and a one-sided statistic when it is not. Choosing GIEG to"
di as text "   be safe is not free."

*=======================================================================
* 4. Empirical size under the null
*=======================================================================
di ""
di as text "{hline 78}"
di as text "4. Empirical size: independent driftless random walks"
di as text "{hline 78}"
di ""
di as text "100 replications at T = 120, nominal 5%. Entries should sit near 0.05;"
di as text "the paper reports the tabulation as mildly conservative at this size."
di ""

local NR 100
local nf 0
local nb 0
local ng 0
forvalues i = 1/`NR' {
    clear
    qui set obs 120
    qui gen int t = _n
    qui tsset t
    qui gen double x = sum(rnormal())
    qui gen double y = sum(rnormal())
    qui cointpart y x, case(c) notable
    tempname C
    matrix `C' = r(cv)
    if (r(fieg) <= `C'[1,2]) local ++nf
    if (r(bieg) <= `C'[2,2]) local ++nb
    if (r(gieg) <= `C'[3,2]) local ++ng
}
di as text "   rejection at 5%:  FIEG " as result %5.3f `nf'/`NR' ///
   as text "   BIEG " as result %5.3f `nb'/`NR' ///
   as text "   GIEG " as result %5.3f `ng'/`NR'
di as text "   (Monte Carlo standard error at 100 reps is about 0.022)"

*=======================================================================
* 5. Every option exercised
*=======================================================================
di ""
di as text "{hline 78}"
di as text "5. Option coverage"
di as text "{hline 78}"

use cointpart_sealevel, clear
tsset year

di ""
di as text "all three deterministic cases:"
tempname C
foreach cs in n c ct {
    qui cointpart temperature sea_level, case(`cs')
    local g = r(gieg)
    matrix `C' = r(cv)
    di as text "   case(`cs')   GIEG = " as result %8.3f `g' ///
       as text "   5% cv = " as result %8.3f `C'[3,2]
}
di as text "-> Case n returns the statistic but no critical value: it is not tabulated."

di ""
di as text "lag criterion and caps:"
foreach cr in bic sic aic {
    qui cointpart temperature sea_level, case(ct) criterion(`cr')
    di as text "   criterion(`cr')  GIEG = " as result %8.3f r(gieg)
}
qui cointpart temperature sea_level, case(ct) maxlag(0)
di as text "   maxlag(0)        GIEG = " as result %8.3f r(gieg) as text "  (no augmentation)"
qui cointpart temperature sea_level, case(ct) dofratio(0)
di as text "   dofratio(0)      GIEG = " as result %8.3f r(gieg) as text "  (paper's rule relaxed)"

di ""
di as text "more than one regressor:"
clear
set seed 4242
set obs 160
gen int t = _n
tsset t
gen double x1 = sum(rnormal())
gen double x2 = sum(rnormal())
gen double x3 = sum(rnormal())
gen double y  = sum(rnormal())
foreach k in 1 2 3 {
    local xs ""
    forvalues j = 1/`k' {
        local xs "`xs' x`j'"
    }
    qui cointpart y `xs', case(ct)
    local g = r(gieg)
    matrix `C' = r(cv)
    di as text "   N = `k'   GIEG = " as result %8.3f `g' ///
       as text "   5% cv = " as result %8.3f `C'[3,2]
}

di ""
di as text "sequence variables, the graph, and the stored window matrix:"
use cointpart_sealevel, clear
tsset year
capture drop cbp_*
cointpart temperature sea_level, case(ct) prefix(cbp) graph name(cbp_app) notable
qui summarize cbp_bieg, meanonly
di as text "   min of cbp_bieg = " as result %9.5f r(min) as text "   (equals GIEG)"
qui summarize cbp_bieg if year == 2019, meanonly
di as text "   last cbp_bieg   = " as result %9.5f r(mean) as text "   (equals BIEG)"
qui cointpart temperature sea_level, case(ct) notable
di as text "   GIEG            = " as result %9.5f r(gieg)
di as text "   BIEG            = " as result %9.5f r(bieg)
tempname W
matrix `W' = r(windows)
di as text "   r(windows) is " as result rowsof(`W') as text " x " ///
   as result colsof(`W') as text ": start, end, length, statistic, lag"

di ""
di as text "simulated p-values (reps is small here so the run stays short;"
di as text "use 199 or more for anything reported):"
di ""
cointpart temperature sea_level, case(ct) reps(49) seed(20260907)

*=======================================================================
* 6. Validity guards
*=======================================================================
di ""
di as text "{hline 78}"
di as text "6. Validity guards -- the command refuses rather than guess"
di as text "{hline 78}"
di ""

use cointpart_sealevel, clear
tsset year
tempname C

qui cointpart temperature sea_level, case(ct) trim(0.25)
matrix `C' = r(cv)
di as text "   trim(0.25): 5% cv = " as result `C'[3,2] ///
   as text "  (suppressed; the tabulation is indexed by r0 = 0.15)"

preserve
keep if year >= 1950
tsset year
qui cointpart temperature sea_level, case(ct)
local nn = r(N)
matrix `C' = r(cv)
di as text "   T = " as result `nn' as text ": 5% cv = " as result `C'[3,2] ///
   as text "  (suppressed; surfaces are fitted for T >= 100)"
restore

foreach bad in "case(xx)" "trim(0.8)" "criterion(zzz)" "trim(0)" {
    capture cointpart temperature sea_level, `bad'
    di as text "   `bad' -> rc = " as result _rc
}

preserve
drop if year == 1950
capture tsset year
capture cointpart temperature sea_level, case(ct)
di as text "   gap in the sample -> rc = " as result _rc as text " (needs a gap-free span)"
restore

capture drop cbp_*
qui cointpart temperature sea_level, case(ct) prefix(cbp) notable
capture cointpart temperature sea_level, case(ct) prefix(cbp)
di as text "   prefix() colliding with existing variables -> rc = " as result _rc

di ""
di as text "{hline 78}"
di as text "Done. See  help cointpart  and  help cointpart methods."
di as text "{hline 78}"
