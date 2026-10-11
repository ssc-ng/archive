*! mispauto_example.do   1.0.1  07oct2026
* Self-test and demonstration for the mispauto package
* Dr Merwan Roudane -- merwanroudane920@gmail.com -- github.com/merwanroudane
*
* Nine known-truth designs.  Each block prints the TRUE data-generating
* process and the expected verdict before running the command, so the package
* can be refereed from the log alone.
*
* Designs 1-6 exercise the branches and should give the expected answer.
* Designs 7-9 are the DOCUMENTED FAILURE MODES of this literature.  They are
* included deliberately: a package that implements Thursby (1981) faithfully
* must reproduce the cases Knottnerus (1985), Thursby & Schmidt (1977) and
* Porter & Kashyap (1984) showed it gets wrong.  Each prints the reference
* that predicts the failure and the remedy the literature offers.
*
*   1  NP        clean regression, independent errors
*   2  AR(1)     first-order autoregressive errors
*   3  NAR       AR(2) errors
*   4  MS        omitted variable CORRELATED with the included regressor
*   5  MS        wrong functional form
*   6  EV/S      regressor measured with error, instruments available
*   7  FAILURE   pure seasonal AR(4) errors      -> Knottnerus sec.II, fn.1
*   8  FAILURE   omitted variable ORTHOGONAL to x -> Thursby & Schmidt sec.2
*   9  FAILURE   persistent regressor AND errors  -> Porter & Kashyap, Tables 1-2
*
* Run with:   do mispauto_example.do

clear all
set more off

capture which mispauto
if _rc do mispauto.ado

set seed 20261007

