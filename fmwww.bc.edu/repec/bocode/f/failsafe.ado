*! version 0.1.6  18sep2026
program define failsafe, rclass
    version 14.2

    syntax [, MINCELL(integer 0) MINCLUSTERS(integer 0) CELLS]

    /*
        FailSafe v0.1.6
        ---------------------------------
        Read-only postestimation linter.

        Design rule:
        FailSafe reports model characteristics and statistical signals that
        deserve review. It does not declare a model valid/invalid, select a
        model, alter the specification, or refit the model.

        mincell(#) is USER-SPECIFIED. There is intentionally no default
        sparse-cell cutoff.
    */

    if (`mincell' < 0) {
        di as error "mincell() must be zero or a positive integer."
        exit 198
    }

    if (`minclusters' < 0) {
        di as error "minclusters() must be zero or a positive integer."
        exit 198
    }

    tempname FS_B FS_N FS_rank FS_dfm FS_clust FS_conv
    tempname FS_cds FS_cdf FS_fail FS_compete FS_censor FS_sub FS_V FCELLS ICELLS
    tempvar  FS_sample

    /*
        Require active estimation results.
    */
    capture matrix `FS_B' = e(b)
    if (_rc) {
        di as error "failsafe must be run immediately after an estimation command."
        exit 301
    }

    local cmd      "`e(cmd)'"
    local cmd2     "`e(cmd2)'"
    local depvar   "`e(depvar)'"
    local vce      "`e(vce)'"
    local vcetype  "`e(vcetype)'"

    /*
        e(b) column count and e(V) rank are different quantities.

        Stata defines e(rank) as the rank of e(V).  Factor-variable base
        categories and omitted terms can remain as columns in e(b), so the
        number of coefficient columns should not be interpreted as model df.
    */
    local coef_columns = colsof(`FS_B')

    /*
        Core model metadata.
    */
    scalar `FS_N' = .
    capture scalar `FS_N' = e(N)

    scalar `FS_rank' = .
    capture scalar `FS_rank' = e(rank)
    /*
        e(rank), when posted, is the rank of e(V).  Do not substitute the
        number of columns of e(b): that is a different quantity.
    */

    scalar `FS_dfm' = .
    capture scalar `FS_dfm' = e(df_m)

    scalar `FS_clust' = .
    capture scalar `FS_clust' = e(N_clust)

    scalar `FS_conv' = .
    capture scalar `FS_conv' = e(converged)

    /*
        Estimator-reported perfect-prediction metadata.

        IMPORTANT:
        Do not test availability with:
            capture scalar x = e(N_cds)
        because a nonexistent e() scalar can evaluate to missing without
        producing the error needed to distinguish "absent" from "present
        but missing".

        Instead, inspect the official list of scalar names in e().
    */
    scalar `FS_cds' = .
    scalar `FS_cdf' = .

    local escalars : e(scalars)
    local cds_pos : list posof "N_cds" in escalars
    local cdf_pos : list posof "N_cdf" in escalars

    local perfect_available = (`cds_pos' > 0 | `cdf_pos' > 0)

    if (`cds_pos' > 0) scalar `FS_cds' = e(N_cds)
    if (`cdf_pos' > 0) scalar `FS_cdf' = e(N_cdf)

    local determined_total .
    if (`perfect_available') {
        local determined_total 0
        if (`FS_cds' < .) local determined_total = `determined_total' + `FS_cds'
        if (`FS_cdf' < .) local determined_total = `determined_total' + `FS_cdf'
    }

    /*
        Survival / competing-risks metadata.

        For stcox and stcrreg, use estimator-native event counts rather than
        trying to infer events from e(depvar) or the final data in memory.
    */
    scalar `FS_fail'    = .
    scalar `FS_compete' = .
    scalar `FS_censor'  = .
    scalar `FS_sub'     = .

    local nfail_pos    : list posof "N_fail" in escalars
    local ncompete_pos : list posof "N_compete" in escalars
    local ncensor_pos  : list posof "N_censor" in escalars
    local nsub_pos     : list posof "N_sub" in escalars

    if (`nfail_pos' > 0)    scalar `FS_fail'    = e(N_fail)
    if (`ncompete_pos' > 0) scalar `FS_compete' = e(N_compete)
    if (`ncensor_pos' > 0)  scalar `FS_censor'  = e(N_censor)
    if (`nsub_pos' > 0)     scalar `FS_sub'     = e(N_sub)

    /*
        stcox stores e(cmd)="cox" (or "stcox_fr" for frailty models) and
        e(cmd2)="stcox".  stcrreg stores e(cmd)="stcrreg".
        Use cmd2 for Cox-family identification so ordinary and frailty Cox
        models are recognized consistently.
    */
    local survivalcmd = ("`cmd2'" == "stcox" | "`cmd'" == "stcrreg")

    /*
        Estimation sample.
    */
    local sample_available 0
    capture quietly gen byte `FS_sample' = e(sample)
    if (!_rc) {
        quietly count if `FS_sample' == 1
        if (r(N) > 0) local sample_available 1
    }

    /*
        Outcome/event counts.

        Binary-response models:
          "Event" means a nonzero dependent-variable value in e(sample).

        Survival models:
          failures come directly from e(N_fail).  For stcrreg, competing and
          censored counts come directly from e(N_compete) and e(N_censor).

        Events/failures per model df is descriptive only; no adequacy threshold
        is applied.
    */
    local binarycmd 0
    if inlist("`cmd'", "logit", "logistic", "probit", "cloglog", ///
                          "clogit", "xtlogit", "melogit", "meqrlogit") {
        local binarycmd 1
    }

    /*
        Some front-end commands store a generic engine in e(cmd) and the
        user-facing estimator in e(cmd2).  Current melogit, for example,
        stores e(cmd)="meglm" and e(cmd2)="melogit".
    */
    if inlist("`cmd2'", "melogit", "meqrlogit") local binarycmd 1

    if ("`cmd'" == "firthlogit" | "`cmd2'" == "firthlogit") local binarycmd 1

    local events    .
    local nonevents .
    local failures  .
    local competing .
    local censored  .
    local subjects  .
    local epdf      .

    if (`binarycmd' & `sample_available' & "`depvar'" != "") {
        capture confirm numeric variable `depvar'
        if (!_rc) {
            quietly count if `FS_sample' & !missing(`depvar') & `depvar' != 0
            local events = r(N)

            quietly count if `FS_sample' & !missing(`depvar') & `depvar' == 0
            local nonevents = r(N)

            if (`FS_dfm' < . & `FS_dfm' > 0) {
                local epdf = `events' / `FS_dfm'
            }
        }
    }

    if (`survivalcmd') {
        if (`FS_fail' < .)    local failures  = `FS_fail'
        if (`FS_compete' < .) local competing = `FS_compete'
        if (`FS_censor' < .)  local censored  = `FS_censor'
        if (`FS_sub' < .)     local subjects  = `FS_sub'

        if (`failures' < . & `FS_dfm' < . & `FS_dfm' > 0) {
            local epdf = `failures' / `FS_dfm'
        }
    }

    /*
        Explicitly omitted coefficients.

        Normal factor-variable base categories ("b.") are NOT omissions.
        Terms Stata marks with "o." are counted.
    */
    local omitted 0
    local omitted_terms

    local cnames : colfullnames `FS_B'
    foreach cn of local cnames {
        if (strpos("`cn'", "o.") > 0) {
            local ++omitted
            local omitted_terms "`omitted_terms' `cn'"
        }
    }
    local omitted_terms : list retokenize omitted_terms

    /*
        Variance-covariance / standard-error integrity.

        Structural signal:
          FS201 = at least one parameter that is not an explicit base or
                  omitted factor-variable term has a missing, zero, or
                  negative variance on the diagonal of e(V).

        This is deliberately narrow.  FailSafe does not use VCE rank alone
        to declare an inferential problem because factor-variable base and
        omitted columns can make colsof(e(b)) exceed e(rank) legitimately.
    */
    local vce_available 0
    local se_problem_count 0
    local se_problem_terms

    capture matrix `FS_V' = e(V)
    if (!_rc) {
        if (rowsof(`FS_V') == colsof(`FS_B') & colsof(`FS_V') == colsof(`FS_B')) {
            local vce_available 1

            local j 0
            foreach cn of local cnames {
                local ++j
                local term "`cn'"

                * Base/omitted factor columns are structural placeholders.
                local skip 0
                if (strpos("`term'", "o.") > 0)  local skip 1
                if (strpos("`term'", "b.") > 0)  local skip 1
                if (strpos("`term'", "bn.") > 0) local skip 1

                if (!`skip') {
                    local vv = `FS_V'[`j',`j']
                    if (missing(`vv') | `vv' <= 0) {
                        local ++se_problem_count
                        local se_problem_terms "`se_problem_terms' `cn'"
                    }
                }
            }
        }
    }
    local se_problem_terms : list retokenize se_problem_terms

    /*
        Discover categorical factor variables and distinct two-way
        categorical interaction sets from expanded coefficient names.

        Scope:
          - numeric factor variables
          - two-way categorical interactions
          - higher-order categorical interactions are detected but deferred
          - continuous components of interactions are not treated as cells
    */
    local factor_vars
    local interaction_sets
    local interaction_coef_terms 0
    local higher_interactions 0

    foreach cn of local cnames {
        local term "`cn'"

        * Strip equation prefix, if present.
        local colon = strpos("`term'", ":")
        if (`colon' > 0) {
            local term = substr("`term'", `colon' + 1, .)
        }

        if (strpos("`term'", "#") == 0) {
            local dot = strpos("`term'", ".")
            if (`dot' > 1) {
                local prefix = substr("`term'", 1, `dot' - 1)
                local vname  = substr("`term'", `dot' + 1, .)

                if regexm("`prefix'", "^[0-9]+[bon]*$") {
                    capture confirm numeric variable `vname'
                    if (!_rc) local factor_vars "`factor_vars' `vname'"
                }
            }
        }
        else {
            local ++interaction_coef_terms
            local comps : subinstr local term "#" " ", all
            local ivars

            foreach comp of local comps {
                local dot = strpos("`comp'", ".")
                if (`dot' > 1) {
                    local prefix = substr("`comp'", 1, `dot' - 1)
                    local vname  = substr("`comp'", `dot' + 1, .)

                    if regexm("`prefix'", "^[0-9]+[bon]*$") {
                        capture confirm numeric variable `vname'
                        if (!_rc) local ivars "`ivars' `vname'"
                    }
                }
            }

            local ivars : list uniq ivars
            local niv : word count `ivars'

            if (`niv' > 0) local factor_vars "`factor_vars' `ivars'"

            if (`niv' == 2) {
                local ikey : subinstr local ivars " " "+", all
                local interaction_sets "`interaction_sets' `ikey'"
            }
            else if (`niv' > 2) {
                local ++higher_interactions
            }
        }
    }

    local factor_vars : list uniq factor_vars
    local interaction_sets : list uniq interaction_sets

    local nfactorvars : word count `factor_vars'
    local ninteractionsets : word count `interaction_sets'

    /*
        Main factor-level outcome-cell inspection.

        FS101 = zero event or zero non-event within an observed factor level.
        FS102 = factor-level N below user-specified mincell(#).

        FS101 is descriptive structure in the FINAL e(sample). It is not
        presented as a complete test for separation/perfect prediction.
    */
    local cellrows 0
    local zero_factor_cells 0
    local sparse_factor_levels 0
    local zero_factor_details
    local sparse_factor_details

    if (`binarycmd' & `sample_available' & "`depvar'" != "" & `nfactorvars' > 0) {
        local vi 0
        foreach fv of local factor_vars {
            local ++vi
            quietly levelsof `fv' if `FS_sample', local(FS_levels)

            foreach lv of local FS_levels {
                quietly count if `FS_sample' & `fv' == `lv'
                local cellN = r(N)

                quietly count if `FS_sample' & `fv' == `lv' & ///
                    !missing(`depvar') & `depvar' != 0
                local cellE = r(N)

                quietly count if `FS_sample' & `fv' == `lv' & ///
                    !missing(`depvar') & `depvar' == 0
                local cellNE = r(N)

                local ze = (`cellE' == 0)
                local zn = (`cellNE' == 0)
                local sp = 0
                if (`mincell' > 0 & `cellN' < `mincell') local sp = 1

                if (`ze' | `zn') {
                    local ++zero_factor_cells
                    local zero_factor_details ///
                        `"`zero_factor_details' `fv'=`lv' (N=`cellN', events=`cellE', non-events=`cellNE');"'
                }

                if (`sp') {
                    local ++sparse_factor_levels
                    local sparse_factor_details ///
                        `"`sparse_factor_details' `fv'=`lv' (N=`cellN');"'
                }

                local ++cellrows
                if (`cellrows' == 1) {
                    matrix `FCELLS' = ///
                        (`vi', `lv', `cellN', `cellE', `cellNE', `ze', `zn', `sp')
                }
                else {
                    matrix `FCELLS' = `FCELLS' \ ///
                        (`vi', `lv', `cellN', `cellE', `cellNE', `ze', `zn', `sp')
                }
            }
        }

        if (`cellrows' > 0) {
            matrix colnames `FCELLS' = ///
                varindex level N events nonevents zeroevent zerononevent sparse
        }
    }

    /*
        Two-way categorical interaction-cell inspection.

        FS103 = zero event or zero non-event in an observed joint cell.
        FS104 = joint-cell N below user-specified mincell(#).
    */
    local irows 0
    local zero_interaction_cells 0
    local sparse_interaction_cells 0
    local zero_interaction_details
    local sparse_interaction_details

    if (`binarycmd' & `sample_available' & "`depvar'" != "" & ///
        `ninteractionsets' > 0) {

        local si 0
        foreach iset of local interaction_sets {
            local ++si
            local ivars : subinstr local iset "+" " ", all
            local v1 : word 1 of `ivars'
            local v2 : word 2 of `ivars'

            quietly levelsof `v1' if `FS_sample', local(FS_L1)
            quietly levelsof `v2' if `FS_sample', local(FS_L2)

            foreach l1 of local FS_L1 {
                foreach l2 of local FS_L2 {
                    quietly count if `FS_sample' & `v1' == `l1' & `v2' == `l2'
                    local cellN = r(N)

                    * Only observed combinations are audited.
                    if (`cellN' > 0) {
                        quietly count if `FS_sample' & `v1' == `l1' & ///
                            `v2' == `l2' & !missing(`depvar') & `depvar' != 0
                        local cellE = r(N)

                        quietly count if `FS_sample' & `v1' == `l1' & ///
                            `v2' == `l2' & !missing(`depvar') & `depvar' == 0
                        local cellNE = r(N)

                        local ze = (`cellE' == 0)
                        local zn = (`cellNE' == 0)
                        local sp = 0
                        if (`mincell' > 0 & `cellN' < `mincell') local sp = 1

                        if (`ze' | `zn') {
                            local ++zero_interaction_cells
                            local zero_interaction_details ///
                                `"`zero_interaction_details' `v1'=`l1' x `v2'=`l2' (N=`cellN', events=`cellE', non-events=`cellNE');"'
                        }

                        if (`sp') {
                            local ++sparse_interaction_cells
                            local sparse_interaction_details ///
                                `"`sparse_interaction_details' `v1'=`l1' x `v2'=`l2' (N=`cellN');"'
                        }

                        local ++irows
                        if (`irows' == 1) {
                            matrix `ICELLS' = ///
                                (`si', `l1', `l2', `cellN', `cellE', `cellNE', `ze', `zn', `sp')
                        }
                        else {
                            matrix `ICELLS' = `ICELLS' \ ///
                                (`si', `l1', `l2', `cellN', `cellE', `cellNE', `ze', `zn', `sp')
                        }
                    }
                }
            }
        }

        if (`irows' > 0) {
            matrix colnames `ICELLS' = ///
                setindex level1 level2 N events nonevents zeroevent zerononevent sparse
        }
    }

    /*
        Signal codes.
    */
    local signal_codes
    local nsignals 0

    if (`FS_conv' < . & `FS_conv' == 0) {
        local ++nsignals
        local signal_codes "`signal_codes' FS001"
    }

    if (`omitted' > 0) {
        local ++nsignals
        local signal_codes "`signal_codes' FS002"
    }

    if (`perfect_available' & `determined_total' > 0) {
        local ++nsignals
        local signal_codes "`signal_codes' FS003"
    }

    if (`zero_factor_cells' > 0) {
        local ++nsignals
        local signal_codes "`signal_codes' FS101"
    }

    if (`sparse_factor_levels' > 0) {
        local ++nsignals
        local signal_codes "`signal_codes' FS102"
    }

    if (`zero_interaction_cells' > 0) {
        local ++nsignals
        local signal_codes "`signal_codes' FS103"
    }

    if (`sparse_interaction_cells' > 0) {
        local ++nsignals
        local signal_codes "`signal_codes' FS104"
    }

    if (`se_problem_count' > 0) {
        local ++nsignals
        local signal_codes "`signal_codes' FS201"
    }

    if (`minclusters' > 0 & `FS_clust' < . & `FS_clust' < `minclusters') {
        local ++nsignals
        local signal_codes "`signal_codes' FS202"
    }

    if (!`sample_available') {
        local ++nsignals
        local signal_codes "`signal_codes' FS901"
    }

    local signal_codes : list retokenize signal_codes

    /*
        Human-readable output.
    */
    di
    di as txt "FailSafe postestimation review"
    di as txt "{hline 72}"

    local displaycmd "`cmd'"
    if ("`cmd2'" == "stcox")     local displaycmd "stcox"
    if ("`cmd2'" == "melogit")   local displaycmd "melogit"
    if ("`cmd2'" == "meqrlogit") local displaycmd "meqrlogit"

    di as txt "Estimator:          " as res "`displaycmd'"
    if ("`depvar'" != "") {
        di as txt "Dependent variable: " as res "`depvar'"
    }

    if (`FS_N' < .) {
        di as txt "Estimation N:       " as res %10.0f `FS_N'
    }
    else {
        di as txt "Estimation N:       " as res "not reported"
    }

    if (`events' < .) {
        di as txt "Events:             " as res %10.0f `events'
        di as txt "Non-events:         " as res %10.0f `nonevents'
    }

    if (`failures' < .) {
        di as txt "Failures:           " as res %10.0f `failures'
    }
    if (`competing' < .) {
        di as txt "Competing events:   " as res %10.0f `competing'
    }
    if (`censored' < .) {
        di as txt "Censored subjects:  " as res %10.0f `censored'
    }
    if (`subjects' < .) {
        di as txt "Subjects:           " as res %10.0f `subjects'
    }

    di as txt "Coefficient columns:" as res %10.0f `coef_columns'

    if (`FS_rank' < .) {
        di as txt "VCE rank:           " as res %10.0f `FS_rank'
    }

    if (`FS_dfm' < .) {
        di as txt "Model df:           " as res %10.0f `FS_dfm'
    }

    if (`epdf' < .) {
        if (`survivalcmd') {
            di as txt "Failures / model df:" as res %9.2f `epdf'
        }
        else {
            di as txt "Events / model df:  " as res %10.2f `epdf'
        }
    }

    if ("`vce'" != "") {
        di as txt "VCE:                " as res "`vce'"
    }
    else if ("`vcetype'" != "") {
        di as txt "VCE:                " as res "`vcetype'"
    }

    if (`FS_clust' < .) {
        di as txt "Clusters:           " as res %10.0f `FS_clust'
    }

    if (`FS_conv' < .) {
        local convtext "Yes"
        if (`FS_conv' == 0) local convtext "No"
        di as txt "Converged:          " as res "`convtext'"
    }

    if (`perfect_available') {
        if (`cds_pos' > 0) {
            di as txt "Completely determined successes: " as res %8.0f `FS_cds'
        }
        if (`cdf_pos' > 0) {
            di as txt "Completely determined failures:  " as res %8.0f `FS_cdf'
        }
    }

    di as txt "Omitted terms:      " as res %10.0f `omitted'
    if (`omitted' > 0) {
        di as txt "                     " as res "`omitted_terms'"
    }

    if (`vce_available') {
        di as txt "SE/VCE diagonal issues:" as res %7.0f `se_problem_count'
        if (`se_problem_count' > 0) {
            di as txt "                     " as res "`se_problem_terms'"
        }
    }

    if (`nfactorvars' > 0) {
        di as txt "Factor variables:   " as res "`factor_vars'"
    }

    if (`ninteractionsets' > 0) {
        di as txt "2-way categorical interactions: " as res "`interaction_sets'"
    }

    if (`higher_interactions' > 0) {
        di as txt "Higher-order categorical interaction coefficients: " ///
            as res `higher_interactions' as txt " (cell parsing deferred)"
    }

    /*
        Optional cell tables.
    */
    if ("`cells'" != "" & `cellrows' > 0) {
        di
        di as txt "Factor-variable outcome cells"
        di as txt "{hline 72}"
        di as txt %18s "Variable" " " %10s "Level" " " ///
            %8s "N" " " %8s "Events" " " %10s "Non-events"

        foreach fv of local factor_vars {
            quietly levelsof `fv' if `FS_sample', local(FS_levels2)
            foreach lv of local FS_levels2 {
                quietly count if `FS_sample' & `fv' == `lv'
                local n0 = r(N)
                quietly count if `FS_sample' & `fv' == `lv' & ///
                    !missing(`depvar') & `depvar' != 0
                local e0 = r(N)
                quietly count if `FS_sample' & `fv' == `lv' & ///
                    !missing(`depvar') & `depvar' == 0
                local ne0 = r(N)

                di as res %18s substr("`fv'",1,18) " " ///
                    %10.0g `lv' " " %8.0f `n0' " " ///
                    %8.0f `e0' " " %10.0f `ne0'
            }
        }
    }

    if ("`cells'" != "" & `irows' > 0) {
        di
        di as txt "Two-way categorical interaction outcome cells"
        di as txt "{hline 78}"
        di as txt %14s "Interaction" " " %8s "Level 1" " " %8s "Level 2" " " ///
            %7s "N" " " %8s "Events" " " %10s "Non-events"

        foreach iset of local interaction_sets {
            local ivars : subinstr local iset "+" " ", all
            local v1 : word 1 of `ivars'
            local v2 : word 2 of `ivars'

            quietly levelsof `v1' if `FS_sample', local(FS_L1b)
            quietly levelsof `v2' if `FS_sample', local(FS_L2b)

            foreach l1 of local FS_L1b {
                foreach l2 of local FS_L2b {
                    quietly count if `FS_sample' & `v1' == `l1' & `v2' == `l2'
                    local n0 = r(N)

                    if (`n0' > 0) {
                        quietly count if `FS_sample' & `v1' == `l1' & ///
                            `v2' == `l2' & !missing(`depvar') & `depvar' != 0
                        local e0 = r(N)

                        quietly count if `FS_sample' & `v1' == `l1' & ///
                            `v2' == `l2' & !missing(`depvar') & `depvar' == 0
                        local ne0 = r(N)

                        di as res %14s substr("`v1'x`v2'",1,14) " " ///
                            %8.0g `l1' " " %8.0g `l2' " " %7.0f `n0' " " ///
                            %8.0f `e0' " " %10.0f `ne0'
                    }
                }
            }
        }
    }

    di
    di as txt "Signals detected"
    di as txt "{hline 72}"

    if (`nsignals' == 0) {
        di as result "No structural or requested threshold signals detected."
    }
    else {
        if (`FS_conv' < . & `FS_conv' == 0) {
            di as error "FS001  WARNING  Estimation did not report convergence."
        }

        if (`omitted' > 0) {
            di as error "FS002  NOTICE   One or more coefficients were omitted during estimation."
            di as txt   "                Review collinearity, empty cells, and model coding."
        }

        if (`perfect_available' & `determined_total' > 0) {
            di as error "FS003  WARNING  The estimator reports completely determined outcomes."
            if (`cds_pos' > 0) {
                di as txt "                Completely determined successes: " ///
                    as res `FS_cds'
            }
            if (`cdf_pos' > 0) {
                di as txt "                Completely determined failures:  " ///
                    as res `FS_cdf'
            }
            di as txt   "                Review perfect-prediction/separation structure."
        }

        if (`zero_factor_cells' > 0) {
            di as error "FS101  CAUTION  At least one factor level has zero events or zero non-events"
            di as txt   "                within the final e(sample). This is descriptive cell structure"
            di as txt   "                and is not a complete separation diagnostic."
            di as txt   "                `zero_factor_details'"
        }

        if (`sparse_factor_levels' > 0) {
            di as error "FS102  NOTICE   At least one factor level is below user-specified mincell(`mincell')."
            di as txt   "                `sparse_factor_details'"
        }

        if (`zero_interaction_cells' > 0) {
            di as error "FS103  CAUTION  At least one observed two-way interaction cell has zero events"
            di as txt   "                or zero non-events within the final e(sample)."
            di as txt   "                `zero_interaction_details'"
        }

        if (`sparse_interaction_cells' > 0) {
            di as error "FS104  NOTICE   At least one observed two-way interaction cell is below"
            di as txt   "                user-specified mincell(`mincell')."
            di as txt   "                `sparse_interaction_details'"
        }

        if (`se_problem_count' > 0) {
            di as error "FS201  WARNING  At least one estimated parameter has a missing or"
            di as txt   "                nonpositive variance on the diagonal of e(V)."
            di as txt   "                Review the affected standard errors / covariance estimate."
            di as txt   "                `se_problem_terms'"
        }

        if (`minclusters' > 0 & `FS_clust' < . & `FS_clust' < `minclusters') {
            di as error "FS202  NOTICE   Cluster count is below user-specified minclusters(`minclusters')."
            di as txt   "                Observed clusters: " as res `FS_clust' as txt "."
        }

        if (!`sample_available') {
            di as error "FS901  NOTICE   e(sample) is unavailable; sample-based checks are limited."
        }
    }

    di
    if (`mincell' == 0) {
        di as txt "No generic sparse-cell cutoff was applied. Use mincell(#) only when"
        di as txt "you want FailSafe to report levels below a threshold you specify."
    }
    if (`minclusters' == 0 & `FS_clust' < .) {
        di as txt "No generic cluster-count cutoff was applied. Use minclusters(#) only"
        di as txt "when you want a threshold you specify."
    }
    di as txt "FailSafe reports signals for review; it does not determine whether"
    di as txt "the fitted model is statistically or substantively appropriate."

    /*
        Returned results.
    */
    return clear

    if (`cellrows' > 0) {
        return matrix factor_cells = `FCELLS'
    }
    if (`irows' > 0) {
        return matrix interaction_cells = `ICELLS'
    }

    return local cmd "`cmd'"
    return local cmd2 "`cmd2'"
    return local depvar "`depvar'"
    return local vce "`vce'"
    return local vcetype "`vcetype'"
    return local omitted_terms "`omitted_terms'"
    return local factor_vars "`factor_vars'"
    return local interaction_sets "`interaction_sets'"
    return local se_problem_terms "`se_problem_terms'"
    return local signal_codes "`signal_codes'"

    return scalar N = `FS_N'
    return scalar coef_columns = `coef_columns'
    return scalar vce_rank = `FS_rank'
    return scalar rank = `FS_rank'
    return scalar modeldf = `FS_dfm'
    return scalar events = `events'
    return scalar nonevents = `nonevents'
    return scalar failures = `failures'
    return scalar competing = `competing'
    return scalar censored = `censored'
    return scalar subjects = `subjects'
    return scalar epdf = `epdf'
    return scalar clusters = `FS_clust'
    return scalar converged = `FS_conv'
    return scalar cds = `FS_cds'
    return scalar cdf = `FS_cdf'
    return scalar determined_total = `determined_total'
    return scalar perfect_available = `perfect_available'
    return scalar omitted = `omitted'
    return scalar sample_available = `sample_available'
    return scalar nfactorvars = `nfactorvars'
    return scalar interaction_coef_terms = `interaction_coef_terms'
    return scalar ninteractionsets = `ninteractionsets'
    return scalar higher_interactions = `higher_interactions'
    return scalar factor_cell_rows = `cellrows'
    return scalar interaction_cell_rows = `irows'
    return scalar zero_factor_cells = `zero_factor_cells'
    return scalar sparse_factor_levels = `sparse_factor_levels'
    return scalar zero_interaction_cells = `zero_interaction_cells'
    return scalar sparse_interaction_cells = `sparse_interaction_cells'
    return scalar vce_available = `vce_available'
    return scalar se_problem_count = `se_problem_count'
    return scalar mincell = `mincell'
    return scalar minclusters = `minclusters'
    return scalar nsignals = `nsignals'
end
