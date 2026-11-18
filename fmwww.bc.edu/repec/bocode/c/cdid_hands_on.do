*! Hands-on guide to cdid for Stata (Stata 19.5 or later)
*! Do-file for docs/hands-on.md
*! Repository: https://github.com/dvbn/cdid-stata
*!
*! USAGE IN THE STATA DO-FILE EDITOR:
*!   1. Start a new Stata session (or set global CDID_DEMO_CLEAR_OK = 1 below
*!      after saving the data in memory).
*!   2. Run Section 0 first to define the CDID_DEMO_* globals and helper program
*!      `cdid_demo_init`, then run the numbered sections in order (each section calls
*!      `cdid_demo_init`, so sections can be run one at a time).
*!   3. Graphs, exported datasets and saved results are kept on disk only when
*!      global CDID_DEMO_OUTDIR names a folder; existing files there are never
*!      overwritten unless global CDID_DEMO_REPLACE = 1. Otherwise exported
*!      datasets and saved results are written to temporary files in c(tmpdir),
*!      which Stata erases when the do-file (or the selection being run) ends,
*!      and no graph is saved.

version 19.5

* ==============================================================================
* SECTION 0: Settings and initialization
* ==============================================================================
* Edit these globals to explore different panel sizes, missingness regimes,
* covariate-dependent untreated trends, treatment effect heterogeneity, and
* multiplier bootstrap draw counts.
*
* Note on bootstrap draws:
*   The package default in `cdid` and `cdid_pretest` is `biters(1000)`.
*   This guide uses `CDID_DEMO_BITERS = 199` so that the examples run quickly.

if `"$CDID_DEMO_CLEAR_OK"' == "" global CDID_DEMO_CLEAR_OK      0          // Set to 1 to allow Section 1 to clear memory
if `"$CDID_DEMO_N"' == "" global CDID_DEMO_N             800        // Number of units (600-1000 recommended)
if `"$CDID_DEMO_T"' == "" global CDID_DEMO_T             6          // Number of calendar periods (5 or 6 recommended)
if `"$CDID_DEMO_SEED"' == "" global CDID_DEMO_SEED          20261103   // Random-number seed for the simulated data
if `"$CDID_DEMO_BITERS"' == "" global CDID_DEMO_BITERS        199        // Bootstrap draws (package default is 1000)
if `"$CDID_DEMO_MISS_LAW"' == "" global CDID_DEMO_MISS_LAW      "conditional_mtar" // "mcar", "conditional_mtar", or "rotating_window"
if `"$CDID_DEMO_MISS_STRENGTH"' == "" global CDID_DEMO_MISS_STRENGTH 0.85       // Strength of covariate-driven observation log-odds
if `"$CDID_DEMO_TREND_HET"' == "" global CDID_DEMO_TREND_HET     0.35       // Covariate slope in untreated outcome changes
if `"$CDID_DEMO_EFF_BASE"' == "" global CDID_DEMO_EFF_BASE      1.20       // Baseline post-treatment causal effect
if `"$CDID_DEMO_EFF_SLOPE"' == "" global CDID_DEMO_EFF_SLOPE     0.30       // Effect growth per event-time period after treatment
if `"$CDID_DEMO_EFF_HET"' == "" global CDID_DEMO_EFF_HET       0.25       // Effect heterogeneity by binary covariate x_bin
if `"$CDID_DEMO_RUN_ADVANCED"' == "" global CDID_DEMO_RUN_ADVANCED  0          // Set to 1 to run optional advanced comparisons
if `"$CDID_DEMO_OUTDIR"' == "" global CDID_DEMO_OUTDIR        ""         // Folder for graphs, datasets and saved results ("" = temporary files only)
if `"$CDID_DEMO_REPLACE"' == "" global CDID_DEMO_REPLACE       0          // Set to 1 to allow cdid_plot/cdid_export to overwrite files

