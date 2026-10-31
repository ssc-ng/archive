* polypml_examples.do -- examples in the polypml article
version 14
clear all
set more off
webuse nhanes2f, clear
* two-step (polycorr) vs pairwise ML vs FIML
polycorr health heartatk diabetes highbp, pairwise notable
polypml health heartatk diabetes highbp, thresholds
polypml health heartatk diabetes highbp, method(fiml) draws(300)
* design-weighted, cluster-robust
polypml health heartatk diabetes highbp [pw = finalwgt], vce(cluster psuid)
test [health]heartatk = [health]diabetes

* simulated MAR example: missingness in x2-x4 driven by observed x1
clear
set seed 2026
set obs 1000
matrix C = (1, .5, .4, .3 \ .5, 1, .5, .4 \ .4, .5, 1, .5 \ .3, .4, .5, 1)
drawnorm z1 z2 z3 z4, corr(C)
gen byte x1 = (z1 > -.8) + (z1 > 0) + (z1 > .9)
gen byte x2 = (z2 > -.3) + (z2 > .7)
gen byte x3 = (z3 > -1) + (z3 > .2) + (z3 > 1.1)
gen byte x4 = (z4 > .4)
gen double pm = cond(x1 >= 2, .5, .05)
foreach v in x2 x3 x4 {
	replace `v' = . if runiform() < pm
}
polycorr x1-x4, pairwise notable
polypml x1-x4
polypml x1-x4, method(fiml)
