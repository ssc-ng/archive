/* Additional ML and explainability output for PIRNEX estimation prototype. */
version 16.0
quietly {
    tempfile __pn_ml_data
    save `__pn_ml_data'
    import delimited using "pirnex_ml_comparison_v18.csv", clear varnames(1)
    noisily di as text _newline "=============================================================================="
    noisily di as result "                   PIRNEX | MACHINE LEARNING COMPARISON"
    noisily di as text "=============================================================================="
    noisily di as text "Model                Test Pair R2     Test Pair RMSE        Pair MSE"
    noisily di as text "------------------------------------------------------------------------------"
    forvalues i=1/`=_N' {
        local nm=model[`i']
        noisily di as text %20s "`nm'" as result %15.5f test_pair_r2[`i'] %18.5f test_pair_rmse[`i'] %16.5f test_pair_mse[`i']
    }
    noisily di as text "=============================================================================="
    noisily di as text "XGBoost/EBM: level training; PIRNEX: within-ID pair training."
    capture confirm file "pirnex_neural_ig_summary_v19.csv"
    if !_rc {
        import delimited using "pirnex_neural_ig_summary_v19.csv", clear varnames(1)
        noisily di as text _newline "=============================================================================="
        noisily di as result "                   PIRNEX | NEURAL INTEGRATED GRADIENTS"
        noisily di as text "=============================================================================="
        noisily di as text "Variable          Mean |contrib.|     Mean contrib.    Positive    Negative"
        noisily di as text "------------------------------------------------------------------------------"
        forvalues i=1/`=_N' {
            local nm=variable[`i']
            noisily di as text %15s "`nm'" as result %17.5f mean_abs_contribution[`i'] %18.5f mean_signed_contribution[`i'] %12.3f positive_share[`i'] %12.3f negative_share[`i']
        }
        noisily di as text "=============================================================================="
        noisily di as text "IG is path-dependent attribution, not a marginal or causal effect."
    }
    capture confirm file "pirnex_explain_summary_v20.csv"
    if !_rc {
        import delimited using "pirnex_explain_summary_v20.csv", clear varnames(1) stringcols(_all)
        noisily di as text _newline "=============================================================================="
        noisily di as result "                   PIRNEX | XGBOOST SHAP / EBM EXPLANATIONS"
        noisily di as text "=============================================================================="
        noisily di as text "Model          Term                    Mean |level|  Mean |pair|  Mean pair"
        noisily di as text "------------------------------------------------------------------------------"
        forvalues i=1/`=_N' {
            local nm=model[`i']
            local term=term[`i']
            local term : subinstr local term "feature_0000" "tenure", all
            local term : subinstr local term "feature_0001" "hours", all
            local term : subinstr local term "feature_0002" "union", all
            local term : subinstr local term "feature_0003" "year", all
            local term : subinstr local term "_x_" "_x_", all
            local short=cond(strpos("`nm'","XGBoost"),"XGBoost SHAP","EBM terms")
            noisily di as text %13s "`short'" "  " %25s "`term'" as result %13.5f real(mean_abs_level_contribution[`i']) %13.5f real(mean_abs_pair_contribution[`i']) %11.5f real(mean_pair_contribution[`i'])
        }
        noisily di as text "=============================================================================="
        noisily di as text "XGBoost: TreeSHAP. EBM: native terms (NOT SHAP). Predictive, not causal."
    }
    use `__pn_ml_data', clear
}
