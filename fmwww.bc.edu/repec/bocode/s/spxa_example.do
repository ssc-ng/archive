*! spxa_example.do  1.0.0  21nov2026
*! Examples for -spxa-; run as a self-checking smoke test:
*!     do spxa_example
*! Every assertion below is a check on the numbers, not just on the syntax, so
*! the file fails loudly if anything is wrong.
*!
*! Requires Stata 16 or newer with the Python integration configured, and the
*! Python library spxa installed in the interpreter Stata uses:
*!     python: import subprocess, sys; subprocess.check_call([sys.executable, "-m", "pip", "install", "spxa"])

version 16
clear all
set more off

* SSC submissions must work with option abbreviations turned off
set varabbrev off

capture log close _all
local logfile "spxa_example.log"
capture confirm file "`logfile'"
if (!_rc) erase "`logfile'"
log using "`logfile'", replace text name(spxaexample)

di as txt _n "{hline 70}"
di as txt "spxa: examples"
di as txt "{hline 70}"

* ---------------------------------------------------------------------------
* 1. One process, from a class and its parameters
* ---------------------------------------------------------------------------

spxa define vg, process(vg) params(sigma=0.2, nu=0.1, theta=-0.1)

* The handle and its exactness level are in r()
assert "`r(handle)'" == "vg"
assert "`r(exactness)'" == "EXACT"

spxa report vg, cumulants(4)

* With this parametrization of the variance-gamma process
*   kappa_1 = theta + GammaRate*(a - b) = theta,  kappa_2 = sigma^2 + c*(a + b),
* so both can be checked against their closed forms (a = b = 0 by default):
local k1 = r(kappa1)
local k2 = r(kappa2)
assert reldif(`k1', -0.1) < 1e-10
assert reldif(`k2', 0.04) < 1e-10
di as res "cumulants check out: kappa_1 = " %6.4f `k1' ", kappa_2 = " %6.4f `k2'

* ---------------------------------------------------------------------------
* 2. A composition: two processes added, then simulated
* ---------------------------------------------------------------------------

spxa define jump, process(cgmy) params(C=1, G=5, M=5, Y=0.5)
spxa define model, expr(vg + 0.5*jump)

assert "`r(exactness)'" == "EXACT"

* the cumulants are stored as a row vector, like e(b): kappa_j is K[1, j]
spxa report model, cumulants(4) matrix(K) detail
assert rowsof(K) == 1
assert colsof(K) == 4
assert reldif(K[1, 2], r(kappa2)) < 1e-12

* The second cumulant is additive over independent components:
spxa report vg, cumulants(4)
local k2vg = r(kappa2)
spxa report jump, cumulants(4)
local k2jump = r(kappa2)
spxa report model, cumulants(4)
assert reldif(r(kappa2), `k2vg' + 0.25 * `k2jump') < 1e-10
di as res "kappa_2 is additive: " %8.6f `k2vg' " + 0.25*" %8.6f `k2jump'

set seed 12345
spxa simulate model, paths(500) steps(52) t(1) generate(dx) clear

assert _N == 500 * 53
assert "`: word 1 of `r(generate)''" == "dx"

* The long layout carries an integer time index, so it can be -xtset- directly
xtset path step
assert "`r(panelvar)'" == "path"
assert "`r(timevar)'" == "step"
assert "`r(balanced)'" == "strongly balanced"
assert r(tdelta) == 1

* t() is the time itself: 52 steps spanning a year
summarize t, meanonly
assert reldif(r(max), 1) < 1e-12

* The simulation is reproducible from the seed
tempfile first
quietly save `first', replace
set seed 12345
spxa simulate model, paths(500) steps(52) t(1) generate(dx) clear
quietly cf _all using `first'
di as res "the same seed reproduces the same paths"

* ---------------------------------------------------------------------------
* 3. Time change: a process run on a subordinator clock
* ---------------------------------------------------------------------------

spxa define clock, process(gamma) params(a=1, b=2)
spxa define sub, expr(vg @ clock)
spxa report sub, cumulants(4) story

* ---------------------------------------------------------------------------
* 4. Prices rather than log prices
* ---------------------------------------------------------------------------

spxa define gbm, expr(bm(mu=0.05, sigma=0.2) + drift(mu=-0.02))
spxa simulate gbm, paths(100) steps(12) t(1) generate(price) initial(100) log clear
* Every path starts at 100, so the first observation of each block of 13 is 100
forvalues p = 1/100 {
    assert reldif(price[(`p' - 1) * 13 + 1], 100) < 1e-12
}
* and prices are positive by construction
summarize price, meanonly
assert r(min) > 0

* ---------------------------------------------------------------------------
* 5. Managing the registry
* ---------------------------------------------------------------------------

* six handles: vg, jump, model, clock, sub, gbm
spxa list
assert r(n_defined) == 6

spxa drop sub
spxa list
assert r(n_defined) == 5

* Drop the handles the error checks below use, so that a stale one from an
* earlier run cannot make a test pass or fail for the wrong reason
spxa drop vg
spxa drop model
spxa list
assert r(n_defined) == 3

spxa clear
spxa list
assert r(n_defined) == 0

* >>> error checks: everything below is expected to fail
* ---------------------------------------------------------------------------
* 6. Errors are conventional Stata errors, not Python tracebacks
* ---------------------------------------------------------------------------

* vg was dropped above, and cleared as well
capture spxa report vg
assert _rc == 111

capture spxa define bad, process(not_a_process)
assert _rc == 198

* an undeclared option is refused rather than silently ignored
capture spxa define bad, process(gamma) paramz(a=1, b=2)
assert _rc == 198

capture spxa define bad, params(sigma=1)
assert _rc == 198

capture spxa define bad, process(gamma) expr(vg)
assert _rc == 198

capture spxa simulate nosuch, clear
assert _rc == 111

* paths() is checked before the handle is looked up, so this is a syntax error
capture spxa simulate vg, paths(0) clear
assert _rc == 198

* and here the handle is genuinely gone, which is a different error
capture spxa simulate vg, clear
assert _rc == 111

capture spxa frobnicate
assert _rc == 198

di as txt _n "{hline 70}"
di as res "spxa examples finished: all checks passed"
di as txt "{hline 70}"

log close spxaexample
exit
