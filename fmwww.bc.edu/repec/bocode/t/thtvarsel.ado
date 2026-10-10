*! thtvarsel 1.0.0  06oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Joint selection of the lag order p, the delay d and the threshold gamma for
*! a threshold VAR, with the linear VAR printed beside it so the first
*! question -- does the threshold earn its place -- can be answered.
*! Tsay, R. S. (1998) JASA 93:1188-1202, doi:10.1080/01621459.1998.10473779
*! Hubrich, K. and T. Terasvirta (2013) Advances in Econometrics 32:273-326,
*!   doi:10.1108/S0731-9053(2013)0000031008

program define thtvarsel, rclass sortpreserve
    version 15

    syntax varlist(numeric ts min=2) [if] [in] , ///
        [ PSearch(numlist integer >0 sort)       ///
          DSearch(numlist integer >0 sort)       ///
          THVar(varname numeric ts)              ///
          IC(string)                             ///
          TRIM(real 0.15)                        ///
          GRIDn(integer 0)                       ///
          MINOBS(integer 0)                      ///
          noCONStant                             ///
          FIT                                    ///
          GRaph                                  ///
          SAVing(string asis) ]

    capture tsset
    if _rc {
        display as error "{bf:thtvarsel} requires the data to be {bf:tsset}"
        exit 459
    }
    local timevar "`r(timevar)'"

    if "`psearch'" == "" local psearch 1/4
    capture numlist "`psearch'", integer range(>0) sort
    if _rc {
        display as error "{bf:psearch()} takes a numlist of lag orders"
        exit 198
    }
    local plist "`r(numlist)'"
    local np : word count `plist'
    local pmax 0
    foreach p of local plist {
        if `p' > `pmax' local pmax = `p'
    }
    if `pmax' > 12 {
        display as error "{bf:psearch()} above 12 lags: the fixed sample would be"
        display as error "very short and every criterion in the table would be"
        display as error "computed on it. Reduce the range."
        exit 198
    }

    if "`thvar'" != "" & "`dsearch'" != "" {
        display as error "{bf:dsearch()} searches the DELAY of a self-exciting"
        display as error "threshold variable; it cannot be combined with an"
        display as error "exogenous {bf:thvar()}, whose timing you have fixed"
        exit 198
    }
    if "`thvar'" == "" {
        if "`dsearch'" == "" local dsearch 1/`pmax'
        capture numlist "`dsearch'", integer range(>0) sort
        if _rc {
            display as error "{bf:dsearch()} takes a numlist of delays"
            exit 198
        }
        local dlist "`r(numlist)'"
    }
    else local dlist 0
    local nd : word count `dlist'
    local dmax 0
    foreach d of local dlist {
        if `d' > `dmax' local dmax = `d'
    }
    if `dmax' > `pmax' {
        display as error "a delay of `dmax' exceeds the largest lag order `pmax'."
        display as error "The threshold variable would reach further back than"
        display as error "the model's own lags, so the fixed sample would be set"
        display as error "by the delay rather than by the model. Raise"
        display as error "{bf:psearch()} or lower {bf:dsearch()}."
        exit 198
    }

    if "`ic'" == "" local ic bic
    local ic = lower("`ic'")
    if !inlist("`ic'", "aic", "bic", "hqic", "lndet") {
        display as error "{bf:ic()} must be aic, bic, hqic or lndet"
        exit 198
    }
    local whichic = cond("`ic'"=="aic", 6, cond("`ic'"=="bic", 7, ///
                    cond("`ic'"=="hqic", 8, 4)))
    if `trim' <= 0 | `trim' >= 0.5 {
        display as error "{bf:trim()} must be in (0, 0.5)"
        exit 198
    }
    local hasconsn = cond("`constant'"=="", 1, 0)

    * ------------------------------------------------ the FIXED sample
    local yvars `varlist'
    local k : word count `yvars'
    marksample touse
    markout `touse' `yvars'

    local wavars ""
    local wanames ""
    forvalues j = 1/`pmax' {
        foreach v of local yvars {
            tempvar wa`j'_`v'
            quietly generate double `wa`j'_`v'' = L`j'.`v'
            local wavars "`wavars' `wa`j'_`v''"
            local wanames "`wanames' L`j'.`v'"
            markout `touse' `wa`j'_`v''
        }
    }

    local qavars ""
    local qanames ""
    if "`thvar'" != "" {
        tempvar qa0
        quietly generate double `qa0' = `thvar'
        local qavars "`qa0'"
        local qanames "`thvar'"
        markout `touse' `qa0'
    }
    else {
        local first : word 1 of `yvars'
        foreach d of local dlist {
            tempvar qa`d'
            quietly generate double `qa`d'' = L`d'.`first'
            local qavars "`qavars' `qa`d''"
            local qanames "`qanames' L`d'.`first'"
            markout `touse' `qa`d''
        }
    }

    quietly count if `touse'
    local n = r(N)
    local kwmax = `pmax' * `k' + `hasconsn'
    if `n' < 4 * `kwmax' + 10 {
        display as error "only `n' observations on the fixed sample, against"
        display as error "`kwmax' regressors per equation at the largest lag order."
        display as error "Reduce {bf:psearch()}."
        exit 2001
    }

    * ------------------------------------------------ the grid
    _tk_drop
    capture noisily mata: tk_thtvarsel()
    if _rc {
        display as error "the selection engine failed (rc=" _rc ")"
        _tk_drop
        exit _rc
    }
    if __tk_tvsfail == 1 {
        display as error "no cell of the (p, d) grid admitted a threshold:"
        display as error "widen {bf:trim()} or reduce {bf:psearch()}"
        _tk_drop
        exit 459
    }

    tempname GR LIN
    matrix `GR'  = __tk_tvsgrid
    matrix `LIN' = __tk_tvslin
    local nn    = __tk_tvsn
    local brow  = __tk_tvsrow
    local bp    = __tk_tvsp
    local bd    = __tk_tvsd
    local bgam  = __tk_tvsgam
    tempname bgam_s
    scalar `bgam_s' = __tk_tvsgam
    local bval  = __tk_tvsval
    local lrow  = __tk_tvslrow
    local lval  = __tk_tvslval
    local lp    = __tk_tvslp
    _tk_drop

    local icname = upper("`ic'")
    local gcol = cond("`ic'"=="lndet", 4, `whichic')
    local lcol = cond("`ic'"=="lndet", 2, `whichic' - 2)

    * ------------------------------------------------ display
    display _n as text "Joint selection of lag order, delay and threshold for a TVAR" ///
        _col(62) as text "N = " as result %6.0f `nn'
    display as text "{hline 78}"
    display as text "  Equations" _col(34) as result "`yvars'"
    display as text "  Lag orders considered" _col(34) as result "`plist'"
    if "`thvar'" == "" {
        display as text "  Delays considered" _col(34) as result "`dlist'" ///
            as text "   (of `first')"
    }
    else {
        display as text "  Threshold variable" _col(34) as result "`thvar'" ///
            as text "   (fixed)"
    }
    display as text "  Criterion" _col(34) as result "`icname'"
    display as text "  Trimming" _col(34) as result %10.3f `trim'
    display as text "{hline 78}"
    display as text "  The sample is FIXED at the observations available with"
    display as text "  `pmax' lags, so every cell below is computed on the same"
    display as text "  `nn' observations. A criterion computed on a sample that"
    display as text "  grows as p falls is not comparable across p, and comparing"
    display as text "  it anyway reliably selects the smallest p."
    display as text "{hline 78}"

    display _n as text "Threshold VAR, cell by cell"
    display as text "{hline 78}"
    display as text "     p" _col(10) "d" _col(20) "gamma" _col(34) "ln|Sigma|" ///
        _col(48) "`icname'" _col(62) "split" _col(72) "grid"
    display as text "{hline 78}"
    forvalues r = 1/`=rowsof(`GR')' {
        local mk = cond(`r' == `brow', "*", " ")
        display as text "  `mk'" as result %3.0f `GR'[`r',1] ///
            _col(8) %4.0f `GR'[`r',2] _continue
        if `GR'[`r',4] < . {
            display as result _col(14) %12.6g `GR'[`r',3] ///
                _col(28) %13.6f `GR'[`r',4] _col(42) %13.3f `GR'[`r',`gcol'] ///
                _col(58) %8.0f `GR'[`r',10] as text "/" ///
                as result %-6.0f (`nn' - `GR'[`r',10]) ///
                _col(70) %8.0f `GR'[`r',9]
        }
        else display as text _col(14) %13s "(no admissible threshold)"
    }
    display as text "{hline 78}"
    display as text "  * minimises `icname'.  Selected p = " as result `bp' ///
        as text ", d = " as result `bd' as text ", gamma = " as result %10.6g `bgam'
    display as text "{hline 78}"

    display _n as text "Linear VAR on the SAME sample, for comparison"
    display as text "{hline 78}"
    display as text "     p" _col(16) "ln|Sigma|" _col(34) "`icname'"
    display as text "{hline 78}"
    forvalues r = 1/`=rowsof(`LIN')' {
        if `LIN'[`r',2] >= . continue
        local mk = cond(`r' == `lrow', "*", " ")
        display as text "  `mk'" as result %3.0f `LIN'[`r',1] ///
            _col(12) %13.6f `LIN'[`r',2] _col(30) %13.3f `LIN'[`r',`lcol']
    }
    display as text "{hline 78}"
    local gain = `lval' - `bval'
    display as text "  best linear `icname'" _col(40) as result %14.3f `lval' ///
        as text "   at p = " as result `lp'
    display as text "  best threshold `icname'" _col(40) as result %14.3f `bval'
    display as text "  difference (linear minus threshold)" _col(40) as result %14.3f `gain'
    display as text "{hline 78}"
    if `gain' > 0 {
        display as text "  The threshold model is preferred by `icname'."
        display as text "  That is a MODEL-SELECTION statement, not a test. For a"
        display as text "  p-value, refit with {bf:thtvar, test} at the selected"
        display as text "  (p, d) -- and read the warning it prints, because the"
        display as text "  specification was chosen here."
    }
    else {
        display as text "  The LINEAR VAR is preferred by `icname' at p = `lp'."
        display as text "  The threshold does not pay for its extra parameters on"
        display as text "  this sample. Reporting a TVAR anyway would be reporting"
        display as text "  a specification the criterion rejected: fit {bf:var}"
        display as text "  instead, or say explicitly why the criterion is being"
        display as text "  overruled."
    }
    display as text "{hline 78}"
    display as text "  WHAT THIS TABLE IS NOT. Choosing (p, d, gamma) by minimising"
    display as text "  a criterion is a search over `=rowsof(`GR')' cells, and no"
    display as text "  p-value reported afterwards knows about it. Report the whole"
    display as text "  table, and say so if the conclusion holds only at the"
    display as text "  selected cell. The criteria also disagree by construction:"
    display as text "  AIC over-selects and BIC under-selects, so run both and"
    display as text "  report whether the choice changed."
    display as text "{hline 78}"

    * ------------------------------------------------ graph
    if "`graph'" != "" {
        preserve
            quietly {
                clear
                svmat double `GR', names(col)
                keep if c4 < .
                rename c1 pord
                rename c2 dly
                rename c`gcol' crit
            }
            local pl ""
            local lg ""
            local i 0
            quietly levelsof dly, local(dd)
            foreach d of local dd {
                local ++i
                local pl `pl' (connected crit pord if dly == `d', sort msymbol(O))
                local lg `lg' `i' "d = `d'"
            }
            twoway `pl' , ytitle("`icname'") xtitle("lag order p")        ///
                title("`icname' over the (p, d) grid")                   ///
                subtitle("lower is better; a flat surface means the"      ///
                    " specification is not pinned down")                 ///
                legend(order(`lg') size(small))
            if `"`saving'"' != "" _tk_gsave `saving'
        restore
    }

    * ------------------------------------------------ optional fit
    local fitcmd ""
    if "`fit'" != "" {
        local ifin ""
        if `"`if'"' != "" local ifin `"`ifin' `if'"'
        if `"`in'"' != "" local ifin `"`ifin' `in'"'
        if "`thvar'" != "" {
            local fitcmd `"thtvar `yvars'`ifin', lags(`bp') thvar(`thvar') trim(`trim') `constant'"'
        }
        else {
            local fitcmd `"thtvar `yvars'`ifin', lags(`bp') delay(`bd') trim(`trim') `constant'"'
        }
        display _n as text "Fitting the selected cell"
        display as text "{hline 78}"
        display as text "  Running: " as result `"`fitcmd'"'
        display as text "{hline 78}"
        capture noisily `fitcmd'
        if _rc {
            display as error "  the fit failed (rc=" _rc ")"
            local fitcmd ""
        }
    }

    * ------------------------------------------------ return
    matrix colnames `GR' = p d gamma lndet ll aic bic hqic ngrid n1
    matrix colnames `LIN' = p lndet ll aic bic hqic
    return matrix grid   = `GR', copy
    return matrix linear = `LIN'
    return scalar N       = `nn'
    return scalar p       = `bp'
    return scalar delay   = `bd'
    return scalar gamma   = `bgam_s'
    return scalar crit    = `bval'
    return scalar crit_linear = `lval'
    return scalar p_linear    = `lp'
    return scalar gain    = `gain'
    return scalar n_cells = rowsof(`GR')
    return scalar trim    = `trim'
    return local  ic      "`ic'"
    return local  yvars   "`yvars'"
    return local  plist   "`plist'"
    return local  dlist   "`dlist'"
    return local  fitcmd  `"`fitcmd'"'
    return local  cmd     "thtvarsel"
end
