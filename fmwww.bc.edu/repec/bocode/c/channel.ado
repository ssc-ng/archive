program define channel                                        
    version 17
    *! Version 1.0.13 LBautista 22Sep2026
    *! - uses met(regmean/bsmedian/robmean)
    *! - adds yvalues(), grtitle(), grsave(), fsave()
    *! - ws = week span (half-window); adds wref = 2*ws+1
    *! - adds nograph: suppresses graph creation (and thus grsave)
    *! - adds logcases/rawcases for regmean (DEFAULT = logcases)
    *! - graph styles follow active scheme by default; adds meanopts(), lbopts(), ubopts(), obsopts()
    *! - vertical reference lines are off by default; xlines turns them on; xlineopts() customizes them
    *! - adds seed(); default seed(313151) controls random-number generation
    *! - adds reps(); default reps(1000) controls bootstrap replications for met(bsmedian)

qui {
        syntax varlist(min=3 max=3 numeric) ///
            [, yeval(int  0) yspan(int 0) wspan(int 0) SEED(integer 313151) ///
               MET(string) REPS(integer 1000) ///
               SMOOther(string) JITTer NOJITTer LOGscale ///
               LOGcases RAWcases ///
               YSRANGE(numlist min=2 max=2) ///
               YVALUES(numlist) ///
               GRTITLE(string) GRSAVE(string) FSave(string) ///
               MEANOPTS(string asis) LBOPTS(string asis) ///
               UBOPTS(string asis) OBSOPTS(string asis) ///
               XLINES XLINEOPTS(string asis) ///
               NOGraph ]

        tokenize `varlist'
        preserve
        marksample touse
        qui count if `touse'
        if `r(N)' == 0 {
            exit 198
        }
    }
    set linesize 180
    local firstvar  : word 1 of `varlist'
    local secondvar : word 2 of `varlist'
    local thirdvar  : word 3 of `varlist'

    scalar yend   = `yeval' - 1
    scalar ystart = `yeval' - `yspan'

    qui sum `secondvar'
    if (`yspan' < 5) {
        di as red "Warning: You selected less than 5 years of reference. Your results may be unstable."
    }
    if (`yeval' - `r(min)' < `yspan') {
        di as red "Warning: Earliest year is `r(min)'. Results are based on less than `yspan' years of reference and may be unstable."
    }
    
    /* Determine method from met()*/
    if "`met'" == "" {
        di as err "met() is required: met(regmean), met(robmean), or met(bsmedian)"
        exit 198
    }

    local method = lower("`met'")
    if !inlist("`method'", "regmean", "bsmedian", "robmean") {
        di as error "met() must be regmean, robmean, or bsmedian"
        exit 198
    }

    /*Jitter policy*/
    if "`jitter'" != "" & "`nojitter'" != "" {
        di as error "Specify only one of jitter or nojitter."
        exit 198
    }

    local _call "`0'"
    if inlist("`method'", "bsmedian", "robmean") & "`jitter'"=="" & "`nojitter'"=="" {
        local _call "`0' jitter"
    }

    /*logcases/rawcases policy (regmean only): Default=logcases (ln(cases+1)) unless user specifies rawcases*/
    if "`logcases'" != "" & "`rawcases'" != "" {
        di as error "Specify only one of logcases or rawcases."
        exit 198
    }

    if "`method'" == "regmean" {
        if "`rawcases'" == "" {
            * default to logcases if neither specified
            if "`logcases'" == "" local _call "`_call' logcases"
        }
        * rawcases selected: keep _call as-is (do not append logcases)
    }

		 /*Pass on command*/
		if "`method'" == "regmean" {
    	noisily regmean `_call'
	}
		else if "`method'" == "bsmedian" {
    	noisily bsmedian `_call'
	}
		else if "`method'" == "robmean" {
    	noisily robmean `_call'
	}

end

/**************************************************************************************************************************/
/*           Means smoothing method (STROUP)                                                                              */
/**************************************************************************************************************************/
program regmean, rclass   /*Stroup with graph*/
qui {
        syntax varlist(min=3 max=3 numeric) ///
            [, yeval(int  0) yspan(int 0) wspan(int 0) SEED(integer 313151) ///
               MET(string) ///
               SMOOther(string) JITTer LOGscale ///
               LOGcases RAWcases ///
               YSRANGE(numlist min=2 max=2) ///
               YVALUES(numlist) ///
               GRTITLE(string) GRSAVE(string) FSave(string) ///
               MEANOPTS(string asis) LBOPTS(string asis) ///
               UBOPTS(string asis) OBSOPTS(string asis) ///
               XLINES XLINEOPTS(string asis) ///
               NOGraph ]
    }
    local firstvar  : word 1 of `varlist'
    local secondvar : word 2 of `varlist'
    local thirdvar  : word 3 of `varlist'

    /*logcases/rawcases policy (regmean only): Default=logcases (ln(cases+1)) unless user specifies rawcases*/
    if "`logcases'" != "" & "`rawcases'" != "" {
        di as err "Specify only one of logcases or rawcases."
        exit 198
    }
    local _log = 1
    if "`rawcases'" != "" local _log = 0
    if "`logcases'" != "" local _log = 1

    qui keep if `secondvar'>=ystart & `secondvar'<=(yend + 1)
    qui sum `secondvar'

    tempname out0
    postfile `out0' `thirdvar' lb mean_`firstvar' ub stdf stdp obscases ytested ystart yend ws ws_used ///
        using `firstvar'_`yeval'_`wspan'_regmean.dta, replace

forvalues i = 1/52 {

    /*defaults for this week*/
    scalar mean_`firstvar' = .
    scalar lb   = .
    scalar ub   = .
    scalar stdf = .
    scalar stdp = .
    scalar ws_used = `wspan'

    /*create working outcome for this week*/
    tempvar ywork
    qui gen double `ywork' = `firstvar'
    if `_log' {
        qui replace `ywork' = ln(`firstvar' + 1)
    }

    local rc = 0
    local widened = 0
    local wspan2 = `wspan' + 1

    /*try requested window*/
    capture qui reg `ywork' if `thirdvar' >= `i' - `wspan' & `thirdvar' <= `i' + `wspan' & ///
        (`secondvar' >= ystart & `secondvar' <= yend)
    local rc = _rc

    /*if failed, try widened window once*/
    if (`rc') {
        capture qui reg `ywork' if `thirdvar' >= `i' - `wspan2' & `thirdvar' <= `i' + `wspan2' & ///
            (`secondvar' >= ystart & `secondvar' <= yend)
        local rc = _rc
        if (!`rc') {
            local widened = 1
            scalar ws_used = `wspan2'
            di as txt "Note: regmean failed for week `i' with wspan(`wspan'); using wspan(`wspan2') for this week."
        }
        else {
            di as err "Warning: regmean failed for week `i' with wspan(`wspan') and wspan(`wspan2'); results set to missing for this week."
        }
    }

    /*if model fit, compute mean + bounds*/
    if (!`rc') {
        scalar stdf = (e(rmse) / (e(N)) ^ 0.5) * (1 + (1 / e(N)) ^ 0.5)
        scalar stdp = (e(rmse) / (e(N)) ^ 0.5)

        capture qui lincom _cons
        if (!_rc) {
            scalar mean_`firstvar' = r(estimate)

            scalar __t  = invttail(e(df_r), 0.025)
            scalar __lb = mean_`firstvar' - (__t * stdf)
            scalar __ub = mean_`firstvar' + (__t * stdf)

            if `_log' {
                scalar mean_`firstvar' = exp(mean_`firstvar') - 1
                scalar lb = exp(__lb) - 1
                scalar ub = exp(__ub) - 1
                if (lb < 0) scalar lb = 0
                if (mean_`firstvar' < 0) scalar mean_`firstvar' = 0
            }
            else {
                scalar lb = __lb
                scalar ub = __ub
            }
        }
        else {
            di as error "Warning: regmean lincom failed for week `i'; results set to missing for this week."
            scalar mean_`firstvar' = .
            scalar lb   = .
            scalar ub   = .
            scalar stdf = .
            scalar stdp = .
        }
    }

    qui sum `firstvar' if `thirdvar' == `i' & `secondvar' == `yeval'
    scalar obscases = r(mean)
    scalar ytested  = `yeval'
    scalar ws       = `wspan'

    post `out0' (`thirdvar') (lb) (mean_`firstvar') (ub) (stdf) (stdp) ///
        (obscases) (ytested) (ystart) (yend) (ws) (ws_used)
}
    postclose `out0'

    use `firstvar'_`yeval'_`wspan'_regmean.dta, clear
    label var `thirdvar' "Epidemiologic week"
    label var ytested "Year tested"
    label var ystart "Earliest reference year"
    label var yend "Latest reference year"
    label var mean_`firstvar' "Non-smoothed mean of cases"
    label var lb "Lower 95% bound non-smoothed mean"
    label var ub "Upper 95% bound non-smoothed mean"
    label var stdp "Standard error of the mean"
    label var stdf "Standard error of the predicted mean"
    label var obscases "Cases of `firstvar'"

    label var ws "Week span (± weeks around index week)"
    label var ws_used "Week span actually used (± weeks) for this week"

    gen byte wref = 2*ws + 1
    label var wref "Number of reference weeks (2*ws+1)"

    gen str8 met="regmean"
    label var met "Method"
    qui replace `thirdvar'=_n
    qui drop if `thirdvar'>52

    qui tsset `thirdvar'

    /*smoother() handling*/
    local sm "`smoother'"
    if "`sm'"=="" local sm "3S5RHE, twice"

    tssmooth nl lbsmooth   = lb,              smoother(`sm')
    tssmooth nl meansmooth = mean_`firstvar', smoother(`sm')
    tssmooth nl ubsmooth   = ub,              smoother(`sm')

    label var lbsmooth   "Lower 95% bound smoothed mean_`firstvar'"
    label var ubsmooth   "Upper 95% bound smoothed mean_`firstvar'"
    label var meansmooth "Smoothed mean_`firstvar'"
    label var obscases   "Cases of `firstvar'"

    scalar eps = 1e-8
    capture assert (lbsmooth - eps) <= meansmooth & (meansmooth - eps) <= (ubsmooth + eps) ///
        if !missing(lbsmooth, meansmooth, ubsmooth)
    if _rc {
        di as error "Warning: meansmooth is outside [lbsmooth, ubsmooth] beyond numeric tolerance."
    }

    tempvar o lbv mv ubv
    qui gen double `o'   = obscases
    qui gen double `lbv' = lbsmooth
    qui gen double `mv'  = meansmooth
    qui gen double `ubv' = ubsmooth

    qui gen byte wtype = .
    qui replace wtype = 0 if `o' <= `lbv' + eps
    qui replace wtype = 1 if `o' >  `lbv' + eps & `o' <  `mv'  - eps
    qui replace wtype = 2 if `o' >= `mv'  - eps & `o' <= `ubv' + eps
    qui replace wtype = 3 if `o' >  `ubv' + eps

    qui replace wtype = . if missing(`o', `lbv', `mv', `ubv')

    quietly capture label list wzonelb
    if _rc {
        label define wzonelb 0 "Baseline (= LB)" ///
                             1 "Alert (LB, Mean]" ///
                             2 "Alarm [Mean, UB]" ///
                             3 "Epidemic (> UB)"
    }

    label values wtype wzonelb
    label var wtype "Epidemic week zone"

    drop _*
    order ytested `thirdvar' obscases ystart yend mean_`firstvar' stdp stdf lb ub ///
          meansmooth lbsmooth ubsmooth ws ws_used wref wtype

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

    /*graph title: grtitle()*/
    local titopt
    if "`grtitle'" != "" {
        local titopt `"title(`"`grtitle'"', size(medium) justification(left))"'
    }
    else {
        local titopt `"title("Endemic channel for `firstvar'; year `yeval'; method: regmean", size(medium) justification(left))"'
    }

    local xlinecmd
    if "`xlines'" != "" {
        if "`xlineopts'" != "" local xlinecmd `"xline(0(4)54, `xlineopts')"'
        else                    local xlinecmd "xline(0(4)54)"
    }

    if "`nograph'" == "" {
        twoway (line meansmooth `thirdvar', sort `meanopts') ///
               (line lbsmooth   `thirdvar', sort `lbopts') ///
               (line ubsmooth   `thirdvar', sort `ubopts') ///
               (line obscases   `thirdvar', sort `obsopts'),  ///
             `yopts' `ylab' ///
             `titopt' ///
             ytitle("Number of cases") ///
             legend(order(1 "Mean" 2 "Lower limit" 3 "Upper limit" 4 "Observed `yeval' ")) ///
             xlabel(0(4)54) `xlinecmd'

        if "`grsave'" != "" {
            local gfile "`grsave'"
            if substr("`gfile'", -4, .) != ".gph" local gfile "`gfile'.gph"
            graph save "`gfile'", replace
            di as text "Graph saved as: {bf:`gfile'}"
        }
    }
    else {
        if "`grsave'" != "" {
            di as error "Warning: grsave() ignored because nograph was specified."
        }
    }

    local outfile "`firstvar'_`yeval'_`wspan'_regmean.dta"
    if "`fsave'" != "" local outfile "`fsave'"

    quietly save "`outfile'", replace
    di as text "Look for the output of this analysis in file: {bf:`outfile'}"
end

/****************************************************************************************************************/
/*           Bootstrapped median                                                                                */
/****************************************************************************************************************/
program bsmedian, rclass
qui {
        syntax varlist(min=3 max=3 numeric) ///
            [, yeval(int  0) yspan(int 0) wspan(int 0) SEED(integer 313151) ///
               MET(string) REPS(integer 1000) ///
               SMOOther(string) JITTer LOGscale ///
               YSRANGE(numlist min=2 max=2) ///
               YVALUES(numlist) ///
               GRTITLE(string) GRSAVE(string) FSave(string) ///
               MEANOPTS(string asis) LBOPTS(string asis) ///
               UBOPTS(string asis) OBSOPTS(string asis) ///
               XLINES XLINEOPTS(string asis) ///
               NOGraph ]
    }
    local firstvar  : word 1 of `varlist'
    local secondvar : word 2 of `varlist'
    local thirdvar  : word 3 of `varlist'

    qui keep if `secondvar'>=ystart & `secondvar'<=(yend + 1)
    qui replace `firstvar' = `firstvar' + 0.5 if `firstvar' == 0

    set seed `seed'

    local basevar "`firstvar'"
    if "`jitter'" != "" {
        qui gen double `firstvar'jit = `firstvar' + rnormal(1, 0.5)
        qui replace `firstvar'jit = 0.0001 if `firstvar'jit <= 0
        local basevar "`firstvar'jit"
    }

    tempname out0
    postfile `out0' `thirdvar' lb mean_`firstvar' ub obscases ytested ystart yend ws ws_used ///
        using `firstvar'_`yeval'_`wspan'_bsmedian.dta, replace

    forvalues i = 1(1)52 {

        scalar mean_`firstvar' = .
        scalar lb  = .
        scalar ub  = .
        scalar ws_used = `wspan'

        capture qui bootstrap mean_`firstvar'=r(p50), nodots bca reps(`reps') seed(`seed'): ///
            qui summarize `basevar' if `thirdvar'>=`i' - `wspan' & `thirdvar' <= `i' + `wspan' & ///
            (`secondvar'>=ystart & `secondvar'<=yend), detail

        if (_rc) {
            local wspan2 = `wspan' + 1
            capture qui bootstrap mean_`firstvar'=r(p50), nodots bca reps(`reps') seed(`seed'): ///
                qui summarize `basevar' if `thirdvar'>=`i' - `wspan2' & `thirdvar' <= `i' + `wspan2' & ///
                (`secondvar'>=ystart & `secondvar'<=yend), detail

            if (!_rc) {
                scalar ws_used = `wspan2'
                di as txt "Note: bsmedian failed for week `i' with wspan(`wspan'); using wspan(`wspan2') for this week."
            }
            else {
                di as err "Warning: bsmedian failed for week `i' with wspan(`wspan') and wspan(`wspan2'); results set to missing for this week."
            }
        }

        if (!_rc) {
            capture qui estat boot, all
            if (!_rc) {
                matrix A = e(b)
                scalar mean_`firstvar' = A[1,1]
                matrix B = e(ci_bc)
                scalar lb = B[1,1]
                scalar ub = B[2,1]
            }
            else {
                di as err "Warning: bsmedian estat boot failed for week `i'; results set to missing for this week."
                scalar mean_`firstvar' = .
                scalar lb  = .
                scalar ub  = .
            }
        }

        qui sum `firstvar' if `thirdvar' == `i' & `secondvar' == `yeval'
        scalar obscases = r(mean)
        scalar ytested  = `yeval'
        scalar ws       = `wspan'

        post `out0' (`thirdvar') (lb) (mean_`firstvar') (ub) ///
                     (obscases) (ytested) (ystart) (yend) (ws) (ws_used)
    }
    postclose `out0'

    use `firstvar'_`yeval'_`wspan'_bsmedian.dta, clear
    label var `thirdvar' "Epidemiologic week"
    label var ytested "Year tested"
    label var ystart "Earliest reference year"
    label var yend "Latest reference year"
    label var mean_`firstvar' "Non-smoothed median of `firstvar'"
    label var lb "Lower 95% bound non-smoothed median"
    label var ub "Upper 95% bound non-smoothed median"
    label var obscases "Cases of `firstvar'"

    label var ws "Week span (± weeks around index week)"
    label var ws_used "Week span actually used (± weeks) for this week"

    gen byte wref = 2*ws + 1
    label var wref "Number of reference weeks (2*ws+1)"

    gen str8 met="bsmedian"
    label var met "Method"
    qui replace `thirdvar'=_n
    qui drop if `thirdvar'>52
    qui tsset `thirdvar'

    local sm "`smoother'"
    if "`sm'"=="" local sm "8453EH, twice"

    if "`smoother'" != "" {
        if trim("`smoother'") != "8453EH, twice" {
            di as red "Warning: You are overriding the recommended smoother (8453EH, twice) for the bootstrap-median method."
            di as red "      Using a more aggressive smoother may distort the discrete behavior of the bootstrap median."
        }
    }

    tssmooth nl lbsmooth   = lb,              smoother(`sm')
    tssmooth nl meansmooth = mean_`firstvar', smoother(`sm')
    tssmooth nl ubsmooth   = ub,              smoother(`sm')

    label var lbsmooth   "Lower 95% bound smoothed median_`firstvar'"
    label var ubsmooth   "Upper 95% bound smoothed median_`firstvar'"
    label var meansmooth "Smoothed median `firstvar'"
    label var obscases   "Cases `firstvar'"

    qui gen stdp = .
    label var stdp "SE of boostrapped mean not available"
    qui gen stdf = .
    label var stdf "SE of predicted boostraped mean not available"

    scalar eps = 1e-8
    capture assert (lbsmooth - eps) <= meansmooth & (meansmooth - eps) <= (ubsmooth + eps) ///
        if !missing(lbsmooth, meansmooth, ubsmooth)
    if _rc {
        di as error "Warning: meansmooth is outside [lbsmooth, ubsmooth] beyond numeric tolerance."
        di as error "This may be caused by the use of an aggressive smoother, particularly when [, twice] is used."
        di as error "In those cases [, twice] could be excluded or other less aggressive smoothers like (3RSSH)"
        di as error "or (4253H) could be used. However, using the latter with [, twice] may lead to the same inconsistency."
    }

    tempvar o lbv mv ubv
    qui gen double `o'   = obscases
    qui gen double `lbv' = lbsmooth
    qui gen double `mv'  = meansmooth
    qui gen double `ubv' = ubsmooth

    qui gen byte wtype = .
    qui replace wtype = 0 if `o' <= `lbv' + eps
    qui replace wtype = 1 if `o' >  `lbv' + eps & `o' <  `mv'  - eps
    qui replace wtype = 2 if `o' >= `mv'  - eps & `o' <= `ubv' + eps
    qui replace wtype = 3 if `o' >  `ubv' + eps

    qui replace wtype = . if missing(`o', `lbv', `mv', `ubv')

    quietly capture label list wzonelb
    if _rc {
        label define wzonelb 0 "Baseline (= LB)" ///
                             1 "Alert (LB, Mean]" ///
                             2 "Alarm [Mean, UB]" ///
                             3 "Epidemic (> UB)"
    }

    label values wtype wzonelb
    label var wtype "Epidemic week zone"

    drop _*
    order ytested `thirdvar' obscases ystart yend mean_`firstvar' stdp stdf lb ub ///
          meansmooth lbsmooth ubsmooth ws ws_used wref wtype

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

    local titopt
    if "`grtitle'" != "" {
        local titopt `"title(`"`grtitle'"', size(medium) justification(left))"'
    }
    else {
        local titopt `"title("Endemic channel for `firstvar'; year `yeval'; method: bootstrapped median", size(medium) justification(left))"'
    }

    local xlinecmd
    if "`xlines'" != "" {
        if "`xlineopts'" != "" local xlinecmd `"xline(0(4)54, `xlineopts')"'
        else                    local xlinecmd "xline(0(4)54)"
    }

    if "`nograph'" == "" {
        twoway (line meansmooth `thirdvar', sort `meanopts') ///
               (line lbsmooth   `thirdvar', sort `lbopts') ///
               (line ubsmooth   `thirdvar', sort `ubopts') ///
               (line obscases   `thirdvar', sort `obsopts'),  ///
             `yopts' `ylab' ///
             `titopt' ///
             ytitle("Number of cases") ///
             legend(order(1 "Mean" 2 "Lower limit" 3 "Upper limit" 4 "Observed `yeval' ")) ///
             xlabel(0(4)54) `xlinecmd'

        if "`grsave'" != "" {
            local gfile "`grsave'"
            if substr("`gfile'", -4, .) != ".gph" local gfile "`gfile'.gph"
            graph save "`gfile'", replace
            di as text "Graph saved as: {bf:`gfile'}"
        }
    }
    else {
        if "`grsave'" != "" {
            di as error "Warning: grsave() ignored because nograph was specified."
        }
    }

    local outfile "`firstvar'_`yeval'_`wspan'_bsmedian.dta"
    if "`fsave'" != "" local outfile "`fsave'"

    quietly save "`outfile'", replace
    di as text "Look for the output of this analysis in file: {bf:`outfile'}"
end

/****************************************************************************************************************/
/*           Robust mean                                                                                        */
/****************************************************************************************************************/
program robmean, rclass
qui {
        syntax varlist(min=3 max=3 numeric) ///
            [, yeval(int  0) yspan(int 0) wspan(int 0) SEED(integer 313151) ///
               SMOOther(string) JITTer LOGscale ///
               MET(string) ///
               YSRANGE(numlist min=2 max=2) ///
               YVALUES(numlist) ///
               GRTITLE(string) GRSAVE(string) FSave(string) ///
               MEANOPTS(string asis) LBOPTS(string asis) ///
               UBOPTS(string asis) OBSOPTS(string asis) ///
               XLINES XLINEOPTS(string asis) ///
               NOGraph ]
    }

    local firstvar  : word 1 of `varlist'
    local secondvar : word 2 of `varlist'
    local thirdvar  : word 3 of `varlist'

    qui keep if `secondvar'>=ystart & `secondvar'<=(yend + 1)
    qui replace `firstvar' = `firstvar' + 0.5 if `firstvar' == 0

    set seed `seed'

    local basevar "`firstvar'"
    if "`jitter'" != "" {
        qui gen double `firstvar'jit = `firstvar' + rnormal(1, 0.5)
        qui replace `firstvar'jit = 0.0001 if `firstvar'jit <= 0
        local basevar "`firstvar'jit"
    }

    tempname out0
    postfile `out0' `thirdvar' lb mean_`firstvar' ub stdf stdp obscases ytested ystart yend ws ws_used ///
        using `firstvar'_`yeval'_`wspan'_robmean.dta, replace

    forvalues i = 1(1)52 {
        scalar mean_`firstvar' = .
        scalar lb  = .
        scalar ub  = .
        scalar stdf = .
        scalar stdp = .
        scalar ws_used = `wspan'

        * Try requested window
        capture qui rreg `basevar' if `thirdvar'>=`i' - `wspan' & `thirdvar' <= `i' + `wspan' & ///
            (`secondvar'>=ystart & `secondvar'<=yend)

        if (_rc) {
            local wspan2 = `wspan' + 1
            capture qui rreg `basevar' if `thirdvar'>=`i' - `wspan2' & `thirdvar' <= `i' + `wspan2' & ///
                (`secondvar'>=ystart & `secondvar'<=yend)

            if (!_rc) {
                scalar ws_used = `wspan2'
                di as txt "Note: robmean failed for week `i' with wspan(`wspan'); using wspan(`wspan2') for this week."
            }
            else {
                di as text "Note: (yeval=`yeval') robmean failed for week `i' with wspan(`wspan'); using wspan(`wspan2') for this week."
            }
        }

        if (!_rc) {
            scalar stdf = (e(rmse)/(e(N))^0.5)*(1 + (1/e(N))^0.5)
            scalar stdp = (e(rmse)/(e(N))^0.5)
            capture qui lincom _cons
            if (!_rc) {
                scalar mean_`firstvar' = r(estimate)
                scalar lb = mean_`firstvar' - invttail(e(df_r), 0.025)*stdf
                scalar ub = mean_`firstvar' + invttail(e(df_r), 0.025)*stdf
            }
            else {
                di as err "Warning: robmean lincom failed for week `i'; results set to missing for this week."
                scalar mean_`firstvar' = .
                scalar lb  = .
                scalar ub  = .
                scalar stdf = .
                scalar stdp = .
            }
        }

        qui sum `firstvar' if `thirdvar' == `i' & `secondvar' == `yeval'
        scalar obscases = r(mean)
        scalar ytested  = `yeval'
        scalar ws       = `wspan'

        post `out0' (`thirdvar') (lb) (mean_`firstvar') (ub) (stdf) (stdp) ///
                      (obscases) (ytested) (ystart) (yend) (ws) (ws_used)
    }
    postclose `out0'

    use `firstvar'_`yeval'_`wspan'_robmean.dta, clear
    label var `thirdvar' "Epidemiologic week"
    label var ytested "Year tested"
    label var ystart "Earliest reference year"
    label var yend "Latest reference year"
    label var mean_`firstvar' "Robust mean_`firstvar'"
    label var lb "Lower 95% bound robust mean_`firstvar'"
    label var ub "Upper 95% bound robust mean_`firstvar'"
    label var stdp "Standard error of the robust mean_`firstvar'"
    label var stdf "Standard error of the robust predicted mean_`firstvar'"
    label var obscases "Cases `firstvar'"

    label var ws "Week span (± weeks around index week)"
    label var ws_used "Week span actually used (± weeks) for this week"

    gen byte wref = 2*ws + 1
    label var wref "Number of reference weeks (2*ws+1)"

    gen str8 met="robmean"
    label var met "Method"
    qui replace `thirdvar'=_n
    qui drop if `thirdvar'>52

    qui tsset `thirdvar'

    local sm "`smoother'"
    if "`sm'"=="" local sm "3S5RHE, twice"

    tssmooth nl lbsmooth   = lb,              smoother(`sm')
    tssmooth nl meansmooth = mean_`firstvar', smoother(`sm')
    tssmooth nl ubsmooth   = ub,              smoother(`sm')

    label var lbsmooth   "Lower 95% bound smoothed robust mean_`firstvar'"
    label var ubsmooth   "Upper 95% bound smoothed robust mean_`firstvar'"
    label var meansmooth "Smoothed robust mean_`firstvar'"
    label var obscases   "Cases of `firstvar'"

    scalar eps = 1e-8
    capture assert (lbsmooth - eps) <= meansmooth & (meansmooth - eps) <= (ubsmooth + eps) ///
        if !missing(lbsmooth, meansmooth, ubsmooth)
    if _rc {
        di as error "Warning: meansmooth is outside [lbsmooth, ubsmooth] beyond numeric tolerance."
    }

    tempvar o lbv mv ubv
    qui gen double `o'   = obscases
    qui gen double `lbv' = lbsmooth
    qui gen double `mv'  = meansmooth
    qui gen double `ubv' = ubsmooth

    qui gen byte wtype = .
    qui replace wtype = 0 if `o' <= `lbv' + eps
    qui replace wtype = 1 if `o' >  `lbv' + eps & `o' <  `mv'  - eps
    qui replace wtype = 2 if `o' >= `mv'  - eps & `o' <= `ubv' + eps
    qui replace wtype = 3 if `o' >  `ubv' + eps

    qui replace wtype = . if missing(`o', `lbv', `mv', `ubv')

    quietly capture label list wzonelb
    if _rc {
        label define wzonelb 0 "Baseline (= LB)" ///
                             1 "Alert (LB, Mean]" ///
                             2 "Alarm [Mean, UB]" ///
                             3 "Epidemic (> UB)"
    }

    label values wtype wzonelb
    label var wtype "Epidemic week zone"

    drop _*
    order ytested `thirdvar' obscases ystart yend mean_`firstvar' stdp stdf lb ub ///
          meansmooth lbsmooth ubsmooth ws ws_used wref wtype

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

    local titopt
    if "`grtitle'" != "" {
        local titopt `"title(`"`grtitle'"', size(medium) justification(left))"'
    }
    else {
        local titopt `"title("Endemic channel for `firstvar'; year `yeval'; method: robust mean", size(medium) justification(left))"'
    }

    local xlinecmd
    if "`xlines'" != "" {
        if "`xlineopts'" != "" local xlinecmd `"xline(0(4)54, `xlineopts')"'
        else                    local xlinecmd "xline(0(4)54)"
    }

    if "`nograph'" == "" {
        twoway (line meansmooth `thirdvar', sort `meanopts') ///
               (line lbsmooth   `thirdvar', sort `lbopts') ///
               (line ubsmooth   `thirdvar', sort `ubopts') ///
               (line obscases   `thirdvar', sort `obsopts'),  ///
             `yopts' `ylab' ///
             `titopt' ///
             ytitle("Number of cases") ///
             legend(order(1 "Mean" 2 "Lower limit" 3 "Upper limit" 4 "Observed `yeval' ")) ///
             xlabel(0(4)54) `xlinecmd'

        if "`grsave'" != "" {
            local gfile "`grsave'"
            if substr("`gfile'", -4, .) != ".gph" local gfile "`gfile'.gph"
            graph save "`gfile'", replace
            di as text "Graph saved as: {bf:`gfile'}"
        }
    }
    else {
        if "`grsave'" != "" {
            di as error "Warning: grsave() ignored because nograph was specified."
        }
    }

    local outfile "`firstvar'_`yeval'_`wspan'_robmean.dta"
    if "`fsave'" != "" local outfile "`fsave'"

    quietly save "`outfile'", replace
    di as text "Look for the output of this analysis in file: {bf:`outfile'}"
end

