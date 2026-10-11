version 14.2
clear all
set more off

* ======================================================================
* modelaudit PUBLIC VALIDATION SUITE
* Target: modelaudit v0.1.4+
* Date: 18 Sep 2026
* Revision: public-validation r6 (v0.1.4 rank-semantics correction)
*
* PURPOSE
* -------
* Public/reproducible validation only.
* Contains no proprietary data, project names, private paths, or
* project-specific variable names.
*
* This file deliberately combines:
*   1. synthetic known-behavior tests; and
*   2. an official Stata example dataset (sysuse auto).
*
* REQUIREMENT
* -----------
* modelaudit must already be discoverable on Stata's adopath.
* ======================================================================

di as text "============================================================"
di as text "MODELAUDIT PUBLIC VALIDATION SUITE"
di as text "============================================================"

capture which modelaudit
if _rc {
    di as error "modelaudit is not currently on Stata's adopath."
    di as error "Add the package directory to adopath, then rerun this file."
    exit 111
}

which modelaudit

* ======================================================================
* TEST 1. Core logistic-model audit with a deliberately changing sample
* ======================================================================

di as text _newline "TEST 1: logistic models, model df, E/df, and changing sample"

clear
set seed 17092026
set obs 500

gen long id = _n
gen double x = rnormal()
gen double z = rnormal()
gen byte g = mod(_n,4) + 1

gen double p = invlogit(-2.0 + 0.7*x - 0.25*z + 0.15*(g==4))
gen byte y = runiform() < p

* Later models lose the first 25 observations.
replace z = . in 1/25

quietly logit y x
estimates store ma1

quietly logit y x z
estimates store ma2

quietly logit y x z i.g
estimates store ma3

modelaudit ma1 ma2 ma3, focal(x) samples
matrix S = r(summary)
matrix O = r(overlap)

assert S[1,1] == 500
assert S[2,1] == 475
assert S[3,1] == 475

* e(rank) is the rank of e(V); model df is a distinct stored result.
assert S[1,4] == 2
assert S[2,4] == 3
assert S[3,4] == 6

* Coefficient-vector columns are counted directly from e(b).
* ma3 includes the base-category column for i.g, so Coef cols exceeds VCE rank.
assert S[1,18] == 2
assert S[2,18] == 3
assert S[3,18] == 7
assert S[3,18] > S[3,4]

assert S[1,5] == 1
assert S[2,5] == 2
assert S[3,5] == 5

* E/df must use e(df_m), not VCE rank or coefficient-column count.
assert abs(S[1,6] - S[1,2]/S[1,5]) < 1e-12
assert abs(S[2,6] - S[2,2]/S[2,5]) < 1e-12
assert abs(S[3,6] - S[3,2]/S[3,5]) < 1e-12

* Base model is a reference, not a self-comparison.
assert S[1,17] == .
assert S[2,17] == 0
assert S[3,17] == 0

* ma2 and ma3 use exactly the same observations.
assert O[2,3] == 475

* Events + non-events must equal estimation N.
assert S[1,2] + S[1,3] == S[1,1]
assert S[2,2] + S[2,3] == S[2,1]
assert S[3,2] + S[3,3] == S[3,1]

di as result "PASS 1: core logistic audit"

* ======================================================================
* TEST 2. Same N but DIFFERENT people
*
* This is a key reason to compare e(sample), not only e(N).
* Both models have N=480, but one drops observations 1-20 and the other
* drops observations 481-500. Their overlap is therefore 460.
* ======================================================================

di as text _newline "TEST 2: equal N but different estimation samples"

clear
set seed 17092027
set obs 500

gen long id = _n
gen double x = rnormal()
gen double z_left = rnormal()
gen double z_right = rnormal()
gen byte y = runiform() < invlogit(-1.7 + 0.55*x)

replace z_left  = . in 1/20
replace z_right = . in 481/500

quietly logit y x z_left
estimates store sameN_A

quietly logit y x z_right
estimates store sameN_B

modelaudit sameN_A sameN_B, focal(x) samples
matrix S2 = r(summary)
matrix O2 = r(overlap)

assert S2[1,1] == 480
assert S2[2,1] == 480
assert S2[2,17] == 0
assert O2[1,2] == 460

di as result "PASS 2: modelaudit detects different people despite identical N"

* ======================================================================
* TEST 3. Sequential comparison
* ======================================================================

di as text _newline "TEST 3: sequential comparison"

clear
set seed 17092028
set obs 400

gen double x = rnormal()
gen double z = rnormal()
gen byte h = mod(_n,3) + 1
gen byte y = runiform() < invlogit(-1.8 + .6*x - .2*z)

replace z = . in 1/30

quietly logit y x
estimates store seq1

quietly logit y x z
estimates store seq2

quietly logit y x z i.h
estimates store seq3

modelaudit seq1 seq2 seq3, focal(x) previous
matrix P = r(summary)

assert P[1,17] == .
assert P[2,17] == 0
assert P[3,17] == 1

di as result "PASS 3: sequential sample comparison"

* ======================================================================
* TEST 4. base() option
* ======================================================================

