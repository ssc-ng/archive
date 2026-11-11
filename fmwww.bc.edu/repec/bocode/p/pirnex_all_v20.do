/* PIRNEX v2.0 | ALL RESULTS IN ONE CLEAN STATA REPORT
   Reads the verified outputs from v1.7/v1.8/v1.9; no model retraining.
   Exactly the previous estimation table followed by ML, neural IG and XAI.
   EBM generic term names are mapped to real variable names.
   Experimental Wald/z p-values are NOT validated inference.
*/
version 16.0
quietly {
    set more off
    cd "C:\Users\DELL\Downloads"
    confirm file "pirnex_metrics_v17.csv"
    confirm file "pirnex_unified_v17.csv"
    confirm file "pirnex_ml_comparison_v18.csv"
    confirm file "pirnex_explain_summary_v181.csv"
    confirm file "pirnex_neural_ig_summary_v19.csv"
    confirm file "pirnex_neural_ig_metrics_v19.csv"

    preserve
    import delimited using "pirnex_metrics_v17.csv", clear varnames(1)
    scalar pr_train = train_n[1]
    scalar pr_pairs = train_pairs[1]
    scalar pr_r2 = test_pair_r2[1]
    scalar pr_rmse = test_pair_rmse[1]
    scalar pr_wald = wald_chi2_exploratory[1]
    scalar pr_prob = wald_prob_exploratory[1]
    scalar pr_df = wald_df[1]
    scalar pr_testpairs = test_pairs[1]
    restore

    preserve
    import delimited using "pirnex_unified_v17.csv", clear varnames(1)
    noisily display as text _newline "=============================================================================="
    noisily display as result "                         PIRNEX ESTIMATION RESULTS"
    noisily display as text "=============================================================================="
    noisily display as text "Training observations = " as result %9.0fc scalar(pr_train) ///
        as text "          Training pairs = " as result %8.0fc scalar(pr_pairs)
    noisily display as text _newline "Test Pairwise R-squared = " as result %8.5f scalar(pr_r2)
    noisily display as text "Test Pairwise RMSE      = " as result %8.5f scalar(pr_rmse)
    noisily display as text _newline "Wald chi2(" as result %1.0f scalar(pr_df) as text ") [EXP]       = " as result %9.4f scalar(pr_wald)
    noisily display as text "Prob > chi2 [EXP]       = " as result %9.6f scalar(pr_prob)
    noisily display as text _newline "------------------------------------------------------------------------------"
    noisily display as text "Variable       Effect      Boot.SE       z[EXP]    P>|z|[EXP]      95% CI"
    noisily display as text "------------------------------------------------------------------------------"
    forvalues i=1/`=_N' {
        local nm = variable[`i']
        noisily display as text %13s "`nm'" "  " ///
            as result %10.5f ame[`i'] "  " %10.5f boot_se[`i'] "  " ///
            %10.3f z_exploratory[`i'] "  " %11.5f p_exploratory[`i'] "   [" ///
            %8.5f ci_lo[`i'] "," %8.5f ci_hi[`i'] "]"
    }
    noisily display as text "------------------------------------------------------------------------------"
    noisily display as result "                   PIRNEX CONDITIONAL EFFECT STRUCTURE"
    noisily display as text "------------------------------------------------------------------------------"
    noisily display as text "Variable           Low effect     High effect      Effect SD   Positive share"
    noisily display as text "------------------------------------------------------------------------------"
    forvalues i=1/`=_N' {
        local nm = variable[`i']
        noisily display as text %15s "`nm'" "  " ///
            as result %12.5f low_effect[`i'] "  " %12.5f high_effect[`i'] "  " ///
            %11.5f effect_sd[`i'] "  " %14.3f pos_share[`i']
    }
    noisily display as text "------------------------------------------------------------------------------"
    noisily display as text "Low/High: predictor p10/p90, other inputs at reference values."
    noisily display as text "Union 0-to-1 contrast evaluated at low/high TENURE."
    noisily display as text "=============================================================================="
    noisily display as text "[EXP] Wald/z reference p-values are experimental; NOT validated inference."
    noisily display as text "Effects are associations, not causal estimates."
    restore

    preserve
    import delimited using "pirnex_ml_comparison_v18.csv", varnames(1) clear
    assert test_pairs == scalar(pr_testpairs)
    noisily display as text _newline "=============================================================================="
    noisily display as result "                   PIRNEX | MACHINE LEARNING COMPARISON"
    noisily display as text "=============================================================================="
    noisily display as text "Model               Test Pair R2      Test Pair RMSE      Pair MSE"
    noisily display as text "------------------------------------------------------------------------------"
    forvalues i=1/`=_N' {
       local nm=model[`i']
       noisily display as text %19s "`nm'" "    " ///
          as result %10.5f test_pair_r2[`i'] "         " ///
          %10.5f test_pair_rmse[`i'] "     " %10.5f test_pair_mse[`i']
    }
    noisily display as text "=============================================================================="
    noisily display as text "Same test pairs. Neural trains on within-ID differences;"
    noisily display as text "XGBoost/EBM train on levels and are evaluated on pair differences."
    restore

    preserve
    import delimited using "pirnex_neural_ig_metrics_v19.csv", varnames(1) clear
    scalar ig_pairs=test_pairs[1]
    scalar ig_r2=test_pair_r2[1]
    scalar ig_max=max_additivity_error[1]
    assert abs(scalar(ig_r2)-scalar(pr_r2))<0.0001
    assert scalar(ig_pairs)==scalar(pr_testpairs)
    restore
    preserve
    import delimited using "pirnex_neural_ig_summary_v19.csv", varnames(1) clear
    noisily display as text _newline "=============================================================================="
    noisily display as result "                   PIRNEX | NEURAL INTEGRATED GRADIENTS"
    noisily display as text "=============================================================================="
    noisily display as text "Variable          Mean |contrib.|     Mean contrib.    Positive    Negative"
    noisily display as text "------------------------------------------------------------------------------"
    forvalues i=1/`=_N' {
        local nm=variable[`i']
        noisily display as text %15s "`nm'" "    " as result ///
            %12.5f mean_abs_contribution[`i'] "      " ///
            %12.5f mean_signed_contribution[`i'] "      " ///
            %7.3f positive_share[`i'] "    " %7.3f negative_share[`i']
    }
    noisily display as text "=============================================================================="
    noisily display as text "Test pair attribution additivity max error = " as result %10.8f scalar(ig_max)
    noisily display as text "IG is path-dependent attribution, not a marginal or causal effect."
    restore

    preserve
    import delimited using "pirnex_explain_summary_v181.csv", varnames(1) clear
    * Normalize feature labels from EBM's auto-generated feature_0000 names.
    forvalues i=1/`=_N' {
        local nm=term[`i']
        local nm=subinstr("`nm'", "feature_0000", "tenure", .)
        local nm=subinstr("`nm'", "feature_0001", "hours", .)
        local nm=subinstr("`nm'", "feature_0002", "union", .)
        local nm=subinstr("`nm'", "feature_0003", "year", .)
        replace term="`nm'" in `i'
    }
    noisily display as text _newline "=============================================================================="
    noisily display as result "                   PIRNEX | XGBOOST SHAP / EBM EXPLANATIONS"
    noisily display as text "=============================================================================="
    noisily display as text "Model          Term                   Mean |level|  Mean |pair|  Mean pair"
    noisily display as text "------------------------------------------------------------------------------"
    forvalues i=1/`=_N' {
        local modelname=model[`i']
        local shortname=cond("`modelname'"=="XGBoost TreeSHAP","XGBoost SHAP","EBM terms")
        local nm=term[`i']
        noisily display as text %13s "`shortname'" "  " %23s "`nm'" "  " ///
            as result %9.5f mean_abs_level_contribution[`i'] "  " ///
            %9.5f mean_abs_pair_contribution[`i'] "  " ///
            %9.5f mean_pair_contribution[`i']
    }
    noisily display as text "=============================================================================="
    noisily display as text "XGBoost: TreeSHAP. EBM: native additive terms (NOT SHAP)."
    noisily display as text "Pair contribution = later attribution minus earlier attribution."
    noisily display as text "All attribution statistics are predictive, not causal."
    restore
    noisily display as result _newline "PIRNEX v2.0 | Complete report finished."
}