capture program drop cdid_demo_init
program define cdid_demo_init
    version 19.5
    if `"$CDID_DEMO_CLEAR_OK"'      == "" global CDID_DEMO_CLEAR_OK      0
    if `"$CDID_DEMO_N"'             == "" global CDID_DEMO_N             800
    if `"$CDID_DEMO_T"'             == "" global CDID_DEMO_T             6
    if `"$CDID_DEMO_SEED"'          == "" global CDID_DEMO_SEED          20261103
    if `"$CDID_DEMO_BITERS"'        == "" global CDID_DEMO_BITERS        199
    if `"$CDID_DEMO_MISS_LAW"'      == "" global CDID_DEMO_MISS_LAW      "conditional_mtar"
    if `"$CDID_DEMO_MISS_STRENGTH"' == "" global CDID_DEMO_MISS_STRENGTH 0.85
    if `"$CDID_DEMO_TREND_HET"'     == "" global CDID_DEMO_TREND_HET     0.35
    if `"$CDID_DEMO_EFF_BASE"'      == "" global CDID_DEMO_EFF_BASE      1.20
    if `"$CDID_DEMO_EFF_SLOPE"'     == "" global CDID_DEMO_EFF_SLOPE     0.30
    if `"$CDID_DEMO_EFF_HET"'       == "" global CDID_DEMO_EFF_HET       0.25
    if `"$CDID_DEMO_RUN_ADVANCED"'  == "" global CDID_DEMO_RUN_ADVANCED  0
    if `"$CDID_DEMO_REPLACE"'       == "" global CDID_DEMO_REPLACE       0
    quietly mata: mata mlib index
end

cdid_demo_init


* ==============================================================================
* SECTION 1: Simulated panel and unit table (frame)
* ==============================================================================
* Pedagogical points:
*   - Every unit has a time-constant cohort date `first_treat` (`0` = never treated;
*     positive numeric calendar dates `3` and `5` = staggered treatment cohorts).
*   - Dates (`period`) are numeric (`1..T`), and `(id, period)` rows are unique.
*   - Untreated outcomes are generated from their CHANGES:
*       Y_{it}(0) - Y_{i,t-1}(0) = delta_t + theta * X_i + (eps_{it} - eps_{i,t-1})
*     with unit fixed effects alpha_i in levels. Fixed unit effects
*     cancel in within-unit outcome changes (Y_{it} - Y_{is}), so identification
*     requires representativeness with respect to MEAN OUTCOME CHANGES, not
*     equal outcome levels between observed and unobserved units.
*   - Every unit is represented in the long dataset even when outcome `y` is missing
*     at a date (`y == .`), and rows with missing `y` keep their covariates,
*     cohort, cluster, and sampling weights.
*   - We also construct a separate unit-level population table in frame `cdid_pop`
*     to show how `frame()` defines the study population of N units when some
*     units have no observed outcome in the long panel.

cdid_demo_init
if $CDID_DEMO_CLEAR_OK != 1 & (c(N) > 0 | c(k) > 0 | c(changed) == 1) {
    display as error "Active dataset in memory. Save your work or set global CDID_DEMO_CLEAR_OK = 1."
    exit 4
}

clear
set seed $CDID_DEMO_SEED

local N = $CDID_DEMO_N
local T = $CDID_DEMO_T
set obs `N'

generate long id = _n
generate long cluster_id = ceil(id / 8)

* Staggered treatment cohorts: 0 = never treated (~40%), 3 = early (~30%), 5 = late (~30%)
generate double u_cohort = runiform()
generate long first_treat = cond(u_cohort < 0.40, 0, cond(u_cohort < 0.70, 3, 5))
drop u_cohort

* Unit covariates and fixed unit effect alpha_i
generate byte   x_bin  = (runiform() < cond(first_treat == 3, 0.60, cond(first_treat == 5, 0.50, 0.40)))
generate double x_cont = rnormal(0.20 * (first_treat > 0), 1.0)
generate double z_sel  = rnormal(0.30 * x_bin, 1.0)
generate double alpha_i = 2.50 * (first_treat == 3) - 1.25 * (first_treat == 5) + 1.50 * x_bin + rnormal(0, 1.0)
generate double w_unit  = exp(0.20 * x_bin + 0.10 * x_cont)

