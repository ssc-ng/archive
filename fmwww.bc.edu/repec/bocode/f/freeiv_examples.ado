*! freeiv_examples 1.0.0  06oct2026  A. Araar (Universite Laval / PEP)
*! The examples of help freeiv, run from their links, in three forms that give
*! the same commands:
*!   freeiv_examples # [k]          estimation k of example # (1 when omitted),
*!                                  run in the command window
*!   freeiv_examples # [k], db      the dialog box of freeiv filled in with the
*!                                  same estimation: OK runs the same command
*!   freeiv_examples #, do          the whole example as a do-file in the
*!                                  Do-file Editor: the data, every estimation
*!                                  and the other commands, in the order of the
*!                                  help
*!   freeiv_examples #, data        the data of example #, the first line of its
*!                                  listing in the help; the other commands of
*!                                  the example (freeivmenu, freeivtest...) run
*!                                  from their own links there
*! An estimation of an example is one freeiv command (preceded by set seed for
*! a bootstrap).  It loads the example data itself, with the commands that
*! prepare them (example 7 generates lwage), and leaves them in memory, so that
*! the other commands of the example can follow.  The example data carry a
*! mark, _dta[freeiv_example] (setting it marks the data as changed), and are
*! replaced without asking, as are the example data of the author's other
*! packages (_dta[*_example]); data with changes not saved are never replaced.
*! The datasets freeiv_sim1, freeiv_sim2, freeiv_card and freeiv_proxy are
*! ancillary files of the package, read from the current folder (where
*! "ssc install freeiv, all" or "net get freeiv" copies them), else beside the
*! command or in the examples/ folder of a copy of the repository, else from
*! the SSC archive, else from GitHub (_freeiv_exload); nothing is written but
*! the do-file, in Stata's temporary folder.  Example 7 uses nlsw88 (sysuse),
*! example 8 nhanes2 (webuse: an internet connection is needed).

cap program drop freeiv_examples
cap program drop _freeiv_exload
cap program drop _freeiv_exdb