di as text _newline "TEST 4: alternate base model"

modelaudit seq1 seq2 seq3, focal(x) base(2)
matrix B = r(summary)

* seq2 is now the reference; seq3 shares its sample; seq1 does not.
assert B[2,17] == .
assert B[1,17] == 0
assert B[3,17] == 1

di as result "PASS 4: base() comparator"

* ======================================================================
* TEST 5. Clustered VCE and factor-variable focal coefficient
* ======================================================================

di as text _newline "TEST 5: clustered VCE and factor-variable focal"

clear
set seed 17092029
set obs 500

gen long cluster_id = ceil(_n/10)
gen byte g = mod(_n,4) + 1
gen double x = rnormal()
gen byte y = runiform() < invlogit(-1.9 + .45*x + .30*(g==2))

quietly logit y x i.g, vce(cluster cluster_id)
estimates store cl1

quietly logit y x i.g c.x#i.g, vce(cluster cluster_id)
estimates store cl2

modelaudit cl1 cl2, focal(2.g)
matrix C = r(summary)

assert C[1,15] == 50
assert C[2,15] == 50
assert C[1,8] > 0
assert C[2,8] > 0

di as result "PASS 5: cluster count and factor-variable focal coefficient"

* ======================================================================
* TEST 6. Missing focal coefficient in one stored model
* ======================================================================

di as text _newline "TEST 6: focal coefficient absent from one model"

clear
set seed 17092030
set obs 350

gen double x = rnormal()
gen double z = rnormal()
gen byte y = runiform() < invlogit(-1.5 + .5*x - .2*z)

quietly logit y z
estimates store nox

quietly logit y x z
estimates store withx

modelaudit nox withx, focal(x)
matrix F = r(summary)

assert r(focal_missing) == 1
assert F[1,7] == .
assert F[1,8] == .
assert F[2,7] < .

di as result "PASS 6: missing focal coefficient handled without fabrication"

* ======================================================================
* TEST 7. Stored estimates with unavailable e(sample)
*
* Official Stata does not provide a noesample option on estimates store.
* Instead, save an estimation result to disk and reload it with
* estimates use. Stata intentionally sets e(sample) to zero after
* reloading because the original estimation data may no longer be present.
* ======================================================================

di as text _newline "TEST 7: unavailable e(sample)"

clear
set seed 17092031
set obs 300

gen double x = rnormal()
gen double z = rnormal()
gen byte y = runiform() < invlogit(-1.6 + .55*x)

tempfile nosampster

* Fit and save the first model to disk.
quietly logit y x
estimates save "`nosampster'", replace

* Store a second model normally; its e(sample) should remain available.
quietly logit y x z
estimates store hassamp

* Reload the first model. Per official Stata behavior, e(sample) is now
* zero/unavailable until the user explicitly reconstructs it.
quietly estimates use "`nosampster'"
estimates store nosamp

modelaudit nosamp hassamp, focal(x)
matrix NS = r(summary)

assert r(sample_missing) == 1
assert NS[1,1] == 300
assert NS[2,1] == 300
assert NS[1,16] == .
assert NS[2,16] == 1

* Exact sample equality cannot be assessed against a model whose
* estimation sample is unavailable.
assert NS[2,17] == .

di as result "PASS 7: reloaded estimates with unavailable e(sample) handled explicitly"

* ======================================================================
* TEST 8. Raw coefficient scale with linear regression
* ======================================================================

di as text _newline "TEST 8: linear regression raw coefficient scale"

clear
set seed 17092032
set obs 450

gen double x = rnormal()
gen double z = rnormal()
gen byte g = mod(_n,4) + 1
gen double y = 2 + .4*x - .2*z + rnormal()

quietly regress y x z i.g
estimates store reg1

quietly regress y x z
estimates store reg2

modelaudit reg1 reg2, focal(x) coef
matrix R = r(summary)

assert abs(R[1,8] - R[1,7]) < 1e-12
assert abs(R[2,8] - R[2,7]) < 1e-12

di as result "PASS 8: linear-model coefficient scale"

* ======================================================================
* TEST 9. Exponentiated display with Poisson
* ======================================================================

di as text _newline "TEST 9: Poisson IRR scale"

clear
set seed 17092033
set obs 500

gen double x = rnormal()
gen byte g = mod(_n,4) + 1
gen int count_y = rpoisson(exp(.2 + .25*x + .10*(g==4)))

quietly poisson count_y x
estimates store pois1

quietly poisson count_y x i.g
estimates store pois2

modelaudit pois1 pois2, focal(x)
matrix Q = r(summary)

assert abs(Q[1,8] - exp(Q[1,7])) < 1e-10
assert abs(Q[2,8] - exp(Q[2,7])) < 1e-10

di as result "PASS 9: Poisson IRR display"

* ======================================================================
* TEST 10. Cox regression HR scale
* ======================================================================

di as text _newline "TEST 10: Cox regression HR scale"

clear
set seed 17092034
set obs 500

gen double x = rnormal()
gen double z = rnormal()

* Exponential event times with covariate-dependent rate.
gen double event_t = -ln(runiform()) / exp(.35*x - .20*z)

