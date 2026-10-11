*! mispauto_demo.do   1.0.1  07oct2026
* A guided demonstration of mispauto for a live audience
* Dr Merwan Roudane -- merwanroudane920@gmail.com -- github.com/merwanroudane
*
* HOW TO RUN THIS IN FRONT OF AN AUDIENCE
* ---------------------------------------
*   do mispauto_demo.do
*
* The file pauses between sections so you can talk.  Press any key in the
* Command window to continue.  To run it straight through with no pauses,
* comment out the "capture set pause on" line just below.
*
* Nothing here needs an internet connection and nothing needs outside data.
* Sections 2 to 5 construct series whose TRUTH IS KNOWN, so the audience can
* check the command against the right answer rather than take it on trust.
*
* SIX SECTIONS, about fifteen minutes:
*   1  The problem, on a real series
*   2  Known truth: AR(1) errors            -- the command gets it right
*   3  Known truth: seasonal errors         -- the famous blind spot, with a plot
*   4  Known truth: misspecification        -- and a live Monte Carlo
*   5  Should I instrument?
*   6  The everyday workflow

clear all
set more off
capture set pause on
set linesize 100

capture which mispauto
if _rc {
	di as err "mispauto is not installed.  Install it with:"
	di as err "    ssc install mispauto"
	di as err "or, from a local copy of the package folder:"
	di as err `"    net install mispauto, from("<path to the folder>") replace"'
	exit 111
}

set seed 7

*==============================================================================
di _n(3) "{hline 78}"
di "  mispauto -- what does a significant Durbin-Watson statistic actually mean?"
di "{hline 78}"
di ""
di "  A significant DW is consistent with FOUR different states of the world:"
di ""
di "     NP     no problem with the regression"
di "     AR(1)  first-order autoregressive disturbances"
di "     NAR    some other non-white-noise error process"
di "     MS     misspecification: omitted variable or wrong functional form"
di ""
di "  The responses are INCOMPATIBLE.  Correcting for AR(1) when the real"
di "  problem is a missing regressor leaves the estimator inconsistent."
di "  Respecifying when the real problem is AR(1) throws away efficiency."
di ""
di "  Four papers built strategies to tell them apart.  mispauto runs all four."
di "{hline 78}"
capture pause

*==============================================================================
* SECTION 1 -- the problem on a real series
*==============================================================================
di _n(3) "{hline 78}"
di "  SECTION 1 -- A REAL REGRESSION: US real GNP on a time trend"
di "  Quarterly data shipped with Stata.  A regression every student has run."
di "{hline 78}"

sysuse gnp96, clear
tsset date
gen double lgnp = ln(gnp96)
gen double trend = _n

regress lgnp trend
estat dwatson

di _n "  The Durbin-Watson statistic is tiny.  Something is wrong."
di "  But WHAT?  Stata will not tell you.  That is the whole question."
capture pause

di _n "  Ask all four strategies at once:"
capture pause
mispauto all lgnp trend
capture pause

*==============================================================================
* SECTION 2 -- known truth: AR(1)
*==============================================================================
di _n(3) "{hline 78}"
di "  SECTION 2 -- KNOWN TRUTH.  We build the data ourselves:"
di ""
di "      y(t) = 1 + x(t) + u(t),     u(t) = 0.8*u(t-1) + v(t)"
di ""
di "  The regression function is CORRECT.  The errors are AR(1)."
di "  The right answer is AR(1).  Let us see whether the command finds it."
di "{hline 78}"
capture pause

clear
set obs 260
gen int t = _n
tsset t
gen double x = rnormal()
gen double v = rnormal()
gen double u = v
replace u = 0.8*L.u + v if t > 1
drop if t <= 60
qui replace t = t - 60
tsset t
gen double y = 1 + x + u

mispauto thursby y x
capture pause
mispauto godfrey y x
capture pause

di _n "  Both strategies say AR(1).  The truth was AR(1)."
di "  Note the 'Response:' line -- it tells you what to do next, not just"
di "  what is wrong."
capture pause

*==============================================================================
* SECTION 3 -- known truth: the seasonal blind spot
*==============================================================================
di _n(3) "{hline 78}"
di "  SECTION 3 -- THE MOST IMPORTANT SECTION"
di ""
di "  Now the errors are PURELY SEASONAL:   u(t) = 0.8*u(t-4) + v(t)"
di ""
di "  Quarterly data.  The errors are strongly dependent.  But the FIRST-order"
di "  autocorrelation is ZERO in population, because the dependence sits at"
di "  lag 4, not lag 1."
di ""
di "  Knottnerus (1985) PROVED that Thursby's procedure must return 'no"
di "  problem' here, no matter how strong the seasonality.  Watch."
di "{hline 78}"
capture pause

clear
set obs 260
gen int i = _n
gen qd = tq(1960q1) + _n - 1
format qd %tq
tsset qd
gen double x = rnormal()
gen double v = rnormal()
gen double u = v
replace u = 0.8*L4.u + v if i > 4
drop if i <= 60
tsset qd
gen double y = 1 + x + u

di _n "  (a) Thursby's strategy:"
capture pause
mispauto thursby y x
capture pause

di _n(2) "  It says NP -- no problem.  It is WRONG, and it cannot do better."
di "  This is not a bug in the software.  It is a theorem."
capture pause

di _n "  (b) Now the Knottnerus diagnostics, which exist to catch exactly this:"
capture pause
mispauto knottnerus y x, lags(16) graph
capture pause

di _n(2) "  Look at the plot.  The red bars are the seasonal lags: 4, 8, 12, 16."
di "  They are enormous.  The lag-1 bar is small -- which is precisely why"
di "  Durbin-Watson and Durbin's S-test see nothing."
di ""
di "  And read the warning block: it names the blind spot and tells you the"
di "  remedy."
capture pause

di _n "  (c) Godfrey's (1987) strategy, which was built to fix this:"
capture pause
mispauto godfrey y x
capture pause

di _n(2) "  Godfrey finds it.  Note that q defaulted to 3 automatically,"
di "  because the data are tsset as quarterly.  The command read the"
di "  frequency and chose the right alternative hypothesis by itself."
capture pause

*==============================================================================
* SECTION 4 -- known truth: misspecification, and a live Monte Carlo
*==============================================================================
di _n(3) "{hline 78}"
di "  SECTION 4 -- MISSPECIFICATION"
di ""
di "      TRUTH:  y = 1 + 2*x + 1.5*x^2 + v        and we fit it LINEAR"
di ""
di "  The right answer is MS."
di "{hline 78}"
capture pause

clear
set obs 260
gen int t = _n
tsset t
gen double x = rnormal()
gen double v = rnormal()
drop if t <= 60
qui replace t = t - 60
tsset t
gen double y = 1 + 2*x + 1.5*x*x + v

mispauto all y x
capture pause

di _n(3) "{hline 78}"
di "  SECTION 4b -- A WARNING WORTH TEACHING"
di ""
di "  Thursby's RESET is NOT robust to autocorrelation, although he believed"
di "  it was.  Porter and Kashyap (1984) showed that when the regressor AND"
di "  the error are both persistent, RESET rejects a PERFECTLY CORRECT model"
di "  most of the time."
di ""
di "  Let us measure it live.  50 replications, correct model throughout,"
di "  x and u both AR(0.95), nominal level 5%."
di "{hline 78}"
capture pause

local R = 50
local c1 = 0
local c2 = 0
quietly forvalues r = 1/`R' {
	set seed `=31000 + `r''
	clear
	set obs 260
	gen int t = _n
	tsset t
	gen double x = 0
	replace x = 0.95*L.x + rnormal() if t > 1
	gen double v = rnormal()
	gen double u = v
	replace u = 0.95*L.u + v if t > 1
	drop if t <= 60
	replace t = t - 60
	tsset t
	gen double y = 1 + x + u
	mispauto thursby y x, notable dwp(normal)
	if r(p_reset) < 0.05 local c1 = `c1' + 1
	mispauto thursby y x, notable dwp(normal) resetmod
	if r(p_reset) < 0.05 local c2 = `c2' + 1
}
di ""
di "   How often is a CORRECT model declared misspecified?   (we want 5%)"
di ""
di "      RESET as Thursby uses it .................. " %5.1f 100*`c1'/`R' "%"
di "      the same test, option -resetmod- .......... " %5.1f 100*`c2'/`R' "%"
di ""
di "   Porter and Kashyap report 77% and correct size respectively."
di "   -resetmod- applies their own correction: estimate the autocorrelation"
di "   in BOTH the maintained and the augmented model, then test."
di ""
di "   LESSON FOR THE AUDIENCE: when your regressors are persistent, a"
di "   significant RESET on its own is weak evidence of misspecification."
capture pause

