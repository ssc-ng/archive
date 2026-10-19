// fmvardlurt_example.do -- examples for fmvardlurt 1.0.0
clear all
set more off

// 1. Lutkepohl (1993) West German data, two covariates
webuse lutkepohl2, clear
tsset
fmvardlurt ln_inv ln_inc ln_consump, reps(999) seed(1)
ereturn list

// 2. Fixed lags, frequency fixed at 1, trend
fmvardlurt ln_inv ln_inc ln_consump, case(5) fixlag(1 1) freq(1) reps(999) seed(1) nograph

// 3. The same model without Fourier terms (plain multivariate ARDL test, same bootstrap)
fmvardlurt ln_inv ln_inc ln_consump, case(5) fixlag(1 1) freq(0) reps(999) seed(1) nograph

// 4. Postestimation
fmvardlurt ln_inv ln_inc ln_consump, fixlag(1 1) reps(499) nograph nodisplay
fmvardlurt
fmvardlurt_diag
predict double fc, fourier
predict double ehat, residuals
fmvardlurt_graph

// 5. Check the statistics against regress (fixed lags, frequency 1, T = observations in the sample)
fmvardlurt ln_inv ln_inc ln_consump, fixlag(1 1) freq(1) noboot nodisplay
local t_f = e(tstat)
local F_f = e(fstat)
local Ff  = e(ffstat)
quietly count if !missing(ln_inv, ln_inc, ln_consump)
local T = r(N)
gen double t_ = sum(!missing(ln_inv, ln_inc, ln_consump))
gen double s1 = sin(2*_pi*1*t_/`T')
gen double c1 = cos(2*_pi*1*t_/`T')
regress D.ln_inv L.ln_inv L.ln_inc L.ln_consump L.D.ln_inv L.D.ln_inc L.D.ln_consump ///
    D.ln_inc D.ln_consump s1 c1
display "t: " %10.6f `t_f' "   regress: " %10.6f _b[L.ln_inv]/_se[L.ln_inv]
test L.ln_inc L.ln_consump
display "F: " %10.6f `F_f' "   regress: " %10.6f r(F)
test s1 c1
display "Fourier F: " %10.6f `Ff' "   regress: " %10.6f r(F)
drop t_ s1 c1

// 6. Simulated series: y cointegrated with three covariates, with a smooth temporary break
clear
set seed 2026
set obs 120
gen t = _n
tsset t
gen x1 = sum(rnormal())
gen x2 = sum(rnormal())
gen x3 = sum(rnormal())
gen u = rnormal()
replace u = 0.5*L.u + rnormal() if _n > 1
gen brk = 4*(1/(1 + exp(-0.15*(t - 40))) - 1/(1 + exp(-0.15*(t - 80))))
gen y = 1 + brk + 0.6*x1 - 0.4*x2 + 0.3*x3 + u
fmvardlurt y x1 x2 x3, reps(999) seed(11) nograph
fmvardlurt y x1 x2 x3, freq(0) reps(999) seed(11) nograph
