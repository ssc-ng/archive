* cgemod worked example: from a SAM to policy simulations, sensitivity analysis and
* estimated elasticities. Run from the folder that contains the package files.
clear all
set more off

* 1. Load the illustrative three-sector SAM and check that it balances
use cgemod_sam3, clear
list account a_agr a_ind a_ser c_agr in 1/6, noobs
cgemod sam a_agr-tax_dir, label(account) name(SAM3)

* 1b. SAM workflow: audit identities, then update the SAM with new data
cgemod samcheck, sam(SAM3) activities(A_AGR A_IND A_SER) commodities(C_AGR C_IND C_SER) ///
    factors(LAB CAP) households(HH_RUR HH_URB) government(GOV) row(ROW) savinv(S_I)    ///
    taxes(TAX_ACT TAX_SAL TAX_TAR TAX_EXP TAX_DIR)
matrix NEW = SAM3
matrix NEW[4, 9] = NEW[4, 9] + 3      // revised rural consumption of agricultural goods
matrix NEW[13, 11] = -4               // government now dissaves
matrix NEW[11, 13] = 0
cgemod samcheck, sam(NEW)
cgemod sambalance, sam(NEW) fixaccounts(TAX_DIR) totals(ROW=110) log(samaudit) compare(sam_changes, replace)
cgemod sammonitor, sam(NEW_bal) benchmark(SAM3) threshold(20) log(samaudit)
cgemod samexport, sam(NEW_bal) prior(NEW) excel(sam_balanced.xlsx) gams(sam_balanced.inc) replace

* 2. Calibrate the standard model (default closures: flexible exchange rate,
*    flexible government savings, savings-driven investment, mobile factors)
local accounts sam(SAM3) activities(A_AGR A_IND A_SER) commodities(C_AGR C_IND C_SER) ///
    factors(LAB CAP) households(HH_RUR HH_URB) government(GOV) row(ROW) savinv(S_I)   ///
    taxes(TAX_ACT TAX_SAL TAX_DIR) tariff(TAX_TAR) exptax(TAX_EXP)
cgemod calibrate, `accounts' sigmava(0.8) sigmaq(2) omega(2)

* 3. Model diagnostics: benchmark replication, Walras' law, homogeneity,
*    Jacobian conditioning and uniqueness of the solution
cgemod check

* 4. Policy experiments
cgemod sim, tm(*0) title(Removal of all import tariffs)
matrix list r(macro)
cgemod sim, pwm(C_IND*1.2) title(20% rise in world industrial import prices)
cgemod sim, tfp(A_AGR*1.1) title(10% productivity gain in agriculture)

* 5. Alternative closures: fixed exchange rate, sector-specific capital, LES demand
cgemod calibrate, `accounts' exchange(fixed) specific(CAP) frisch(-2) ///
    incelas(C_AGR=0.6 C_IND=1.1 C_SER=1.3) notable
cgemod sim, tm(*0) title(Tariff removal under a fixed exchange rate)

* 6. Systematic sensitivity analysis of the tariff experiment
cgemod calibrate, `accounts' notable
cgemod ssa, tm(*0) elasticities(sigmava sigmaq omega) range(0.5)
cgemod ssa, tm(*0) method(montecarlo) reps(300) seed(2026) bysector distribution(triangular)

* 7. Recursive dynamics: tariffs removed from period 2 on
cgemod dynamic, periods(10) labor(LAB) capital(CAP) lgrowth(0.03) tfpgrowth(0.01) ///
    deprec(0.05) rate(0.10) start(2) tm(*0)

* 8. Estimate an Armington elasticity from time-series data, with diagnostics and remedies
use cgemod_tsdata, clear
tsset year
cgemod elast ln_qm_qd ln_pd_pm ln_gdp, type(armington) sector(C_IND) store(SIGQ)
cgemod elast ln_qm_qd ln_pd_pm ln_gdp, type(armington) dynamic remedy(newey)

* 9. Panel estimation in the presence of cross-sectional dependence
use cgemod_paneldata, clear
xtset sector year
cgemod elast ln_qm_qd ln_pd_pm, type(armington)
cgemod elast ln_qm_qd ln_pd_pm, type(armington) remedy(cce)

* 10. Use the estimated elasticity in the model
use cgemod_sam3, clear
cgemod sam a_agr-tax_dir, label(account) name(SAM3) nolist
cgemod calibrate, `accounts' sigmaq(SIGQ)
cgemod sim, tm(*0) title(Tariff removal with the estimated Armington elasticity for C_IND)

