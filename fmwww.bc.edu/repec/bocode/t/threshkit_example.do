*! threshkit_example.do 1.0.0  07oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! A guided tour of THRESHKIT on the four shipped datasets.
*!
*! Run it after installing both packages:
*!
*!     ssc install threshkit
*!     ssc install threshkitdata
*!     threshkitdata, get
*!     do threshkit_example.do
*!
*! (The datasets live in the companion package threshkitdata because a Stata
*!  .pkg lists at most 100 files and threshkit's code and help come to
*!  exactly 100. threshkit itself needs none of this to work.)
*!
*! Nothing here is a self-test -- the package's own certification suites do
*! that, 48 of them. This file is for a reader who has just installed the
*! package and wants to see what it does and in what order to do it. Every
*! block says WHY the command is the right one for that question, because the
*! hard part of threshold modelling is not running a command, it is choosing
*! between a jump and a kink, between two regimes and three, and between a
*! threshold that is real and one the search found in noise.
*!
*! The four datasets:
*!   threshkit_dj      Durlauf-Johnson (1995) growth, as used by Hansen (2000)
*!   threshkit_kink    Reinhart-Rogoff US debt and growth (Hansen 2017)
*!   threshkit_ur      US unemployment 1959m1-1996m7 (Hansen 1997)
*!   threshkit_rates   US interest rates 1959m1-1993m2 (Tsay 1998)

version 15
clear all
set more off

display _n(2) as text "{hline 78}"
display as text "THRESHKIT: a guided tour"
display as text "{hline 78}"


* ======================================================================
* 1. CROSS-SECTION: is there a threshold at all, and where?
*
* Durlauf and Johnson asked whether countries converge at different rates
* depending on initial conditions. That is a threshold question, and the
* FIRST thing to settle is whether the data support a split at all --
* because the search will always return a minimum, threshold or not.
* ======================================================================
display _n as text "{hline 78}"
display as text "1. CROSS-SECTION  (Durlauf-Johnson growth data)"
display as text "{hline 78}"

use "threshkit_dj.dta", clear

* Test BEFORE estimating. Under the null the threshold is not identified,
* so the p-value has to be bootstrapped -- there is no table to look it up in.
thtest diff gdp60 iony pgro sch, threshvar(q) reps(199) seed(1)

* Having rejected, estimate. The confidence set for the threshold is the
* inverted likelihood ratio, NOT gamma-hat plus or minus a standard error:
* the limit distribution is not normal.
thregress diff gdp60 iony pgro sch, threshvar(q)

* Look at the profile before quoting the interval. A flat profile means the
* threshold is weakly identified however tight the interval looks.
estat lrplot

* Residual diagnostics against the REGIME-SPLIT design, so they ask what is
* left over after the threshold has been accounted for.
estat diag

* How many regimes, rather than assuming two? Note this uses the FULL grid
* by default, which matters: a coarse gridn() inflates the sequential test.
thnregimes diff gdp60 iony pgro sch, threshvar(q) maxthresh(2) reps(199) seed(2)


* ======================================================================
* 2. JUMP OR KINK? -- the question most often skipped
*
* A jump model fitted to kinked data gives an inconsistent threshold; a kink
* model fitted to jumped data leaves a systematic residual pattern at the
* break. The two are different models with different convergence rates, and
* the data can usually tell them apart.
* ======================================================================
display _n as text "{hline 78}"
display as text "2. JUMP OR KINK?  (Reinhart-Rogoff debt and growth)"
display as text "{hline 78}"

use "threshkit_kink.dta", clear

* The continuous (kink) model. The kink point is root-n normal here, so it
* DOES get a conventional standard error -- unlike the jump case.
thkink gdp gdp1, kinkvar(debt1)

* Is the slope change real? And is a breakpoint there at all? estat pscore
* answers the second with a conventional reference distribution and no
* bootstrap, by averaging over the unidentified breakpoint instead of
* maximising over it (Muggeo 2016).
estat slopetest
estat pscore

* Now compare the two model classes directly on the same data.
estat continuity


