* run_idxnl_certification.do
* Certification run for the idxnl package (version 1.2.2).
*
* How to use:
*   1. Unzip idxnl_stata_package.zip.
*   2. In Stata, change directory into the unzipped "idxnl" folder (cd ".../idxnl").
*   3. do run_idxnl_certification.do
* A log file, idxnl_certification.log, is written to the same folder.

version 14
clear all
set more off
capture log close _all
discard

local pkgdir "`c(pwd)'"
log using "`pkgdir'/idxnl_certification.log", replace text name(cert)

display as txt "{hline 78}"
display as txt "idxnl certification run"
display as txt "Stata version: " as res c(stata_version) as txt "   flavor: " as res c(flavor) ///
    as txt "   date: " as res c(current_date) " " c(current_time)
display as txt "Package folder: " as res "`pkgdir'"
display as txt "{hline 78}"

* ------------------------------------------------------------------ 0. load package from this folder
foreach f in idxspec.ado idxint.ado idxtp.ado idxdescribe.ado _idxtp_core.ado ///
    _idxnl_dkrepost.ado _idxnl_cd.ado _idxspec_iv.ado _idxspec_simex.ado ///
    idxnl_example.dta idxnl_cert.do {
    capture confirm file "`pkgdir'/`f'"
    if _rc {
        display as err "file `f' not found in `pkgdir'; cd into the unzipped idxnl folder first"
        log close cert
        exit 601
    }
}
adopath ++ "`pkgdir'"
foreach c in idxspec idxint idxtp idxdescribe _idxtp_core _idxnl_dkrepost _idxnl_cd _idxspec_iv _idxspec_simex {
    which `c'
}

local npass = 0
local nfail = 0
local faillist ""

* ------------------------------------------------------------------ 1. bundled certification script
display _n as txt "{hline 78}" _n "PART 1: bundled certification script (idxnl_cert.do)" _n "{hline 78}"
capture noisily do "`pkgdir'/idxnl_cert.do"
local rc1 = _rc
if `rc1' == 0 {
    local ++npass
    display as res "PART 1 PASSED"
}
else {
    local ++nfail
    local faillist "`faillist' part1(rc=`rc1')"
    display as err "PART 1 FAILED with return code `rc1'; the failing assertion is printed just above"
}

* ------------------------------------------------------------------ 2. independent checks against Stata's own commands
display _n as txt "{hline 78}" _n "PART 2: independent checks against official Stata commands" _n "{hline 78}"
use "`pkgdir'/idxnl_example.dta", clear
xtset id year

