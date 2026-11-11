*! csdlp_realdata.do -- real-data application of csdlp
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane
*
* Regional micro-macro analogue of David, Giacomini, Jiao & Wang (2026, Sec. 6):
*   units   : 50 US states, monthly
*   outcome : 100 x [ln CI_{i,t+h} - ln CI_{i,t-1}], CI = Philadelphia Fed
*             state coincident index (cumulative activity response)
*   shock   : Jarocinski-Karadi (2020) pure monetary policy shock (MP_median),
*             updated series, 1990m2-2024m1; responses scaled to +25bp
*   state   : lagged 12-month activity growth of the state relative to the
*             US, winsorised at p1/p99 and standardised (local cycle position)
*   FE      : month (absorbs X_t -> differential responses, as the paper's
*             sector-time FE) and state
* Baseline sample ends 2019m12 (pre-COVID); the full sample is a robustness check.
* Data: csdlp_states.dta (installed with -net get csdlp-); no internet needed.

version 15.0
clear
set more off

* ---------------------------------------------------------------- data
* csdlp_states.dta ships with the package:   net get csdlp
* (sources and citations: -notes- after loading; rebuild with
*  csdlp_states_build.do)
capture findfile csdlp_states.dta
if _rc {
    di as err "csdlp_states.dta not found: type {cmd:net get csdlp} (or run csdlp_states_build.do)"
    exit 601
}
use "`r(fn)'", clear
notes
xtset sid mdate

* ---------------------------------------------------------------- baseline
csdlp y if pre, shock(mp_median) state(L.zw) horizons(0/24) cumulative ///
    absorb(mdate sid) controls(L.dy L2.dy L3.dy L.zw) scale(0.25)        ///
    level(90) level2(68) range(5 95) quantiles(5 50 95) seed(1)          ///
    ghorizons(0 6 12 24) saving(state_irf)

csdlp_diff, at(50 5)  level(90) horizons(0 3 6 9 12 15 18 21 24) saving(state_diff_50_5)
csdlp_diff, at(95 50) level(90) horizons(0 3 6 9 12 15 18 21 24) saving(state_diff_95_50)
csdlp_graph, lemma horizons(12) saving(state)
csdlp_graph, surface saving(state)

* ---------------------------------------------------------------- robustness
* (1) time-clustered VCE (Almuzara-Sancibrian) and BIC
csdlp y if pre, shock(mp_median) state(L.zw) horizons(0 6 12 18 24) cumulative ///
    absorb(mdate sid) controls(L.dy L2.dy L3.dy L.zw) scale(0.25) level(90)    ///
    range(5 95) seed(1) vce(cluster) select(bic) nograph
* (2) HAC with L = h
csdlp y if pre, shock(mp_median) state(L.zw) horizons(0 6 12 18 24) cumulative ///
    absorb(mdate sid) controls(L.dy L2.dy L3.dy L.zw) scale(0.25) level(90)    ///
    range(5 95) seed(1) vce(hlag) nograph
* (3) full sample including 2020-2023
csdlp y, shock(mp_median) state(L.zw) horizons(0 6 12 18 24) cumulative ///
    absorb(mdate sid) controls(L.dy L2.dy L3.dy L.zw) scale(0.25) level(90) ///
    range(5 95) seed(1) nograph
