*! PIRNEX Stata estimation prototype v2.1.4, 08nov2026; v2.0 frozen report preserved
* Authors: Zehra Yalnız; Figen Büyükakın; Sinan Bedir (doctoral student)
* License: MIT (see LICENSE)
program define pirnex
    version 16.0
    gettoken action rest : 0, parse(" ,")
    local actionlow = lower(strtrim(`"`action'"'))

    if `"`actionlow'"' == "version" {
        display as result "PIRNEX v2.0 (frozen reference); estimation prototype v2.1.4"
        exit
    }
    if `"`actionlow'"' == "report" {
        local 0 `"`rest'"'
        syntax [, FOLDER(string)]
        if `"`folder'"' == "" local folder `"`c(pwd)'"'
        local olddir `"`c(pwd)'"'
        capture cd `"`folder'"'
        if _rc {
            display as error "Folder not found: `folder'"
            exit 601
        }
        capture confirm file "pirnex_all_v20.do"
        if _rc {
            quietly cd `"`olddir'"'
            display as error "Frozen v2.0 report missing: pirnex_all_v20.do"
            exit 601
        }
        capture noisily do "pirnex_all_v20.do"
        local ret = _rc
        quietly cd `"`olddir'"'
        if `ret' exit `ret'
        exit
    }

    * New data-driven estimator: exactly two continuous and one binary predictor.
    local 0 `"`action' `rest'"'
    syntax varlist(min=4 max=4 numeric) [if] [in], ID(varname numeric) TIME(varname numeric) ///
        [FOLDER(string) BOOTS(integer 60) EPOCHS(integer 150) SEED(integer 20261108) ML EXPLAIN]
    if `boots' < 0 | `epochs' < 1 {
        display as error "boots() must be >= 0 and epochs() >= 1"
        exit 198
    }
    if "`explain'" != "" & "`ml'" == "" local ml "ml"
    tokenize `varlist'
    local outcome `1'
    local v1 `2'
    local v2 `3'
    local binary `4'
    if `"`outcome'"' == `"`id'"' | `"`outcome'"' == `"`time'"' {
        display as error "Outcome must differ from panel ID and time."
        exit 198
    }
    if `"`folder'"' == "" local folder `"`c(pwd)'/pirnex_run_v21"'
    capture mkdir `"`folder'"'
    local olddir `"`c(pwd)'"'

    * Locate the accompanying Python estimator and report in the current working directory.
    * Resolve dependencies before changing the working directory.
    * Using files in the command directory avoids Windows shell quoting of findfile macros.
    local engine "`olddir'\pirnex_est_engine_v21.py"
    local report "`olddir'\pirnex_est_report_v21.do"
    capture confirm file "`engine'"
    if _rc {
        display as error "Missing pirnex_est_engine_v21.py in `olddir'"
        exit 601
    }
    capture confirm file "`report'"
    if _rc {
        display as error "Missing pirnex_est_report_v21.do in `olddir'"
        exit 601
    }

    marksample touse
    markout `touse' `id' `time'
    preserve
    capture noisily {
        quietly keep if `touse'
        quietly keep `outcome' `v1' `v2' `binary' `id' `time'
        quietly assert inlist(`binary',0,1)
        quietly isid `id' `time'
        quietly bysort `id': keep if _N>=2
        quietly count
        if r(N)<100 {
            display as error "PIRNEX requires >=100 complete repeated observations (prototype safeguard)."
            error 2001
        }
        quietly egen byte __pn_tag = tag(`id')
        quietly count if __pn_tag
        if r(N)<60 {
            display as error "PIRNEX prototype requires >=60 individuals for ID-disjoint splits."
            error 2001
        }
        quietly drop __pn_tag
        quietly set seed `seed'
        tempfile pn_base pn_groups
        quietly save `pn_base'
        quietly bysort `id': keep if _n==1
            quietly keep `id'
            quietly gen double __pn_rand=runiform()
            quietly sort __pn_rand
            quietly gen byte __pn_grp=cond(_n<=floor(.60*_N),1,cond(_n<=floor(.80*_N),2,3))
            quietly keep `id' __pn_grp
        quietly save `pn_groups'
        quietly use `pn_base', clear
        quietly merge m:1 `id' using `pn_groups', assert(match) nogen
        quietly summ `v1' if __pn_grp==1, meanonly
        local min1=r(min)
        local range1=r(max)-r(min)
        quietly summ `v2' if __pn_grp==1, meanonly
        local min2=r(min)
        local range2=r(max)-r(min)
        if `range1'<=0 | `range2'<=0 {
            display as error "Predictors 1 and 2 must vary in the training sample."
            error 498
        }
        quietly summ `time', meanonly
        local mintime=r(min)
        quietly gen double x1=(`v1'-`min1')/`range1'
        quietly gen double x2=(`v2'-`min2')/`range2'
        quietly gen long yridx=`time'-`mintime'
        quietly assert yridx>=0 & yridx==floor(yridx)
        if `"`id'"' != "idcode" quietly rename `id' idcode
        if `"`outcome'"' != "y" quietly rename `outcome' y
        if `"`binary'"' != "union" quietly rename `binary' union
        quietly gen double fe_xb=0
        quietly cd `"`folder'"'
        * Ado command already has one outer preserve: use temporary snapshots
        * instead of nested preserve (which triggers Stata r(621)).
        quietly save `pn_base', replace
        foreach part in train valid test {
            local g=cond("`part'"=="train",1,cond("`part'"=="valid",2,3))
            quietly use `pn_base', clear
            quietly keep if __pn_grp==`g'
            quietly keep idcode yridx x1 x2 union y fe_xb
            quietly export delimited using "pinn_panel_`part'.csv", replace
        }
        quietly clear
        quietly set obs 1
        quietly gen double range_tenure=`range1'
        quietly gen double min_tenure=`min1'
        quietly gen double range_hours=`range2'
        quietly export delimited using "pinn_panel_ranges.csv", replace
        quietly use `pn_base', clear
        display as text "PIRNEX prototype: estimating `outcome' on `v1' `v2' `binary'"
        display as text "Output folder: `folder'"
        capture erase "pirnex_metrics_v17.csv"
        capture erase "pirnex_unified_v17.csv"
        * Copy helpers into current output directory, then use short relative names.
        quietly copy "`engine'" "pirnex_est_engine_v21.py", replace
        quietly copy "`report'" "pirnex_est_report_v21.do", replace
        noisily shell python "pirnex_est_engine_v21.py" --folder "." --epochs `epochs' --boots `boots' --names `v1' `v2' `binary' --seed `seed'
        confirm file "pirnex_metrics_v17.csv"
        confirm file "pirnex_unified_v17.csv"
        noisily do "pirnex_est_report_v21.do"
        if "`ml'" != "" {
            quietly copy "`olddir'\pirnex_ml_report_v213.do" "pirnex_ml_report_v213.do", replace
            capture erase "pirnex_ml_comparison_v18.csv"
            capture erase "pirnex_ml_test_pairs_v18.csv"
            capture erase "pirnex_explain_summary_v20.csv"
            capture erase "pirnex_neural_ig_summary_v19.csv"
            capture erase "pirnex_neural_ig_metrics_v19.csv"
            * Explicit helper copies avoid nested macro/path parsing in Stata.
            quietly copy "`olddir'\pirnex_ml_engine_v18.py" "pirnex_ml_engine_v18.py", replace
            quietly copy "`olddir'\pirnex_shap_engine_v20.py" "pirnex_shap_engine_v20.py", replace
            quietly copy "`olddir'\pirnex_ig_engine_v19.py" "pirnex_ig_engine_v19.py", replace
            quietly copy "`olddir'\pirnex_engine_v17.py" "pirnex_engine_v17.py", replace
            noisily shell python "pirnex_ml_engine_v18.py" --folder "." --ebm 1
            confirm file "pirnex_ml_comparison_v18.csv"
            * Explanations are optional only when explain is requested.
            if "`explain'" != "" {
                noisily shell python "pirnex_shap_engine_v20.py" --folder "." --ebm 1
                confirm file "pirnex_explain_summary_v20.csv"
                noisily shell python "pirnex_ig_engine_v19.py" --folder "." --steps 128 --epochs `epochs'
                confirm file "pirnex_neural_ig_summary_v19.csv"
            }
            noisily do "pirnex_ml_report_v213.do"
        }
    }
    local rc=_rc
    restore
    quietly cd `"`olddir'"'
    if `rc' exit `rc'
end
