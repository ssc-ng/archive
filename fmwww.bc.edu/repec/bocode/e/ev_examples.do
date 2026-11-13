* ev_examples.do
* Examples for the -ev- command (EViews-style expressions in Stata estimation commands).
* Authors: Matthew Yeung and Aaron Tao
*          School of Open Learning, Hong Kong Metropolitan University
*          myeung@hkmu.edu.hk
* Run with: do ev_examples.do
* The data below are simulated for illustration only.

clear all
set more off
set seed 20261105

*----------------------------------------------------------------------
* 1. Hypothetical panel: 10 companies, 1935-1954
*----------------------------------------------------------------------
set obs 10
gen company = _n
gen u = rnormal()*2
expand 20
bysort company: gen year = 1934 + _n
gen mvalue = 500*exp(0.4*rnormal() + 0.1*u + 0.02*(year-1935))
gen kstock = 300*exp(0.3*rnormal() + 0.1*u + 0.03*(year-1935))
gen invest = -50 + 12*ln(mvalue) + 0.02*kstock + 5*u + 5*rnormal()
gen patents = rpoisson(3 + 0.002*mvalue)
xtset company year
describe
summarize

*----------------------------------------------------------------------
* 2. Transformations
*----------------------------------------------------------------------
ev: regress invest ln(mvalue) ln(kstock)
ev: regress invest mvalue kstock^2
ev: regress invest mvalue/kstock c

* Subtraction: a hyphen is always a difference (never a variable range)
ev: regress invest mvalue-kstock
ev: regress invest (mvalue-kstock)

*----------------------------------------------------------------------
* 3. Lags and leads
*----------------------------------------------------------------------
ev: regress invest mvalue(-1) kstock
ev: regress invest mvalue(-1 to -3) kstock
capture noisily ev: regress invest mvalue(1) kstock

*----------------------------------------------------------------------
* 4. Differences and growth rates
*----------------------------------------------------------------------
ev: regress invest d(mvalue) dlog(kstock)
ev: regress invest d(ln(mvalue)) kstock
capture noisily ev: regress invest d(mvalue,2) kstock
ev: regress invest d(mvalue,1,2)
ev: regress invest @pch(mvalue) kstock

* Annual data: the number of periods per year must be given with freq()
ev, freq(1): regress invest @pchy(mvalue)

*----------------------------------------------------------------------
* 5. Moving average and trend
*----------------------------------------------------------------------
ev: regress invest @movav(mvalue,3) kstock
ev: regress invest @trend ln(mvalue)
capture noisily ev: regress invest @trend(1935) ln(mvalue)

*----------------------------------------------------------------------
* 6. Other estimators
*----------------------------------------------------------------------
ev: xtreg invest ln(mvalue) d(kstock), fe vce(cluster company)
ev: areg invest ln(mvalue) kstock^2, absorb(company)
ev: regress invest ln(mvalue) i.company
ev: poisson patents ln(mvalue) kstock
ev, keep: mixed invest ln(mvalue) || company:
capture drop _ev_*

*----------------------------------------------------------------------
* 7. Weights, if and estimator options
*----------------------------------------------------------------------
ev: regress invest ln(mvalue) d(kstock) [aw = kstock] if year > 1940, vce(robust)

*----------------------------------------------------------------------
* 8. Declaring the time structure for a single command
*----------------------------------------------------------------------
xtset, clear
ev, panel(company) time(year): regress invest d(mvalue) ln(kstock)
* the data are undeclared again here; set the panel back
xtset company year

*----------------------------------------------------------------------
* 9. Keeping the generated variables for prediction
*----------------------------------------------------------------------
ev, keep: regress invest ln(mvalue) d(kstock)
predict double yhat
summarize yhat
drop yhat
drop _ev_*

*----------------------------------------------------------------------
* 10. Quarterly time series: frequency is inferred from the %tq format
*----------------------------------------------------------------------
preserve
clear
set obs 80
gen q = tq(2000q1) + _n - 1
format q %tq
tsset q
gen x = 100*exp(0.01*_n + 0.05*rnormal())
gen y = 2 + 0.02*x + rnormal()
ev: regress y @pcha(x) @pchy(x)
capture noisily ev: newey y @pch(x), lag(2)
ev: regress y @trend ln(x)
restore

quietly {
    noisily display as txt "ev_examples.do finished." _n
    noisily display as txt "If you use -ev- in your work, please cite:"
    noisily display as txt "Yeung, M., and Tao, A. Z. 2026. ev: Stata module for EViews-style expressions in estimation commands. Statistical Software Components, Boston College Department of Economics." _n
}