* Save the unit table of the study population in frame `cdid_pop`
capture frame drop cdid_pop
frame put id first_treat x_bin x_cont z_sel w_unit cluster_id, into(cdid_pop)

* Expand to balanced (id, period) long grid; missing outcomes are represented as `y = .`
expand `T'
bysort id: generate long period = _n

* Time-varying sampling weight (to illustrate `fixweights(first_period)` vs `fixweights(base_period)`)
generate double w_tv = w_unit * (1 + 0.03 * (period - 1))

* Untreated potential outcome Y_{it}(0) with covariate-dependent untreated changes
generate double trend_t = 0.25 * (period - 1) + ($CDID_DEMO_TREND_HET) * x_bin * (period - 1) ///
    + 0.20 * x_cont * (period - 1)
generate double eps_it  = rnormal(0, 0.50)
generate double y0      = alpha_i + trend_t + eps_it

* Treatment effect on treated cohorts (zero before treatment)
generate double tau_it = cond(first_treat > 0 & period >= first_treat, ///
    ($CDID_DEMO_EFF_BASE) + ($CDID_DEMO_EFF_SLOPE) * (period - first_treat) + ($CDID_DEMO_EFF_HET) * x_bin, 0)
generate double y_full = y0 + tau_it

* Observation indicator R_{it}, by missingness design:
*   1. "mcar": uniform observation probability across units and dates.
*   2. "conditional_mtar": date observation probabilities depend on x_bin and z_sel
*      and are conditionally independent given both covariates, before the
*      edits below that create units observed once or never. Models using only x_bin omit z_sel;
*      a direct linear pair logit need not equal a product of date logits.
*   3. "rotating_window": each unit is observed only in a two-period adjacent window,
*      violating conditional date independence across arbitrary pairs (s, t).
generate byte obs_y = 1
if "$CDID_DEMO_MISS_LAW" == "mcar" {
    replace obs_y = (runiform() < 0.82)
}
else if "$CDID_DEMO_MISS_LAW" == "rotating_window" {
    bysort id (period): generate long start_win = 1 + mod(id, `T' - 1)
    replace obs_y = (period == start_win | period == start_win + 1)
    drop start_win
}
else {
    generate double logit_p = 1.15 + ($CDID_DEMO_MISS_STRENGTH) * (x_bin - 0.5) ///
        + 0.35 * z_sel - 0.08 * (period - 1)
    replace obs_y = (runiform() < invlogit(logit_p))
    drop logit_p
}

* Designate a small set of units (id <= 6) as never-observed in `y` so the population
* table (`cdid_pop`) and long dataset illustrate 0-observation and 1-observation units
replace obs_y = 0 if id <= 6
replace obs_y = (period == 1) if inrange(id, 7, 12)

* Observed outcome `y`: missing when obs_y == 0, while covariates/cohort/weights stay nonmissing
generate double y = cond(obs_y == 1, y_full, .)

label variable id          "Unit identifier"
label variable period      "Calendar period (1..T)"
label variable first_treat "First treatment period (0 = never treated)"
label variable y           "Observed outcome (missing when unobserved)"
label variable x_bin       "Binary baseline covariate"
label variable x_cont      "Continuous baseline covariate"
label variable z_sel       "Selection-specific predictor"
label variable w_unit      "Time-constant unit sampling weight"
label variable w_tv        "Time-varying sampling weight"
label variable cluster_id  "Unit-level cluster identifier"


* ==============================================================================
* SECTION 2: Missingness checks and the study population
* ==============================================================================
* Pedagogical points:
*   - Every unit of the study population (N units) has a cohort `first_treat`.
*   - Chained DiD forms elementary two-date differences Delta Y_{i,s,t} = Y_{it} - Y_{is}
*     using the units observed at BOTH dates s and t.
*   - Under the assumptions stated, units observed at both dates represent
*     the cohort with respect to the mean outcome change between s and t, while
*     aggregation weights are computed over the study population of N units.
*   - Always inspect per-unit observation counts (0, 1, or >=2 observed dates),
*     date-by-cohort outcome coverage, and pair overlap before fitting.

cdid_demo_init

