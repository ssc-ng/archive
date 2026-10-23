// xtutest_example.do -- examples for xtutest 1.3.0
clear all
set more off

// 1. Simulated panel with a known inverse U: turning point of the mean curve at x = 1,
//    heterogeneous slopes and one common factor that drives x and y
set seed 2026
local N 30
local T 40
* common factor f_t: AR(1), the same for every unit
clear
set obs `T'
gen t = _n
gen double f = rnormal()
replace f = 0.5*f[_n-1] + rnormal() if _n > 1
tempfile F
save `F'
* units with heterogeneous slopes and factor loadings
clear
set obs `N'
gen id = _n
gen double mu = rnormal()
gen double g  = runiform(0.5, 1.5)
gen double b1 = 0.5 + 0.3*rnormal()
gen double b2 = -0.25 + 0.05*rnormal()
expand `T'
bysort id: gen t = _n
merge m:1 t using `F', nogenerate
xtset id t
gen double x = mu + g*f + rnormal(0, 0.7)
gen double y = b1*x + b2*x^2 + f + rnormal()
xtutest y x, interval(-2 2) pooled units
xtutest y x, interval(-2 2) nocce
xtutest_graph

// 2. APEC economies, 2000-2023: ecological footprint and internet use (shipped with the package)
use xtutest_apec, clear
xtset id year
gen lnEF = ln(EF)
xtutest lnEF NET GLB, pooled
xtutest lnEF NET GLB, nocce pooled
xtutest lnEF NET GLB, interval(0 100) graph
ereturn list

// 3. Residual diagnostics with unit p-values, and the homogeneous-slope variants
xtutest lnEF NET GLB, diag
xtutest lnEF NET GLB, estimator(ccep)
xtutest lnEF NET GLB, estimator(fe)
xtutest lnEF NET GLB, estimator(re)
xtutest lnEF NET GLB, estimator(iv)
xtutest lnEF NET GLB, estimator(gmm) gmmlags(2)
xtutest lnEF NET GLB, estimator(gmm) endog gmmlags(2)
