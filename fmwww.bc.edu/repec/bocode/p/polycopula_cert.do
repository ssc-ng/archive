* polycopula_cert.do -- certification script for polycopula 1.1.0
version 14
clear all
set more off
which polycorr
which polycopula
program define relclose
	args a b tol
	if abs(`a' - `b') > `tol' * max(abs(`b'), 1e-8) {
		di as err "FAILED: got " %16.10f `a' ", expected " %16.10f `b'
		exit 9
	}
end
set obs 500
gen long i = _n
gen double u = (mod(37*i, 503) + .5)/503
gen double w = (mod(101*i, 503) + .5)/503
gen double v = (u^(-2)*(w^(-2/3) - 1) + 1)^(-1/2)
gen byte x = (u > .2) + (u > .5) + (u > .8)
gen byte y = (v > .35) + (v > .75)
polycopula x y
matrix T = r(table)
* rows: gaussian, frank, clayton, gumbel
relclose T[1,4] .6869802870 1e-6
relclose T[1,5] .0306083612 1e-3
relclose T[2,4] 5.2183748557 1e-5
relclose T[3,4] 1.9651902757 1e-5
relclose T[3,5] .2199172273 1e-3
relclose T[3,6] .4956105859 1e-5
relclose T[3,7] .0279744259 1e-3
relclose T[4,6] .4659808558 1e-5
relclose T[1,9] -1116.7451440948 1e-7
relclose T[3,9] -1105.9131320651 1e-7
relclose T[3,12] .7361173713 1e-4
relclose T[3,15] 2.4533196710 1e-4
* Gaussian copula equals polycorr's polychoric correlation
quietly polycorr x y
relclose T[1,4] _b[x:y] 1e-6
* negative dependence: rotated Clayton
gen byte y2 = 2 - y
polycopula x y2, copulas(clayton)
matrix T = r(table)
assert T[2,3] == 1
relclose T[2,6] -.4956105814 1e-5
* robust polychoric (C-estimator): joint thresholds and rho
drop y2
polycopula x y, copulas(gaussian) robust
matrix RB = r(robust)
relclose RB[1,3] .6893033384 5e-4
relclose RB[1,4] .0305420988 1e-2
assert RB[1,5] == 0
assert RB[1,6] == 1
polycopula x y, copulas(gaussian) robust cutoff(.3)
matrix RB = r(robust)
relclose RB[1,3] .7022754376 5e-4
relclose RB[1,4] .0494972551 1e-2
assert RB[1,5] == 3
capture polycopula x y, robust cutoff(0)
assert _rc == 198
di as res _n "ALL CERTIFICATION TESTS PASSED"
