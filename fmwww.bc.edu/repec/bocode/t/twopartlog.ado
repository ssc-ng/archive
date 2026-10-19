*! twopartlog.ado - Two-Part Log Model with Optimal Zero-Handling Constant
*! Version 1.1.0 - 2026
*! Methodology based on Lien, Hu, & Liu (2025, Applied Economics Letters)
*! Author: Dereje Fedasa Hordofa, Dire Dawa University, Ethiopia

program define twopartlog, eclass
    version 16.0
    syntax varlist(min=2 max=2) [if] [in], GENerate(name) [METHOD(string) C_fixed(real -999) GRID(integer 100)]
    
    marksample touse
    gettoken y x: varlist
    
    if "`method'" == "" {
        local method "gslt"
    }
    
    di as text ""
    di as text "{hline 78}"
    di as text "{bf:twopartlog: Two-Part Log Regression with Optimal Zero Constant}"
    di as text "{bf:Methodology: Lien, Hu, & Liu (2025) | Author: Dereje Fedasa Hordofa}"
    di as text "{hline 78}"
    di as text "Dependent Variable (y):    " as result "`y'"
    di as text "Independent Var (x, 0s):   " as result "`x'"
    di as text "Transformation Method:     " as result upper("`method'")
    if `c_fixed' != -999 {
        di as text "Constant (c) Setting:      " as result "Fixed at " `c_fixed'
    }
    else {
        di as text "Constant (c) Setting:      " as result "Estimated via Concentrated NLS"
    }
    di as text "{hline 78}"
    
    preserve
    qui keep if `touse'
    
    qui summarize `x'
    if r(min) < 0 {
        di as error "Error: Independent variable `x' must be >= 0."
        exit 411
    }
    
    if `c_fixed' != -999 {
        scalar opt_c = `c_fixed'
        scalar min_rss = .
        di as text "Using user-specified fixed constant c = " scalar(opt_c)
    }
    else {
        di as text "Step 1: Running concentrated least squares search for optimal c..."
        mata: twopartlog_optimizer("`y'", "`x'", "`method'", `grid')
        scalar opt_c = r_opt_c
        scalar min_rss = r_min_rss
        di as text "Optimal Constant (c-hat) = " as result %10.4f scalar(opt_c)
    }
    
    di as text ""
    di as text "Step 2: Estimating final two-part regression model..."
    
    tempvar d_zero t_var
    qui gen byte `d_zero' = (`x' == 0)
    
    if "`method'" == "gihst" {
        qui gen double `t_var' = ln(`x' + sqrt(`x'^2 + scalar(opt_c))) if `x' > 0
    }
    else {
        qui gen double `t_var' = ln(`x' + scalar(opt_c)) if `x' > 0
    }
    qui replace `t_var' = 0 if `x' == 0
    
    tempvar d_trans x_trans
    qui gen byte `d_trans' = (`x' > 0)
    qui gen double `x_trans' = `d_trans' * `t_var'
    
    regress `y' `d_zero' `x_trans', vce(robust)
    
    matrix b_reg = e(b)
    scalar b_zero = b_reg[1, 1]  
    scalar b_trans = b_reg[1, 2] 
    
    tempvar elasticity
    if "`method'" == "gihst" {
        qui gen double `elasticity' = b_trans * (`x' * (`x'^2 + scalar(opt_c))^(-0.5)) if `x' > 0
    }
    else {
        qui gen double `elasticity' = b_trans * (`x' / (`x' + scalar(opt_c))) if `x' > 0
    }
    qui sum `elasticity' if `x' > 0, meanonly
    scalar avg_elasticity = r(mean)
    
    if "`method'" == "gihst" {
        scalar test_stat = b_zero - b_trans * (ln(scalar(opt_c)) / 2)
    }
    else {
        scalar test_stat = b_zero - b_trans * ln(scalar(opt_c))
    }
    
    di as text ""
    di as text "{hline 78}"
    di as text "{bf:Post-Estimation Diagnostic & Elasticity Report:}"
    di as text "{hline 78}"
    di as text "Average Elasticity (for x > 0):  " as result %9.4f scalar(avg_elasticity)
    di as text "Continuity Test Difference (H0): " as result %9.4f scalar(test_stat)
    di as text "{hline 78}"
    
    if "`generate'" != "" {
        capture drop `generate'
        qui gen double `generate' = `t_var'
        local c_fmt : display %9.4f scalar(opt_c)
        label variable `generate' "Transformed `x' (optimal c = `c_fmt')"
        di as text "Note: Transformed variable saved as: " as result "`generate'"
    }
    
    ereturn scalar c_opt = scalar(opt_c)
    ereturn scalar rss = scalar(min_rss)
    ereturn scalar elasticity = scalar(avg_elasticity)
    ereturn scalar test_continuity = scalar(test_stat)
    ereturn local method "`method'"
    ereturn local cmd "twopartlog"
    
    restore
end

version 16.0
mata:
void twopartlog_optimizer(string scalar y_name, string scalar x_name, string scalar method, real scalar grid_pts)
{
    real vector y, x
    st_view(y, ., y_name)
    st_view(x, ., x_name)
    
    real scalar max_x
    max_x = max(x)
    
    real vector c_grid
    if (method == "gihst") {
        c_grid = range(0.01, max_x, grid_pts)
    }
    else {
        c_grid = range(0.001, max_x, grid_pts)
    }
    
    real scalar i, c_val, rss, best_c, min_rss
    min_rss = 1e12
    best_c = 1.0
    
    real vector t_v, d_z, d_t, res
    real matrix X_mat
    real vector beta_vec
    
    for(i=1; i<=rows(c_grid); i++) {
        c_val = c_grid[i]
        d_z = (x :== 0)
        d_t = (x :> 0)
        
        if (method == "gihst") {
            t_v = d_t :* ln(x :+ sqrt(x:^2 :+ c_val))
        } else {
            t_v = d_t :* ln(x :+ c_val)
        }
        
        X_mat = J(rows(y), 1, 1), d_z, t_v
        beta_vec = invsym(cross(X_mat, X_mat)) * cross(X_mat, y)
        res = y - (X_mat * beta_vec)
        rss = quadcross(res, res)
        
        if (rss < min_rss) {
            min_rss = rss
            best_c = c_val
        }
    }
    
    st_numscalar("r_opt_c", best_c)
    st_numscalar("r_min_rss", min_rss)
}
end