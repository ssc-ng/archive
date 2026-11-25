* cgemod certification script, version 2.1.0
* Compares cgemod results with an independent reference implementation of the same model.
* Run from the folder that contains the package files.
clear all
set more off
version 15
which cgemod

capture program drop _cert
program define _cert
    args got want
    if abs(`got' - `want') > 1e-6*max(1, abs(`want')) {
        di as err "certification failed: got " %20.12g `got' ", expected " %20.12g `want'
        exit 9
    }
end

* ---- SAM import, balance check and RAS balancing
use cgemod_sam3, clear
cgemod sam a_agr-tax_dir, label(account) name(SAM3)
assert r(accounts) == 18
assert r(maxdiff) < 1e-9
matrix BAD = SAM3
matrix BAD[4, 9] = BAD[4, 9] + 3
cgemod sam, matrix(BAD) name(BALD) balance nolist
assert r(converged) == 1
assert r(maxdiff) < 1e-8*r(total)
assert r(maxdiff_before) > 2.9

* macro rows: 1 RGDP 3 RABS 4 RCONS 5 RINV 7 REXP 8 RIMP 9 EXR 13 FSAV 14 GSAV

* ---- SAM workflow: audit, GRAS balancing, monitoring, logging, export
use cgemod_sam3, clear
cgemod sam a_agr-tax_dir, label(account) name(SAM3) nolist
cgemod samcheck, sam(SAM3) activities(A_AGR A_IND A_SER) commodities(C_AGR C_IND C_SER) factors(LAB CAP) households(HH_RUR HH_URB) government(GOV) row(ROW) savinv(S_I) taxes(TAX_ACT TAX_SAL TAX_TAR TAX_EXP TAX_DIR)
assert r(maxgap) < 1e-9
assert abs(r(gdp_income) - r(gdp_exp)) < 1e-9
* perturbed SAM with a negative government saving
matrix Q = SAM3
matrix Q[4, 9] = Q[4, 9] + 3
matrix Q[12, 8] = Q[12, 8] + 2
matrix Q[13, 11] = -4
matrix Q[11, 13] = 0
tempfile lg cmp
* the audit log is lg.dta, which Stata does not erase with the tempfile; clear it so reruns start fresh
capture erase `"`lg'.dta"'
cgemod sambalance, sam(Q) name(QG) log(`lg'.dta) compare(`cmp', replace)
assert r(converged) == 1 & r(imb_after) < 1e-6 & r(signflips) == 0
_cert QG[13,11] -2.869475700228022
_cert QG[4,9] 46.855935218039114
mata: st_numscalar("cert_tot", sum(st_matrix("QG")))
_cert scalar(cert_tot) 2106.723965472058
* locked cells, a low-reliability cell and a control total
matrix FX = J(18, 18, 0)
matrix FX[18, 9] = 1
matrix FX[11, 18] = 1
matrix WT = J(18, 18, 1)
matrix WT[4, 9] = 0.2
cgemod sambalance, sam(Q) name(QC) fix(FX) weights(WT) totals(ROW=112) log(`lg'.dta) notable
assert r(converged) == 1 & r(fixed) == 2 & r(targets) == 1
assert QC[18,9] == Q[18,9] & QC[11,18] == Q[11,18]
_cert QC[4,9] 45.43020445430143
_cert QC[13,11] -2.8080732960872257
mata: st_numscalar("cert_tot", sum(st_matrix("QC")))
_cert scalar(cert_tot) 2111.363177239564
* RAS moves the negative cell and therefore changes signs
cgemod sambalance, sam(Q) name(QR) method(ras) notable
assert r(converged) == 1 & r(signflips) > 0
* monitoring
cgemod sammonitor, sam(SAM3) benchmark(SAM3)
assert r(alerts) == 0 & "`r(status)'" == "OK"
cgemod sammonitor, sam(QG) benchmark(SAM3) threshold(10) log(`lg'.dta)
assert r(alerts) > 0 & r(signflips) > 0
* audit log and comparison data
preserve
use `lg'.dta, clear
assert _N == 3
use `cmp', clear
assert _N > 0
restore
* export
tempfile xc xg
cgemod samexport, sam(QG) csv(`xc'.csv) gams(`xg'.inc) replace
confirm file `xc'.csv
confirm file `xg'.inc

* ---- S1: tariff removal, default closures
cgemod calibrate, sam(SAM3) activities(A_AGR A_IND A_SER) commodities(C_AGR C_IND C_SER) factors(LAB CAP) households(HH_RUR HH_URB) government(GOV) row(ROW) savinv(S_I) taxes(TAX_ACT TAX_SAL TAX_DIR) tariff(TAX_TAR) exptax(TAX_EXP) notable
assert r(bench_resid) < 1e-10
cgemod check
assert r(failed) == 0
cgemod sim, tm(*0) notable
matrix M = r(macro)
matrix X = r(sector)
matrix H = r(household)
_cert M[1,3] -9.835357063225914e-05
_cert M[3,3] 0.21360503128038388
_cert M[4,3] 3.729262581142523
_cert M[5,3] -10.800344906095294
_cert M[7,3] 9.654547344574315
_cert M[8,3] 8.130145135287602
_cert M[9,3] 7.047866705965289
_cert M[13,3] 0.0
_cert M[14,3] -11.163200002729695
_cert X[1,1] 0.390840162640016
_cert X[2,1] -1.53397792314921
_cert X[3,1] 0.6967059293061961
_cert H[1,3] 4.0933902120075345
_cert H[2,3] 4.722485376296788
assert abs(r(walras)) < 1e-5

* ---- S2: fixed exchange rate
cgemod calibrate, sam(SAM3) activities(A_AGR A_IND A_SER) commodities(C_AGR C_IND C_SER) factors(LAB CAP) households(HH_RUR HH_URB) government(GOV) row(ROW) savinv(S_I) taxes(TAX_ACT TAX_SAL TAX_DIR) tariff(TAX_TAR) exptax(TAX_EXP) exchange(fixed) notable
cgemod check, notable
assert r(failed) == 0
cgemod sim, tm(*0) notable
matrix M = r(macro)
matrix X = r(sector)
matrix H = r(household)
_cert M[1,3] -2.088593376026182e-06
_cert M[3,3] 11.321254756532962
_cert M[4,3] 4.182843152397786
_cert M[5,3] 41.521317418010504
_cert M[7,3] -5.742968648113034
_cert M[8,3] 34.50259253371719
_cert M[9,3] 0.0
_cert M[13,3] 37.3718378255218
_cert M[14,3] -9.95514565626577
_cert X[1,1] -4.514318793717997
_cert X[2,1] -0.413239666797649
_cert X[3,1] 4.037420217813326
_cert H[1,3] 3.9616417299742324
_cert H[2,3] 5.912281749197916
assert abs(r(walras)) < 1e-5

* ---- S3: investment-driven, fixed government savings, specific capital, LES
cgemod calibrate, sam(SAM3) activities(A_AGR A_IND A_SER) commodities(C_AGR C_IND C_SER) factors(LAB CAP) households(HH_RUR HH_URB) government(GOV) row(ROW) savinv(S_I) taxes(TAX_ACT TAX_SAL TAX_DIR) tariff(TAX_TAR) exptax(TAX_EXP) siclosure(investment) gsav(fixed) specific(CAP) frisch(-2) incelas(C_AGR=0.6 C_IND=1.1 C_SER=1.3) notable
cgemod check, notable
assert r(failed) == 0
cgemod sim, pwm(C_IND*1.2) notable
matrix M = r(macro)
matrix X = r(sector)
matrix H = r(household)
_cert M[1,3] -0.029973898669977128
_cert M[3,3] -3.442611639483839
_cert M[4,3] -5.250705987952243
_cert M[5,3] 0.0
_cert M[7,3] -2.648643667343431
_cert M[8,3] -12.51406066324745
_cert M[9,3] -2.8565459137234517
_cert M[13,3] 0.0
_cert M[14,3] -1.0800249583553523e-11
_cert X[1,1] -0.6207576163116291
_cert X[2,1] 3.3156481887052225
_cert X[3,1] -1.7680688588853966
_cert H[1,3] -5.1610703128718
_cert H[2,3] -7.449216923452212
assert abs(r(walras)) < 1e-5

* ---- S4: unemployed labour, productivity shock
cgemod calibrate, sam(SAM3) activities(A_AGR A_IND A_SER) commodities(C_AGR C_IND C_SER) factors(LAB CAP) households(HH_RUR HH_URB) government(GOV) row(ROW) savinv(S_I) taxes(TAX_ACT TAX_SAL TAX_DIR) tariff(TAX_TAR) exptax(TAX_EXP) unemployed(LAB) notable
cgemod check, notable
assert r(failed) == 0
cgemod sim, tfp(A_AGR*1.1) notable
matrix M = r(macro)
matrix X = r(sector)
matrix H = r(household)
_cert M[1,3] 7.2125936886389574
_cert M[3,3] 6.794534841670985
_cert M[4,3] 7.349362362260159
_cert M[5,3] 9.563572070781978
_cert M[7,3] 9.369181327254484
_cert M[8,3] 7.889836906453773
_cert M[9,3] 0.27922366352912675
_cert M[13,3] 0.0
_cert M[14,3] 4.827632293649515
_cert X[1,1] 14.602742188507367
_cert X[2,1] 3.3398722639638834
_cert X[3,1] 3.635950888532058
_cert H[1,3] 7.397960732212866
_cert H[2,3] 9.95440222543317
assert abs(r(walras)) < 1e-5

* ---- recursive dynamics
cgemod calibrate, sam(SAM3) activities(A_AGR A_IND A_SER) commodities(C_AGR C_IND C_SER) factors(LAB CAP) households(HH_RUR HH_URB) government(GOV) row(ROW) savinv(S_I) taxes(TAX_ACT TAX_SAL TAX_DIR) tariff(TAX_TAR) exptax(TAX_EXP) notable
cgemod dynamic, periods(5) labor(LAB) capital(CAP) lgrowth(0.03) tfpgrowth(0.01) start(2) tm(*0) notable
matrix B = r(baseline)
matrix D = r(deviation)
_cert B[1,2] 300.0
_cert B[2,2] 312.5442595071417
_cert B[3,2] 326.04835384408307
_cert B[4,2] 340.57124108555143
_cert B[5,2] 356.17323913275635
_cert B[6,2] 372.9159705272957
_cert D[1,2] 0.0
_cert D[2,2] 0.0
_cert D[3,2] -0.0006659266655217877
_cert D[4,2] -0.3964398100886002
_cert D[5,2] -0.7833597356053823
_cert D[6,2] -1.1590622090643543

* ---- systematic sensitivity analysis (Stroud quadrature, 6 points)
cgemod ssa, tm(*0) elasticities(sigmava sigmaq omega) range(0.5) notable
matrix Q = r(ssa)
assert r(ndraws) == 6 & r(failed) == 0
_cert Q[1,2] -0.0001011090913198102
_cert Q[1,3] 3.970484693181357e-05
cgemod ssa, tm(*0) method(montecarlo) reps(50) seed(12345) bysector notable
assert r(failed) == 0

* ---- shock syntax and saving
tempfile s
cgemod sim, tm(C_IND=0.05 C_AGR*0.5) ty(+0.01) gadj(1.05) saving(`s', replace) notable
preserve
use `s', clear
assert _N == 3
restore

* ---- elasticity estimation: time series
use cgemod_tsdata, clear
tsset year
cgemod elast ln_qm_qd ln_pd_pm ln_gdp, type(armington) sector(C_IND) store(SIGQ) reps(199)
assert r(bg_p) < 0.05
assert inlist(r(remedy), "newey")
assert SIGQ[1,1] == r(elast_used)
cgemod elast ln_qm_qd ln_pd_pm ln_gdp, type(armington) dynamic remedy(newey) nosupf
assert r(elast_lr) < .
cgemod elast ln_qm_qd ln_pd_pm ln_gdp, remedy(break) reps(199)
assert r(elast_post) < .

* ---- elasticity estimation: panel
use cgemod_paneldata, clear
xtset sector year
cgemod elast ln_qm_qd ln_pd_pm, type(armington)
assert r(cd_p) < 0.05
assert r(remedy) == "dk"
cgemod elast ln_qm_qd ln_pd_pm, type(armington) remedy(cce)
cgemod elast ln_qm_qd ln_pd_pm, type(armington) remedy(cluster)

* ---- estimated elasticity feeds the model
use cgemod_sam3, clear
cgemod sam a_agr-tax_dir, label(account) name(SAM3) nolist
cgemod calibrate, sam(SAM3) activities(A_AGR A_IND A_SER) commodities(C_AGR C_IND C_SER) factors(LAB CAP) households(HH_RUR HH_URB) government(GOV) row(ROW) savinv(S_I) taxes(TAX_ACT TAX_SAL TAX_DIR) tariff(TAX_TAR) exptax(TAX_EXP) sigmaq(SIGQ) notable
cgemod check, notable
assert r(failed) == 0

* ---- Tier 1: extended SAM structure, SAM import with role detection, replication harness
cgemod samimport using cgemod_sam_ext.csv, name(EXT)
assert r(accounts) == 21
assert "`r(enterprises)'" == "ENT" & "`r(margins)'" == "TRC" & "`r(tariff)'" == "TAX_TAR" & "`r(unassigned)'" == ""
cgemod samcheck, sam(EXT) activities(`r(activities)') commodities(`r(commodities)') factors(`r(factors)') households(`r(households)') enterprises(`r(enterprises)') government(GOV) row(ROW) savinv(S_I) taxes(`r(taxes)') margins(TRC)
assert abs(r(gdp_income) - r(gdp_exp)) < 1e-6 & r(maxgap) < 1e-6
cgemod calibrate, sam(EXT) notable
assert r(activities) == 3 & r(commodities) == 4 & r(enterprises) == 1
cgemod check, notable
assert r(failed) == 0
cgemod sim, tm(*0) notable
cgemod compare using cgemod_ext_reference.csv, value(default) tolerance(1e-4)
assert "`r(status)'" == "REPLICATED" & r(compared) == 34
cgemod calibrate, sam(EXT) exchange(fixed) notable
cgemod check, notable
assert r(failed) == 0
cgemod sim, tm(*0) notable
cgemod compare using cgemod_ext_reference.csv, value(fixer) tolerance(1e-4)
assert "`r(status)'" == "REPLICATED"
cgemod calibrate, sam(EXT) siclosure(investment) gsav(fixed) specific(CAP) frisch(-2) notable
cgemod check, notable
assert r(failed) == 0
cgemod sim, tm(*0) notable
cgemod compare using cgemod_ext_reference.csv, value(inv) tolerance(1e-4)
assert "`r(status)'" == "REPLICATED"
cgemod calibrate, sam(EXT) unemployed(LAB) notable
cgemod sim, tm(*0) notable
cgemod compare using cgemod_ext_reference.csv, value(unemp) tolerance(1e-4)
assert "`r(status)'" == "REPLICATED"
* the same SAM loaded from Stata data gives the same model
use cgemod_sam_ext, clear
cgemod sam a_agr-tax_dir, label(account) name(EXT2) nolist
cgemod calibrate, sam(EXT2) activities(A_AGR A_IND A_SER) commodities(C_AGR C_IND C_SER C_OIL) factors(LAB CAP) households(HH_RUR HH_URB) enterprises(ENT) government(GOV) row(ROW) savinv(S_I) margins(TRC) taxes(TAX_ACT TAX_SAL TAX_DIR) tariff(TAX_TAR) exptax(TAX_EXP) notable
cgemod sim, tm(*0) notable
cgemod compare using cgemod_ext_reference.csv, value(default) tolerance(1e-4)
assert "`r(status)'" == "REPLICATED"
cgemod ssa, tm(*0) elasticities(sigmava sigmaq omega sigmax) range(0.3) notable
assert r(failed) == 0
cgemod dynamic, periods(3) labor(LAB) capital(CAP) lgrowth(0.03) start(1) tm(*0) notable

* ---- 2.1.0: GAMS include import and mapping-file aggregation (values from the Python implementation)
cgemod samimport using cgemod_sam_ext.csv, name(EXT) nolist
cgemod samexport, sam(EXT) gams(__cgemod_ext.inc) replace
cgemod samimport using __cgemod_ext.inc, name(EXTG) nolist
assert r(accounts) == 21 & "`r(unassigned)'" == ""
cgemod calibrate, sam(EXTG) notable
cgemod sim, tm(*0) notable
cgemod compare using cgemod_ext_reference.csv, value(default) tolerance(1e-4)
assert "`r(status)'" == "REPLICATED"
erase __cgemod_ext.inc
tempname fh
file open `fh' using __cgemod_map.csv, write replace
file write `fh' "source,destination" _n "A_IND,A_NAG" _n "A_SER,A_NAG" _n "C_IND,C_NAG" _n "C_SER,C_NAG" _n
file close `fh'
cgemod samimport using cgemod_sam_ext.csv, name(AGG) map(__cgemod_map.csv) nolist
assert r(accounts) == 19 & r(maxdiff) < 1e-6
assert "`r(activities)'" == "A_AGR A_NAG" & "`r(commodities)'" == "C_AGR C_NAG C_OIL"
erase __cgemod_map.csv
cgemod calibrate, sam(AGG) notable
cgemod sim, tm(*0) notable
matrix M = r(macro)
local v = M[rownumb(M,"RGDP"),3]
_cert `v' -3.276611052482892e-05
local v = M[rownumb(M,"RCONS"),3]
_cert `v' 4.180486702094188
local v = M[rownumb(M,"EXR"),3]
_cert `v' 7.976522602383862
local v = M[rownumb(M,"RIMP"),3]
_cert `v' 9.388603792199458
matrix X = r(sector)
local v = X[rownumb(X,"A_NAG"),1]
_cert `v' -0.713395417856133
matrix H = r(household)
local v = H[rownumb(H,"HH_URB"),3]
_cert `v' 5.372926982671629

* ---- Tier 2: wage curve, carbon tax, fiscal closures and rules, quotas, price caps, debt, poverty
cgemod samimport using cgemod_sam_ext.csv, name(EXT) nolist
cgemod calibrate, sam(EXT) wagecurve(LAB) urate(0.15) notable
cgemod check, notable
assert r(failed) == 0
cgemod sim, tm(*0) notable
cgemod compare using cgemod_tier2_reference.csv, value(wcurve) tolerance(1e-4)
assert "`r(status)'" == "REPLICATED"
cgemod calibrate, sam(EXT) emissions(C_OIL=50) pemissions(A_IND=10) notable
cgemod check, notable
assert r(failed) == 0
cgemod sim, ctax(0.2) notable
cgemod compare using cgemod_tier2_reference.csv, value(carbon) tolerance(1e-4)
assert "`r(status)'" == "REPLICATED"
cgemod calibrate, sam(EXT) emissions(C_OIL=50) pemissions(A_IND=10) gsav(fixed) fiscal(transfers) notable
cgemod check, notable
assert r(failed) == 0
cgemod sim, ctax(0.2) notable
cgemod compare using cgemod_tier2_reference.csv, value(carbon_tr) tolerance(1e-4)
assert "`r(status)'" == "REPLICATED"
cgemod calibrate, sam(EXT) gsav(fixed) fiscal(spending) notable
cgemod sim, gsavshare(-0.02) notable
cgemod compare using cgemod_tier2_reference.csv, value(rule) tolerance(1e-4)
assert "`r(status)'" == "REPLICATED"
cgemod calibrate, sam(EXT) notable
cgemod sim, tm(*0) mquota(C_IND=0.95) notable
cgemod compare using cgemod_tier2_reference.csv, value(mquota) tolerance(1e-4)
assert "`r(status)'" == "REPLICATED"
cgemod sim, tm(*0) xquota(C_AGR=0.98) notable
cgemod compare using cgemod_tier2_reference.csv, value(xquota) tolerance(1e-4)
assert "`r(status)'" == "REPLICATED"
cgemod sim, pwm(C_OIL*1.5) pcap(C_OIL=1.05) notable
cgemod compare using cgemod_tier2_reference.csv, value(pcap) tolerance(1e-4)
assert "`r(status)'" == "REPLICATED"
cgemod dynamic, periods(3) labor(LAB) capital(CAP) debt0(100) tm(*0) notable
matrix B = r(baseline)
assert B[1, colnumb(B, "DEBT")] == 100
use cgemod_sam3, clear
cgemod sam a_agr-tax_dir, label(account) name(SAM3) nolist
cgemod calibrate, sam(SAM3) activities(A_AGR A_IND A_SER) commodities(C_AGR C_IND C_SER) factors(LAB CAP) households(HH_RUR HH_URB) government(GOV) row(ROW) savinv(S_I) taxes(TAX_ACT TAX_SAL TAX_DIR) tariff(TAX_TAR) exptax(TAX_EXP) notable
cgemod sim, tm(*0) notable
use cgemod_survey, clear
cgemod poverty, group(group) welfare(pcexp) weight(weight) hhsize(hhsize) line(167.81527955306038) by(region) generate(w_ev)
matrix P = r(poverty)
_cert P[1,1] 39.98269285974238
_cert P[1,2] 37.59891860124883
_cert P[2,1] 13.747252023170466
_cert P[2,2] 12.757910386054009
_cert P[3,1] 6.530076019365451
_cert P[3,2] 5.984778534568494
_cert P[4,1] 35.755236472902766
_cert P[4,2] 35.68519678563739
_cert P[5,1] 242.896875599712
_cert P[5,2] 251.95923828993077
cgemod poverty, group(group) welfare(pcexp) weight(weight) hhsize(hhsize) line(167.81527955306038) method(real) notable
matrix P = r(poverty)
_cert P[1,2] 37.59891860124883
_cert P[2,2] 12.763207272622694
_cert P[3,2] 5.987613736151334
_cert P[4,2] 35.684315946458
_cert P[5,2] 251.89899302623047
cgemod poverty, group(group) welfare(pcexp) weight(weight) hhsize(hhsize) line(167.81527955306038) method(income) sources(inc_lab=LAB inc_cap=CAP) transfers(inc_trans) notable
matrix P = r(poverty)
_cert P[1,2] 37.60647465003696
_cert P[2,2] 12.767987259809196
_cert P[3,2] 5.991187121816849
_cert P[4,2] 35.69548367907102
_cert P[5,2] 251.92070227269718

* ---- Tier 3: calibrated growth baseline, population, public capital, human capital, debt, poverty paths
* columns of r(baseline): 2 RGDP, 16 DEBT, 18 POP, 21 KG, 22 KE, 23 TFPX (3 activities, 2 factors)
cgemod samimport using cgemod_sam_ext.csv, name(EXT) nolist
cgemod calibrate, sam(EXT) notable
local dopts "periods(6) labor(LAB) capital(CAP) lgrowth(LAB=0.025) tfpgrowth(A_AGR=0.01) gdpgrowth(0.05) popgrowth(HH_RUR=0.03 HH_URB=0.04) ggrowth(0.04) fsavgrowth(0.03) pubshare(0.3) pubdep(0.05) pubelas(A_AGR=0.1 A_IND=0.15 A_SER=0.1) educom(C_SER) edulabor(LAB) eduelas(0.2) edudep(0.1) debt0(100) start(1)"
cgemod dynamic, `dopts' pubinv(0.01) notable
matrix B = r(baseline)
matrix D = r(deviation)
assert colsof(B) == 23
_cert B[1,2] 307.33276367398395
_cert B[1,23] 1.0
_cert B[1,16] 100.0
_cert B[1,18] 1.0
_cert B[1,21] 500.62267382060764
_cert B[1,22] 443.37204214340017
_cert D[1,2] 0.0
_cert D[1,16] 0.0
_cert B[2,2] 322.6994018576138
_cert B[2,23] 1.0136343991599461
_cert B[2,16] 82.0602504739189
_cert B[2,18] 1.0353448864387755
_cert B[2,21] 500.62267382060764
_cert B[2,22] 443.37204214340017
_cert D[2,2] 0.06951979430034338
_cert D[2,16] 3.0112924501329417
_cert B[3,2] 338.834371950505
_cert B[3,23] 1.0262006653699254
_cert B[3,16] 62.56347888609406
_cert B[3,18] 1.0719639149282651
_cert B[3,21] 501.97624530700085
_cert B[3,22] 445.14553031197374
_cert D[3,2] -0.017954767948125117
_cert D[3,16] 6.103088329388697
_cert B[4,2] 355.77609054804
_cert B[4,23] 1.037730686619199
_cert B[4,16] 41.4083380130254
_cert B[4,18] 1.1099038615482923
_cert B[4,21] 504.6873213019906
_cert B[4,22] 448.58609735900654
_cert D[4,2] -0.09722873975139823
_cert D[4,16] 9.275100075684477
_cert B[5,2] 373.5648950754513
_cert B[5,23] 1.0482627968911222
_cert B[5,16] 18.487604695184174
_cert B[5,18] 1.149213247733808
_cert B[5,21] 508.763367764241
_cert B[5,22] 453.6008125044653
_cert D[5,2] -0.16885566299315036
_cert D[5,16] 12.527017349684698
_cert B[6,2] 392.24313982923275
_cert B[6,23] 1.0578404189344859
_cert B[6,16] -6.312134116610508
_cert B[6,18] 1.1899424063184514
_cert B[6,21] 514.2153940232621
_cert B[6,22] 460.10898913063255
_cert D[6,2] -0.2333910454812127
_cert D[6,16] 15.858543804589914
_cert B[7,2] 411.8552968207018
_cert B[7,23] 1.0665107775526903
_cert B[7,16] -33.1108132658414
_cert B[7,18] 1.2321435501067395
_cert B[7,21] 521.0579719900242
_cert B[7,22] 468.0410784092476
_cert D[7,2] -0.29138159673012254
_cert D[7,16] 19.26942853320341
preserve
use cgemod_survey, clear
cgemod poverty, group(group) welfare(pcexp) weight(weight) hhsize(hhsize) line(167.81527955306038) dynamic
matrix V = r(path)
_cert V[1,2] 39.98269285974238
_cert V[1,3] 39.98269285974238
_cert V[2,2] 39.13536608269499
_cert V[2,3] 39.11513149596265
_cert V[3,2] 38.045557659585135
_cert V[3,3] 38.106684773172496
_cert V[4,2] 37.4783208128237
_cert V[4,3] 37.4783208128237
_cert V[5,2] 36.86922703114393
_cert V[5,3] 36.8960239330946
_cert V[6,2] 36.40399685704668
_cert V[6,3] 36.57879708182336
_cert V[7,2] 35.36108337830147
_cert V[7,3] 35.675547687205714
restore
cgemod dynamic, `dopts' qg(C_SER*1.1) notable
matrix D = r(deviation)
_cert D[1,2] 0.0
_cert D[2,2] -0.003100899193653195
_cert D[3,2] -0.15114725090819014
_cert D[4,2] -0.29860625338605784
_cert D[5,2] -0.44555859217195737
_cert D[6,2] -0.5919806287806972
_cert D[7,2] -0.7377600267390094

* ---- Tier 4: synthetic SAMs, Broyden solver, scenario manager, validation suite
cgemod samgen, sectors(10) households(3) seed(1) name(G10) nolist
assert r(accounts) == 31
_cert r(total) 6100.865895125
local v = G10[rownumb(G10, "S_I"), colnumb(G10, "ROW")]
_cert `v' 80.21570000000006
local v = G10[rownumb(G10, "S_I"), colnumb(G10, "GOV")]
_cert `v' 28.474198725000093
local v = G10[rownumb(G10, "S_I"), colnumb(G10, "HH_2")]
_cert `v' 65.12558470685627
local v = G10[rownumb(G10, "C_3"), colnumb(G10, "A_5")]
_cert `v' 1.8895468841001752
foreach solver in newton broyden {
    cgemod calibrate, sam(G10) solver(`solver') notable
    cgemod sim, tm(*0) notable
    matrix M = r(macro)
    matrix A = r(sector)
    matrix H = r(household)
    _cert M[1,3] -9.266902538662691e-05
    _cert M[9,3] 6.390550097748604
    _cert A[1,1] 2.036459814373681
    _cert H[1,3] 4.652899734287047
    _cert H[2,3] 6.936172063674945
    _cert H[3,3] 6.618682682826972
}
cgemod calibrate, sam(G10) notable
cgemod scenario drop _all
cgemod scenario define free, tm(*0) description("All tariffs removed")
cgemod scenario define tfp, tfp(*1.05)
cgemod scenario define free_fix, tm(*0) closure(exchange(fixed))
cgemod scenario run, notable
assert "`r(failed)'" == ""
matrix S = r(macro)
matrix E = r(ev)
assert colsof(S) == 3
_cert S[1,1] -9.266902538662691e-05
_cert S[9,1] 6.390550097748604
_cert E[1,1] 4.652899734287047
_cert E[2,1] 6.936172063674945
_cert E[3,1] 6.618682682826972
_cert S[1,2] 4.999999585910531
_cert S[9,2] 0.333637391335051
_cert E[1,2] 7.790731398705503
_cert E[2,2] 12.10803055532719
_cert E[3,2] 11.45367478920582
_cert S[1,3] -0.00010075811347487473
_cert S[9,3] 0.0
_cert E[1,3] 5.763556981253032
_cert E[2,3] 9.21488255582372
_cert E[3,3] 8.838219519949547
* the original closure is restored after a scenario with its own closure
cgemod sim, tm(*0) notable
matrix M = r(macro)
_cert M[9,3] 6.390550097748604
tempfile dash xl cs
cgemod scenario export using "`dash'.html", replace
confirm file "`dash'.html"
cgemod scenario export using "`xl'.xlsx", replace
confirm file "`xl'.xlsx"
cgemod scenario export using "`cs'.csv", replace
preserve
import delimited using "`cs'.csv", clear
assert _N > 0
restore
cgemod validate, notable
assert r(failed) == 0
cgemod validate, performance sizes(5 12) notable
assert r(failed) == 0
matrix P = r(performance)
assert P[1,9] < 1e-6 & P[2,9] < 1e-6
assert P[2,6] >= 1
* the model in memory is unchanged by the validation suite
cgemod sim, tm(*0) notable
matrix M = r(macro)
_cert M[1,3] -9.266902538662691e-05
cgemod samimport using cgemod_sam_ext.csv, name(EXT) nolist
cgemod calibrate, sam(EXT) notable
cgemod validate, notable
assert r(failed) == 0
cgemod calibrate, sam(EXT) exchange(fixed) notable
cgemod validate, notable
assert r(failed) == 0

di as res _n "cgemod certification completed successfully"
