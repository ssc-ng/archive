*! version 2.0.0 25sep2026
*! cvcombo: Control-variable all-combinations robustness test
*! Author: Jiang ZhenYuan(蒋镇源) & Zhang Na(张娜)
*! Affiliation: School of Economics, Northwest Normal University
*! E-mail: kangjang504@gmail.com; zhangna@nwnu.edu.cn

program define cvcombo, rclass
    version 15.1

    syntax varlist(min=2 max=2 numeric) [if] [in], ///
        METHOD(string) ///
        CONTROLS(varlist min=1 fv ts) ///
        [OPTIONS(string asis) ABSORB(string asis) CLUSTER(string asis) ///
         SAMPLEVars(varlist) LEVEL(real 95) SAVing(string) REPLACE ///
         GRAPHPrefix(string) PAPER PAPERDir(string) DOCX(string) NOGRAPH]

    * ------------------------------------------------------------
    * User-supplied estimation method
    * ------------------------------------------------------------
    local method = strtrim("`method'")
    if `"`method'"' == "" {
        di as error "method() is required."
        di as error "Examples: method(regress), method(xtreg), method(logit), method(probit), method(reghdfe)"
        exit 198
    }

    if (`level' <= 0 | `level' >= 100) {
        di as error "level() must be between 0 and 100."
        exit 198
    }

    gettoken depvar mainvar : varlist

    local k : word count `controls'
    local total = 2^`k' - 1

    if `k' > 15 {
        di as yellow "Warning: `k' controls imply `total' specifications."
        di as yellow "Computation time grows exponentially with the number of controls."
    }

    * ------------------------------------------------------------
    * Common estimation sample
    *
    * The sample always includes depvar, mainvar and all controls.
    * samplevars() can be used to add variables appearing only inside
    * method options, e.g. FE identifiers or cluster variables.
    * ------------------------------------------------------------
    marksample touse
    markout `touse' `depvar' `mainvar' `controls'
    if `"`samplevars'"' != "" {
        markout `touse' `samplevars'
    }

    quietly count if `touse'
    local commonN = r(N)
    if `commonN' == 0 {
        di as error "No observations remain after forming the common estimation sample."
        exit 2000
    }

    * ------------------------------------------------------------
    * Build model-specific options.
    * method() is the estimation command supplied by the user, while
    * options() is passed through as-is. For reghdfe users we also
    * provide optional absorb()/cluster() shorthands for compatibility
    * and to make the intended specification explicit.
    * ------------------------------------------------------------
    local modelopts `"`options'"'

    if `"`absorb'"' != "" {
        local modelopts `"`modelopts' absorb(`absorb')"'
    }

    if `"`cluster'"' != "" {
        local modelopts `"`modelopts' vce(cluster `cluster')"'
    }

    local modelopts : list retokenize modelopts

    * ------------------------------------------------------------
    * Helper: construct the command from method() and model options.
    * Same dynamic-command logic as the supplied OneClick example:
    * `method' y x controls, `modelopts'
    * ------------------------------------------------------------
    local basecmd `"`method' `depvar' `mainvar' `controls' if `touse'"'
    if `"`modelopts'"' != "" {
        local basecmd `"`basecmd', `modelopts'"'
    }

    di as text _newline "cvcombo v2.0 | method = " as result "`method'"
    di as text "Constructed baseline command:"
    di as result `"`basecmd'"'

    * ------------------------------------------------------------
    * Baseline model = ALL controls
    * ------------------------------------------------------------
    capture estimates drop CVCOMBO_BASELINE

    capture quietly `basecmd'
    if _rc {
        local rc = _rc
        di as error "cvcombo could not run the baseline specification."
        di as error "Method: `method'"
        di as error "Command attempted:"
        di as error `"`basecmd'"'
        di as error "Check that method() is installed and that options() are valid for that method."
        exit `rc'
    }

    estimates store CVCOMBO_BASELINE

    capture confirm scalar e(df_r)
    local has_df_r = 0
    local base_df = .
    if !_rc {
        local base_df = e(df_r)
        if !missing(`base_df') local has_df_r = 1
    }

    local base_b    = _b[`mainvar']
    local base_se   = _se[`mainvar']
    if `has_df_r' {
        local base_t    = `base_b' / `base_se'
        local base_p    = 2*ttail(`base_df', abs(`base_t'))
        local base_crit = invttail(`base_df', (100-`level')/200)
    }
    else {
        local base_t    = `base_b' / `base_se'
        local base_p    = 2*(1-normal(abs(`base_t')))
        local base_crit = invnormal(1-(100-`level')/200)
    }
    local base_lo   = `base_b' - `base_crit'*`base_se'
    local base_hi   = `base_b' + `base_crit'*`base_se'
    local base_N    = e(N)
    local base_cmdline `"`basecmd'"'

    di as text _newline "Baseline model stored as: CVCOMBO_BASELINE"
    di as text "Method: " as result "`method'"
    di as text "Baseline command:"
    di as result `"`basecmdline'"'
    di as text "Baseline coefficient on `mainvar': " %10.6f `base_b' ///
        "   SE: " %10.6f `base_se' ///
        "   p: " %8.5f `base_p'
    di as text "Inference: " as result cond(`has_df_r', "t", "z")
    di as text "Baseline N: " as result `base_N'
    if `has_df_r' di as text "   df_r: " as result %10.3f `base_df'
    di as text "Common estimation sample N: " as result `commonN'
    di as text "Total nonempty control-variable combinations: " as result `total'
    di as text _newline

    * ------------------------------------------------------------
    * Machine-readable results
    * ------------------------------------------------------------
    tempfile results
    tempname posth

    postfile `posth' ///
        long model ///
        int nctrl ///
        byte ok ///
        double b se t p lo hi ///
        byte direction ///
        byte p01 p05 p10 p15 ///
        byte baseline ///
        long N ///
        double df_r ///
        str2045 controls_str ///
        using "`results'", replace

    * ------------------------------------------------------------
    * Enumerate all nonempty subsets using a bit mask.
    * ------------------------------------------------------------
    forvalues mask = 1/`total' {

        local combo ""
        local nctrl = 0

        forvalues j = 1/`k' {
            local bit = mod(floor(`mask' / 2^(`j'-1)), 2)
            if `bit' == 1 {
                local cv : word `j' of `controls'
                local combo "`combo' `cv'"
                local nctrl = `nctrl' + 1
            }
        }

        local combo : list retokenize combo
        local isbase = (`mask' == `total')

        local thiscmd `"`method' `depvar' `mainvar' `combo' if `touse'"'
        if `"`modelopts'"' != "" {
            local thiscmd `"`thiscmd', `modelopts'"'
        }

        capture quietly `thiscmd'

        if _rc == 0 {
            capture scalar __cvcombo_b = _b[`mainvar']
            capture scalar __cvcombo_se = _se[`mainvar']

            if _rc == 0 & !missing(__cvcombo_b) & !missing(__cvcombo_se) & __cvcombo_se > 0 {

                local b_this  = _b[`mainvar']
                local se_this = _se[`mainvar']
                local t_this  = `b_this'/`se_this'

                capture confirm scalar e(df_r)
                local use_t = 0
                local df_this = .
                if !_rc {
                    local df_this = e(df_r)
                    if !missing(`df_this') local use_t = 1
                }

                if `use_t' {
                    local p_this = 2*ttail(`df_this', abs(`t_this'))
                    local crit_this = invttail(`df_this', (100-`level')/200)
                }
                else {
                    local p_this = 2*(1-normal(abs(`t_this')))
                    local crit_this = invnormal(1-(100-`level')/200)
                }

                local lo_this = `b_this' - `crit_this'*`se_this'
                local hi_this = `b_this' + `crit_this'*`se_this'

                local dir_this = cond(`b_this' > 0, 1, cond(`b_this' < 0, -1, 0))
                local p01_this = (`p_this' < .01)
                local p05_this = (`p_this' < .05)
                local p10_this = (`p_this' < .10)
                local p15_this = (`p_this' < .15)
                local N_this = e(N)

                post `posth' ///
                    (`mask') (`nctrl') (1) ///
                    (`b_this') (`se_this') (`t_this') (`p_this') ///
                    (`lo_this') (`hi_this') (`dir_this') ///
                    (`p01_this') (`p05_this') (`p10_this') (`p15_this') ///
                    (`isbase') (`N_this') (`df_this') ("`combo'")
            }
            else {
                post `posth' ///
                    (`mask') (`nctrl') (0) ///
                    (.) (.) (.) (.) (.) (.) (.) ///
                    (.) (.) (.) (.) ///
                    (`isbase') (.) (.) ("`combo'")
            }
        }
        else {
            post `posth' ///
                (`mask') (`nctrl') (0) ///
                (.) (.) (.) (.) (.) (.) (.) ///
                (.) (.) (.) (.) ///
                (`isbase') (.) (.) ("`combo'")
        }
    }

    postclose `posth'

    * ------------------------------------------------------------
    * Summary statistics / graphs
    * ------------------------------------------------------------
    preserve
        use "`results'", clear

        count if ok == 1
        local nsuccess = r(N)
        count if ok == 0
        local nfail = r(N)

        if `nsuccess' == 0 {
            restore
            di as error "All specifications failed to estimate."
            exit 2000
        }

        * Significance
        count if ok == 1 & p < .01
        local n01 = r(N)
        local pct01 = 100*`n01'/`nsuccess'

        count if ok == 1 & p < .05
        local n05 = r(N)
        local pct05 = 100*`n05'/`nsuccess'

        count if ok == 1 & p < .10
        local n10 = r(N)
        local pct10 = 100*`n10'/`nsuccess'

        count if ok == 1 & p < .15
        local n15 = r(N)
        local pct15 = 100*`n15'/`nsuccess'

        * Direction
        count if ok == 1 & direction > 0
        local npos = r(N)
        local pctpos = 100*`npos'/`nsuccess'

        count if ok == 1 & direction < 0
        local nneg = r(N)
        local pctneg = 100*`nneg'/`nsuccess'

        count if ok == 1 & direction == 0
        local nzero = r(N)
        local pctzero = 100*`nzero'/`nsuccess'

        * Coefficient distribution
        quietly summarize b if ok == 1, detail
        local b_mean = r(mean)
        local b_sd = r(sd)
        local b_min = r(min)
        local b_max = r(max)
        local b_p25 = r(p25)
        local b_median = r(p50)
        local b_p75 = r(p75)

        quietly generate double ci_width = hi - lo if ok == 1
        quietly summarize ci_width if ok == 1, detail
        local ci_mean_width = r(mean)
        local ci_median_width = r(p50)

        * CI excludes zero
        count if ok == 1 & (lo > 0 | hi < 0)
        local nci = r(N)
        local pctci = 100*`nci'/`nsuccess'

        * Summary
        di as text _newline "=============================================================="
        di as text " cvcombo v2.0 summary"
        di as text "=============================================================="
        di as text "Author: Jiang ZhenYuan(蒋镇源) & Zhang Na(张娜)"
        di as text "Affiliation: School of Economics, Northwest Normal University"
        di as text "Method: " as result "`method'"
        di as text "Baseline model:"
        di as result `"`basecmdline'"'
        di as text "Baseline coefficient = " %10.6f `base_b' ///
            "   " cond(`has_df_r', "CI", "CI") " = [" %10.6f `base_lo' ", " %10.6f `base_hi' "]"
        di as text _newline "Specifications"
        di as text "--------------------------------------------------------------"
        di as text "All nonempty combinations    " as result %8.0f `total'
        di as text "Successfully estimated       " as result %8.0f `nsuccess'
        di as text "Failed specifications        " as result %8.0f `nfail'
        di as text "Common estimation sample N   " as result %8.0f `commonN'

        di as text _newline "Significance of coefficient on `mainvar'"
        di as text "--------------------------------------------------------------"
        di as text %12s "Threshold" %12s "Count" %15s "Percent"
        di as text %12s "p < 0.01" %12.0f `n01' %14.2f `pct01'
        di as text %12s "p < 0.05" %12.0f `n05' %14.2f `pct05'
        di as text %12s "p < 0.10" %12.0f `n10' %14.2f `pct10'
        di as text %12s "p < 0.15" %12.0f `n15' %14.2f `pct15'

        di as text _newline "Coefficient direction"
        di as text "--------------------------------------------------------------"
        di as text %12s "Direction" %12s "Count" %15s "Percent"
        di as text %12s "Positive" %12.0f `npos' %14.2f `pctpos'
        di as text %12s "Negative" %12.0f `nneg' %14.2f `pctneg'
        di as text %12s "Zero"     %12.0f `nzero' %14.2f `pctzero'

        di as text _newline "Coefficient distribution"
        di as text "--------------------------------------------------------------"
        di as text "Mean       = " %12.6f `b_mean'
        di as text "SD         = " %12.6f `b_sd'
        di as text "Minimum    = " %12.6f `b_min'
        di as text "P25        = " %12.6f `b_p25'
        di as text "Median     = " %12.6f `b_median'
        di as text "P75        = " %12.6f `b_p75'
        di as text "Maximum    = " %12.6f `b_max'

        di as text _newline "Confidence intervals"
        di as text "--------------------------------------------------------------"
        di as text "CI level                  = " %6.2f `level' "%"
        di as text "CI excludes zero          = " %10.0f `nci' ///
            " (" %6.2f `pctci' "%)"
        di as text "Mean CI width             = " %12.6f `ci_mean_width'
        di as text "Median CI width           = " %12.6f `ci_median_width'
        di as text "=============================================================="

        * Save results
        sort model
        format b se t p lo hi %12.6f

        local result_path `"`saving'"'
        if `"`result_path'"' != "" {
            if `"`replace'"' != "" {
                save `"`result_path'"', replace
            }
            else {
                save `"`result_path'"'
            }
            local saved_results `"`result_path'"'
        }
        else {
            tempfile autosave
            save "`autosave'", replace
            local saved_results "`autosave'"
        }

        * ------------------------------------------------------------
        * Paper outputs
        *
        * Default: specification curve + specification matrix.
        * paper: full paper-output bundle, including SVG/PNG/GPH graphs,
        * a CSV summary, and a Chinese Word Table 8.
        *
        * Graph text is intentionally ASCII/English to avoid Chinese-font
        * problems in SVG files. The Word table is Unicode and uses
        * Microsoft YaHei as its document font.
        * ------------------------------------------------------------
        local gprefix "cvcombo"
        if `"`graphprefix'"' != "" local gprefix `"`graphprefix'"'

        local paper_outdir ""
        if `"`paperdir'"' != "" {
            local paper_outdir = strtrim(`"`paperdir'"')

            * mkdir() returns 693 both when the directory already exists
            * and when it cannot be created. Therefore, after a failed
            * mkdir(), test the path by temporarily changing into it.
            local cvcombo_oldpwd `"`c(pwd)'"'
            capture mkdir `"`paper_outdir'"'
            if _rc {
                local mkdir_rc = _rc
                capture cd `"`paper_outdir'"'
                if _rc {
                    di as error "paperdir() could not be created or accessed: `paper_outdir'"
                    di as error "mkdir return code: `mkdir_rc'"
                    di as error "Current working directory: `cvcombo_oldpwd'"
                    exit 693
                }
                capture cd `"`cvcombo_oldpwd'"'
            }
            else {
                capture cd `"`cvcombo_oldpwd'"'
            }

            local gfile `"`paper_outdir'/`gprefix'"'
        }
        else {
            local gfile `"`gprefix'"'
        }

        local spec_curve ""
        local spec_matrix ""
        local coef_hist ""
        local coef_box ""
        local coef_ci ""
        local table8_docx ""
        local summary_csv ""

        if `"`nograph'"' == "" | `"`paper'"' != "" {
            * ========================================================
            * 1. Specification Curve
            * ========================================================
            sort b
            generate long spec_order = sum(ok == 1)
            quietly summarize spec_order if baseline == 1 & ok == 1, meanonly
            local baseline_pos = r(mean)

            twoway ///
                (rcap lo hi spec_order if ok == 1, lwidth(vthin) lcolor(gs8)) ///
                (scatter b spec_order if ok == 1, msymbol(O) msize(tiny) mcolor(black)) ///
                (scatter b spec_order if baseline == 1 & ok == 1, ///
                    msymbol(D) msize(medium) mcolor(black)) ///
                , ///
                yline(0, lpattern(dash) lcolor(gs8)) ///
                xline(`baseline_pos', lpattern(shortdash) lcolor(gs8)) ///
                xlabel(, labsize(vsmall)) ///
                xtitle("Specifications sorted by coefficient") ///
                ytitle("Coefficient on `mainvar'") ///
                title("Specification Curve") ///
                legend(off) ///
                graphregion(color(white)) ///
                plotregion(color(white)) ///
                name(cvcombo_spec_curve, replace)

            graph save "`gfile'_specification_curve.gph", replace
            graph export "`gfile'_specification_curve.svg", as(svg) fontface(Arial) replace
            graph export "`gfile'_specification_curve.png", width(2200) replace
            local spec_curve "`gfile'_specification_curve.svg"

            if `"`paper'"' != "" {
                * ====================================================
                * 2. Demand coefficient distribution
                * ====================================================
                histogram b if ok == 1, fraction ///
                    xline(0, lpattern(dash) lcolor(gs8)) ///
                    xline(`base_b', lpattern(shortdash) lcolor(black)) ///
                    xtitle("Demand coefficient") ///
                    ytitle("Fraction") ///
                    title("Distribution of Demand Coefficients") ///
                    note("Dashed line: zero; solid line: baseline coefficient") ///
                    legend(off) ///
                    graphregion(color(white)) ///
                    plotregion(color(white)) ///
                    name(cvcombo_coef_hist, replace)

                graph save "`gfile'_coefficient_distribution.gph", replace
                graph export "`gfile'_coefficient_distribution.svg", as(svg) fontface(Arial) replace
                graph export "`gfile'_coefficient_distribution.png", width(2200) replace
                local coef_hist "`gfile'_coefficient_distribution.svg"

                * ====================================================
                * 3. Coefficient by number of controls
                * ====================================================
                * graph box does not require an x-axis title here; the
                * over() categories already identify the number of controls.
                graph box b if ok == 1, over(nctrl, label(labsize(small))) ///
                    yline(0, lpattern(dash) lcolor(gs8)) ///
                    ytitle("Demand coefficient") ///
                    title("Demand Coefficients by Number of Controls") ///
                    graphregion(color(white)) ///
                    plotregion(color(white)) ///
                    name(cvcombo_coef_box, replace)

                graph save "`gfile'_coefficient_by_nctrl.gph", replace
                graph export "`gfile'_coefficient_by_nctrl.svg", as(svg) fontface(Arial) replace
                graph export "`gfile'_coefficient_by_nctrl.png", width(2200) replace
                local coef_box "`gfile'_coefficient_by_nctrl.svg"

                * ====================================================
                * 4. Specification Matrix
                * ====================================================
                sort b
                generate long spec_order_m = _n
                    local heatplots ""
                    local ylabs ""
                    local j = 0
                    foreach cv of local controls {
                        local ++j
                        generate byte inc`j' = ///
                            strpos(" " + controls_str + " ", " `cv' ") > 0 if ok == 1
                        generate double yy`j' = `j' if inc`j' == 1 & ok == 1
                        local heatplots `heatplots' ///
                            (scatter yy`j' spec_order_m if ok == 1 & inc`j' == 1, ///
                                msymbol(square) msize(vsmall) mcolor(black))
                        local ylabs `ylabs' `j' "`cv'"
                    }

                twoway `heatplots', ///
                    yscale(reverse) ///
                    ylabel(`ylabs', angle(horizontal) labsize(small)) ///
                    xlabel(, labsize(vsmall)) ///
                    xtitle("Specifications sorted by coefficient") ///
                    ytitle("Control variable") ///
                    title("Specification Matrix") ///
                    legend(off) ///
                    graphregion(color(white)) ///
                    plotregion(color(white)) ///
                    name(cvcombo_spec_matrix, replace)

                graph save "`gfile'_specification_matrix.gph", replace
                graph export "`gfile'_specification_matrix.svg", as(svg) fontface(Arial) replace
                graph export "`gfile'_specification_matrix.png", width(2200) replace

                capture drop spec_order_m
                forvalues k = 1/`j' {
                    capture drop inc`k' yy`k'
                }
                local spec_matrix "`gfile'_specification_matrix.svg"

                * ====================================================
                * 5. Ranked coefficient + 95% CI
                * ====================================================
                sort b
                generate long rank = _n

                twoway ///
                    (rcap lo hi rank, lcolor(gs8) lwidth(vthin)) ///
                    (scatter b rank, msymbol(O) msize(vsmall) mcolor(black)) ///
                    , ///
                    yline(0, lpattern(dash) lcolor(gs8)) ///
                    xtitle("Specification rank") ///
                    ytitle("Demand coefficient with 95% CI") ///
                    title("Robustness of Demand Coefficient") ///
                    legend(off) ///
                    graphregion(color(white)) ///
                    plotregion(color(white)) ///
                    name(cvcombo_coef_ci, replace)

                graph save "`gfile'_coefficient_ci.gph", replace
                graph export "`gfile'_coefficient_ci.svg", as(svg) fontface(Arial) replace
                graph export "`gfile'_coefficient_ci.png", width(2200) replace
                capture drop rank
                local coef_ci "`gfile'_coefficient_ci.svg"

                * ====================================================
                * 6. Paper summary CSV
                * ====================================================
                local summary_csv `"`gfile'_robustness_summary.csv"'
                file open fh using `"`summary_csv'"', write replace
                file write fh "Indicator,Value,Percent/Note" _n
                file write fh "All specifications,`nsuccess',100" _n
                file write fh "p<0.01,`n01',`pct01'" _n
                file write fh "p<0.05,`n05',`pct05'" _n
                file write fh "p<0.10,`n10',`pct10'" _n
                file write fh "p<0.15,`n15',`pct15'" _n
                file write fh "Positive coefficient,`npos',`pctpos'" _n
                file write fh "Negative coefficient,`nneg',`pctneg'" _n
                file write fh "Zero coefficient,`nzero',`pctzero'" _n
                file write fh "95% CI excludes zero,`nci',`pctci'" _n
                file write fh "Mean,`b_mean'," _n
                file write fh "SD,`b_sd'," _n
                file write fh "Minimum,`b_min'," _n
                file write fh "P25,`b_p25'," _n
                file write fh "Median,`b_median'," _n
                file write fh "P75,`b_p75'," _n
                file write fh "Maximum,`b_max'," _n
                file write fh "Mean CI width,`ci_mean_width'," _n
                file write fh "Median CI width,`ci_median_width'," _n
                file write fh "Baseline coefficient,`base_b'," _n
                file write fh "Baseline CI low,`base_lo'," _n
                file write fh "Baseline CI high,`base_hi'," _n
                file close fh

                * ====================================================
                * 7. Table 8 Word output
                * ====================================================
                capture which putdocx
                if _rc {
                    di as error "putdocx is not available; Word table was not created."
                }
                else {
                    local table8_docx ""
                    if `"`docx'"' != "" {
                        local table8_docx `"`docx'"'
                    }
                    else {
                        local table8_docx `"`gfile'_table8_control_combinations.docx"'
                    }

                    capture putdocx clear
                    capture putdocx begin, pagesize(A4) font("Microsoft YaHei", 10.5)
                    if _rc == 0 {
                        capture putdocx paragraph, halign(center) font("Microsoft YaHei", 10.5)
                        capture putdocx text ("表8  控制变量任意组合检验")

                        capture putdocx paragraph, halign(center)
                        capture putdocx table tbl8 = (2,4)
                        if _rc == 0 {
                            capture putdocx table tbl8(1,1) = ("组合数")
                            capture putdocx table tbl8(1,2) = ("p<0.01")
                            capture putdocx table tbl8(1,3) = ("p<0.05")
                            capture putdocx table tbl8(1,4) = ("p<0.1")
                            capture putdocx table tbl8(2,1) = (`nsuccess')
                            capture putdocx table tbl8(2,2) = (`n01')
                            capture putdocx table tbl8(2,3) = (`n05')
                            capture putdocx table tbl8(2,4) = (`n10')

                            * Three-line table: no vertical lines.
                            capture putdocx table tbl8, border(all, nil)
                            capture putdocx table tbl8(1,.), ///
                                border(top, single, black, 1.25pt) ///
                                border(bottom, single, black, .5pt) ///
                                halign(center)
                            capture putdocx table tbl8(2,.), ///
                                border(bottom, single, black, 1.25pt) ///
                                halign(center)
                            capture putdocx table tbl8(1,.), bold font("Microsoft YaHei", 10.5)
                            capture putdocx table tbl8(2,.), font("Microsoft YaHei", 10.5)
                            capture putdocx table tbl8(.,.), halign(center)
                            capture putdocx table tbl8(.,1), width(1.1in)
                            capture putdocx table tbl8(.,2), width(1.25in)
                            capture putdocx table tbl8(.,3), width(1.25in)
                            capture putdocx table tbl8(.,4), width(1.25in)

                            capture putdocx save `"`table8_docx'"', replace
                            if _rc {
                                di as error "Could not save Word table: `table8_docx'"
                                local table8_docx ""
                            }
                        }
                        else {
                            di as error "Could not create the Word table object."
                            local table8_docx ""
                            capture putdocx clear
                        }
                    }
                    else {
                        di as error "Could not start putdocx; Word table was not created."
                        local table8_docx ""
                    }
                }

                di as text _newline "Paper outputs:"
                di as text "  specification_curve   = " as result "`spec_curve'"
                di as text "  coefficient_distribution = " as result "`coef_hist'"
                di as text "  coefficient_by_nctrl = " as result "`coef_box'"
                di as text "  specification_matrix = " as result "`spec_matrix'"
                di as text "  coefficient_ci       = " as result "`coef_ci'"
                di as text "  table8_docx          = " as result "`table8_docx'"
                di as text "  summary_csv          = " as result "`summary_csv'"
            }
        }

        sort model
        save "`saved_results'", replace
    restore

    * Return results and restore baseline estimates for convenient use.
    estimates restore CVCOMBO_BASELINE

    return scalar combinations = `total'
    return scalar successful = `nsuccess'
    return scalar failed = `nfail'
    return scalar common_N = `commonN'
    return scalar p01_n = `n01'
    return scalar p05_n = `n05'
    return scalar p10_n = `n10'
    return scalar p15_n = `n15'
    return scalar p01_pct = `pct01'
    return scalar p05_pct = `pct05'
    return scalar p10_pct = `pct10'
    return scalar p15_pct = `pct15'
    return scalar positive_n = `npos'
    return scalar negative_n = `nneg'
    return scalar zero_n = `nzero'
    return scalar positive_pct = `pctpos'
    return scalar negative_pct = `pctneg'
    return scalar zero_pct = `pctzero'
    return scalar coef_mean = `b_mean'
    return scalar coef_sd = `b_sd'
    return scalar coef_min = `b_min'
    return scalar coef_p25 = `b_p25'
    return scalar coef_median = `b_median'
    return scalar coef_p75 = `b_p75'
    return scalar coef_max = `b_max'
    return scalar ci_excludes_zero_n = `nci'
    return scalar ci_excludes_zero_pct = `pctci'
    return scalar ci_mean_width = `ci_mean_width'
    return scalar ci_median_width = `ci_median_width'
    return scalar baseline_b = `base_b'
    return scalar baseline_se = `base_se'
    return scalar baseline_p = `base_p'
    return scalar baseline_N = `base_N'
    return scalar baseline_df_r = `base_df'
    return scalar has_df_r = `has_df_r'
    return local method "`method'"
    return local baseline_cmd `"`base_cmdline'"'
    return local model_options `"`modelopts'"'
    return local baseline_estimate "CVCOMBO_BASELINE"
    return local results_file "`saved_results'"
    return local spec_curve "`spec_curve'"
    return local spec_matrix "`spec_matrix'"
    return local coefficient_hist "`coef_hist'"
    return local coefficient_box "`coef_box'"
    return local coefficient_ci "`coef_ci'"
    return local table8_docx "`table8_docx'"
    return local summary_csv "`summary_csv'"
end
