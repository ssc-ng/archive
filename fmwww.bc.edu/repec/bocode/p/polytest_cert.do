* polytest_cert.do -- certification script for polytest 1.0.0
version 14
clear all
set more off
which polycorr
which polytest
program define relclose
	args a b tol
	if abs(`a' - `b') > `tol' * max(abs(`b'), 1e-8) {
		di as err "FAILED: got " %16.10f `a' ", expected " %16.10f `b'
		exit 9
	}
end
set obs 600
gen long i = _n
gen double z1 = invnormal((mod(37*i, 601) + .5)/601)
gen double z2 = .5*z1 + sqrt(.75)*invnormal((mod(101*i, 601) + .5)/601)
gen double z3 = .4*z1 + sqrt(.84)*invnormal((mod(173*i, 601) + .5)/601)
gen double x  = .6*z1 + .8*invnormal((mod(211*i, 601) + .5)/601)
gen byte b1 = z1 > 0
gen byte b2 = z2 > .3
gen byte b3 = z3 > -.4
gen byte o  = (z2 > -.5) + (z2 > .4) + (z2 > 1)

polytest b1 b2 b3, triplets reps(0)
matrix T = r(triplets)
assert T[1,4] == 1
relclose T[1,5] .16037105324913437 1e-4
relclose T[1,7] .16059899592362448 1e-4
relclose T[1,8] .688605633654007   1e-4

polytest b1 b3 o, triplets reps(0)
matrix T = r(triplets)
assert T[1,4] == 7
relclose T[1,7] .5499615853369163 1e-4

polytest x o, polyserial reps(0) bins(5)
matrix P = r(polyserial)
relclose P[1,3] .2926552671991245 1e-6
assert P[1,4] == 11
relclose P[1,5] 4.749296146494708 1e-4
relclose P[1,9] .9886479598854166 1e-6

polytest x b1, polyserial reps(0) bins(4)
matrix P = r(polyserial)
relclose P[1,5] .17543702345901116 1e-4

* bootstrap runs and returns a valid p-value
polytest b1 b2 b3 x o, reps(49) seed(3)
matrix T = r(triplets)
assert T[1,9] > 0 & T[1,9] <= 1
assert rowsof(T) == 4
di as res _n "ALL CERTIFICATION TESTS PASSED"