program define freeiv_examples, rclass
    version 16
    syntax anything(name=exk id="example number") [, DB DO DATA NOEDIT]
    gettoken ex exk : exk
    gettoken k  exk : exk
    if `"`exk'"' != "" {
        di as err "freeiv_examples: the example number, then the estimation, as in freeiv_examples 3 2"
        exit 198
    }
    capture confirm integer number `ex'
    if _rc | !inrange(`ex', 1, 12) {
        di as err "freeiv_examples: the examples are numbered 1 to 12 (see help freeiv)"
        exit 198
    }
    local kgiven = ("`k'" != "")
    if !`kgiven' local k 1
    capture confirm integer number `k'
    if _rc {
        di as err "freeiv_examples: the estimation is a number, as in freeiv_examples 3 2"
        exit 198
    }
    if ("`db'" != "") + ("`do'" != "") + ("`data'" != "") > 1 {
        di as err "freeiv_examples: db, do and data cannot be combined"
        exit 198
    }
    if `kgiven' & ("`do'" != "" | "`data'" != "") {
        di as err "freeiv_examples: `do'`data' takes the example number alone (the whole example)"
        exit 198
    }

    * ---- the examples, as listed in help freeiv ----
    * dta: the dataset; s`i': the commands that prepare it; v`j'_`i': the
    * commands of estimation j (one, or set seed and a bootstrap); vl`j': its
    * label in the help; vdb`j' = 0 when the dialog box cannot write it (the
    * bootstrap prefix); f`i': the commands that follow the data, in order
    local C3 "lwage exper expersq black south smsa"
    local ns 0
    if `ex' == 1 {
        local title "Where the model holds"
        local dta "freeiv_sim1"
        local nv 4
        local v1_1 "freeiv y1 x (y2)"
        local vl1 "qme, the default"
        local v2_1 "freeiv y1 x (y2), method(all)"
        local vl2 "method(all)"
        local v3_1 "freeiv y1 x (y2), method(gmm)"
        local vl3 "method(gmm)"
        local v4_1 "freeiv y1 x (y2), method(pgmm)"
        local vl4 "method(pgmm)"
        local f1 "freeivmenu y1 x (y2)"
        local f2 "`v1_1'"
        local f3 "`v2_1'"
        local f4 "`v3_1'"
        local f5 "display e(g_gmm), e(ar_lo), e(ar_hi), e(ar_frac)"
        local f6 "`v4_1'"
        local nf 6
    }
    else if `ex' == 2 {
        local title "The edge of identification"
        local dta "freeiv_sim2"
        local nv 1
        local v1_1 "freeiv y1 x (y2), method(all)"
        local vl1 "method(all)"
        local f1 "freeivmenu y1 x (y2)"
        local f2 "`v1_1'"
        local nf 2
    }
    else if `ex' == 3 {
        local title "Real data with one regressor: the interval is the result"
        local dta "freeiv_card"
        local nv 2
        local v1_1 "freeiv `C3' (educ), method(all)"
        local vl1 "all the controls, method(all)"
        local v2_1 "freeiv lwage exper expersq (educ)"
        local vl2 "exper expersq only"
        local f1 "freeivmenu `C3' (educ)"
        local f2 "`v1_1'"
        local f3 "`v2_1'"
        local f4 "freeivdiag"
        local nf 4
    }
    else if `ex' == 4 {
        local title "An estimate from elsewhere, against the interval"
        local dta "freeiv_card"
        local nv 1
        local v1_1 "freeiv `C3' (educ)"
        local vl1 "qme, the default"
        local f1 "`v1_1'"
        local f2 "freeivtest, gamma(0.132) segamma(0.049)"
        local nf 2
    }
    else if `ex' == 5 {
        local title "A second indicator of the confounder"
        local dta "freeiv_card"
        local nv 3
        local v1_1 "freeiv `C3' (educ motheduc)"
        local vl1 "motheduc"
        local v2_1 "freeiv `C3' (educ IQ)"
        local vl2 "IQ"
        local v3_1 "freeiv `C3' (educ KWW)"
        local vl3 "KWW"
        local f1 "freeivmenu `C3' (educ motheduc)"
        local f2 "`v1_1'"
        local f3 "freeivtest"
        * a guard refuses IQ and KWW: freeiv ends with r(498), which would
        * stop the do-file before KWW
        local f4 "* a guard refuses IQ and KWW, r(498): capture noisily keeps the do-file going"
        local f5 "capture noisily `v2_1'"
        local f6 "capture noisily `v3_1'"
        local nf 6
    }
    else if `ex' == 6 {
        local title "Two indicators with a known truth"
        local dta "freeiv_proxy"
        local nv 1
        local v1_1 "freeiv y1 x (y2 y3)"
        local vl1 "two indicators"
        local f1 "`v1_1'"
        local f2 "freeivtest"
        local nf 2
    }
    else if `ex' == 7 {
        local title "A model the data refute"
        local dta "nlsw88"
        local s1 "generate lwage = ln(wage)"
        local ns 1
        local nv 1
        local v1_1 "freeiv lwage grade age i.race (tenure)"
        local vl1 "qme, the default"
        local f1 "freeivmenu lwage grade age i.race (tenure)"
        local f2 "`v1_1'"
        local nf 2
    }
    else if `ex' == 8 {
        local title "Survey data"
        local dta "nhanes2"
        local nv 2
        local v1_1 "freeiv bpsystol age female black (bmi), vce(svy)"
        local vl1 "vce(svy)"
        local v2_1 "freeiv bpsystol age female black (bmi) [pweight=finalwgt]"
        local vl2 "pweights"
        local f1 "svyset"
        local f2 "`v1_1'"
        local f3 "`v2_1'"
        local nf 3
    }
    else if `ex' == 9 {
        local title "Inference for a route with no analytic standard error"
        local dta "freeiv_card"
        local nv 1
        local v1_1 "set seed 20261006"
        local v1_2 "bootstrap, reps(500): freeiv `C3' (educ), method(lewbel12)"
        local vl1 "the bootstrap of lewbel12"
        local vdb1 0
        local f1 "`v1_1'"
        local f2 "`v1_2'"
        local nf 2
    }
    else if `ex' == 10 {
        local title "The qme near the edge: the bootstrap against the delta method"
        local dta "freeiv_sim1"
        local nv 2
        local v1_1 "freeiv y1 x (y2)"
        local vl1 "the delta method"
        local v2_1 "set seed 20261006"
        local v2_2 "bootstrap, reps(500): freeiv y1 x (y2)"
        local vl2 "the bootstrap"
        local vdb2 0
        local f1 "`v1_1'"
        local f2 "`v2_1'"
        local f3 "`v2_2'"
        local nf 3
    }
    else if `ex' == 11 {
        local title "Oster's answer depends on what is assumed: report a range"
        local dta "freeiv_card"
        local nv 2
        local v1_1 "freeiv `C3' (educ), method(oster) rmax(0.5)"
        local vl1 "rmax(0.5)"
        local v2_1 "freeiv `C3' (educ), method(oster) delta(2) rmax(0.8)"
        local vl2 "delta(2) rmax(0.8)"
        local f1 "`v1_1'"
        local f2 "`v2_1'"
        local nf 2
    }
    else if `ex' == 12 {
        local title "Factor variables among the controls give what hand-made terms give"
        local dta "freeiv_card"
        local nv 1
        local v1_1 "freeiv lwage c.exper##c.exper i.black i.south i.smsa (educ), method(all)"
        local vl1 "factor variables, method(all)"
        local f1 "`v1_1'"
        local nf 1
    }
    forvalues j = 1/`nv' {
        if "`vdb`j''" == "" local vdb`j' 1
        local vn`j' = 1 + (`"`v`j'_2'"' != "")
    }
    if !inrange(`k', 1, `nv') {
        if `nv' == 1 di as err "freeiv_examples: example `ex' has one estimation"
        else         di as err "freeiv_examples: example `ex' has `nv' estimations, 1 to `nv'"
        exit 198
    }
    if "`db'" != "" & !`vdb`k'' {
        di as err "freeiv_examples: no dialog box for `vl`k'' (example `ex'):"
        di as err "  the dialog box does not write the bootstrap prefix; use the command window"
        exit 198
    }

    * ---- the whole example, as a do-file in Stata's temporary folder ----
    if "`do'" != "" {
        local T = c(tmpdir)
        local T : subinstr local T "\" "/", all
        if substr("`T'", -1, 1) != "/" local T "`T'/"
        local fn "`T'freeiv_example_`ex'.do"
        tempname fh
        file open `fh' using "`fn'", write text replace
        file write `fh' "* freeiv, example `ex': `title'" _n
        file write `fh' "* The commands of the links of help freeiv, written by freeiv_examples in" _n
        file write `fh' "* Stata's temporary folder: save this file elsewhere to keep it.  The example" _n
        file write `fh' "* data replace the data in memory: if yours have changes not saved, save them" _n
        file write `fh' "* first." _n
        if "`dta'" == "nlsw88" {
            file write `fh' "sysuse nlsw88, clear" _n
        }
        else if "`dta'" == "nhanes2" {
            file write `fh' "* the manual's data, from Stata's web site" _n
            file write `fh' "webuse nhanes2, clear" _n
        }
        else {
            file write `fh' "* the example data: the current folder (where ssc install freeiv, all copies" _n
            file write `fh' "* them), else the SSC archive, else GitHub" _n
            file write `fh' "capture use `dta', clear" _n
            file write `fh' `"if _rc capture use "http://fmwww.bc.edu/repec/bocode/f/`dta'.dta", clear"' _n
            file write `fh' `"if _rc use "https://raw.githubusercontent.com/aabbdd12/freeiv/main/examples/`dta'.dta", clear"' _n
        }
        forvalues i = 1/`ns' {
            file write `fh' `"`s`i''"' _n
        }
        forvalues i = 1/`nf' {
            file write `fh' `"`f`i''"' _n
        }
        file close `fh'
        if "`noedit'" == "" doedit "`fn'"
        di as txt "(example `ex' written to " as res `"`fn'"' as txt ")"
        return local fn `"`fn'"'
        exit
    }

    * ---- the other forms put the example data in memory and leave them there;
    *      data with changes not saved are never replaced, except example data
    *      (_dta[freeiv_example], or the mark of another package's examples)
    local isex 0
    local cl : char _dta[]
    foreach c of local cl {
        if substr("`c'", -8, .) == "_example" & `"`: char _dta[`c']'"' == "1" local isex 1
    }
    if c(changed) & !`isex' {
        di as err "freeiv_examples: the data in memory have changes not saved;"
        di as err "  save them (or clear) first: the example puts its own data in memory"
        exit 4
    }
    _freeiv_exload `dta'
    local note "data `dta', from `r(source)'"

    * the data alone: the first line of the listing; what prepares them is
    * the next line of the listing, with its own link
    if "`data'" != "" {
        char _dta[freeiv_example] "1"
        di as txt "(example `ex': `note')"
        exit
    }

    * an estimation prepares the data itself
    forvalues i = 1/`ns' {
        quietly `s`i''
    }
    char _dta[freeiv_example] "1"
    if `ns' == 1 local note `"`note', then `s1'"'

    * ---- in the dialog box ----
    if "`db'" != "" {
        db freeiv
        _freeiv_exdb `ex' `k'
        di as txt "(example `ex': `note')"
        di as txt "(the dialog box is filled in; OK runs " as res `"`v`k'_1'"' as txt ")"
        if `ex' == 11 di as txt "(delta() and rmax() are on its Estimator options tab)"
        return local cmd `"`v`k'_1'"'
        exit
    }

    * ---- in the command window ----
    di as txt "(example `ex': `note')"
    forvalues i = 1/`vn`k'' {
        di as txt _n `". `v`k'_`i''"'
        `v`k'_`i''
    }
    return local cmd `"`v`k'_`vn`k'''"'
end

* ============================================================================
* the data of the examples: nlsw88 and nhanes2 from Stata; the four datasets of
* the package, ancillary files, from the current folder (where "ssc install
* freeiv, all" or "net get freeiv" copies them), else beside the command or in
* the examples/ folder of a copy of the repository (src/../examples), else from
* the SSC archive, else from GitHub; nothing is written to disk
program define _freeiv_exload, rclass
    args f
    if "`f'" == "nlsw88" {
        quietly sysuse nlsw88, clear
        return local source "Stata's example datasets"
        exit
    }
    if "`f'" == "nhanes2" {
        capture quietly webuse nhanes2, clear
        if !_rc {
            return local source "Stata's web site"
            exit
        }
        di as err "freeiv_examples: nhanes2 could not be read with webuse (is the internet reachable?)"
        exit 631
    }
    capture confirm file "`f'.dta"
    if !_rc {
        quietly use "`f'.dta", clear
        return local source "the current folder"
        exit
    }
    capture findfile freeiv_examples.ado
    if !_rc {
        local here = subinstr("`r(fn)'", "\", "/", .)
        local here = substr("`here'", 1, strrpos("`here'", "/") - 1)
        foreach d in "`here'" "`here'/../examples" {
            capture confirm file "`d'/`f'.dta"
            if !_rc {
                quietly use "`d'/`f'.dta", clear
                return local source "`d'"
                exit
            }
        }
    }
    capture quietly use "http://fmwww.bc.edu/repec/bocode/f/`f'.dta", clear
    if !_rc {
        return local source "the SSC archive"
        exit
    }
    capture quietly use "https://raw.githubusercontent.com/aabbdd12/freeiv/main/examples/`f'.dta", clear
    if !_rc {
        return local source "GitHub"
        exit
    }
    di as err "freeiv_examples: `f'.dta is not in the current folder (`c(pwd)'),"
    di as err "  and it could not be read from the SSC archive or from GitHub."
    di as txt "  Copy the example data into the current folder with"
    di as txt `"  {stata "ssc install freeiv, all replace"} (from SSC), or"'
    di as txt `"  {stata "net get freeiv, from(https://raw.githubusercontent.com/aabbdd12/freeiv/main)"} (from GitHub)."'
    exit 601
end

* ============================================================================
* the dialog box filled in with estimation k of example ex: the controls that
* write the command a user would type, the one the help lists; what the
* dialog's own scripts show or hide is set explicitly too, in case setting a
* control from here does not run them
program define _freeiv_exdb
    args ex k
    * Stata keeps the state of a dialog between two openings: every control an
    * example may set is first put back to its default
    .freeiv_dlg.main.vn_dv.setvalue ""
    .freeiv_dlg.main.vn_en.setvalue ""
    .freeiv_dlg.main.vl_x.setvalue ""
    .freeiv_dlg.main.ck_two.setoff
    .freeiv_dlg.main.vn_en2.setvalue ""
    .freeiv_dlg.main.tx_en2.disable
    .freeiv_dlg.main.vn_en2.disable
    .freeiv_dlg.main.tx_m.show
    .freeiv_dlg.main.cb_m.show
    .freeiv_dlg.main.cb_m.setvalue "qme"
    .freeiv_dlg.opts.ed_d.setvalue "1"
    .freeiv_dlg.opts.ed_r.setvalue ""
    .freeiv_dlg.opts.rb_s1.seton
    .freeiv_dlg.rep.ck_nohd.setoff
    .freeiv_dlg.rep.sp_level.setvalue "`c(level)'"
    .freeiv_dlg.byifin.ck_by.setoff
    .freeiv_dlg.byifin.vl_by.setvalue ""
    .freeiv_dlg.byifin.vl_by.disable
    .freeiv_dlg.byifin.ed_if.setvalue ""
    .freeiv_dlg.byifin.ed_in.setvalue ""
    .freeiv_dlg.wgt.ck_svy.setoff
    .freeiv_dlg.wgt.rb_wnone.enable
    .freeiv_dlg.wgt.rb_wpw.enable
    .freeiv_dlg.wgt.rb_waw.enable
    .freeiv_dlg.wgt.rb_wnone.seton
    .freeiv_dlg.wgt.ed_wexp.setvalue ""
    .freeiv_dlg.wgt.tx_wexp.disable
    .freeiv_dlg.wgt.ed_wexp.disable

    * the model: dependent variable, endogenous regressor(s), controls
    local en2
    if inlist(`ex', 1, 2, 6, 10) {
        local dv "y1"
        local en "y2"
        local x  "x"
    }
    if inlist(`ex', 3, 4, 5, 9, 11) {
        local dv "lwage"
        local en "educ"
        local x  "exper expersq black south smsa"
    }
    if `ex' == 3 & `k' == 2 local x "exper expersq"
    if `ex' == 5 local en2 = word("motheduc IQ KWW", `k')
    if `ex' == 6 local en2 "y3"
    if `ex' == 7 {
        local dv "lwage"
        local en "tenure"
        local x  "grade age i.race"
    }
    if `ex' == 8 {
        local dv "bpsystol"
        local en "bmi"
        local x  "age female black"
    }
    if `ex' == 12 {
        local dv "lwage"
        local en "educ"
        local x  "c.exper##c.exper i.black i.south i.smsa"
    }
    .freeiv_dlg.main.vn_dv.setvalue "`dv'"
    .freeiv_dlg.main.vn_en.setvalue "`en'"
    .freeiv_dlg.main.vl_x.setvalue "`x'"

    * the estimator; qme, the default, is not written by the dialog
    local m "qme"
    if `ex' == 1 local m = word("qme all gmm pgmm", `k')
    if `ex' == 2 | `ex' == 12 | (`ex' == 3 & `k' == 1) local m "all"
    if `ex' == 11 local m "oster"
    if "`en2'" != "" {
        .freeiv_dlg.main.ck_two.seton
        .freeiv_dlg.main.tx_en2.enable
        .freeiv_dlg.main.vn_en2.enable
        .freeiv_dlg.main.vn_en2.setvalue "`en2'"
        .freeiv_dlg.main.tx_m.hide
        .freeiv_dlg.main.cb_m.hide
    }
    else .freeiv_dlg.main.cb_m.setvalue "`m'"
    if `ex' == 11 & `k' == 1 .freeiv_dlg.opts.ed_r.setvalue "0.5"
    if `ex' == 11 & `k' == 2 {
        .freeiv_dlg.opts.ed_d.setvalue "2"
        .freeiv_dlg.opts.ed_r.setvalue "0.8"
    }
    * the Estimator options tab, as the dialog's program check_method shows it
    local o = cond("`en2'" == "" & inlist("`m'", "oster", "all"), "show", "hide")
    local s = cond("`en2'" == "" & inlist("`m'", "lsz", "all"), "show", "hide")
    local n = cond("`o'" == "hide" & "`s'" == "hide", "show", "hide")
    foreach c in gb_o tx_d ed_d tx_dn tx_r ed_r tx_rn {
        .freeiv_dlg.opts.`c'.`o'
    }
    foreach c in gb_s tx_s rb_s1 rb_s2 {
        .freeiv_dlg.opts.`c'.`s'
    }
    .freeiv_dlg.opts.tx_noopt.`n'
    if "`en2'" != "" .freeiv_dlg.opts.tx_twonote.show
    else             .freeiv_dlg.opts.tx_twonote.hide

    * weights and design (example 8)
    if `ex' == 8 & `k' == 1 {
        .freeiv_dlg.wgt.ck_svy.seton
        .freeiv_dlg.wgt.rb_wnone.disable
        .freeiv_dlg.wgt.rb_wpw.disable
        .freeiv_dlg.wgt.rb_waw.disable
    }
    if `ex' == 8 & `k' == 2 {
        .freeiv_dlg.wgt.rb_wpw.seton
        .freeiv_dlg.wgt.tx_wexp.enable
        .freeiv_dlg.wgt.ed_wexp.enable
        .freeiv_dlg.wgt.ed_wexp.setvalue "finalwgt"
    }
end
