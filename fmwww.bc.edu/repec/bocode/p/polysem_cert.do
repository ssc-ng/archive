* polysem_cert.do -- certification script for polysem 1.0.0
* Reference values from an independent Python implementation (see article appendix).
version 14
clear all
set more off
which polycorr
which polysem

program define relclose
	args a b tol
	if abs(`a' - `b') > `tol' * max(abs(`b'), 1e-8) {
		di as err "FAILED: got " %16.10f `a' ", expected " %16.10f `b'
		exit 9
	}
end

set obs 500
gen long i = _n
gen double f1 = invnormal((mod(37*i, 503) + .5)/503)
gen double f2 = .4*f1 + sqrt(.84)*invnormal((mod(101*i, 503) + .5)/503)
local lam  .7 .6 .8 .75 .65 .5
local mult 53 71 89 113 131 151
local c1 -1 0 1
local c2 -.5 .6
local c3 -.2
local c4 -1.2 -.3 .4 1.1
local c5 0 .8
local c6 -.6 .3
forvalues j = 1/6 {
	local l : word `j' of `lam'
	local a : word `j' of `mult'
	local f = cond(`j' <= 3, "f1", "f2")
	gen double z`j' = `l'*`f' + sqrt(1 - `l'^2)*invnormal((mod(`a'*i, 503) + .5)/503)
	gen byte y`j' = 0
	foreach c of local c`j' {
		replace y`j' = y`j' + (z`j' > `c')
	}
}

polysem (F1: y1 y2 y3) (F2: y4 y5 y6)
relclose _b[F1:y1]   .6534886403 1e-5
relclose _b[F1:y2]   .6129940567 1e-5
relclose _b[F1:y3]   .8184083627 1e-5
relclose _b[F2:y4]   .7469999351 1e-5
relclose _b[F2:y5]   .6272329034 1e-5
relclose _b[F2:y6]   .6056680669 1e-5
relclose _b[corr:F1_F2] .3695685282 1e-5
relclose _se[F1:y1]  .0521575045 1e-3
relclose _se[F2:y6]  .0510563109 1e-3
relclose _se[corr:F1_F2] .06177713 1e-3
relclose e(chi2)    6.7548893346 1e-3
relclose e(chi2_ms) 6.6440281380 1e-3
assert e(df_m) == 8
assert e(converged) == 1

polysem (F1: y1 y2 y3) (F2: y4 y5 y6), estimator(uls)
relclose _b[F1:y3] .8225892173 1e-5
relclose _b[corr:F1_F2] .3634176908 1e-5

* features
polysem (F1: y1 y2 y3) (F2: y4 y5 y6), orthogonal
assert e(df_m) == 9
polysem (F1: y1 y2 y3 y4) (F2: y4 y5 y6)
assert e(df_m) == 7
test [F1]y1 = [F1]y2
gen int cl = ceil(i/10)
polysem (F1: y1 y2 y3) (F2: y4 y5 y6), vce(cluster cl)
assert "`e(vce)'" == "cluster"
capture polysem (F1: y1) (F2: y4 y5 y6)
assert _rc == 459
polysem
di as res _n "ALL CERTIFICATION TESTS PASSED"
