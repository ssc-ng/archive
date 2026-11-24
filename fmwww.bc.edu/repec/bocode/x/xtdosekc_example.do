* =============================================================================
*  xtdosekc_example.do
*  Full replication of Amoroso, Garcia-Martos and Koopman (2026),
*  "A Dynamic Nonlinear Panel Decomposition Model for the Global
*   Environmental Kuznets Curve", The Econometrics Journal.
*  Author of xtdosekc: Dr Merwan Roudane (merwanroudane920@gmail.com)
*
*  Get the data with:  net get xtdosekc   (installs xtdosekc_g20.dta here)
*  Run time: about 5 minutes with B = 500 bootstrap draws (set B lower to test).
* =============================================================================
clear
set more off
version 15.0
local B 500
local seed 20260226
use xtdosekc_g20, clear
xtset id year

* -----------------------------------------------------------------------------
*  Figure 1. The difference-of-sigmoids function (x* = 6.01)
* -----------------------------------------------------------------------------
xtdosekc illustrate, gname(fig1)

* -----------------------------------------------------------------------------
*  Table 1 and Figure 3. Single-equation static fits, country by country.
*  As in R/01_helper_functions.R, each country starts at the published optimum
*  (columns: mu gamma c1 c2gap s1 s2, with c2 = c1 + c2gap + 0.001).
* -----------------------------------------------------------------------------
matrix S = ( 1.36711417955419, 1.70314660303597, 2.70507068628478, 1e-06, 6.71982950742327, 4.98685144714441 \ ///
             1.39763710616122, 4.14003828492473, 4.19352718186283, 1e-06, 0.811799066543749, 7.14999833783242 \ ///
            -6.65795824152522, 15.7437443849399, 0.278111318542323, 0.0122119503376701, 1.58702713041561, 1e-06 \ ///
            -3.44320801644175, 11.3957709575705, 1.17553237196991, 2.95036599670994, 0.0904330678477681, 12.2770663634864 \ ///
            -0.190139966973609, 8.37644796267124, 3.12714501234542, 0.377125134417475, 1.009350181144, 2.33467363929113 \ ///
            -17.3503160443798, 38.7557459443002, 2.68109920707986, 1.58364921574903, 1e-06, 7.71013608286624 \ ///
             2.90689209300259, 6.33157637875685, 2.51863030868933, 1e-06, 1e-06, 0.32442477528536 \ ///
            -1.39920415651851, 4.86945777816726, 1e-06, 2.90518298233885e-05, 1.22006274434573, 1e-06 \ ///
            -0.115426295052713, 2.31511485535704, 1.36747442407133, 0.374358151638594, 1.95540631402092, 1e-06 \ ///
             1.91116381751537, 19.3871881375298, 3.23856422219683, 0.000386589900688486, 10.207710454218, 10.0220928142673 \ ///
             2.10046534138483, 2.33028861919855, 3.38938359140184, 0.0151870706368283, 11.6979467640143, 9.07596894520849 \ ///
             1.34255559831738, 18.2083949535901, 2.73772635031614, 1e-06, 12.7411047525125, 12.9880421465394 \ ///
            -4.73710847211768, 13.2996023633378, 1e-06, 0.314627527978988, 1.19177492686784, 1e-06 \ ///
            -4.98289049964191, 14.4863200231144, 2.58315717230184, 1.33143929420919, 0.0201327279703441, 12.0894517251614 \ ///
            -1.05044033356165, 7.82492924074776, 3.21685557834823, 1.07978216168371, 0.200258867188913, 9.32815679286961 )
xtdosekc ln_co2 ln_gdp, model(country) from(S) idlabel(country) nodiag ///
    graph(fit) gname(fig3) tex(table1.tex)

* -----------------------------------------------------------------------------
*  Figure 2 (data), Figure 4 (pooled fits) and Figure 5 (residual diagnostics):
*  static DoS panel model with fixed effects (Section 4.3)
* -----------------------------------------------------------------------------
xtdosekc ln_co2 ln_gdp, model(static) idlabel(iso3) group(advanced) ///
    graph(data fit diag) gname(fe)

