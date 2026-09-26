/*
  SREG 1.0.0: hands-on walkthrough (Stata 14.2+)
  Project website: https://sreg-project.github.io
  Stata version of the R package sreg; no R installation is required.

  Install the package and download its examples from SSC:
      ssc install sreg, all replace

  This downloads try_sreg.do and sreg_aejapp.dta to the current folder.
  Run from that folder in a fresh Stata session:
      do try_sreg.do
  Optional argument: output folder (its parent must already exist):
      do try_sreg.do "/path/to/output"

  This walkthrough uses the installed package and the downloaded dataset.
  It does not reinstall the package or require a repository checkout.
  Save your data first: it replaces data in memory and creates a log, result
  tables, saved estimates and SVG plots. Rerunning replaces those outputs.
*/
version 14.2
clear all
set more off
set linesize 100
set rng mt64
args output_dir

* 1. Check the installed commands and downloaded example data.
which sreg
which sreg_rgen
which sregplot
local data_file `"`c(pwd)'/sreg_aejapp.dta"'
capture confirm file `"`data_file'"'
if _rc {
    display as error "Download the example data using one of the routes above, then run from that folder."
    exit 601
}
if `"`output_dir'"' == "" local output_dir `"`c(pwd)'/sreg_output"'
capture mkdir `"`output_dir'"'
local starting_dir `"`c(pwd)'"'
quietly cd `"`output_dir'"'
local output_dir `"`c(pwd)'"'
quietly cd `"`starting_dir'"'
capture log close sreg_walkthrough
log using `"`output_dir'/sreg_walkthrough.log"', text replace name(sreg_walkthrough)
* Interactive documentation: help sreg | help sreg_rgen | help sregplot

* Collect individual treatment estimates after each model.
* r(table) holds: coefficient, SE, z, p, CI lower, CI upper (rows 1-6).
* Copy it immediately, before other commands can overwrite r().
postfile results str32 model byte arm double estimate double se double z ///
    double p double ci_lower double ci_upper long N long units ///
    using `"`output_dir'/sreg_results.dta"', replace
