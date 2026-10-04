*! duvm_examples 1.2.1  2026-10-01  Abdelkrim Araar
*! The examples of help duvm and help duvmdiag, run from their links.
*!   duvm_examples #          run example # in the command window
*!   duvm_examples #, db      open the dialog box of duvm filled in for example #
*!   duvm_examples #, do      open example # as a do-file in the Do-file Editor
*! The data in memory are never lost: the run keeps them (preserve) and gives
*! them back at the end, even after an error or a Break; the do-file does the
*! same; the dialog box, which needs the example data in memory, refuses to
*! replace data that have unsaved changes. Files written by the examples go to
*! Stata's temporary folder, c(tmpdir), never to the working folder.
*! The example data are an ancillary file: read from the current folder
*! (where "ssc install duvm, all" or "net get duvm" copies it), else from
*! the SSC archive, else from GitHub (_duvm_exload); nothing is written.
program define duvm_examples
    version 14.2
    syntax anything(name=ex id="example number") [, DB DO NOEDIT]
    capture confirm integer number `ex'
    if _rc | !inrange(`ex', 1, 9) {
        di as err "duvm_examples: the examples are numbered 1 to 9 (see help duvm)"
        exit 198
    }
    if "`db'" != "" & "`do'" != "" {
        di as err "duvm_examples: db and do cannot be combined"
        exit 198
    }
    * Stata's temporary folder, with its separator
    local T = c(tmpdir)
    local T : subinstr local T "\" "/", all
    if substr("`T'", -1, 1) != "/" local T "`T'/"
    local G "corn wheat rice other [aw=sweight], hhsize(hhsize) expend(hh_current_inc) cluster(psu) region(rururb) indcat(sex educ) indcon(age)"
    local n 0
    if `ex' == 1 {
        local title "Estimating the elasticities, with the diagnostics and the quality parameters"
        local c1 "duvm `G'"
        local c2 "estat diagnostics"
        local c3 "estat quality"
        local n 3
    }
    else if `ex' == 2 {
        local title "With the survey design"
        local c1 "svyset psu [pweight=sweight], strata(strata) vce(linearized) singleunit(missing)"
        local c2 "duvm corn wheat rice other, hhsize(hhsize) expend(hh_current_inc) cluster(psu) region(rururb) indcat(sex educ) indcon(age) vce(svy)"
        local n 2
    }
    else if `ex' == 3 {
        local title "Bootstrap of both stages (50 replications for the example)"
        local c1 "duvm `G' vce(bootstrap, reps(50) seed(1))"
        local n 1
    }
    else if `ex' == 4 {
        local title "Own-price elasticities by decile of per capita expenditure"
        local c1 "duvm `G' hgroup(decile)"
        local n 1
    }
    else if `ex' == 5 {
        local title "Selection of the buyers: the diagnostic, then the correction of corn, wheat and rice"
        local c1 "duvmdiag `G' selection"
        local c2 "duvm `G' selgoods(corn wheat rice)"
        local n 2
    }
    else if `ex' == 6 {
        local title "Variables of the probit only: for rice only, for all three, then for two goods of the three"
        local c1 "duvm `G' selgoods(corn wheat rice) selvars(rice: perc_ocupa)"
        local c2 "duvm `G' selgoods(corn wheat rice) selvars(perc_ocupa)"
        local c3 "duvm `G' selgoods(corn wheat rice) selvars(wheat: perc_ocupa ; rice: nocup0)"
        local n 3
    }
    else if `ex' == 7 {
        local title "The tables in a Word file, then with significance stars on screen"
        local c1 `"duvm `G' saveres("`T'duvm_results.docx")"'
        local c2 "duvm, stars"
        local n 2
    }
    else if `ex' == 8 {
        local title "Engel curves after estimation"
        local c1 "duvm `G' notable"
        local c2 "predict w_corn, share good(corn)"
        local c3 "predict se_w_corn, share good(corn) stdp"
        local c4 "estat engel"
        local c5 "estat engel, quality lnx"
        local c6 `"estat engel, quantity normalize level(90) data("`T'engel_q")"'
        local n 6
    }
    else if `ex' == 9 {
        local title "The diagnostic before estimating"
        local c1 "duvmdiag `G'"
        local n 1
    }

    * ---- as a do-file, in Stata's temporary folder ----
    if "`do'" != "" {
        local fn "`T'duvm_example_`ex'.do"
        tempname fh
        file open `fh' using "`fn'", write text replace
        file write `fh' "* duvm, example `ex': `title'" _n
        file write `fh' "* Written by duvm_examples in Stata's temporary folder; save it elsewhere to keep it." _n
        file write `fh' "* preserve keeps the data in memory and gives them back when this do-file ends;" _n
        file write `fh' "* delete that line to keep working on the example data." _n
        file write `fh' "preserve" _n
        file write `fh' "* the example data: the current folder (where ssc install duvm, all copies" _n
        file write `fh' "* them), else the SSC archive, else GitHub" _n
        file write `fh' "capture use mexico_2014_cereals, clear" _n
        file write `fh' `"if _rc capture use "http://fmwww.bc.edu/repec/bocode/m/mexico_2014_cereals.dta", clear"' _n
        file write `fh' `"if _rc use "https://raw.githubusercontent.com/aabbdd12/duvm/main/examples/mexico_2014_cereals.dta", clear"' _n
        forvalues i = 1/`n' {
            file write `fh' `"`c`i''"' _n
        }
        file close `fh'
        if "`noedit'" == "" doedit "`fn'"
        di as txt "(example `ex' written to " as res `"`fn'"' as txt ")"
        exit
    }

    * ---- in the dialog box: needs the example data in memory ----
    if "`db'" != "" {
        if `ex' == 9 {
            di as err "duvm_examples: duvmdiag has no dialog box; run example 9 in the command window"
            exit 198
        }
        * the example data loaded for a dialog box carry a mark, here
        * _dta[duvm_example], and _dta[easi_example] or _dta[equaids_example]
        * from the examples of easi and equaids (easi builds prices in levels
        * on them, which sets c(changed)): they are replaced without asking;
        * the user's own data with changes are not
        local isex 0
        local cl : char _dta[]
        foreach c of local cl {
            if substr("`c'", -8, .) == "_example" & `"`: char _dta[`c']'"' == "1" local isex 1
        }
        if c(changed) & !`isex' {
            di as err "duvm_examples, db: the data in memory have changes not saved;"
            di as err "save them (or clear) first: the dialog box needs the example data in memory"
            exit 4
        }
        _duvm_exload
        char _dta[duvm_example] "1"
        if `ex' == 2 qui svyset psu [pweight=sweight], strata(strata) vce(linearized) singleunit(missing)
        di as txt "(example data mexico_2014_cereals loaded for the dialog box)"
        db duvm
        * Stata keeps the state of the dialog between two openings: every
        * control an example may set is first put back to its default
        .duvm_dlg.main.ed_qother.setvalue "0.25"
        .duvm_dlg.main.ck_nosym.setoff
        .duvm_dlg.main.cb_nb.setvalue ""
        .duvm_dlg.main.ck_compat.setoff
        .duvm_dlg.main.vn_sub.setvalue ""
        .duvm_dlg.se.rb_cluster.seton
        .duvm_dlg.se.ed_reps.setvalue "200"
        .duvm_dlg.se.ed_seed.setvalue ""
        .duvm_dlg.se.ck_bsvy.setoff
        .duvm_dlg.se.ck_short.setoff
        .duvm_dlg.se.vn_strata.setvalue ""
        .duvm_dlg.se.vn_psu.setvalue ""
        .duvm_dlg.sel.ed_selg.setvalue ""
        .duvm_dlg.sel.vl_all.setvalue ""
        forvalues r = 1/10 {
            .duvm_dlg.sel.ed_g`r'.setvalue ""
            .duvm_dlg.sel.vl_v`r'.setvalue ""
        }
        .duvm_dlg.sel.cb_ng.setvalue "0"
        .duvm_dlg.sel.ck_sel.setoff
        .duvm_dlg.rpt.vn_hgroup.setvalue ""
        .duvm_dlg.rpt.ck_stars.setoff
        .duvm_dlg.rpt.ck_seall.setoff
        .duvm_dlg.rpt.ck_dreg.setoff
        .duvm_dlg.rpt.ck_notab.setoff
        .duvm_dlg.rpt.fi_save.setvalue ""
        .duvm_dlg.rpt.rb_hh.seton
        .duvm_dlg.weights.vl_wgt.setvalue ""
        .duvm_dlg.weights.rb_none.seton
        * the example
        .duvm_dlg.main.ed_goods.setvalue "corn wheat rice other"
        .duvm_dlg.main.vn_hhsize.setvalue "hhsize"
        .duvm_dlg.main.vn_expend.setvalue "hh_current_inc"
        .duvm_dlg.main.vn_cluster.setvalue "psu"
        .duvm_dlg.main.vn_region.setvalue "rururb"
        .duvm_dlg.main.vl_indcat.setvalue "sex educ"
        .duvm_dlg.main.vl_indcon.setvalue "age"
        if `ex' == 2 {
            .duvm_dlg.se.rb_svy.seton
        }
        else {
            .duvm_dlg.weights.rb_aw.seton
            .duvm_dlg.weights.vl_wgt.setvalue "sweight"
        }
        if `ex' == 3 {
            .duvm_dlg.se.rb_boot.seton
            .duvm_dlg.se.ed_reps.setvalue "50"
            .duvm_dlg.se.ed_seed.setvalue "1"
        }
        if `ex' == 4 {
            .duvm_dlg.rpt.vn_hgroup.setvalue "decile"
        }
        if inlist(`ex', 5, 6) {
            .duvm_dlg.sel.ck_sel.seton
            .duvm_dlg.sel.ed_selg.setvalue "corn wheat rice"
        }
        if `ex' == 6 {
            .duvm_dlg.sel.cb_ng.setvalue "2"
            .duvm_dlg.sel.ed_g1.setvalue "wheat"
            .duvm_dlg.sel.vl_v1.setvalue "perc_ocupa"
            .duvm_dlg.sel.ed_g2.setvalue "rice"
            .duvm_dlg.sel.vl_v2.setvalue "nocup0"
        }
        if `ex' == 7 {
            .duvm_dlg.rpt.ck_stars.seton
            .duvm_dlg.rpt.fi_save.setvalue `"`T'duvm_results.docx"'
        }
        exit
    }

    * ---- in the command window: the data in memory are kept ----
    preserve
    _duvm_exload
    local src "`r(source)'"
    di as txt _n "{hline 78}" _n "duvm, example `ex': " as res "`title'" _n as txt "{hline 78}"
    di as txt "(example data mexico_2014_cereals.dta, read from `src'; the data in memory come back at the end)"
    forvalues i = 1/`n' {
        di as txt _n `". `c`i''"'
        `c`i''
    }
    if inlist(`ex', 7, 8) di as txt _n `"(files written to `T')"'
end

* ============================================================================
* the data of the examples, an ancillary file of the package: from the
* current folder (where "ssc install duvm, all" or "net get duvm" copies it),
* else from the SSC archive, else from GitHub; nothing is written to disk
program define _duvm_exload, rclass
    capture confirm file "mexico_2014_cereals.dta"
    if !_rc {
        quietly use "mexico_2014_cereals.dta", clear
        return local source "the current folder"
        exit
    }
    capture quietly use "http://fmwww.bc.edu/repec/bocode/m/mexico_2014_cereals.dta", clear
    if !_rc {
        return local source "the SSC archive"
        exit
    }
    capture quietly use "https://raw.githubusercontent.com/aabbdd12/duvm/main/examples/mexico_2014_cereals.dta", clear
    if !_rc {
        return local source "GitHub"
        exit
    }
    di as err "duvm_examples: mexico_2014_cereals.dta is not in the current folder (`c(pwd)'),"
    di as err "  and neither the SSC archive nor GitHub could be reached."
    di as txt "  Copy the example data into the current folder with"
    di as txt `"  {stata "ssc install duvm, all replace"} (from SSC), or"'
    di as txt `"  {stata "net get duvm, from(https://raw.githubusercontent.com/aabbdd12/duvm/main)"} (from GitHub)."'
    exit 601
end