* 2a. turning point and delta-method SE (pooled): idxtp vs nlcom
capture noisily {
    quietly regress y c.gov##c.gov w1 w2 i.year, vce(cluster id)
    quietly nlcom (tp: -_b[gov]/(2*_b[c.gov#c.gov]))
    tempname bn Vn
    matrix `bn' = r(b)
    matrix `Vn' = r(V)
    local tp_nl = `bn'[1,1]
    local se_nl = sqrt(`Vn'[1,1])
    idxtp gov, nodisplay
    display as txt "  pooled: idxtp tp = " %14.10f r(tp) "  nlcom = " %14.10f `tp_nl'
    display as txt "          idxtp se = " %14.10f r(se_tp) "  nlcom = " %14.10f `se_nl'
    assert reldif(r(tp), `tp_nl') < 1e-8
    assert reldif(r(se_tp), `se_nl') < 1e-6
}
if _rc == 0 {
    local ++npass
    display as res "  2a passed"
}
else {
    local ++nfail
    local faillist "`faillist' 2a"
    display as err "  2a FAILED"
}

* 2b. same check with fixed effects
capture noisily {
    capture drop gov_sq
    generate double gov_sq = gov^2
    quietly xtreg y gov gov_sq w1 w2 i.year, fe vce(cluster id)
    quietly nlcom (tp: -_b[gov]/(2*_b[gov_sq]))
    tempname bn Vn
    matrix `bn' = r(b)
    matrix `Vn' = r(V)
    local tp_nl = `bn'[1,1]
    local se_nl = sqrt(`Vn'[1,1])
    idxtp gov, sq(gov_sq) nodisplay
    display as txt "  FE:     idxtp tp = " %14.10f r(tp) "  nlcom = " %14.10f `tp_nl'
    display as txt "          idxtp se = " %14.10f r(se_tp) "  nlcom = " %14.10f `se_nl'
    assert reldif(r(tp), `tp_nl') < 1e-8
    assert reldif(r(se_tp), `se_nl') < 1e-6
}
if _rc == 0 {
    local ++npass
    display as res "  2b passed"
}
else {
    local ++nfail
    local faillist "`faillist' 2b"
    display as err "  2b FAILED"
}

* 2c. idxspec turning point and SE equal idxtp after the same model
capture noisily {
    quietly regress y c.gov##c.gov w1 w2 i.year, vce(cluster id)
    idxtp gov, nodisplay
    local tp_a = r(tp)
    local se_a = r(se_tp)
    local lm_a = r(lm_t)
    idxspec y gov w1 w2 i.year, vce(cluster id) notable
    display as txt "  idxspec tp = " %14.10f r(tp) "  idxtp tp = " %14.10f `tp_a'
    assert reldif(r(tp), `tp_a') < 1e-8
    assert reldif(r(se_tp), `se_a') < 1e-6
    assert reldif(r(lm_t), `lm_a') < 1e-6
}
if _rc == 0 {
    local ++npass
    display as res "  2c passed"
}
else {
    local ++nfail
    local faillist "`faillist' 2c"
    display as err "  2c FAILED"
}

* 2d. Lind-Mehlum slopes by hand (lincom) on the supported interval
capture noisily {
    quietly regress y c.gov##c.gov w1 w2 i.year, vce(cluster id)
    quietly _pctile gov if e(sample), percentiles(5 95)
    local lo = r(r1)
    local hi = r(r2)
    quietly lincom gov + 2*(`lo')*c.gov#c.gov
    local tlo = r(estimate)/r(se)
    quietly lincom gov + 2*(`hi')*c.gov#c.gov
    local thi = r(estimate)/r(se)
    local tlm = cond(_b[c.gov#c.gov] < 0, min(`tlo', -(`thi')), min(-(`tlo'), `thi'))
    idxtp gov, nodisplay
    display as txt "  Lind-Mehlum t: idxtp = " %12.8f r(lm_t) "  lincom = " %12.8f `tlm'
    assert reldif(r(t_lo), `tlo') < 1e-6
    assert reldif(r(t_hi), `thi') < 1e-6
    assert reldif(r(lm_t), `tlm') < 1e-6
}
if _rc == 0 {
    local ++npass
    display as res "  2d passed"
}
else {
    local ++nfail
    local faillist "`faillist' 2d"
    display as err "  2d FAILED"
}

* 2e. Fieller interval: endpoints must make the t statistic of b1 + 2*b2*theta equal to the critical value
capture noisily {
    quietly regress y c.gov##c.gov w1 w2 i.year, vce(cluster id)
    local crit = invttail(e(df_r), 0.025)
    idxtp gov, nodisplay
    if "`r(fieller_type)'" != "unbounded" {
        local f1 = r(fieller_lb)
        local f2 = r(fieller_ub)
        foreach f in `f1' `f2' {
            quietly lincom gov + 2*(`f')*c.gov#c.gov
            local tt = abs(r(estimate)/r(se))
            display as txt "  Fieller endpoint " %10.5f `f' ": |t| = " %10.6f `tt' "  (critical value " %8.5f `crit' ")"
            assert reldif(`tt', `crit') < 1e-5
        }
    }
    else display as txt "  Fieller set unbounded; endpoint check not applicable"
}
if _rc == 0 {
    local ++npass
    display as res "  2e passed"
}
else {
    local ++nfail
    local faillist "`faillist' 2e"
    display as err "  2e FAILED"
}

* 2f. IV quadratic: idxspec, iv() vs ivregress with generated instruments
capture noisily {
    capture drop gov_l2 xh xh2 gsq
    generate double gov_l2 = L2.gov
    quietly regress gov gov_l2 w1 w2 i.year if !missing(gov_l2, y), vce(cluster id)
    quietly predict double xh if e(sample), xb
    generate double xh2 = xh^2
    generate double gsq = gov^2
    quietly ivregress 2sls y w1 w2 i.year (gov gsq = xh xh2), small vce(cluster id)
    local b1 = _b[gov]
    local b2 = _b[gsq]
    idxspec y gov w1 w2 i.year, iv(gov_l2) vce(cluster id) notable
    display as txt "  IV b(x):   idxspec = " %12.8f r(b1) "  ivregress = " %12.8f `b1'
    display as txt "  IV b(x^2): idxspec = " %12.8f r(b2) "  ivregress = " %12.8f `b2'
    assert reldif(r(b1), `b1') < 1e-6
    assert reldif(r(b2), `b2') < 1e-6
}
if _rc == 0 {
    local ++npass
    display as res "  2f passed"
}
else {
    local ++nfail
    local faillist "`faillist' 2f"
    display as err "  2f FAILED"
}

* 2g. interaction model (A): idxint vs regress
capture noisily {
    quietly regress y c.gov2##c.gov1 w1 w2 i.year, vce(cluster id)
    local bxz = _b[c.gov2#c.gov1]
    local sxz = _se[c.gov2#c.gov1]
    idxint y gov2 gov1 w1 w2 i.year, vce(cluster id) notable
    display as txt "  b(x*z): idxint = " %12.8f r(b_xz_A) "  regress = " %12.8f `bxz'
    assert reldif(r(b_xz_A), `bxz') < 1e-8
    assert reldif(r(se_xz_A), `sxz') < 1e-6
}
if _rc == 0 {
    local ++npass
    display as res "  2g passed"
}
else {
    local ++nfail
    local faillist "`faillist' 2g"
    display as err "  2g FAILED"
}

* 2h. invariance: affine recoding leaves test statistics unchanged and maps the turning point
capture noisily {
    capture drop gov100
    generate double gov100 = (gov + 2.5)/5*100
    idxspec y gov w1 w2 i.year, vce(cluster id) notable
    local tp0 = r(tp)
    local lm0 = r(lm_t)
    local pq0 = r(p_quad)
    idxspec y gov100 w1 w2 i.year, vce(cluster id) notable
    assert reldif(r(tp), (`tp0' + 2.5)/5*100) < 1e-6
    assert reldif(r(lm_t), `lm0') < 1e-5
    assert reldif(r(p_quad), `pq0') < 1e-5
}
if _rc == 0 {
    local ++npass
    display as res "  2h passed"
}
else {
    local ++nfail
    local faillist "`faillist' 2h"
    display as err "  2h FAILED"
}

* 2i. graphs and remaining options run without error
capture noisily {
    set seed 20261109
    quietly idxspec y gov w1 w2 i.year, fe vce(cluster id) graph notable
    graph close _all
    quietly idxint y gov2 gov1 w1 w2 i.year, vce(cluster id) graph notable
    graph close _all
    quietly idxdescribe gov gov1 gov2, bounds(-2.5 2.5)
    quietly idxdescribe ict, bounds(0 100)
    quietly idxspec y gov w1 w2 i.year, rankby(year) vce(cluster id) notable
    quietly idxspec y gov w1 w2 i.year, fe cce vce(cluster id) notable
    quietly idxspec y gov w1 w2 i.year, fe twoway notable
    quietly idxspec y gov w1 w2 i.year, fe dk notable
}
if _rc == 0 {
    local ++npass
    display as res "  2i passed"
}
else {
    local ++nfail
    local faillist "`faillist' 2i"
    display as err "  2i FAILED"
}

* ------------------------------------------------------------------ summary
display _n as txt "{hline 78}"
display as txt "SUMMARY: " as res `npass' as txt " passed, " as res `nfail' as txt " failed"
if `nfail' > 0 display as err "Failed parts:`faillist'"
else display as res "idxnl 1.2.2 certified on this installation"
display as txt "Log file: " as res "`pkgdir'/idxnl_certification.log"
display as txt "{hline 78}"
log close cert