*==============================================================================
* SECTION 5 -- should I instrument?
*==============================================================================
di _n(3) "{hline 78}"
di "  SECTION 5 -- A DIFFERENT QUESTION: SHOULD I INSTRUMENT?"
di ""
di "  A significant Hausman statistic is usually read as 'endogeneity, so use"
di "  IV'.  Godfrey and Hutton (1994) showed that does not follow: Hausman's"
di "  test reacts to many kinds of misspecification, and for most of them IV"
di "  will not help."
di ""
di "  Their fix is to ask the questions in order:"
di "     stage 1 -- is errors-in-variables the ONLY problem?   (Sargan J)"
di "     stage 2 -- only if so, is there any endogeneity at all? (Hausman)"
di ""
di "  TRUTH here: x is measured with error, two valid instruments exist."
di "{hline 78}"
capture pause

clear
set obs 260
gen int t = _n
tsset t
gen double z1 = rnormal()
gen double z2 = rnormal()
gen double xstar = 0.9*z1 + 0.9*z2 + rnormal()
gen double e = rnormal()
gen double y = 1 + xstar + e
gen double x = xstar + 1.2*rnormal()
drop if t <= 60
qui replace t = t - 60
tsset t

mispauto ghutton y (x = z1 z2)
capture pause

di _n(2) "  Stage 1 passes, stage 2 rejects, so the verdict is EV/S and the IV"
di "  estimates are the ones to present.  Had stage 1 REJECTED, the command"
di "  would refuse to even report stage 2 -- because that is the case where"
di "  presenting IV results would be the mistake."
capture pause