* 2a. Count observed outcome dates per unit across all units in the long dataset
tempvar n_obs_unit tag_unit
bysort id: egen long `n_obs_unit' = count(y)
bysort id: generate byte `tag_unit' = (_n == 1)

display as text _n "=== Unit-level count of observed outcome dates (0, 1, >=2) ==="
tabulate `n_obs_unit' first_treat if `tag_unit', missing

* 2b. Inspect outcome observation rates by calendar period and cohort
display as text _n "=== Outcome observation indicator (obs_y) by period and cohort ==="
tabulate period first_treat, summarize(obs_y) means

* 2c. Compare covariate composition across all units vs repeat-observer units (>=2 dates)
display as text _n "=== Covariate means: all population units vs units with >=2 observed dates ==="
summarize x_bin x_cont z_sel if `tag_unit'
summarize x_bin x_cont z_sel if `tag_unit' & `n_obs_unit' >= 2


* ==============================================================================
* SECTION 3: Chained estimation: control groups, base periods, parallel trends
* ==============================================================================
* Pedagogical points:
*   - `controlgroup(nevertreated)` (default) uses `first_treat == 0` as controls;
*     `controlgroup(notyettreated)` adds cohorts not yet treated at `max(s, t) + anticipation`.
*   - `baseperiod(varying)` (default) reports pre-treatment cells against adjacent
*     reference periods; `baseperiod(universal)` anchors reporting to `g - 1 - anticipation`.
*   - `ptassumption(post)` (default) imposes parallel trends from `g - 1 - anticipation`
*     onward; `ptassumption(all)` imposes parallel trends from a common
*     calendar date given in `ptstart(#)`, which is then required.
*   - `method(dr)` (default), `method(reg)`, and `method(ipw)` fit the treatment
*     adjustment models on outcome changes. Importantly, `method(reg)` and `method(dr)`
*     model untreated OUTCOME CHANGES per comparison block by default
*     (`outcomepooling(separate)`) or with shared duration-scaled slopes
*     (`outcomepooling(pooled)`), not outcome levels.

cdid_demo_init

* 3a. Doubly robust (DR) chained estimation with never-treated controls and varying base period
cdid y x_bin x_cont, ivar(id) time(period) gvar(first_treat) ///
    method(dr) controlgroup(nevertreated) baseperiod(varying) ///
    biters($CDID_DEMO_BITERS)

* Redisplay the results without refitting
cdid

* 3b. Not-yet-treated control group and universal base period
cdid y x_bin x_cont, ivar(id) time(period) gvar(first_treat) ///
    method(dr) controlgroup(notyettreated) baseperiod(universal) ///
    biters($CDID_DEMO_BITERS)

* 3c. Parallel trends over all periods from `ptstart(1)`
cdid y x_bin x_cont, ivar(id) time(period) gvar(first_treat) ///
    method(dr) controlgroup(nevertreated) ptassumption(all) ptstart(1) ///
    biters($CDID_DEMO_BITERS)

* 3d. Comparing treatment methods (`method(ipw)`, `method(reg)`) and `outcomepooling(pooled)`
if $CDID_DEMO_RUN_ADVANCED == 1 {
    cdid y x_bin x_cont, ivar(id) time(period) gvar(first_treat) ///
        method(dr) outcomepooling(pooled) biters($CDID_DEMO_BITERS)

    cdid y x_bin x_cont, ivar(id) time(period) gvar(first_treat) ///
        method(ipw) biters($CDID_DEMO_BITERS)

    cdid y x_bin x_cont, ivar(id) time(period) gvar(first_treat) ///
        method(reg) biters($CDID_DEMO_BITERS)
}


