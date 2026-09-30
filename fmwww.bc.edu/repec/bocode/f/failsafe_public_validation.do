version 14.2
clear all
set more off
set seed 18092026

* ============================================================================
* FailSafe v0.1.6 PUBLIC VALIDATION
* Date: 18 Sep 2026
*
* v0.1.6 validation:
*   - core metadata and structural signals
*   - factor-variable and interaction cells
*   - perfect prediction and VCE integrity
*   - user-controlled thresholds
*   - Cox and Fine-Gray estimator-native event metadata
*   - broader binary-estimator compatibility
* ============================================================================

capture program drop failsafe

capture which failsafe
if _rc {
    di as error "failsafe was not found."
    di as error "Install the release candidate before running this file."
    exit 111
}

which failsafe

di as text _newline "============================================================"
di as text "FAILSAFE v0.1.6 PUBLIC VALIDATION"
di as text "============================================================"


* ============================================================================
* TEST 1. Binary logistic metadata
* ============================================================================

di as text _newline "TEST 1: logistic metadata"

clear
set seed 18092026
set obs 500

gen double x = rnormal()
gen double z = rnormal()
gen double p = invlogit(-2 + .7*x - .25*z)
gen byte y = runiform() < p

quietly logit y x z
local directN = e(N)
local directdf = e(df_m)
local directrank = e(rank)
matrix __b1 = e(b)
local directcols = colsof(__b1)

quietly count if e(sample) & y != 0
local directevents = r(N)

quietly count if e(sample) & y == 0
local directnonevents = r(N)

failsafe

assert r(N) == `directN'
assert r(events) == `directevents'
assert r(nonevents) == `directnonevents'
assert r(modeldf) == `directdf'
assert r(vce_rank) == `directrank'
assert r(rank) == `directrank'
assert r(coef_columns) == `directcols'
assert abs(r(epdf) - (`directevents'/`directdf')) < 1e-10
assert r(sample_available) == 1
assert r(perfect_available) == 1
assert r(determined_total) == 0
assert r(vce_available) == 1
assert r(se_problem_count) == 0

di as result "PASS 1: binary logistic metadata"


* ============================================================================
* TEST 2. Cluster count
* ============================================================================

di as text _newline "TEST 2: clustered logistic model"

clear
set seed 18092027
set obs 600

gen int hospital = ceil(_n/30)
gen double x = rnormal()
gen double p = invlogit(-1.5 + .6*x)
gen byte y = runiform() < p

quietly logit y x, vce(cluster hospital)
local directclust = e(N_clust)

failsafe

assert r(clusters) == `directclust'
assert r(clusters) == 20

di as result "PASS 2: cluster count"


* ============================================================================
* TEST 3. Collinearity / omitted coefficient
* ============================================================================

di as text _newline "TEST 3: omitted coefficient detection"

clear
set seed 18092028
set obs 400

gen double x = rnormal()
gen double xdup = 2*x
gen double p = invlogit(-1 + .5*x)
gen byte y = runiform() < p

quietly logit y x xdup
failsafe

assert r(omitted) >= 1
assert strpos("`r(signal_codes)'", "FS002") > 0

di as result "PASS 3: omitted coefficient detection"


* ============================================================================
* TEST 4. Factor-variable base category is NOT an omission signal
* ============================================================================

di as text _newline "TEST 4: normal factor-variable base category"

sysuse auto, clear
quietly regress price mpg i.foreign
failsafe

assert r(N) == 74
assert r(omitted) == 0
assert r(perfect_available) == 0
assert missing(r(determined_total))
assert missing(r(cds))
assert missing(r(cdf))

di as result "PASS 4: base category and absent perfect-prediction metadata"


* ============================================================================
* TEST 5. Nonbinary model does not invent event counts
* ============================================================================

di as text _newline "TEST 5: linear regression metadata"

sysuse auto, clear
quietly regress price mpg weight
failsafe

assert r(N) == 74
assert missing(r(events))
assert missing(r(nonevents))
assert missing(r(epdf))
assert r(perfect_available) == 0

di as result "PASS 5: nonbinary model metadata"