* ======================================================================
* 3. UNIVARIATE TIME SERIES: a SETAR, and whether the regimes differ in
*    their DYNAMICS rather than only in their level
* ======================================================================
display _n as text "{hline 78}"
display as text "3. TIME SERIES  (US unemployment)"
display as text "{hline 78}"

use "threshkit_ur.dta", clear
tsset t

* Choose the order, the delay and the number of regimes TOGETHER, on one
* fixed sample -- comparing a model fitted to n-1 rows with one fitted to
* n-4 would let the smallest order win by arithmetic rather than evidence.
thtarsel dy, maxp(4) maxdelay(3) maxregimes(2)

* Fit the SETAR the selection points to.
thtar dy, ar(1/2) delay(1) test reps(199) seed(3)

* The deterministic skeleton: does the fitted model settle to a fixed point
* or to a LIMIT CYCLE? A linear model cannot produce a cycle at all, so this
* is where a threshold model earns its keep. It is not a forecast.
* (estat skeleton belongs to thtar and thstar; thsubtar below has its own
*  estat suite -- trace, orders, regimes, compare -- and not this one.)
estat skeleton

* Do the two regimes want DIFFERENT autoregressive orders? Forcing one order
* on both spends degrees of freedom in the quiet regime to buy nothing, and
* Tong and Lim's own lynx and sunspot models are asymmetric. On these data
* it selects SETAR(2; 4, 2) and estat compare reports what that asymmetry
* bought, which is the comparison a referee will ask for.
thsubtar dy, maxp(4) delay(1 2)
estat orders
estat compare

* A unit root against a stationary threshold alternative. Which command
* depends on the alternative: thunitroot is Caner-Hansen (two regimes,
* a lagged DIFFERENCE as the transition variable); thbandur is
* Kapetanios-Shin (three regimes, a band of inaction, the lagged LEVEL).
thunitroot y, lags(2) reps(199) seed(4)


* ======================================================================
* 4. SMOOTH OR SHARP? -- and if smooth, WHICH transition
* ======================================================================
display _n as text "{hline 78}"
display as text "4. SMOOTH TRANSITION"
display as text "{hline 78}"

* Logistic or exponential? The Escribano-Jorda rule compares the STRENGTH of
* two rejections without conditioning on the first, which is why it is more
* reliable than the older nested sequence when the transition centre is not
* at zero.
thstrtype dy, ar(1/2) delay(1)

* Fit what it chooses. A smooth transition is the right model when the regime
* changes gradually -- adjustment costs, aggregation over heterogeneous
* agents -- and a sharp one when a rule really does switch at a value.
thstar dy, ar(1/2) delay(1) type(lstar1)
estat misspec, lags(4)


* ======================================================================
* 5. MULTIVARIATE: a threshold VAR, and the response to a shock when there
*    is no single response
* ======================================================================
display _n as text "{hline 78}"
display as text "5. MULTIVARIATE  (US interest rates)"
display as text "{hline 78}"

use "threshkit_rates.dta", clear
tsset t

* A threshold VAR. The regime is decided by the spread: the term structure
* behaves differently when it is wide.
thtvar g3month g3year, lags(2) thvar(sspread) test reps(199) seed(5)

* Is a regime locally explosive? That is NOT by itself a broken fit: a
* threshold model can be globally stationary with an explosive inner regime,
* because the process is thrown out of it before it can run away. What
* matters is the OUTER regime.
estat stability

* In a nonlinear system the impulse response depends on the state and on the
* SIGN and SIZE of the shock, so there is no single impulse response
* function. The generalised IRF averages over histories instead.
*
* It needs the threshold variable to be a LAG OF A MODELLED VARIABLE, so that
* a shock can propagate into the regime decision. With thvar(sspread) above
* the threshold variable is outside the system and estat girf refuses -- and
* that refusal is correct, not a limitation to work around. Refit with
* delay() to make the model self-exciting and the GIRF meaningful.
thtvar g3month g3year, lags(2) delay(1)
estat girf, horizon(12)

* System residual diagnostics, against the regime-split design.
estat diag


display _n(2) as text "{hline 78}"
display as text "End of tour. {bf:help threshkit} lists every command;"
display as text "{bf:help threshkit_choose} is the decision guide for picking"
display as text "between them, which is the part worth reading first."
display as text "{hline 78}"
