* =====================================================================
* indsat_example.do  --  worked examples for the indsat package
* Dr Merwan Roudane  (merwanroudane920@gmail.com)  github.com/merwanroudane
* Run after:  net get indsat   (copies the example data to the working directory)
* =====================================================================
version 14.0
clear
set more off
capture log close
log using indsat_example.log, replace text

* ---------------------------------------------------------------------
* 0. Theory before data: how many false indicators to expect?
* ---------------------------------------------------------------------
indsat gauge, t(100)

* ---------------------------------------------------------------------
* 1. Simulated DGP with known truth (Castle et al. 2015 design + outlier)
*    y = 1 + 0.5 x + 3*1(t>=60) + 6*1(t=30) + e
* ---------------------------------------------------------------------
set obs 100
set seed 123
gen t = _n
tsset t
gen x = rnormal()
gen y = 1 + 0.5*x + rnormal() + 3*(t>=60) + 6*(t==30)

indsat y x, iis                       // impulses only (R gets: retains nothing at 0.001)
indsat y x, sis                       // steps: shift at 60 and the outlier as two steps
indsat y x, super tpval(0.01)         // super saturation: impulses + steps
indsat dates
indsat biascorr
indsat plot, name(sim_dash)

* the theoretical estimators: split-half IIS and m-step Huber-skip
indsat y x, iis algorithm(split) tpval(0.01) nodates
indsat y x, iis algorithm(mstep) msteps(3) tpval(0.01) nodates

* ---------------------------------------------------------------------
* 2. Coefficient breaks (MIS) and common break dates
*    slope of x jumps from 1 to 3 at t = 70
* ---------------------------------------------------------------------
clear
set obs 150
set seed 77
gen t = _n
tsset t
gen x = rnormal()
gen z = rnormal()
gen y = 1 + 1*x + 0.5*z + (t>=80)*(1.5*x - 1*z + 1) + 0.8*rnormal()
indsat y x z, mis(x z) tpval(0.01)                // separate coefficient breaks
indsat y x z, sis mis(x z) common tpval(0.01)     // one break date for all parameters
indsat path
indsat plot, name(mis_dash)

* ---------------------------------------------------------------------
* 3. Trend breaks, designed breaks and the other indicator shapes
* ---------------------------------------------------------------------
clear
set obs 120
set seed 2026
gen t = _n
tsset t
gen e = rnormal()
gen d = 0
replace d = -5        if t==40
replace d = -5*0.503  if t==41
replace d = -5*0.203  if t==42
gen y = 2 + d + 0.15*(t-89)*(t>=90) + e
indsat y, tis tpval(0.01)                        // broken trend at 90
indsat y, ultra tpval(0.005)                     // impulses + steps + trends
indsat y, bis(volcanic) tpval(0.01)              // designed volcanic-type shock at 40
indsat y, bis(tc, delta(0.5)) tpval(0.01)        // transitory change
indsat y, dis tpval(0.01) nodates                // differenced impulses
indsat y, pis(1) tpval(0.01) nodates             // pairwise impulses

* ---------------------------------------------------------------------
* 4. Real data I: Nile river flow, 1871-1970 (Aswan dam, 1898)
* ---------------------------------------------------------------------
use indsat_nile, clear
indsat flow, iis sis tpval(0.01)
indsat dates                         // regime table: 1087.7 -> 807.1 ...
indsat test, hnull(1000) biascorr graph name(nile_test)
indsat plot, name(nile_dash)
indsat outlier
indsat diag
indsat forecast, h(5)
indsat loop flow, nums(10(-1)1) seed(1) graph name(nile_loop)

* ---------------------------------------------------------------------
* 5. Real data II: UK road casualties and the 1983 seat-belt law
* ---------------------------------------------------------------------
use indsat_seatbelts, clear
gen byte month = month(dofm(mdate))
indsat ldriverskilled lkms lpetrol i.month, ar(1) super tpval(0.005)
indsat diag
indsat ldriverskilled lkms lpetrol i.month, sis tpval(0.005)
indsat plot, name(sb_dash)
indsat ldriverskilled lkms lpetrol i.month, ar(1) iis tpval(0.01)
indsat distort, boot(49) seed(1)

* ---------------------------------------------------------------------
* 6. Real data III: DHSY UK consumption -- ARDL with saturation + bounds test
* ---------------------------------------------------------------------
use indsat_dhsy, clear
indsat ardl c y D4p, lags(5 5 1) super tpval(0.01)

* ---------------------------------------------------------------------
* 6b. Post-estimation mode: saturate the researcher's own model
* ---------------------------------------------------------------------
use indsat_seatbelts, clear
gen byte month = month(dofm(mdate))
regress ldriverskilled lkms lpetrol i.month
indsat, sis tpval(0.005)                 // same model + step saturation, comparison table
indsat dates
newey ldriverskilled lkms lpetrol, lag(4)
indsat, super tpval(0.005)
use indsat_dhsy, clear
ardl c y D4p, lags(2 2 1)
indsat, sis tpval(0.01)                  // ARDL in memory -> saturation + bounds test

* ---------------------------------------------------------------------
* 7. Monte Carlo: gauge and potency of SIS (Castle et al. 2015 design)
* ---------------------------------------------------------------------
indsat sim, t(100) reps(50) sizes(0 1 2 3 4) tpval(0.01) seed(11)

log close
