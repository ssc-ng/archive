*==============================================================================
* dvar_example.do  --  worked example and replication script for -dvar-
* Wang, Oka & Zhu (2025, JAE) "Distributional Vector Autoregression"
* Adrian, Boyarchenko & Giannone (2021, IER) "Multimodality in macrofinancial
* dynamics"
* Author: Dr Merwan Roudane  (merwanroudane920@gmail.com)
*
* Data: dvar_us.dta -- US quarterly 1971q1-2024q1 from the JAE replication
* package: real GDP growth (gdp, % SAAR), Chicago Fed NFCI (nfci, quarterly
* average) and the federal funds rate with the Wu-Xia (2016) shadow rate at the
* zero lower bound (rate).  Get it with:  net get dvar
*==============================================================================
clear
set more off
use dvar_us, clear
tsset q

*------------------------------------------------------------------------------
* 1. DR system: coefficient processes, Theorem-1 sandwich SEs, in-sample
*    one-step distributions and the conditional NFCI-GDP correlation (Fig. 3)
*------------------------------------------------------------------------------
dvar fit nfci gdp rate, lags(3) insample generate(is) seed(2025)

* the same system estimated by plain maximum likelihood, eq. (6)
dvar fit nfci gdp rate, lags(3) lambda(0) nograph

*------------------------------------------------------------------------------
* 2. Multimodality during the Great Recession (Fig. 4): joint distribution of
*    NFCI and GDP, information up to 2008q3 ... 2009q3
*------------------------------------------------------------------------------
foreach d in 2008q3 2008q4 2009q1 2009q2 2009q3 {
    dvar joint nfci gdp rate, at(`d') horizons(1 2 3 4) draws(20000) ///
        bw(0.25 0.8) seed(2025) name(joint_`d')
}

*------------------------------------------------------------------------------
* 3. Counterfactual monetary easing in 2008q4 (replication code):
*    rate ~ N(-1, 0.3^2), the shadow rate observed in 2011
*------------------------------------------------------------------------------
dvar irf nfci gdp rate, at(2008q4) shock(rate) cf(normal -1 0.3) ///
    inlags(3) lags(4) horizon(4) lpend(2019q4) draws(20000) seed(2025) joint

*------------------------------------------------------------------------------
* 4. Limit financial tightening in 2008q4 (paper, Sec. 4.4.1, Table 1):
*    NFCI ~ truncated N(0, 0.2^2) on (-1.5, 2), with bootstrap bands
*------------------------------------------------------------------------------
dvar irf nfci gdp rate, at(2008q4) shock(nfci) cf(tnormal 0 0.2 -1.5 2) ///
    lpend(2019q4) draws(5000) reps(99) blocklength(8) seed(2025) name(nfci_irf)

*------------------------------------------------------------------------------
* 5. Limit the GDP collapse in 2008q4 (paper, Sec. 4.4.2, Table 2):
*    GDP ~ truncated Gamma(shape 0.6, scale 6) on (0, 11)
*------------------------------------------------------------------------------
dvar irf nfci gdp rate, at(2008q4) shock(gdp) cf(tgamma 0.6 6 0 11) ///
    lpend(2019q4) draws(20000) seed(2025) name(gdp_irf)

*------------------------------------------------------------------------------
* 6. Out-of-sample calibration (Fig. 1-2): PITs, CRPS, quantile and log scores
*------------------------------------------------------------------------------
dvar forecast nfci gdp rate, start(1999q4) horizon(1) draws(2000) seed(2025) generate(f1)
dvar forecast nfci gdp rate, start(1999q4) horizon(4) draws(2000) seed(2025) name(fc_h4)

*------------------------------------------------------------------------------
* 7. Adrian-Boyarchenko-Giannone kernel model: bandwidth by log score, joint
*    term structure from 2008q4 and density impulse response to NFCI
*------------------------------------------------------------------------------
dvar kernel nfci gdp, at(2008q4) lags(1) cvgrid(0.3(0.1)0.9) cvstart(1982q3) ///
    horizon(4) draws(10000) seed(2025)
dvar kernel nfci gdp, at(2008q4) lags(1) c(0.5) horizon(4) draws(10000) ///
    shock(nfci) cf(tnormal 0 0.2 -1.5 2) seed(2025) name(abg_dir)

*------------------------------------------------------------------------------
* 8. The QQR colour maps
*------------------------------------------------------------------------------
dvar palette parula, n(64)
dvar joint nfci gdp rate, at(2008q4) horizons(1) colorscale(turbo) heatmap ///
    seed(2025) name(joint_turbo)

*------------------------------------------------------------------------------
* 9. Known-truth check: a bivariate Gaussian VAR(1) where the true conditional
*    quantiles are known; the DVAR quantiles must recover them
*------------------------------------------------------------------------------
clear
set seed 12345
set obs 400
gen t = _n
tsset t
gen double y1 = 0
gen double y2 = 0
gen double e1 = rnormal()
gen double e2 = 0.6*e1 + 0.8*rnormal()
replace y1 = 0.5*L.y1 + e1 if t > 1
replace y2 = 0.3*L.y1 + 0.4*L.y2 + e2 if t > 1
dvar fit y1 y2, lags(1) insample generate(sim) nograph seed(1)
* true one-step 5% / 50% / 95% quantiles of y2 (sd of e2 = 1)
gen double true_q50 = 0.3*L.y1 + 0.4*L.y2
gen double true_q05 = true_q50 + invnormal(0.05)
gen double true_q95 = true_q50 + invnormal(0.95)
foreach q in 05 50 95 {
    qui corr sim_q`q'_y2 true_q`q'
    di as text "corr(DVAR q`q', true q`q') = " as result %6.3f r(rho)
    qui gen double d`q' = sim_q`q'_y2 - true_q`q'
    qui su d`q'
    di as text "   mean error = " as result %6.3f r(mean) as text "   sd = " as result %6.3f r(sd)
}
* true contemporaneous correlation of (y1, y2) given the past = 0.6
qui su sim_corr_1_2
di as text "mean in-sample conditional correlation (truth 0.60) = " as result %6.3f r(mean)