* 11. A richer SAM imported from a spreadsheet: a multi-product activity, home consumption,
*     trade margins, an enterprise account and a commodity that is only imported.
*     Account roles are detected from the names and used by calibrate.
cgemod samimport using cgemod_sam_ext.csv, name(EXT)
cgemod calibrate, sam(EXT) sigmax(4)
cgemod sim, tm(*0) title(Tariff removal, extended SAM)
* compare the results with an independent implementation of the same model
cgemod compare using cgemod_ext_reference.csv, value(default)

* 12. Tier 2: labour market, carbon tax, fiscal rules, quotas, price caps
cgemod calibrate, sam(EXT) wagecurve(LAB) urate(0.15) elasw(0.1) notable
cgemod sim, tm(*0) title(Tariff removal with a wage curve for labour)
cgemod calibrate, sam(EXT) emissions(C_OIL=50) pemissions(A_IND=10) gsav(fixed) fiscal(transfers) notable
cgemod sim, ctax(0.2) title(Carbon tax with revenue returned as transfers)
cgemod calibrate, sam(EXT) notable
cgemod sim, tm(*0) mquota(C_IND=0.95) title(Tariff removal with an import quota on industry)
cgemod sim, pwm(C_OIL*1.5) pcap(C_OIL=1.05) title(Oil price shock with a fuel price cap)
cgemod calibrate, sam(EXT) gsav(fixed) fiscal(spending) notable
cgemod sim, gsavshare(-0.02) title(Fiscal rule: deficit of 2% of GDP)
cgemod calibrate, sam(EXT) notable
cgemod dynamic, periods(10) labor(LAB) capital(CAP) lgrowth(0.03) debt0(100) tm(*0)

* 13. Poverty and inequality on a household survey
use cgemod_sam3, clear
cgemod sam a_agr-tax_dir, label(account) name(SAM3) nolist
cgemod calibrate, `accounts' notable
cgemod sim, tm(*0) notable
use cgemod_survey, clear
cgemod poverty, group(group) welfare(pcexp) weight(weight) hhsize(hhsize) line(167.8) by(region)
cgemod poverty, group(group) welfare(pcexp) weight(weight) hhsize(hhsize) line(167.8) ///
    method(income) sources(inc_lab=LAB inc_cap=CAP) transfers(inc_trans) generate(pcexp_sim)

* 14. Tier 3: calibrated growth baseline with population, public capital and human capital
cgemod samimport using cgemod_sam_ext.csv, name(EXT) nolist
cgemod calibrate, sam(EXT) notable
cgemod dynamic, periods(10) labor(LAB) capital(CAP) lgrowth(LAB=0.025) gdpgrowth(0.05)       ///
    popgrowth(HH_RUR=0.03 HH_URB=0.04) ggrowth(0.04) pubshare(0.3) pubelas(A_IND=0.15 A_AGR=0.1 A_SER=0.1) ///
    educom(C_SER) edulabor(LAB) eduelas(0.2) debt0(100) pubinv(0.01)
matrix list r(baseline), format(%9.3f)
use cgemod_survey, clear
cgemod poverty, group(group) welfare(pcexp) weight(weight) hhsize(hhsize) line(167.8) dynamic

* 15. Tier 4: scenario manager, validation suite and large synthetic SAMs
cgemod samimport using cgemod_sam_ext.csv, name(EXT) nolist
cgemod calibrate, sam(EXT) notable
cgemod scenario drop _all
cgemod scenario define free, tm(*0) description("All import tariffs removed")
cgemod scenario define free_fix, tm(*0) closure(exchange(fixed)) description("Tariffs removed, fixed exchange rate")
cgemod scenario define oil, pwm(C_OIL*1.3) description("World oil price up 30%")
cgemod scenario define vat, tq(+0.02) closure(gsav(fixed) fiscal(dirtax)) description("Sales tax up 2 points, direct taxes adjust")
use cgemod_survey, clear
cgemod scenario run, poverty(group(group) welfare(pcexp) weight(weight) hhsize(hhsize) line(167.8))
cgemod scenario graph, indicators(RGDP RCONS RINV) title(Macroeconomic effects)
cgemod scenario graph, households title(Household welfare)
cgemod scenario export using cgemod_dashboard.html, replace title(Trade and fiscal scenarios)
cgemod scenario export using cgemod_scenarios.xlsx, replace
cgemod validate
cgemod validate, performance sizes(10 25 50 100) notable
matrix list r(performance)
cgemod samgen, sectors(150) households(8) name(BIG) nolist
cgemod calibrate, sam(BIG) solver(broyden) notable
cgemod sim, tm(*0) notable
