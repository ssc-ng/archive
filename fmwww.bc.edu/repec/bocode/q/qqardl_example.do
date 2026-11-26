*! qqardl_example.do -- worked example for qqardl
*! Dr Merwan Roudane <merwanroudane920@gmail.com>
*
* Simulates a cointegrated ARDL(1,1) system with a known long-run coefficient
* of 1 and an adjustment speed of -0.3, then runs QQARDL with the defaults of
* Balci and Dogan (2026) and the robustness variants of their Section 5.

clear
set seed 2026
set obs 241
gen t = tm(2005m1) + _n - 1
format t %tm
tsset t

* x: I(1) with drift; y: error-corrects towards y = x (long run 1, ECT -0.3)
gen x = 0
replace x = L.x + 0.02 + rnormal(0, 0.1) in 2/l
gen y = 1
replace y = L.y + 0.5 - 0.3*(L.y - 1.0*L.x) + 0.4*D.x + rnormal(0, 0.1) in 2/l

* 1) Baseline QQARDL(1,1), 11 x 11 grid, heatmaps
qqardl y x

* the median-median cell should be close to the true values
matrix LR = r(lr)
matrix ECT = r(ect)
display "LR(0.5, 0.5) = " %6.3f LR[6,6] "   (true 1)"
display "ECT(0.5, 0.5) = " %6.3f ECT[6,6] "   (true -0.3)"

* 2) Robustness (Balci and Dogan 2026, Section 5)
foreach L in "1 2" "2 1" "2 2" {
    qqardl y x, lags(`L') tau(0.1 0.5 0.9) notable nograph
    matrix LR = r(lr)
    display "ARDL(`L'): LR at (0.5, 0.5) = " %6.3f LR[2,2]
}

* 3) Robust standard errors, values printed in the cells, results saved
qqardl y x, vce(robust) tau(0.1(0.2)0.9) values graphname(qqrob) ///
    saving(qqardl_results, replace) genqser(qs)
describe qs_*

* 4) Figures in the colours of Destek et al. (2025), long run as b1 of Eq. (4),
*    bounds test from the error-correction form instead of Eq. (1)
qqardl y x, colormap(bwr) lrtype(beta) graphname(qqbwr)
qqardl y x, btest(ecm) tau(0.1 0.5 0.9) notable nograph
matrix list r(coint)
