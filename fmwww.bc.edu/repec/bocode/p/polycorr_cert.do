* polycorr_cert.do -- certification script for polycorr 1.1.0
* Reference values computed with an independent Python implementation
* (numpy/scipy) of the same estimator; see the article's appendix.
* Run:  do polycorr_cert.do      Expect: "ALL CERTIFICATION TESTS PASSED"

version 14
clear all
set more off
which polycorr
which polyindex

program define relclose
	args a b tol
	if abs(`a' - `b') > `tol' * max(abs(`b'), 1e-8) {
		di as err "FAILED: got " %16.10f `a' ", expected " %16.10f `b'
		exit 9
	}
end

* ---------------------------------------------------------- 1. deterministic data
set obs 400
gen long i = _n
gen double z1 = invnormal((mod(37*i, 401) + .5)/401)
gen double z2 = invnormal((mod(91*i, 401) + .5)/401)
gen double x3 = .6*z1 + .8*z2
gen byte  y1 = 1 + (z1 > -.8) + (z1 > 0) + (z1 > .9)
gen double v = .5*z1 + .866*z2
gen byte  y2 = 1 + (v > -.3) + (v > .7)
gen byte  w  = 1 + mod(i, 3)
gen int   cl = ceil(i/8)

* unweighted, robust
polycorr y1 y2 x3
relclose _b[y1:y2] .2427740125 1e-6
relclose _b[y1:x3] .410096868  1e-6
relclose _b[y2:x3] .9766293299 1e-6
relclose _se[y1:y2] .0605630137 1e-4
relclose _se[y1:x3] .0490851912 1e-4
relclose _se[y2:x3] .0045395046 1e-4
matrix V = e(V)
relclose V[1,2] .00282622014749 1e-3
assert "`e(types)'" == "O O C"
matrix F = e(fit)
relclose F[1,1] 20.2175228587 1e-5
relclose F[1,4] 20.0851905451 1e-5
assert F[1,2] == 5
relclose F[1,5] .0012045512 1e-4
matrix T = e(tau)
relclose T[1,1] -.80642125 1e-6
relclose T[2,2] .59776013 1e-6

* cluster
polycorr y1 y2 x3, vce(cluster cl)
relclose _se[y1:y2] .0306064888 1e-4
relclose _se[y1:x3] .0235158618 1e-4
relclose _se[y2:x3] .0036468449 1e-4
assert e(N_clust) == 50

* pweights
polycorr y1 y2 x3 [pw = w]
relclose _b[y1:y2] .2512517779 1e-6
relclose _b[y1:x3] .414264558  1e-6
relclose _se[y1:y2] .0651605686 1e-4
relclose _se[y2:x3] .0044187005 1e-4

* fweights: same point estimates, SEs as if data were expanded
polycorr y1 y2 x3 [fw = w]
relclose _b[y1:y2] .2512517779 1e-6
relclose _se[y1:y2] .0427284837 1e-4
relclose _se[y1:x3] .0344371851 1e-4
preserve
expand w
polycorr y1 y2 x3
local se_exp = _se[y1:y2]
restore
polycorr y1 y2 x3 [fw = w]
relclose _se[y1:y2] `se_exp' 1e-6

* ---------------------------------------------------------- 2. known table (auto: rep78 x foreign)
clear
input byte rep78 byte foreign int n
1 0  2
2 0  8
3 0 27
4 0  9
5 0  2
3 1  3
4 1  9
5 1  9
end
expand n
polycorr rep78 foreign, fit
relclose _b[rep78:foreign] .8058083158 1e-6
relclose _se[rep78:foreign] .0796155281 1e-4
matrix F = e(fit)
relclose F[1,1] .2372484649 1e-4
relclose F[1,4] .2643767106 1e-4
assert F[1,2] == 3

* ---------------------------------------------------------- 3. invariances and features
sysuse auto, clear
* pairwise == listwise when no missing values
polycorr foreign mpg headroom
matrix b1 = e(b)
polycorr foreign mpg headroom, pairwise
matrix b2 = e(b)
assert mreldif(b1, b2) < 1e-10
* Pearson pair equals correlate
polycorr mpg weight, continuous(mpg weight)
local r = _b[mpg:weight]
quietly correlate mpg weight
relclose `r' r(rho) 1e-10
* catmax(): headroom (8 values) becomes continuous
polycorr headroom mpg, catmax(5)
assert "`e(types)'" == "C C"
* postestimation
polycorr foreign mpg headroom trunk, ordinal(headroom) continuous(trunk)
test [foreign]mpg = [foreign]trunk
lincom [foreign]mpg - [foreign]trunk
* replay
polycorr
* unknown options are rejected (not passed to ml)
capture polycorr foreign mpg, difficult
assert _rc == 198
* pdfix on an indefinite matrix: each pair observed on its own subsample
clear
set obs 900
set seed 101
gen double e1 = rnormal()
gen double e2 = rnormal()
gen int blk = ceil(_n/300)
gen byte a = .
gen byte b = .
gen byte c = .
replace a = (e1 > 0)                  if blk == 1
replace b = (e1 + .3*e2 > 0)          if blk == 1
replace b = (e1 > 0)                  if blk == 2
replace c = (e1 + .3*e2 > 0)          if blk == 2
replace a = (e1 > 0)                  if blk == 3
replace c = (-e1 + .3*e2 > 0)         if blk == 3
polycorr a b c, pairwise pdfix
assert e(is_pd) == 0
matrix Rp = e(R_pd)
mata: st_numscalar("me", min(symeigenvalues(st_matrix("Rp"))))
assert me > 0
assert abs(Rp[1,1] - 1) < 1e-10

* ---------------------------------------------------------- 4. survey and mi
webuse nhanes2f, clear
svyset psuid [pweight = finalwgt], strata(stratid)
polycorr health heartatk diabetes highbp, svy fit
assert e(N_strata) == 31 & e(N_psu) == 62
svy jackknife, nodots: polycorr health highbp, novce
* (replicate-weight route runs without error)

* ---------------------------------------------------------- 5. polyindex
clear
set obs 2000
set seed 2026
gen double wl = rnormal()
forvalues j = 1/6 {
	gen byte a`j' = (.7*wl + sqrt(1 - .49)*rnormal()) > (`j' - 3.5)/3
}
gen byte fl = 1 + (wl + rnormal() > -.5) + (wl + rnormal() > .8)
* the correlation matrix of this design is clearly positive definite (smallest
* eigenvalue about 0.4 in the reference implementation)
polycorr a1-a6 fl, novce matrix
assert e(mineig) > .2
polyindex a1-a6 fl, gen(s) q(5) qgen(q5) reps(30) seed(1)
assert r(reps) >= 25
assert r(spearman) > .9
quietly correlate s1 wl
assert r(rho) > .7
tab q5
* factor method, household score SEs and comparison indices
polyindex a1-a6 fl, method(fa) gen(f) reps(25) seed(2) scorese(f_se) compare(pca mca) nodots
assert r(rho_pca) > .8 & r(rho_pca) <= 1
assert r(rho_mca) > .8 & r(rho_mca) <= 1
matrix U = r(uniqueness)
assert U[1,1] > 0 & U[1,1] < 1
summarize f_se, meanonly
assert r(min) >= 0 & r(mean) > 0
polyindex a1-a6 fl, method(fa) ncomp(2) rotate(varimax) gen(g) replace
matrix Lr = r(loadings)
assert colsof(Lr) == 2
* Fisher-z display
polycorr a1 a2 fl, cifz

di as res _n "ALL CERTIFICATION TESTS PASSED"
