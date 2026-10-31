* polyreg_cert.do -- certification script for polyreg 1.0.0
* Expect: "ALL CERTIFICATION TESTS PASSED"
version 14
clear all
set more off
which polycorr
which polyindex
which polyreg

set seed 7
set obs 800
gen int ea = ceil(_n/10)
gen double u = rnormal(0, .4)
bysort ea: replace u = u[1]
gen double W = u + rnormal()
local j 0
foreach c in -.5 0 .3 .8 1 -.2 {
	local ++j
	gen byte a`j' = .7*W + rnormal()*.7 > `c'
}
gen double x = rnormal() + .3*W
gen double y = 1 + .5*W + .3*x + rnormal()
gen byte yb = y > 1.2

* 1. point estimates equal the manual two-step
polyreg y x, index(a1-a6) reps(50) seed(1) nodots
matrix b = e(b)
matrix Vn = e(V_naive)
matrix Vb = e(V)
local ok   = e(reps_ok)
local reps = e(reps)
local cmd  `e(cmd)'
quietly polyindex a1-a6, gen(chk) replace
quietly regress y chk1 x, vce(robust)
assert reldif(b[1,1], _b[chk1]) < 1e-10
assert reldif(sqrt(Vn[1,1]), _se[chk1]) < 1e-10
assert `ok' == `reps'
assert Vb[1,1] > 0
assert "`cmd'" == "polyreg"
* index variable left in the data equals polyindex's score
assert reldif(__prx1, chk1) < 1e-10

* 2. cluster bootstrap and naive cluster SEs
polyreg y x, index(a1-a6) reps(40) cluster(ea) seed(2) nodots
assert e(N_clust) == 80
matrix Vn2 = e(V_naive)
quietly regress y __prx1 x, vce(cluster ea)
assert reldif(sqrt(Vn2[1,1]), _se[__prx1]) < 1e-10

* 3. quintile dummies and logit
polyreg yb x, index(a1-a6) quantiles(5) model(logit) reps(40) seed(3) nodots
matrix b3 = e(b)
assert colsof(b3) == 7
assert "`e(model)'" == "logit"
tab __prxq

* 4. errors
capture polyreg y x, index(a1-a6) reps(5)
assert _rc == 198
capture polyreg y a1, index(a1-a6)
assert _rc == 198

* 5. replay
polyreg

di as res _n "ALL CERTIFICATION TESTS PASSED"
