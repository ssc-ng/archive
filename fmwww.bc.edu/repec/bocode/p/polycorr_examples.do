* polycorr_examples.do -- reproduces every example in the Stata Journal article
* "polycorr: Polychoric correlations with joint inference, normality diagnostics,
*  and polychoric principal-component indices"  (Yusuf Toyin Yusuf)
version 14
clear all
set more off
capture log close
log using polycorr_examples.log, replace text

* ------------------------------------------------------------ Section 4.1 auto
sysuse auto, clear
polycorr rep78 foreign
polycorr rep78 foreign mpg headroom, fit matrix
* joint inference: equality of two polyserial correlations
polycorr foreign mpg trunk, continuous(trunk)
test [foreign]mpg = [foreign]trunk
nlcom (diff: atanh(_b[foreign:mpg]) - atanh(_b[foreign:trunk]))
* comparison with Kolenikov's polychoric (if installed)
capture which polychoric
if !_rc {
	polychoric rep78 foreign
	return list
}

* ------------------------------------------------------------ Section 4.2 survey
webuse nhanes2f, clear
svyset psuid [pweight = finalwgt], strata(stratid)
polycorr health heartatk diabetes highbp, svy fit
polycorr health heartatk diabetes highbp
* replicate-weight alternative
svy jackknife, nodots: polycorr health heartatk diabetes highbp, novce

* ------------------------------------------------------------ Section 4.3 simulated asset survey
* 6,000 households in 300 enumeration areas (EAs) within 12 strata.
clear
set seed 20261021
set obs 300
gen int ea     = _n
gen int stratum = ceil(_n/25)
gen double u_ea = rnormal(0, .6)
gen byte urban = runiform() < .35
expand 20
bysort ea: gen int hh = _n
gen double wealth = u_ea + .8*urban + rnormal()
gen double wt = cond(urban, 0.8, 1.6) * (1 + .2*runiform())
gen byte electricity = wealth + rnormal(0, .7) > 0.3
gen byte radio       = wealth + rnormal(0, 1.2) > -0.6
gen byte tv          = wealth + rnormal(0, .8) > 0.6
gen byte fridge      = wealth + rnormal(0, .8) > 1.2
gen byte mobile      = wealth + rnormal(0, 1.0) > -1.0
gen byte bicycle     = wealth + rnormal(0, 2.5) > 0
gen byte floor  = 1 + (wealth + rnormal(0, .9) > -.2) + (wealth + rnormal(0, .9) > 1.0)
gen byte water  = 1 + (wealth + rnormal(0, 1) > -1) + (wealth + rnormal(0, 1) > 0) ///
                    + (wealth + rnormal(0, 1) > 1)
gen byte toilet = 1 + (wealth + rnormal(0, .9) > -.4) + (wealth + rnormal(0, .9) > .9)
gen double lnexp = 10 + .35*wealth + rnormal(0, .4)
label define fl 1 "earth" 2 "cement" 3 "tiles"
label values floor fl
svyset ea [pweight = wt], strata(stratum)

local assets electricity radio tv fridge mobile bicycle floor water toilet
polycorr `assets', svy fit pdfix
display "min eigenvalue = " e(mineig)
* test: are tv and fridge equally correlated with electricity?
test [electricity]tv = [electricity]fridge

polyindex `assets' [pw = wt], gen(wi) ncomp(2) q(5) qgen(wq) ///
	reps(200) cluster(ea) seed(2026) scorese(wi_se) compare(mca pca)
* factor-analytic variant with varimax rotation
polyindex `assets' [pw = wt], method(fa) ncomp(2) rotate(varimax) gen(fi)
matrix list r(load_se)
* validity check against the simulated latent wealth and expenditure
correlate wi1 wealth lnexp
tabstat lnexp, by(wq) stat(mean n)

log close
