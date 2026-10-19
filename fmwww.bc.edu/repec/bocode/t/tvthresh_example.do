*! tvthresh_example.do -- a tour of TVTHRESH on simulated data
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Every dataset here is simulated by tvtsim, so this file runs anywhere
*! with no data to download. Run it top to bottom after
*!   net install tvthresh
*!
*! The order is the order you should work in: ask whether the threshold
*! moves at all, then ask what moves it, then fit that.

clear all
set more off

* =====================================================================
* 0. START HERE WHEN THE CHOICE IS OPEN
*
*    tvtsel runs the library's own diagnostics on your data and reports
*    which specifications they point to. It protects whatever is in
*    e() while it works.
* =====================================================================
tvtsim, n(200) model(fourier) seed(20261014) clear
tvtsel y x, threshvar(q)

* =====================================================================
* 1. IS THE THRESHOLD CONSTANT? The gateway test.
*
*    Fail to reject and an ordinary constant-threshold command is the
*    right tool and nothing in this library is needed.
* =====================================================================
tvthomog y x, threshvar(q)

* =====================================================================
* 2. A THRESHOLD THAT MOVES WITH TIME
*
*    The flagship estimator: the threshold is a Fourier function of t.
*    F1 tests for a threshold effect, F2 for constancy of the threshold.
* =====================================================================
tvtfourier y x, threshvar(q) kmax(3) reps(199)

* always look at the path before reading the slopes
tvtplot, truevar(gamma) name(fig_fourier)

* the fitted path against the true one, which tvtsim stored as gamma
matrix P = e(path)
svmat double P, name(fit)
correlate fit1 gamma
drop fit1

* =====================================================================
* 3. A THRESHOLD THAT TRACKS THE SERIES' OWN RECENT PAST
* =====================================================================
tvtsim, n(250) model(shift3) seed(77) clear
tvtcotar y, memory(20) lags(1) reps(199)

* =====================================================================
* 4. A THRESHOLD DRIVEN BY OTHER OBSERVED VARIABLES
* =====================================================================
tvtsim, n(250) model(logistic) seed(99) clear
generate double z1 = rnormal()
tvtboundary y x, threshvar(q) zvars(z1) reps(199)

* =====================================================================
* 5. WHEN THE SPECIFICATION ITSELF IS IN QUESTION
*
*    tvtcovdep chooses the regressors, which of them shift between
*    regimes, and which variables move the threshold, all at once.
* =====================================================================
tvtsim, n(250) model(fourier) seed(123) clear
forvalues j = 2/5 {
    generate double x`j' = rnormal()
    generate double z`j' = rnormal()
}
tvtcovdep y x x2 x3 x4 x5, threshvar(q) zvars(z2 z3 z4 z5)

* =====================================================================
* 6. A THRESHOLD YOU CANNOT SEE AT ALL
*
*    tvtlatent makes the threshold an unobserved AR(1) state. Read the
*    threshold block before the slopes, and note that phi and sigma2_u
*    need about 500 observations before they mean much.
* =====================================================================
clear
set seed 4242
set obs 600
generate int t = _n
tsset t
generate double z = sqrt(2)*rnormal()
generate double g = .
quietly replace g = sqrt(0.5/(1-0.81))*rnormal() in 1
quietly replace g = 0.9*g[_n-1] + sqrt(0.5)*rnormal() in 2/l
generate double y = cond(z <= g, 0.75, -0.75) + rnormal()

tvtlatent y, threshvar(z) mcmcreps(20000) burnin(10000) seed(1)
tvtplot, truevar(g) name(fig_latent)

* =====================================================================
* 7. COUNT DATA
*
*    The only count command here. A Gaussian threshold model is the
*    wrong family for integer data however the threshold behaves.
* =====================================================================
clear
set seed 616
set obs 400
generate int t = _n
tsset t
generate int cases = 0
quietly replace cases = rpoisson(1) in 1/7
forvalues i = 8/400 {
    quietly summarize cases in `=`i'-7'/`=`i'-2', detail
    local q3 = r(p50)
    local a = cond(cases[`=`i'-1'] <= `q3', 0.3, 0.6)
    * rbinomial(0, p) is MISSING, not 0, so the zero case must be
    * handled or the series dies at the first zero -- and zeros are
    * exactly what a count series is full of
    local prev = cases[`=`i'-1']
    local surv = cond(`prev' > 0, rbinomial(`prev', `a'), 0)
    quietly replace cases = `surv' + rpoisson(1) in `i'
}
tvtinar cases, memory(6)
tvtinar cases, memory(6) method(cml)

* =====================================================================
* 8. PUBLICATION TABLES
*
*    tvtexport knows WHERE EACH COMMAND PUTS ITS THRESHOLD, so the table
*    carries the threshold panel a threshold paper actually reports and
*    not just a block of coefficients.
* =====================================================================
tvtsim, n(200) model(fourier) seed(31415) clear
quietly tvtfourier y x, threshvar(q) kmax(3) reps(99)
tvtexport
tvtexport using "tvthresh_table.tex", format(latex) replace

display _n as result "TVTHRESH EXAMPLE COMPLETE"
display as text "See {helpb tvthresh} for the full command list and"
display as text "{helpb tvthresh_choose} for which specification to fit."
