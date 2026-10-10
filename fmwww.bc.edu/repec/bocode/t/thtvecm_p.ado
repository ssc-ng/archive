*! thtvecm_p 1.0.0  02oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! predict after thtvecm. The dependent variables are the FIRST DIFFERENCES,
*! so xb and residuals refer to D.y, not to y.

program define thtvecm_p
    version 15
    syntax newvarname [if] [in] [, XB Residuals EC REGime EQuation(string) ]

    if "`e(cmd)'" != "thtvecm" {
        display as error "last estimates not found, or not from {bf:thtvecm}"
        exit 301
    }
    local nopt : word count `xb' `residuals' `ec' `regime'
    if `nopt' > 1 {
        display as error "only one of xb, residuals, ec, regime may be specified"
        exit 198
    }
    if `nopt' == 0 local xb xb

    marksample touse, novarlist
    quietly replace `touse' = 0 if !e(sample)

    local yv "`e(depvars)'"
    local k  = e(k_var)
    local p  = e(lags)

    * ---- the error-correction term, beta'y_{t-1} with beta normalised to 1
    tempname BE
    matrix `BE' = e(beta)
    tempvar ecv
    quietly generate double `ecv' = 0 if `touse'
    local j 0
    foreach v of local yv {
        local ++j
        quietly replace `ecv' = `ecv' + `BE'[1,`j'] * L.`v' if `touse'
    }

    if "`ec'" != "" {
        quietly generate double `varlist' = `ecv' if `touse'
        label variable `varlist' "Error-correction term, beta'y(t-1)"
        exit
    }

    local mdl "`e(model)'"

    tempname GAM
    scalar `GAM' = e(gamma)
    if "`regime'" != "" {
        if "`mdl'" == "tvecm3" {
            * three regimes, so a two-way split would be wrong: e(gamma) is
            * only the FIRST threshold in that fit
            tempname G1 G2
            scalar `G1' = e(gamma1)
            scalar `G2' = e(gamma2)
            quietly generate byte `varlist' = ///
                1 + (`ecv' > `G1') + (`ecv' > `G2') if `touse'
            label variable `varlist' ///
                "Regime (1: low, 2: middle/band, 3: high)"
            exit
        }
        quietly generate byte `varlist' = 1 + (`ecv' > `GAM') if `touse'
        if "`mdl'" == "tvecm_sls" {
            * the smoothed fit has no sharp regimes. This reports the side of
            * the threshold each observation falls on, which is where the
            * transition weight passes one half -- useful for description,
            * but the FITTED VALUES use the smooth weight, not this split.
            label variable `varlist' ///
                "Side of the threshold (1: ec <= gamma, 2: ec > gamma)"
            exit
        }
        label variable `varlist' "Regime (1: ec <= gamma, 2: ec > gamma)"
        exit
    }

    if "`equation'" == "" local equation 1
    local ej 0
    local i 0
    foreach v of local yv {
        local ++i
        if "`v'" == "`equation'" local ej `i'
    }
    if `ej' == 0 {
        capture confirm integer number `equation'
        if _rc | `equation' < 1 | `equation' > `k' {
            display as error "equation() must be a name in `yv' or an integer 1-`k'"
            exit 198
        }
        local ej `equation'
    }
    local dv : word `ej' of `yv'

    * =================================================================
    * The three-regime and smoothed fits post a coefficient vector of a
    * different shape and do NOT post e(A1)/e(A2), so the two-regime
    * arithmetic below cannot be used for them. Reading a matrix that does
    * not exist would not even raise an error -- matrix X = e(A1) yields a
    * 1 x 1 missing matrix with rc 0 -- so this branch is what stops the
    * prediction being silently wrong.
    *
    * Work from e(b) by NAME. The column names carry the block, so the same
    * code covers the free fit, the band restriction with its missing middle
    * ec, and the pooled outer block of restrict(equal).
    * =================================================================
    if inlist("`mdl'", "tvecm3", "tvecm_sls") {
        tempname BV
        matrix `BV' = e(b)
        local blocks "`e(blocks)'"
        local wnm    "`e(wnames)'"
        local restr  "`e(restrict)'"
        tempname T1 T2 HBW
        if "`mdl'" == "tvecm3" {
            scalar `T1' = e(gamma1)
            scalar `T2' = e(gamma2)
        }
        else {
            scalar `T1' = e(gamma)
            scalar `HBW' = e(bw)
        }

        tempvar xb2
        quietly generate double `xb2' = 0 if `touse'
        foreach bl of local blocks {
            tempvar wt
            if "`mdl'" == "tvecm3" {
                if "`bl'" == "Low" ///
                    quietly generate double `wt' = (`ecv' <= `T1') if `touse'
                if "`bl'" == "High" ///
                    quietly generate double `wt' = (`ecv' > `T2') if `touse'
                if "`bl'" == "Middle" ///
                    quietly generate double `wt' = ///
                        (`ecv' > `T1' & `ecv' <= `T2') if `touse'
                if "`bl'" == "Outer" ///
                    quietly generate double `wt' = ///
                        (`ecv' <= `T1' | `ecv' > `T2') if `touse'
            }
            else {
                * the SMOOTH weight, the one the estimator actually used. A
                * smoothed fit's prediction is not a sharp-split prediction,
                * and substituting one for the other would make the
                * residuals here differ from the residuals the fit
                * minimised.
                if "`bl'" == "R1" ///
                    quietly generate double `wt' = ///
                        normal((`T1' - `ecv')/`HBW') if `touse'
                if "`bl'" == "R2" ///
                    quietly generate double `wt' = ///
                        1 - normal((`T1' - `ecv')/`HBW') if `touse'
            }
            foreach nw of local wnm {
                if "`restr'" == "band" & "`bl'" == "Middle" ///
                    & "`nw'" == "ec" continue
                local cc = colnumb(`BV', "`bl'_D_`dv':`nw'")
                if `cc' == . {
                    display as error ///
                        "internal: e(b) has no column `bl'_D_`dv':`nw'"
                    exit 498
                }
                if "`nw'" == "_cons" {
                    quietly replace `xb2' = ///
                        `xb2' + `BV'[1,`cc'] * `wt' if `touse'
                }
                else if "`nw'" == "ec" {
                    quietly replace `xb2' = ///
                        `xb2' + `BV'[1,`cc'] * `ecv' * `wt' if `touse'
                }
                else {
                    local dpos = strpos("`nw'", ".")
                    local lgn  = real(substr("`nw'", 3, `dpos' - 3))
                    local vnm  = substr("`nw'", `dpos' + 1, .)
                    quietly replace `xb2' = `xb2' + ///
                        `BV'[1,`cc'] * L`lgn'.D.`vnm' * `wt' if `touse'
                }
            }
        }

        if "`xb'" != "" {
            quietly generate double `varlist' = `xb2' if `touse'
            label variable `varlist' "Linear prediction of D.`dv'"
            exit
        }
        quietly generate double `varlist' = D.`dv' - `xb2' if `touse'
        label variable `varlist' "Residuals, equation D.`dv'"
        exit
    }

    * ---- the regressors, in the order thtvecm built them: constant, ec,
    *      then the lagged differences lag major
    local wvars ""
    forvalues j = 1/`p' {
        foreach v of local yv {
            tempvar d`j'_`v'
            quietly generate double `d`j'_`v'' = L`j'.D.`v' if `touse'
            local wvars `wvars' `d`j'_`v''
        }
    }

    tempname A1 A2
    matrix `A1' = e(A1)
    matrix `A2' = e(A2)
    tempvar xb_
    quietly generate double `xb_' = 0 if `touse'
    local r 0
    if e(hascons) == 1 {
        local ++r
        quietly replace `xb_' = `xb_' + ///
            cond(`ecv' <= `GAM', `A1'[`r',`ej'], `A2'[`r',`ej']) if `touse'
    }
    local ++r
    quietly replace `xb_' = `xb_' + ///
        cond(`ecv' <= `GAM', `A1'[`r',`ej'], `A2'[`r',`ej']) * `ecv' if `touse'
    foreach v of local wvars {
        local ++r
        quietly replace `xb_' = `xb_' + ///
            cond(`ecv' <= `GAM', `A1'[`r',`ej'], `A2'[`r',`ej']) * `v' if `touse'
    }

    if "`xb'" != "" {
        quietly generate double `varlist' = `xb_' if `touse'
        label variable `varlist' "Linear prediction of D.`dv'"
        exit
    }
    quietly generate double `varlist' = D.`dv' - `xb_' if `touse'
    label variable `varlist' "Residuals, equation D.`dv'"
end