capture program drop sreg_demo_collect
program define sreg_demo_collect
    args handle model
    tempname T
    matrix `T' = r(table)
    forvalues j=1/`=colsof(`T')' {
        post `handle' ("`model'") (`j') (`T'[1,`j']) (`T'[2,`j']) ///
            (`T'[3,`j']) (`T'[4,`j']) (`T'[5,`j']) (`T'[6,`j']) (e(N)) (e(N_units))
    }
end

* 2. Six designs: individual / cluster x large / small / mixed strata.
* Each dataset has two active treatments and is fitted with and without X.
foreach assignment in individual cluster {
    foreach design in large small mixed {
        set seed 20260913
        local generator_options
        local estimator_options
        if "`assignment'" == "individual" {
            local generator_options individual
            local n = 1200
            local nsmall = 720
        }
        else {
            local n = 360
            local nsmall = 216
            local estimator_options cluster(G_id) clustersize(Ng)
        }
        if "`design'" == "small" {
            local generator_options `generator_options' smallstrata k(3) treatsizes(1 1 1)
            local estimator_options `estimator_options' smallstrata k(3)
        }
        if "`design'" == "mixed" {
            local generator_options `generator_options' mixedstrata nsmall(`nsmall') k(3) treatsizes(1 1 1)
            local estimator_options `estimator_options' smallstrata k(3)
        }
        display as text "=== `assignment' assignment / `design' strata ==="
        sreg_rgen, n(`n') strata(4) tau(.5 .8) `generator_options' clear
        describe
        list in 1/6, abbreviate(14)
        foreach adjusted in 0 1 {
            local xvars
            if `adjusted' local xvars x_1 x_2
            local model `assignment'_`design'_`adjusted'
            sreg Y `xvars', treatment(D) strata(S) `estimator_options'
            sreg_demo_collect results `model'
            estimates store `model'
            estimates save `"`output_dir'/`model'.ster"', replace
        }
        * Inspect estimates, their covariance, adjustment slopes and metadata.
        ereturn list
        matrix B = e(b)
        matrix V = e(V)
        matrix slopes = e(beta)
        matrix list B
        matrix list V
        matrix list slopes
        display "Treatment 1: estimate = " _b[tau1] "; SE = " _se[tau1]
        generate byte estimation_sample = e(sample)
        count if estimation_sample
        * An individual treatment-versus-control test and a treatment contrast.
        lincom tau1
        lincom tau2 - tau1
        if "`design'" == "mixed" {
            matrix list e(b_small)
            matrix list e(b_large)
            matrix list e(beta_small)
            matrix list e(beta_large)
            display "Small-component population share = " e(p_small)
        }
        sregplot, treatmentlabels("Treatment 1" "Treatment 2") ///
            title("`assignment': `design' strata") bgcolor(white)
        graph export `"`output_dir'/`assignment'_`design'.svg"', replace
    }
}

* 3. Other useful options: one treatment, no stratification, HC1 off, 90% CI.
set seed 20260914
sreg_rgen, n(1000) individual strata(1) tau(.5) clear
sreg Y x_1, treatment(D) nohc1 level(90)
sreg_demo_collect results individual_onearm_90

* Four active treatments in general k-tuples (control + four = five units).
set seed 20260915
sreg_rgen, n(1000) individual tau(.2 .4 .6 .8) ///
    smallstrata k(5) treatsizes(1 1 1 1 1) clear
sreg Y x_1 x_2, treatment(D) strata(S) smallstrata k(5)
sreg_demo_collect results individual_fourarm

* Inferred versus supplied cluster sizes: here all cluster members are observed.
set seed 20260916
sreg_rgen, n(300) strata(4) tau(.5 .8) clear
sreg Y x_1 x_2, treatment(D) strata(S) cluster(G_id) clustersize(Ng)
sreg_demo_collect results cluster_sizes_supplied
matrix supplied = e(b)
sreg Y x_1 x_2, treatment(D) strata(S) cluster(G_id)
sreg_demo_collect results cluster_sizes_inferred
matrix inferred = e(b)
matrix list supplied
matrix list inferred

* 4. Empirical example: Peru iron supplementation study.
* Chong et al. (2016), Iron Deficiency and Schooling Attainment in Peru.
* Dataset source and variable provenance: help sreg_aejapp.
* The included data contain all 215 observations and 62 original variables.
use `"`data_file'"', clear
assert _N == 215
describe
* Recode treatment 3 as the control (0).
generate byte D = cond(treatment == 3, 0, treatment)
tabulate D class_level
list gradesq34 D class_level pills_taken age_months in 1/10

sreg gradesq34, treatment(D) strata(class_level)
sreg_demo_collect results empirical_unadjusted
estimates store empirical_unadjusted
estimates save `"`output_dir'/empirical_unadjusted.ster"', replace
* Expected estimates approximately -0.05113 and 0.40903.

sreg gradesq34 pills_taken age_months, treatment(D) strata(class_level)
sreg_demo_collect results empirical_adjusted
estimates store empirical_adjusted
estimates save `"`output_dir'/empirical_adjusted.ster"', replace
* Expected adjusted estimates approximately -0.02862 and 0.34609.
matrix empirical_b = e(b)
matrix empirical_V = e(V)
matrix empirical_beta = e(beta)
matrix list empirical_b
matrix list empirical_V
matrix list empirical_beta
sregplot, treatmentlabels("Treatment 1" "Treatment 2") ///
    title("Peru: school grades, covariate adjusted") bgcolor(white)
graph export `"`output_dir'/empirical_adjusted.svg"', replace
estimates table empirical_unadjusted empirical_adjusted, b(%9.5f) se(%9.5f) stats(N)

* 5. Inspect/export all model results, then restore the empirical estimate.
postclose results
preserve
use `"`output_dir'/sreg_results.dta"', clear
format estimate se z ci_lower ci_upper %10.5f
format p %9.5f
list, sepby(model) noobs abbreviate(32)
export delimited using `"`output_dir'/sreg_results.csv"', replace
restore
estimates restore empirical_adjusted
sreg
* To reload this fit in a later Stata session:
* estimates use "/path/to/output/empirical_adjusted.ster"
* sreg
capture program drop sreg_demo_collect
display as result `"Walkthrough finished. Results saved in: `output_dir'"'
log close sreg_walkthrough
