/* PIRNEX estimation prototype report; reads active folder CSV, prints only results */
version 16.0
quietly {
    tempfile __pn_report_base
    save `__pn_report_base'
    import delimited using "pirnex_metrics_v17.csv", clear varnames(1)
        scalar __pn_n=train_n[1]
        scalar __pn_pairs=train_pairs[1]
        scalar __pn_r2=test_pair_r2[1]
        scalar __pn_rmse=test_pair_rmse[1]
        scalar __pn_wald=wald_chi2_exploratory[1]
        scalar __pn_prob=wald_prob_exploratory[1]
        scalar __pn_df=wald_df[1]
    import delimited using "pirnex_unified_v17.csv", clear varnames(1)
        noisily di as text _newline "=============================================================================="
        noisily di as result "                         PIRNEX ESTIMATION RESULTS"
        noisily di as text "=============================================================================="
        noisily di as text "Training observations = " as result %9.0fc scalar(__pn_n) ///
            as text "          Training pairs = " as result %9.0fc scalar(__pn_pairs)
        noisily di as text "Test Pairwise R-squared = " as result %8.5f scalar(__pn_r2)
        noisily di as text "Test Pairwise RMSE      = " as result %8.5f scalar(__pn_rmse)
        noisily di as text "Wald chi2(" %1.0f scalar(__pn_df) ") [EXP] = " as result %11.4f scalar(__pn_wald)
        noisily di as text "Prob > chi2 [EXP]       = " as result %11.6f scalar(__pn_prob)
        noisily di as text "------------------------------------------------------------------------------"
        noisily di as text "Variable       Effect      Boot.SE       z[EXP]    P>|z|[EXP]      95% CI"
        noisily di as text "------------------------------------------------------------------------------"
        forvalues i=1/`=_N' {
            local nm=variable[`i']
            noisily di as text %13s "`nm'" "  " as result %9.5f ame[`i'] " " ///
                %9.5f boot_se[`i'] "  " %8.3f z_exploratory[`i'] "  " ///
                %9.5f p_exploratory[`i'] "  [" %8.5f ci_lo[`i'] "," %8.5f ci_hi[`i'] "]"
        }
        noisily di as text "------------------------------------------------------------------------------"
        noisily di as result "                   PIRNEX CONDITIONAL EFFECT STRUCTURE"
        noisily di as text "------------------------------------------------------------------------------"
        noisily di as text "Variable        Low effect     High effect      Effect SD   Positive share"
        forvalues i=1/`=_N' {
            local nm=variable[`i']
            noisily di as text %13s "`nm'" "  " as result %11.5f low_effect[`i'] " " ///
                %13.5f high_effect[`i'] " " %11.5f effect_sd[`i'] " " %12.3f pos_share[`i']
        }
        noisily di as text "=============================================================================="
        noisily di as text "[EXP] Exploratory Wald/z p-values; NOT validated inference. Associations only."
    use `__pn_report_base', clear
}
