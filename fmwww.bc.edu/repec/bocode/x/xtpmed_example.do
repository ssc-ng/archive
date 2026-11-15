* xtpmed_example.do
* Simulated UNBALANCED panel with two mediators and known effects.
* Static design (true values for d1 = 1, d0 = 0):
*   NDE = 1.5,  NIE via m1 = 0.8*1.0 = 0.8,  NIE via m2 = -0.5*0.6 = -0.3
*   NIE = 0.5,  TE = 2.0,  PM = 0.25

clear all
set seed 20261110
local N 200
local T 20

set obs `N'
gen id = _n
gen double a  = rnormal()
gen double lD = rnormal()
gen double lM = rnormal()
gen double lY = rnormal()
expand `T'
bysort id: gen year = 1999 + _n
xtset id year

* common factor (creates cross-sectional dependence)
bysort year: gen double f = rnormal() if _n == 1
bysort year (f): replace f = f[1]
sort id year

gen double x  = rnormal()
gen double d  = a + 0.5*x + lD*f + rnormal()
gen double m1 =  0.8*d + 0.3*x + 0.5*a + lM*f + rnormal()
gen double m2 = -0.5*d + 0.3*x + 0.5*a + lM*f + rnormal()
gen double y  = 1.5*d + 1.0*m1 + 0.6*m2 + 0.5*x + a + lY*f + rnormal()

* make the panel unbalanced: drop 10% of observations at random
drop if runiform() < 0.10
keep id year y d m1 m2 x
xtset id year

* ---------------------------------------------------------------
* 1. Two-way fixed effects with Driscoll-Kraay standard errors
xtpmed y, treatment(d) mediators(m1 m2) controls(x) estimator(fe) timefe vce(dk)

* 2. CCE pooled: removes the common factor (compare the CD tests with model 1)
xtpmed y, treatment(d) mediators(m1 m2) controls(x) estimator(ccep)

* 3. CCE mean group
xtpmed y, treatment(d) mediators(m1 m2) controls(x) estimator(ccemg)

* 4. Random effects (inconsistent here: the unit effect is correlated with d)
xtpmed y, treatment(d) mediators(m1 m2) controls(x) estimator(re)

* 5. DML-GMM with repeated cross-fitting
xtpmed y, treatment(d) mediators(m1 m2) controls(x) estimator(dml) lags(0) ivlags(2) repeat(3) seed(1)

* 6. Bootstrap inference for the effects
xtpmed y, treatment(d) mediators(m1 m2) controls(x) estimator(fe) timefe bootstrap(99) seed(1)

* 7. Stored results
matrix list e(effects)
matrix list e(diag)

* ---------------------------------------------------------------
* Dynamic heterogeneous design for dfe / mg / pmg / csardl (long T)
clear
set seed 7
local N 60
local T 60
set obs `N'
gen id = _n
gen double mu = rnormal()
gen double ci = 1.5 + 0.2*rnormal()
expand `T'
bysort id: gen t = _n
xtset id t
gen double x = rnormal()
gen double d = 0
gen double m = 0
gen double y = 0
* long-run: d -> m = 0.8, m -> y = 1.0, d -> y = c_i (mean 1.5); NIE = 0.8, NDE = 1.5
by id: replace d = mu + 0.5*d[_n-1] + 0.3*x + rnormal() if _n > 1
by id: replace m = 0.5*m[_n-1] + 0.5*0.8*(0.6*d + 0.4*d[_n-1]) + 0.2*x + rnormal() if _n > 1
by id: replace y = mu + 0.4*y[_n-1] + 0.6*(ci*(0.7*d + 0.3*d[_n-1]) + 1.0*(0.5*m + 0.5*m[_n-1])) + 0.2*x + rnormal() if _n > 1
drop if t <= 10

xtpmed y, treatment(d) mediators(m) controls(x) estimator(dfe)
xtpmed y, treatment(d) mediators(m) controls(x) estimator(mg)
xtpmed y, treatment(d) mediators(m) controls(x) estimator(pmg)
xtpmed y, treatment(d) mediators(m) controls(x) estimator(csardl)
