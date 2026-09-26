version 15.1
clear all
set more off

* Core test using built-in Stata commands only.
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

* Binary-response test.
cvcombo foreign weight, ///
    method(logit) ///
    controls(mpg length headroom trunk) ///
    level(95) ///
    saving("cvcombo_test_logit.dta") ///
    replace

assert r(combinations) == 15
assert r(failed) == 0

display as result "cvcombo core certification tests passed."
