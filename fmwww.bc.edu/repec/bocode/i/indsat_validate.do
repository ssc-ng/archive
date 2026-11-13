* =====================================================================
* indsat_validate.do -- numerical cross-check of indsat against R gets::isat
* Dr Merwan Roudane  (merwanroudane920@gmail.com)
* 1) run this file in Stata; it writes indsat_validate.csv and prints results
* 2) run indsat_validate.R in R (install.packages("gets")); compare the numbers
* =====================================================================
version 14.0
clear
set obs 100
set seed 123
gen t = _n
tsset t
gen x = rnormal()
gen y = 1 + 0.5*x + rnormal() + 3*(t>=60) + 6*(t==30)
export delimited t x y using indsat_validate.csv, replace

local cases `" "iis" "sis" "iis sis" "iis sis tis" "iis sis tpval(0.01) vce(robust)" "sis tpval(0.01) vce(nw)" "ar(1 2) iis tis tpval(0.01) ic(aic)" "'
local i 0
foreach c of local cases {
    local ++i
    quietly indsat y x, `c' nodates
    di as text _n "Case `i': `c'" _col(50) "retained: " as res e(nret) as text "  estimations: " as res e(nest)
    matrix b = e(b)
    matrix list b, format(%12.7f) noheader
    if (e(op_z)<.) di as text "outlier proportion z = " as res %9.6f e(op_z) as text "  count p = " as res %7.4f e(op_count_p) as text "  distortion = " as res %9.6f e(dist_chi2)
}
