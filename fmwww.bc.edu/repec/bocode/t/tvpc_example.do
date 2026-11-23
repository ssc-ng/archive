* tvpc_example.do -- self-test and worked examples for the tvpc package
* Dr Merwan Roudane (merwanroudane920@gmail.com)
* https://github.com/merwanroudane
*
* Run after:  net install tvpc, from("<folder>") replace
*             net get tvpc, from("<folder>")        (copies the .dta files)
version 15.0
clear
set more off

* =====================================================================
* PART 1. Benchmark: TimeGraph A1 (known truth) - reproduces Table 1
* =====================================================================
use tvpc_a1, clear
local tr : char _dta[tvpc_truth]
matrix T = (`tr')
matrix list T

* TV-PC on the benchmark, lags t-1..t-4 (lag step = 1 period)
tvpc X1-X8, lags(4) alpha(0.0005) truth(T)

* expected (paper Table 1, TV-PC column): F1 = 0.6957
display "F1 = " %6.4f e(F1) "   (paper: 0.6957)"

* Table 1 of the paper: TV-PC vs PCMCI over five p-values
tvpcsens X1-X8, lagslist(4) alphas(0.0005 0.001 0.005 0.01 0.05) ///
    truth(T) pcmci graph name(table1)
* expected TV-PC F1 : 0.6957 0.6957 0.6667 0.6400 0.4138
*   (paper prints 0.5517 at p = 0.05; gCastle itself gives 0.4138)
* expected PCMCI F1 : 0.6923 0.6923 0.6923 0.6923 0.5294 (tigramite 5.2)

* PCMCI benchmark alone
tvpcmci X1-X8, taumax(4) alpha(0.01) truth(T) nolagmap

* =====================================================================
* PART 2. Paper-style application: 11 monthly indicators, 4 quarterly lags
*         (SIMULATED data with the variable names of Table 2)
* =====================================================================
use tvpc_macro, clear
tsset month, monthly
* true causal links of the simulated system: (cause effect lag-in-quarters)
* variable order: 1 cpi 2 wage 3 short_interest 4 long_interest 5 dom_equity
* 6 dom_equityacc 7 int_equityacc 8 dom_bond 9 int_bond 10 unemp 11 hpi
matrix TM = (1,1,1 \ 1,2,1 \ 1,4,2 \ 1,8,3 \ 1,11,2 \ 2,1,1 \ 2,2,1 \ ///
    2,2,2 \ 2,8,1 \ 3,3,1 \ 3,4,1 \ 3,5,3 \ 3,5,4 \ 3,10,3 \ 3,11,1 \ ///
    4,1,1 \ 4,3,1 \ 4,4,1 \ 4,8,1 \ 5,5,1 \ 5,6,2 \ 5,7,0 \ 5,10,1 \ ///
    6,1,2 \ 6,6,1 \ 7,7,1 \ 8,8,1 \ 8,9,1 \ 8,11,1 \ 9,9,1 \ 10,10,1 \ ///
    11,6,4 \ 11,11,1)

* Fig. 1 design: standardise, 4 lags of one quarter (3 months), alpha 0.05
tvpc cpi wage short_interest long_interest dom_equity dom_equityacc ///
    int_equityacc dom_bond int_bond unemp hpi, ///
    lags(4) lagstep(3) alpha(0.05) truth(TM) strength

* graphs: grid (Fig. 13), network (Fig. 2), heat map, degree bars
tvpcgraph, all name(macro)

* causal relationship maps (Figs. 3-11)
tvpcgraph, map(cpi wage short_interest unemp hpi) name(macro)

* edge stability: 100 moving-block bootstrap replications
tvpc cpi-hpi, lags(4) lagstep(3) alpha(0.05) reps(100) seed(2026) ///
    nolagmap nosummary

* Sec. 4.4 / Fig. 12: sensitivity to 3, 4, 5 quarterly lags
tvpcsens cpi-hpi, lagslist(3 4 5) alphas(0.01 0.05) lagstep(3) ///
    target(cpi) truth(TM) graph name(sens)

* stored results
ereturn list
matrix list e(lagmap)