*==============================================================================
* SECTION 6 -- the everyday workflow
*==============================================================================
di _n(3) "{hline 78}"
di "  SECTION 6 -- HOW YOU WILL ACTUALLY USE IT"
di "{hline 78}"
di ""
di "  Fit the model first, then just ask.  No need to retype the variables."
capture pause

sysuse gnp96, clear
tsset date
gen double lgnp = ln(gnp96)
gen double trend = _n
gen double trend2 = trend*trend

regress lgnp trend trend2
mispauto godfrey
capture pause

di _n "  Your estimation results are untouched afterwards:"
regress
capture pause

di _n(3) "{hline 78}"
di "  WHERE TO READ MORE"
di "{hline 78}"
di ""
di "     help mispauto                  overview, options, how to read output"
di "     help mispauto methods          every step mapped to its equation"
di "     help mispauto thursby          and godfrey, ghutton, knottnerus"
di "     help mispauto postestimation   using it after regress"
di ""
di "  Everything is returned in r() -- see the Stored results section of each"
di "  page -- so verdicts can be collected into a table across specifications."
di ""
di "  The nine-design self-test, including the documented failure modes:"
di "     do mispauto_example.do"
di ""
di "{hline 78}"
di "  END OF DEMONSTRATION"
di "{hline 78}"
capture set pause off
