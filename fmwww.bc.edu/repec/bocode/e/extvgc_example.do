* extvgc_example.do  --  self-test for extvgc (Hong, Guo & Zhao 2025)
* Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*
* Known-truth DGP: x is a random walk with fat-tailed shocks.  During the
* break window 2005m1-2011m12 the shock of y loads on the LAGGED EXTREME
* POSITIVE shocks of x only; outside it y is independent of x.
* Expected: Ext+ => (Ext+ / Normal) pairs reject inside the window;
*           Ext- => . and Normal => . pairs show no (or isolated) rejection.

clear
set seed 20250521
set obs 360
gen int t = ym(1990, 1) + _n - 1
format t %tm
tsset t

gen double e1 = rt(4) * 0.05
qui _pctile e1, p(90)
local q90 = r(r1)
gen double xp = cond(e1 > `q90', e1, 0)
gen double e2 = rt(4) * 0.05
replace e2 = e2 + 1.2*L.xp if inrange(t, ym(2005,1), ym(2011,12))
gen double x = sum(e1)
gen double y = sum(e2)

* ---- 1. main run: all nine pairs + overall, tables, episodes, graphs
extvgc y x, theta(0.1) window(72) control(12) reps(199) seed(1) ///
    descriptive diagnostics generate(sew)
return list
matrix list r(results)

* ---- 2. same data given as shocks (log-return style input) must coincide
extvgc e2 e1 if _n > 1, differenced window(72) reps(0) nograph noepisodes
matrix A = r(results)

* ---- 3. other algorithms, own thresholds, fixed lag, per-pair lag
extvgc y x, algorithm(rolling) window(60) causeshocks(pos) depshocks(pos nor) reps(99) nograph
extvgc y x, algorithm(forward) threshold(own) lags(2) causeshocks(neg) reps(99) nograph
extvgc y x, lagmode(pair) ic(aic) causeshocks(nor) nooverall reps(49) resample(joint) nograph

* ---- 4. classical positive / negative split (Hatemi-J 2012; AS-TVGC of Hong et al. 2022)
extvgc y x, threshold(zero) window(72) reps(99) seed(2) nograph

* ---- 5. check: Wald at the last date (forward) = regress + test x N/(N-k), Sigma = e'e/T
qui extvgc y x, algorithm(forward) window(72) causeshocks(pos) depshocks(pos) ///
    nooverall reps(0) nograph noepisodes
matrix S = r(sew)
matrix Q = r(thresholds)
local p  = r(results)[1,1]
local qu = Q[1,1]
gen double cy = sum(cond(D.y > `qu', D.y, 0)) if _n > 1
gen double cx = sum(cond(D.x > `qu', D.x, 0)) if _n > 1
qui regress cy L(1/`=`p'+1').cy L(1/`=`p'+1').cx t
qui test L1.cx
display "regress-based Wald = " %9.4f r(F)*r(df)*e(N)/(e(N)-e(df_m)-1) ///
    "    extvgc = " %9.4f S[rowsof(S),1]