* ==============================================================================
* SECTION 4: Observation models, poolings and covariates
* ==============================================================================
* Pedagogical points:
*   - Under `selection(conditional_mtar)` with `selmethod(ipw)` (the default),
*     chained comparisons weight observed pairs by inverse pair
*     observation probabilities q_{g,s,t}(Z).
*   - With observation independent across dates conditional on all predictors,
*     `selmodel(independent_period_logit)` multiplies
*     marginal date probabilities pi_{g,s}(Z) * pi_{g,t}(Z) and MUST NOT be used
*     when observation follows rotating two-date windows or persistent dropout where
*     conditional independence between dates s and t fails.
*   - `selpooling(separate)` fits separate logits by cohort/pair (or cohort/date);
*     `within_cohort` and `across_cohorts` impose additional parameter restrictions
*     for sparse cells and do not automatically produce better estimates when sample
*     support is already adequate.
*   - `covars()` specifies outcome/treatment covariates X, while `selcovars()`
*     specifies the predictors Z of observation (the `covars()` if omitted).

cdid_demo_init

* 4a. Binary X illustration: direct pair logit vs product of period logits
* These deliberately parsimonious models omit z_sel; agreement is not guaranteed.
cdid y i.x_bin, ivar(id) time(period) gvar(first_treat) ///
    selection(conditional_mtar) selmodel(pair_logit) selpooling(separate) ///
    biters($CDID_DEMO_BITERS)

cdid y i.x_bin, ivar(id) time(period) gvar(first_treat) ///
    selection(conditional_mtar) selmodel(independent_period_logit) selpooling(separate) ///
    biters($CDID_DEMO_BITERS)

* 4b. Separate outcome covariates `covars()` and selection covariates `selcovars()`
*     with the unit table `frame(cdid_pop)` of the study population
cdid y, ivar(id) time(period) gvar(first_treat) ///
    covars(i.x_bin c.x_cont) ///
    selection(conditional_mtar) selmodel(pair_logit) selpooling(separate) ///
    selcovars(i.x_bin c.x_cont c.z_sel) ///
    frame(cdid_pop) frameivar(id) framegvar(first_treat) ///
    framecovars(x_bin x_cont) frameselcovars(x_bin x_cont z_sel) ///
    biters($CDID_DEMO_BITERS)

* 4c. Comparing more restricted selection poolings (`within_cohort` and `across_cohorts`)
if $CDID_DEMO_RUN_ADVANCED == 1 {
    cdid y i.x_bin c.x_cont, ivar(id) time(period) gvar(first_treat) ///
        selection(conditional_mtar) selmodel(pair_logit) selpooling(within_cohort) ///
        selcovars(i.x_bin c.x_cont c.z_sel) biters($CDID_DEMO_BITERS)

    cdid y i.x_bin c.x_cont, ivar(id) time(period) gvar(first_treat) ///
        selection(conditional_mtar) selmodel(pair_logit) selpooling(across_cohorts) ///
        selcovars(i.x_bin c.x_cont c.z_sel) biters($CDID_DEMO_BITERS)
}


* ==============================================================================
* SECTION 5: Pure Outcome-Change Imputation vs Augmented Correction (`selmethod`)
* ==============================================================================
* Pedagogical points:
*   - `selmethod(imputation)` performs pure outcome-change imputation over the
*     full cohort population using linear outcome-change regressions controlled by
*     `imppooling(separate|within_cohort|across_cohorts)`. Under `selmethod(imputation)`,
*     selection logit options (`selmodel`, `selpooling`, `selcovars`) are inactive
*     and listed in `e(inactive_options)`.
*   - `selmethod(dr)` (under `selection(conditional_mtar)` with `seluniverse(F)` and
*     no `selrho()`) works with `method(ipw|reg|dr)` and combines inverse
*     pair-observation probability weighting (`selmodel`, `selpooling`, `selcovars`)
*     with outcome-change imputation (`imppooling`).

cdid_demo_init

* 5a. Pure outcome-change imputation (`selmethod(imputation)`)
cdid y i.x_bin c.x_cont, ivar(id) time(period) gvar(first_treat) ///
    method(dr) selection(conditional_mtar) ///
    selmethod(imputation) imppooling(separate) ///
    biters($CDID_DEMO_BITERS)
display as text "Inactive options under selmethod(imputation): " as result "`e(inactive_options)'"

* 5b. Doubly robust observation + treatment adjustment (`selmethod(dr)` with `method(dr)`)
cdid y i.x_bin c.x_cont, ivar(id) time(period) gvar(first_treat) ///
    method(dr) selection(conditional_mtar) ///
    selmethod(dr) selmodel(pair_logit) selpooling(separate) ///
    selcovars(i.x_bin c.x_cont c.z_sel) imppooling(separate) ///
    biters($CDID_DEMO_BITERS)

