*! duvm 1.2.1  2026-10-01  Abdelkrim Araar
*! Deaton's unit-value model: quality-corrected price and expenditure
*! elasticities from budget shares and unit values, cluster-level prices.
*! Model: Deaton (1988, 1990, 1997 ch. 5). Mata engine, closed-form estimator.
*! License: GPL-3.0-or-later
program define duvm, eclass
    version 14.2
    if replay() {
        if "`e(cmd)'" != "duvm" error 301
        syntax [, DEC(integer -1) SEall STars]
        _duvm_display, dec(`dec') `seall' `stars'
        if "`stars'" != "" _duvm_tables "", dec(`dec') screen(1)
        exit
    }
    syntax anything(name=namelist id="goods") [if] [in] [aweight fweight pweight iweight] , ///
        EXPend(varname numeric) CLuster(varname) ///
        [ HHsize(varname numeric) REGion(varname) SUBround(varname) INDCAT(varlist) INDCON(varlist numeric) ///
          HWeight(varname numeric) SELection SELGoods(namelist) SELVars(string) CSB(string) QOTHer(real 0.25) ///
          NOSYMmetry COMPAT COMPATFlags(string) VCE(string) Level(cilevel) ///
          DEC(integer 3) DREGres(integer 0) BOOT(integer 0) HGroup(varname) SEall ///
          SAVEres(string) STars NONBuyers(string) ELASticities(string) ///
          QUARD4(passthru) INISave(passthru) XFIL(passthru) GMODifier(passthru) noTABle ]
    _duvm_nofw `weight'

    * ---- goods and their variables ----
    local goods `namelist'
    local M : word count `goods'
    local wvars ""
    local uvvars ""
    foreach g of local goods {
        confirm numeric variable w`g' luv`g'
        local wvars  `wvars' w`g'
        local uvvars `uvvars' luv`g'
    }

    * ---- compat flags: 1 zeta formula, 2 completion (reciprocal zeta, syminv),
    * 3 sign of the last row of Theta_x, 4 cluster sizes = sum of weights,
    * 5 chi from the auxiliary regression, 6 mwegen denominator, 7 region = first household.
    * compat = the Stata code published with Deaton (1997, ch. 5): flags 1 2 3 5 7.
    * Flags 4 and 6 are weighting conventions of the earlier WELCOM implementation
    * (Deaton's code is unweighted); they stay reachable through compatflags().
    local cf "0 0 0 0 0 0 0"
    if "`compat'" != "" & "`hhsize'" == "" {
        di as err "compat requires hhsize(): the first stage of the code published with Deaton (1997)"
        di as err "has log household size among its regressors"
        exit 198
    }
    if "`compat'" != "" local cf "1 1 1 0 1 0 1"
    else if "`compatflags'" != "" {
        local cf ""
        foreach f in zeta completion sign counts chi mean region {
            local on : list f in compatflags
            local cf "`cf' `on'"
        }
        local compat "compat"
    }

    * ---- non-buyers: a buyer is a household whose budget share is positive;
    * drop (the book) ignores the unit value of a non-buyer whatever its coding,
    * average gives it the mean of the buyers of its cluster, asis takes the data
    * as they are (the default under compat, as Deaton's code does)
    if "`nonbuyers'" == "" local nonbuyers = cond("`compat'" != "", "asis", "drop")
    if !inlist("`nonbuyers'", "drop", "average", "asis") {
        di as err "nonbuyers(`nonbuyers') not allowed; use nonbuyers(drop), nonbuyers(average) or nonbuyers(asis)"
        exit 198
    }

    * ---- selection correction of the unit values (Heckman), see the help ----
    if `"`csb'"' != "" {
        di as err "csb() was replaced by selection in duvm 1.1: the correction now applies to the"
        di as err "unit values of the buyers (see help duvm, option selection)"
        exit 198
    }
    * the goods corrected (all by default, or selgoods()), and the variables of
    * each good's probit beyond x and its cluster means: selvars() holds
    * segments separated by ";", each "vars" (every corrected good) or
    * "good: vars" (that good only)
    if "`selgoods'" != "" | `"`selvars'"' != "" local selection "selection"
    local sel = ("`selection'" != "")
    local zall ""
    local selgstr ""
    local zmstr ""
    if `sel' {
        if "`selgoods'" == "" local selgoods `goods'
        foreach g of local selgoods {
            if !`: list g in goods' {
                di as err "selgoods(): `g' is not one of the goods"
                exit 198
            }
        }
        local selgoods : list uniq selgoods
        local selgoods0 `selgoods'
        local zcom ""
        foreach g of local goods {
            local z_`g' ""
        }
        local rest `"`selvars'"'
        while `"`rest'"' != "" {
            gettoken seg rest : rest, parse(";")
            local seg = trim(`"`seg'"')
            if `"`seg'"' == ";" | `"`seg'"' == "" continue
            if strpos(`"`seg'"', ":") {
                local gg = trim(substr(`"`seg'"', 1, strpos(`"`seg'"', ":") - 1))
                local vv = trim(substr(`"`seg'"', strpos(`"`seg'"', ":") + 1, .))
                if `"`gg'"' == "" {
                    di as err `"selvars(): a good name is missing before ":" in "`seg'""'
                    exit 198
                }
                if `: word count `gg'' > 1 {
                    di as err `"selvars(): one good per segment, "`gg'" is not one good; write "good1: vars ; good2: vars""'
                    exit 198
                }
                if strpos(`"`vv'"', ":") {
                    di as err `"selvars(): one colon per segment in "`seg'"; separate the goods by ";""'
                    exit 198
                }
                if `"`vv'"' == "" {
                    di as err "selvars(): no variable after `gg':"
                    exit 198
                }
                if !`: list gg in goods' {
                    di as err "selvars(): `gg' is not one of the goods (`goods')"
                    exit 198
                }
                if !`: list gg in selgoods' {
                    di as err "selvars(): `gg' is not corrected; add it to selgoods() (`selgoods')"
                    exit 198
                }
                capture unab vv : `vv'
                if _rc {
                    di as err "selvars(), `gg': variable not found in `vv'"
                    exit 111
                }
                confirm numeric variable `vv'
                local z_`gg' `z_`gg'' `vv'
            }
            else {
                capture unab vv : `seg'
                if _rc {
                    di as err `"selvars(): variable not found in "`seg'""'
                    exit 111
                }
                confirm numeric variable `vv'
                local zcom `zcom' `vv'
            }
        }
        foreach g of local selgoods {
            local z_`g' : list zcom | z_`g'
            local zall : list zall | z_`g'
        }
        * a probit-only variable is an exclusion restriction: it cannot be a
        * regressor of the unit-value equation, nor the purchase itself
        local xin `hhsize' `expend' `indcon' `indcat' `cluster'
        foreach g of local goods {
            local xin `xin' w`g' luv`g'
        }
        local bad : list zall & xin
        if "`bad'" != "" {
            di as err "selvars(): `bad' already in the model (first-stage regressor, cluster, budget share or"
            di as err "unit value); a variable of the probit only must be excluded from the unit-value equation"
            exit 198
        }
    }
    if `sel' & "`nonbuyers'" != "drop" {
        di as err "selection requires nonbuyers(drop): the correction applies to the unit values of the buyers"
        exit 198
    }
    if `sel' & "`compat'" != "" {
        di as err "selection is not available with compat or compatflags()"
        exit 198
    }

    * ---- variance estimator ----
    if `boot' > 0 & "`vce'" == "" {
        local vce "bootstrap, reps(`boot')"
        if "`compat'" != "" local vce "`vce' shortcut"
    }
    _duvm_vceparse `vce'
    local vtype   "`s(vtype)'"
    local reps    "`s(reps)'"
    local seed    "`s(seed)'"
    local bstrata "`s(strata)'"
    local bpsu    "`s(psu)'"
    local shortcut "`s(shortcut)'"
    local bsvy    "`s(svy)'"
    local fpcvar ""
    if "`bsvy'" != "" | "`vtype'" == "svy" {
        qui svyset
        if "`r(settings)'" == ", clear" | "`r(su1)'" == "" {
            di as err "vce(svy) requires the survey design to be declared with svyset"
            exit 119
        }
        if "`r(su1)'" != "." local bpsu "`r(su1)'"
        if "`r(strata1)'" != "." & "`r(strata1)'" != "" local bstrata "`r(strata1)'"
        if "`r(fpc1)'" != "." & "`r(fpc1)'" != "" local fpcvar "`r(fpc1)'"
        if "`weight'" == "" & "`hweight'" == "" & "`r(wvar)'" != "" {
            local weight "pweight"
            local exp "= `r(wvar)'"
        }
    }
    if "`vtype'" == "cluster" & "`compat'" != "" {
        di as txt "(compat: the analytic variance is not available; use vce(bootstrap) or vce(none))"
        local vtype "none"
    }
    local vnum = cond("`vtype'" == "none", 0, cond("`vtype'" == "cluster", 1, cond("`vtype'" == "svy", 2, 3)))

    * ---- the elasticities: of the household (each household counts for its
    * weight), of the individual (its weight times its size) or of the market
    * (the elasticities at the aggregate budget shares, each household counting
    * for its weight times its total expenditure) ----
    local elasticities = lower(trim("`elasticities'"))
    if "`elasticities'" == "" | strpos("households", "`elasticities'") == 1 local elasticities "households"
    else if strpos("individuals", "`elasticities'") == 1 local elasticities "individuals"
    else if strpos("market", "`elasticities'") == 1 local elasticities "market"
    else {
        di as err "elasticities(): households, individuals or market"
        exit 198
    }
    * the individuals need the size of each household: with hhsize(), every
    * statistic (regressions, cluster means, shares) weighs a household by its
    * weight times its size; without it, the choice is households or market
    if "`elasticities'" == "individuals" & "`hhsize'" == "" {
        di as err "elasticities(individuals) requires hhsize(): each household then counts for its"
        di as err "weight times its size; without hhsize(), use elasticities(households) or elasticities(market)"
        exit 198
    }
    local reference = cond("`elasticities'" == "individuals", "individuals", "households")
    local mkt = ("`elasticities'" == "market")

    * ---- weights: [w=] or hweight() ----
    if "`weight'" != "" & "`hweight'" != "" {
        di as err "specify either [weight=] or hweight(), not both"
        exit 198
    }
    tempvar wt
    if "`weight'" != "" {
        local wexp : subinstr local exp "=" "", all
        qui gen double `wt' = `wexp'
        local wtype "`weight'"
    }
    else if "`hweight'" != "" {
        qui gen double `wt' = `hweight'
        local wtype "aweight"
    }
    else {
        qui gen double `wt' = 1
        local wtype ""
    }
    * individuals: the weight times the household size; e(wexp) holds the weight
    * used, so that predict and estat rebuild the same one
    local wexpost ""
    if "`reference'" == "individuals" {
        qui replace `wt' = `wt' * `hhsize'
        if "`weight'" != ""       local wexpost "= (`=trim("`wexp'")') * (`hhsize')"
        else if "`hweight'" != "" local wexpost "= (`hweight') * (`hhsize')"
        else {
            local wexpost "= `hhsize'"
            local wtype "aweight"
        }
    }

    * ---- regressors of the first stage: log household size only with hhsize() ----
    tempvar lnexp lhhs
    qui gen double `lnexp' = ln(`expend')
    local X `lnexp'
    local Xnames "lnexp"
    if "`hhsize'" != "" {
        qui gen double `lhhs' = ln(`hhsize')
        local X `X' `lhhs'
        local Xnames "`Xnames' lnhhsize"
    }
    local X `X' `indcon'
    local Xnames "`Xnames' `indcon'"
    * the indicators of indcat(), one per level after the first, as temporary
    * variables: tabulate, generate() would leave the data in memory marked
    * as changed, c(changed), after the estimation
    foreach v of local indcat {
        tempvar grp
        qui egen long `grp' = group(`v') `if' `in'
        qui levelsof `v' `if' `in', local(levs)
        local nl : word count `levs'
        forvalues l = 2/`nl' {
            tempvar cd
            qui gen byte `cd' = (`grp' == `l') if `grp' < .
            local X `X' `cd'
            local val : word `l' of `levs'
            local Xnames "`Xnames' `v'==`val'"
        }
    }
    local k : word count `X'

    * ---- estimation sample: regressors non-missing, weight > 0 ----
    * (a missing budget share is a non-buyer: it does not drop the household)
    marksample touse
    markout `touse' `X' `wt' `cluster' `bstrata' `bpsu'
    qui replace `touse' = 0 if `wt' <= 0 | `wt' >= .
    if `sel' & "`zall'" != "" {
        qui count if `touse'
        local n0 = r(N)
        markout `touse' `zall'
        qui count if `touse'
        if r(N) < `n0' di as txt "(selvars(): `=string(`n0' - r(N), "%12.0fc")' households dropped for missing values of `zall')"
    }
    qui count if `touse'
    local N = r(N)
    if `N' == 0 error 2000
    if `sel' {
        * a good every household buys has no selection to correct (and no probit)
        local sg ""
        foreach g of local selgoods {
            qui count if `touse' & !(w`g' > 0 & w`g' < .)
            if r(N) == 0 di as txt "(selection: every household buys `g'; it is left uncorrected)"
            else local sg `sg' `g'
        }
        if "`sg'" == "" {
            di as err "selection: every household buys each of the goods to correct; nothing to correct"
            exit 459
        }
        local selgoods `sg'
        * for the engine: goods corrected (0/1) and, good by good, which of
        * the variables in zall enter its probit (row by row)
        foreach g of local goods {
            local on : list g in selgoods
            local selgstr `selgstr' `on'
            foreach v of local zall {
                local inz : list v in z_`g'
                local zmstr `zmstr' `=`on' & `inz''
            }
        }
    }

    * ---- the shares and unit values the model uses (see _duvm_uv) ----
    local wnames `wvars'
    local wvars ""
    local uvvars ""
    local nbnotes ""
    foreach g of local goods {
        tempvar s`g' u`g'
        _duvm_uv `g', touse(`touse') wt(`wt') cluster(`cluster') mode(`nonbuyers') share(`s`g'') uv(`u`g'')
        local wvars `wvars' `s`g''
        local uvvars `uvvars' `u`g''
        if r(n_wmiss) > 0 {
            local nbnotes `"`nbnotes' "(w`g': `=string(r(n_wmiss), "%12.0fc")' missing budget shares read as 0, households that do not buy `g')""'
        }
        if r(n_nbuv) > 0 & "`nonbuyers'" == "drop" {
            local nbnotes `"`nbnotes' "(luv`g': `=string(r(n_nbuv), "%12.0fc")' non-buyers have a unit value in the data, imputed or coded 0; ignored, see nonbuyers())""'
        }
        if r(n_nbuv) > 0 & "`nonbuyers'" == "asis" {
            local nbnotes `"`nbnotes' "(luv`g': the unit values of `=string(r(n_nbuv), "%12.0fc")' non-buyers are used as they are in the data, nonbuyers(asis))""'
        }
    }

    * ---- cluster-level design for the purge: region and subround dummies ----
    tempvar reg1 sub1
    if "`region'" != ""   qui gen double `reg1' = `region'
    else                  qui gen double `reg1' = 1
    if "`subround'" != "" qui gen double `sub1' = `subround'
    else                  qui gen double `sub1' = 1
    tempvar st1 ps1 fp1
    if "`bstrata'" != "" qui gen double `st1' = `bstrata'
    else                 qui gen double `st1' = 1
    if "`bpsu'" != ""    qui gen double `ps1' = `bpsu'
    else                 qui gen double `ps1' = `cluster'
    if "`fpcvar'" != ""  qui gen double `fp1' = `fpcvar'
    else                 qui gen double `fp1' = 0

    * ---- first-stage regressions echoed if requested ----
    if `dregres' == 1 {
        di as txt _n "The cluster fixed-effect regressions (unit values)"
        foreach g of local goods {
            di as txt _n "log unit value of `g'"
            areg `u`g'' `X' [aw=`wt'] if `touse', absorb(`cluster')
        }
        if `sel' di as txt "(selection: the unit-value regressions above omit the Mills ratio; the"
        if `sel' di as txt " corrected coefficients are in e(beta1), e(sel_theta) and e(sel_gamma))"
        di as txt _n "The budget-share regressions"
        foreach g of local goods {
            di as txt _n "budget share of `g'"
            areg `s`g'' `X' [aw=`wt'] if `touse', absorb(`cluster')
        }
    }

    * ---- the engine ----
    tempname R
    mata: _duvm_run("`R'", "`wvars'", "`uvvars'", "`X'", `sel', "`zall'", "`selgstr'", "`zmstr'", "`wt'", ///
                    "`cluster'", "`reg1'", "`sub1'", "`st1'", "`ps1'", "`fp1'", "`touse'", ///
                    "`cf'", "`nosymmetry'" == "", `qother', ///
                    `vnum', `reps', `seed', "`shortcut'" != "", `mkt')

    * ---- own-price elasticities by group (re-estimation on each subsample) ----
    if "`hgroup'" != "" {
        tempname G
        qui levelsof `hgroup' if `touse', local(glevs)
        local ng : word count `glevs'
        local gopts expend(`expend') cluster(`cluster') `selection' qother(`qother') `nosymmetry' nonbuyers(`nonbuyers')
        if "`hhsize'" != "" local gopts `gopts' hhsize(`hhsize')
        local gopts `gopts' elasticities(`elasticities')
        if `sel' local gopts `gopts' selgoods(`selgoods0')
        if `"`selvars'"' != "" local gopts `gopts' selvars(`selvars')
        if "`compatflags'" != "" local gopts `gopts' compatflags(`compatflags')
        else if "`compat'" != "" local gopts `gopts' compat
        foreach o in region subround indcat indcon hweight {
            if "``o''" != "" local gopts `gopts' `o'(``o'')
        }
        if "`vtype'" == "bootstrap" {
            local bv "reps(`reps')"
            if `seed' >= 0 local bv "`bv' seed(`seed')"
            if "`bstrata'" != "" local bv "`bv' strata(`bstrata')"
            if "`bpsu'" != "" local bv "`bv' psu(`bpsu')"
            local gopts `gopts' vce(bootstrap, `bv' `shortcut')
        }
        else local gopts `gopts' vce(`vtype')
        local gw ""
        if "`weight'" != "" local gw "[`weight'`exp']"
        local gse = ("`vtype'" != "none")
        local ncol = cond(`gse', 2*`M', `M')
        matrix `G' = J(`ng', `ncol', .)
        local gi 0
        local gnames ""
        local gcols ""
        foreach g of local goods {
            local gcols `gcols' `g'
            if `gse' local gcols `gcols' se_`g'
        }
        foreach gv of local glevs {
            local ++gi
            local gl : label (`hgroup') `gv'
            local gnames `"`gnames' "`gl'""'
            capture {
                preserve
                qui keep if `touse' & `hgroup' == `gv'
                qui duvm `goods' `gw', `gopts' notable
                forvalues j = 1/`M' {
                    if `gse' {
                        matrix `G'[`gi', 2*`j'-1] = el(e(elast_price), `j', `j')
                        matrix `G'[`gi', 2*`j']   = el(e(se_elast_price), `j', `j')
                    }
                    else matrix `G'[`gi', `j'] = el(e(elast_price), `j', `j')
                }
                restore
            }
            if _rc {
                capture restore
                di as txt "  (group `gl': estimation failed, rc=`_rc')"
            }
        }
        matrix rownames `G' = `gnames'
        matrix colnames `G' = `gcols'
    }

    * ---- post ----
    tempname b V
    mata: _duvm_b("`R'", "`goods'", "`b'", "`V'")
    if `duvm_hasV' ereturn post `b' `V', obs(`duvm_N') esample(`touse')
    else           ereturn post `b', obs(`duvm_N') esample(`touse')
    mata: _duvm_post("`R'", "`goods'", "`Xnames'", "`zall'")
    ereturn local cmd "duvm"
    ereturn local cmdline `"duvm `0'"'
    ereturn local estat_cmd "duvm_estat"
    ereturn local predict "duvm_p"
    ereturn local expend "`expend'"
    ereturn local hhsize "`hhsize'"
    ereturn local indcat "`indcat'"
    ereturn local indcon "`indcon'"
    ereturn local goods "`goods'"
    ereturn local depvar "`wnames'"
    ereturn local nonbuyers "`nonbuyers'"
    ereturn local clustvar "`cluster'"
    ereturn local wtype "`wtype'"
    if "`wexpost'" != "" ereturn local wexp "`wexpost'"
    else if "`weight'" != "" ereturn local wexp "`exp'"
    else if "`hweight'" != "" ereturn local wexp "= `hweight'"
    ereturn local elasticities "`elasticities'"
    ereturn local region "`region'"
    ereturn local subround "`subround'"
    if "`compat'" != "" ereturn local compat "compat"
    if "`compatflags'" != "" ereturn local compatflags "`compatflags'"
    if "`nosymmetry'" != "" ereturn local symmetry "none"
    else ereturn local symmetry "approx"
    if `sel' {
        ereturn local selection "heckman"
        ereturn local selgoods "`selgoods'"
        ereturn local selvars `"`selvars'"'
        foreach g of local selgoods {
            ereturn local sel_z_`g' "`z_`g''"
        }
    }
    if "`vtype'" == "bootstrap" {
        ereturn local vce "bootstrap"
        ereturn local vcetype "Bootstrap"
        if "`shortcut'" != "" ereturn local bootstrap "second stage only (Deaton's shortcut)"
        else                  ereturn local bootstrap "both stages"
        ereturn local bstrata "`bstrata'"
        ereturn local bpsu "`bpsu'"
        ereturn scalar N_reps = `reps'
        if `seed' >= 0 ereturn scalar seed = `seed'
    }
    else if "`vtype'" == "cluster" {
        ereturn local vce "cluster"
        ereturn local vcetype "Linearized"
    }
    else if "`vtype'" == "svy" {
        ereturn local vce "svy"
        ereturn local vcetype "Linearized"
        ereturn local bstrata "`bstrata'"
        ereturn local bpsu "`bpsu'"
        ereturn local fpc "`fpcvar'"
    }
    else ereturn local vce "none"
    ereturn scalar qother = `qother'
    ereturn scalar M = `M'
    ereturn scalar k = `k'
    ereturn scalar dec = `dec'
    ereturn scalar level = `level'
    if "`hgroup'" != "" {
        ereturn matrix elast_price_own_group = `G'
        ereturn local hgroup "`hgroup'"
    }
    foreach l of local nbnotes {
        di as txt `"`l'"'
    }
    if "`table'" == "" _duvm_display, dec(`dec') `seall' `stars'
    * the tables through tabstars: on screen with stars, and/or into a file
    local scr = ("`stars'" != "" & "`table'" == "")
    if `"`saveres'"' != "" | `scr' _duvm_tables `"`saveres'"', dec(`dec') screen(`scr')
end

* ============================================================================
* the tables through _duvm_tabstars, the private copy of tabstars shipped with
* the package (src/_duvm_tabstars.ado, built by tools/make_duvm_tabstars.py):
* stars renders them on screen (significance stars, Table N / N-b),
* saveres(file) writes them to one file (the extension gives the format:
* .docx .tex .xlsx .csv .md). Only the basic layout is used (matrices,
* standard errors, titles, numbers, decimals): for a different rendering,
* call the tabstars package on the e() matrices.
program define _duvm_tables
    syntax [anything(name=fname)] [, DEC(integer 3) SCREEN(integer 0)]
    * the file name as typed, quoted or not: one level of quotes is removed here
    local file `fname'
    if `dec' < 0 local dec = e(dec)
    local M = e(M)
    local goods `e(goods)'
    local hasV = inlist("`e(vce)'", "bootstrap", "cluster", "svy")
    local sym = ("`e(symmetry)'" == "approx")
    tempname T S
    local show = cond(`screen', "", "nodisplay")
    if "`file'" != "" _duvm_tabstars export begin using "`file'", replace
    capture noisily {
        matrix `T' = e(shares_mean) * 100
        matrix rownames `T' = "Share"
        matrix colnames `T' = `goods'
        if `hasV' {
            matrix `S' = e(se_shares_mean) * 100
            _duvm_tab, num(1) title("Average budget shares (in %)") est(`T') se(`S') dec(`dec') nostars `show'
        }
        else _duvm_tab, num(1) title("Average budget shares (in %)") est(`T') dec(`dec') `show'
        matrix `T' = e(elast_exp)
        matrix rownames `T' = "Elasticity"
        if `hasV' {
            matrix `S' = e(se_elast_exp)
            _duvm_tab, num(2) title("Expenditure elasticities of quantity, e = 1 - b1 + b0/wbar") est(`T') se(`S') dec(`dec') `show'
        }
        else _duvm_tab, num(2) title("Expenditure elasticities of quantity, e = 1 - b1 + b0/wbar") est(`T') dec(`dec') `show'
        matrix `T' = e(elast_qual)
        matrix rownames `T' = "Elasticity"
        if `hasV' {
            matrix `S' = e(se_elast_qual)
            _duvm_tab, num(3) title("Quality elasticities, b1 = dln(unit value)/dln(expenditure)") est(`T') se(`S') dec(`dec') `show'
        }
        else _duvm_tab, num(3) title("Quality elasticities, b1 = dln(unit value)/dln(expenditure)") est(`T') dec(`dec') `show'
        * the price-elasticity matrices; with a variance each one is followed
        * by its standard errors (Table N-b), so Table 9 of the screen (the SE
        * of the final matrix) is Table 8-b (7-b without symmetry)
        local pt "Price elasticities of quantity"
        local rt "Quantity of"
        _duvm_tabm, num(4) title("`pt', unit values taken as prices (no quality correction), unrestricted") est(e(elast_price_noqual)) se(e(se_elast_price_noqual)) dec(`dec') rowtitle("`rt'") hasv(`hasV') `show'
        _duvm_tabm, num(5) title("`pt', quality corrected, unrestricted, M x M system") est(e(elast_price_M_ns)) se(e(se_elast_price_M_ns)) dec(`dec') rowtitle("`rt'") hasv(`hasV') `show'
        if `sym' _duvm_tabm, num(6) title("`pt', quality corrected, symmetry restricted, M x M system") est(e(elast_price_M)) se(e(se_elast_price_M)) dec(`dec') rowtitle("`rt'") hasv(`hasV') `show'
        _duvm_tabm, num(7) title("`pt', quality corrected, unrestricted, completed system") est(e(elast_price_ns)) se(e(se_elast_price_ns)) dec(`dec') rowtitle("`rt'") hasv(`hasV') `show'
        if `sym' _duvm_tabm, num(8) title("`pt', quality corrected, symmetry restricted, completed system") est(e(elast_price)) se(e(se_elast_price)) dec(`dec') rowtitle("`rt'") hasv(`hasV') `show'
        if "`e(hgroup)'" != "" {
            * the group table interleaves elasticity and SE columns: split them
            local gse = (colsof(e(elast_price_own_group)) == 2 * `M')
            mata: st_matrix("`T'", st_matrix("e(elast_price_own_group)")[., ((1 + `gse') * (1::`M') :- `gse')'])
            mata: st_matrixrowstripe("`T'", st_matrixrowstripe("e(elast_price_own_group)"))
            matrix colnames `T' = `goods'
            local gt "Own-price elasticities by `e(hgroup)' (the model re-estimated within each group; method of Table `=cond(`sym', 8, 7)')"
            if `gse' {
                mata: st_matrix("`S'", st_matrix("e(elast_price_own_group)")[., (2 * (1::`M'))'])
                _duvm_tab, num(10) title("`gt'") est(`T') se(`S') dec(`dec') rowtitle("`e(hgroup)'") `show'
            }
            else _duvm_tab, num(10) title("`gt'") est(`T') dec(`dec') rowtitle("`e(hgroup)'") `show'
        }
    }
    if _rc {
        local rc = _rc
        capture _duvm_tabstars export clear
        if "`file'" != "" di as err "saveres(): the tables could not be written to `file'"
        exit `rc'
    }
    if `screen' _duvm_footnote
    if "`file'" != "" _duvm_tabstars export end
end

* one table (and its standard errors) through tabstars
program define _duvm_tab
    syntax, num(string) title(string) est(name) [se(name) dec(integer 3) noSTars rowtitle(string) NODISplay]
    if "`nodisplay'" == "" di ""
    if "`se'" != "" _duvm_tabstars `est', se(`se') dec(`dec') title(`"`title'"') tabnumber(`num') rowtitle(`"`rowtitle'"') `nodisplay' `stars'
    else _duvm_tabstars `est', dec(`dec') title(`"`title'"') tabnumber(`num') rowtitle(`"`rowtitle'"') `nodisplay'
end

* a price-elasticity matrix from e(): copied first (tabstars wants a matrix name)
program define _duvm_tabm
    syntax, num(string) title(string) est(string) se(string) [dec(integer 3) hasv(integer 0) rowtitle(string) NODISplay]
    tempname T S
    matrix `T' = `est'
    if `hasv' {
        matrix `S' = `se'
        _duvm_tab, num(`num') title(`"`title'"') est(`T') se(`S') dec(`dec') rowtitle(`"`rowtitle'"') `nodisplay'
    }
    else _duvm_tab, num(`num') title(`"`title'"') est(`T') dec(`dec') rowtitle(`"`rowtitle'"') `nodisplay'
end

* ============================================================================
program define _duvm_vceparse, sclass
    sreturn clear
    if `"`0'"' == "" {
        sreturn local vtype "cluster"
        sreturn local reps 0
        sreturn local seed -1
        exit
    }
    gettoken vtype 0 : 0, parse(",")
    local vtype = lower(trim("`vtype'"))
    if inlist("`vtype'", "boot", "bootstrap", "bs") local vtype "bootstrap"
    else if inlist("`vtype'", "none") local vtype "none"
    else if inlist("`vtype'", "cluster", "linearized", "robust", "") local vtype "cluster"
    else if inlist("`vtype'", "svy", "survey") local vtype "svy"
    else {
        di as err "vce(`vtype') not allowed; use vce(cluster), vce(svy) or vce(bootstrap [, reps() seed() strata() psu() shortcut svy])"
        exit 198
    }
    gettoken comma 0 : 0, parse(",")
    local 0 ", `0'"
    syntax [, Reps(integer 200) SEED(integer -1) STRata(varname) PSU(varname) SHORTcut SVY]
    if `reps' < 2 {
        di as err "reps() must be at least 2"
        exit 198
    }
    sreturn local vtype "`vtype'"
    sreturn local reps `reps'
    sreturn local seed `seed'
    sreturn local strata "`strata'"
    sreturn local psu "`psu'"
    sreturn local shortcut "`shortcut'"
    sreturn local svy "`svy'"
end

* ============================================================================
* fweights are refused: a household of the survey stands for its sampling
* weight, it is not a replicated record (the variance counts the households)
program define _duvm_nofw
    if "`0'" == "fweight" {
        di as err "fweights are not allowed: sampling weights go in {bf:[pweight=]} (or {bf:[aweight=]});"
        di as err "a frequency weight built from a sampling weight, such as int(pw*10000), is a pweight"
        exit 101
    }
end

* ============================================================================
program define _duvm_display
    syntax [, DEC(integer 3) SEall STars]
    if `dec' < 0 local dec = e(dec)
    local M = e(M)
    local cw = `dec' + 5
    local fmt "%`cw'.`dec'f"
    local goods `e(goods)'
    local wtxt = cond("`e(wtype)'" == "", "none", "`e(wtype)' `e(wexp)'")
    local hasV = inlist("`e(vce)'", "bootstrap", "cluster", "svy")
    di as txt _n "Deaton's unit-value model" _col(49) "Number of obs" _col(67) "= " as res %10.0fc e(N)
    di as txt "Goods: " as res "`goods'" as txt _col(49) "Number of clusters" _col(67) "= " as res %10.0fc e(N_clust)
    di as txt "Cluster variable: " as res "`e(clustvar)'" as txt _col(49) "Weights" _col(67) "= " as res "`wtxt'"
    local sy = cond("`e(symmetry)'" == "approx", "imposed (Deaton's approximation)", "not imposed")
    di as txt "Symmetry: " as res "`sy'" as txt _col(49) "Quality elast., other goods = " as res %5.3f e(qother)
    if "`e(elasticities)'" == "individuals" di as txt "Elasticities: " as res "individuals" as txt " (each household counts for its weight x its size)"
    else if "`e(elasticities)'" == "market" di as txt "Elasticities: " as res "market" as txt " (at the aggregate budget shares: weight x total expenditure)"
    else di as txt "Elasticities: " as res "households" as txt " (each household counts for its weight)"
    if "`e(hhsize)'" != "" di as txt "Household size: " as res "`e(hhsize)'" as txt " (its log is a regressor of the first stage)"
    else di as txt "Household size: " as res "not specified" as txt " (no log household size in the first stage)"
    if "`e(compatflags)'" != "" di as txt "Mode: " as res "compatflags(`e(compatflags)')"
    else if "`e(compat)'" != "" di as txt "Mode: " as res "compat" as txt " (the formulas of the Stata code published with Deaton, 1997)"
    if "`e(selection)'" != "" {
        di as txt "Selection: " as res "Heckman correction of the unit values" as txt " of " as res "`e(selgoods)'" ///
            as txt " (probit on x and its cluster means)"
        foreach g in `e(selgoods)' {
            if "`e(sel_z_`g')'" != "" di as txt "   probit of `g' also on: " as res "`e(sel_z_`g')'"
        }
    }
    if "`e(nonbuyers)'" == "average" di as txt "Non-buyers: unit value = mean of the buyers of the cluster (nonbuyers(average))"
    if "`e(nonbuyers)'" == "asis"    di as txt "Non-buyers: unit values as in the data (nonbuyers(asis))"
    if "`e(vce)'" == "bootstrap" {
        local bs = "bootstrap, `e(bootstrap)', " + strofreal(e(N_reps)) + " replications"
        if "`e(bpsu)'" != "" & "`e(bpsu)'" != "`e(clustvar)'" local bs "`bs', resampling `e(bpsu)'"
        if "`e(bstrata)'" != "" local bs "`bs' within `e(bstrata)'"
        di as txt "Std. err.: " as res "`bs'"
        if e(N_reps_ok) < e(N_reps) di as txt "  (" as res e(N_reps) - e(N_reps_ok) as txt " replications failed and were dropped)"
    }
    else if "`e(vce)'" == "cluster" di as txt "Std. err.: " as res "linearized, clustered by `e(clustvar)'"
    else if "`e(vce)'" == "svy" {
        local bs "linearized, survey design (PSU `e(bpsu)'"
        if "`e(bstrata)'" != "" local bs "`bs', strata `e(bstrata)'"
        if "`e(fpc)'" != "" local bs "`bs', FPC `e(fpc)'"
        di as txt "Std. err.: " as res "`bs')"
    }

    * the tables: 1-3 shares and expenditure/quality elasticities, 4 E without
    * quality correction, 5-6 the quality-corrected M x M system, 7-8 the
    * completed system (unrestricted, symmetry restricted), 9 SE, 10 by group
    local sym = ("`e(symmetry)'" == "approx")
    if "`stars'" != "" exit
    tempname T
    if `hasV' {
        matrix `T' = e(shares_mean) * 100 \ e(se_shares_mean) * 100
        matrix rownames `T' = "Share (%)" "  std. err."
    }
    else {
        matrix `T' = e(shares_mean) * 100
        matrix rownames `T' = "Share (%)"
    }
    matrix colnames `T' = `goods'
    matlist `T', border(rows) format(`fmt') twidth(14) left(2) title("Table 1: Average budget shares (in %)")

    if `hasV' {
        matrix `T' = e(elast_exp) \ e(se_elast_exp)
        matrix rownames `T' = "Elasticity" "  std. err."
    }
    else {
        matrix `T' = e(elast_exp)
        matrix rownames `T' = "Elasticity"
    }
    matrix colnames `T' = `goods'
    matlist `T', border(rows) format(`fmt') twidth(14) left(2) title("Table 2: Expenditure elasticities of quantity, e = 1 - b1 + b0/wbar")

    if `hasV' {
        matrix `T' = e(elast_qual) \ e(se_elast_qual)
        matrix rownames `T' = "Elasticity" "  std. err."
    }
    else {
        matrix `T' = e(elast_qual)
        matrix rownames `T' = "Elasticity"
    }
    * selection: the coefficient of the Mills ratio in the unit-value equation
    if "`e(selection)'" != "" {
        tempname TS
        capture confirm matrix e(se_sel_theta)
        if !_rc {
            matrix `TS' = e(sel_theta) \ e(se_sel_theta)
            matrix rownames `TS' = "Mills ratio" "  std. err."
        }
        else {
            matrix `TS' = e(sel_theta)
            matrix rownames `TS' = "Mills ratio"
        }
        matrix `T' = `T' \ `TS'
    }
    matrix colnames `T' = `goods'
    matlist `T', border(rows) format(`fmt') twidth(14) left(2) title("Table 3: Quality elasticities, b1 = dln(unit value)/dln(expenditure)")

    di _n as txt "Table 4: Price elasticities of quantity, unit values taken as prices (no quality correction), unrestricted"
    matlist e(elast_price_noqual), border(rows) format(`fmt') twidth(10) left(2)
    if `hasV' & "`seall'" != "" {
        di as txt "         standard errors (`e(vcetype)')"
        matlist e(se_elast_price_noqual), border(rows) format(`fmt') twidth(10) left(2)
    }
    di _n as txt "Table 5: Price elasticities of quantity, quality corrected, unrestricted, M x M system"
    matlist e(elast_price_M_ns), border(rows) format(`fmt') twidth(10) left(2)
    if `hasV' & "`seall'" != "" {
        di as txt "         standard errors (`e(vcetype)')"
        matlist e(se_elast_price_M_ns), border(rows) format(`fmt') twidth(10) left(2)
    }
    if `sym' {
        di _n as txt "Table 6: Price elasticities of quantity, quality corrected, symmetry restricted, M x M system"
        matlist e(elast_price_M), border(rows) format(`fmt') twidth(10) left(2)
    if `hasV' & "`seall'" != "" {
        di as txt "         standard errors (`e(vcetype)')"
        matlist e(se_elast_price_M), border(rows) format(`fmt') twidth(10) left(2)
    }
    }
    di _n as txt "Table 7: Price elasticities of quantity, quality corrected, unrestricted, completed system"
    matlist e(elast_price_ns), border(rows) format(`fmt') twidth(10) left(2)
    if `hasV' & "`seall'" != "" {
        di as txt "         standard errors (`e(vcetype)')"
        matlist e(se_elast_price_ns), border(rows) format(`fmt') twidth(10) left(2)
    }
    if `sym' {
        di _n as txt "Table 8: Price elasticities of quantity, quality corrected, symmetry restricted, completed system"
        matlist e(elast_price), border(rows) format(`fmt') twidth(10) left(2)
    }
    if `hasV' {
        di _n as txt "Table 9: Standard errors of the price elasticities of Table " cond(`sym', "8", "7") " (`e(vcetype)')"
        matlist e(se_elast_price), border(rows) format(`fmt') twidth(10) left(2)
    }
    if "`e(hgroup)'" != "" {
        di _n as txt "Table 10: Own-price elasticities by `e(hgroup)' (the model re-estimated within each group; method of Table " cond(`sym', "8", "7") ")"
        matlist e(elast_price_own_group), border(rows) format(`fmt') twidth(14) left(2)
    }
    _duvm_footnote
end

program define _duvm_footnote
    di as txt _n "Rows: quantity of the good; columns: price of the good. In the completed system the last row and"
    di as txt "column are the composite of all other goods. Tables 5-8 use the quality parameter of Deaton (1997, eq. 5.92)."
end

* ============================================================================
version 14.2
mata:
mata set matastrict on

struct duvm_d {                         // the data
    real matrix    W, UV, X, Zx             // Zx: variables of the selection probits only
    real matrix    zmask                    // M x cols(Zx): which enter the probit of good j
    real colvector selg                     // goods corrected (0/1)
    real colvector w, cid, reg, sub, strat, psu, fpc
    real scalar    hasl, N, C               // hasl: selection correction of the unit values
    real scalar    mkt                      // market elasticities: shares weighted by expenditure
}

struct duvm_c {                         // first stage + cluster-level series
    real scalar    N, C, M, k, kk, p, hasl  // kk = k + hasl regressors in the unit-value equation
    real scalar    mkt                      // the mean shares weighted by total expenditure
    real matrix    beta0, beta1
    real colvector wbar, b0, b1, ome, sig, chi
    real matrix    y0c, y1c, n0c, n1c, D
    // kept for the influence functions (data sorted by cluster)
    real matrix    Xs, Ws, info, MU, M0, E0, E1, XX0, XX1, xb0c, xb1c
    real colvector ws, cl, psu_c, strat_c, fpc_c
    real colvector norm0, norm1, norm01, df0, df1, df01, N0, N1, N01
    // selection (Heckman on the unit values): per good j, the Mills ratio
    // lambda, the probit coefficients and household influence functions, the
    // derivative terms of the unit-value coefficients, of the cluster series,
    // of omega and of chi with respect to the probit coefficients
    real colvector theta, selg
    real matrix    LAM, GAM, IFG, GG, zl1c, dome, dchi
    real matrix    sdiag                    // M x 5: buyers, % buyers, pseudo-R2, perfectly predicted, VIF of b1
}

struct duvm_r {                         // second stage and elasticities
    real scalar    N, C, M, k, sym, qother
    real rowvector cf                       // compat flags (7), all zero = the book
    real matrix    beta0, beta1
    real colvector wbar, b0, b1, ome, sig, chi, n0, n1, zeta, el
    real matrix    S, R, Sf, Rf, Bols, B, Bsym
    real matrix    Enq, Ens, Esy
    real matrix    Exns, Exsy
    real colvector ex, zx, wx
    real matrix    Psi, Theta, Psix, Thx
    real matrix    y0t, y1t                 // purged cluster-level series
    real colvector Nrep, Crep, Cpair        // reporters, clusters with reporters, min clusters per pair
    // variance
    real scalar    boot, reps, reps_ok, shortcut, seed, hasV, P
    real matrix    V, bootb, G, Veta
    // selection: coefficient of the Mills ratio, its std. err., probit coefficients
    real scalar    hasl
    real colvector theta, thse, selg
    real matrix    gam, sdiag
}

// ---------------------------------------------------------------- data
struct duvm_d scalar _duvm_load(string scalar wvars, string scalar uvvars, string scalar Xvars,
                                real scalar sel, string scalar zvars, string scalar selgs,
                                string scalar zms, string scalar wtvar, string scalar clvar,
                                string scalar regvar, string scalar subvar, string scalar stvar,
                                string scalar psvar, string scalar fpcvar, string scalar touse)
{
    struct duvm_d scalar d
    real colvector raw
    d.W   = st_data(., tokens(wvars), touse)
    d.UV  = st_data(., tokens(uvvars), touse)
    d.X   = st_data(., tokens(Xvars), touse)
    d.hasl = sel
    if (zvars != "") d.Zx = st_data(., tokens(zvars), touse)
    else             d.Zx = J(rows(d.W), 0, .)
    if (sel) d.selg = strtoreal(tokens(selgs))'
    else     d.selg = J(cols(d.W), 1, 0)
    if (sel & cols(d.Zx)) d.zmask = rowshape(strtoreal(tokens(zms)), cols(d.W))
    else                  d.zmask = J(cols(d.W), cols(d.Zx), 0)
    d.w   = st_data(., wtvar, touse)
    d.reg = st_data(., regvar, touse)
    d.sub = st_data(., subvar, touse)
    d.N   = rows(d.W)
    raw   = st_data(., clvar, touse)
    d.cid = _duvm_dense(raw)
    d.C   = max(d.cid)
    d.strat = _duvm_dense(st_data(., stvar, touse))
    d.psu   = _duvm_dense(st_data(., psvar, touse))
    if (fpcvar != "") d.fpc = st_data(., fpcvar, touse)
    else              d.fpc = J(d.N, 1, 0)
    return(d)
}

// dense 1..K codes of a categorical vector (original row order kept)
real colvector _duvm_dense(real colvector v)
{
    real colvector ord, s, code
    real scalar n
    n = rows(v)
    if (n == 0) return(v)
    ord = order(v, 1)
    s = v[ord]
    code = J(n, 1, .)
    code[ord] = runningsum(1 \ (s[|2 \ n|] :!= s[|1 \ n-1|]))
    return(code)
}

// ---------------------------------------------------------------- stage 1
// weighted within-cluster regression of Y (N x q) on X (N x k) on the rows
// with m==1; clusters contiguous, info = panelsetup, cl = cluster index.
real matrix _duvm_fe(real matrix Y, real matrix X, real colvector w, real colvector m,
                     real matrix info, real colvector cl,
                     real matrix e, real matrix yp, real scalar df, real scalar Cused,
                     real scalar norm, real matrix XXi)
{
    real colvector wm, sw
    real matrix Z, Zs, mu, Zd, b, Yc
    real scalar k, q

    k = cols(X); q = cols(Y)
    Yc = editmissing(Y, 0) :* m
    wm = w :* m
    sw = panelsum(wm, info)
    Z  = (Yc, X)
    Zs = panelsum(Z :* wm, info)
    mu = Zs :/ (sw :+ (sw :== 0))
    Zd = (Z - mu[cl, .]) :* m
    XXi = invsym(quadcross(Zd[., q+1..q+k], wm, Zd[., q+1..q+k]))
    b  = XXi * quadcross(Zd[., q+1..q+k], wm, Zd[., 1..q])
    e  = (Zd[., 1..q] - Zd[., q+1..q+k] * b) :* m
    yp = (Yc - X * b) :* m
    Cused = sum(sw :> 0)
    df = sum(m) - k - Cused
    norm = sum(m) / sum(wm)
    return(b)
}

// weighted probit of dd (0/1) on Z, by Fisher scoring (the log likelihood is
// concave). Returns the coefficients; lam = phi/Phi at the index (the inverse
// Mills ratio of the buyers), dlam = d lam / d index = -lam (index + lam), and
// IF, the household influence functions of the coefficients, (w r z') H^-1
// with H the observed Hessian. ok = 0 when everybody or nobody buys: then
// lam = 0 and nothing is corrected.
real colvector _duvm_probit(real colvector dd, real matrix Z, real colvector w,
                            real colvector lam, real colvector dlam, real matrix IF,
                            real scalar ok)
{
    real colvector g, xb, P, f, r, a, step, aq, rq
    real matrix Ii
    real scalar it, n, n1
    n = rows(dd)
    g = J(cols(Z), 1, 0)
    n1 = sum(dd)
    ok = (n1 > 0 & n1 < n)
    if (!ok) {
        lam = J(n, 1, 0); dlam = lam; IF = J(n, cols(Z), 0)
        return(g)
    }
    for (it = 1; it <= 200; it++) {
        xb = Z * g
        P  = rowmin((rowmax((normal(xb), J(n, 1, 1e-15))), J(n, 1, 1 - 1e-15)))
        f  = normalden(xb)
        r  = (dd - P) :* f :/ (P :* (1 :- P))
        a  = (f :^ 2) :/ (P :* (1 :- P))
        Ii = invsym(quadcross(Z, w :* a, Z))
        step = Ii * quadcross(Z, w :* r)
        g = g + step
        if (max(abs(step)) < 1e-11) break
    }
    xb = Z * g
    P  = rowmin((rowmax((normal(xb), J(n, 1, 1e-15))), J(n, 1, 1 - 1e-15)))
    f  = normalden(xb)
    lam  = exp(lnnormalden(xb) - lnnormal(xb))
    dlam = -lam :* (xb + lam)
    // The influence function uses the OBSERVED Hessian,
    // sum w r (r + xb) z z' with r = q phi(q xb) / Phi(q xb), q = 2d - 1
    // (the generalized residual): the derivative of the score the estimator
    // solves.  The expected information of the scoring steps equals it only
    // in expectation under a correct probit; on survey data the two differ at
    // first order (easi's brute force: up to 4.6% of the standard errors).
    aq = 2 :* dd :- 1
    rq = aq :* normalden(aq :* xb) :/ normal(aq :* xb)
    Ii = invsym(quadcross(Z, w :* (rq :* (rq :+ xb)), Z))
    IF = ((w :* rq) :* Z) * Ii
    return(g)
}

struct duvm_c scalar _duvm_stage1(struct duvm_d scalar d, real rowvector cf)
{
    struct duvm_c scalar c
    real matrix W, UV, X, Zx, info, e0, e1, e2, yp0, yp1, b, Zd, XXi, Zp, Xa, Xd, A, IFg, mu
    real colvector w, cid, cl, ord, mS, mU, m0, m01, sw, sw0, swsq, sw2, ee, y2, cnt, cnt0, nc
    real colvector dd, lam, dlam, ix, gj, xbp, Pp
    real matrix IFgj, ylp, el, Cm
    real scalar M, k, N, C, j, df, Cu, norm, i, kk, p, okp, cor, pb, ll, ll0, dfl, cul, nol

    // sort by cluster, stable, so that clusters are contiguous
    ord = order((d.cid, (1::rows(d.cid))), (1, 2))
    W = d.W[ord, .]; UV = d.UV[ord, .]; X = d.X[ord, .]; w = d.w[ord]; cid = d.cid[ord]
    Zx = d.Zx[ord, .]
    N = rows(W); k = cols(X); M = cols(W)
    info = panelsetup(cid, 1)
    C = rows(info)
    cl = J(N, 1, .)
    for (i = 1; i <= C; i++) cl[|info[i,1] \ info[i,2]|] = J(info[i,2]-info[i,1]+1, 1, i)

    c.N = N; c.C = C; c.M = M; c.k = k
    c.beta0 = J(k, M, .); c.beta1 = J(k, M, .)
    c.b0 = J(M, 1, .); c.b1 = J(M, 1, .); c.ome = J(M, 1, .); c.sig = J(M, 1, .); c.chi = J(M, 1, .)
    // the budget shares at which the elasticities are evaluated: the weighted
    // means (households, individuals), or the aggregate shares, total spending
    // on the good over total spending (market): weights times expenditure x
    c.mkt = d.mkt
    if (d.mkt) c.wbar = (quadcross(w :* exp(X[., 1]), W) / sum(w :* exp(X[., 1])))'
    else       c.wbar = (quadcross(w, W) / sum(w))'
    // kept for the influence functions
    c.Xs = X; c.Ws = W; c.ws = w; c.info = info; c.cl = cl
    c.MU = J(N, M, .); c.M0 = J(N, M, .); c.E0 = J(N, M, .); c.E1 = J(N, M, .)
    kk = k + d.hasl
    c.kk = kk; c.hasl = d.hasl
    c.XX0 = J(k, k*M, .); c.XX1 = J(kk, kk*M, .); c.xb0c = J(C, k*M, .); c.xb1c = J(C, kk*M, .)
    c.norm0 = J(M, 1, .); c.norm1 = J(M, 1, .); c.norm01 = J(M, 1, .)
    c.df0 = J(M, 1, .); c.df1 = J(M, 1, .); c.df01 = J(M, 1, .)
    c.N0 = J(M, 1, .); c.N1 = J(M, 1, .); c.N01 = J(M, 1, .)
    c.psu_c = d.psu[ord][info[., 1]]; c.strat_c = d.strat[ord][info[., 1]]; c.fpc_c = d.fpc[ord][info[., 1]]

    yp0 = J(N, M, .); yp1 = J(N, M, .)
    c.n0c = J(C, M, .); c.n1c = J(C, M, .)
    c.y0c = J(C, M, .); c.y1c = J(C, M, .)
    mS = J(N, 1, 1)
    sw = panelsum(w, info)
    nc = info[., 2] - info[., 1] :+ 1
    // selection: probit regressors = constant, x, the cluster means of x
    // (Mundlak 1978; Wooldridge 1995), and the probit-only variables
    p = 0
    if (d.hasl) {
        mu = panelsum(X :* w, info) :/ sw
        Zp = (J(N, 1, 1), X, mu[cl, .], Zx)
        p = cols(Zp)
    }
    c.p = p; c.selg = d.selg
    c.theta = J(M, 1, 0); c.LAM = J(N, M, 0); c.GAM = J(p, M, .); c.IFG = J(N, p*M, 0)
    c.GG = J(kk, p*M, 0); c.zl1c = J(C, p*M, 0); c.dome = J(M, p, 0); c.dchi = J(M, p, 0)
    c.sdiag = J(M, 5, .)
    for (j = 1; j <= M; j++) {
        // selection: probit of buying the good on all households, Mills ratio.
        // The probit of good j uses the constant, x, its cluster means and the
        // variables of zmask[j, .]; its coefficients and influence functions are
        // stored in blocks of p columns, zero (or missing) where a variable does
        // not enter. A good not corrected keeps the equation of the book.
        cor = (d.hasl ? d.selg[j] : 0)
        if (cor) {
            dd = (W[., j] :> 0) :& (W[., j] :< .)
            ix = (1::1+2*k)
            if (cols(d.zmask)) {
                if (any(d.zmask[j, .])) ix = ix \ (1 + 2*k) :+ selectindex(d.zmask[j, .])'
            }
            gj = _duvm_probit(dd, Zp[., ix], w, lam, dlam, IFgj, okp)
            c.GAM[ix, j] = gj
            IFg = J(N, p, 0); IFg[., ix] = IFgj
            c.LAM[., j] = lam
            c.IFG[., (j-1)*p+1..j*p] = IFg
            Xa = (X, lam)
        }
        else Xa = X
        // unit value equation on the reporters (+ the Mills ratio under selection)
        mU = (UV[., j] :< .)
        b = _duvm_fe(UV[., j], Xa, w, mU, info, cl, e1, ee, df, Cu, norm, XXi)
        if (d.hasl & !cor) {
            // not corrected: the blocks keep kk = k + 1 columns, the last one zero
            b = b \ 0
            XXi = (XXi, J(k, 1, 0) \ J(1, kk, 0))
            Xa = (X, J(N, 1, 0))
        }
        c.beta1[., j] = b[1..k]
        c.b1[j] = b[1]
        if (d.hasl) c.theta[j] = b[kk]
        c.ome[j] = norm * quadcross(e1, w :* mU, e1) / df
        yp1[., j] = ee
        c.MU[., j] = mU; c.E1[., j] = e1; c.XX1[., (j-1)*kk+1..j*kk] = XXi
        c.norm1[j] = norm; c.df1[j] = df; c.N1[j] = sum(mU)
        sw2 = panelsum(w :* mU, info)
        c.xb1c[., (j-1)*kk+1..j*kk] = panelsum(Xa :* (w :* mU), info) :/ (sw2 :+ (sw2 :== 0))
        if (cor) {
            // diagnostics of the correction: buyers, McFadden pseudo-R2 of the
            // probit, households predicted with probability 0 or 1 (separation),
            // and the variance inflation of the coefficient of ln x (b1) due to
            // lambda, 1/(1 - rho^2), rho the within-cluster partial correlation
            // of lambda and ln x given the other regressors, on the reporters
            xbp = Zp[., ix] * gj
            Pp  = normal(xbp)
            pb  = quadsum(w :* dd) / quadsum(w)
            ll  = quadsum(w :* (dd :* lnnormal(xbp) + (1 :- dd) :* lnnormal(-xbp)))
            ll0 = quadsum(w) * (pb * ln(pb) + (1 - pb) * ln(1 - pb))
            c.sdiag[j, 1] = sum(dd)
            c.sdiag[j, 2] = 100 * pb
            c.sdiag[j, 3] = 1 - ll / ll0
            c.sdiag[j, 4] = sum((Pp :< 1e-10) :| (Pp :> 1 - 1e-10))
            if (k > 1) (void) _duvm_fe((lam, X[., 1]), X[., 2..k], w, mU, info, cl, el, ylp, dfl, cul, nol, IFgj)
            else {
                mu = panelsum((lam, X[., 1]) :* (w :* mU), info) :/ (sw2 :+ (sw2 :== 0))
                el = ((lam, X[., 1]) - mu[cl, .]) :* mU
            }
            Cm = quadcross(el, w :* mU, el)
            c.sdiag[j, 5] = 1 / (1 - Cm[1, 2]^2 / (Cm[1, 1] * Cm[2, 2]))
            // A = theta dlambda z': how the fitted theta*lambda moves with the
            // probit coefficients; its terms in the unit-value coefficients (GG),
            // the cluster series (zl1c) and omega (dome)
            A  = J(N, p, 0); A[., ix] = (c.theta[j] :* dlam) :* Zp[., ix]
            mu = panelsum(Xa :* (w :* mU), info) :/ (sw2 :+ (sw2 :== 0))
            Xd = (Xa - mu[cl, .]) :* mU
            c.GG[., (j-1)*p+1..j*p]   = quadcross(Xd, w :* mU, A)
            c.zl1c[., (j-1)*p+1..j*p] = panelsum(A :* (w :* mU), info) :/ (sw2 :+ (sw2 :== 0))
            c.dome[j, .] = -2 * norm * quadcross(e1, w :* mU, A) / df
        }
        // budget share equation on all households: the regression of the share
        // averaging over zero and nonzero purchases (Deaton 1997, p. 304-305)
        m0 = mS
        b = _duvm_fe(W[., j], X, w, m0, info, cl, e0, ee, df, Cu, norm, XXi)
        c.beta0[., j] = b[1..k]
        c.b0[j] = b[1]
        c.sig[j] = norm * quadcross(e0, w :* m0, e0) / df
        yp0[., j] = ee
        c.M0[., j] = m0; c.E0[., j] = e0; c.XX0[., (j-1)*k+1..j*k] = XXi
        c.norm0[j] = norm; c.df0[j] = df; c.N0[j] = sum(m0)
        sw0 = panelsum(w :* m0, info)
        c.xb0c[., (j-1)*k+1..j*k] = panelsum(X :* (w :* m0), info) :/ (sw0 :+ (sw0 :== 0))
        // covariance of the two residuals on the households in both equations
        m01 = mU :* m0
        if (cf[5]) {
            Zd = (e0, X)
            b = _duvm_fe(e1, Zd, w, m01, info, cl, e2, y2, df, Cu, norm, XXi)
            c.chi[j] = b[1] * c.sig[j]
            c.norm01[j] = norm; c.df01[j] = df; c.N01[j] = sum(m01)
        }
        else {
            df = sum(m01) - k - sum(panelsum(w :* m01, info) :> 0)
            c.chi[j] = (sum(m01) / sum(w :* m01)) * quadcross(e1, w :* m01, e0) / df
            c.norm01[j] = sum(m01) / sum(w :* m01); c.df01[j] = df; c.N01[j] = sum(m01)
            // selection: e1 moves with the probit coefficients by -A, centred
            // within the cluster on the reporters
            if (cor) {
                mu = c.zl1c[., (j-1)*p+1..j*p]
                c.dchi[j, .] = -c.norm01[j] * quadcross(e0, w :* m01, (A - mu[cl, .]) :* mU) / df
            }
        }
        // cluster averages of the purged series and cluster sizes
        cnt  = panelsum(mU, info)
        cnt0 = panelsum(m0, info)
        sw0 = panelsum(w :* m0, info)
        sw2 = panelsum(w :* mU, info)
        if (cf[6]) {
            // WELCOM mwegen: numerator averaged over the observed, denominator over all
            c.y0c[., j] = (panelsum(yp0[., j] :* w, info) :/ (cnt0 :+ (cnt0 :== 0))) :/ (sw :/ nc)
            c.y1c[., j] = (panelsum(yp1[., j] :* w, info) :/ (cnt :+ (cnt :== 0))) :/ (sw :/ nc)
        }
        else {
            c.y0c[., j] = panelsum(yp0[., j] :* w, info) :/ (sw0 :+ (sw0 :== 0))
            c.y1c[., j] = panelsum(yp1[., j] :* w, info) :/ (sw2 :+ (sw2 :== 0))
        }
        if (cf[4]) {
            // WELCOM: the size of a cluster is the sum of its weights
            c.n0c[., j] = sw0
            c.n1c[., j] = sw2
        }
        else {
            // Kish effective sizes (5.55): (sum w)^2 / sum w^2
            swsq = panelsum((w:^2) :* m0, info)
            c.n0c[., j] = sw0:^2 :/ (swsq :+ (swsq :== 0))
            swsq = panelsum((w:^2) :* mU, info)
            c.n1c[., j] = sw2:^2 :/ (swsq :+ (swsq :== 0))
        }
        if (any(cnt0 :== 0)) c.y0c[selectindex(cnt0 :== 0), j] = J(sum(cnt0 :== 0), 1, .)
        if (any(cnt :== 0))  c.y1c[selectindex(cnt :== 0), j]  = J(sum(cnt :== 0), 1, .)
    }
    // cluster-level design of the purge: constant, region and subround dummies
    c.D = (J(C, 1, 1), _duvm_dummies(_duvm_clval(d.reg[ord], info, cf[7])),
                       _duvm_dummies(_duvm_clval(d.sub[ord], info, cf[7])))
    return(c)
}

// value of a household-level variable at the cluster level: the first
// non-missing value in the cluster (compat: the first household, as Deaton's code)
real colvector _duvm_clval(real colvector v, real matrix info, real scalar compat)
{
    real colvector out, x
    real scalar i
    out = v[info[., 1]]
    if (compat) return(out)
    for (i = 1; i <= rows(info); i++) {
        if (out[i] < .) continue
        x = select(v[|info[i, 1] \ info[i, 2]|], v[|info[i, 1] \ info[i, 2]|] :< .)
        if (rows(x)) out[i] = x[1]
    }
    return(out)
}

// pairwise covariance across clusters, divisor n-1, missing-aware
real scalar _duvm_cov(real colvector a, real colvector b)
{
    real colvector ok, x, y
    real scalar n
    ok = (a :< .) :& (b :< .)
    n = sum(ok)
    if (n < 2) return(.)
    x = select(a, ok); y = select(b, ok)
    return(quadcross(x :- mean(x), y :- mean(y)) / (n - 1))
}

real colvector _duvm_purge(real colvector y, real matrix D)
{
    real colvector ok, r, ys
    real matrix Ds
    ok = (y :< .) :& (rowsum(D :>= .) :== 0)
    if (sum(ok) < 2) return(y)
    Ds = select(D, ok); ys = select(y, ok)
    r = J(rows(y), 1, .)
    r[selectindex(ok)] = ys - Ds * (invsym(quadcross(Ds, Ds)) * quadcross(Ds, ys))
    return(r)
}

real matrix _duvm_dummies(real colvector v)
{
    real colvector u
    real scalar j
    real matrix D
    u = uniqrows(select(v, v :< .))
    if (rows(u) <= 1) return(J(rows(v), 0, .))
    D = J(rows(v), rows(u), 0)
    for (j = 1; j <= rows(u); j++) D[., j] = (v :== u[j])
    if (any(v :>= .)) D[selectindex(v :>= .), .] = J(sum(v :>= .), rows(u), .)
    return(D)
}

// ---------------------------------------------------------------- elasticities
void _duvm_elast(real matrix B, real colvector b0, real colvector b1, real colvector wbar,
                 real rowvector cf, real matrix Psi, real matrix Theta, real matrix E,
                 real colvector zeta)
{
    real scalar M
    M = rows(B)
    if (cf[1])  zeta = b1 :/ (b0 :+ (1 :- b1 :* wbar))          // the posted code
    else        zeta = b1 :/ (b0 :+ wbar :* (1 :- b1))          // Deaton (1997, 5.92)
    Psi   = luinv(I(M) - diag(zeta) * B' + diag(zeta) * diag(wbar))
    Theta = B' * Psi
    E     = (diag(1 :/ wbar) * B' - I(M)) * Psi
}

void _duvm_complete(real matrix Theta, real colvector b0, real colvector b1, real colvector wbar,
                    real scalar qother, real rowvector cf,
                    real matrix Thx, real matrix Psix, real matrix Ex, real colvector ex,
                    real colvector zx, real colvector wx)
{
    real scalar M
    real colvector b0x, b1x
    real matrix Bx
    M = rows(Theta)
    Thx = (Theta, -rowsum(Theta) - b0)                        // (5.93)
    if (cf[3])  Thx = Thx \ colsum(Thx)                         // the posted code (sign error)
    else        Thx = Thx \ -colsum(Thx)                        // (5.94): columns add to zero
    wx  = wbar \ (1 - sum(wbar))
    b1x = b1 \ qother
    b0x = b0 \ -sum(b0)
    ex  = 1 :- b1x + b0x :/ wx
    if (cf[2]) {
        // the posted code: the reciprocal of zeta through syminv(diag(b1)), which
        // zeroes the rows whose pivot is not positive
        zx = (wx :* (1 :- b1x) + b0x) :/ b1x
        zx = zx :* (b1x :> 0)
    }
    else zx = b1x :/ (wx :* (1 :- b1x) + b0x)                  // (5.92) on the extended vectors
    Psix = luinv(I(M+1) + diag(zx) * diag(wx)) * (I(M+1) + diag(zx) * Thx)
    Bx   = Thx * luinv(Psix)
    Ex   = (diag(1 :/ wx) * Bx - I(M+1)) * Psix
}

// restriction matrix R of (5.100)-(5.101): R vec(B) = r
real matrix _duvm_Rm(real scalar M)
{
    real scalar i, j, r, M2
    real matrix K, L
    M2 = M * M
    K = J(M2, M2, 0)
    for (i = 1; i <= M; i++) for (j = 1; j <= M; j++) K[(i-1)*M + j, (j-1)*M + i] = 1
    L = J(M*(M-1)/2, M2, 0)
    r = 0
    for (j = 1; j < M; j++) {
        for (i = j+1; i <= M; i++) {
            r = r + 1
            L[r, (j-1)*M + i] = 1
        }
    }
    return(L * (I(M2) - K))
}

real matrix _duvm_symmetry(real matrix B, real matrix A, real colvector b0, real colvector wbar)
{
    real scalar M
    real matrix Rm, iss, inn
    real colvector vb, rh
    M = rows(B)
    Rm = _duvm_Rm(M)
    rh = -Rm * (b0 # wbar)
    vb = vec(B)
    iss = (I(M) # invsym(A)) * Rm'
    inn = iss * invsym(Rm * iss)
    return(rowshape(vb + inn * (rh - Rm * vb), M)')
}

// ---------------------------------------------------------------- analytic variance
// Forward differential of the chain (S, R, ome, chi, b0, b1, wbar) -> theta,
// theta = (vec by row of E_x, e_x, b1). Exact derivatives, no finite difference.
real rowvector _duvm_dtheta(struct duvm_r scalar r, real matrix dS, real matrix dR,
                            real colvector dome, real colvector dchi, real colvector db0,
                            real colvector db1, real colvector dw)
{
    real scalar M
    real matrix Sf, Sfi, B, dSf, dRf, dB, Rm, Kr, Q, Qi, P, dAi, dKr, dQ, dP, BR, dBR
    real matrix dEnq, dEns, dExns, dEsy, dExsy
    real colvector b0, b1, w, g, dg, z, dz, vb, dvb, rh, drh, dvbR, ex, dex

    M = r.M
    b0 = r.b0; b1 = r.b1; w = r.wbar
    Sf = r.Sf; Sfi = invsym(Sf); B = r.B
    // S is a covariance matrix: a perturbation is read symmetrically (as invsym does)
    dSf = (dS + dS') / 2 - diag(dome :/ r.n1)
    dRf = dR - diag(dchi :/ r.n0)
    dB  = Sfi * (dRf - dSf * B)
    // unit values taken as prices: E = D(w)^-1 B' - I
    dEnq = -diag(1 :/ (w:^2)) * diag(dw) * B' + diag(1 :/ w) * dB'
    // zeta (5.92)
    g  = b0 + w :* (1 :- b1)
    dg = db0 + dw :* (1 :- b1) - w :* db1
    z  = b1 :/ g
    dz = db1 :/ g - b1 :* dg :/ (g:^2)
    // unrestricted B: M x M system and completed system
    _duvm_dchain(B, dB, z, dz, b0, db0, b1, db1, w, dw, r.qother, dEns, dExns, ex, dex)
    if (r.sym) {
        Rm = _duvm_Rm(M)
        Kr = I(M) # Sfi
        Q  = Rm * Kr * Rm'; Qi = invsym(Q)
        P  = Kr * Rm' * Qi
        rh = -Rm * (b0 # w)
        vb = vec(B)
        dAi = -Sfi * dSf * Sfi
        dKr = I(M) # dAi
        dQ  = Rm * dKr * Rm'
        dP  = dKr * Rm' * Qi - P * dQ * Qi
        drh = -Rm * (db0 # w + b0 # dw)
        dvb = vec(dB)
        dvbR = dvb + dP * (rh - Rm * vb) + P * (drh - Rm * dvb)
        BR  = r.Bsym
        dBR = rowshape(dvbR, M)'
        _duvm_dchain(BR, dBR, z, dz, b0, db0, b1, db1, w, dw, r.qother, dEsy, dExsy, ex, dex)
    }
    else {
        dEsy = dEns; dExsy = dExns
    }
    return((vec(dEnq')', vec(dEns')', vec(dEsy')', vec(dExns')', vec(dExsy')', dex', db1', dw', dz'))
}

// differential of (5.90)-(5.91) and of the completion (5.93)-(5.97) for a given B
void _duvm_dchain(real matrix B, real matrix dB, real colvector z, real colvector dz,
                  real colvector b0, real colvector db0, real colvector b1, real colvector db1,
                  real colvector w, real colvector dw, real scalar qother,
                  real matrix dE, real matrix dEx, real colvector ex, real colvector dex)
{
    real scalar M
    real matrix Q2, Psi, dQ2, dPsi, Theta, dTheta, Thx, dThx, A1, A2, A1i, Psix, dA1, dA2, dPsix
    real matrix Psixi, Bx, dBx, Dwi
    real colvector wx, dwx, b1x, db1x, b0x, db0x, gx, dgx, zx, dzx

    M = rows(B)
    Q2  = I(M) - diag(z) * B' + diag(z) * diag(w)
    Psi = luinv(Q2)
    dQ2 = -diag(dz) * B' - diag(z) * dB' + diag(dz) * diag(w) + diag(z) * diag(dw)
    dPsi = -Psi * dQ2 * Psi
    Theta  = B' * Psi
    dTheta = dB' * Psi + B' * dPsi
    Dwi = diag(1 :/ w)
    dE = (-Dwi * Dwi * diag(dw) * B' + Dwi * dB') * Psi + (Dwi * B' - I(M)) * dPsi
    // completion
    Thx  = (Theta, -rowsum(Theta) - b0)
    Thx  = Thx \ -colsum(Thx)
    dThx = (dTheta, -rowsum(dTheta) - db0)
    dThx = dThx \ -colsum(dThx)
    wx  = w \ (1 - sum(w));       dwx  = dw \ -sum(dw)
    b1x = b1 \ qother;            db1x = db1 \ 0
    b0x = b0 \ -sum(b0);          db0x = db0 \ -sum(db0)
    ex  = 1 :- b1x + b0x :/ wx
    dex = -db1x + db0x :/ wx - b0x :* dwx :/ (wx:^2)
    gx  = b0x + wx :* (1 :- b1x)
    dgx = db0x + dwx :* (1 :- b1x) - wx :* db1x
    zx  = b1x :/ gx
    dzx = db1x :/ gx - b1x :* dgx :/ (gx:^2)
    A1 = I(M+1) + diag(zx) * diag(wx)
    A2 = I(M+1) + diag(zx) * Thx
    A1i = luinv(A1)
    Psix = A1i * A2
    dA1 = diag(dzx) * diag(wx) + diag(zx) * diag(dwx)
    dA2 = diag(dzx) * Thx + diag(zx) * dThx
    dPsix = A1i * (dA2 - dA1 * Psix)
    Psixi = luinv(Psix)
    Bx  = Thx * Psixi
    dBx = (dThx - Bx * dPsix) * Psixi
    Dwi = diag(1 :/ wx)
    dEx = (-Dwi * Dwi * diag(dwx) * Bx + Dwi * dBx) * Psix + (Dwi * Bx - I(M+1)) * dPsix
}

// Jacobian of theta with respect to eta = (vec S, vec R, ome, chi, b0, b1, wbar)
real matrix _duvm_jac(struct duvm_r scalar r)
{
    real scalar M, q, i, j, s, K
    real matrix G, Z, U
    real colvector z, u
    M = r.M
    q = 2*M*M + 5*M
    K = cols(_duvm_bvec(r))
    G = J(K, q, .)
    Z = J(M, M, 0); z = J(M, 1, 0)
    for (j = 1; j <= M; j++) for (i = 1; i <= M; i++) {
        s = (j-1)*M + i
        U = Z; U[i, j] = 1
        G[., s]       = _duvm_dtheta(r, U, Z, z, z, z, z, z)'
        G[., M*M + s] = _duvm_dtheta(r, Z, U, z, z, z, z, z)'
    }
    for (j = 1; j <= M; j++) {
        u = z; u[j] = 1
        G[., 2*M*M + j]       = _duvm_dtheta(r, Z, Z, u, z, z, z, z)'
        G[., 2*M*M + M + j]   = _duvm_dtheta(r, Z, Z, z, u, z, z, z)'
        G[., 2*M*M + 2*M + j] = _duvm_dtheta(r, Z, Z, z, z, u, z, z)'
        G[., 2*M*M + 3*M + j] = _duvm_dtheta(r, Z, Z, z, z, z, u, z)'
        G[., 2*M*M + 4*M + j] = _duvm_dtheta(r, Z, Z, z, z, z, z, u)'
    }
    return(G)
}

// theta recomputed from a perturbed eta (used only to check the Jacobian)
real rowvector _duvm_theta_of(struct duvm_r scalar r0, real matrix S, real matrix R,
                              real colvector ome, real colvector chi, real colvector b0,
                              real colvector b1, real colvector wbar)
{
    struct duvm_r scalar r
    r = r0
    r.S = S; r.R = R; r.ome = ome; r.chi = chi; r.b0 = b0; r.b1 = b1; r.wbar = wbar
    _duvm_chain(r)
    return(_duvm_bvec(r))
}

// influence functions of eta, summed within price clusters: C x q
real matrix _duvm_if(struct duvm_c scalar c, struct duvm_r scalar r, real matrix Cth)
{
    real scalar M, k, kk, p, C, N, q, i, j, s, n, mi, mj, jj
    real matrix Phi, IF, Cb0, Cb1, CG, xt0, xt1, zt1, Xa, Xd, mu, XXj
    real colvector w, ok, yi, yj, Ji, Jj, m, sw, wm, wsh

    M = c.M; k = c.k; kk = c.kk; p = c.p; C = c.C; N = c.N
    q = 2*M*M + 5*M
    Phi = J(C, q, 0)
    w = c.ws
    // the weights of the mean shares (times expenditure for the market)
    wsh = (c.mkt ? w :* exp(c.Xs[., 1]) : w)

    // household-level influence functions, summed by cluster
    Cb0 = J(C, k*M, .); Cb1 = J(C, kk*M, .); CG = J(C, p*M, 0)
    for (j = 1; j <= M; j++) {
        // beta1_j (and theta_j under selection): (X~'WX~)^-1 x~_h w_h e1_h on
        // the reporters; under selection, minus the term of the estimated
        // probit (the Mills ratio is a generated regressor)
        m = c.MU[., j]; wm = w :* m
        sw = panelsum(wm, c.info)
        if (c.hasl) Xa = (c.Xs, c.LAM[., j])
        else        Xa = c.Xs
        mu = panelsum(Xa :* wm, c.info) :/ (sw :+ (sw :== 0))
        Xd = (Xa - mu[c.cl, .]) :* m
        XXj = c.XX1[., (j-1)*kk+1..j*kk]
        IF = (Xd :* (wm :* c.E1[., j])) * XXj
        if (c.hasl) {
            IF = IF - c.IFG[., (j-1)*p+1..j*p] * (c.GG[., (j-1)*p+1..j*p]' * XXj)
            CG[., (j-1)*p+1..j*p] = panelsum(c.IFG[., (j-1)*p+1..j*p], c.info)
        }
        Cb1[., (j-1)*kk+1..j*kk] = panelsum(IF, c.info)
        // beta0_j on the share sample
        m = c.M0[., j]; wm = w :* m
        sw = panelsum(wm, c.info)
        mu = panelsum(c.Xs :* wm, c.info) :/ (sw :+ (sw :== 0))
        Xd = (c.Xs - mu[c.cl, .]) :* m
        IF = (Xd :* (wm :* c.E0[., j])) * c.XX0[., (j-1)*k+1..j*k]
        Cb0[., (j-1)*k+1..j*k] = panelsum(IF, c.info)
        // omega_j, chi_j, wbar_j, b0_j, b1_j
        m = c.MU[., j]
        Phi[., 2*M*M + j] = panelsum(c.norm1[j] :* w :* (c.E1[., j]:^2) :* m :/ c.df1[j] - (r.ome[j] / c.N1[j]) :* m, c.info)
        m = c.MU[., j] :* c.M0[., j]
        Phi[., 2*M*M + M + j] = panelsum(c.norm01[j] :* w :* c.E0[., j] :* c.E1[., j] :* m :/ c.df01[j] - (r.chi[j] / c.N01[j]) :* m, c.info)
        if (c.hasl) {
            Phi[., 2*M*M + j]     = Phi[., 2*M*M + j]     + CG[., (j-1)*p+1..j*p] * c.dome[j, .]'
            Phi[., 2*M*M + M + j] = Phi[., 2*M*M + M + j] + CG[., (j-1)*p+1..j*p] * c.dchi[j, .]'
        }
        Phi[., 2*M*M + 4*M + j] = panelsum(wsh :* (c.Ws[., j] :- r.wbar[j]), c.info) / sum(wsh)
        Phi[., 2*M*M + 2*M + j] = Cb0[., (j-1)*k+1]
        Phi[., 2*M*M + 3*M + j] = Cb1[., (j-1)*kk+1]
    }
    // the coefficient of the Mills ratio, for its own standard error
    Cth = J(C, M, 0)
    if (c.hasl) for (j = 1; j <= M; j++) Cth[., j] = Cb1[., j*kk]

    // cluster-level means of x (and of lambda, theta dlambda z), purged like
    // the y's (generated-regressor terms)
    xt0 = c.xb0c; xt1 = c.xb1c; zt1 = c.zl1c
    for (j = 1; j <= M; j++) {
        for (jj = 1; jj <= k; jj++) {
            xt0[., (j-1)*k+jj] = _duvm_purge(_duvm_setmiss(c.xb0c[., (j-1)*k+jj], r.y0t[., j] :< .), c.D)
        }
        for (jj = 1; jj <= kk; jj++) {
            xt1[., (j-1)*kk+jj] = _duvm_purge(_duvm_setmiss(c.xb1c[., (j-1)*kk+jj], r.y1t[., j] :< .), c.D)
        }
        for (jj = 1; jj <= p; jj++) {
            zt1[., (j-1)*p+jj] = _duvm_purge(_duvm_setmiss(c.zl1c[., (j-1)*p+jj], r.y1t[., j] :< .), c.D)
        }
    }
    xt0 = editmissing(xt0, 0); xt1 = editmissing(xt1, 0); zt1 = editmissing(zt1, 0)

    // second-stage moments: own term + generated-regressor terms
    for (i = 1; i <= M; i++) for (j = 1; j <= M; j++) {
        s = (j-1)*M + i
        // S_ij = cov(y1_i, y1_j)
        ok = (r.y1t[., i] :< .) :& (r.y1t[., j] :< .)
        n = sum(ok)
        yi = editmissing(r.y1t[., i], 0) :* ok; yj = editmissing(r.y1t[., j], 0) :* ok
        mi = sum(yi) / n; mj = sum(yj) / n
        yi = (yi :- mi) :* ok; yj = (yj :- mj) :* ok
        Phi[., s] = Phi[., s] + (yi :* yj - r.S[i, j] :* ok) / (n - 1)
        Ji = -quadcross(xt1[., (i-1)*kk+1..i*kk] :* ok, yj) / (n - 1)
        Jj = -quadcross(xt1[., (j-1)*kk+1..j*kk] :* ok, yi) / (n - 1)
        Phi[., s] = Phi[., s] + Cb1[., (i-1)*kk+1..i*kk] * Ji + Cb1[., (j-1)*kk+1..j*kk] * Jj
        if (c.hasl) {
            Ji = -quadcross(zt1[., (i-1)*p+1..i*p] :* ok, yj) / (n - 1)
            Jj = -quadcross(zt1[., (j-1)*p+1..j*p] :* ok, yi) / (n - 1)
            Phi[., s] = Phi[., s] + CG[., (i-1)*p+1..i*p] * Ji + CG[., (j-1)*p+1..j*p] * Jj
        }
        // R_ij = cov(y1_i, y0_j)
        ok = (r.y1t[., i] :< .) :& (r.y0t[., j] :< .)
        n = sum(ok)
        yi = editmissing(r.y1t[., i], 0) :* ok; yj = editmissing(r.y0t[., j], 0) :* ok
        mi = sum(yi) / n; mj = sum(yj) / n
        yi = (yi :- mi) :* ok; yj = (yj :- mj) :* ok
        Phi[., M*M + s] = Phi[., M*M + s] + (yi :* yj - r.R[i, j] :* ok) / (n - 1)
        Ji = -quadcross(xt1[., (i-1)*kk+1..i*kk] :* ok, yj) / (n - 1)
        Jj = -quadcross(xt0[., (j-1)*k+1..j*k] :* ok, yi) / (n - 1)
        Phi[., M*M + s] = Phi[., M*M + s] + Cb1[., (i-1)*kk+1..i*kk] * Ji + Cb0[., (j-1)*k+1..j*k] * Jj
        if (c.hasl) {
            Ji = -quadcross(zt1[., (i-1)*p+1..i*p] :* ok, yj) / (n - 1)
            Phi[., M*M + s] = Phi[., M*M + s] + CG[., (i-1)*p+1..i*p] * Ji
        }
    }
    return(Phi)
}

real colvector _duvm_setmiss(real colvector v, real colvector ok)
{
    real colvector out
    out = v
    if (any(!ok)) out[selectindex(!ok)] = J(sum(!ok), 1, .)
    return(out)
}

// design aggregation: rows of Phi are price clusters; each belongs to a PSU
// and a stratum; fpc = population count of PSUs (>= 1) or sampling rate (< 1)
real matrix _duvm_vagg(real matrix Phi, real colvector psu, real colvector strat,
                       real colvector fpc, real scalar P)
{
    real matrix Php, V, D
    real colvector ord, ps, st, fp, u, sel
    real scalar h, nh, f, q
    ord = order(psu, 1)
    Php = panelsum(Phi[ord, .], panelsetup(psu[ord], 1))
    ps  = psu[ord][panelsetup(psu[ord], 1)[., 1]]
    st  = strat[ord][panelsetup(psu[ord], 1)[., 1]]
    fp  = fpc[ord][panelsetup(psu[ord], 1)[., 1]]
    P = rows(Php)
    q = cols(Phi)
    V = J(q, q, 0)
    u = uniqrows(st)
    for (h = 1; h <= rows(u); h++) {
        sel = selectindex(st :== u[h])
        nh = rows(sel)
        if (nh < 2) continue
        f = fp[sel[1]]
        if (f >= .) f = 0
        else if (f >= 1) f = nh / f
        D = Php[sel, .] :- mean(Php[sel, .])
        V = V + (1 - f) * nh / (nh - 1) * quadcross(D, D)
    }
    return(V)
}

void _duvm_analytic(struct duvm_c scalar c, struct duvm_r scalar r, real scalar svy)
{
    real matrix Phi, Cth
    real scalar P
    Phi = _duvm_if(c, r, Cth)
    r.G = _duvm_jac(r)
    if (svy) r.Veta = _duvm_vagg(Phi, c.psu_c, c.strat_c, c.fpc_c, P)
    else     r.Veta = _duvm_vagg(Phi, (1::c.C), J(c.C, 1, 1), J(c.C, 1, 0), P)
    // std. err. of the coefficient of the Mills ratio, same aggregation
    if (c.hasl) {
        if (svy) r.thse = sqrt(diagonal(_duvm_vagg(Cth, c.psu_c, c.strat_c, c.fpc_c, P)))
        else     r.thse = sqrt(diagonal(_duvm_vagg(Cth, (1::c.C), J(c.C, 1, 1), J(c.C, 1, 0), P)))
    }
    r.P = P
    r.V = r.G * r.Veta * r.G'
    r.V = (r.V + r.V') / 2
    r.hasV = 1
}

// ---------------------------------------------------------------- stage 2
// sel: the clusters used (rows of the cluster-level arrays, repetition allowed)
struct duvm_r scalar _duvm_stage2(struct duvm_c scalar c, real colvector sel,
                                  real rowvector cf, real scalar sym, real scalar qother)
{
    struct duvm_r scalar r
    real matrix y0c, y1c, n0c, n1c, D
    real colvector ok
    real scalar M, i, j

    M = c.M
    r.N = c.N; r.C = rows(sel); r.M = M; r.k = c.k; r.cf = cf; r.sym = sym; r.qother = qother
    r.beta0 = c.beta0; r.beta1 = c.beta1
    r.wbar = c.wbar; r.b0 = c.b0; r.b1 = c.b1; r.ome = c.ome; r.sig = c.sig; r.chi = c.chi
    r.hasl = c.hasl; r.theta = c.theta; r.gam = c.GAM; r.thse = J(M, 1, .); r.selg = c.selg; r.sdiag = c.sdiag
    y0c = c.y0c[sel, .]; y1c = c.y1c[sel, .]; n0c = c.n0c[sel, .]; n1c = c.n1c[sel, .]; D = c.D[sel, .]

    // harmonic means of the cluster sizes (5.55)
    r.n0 = J(M, 1, .); r.n1 = J(M, 1, .)
    for (j = 1; j <= M; j++) {
        ok = n0c[., j] :> 0
        r.n0[j] = 1 / mean(1 :/ select(n0c[., j], ok))
        ok = n1c[., j] :> 0
        r.n1[j] = 1 / mean(1 :/ select(n1c[., j], ok))
    }
    // purge region and subround effects
    for (j = 1; j <= M; j++) {
        y0c[., j] = _duvm_purge(y0c[., j], D)
        y1c[., j] = _duvm_purge(y1c[., j], D)
    }
    // between-cluster moments, pairwise
    r.S = J(M, M, .); r.R = J(M, M, .)
    for (i = 1; i <= M; i++) for (j = 1; j <= M; j++) {
        r.S[i, j] = _duvm_cov(y1c[., i], y1c[., j])
        r.R[i, j] = _duvm_cov(y1c[., i], y0c[., j])
    }
    r.y0t = y0c; r.y1t = y1c
    r.Bols = invsym(r.S) * r.R
    _duvm_chain(r)
    r.boot = 0; r.hasV = 0
    // counts for the diagnostics
    r.Nrep = c.N1; r.Crep = colsum(n1c :> 0)'
    r.Cpair = J(M, 1, .)
    for (i = 1; i <= M; i++) {
        r.Cpair[i] = rows(y1c)
        for (j = 1; j <= M; j++) r.Cpair[i] = min((r.Cpair[i], sum((y1c[., i] :< .) :& (y1c[., j] :< .))))
    }
    return(r)
}

// from (S, R, ome, chi, b0, b1, wbar, n0, n1) to the elasticities
void _duvm_chain(struct duvm_r scalar r)
{
    real scalar M
    M = r.M
    r.Sf = r.S - diag(r.ome :/ r.n1)
    r.Rf = r.R - diag(r.chi :/ r.n0)
    r.B  = invsym(r.Sf) * r.Rf
    r.el  = 1 :- r.b1 + r.b0 :/ r.wbar
    r.Enq = diag(1 :/ r.wbar) * r.B' - I(M)
    _duvm_elast(r.B, r.b0, r.b1, r.wbar, r.cf, r.Psi, r.Theta, r.Ens, r.zeta)
    _duvm_complete(r.Theta, r.b0, r.b1, r.wbar, r.qother, r.cf, r.Thx, r.Psix, r.Exns, r.ex, r.zx, r.wx)
    if (r.sym) {
        r.Bsym = _duvm_symmetry(r.B, r.Sf, r.b0, r.wbar)
        _duvm_elast(r.Bsym, r.b0, r.b1, r.wbar, r.cf, r.Psi, r.Theta, r.Esy, r.zeta)
        _duvm_complete(r.Theta, r.b0, r.b1, r.wbar, r.qother, r.cf, r.Thx, r.Psix, r.Exsy, r.ex, r.zx, r.wx)
    }
    else {
        r.Bsym = r.B; r.Esy = r.Ens; r.Exsy = r.Exns
    }
}

struct duvm_r scalar _duvm_estimate(struct duvm_d scalar d, real rowvector cf,
                                    real scalar sym, real scalar qother)
{
    struct duvm_c scalar c
    c = _duvm_stage1(d, cf)
    return(_duvm_stage2(c, (1::c.C), cf, sym, qother))
}

// the parameter vector reported in e(b): vec by row of E_x, then e_x, then b1
real rowvector _duvm_bvec(struct duvm_r scalar r)
{
    return((vec(r.Enq')', vec(r.Ens')', vec(r.Esy')', vec(r.Exns')', vec(r.Exsy')',
            r.ex', r.b1', r.wbar', r.zeta'))
}

// ---------------------------------------------------------------- bootstrap
// draw PSUs with replacement within strata; returns the list of drawn PSU codes
real colvector _duvm_draw(real colvector pstrat, real colvector plist)
{
    real colvector u, out, ids
    real scalar h, nh
    u = uniqrows(pstrat)
    out = J(0, 1, .)
    for (h = 1; h <= rows(u); h++) {
        ids = select(plist, pstrat :== u[h])
        nh = rows(ids)
        out = out \ ids[ceil(nh :* runiform(nh, 1))]
    }
    return(out)
}

void _duvm_boot(struct duvm_d scalar d, struct duvm_r scalar r, real scalar reps,
                real scalar seed, real scalar shortcut, real rowvector cf,
                real scalar sym, real scalar qother)
{
    struct duvm_c scalar c
    struct duvm_d scalar db
    struct duvm_r scalar rb
    real matrix pinfo, B, TH
    real colvector porder, psu_s, pstrat, plist, draws, idx, cidb, cstrat, ok, sel
    real scalar P, t, p, K, i, n, pos

    if (seed >= 0) rseed(seed)
    K = cols(_duvm_bvec(r))
    B = J(reps, K, .)
    TH = J(reps, r.M, .)
    if (shortcut) {
        // Deaton's shortcut: stage 1 once, resample the cluster-level file
        c = _duvm_stage1(d, cf)
        // stratum of a cluster = stratum of its first household
        porder = order(d.cid, 1)
        pinfo  = panelsetup(d.cid[porder], 1)
        cstrat = d.strat[porder][pinfo[., 1]]
        plist  = (1::c.C)
        for (t = 1; t <= reps; t++) {
            sel = _duvm_draw(cstrat, plist)
            rb = _duvm_stage2(c, sel, cf, sym, qother)
            B[t, .] = _duvm_bvec(rb)
            _duvm_dots(t, reps)
        }
    }
    else {
        // both stages: resample PSUs within strata, households travel with them
        porder = order(d.psu, 1)
        pinfo  = panelsetup(d.psu[porder], 1)
        P = rows(pinfo)
        pstrat = d.strat[porder][pinfo[., 1]]
        plist  = (1::P)
        for (t = 1; t <= reps; t++) {
            draws = _duvm_draw(pstrat, plist)
            n = sum(pinfo[draws, 2] - pinfo[draws, 1] :+ 1)
            idx = J(n, 1, .); cidb = J(n, 1, .)
            pos = 0
            for (i = 1; i <= rows(draws); i++) {
                p = draws[i]
                n = pinfo[p, 2] - pinfo[p, 1] + 1
                idx[|pos+1 \ pos+n|]  = porder[|pinfo[p, 1] \ pinfo[p, 2]|]
                // a PSU drawn twice is two distinct clusters
                cidb[|pos+1 \ pos+n|] = d.cid[porder[|pinfo[p, 1] \ pinfo[p, 2]|]] :+ (i - 1) * d.C
                pos = pos + n
            }
            db.W = d.W[idx, .]; db.UV = d.UV[idx, .]; db.X = d.X[idx, .]
            // selection: the probit is estimated again in every draw
            db.Zx = d.Zx[idx, .]; db.hasl = d.hasl; db.zmask = d.zmask; db.selg = d.selg; db.mkt = d.mkt
            db.w = d.w[idx]; db.reg = d.reg[idx]; db.sub = d.sub[idx]
            db.cid = _duvm_dense(cidb); db.N = rows(idx); db.C = max(db.cid)
            db.strat = d.strat[idx]; db.psu = d.psu[idx]; db.fpc = d.fpc[idx]
            rb = _duvm_estimate(db, cf, sym, qother)
            B[t, .] = _duvm_bvec(rb)
            TH[t, .] = rb.theta'
            _duvm_dots(t, reps)
        }
    }
    ok = (rowsum(B :>= .) :== 0)
    r.reps = reps; r.reps_ok = sum(ok); r.boot = 1; r.shortcut = shortcut; r.seed = seed
    r.bootb = B
    if (r.reps_ok >= 2) {
        B = select(B, ok)
        r.V = quadvariance(B)
        // selection: the coefficient of the Mills ratio (not under the
        // shortcut, where the first stage is not resampled)
        if (r.hasl & !shortcut) r.thse = sqrt(diagonal(quadvariance(select(TH, ok))))
    }
    else r.V = J(K, K, .)
}

void _duvm_dots(real scalar t, real scalar reps)
{
    if (t == 1) printf("{txt}Bootstrap replications ({res}%g{txt})\n", reps)
    if (mod(t, 50) == 0) printf(".%g\n", t)
    else printf(".")
    if (t == reps & mod(t, 50) != 0) printf("\n")
    displayflush()
}

// ---------------------------------------------------------------- driver
// vtype: 0 none, 1 linearized clustered by the price cluster, 2 linearized
// survey design, 3 bootstrap
void _duvm_run(string scalar Rname, string scalar wvars, string scalar uvvars,
               string scalar Xvars, real scalar sel, string scalar zvars, string scalar selgs,
               string scalar zms, string scalar wtvar,
               string scalar clvar, string scalar regvar, string scalar subvar,
               string scalar stvar, string scalar psvar, string scalar fpcvar,
               string scalar touse, string scalar cfstr, real scalar sym, real scalar qother,
               real scalar vtype, real scalar reps, real scalar seed, real scalar shortcut,
               real scalar mkt)
{
    struct duvm_d scalar d
    struct duvm_c scalar c
    struct duvm_r scalar r
    real rowvector cf
    pointer(struct duvm_r scalar) scalar p

    cf = strtoreal(tokens(cfstr))
    d = _duvm_load(wvars, uvvars, Xvars, sel, zvars, selgs, zms, wtvar, clvar, regvar, subvar, stvar, psvar, fpcvar, touse)
    d.mkt = mkt
    c = _duvm_stage1(d, cf)
    r = _duvm_stage2(c, (1::c.C), cf, sym, qother)
    if (vtype == 3) {
        _duvm_boot(d, r, reps, seed, shortcut, cf, sym, qother)
        r.hasV = (r.reps_ok >= 2)
    }
    else if (vtype == 1 | vtype == 2) _duvm_analytic(c, r, vtype == 2)
    p = crexternal(Rname)
    *p = r
}

void _duvm_b(string scalar Rname, string scalar goods, string scalar bname, string scalar Vname)
{
    struct duvm_r scalar r
    string rowvector g, gx
    string matrix cs
    real scalar M, j
    pointer(struct duvm_r scalar) scalar p

    p = findexternal(Rname); r = *p
    M = r.M
    g = tokens(goods); gx = (g, "composite")
    cs = _duvm_stripes(M, g, gx)
    st_matrix(bname, _duvm_bvec(r))
    st_matrixcolstripe(bname, cs)
    if (r.hasV) {
        st_matrix(Vname, r.V)
        st_matrixcolstripe(Vname, cs)
        st_matrixrowstripe(Vname, cs)
    }
    st_local("duvm_N", strofreal(r.N))
    st_local("duvm_hasV", strofreal(r.hasV))
}

// names of e(b): eq = table, name = quantity_price
string matrix _duvm_stripes(real scalar M, string rowvector g, string rowvector gx)
{
    string matrix cs
    string rowvector tabs
    real scalar t, i, j
    cs = J(0, 2, "")
    tabs = ("E_noqual", "E_M", "E_Msym")
    for (t = 1; t <= 3; t++) for (i = 1; i <= M; i++) for (j = 1; j <= M; j++) cs = cs \ (tabs[t], g[i] + "_p" + g[j])
    tabs = ("E_x", "E_xsym")
    for (t = 1; t <= 2; t++) for (i = 1; i <= M+1; i++) for (j = 1; j <= M+1; j++) cs = cs \ (tabs[t], gx[i] + "_p" + gx[j])
    cs = cs \ (J(M+1, 1, "exp"), gx') \ (J(M, 1, "qual"), g') \ (J(M, 1, "share"), g') \ (J(M, 1, "zeta"), g')
    return(cs)
}

void _duvm_post(string scalar Rname, string scalar goods, string scalar Xnames,
                string scalar Znames)
{
    struct duvm_r scalar r
    string rowvector g, gx, xn, zn
    real colvector th, ts
    real scalar M, K
    real colvector se
    pointer(struct duvm_r scalar) scalar p

    p = findexternal(Rname); r = *p
    M = r.M
    g = tokens(goods); gx = (g, "composite")
    xn = tokens(Xnames)

    st_numscalar("e(N_clust)", r.C)
    _duvm_mat("e(elast_price)",        r.Exsy, gx, gx)
    _duvm_mat("e(elast_price_ns)",     r.Exns, gx, gx)
    _duvm_mat("e(elast_price_noqual)", r.Enq,  g,  g)
    _duvm_mat("e(elast_price_M)",      r.Esy,  g,  g)
    _duvm_mat("e(elast_price_M_ns)",   r.Ens,  g,  g)
    _duvm_mat("e(elast_exp)",  r.el', "Elasticity", g)
    _duvm_mat("e(elast_exp_x)", r.ex', "Elasticity", gx)
    _duvm_mat("e(elast_qual)", r.b1', "Elasticity", g)
    _duvm_mat("e(shares_mean)", r.wbar', "Share", g)
    _duvm_mat("e(zeta)",  r.zeta', "zeta", g)
    _duvm_mat("e(zeta_x)", r.zx', "zeta", gx)
    _duvm_mat("e(b0)", r.b0', "b0", g)
    _duvm_mat("e(b1)", r.b1', "b1", g)
    _duvm_mat("e(omega)", r.ome', "omega", g)
    _duvm_mat("e(sigma)", r.sig', "sigma", g)
    _duvm_mat("e(chi)",   r.chi', "chi", g)
    _duvm_mat("e(n0)", r.n0', "n", g)
    _duvm_mat("e(n1)", r.n1', "n_plus", g)
    _duvm_mat("e(S)",  r.S,  g, g)
    _duvm_mat("e(R)",  r.R,  g, g)
    _duvm_mat("e(Sf)", r.Sf, g, g)
    _duvm_mat("e(Rf)", r.Rf, g, g)
    _duvm_mat("e(B_ols)", r.Bols, g, g)
    _duvm_mat("e(B)",     r.B,    g, g)
    _duvm_mat("e(B_sym)", r.Bsym, g, g)
    _duvm_mat("e(Psi)",   r.Psi,  g, g)
    _duvm_mat("e(Theta)", r.Theta, g, g)
    _duvm_mat("e(Psi_x)",   r.Psix, gx, gx)
    _duvm_mat("e(Theta_x)", r.Thx,  gx, gx)
    _duvm_mat("e(beta0)", r.beta0, xn, g)
    _duvm_mat("e(beta1)", r.beta1, xn, g)
    // selection: coefficient of the Mills ratio in the unit-value equations,
    // its std. err., the probit coefficients (constant, x, cluster means of x,
    // probit-only variables)
    if (r.hasl) {
        th = r.theta; ts = r.thse
        if (any(!r.selg)) {
            th[selectindex(!r.selg)] = J(sum(!r.selg), 1, .)
            ts[selectindex(!r.selg)] = J(sum(!r.selg), 1, .)
        }
        _duvm_mat("e(sel_theta)", th', "theta", g)
        // std. err.: available for every corrected good (not under the shortcut)
        if (missing(ts) == sum(!r.selg)) _duvm_mat("e(se_sel_theta)", ts', "Std. err.", g)
        zn = ("_cons", xn, "m_" :+ xn, tokens(Znames))
        _duvm_mat("e(sel_gamma)", r.gam, zn, g)
        _duvm_mat("e(sel_diag)", r.sdiag, g, ("Buyers", "Buy_pct", "Pseudo_R2", "Perfect", "VIF_b1"))
    }
    // legacy names of the WELCOM version
    _duvm_mat("e(elprice)",  r.Exsy[1..M, 1..M], g, g)
    _duvm_mat("e(elincome)", r.el', "Elasticity", g)
    _duvm_mat("e(N_report)",       r.Nrep', "N", g)
    _duvm_mat("e(N_clust_report)", r.Crep', "N", g)
    _duvm_mat("e(N_clust_pair)",   r.Cpair', "N", g)
    if (r.hasV) {
        se = sqrt(diagonal(r.V))
        K = 0
        _duvm_mat("e(se_elast_price_noqual)", rowshape(se[K+1..K+M*M], M), g, g);       K = K + M*M
        _duvm_mat("e(se_elast_price_M_ns)",   rowshape(se[K+1..K+M*M], M), g, g);       K = K + M*M
        _duvm_mat("e(se_elast_price_M)",      rowshape(se[K+1..K+M*M], M), g, g);       K = K + M*M
        _duvm_mat("e(se_elast_price_ns)", rowshape(se[K+1..K+(M+1)^2], M+1), gx, gx);   K = K + (M+1)^2
        _duvm_mat("e(se_elast_price)",    rowshape(se[K+1..K+(M+1)^2], M+1), gx, gx);   K = K + (M+1)^2
        _duvm_mat("e(se_elast_exp_x)", se[K+1..K+M+1]', "Std. err.", gx)
        _duvm_mat("e(se_elast_exp)",   se[K+1..K+M]', "Std. err.", g);                  K = K + M + 1
        _duvm_mat("e(se_elast_qual)",  se[K+1..K+M]', "Std. err.", g);                  K = K + M
        _duvm_mat("e(se_shares_mean)", se[K+1..K+M]', "Std. err.", g);                  K = K + M
        _duvm_mat("e(se_zeta)",        se[K+1..K+M]', "Std. err.", g)
        if (r.boot) {
            st_matrix("e(boot_b)", r.bootb)
            st_numscalar("e(N_reps_ok)", r.reps_ok)
        }
        else {
            st_matrix("e(G)", r.G)
            st_matrix("e(V_eta)", r.Veta)
            st_numscalar("e(N_psu)", r.P)
        }
    }
    rmexternal(Rname)
}

void _duvm_mat(string scalar name, real matrix A, string rowvector rn, string rowvector cn)
{
    st_matrix(name, A)
    st_matrixrowstripe(name, (J(rows(A), 1, ""), rn'))
    st_matrixcolstripe(name, (J(cols(A), 1, ""), cn'))
}
end
