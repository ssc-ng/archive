*! _mvardlurt_multivariate_boot  version 1.1.2  03oct2026
*! Residual bootstrap engine for mvardlurt_multivariate
*! Sam, McNown, Goh and Goh (2024), section 4.2
*!
*!   t-test: model re-estimated with beta1 = 0 imposed (L.y dropped);
*!           y* rebuilt recursively; t* from the full ARDL on y*.
*!   F-test: model re-estimated with beta2 = 0 imposed (all L.x dropped);
*!           y* rebuilt recursively; F* from the full ARDL on y*.
*!   Residuals are centred, rescaled by sqrt(n/(n-m)) and resampled with
*!   replacement; covariates are held at their observed values.
*!
*! Called by mvardlurt_multivariate after the Mata engine has stored the final
*! regression (mvu_Z, mvu_dep, mvu_y, ...). The Mata code is in
*! _mvardlurt_multivariate_bmata.ado (loaded by _mvardlurt_multivariate_load).

capture program drop _mvardlurt_multivariate_boot
program define _mvardlurt_multivariate_boot, rclass
    version 14
    syntax , REPS(integer) ALPHA(real) TSTAT(real) FSTAT(real)

    _mvardlurt_multivariate_load, boot

    tempname CVB INFO
    matrix `CVB'  = J(2, 5, .)
    matrix `INFO' = J(1, 4, .)

    local mvu_err ""
    capture noisily mata: mvu_boot_run()
    if _rc {
        di as err "bootstrap engine failed (rc = " _rc "); the regression objects may have been cleared"
        exit 498
    }
    if "`mvu_err'" == "1" {
        di as err "bootstrap failed: regression objects not in memory"
        exit 498
    }
    if "`mvu_err'" == "4" {
        di as err "bootstrap failed (too few valid replications)"
        exit 498
    }

    return matrix cv   = `CVB'
    return matrix info = `INFO'
end