* ============================================================================
* TEST 6. Main-effect factor cell accounting
* ============================================================================

di as text _newline "TEST 6: factor-variable discovery and cell accounting"

clear
set seed 18092029
set obs 600

gen byte g = mod(_n,3) + 1
gen double x = rnormal()
gen double p = invlogit(-1.2 + .4*x + .25*(g==2) - .15*(g==3))
gen byte y = runiform() < p

quietly logit y x i.g
failsafe, cells

assert r(nfactorvars) == 1
assert "`r(factor_vars)'" == "g"
assert r(factor_cell_rows) == 3
assert r(zero_factor_cells) == 0

matrix C = r(factor_cells)
assert rowsof(C) == 3
assert colsof(C) == 8

forvalues i = 1/3 {
    assert C[`i',3] == 200
    assert C[`i',4] + C[`i',5] == C[`i',3]
}

di as result "PASS 6: factor-variable discovery and cell accounting"


* ============================================================================
* TEST 7. User-specified sparse threshold
* ============================================================================

di as text _newline "TEST 7: mincell() remains user-controlled"

clear
set seed 18092030
set obs 204

gen byte g = 1
replace g = 2 in 101/200
replace g = 3 in 201/204

gen double x = rnormal()
gen double p = invlogit(-1 + .4*x)
gen byte y = runiform() < p

replace y = 0 in 201/202
replace y = 1 in 203/204

quietly logit y x i.g

failsafe
assert r(mincell) == 0
assert r(sparse_factor_levels) == 0
assert strpos("`r(signal_codes)'", "FS102") == 0

failsafe, mincell(5) cells
assert r(mincell) == 5
assert r(sparse_factor_levels) == 1
assert strpos("`r(signal_codes)'", "FS102") > 0

di as result "PASS 7: user-specified sparse-level threshold"


* ============================================================================
* TEST 8. Two-way categorical interaction accounting
* ============================================================================

di as text _newline "TEST 8: two-way categorical interaction cells"

clear
set seed 18092031
set obs 800

gen byte g = mod(_n,2) + 1
gen byte h = mod(ceil(_n/2),2) + 1
gen double p = invlogit(-1 + .25*(g==2) + .2*(h==2))
gen byte y = runiform() < p

quietly logit y i.g#i.h
failsafe, cells

assert r(nfactorvars) == 2
assert r(ninteractionsets) == 1
assert r(interaction_cell_rows) == 4
assert r(zero_interaction_cells) == 0

matrix I = r(interaction_cells)
assert rowsof(I) == 4
assert colsof(I) == 9

forvalues i = 1/4 {
    assert I[`i',4] == 200
    assert I[`i',5] + I[`i',6] == I[`i',4]
}

di as result "PASS 8: two-way interaction cell accounting"


* ============================================================================
* TEST 9. Official Stata perfect-prediction example
*
* Current [R] logit manual:
*   sysuse auto
*   drop if foreign==0 & gear_ratio > 3.1
*   logit foreign mpg weight gear_ratio
*
* Stata reports 4 failures and 0 successes completely determined.
* ============================================================================

di as text _newline "TEST 9: official Stata completely determined outcome example"

sysuse auto, clear
drop if foreign == 0 & gear_ratio > 3.1

quietly logit foreign mpg weight gear_ratio

failsafe

assert r(perfect_available) == 1
assert r(cds) == 0
assert r(cdf) == 4
assert r(determined_total) == 4
assert strpos("`r(signal_codes)'", "FS003") > 0

di as result "PASS 9: official Stata completely determined outcome example"


* ============================================================================
* TEST 10. Probit exposes official metadata names without false positives
* ============================================================================

di as text _newline "TEST 10: probit perfect-prediction metadata availability"

clear
set seed 18092032
set obs 500

gen double x = rnormal()
gen double z = rnormal()
gen double p = normal(-1 + .5*x - .2*z)
gen byte y = runiform() < p

quietly probit y x z
failsafe

assert r(perfect_available) == 1
assert r(cds) >= 0
assert r(cdf) >= 0
assert r(determined_total) >= 0

di as result "PASS 10: probit metadata availability"


* ============================================================================
* TEST 11. Regression cannot be mislabeled as perfect-prediction-capable
* ============================================================================

di as text _newline "TEST 11: absent e(N_cds)/e(N_cdf) is detected exactly"

sysuse auto, clear
quietly regress price mpg weight

local escalars : e(scalars)
local cds_pos : list posof "N_cds" in escalars
local cdf_pos : list posof "N_cdf" in escalars

assert `cds_pos' == 0
assert `cdf_pos' == 0

failsafe

assert r(perfect_available) == 0
assert missing(r(cds))
assert missing(r(cdf))
assert missing(r(determined_total))
assert strpos("`r(signal_codes)'", "FS003") == 0

di as result "PASS 11: absent perfect-prediction metadata detected exactly"


* ============================================================================
* TEST 12. e(rank) is VCE rank, not coefficient-column count
*
* Deliberate collinearity leaves an omitted coefficient column in e(b).
* The coefficient vector can therefore have more columns than e(V)'s rank.
* ============================================================================

di as text _newline "TEST 12: VCE rank is distinguished from coefficient columns"

clear
set seed 18092033
set obs 300

gen double x = rnormal()
gen double xdup = 2*x
gen double y = 1 + .5*x + rnormal()

quietly regress y x xdup

matrix __b12 = e(b)
local kcols12 = colsof(__b12)
local vrank12 = e(rank)

assert `kcols12' > `vrank12'

failsafe

assert r(coef_columns) == `kcols12'
assert r(vce_rank) == `vrank12'
assert r(rank) == `vrank12'
assert r(coef_columns) > r(vce_rank)

di as result "PASS 12: VCE rank distinguished from coefficient columns"


* ============================================================================
* TEST 13. Cluster threshold is user-controlled
* ============================================================================

di as text _newline "TEST 13: minclusters() is user-controlled"

clear
set seed 18092034
set obs 600

gen int hospital = ceil(_n/30)
gen double x = rnormal()
gen double p = invlogit(-1.5 + .6*x)
gen byte y = runiform() < p

quietly logit y x, vce(cluster hospital)

failsafe
assert r(clusters) == 20
assert r(minclusters) == 0
assert strpos("`r(signal_codes)'", "FS202") == 0

failsafe, minclusters(21)
assert r(minclusters) == 21
assert strpos("`r(signal_codes)'", "FS202") > 0

failsafe, minclusters(20)
assert strpos("`r(signal_codes)'", "FS202") == 0

di as result "PASS 13: user-specified cluster threshold"


* ============================================================================
* TEST 14. Missing/nonpositive VCE diagonal is a structural signal
*
* ereturn post must run from an e-class program.  The temporary program below
* posts a deliberately invalid variance of zero for x so FailSafe can inspect
* a controlled e(V) without depending on an estimator-specific failure mode.
* ============================================================================

di as text _newline "TEST 14: unusable standard-error metadata"

clear
set obs 20
gen double y = rnormal()
gen double x = rnormal()

capture program drop __fs_post_bad_vce
program define __fs_post_bad_vce, eclass
    version 14.2

    tempname b V

    matrix `b' = (0.5, 1)
    matrix colnames `b' = x _cons

    matrix `V' = (0, 0 \ 0, 1)
    matrix rownames `V' = x _cons
    matrix colnames `V' = x _cons

    ereturn post `b' `V', obs(20) depname(y)
    ereturn local cmd "regress"
    ereturn local vce "user"
end

__fs_post_bad_vce

failsafe

assert r(vce_available) == 1
assert r(se_problem_count) == 1
assert strpos("`r(se_problem_terms)'", "x") > 0
assert strpos("`r(signal_codes)'", "FS201") > 0

capture program drop __fs_post_bad_vce

di as result "PASS 14: unusable standard-error metadata"


* ============================================================================
* TEST 15. Cox survival metadata uses e(N_fail)
* ============================================================================

di as text _newline "TEST 15: Cox failure-count metadata"

clear
set seed 18092035
set obs 500

gen double x = rnormal()
gen double z = rnormal()

* Exponential event time with independent administrative/random censoring.
gen double event_t = -ln(runiform()) / exp(.35*x - .20*z)
gen double censor_t = 1.5 + 3*runiform()
gen double t = min(event_t, censor_t)
gen byte fail = event_t <= censor_t

stset t, failure(fail)
quietly stcox x z

local directfail15 = e(N_fail)
local directsub15  = e(N_sub)
local directdf15   = e(df_m)
local directcmd15  "`e(cmd)'"
local directcmd215 "`e(cmd2)'"

* Current Stata semantics: stcox identifies itself through e(cmd2).
assert "`directcmd15'" == "cox" | "`directcmd15'" == "stcox_fr"
assert "`directcmd215'" == "stcox"

failsafe

assert "`r(cmd2)'" == "stcox"
assert r(failures) == `directfail15'
assert r(subjects) == `directsub15'
assert missing(r(events))
assert missing(r(nonevents))
assert abs(r(epdf) - (`directfail15'/`directdf15')) < 1e-10

di as result "PASS 15: Cox failure-count metadata"


* ============================================================================
* TEST 16. Fine-Gray competing-risks metadata uses estimator-native counts
* ============================================================================

di as text _newline "TEST 16: Fine-Gray failure/competing/censor metadata"

clear
set seed 18092036
set obs 700

gen double x = rnormal()
gen double z = rnormal()

* Two latent causes plus administrative/random censoring.
gen double t1 = -ln(runiform()) / exp(.30*x - .15*z)
gen double t2 = -ln(runiform()) / exp(-.10*x + .20*z)
gen double tc = 1.0 + 4*runiform()

gen double t = min(t1, t2, tc)
gen byte status = 0
replace status = 1 if t1 <= t2 & t1 <= tc
replace status = 2 if t2 < t1 & t2 <= tc

stset t, failure(status==1)
quietly stcrreg x z, compete(status==2)

local directfail16 = e(N_fail)
local directcomp16 = e(N_compete)
local directcens16 = e(N_censor)
local directsub16  = e(N_sub)
local directdf16   = e(df_m)

failsafe

assert r(failures) == `directfail16'
assert r(competing) == `directcomp16'
assert r(censored) == `directcens16'
assert r(subjects) == `directsub16'
assert missing(r(events))
assert missing(r(nonevents))
assert abs(r(epdf) - (`directfail16'/`directdf16')) < 1e-10

di as result "PASS 16: Fine-Gray competing-risks metadata"


* ============================================================================
* TEST 17. logistic command compatibility
* ============================================================================

di as text _newline "TEST 17: logistic command compatibility"

clear
set seed 18092037
set obs 500

gen double x = rnormal()
gen double z = rnormal()
gen double p = invlogit(-1.4 + .55*x - .20*z)
gen byte y = runiform() < p

quietly logistic y x z

local directN17 = e(N)
local directdf17 = e(df_m)
quietly count if e(sample) & y != 0
local directevents17 = r(N)
quietly count if e(sample) & y == 0
local directnonevents17 = r(N)

failsafe

assert r(N) == `directN17'
assert r(events) == `directevents17'
assert r(nonevents) == `directnonevents17'
assert r(modeldf) == `directdf17'

di as result "PASS 17: logistic command compatibility"


* ============================================================================
* TEST 18. Complementary log-log compatibility
* ============================================================================

di as text _newline "TEST 18: cloglog command compatibility"

clear
set seed 18092038
set obs 600

gen double x = rnormal()
gen double z = rnormal()
gen double eta = -1.2 + .45*x - .15*z
gen double p = 1 - exp(-exp(eta))
gen byte y = runiform() < p

quietly cloglog y x z

local directN18 = e(N)
local directdf18 = e(df_m)
quietly count if e(sample) & y != 0
local directevents18 = r(N)
quietly count if e(sample) & y == 0
local directnonevents18 = r(N)

failsafe

assert r(N) == `directN18'
assert r(events) == `directevents18'
assert r(nonevents) == `directnonevents18'
assert r(modeldf) == `directdf18'

di as result "PASS 18: cloglog command compatibility"


* ============================================================================
* TEST 19. Conditional logistic compatibility
* ============================================================================

di as text _newline "TEST 19: clogit command compatibility"

clear
set seed 18092039
set obs 800

gen int stratum = ceil(_n/4)
bysort stratum: gen byte case = (_n == 1)
gen double x = rnormal() + .6*case
gen double z = rnormal()

quietly clogit case x z, group(stratum)

local directN19 = e(N)
local directdf19 = e(df_m)
quietly count if e(sample) & case != 0
local directevents19 = r(N)
quietly count if e(sample) & case == 0
local directnonevents19 = r(N)

failsafe

assert r(N) == `directN19'
assert r(events) == `directevents19'
assert r(nonevents) == `directnonevents19'
assert r(modeldf) == `directdf19'
assert r(sample_available) == 1

di as result "PASS 19: clogit command compatibility"


* ============================================================================
* TEST 20. xtlogit random-effects compatibility
* ============================================================================

di as text _newline "TEST 20: xtlogit random-effects compatibility"

clear
set seed 18092040
set obs 600

gen int id = ceil(_n/12)
bysort id: gen int wave = _n
gen double u = rnormal() if wave == 1
bysort id (wave): replace u = u[1]
gen double x = rnormal()
gen double p = invlogit(-1.0 + .45*x + .45*u)
gen byte y = runiform() < p

xtset id wave
quietly xtlogit y x, re

local directN20 = e(N)
quietly count if e(sample) & y != 0
local directevents20 = r(N)
quietly count if e(sample) & y == 0
local directnonevents20 = r(N)

failsafe

assert r(N) == `directN20'
assert r(events) == `directevents20'
assert r(nonevents) == `directnonevents20'
assert r(sample_available) == 1
assert r(vce_available) == 1

di as result "PASS 20: xtlogit random-effects compatibility"


* ============================================================================
* TEST 21. melogit random-intercept compatibility
* ============================================================================

di as text _newline "TEST 21: melogit random-intercept compatibility"

clear
set seed 18092041
set obs 600

gen int hospital = ceil(_n/15)
bysort hospital: gen int seq = _n
gen double u = rnormal() if seq == 1
bysort hospital (seq): replace u = u[1]
gen double x = rnormal()
gen double p = invlogit(-1.1 + .50*x + .40*u)
gen byte y = runiform() < p

quietly melogit y x || hospital:

local directN21 = e(N)
local directcmd21 "`e(cmd)'"
local directcmd221 "`e(cmd2)'"
quietly count if e(sample) & y != 0
local directevents21 = r(N)
quietly count if e(sample) & y == 0
local directnonevents21 = r(N)

assert "`directcmd21'" == "meglm"
assert "`directcmd221'" == "melogit"

failsafe

assert "`r(cmd2)'" == "melogit"
assert r(N) == `directN21'
assert r(events) == `directevents21'
assert r(nonevents) == `directnonevents21'
assert r(sample_available) == 1
assert r(vce_available) == 1

di as result "PASS 21: melogit random-intercept compatibility"


* ============================================================================
* TEST 22. meqrlogit random-intercept compatibility
* ============================================================================

di as text _newline "TEST 22: meqrlogit random-intercept compatibility"

clear
set seed 18092042
set obs 600

gen int hospital = ceil(_n/15)
bysort hospital: gen int seq = _n
gen double u = rnormal() if seq == 1
bysort hospital (seq): replace u = u[1]
gen double x = rnormal()
gen double p = invlogit(-1.1 + .50*x + .40*u)
gen byte y = runiform() < p

quietly meqrlogit y x || hospital:

local directN22 = e(N)
quietly count if e(sample) & y != 0
local directevents22 = r(N)
quietly count if e(sample) & y == 0
local directnonevents22 = r(N)

failsafe

assert r(N) == `directN22'
assert r(events) == `directevents22'
assert r(nonevents) == `directnonevents22'
assert r(sample_available) == 1
assert r(vce_available) == 1

di as result "PASS 22: meqrlogit random-intercept compatibility"


* ============================================================================
* FINAL STATUS
* ============================================================================

di as text _newline "============================================================"
di as result "ALL FAILSAFE v0.1.6 PUBLIC VALIDATION TESTS PASSED"
di as text "============================================================"
