* idxnl_cert.do -- certification script for the idxnl package
* Expected values were computed independently from the same formulas.
version 14
clear all
set more off
cscript "idxnl certification" adofile idxdescribe idxspec idxtp idxint
use idxnl_example, clear
xtset id year

* ---------------------------------------------------------------- idxdescribe
idxdescribe gov, bounds(-2.5 2.5)
matrix T = r(table)
assert reldif(T[1,6], -0.4861689750183038) < 1e-05
assert reldif(T[1,7], -1.5597775) < 1e-05
assert reldif(T[1,9], 0.3924145) < 1e-05
assert reldif(T[1,13], 0.1447077523989899) < 1e-05
assert reldif(T[1,14], 0.5212596105394206) < 1e-05
assert reldif(T[1,15], 0.07283993904770705) < 1e-05

* ---------------------------------------------------------------- idxspec (pooled)
idxspec y gov w1 w2 i.year, vce(cluster id)
matrix C = r(compare)
assert reldif(r(tp), 0.3916220390050827) < 1e-05
assert reldif(r(se_tp), 0.6507797442420397) < 1e-05
assert reldif(r(delta_lb), -0.9161688198490199) < 1e-05
assert reldif(r(lm_t), 0.0012168340269253122) < 1e-05
assert reldif(r(lmfull_t), 0.5540401020689971) < 1e-05
assert reldif(r(kink), -1.408394) < 1e-05
assert reldif(r(slope_below), 7.507666281044523) < 1e-05
assert reldif(r(slope_above), 0.6898013898390749) < 1e-05
assert reldif(r(p_quad), 0.12198093989221492) < 1e-05
assert reldif(r(p_rcs), 0.02468867515095352) < 1e-05
assert reldif(r(p_kink), 0.0001293885591657773) < 1e-05
assert reldif(r(lo), -1.5597775) < 1e-05
assert reldif(r(hi), 0.3924145) < 1e-05
assert reldif(r(twolines_t1), 3.243490172187128) < 1e-05
assert reldif(r(twolines_t2), -1.1406348279105214) < 1e-05
assert reldif(r(twolines_at), 0.3916220390050827) < 1e-05
assert reldif(r(fieller_lb), -3.904565112893687) < 1e-05
assert reldif(r(fieller_ub), -0.2397195783176827) < 1e-05
assert "`r(fieller_type)'" == "union"
assert r(supported) == 0
assert r(adhoc) == 0
assert reldif(C[1,4], 1.6660886518614644) < 1e-05
assert reldif(C[2,4], 1.6533119199184256) < 1e-05
assert reldif(C[3,4], 1.6339411338427279) < 1e-05
assert reldif(C[4,4], 1.6337624575208956) < 1e-05
assert reldif(C[5,4], 1.6315906047212285) < 1e-05
assert reldif(C[1,3], 3965.7231641289864) < 1e-05
assert reldif(C[2,3], 3948.4854342698127) < 1e-05
assert reldif(C[3,3], 3925.5827739163756) < 1e-05
assert reldif(C[4,3], 3925.314360816612) < 1e-05
assert reldif(C[5,3], 3923.7549021234063) < 1e-05