if $CDID_DEMO_RUN_ADVANCED == 1 {
    cdid y i.x_bin c.x_cont, ivar(id) time(period) gvar(first_treat) ///
        method(reg) selection(conditional_mtar) ///
        selmethod(dr) selmodel(pair_logit) selpooling(separate) ///
        selcovars(i.x_bin c.x_cont c.z_sel) imppooling(separate) ///
        biters($CDID_DEMO_BITERS)
}


* ==============================================================================
* SECTION 6: Clustering (inference only) and sampling weights
* ==============================================================================
* Pedagogical points:
*   - `cluster(cluster_id)` sums the unit influence functions within clusters
*     for analytical covariance `e(V)`, multiplier bootstrap draws, and Wald tests.
*     Clustering affects INFERENCE ONLY and changes neither the GMM weighting
*     matrix nor the point estimates.
*   - When sampling weights vary over time (`w_tv`), `fixweights(first_period)` or
*     `fixweights(base_period)` sets the weight of each unit from one period.

cdid_demo_init

* 6a. Clustered inference (`cluster(cluster_id)`) with time-varying weights anchored at `first_period`
cdid y i.x_bin c.x_cont, ivar(id) time(period) gvar(first_treat) ///
    wvar(w_tv) fixweights(first_period) cluster(cluster_id) ///
    biters($CDID_DEMO_BITERS)

* 6b. Anchoring time-varying weights at `base_period`
if $CDID_DEMO_RUN_ADVANCED == 1 {
    cdid y i.x_bin c.x_cont, ivar(id) time(period) gvar(first_treat) ///
        wvar(w_tv) fixweights(base_period) cluster(cluster_id) ///
        biters($CDID_DEMO_BITERS)
}


* ==============================================================================
* SECTION 7: Aggregation (`estat`), pointwise intervals and simultaneous bands
* ==============================================================================
* Pedagogical points:
*   - `estat simple`, `estat group`, `estat dynamic`, and `estat calendar` aggregate
*     the stored group-time estimates and influence functions without refitting
*     any model and without using the data in memory.
*   - By default (no `bstrap()` or `cband()`), `estat` uses the inference settings
*     of the estimation (`bstrap`, `cband`, `biters`, `level`, `cluster`).
*   - You can override `cband(0)` for pointwise intervals or `cband(1)` for
*     simultaneous confidence bands, and use dynamic window selectors
*     `mine(#)`, `maxe(#)`, `balancee(#)`, and `narm`.
*   - Each `estat` call replaces `e()` with the aggregation; another `estat`
*     can follow directly, because the group-time estimates are kept with it.
*     `saving()` and `cdid_load` also restore the group-time results.

cdid_demo_init

* Estimation to aggregate
cdid y i.x_bin c.x_cont, ivar(id) time(period) gvar(first_treat) ///
    cluster(cluster_id) biters($CDID_DEMO_BITERS)

* 7a. The four `estat` aggregations (with the inference settings of the estimation)
estat simple
estat group
estat calendar
estat dynamic

* 7b. Dynamic event-study selectors (`mine`, `maxe`, `balancee`, `narm`)
estat dynamic, mine(-2) maxe(2) narm
estat dynamic, balancee(1) narm

* 7c. Comparing simultaneous confidence bands (`cband(1)`) vs pointwise intervals (`cband(0)`)
estat dynamic, cband(1)
estat dynamic, cband(0)


* ==============================================================================
* SECTION 8: Pretrend tests: the Wald test and `cdid_pretest`
* ==============================================================================
* Pedagogical points:
*   - `cdid` reports a joint pretrend Wald test (`e(wald_statistic)`,
*     `e(wald_df)`, `e(wald_p)`, `e(wald_status)`) on the pretreatment cells
*     other than reference cells.
*   - `cdid_pretest` is a SEPARATE conditional pretrend Cramer-von Mises (CvM)
*     test over the covariate values. Its default is `method(ipw)` (whereas
*     `cdid` uses `method(dr)`); it returns its results in `r()` and leaves the
*     current `e()` results unchanged.

