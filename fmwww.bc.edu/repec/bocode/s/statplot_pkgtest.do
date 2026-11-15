*! statplot 1.3.3 -- package test
*  Eric A. Booth and Nicholas J. Cox
*  Runs on Stata 16 or later (frame() and the final section need 16; the
*  % suffix in 1b is drawn only on Stata 19 or later).

clear all
set more off
local vabbrev = c(varabbrev)
set varabbrev off      // the checks must not lean on abbreviated names

*----------------------------------------------------------------------*
* 0.  Where to write the example graphs (edit if you like)
*----------------------------------------------------------------------*
local out "."          // current working directory
capture mkdir "`out'/statplot_examples"
local g "`out'/statplot_examples"

* small assert helper (relative difference)
capture program drop _spchk
program _spchk
    args got want tag
    if reldif(`got',`want') > 1e-6 {
        di as err "CHECK FAILED [`tag']: got `got', want `want'"
        exit 9
    }
    di as txt "  ok  [`tag']"
end


*======================================================================*
di as txt _n "{hline 70}"
di as res    "PART 1 -- the new features, one graph each"
di as txt    "{hline 70}"
*======================================================================*

*--- 1a. Confidence intervals on group means (the headline addition) --*
sysuse nlsw88, clear
statplot wage, over(race) ci ///
    title("Mean hourly wage by race, with 95% CI")
graph export "`g'/01_ci_hbar.png", replace width(900)

* several variables -> small multiples, one panel per variable.
* Each panel is titled with its variable label (via graph -by()-), so leave the
* overall title off here; a user title() would repeat once per panel.
statplot wage ttl_exp tenure, over(race) ci
graph export "`g'/02_ci_panels.png", replace width(1000)

* recast as vertical bars or as a dot/interval plot.
* baropts() styles the CI bars; ciopts() styles the whiskers.
statplot wage, over(race) ci recast(bar) ///
    baropts(fcolor(navy) lcolor(navy)) ciopts(lcolor(gs6))
graph export "`g'/03_ci_bar.png", replace width(900)
statplot wage, over(race) ci recast(dot) level(90) ciopts(lcolor(gs6))
graph export "`g'/04_ci_dot.png", replace width(900)