* ---------------------------------------------------------------- idxspec (fe)
idxspec y gov w1 w2 i.year, fe vce(cluster id)
matrix C = r(compare)
assert reldif(r(tp), 0.17880150718111745) < 1e-05
assert reldif(r(se_tp), 0.26590793636636323) < 1e-05
assert reldif(r(delta_lb), -0.35556049709686366) < 1e-05
assert reldif(r(lm_t), 0.6420278336799363) < 1e-05
assert reldif(r(lmfull_t), 1.4496295138049202) < 1e-05
assert reldif(r(kink), -1.1287349999999998) < 1e-05
assert reldif(r(slope_below), 2.740775012915125) < 1e-05
assert reldif(r(slope_above), 0.6700513888483659) < 1e-05
assert reldif(r(p_quad), 0.011610236880793545) < 1e-05
assert reldif(r(p_rcs), 0.06098231435152601) < 1e-05
assert reldif(r(p_kink), 0.04527245023608073) < 1e-05
assert reldif(r(lo), -1.5597775) < 1e-05
assert reldif(r(hi), 0.3924145) < 1e-05
assert reldif(r(twolines_t1), 4.099431226844317) < 1e-05
assert reldif(r(twolines_t2), -0.15322151759452574) < 1e-05
assert reldif(r(twolines_at), 0.17880150718111745) < 1e-05
assert reldif(r(fieller_lb), -0.1866235839224165) < 1e-05
assert reldif(r(fieller_ub), 2.07243361477139) < 1e-05
assert "`r(fieller_type)'" == "bounded"
assert r(supported) == 0
assert r(adhoc) == 1
assert reldif(C[1,4], 1.2782728015023632) < 1e-05
assert reldif(C[2,4], 1.2748090675260866) < 1e-05
assert reldif(C[3,4], 1.2757607550760128) < 1e-05
assert reldif(C[4,4], 1.2752465337394783) < 1e-05
assert reldif(C[5,4], 1.2748659954407202) < 1e-05
assert reldif(C[1,3], 3332.3414898297306) < 1e-05
assert reldif(C[2,3], 3331.3218597969335) < 1e-05
assert reldif(C[3,3], 3338.1852830292246) < 1e-05
assert reldif(C[4,3], 3339.1234879407184) < 1e-05
assert reldif(C[5,3], 3339.7729610447977) < 1e-05

* ---------------------------------------------------------------- idxint
idxint y gov2 gov1 w1 w2 i.year, vce(cluster id)
assert reldif(r(rho), 0.6933025109078148) < 1e-05
assert reldif(r(b_xz_A), -0.5782547576646542) < 1e-05
assert reldif(r(se_xz_A), 0.3432358816775663) < 1e-05
assert reldif(r(p_xz_A), 0.09840348892440054) < 1e-05
assert reldif(r(b_xz_B), -0.2615195522963715) < 1e-05
assert reldif(r(p_xz_B), 0.5000613687548059) < 1e-05
assert reldif(r(F_quad), 2.1628354664565363) < 1e-05
assert reldif(r(F_bin), 4.403234847795217) < 1e-05
assert reldif(r(p_bin), 0.01743335607724328) < 1e-05
assert reldif(r(jn_lb), -2.641077163750758) < 1e-05
assert reldif(r(zsup_lo), -1.4984954999999998) < 1e-05
assert reldif(r(zsup_hi), 0.38418149999999995) < 1e-05

* ---------------------------------------------------------------- idxtp consistency with idxspec
regress y c.gov##c.gov w1 w2 i.year, vce(cluster id)
idxtp gov
assert reldif(r(tp), 0.3916220390050827) < 1e-05
assert reldif(r(se_tp), 0.6507797442420397) < 1e-05
assert reldif(r(lm_t), 0.0012168340269253122) < 1e-05
generate double gov_sq = gov^2
xtreg y gov gov_sq w1 w2 i.year, fe vce(cluster id)
idxtp gov, sq(gov_sq)
assert reldif(r(tp), 0.17880150718111745) < 1e-05
assert reldif(r(se_tp), 0.26590793636636323) < 1e-05
assert reldif(r(lm_t), 0.6420278336799363) < 1e-05

* ---------------------------------------------------------------- invariance to affine recoding
generate double gov100 = (gov + 2.5)/5*100
idxspec y gov100 w1 w2 i.year, vce(cluster id) notable
assert reldif(r(tp), (0.3916220390050827 + 2.5)/5*100) < 1e-5
assert reldif(r(lm_t), 0.0012168340269253122) < 1e-4

* ---------------------------------------------------------------- error checks
rcof "idxspec y gov, trim(0.4)" == 198
rcof "idxspec y gov, nknots(9)" == 198
rcof "idxint y gov2 gov1, nbins(9)" == 198
xtset, clear
rcof "idxspec y gov, fe" == 459
di as res "idxnl version 1.0 checks completed"

* ================================================================ version 1.1 extensions
use idxnl_example, clear
xtset id year

* Driscoll-Kraay (pooled)
idxspec y gov w1 w2 i.year, dk notable
assert reldif(r(tp), 0.39162203900507997) < 1e-05
assert reldif(r(se_tp), 0.14127438671548237) < 1e-05
assert reldif(r(lm_t), 0.005604744989262763) < 1e-05
assert reldif(r(lm_p), 0.4977932569969953) < 1e-05