cdid_demo_init

* 8a. The pretrend Wald test stored in `e()`
cdid y i.x_bin c.x_cont, ivar(id) time(period) gvar(first_treat) ///
    method(dr) biters($CDID_DEMO_BITERS)
display as text "Wald test status: " as result "`e(wald_status)'" ///
    as text "  chi2(" as result e(wald_df) as text ") = " as result %9.4f e(wald_statistic) ///
    as text "  p = " as result %6.4f e(wald_p)

* 8b. Conditional pretrend CvM test (`cdid_pretest`)
*     The default treatment adjustment is `ipw`; `e()` from `cdid` is unchanged.
cdid_pretest y i.x_bin c.x_cont, ivar(id) time(period) gvar(first_treat) ///
    biters($CDID_DEMO_BITERS)
return list

* 8c. Conditional pretrend test under `selection(conditional_mtar)`
cdid_pretest y i.x_bin c.x_cont, ivar(id) time(period) gvar(first_treat) ///
    method(dr) selection(conditional_mtar) selmodel(pair_logit) selpooling(separate) ///
    selcovars(i.x_bin c.x_cont c.z_sel) biters($CDID_DEMO_BITERS)


* ==============================================================================
* SECTION 9: Diagnostics, graphs and datasets (`cdid_diagnostics`, `cdid_plot`, `cdid_export`)
* ==============================================================================
* Pedagogical points:
*   - `cdid_diagnostics [, detail]` summarizes the study population, the cells,
*     the model and the inference from the stored results, without using the
*     data in memory.
*   - `cdid_plot` graphs the group-time estimates or the `estat` aggregation;
*     after `estat`, `cells` graphs the group-time estimates.
*   - `cdid_export using path, type(cells|aggregate|units|influence|summary)`
*     writes a Stata dataset. Open it in a separate frame to inspect it.
*   - Quantities not stored with the results are reported as not retained. After
*     an ordinary-mode aggregation, the pointwise intervals of the group-time cells
*     can be missing; the reported intervals are always exported.

cdid_demo_init

cdid y i.x_bin c.x_cont, ivar(id) time(period) gvar(first_treat) ///
    selection(conditional_mtar) selmodel(pair_logit) selpooling(separate) ///
    biters($CDID_DEMO_BITERS)

* 9a. Diagnostics
cdid_diagnostics
cdid_diagnostics, detail

* 9b. Export cell and summary tables to temporary files and inspect them in frames
* cdid_export accepts temporary file names as they are; Stata erases the files
* when the do-file ends. Files are kept on disk only in 9c and Section 10.
tempfile demo_cells_dta demo_summary_dta
cdid_export using "`demo_cells_dta'", type(cells)
capture frame drop demo_cells_tbl
frame create demo_cells_tbl
frame demo_cells_tbl: use "`demo_cells_dta'"
frame demo_cells_tbl: list in 1/10, abbrev(16)

cdid_export using "`demo_summary_dta'", type(summary)
capture frame drop demo_summary_tbl
frame create demo_summary_tbl
frame demo_summary_tbl: use "`demo_summary_dta'"
frame demo_summary_tbl: list, abbrev(20)

* 9c. Graphs and datasets kept on disk (requires CDID_DEMO_OUTDIR)
if `"$CDID_DEMO_OUTDIR"' != "" {
    local repopt = cond($CDID_DEMO_REPLACE == 1, "replace", "")
    cdid_plot, title("Group-Time ATT Estimates") ///
        saving("$CDID_DEMO_OUTDIR/cdid_group_time.gph") `repopt'
    estat dynamic
    cdid_plot, title("Dynamic Event-Study ATT") ///
        saving("$CDID_DEMO_OUTDIR/cdid_dynamic.gph") `repopt'
    cdid_export using "$CDID_DEMO_OUTDIR/cdid_dynamic.dta", type(aggregate) `repopt'
}


