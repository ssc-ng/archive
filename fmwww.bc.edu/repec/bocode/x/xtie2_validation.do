version 17
clear all
set more off
set seed 271828
set obs 240
gen int panel = ceil(_n/12)
bysort panel: gen int year = 2000 + _n
xtset panel year
gen double x1 = rnormal()
gen double x2 = rnormal() + 0.2*x1
gen double z = rnormal() + panel/30
gen double y = 0.7*x1 - 0.3*x2 + 0.4*z + 0.5*x1*x2 + 0.2*x1*z - 0.15*x2*z + panel/10 + rnormal()
replace z = . in 1
adopath ++ "."
xtie2 y x1 x2 z, robust level(95)
assert e(cmd)=="xtie2"
assert e(level)==95
scalar oldcrit = e(critical_x2)
quietly summarize z if e(sample), meanonly
scalar zbar = r(mean)
quietly summarize x2 if e(sample), meanonly
scalar x2bar = r(mean)
quietly summarize x2 if e(sample), detail
scalar x2min = r(min)
quietly lincom _b[x1] + zbar*_b[c.x1#c.z] + _b[c.x1#c.x2]*0.5
scalar manual = r(estimate)
scalar manualse = r(se)
scalar derived = _b[x1] + zbar*_b[c.x1#c.z] + 0.5*_b[c.x1#c.x2]
assert abs(manual-derived)<1e-9
quietly lincom _b[x1] + zbar*_b[c.x1#c.z] + x2min*_b[c.x1#c.x2]
assert r(se)<.
assert abs(r(estimate)-(_b[x1]+zbar*_b[c.x1#c.z]+x2min*_b[c.x1#c.x2]))<1e-9
assert abs(me_x1 - (_b[x1]+zbar*_b[c.x1#c.z]+_b[c.x1#c.x2]*x2))<1e-9 if e(sample)
assert abs(oldcrit + (_b[x1]+zbar*_b[c.x1#c.z])/_b[c.x1#c.x2])<1e-9
assert missing(me_x1) if !e(sample)
capture noisily xtie2 y x1 x2 z, robust
assert _rc != 0
drop me_x1 me_x2 regime_x2
xtie2 y x1 x2 z, pair(x2 z) robust level(90)
assert e(level)==90
assert e(primary_interaction)=="x2 x z"
quietly summarize x1 if e(sample), meanonly
scalar x1bar = r(mean)
assert abs(me_x2-(_b[x2]+x1bar*_b[c.x2#c.x1]+_b[c.x2#c.z]*z))<1e-9 if e(sample)
di as result "Core, selected pair, full derivative, stored results and overwrite checks passed."
