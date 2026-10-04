*! duvm_estat 1.1.0  2026-09-26  Abdelkrim Araar
*! estat after duvm: diagnostics, elasticities, quality, engel
program define duvm_estat, rclass
    version 14.2
    if "`e(cmd)'" != "duvm" error 301
    gettoken sub 0 : 0, parse(" ,")
    local sub = lower("`sub'")
    if inlist("`sub'", "diag", "diagnostics", "diagnostic") {
        _duvm_estat_diag `0'
    }
    else if inlist("`sub'", "elast", "elasticities", "elasticity") {
        _duvm_estat_elast `0'
    }
    else if inlist("`sub'", "quality", "qual") {
        _duvm_estat_quality `0'
    }
    else if "`sub'" == "engel" {
        _duvm_estat_engel `0'
    }
    else {
        di as err "estat `sub' not allowed after duvm; use estat diagnostics, estat elasticities, estat quality or estat engel"
        exit 198
    }
    return add
end

* ---------------------------------------------------------------------------
program define _duvm_estat_diag, rclass
    syntax [, DEC(integer 3)]
    local M = e(M)
    local goods `e(goods)'
    tempname T S Sf ome n1 n0 b1 el zeta B Bs w rep crep cpair
    matrix `S' = e(S)
    matrix `Sf' = e(Sf)
    matrix `ome' = e(omega)
    matrix `n1' = e(n1)
    matrix `n0' = e(n0)
    matrix `b1' = e(b1)
    matrix `el' = e(elast_exp)
    matrix `zeta' = e(zeta)
    matrix `B' = e(B)
    matrix `Bs' = e(B_sym)
    matrix `w' = e(shares_mean)
    matrix `rep' = e(N_report)
    matrix `crep' = e(N_clust_report)
    matrix `cpair' = e(N_clust_pair)
    local C = e(N_clust)
    local N = e(N)

    di as txt _n "Diagnostics for the unit-value model" _col(49) "Number of obs" _col(67) "= " as res %10.0fc `N'
    di as txt _col(49) "Number of clusters" _col(67) "= " as res %10.0fc `C'

    * ---- table 0: how the non-buyers are coded in the data ----
    * a buyer has a positive budget share; its unit value is the only one the
    * unit-value equation should see (nonbuyers(drop), the default)
    local nwarn 0
    local mode "`e(nonbuyers)'"
    if "`mode'" == "" local mode "asis"
    tempvar wt0 es0
    local wexp = trim(subinstr(`"`e(wexp)'"', "=", "", 1))
    if "`wexp'" == "" qui gen double `wt0' = 1
    else              qui gen double `wt0' = `wexp'
    qui gen byte `es0' = e(sample)
    tempname T0
    matrix `T0' = J(`M', 7, .)
    forvalues j = 1/`M' {
        local g : word `j' of `goods'
        tempvar sv`j' uv`j'
        _duvm_uv `g', touse(`es0') wt(`wt0') cluster(`e(clustvar)') mode(`mode') share(`sv`j'') uv(`uv`j'')
        matrix `T0'[`j', 1] = r(n_buy)
        matrix `T0'[`j', 2] = r(n_buy) / `N' * 100
        matrix `T0'[`j', 3] = r(n_wmiss)
        matrix `T0'[`j', 4] = r(n_nbuv)
        matrix `T0'[`j', 5] = r(n_nbzero)
        matrix `T0'[`j', 6] = r(n_buynouv)
        matrix `T0'[`j', 7] = r(c_uvnobuy)
        if r(n_wmiss) > 0 {
            local ++nwarn
            local warn`nwarn' = "`g': " + string(r(n_wmiss), "%12.0fc") + " budget shares are missing, read as 0 (non-buyers); check that a missing share means no purchase, not a missing record"
        }
        if r(n_nbuv) > 0 {
            local ++nwarn
            local nz = cond(r(n_nbzero) > 0, " (" + string(r(n_nbzero), "%12.0fc") + " coded 0)", "")
            if "`mode'" == "drop" local warn`nwarn' = "`g': " + string(r(n_nbuv), "%12.0fc") + " non-buyers have a unit value in the data`nz': imputed or zero values, ignored by nonbuyers(drop)"
            else if "`mode'" == "asis" local warn`nwarn' = "`g': " + string(r(n_nbuv), "%12.0fc") + " non-buyers have a unit value`nz', used as it is (nonbuyers(asis)); imputed values bias the quality elasticity toward zero"
            else local warn`nwarn' = "`g': " + string(r(n_nbuv), "%12.0fc") + " non-buyers have a unit value in the data`nz'; nonbuyers(average) replaces it by the mean of the buyers of the cluster"
        }
        if r(c_uvnobuy) > 0 {
            local ++nwarn
            local warn`nwarn' = "`g': " + string(r(c_uvnobuy), "%12.0fc") + " clusters have a unit value but no buyer: prices imputed from outside the cluster" + cond("`mode'" == "asis", ", used as prices by the second stage", ", ignored")
        }
    }
    matrix rownames `T0' = `goods'
    matrix colnames `T0' = "Buyers" "Buy_pct" "Share_miss" "NonbuyUV" "of_which_0" "BuyNoUV" "Cl_UVnobuy"
    di _n as txt "Table D0: Buyers (positive share) and the coding of the non-buyers; non-buyers treated by nonbuyers(" as res "`mode'" as txt ")"
    matlist `T0', border(rows) format(%10.0fc) twidth(9) left(2)
    di as txt "  Share_miss: budget shares coded . (read as 0); NonbuyUV: non-buyers with a unit value in the data;"
    di as txt "  BuyNoUV: buyers without a unit value; Cl_UVnobuy: clusters with a unit value but no buyer"

    * ---- table 1: the data behind each good ----
    matrix `T' = J(`M', 7, .)
    forvalues j = 1/`M' {
        local g : word `j' of `goods'
        matrix `T'[`j', 1] = `w'[1, `j'] * 100
        matrix `T'[`j', 2] = `rep'[1, `j']
        matrix `T'[`j', 3] = `rep'[1, `j'] / `N' * 100
        matrix `T'[`j', 4] = `crep'[1, `j']
        matrix `T'[`j', 5] = `n1'[1, `j']
        matrix `T'[`j', 6] = `n0'[1, `j']
        matrix `T'[`j', 7] = `cpair'[1, `j']
        if `rep'[1, `j'] / `N' < 0.25 {
            local ++nwarn
            local warn`nwarn' = "`g': only " + string(`rep'[1, `j'] / `N' * 100, "%4.1f") + "% of households report a unit value; its price signal rests on few clusters"
        }
        if `n1'[1, `j'] < 2 {
            local ++nwarn
            local warn`nwarn' = "`g': harmonic mean cluster size of reporters below 2; the measurement-error correction is large and imprecise"
        }
    }
    matrix rownames `T' = `goods'
    matrix colnames `T' = "Share_pct" "Reporters" "Rep_pct" "Clusters" "n_plus_harm" "n_harm" "Pairs_min"
    di _n as txt "Table D1: Households whose unit value enters the model, clusters, and the harmonic cluster sizes of (5.55)"
    matlist `T', border(rows) format(%10.2f) twidth(9) left(2)

    * ---- table 2: the second stage ----
    matrix `T' = J(`M', 6, .)
    forvalues j = 1/`M' {
        local g : word `j' of `goods'
        local sd = sqrt(`S'[`j', `j'])
        local corr = `ome'[1, `j'] / `n1'[1, `j']
        matrix `T'[`j', 1] = `sd'
        matrix `T'[`j', 2] = `corr' / `S'[`j', `j'] * 100
        matrix `T'[`j', 3] = `Sf'[`j', `j']
        matrix `T'[`j', 4] = `b1'[1, `j']
        matrix `T'[`j', 5] = `el'[1, `j']
        matrix `T'[`j', 6] = `zeta'[1, `j'] * `w'[1, `j']
        if `Sf'[`j', `j'] <= 0 {
            local ++nwarn
            local warn`nwarn' = "`g': the corrected between-cluster variance of the unit value is not positive; the price variation is swamped by measurement error"
        }
        else if `corr' / `S'[`j', `j'] > 0.5 {
            local ++nwarn
            local warn`nwarn' = "`g': the measurement-error correction removes " + string(`corr' / `S'[`j', `j'] * 100, "%4.0f") + "% of the between-cluster variance of the unit value"
        }
        if `b1'[1, `j'] < 0 {
            local ++nwarn
            local warn`nwarn' = "`g': negative quality elasticity (" + string(`b1'[1, `j'], "%6.4f") + "); the quality correction (5.92) then raises the price elasticities"
        }
        if abs(`el'[1, `j']) < 0.1 {
            local ++nwarn
            local warn`nwarn' = "`g': expenditure elasticity near zero (" + string(`el'[1, `j'], "%6.3f") + "); zeta = b1/(wbar e) is unstable"
        }
    }
    matrix rownames `T' = `goods'
    matrix colnames `T' = "SD_uv" "Corr_pct" "Sf_jj" "b1" "Exp_elast" "b1_over_e"
    di _n as txt "Table D2: Between-cluster SD of the purged log unit value, the share of it removed by the"
    di as txt "          measurement-error correction, the corrected variance, and the quality parameters"
    matlist `T', border(rows) format(%10.`dec'f) twidth(9) left(2)

    * ---- table 3: the selection correction (option selection) ----
    if "`e(selection)'" != "" {
        tempname SD
        matrix `SD' = e(sel_diag)
        local hasse 0
        capture confirm matrix e(se_sel_theta)
        if !_rc local hasse 1
        di _n as txt "Table D3: Selection of the buyers, the probit of purchase and the Mills ratio lambda"
        di as txt "{hline 11}{c TT}{hline 70}"
        di as txt _col(12) "{c |}" _col(16) "Buy_pct" _col(25) "Pseudo_R2" _col(36) "Perfect" _col(48) "VIF_b1" ///
            _col(57) "Excl" _col(64) "theta" _col(77) "z"
        di as txt "{hline 11}{c +}{hline 70}"
        forvalues j = 1/`M' {
            local g : word `j' of `goods'
            if missing(`SD'[`j', 1]) {
                di as txt %10s abbrev("`g'", 10) _col(12) "{c |}" _col(16) "not corrected"
                continue
            }
            local nex : word count `e(sel_z_`g')'
            local th = el(e(sel_theta), 1, `j')
            local zs "."
            if `hasse' local zs = string(`th' / el(e(se_sel_theta), 1, `j'), "%6.2f")
            di as txt %10s abbrev("`g'", 10) _col(12) "{c |}" as res _col(14) %8.1f `SD'[`j', 2] _col(25) %8.3f `SD'[`j', 3] ///
                _col(34) %8.0fc `SD'[`j', 4] _col(46) %8.1f `SD'[`j', 5] _col(55) %5.0f `nex' _col(61) %9.4f `th' _col(72) %7s "`zs'"
            if `SD'[`j', 4] > 0 {
                local ++nwarn
                local warn`nwarn' = "`g': " + string(`SD'[`j', 4], "%12.0fc") + " households are predicted with probability 0 or 1 by the selection probit (separation); the coefficients of the separating variables drift, the Mills ratio and theta do not"
            }
            if `SD'[`j', 5] > 10 {
                local ++nwarn
                local why = cond(`nex' == 0, "a variable of the probit only, in selvars(), could separate them", ///
                    "the probit-only variables do not separate them")
                local warn`nwarn' = "`g': within clusters, lambda is almost collinear with ln x (VIF of the quality elasticity " + string(`SD'[`j', 5], "%9.1f") + "): the correction multiplies its std. err. by about " + string(sqrt(`SD'[`j', 5]), "%5.1f") + " and it rests on the curvature of the probit, where the linearized std. errors understate the uncertainty; leave `g' uncorrected with selgoods(), or `why'; at least use vce(bootstrap)"
            }
            if `SD'[`j', 2] > 97 {
                local ++nwarn
                local warn`nwarn' = "`g': " + string(`SD'[`j', 2], "%4.1f") + "% of households buy; lambda is small and theta poorly identified; selgoods() can leave this good uncorrected"
            }
        }
        di as txt "{hline 11}{c BT}{hline 70}"
        di as txt "  Pseudo_R2: McFadden, of the probit of purchase; Perfect: households predicted with probability 0 or 1;"
        di as txt "  VIF_b1: variance inflation of the quality elasticity due to lambda, 1/(1-rho^2), rho the within-cluster"
        di as txt "  correlation of lambda and ln x given the other regressors, among the reporters (above 10: collinear);"
        di as txt "  Excl: variables of the probit only (selvars()); theta: coefficient of lambda in the unit-value equation" ///
            cond(`hasse', ", z its ratio to the std. err.", "")
        return matrix sel_diag = `SD', copy
    }

    * ---- the moment matrix and the symmetry restriction ----
    mata: st_numscalar("r(cond_Sf)", cond(st_matrix("e(Sf)")))
    mata: st_numscalar("r(mineig_Sf)", min(symeigenvalues(st_matrix("e(Sf)"))))
    mata: st_numscalar("r(sym_dist)", norm(st_matrix("e(B_sym)") - st_matrix("e(B)")) / norm(st_matrix("e(B)")))
    di _n as txt "Corrected moment matrix Sf: condition number = " as res %9.1f r(cond_Sf) as txt ", smallest eigenvalue = " as res %9.5f r(mineig_Sf)
    if "`e(symmetry)'" == "approx" {
        di as txt "Symmetry restriction: relative change of B, ||B_sym - B|| / ||B|| = " as res %6.3f r(sym_dist)
        if r(sym_dist) > 0.5 {
            local ++nwarn
            local warn`nwarn' = "the symmetry restriction moves B by more than 50%; the unrestricted and restricted elasticities tell different stories"
        }
    }
    if r(mineig_Sf) <= 0 {
        local ++nwarn
        local warn`nwarn' = "Sf is not positive definite; the corrected second stage is not a valid regression"
    }
    if r(cond_Sf) > 1e4 {
        local ++nwarn
        local warn`nwarn' = "Sf is ill-conditioned (condition number above 1e4); the price elasticities are fragile"
    }

    di _n as txt "Warnings: " as res `nwarn'
    forvalues i = 1/`nwarn' {
        di as txt "  " as res `i' as txt ". `warn`i''"
    }
    if `nwarn' == 0 di as txt "  none: every good has a usable price signal and a well-behaved correction"
    return scalar N_warn = `nwarn'
    return scalar cond_Sf = r(cond_Sf)
    return scalar mineig_Sf = r(mineig_Sf)
    if "`e(symmetry)'" == "approx" return scalar sym_dist = r(sym_dist)
end

* ---------------------------------------------------------------------------
program define _duvm_estat_elast, rclass
    syntax [, UNRestricted NOQuality UNCompleted DEC(integer 3)]
    local fmt "%`=`dec'+5'.`dec'f"
    if "`noquality'" != "" {
        di as txt _n "Price elasticities of quantity, no quality correction, unrestricted B (M x M)"
        matlist e(elast_price_noqual), border(rows) format(`fmt') twidth(10) left(2)
        if "`e(vce)'" != "none" {
            di as txt _n "Standard errors (`e(vcetype)')"
            matlist e(se_elast_price_noqual), border(rows) format(`fmt') twidth(10) left(2)
            tempname _r_se
            matrix `_r_se' = e(se_elast_price_noqual)
            return matrix se = `_r_se'
        }
        tempname _r_elast
        matrix `_r_elast' = e(elast_price_noqual)
        return matrix elast = `_r_elast'
        exit
    }
    if "`unrestricted'" != "" & "`uncompleted'" != "" {
        di as txt _n "Price elasticities of quantity, quality corrected, unrestricted B (M x M)"
        matlist e(elast_price_M_ns), border(rows) format(`fmt') twidth(10) left(2)
        if "`e(vce)'" != "none" {
            di as txt _n "Standard errors (`e(vcetype)')"
            matlist e(se_elast_price_M_ns), border(rows) format(`fmt') twidth(10) left(2)
            tempname _r_se
            matrix `_r_se' = e(se_elast_price_M_ns)
            return matrix se = `_r_se'
        }
        tempname _r_elast
        matrix `_r_elast' = e(elast_price_M_ns)
        return matrix elast = `_r_elast'
        exit
    }
    if "`unrestricted'" != "" {
        di as txt _n "Price elasticities of quantity, quality corrected, unrestricted B, completed system"
        matlist e(elast_price_ns), border(rows) format(`fmt') twidth(10) left(2)
        if "`e(vce)'" != "none" {
            di as txt _n "Standard errors (`e(vcetype)')"
            matlist e(se_elast_price_ns), border(rows) format(`fmt') twidth(10) left(2)
            tempname _r_se
            matrix `_r_se' = e(se_elast_price_ns)
            return matrix se = `_r_se'
        }
        tempname _r_elast
        matrix `_r_elast' = e(elast_price_ns)
        return matrix elast = `_r_elast'
        exit
    }
    if "`uncompleted'" != "" {
        di as txt _n "Price elasticities of quantity, quality corrected, symmetry restricted (M x M)"
        matlist e(elast_price_M), border(rows) format(`fmt') twidth(10) left(2)
        if "`e(vce)'" != "none" {
            di as txt _n "Standard errors (`e(vcetype)')"
            matlist e(se_elast_price_M), border(rows) format(`fmt') twidth(10) left(2)
            tempname _r_se
            matrix `_r_se' = e(se_elast_price_M)
            return matrix se = `_r_se'
        }
        tempname _r_elast
        matrix `_r_elast' = e(elast_price_M)
        return matrix elast = `_r_elast'
        exit
    }
    di as txt _n "Price elasticities of quantity, quality corrected, symmetry restricted, completed system"
    matlist e(elast_price), border(rows) format(`fmt') twidth(10) left(2)
    if "`e(vce)'" != "none" {
        di as txt _n "Standard errors (`e(vcetype)')"
        matlist e(se_elast_price), border(rows) format(`fmt') twidth(10) left(2)
        tempname _r_se
        matrix `_r_se' = e(se_elast_price)
        return matrix se = `_r_se'
    }
    tempname _r_elast
        matrix `_r_elast' = e(elast_price)
        return matrix elast = `_r_elast'
end

* ---------------------------------------------------------------------------
program define _duvm_estat_quality, rclass
    syntax [, DEC(integer 3)]
    local fmt "%`=`dec'+5'.`dec'f"
    local goods `e(goods)'
    tempname T
    matrix `T' = e(b1) \ e(zeta) \ hadamard(e(zeta), e(shares_mean)) \ e(elast_exp)
    if "`e(vce)'" != "none" {
        matrix `T' = e(b1) \ e(se_elast_qual) \ e(zeta) \ e(se_zeta) \ hadamard(e(zeta), e(shares_mean)) \ e(elast_exp) \ e(se_elast_exp)
        matrix rownames `T' = "b1_quality" "  std_err" "zeta" "  std_err" "zeta_x_wbar" "e_expenditure" "  std_err"
    }
    else matrix rownames `T' = "b1_quality" "zeta" "zeta_x_wbar" "e_expenditure"
    matrix colnames `T' = `goods'
    di as txt _n "Quality: the expenditure elasticity of the unit value (b1), the quality parameter zeta of (5.92),"
    di as txt "and zeta x wbar = b1 / e, the share of a price change absorbed by quality shading"
    matlist `T', border(rows) format(`fmt') twidth(22) left(2)
    di as txt _n "Unit-value response to own price (diagonal of Psi):"
    tempname P
    matrix `P' = vecdiag(e(Psi))
    matrix rownames `P' = "psi_GG"
    matrix colnames `P' = `goods'
    matlist `P', border(rows) format(`fmt') twidth(22) left(2)
    return matrix quality = `T'
end

* ---------------------------------------------------------------------------
* estat engel: the Engel curves of every good, one panel per good, against the
* percentiles of total expenditure (the layout of easi's estat engel)
program define _duvm_estat_engel, rclass
    syntax [if] [in] [, SHare QUality QUAntity ATMeans ASObserved N(integer 100) ///
        TRIM(real 1) Level(cilevel) NOCI DATA(string) SAVing(string asis) NODRAW ///
        BWidth(real 0) LNX NORMalize *]
    local nc : word count `share' `quality' `quantity'
    if `nc' > 1 {
        di as err "specify only one of share, quality and quantity"
        exit 198
    }
    if `nc' == 0 local share share
    local curve `share'`quality'`quantity'
    if "`atmeans'" != "" & "`asobserved'" != "" {
        di as err "specify atmeans or asobserved, not both"
        exit 198
    }
    local asobs = ("`asobserved'" != "")
    if "`normalize'" != "" & ("`curve'" != "quantity" | `asobs') {
        di as err "normalize goes with quantity at the means: it sets the log quantity to 0 at the mean of ln x"
        exit 198
    }
    if `bwidth' != 0 & !`asobs' {
        di as err "bwidth() goes with asobserved: the Engel curve at the means is exact, there is nothing to smooth"
        exit 198
    }
    if `n' < 2 {
        di as err "n() must be at least 2"
        exit 198
    }
    if `trim' < 0 | `trim' >= 50 {
        di as err "trim() must be in [0, 50)"
        exit 198
    }
    if "`e(expend)'" == "" {
        di as err "these duvm results predate the Engel curves; estimate the model again"
        exit 301
    }
    local goods `e(goods)'
    local M : word count `goods'
    marksample touse, novarlist
    qui replace `touse' = 0 if !e(sample)
    tempvar wt lnxv
    local wexp = trim(subinstr(`"`e(wexp)'"', "=", "", 1))
    if "`wexp'" == "" qui gen double `wt' = 1
    else              qui gen double `wt' = `wexp'
    qui gen double `lnxv' = ln(`e(expend)')
    local zc = invnormal((100 + `level') / 200)
    local ci = ("`noci'" == "" & !`asobs' & "`e(vce)'" != "none")

    * ---- the curves: parameters at the means, or fitted values as observed ----
    if !`asobs' {
        forvalues j = 1/`M' {
            tempname th`j' V`j'
            if `ci' _duvm_engel, good(`j')
            else    _duvm_engel, good(`j') novar
            matrix `th`j'' = r(theta)
            local L0_`j' = r(L0)
            local wb_`j' = r(wbar)
            if `ci' {
                matrix `V`j'' = r(V)
            }
        }
    }
    else {
        forvalues j = 1/`M' {
            tempvar raw`j'
            qui predict double `raw`j'' if `touse', `curve' good(`: word `j' of `goods'') asobserved
        }
    }

    preserve
    qui keep if `touse'
    local nobs = _N
    if `n' > `nobs' local n = `nobs'
    tempvar gx gp
    qui gen double `gx' = .
    qui gen double `gp' = .
    forvalues i = 1/`n' {
        local q = `trim' + (100 - 2 * `trim') * (`i' - 0.5) / `n'
        qui _pctile `lnxv' [aw=`wt'], percentiles(`q')
        qui replace `gx' = r(r1) in `i'
        qui replace `gp' = `q' in `i'
    }
    if `asobs' {
        if `bwidth' == 0 {
            qui lpoly `raw1' `lnxv' [aw=`wt'], degree(1) nograph
            local bwidth = r(bwidth)
        }
        forvalues j = 1/`M' {
            qui lpoly `raw`j'' `lnxv' [aw=`wt'], degree(1) bwidth(`bwidth') at(`gx') nograph generate(_w`j')
        }
        local bws = string(`bwidth', "%6.4f")
        local what "as observed, local linear, bandwidth `bws'"
    }
    qui keep in 1/`n'
    qui gen double pctile = `gp'
    qui gen double lnexp = `gx'
    if !`asobs' {
        local what "at the means of the other regressors"
        forvalues j = 1/`M' {
            local a0 = el(`th`j'', 1, 1)
            local b0 = el(`th`j'', 1, 2)
            local a1 = el(`th`j'', 1, 3)
            local b1 = el(`th`j'', 1, 4)
            if "`curve'" == "share" {
                qui gen double _w`j' = `a0' + `b0' * lnexp
                if `ci' qui gen double _se`j' = sqrt(el(`V`j'',1,1) + 2*lnexp*el(`V`j'',1,2) + lnexp^2*el(`V`j'',2,2))
            }
            else if "`curve'" == "quality" {
                qui gen double _w`j' = `a1' + `b1' * lnexp
                if `ci' qui gen double _se`j' = sqrt(el(`V`j'',3,3) + 2*lnexp*el(`V`j'',3,4) + lnexp^2*el(`V`j'',4,4))
            }
            else {
                tempvar sh one
                qui gen double `sh' = `a0' + `b0' * lnexp
                if "`normalize'" == "" qui gen double _w`j' = ln(`sh') + lnexp - (`a1' + `b1' * lnexp) if `sh' > 0
                else qui gen double _w`j' = ln(`sh') - ln(`wb_`j'') + (1 - `b1') * (lnexp - `L0_`j'') if `sh' > 0
                qui count if !(`sh' > 0)
                if r(N) {
                    di as txt "(`: word `j' of `goods'': the predicted share is not positive on `r(N)' of the `n' points; the log quantity stops there)"
                }
                if `ci' {
                    qui gen byte `one' = 1
                    qui gen double _se`j' = .
                    if "`normalize'" == "" _duvm_engel, qse(_se`j' `sh' lnexp `one') vmat(`V`j'')
                    else _duvm_engel, qse(_se`j' `sh' lnexp `one') vmat(`V`j'') ref(`L0_`j'') sh0(`wb_`j'')
                    drop `one'
                }
                drop `sh'
            }
        }
    }
    forvalues j = 1/`M' {
        if `ci' {
            qui gen double _lo`j' = _w`j' - `zc' * _se`j'
            qui gen double _hi`j' = _w`j' + `zc' * _se`j'
        }
        label variable _w`j' "`: word `j' of `goods''"
    }
    label variable pctile "Percentiles of total expenditure"
    label variable lnexp "Log of total expenditure"
    if `ci' keep pctile lnexp _w* _se* _lo* _hi*
    else    keep pctile lnexp _w*
    order pctile lnexp

    if `"`data'"' != "" {
        qui save `data', replace
        di as txt `"curve data saved to {bf:`data'}"'
    }

    if "`nodraw'" == "" {
        if "`curve'" == "share"        local yt "Budget share"
        else if "`curve'" == "quality" local yt "Log unit value"
        else if "`normalize'" != ""    local yt "Log quantity, 0 at mean ln x"
        else                           local yt "Log quantity"
        * the x axis: percentiles of total expenditure (as easi), or its log
        if "`lnx'" != "" {
            local xv lnexp
            local xl "xlabel(, labsize(vsmall))"
            local xt "Log of total expenditure"
        }
        else {
            local xv pctile
            local xl "xlabel(0(20)100, labsize(vsmall))"
            local xt "Percentiles of total expenditure"
        }
        local plots
        forvalues j = 1/`M' {
            local band
            if `ci' local band (rarea _lo`j' _hi`j' `xv', color(navy%25) lwidth(none))
            tempname g`j'
            twoway `band' (line _w`j' `xv', lcolor(navy) lpattern(solid) lwidth(medthick)), ///
                title("`: word `j' of `goods''", size(medsmall)) ///
                ytitle("`yt'", size(vsmall)) xtitle("") ylabel(, labsize(vsmall) angle(0)) ///
                `xl' legend(off) graphregion(color(white)) ///
                name(`g`j'', replace) nodraw
            local plots `plots' `g`j''
        }
        local nt `""`yt', `what'""'
        local nt2
        if !`asobs' & "`curve'" != "quantity" local nt2 "straight lines in ln x (the first stage of duvm)"
        if !`asobs' & "`curve'" == "quantity" local nt2 "ln w + ln x - ln v; falls where the share nears 0"
        if `trim' > 0 {
            if "`nt2'" != "" local nt2 "`nt2'; "
            local nt2 "`nt2'tails trimmed at `trim'%"
        }
        if `ci' local nt2 "`nt2'; `level'% confidence band (linearized)"
        if "`nt2'" != "" local nt `"`nt' "`nt2'""'
        local ncol = ceil(sqrt(`M'))
        local nrow = ceil(`M' / `ncol')
        local grid
        if !strpos(`"`options'"', "cols(") & !strpos(`"`options'"', "rows(") local grid cols(`ncol')
        local gsize
        if !strpos(`"`options'"', "xsize(") & !strpos(`"`options'"', "ysize(") {
            local gsize xsize(`=min(2.3 * `ncol', 12)') ysize(`=min(1.9 * `nrow' + 1, 12)')
        }
        graph combine `plots', `grid' `gsize' ///
            title("Engel curves, unit-value model (duvm)") ///
            b1title("`xt'", size(small)) ///
            note(`nt', size(vsmall)) graphregion(color(white)) `options'
        if `"`saving'"' != "" graph save `saving'
        graph drop `plots'
    }
    restore
    return scalar n = `n'
    if `asobs' return scalar bwidth = `bwidth'
    return local curve "`curve'"
end
