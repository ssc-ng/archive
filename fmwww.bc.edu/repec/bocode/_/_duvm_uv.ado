*! _duvm_uv 1.0.1  2026-09-24  Abdelkrim Araar
*! The budget share and the log unit value of one good as duvm uses them.
*!
*!     _duvm_uv good, touse(varname) wt(varname) cluster(varname)
*!                    mode(drop|average|asis) share(newvar) uv(newvar)
*!
*! A buyer is a household whose budget share is positive.
*!   share  the budget share, a missing share read as 0 (a household that does
*!          not buy the good has a zero share, whatever the coding: . or 0)
*!   uv     the log unit value:
*!            drop     buyers only; the unit value of a non-buyer is ignored,
*!                     whatever its coding (., 0, or a value imputed in the data)
*!            average  buyers as in the data; each non-buyer of a cluster that
*!                     has buyers gets their weighted mean (never a value from
*!                     outside the cluster)
*!            asis     the variable as it is in the data
*! r(): counts over touse, for the diagnostics and the notes of duvm
*!   n_buy       buyers                  n_wmiss   shares coded . (read as 0)
*!   n_nbuv      non-buyers with a unit value in the data (imputed or coded 0)
*!   n_nbzero    of which a unit value coded 0 (a log unit value of 0)
*!   n_buynouv   buyers without a unit value
*!   c_buy       clusters with a buyer   c_uvnobuy clusters with a unit value but no buyer
program define _duvm_uv, rclass sortpreserve
    version 14.2
    syntax name(name=g), TOuse(varname) WT(varname) CLuster(varname) MODE(string) ///
        SHare(name) UV(name)
    if !inlist("`mode'", "drop", "average", "asis") {
        di as err "nonbuyers(`mode') not allowed; use nonbuyers(drop), nonbuyers(average) or nonbuyers(asis)"
        exit 198
    }
    confirm numeric variable w`g' luv`g'
    qui gen double `share' = cond(w`g' >= ., 0, w`g')
    tempvar buy
    qui gen byte `buy' = (`share' > 0) if `touse'

    * ---- counts, over the sample ----
    qui count if `touse' & `buy'
    return scalar n_buy = r(N)
    qui count if `touse' & w`g' >= .
    return scalar n_wmiss = r(N)
    qui count if `touse' & !`buy' & luv`g' < .
    return scalar n_nbuv = r(N)
    qui count if `touse' & !`buy' & luv`g' == 0
    return scalar n_nbzero = r(N)
    qui count if `touse' & `buy' & luv`g' >= .
    return scalar n_buynouv = r(N)
    tempvar cb cu tag
    qui egen `cb' = total(`buy' == 1), by(`cluster')
    qui egen `cu' = total(`touse' & luv`g' < .), by(`cluster')
    qui egen byte `tag' = tag(`cluster') if `touse'
    qui count if `tag' == 1 & `cb' > 0
    return scalar c_buy = r(N)
    qui count if `tag' == 1 & `cb' == 0 & `cu' > 0
    return scalar c_uvnobuy = r(N)

    * ---- the log unit value used by the model ----
    if "`mode'" == "asis" qui gen double `uv' = luv`g'
    else {
        qui gen double `uv' = luv`g' if `buy' == 1
        if "`mode'" == "average" {
            tempvar num den
            qui egen double `num' = total(cond(`buy' == 1 & luv`g' < ., `wt' * luv`g', 0)), by(`cluster')
            qui egen double `den' = total(cond(`buy' == 1 & luv`g' < ., `wt', 0)), by(`cluster')
            qui replace `uv' = `num' / `den' if `touse' & `buy' == 0 & `den' > 0
        }
    }
end
