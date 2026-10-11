version 15.1
clear all
set more off

* ------------------------------------------------------------
* Core tests using built-in Stata commands.
* ------------------------------------------------------------
sysuse auto, clear

capture program drop cvcombo
quietly do "cvcombo.ado"

* 3 candidate controls -> 7 nonempty combinations.
cvcombo mpg weight, ///
    method(regress) ///
    controls(length headroom trunk) ///
    level(95) ///
    saving("cvcombo_test_regress.dta") ///
    replace

assert r(combinations) == 7
assert r(successful) == 7
assert r(failed) == 0
assert r(n_absorb) == 0
assert r(n_cluster) == 0
confirm file "cvcombo_test_regress.dta"

* Binary-response test.
cvcombo foreign weight, ///
    method(logit) ///
    controls(mpg length headroom trunk) ///
    level(95) ///
    saving("cvcombo_test_logit.dta") ///
    replace

assert r(combinations) == 15
assert r(failed) == 0
confirm file "cvcombo_test_logit.dta"

* ------------------------------------------------------------
* Quantile regression tests.
* Built-in qreg supports a quantile() specification and robust VCE.
* ------------------------------------------------------------
cvcombo mpg weight, ///
    method(qreg) ///
    quantile(.25) ///
    options(vce(robust)) ///
    controls(length headroom trunk) ///
    saving("cvcombo_test_q25.dta") ///
    replace

assert r(combinations) == 7
assert r(successful) == 7
assert r(failed) == 0
assert abs(r(quantile) - .25) < 1e-12
confirm file "cvcombo_test_q25.dta"

cvcombo mpg weight, ///
    method(qreg) ///
    quantile(75) ///
    options(vce(robust)) ///
    controls(length headroom trunk) ///
    saving("cvcombo_test_q75.dta") ///
    replace

assert abs(r(quantile) - .75) < 1e-12
confirm file "cvcombo_test_q75.dta"


* ------------------------------------------------------------
* Multi-way FE / clustering test.
* Uses reghdfe when installed.
* ------------------------------------------------------------
capture which reghdfe
if !_rc {
    clear
    set obs 120
    generate int id = ceil(_n/6)
    generate int year = 2010 + mod(_n-1,6)
    generate double x = rnormal()
    generate double c1 = rnormal()
    generate double c2 = rnormal()
    generate double c3 = rnormal()
    generate double y = 1 + .8*x + .3*c1 - .2*c2 + .1*c3 + rnormal()

    cvcombo y x, ///
        method(reghdfe) ///
        controls(c1 c2 c3) ///
        absorb(id year) ///
        cluster(id year) ///
        level(95) ///
        saving("cvcombo_test_reghdfe_twoway.dta") ///
        replace

    assert r(combinations) == 7
    assert r(failed) == 0
    assert r(n_absorb) == 2
    assert r(n_cluster) == 2
    confirm file "cvcombo_test_reghdfe_twoway.dta"
}

display as result "cvcombo v2.1.3 certification tests passed."