* CD test and detectability (pooled)
idxspec y gov w1 w2 i.year, vce(cluster id) notable
assert reldif(r(cd), -3.099083371786513) < 1e-05
assert reldif(r(mds), 5.984939665933382) < 1e-05
assert r(n_beyond) == 51

* Driscoll-Kraay (fe)
idxspec y gov w1 w2 i.year, fe dk notable
assert reldif(r(tp), 0.1788015071811124) < 1e-05
assert reldif(r(se_tp), 0.3377096690531492) < 1e-05
assert reldif(r(lm_t), 0.48055466933655583) < 1e-05
assert reldif(r(lm_p), 0.31815989475349404) < 1e-05

* CD test and detectability (fe)
idxspec y gov w1 w2 i.year, fe vce(cluster id) notable
assert reldif(r(cd), -3.0948563712194064) < 1e-05
assert reldif(r(mds), 2.254214268950537) < 1e-05
assert r(n_beyond) == 100

* instrumental variables with a second lag of the index as instrument
generate double gov_l2 = L2.gov
idxspec y gov w1 w2 i.year, iv(gov_l2) vce(cluster id) notable
assert reldif(r(F_first), 9163.990418671812) < 0.0001
assert reldif(r(b1), 0.5585225407367294) < 0.0001
assert reldif(r(b2), -0.6041404817472901) < 0.0001
assert reldif(r(lm_t), -0.08165200109915069) < 0.0001
idxspec y gov w1 w2 i.year, fe iv(gov_l2) vce(cluster id) notable
assert reldif(r(F_first), 51.73470834854411) < 0.0001
assert reldif(r(b1), 0.7811732030002516) < 0.0001
assert reldif(r(b2), -0.6862936398324635) < 0.0001
assert reldif(r(lm_t), -0.08198982867478138) < 0.0001

* percentile-rank (ordinal) protocol
idxspec y gov w1 w2 i.year, rank vce(cluster id) notable
assert reldif(r(tp), 80.71142164464494) < 1e-05
assert reldif(r(lm_t), 0.38039114395380125) < 1e-05

* SIMEX (simulation-based: check that it runs and returns finite results)
set seed 20261101
idxspec y gov w1 w2 i.year, fe vce(cluster id) simex(0.10) pseudo(10) breps(20) notable
assert r(simex_b2) < . & r(simex_se2) < .
assert abs(r(simex_b2)) >= abs(r(naive_b2))*0.5

* Driscoll-Kraay in idxint
idxint y gov2 gov1 w1 w2 i.year, fe dk notable
assert r(b_xz_A) < .
rcof "idxspec y gov w1 w2, dk iv(gov_l2)" == 198
di as res "idxnl version 1.1 extensions certified"

* ================================================================ version 1.2: CCE and two-way clustering
use idxnl_example, clear
xtset id year
idxspec y gov w1 w2 i.year, fe cce vce(cluster id) notable
assert reldif(r(tp), 0.5895330258741819) < 1e-05
assert reldif(r(se_tp), 1.118329465040852) < 1e-05
assert reldif(r(lm_t), -0.21251511107630286) < 1e-05
assert reldif(r(p_quad), 0.3741708751385544) < 1e-05
assert reldif(r(cd), -3.0855868633380323) < 1e-05
idxspec y gov w1 w2 i.year, twoway notable
assert reldif(r(tp), 0.39162203900507997) < 1e-05
assert reldif(r(se_tp), 0.6296763590255229) < 1e-05
assert reldif(r(lm_t), 0.0012576167839086943) < 1e-05
assert reldif(r(lm_p), 0.4995048389234179) < 1e-05
idxspec y gov w1 w2 i.year, fe twoway notable
assert reldif(r(tp), 0.1788015071811124) < 1e-05
assert reldif(r(se_tp), 0.2779170988782889) < 1e-05
assert reldif(r(lm_t), 0.6110186711324671) < 1e-05
assert reldif(r(lm_p), 0.27421408187423446) < 1e-05
idxint y gov2 gov1 w1 w2 i.year, fe cce vce(cluster id) notable
assert r(b_xz_A) < .
rcof "idxspec y gov w1 w2, cce" == 198
rcof "idxspec y gov w1 w2, dk twoway" == 198
di as res "idxnl version 1.2 extensions certified"
