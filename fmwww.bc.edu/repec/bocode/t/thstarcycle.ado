*! thstarcycle 1.0.0  06oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Terasvirta's (1994) specification cycle for a smooth transition
*! autoregression, run end to end as one command.
*! Terasvirta (1994) JASA 89:208-218, doi:10.1080/01621459.1994.10476462
*! Luukkonen, Saikkonen & Terasvirta (1988) Biometrika 75:491-499,
*!   doi:10.1093/biomet/75.3.491
*! Lundbergh, Terasvirta & van Dijk (2003) JBES 21:104-121,
*!   doi:10.1198/073500102288618810
*! Eitrheim & Terasvirta (1996) J. Econometrics 74:59-75,
*!   doi:10.1016/0304-4076(95)01751-8
*!
*! The command runs the steps, prints one report, and leaves the fitted
*! thstar estimates in e() so that estat and predict work afterwards exactly
*! as if the user had typed thstar by hand -- which is the point: the cycle
*! should be reproducible one command at a time, and the report says which
*! commands those are.

program define thstarcycle, rclass sortpreserve
    version 15

    syntax varname(numeric ts) [if] [in] , ///
        [ MAXAR(integer 6)                 ///
          ARIC(string)                     ///
          DELAY(numlist integer >0 sort)   ///
          CANDidates(varlist numeric ts)   ///
          ALPHA(real 0.05)                 ///
          ORDer(integer 3)                 ///
          TYPE(string)                     ///
          NGamma(integer 20)               ///
          NC(integer 25)                   ///
          noCONStant                       ///
          Level(cilevel)                   ///
          NOFIT ]

    capture tsset
    if _rc {
        display as error "{bf:thstarcycle} requires the data to be {bf:tsset}"
        exit 459
    }
    local timevar "`r(timevar)'"

    if `maxar' < 1 | `maxar' > 24 {
        display as error "{bf:maxar()} must be between 1 and 24"
        exit 198
    }
    if "`aric'" == "" local aric aic
    local aric = lower("`aric'")
    if !inlist("`aric'", "aic", "bic", "hqic") {
        display as error "{bf:aric()} must be aic, bic or hqic"
        exit 198
    }
    local aricn = cond("`aric'"=="aic", 4, cond("`aric'"=="bic", 5, 6))
    if `alpha' <= 0 | `alpha' >= 1 {
        display as error "{bf:alpha()} must be in (0,1)"
        exit 198
    }
    if `order' < 1 | `order' > 3 {
        display as error "{bf:order()} must be 1, 2 or 3"
        exit 198
    }
    if "`delay'" == "" local delay 1/`maxar'
    capture numlist "`delay'", integer range(>0) sort
    local dlist "`r(numlist)'"
    foreach d of local dlist {
        if `d' > `maxar' {
            display as error "{bf:delay(`d')} exceeds {bf:maxar(`maxar')}:"
            display as error "the transition variable cannot reach further back"
            display as error "than the longest lag the model considers"
            exit 198
        }
    }
    local hasconsn = cond("`constant'"=="", 1, 0)
    local alphan   = `alpha'
    local depv "`varlist'"
    * the fit must run on the user's own sample restriction, or the cycle
    * would select on one sample and estimate on another
    local ifin ""
    if `"`if'"' != "" local ifin `"`ifin' `if'"'
    if `"`in'"' != "" local ifin `"`ifin' `in'"'

    * ------------------------------------------------ the fixed sample
    * Every information criterion in step 1 is computed on the SAME sample --
    * the one available at maxar -- because a criterion computed on a sample
    * that grows as p falls is not comparable across p, and comparing it
    * anyway reliably picks the smallest p.
    marksample touse
    tempname LAG
    local lagvars ""
    forvalues j = 1/`maxar' {
        tempvar l`j'
        quietly generate double `l`j'' = L`j'.`depv'
        local lagvars "`lagvars' `l`j''"
        markout `touse' `l`j''
    }

    local candvars ""
    local candnames ""
    foreach d of local dlist {
        local candvars  "`candvars' `l`d''"
        local candnames "`candnames' L`d'.`depv'"
    }
    if "`candidates'" != "" {
        fvexpand `candidates' if `touse'
        local clist `r(varlist)'
        fvrevar `clist' if `touse'
        local cvars `r(varlist)'
        local candvars  "`candvars' `cvars'"
        local candnames "`candnames' `clist'"
        foreach v of local cvars {
            markout `touse' `v'
        }
    }
    local ncand : word count `candvars'

    quietly count if `touse'
    local nobs = r(N)
    if `nobs' < 4 * `maxar' + 20 {
        display as error "only `nobs' observations usable at {bf:maxar(`maxar')}"
        display as error "reduce {bf:maxar()} or use a longer series"
        exit 2001
    }

    * ------------------------------------------------ steps 1 to 4
    _tk_drop
    capture noisily mata: tk_thstarcycle()
    if _rc {
        display as error "the specification-cycle engine failed (rc=" _rc ")"
        _tk_drop
        exit _rc
    }
    local fail = __tk_scfail
    if `fail' != 0 {
        display as error cond(`fail'==1, ///
            "no AR order could be fitted on the common sample", ///
            "no candidate transition variable produced a usable test")
        _tk_drop
        exit 459
    }

    tempname AR LIN
    matrix `AR'  = __tk_scar
    matrix `LIN' = __tk_sclin
    local psel  = __tk_scp
    local cbest = __tk_sccand
    local minp  = __tk_scminp
    local fam   = __tk_scfam
    local famp  = __tk_scfamp
    local n     = __tk_scn
    _tk_drop

    local zname : word `cbest' of `candnames'
    local famname = cond(`fam'==1, "LSTAR", cond(`fam'==2, "ESTAR", "none indicated"))
    local fampname = cond(`famp'==1, "LSTAR", cond(`famp'==2, "ESTAR", "none"))

    * ------------------------------------------------ report, steps 1 to 4
    display _n as text "{hline 78}"
    display as text "Terasvirta (1994) specification cycle for a smooth transition AR"
    display as text "{hline 78}"
    display as text "  Series" _col(32) as result "`depv'"
    display as text "  Common sample" _col(32) as result %10.0f `n' ///
        as text "   (fixed at maxar = " as result `maxar' as text ")"
    display as text "  Candidates considered" _col(32) as result %10.0f `ncand'
    display as text "  alpha" _col(32) as result %10.3f `alpha'
    display as text "{hline 78}"

    display _n as text "Step 1. AR order, on a LINEAR model and a fixed sample"
    display as text "{hline 78}"
    display as text "     p" _col(12) "SSR" _col(26) "ll" _col(38) "AIC" ///
        _col(50) "BIC" _col(62) "HQIC"
    display as text "{hline 78}"
    forvalues i = 1/`maxar' {
        if `AR'[`i',1] >= . continue
        local mk = cond(`i' == `psel', "*", " ")
        display as text "  `mk'" as result %3.0f `i' ///
            _col(8) %13.5f `AR'[`i',2] _col(22) %11.3f `AR'[`i',3] ///
            _col(34) %11.3f `AR'[`i',4] _col(46) %11.3f `AR'[`i',5] ///
            _col(58) %11.3f `AR'[`i',6]
    }
    display as text "{hline 78}"
    display as text "  * minimises `=upper("`aric'")'.  Selected p = " as result `psel'
    display as text "  Choose p on a LINEAR model FIRST. If p is too small the"
    display as text "  omitted dynamics appear as nonlinearity and step 2 rejects"
    display as text "  for the wrong reason -- the commonest way to find a smooth"
    display as text "  transition that is not there. If AIC and BIC disagree, run"
    display as text "  the cycle at both and say whether the conclusion changed."

    display _n as text "Step 2. Linearity against STAR, candidate by candidate"
    display as text "  (order-`order' Taylor LM; df are the RANK increase, not a"
    display as text "   column count, because a self-exciting candidate is itself"
    display as text "   a regressor and the interaction block is rank deficient)"
    display as text "{hline 78}"
    display as text "  candidate" _col(28) "LM3 F" _col(40) "df" _col(50) "p"
    display as text "{hline 78}"
    forvalues c = 1/`ncand' {
        local nm : word `c' of `candnames'
        local mk = cond(`c' == `cbest', "+", " ")
        display as text "  `mk'" _continue
        display as text %-22s abbrev("`nm'", 22) _continue
        if `LIN'[`c',1] < . {
            display as result _col(26) %11.4f `LIN'[`c',1] ///
                _col(38) %8.0f `LIN'[`c',2] _col(46) %12.4f `LIN'[`c',3]
        }
        else display as text _col(26) %11s "(not estimable)"
    }
    display as text "{hline 78}"
    display as text "  + smallest linearity p-value"

    local reject = (`minp' <= `alpha')
    display _n as text "Step 3. The transition variable"
    display as text "{hline 78}"
    if !`reject' {
        display as text "  Smallest linearity p-value" _col(44) as result %12.4f `minp'
        display as text "  at" _col(44) as result "`zname'"
        display as text "{hline 78}"
        display as error "  LINEARITY IS NOT REJECTED at alpha = " %4.2f `alpha' "."
        display as text ""
        display as text "  The cycle STOPS here. A linear AR(`psel') is the model."
        display as text "  Steps 4 to 7 would be fitting a transition function to"
        display as text "  noise: the transition parameters are not identified under"
        display as text "  this null, so their standard errors would be meaningless"
        display as text "  and the fit would look better only because it has more"
        display as text "  parameters."
        display as text ""
        display as text "  What to do instead: report the linear AR(`psel'), and"
        display as text "  {bf:thnltest} for a second opinion from tests built on a"
        display as text "  different principle (Keenan, Tsay, CUSUM), and"
        display as text "  {bf:thsearch} if you want a SHARP threshold instead --"
        display as text "  the Taylor LM has little power against one."
        display as text "{hline 78}"
        local famname "not reached"
        local fitted 0
    }
    else {
        display as text "  Selected transition variable" _col(44) as result "`zname'"
        display as text "  its linearity p-value" _col(44) as result %12.4f `minp'
        display as text "{hline 78}"
        display as text "  Chosen by the smallest linearity p-value, which is the"
        display as text "  Lundbergh-Terasvirta-van Dijk rule. Everything from here"
        display as text "  on is CONDITIONAL on this choice, and the p-values below"
        display as text "  do not account for having made it."

        display _n as text "Step 4. LSTAR or ESTAR? The H04 / H03 / H02 sequence"
        display as text "{hline 78}"
        display as text "  hypothesis" _col(26) "F" _col(38) "df" _col(48) "p"
        display as text "{hline 78}"
        display as text "  H04: third-order term" _col(24) as result ///
            %11.4f `LIN'[`cbest',4] _col(36) %8.0f `LIN'[`cbest',5] ///
            _col(44) %12.4f `LIN'[`cbest',6]
        display as text "  H03: second-order term" _col(24) as result ///
            %11.4f `LIN'[`cbest',7] _col(36) %8.0f `LIN'[`cbest',8] ///
            _col(44) %12.4f `LIN'[`cbest',9]
        display as text "  H02: first-order term" _col(24) as result ///
            %11.4f `LIN'[`cbest',10] _col(36) %8.0f `LIN'[`cbest',11] ///
            _col(44) %12.4f `LIN'[`cbest',12]
        display as text "{hline 78}"
        display as text "  Sequential rule" _col(44) as result "`famname'"
        display as text "  Minimum-p-value rule" _col(44) as result "`fampname'"
        display as text "{hline 78}"
        display as text "  The rule: reject H04 -> LSTAR; accept H04 and reject H03"
        display as text "  -> ESTAR; accept both and reject H02 -> LSTAR. The"
        display as text "  reasoning is that a symmetric (exponential) transition"
        display as text "  leaves no odd-order term, so a significant third-order"
        display as text "  term is evidence for the asymmetric logistic one."
        if "`famname'" != "`fampname'" & "`fampname'" != "none" {
            display as text ""
            display as text "  THE TWO RULES DISAGREE here. That is a real ambiguity"
            display as text "  and not a defect: fit both families and compare on the"
            display as text "  evaluation tests of step 6 and on the shape of the"
            display as text "  fitted transition ({bf:estat transition}). Do not"
            display as text "  report only the one that happened to win."
        }
        local fitted 1
    }

    * ------------------------------------------------ steps 5 and 6
    local arstr ""
    forvalues j = 1/`psel' {
        local arstr "`arstr' `j'"
    }
    local usetype = cond("`type'"!="", lower("`type'"), ///
        cond(`fam'==2, "estar", "lstar1"))
    local dsel .
    local isdelay 0
    if `cbest' <= `: word count `dlist'' {
        local dsel : word `cbest' of `dlist'
        local isdelay 1
    }

    local fitcmd ""
    if `fitted' & "`nofit'" == "" {
        if `isdelay' {
            local fitcmd `"thstar `depv'`ifin', ar(`=trim("`arstr'")') type(`usetype') delay(`dsel') ngamma(`ngamma') nc(`nc') `constant'"'
        }
        else {
            local fitcmd `"thstar `depv'`ifin', ar(`=trim("`arstr'")') type(`usetype') thvar(`zname') ngamma(`ngamma') nc(`nc') `constant'"'
        }
        display _n as text "Step 5. Estimation"
        display as text "{hline 78}"
        display as text "  Running: " as result `"`fitcmd'"'
        display as text "{hline 78}"
        capture noisily `fitcmd'
        if _rc {
            display as error ""
            display as error "  The fit failed (rc=" _rc "). The specification the"
            display as error "  cycle selected is not estimable on this sample."
            display as error "  Steps 6 and 7 are skipped; steps 1 to 4 above stand."
            local fitted 0
        }
        else {
            display _n as text "Step 6. Evaluation (Eitrheim-Terasvirta 1996)"
            display as text "{hline 78}"
            capture noisily estat misspec
            if _rc {
                display as error "  the evaluation tests failed (rc=" _rc ")"
            }
        }
    }
    else if `fitted' {
        display _n as text "Step 5. Estimation SKIPPED ({bf:nofit})"
        display as text "{hline 78}"
        if `isdelay' {
            display as text "  Run: " as result ///
                `"thstar `depv'`ifin', ar(`=trim("`arstr'")') type(`usetype') delay(`dsel') `constant'"'
        }
        else {
            display as text "  Run: " as result ///
                `"thstar `depv'`ifin', ar(`=trim("`arstr'")') type(`usetype') thvar(`zname') `constant'"'
        }
        display as text "{hline 78}"
    }

    * ------------------------------------------------ step 7
    display _n as text "{hline 78}"
    display as text "Step 7. The cycle in one line, reproducible by hand"
    display as text "{hline 78}"
    display as text "  AR order" _col(34) as result `psel' as text "   (by `aric')"
    display as text "  Transition variable" _col(34) as result "`zname'"
    display as text "  Linearity p" _col(34) as result %10.4f `minp'
    display as text "  Family" _col(34) as result "`famname'"
    if `fitted' & "`nofit'" == "" {
        display as text "  gamma" _col(34) as result %10.4f e(gamma)
        display as text "  c" _col(34) as result %10.4f e(c)
        display as text "  converged" _col(34) as result ///
            cond(e(converged)==1, "yes", "NO -- do not report this fit")
    }
    display as text "{hline 78}"
    if `"`fitcmd'"' != "" {
        display as text "  The fitted model is in {bf:e()}: {bf:estat},"
        display as text "  {bf:predict} and {bf:thforecast} all work from here."
        display as text "  The command the cycle ran was"
        display as text "    " as result `"`fitcmd'"'
        display as text "  and typing it by hand gives exactly this fit."
    }
    display as text "{hline 78}"
    display as text "  WHAT THIS REPORT IS NOT. The p-values in steps 4 and 6 are"
    display as text "  conditional on the AR order and the transition variable"
    display as text "  selected in steps 1 and 3, and they do not account for the"
    display as text "  search. The cycle is a specification PROCEDURE, not a"
    display as text "  simultaneous test, and that is how Terasvirta presents it."
    display as text "  Report the whole table, not only the chosen row."
    display as text "{hline 78}"

    * ------------------------------------------------ return
    matrix colnames `AR'  = p ssr ll aic bic hqic k
    matrix colnames `LIN' = LM3_F LM3_df LM3_p H04_F H04_df H04_p ///
        H03_F H03_df H03_p H02_F H02_df H02_p
    local rn ""
    forvalues c = 1/`ncand' {
        local nm : word `c' of `candnames'
        local rn "`rn' `nm'"
    }
    capture matrix rownames `LIN' = `rn'
    return matrix arsel   = `AR'
    return matrix lintest = `LIN'
    return scalar N        = `n'
    return scalar p        = `psel'
    return scalar alpha    = `alpha'
    return scalar n_cand   = `ncand'
    return scalar cand     = `cbest'
    return scalar p_lin    = `minp'
    return scalar rejected = `reject'
    return scalar family   = `fam'
    return scalar family_minp = `famp'
    if `dsel' < . return scalar delay = `dsel'
    return local  candvar  "`zname'"
    return local  candidates "`=trim("`candnames'")'"
    return local  familyname "`famname'"
    return local  aric     "`aric'"
    return local  fitcmd   `"`fitcmd'"'
    return local  cmd      "thstarcycle"
end