*------------------------------------------------------------------ helper ---
capture program drop mpa_mkdata
program define mpa_mkdata
	syntax , n(integer) [ rho1(real 0) rho2(real 0) rhos(real 0) ///
		seas(integer 4) rhox(real 0) corrx(real 0) ]
	clear
	qui set obs `=`n'+60'
	qui gen int t = _n
	qui tsset t
	qui gen double x1 = 0
	qui replace x1 = `rhox'*L.x1 + rnormal() if t > 1
	* x2 is correlated with x1 when corrx>0, independent of it when corrx=0
	qui gen double x2 = `corrx'*x1 + rnormal()
	qui gen double v = rnormal()
	qui gen double u = v
	if `rho1' != 0 | `rho2' != 0 {
		qui replace u = `rho1'*L.u + v if t > 1
		qui replace u = `rho1'*L.u + `rho2'*L2.u + v if t > 2
	}
	if `rhos' != 0 {
		qui replace u = `rhos'*L`seas'.u + v if t > `seas'
	}
	qui drop if t <= 60
	qui replace t = t - 60
	qui tsset t
end

*=============================================================== 1  NP  =======
di _n(2) "{hline 78}"
di "  DESIGN 1 -- TRUTH: y = 1 + x1 + u, u iid N(0,1).      EXPECT: NP"
di "{hline 78}"
mpa_mkdata, n(200)
gen double y = 1 + x1 + u
mispauto all y x1

*=============================================================== 2  AR(1) =====
di _n(2) "{hline 78}"
di "  DESIGN 2 -- TRUTH: y = 1 + x1 + u, u(t) = 0.8 u(t-1) + v."
di "  x1 is serially independent, so RESET is not contaminated (cf. design 9)."
di "                                                        EXPECT: AR(1)"
di "{hline 78}"
mpa_mkdata, n(200) rho1(0.8)
gen double y = 1 + x1 + u
mispauto all y x1

*=============================================================== 3  AR(2) =====
di _n(2) "{hline 78}"
di "  DESIGN 3 -- TRUTH: u(t) = 0.5 u(t-1) + 0.4 u(t-2) + v. EXPECT: NAR"
di "{hline 78}"
mpa_mkdata, n(200) rho1(0.5) rho2(0.4)
gen double y = 1 + x1 + u
mispauto all y x1

*====================================================== 4  OMITTED VARIABLE ===
di _n(2) "{hline 78}"
di "  DESIGN 4 -- TRUTH: y = 1 + x1 + 2*x2 + v with x2 OMITTED, where x2 is"
di "  RELATED TO x1 (x2 = 0.8*x1^2 + w)."
di "  Thursby & Schmidt (1977) sec.2: RESET has power only when Z'Mx xi is"
di "  non-zero, i.e. when the omitted part is correlated with the test"
di "  variables.  Here it is, through x1^2.  This is the case Thursby (1981,"
di "  p.122) describes as giving excellent results in his models 15 and 16,"
di "  'due to the fact that the included and excluded terms are related'."
di "  Note that an omitted variable entering LINEARLY as a*x1 + w would be"
di "  absorbed entirely by OLS and would leave nothing to detect."
di "                                                        EXPECT: MS"
di "{hline 78}"
mpa_mkdata, n(200)
gen double x2b = 0.8*x1*x1 + rnormal()
gen double y = 1 + x1 + 2*x2b + v
mispauto all y x1

*==================================================== 5  FUNCTIONAL FORM ======
di _n(2) "{hline 78}"
di "  DESIGN 5 -- TRUTH: y = 1 + 2*x1 + 1.5*x1^2 + v, fitted LINEAR."
di "                                                        EXPECT: MS"
di "{hline 78}"
mpa_mkdata, n(200)
gen double y = 1 + 2*x1 + 1.5*x1*x1 + v
mispauto all y x1

*=============================================================== 6  EV/S ======
di _n(2) "{hline 78}"
di "  DESIGN 6 -- TRUTH: y = 1 + xstar + e, but we observe x = xstar + noise."
di "  Two valid instruments available.                      EXPECT: EV/S"
di "{hline 78}"
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

*=================================== 7  DOCUMENTED FAILURE: SEASONAL ==========
di _n(2) "{hline 78}"
di "  DESIGN 7 -- DOCUMENTED FAILURE.  TRUTH: u(t) = 0.8 u(t-4) + v, so the"
di "  first-order autocorrelation is ZERO in population."
di "  Knottnerus (1985) sec.II and fn.1 prove Thursby's strategy must return NP"
di "  here however strong the seasonal dependence."
di "    EXPECT: thursby -> NP (WRONG, and unavoidable);"
di "            knottnerus -> raises blind-spot warning 1;"
di "            godfrey with q>=4 -> detects it."
di "{hline 78}"
mpa_mkdata, n(200) rhos(0.8) seas(4)
gen double y = 1 + x1 + u
mispauto thursby y x1
mispauto knottnerus y x1, lags(12)
mispauto godfrey y x1, q(4) truncate(4)

*================================ 8  DOCUMENTED FAILURE: ORTHOGONAL OMIT =====
di _n(2) "{hline 78}"
di "  DESIGN 8 -- DOCUMENTED FAILURE.  TRUTH: y = 1 + x1 + 2*x2 + v with x2"
di "  OMITTED and ORTHOGONAL to x1, and x2 itself serially correlated."
di "  Thursby & Schmidt (1977) sec.2: E(theta-hat) = (Z'MxZ)^-1 Z'Mx xi, so an"
di "  omitted regressor orthogonal to everything in the model is INVISIBLE to"
di "  RESET.  The omitted series instead looks like an autocorrelated error."
di "  Thursby (1981, p.122) reports exactly this for his own model 14."
di "    EXPECT: AR(1) or NAR, not MS.  This is the procedure behaving as"
di "            its authors documented, not a defect in the code."
di "{hline 78}"
clear
set obs 260
gen int t = _n
tsset t
gen double x1 = rnormal()
gen double x2 = 0
replace x2 = 0.8*L.x2 + rnormal() if t > 1
gen double v = rnormal()
drop if t <= 60
qui replace t = t - 60
tsset t
gen double y = 1 + x1 + 2*x2 + v
mispauto all y x1

*============================= 9  DOCUMENTED FAILURE: PORTER-KASHYAP =========
di _n(2) "{hline 78}"
di "  DESIGN 9 -- DOCUMENTED FAILURE.  TRUTH: y = 1 + x1 + u, CORRECTLY"
di "  SPECIFIED, with x1 AR(0.95) and u AR(0.95)."
di "  Porter & Kashyap (1984) Tables 1-2: at a nominal 5% level the plain"
di "  Thursby-Schmidt RESET rejects this correct model in 77% of samples at"
di "  T=200.  Their Table 3 shows that estimating the autocorrelation in both"
di "  the maintained and the augmented model restores correct size."
di "    EXPECT: plain RESET rejects far more than 5% of the time;"
di "            the same test with resetmod holds its size."
di "  A single draw cannot show a rejection RATE, so this design runs a short"
di "  Monte Carlo rather than one regression.  100 replications."
di "{hline 78}"
local R = 100
local cpl = 0
local cpk = 0
quietly forvalues r = 1/`R' {
	set seed `=20000+`r''
	mpa_mkdata, n(200) rho1(0.95) rhox(0.95)
	gen double y = 1 + x1 + u
	mispauto thursby y x1, notable dwp(normal)
	if r(p_reset) < 0.05 local cpl = `cpl' + 1
	mispauto thursby y x1, notable dwp(normal) resetmod
	if r(p_reset) < 0.05 local cpk = `cpk' + 1
}
di ""
di "   Rejections of a CORRECTLY SPECIFIED model, nominal level 5%, T=200:"
di "      plain RESET as Thursby uses it ....... " %5.1f 100*`cpl'/`R' "%"
di "      the same test with resetmod .......... " %5.1f 100*`cpk'/`R' "%"
di ""
di "   Porter & Kashyap report 77% for the plain test at these parameters and"
di "   correct size for their modification (their Tables 2 and 3)."
di ""
di "   One illustrative draw, both ways:"
set seed 20261007
mpa_mkdata, n(200) rho1(0.95) rhox(0.95)
gen double y = 1 + x1 + u
di _n "  --- (a) as published: plain RESET ---"
mispauto thursby y x1
di _n "  --- (b) with the Porter-Kashyap correction ---"
mispauto thursby y x1, resetmod

di _n(2) "{hline 78}"
di "  END OF SELF-TEST"
di "  Designs 1-6 should match the EXPECT line.  Designs 7-9 should reproduce"
di "  the published failure and, where one exists, the published remedy."
di "{hline 78}"
