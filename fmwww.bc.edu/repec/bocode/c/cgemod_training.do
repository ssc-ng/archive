* cgemod training course: applied CGE analysis in Stata
* Six modules with exercises. Each module can be run on its own after module 1.
* The data are the example files distributed with cgemod.
* Run from the folder that contains the package files.
clear all
set more off
version 15

* ===========================================================================
* Module 1. The social accounting matrix
* ---------------------------------------------------------------------------
* Aim: read a SAM, check its identities, find and repair imbalances.
* ===========================================================================
cgemod samimport using cgemod_sam_ext.csv, name(EXT)
* The roles table lists how every account will be treated. Check it before going on.
cgemod samcheck, sam(EXT) top(5)
* GDP from the income side (value added plus net indirect taxes) and from the expenditure side
display "GDP (income) = " r(gdp_income) "   GDP (expenditure) = " r(gdp_exp)

* Exercise 1.1  Introduce a data error and see how the audit reports it.
matrix ERR = EXT
matrix ERR[rownumb(ERR, "C_AGR"), colnumb(ERR, "HH_RUR")] = ERR[rownumb(ERR, "C_AGR"), colnumb(ERR, "HH_RUR")] + 15
cgemod samcheck, sam(ERR)
* Exercise 1.2  Repair it with cross-entropy, keeping the government and rest-of-world accounts fixed,
* and compare with plain RAS. Which cells move most under each method?
cgemod sambalance, sam(ERR) method(gras) fixaccounts(GOV ROW) name(ERR_ce)
cgemod sambalance, sam(ERR) method(ras) name(ERR_ras)
cgemod sammonitor, sam(ERR_ce) benchmark(EXT) threshold(10)

* ===========================================================================
* Module 2. Calibration and model checks
* ---------------------------------------------------------------------------
* Aim: calibrate the model, read the benchmark structure, verify that the model is sound.
* ===========================================================================
cgemod calibrate, sam(EXT) sigmava(0.8) sigmaq(2) omega(2)
cgemod describe
cgemod check
cgemod validate
* Exercise 2.1  Why must a model reproduce the benchmark exactly before any simulation?
* Exercise 2.2  Calibrate with frisch(-2) and incelas(0.8 C_SER=1.3). How do the LES parameters change?
cgemod calibrate, sam(EXT) frisch(-2) incelas(0.8 C_SER=1.3) notable
cgemod describe

* ===========================================================================
* Module 3. Trade policy and closures
* ---------------------------------------------------------------------------
* Aim: understand how macro closures shape the results of the same shock.
* ===========================================================================
cgemod calibrate, sam(EXT) notable
cgemod scenario drop _all
cgemod scenario define flex, tm(*0) description("Flexible exchange rate, savings-driven investment")
cgemod scenario define fixer, tm(*0) closure(exchange(fixed)) description("Fixed exchange rate")
cgemod scenario define invdr, tm(*0) closure(siclosure(investment)) description("Investment-driven")
cgemod scenario define govfix, tm(*0) closure(gsav(fixed) fiscal(salestax)) description("Lost tariff revenue replaced by sales taxes")
cgemod scenario run
cgemod scenario graph, indicators(RGDP RCONS RINV REXP RIMP)
* Exercise 3.1  Under which closure do households gain most? Explain through the exchange rate and investment.
* Exercise 3.2  Repeat with sigmaq(4) omega(4). Do the rankings of the closures change?
cgemod calibrate, sam(EXT) sigmaq(4) omega(4) notable
cgemod scenario run, notable
cgemod scenario table
* Exercise 3.3  How robust are the welfare results to the trade elasticities?
cgemod calibrate, sam(EXT) notable
cgemod ssa, tm(*0) elasticities(sigmaq omega) range(0.5)

* ===========================================================================
* Module 4. Labour markets, climate policy and fiscal recycling
* ---------------------------------------------------------------------------
* Aim: use the policy modules: wage curve, carbon tax with revenue recycling.
* ===========================================================================
cgemod calibrate, sam(EXT) wagecurve(LAB) urate(LAB=0.12) elasw(0.1) emissions(C_OIL=50) pemissions(A_IND=10) notable
cgemod sim, ctax(0.2) title(Carbon tax, revenue saved)
cgemod calibrate, sam(EXT) wagecurve(LAB) urate(LAB=0.12) elasw(0.1) emissions(C_OIL=50) pemissions(A_IND=10) ///
    gsav(fixed) fiscal(dirtax) notable
cgemod sim, ctax(0.2) title(Carbon tax, revenue returned through lower direct taxes)
* Exercise 4.1  Compare emissions, unemployment and household EV in the two runs. Is there a double dividend?
* Exercise 4.2  Recycle the revenue through transfers (fiscal(transfers)). Which household gains most?

* ===========================================================================
* Module 5. Growth paths, public investment and the SDGs
* ---------------------------------------------------------------------------
* Aim: build a calibrated baseline and analyse a public investment programme over time.
* ===========================================================================
cgemod calibrate, sam(EXT) notable
cgemod dynamic, periods(10) labor(LAB) capital(CAP) lgrowth(LAB=0.025) gdpgrowth(0.05)       ///
    popgrowth(HH_RUR=0.03 HH_URB=0.04) ggrowth(0.04) pubshare(0.3) pubelas(0.1)               ///
    educom(C_SER) edulabor(LAB) eduelas(0.2) debt0(100) pubinv(0.01)
matrix D = r(deviation)
matrix list D, format(%9.3f)
* Exercise 5.1  Plot real GDP and debt/GDP deviations over time. When does the programme pay for itself?
* Exercise 5.2  Finance the same programme with higher direct taxes: add gsav(fixed) fiscal(dirtax) to
*               cgemod calibrate and rerun. How do crowding out and growth change?

* ===========================================================================
* Module 6. Poverty and distribution
* ---------------------------------------------------------------------------
* Aim: link the model to a household survey (top-down microsimulation).
* ===========================================================================
use cgemod_survey, clear
cgemod poverty, group(group) welfare(pcexp) weight(weight) hhsize(hhsize) line(167.8) dynamic
cgemod calibrate, sam(EXT) notable
cgemod scenario drop _all
cgemod scenario define free, tm(*0)
cgemod scenario define oil, pwm(C_OIL*1.3)
cgemod scenario define vat, tq(+0.02) closure(gsav(fixed) fiscal(transfers))
cgemod scenario run, poverty(group(group) welfare(pcexp) weight(weight) hhsize(hhsize) line(167.8) method(ev))
cgemod scenario export using training_dashboard.html, replace title(Poverty effects of three policies)
* Exercise 6.1  Repeat with method(income) and sources(). Why do the two methods differ?
* Exercise 6.2  Which scenario is most pro-poor? Use the change in the poverty gap, not only the headcount.
