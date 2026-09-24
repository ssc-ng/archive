*! version 0.1.3 19may2026
program define mi_impute_cmd_glemb_cleanup
    version 17.0

    if "${MI_IMPUTE_GLEMB_profile}" != "1" {
        exit
    }

    local n = ${MI_IMPUTE_GLEMB_n}
    if (`n' <= 0) {
        exit
    }

    if (${MI_IMPUTE_GLEMB_nonconv} > 0) {
        di as err "warning: " as res ${MI_IMPUTE_GLEMB_nonconv} ///
            as err " of " as res `n' as err " imputation(s) did not converge"
    }

    di as txt "glemb profile: mean ECM iterations = " ///
        as res %6.2f (${MI_IMPUTE_GLEMB_iter_sum} / `n') ///
        as txt ", max = " as res ${MI_IMPUTE_GLEMB_iter_max}
    di as txt "glemb profile: mean Mata seconds per imputation"
    di as txt "  read data        " as res %8.4f (${MI_IMPUTE_GLEMB_read} / `n') ///
        as txt "    bootstrap       " as res %8.4f (${MI_IMPUTE_GLEMB_bootstrap} / `n') ///
        as txt "    pseudo/prior    " as res %8.4f (${MI_IMPUTE_GLEMB_pseudo} / `n')
    di as txt "  boot prelim      " as res %8.4f (${MI_IMPUTE_GLEMB_boot_prelim} / `n') ///
        as txt "    ECM             " as res %8.4f (${MI_IMPUTE_GLEMB_ecm} / `n') ///
        as txt "    orig prelim     " as res %8.4f (${MI_IMPUTE_GLEMB_orig_prelim} / `n')
    di as txt "  impute           " as res %8.4f (${MI_IMPUTE_GLEMB_impute} / `n') ///
        as txt "    store to Stata   " as res %8.4f (${MI_IMPUTE_GLEMB_store} / `n')
    di as txt "glemb profile: mean ECM component seconds per imputation"
    di as txt "  E-step           " as res %8.4f (${MI_IMPUTE_GLEMB_estep} / `n') ///
        as txt "    M-step          " as res %8.4f (${MI_IMPUTE_GLEMB_mstep} / `n') ///
        as txt "    IPF             " as res %8.4f (${MI_IMPUTE_GLEMB_ipf} / `n')
    di as txt "glemb profile: mean E-step row counts per imputation"
    di as txt "  deterministic    " as res %8.2f (${MI_IMPUTE_GLEMB_det_rows} / `n') ///
        as txt "    active rows     " as res %8.2f (${MI_IMPUTE_GLEMB_active_rows} / `n')
    di as txt "  deterministic wt " as res %8.2f (${MI_IMPUTE_GLEMB_det_weight} / `n') ///
        as txt "    active wt       " as res %8.2f (${MI_IMPUTE_GLEMB_active_weight} / `n')
end
