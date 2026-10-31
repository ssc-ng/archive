* polypml_cert.do -- certification script for polypml 1.0.0
* Reference values: independent Python implementation (polypml/ref/cert_pml.py).
* Expect: "ALL CERTIFICATION TESTS PASSED"
version 14
clear all
set more off
which polycorr
which polypml

program define relclose
	args a b tol
	if abs(`a' - `b') > `tol' * max(abs(`b'), 1e-8) {
		di as err "FAILED: got " %16.10f `a' ", expected " %16.10f `b'
		exit 9
	}
end

set obs 400
gen long i = _n
gen double z1 = invnormal((mod(37*i, 401) + .5)/401)
gen double z2 = invnormal((mod(91*i, 401) + .5)/401)
gen double z3 = invnormal((mod(53*i, 401) + .5)/401)
gen double x3 = .6*z1 - .3*z2 + .74*z3
gen double v  = .5*z1 + .866*z2
gen byte y1 = 1 + (z1 > -.8) + (z1 > 0) + (z1 > .9)
gen byte y2 = 1 + (v > -.3) + (v > .7)
gen byte y3 = 1 + (x3 > 0)
replace y2 = . if mod(i, 7) == 0
replace y3 = . if mod(i, 5) == 0 & y1 >= 3

* ---------------------------------------------- pairwise ML
polypml y1 y2 y3, thresholds
matrix b = e(b)
matrix V = e(V)
local ref  .2520487262 .6116966288 -.1159075191 -.7572769349 .087818547 .9642295898 -.2960212764 .5991623314 .0691015304
local rse  .0585491068 .0505268187 .0803943066 .0731210567 .0645890017 .0755648102 .0701960531 .0725853241 .0674839545
forvalues j = 1/9 {
	relclose b[1,`j'] `: word `j' of `ref'' 1e-6
	relclose sqrt(V[`j',`j']) `: word `j' of `rse'' 1e-4
}
relclose e(ll) -2063.2213546377 1e-8
assert e(converged) == 1
assert "`e(method)'" == "pml"

* complete data: PML agrees with the two-step estimator to two decimals
preserve
drop if missing(y1, y2, y3)
quietly polycorr y1 y2 y3
matrix b2 = e(b)
quietly polypml y1 y2 y3
matrix b3 = e(b)
forvalues j = 1/3 {
	assert abs(b2[1,`j'] - b3[1,`j']) < .02
}
restore

* ---------------------------------------------- FIML (deterministic Halton draws)
polypml y1 y2 y3, method(fiml) draws(200) thresholds
matrix b = e(b)
matrix V = e(V)
local ref  .25204434 .61814797 -.11121698 -.80588527 .00187127 .89590202 -.31991796 .58471346 .01224122
local rse  .06497344 .04956529 .07940388 .07091845 .06235583 .07256525 .06881259 .07155074 .06545586
forvalues j = 1/9 {
	if abs(`: word `j' of `ref'') > .05 relclose b[1,`j'] `: word `j' of `ref'' 1e-4
	else assert abs(b[1,`j'] - `: word `j' of `ref'') < 1e-5
	relclose sqrt(V[`j',`j']) `: word `j' of `rse'' 1e-2
}
relclose e(ll) -1108.58798877 1e-6
assert e(n_patterns) == 40

* ---------------------------------------------- postestimation and options
test [y1]y2 = [y1]y3
gen int cl = ceil(i/8)
polypml y1 y2 y3, vce(cluster cl)
assert e(N_clust) == 50
capture polypml y1 x3
assert _rc == 459
capture polypml y1 y2, method(xx)
assert _rc == 198

di as res _n "ALL CERTIFICATION TESTS PASSED"
