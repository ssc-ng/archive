// =========================================================================
// mvardlurt_multivariate_example.do
// Examples: multivariate ARDL unit root test with 2+ covariates
// Sam, McNown, Goh and Goh (2024)
// =========================================================================

clear all
set more off

// 1. Lutkepohl (1993) West German data, two covariates
webuse lutkepohl2, clear
tsset
mvardlurt_multivariate ln_inv ln_inc ln_consump, maxlag(4) reps(999) seed(12345)
ereturn list

// 2. Intercept and trend, manual lags (p = 2, common q = 1)
mvardlurt_multivariate ln_inv ln_inc ln_consump, case(5) fixlag(2 1) reps(999) seed(1) nograph

// 3. Covariate-specific lags: p = 1, q1 = 2 (ln_inc), q2 = 0 (ln_consump)
mvardlurt_multivariate ln_inv ln_inc ln_consump, fixlag(1 2 0) reps(999) seed(1) nograph

// 4. BIC, contemporaneous D.x, 10% decision level, no stars
mvardlurt_multivariate ln_inv ln_inc ln_consump, ic(bic) contemp level(90) nostar reps(999) nograph

// 5. Statistics only, no bootstrap
mvardlurt_multivariate ln_inv ln_inc ln_consump, noboot nograph

// 6. Postestimation: diagnostics, predict, graphs, redisplay
mvardlurt_multivariate ln_inv ln_inc ln_consump, maxlag(3) reps(499) nograph notable
mvardlurt_multivariate_diag
matrix list r(diag)
predict double ehat, residuals
predict double dyhat, xb
summarize ehat dyhat
mvardlurt_multivariate_graph
_mvardlurt_multivariate_display

// 7. Check against -regress-: statistics must match plain OLS with the same lags
mvardlurt_multivariate ln_inv ln_inc ln_consump, fixlag(1 1) reps(100) nograph nodisplay
local t_mv = e(tstat)
local f_mv = e(fstat)
regress D.ln_inv L.ln_inv L.ln_inc L.ln_consump L.D.ln_inv L.D.ln_inc L.D.ln_consump
local t_ols = _b[L.ln_inv] / _se[L.ln_inv]
test L.ln_inc L.ln_consump
display as txt "t: " %10.6f `t_mv' "  vs regress " %10.6f `t_ols'
display as txt "F: " %10.6f `f_mv' "  vs regress " %10.6f r(F)

// 8. Simulated system with THREE covariates
clear
set seed 2026
set obs 120
gen t = _n
tsset t
gen x1 = sum(rnormal())
gen x2 = sum(rnormal())
gen x3 = sum(rnormal())
gen u  = rnormal()
replace u = 0.5*L.u + rnormal() if _n > 1
gen y_coint = 1 + 0.6*x1 - 0.4*x2 + 0.3*x3 + u     // cointegrated with x1 x2 x3
gen y_rw    = sum(rnormal())                         // independent random walk

display as res _n "--- y cointegrated with three I(1) covariates (expect Case IV) ---"
mvardlurt_multivariate y_coint x1 x2 x3, maxlag(3) reps(999) seed(11) nograph

display as res _n "--- independent random walk (expect Case I) ---"
mvardlurt_multivariate y_rw x1 x2 x3, maxlag(3) reps(999) seed(11) nograph

// 9. Export headline results
* mvardlurt_multivariate y_coint x1 x2 x3, maxlag(3) reps(499) nograph savepath("mvardlurt_results.xlsx")
