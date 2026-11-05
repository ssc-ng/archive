program define rregmm, rclass          
    version 17
    *! Version 1.0.11 LBautista 18Sep2026
    *! Changes from 1.0.10:
    *! - Graph marker appearance now follows the active Stata scheme by default
    *! - Added options to customize marker appearance by week type
    *! - Quietly drops non-evaluation-year observations before saving output (silence "observations deleted")
    *! - Quietly restores original dataset (silence file label output)

    syntax varlist(max=3 numeric) [if] [in] ///
        [, YEVAL(int 0) RYSPAN(int 0) SEED(int 0) ///
           LOGSCALE JITTer ///
           YSRANGE(numlist min=2 max=2) ///
           YVALUES(numlist) ///
           GRTITLE(string) ///
           BASELINEOPTS(string asis) ALARMOPTS(string asis) ///
           ALERTOPTS(string asis) EPIDEMICOPTS(string asis) ///
           GRSave(string) FSave(string) ///
           GRCURVE ]

    marksample touse
    preserve
    quietly keep if `touse'
    capture unab __junk : __0*
    if !_rc {
        capture drop `__junk'
    }

    if `seed' != 0 {
        quietly set seed `seed'
    }

    local firstvar  : word 1 of `varlist'
    local secondvar : word 2 of `varlist'
    local thirdvar  : word 3 of `varlist'
    local sm1 = `yeval' - `ryspan'

    /*Base variable for smoothing / regression: optionally jittered*/
    local basevar "`firstvar'"
    if "`jitter'" != "" {
        qui gen double `firstvar'jit = `firstvar' + rnormal(1, 0.5)
        qui replace `firstvar'jit = 0.0001 if `firstvar'jit <= 0
        label var `firstvar'jit "`firstvar' with jitter N(1,0.5)"
        local basevar "`firstvar'jit"
    }

    qui generate date = yw(`secondvar', `thirdvar')
    label var date "Date (`secondvar'/`thirdvar')"
    format date %tw
    tsset date

    /*Log of (possibly jittered) series, with +0.5 offset for zeros/missing*/
    qui gen l = `basevar'
    qui replace l = `basevar' + 0.5 if `basevar' == 0 | `basevar' == .
    qui gen log_`firstvar' = ln(l)
    label var log_`firstvar' "Log of (possibly jittered) number of cases of `firstvar'"
    drop l

    /*Smoothed series based on basevar (original or jittered)*/
    tssmooth nl `firstvar'_sm = `basevar', smoother(3S5RHE, twice)
    label var `firstvar'_sm "`firstvar', smoothed number of cases"
    qui gen log_`firstvar'_sm = ln(`firstvar'_sm)
    label var log_`firstvar'_sm "Log of smoothed number of cases of `firstvar'"
    qui gen `firstvar'_sm_no_`yeval' = `firstvar'_sm
    label var `firstvar'_sm_no_`yeval' "`firstvar' smoothed and without outliers"

    /*Robust regression by week*/
    forvalues i = 1(1)52 {
        qui robreg mm `firstvar'_sm `secondvar' if `thirdvar'==`i' & ///
            `secondvar'<=`yeval'-1 & `secondvar'>=`sm1', relax
        predict res_`thirdvar'_`i'_`yeval', rs
        qui replace res_`thirdvar'_`i'_`yeval' = . if `thirdvar'!=`i' | `secondvar'!=`yeval'
        predict out_`thirdvar'_`i'_`yeval', outlier
        qui replace out_`thirdvar'_`i'_`yeval' = . if `thirdvar'!=`i' | `secondvar'!=`yeval'
    }

    qui gen residual_`yeval' = .
    forvalues i = 1(1)52 {
        qui replace residual_`yeval' = res_`thirdvar'_`i'_`yeval' if `thirdvar'==`i'
    }
    label var residual_`yeval' "Robust standardized residual for `yeval'"

    qui gen outlier_`yeval' = .
    forvalues i = 1(1)52 {
        qui replace outlier_`yeval' = out_`thirdvar'_`i'_`yeval' if `thirdvar'==`i' & `secondvar'==`yeval'
    }
    label define ynlb 0 No 1 Yes
    label var outlier_`yeval' "Outlier week"
    label values outlier_`yeval' ynlb

    qui gen loutlier_`yeval' = .
    qui replace loutlier_`yeval' = 1 if outlier_`yeval'==1 & `secondvar'==`yeval' & residual_`yeval'>=2.25
    label var loutlier_`yeval' "Large outlier (residual>=2.5)"
    label values loutlier_`yeval' ynlb

    qui gen soutlier_`yeval' = .
    qui replace soutlier_`yeval' = 1 if outlier_`yeval'==1 & `secondvar'==`yeval' & residual_`yeval'<=-2.25
    label var soutlier_`yeval' "Small outlier (residual<=-2.5)"
    label values soutlier_`yeval' ynlb

    /*Define week type (4 types)*/
    quietly summ residual_`yeval', meanonly
    local rbar = r(mean)
    qui gen wbaseline_`yeval' = `firstvar'_sm if residual_`yeval' <= -2.5
    label var wbaseline_`yeval' "Baseline `thirdvar'"
    qui gen walarm_`yeval' = `firstvar'_sm if residual_`yeval'> -2.5 & residual_`yeval' <= `rbar'
    label var walarm_`yeval' "Alarm `thirdvar'"
    qui gen walert_`yeval' = `firstvar'_sm if residual_`yeval' > `rbar' & residual_`yeval' < 2.5
    label var walert_`yeval' "Alert `thirdvar'"
    qui gen wepid_`yeval' = `firstvar'_sm if residual_`yeval' >=  2.5
    label var wepid_`yeval' "Epidemic `thirdvar'"
    drop res_`thirdvar'* out_`thirdvar'*

    foreach var in residual_`yeval' outlier_`yeval' loutlier_`yeval' soutlier_`yeval' ///
                   wbaseline_`yeval' walarm_`yeval' walert_`yeval' wepid_`yeval' {
        qui replace `var' = . if `secondvar'!=`yeval'
    }

    quietly summ residual_`yeval', meanonly
    local rbar = r(mean)

    qui gen byte wtype = .
    qui replace wtype = 0 if residual_`yeval' <= -2.5
    qui replace wtype = 1 if residual_`yeval'> -2.5 & residual_`yeval' <= `rbar'
    qui replace wtype = 2 if residual_`yeval' > `rbar' & residual_`yeval' < 2.5
    qui replace wtype = 3 if residual_`yeval' >=  2.5
    label var wtype "Type of `thirdvar'"

    quietly capture label list wzonelb
    if _rc {
        label define wzonelb 0 "Baseline (= LB)" ///
                             1 "Alert (LB, Mean]" ///
                             2 "Alarm (Mean, UB]" ///
                             3 "Epidemic (>= UB)"
    }
    label values wtype wzonelb

    /*-- y-axis options --*/
    local yopts ""
    local ylab  ""

    if "`logscale'" != "" {
        if "`ysrange'" != "" local yopts "yscale(log range(`ysrange'))"
        else                 local yopts "yscale(log)"
    }
    else {
        if "`ysrange'" != "" local yopts "yscale(range(`ysrange'))"
    }

    if "`yvalues'" != "" {
        local ylab "ylabel(`yvalues')"
    }

    /*-- grtitle options --*/
    local titopt
    if "`grtitle'" != "" {
        local titopt `"title(`"`grtitle'"', size(small) justification(left))"'
    }
    else {
        local titopt ///
        `"title("Epidemic curve for `firstvar', by type of `thirdvar'; `secondvar' `yeval'; method: mm-robust regression.", size(small) justification(left))"'
    }

    /*--Graph control--*/
    if "`grcurve'" == "" {
        local grcurve "grcurve"
    }

    if "`grcurve'" != "" {
        local baselineopt ""
        local alarmopt    ""
        local alertopt    ""
        local epidemicopt ""
        if `"`baselineopts'"' != "" local baselineopt `", `baselineopts'"'
        if `"`alarmopts'"'    != "" local alarmopt    `", `alarmopts'"'
        if `"`alertopts'"'    != "" local alertopt    `", `alertopts'"'
        if `"`epidemicopts'"' != "" local epidemicopt `", `epidemicopts'"'

        twoway (scatter wbaseline_`yeval' `thirdvar' if `secondvar'==`yeval' `baselineopt') ///
               (scatter walarm_`yeval'    `thirdvar' if `secondvar'==`yeval' `alarmopt')    ///
               (scatter walert_`yeval'    `thirdvar' if `secondvar'==`yeval' `alertopt')    ///
               (scatter wepid_`yeval'     `thirdvar' if `secondvar'==`yeval' `epidemicopts'), ///
               `yopts' `ylab' ///
               `titopt' ///
               ytitle("Number of cases")

        if "`grsave'" != "" {
            local gfile "`grsave'"
            if substr("`gfile'", -4, .) != ".gph" local gfile "`gfile'.gph"
            qui graph save "`gfile'", replace
            di as text "Graph saved as: {bf:`gfile'}"
        }
    }

    /*Save output file*/
    local outfile "`firstvar'_`yeval'_`ryspan'.dta"
    if "`fsave'" != "" {
        local outfile "`fsave'"
    }

    tempfile __hold
    quietly save "`__hold'", replace

    quietly keep if `secondvar' == `yeval'
    capture drop __000000
    rename `secondvar' ytested
    label var ytested "Evaluation year (yeval)"

    quietly save "`outfile'", replace
    di as text "Look for the output of this analysis in file: {bf:`outfile'}"

    quietly use "`__hold'", clear
end
