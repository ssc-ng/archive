* =====================================================================
* xtqqr_example.do  --  worked example for the xtqqr package
* Panel quantile-on-quantile regression (xtqqr), panel QQKRLS (xtqqkrls)
* and graphs (xtqqplot).
* Dr Merwan Roudane  <merwanroudane920@gmail.com>
* =====================================================================
* Simulated panel with a KNOWN quantile-on-quantile surface:
*   y_it = a_i + 0.5 x + 0.5 x 1(x>0) + 0.3 z + (1 + 0.3 x 1(x>0)) e
*   x_it = 0.7 a_i + v_it          (unit effect correlated with x)
* True slope b1(tau,theta):
*   0.5                          if x^theta < 0   (lower half of x)
*   1 + 0.3 * invnormal(tau)     if x^theta > 0   (upper half of x)
* =====================================================================

clear
set seed 2026
set obs 60
gen id = _n
gen a  = rnormal()
expand 25
bysort id: gen year = 1995 + _n
xtset id year
gen x = 0.7*a + rnormal()
gen z = rnormal()
gen y = a + 0.5*x + 0.5*x*(x>0) + 0.3*z + (1 + 0.3*x*(x>0))*rnormal()
label var y "outcome"
label var x "QQ regressor"
label var z "control"

* ---------------------------------------------------------------------
* 1. Panel QQR (Sim & Zhou 2015) with Canay fixed effects + validation
* ---------------------------------------------------------------------
xtqqr y x z, validate

xtqqplot, heatmap                        name(fig_heat)
xtqqplot, heatmap colormap(bwr)          name(fig_heat_bwr)
xtqqplot, heatmap combine                name(fig_combine)
xtqqplot, slices at(0.2 0.5 0.8)         name(fig_slices)
xtqqplot, validate                       name(fig_valid)

* a coarser grid with the values printed in the cells
xtqqr y x z, tau(0.1(0.1)0.9) theta(0.1(0.1)0.9) notable
xtqqplot, heatmap values                 name(fig_values)

* ---------------------------------------------------------------------
* 2. Variants from the literature
* ---------------------------------------------------------------------
* pooled QQ (Wu et al. 2021)
xtqqr y x, fe(none) tau(0.1(0.1)0.9) theta(0.1(0.1)0.9)

* unit-specific quantiles of x + time effects (Atsalakis et al. 2021)
xtqqr y x z, xref(unit) timefe bw(0.10) tau(0.1(0.1)0.9) theta(0.1(0.1)0.9)

* quantile groups of a lagged regressor (Clance et al.)
xtqqr y L.x, method(groups) groups(4) timefe tau(0.1(0.1)0.9)
xtqqplot, heatmap colormap(bwr)          name(fig_groups)

* panel block bootstrap on a small grid
xtqqr y x z, tau(0.25 0.5 0.75) theta(0.25 0.5 0.75) vce(bootstrap) reps(100) seed(1)

* save the surface for MATLAB / R 3-D plots
xtqqr y x z, tau(0.1(0.1)0.9) theta(0.1(0.1)0.9) notable saving(qq_surface, replace)

* ---------------------------------------------------------------------
* 3. Panel QQKRLS (Adebayo et al. 2024; Sonail et al. 2026)
*    requires: ssc install krls
* ---------------------------------------------------------------------
capture which krls
if _rc == 0 {
    xtqqkrls y x, tau(0.1(0.1)0.9) theta(0.2(0.1)0.9) seed(1)
    xtqqplot, heatmap                    name(fig_krls)
    xtqqplot, ame                        name(fig_ame)
    * within (fixed-effects) version: removes the a_i-x correlation
    xtqqkrls y x z, fe(within) tau(0.1(0.1)0.9) theta(0.2(0.1)0.9) seed(1)
    xtqqplot, ame                        name(fig_ame_fe)
}
else {
    di as txt "krls not installed: ssc install krls"
}

* ---------------------------------------------------------------------
* 4. (optional) Monte Carlo coverage of the clustered sandwich
*    set run_mc to 1 to execute (about 2 minutes)
* ---------------------------------------------------------------------
local run_mc 0
if `run_mc' {
    tempname R
    tempfile mc
    postfile `R' b30 s30 b80 s80 using `mc', replace
    forvalues r = 1/200 {
        quietly {
            clear
            set obs 60
            gen id = _n
            gen a = rnormal()
            expand 25
            bysort id: gen t = _n
            xtset id t
            gen x = 0.7*a + rnormal()
            gen z = rnormal()
            gen y = a + 0.5*x + 0.5*x*(x>0) + 0.3*z + (1 + 0.3*x*(x>0))*rnormal()
            xtqqr y x z, tau(0.5) theta(0.3 0.8) nodots notable
            matrix B = e(coef)
            matrix S = e(se)
        }
        post `R' (B[1,1]) (S[1,1]) (B[1,2]) (S[1,2])
    }
    postclose `R'
    use `mc', clear
    gen cover30 = abs(b30 - 0.5) <= 1.96*s30
    gen cover80 = abs(b80 - 1.0) <= 1.96*s80
    summarize
}