* ==============================================================================
* SECTION 10: Saving and loading results (`saving()`, `cdid_load`, `cdid_pretest_load`)
* ==============================================================================
* Pedagogical points:
*   - `cdid ..., saving(path)`, `estat ..., saving(path)` and
*     `cdid_pretest ..., saving(path)` write the complete results to a file.
*     `saving()` never overwrites an existing file.
*   - `cdid_load using path [, posting(matrix|state) workspace(#)]` and
*     `cdid_pretest_load using path [, store(name) posting(matrix|state) workspace(#)]`
*     restore the saved results in a new session or when an unrelated dataset
*     is in memory, without using the data, refitting, or drawing random numbers.
*   - `cdid_load` does not set `e(sample)`, because the loaded results do not
*     refer to the data in memory. As with `estimates use`, `e(cmdline)` is the
*     command line of the saved results.
*   - Without CDID_DEMO_OUTDIR, the results are saved to temporary files.

cdid_demo_init

if `"$CDID_DEMO_OUTDIR"' != "" {
    local cells_file "$CDID_DEMO_OUTDIR/demo_cells.cdidstate"
    local dyn_file   "$CDID_DEMO_OUTDIR/demo_dynamic.cdidstate"
    local pt_file    "$CDID_DEMO_OUTDIR/demo_pretest.cdidpt"
}
else {
    tempfile cells_file dyn_file pt_file
}

* 10a. Save the group-time results, the event study, and the pretrend test
cdid y i.x_bin c.x_cont, ivar(id) time(period) gvar(first_treat) ///
    cluster(cluster_id) biters($CDID_DEMO_BITERS) saving("`cells_file'")

estat dynamic, saving("`dyn_file'")

cdid_pretest y i.x_bin c.x_cont, ivar(id) time(period) gvar(first_treat) ///
    biters($CDID_DEMO_BITERS) saving("`pt_file'")

* 10b. Replace the data with a small unrelated dataset and load the results
preserve
clear
set obs 5
generate byte unrelated_x = _n

* Load the group-time results and use `estat` and `cdid_diagnostics`
cdid_load using "`cells_file'"
count if e(sample)
assert r(N) == 0
display as text "e(sample_scope): " as result "`e(sample_scope)'"
display as text "e(cmdline): " as result `"`e(cmdline)'"'
cdid_diagnostics
estat group

* Load the event study
cdid_load using "`dyn_file'"

* Load with `posting(state)` (complete results, without e(b) and e(V))
cdid_load using "`cells_file'", posting(state)
display as text "Coefficients posted with posting(state): " as result e(N_posted)

* Load the pretrend test results (e() is unchanged)
cdid_pretest_load using "`pt_file'"
return list
restore


* ==============================================================================
* SECTION 11: Common errors (insufficient data and incomplete specifications)
* ==============================================================================
* Pedagogical points:
*   - `cdid` stops with an error for invalid specifications or unsupported designs
*     and leaves `e()`, `r()`, the data, frames and the random-number state unchanged.
*   - Each example is run with `capture noisily`, and `_rc` is checked, so that
*     the do-file continues.

cdid_demo_init

* 11a. `ptassumption(all)` without `ptstart(#)` (rc = 459)
capture noisily cdid y x_bin, ivar(id) time(period) gvar(first_treat) ptassumption(all)
assert _rc == 459

* 11b. `selmethod(dr)` with `selection(none)` (rc = 459)
capture noisily cdid y x_bin, ivar(id) time(period) gvar(first_treat) ///
    selection(none) selmethod(dr)
assert _rc == 459

* 11c. Insufficient support: restricting to a single calendar period leaves no (s, t) pairs
capture noisily cdid y x_bin if period == 1, ivar(id) time(period) gvar(first_treat)
assert _rc != 0

* 11d. Wrong file type: a file saved by `cdid` given to `cdid_pretest_load` (rc = 498)
tempfile tmp_cell_state
cdid y x_bin, ivar(id) time(period) gvar(first_treat) noinffunc saving("`tmp_cell_state'")
capture noisily cdid_pretest_load using "`tmp_cell_state'"
assert _rc == 498

display as text _n "=== Hands-on cdid guide completed successfully ==="
