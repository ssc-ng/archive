*! tvtplot 1.0.1  14oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Plot the fitted time-varying threshold against the threshold variable.
*!
*! THE POINT OF THE PICTURE. A time-varying threshold model asserts that the
*! boundary between regimes moved. That assertion is far easier to judge by
*! eye than from three Fourier coefficients: a reader can see at once whether
*! the fitted path tracks a real feature of the data or wanders through a
*! cloud of points, and whether the regimes it implies are populated
*! throughout the sample or only at the ends. A table of coefficients hides
*! both.
*!
*! Works after any TVTHRESH estimator that leaves e(path).
*!
*! See tvtplot.sthlp.

program define tvtplot
    version 15

    syntax [, TItle(string asis) SUBtitle(string asis)         ///
              YTitle(string asis) XTitle(string asis)          ///
              NAME(string) SAVing(string asis)                 ///
              TRUEvar(varname numeric)                         ///
              noSCATter noREGime noLEGend                      ///
              MSize(string) LWidth(string)                     ///
              SCHeme(string) *  ]

    if "`e(cmd)'" == "" {
        display as error "no estimation results in memory"
        display as error "{bf:tvtplot} runs after a TVTHRESH estimator," ///
            " such as {bf:tvtfourier}"
        exit 301
    }
    capture confirm matrix e(path)
    if _rc {
        display as error "`e(cmd)' did not leave a fitted threshold path"
        display as error ""
        display as error "{bf:tvtplot} needs {bf:e(path)}, which the" ///
            " time-varying threshold"
        display as error "ESTIMATORS leave behind. A test such as" ///
            " {bf:tvthomog} does not fit"
        display as error "a path at all -- it reports whether the" ///
            " threshold is constant"
        display as error "without estimating how it moves -- so there is" ///
            " nothing to draw."
        exit 198
    }

    local qv "`e(threshvar)'"
    if "`qv'" == "" {
        display as error "`e(cmd)' did not record its threshold variable"
        exit 198
    }
    * EXACT, because confirm variable honours Stata's variable-name
    * abbreviation: with the threshold variable q renamed away and some
    * other variable qq still present, a plain confirm MATCHES qq, and
    * the fitted path is then drawn against the wrong variable without
    * a word of warning. A picture that is silently wrong is the one
    * failure this command must not have.
    capture confirm variable `qv', exact
    if _rc {
        display as error "the threshold variable `qv' is no longer in" ///
            " the data"
        display as error "{bf:tvtplot} draws the fitted path against it," ///
            " so it must still exist"
        exit 111
    }

    * the time axis: whatever the data are tsset on, else the row number
    capture quietly tsset
    local tv "`r(timevar)'"
    tempvar tt
    if "`tv'" == "" {
        quietly generate long `tt' = _n if e(sample)
        local tv `tt'
        local tlab "observation"
    }
    else {
        local tlab "`tv'"
    }

    * ---- the fitted path back into a variable. e(path) has one row per
    *      ESTIMATION-SAMPLE observation, in sample order, so it is lined
    *      up against e(sample) rather than against the whole dataset.
    tempvar pathv idx
    quietly generate double `pathv' = .
    quietly generate long `idx' = sum(e(sample))
    tempname P
    matrix `P' = e(path)
    local np = rowsof(`P')
    quietly count if e(sample)
    if r(N) != `np' {
        display as error "e(path) has `np' rows but the estimation" ///
            " sample has " r(N)
        display as error "the data have changed since the model was" ///
            " fitted; refit it"
        exit 459
    }
    forvalues i = 1/`np' {
        quietly replace `pathv' = `P'[`i',1] if `idx' == `i' & e(sample)
    }

    * ---- defaults chosen to read on a printed page: the data in light
    *      grey so they do not fight the fitted line, which is the thing
    *      the reader is being asked to look at.
    if `"`title'"'    == "" local title    `"Fitted time-varying threshold"'
    if `"`subtitle'"' == "" {
        local subtitle `"`e(title)'"'
    }
    if `"`ytitle'"'   == "" local ytitle   `"`qv'"'
    if `"`xtitle'"'   == "" local xtitle   `"`tlab'"'
    if "`name'"       == "" local name     tvtplot
    if "`msize'"      == "" local msize    vsmall
    if "`lwidth'"     == "" local lwidth   medthick

    local layers
    if "`scatter'" == "" {
        local layers `layers' (scatter `qv' `tv' if e(sample),            ///
            msymbol(circle_hollow) msize(`msize') mcolor(gs10)            ///
            legend(label(1 "`qv'")))
    }
    if "`regime'" == "" {
        * shade the observations assigned to the lower regime, so the
        * reader can see WHICH points the fitted path actually separates
        tempvar lowq
        quietly generate double `lowq' = `qv' if e(sample) & `qv' <= `pathv'
        local layers `layers' (scatter `lowq' `tv',                        ///
            msymbol(circle) msize(`msize') mcolor(navy%40)                 ///
            legend(label(2 "lower regime")))
    }
    local layers `layers' (line `pathv' `tv' if e(sample),                 ///
        lwidth(`lwidth') lcolor(cranberry)                                 ///
        legend(label(3 "fitted threshold")))
    if "`truevar'" != "" {
        local layers `layers' (line `truevar' `tv' if e(sample),           ///
            lwidth(`lwidth') lpattern(dash) lcolor(black)                  ///
            legend(label(4 "true threshold")))
    }

    local leg legend(order(1 2 3 4) rows(1) size(small) region(lstyle(none)))
    if "`legend'" != "" local leg legend(off)

    local schopt
    if "`scheme'" != "" local schopt scheme(`scheme')

    twoway `layers',                                                       ///
        title(`"`title'"', size(medium))                                   ///
        subtitle(`"`subtitle'"', size(small))                              ///
        ytitle(`"`ytitle'"') xtitle(`"`xtitle'"')                          ///
        `leg' `schopt'                                                     ///
        graphregion(color(white)) plotregion(lstyle(none))                 ///
        name(`name', replace) `options'

    if `"`saving'"' != "" {
        * saving() follows Stata's own convention, saving(filename[,
        * replace]), so the filename and the option must be SPLIT before
        * either is used. Appending ", replace" to whatever came in
        * produced "..., replace, replace" whenever the user supplied
        * replace -- which is the normal way to use the option -- and the
        * capture below then swallowed the failure, so the command
        * reported SUCCESS and wrote no file at all.
        gettoken sfile srest : saving, parse(",")
        local srep
        if `"`srest'"' != "" {
            gettoken scomma sopt : srest, parse(",")
            local sopt = trim(`"`sopt'"')
            if `"`sopt'"' != "" & lower(`"`sopt'"') != "replace" {
                display as error "{bf:saving()} takes a filename and," ///
                    " optionally, {bf:replace}"
                display as error "{bf:`sopt'} is neither"
                exit 198
            }
            if lower(`"`sopt'"') == "replace" local srep replace
        }
        if "`srep'" == "" {
            capture graph save `name' `sfile'
        }
        else {
            capture graph save `name' `sfile', replace
        }
        * and a failure to write must FAIL. Printing a message and
        * returning 0 is how a missing file goes unnoticed until the
        * draft is being assembled.
        if _rc {
            display as error "could not save the graph to `sfile'" ///
                " (rc = " _rc ")"
            if _rc == 602 {
                display as error "the file exists; add {bf:replace} to" ///
                    " {bf:saving()} to overwrite it"
            }
            exit _rc
        }
    }
end