* -----------------------------------------------------------------------------
*  Table 2. Dynamic nonlinear panel models (Section 4.4)
* -----------------------------------------------------------------------------
* Global model with bootstrap standard errors
xtdosekc ln_co2 ln_gdp, reps(`B') seed(`seed') idlabel(country) expscale(1000) ///
    nodiag graph(curve) gname(glob)
estimates store Global
* E7 (emerging) and G7 + Australia (advanced): no SEs, as in the paper.
* The replication code (R/06_model_tw.R) bounds c1, c2 below by min(x) of the FULL
* panel and calls optim() without control(), i.e. R's default maxit = 100; clb()
* and maxiter(100) reproduce those settings (E7 stops at the iteration limit).
qui summ ln_gdp
local xmin = r(min)
xtdosekc ln_co2 ln_gdp if advanced == 0, clb(`xmin') maxiter(100) idlabel(country) ///
    nodiag graph(curve) gname(e7)
estimates store E7
xtdosekc ln_co2 ln_gdp if advanced == 1, clb(`xmin') maxiter(100) idlabel(country) ///
    nodiag graph(curve) gname(g7)
estimates store G7
* Regional model (preferred): separate green-transition location for Europe
xtdosekc ln_co2 ln_gdp, shift(europe) reps(`B') seed(`seed') idlabel(country) ///
    expscale(1000) group(advanced) graph(curve trends dfm decomp boot) gname(reg) ///
    tex(table2_3.tex)
estimates store Regional

* Figure 6: Global, E7 and G7 structural curves side by side
graph combine glob_curve e7_curve g7_curve, rows(1) graphregion(color(white)) ///
    xsize(12) ysize(4.5) name(fig6, replace)

* Table 2 side by side (Est. and bootstrap SE)
di _n as txt "{bf:Table 2. Parameter estimates for different model specifications}"
di as txt "{hline 76}"
di as txt %16s "" %10s "Global" %8s "SE" %10s "E7" %10s "G7" %12s "Regional" %8s "SE"
di as txt "{hline 76}"
local rows "gamma c1 c2 c2_shift s1 s2 c2_minus_c1 c2_minus_c2shift xstar xstar_shift xstar_gap"
foreach r of local rows {
    local line ""
    foreach m in Global E7 G7 Regional {
        qui estimates restore `m'
        tempname T
        matrix `T' = e(table)
        local k = rownumb(`T', "`r'")
        local e = .
        local s = .
        if !missing(`k') {
            local e = `T'[`k', 1]
            local s = `T'[`k', 2]
            if strpos("`r'", "xstar") & "`r'" != "xstar_gap" {
                local f = cond("`r'" == "xstar", "int_xstar", "int_xstar_shift")
                if `T'[rownumb(`T', "`f'"), 1] != 1 local e = .
            }
        }
        local line "`line' `e' `s'"
    }
    tokenize `line'
    di as txt %16s "`r'" as res %10.3f `1' %8.3f `2' %10.3f `3' %10.3f `5' %12.3f `7' %8.3f `8'
}
foreach m in Global E7 G7 Regional {
    qui estimates restore `m'
    local ll`m' = e(ll)
}
di as txt %16s "Log-likelihood" as res %10.2f `llGlobal' %8s "" %10.2f `llE7' %10.2f `llG7' %12.2f `llRegional'
di as txt "{hline 76}"
di as txt "Paper: Global 984.83, E7 459.41, G7 516.43 (E7 + G7 = 975.84), Regional 992.39."
qui estimates restore Regional

* -----------------------------------------------------------------------------
*  Online Appendix
* -----------------------------------------------------------------------------
* S1.2: penalty sensitivity (Tables S1-S2)
xtdosekc sens ln_co2 ln_gdp, shift(europe)

* S2.1: deterministic versus stochastic trends (Tables S3-S5); authors' start
* values for the linear-trend model (R/09_deterministic_trends.R)
matrix TS = (1.00094763370398, 1.89677351767153, 0.34700236913865, 1.93613619906854, ///
    1.50100766138036, 1.25182016534646, 1.87113345523286, 0.54633299974729,          ///
    0.369342382335564, 1.20907085534276, 1.23243632844419, 1.27433642937774,         ///
    0.86692556984481, 1.67872360343572, 1.99557544254549,                            ///
    -0.00591640094685398, -0.0111691186532512, 0.00199538126395651,                  ///
    -0.0134871472379283, 0.00276680599416399, -0.0225840979374132,                   ///
    -0.0265724857738893, 0.00764989765102977, 0.00588685850373479,                   ///
    -0.0129286955762889, -0.00436282638931786, -0.0111157196842857,                  ///
    -0.000154942126978462, -0.0262526906472055, -0.0169680935335663,                 ///
    16.6199349557055, 2.07011153292962, 0.00256721091704041, 0.188765314979074, 1e-06)
xtdosekc compare ln_co2 ln_gdp, trendfrom(TS) idlabel(iso3)

* S3: integration properties (Tables S6-S7)
xtdosekc integ ln_co2 ln_gdp, idlabel(iso3)

* -----------------------------------------------------------------------------
*  Known-truth check: simulate eqs (2.1)-(2.3) and recover the parameters
*  truth: gamma 4, c1 1, c2 3.8, s1 1.2, s2 3, sigma_eps 0.03, sigma_eta 0.012
* -----------------------------------------------------------------------------
preserve
clear
set seed 12345
local N 20
local T 60
set obs `=`N' * `T''
gen id = ceil(_n / `T')
bysort id: gen t = _n
xtset id t
bysort id (t): gen double x0 = 0.3 + 3.2 * (id - 1) / (`N' - 1) if _n == 1
bysort id (t): replace x0 = x0[1]
gen double g = 0.01 + 0.02 * runiform()
bysort id (t): replace g = g[1]
gen double x = x0 + g * (t - 1) + 0.02 * rnormal()
gen double eta = 0.012 * rnormal()
bysort id (t): gen double tau = sum(eta) - eta[1]
gen double mu = -2 + 0.5 * id / `N'
gen double dos = 4 * (1 / (1 + exp(-1.2 * (x - 1))) - 1 / (1 + exp(-3 * (x - 3.8))))
gen double y = mu + dos + tau + 0.03 * rnormal()
xtdosekc y x, reps(100) seed(1) nodiag
di as txt "Truth: gamma 4, c1 1, c2 3.8, s1 1.2, s2 3, sigma_eps .03, sigma_eta .012"
restore
