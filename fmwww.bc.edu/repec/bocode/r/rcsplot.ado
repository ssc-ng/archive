************************************
*! rcsplot version 1.0
*! Zumin Shi, Oct 4 2026
************************************

program rcsplot, rclass
    version 16.0

    syntax anything [if] [in] [fw aw pw iw], ///
        [KNOTs(integer 3) REFval(string) EXP(string) ///
         LEVel(integer 95) XTItle(string) YTItle(string) ///
         TITle(string) NOtes(string asis) SAVing(string asis) ///
         DEBUG ///
         XLABel(string asis) YLABel(string asis)                ///
         XSCale(string asis) YSCale(string asis)                ///
         XTICks(string asis) YTICks(string asis)                ///
         GRaphregion(string asis) PLOTregion(string asis)       ///
         LWidth(string) CILWidth(string)                        ///
         LColor(string) CIColor(string)                         ///
         LEGend(string asis) NAME(string) INRANGE(string)       ///
         PVALues(string asis)                                   ///
         PVALtext                                               ///
         HISTogram                                              ///
         BINs(integer 15)                                       ///
         HISTColor(string)                                      ///
         HISTYTitle(string)                                     ///
         SVY                                                    ///
         SVYOPTS(string asis)                                   ///
         CIBand                                                 ///
         CIBColor(string asis)                                  ///
         CIBOpacity(string)                                     ///
         NATure                                                 ///
         TRim(string)                                           ///
         * ]

    *--- Normalize user if/in clause --------------------------------
    local userif "`if'"
    local userin "`in'"

    local userif_cond "`userif'"
    if substr("`userif_cond'", 1, 3) == "if " {
        local userif_cond = substr("`userif_cond'", 4, .)
    }
    local userin_cond "`userin'"
    if substr("`userin_cond'", 1, 3) == "in " {
        local userin_cond = substr("`userin_cond'", 4, .)
    }

    local ifclause ""
    if "`userif_cond'" != "" & "`userin_cond'" != "" {
        local ifclause "if `userif_cond' in `userin_cond'"
    }
    else if "`userif_cond'" != "" {
        local ifclause "if `userif_cond'"
    }
    else if "`userin_cond'" != "" {
        local ifclause "in `userin_cond'"
    }

    *--- Extract user name() from catch-all options -----------------
    if "`options'" != "" {
        local opts_str "`options'"
        local npos = ustrpos("`opts_str'", "name(")
        if `npos' > 0 {
            local rest = substr("`opts_str'", `npos' + 5, .)
            local depth = 1
            local pos = 0
            local len = strlen("`rest'")
            forvalues i = 1/`len' {
                local ch = substr("`rest'", `i', 1)
                if "`ch'" == "(" local depth = `depth' + 1
                if "`ch'" == ")" local depth = `depth' - 1
                if `depth' == 0 {
                    local pos = `i'
                    continue, break
                }
            }
            if `pos' > 0 {
                local user_name = substr("`rest'", 1, `pos' - 1)
                local user_name : subinstr local user_name ", replace" "", all
                local user_name : subinstr local user_name ",replace"  "", all
                local user_name : subinstr local user_name ","          "", all
                local user_name = strtrim("`user_name'")
                local before = substr("`opts_str'", 1, `npos' - 1)
                local after  = substr("`opts_str'", `npos' + 5 + `pos', .)
                local options "`before'`after'"
                local options = stritrim("`options'")
            }
        }
    }

    gettoken cmd rest : anything
    if "`cmd'" == "stcox" {
        gettoken xvar rest : rest
        local depvar ""
    }
    else {
        gettoken depvar rest : rest
        gettoken xvar   rest : rest
    }
    local covars "`rest'"

    if strpos("`xvar'", ".") == 0 local xvar_raw "`xvar'"
    else {
        tokenize "`xvar'", parse(".")
        local xvar_raw "`3'"
    }
    confirm variable `xvar_raw'

    if "`exp'" == "" {
        if inlist("`cmd'", "logistic", "logit", "poisson", "stcox") local exp "yes"
        else local exp "no"
    }

    if "`ytitle'" == "" {
        if "`exp'" == "yes" {
            if inlist("`cmd'", "logistic", "logit")       local ytitle "Odds ratio"
            else if "`cmd'" == "poisson"                  local ytitle "Rate ratio"
            else if "`cmd'" == "stcox"                    local ytitle "Hazard ratio"
            else                                          local ytitle "Exp(beta)"
        }
        else {
            if inlist("`cmd'", "logistic", "logit")       local ytitle "Log odds"
            else if "`cmd'" == "poisson"                  local ytitle "Log rate"
            else if "`cmd'" == "stcox"                    local ytitle "Log hazard"
            else                                          local ytitle "Beta coefficient"
        }
    }

    if "`xtitle'" == "" {
        local xtitle : variable label `xvar_raw'
        if "`xtitle'" == "" local xtitle "`xvar_raw'"
    }

    *--- Detect svy with subpop and extract the subpop condition -----
    local svy_with_subpop = 0
    local subpop_cond ""

    if "`svy'" != "" & ustrpos("`svyopts'", "subpop") > 0 {
        local svy_with_subpop = 1

        local svyopts_str "`svyopts'"
        local subpop_start = ustrpos("`svyopts_str'", "subpop(")
        if `subpop_start' > 0 {
            local rest = substr("`svyopts_str'", `subpop_start' + 7, .)
            local depth = 1
            local pos = 0
            local len = strlen("`rest'")
            forvalues i = 1/`len' {
                local ch = substr("`rest'", `i', 1)
                if "`ch'" == "(" local depth = `depth' + 1
                if "`ch'" == ")" local depth = `depth' - 1
                if `depth' == 0 {
                    local pos = `i'
                    continue, break
                }
            }
            if `pos' > 0 {
                local subpop_cond = substr("`rest'", 1, `pos' - 1)
                local subpop_cond = strtrim("`subpop_cond'")
                if substr("`subpop_cond'", 1, 3) == "if " {
                    local subpop_cond = substr("`subpop_cond'", 4, .)
                }
            }
        }
    }

    local model_if "`ifclause'"
    if `svy_with_subpop' == 1 {
        local model_if ""
    }

    *--- Parse trim() ----------------------------------------------
    local trimlo ""
    local trimhi ""
    local trimlabel ""
    if "`trim'" == "" {
        local trimlo 1
        local trimhi 99
        local trimlabel "1 99"
    }
    else if "`trim'" == "none" | "`trim'" == "None" | "`trim'" == "NONE" {
        local trimlo ""
        local trimhi ""
        local trimlabel "none"
    }
    else {
        local trim_norm : subinstr local trim "," " ", all
        local trim_norm = stritrim("`trim_norm'")
        tokenize "`trim_norm'"
        local trimlo "`1'"
        local trimhi "`2'"
        if "`trimlo'" == "" | "`trimhi'" == "" {
            di as error "trim() requires two numbers, e.g. trim(1 99), or trim(none)"
            exit 198
        }
        if `trimlo' < 0 | `trimhi' > 100 | `trimlo' >= `trimhi' {
            di as error "trim() bounds must be 0 <= lo < hi <= 100"
            exit 198
        }
        if `trimlo' == 0 & `trimhi' == 100 {
            local trimlo ""
            local trimhi ""
            local trimlabel "none"
        }
        else {
            local trimlabel "`trimlo' `trimhi'"
        }
    }

    local naturemode = 0
    if "`ciband'" != "" | "`nature'" != "" local naturemode = 1

    if `"`cibcolor'"' == "" local cibcolor "ltbluishgray"

    local cibalpha ""
    if "`cibopacity'" != "" {
        capture confirm number `cibopacity'
        if _rc {
            di as error "cibopacity() must be a number between 0 and 100"
            exit 198
        }
        if `cibopacity' < 0 | `cibopacity' > 100 {
            di as error "cibopacity() must be between 0 and 100"
            exit 198
        }
        local cibtrans = `cibopacity'
        local cibalpha "%`cibtrans'"
    }

    local cibcolor_full "`cibcolor'"
    if "`cibalpha'" != "" {
        if "`cibcolor'" == "ltbluishgray" {
            local cibcolor_full "234 242 250`cibalpha'"
        }
        else if "`cibcolor'" == "ltblue" {
            local cibcolor_full "173 216 230`cibalpha'"
        }
        else if "`cibcolor'" == "eltblue" {
            local cibcolor_full "110 150 200`cibalpha'"
        }
        else if "`cibcolor'" == "ebblue" {
            local cibcolor_full "130 200 220`cibalpha'"
        }
        else if "`cibcolor'" == "bluishgray" {
            local cibcolor_full "150 180 200`cibalpha'"
        }
        else if "`cibcolor'" == "gs14" {
            local cibcolor_full "230 230 230`cibalpha'"
        }
        else if "`cibcolor'" == "gs13" {
            local cibcolor_full "210 210 210`cibalpha'"
        }
        else if "`cibcolor'" == "gs12" {
            local cibcolor_full "190 190 190`cibalpha'"
        }
        else {
            local cibcolor_full "`cibcolor'`cibalpha'"
        }
    }

    if "`lwidth'"     == "" local lwidth "medthick"
    if "`cilwidth'"   == "" local cilwidth "medthin"

    if "`lcolor'" == "" {
        if "`ciband'" != "" {
            if "`cibcolor'" == "ltbluishgray" local lcolor "eltblue"
            else if "`cibcolor'" == "ltblue"  local lcolor "eltblue"
            else if "`cibcolor'" == "bluishgray" local lcolor "eltblue"
            else if "`cibcolor'" == "ebblue"  local lcolor "eltblue"
            else if "`cibcolor'" == "gs14"    local lcolor "gs6"
            else if "`cibcolor'" == "gs13"    local lcolor "gs5"
            else if "`cibcolor'" == "gs12"    local lcolor "gs4"
            else                              local lcolor "eltblue"
        }
        else if `naturemode' == 1 {
            local lcolor "eltblue"
        }
        else {
            local lcolor "black"
        }
    }

    if "`cicolor'"    == "" {
        if `naturemode' == 1 local cicolor "eltblue"
        else                local cicolor "black"
    }

    if "`name'" == "" {
        if "`user_name'" != "" {
            local name "`user_name'"
        }
        else {
            local name "rcsplot"
        }
    }

    if "`histcolor'"  == "" {
        if `naturemode' == 1 local histcolor "gs14"
        else                local histcolor "white"
    }
    if "`histytitle'" == "" local histytitle "Percent"

    local axistext "gs4"
    if `naturemode' != 1 local axistext ""

    local svyprefix ""
    if "`svy'" != "" {
        if "`svyopts'" != "" {
            local svyprefix "svy `svyopts':"
        }
        else {
            local svyprefix "svy:"
        }
    }

    *--- Parse inrange ---------------------------------------------
    local inrange_user = 0
    if "`inrange'" != "" {
        local inrange_user = 1
        local inrange_norm : subinstr local inrange "," " ", all
        local inrange_norm = stritrim("`inrange_norm'")
        tokenize "`inrange_norm'"
        local range_lo "`1'"
        local range_hi "`2'"
        if "`range_lo'" == "" | "`range_hi'" == "" {
            di as error "inrange() requires two numbers: inrange(low high)"
            exit 198
        }
        if `range_lo' >= `range_hi' {
            di as error "inrange(low high): low must be less than high"
            exit 198
        }
    }

    *--- Parse saving() --------------------------------------------
    * Accepts: saving("file.gph"), saving("file.gph", replace),
    *          saving(file.gph), saving(file.gph, replace)
    local sv_file ""
    local sv_opts ""
    if "`saving'" != "" {
        local sv_full "`saving'"
        * Strip outer quotes if present
        if substr("`sv_full'", 1, 1) == `"""' {
            local sv_full = substr("`sv_full'", 2, strlen("`sv_full'") - 2)
        }
        if ustrpos("`sv_full'", ",") > 0 {
            tokenize "`sv_full'", parse(",")
            local sv_file "`1'"
            local sv_opts "`3'"
            local sv_file = strtrim("`sv_file'")
            local sv_opts = strtrim("`sv_opts'")
        }
        else {
            local sv_file "`sv_full'"
            local sv_file = strtrim("`sv_file'")
        }
    }

    capture drop __rcs_*
    capture drop __df __yhat __lo __hi __lo_l __hi_l
    capture restore

    preserve
    capture noisily {

        local base_cond "`ifclause'"
        if `svy_with_subpop' == 1 {
            if "`subpop_cond'" != "" {
                if "`userif_cond'" != "" {
                    local base_cond "if (`subpop_cond') & (`userif_cond')"
                }
                else {
                    local base_cond "if `subpop_cond'"
                }
            }
        }

        local trim_p_lo = .
        local trim_p_hi = .
        local n_dropped = 0
        local n_kept = _N
        if "`trimlo'" != "" {
            quietly _pctile `xvar_raw' `base_cond', p(`trimlo' `trimhi')
            local trim_p_lo = r(r1)
            local trim_p_hi = r(r2)
        }

        if `inrange_user' == 0 {
            if "`trimlo'" != "" {
                local range_lo = `trim_p_lo'
                local range_hi = `trim_p_hi'
            }
            else {
                quietly summarize `xvar_raw' `base_cond'
                local range_lo = r(min)
                local range_hi = r(max)
            }
        }

        if "`trimlo'" != "" & `svy_with_subpop' == 0 {
            if "`userif_cond'" != "" {
                quietly drop if `xvar_raw' < `trim_p_lo' & (`userif_cond')
                quietly drop if `xvar_raw' > `trim_p_hi' & (`userif_cond')
            }
            else {
                quietly drop if `xvar_raw' < `trim_p_lo'
                quietly drop if `xvar_raw' > `trim_p_hi'
            }
            local n_kept = _N
        }
        else if "`trimlo'" != "" & `svy_with_subpop' == 1 {
            local trim_add "(`xvar_raw' >= `trim_p_lo' & `xvar_raw' <= `trim_p_hi')"
            if "`subpop_cond'" != "" {
                local subpop_cond "(`subpop_cond') & `trim_add'"
            }
            else {
                local subpop_cond "`trim_add'"
            }
            local svyopts ", subpop(if `subpop_cond')"
            local svyprefix "svy `svyopts':"
            local trimlabel "`trimlo' `trimhi'"

            if "`userif_cond'" != "" {
                local base_cond "if (`subpop_cond') & (`userif_cond')"
            }
            else {
                local base_cond "if `subpop_cond'"
            }
        }

        if `knots' == 3 local pcts "10 50 90"
        else if `knots' == 4 local pcts "5 35 65 95"
        else if `knots' == 5 local pcts "5 27.5 50 72.5 95"
        else if `knots' == 6 local pcts "5 23 41 59 77 95"
        else if `knots' == 7 local pcts "2.5 18.33 34.17 50 65.83 81.67 97.5"
        else {
            di as error "knots() must be between 3 and 7"
            exit 198
        }

        quietly _pctile `xvar_raw' `base_cond', p(`pcts')
        local knotlist ""
        local knotlist_fmt ""
        forvalues i = 1/`knots' {
            local kv = r(r`i')
            local knotlist "`knotlist' `kv'"
            local kv_fmt : di %8.2f `kv'
            local kv_fmt = strtrim("`kv_fmt'")
            local knotlist_fmt "`knotlist_fmt' `kv_fmt'"
        }

        mkspline __rcs_ = `xvar_raw', cubic knots(`knotlist')
        quietly ds __rcs_*
        local nterms : word count `r(varlist)'

        if "`cmd'" == "stcox" {
            quietly `svyprefix' `cmd' __rcs_* `covars' `model_if' `weight'
        }
        else {
            quietly `svyprefix' `cmd' `depvar' __rcs_* `covars' `model_if' `weight'
        }

        local reg_n = e(N)

        local aic_val .
        local bic_val .
        capture local aic_val = e(aic)
        if _rc | missing(`aic_val') {
            capture local ll = e(ll)
            capture local k = e(k)
            if _rc == 0 & !missing(`ll') & !missing(`k') {
                local aic_val = -2*`ll' + 2*`k'
                local bic_val = -2*`ll' + `k'*ln(`reg_n')
            }
        }
        capture local bic_val = e(bic)
        if _rc | missing(`bic_val') {
            capture local ll = e(ll)
            capture local k = e(k)
            if _rc == 0 & !missing(`ll') & !missing(`k') {
                local aic_val = -2*`ll' + 2*`k'
                local bic_val = -2*`ll' + `k'*ln(`reg_n')
            }
        }

        local teststr ""
        forvalues i = 1/`nterms' {
            local teststr "`teststr' (__rcs_`i' = 0)"
        }
        quietly test `teststr'
        local chi2 = r(chi2)
        local p_overall = r(p)

        if `nterms' >= 2 {
            local teststr2 ""
            forvalues i = 2/`nterms' {
                local teststr2 "`teststr2' (__rcs_`i' = 0)"
            }
            quietly test `teststr2'
            local p_nonlin = r(p)
        }
        else {
            local p_nonlin = .
        }

        quietly summarize `xvar_raw' `base_cond'
        local minx = r(min)
        local maxx = r(max)

        if "`refval'" == "" {
            quietly summarize `xvar_raw' `base_cond', detail
            local refval_use = r(p50)
        }
        else local refval_use = `refval'

        local refval_fmt : di %8.2f `refval_use'
        local refval_fmt = strtrim("`refval_fmt'")
        local range_lo_fmt : di %8.2f `range_lo'
        local range_lo_fmt = strtrim("`range_lo_fmt'")
        local range_hi_fmt : di %8.2f `range_hi'
        local range_hi_fmt = strtrim("`range_hi_fmt'")

        tempname __refframe
        capture frame drop `__refframe'
        frame create `__refframe'
        frame `__refframe' {
            quietly set obs 1
            quietly gen `xvar_raw' = `refval_use'
            quietly mkspline __ref_ = `xvar_raw', cubic knots(`knotlist')
            forvalues i = 1/`nterms' {
                local ref_s`i' = __ref_`i'[1]
            }
        }
        frame drop `__refframe'

        if `inrange_user' == 1 {
            if `range_lo' < `minx' local range_lo = `minx'
            if `range_hi' > `maxx' local range_hi = `maxx'
            local range_lo_fmt : di %8.2f `range_lo'
            local range_lo_fmt = strtrim("`range_lo_fmt'")
            local range_hi_fmt : di %8.2f `range_hi'
            local range_hi_fmt = strtrim("`range_hi_fmt'")
        }

        local expr ""
        forvalues i = 1/`nterms' {
            if `i' == 1 local expr "_b[__rcs_`i']*(__rcs_`i' - `ref_s`i'')"
            else local expr "`expr' + _b[__rcs_`i']*(__rcs_`i' - `ref_s`i'')"
        }

        quietly predictnl __df = `expr', ci(__lo_l __hi_l) level(`level')

        if "`exp'" == "yes" {
            quietly {
                gen __yhat = exp(__df)
                gen __lo   = exp(__lo_l)
                gen __hi   = exp(__hi_l)
            }
        }
        else {
            quietly {
                gen __yhat = __df
                gen __lo   = __lo_l
                gen __hi   = __hi_l
            }
        }

        quietly {
            gen __inrange = (`xvar_raw' >= `range_lo' & `xvar_raw' <= `range_hi')
            replace __yhat = . if __inrange == 0
            replace __lo   = . if __inrange == 0
            replace __hi   = . if __inrange == 0
            drop __inrange
        }

        if `p_overall' < 0.001 {
            local p_overall_txt "<0.001"
            local p_overall_op " "
        }
        else {
            local p_overall_txt : di %5.3f `p_overall'
            local p_overall_txt = strtrim("`p_overall_txt'")
            local p_overall_op "= "
        }
        if `p_nonlin' == . | `p_nonlin' >= . {
            local p_nonlin_txt "."
            local p_nonlin_op "= "
        }
        else if `p_nonlin' < 0.001 {
            local p_nonlin_txt "<0.001"
            local p_nonlin_op " "
        }
        else {
            local p_nonlin_txt : di %5.3f `p_nonlin'
            local p_nonlin_txt = strtrim("`p_nonlin_txt'")
            local p_nonlin_op "= "
        }

        quietly {
            _pctile __yhat if !missing(__yhat), p(2 98)
            local yhat_p2  = r(r1)
            local yhat_p98 = r(r2)
            _pctile __hi if !missing(__hi), p(2 98)
            local yhi_p98 = r(r2)
            _pctile __lo if !missing(__lo), p(2 98)
            local ylo_p2 = r(r1)
        }

        local y_vis_lo = min(`yhat_p2', `ylo_p2')
        local y_vis_hi = max(`yhat_p98', `yhi_p98')
        local y_vis_rng = `y_vis_hi' - `y_vis_lo'

        if ustrpos("`yscale'", "log") > 0 {
            local y1 = exp(0.92*ln(`y_vis_hi') + 0.08*ln(`y_vis_lo'))
            local y2 = exp(0.84*ln(`y_vis_hi') + 0.16*ln(`y_vis_lo'))
        }
        else {
            local y1 = `y_vis_hi' - 0.08*`y_vis_rng'
            local y2 = `y_vis_hi' - 0.16*`y_vis_rng'
        }
        local xmid = (`range_lo' + `range_hi')/2

        if "`debug'" != "" {
            di as text _n "=== DEBUG ==="
            di as text "  user_name  = `user_name'"
            di as text "  options    = `options'"
            di as text "  name       = `name'"
            di as text "  sv_file    = `sv_file'"
            di as text "  sv_opts    = `sv_opts'"
            di as text "  subpop_cond= `subpop_cond'"
            di as text "  base_cond  = `base_cond'"
            di as text "  svyopts    = `svyopts'"
            di as text "  svyprefix  = `svyprefix'"
            di as text "  trim       = `trimlabel'"
            di as text "  range_lo   = `range_lo'"
            di as text "  range_hi   = `range_hi'"
            di as text "  knotlist   = `knotlist'"
            di as text "  refval     = `refval_use'"
            di as text "  reg_N      = `reg_n'"
            di as text "  AIC        = `aic_val'"
            di as text "  BIC        = `bic_val'"
            di as text "  cibopacity = `cibopacity'"
            di as text "  cibalpha   = `cibalpha'"
            di as text "  cibcolor   = `cibcolor'"
            di as text "  cibcolor_full = `cibcolor_full'"
            di as text "  pvaltext   = `pvaltext'"
            quietly summarize __df if abs(`xvar_raw' - `refval_use') < 0.001
            di as text "  __df at ref= " %10.6f r(mean)
            di as text "  OR at ref  = " %10.6f exp(r(mean))
        }

        local twopts "xtitle(`"`xtitle'"')"
        local twopts "`twopts' ytitle(`"`ytitle'"', axis(1))"
        if `"`title'"' != ""    local twopts "`twopts' title(`"`title'"')"
        if `"`notes'"' != ""    local twopts "`twopts' note(`"`notes'"')"

        if `naturemode' == 1 {
            local twopts "`twopts' ytitle(, axis(1) color(`axistext'))"
            local twopts "`twopts' xtitle(, color(`axistext'))"
        }

        local userxscale "`xscale'"

        if `"`xlabel'"' != "" {
            local xlab_full "`xlabel'"
            local xlab_nums "`xlab_full'"
            local xlab_opts ""
            if ustrpos("`xlab_full'", ",") > 0 {
                tokenize "`xlab_full'", parse(",")
                local xlab_nums "`1'"
                local xlab_opts "`3'"
                local xlab_opts = strtrim("`xlab_opts'")
            }
            if !ustrpos("`xlab_opts'", "grid") {
                if `naturemode' == 1 {
                    if !ustrpos("`xlab_opts'", "color") {
                        if "`xlab_opts'" != "" {
                            local twopts "`twopts' xlabel(`xlab_nums', `xlab_opts' nogrid labcolor(`axistext'))"
                        }
                        else {
                            local twopts "`twopts' xlabel(`xlab_nums', nogrid labcolor(`axistext'))"
                        }
                    }
                    else {
                        if "`xlab_opts'" != "" {
                            local twopts "`twopts' xlabel(`xlab_nums', `xlab_opts' nogrid)"
                        }
                        else {
                            local twopts "`twopts' xlabel(`xlab_nums', nogrid)"
                        }
                    }
                }
                else {
                    if "`xlab_opts'" != "" {
                        local twopts "`twopts' xlabel(`xlab_nums', `xlab_opts' nogrid)"
                    }
                    else {
                        local twopts "`twopts' xlabel(`xlab_nums', nogrid)"
                    }
                }
            }
            else {
                if "`xlab_opts'" != "" {
                    local twopts "`twopts' xlabel(`xlab_nums', `xlab_opts')"
                }
                else {
                    local twopts "`twopts' xlabel(`xlab_nums')"
                }
            }
        }
        else {
            local xrng = `range_hi' - `range_lo'
            local tick = .
            if `xrng' <= 1          local tick 0.1
            else if `xrng' <= 5     local tick 0.5
            else if `xrng' <= 10    local tick 1
            else if `xrng' <= 25    local tick 2
            else if `xrng' <= 50    local tick 5
            else if `xrng' <= 100   local tick 10
            else if `xrng' <= 250   local tick 25
            else if `xrng' <= 500   local tick 50
            else if `xrng' <= 1000  local tick 100
            else                    local tick 200
            local start = ceil(`range_lo'/`tick')*`tick'
            local end   = floor(`range_hi'/`tick')*`tick'
            if `start' <= `end' {
                if `naturemode' == 1 {
                    local twopts "`twopts' xlabel(`start'(`tick')`end', nogrid labcolor(`axistext'))"
                }
                else {
                    local twopts "`twopts' xlabel(`start'(`tick')`end', nogrid)"
                }
            }
        }

        if "`userxscale'" == "" {
            local twopts "`twopts' xscale(range(`range_lo' `range_hi'))"
        }
        else {
            if !ustrpos("`userxscale'", "range") {
                local twopts "`twopts' xscale(`userxscale' range(`range_lo' `range_hi'))"
            }
            else {
                local twopts "`twopts' xscale(`userxscale')"
            }
        }

        if "`histogram'" != "" {
            if `"`ylabel'"' != "" {
                local ylab_full "`ylabel'"
                local ylab_nums "`ylab_full'"
                local ylab_opts ""
                if ustrpos("`ylab_full'", ",") > 0 {
                    tokenize "`ylab_full'", parse(",")
                    local ylab_nums "`1'"
                    local ylab_opts "`3'"
                    local ylab_opts = strtrim("`ylab_opts'")
                }
                if !ustrpos("`ylab_opts'", "format") {
                    local ylab_opts "`ylab_opts' format(%4.1f)"
                }
                if !ustrpos("`ylab_opts'", "grid") {
                    local ylab_opts "`ylab_opts' nogrid"
                }
                if `naturemode' == 1 {
                    if !ustrpos("`ylab_opts'", "labcolor") {
                        local ylab_opts "`ylab_opts' labcolor(`axistext')"
                    }
                }
                local ylab_opts = strtrim("`ylab_opts'")
                local twopts "`twopts' ylabel(`ylab_nums', axis(1) `ylab_opts')"
            }
            else {
                if `naturemode' == 1 {
                    local twopts "`twopts' ylabel(, axis(1) format(%4.1f) nogrid labcolor(`axistext'))"
                }
                else {
                    local twopts "`twopts' ylabel(, axis(1) format(%4.1f) nogrid)"
                }
            }

            if `"`yscale'"' != "" {
                local ys_full "`yscale'"
                local ys_base "`ys_full'"
                local ys_opts ""
                if ustrpos("`ys_full'", ",") > 0 {
                    tokenize "`ys_full'", parse(",")
                    local ys_base "`1'"
                    local ys_opts "`3'"
                    local ys_opts = strtrim("`ys_opts'")
                }
                if "`ys_opts'" != "" {
                    local twopts "`twopts' yscale(axis(1) `ys_base' `ys_opts')"
                }
                else {
                    local twopts "`twopts' yscale(axis(1) `ys_base')"
                }
            }

            if `naturemode' == 1 {
                local twopts "`twopts' ylabel(, axis(2) nogrid labcolor(`axistext'))"
            }
            else {
                local twopts "`twopts' ylabel(, axis(2) nogrid)"
            }
            local twopts "`twopts' ytitle(`"`histytitle'"', axis(2) orientation(vertical) height(0) margin(zero))"
            local twopts "`twopts' yscale(axis(2) range(0 100) noextend)"
        }
        else {
            if `"`ylabel'"' != "" {
                local ylab_full "`ylabel'"
                local ylab_nums "`ylab_full'"
                local ylab_opts ""
                if ustrpos("`ylab_full'", ",") > 0 {
                    tokenize "`ylab_full'", parse(",")
                    local ylab_nums "`1'"
                    local ylab_opts "`3'"
                    local ylab_opts = strtrim("`ylab_opts'")
                }
                if !ustrpos("`ylab_opts'", "format") {
                    local ylab_opts "`ylab_opts' format(%4.1f)"
                }
                if !ustrpos("`ylab_opts'", "grid") {
                    local ylab_opts "`ylab_opts' nogrid"
                }
                if `naturemode' == 1 {
                    if !ustrpos("`ylab_opts'", "labcolor") {
                        local ylab_opts "`ylab_opts' labcolor(`axistext')"
                    }
                }
                local ylab_opts = strtrim("`ylab_opts'")
                local twopts "`twopts' ylabel(`ylab_nums', `ylab_opts')"
            }
            else {
                if `naturemode' == 1 {
                    local twopts "`twopts' ylabel(, format(%4.1f) nogrid labcolor(`axistext'))"
                }
                else {
                    local twopts "`twopts' ylabel(, format(%4.1f) nogrid)"
                }
            }
            if `"`yscale'"' != ""   local twopts "`twopts' yscale(`yscale')"
        }

        if `"`plotregion'"' == "" {
            if `naturemode' == 1 {
                local twopts "`twopts' plotregion(style(none) color(white))"
            }
            else {
                local twopts "`twopts' plotregion(style(none))"
            }
        }
        else {
            local twopts "`twopts' plotregion(`plotregion')"
        }

        if `naturemode' == 1 {
            if `"`graphregion'"' == "" {
                local twopts "`twopts' graphregion(color(white))"
            }
            else {
                local twopts "`twopts' graphregion(`graphregion')"
            }
        }
        else {
            if `"`graphregion'"' != "" local twopts "`twopts' graphregion(`graphregion')"
        }

        if `"`xticks'"' != ""   local twopts "`twopts' xticks(`xticks')"
        if `"`yticks'"' != ""   local twopts "`twopts' yticks(`yticks')"
        if `"`legend'"' != ""   local twopts "`twopts' legend(`legend')"
        else                    local twopts "`twopts' legend(off)"

        local twopts "`twopts' name(`name', replace)"

        if `"`pvalues'"' != "" {
            tokenize "`pvalues'"
            local tx1 "`1'"
            local ty1 "`2'"
            local tx2 "`3'"
            local ty2 "`4'"
            if "`tx2'" == "" {
                local tx2 "`tx1'"
                local ty2 "`ty1'"
            }
            if `naturemode' == 1 {
                local twopts "`twopts' text(`ty1' `tx1' `"{it:P} overall `p_overall_op'`p_overall_txt'"', placement(center) color(`axistext'))"
                local twopts "`twopts' text(`ty2' `tx2' `"{it:P} non-linear `p_nonlin_op'`p_nonlin_txt'"', placement(center) color(`axistext'))"
            }
            else {
                local twopts "`twopts' text(`ty1' `tx1' `"{it:P} overall `p_overall_op'`p_overall_txt'"', placement(center))"
                local twopts "`twopts' text(`ty2' `tx2' `"{it:P} non-linear `p_nonlin_op'`p_nonlin_txt'"', placement(center))"
            }
        }
        else if "`pvaltext'" != "" {
            if `naturemode' == 1 {
                local twopts "`twopts' text(`y1' `xmid' `"{it:P} overall `p_overall_op'`p_overall_txt'"', placement(center) color(`axistext'))"
                local twopts "`twopts' text(`y2' `xmid' `"{it:P} non-linear `p_nonlin_op'`p_nonlin_txt'"', placement(center) color(`axistext'))"
            }
            else {
                local twopts "`twopts' text(`y1' `xmid' `"{it:P} overall `p_overall_op'`p_overall_txt'"', placement(center))"
                local twopts "`twopts' text(`y2' `xmid' `"{it:P} non-linear `p_nonlin_op'`p_nonlin_txt'"', placement(center))"
            }
        }

        if "`options'" != "" local twopts "`twopts' `options'"

        if "`ciband'" != "" {
            if "`histogram'" != "" {
                twoway ///
                    (rarea __lo __hi `xvar_raw' ///
                        if inrange(`xvar_raw', `range_lo', `range_hi'), ///
                        sort color(`"`cibcolor_full'"') lwidth(none) yaxis(1)) ///
                    (line __yhat `xvar_raw' ///
                        if inrange(`xvar_raw', `range_lo', `range_hi'), ///
                        sort lcolor(`lcolor') lwidth(`lwidth') yaxis(1)) ///
                    (histogram `xvar_raw' ///
                        if inrange(`xvar_raw', `range_lo', `range_hi'), ///
                        percent bin(`bins') yaxis(2) fcolor(`histcolor') ///
                        lcolor(gs10) lwidth(vthin)),                      ///
                    `twopts'
            }
            else {
                twoway ///
                    (rarea __lo __hi `xvar_raw' ///
                        if inrange(`xvar_raw', `range_lo', `range_hi'), ///
                        sort color(`"`cibcolor_full'"') lwidth(none) yaxis(1)) ///
                    (line __yhat `xvar_raw' ///
                        if inrange(`xvar_raw', `range_lo', `range_hi'), ///
                        sort lcolor(`lcolor') lwidth(`lwidth') yaxis(1)), ///
                    `twopts'
            }
        }
        else {
            if "`histogram'" != "" {
                twoway ///
                    (line __yhat `xvar_raw' ///
                        if inrange(`xvar_raw', `range_lo', `range_hi'), ///
                        sort lcolor(`lcolor') lwidth(`lwidth') yaxis(1)) ///
                    (line __lo   `xvar_raw' ///
                        if inrange(`xvar_raw', `range_lo', `range_hi'), ///
                        sort lcolor(`cicolor') lpattern(dash) lwidth(`cilwidth') yaxis(1)) ///
                    (line __hi   `xvar_raw' ///
                        if inrange(`xvar_raw', `range_lo', `range_hi'), ///
                        sort lcolor(`cicolor') lpattern(dash) lwidth(`cilwidth') yaxis(1)) ///
                    (histogram `xvar_raw' ///
                        if inrange(`xvar_raw', `range_lo', `range_hi'), ///
                        percent bin(`bins') yaxis(2) fcolor(`histcolor') ///
                        lcolor(gs10) lwidth(vthin)),                      ///
                    `twopts'
            }
            else {
                twoway ///
                    (line __yhat `xvar_raw' ///
                        if inrange(`xvar_raw', `range_lo', `range_hi'), ///
                        sort lcolor(`lcolor') lwidth(`lwidth') yaxis(1)) ///
                    (line __lo   `xvar_raw' ///
                        if inrange(`xvar_raw', `range_lo', `range_hi'), ///
                        sort lcolor(`cicolor') lpattern(dash) lwidth(`cilwidth') yaxis(1)) ///
                    (line __hi   `xvar_raw' ///
                        if inrange(`xvar_raw', `range_lo', `range_hi'), ///
                        sort lcolor(`cicolor') lpattern(dash) lwidth(`cilwidth') yaxis(1)), ///
                    `twopts'
            }
        }

        *--- Save the graph if saving() was given -------------------------
        if "`sv_file'" != "" {
            if "`sv_opts'" != "" {
                graph save "`sv_file'", `sv_opts'
            }
            else {
                graph save "`sv_file'", replace
            }
        }
        graph display `name'

        if missing(`aic_val') {
            local aic_txt "."
        }
        else {
            local aic_txt : di %12.2f `aic_val'
            local aic_txt = strtrim("`aic_txt'")
        }
        if missing(`bic_val') {
            local bic_txt "."
        }
        else {
            local bic_txt : di %12.2f `bic_val'
            local bic_txt = strtrim("`bic_txt'")
        }

        di as text _n "{hline 62}"
        di as text "Restricted Cubic Spline Model"
        if "`svy'" != "" {
            if "`svyopts'" != "" {
                di as text "  Estimator  : svy `svyopts': `cmd'"
            }
            else {
                di as text "  Estimator  : svy: `cmd'"
            }
        }
        else {
            di as text "  Command    : `cmd'"
        }
        di as text "  Outcome    : `depvar'"
        di as text "  Exposure   : `xvar_raw'"
        di as text "  Covariates : `covars'"
        if "`userif_cond'" != "" {
            di as text "  If         : " as result "`userif_cond'"
        }
        if "`svyopts'" != "" {
            di as text "  Svy opts   : " as result "`svyopts'"
        }
        di as text "  Knots      : `knots'"
        di as text "  Knots used : " as result "`knotlist_fmt'"
        di as text "  Terms      : `nterms'"
        di as text "  Reference  : " as result %8.2f `refval_use'
        di as text "  X range    : " as result %8.2f `range_lo' ///
            as text " to " as result %8.2f `range_hi'
        if `inrange_user' == 0 {
            di as text "  Range      : " as result "matched to trim window"
        }
        di as text "  P overall  : " as result "`p_overall_op'`p_overall_txt'"
        di as text "  P non-lin  : " as result "`p_nonlin_op'`p_nonlin_txt'"
        di as text "  AIC        : " as result "`aic_txt'"
        di as text "  BIC        : " as result "`bic_txt'"
        if "`histogram'" != "" {
            di as text "  Histogram  : yes (bins=`bins')"
        }
        if "`ciband'" != "" {
            if "`cibopacity'" != "" {
                di as text "  CI style   : shaded band (`cibcolor', `cibopacity'% opaque)"
            }
            else {
                di as text "  CI style   : shaded band (`cibcolor')"
            }
        }
        if `naturemode' == 1 {
            di as text "  Style      : Nature Medicine"
        }
        if "`trimlabel'" == "none" {
            di as text "  Trim       : none, N = " ///
                as result %8.0f `reg_n'
        }
        else {
            di as text "  Trim       : " as result "`trimlabel'%" ///
                as text ", N = " as result %8.0f `reg_n'
        }
        di as text "{hline 62}"
    }

    capture restore
end