*--- 1b. Percentages of a 0/1 indicator, with a % sign on each bar -----*
* (blabel suffix() needs Stata 19+; earlier Stata draws the number alone)
if c(stata_version) >= 19 local pct suffix(%)
statplot union, over(race) percent ///
    blabel(bar, format(%2.0f) `pct') ///
    title("Union membership rate by race")
graph export "`g'/05_percent.png", replace width(900)

*--- 1c. Shares of a total -------------------------------------------*
sysuse census, clear
statplot marriage divorce, over(region) s(sum) share base(var) ///
    title(`"Marriages and divorces: "' `"share across regions (each var = 100%)"')
graph export "`g'/06_share.png", replace width(900)

*--- 1d. Wrapping long labels ----------------------------------------*
* wrap() breaks labels longer than # characters onto several lines. With a
* handful of bars the lines have room; a chart with many tall over() categories
* will also want a larger ysize() and/or a smaller label size.
sysuse nlsw88, clear
statplot ttl_exp tenure grade hours, wrap(18) ///
    title("Wrapped variable labels")
graph export "`g'/07_wrap.png", replace width(900)

*--- 1e. Ordering: rank by value, pin a category last ----------------*
sysuse citytemp, clear
statplot tempjan tempjuly heatdd cooldd, sort descending ///
    title("Variables ordered high-to-low by mean")
graph export "`g'/08_sort.png", replace width(900)

*--- 1e2. Headings and groups among the bars (coefplot-style) ---------*
* headings() = section-title rows (bars shift down); groups() = side brackets.
sysuse auto, clear
statplot price mpg weight length headroom trunk, ///
    headings(price = "{bf:Cost}" mpg = "{bf:Efficiency}" weight = "{bf:Size}") ///
    title("headings(): section titles among the bars")
graph export "`g'/10_headings.png", replace width(900)

statplot price mpg weight length headroom trunk, ci ///
    groups(price mpg = "{bf:Performance}" weight length headroom trunk = "{bf:Dimensions}") ///
    title("groups(): bracket labels beside spans")
graph export "`g'/11_groups.png", replace width(900)

*--- 1f. Keep / view the numbers behind the bars ---------------------*
sysuse citytemp, clear
statplot heatdd cooldd, over(region) listdata          // to the screen
statplot heatdd cooldd, over(region) savedata("`g'/09_results", replace)
if c(stata_version) >= 16 {
    statplot heatdd cooldd, over(region) frame(sp_results)
    frame dir
}


*======================================================================*
di as txt _n "{hline 70}"
di as res    "PART 2 -- checks: new options do not change the calculation"
di as txt    "{hline 70}"
*======================================================================*

* (A) default path still equals collapse -----------------------------*
sysuse citytemp, clear
tempfile sd
qui statplot heatdd cooldd, over(region) savedata("`sd'", replace)
preserve
    collapse (mean) heatdd, by(region)
    qui su heatdd if region==1, meanonly
    local truth = r(mean)
restore
preserve
    use "`sd'", clear
    qui su heatdd if region==1, meanonly
    _spchk `r(mean)' `truth' "default path == collapse"
restore

* (B) percent == 100 x mean ------------------------------------------*
sysuse nlsw88, clear
qui statplot union, over(race) percent savedata("`sd'", replace)
qui su union if race==2, meanonly
local want = r(mean)*100
preserve
    use "`sd'", clear
    qui su union if race==2, meanonly
    _spchk `r(mean)' `want' "percent == 100*mean"
restore

* (C) ci bounds == ci means ------------------------------------------*
sysuse nlsw88, clear
qui statplot wage, over(race) ci savedata("`sd'", replace)
qui ci means wage if race==2
local lb = r(lb)
preserve
    use "`sd'", clear
    qui su lo if race==2, meanonly
    _spchk `r(mean)' `lb' "ci lower bound == ci means"
restore

* (D) wrap and sort leave the values untouched -----------------------*
sysuse citytemp, clear
qui statplot heatdd cooldd, over(region) wrap(6) sort savedata("`sd'", replace)
preserve
    collapse (mean) heatdd, by(region)
    qui su heatdd if region==3, meanonly
    local truth = r(mean)
restore
preserve
    use "`sd'", clear
    qui su heatdd if region==3, meanonly
    _spchk `r(mean)' `truth' "wrap+sort keep values"
restore

* (E) since 1.3.2: long labels and space-less scripts ----------------------*
sysuse citytemp, clear
label variable heatdd "this is a very very long story about Heating degree days"

* a label past 32 characters must not error and must not move the values
qui statplot heatdd, over(region) savedata("`sd'", replace)
preserve
    collapse (mean) heatdd, by(region)
    qui su heatdd if region==3, meanonly
    local truth = r(mean)
restore
preserve
    use "`sd'", clear
    qui su heatdd if region==3, meanonly
    _spchk `r(mean)' `truth' "long label keeps values"
restore

* varopts() must still be able to suppress and to replace the label
capture qui statplot heatdd, over(region) varopts(label(nolabel))
if _rc {
    di as err "CHECK FAILED [varopts label(nolabel)]: rc=" _rc
    exit 9
}
di as txt "  ok  [varopts label(nolabel)]"

* a user relabel() must win over the one statplot builds, with no clash
capture qui statplot heatdd, over(region) wrap(18) varopts(relabel(1 "Short"))
if _rc {
    di as err "CHECK FAILED [user relabel beats wrap]: rc=" _rc
    exit 9
}
di as txt "  ok  [user relabel beats wrap]"

* a space-less (CJK) label must wrap without error and keep its values
label variable heatdd "这是一个关于高温天数的很长很长很长的故事"
qui statplot heatdd, over(region) wrap(18) savedata("`sd'", replace)
preserve
    use "`sd'", clear
    qui su heatdd if region==3, meanonly
    _spchk `r(mean)' `truth' "CJK wrap keeps values"
restore

* (F) 1.3.3 ----------------------------------------------------------*
* small helpers: assert a return code; load the plotted serset of a
* twoway (ci) graph as (zero mean position lo hi)
capture program drop _sprc
program _sprc
    args got want tag
    if `got' != `want' {
        di as err "CHECK FAILED [`tag']: rc `got', want `want'"
        exit 9
    }
    di as txt "  ok  [`tag']"
end
capture program drop _spserset
program _spserset
    serset set 0
    serset use, clear
    unab sv : _all
    rename (`sv') (zero mn pos lo hi)
end

* ci in hbar: the first group is drawn on top, as in graph hbar, and
* sort descending puts the largest mean on top
sysuse citytemp, clear
qui statplot heatdd, over(region) ci
preserve
    _spserset
    qui su pos, meanonly
    local top = r(max)
    qui su mn if pos == `top', meanonly
    local got = r(mean)
restore
qui su heatdd if region == 1, meanonly
_spchk `got' `r(mean)' "ci hbar: first group on top"

qui statplot heatdd, over(region) ci sort descending
preserve
    _spserset
    qui su pos, meanonly
    local top = r(max)
    qui su mn if pos == `top', meanonly
    local got = r(mean)
    qui su mn, meanonly
    local want = r(max)
restore
_spchk `got' `want' "ci hbar sort descending: largest on top"

* ci in bar keeps the first group on the left
qui statplot heatdd, over(region) ci recast(bar)
preserve
    _spserset
    qui su mn if pos == 1, meanonly
    local got = r(mean)
restore
qui su heatdd if region == 1, meanonly
_spchk `got' `r(mean)' "ci bar: first group on the left"

* a group with a single observation gets no interval (not a zero-width one)
sysuse auto, clear
gen grp = cond(_n == 1, 9, foreign)
qui statplot price, over(grp) ci savedata("`sd'", replace)
preserve
    use "`sd'", clear
    qui count if N == 1 & missing(lo) & missing(hi)
    _spchk `=r(N)' 1 "ci: no interval for a group of one"
    qui count if N > 1 & !missing(lo) & !missing(hi)
    _spchk `=r(N)' 2 "ci: intervals kept for larger groups"
restore

* the exported grouping variable holds its own values (foreign is 0/1),
* not the group codes 1, 2
qui statplot price, over(foreign) savedata("`sd'", replace)
qui su price if foreign == 1, meanonly
local want = r(mean)
preserve
    use "`sd'", clear
    qui count if inlist(foreign, 0, 1)
    _spchk `=r(N)' 2 "savedata keeps the over() values"
    qui su price if foreign == 1, meanonly
    _spchk `r(mean)' `want' "savedata values line up with the over() values"
    if "`: value label foreign'" != "origin" {
        di as err "CHECK FAILED [savedata keeps the value label]"
        exit 9
    }
    di as txt "  ok  [savedata keeps the value label]"
restore

* percent rescales the saved se with the mean and bounds
gen dear = price > 6000
qui statplot dear, over(foreign) ci percent savedata("`sd'", replace)
qui ci means dear if foreign == 1
local want = 100*r(se)
preserve
    use "`sd'", clear
    qui su se if foreign == 1, meanonly
    _spchk `r(mean)' `want' "ci percent: se on the percent scale"
restore

* weighted intervals equal ci means with the same weights
qui statplot price [aw=weight], over(foreign) ci savedata("`sd'", replace)
qui ci means price [aw=weight] if foreign == 0
local want = r(ub)
preserve
    use "`sd'", clear
    qui su hi if foreign == 0, meanonly
    _spchk `r(mean)' `want' "ci aweight == ci means"
restore
gen fw = cond(missing(rep78), 1, rep78)
qui statplot price [fw=fw], over(foreign) ci savedata("`sd'", replace)
qui ci means price [fw=fw] if foreign == 1
local want = r(lb)
preserve
    use "`sd'", clear
    qui su lo if foreign == 1, meanonly
    _spchk `r(mean)' `want' "ci fweight == ci means"
restore

* r(varlist) is the plotted order under ci, as it is without ci
qui statplot price mpg weight, sort
local want `r(varlist)'
qui statplot price mpg weight, sort ci
if "`r(varlist)'" != "`want'" {
    di as err "CHECK FAILED [ci r(varlist) order]: `r(varlist)' vs `want'"
    exit 9
}
di as txt "  ok  [ci r(varlist) order]"

* share applies with headings() (it was ignored there)
sysuse citytemp, clear
qui statplot heatdd cooldd, share headings(heatdd = "Degree days") savedata("`sd'", replace)
preserve
    use "`sd'", clear
    qui su mean, meanonly
    _spchk `=r(sum)' 100 "share with headings sums to 100"
restore

* sort copes with an all-missing variable
gen allmiss = .
capture qui statplot heatdd allmiss cooldd, sort
_sprc `=_rc' 0 "sort with an all-missing variable"

* savedata() accepts a path with spaces
capture mkdir "`g'/a folder"
qui statplot heatdd, over(region) savedata("`g'/a folder/res file", replace)
capture confirm file "`g'/a folder/res file.dta"
_sprc `=_rc' 0 "savedata path with spaces"
capture erase "`g'/a folder/res file.dta"
capture rmdir "`g'/a folder"

* a backtick in a variable or value label no longer stops the command
mata: st_varlabel("heatdd", "Don" + char(96) + "t know")
mata: st_vlmodify("bt_lbl", 1, "a " + char(96) + "tick")
gen bt = 1 + (region > 2)
label values bt bt_lbl
capture qui statplot heatdd cooldd, over(bt)
_sprc `=_rc' 0 "backtick in labels"
capture qui statplot heatdd, over(bt) ci wrap(4)
_sprc `=_rc' 0 "backtick in labels, ci + wrap"

* clear messages for mistakes
sysuse auto, clear
capture statplot price, over(rep78) over(foreign) over(headroom)
_sprc `=_rc' 198 "third over() refused"
capture statplot price [iw=weight], over(foreign) ci
_sprc `=_rc' 198 "iweights refused with ci"
capture statplot price mpg, headings(price "Cost")
_sprc `=_rc' 198 "malformed headings() refused"

* the data in memory, and their sort order, are unchanged
sysuse auto, clear
sort mpg make
qui datasignature
local sig `r(datasignature)'
qui statplot price mpg, over(foreign) savedata("`sd'", replace) listdata
qui statplot price mpg, ci sort savedata("`sd'", replace)
qui statplot price, over(rep78) ci missing
if c(stata_version) >= 16 qui statplot price, over(foreign) frame(sp_check)
qui datasignature
if "`r(datasignature)'" != "`sig'" | "`: sortedby'" != "mpg make" {
    di as err "CHECK FAILED [data unchanged]"
    exit 9
}
di as txt "  ok  [data and sort order unchanged]"

* wrap(): ASCII words stay whole (as in 1.3.0); text without spaces is
* split between characters (unit test of the private helper)
discard      // unload the ado copy before -run- defines its programs directly
qui findfile statplot.ado
qui run "`r(fn)'"
_statplot_wrap , width(12) text("internationalization of telecommunications")
if `"`s(wrapped)'"' != `""internationalization" "of" "telecommunications" "' {
    di as err `"CHECK FAILED [wrap keeps ASCII words]: `s(wrapped)'"'
    exit 9
}
di as txt "  ok  [wrap keeps ASCII words whole]"
_statplot_wrap , width(12) text("这是一个关于高温天数的故事")
if `"`s(wrapped)'"' != `""这是一个关于" "高温天数的故" "事" "' {
    di as err `"CHECK FAILED [wrap splits CJK]: `s(wrapped)'"'
    exit 9
}
di as txt "  ok  [wrap splits text without spaces]"
discard

set varabbrev `vabbrev'
di as res _n "ALL statplot 1.3.3 CHECKS PASSED"
di as txt "Example graphs written to: `g'"