* Independent administrative/random censoring.
gen double censor_t = 1.5 + 3*runiform()
gen double t = min(event_t, censor_t)
gen byte fail = event_t <= censor_t

stset t, failure(fail)

quietly stcox x
estimates store cox1

quietly stcox x z
estimates store cox2

modelaudit cox1 cox2, focal(x)
matrix H = r(summary)

* stcox stores command identity through e(cmd2)="stcox" while e(cmd)
* may be "cox"; modelaudit must still recognize and display HRs.
assert abs(H[1,8] - exp(H[1,7])) < 1e-10
assert abs(H[2,8] - exp(H[2,7])) < 1e-10
assert H[1,8] > 0
assert H[2,8] > 0
assert H[1,2] == .
assert H[2,2] == .

di as result "PASS 10: Cox HR display"

* ======================================================================
* TEST 11. Noncomparable focal-change comparisons
*
* Delta b % should be suppressed when outcomes and/or estimation commands
* differ, while model-specific estimates and other diagnostics still print.
* ======================================================================

di as text _newline "TEST 11: suppress noncomparable Delta b comparisons"

clear
set seed 17092035
set obs 400

gen double x = rnormal()
gen byte y_bin  = runiform() < invlogit(-1.5 + .5*x)
gen byte y_bin2 = runiform() < invlogit(-1.2 + .4*x)
gen int y_count = rpoisson(exp(.2 + .2*x))

* 11A: different outcome AND different estimation command.
quietly logit y_bin x
estimates store het_logit

quietly poisson y_count x
estimates store het_pois

capture noisily modelaudit het_logit het_pois, focal(x)
assert _rc == 0
matrix HET1 = r(summary)

assert HET1[2,11] == .
assert r(delta_suppressed) == 1

* 11B: same estimation command, different dependent variable.
quietly logit y_bin2 x
estimates store het_logit2

capture noisily modelaudit het_logit het_logit2, focal(x)
assert _rc == 0
matrix HET2 = r(summary)

assert HET2[2,11] == .
assert r(delta_suppressed) == 1

* 11C: same outcome, different estimation command.
quietly probit y_bin x
estimates store het_probit

capture noisily modelaudit het_logit het_probit, focal(x)
assert _rc == 0
matrix HET3 = r(summary)

assert HET3[2,11] == .
assert r(delta_suppressed) == 1

di as result "PASS 11: noncomparable Delta b comparisons are suppressed"

* ======================================================================
* TEST 12. Mutually incompatible display options should fail explicitly
* ======================================================================

di as text _newline "TEST 12: invalid option combination"

capture noisily modelaudit het_logit het_pois, focal(x) eform coef
local rc = _rc
assert `rc' == 198

di as result "PASS 12: eform + coef rejected explicitly"

* ======================================================================
* TEST 13. Official Stata example data: auto
*
* This is deliberately not synthetic. It checks behavior on a bundled,
* public Stata example dataset without any private project dependency.
* ======================================================================

di as text _newline "TEST 13: official Stata example dataset (auto)"

sysuse auto, clear

quietly logit foreign mpg
estimates store auto1

quietly logit foreign mpg weight
estimates store auto2

quietly logit foreign mpg weight i.rep78
estimates store auto3

modelaudit auto1 auto2 auto3, focal(mpg) samples
matrix A = r(summary)
matrix AO = r(overlap)

* auto has 74 observations and 22 foreign cars.
assert A[1,1] == 74
assert A[1,2] == 22

* rep78 has missing observations, so the third model must use fewer records.
assert A[3,1] < A[2,1]
assert A[3,17] == 0

* First two models use all 74 observations and therefore share e(sample).
assert A[2,17] == 1
assert AO[1,2] == 74

di as result "PASS 13: official Stata auto-data validation"

* ======================================================================
* TEST 14. VCE rank and coefficient-vector columns are distinct quantities
*
* Create an exactly collinear predictor. Stata retains an omitted coefficient
* column in e(b), while e(rank) reports the rank of e(V). modelaudit must
* report the two quantities separately and must not substitute one for the other.
* ======================================================================

di as text _newline "TEST 14: VCE rank versus coefficient columns"

clear
set obs 250
set seed 29092026
gen double x = rnormal()
gen double xdup = x
gen double y = 1 + .8*x + rnormal()

quietly regress y x
estimates store rk1

quietly regress y x xdup
scalar expected_vcerank = e(rank)
matrix expected_b = e(b)
scalar expected_bcols = colsof(expected_b)
assert expected_bcols > expected_vcerank
estimates store rk2

modelaudit rk1 rk2, focal(x) coef
matrix RK = r(summary)

assert RK[2,4] == expected_vcerank
assert RK[2,18] == expected_bcols
assert RK[2,4] < RK[2,18]

di as result "PASS 14: VCE rank and coefficient columns are reported separately"


* ======================================================================
* FINAL STATUS
* ======================================================================

di as text _newline "============================================================"
di as result "ALL MODELAUDIT PUBLIC VALIDATION TESTS PASSED"
di as text "============================================================"
