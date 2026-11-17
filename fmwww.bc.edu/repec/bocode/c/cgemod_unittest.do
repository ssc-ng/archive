* cgemod unit tests, version 2.0.0
* Checks that invalid input is rejected with the right return code and a clear message,
* and that each subcommand runs end to end. Run from the folder that contains the package files.
clear all
set more off
version 15
which cgemod

capture program drop _ut
program define _ut
    * _ut <expected rc> : <command>
    gettoken want 0 : 0
    gettoken colon 0 : 0, parse(":")
    capture noisily `0'
    if _rc != `want' {
        di as err `"unit test failed: {bf:`0'} returned "' _rc `", expected `want'"'
        exit 9
    }
    global UT_n = $UT_n + 1
end
global UT_n 0

* ---- dispatcher
_ut 198 : cgemod
_ut 198 : cgemod nosuchcommand

* ---- commands that need a calibrated model
capture mata: rmexternal("_cgemod_M")
_ut 301 : cgemod sim, tm(*0)
_ut 301 : cgemod check
_ut 301 : cgemod validate
_ut 301 : cgemod scenario run
_ut 301 : cgemod dynamic, periods(3)

* ---- samgen
_ut 198 : cgemod samgen, sectors(0)
_ut 198 : cgemod samgen, sectors(5) households(0)
_ut 198 : cgemod samgen, sectors(5) seed(-1)
_ut 0   : cgemod samgen, sectors(4) households(2) name(U4) nolist
assert rowsof(U4) == 4 + 4 + 2 + 2 + 6
mata: st_numscalar("gap", max(abs(rowsum(st_matrix("U4")) - colsum(st_matrix("U4"))')))
assert scalar(gap) < 1e-9
_ut 0   : cgemod samcheck, sam(U4) notable

* ---- calibrate: option checks
_ut 111 : cgemod calibrate, sam(NOSUCHSAM)
_ut 198 : cgemod calibrate, sam(U4) exchange(floating)
_ut 198 : cgemod calibrate, sam(U4) gsav(sometimes)
_ut 198 : cgemod calibrate, sam(U4) siclosure(other)
_ut 198 : cgemod calibrate, sam(U4) fiscal(lumpsum)
_ut 198 : cgemod calibrate, sam(U4) frisch(2)
_ut 198 : cgemod calibrate, sam(U4) tolerance(0)
_ut 198 : cgemod calibrate, sam(U4) solver(gauss)
_ut 0   : cgemod calibrate, sam(U4) notable
assert abs(r(bench_resid)) < 1e-8
assert "`r(solver)'" == "newton"

* ---- sim: shock syntax
_ut 198 : cgemod sim, tm(0.5)
_ut 111 : cgemod sim, tm(C_99=0)
_ut 198 : cgemod sim, tm(C_1=abc)
_ut 0   : cgemod sim, tm(*0) notable
assert r(iterations) >= 1 & r(max_resid) < 1e-8
_ut 0   : cgemod sim, notable
matrix UTM = r(macro)
assert abs(UTM[1,3]) < 1e-8

* ---- dynamic: option checks
_ut 198 : cgemod dynamic, periods(3) labor(LAB) capital(CAP) pubshare(1.5)
_ut 198 : cgemod dynamic, periods(3) labor(LAB) capital(CAP) eduelas(0.2)
_ut 0   : cgemod dynamic, periods(3) labor(LAB) capital(CAP) lgrowth(0.02) notable

* ---- scenario manager
cgemod scenario drop _all
_ut 198 : cgemod scenario
_ut 198 : cgemod scenario define 1bad, tm(*0)
_ut 198 : cgemod scenario define ok, nosuchoption(1)
_ut 198 : cgemod scenario define ok, tm(*0) closure(frisch(-2))
_ut 0   : cgemod scenario define ok, tm(*0)
_ut 110 : cgemod scenario define ok, tm(*0.5)
_ut 0   : cgemod scenario define ok, tm(*0.5) replace
_ut 111 : cgemod scenario run nosuch
_ut 0   : cgemod scenario define bad, tm(C_99=0)
_ut 0   : cgemod scenario run, notable
assert "`r(failed)'" == "bad"
matrix UTM = r(macro)
assert UTM[1,2] >= .
_ut 0   : cgemod scenario drop bad
_ut 111 : cgemod scenario drop bad
_ut 198 : cgemod scenario export using results.pdf
_ut 0   : cgemod scenario list
_ut 0   : cgemod scenario run, notable
_ut 0   : cgemod scenario table

* ---- validation suite
_ut 198 : cgemod validate, steps(1)
_ut 0   : cgemod validate, notable
assert r(failed) == 0

* ---- poverty
preserve
use cgemod_survey, clear
_ut 198 : cgemod poverty, group(group) welfare(pcexp) weight(weight) hhsize(hhsize)
restore

di as res _n "cgemod unit tests: $UT_n tests passed"
