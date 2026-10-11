*! version 0.1.4  29sep2026
program define modelaudit, rclass
    version 14.2

    syntax namelist(min=2), FOCAL(string) ///
        [BASE(integer 1) PREVIOUS SAMPLES EFORM COEF Level(cilevel)]

    local nmodels : word count `namelist'

    if (`base' < 1 | `base' > `nmodels') {
        di as err "base() must index one of the supplied stored models"
        exit 198
    }

    if ("`eform'" != "" & "`coef'" != "") {
        di as err "eform and coef may not be specified together"
        exit 198
    }

    /*
        Preserve the user's active estimation results. restore makes this
        fail-safe even if modelaudit exits early.
    */
    tempname MA_hold
    capture _estimates hold `MA_hold', copy restore nullok

    /*
        All scratch matrices/scalars use temporary names so modelaudit
        does not leave behind objects in the user's session.
    */
    tempname SUMMARY OVERLAP
    tempname MA_N MA_vcerank MA_bcols MA_dfm MA_ll MA_cl MA_fb MA_se
    tempname MA_alpha MA_crit MA_dfr MA_lb MA_ub
    tempname MA_ic MA_bmat MA_bi MA_br

    /*
        summary columns:
          1 N
          2 events
          3 nonevents
          4 vcerank      = e(rank), the rank of e(V), when available
          5 modeldf      = e(df_m), when available
          6 ep           = events / modeldf for selected binary models
          7 b            = raw focal coefficient
          8 estimate     = displayed focal estimate
          9 lb
         10 ub
         11 pctchg       = percent change in raw b
         12 ll
         13 aic
         14 bic
         15 clusters
         16 sampleok
         17 samecomp     = exact equality of e(sample) to comparator
         18 bcols        = number of columns in e(b), when available
    */
    matrix `SUMMARY' = J(`nmodels', 18, .)
    matrix colnames `SUMMARY' = ///
        N events nonevents vcerank modeldf ep b estimate lb ub pctchg ///
        ll aic bic clusters sampleok samecomp bcols
    matrix rownames `SUMMARY' = `namelist'

    matrix `OVERLAP' = J(`nmodels', `nmodels', .)
    matrix rownames `OVERLAP' = `namelist'
    matrix colnames `OVERLAP' = `namelist'

    local scales
    local any_sample_missing 0
    local any_focal_missing 0
    local any_sample_change 0
    local any_ic 0
    local any_delta_suppressed 0
    local depvar0
    local cmd0
    local different_depvar 0
    local different_cmd 0

    /*
        First pass: restore each model and collect model-level quantities.
        We intentionally use official estimates stats for AIC/BIC rather
        than reimplementing Stata's information-criterion bookkeeping.
    */
    forvalues i = 1/`nmodels' {
        local m : word `i' of `namelist'

        capture quietly estimates restore `m'
        if (_rc) {
            di as err "stored estimates `m' not found or could not be restored"
            exit _rc
        }

        local cmd`i' "`e(cmd)'"
        local cmd2`i' "`e(cmd2)'"
        local dep`i' "`e(depvar)'"

        if (`i' == 1) {
            local cmd0 "`e(cmd)'"
            local depvar0 "`e(depvar)'"
        }
        else {
            if ("`e(cmd)'" != "`cmd0'") local different_cmd 1
            if ("`e(depvar)'" != "`depvar0'") local different_depvar 1
        }

        scalar `MA_N' = .
        capture scalar `MA_N' = e(N)
        if (!_rc) matrix `SUMMARY'[`i',1] = `MA_N'

        /*
            Keep three distinct notions of model dimension separate:
              - e(rank): rank of the posted VCE matrix e(V);
              - colsof(e(b)): number of coefficient-vector columns; and
              - e(df_m): estimator-reported model degrees of freedom.
            These quantities can differ, for example when coefficients are
            omitted because of collinearity.  Never substitute one for another.
        */
        scalar `MA_vcerank' = .
        capture scalar `MA_vcerank' = e(rank)
        if (!_rc) {
            if (`MA_vcerank' < .) matrix `SUMMARY'[`i',4] = `MA_vcerank'
        }

        scalar `MA_bcols' = .
        capture matrix `MA_bmat' = e(b)
        if (!_rc) {
            scalar `MA_bcols' = colsof(`MA_bmat')
            if (`MA_bcols' < .) matrix `SUMMARY'[`i',18] = `MA_bcols'
        }

        scalar `MA_dfm' = .
        capture scalar `MA_dfm' = e(df_m)
        if (!_rc) {
            if (`MA_dfm' < .) matrix `SUMMARY'[`i',5] = `MA_dfm'
        }

        scalar `MA_ll' = .
        capture scalar `MA_ll' = e(ll)
        if (!_rc) matrix `SUMMARY'[`i',12] = `MA_ll'

        scalar `MA_cl' = .
        capture scalar `MA_cl' = e(N_clust)
        if (!_rc) matrix `SUMMARY'[`i',15] = `MA_cl'

        /*
            Capture e(sample) into a temporary variable. Stored estimates
            loaded from disk without reconstructing e(sample) cannot support
            sample-comparison diagnostics.
        */
        tempvar __ma_s
        capture quietly gen byte `__ma_s' = e(sample)
        if (_rc) {
            local sampleok`i' 0
            local any_sample_missing 1
        }
        else {
            quietly count if `__ma_s' == 1
            if (r(N) == 0) {
                local sampleok`i' 0
                local any_sample_missing 1
            }
            else {
                local sampleok`i' 1
                local samplevar`i' "`__ma_s'"
                matrix `SUMMARY'[`i',16] = 1
            }
        }

        /*
            Events/non-events are reported only for commands whose outcome
            is ordinarily binary. No adequacy cutoff is imposed.
        */
        local isbinary 0
        if inlist("`e(cmd)'", "logit", "logistic", "clogit", "xtlogit", ///
                               "melogit", "meqrlogit", "firthlogit") {
            local isbinary 1
        }

        if (`isbinary' & `sampleok`i'' == 1 & "`e(depvar)'" != "") {
            capture confirm variable `e(depvar)'
            if (!_rc) {
                quietly count if `samplevar`i'' & !missing(`e(depvar)') & `e(depvar)' != 0
                matrix `SUMMARY'[`i',2] = r(N)

                quietly count if `samplevar`i'' & !missing(`e(depvar)') & `e(depvar)' == 0
                matrix `SUMMARY'[`i',3] = r(N)

                /*
                    E/df is descriptive only and, in v0.1, is restricted to
                    ordinary fixed-effect binary logistic models.  The
                    denominator is e(df_m), not VCE rank or coefficient-column count.
                */
                if inlist("`e(cmd)'", "logit", "logistic", "firthlogit") {
                    if (`SUMMARY'[`i',5] < . & `SUMMARY'[`i',5] > 0) {
                        matrix `SUMMARY'[`i',6] = ///
                            `SUMMARY'[`i',2] / `SUMMARY'[`i',5]
                    }
                }
            }
        }

        /*
            Focal coefficient. focal() should be a coefficient name Stata
            understands in _b[], e.g. focal(exposure), focal(1.exposure),
            or an equation-qualified name when needed.
        */
        scalar `MA_fb' = .
        capture scalar `MA_fb' = _b[`focal']

        if (_rc) {
            local focalok`i' 0
            local any_focal_missing 1
            local scale`i' "NA"
        }
        else {
            local focalok`i' 1
            matrix `SUMMARY'[`i',7] = `MA_fb'

            scalar `MA_se' = .
            capture scalar `MA_se' = _se[`focal']

            local doexp 0
            local thisscale "b"

            if ("`coef'" != "") {
                local doexp 0
                local thisscale "b"
            }
            else if ("`eform'" != "") {
                local doexp 1
                local thisscale "exp(b)"
            }
            else {
                if inlist("`e(cmd)'", "logit", "logistic", "clogit", "xtlogit", ///
                                       "melogit", "meqrlogit", "firthlogit") {
                    local doexp 1
                    local thisscale "OR"
                }
                else if ("`e(cmd2)'" == "stcox" | ///
                         inlist("`e(cmd)'", "cox", "stcox", "stcox_fr")) {
                    local doexp 1
                    local thisscale "HR"
                }
                else if inlist("`e(cmd)'", "poisson", "xtpoisson", "mepoisson", ///
                                           "nbreg", "xtnbreg", "menbreg") {
                    local doexp 1
                    local thisscale "IRR"
                }
                else if ("`e(cmd)'" == "mlogit" & strpos("`focal'", ":") > 0) {
                    local doexp 1
                    local thisscale "RRR"
                }
            }

            local scale`i' "`thisscale'"
            local scales "`scales' `m':`thisscale'"

            scalar `MA_alpha' = (100 - `level')/100
            scalar `MA_crit' = invnormal(1 - `MA_alpha'/2)

            scalar `MA_dfr' = .
            capture scalar `MA_dfr' = e(df_r)
            if (!_rc) {
                if (`MA_dfr' < . & `MA_dfr' > 0) {
                    scalar `MA_crit' = invttail(`MA_dfr', `MA_alpha'/2)
                }
            }

            scalar `MA_lb' = `MA_fb' - `MA_crit'*`MA_se'
            scalar `MA_ub' = `MA_fb' + `MA_crit'*`MA_se'

            if (`doexp') {
                matrix `SUMMARY'[`i',8]  = exp(`MA_fb')
                matrix `SUMMARY'[`i',9]  = exp(`MA_lb')
                matrix `SUMMARY'[`i',10] = exp(`MA_ub')
            }
            else {
                matrix `SUMMARY'[`i',8]  = `MA_fb'
                matrix `SUMMARY'[`i',9]  = `MA_lb'
                matrix `SUMMARY'[`i',10] = `MA_ub'
            }
        }

        /*
            Let official Stata compute information criteria. When they are
            undefined for an estimator, cells remain missing.
        */
        capture quietly estimates stats `m'
        if (!_rc) {
            capture matrix `MA_ic' = r(S)
            if (!_rc & colsof(`MA_ic') >= 6) {
                matrix `SUMMARY'[`i',13] = `MA_ic'[1,5]
                matrix `SUMMARY'[`i',14] = `MA_ic'[1,6]
                if (`MA_ic'[1,5] < . | `MA_ic'[1,6] < .) local any_ic 1
            }
        }
    }

    /*
        Pairwise estimation-sample overlap.
    */
    forvalues i = 1/`nmodels' {
        forvalues j = 1/`nmodels' {
            if (`sampleok`i'' == 1 & `sampleok`j'' == 1) {
                quietly count if `samplevar`i'' & `samplevar`j''
                matrix `OVERLAP'[`i',`j'] = r(N)
            }
        }
    }

    /*
        Comparator for coefficient change and exact sample equality:
        default = base model; previous = immediately preceding model.
        Percent change is computed on the raw coefficient (linear-predictor)
        scale, even when the displayed focal estimate is exponentiated.

        The reference model itself is not coded as "same sample = 1";
        samecomp remains missing because there is no meaningful comparison.
    */
    forvalues i = 1/`nmodels' {
        local ref = `base'

        if ("`previous'" != "") {
            if (`i' == 1) local ref = 0
            else local ref = `i' - 1
        }

        if (`ref' > 0) {
            if (`focalok`i'' == 1 & `focalok`ref'' == 1) {
                scalar `MA_bi' = `SUMMARY'[`i',7]
                scalar `MA_br' = `SUMMARY'[`ref',7]

                if (`i' == `ref') {
                    matrix `SUMMARY'[`i',11] = 0
                }
                else {
                    /*
                        Delta b % is only defined here when the compared
                        models use the same dependent variable and the same
                        estimation command.  A numerical coefficient change
                        across different outcomes or estimators is easy to
                        compute but can be analytically meaningless.

                        logit and logistic are treated as aliases.
                    */
                    local sameout = ("`dep`i''" == "`dep`ref''")

                    local fam_i "`cmd`i''"
                    local fam_r "`cmd`ref''"

                    if inlist("`fam_i'", "logit", "logistic") local fam_i "logit"
                    if inlist("`fam_r'", "logit", "logistic") local fam_r "logit"

                    local samecmd = ("`fam_i'" == "`fam_r'")

                    if (`sameout' & `samecmd') {
                        if (`MA_br' != 0 & `MA_br' < .) {
                            matrix `SUMMARY'[`i',11] = ///
                                100*(`MA_bi' - `MA_br')/`MA_br'
                        }
                    }
                    else {
                        local any_delta_suppressed 1
                    }
                }
            }

            if (`i' != `ref' & `sampleok`i'' == 1 & `sampleok`ref'' == 1) {
                quietly count if `samplevar`i'' != `samplevar`ref''
                matrix `SUMMARY'[`i',17] = (r(N) == 0)
                if (r(N) > 0) local any_sample_change 1
            }
        }
    }

    /*
        Human-readable output.
    */
    di
    di as txt "Model audit"
    di as txt "{hline 78}"
    di as txt "Focal coefficient: " as res "`focal'"

    if ("`previous'" != "") {
        di as txt "Comparison:        " as res "each model vs previous model"
    }
    else {
        local bm : word `base' of `namelist'
        di as txt "Comparison:        " as res "each model vs `bm'"
    }

    di as txt "CI level:          " as res "`level'%"
    di

    di as txt "Model characteristics"
    di as txt "{hline 82}"
    di as txt %14s "Model" " " ///
        %9s "N" " " ///
        %9s "Events" " " ///
        %8s "VCE rank" " " ///
        %9s "Coef cols" " " ///
        %8s "Model df" " " ///
        %9s "E/df" " " ///
        %10s "Clusters"

    forvalues i = 1/`nmodels' {
        local m : word `i' of `namelist'
        di as res %14s substr("`m'",1,14) " " ///
            %9.0f `SUMMARY'[`i',1] " " ///
            %9.0f `SUMMARY'[`i',2] " " ///
            %8.0f `SUMMARY'[`i',4] " " ///
            %9.0f `SUMMARY'[`i',18] " " ///
            %8.0f `SUMMARY'[`i',5] " " ///
            %9.2f `SUMMARY'[`i',6] " " ///
            %10.0f `SUMMARY'[`i',15]
    }

    di
    di as txt "Likelihood / information criteria"
    di as txt "{hline 63}"
    di as txt %14s "Model" " " ///
        %14s "Log likelihood" " " ///
        %14s "AIC" " " ///
        %14s "BIC"

    forvalues i = 1/`nmodels' {
        local m : word `i' of `namelist'
        di as res %14s substr("`m'",1,14) " " ///
            %14.3f `SUMMARY'[`i',12] " " ///
            %14.2f `SUMMARY'[`i',13] " " ///
            %14.2f `SUMMARY'[`i',14]
    }

    di
    di as txt "Focal-estimate tracking"
    di as txt "{hline 86}"
    di as txt %14s "Model" " " ///
        %7s "Scale" " " ///
        %11s "Estimate" " " ///
        %11s "Lower CI" " " ///
        %11s "Upper CI" " " ///
        %10s "Delta b %" " " ///
        %11s "Same samp."

    forvalues i = 1/`nmodels' {
        local m : word `i' of `namelist'

        local samedisplay "."
        if ("`previous'" != "") {
            if (`i' == 1) local samedisplay "--"
            else if (`SUMMARY'[`i',17] == 1) local samedisplay "Yes"
            else if (`SUMMARY'[`i',17] == 0) local samedisplay "No"
        }
        else {
            if (`i' == `base') local samedisplay "REF"
            else if (`SUMMARY'[`i',17] == 1) local samedisplay "Yes"
            else if (`SUMMARY'[`i',17] == 0) local samedisplay "No"
        }

        di as res %14s substr("`m'",1,14) " " ///
            %7s "`scale`i''" " " ///
            %11.4f `SUMMARY'[`i',8] " " ///
            %11.4f `SUMMARY'[`i',9] " " ///
            %11.4f `SUMMARY'[`i',10] " " ///
            %10.1f `SUMMARY'[`i',11] " " ///
            %11s "`samedisplay'"
    }

    di as txt "Same samp. compares exact equality of e(sample), not merely equal sample size."
    di as txt "Delta b % is calculated on the raw coefficient scale."

    if ("`samples'" != "") {
        di
        di as txt "Pairwise estimation-sample overlap (number of observations)"
        matrix list `OVERLAP', format(%10.0f)
    }

    di
    di as txt "Audit notes"
    di as txt "{hline 78}"

    if (`any_sample_missing') {
        di as error "WARNING: e(sample) was unavailable for at least one model; some sample diagnostics are missing."
        di as txt   "         This can occur after loading saved estimation results without"
        di as txt   "         reconstructing the original estimation sample."
    }

    if (`any_sample_change') {
        di as error "CAUTION: estimation samples differ across at least one requested comparison."
        if (`any_ic') {
            di as txt "         AIC/BIC values are displayed, but cross-model comparisons can reflect both"
            di as txt "         model specification and a change in the observations being analyzed."
        }
    }

    if (`different_depvar') {
        di as error "CAUTION: the stored models do not all report the same dependent variable."
    }

    if (`different_cmd') {
        di as error "NOTE: the stored models were fit with different estimation commands."
        di as txt   "      Verify that likelihood-based fit statistics are substantively comparable."
    }

    if (`any_delta_suppressed') {
        di as error "NOTE: Delta b % was not calculated for at least one comparison because"
        di as txt   "      the compared models use different outcomes and/or estimation commands."
    }

    if (`any_focal_missing') {
        di as error "WARNING: focal(`focal') was not found in at least one model."
        di as txt   "         Use the exact coefficient name shown by the estimator's coeflegend when needed."
    }

    di as txt "VCE rank is e(rank), the rank of e(V); Coef cols is colsof(e(b))."
    di as txt "These are kept separate from e(df_m) and are not used as substitutes for one another."
    di as txt "E/df, when shown, is events divided by e(df_m). It is descriptive;"
    di as txt "modelaudit does not apply a rule-of-10 cutoff or declare a model adequate/inadequate."

    return clear
    return matrix summary = `SUMMARY'
    return matrix overlap = `OVERLAP'
    return local models "`namelist'"
    return local focal "`focal'"
    return local scales "`scales'"
    return scalar base = `base'
    return scalar level = `level'
    return scalar nmodels = `nmodels'
    return scalar sample_changes = `any_sample_change'
    return scalar sample_missing = `any_sample_missing'
    return scalar focal_missing = `any_focal_missing'
    return scalar delta_suppressed = `any_delta_suppressed'
end
