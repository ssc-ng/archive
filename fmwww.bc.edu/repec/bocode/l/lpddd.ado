*! lpddd 0.4.0  22nov2026
*! Stacked local-projection triple differences (and differences-in-differences)
*! with a seasonal base period and estimates for spans of periods
*! Uses reghdfe (Correia, SSC) if it is installed; otherwise regress and xtreg

program define lpddd, eclass
    version 15.1
    syntax varname(numeric) [if] [in] [aweight pweight fweight] ,      ///
        Unit(varname) Time(varname numeric) GROup(varname)             ///
        COHort(varname numeric)                                        ///
        [ ELigible(varname numeric) DD PRE(integer 0) POST(integer 0)  ///
          SEASon(integer 1) SPANs(numlist integer) noEVent LOG IHS     ///
          FILLzero CONTrol(string) GFE STRata(varname) ABSorb(string)  ///
          AGGregate(string) CLuster(varname) Level(cilevel) GRAph      ///
          ENGine(string) noCOV BY(varname) TCode(string)               ///
          SAVing(string asis) noTABle ]

    local cmdline `"lpddd `0'"'
    local y `varlist'
    capture mata: mata drop LPDDD_S LPDDD_U

    * ------------------------------------------------------------------ checks
    if !inlist("`engine'", "", "reghdfe", "builtin") {
        display as error "engine() must be reghdfe or builtin"
        exit 198
    }
    capture which reghdfe
    local hasreghdfe = (_rc == 0)
    if "`engine'" == "" {
        if `hasreghdfe' local engine "reghdfe"
        else local engine "builtin"
    }
    if "`engine'" == "reghdfe" & !`hasreghdfe' {
        display as error "engine(reghdfe) requires reghdfe. Type: ssc install reghdfe  and  ssc install ftools"
        exit 199
    }
    * tcode(): how time() and cohort() are coded when they are not consecutive integers
    if !inlist("`tcode'", "", "yyyymm", "yyyyq", "dmonth", "dquarter", "dyear") {
        display as error "tcode() must be yyyymm, yyyyq, dmonth, dquarter or dyear"
        exit 198
    }
    local tmpl "@"
    if "`tcode'" == "yyyymm"   local tmpl "ym(floor(@ / 100), mod(@, 100))"
    if "`tcode'" == "yyyyq"    local tmpl "yq(floor(@ / 10), mod(@, 10))"
    if "`tcode'" == "dmonth"   local tmpl "mofd(@)"
    if "`tcode'" == "dquarter" local tmpl "qofd(@)"
    if "`tcode'" == "dyear"    local tmpl "yofd(@)"
    local texp : subinstr local tmpl "@" "`time'", all
    local cexp : subinstr local tmpl "@" "`cohort'", all
    local gapnote 0
    if "`engine'" == "builtin" & `"`absorb'"' != "" {
        display as error "absorb() requires reghdfe (ssc install reghdfe; ssc install ftools)"
        exit 198
    }
    if "`dd'" == "" & "`eligible'" == "" {
        display as error "specify eligible() for a triple difference, or dd for a difference-in-differences"
        exit 198
    }
    if "`dd'" != "" & "`eligible'" != "" {
        display as error "eligible() and dd may not be combined"
        exit 198
    }
    if "`dd'" != "" & "`gfe'" != "" {
        display as error "gfe may not be combined with dd (treatment does not vary within a group)"
        exit 198
    }
    if `season' < 1 {
        display as error "season() must be 1 or larger"
        exit 198
    }
    if `pre' < 0 | `post' < 0 {
        display as error "pre() and post() must not be negative"
        exit 198
    }
    if "`log'" != "" & "`ihs'" != "" {
        display as error "log and ihs may not be combined"
        exit 198
    }
    if "`control'" == "" local control "never"
    if !inlist("`control'", "never", "notyet") {
        display as error "control() must be never or notyet"
        exit 198
    }
    if "`aggregate'" == "" local aggregate "ols"
    if !inlist("`aggregate'", "ols", "cohort", "equal") {
        display as error "aggregate() must be ols, cohort or equal"
        exit 198
    }
    if "`by'" != "" & "`aggregate'" != "ols" {
        display as error "by() may not be combined with aggregate(cohort) or aggregate(equal)"
        exit 198
    }
    if "`event'" == "noevent" & "`spans'" == "" {
        display as error "nothing to estimate: noevent requires spans()"
        exit 198
    }
    local transf "none"
    if "`log'" != "" local transf "log"
    if "`ihs'" != "" local transf "ihs"

    * saving(filename [, replace])
    local savefile ""
    local savereplace ""
    if `"`saving'"' != "" {
        _lpddd_parsesave `saving'
        local savefile `"`r(file)'"'
        local savereplace "`r(replace)'"
    }

    * ------------------------------------------------------------------ spans
    * span j: periods a_j to b_j, compared with its reference periods
    *   after treatment (a_j >= 0): the same seasons of the last cycle before treatment
    *   before treatment (b_j < 0): the same periods one or more full cycles earlier
    local nsp 0
    if "`spans'" != "" {
        local nw : word count `spans'
        if mod(`nw', 2) != 0 {
            display as error "spans() needs pairs of numbers: first and last period of each span"
            exit 198
        }
        local nsp = `nw' / 2
        forvalues j = 1/`nsp' {
            local i1 = 2 * `j' - 1
            local i2 = 2 * `j'
            local a`j' : word `i1' of `spans'
            local b`j' : word `i2' of `spans'
            if `a`j'' > `b`j'' {
                display as error "spans(): the first period of a span must not exceed its last period"
                exit 198
            }
            if `a`j'' < 0 & `b`j'' >= 0 {
                display as error "spans(): a span may not contain periods before and after treatment"
                exit 198
            }
            local len`j' = `b`j'' - `a`j'' + 1
            if `a`j'' >= 0 {
                local rtype`j' "list"
                local ref`j' ""
                forvalues e = `a`j''/`b`j'' {
                    local r = `e' - `season' * (floor(`e' / `season') + 1)
                    local ref`j' : list ref`j' | r
                }
                local rlen`j' : word count `ref`j''
            }
            else {
                local rtype`j' "range"
                local m = ceil(`len`j'' / `season')
                local ra`j' = `a`j'' - `season' * `m'
                local rb`j' = `b`j'' - `season' * `m'
                local rlen`j' = `len`j''
            }
        }
    }

    * event window needed in every stack
    local lo = -max(`pre', `season')
    local hi = `post'
    forvalues j = 1/`nsp' {
        if `b`j'' > `hi' local hi = `b`j''
        if `a`j'' < `lo' local lo = `a`j''
        if "`rtype`j''" == "range" {
            if `ra`j'' < `lo' local lo = `ra`j''
        }
    }

    * ------------------------------------------------------------------ sample
    marksample touse, novarlist
    markout `touse' `unit' `time' `group', strok
    if "`eligible'" != "" markout `touse' `eligible'
    if "`strata'" != ""   markout `touse' `strata', strok
    if "`by'" != ""       markout `touse' `by', strok
    if "`cluster'" != ""  markout `touse' `cluster', strok
    local wv ""
    if "`weight'" != "" {
        tempvar wv
        quietly generate double `wv' `exp'
        markout `touse' `wv'
    }

    * variables named in absorb()
    local absv ""
    if `"`absorb'"' != "" {
        local tmp : subinstr local absorb "#" " ", all
        foreach tk of local tmp {
            local v = regexr("`tk'", "^[a-z0-9]*\.", "")
            capture confirm variable `v'
            if !_rc local absv `absv' `v'
        }
    }

    preserve
    quietly keep if `touse'
    if _N == 0 {
        display as error "no observations"
        exit 2000
    }
    capture describe __lp_*, varlist
    if !_rc {
        display as error "variables with names starting with __lp_ are not allowed in the data"
        exit 110
    }
    local keepv `y' `unit' `time' `group' `cohort' `eligible' `strata' `cluster' `wv' `absv' `by'
    local keepv : list uniq keepv
    keep `keepv'

    quietly egen long __lp_u = group(`unit')
    quietly egen long __lp_g = group(`group')

    capture assert `time' == int(`time')
    if _rc {
        display as error "time() must contain integers"
        exit 451
    }
    if "`tcode'" != "" {
        * convert time() and cohort() to consecutive periods (in the copy of the data used here)
        if "`tcode'" == "yyyymm" {
            capture assert inrange(mod(`time', 100), 1, 12)
            if _rc {
                display as error "tcode(yyyymm): time() must be coded as year and month, for example 201807"
                exit 451
            }
            capture assert inrange(mod(`cohort', 100), 1, 12) if !missing(`cohort') & `cohort' != 0
            if _rc {
                display as error "tcode(yyyymm): cohort() must be coded as year and month, for example 201807 (0 or missing if never treated)"
                exit 459
            }
        }
        if "`tcode'" == "yyyyq" {
            capture assert inrange(mod(`time', 10), 1, 4)
            if _rc {
                display as error "tcode(yyyyq): time() must be coded as year and quarter, for example 20183"
                exit 451
            }
            capture assert inrange(mod(`cohort', 10), 1, 4) if !missing(`cohort') & `cohort' != 0
            if _rc {
                display as error "tcode(yyyyq): cohort() must be coded as year and quarter, for example 20183 (0 or missing if never treated)"
                exit 459
            }
        }
        quietly replace `cohort' = `cexp' if !missing(`cohort') & `cohort' != 0
        quietly replace `time' = `texp'
    }
    else {
        * dates that are not consecutive integers: stop if they look like yyyymm or yyyyq,
        * otherwise show a note
        quietly summarize `time', meanonly
        local tmin = r(min)
        local tmax = r(max)
        tempvar tg
        quietly bysort `time': generate byte `tg' = (_n == 1)
        quietly count if `tg'
        local nT = r(N)
        drop `tg'
        if `tmax' - `tmin' + 1 > `nT' {
            capture assert inrange(mod(`time', 100), 1, 12) & inrange(floor(`time' / 100), 1000, 9999)
            if _rc == 0 {
                display as error "time() looks like dates coded as year and month (for example 201807), which are not"
                display as error "consecutive: 201812 is followed by 201901. Add the option tcode(yyyymm); cohort() must be"
                display as error "coded in the same way. Or build a Stata monthly date with ym()."
                exit 451
            }
            capture assert inrange(mod(`time', 10), 1, 4) & inrange(floor(`time' / 10), 1000, 9999)
            if _rc == 0 {
                display as error "time() looks like dates coded as year and quarter (for example 20183), which are not"
                display as error "consecutive: 20184 is followed by 20191. Add the option tcode(yyyyq); cohort() must be"
                display as error "coded in the same way. Or build a Stata quarterly date with yq()."
                exit 451
            }
            local gapnote 1
            local tfmt : format `time'
            if substr("`tfmt'", 1, 3) == "%td" local gapnote 2
        }
    }
    capture assert `cohort' == int(`cohort') if !missing(`cohort')
    if _rc {
        display as error "cohort() must contain integers (the period of first treatment), 0 or missing for never treated"
        exit 459
    }
    capture isid __lp_u `time'
    if _rc {
        display as error "repeated time values within unit(): unit() and time() must identify the observations"
        exit 451
    }
    quietly generate byte __lp_never = missing(`cohort') | `cohort' == 0
    quietly bysort __lp_g (`cohort'): generate byte __lp_bad = (`cohort'[1] != `cohort'[_N])
    quietly count if __lp_bad
    if r(N) > 0 {
        display as error "cohort() must be constant within group()"
        exit 459
    }
    drop __lp_bad

    if "`eligible'" != "" {
        capture assert inlist(`eligible', 0, 1)
        if _rc {
            display as error "eligible() must be 0 or 1"
            exit 450
        }
        quietly bysort __lp_u (`eligible'): generate byte __lp_bad = (`eligible'[1] != `eligible'[_N])
        quietly count if __lp_bad
        if r(N) > 0 {
            display as error "eligible() must be constant within unit()"
            exit 459
        }
        drop __lp_bad
        quietly generate byte __lp_Q = `eligible'
    }
    else quietly generate byte __lp_Q = 1

    * by(): states of the groups; the effect is estimated for every state in one regression
    local nby 0
    local bykeep ""
    if "`by'" != "" {
        quietly egen long __lp_by = group(`by')
        quietly bysort __lp_g (__lp_by): generate byte __lp_bad = (__lp_by[1] != __lp_by[_N])
        quietly count if __lp_bad
        if r(N) > 0 {
            display as error "by() must be constant within group()"
            exit 459
        }
        drop __lp_bad
        quietly summarize __lp_by, meanonly
        local nby = r(max)
        if `nby' < 2 {
            display as error "by() takes one value only in the sample"
            exit 459
        }
        if `nby' > 20 {
            display as error "by() may take at most 20 values"
            exit 198
        }
        forvalues l = 1/`nby' {
            quietly levelsof `by' if __lp_by == `l', local(tmpl) clean
            local bylab`l' `"`tmpl'"'
        }
        local bykeep "__lp_by"
    }
    local nl1 = max(1, `nby')

    * strata of the fixed effects: strata() and, with by(), the states
    local strk ""
    if "`strata'`by'" != "" {
        quietly egen long __lp_str = group(`strata' `by')
        local strk "__lp_str"
    }
    if "`cluster'" == "" local clv "__lp_g"
    else {
        quietly egen long __lp_cl = group(`cluster')
        local clv "__lp_cl"
    }
    * are the groups nested in the clusters? (decides the count of degrees of freedom
    * that reghdfe uses when the group effects are absorbed)
    local clnest 1
    if "`cluster'" != "" {
        quietly bysort __lp_g (__lp_cl): generate byte __lp_nb = (__lp_cl[1] != __lp_cl[_N])
        quietly count if __lp_nb
        if r(N) > 0 local clnest 0
        drop __lp_nb
    }
    local wkeep ""
    if "`weight'" != "" {
        quietly generate double __lp_w = `wv'
        quietly bysort __lp_u (__lp_w): generate byte __lp_bad = (__lp_w[1] != __lp_w[_N])
        quietly count if __lp_bad
        if r(N) > 0 {
            display as error "weights must be constant within unit()"
            exit 459
        }
        drop __lp_bad
        local wkeep "__lp_w"
    }

    quietly levelsof `cohort' if !__lp_never, local(glist)
    local ng : word count `glist'
    if `ng' == 0 {
        display as error "no treated cohort: cohort() is 0 or missing in all observations"
        exit 2001
    }
    quietly count if __lp_never
    if r(N) == 0 & "`control'" == "never" {
        display as error "no never-treated group; consider control(notyet)"
        exit 2001
    }

    * fixed effects
    if "`dd'" != "" {
        local fe "i.__lp_stack"
        if "`strk'" != "" local fe "i.__lp_stack#i.__lp_str"
    }
    else {
        if "`gfe'" != "" local fe1 "i.__lp_stack#i.__lp_g"
        else if "`strk'" != "" local fe1 "i.__lp_stack#i.__lp_T#i.__lp_str"
        else local fe1 "i.__lp_stack#i.__lp_T"
        if "`strk'" != "" local fe2 "i.__lp_stack#i.__lp_Q#i.__lp_str"
        else local fe2 "i.__lp_stack#i.__lp_Q"
        local fe "`fe1' `fe2'"
    }
    if `"`absorb'"' != "" local fe `"`fe' `absorb'"'
    * built-in commands: "one" = one set of effects (regress), "two" = two sets (regress),
    * "xt" = group effects absorbed by xtreg, fe and the other set as indicators
    local mode "two"
    if "`dd'" != "" local mode "one"
    else if "`gfe'" != "" local mode "xt"

    local carry __lp_u __lp_g __lp_T __lp_Q __lp_D __lp_stack `clv' `wkeep' `strk' `absv' `bykeep'
    local carry : list uniq carry

    * workspace in Mata: sums of the influence of every cluster on every estimate (for the
    * covariances between estimates) and a marker of the units used (for e(sample))
    quietly summarize __lp_u, meanonly
    local Umax = r(max)
    quietly summarize `clv', meanonly
    local Gmax = r(max)
    local nrowR = `nsp'
    if "`event'" != "noevent" local nrowR = `nrowR' + `pre' + `post' + 1
    local ncolS = `nrowR' * `nl1'
    mata: _lpddd_init(`Gmax', `ncolS', `Umax')
    local dovc = ("`cov'" != "nocov")

    tempfile base
    quietly save `base'

    * ------------------------------------------------------------------ stacks
    local k 0
    foreach g of local glist {
        local ++k
        tempfile wk`k' ev`k' sp`k'
        quietly {
            use `base', clear
            if "`control'" == "never" keep if `cohort' == `g' | __lp_never
            else keep if `cohort' == `g' | __lp_never | (`cohort' > `g' + `hi' & !missing(`cohort'))
            generate long __lp_rel = `time' - `g'
            keep if inrange(__lp_rel, `lo', `hi')
            generate byte __lp_T = (`cohort' == `g')
            generate int __lp_stack = `k'
            if "`dd'" != "" generate byte __lp_D = __lp_T
            else generate byte __lp_D = __lp_T * __lp_Q
            count if __lp_D == 1
            local ntr`k' = r(N)
            save `wk`k''

            * spans: one observation per unit
            if `nsp' > 0 {
                forvalues j = 1/`nsp' {
                    generate byte __lp_i1 = inrange(__lp_rel, `a`j'', `b`j'')
                    if "`rtype`j''" == "range" generate byte __lp_i0 = inrange(__lp_rel, `ra`j'', `rb`j'')
                    else {
                        generate byte __lp_i0 = 0
                        foreach r of local ref`j' {
                            replace __lp_i0 = 1 if __lp_rel == `r'
                        }
                    }
                    bysort __lp_u: egen double __lp_s1 = total(`y' * __lp_i1)
                    bysort __lp_u: egen double __lp_s0 = total(`y' * __lp_i0)
                    bysort __lp_u: egen long __lp_n1 = total(__lp_i1 * !missing(`y'))
                    bysort __lp_u: egen long __lp_n0 = total(__lp_i0 * !missing(`y'))
                    replace __lp_s1 = __lp_s1 / `len`j''
                    replace __lp_s0 = __lp_s0 / `rlen`j''
                    if "`transf'" == "log" generate double __lp_sp`j' = ln(__lp_s1) - ln(__lp_s0) if __lp_s1 > 0 & __lp_s0 > 0
                    else if "`transf'" == "ihs" generate double __lp_sp`j' = asinh(__lp_s1) - asinh(__lp_s0)
                    else generate double __lp_sp`j' = __lp_s1 - __lp_s0
                    if "`fillzero'" == "" replace __lp_sp`j' = . if __lp_n1 < `len`j'' | __lp_n0 < `rlen`j''
                    drop __lp_i1 __lp_i0 __lp_s1 __lp_s0 __lp_n1 __lp_n0
                }
                bysort __lp_u (`time'): keep if _n == 1
                keep `carry' __lp_sp*
                save `sp`k''
                use `wk`k'', clear
            }

            * event time: one observation per unit and period
            if "`event'" != "noevent" {
                if "`transf'" == "log" generate double __lp_f = ln(`y') if `y' > 0
                else if "`transf'" == "ihs" generate double __lp_f = asinh(`y')
                else generate double __lp_f = `y'
                xtset __lp_u `time'
                generate long __lp_d = `season' * (floor(__lp_rel / `season') + 1)
                generate double __lp_dy = .
                levelsof __lp_d if inrange(__lp_rel, -`pre', `post') & __lp_d != 0, local(dl)
                foreach d of local dl {
                    if `d' > 0 {
                        replace __lp_dy = __lp_f - L`d'.__lp_f if __lp_d == `d'
                    }
                    else {
                        local ad = -`d'
                        replace __lp_dy = __lp_f - F`ad'.__lp_f if __lp_d == `d'
                    }
                }
                keep if inrange(__lp_rel, -`pre', `post') & __lp_d != 0 & !missing(__lp_dy)
                keep `carry' __lp_rel __lp_dy
                save `ev`k''
            }
        }
    }

    * ------------------------------------------------------------------ estimates
    * columns of the results matrix:
    *   type (0 event time, 1 span), from, to, b, se, t, p, ll, ul, N, ref (1 = reference period)
    tempname R bb vv sb sse sN sdf sncl st sp sll sul crit BS WS tmpm sv IX VF bp Vp Vi Wm Bby Sby Cm HT Nby sNl
    local hasht 0
    local row 0
    local cols ""
    local vcok 1
    local prepos ""
    local nest 0
    local names ""
    local Nmax 0
    local Nclmax 0
    local lastrc 0
    local nfail 0
    local fitopt d(__lp_D) fe(`fe') clv(`clv') agg(`aggregate') nst(`ng') engine(`engine') mode(`mode') nest(`clnest') dovc(`dovc') nby(`nby')
    local wopt ""
    if "`weight'" != "" local wopt "wtype(`weight')"

    if "`event'" != "noevent" {
        quietly {
            use `ev1', clear
            forvalues k = 2/`ng' {
                append using `ev`k''
            }
            if "`aggregate'" != "ols" {
                forvalues k = 1/`ng' {
                    generate byte __lp_D`k' = __lp_D * (__lp_stack == `k')
                }
            }
            if `nby' > 0 {
                forvalues l = 1/`nby' {
                    generate byte __lp_B`l' = __lp_D * (__lp_by == `l')
                }
            }
            if "`engine'" == "builtin" {
                if "`mode'" == "one" egen long __lp_fa = group(__lp_stack `strk')
                else if "`mode'" == "xt" egen long __lp_fa = group(__lp_stack __lp_g)
                else egen long __lp_fa = group(__lp_stack __lp_T `strk')
                if "`mode'" != "one" egen long __lp_fb = group(__lp_stack __lp_Q `strk')
                if "`mode'" == "xt" xtset __lp_fa
            }
        }
        forvalues e = -`pre'/`post' {
            local ++row
            local rt`row' 0
            local rf`row' `e'
            local rto`row' `e'
            local d = `season' * (floor(`e' / `season') + 1)
            if `d' == 0 {
                forvalues l = 1/`nl1' {
                    local lv 0
                    if `nby' > 0 local lv `l'
                    matrix `R' = nullmat(`R') \ (0, `e', `e', 0, ., ., ., 0, 0, ., 1, `lv')
                }
                matrix `BS' = nullmat(`BS') \ J(1, `ng', .)
                matrix `WS' = nullmat(`WS') \ J(1, `ng', .)
                continue
            }
            local col = (`row' - 1) * `nl1' + 1
            _lpddd_fit __lp_dy if __lp_rel == `e', `fitopt' `wopt' col(`col')
            scalar `sb'  = r(b)
            scalar `sse' = r(se)
            scalar `sN'  = r(N)
            scalar `sdf' = r(df)
            scalar `sncl' = r(ncl)
            local fitrc = r(rc)
            local fitvc = r(vc)
            matrix `tmpm' = r(bk)
            matrix `BS' = nullmat(`BS') \ `tmpm'
            matrix `tmpm' = r(wk)
            matrix `WS' = nullmat(`WS') \ `tmpm'
            matrix `Bby' = r(bby)
            matrix `Sby' = r(seby)
            matrix `Nby' = r(nby)
            if `fitrc' != 0 {
                local lastrc = `fitrc'
                local ++nfail
            }
            if `e' < 0 {
                local ae = -`e'
                local nm "m`ae'"
            }
            else local nm "p`e'"
            forvalues l = 1/`nl1' {
                local suf ""
                local lv 0
                scalar `sNl' = `sN'
                if `nby' > 0 {
                    scalar `sb'  = `Bby'[1, `l']
                    scalar `sse' = `Sby'[1, `l']
                    scalar `sNl' = `Nby'[1, `l']
                    local suf "_`l'"
                    local lv `l'
                }
                scalar `st'  = .
                scalar `sp'  = .
                scalar `sll' = .
                scalar `sul' = .
                if `sse' > 0 & `sse' < . {
                    scalar `st'   = `sb' / `sse'
                    scalar `sp'   = 2 * ttail(`sdf', abs(`st'))
                    scalar `crit' = invttail(`sdf', (100 - `level') / 200)
                    scalar `sll'  = `sb' - `crit' * `sse'
                    scalar `sul'  = `sb' + `crit' * `sse'
                    local cix = `col' + `l' - 1
                    matrix `bb' = nullmat(`bb'), `sb'
                    matrix `vv' = nullmat(`vv'), `sse'^2
                    matrix `sv' = nullmat(`sv'), `sse'
                    matrix `IX' = nullmat(`IX'), `cix'
                    local names `names' `nm'`suf'
                    local ++nest
                    local pos_`row'_`l' `nest'
                    if `e' < 0 local prepos `prepos' `nest'
                    if `fitvc' == 0 local vcok 0
                    if `sN' > `Nmax' local Nmax = `sN'
                    if `sncl' < . {
                        if `sncl' > `Nclmax' local Nclmax = `sncl'
                    }
                }
                matrix `R' = nullmat(`R') \ (0, `e', `e', `sb', `sse', `st', `sp', `sll', `sul', `sNl', 0, `lv')
            }
        }
    }

    if `nsp' > 0 {
        quietly {
            use `sp1', clear
            forvalues k = 2/`ng' {
                append using `sp`k''
            }
            if "`aggregate'" != "ols" {
                forvalues k = 1/`ng' {
                    generate byte __lp_D`k' = __lp_D * (__lp_stack == `k')
                }
            }
            if `nby' > 0 {
                forvalues l = 1/`nby' {
                    generate byte __lp_B`l' = __lp_D * (__lp_by == `l')
                }
            }
            if "`engine'" == "builtin" {
                if "`mode'" == "one" egen long __lp_fa = group(__lp_stack `strk')
                else if "`mode'" == "xt" egen long __lp_fa = group(__lp_stack __lp_g)
                else egen long __lp_fa = group(__lp_stack __lp_T `strk')
                if "`mode'" != "one" egen long __lp_fb = group(__lp_stack __lp_Q `strk')
                if "`mode'" == "xt" xtset __lp_fa
            }
        }
        forvalues j = 1/`nsp' {
            local ++row
            local rt`row' 1
            local rf`row' `a`j''
            local rto`row' `b`j''
            local col = (`row' - 1) * `nl1' + 1
            _lpddd_fit __lp_sp`j', `fitopt' `wopt' col(`col')
            scalar `sb'  = r(b)
            scalar `sse' = r(se)
            scalar `sN'  = r(N)
            scalar `sdf' = r(df)
            scalar `sncl' = r(ncl)
            local fitrc = r(rc)
            local fitvc = r(vc)
            matrix `tmpm' = r(bk)
            matrix `BS' = nullmat(`BS') \ `tmpm'
            matrix `tmpm' = r(wk)
            matrix `WS' = nullmat(`WS') \ `tmpm'
            matrix `Bby' = r(bby)
            matrix `Sby' = r(seby)
            matrix `Nby' = r(nby)
            if `fitrc' != 0 {
                local lastrc = `fitrc'
                local ++nfail
            }
            local nm "span`j'"
            forvalues l = 1/`nl1' {
                local suf ""
                local lv 0
                scalar `sNl' = `sN'
                if `nby' > 0 {
                    scalar `sb'  = `Bby'[1, `l']
                    scalar `sse' = `Sby'[1, `l']
                    scalar `sNl' = `Nby'[1, `l']
                    local suf "_`l'"
                    local lv `l'
                }
                scalar `st'  = .
                scalar `sp'  = .
                scalar `sll' = .
                scalar `sul' = .
                if `sse' > 0 & `sse' < . {
                    scalar `st'   = `sb' / `sse'
                    scalar `sp'   = 2 * ttail(`sdf', abs(`st'))
                    scalar `crit' = invttail(`sdf', (100 - `level') / 200)
                    scalar `sll'  = `sb' - `crit' * `sse'
                    scalar `sul'  = `sb' + `crit' * `sse'
                    local cix = `col' + `l' - 1
                    matrix `bb' = nullmat(`bb'), `sb'
                    matrix `vv' = nullmat(`vv'), `sse'^2
                    matrix `sv' = nullmat(`sv'), `sse'
                    matrix `IX' = nullmat(`IX'), `cix'
                    local names `names' `nm'`suf'
                    local ++nest
                    local pos_`row'_`l' `nest'
                    if `fitvc' == 0 local vcok 0
                    if `sN' > `Nmax' local Nmax = `sN'
                    if `sncl' < . {
                        if `sncl' > `Nclmax' local Nclmax = `sncl'
                    }
                }
                matrix `R' = nullmat(`R') \ (1, `a`j'', `b`j'', `sb', `sse', `st', `sp', `sll', `sul', `sNl', 0, `lv')
            }
        }
    }
    matrix colnames `R' = type from to b se t p ll ul N ref state

    * ------------------------------------------------------------------ covariance matrix
    * full matrix from the sums by cluster of the influence of every observation on every
    * estimate; the diagonal is the variance reported by each regression
    local fullv 0
    local Fpre = .
    local ppre = .
    local qpre 0
    local dfr = .
    if `Nclmax' > 1 local dfr = `Nclmax' - 1
    if `nest' > 0 {
        if `dovc' & `vcok' {
            mata: _lpddd_V("`IX'", "`sv'", "`VF'")
            local fullv 1
        }
        else matrix `VF' = diag(`vv')
        * joint test that the estimates for the periods before treatment are zero
        local np : word count `prepos'
        if `fullv' & `np' > 0 & `dfr' < . {
            matrix `bp' = J(1, `np', 0)
            matrix `Vp' = J(`np', `np', 0)
            local i 0
            foreach pi of local prepos {
                local ++i
                matrix `bp'[1, `i'] = `bb'[1, `pi']
                local j 0
                foreach pj of local prepos {
                    local ++j
                    matrix `Vp'[`i', `j'] = `VF'[`pi', `pj']
                }
            }
            matrix `Vi' = syminv(`Vp')
            local qpre = `np' - diag0cnt(`Vi')
            if `qpre' > 0 {
                matrix `Wm' = `bp' * `Vi' * `bp''
                local Fpre = `Wm'[1, 1] / `qpre'
                local ppre = Ftail(`qpre', `dfr', `Fpre')
            }
        }
        * by(): test, for every period and span, that the effect is the same in all states
        if `nby' > 1 & `fullv' & `dfr' < . {
            forvalues r = 1/`row' {
                local plist ""
                forvalues l = 1/`nby' {
                    if "`pos_`r'_`l''" != "" local plist `plist' `pos_`r'_`l''
                }
                local q : word count `plist'
                if `q' >= 2 {
                    matrix `bp' = J(1, `q', 0)
                    matrix `Vp' = J(`q', `q', 0)
                    local i 0
                    foreach pa of local plist {
                        local ++i
                        matrix `bp'[1, `i'] = `bb'[1, `pa']
                        local j 0
                        foreach pb of local plist {
                            local ++j
                            matrix `Vp'[`i', `j'] = `VF'[`pa', `pb']
                        }
                    }
                    local q1 = `q' - 1
                    matrix `Cm' = J(`q1', 1, 1), -I(`q1')
                    matrix `Vi' = `Cm' * `Vp' * `Cm''
                    matrix `Vi' = syminv(`Vi')
                    local rk = `q1' - diag0cnt(`Vi')
                    if `rk' > 0 {
                        matrix `Wm' = `Cm' * `bp''
                        matrix `Wm' = `Wm'' * `Vi' * `Wm'
                        local Fh = `Wm'[1, 1] / `rk'
                        local ph = Ftail(`rk', `dfr', `Fh')
                        local dif = .
                        local dse = .
                        if `q' == 2 {
                            local dif = `bp'[1, 1] - `bp'[1, 2]
                            local dse = sqrt(`Vp'[1, 1] + `Vp'[2, 2] - 2 * `Vp'[1, 2])
                        }
                        matrix `HT' = nullmat(`HT') \ (`rt`r'', `rf`r'', `rto`r'', `Fh', `rk', `ph', `dif', `dse')
                        local hasht 1
                    }
                }
            }
            if `hasht' matrix colnames `HT' = type from to F df p diff se
        }
    }

    * ------------------------------------------------------------------ results as data: graph, saving
    if "`graph'" != "" | `"`savefile'"' != "" {
        quietly {
            drop _all
            svmat double `R', names(col)
            label variable type "0 event time, 1 span"
            label variable from "First period"
            label variable to   "Last period"
            label variable b    "Estimate"
            label variable se   "Standard error"
            label variable ll   "Lower limit"
            label variable ul   "Upper limit"
            label variable N    "Observations"
            label variable ref  "1 = reference period (zero by construction)"
            label variable state "State of by(); 0 without by()"
            if `nby' > 0 {
                capture label drop __lp_st
                forvalues l = 1/`nby' {
                    label define __lp_st `l' `"`by' = `bylab`l''"', add
                }
                label values state __lp_st
            }
        }
        if `"`savefile'"' != "" {
            quietly save `savefile', `savereplace'
        }
        if "`graph'" != "" {
            quietly count if type == 0
            if r(N) > 0 & `nby' == 0 {
                twoway (rarea ll ul from if type == 0, color(gs13) lwidth(none))        ///
                       (line b from if type == 0, lcolor(black) lwidth(medthick)),      ///
                       yline(0, lcolor(gs8) lwidth(thin))                               ///
                       xline(-0.5, lcolor(gs8) lpattern(shortdash))                     ///
                       xtitle("Periods from the first period of treatment")             ///
                       ytitle("Estimate")                                               ///
                       legend(order(2 "Estimate" 1 "`level' percent interval") rows(1) position(6)) ///
                       graphregion(color(white))
            }
            if r(N) > 0 & `nby' > 0 {
                twoway (rarea ll ul from if type == 0, color(gs13) lwidth(none))        ///
                       (line b from if type == 0, lcolor(black) lwidth(medthick)),      ///
                       yline(0, lcolor(gs8) lwidth(thin))                               ///
                       xline(-0.5, lcolor(gs8) lpattern(shortdash))                     ///
                       xtitle("Periods from the first period of treatment")             ///
                       ytitle("Estimate")                                               ///
                       legend(order(2 "Estimate" 1 "`level' percent interval") rows(1)) ///
                       by(state, note("") legend(position(6)) graphregion(color(white)))
            }
        }
    }
    restore

    * ------------------------------------------------------------------ e(sample)
    * observations of the units that entered at least one regression, in the periods of the
    * stacks in which these units are used
    tempvar uu esamp inwin tcv ccv
    quietly egen long `uu' = group(`unit') if `touse'
    quietly generate double `tcv' = `texp'
    quietly generate double `ccv' = cond(missing(`cohort') | `cohort' == 0, `cohort', `cexp')
    quietly generate byte `esamp' = 0
    mata: _lpddd_esample("`uu'", "`esamp'")
    quietly generate byte `inwin' = 0
    foreach g of local glist {
        if "`control'" == "never" {
            quietly replace `inwin' = 1 if `esamp' == 1 & inrange(`tcv' - `g', `lo', `hi') ///
                & (`ccv' == `g' | missing(`ccv') | `ccv' == 0)
        }
        else {
            quietly replace `inwin' = 1 if `esamp' == 1 & inrange(`tcv' - `g', `lo', `hi') ///
                & (`ccv' == `g' | missing(`ccv') | `ccv' == 0 | `ccv' > `g' + `hi')
        }
    }
    quietly replace `esamp' = `inwin'
    capture mata: mata drop LPDDD_S LPDDD_U

    * ------------------------------------------------------------------ display
    local design "triple difference (treated group x eligible unit)"
    if "`dd'" != "" local design "difference-in-differences (treated group)"
    display _newline as text "Stacked local projections: `design'"
    display as text "Outcome: " as result "`y'" as text "   transformation: " as result "`transf'" ///
        as text "   seasonal cycle: " as result "`season'"
    display as text "Stacks (treated cohorts): " as result "`ng'" as text "   controls: " as result "`control'" ///
        as text "   aggregation: " as result "`aggregate'"
    local k 0
    foreach g of local glist {
        local ++k
        display as text "  stack `k': first treated period " as result "`g'" ///
            as text ", treated observations in the window " as result "`ntr`k''"
    }
    display as text "Estimation: " as result cond("`engine'" == "reghdfe", "reghdfe", cond("`mode'" == "xt", "xtreg, fe", "regress"))
    display as text "Fixed effects: " as result `"`fe'"'
    display as text "Standard errors clustered by: " as result cond("`cluster'" == "", "`group'", "`cluster'")
    if "`tcode'" != "" {
        display as text "Time: " as result "`time'" as text " and " as result "`cohort'" as text " read as " as result "`tcode'" ///
            as text " and counted in consecutive periods"
    }
    if `gapnote' == 1 {
        display as text "Note: the values of `time' are not consecutive (some are missing between the first and the last)."
        display as text "      Periods are counted in units of `time'. If the dates are coded, see option tcode()."
    }
    if `gapnote' == 2 {
        display as text "Note: `time' is a daily date with gaps. For monthly, quarterly or annual data stored as daily"
        display as text "      dates, add tcode(dmonth), tcode(dquarter) or tcode(dyear)."
    }

    if `nby' > 0 {
        display as text "States: " as result "`by'" as text " (the fixed effects are interacted with the state)"
    }
    if "`table'" != "notable" {
        local nr = rowsof(`R')
        forvalues l = 1/`nl1' {
            if `nby' > 0 display _newline as text "State `l': `by' = " as result `"`bylab`l''"'
            else display ""
            display as text "{hline 14}{c TT}{hline 64}"
            display as text %13s "Periods" " {c |}" %10s "Estimate" %10s "Std. err." %8s "t" %7s "P>|t|" ///
                %21s "[`level'% conf. interval]" %8s "Obs."
            display as text "{hline 14}{c +}{hline 64}"
            local prevtype -1
            forvalues i = 1/`nr' {
                if `nby' > 0 & `R'[`i', 12] != `l' continue
                if `prevtype' == 0 & `R'[`i', 1] == 1 display as text "{hline 14}{c +}{hline 64}"
                local prevtype = `R'[`i', 1]
                if `R'[`i', 1] == 0 local lab = string(`R'[`i', 2])
                else local lab = string(`R'[`i', 2]) + " to " + string(`R'[`i', 3])
                if `R'[`i', 11] == 1 {
                    display as text %13s "`lab'" " {c |}" as text %10s "0" as text "  (reference)"
                }
                else {
                    display as text %13s "`lab'" " {c |}" as result %10.4f `R'[`i', 4] %10.4f `R'[`i', 5] ///
                        %8.2f `R'[`i', 6] %7.3f `R'[`i', 7] %10.4f `R'[`i', 8] %11.4f `R'[`i', 9] %8.0f `R'[`i', 10]
                }
            }
            display as text "{hline 14}{c BT}{hline 64}"
        }
        if `Fpre' < . {
            display as text "Joint test that the `qpre' estimates before treatment are zero: F(" ///
                as result "`qpre'" as text ", " as result "`dfr'" as text ") = " as result %6.2f `Fpre' ///
                as text ", P = " as result %5.3f `ppre'
        }
        if `hasht' {
            display _newline as text "Test that the effect is the same in all states of `by'"
            if `nby' == 2 {
                display as text "{hline 14}{c TT}{hline 52}"
                display as text %13s "Periods" " {c |}" %9s "F" %6s "df" %8s "P>F" %15s "State 1 - 2" %11s "Std. err."
                display as text "{hline 14}{c +}{hline 52}"
            }
            else {
                display as text "{hline 14}{c TT}{hline 26}"
                display as text %13s "Periods" " {c |}" %9s "F" %6s "df" %8s "P>F"
                display as text "{hline 14}{c +}{hline 26}"
            }
            forvalues i = 1/`=rowsof(`HT')' {
                if `HT'[`i', 1] == 0 local lab = string(`HT'[`i', 2])
                else local lab = string(`HT'[`i', 2]) + " to " + string(`HT'[`i', 3])
                if `nby' == 2 {
                    display as text %13s "`lab'" " {c |}" as result %9.2f `HT'[`i', 4] %6.0f `HT'[`i', 5] ///
                        %8.3f `HT'[`i', 6] %15.4f `HT'[`i', 7] %11.4f `HT'[`i', 8]
                }
                else {
                    display as text %13s "`lab'" " {c |}" as result %9.2f `HT'[`i', 4] %6.0f `HT'[`i', 5] %8.3f `HT'[`i', 6]
                }
            }
            if `nby' == 2 display as text "{hline 14}{c BT}{hline 52}"
            else display as text "{hline 14}{c BT}{hline 26}"
        }
    }
    if `nest' > 0 & !`fullv' & `dovc' {
        display as text "Note: the covariances between the estimates could not be computed; e(V) is diagonal."
    }
    if `nfail' > 0 {
        display as error "Note: `nfail' regression(s) could not be estimated; last return code r(`lastrc')."
        if "`engine'" == "builtin" display as error "      With many fixed effects or weights that vary within a group, install reghdfe."
    }

    * ------------------------------------------------------------------ stored results
    ereturn clear
    if "`names'" != "" {
        matrix colnames `bb' = `names'
        matrix colnames `VF' = `names'
        matrix rownames `VF' = `names'
        if `dfr' < . ereturn post `bb' `VF', obs(`Nmax') depname(`y') esample(`esamp') dof(`dfr')
        else ereturn post `bb' `VF', obs(`Nmax') depname(`y') esample(`esamp')
    }
    ereturn matrix results = `R'
    if `hasht' ereturn matrix het = `HT'
    if `nby' > 0 {
        ereturn scalar n_by = `nby'
        ereturn local by "`by'"
        local bl ""
        forvalues l = 1/`nby' {
            local bl `"`bl' `l'=`bylab`l''"'
        }
        ereturn local by_levels `"`bl'"'
    }
    if "`aggregate'" != "ols" {
        ereturn matrix stack_b = `BS'
        ereturn matrix stack_w = `WS'
    }
    if `Nclmax' > 0 ereturn scalar N_clust = `Nclmax'
    ereturn scalar n_stacks = `ng'
    if `Fpre' < . {
        ereturn scalar F_pre = `Fpre'
        ereturn scalar df_pre = `qpre'
        ereturn scalar p_pre = `ppre'
    }
    ereturn local vfull = cond(`fullv', "full", "diagonal")
    ereturn scalar season = `season'
    ereturn scalar pre = `pre'
    ereturn scalar post = `post'
    ereturn scalar level = `level'
    ereturn local cohorts "`glist'"
    ereturn local absorb `"`fe'"'
    ereturn local aggregate "`aggregate'"
    ereturn local control "`control'"
    ereturn local transform "`transf'"
    ereturn local design = cond("`dd'" != "", "dd", "ddd")
    ereturn local clustvar = cond("`cluster'" == "", "`group'", "`cluster'")
    ereturn local depvar "`y'"
    if "`weight'" != "" {
        ereturn local wtype "`weight'"
        ereturn local wexp "`exp'"
    }
    ereturn local engine "`engine'"
    if "`tcode'" != "" ereturn local tcode "`tcode'"
    ereturn local vce "cluster"
    ereturn local vcetype "Robust"
    if "`dd'" != "" ereturn local title "Stacked local-projection difference-in-differences"
    else ereturn local title "Stacked local-projection triple differences"
    ereturn local cmdline `"`cmdline'"'
    ereturn local cmd "lpddd"
end


* one regression: the coefficient on the treatment indicator, or an explicitly
* weighted average of stack-specific coefficients estimated in one regression
* (the average and its variance are computed from e(b) and e(V) in double precision)
program define _lpddd_fit, rclass
    version 15.1
    syntax varname [if] , d(varname) clv(varname) agg(string) nst(integer) ///
        engine(string) mode(string) [ fe(string) wtype(string) nest(integer 0) ///
          col(integer 0) dovc(integer 0) nby(integer 0) ]
    local wx ""
    if "`wtype'" != "" local wx "[`wtype' = __lp_w]"
    tempname b se N df ncl bk wk bf Vf tot est var adj om Am Ai cm bby seby nbym
    local bydone 0
    local nb1 = max(1, `nby')
    matrix `bby' = J(1, `nb1', .)
    matrix `seby' = J(1, `nb1', .)
    matrix `nbym' = J(1, `nb1', .)
    tempvar eps smp zz psi
    local resok 0
    local vc 0
    local wmul ""
    if "`wtype'" != "" local wmul "* __lp_w"
    scalar `b' = .
    scalar `se' = .
    scalar `N' = .
    scalar `df' = .
    scalar `ncl' = .
    matrix `bk' = J(1, `nst', .)
    matrix `wk' = J(1, `nst', .)

    if `nby' > 0 {
        local x ""
        forvalues l = 1/`nby' {
            local x `x' __lp_B`l'
        }
    }
    else if "`agg'" == "ols" local x "`d'"
    else {
        local x ""
        forvalues k = 1/`nst' {
            local x `x' __lp_D`k'
        }
    }
    * the residuals are kept for the covariances between estimates (dovc)
    if "`engine'" == "reghdfe" {
        if `dovc' {
            capture reghdfe `varlist' `x' `if' `wx', absorb(`fe') vce(cluster `clv') residuals(`eps')
            local rc = _rc
            if `rc' == 0 local resok 1
            else {
                capture drop `eps'
                capture reghdfe `varlist' `x' `if' `wx', absorb(`fe') vce(cluster `clv')
                local rc = _rc
            }
        }
        else {
            capture reghdfe `varlist' `x' `if' `wx', absorb(`fe') vce(cluster `clv')
            local rc = _rc
        }
    }
    else {
        * observations alone in a cell of a fixed effect carry no information; reghdfe drops
        * them, repeatedly, and so do the built-in commands here, so that the number of
        * observations, of clusters and the standard errors are the same
        marksample touse
        if "`wtype'" != "" quietly replace `touse' = 0 if missing(__lp_w) | __lp_w <= 0
        local flist "__lp_fa"
        if "`mode'" != "one" local flist "__lp_fa __lp_fb"
        local changed 1
        while `changed' {
            local changed 0
            foreach f of local flist {
                tempvar nn
                quietly egen long `nn' = total(`touse'), by(`f')
                quietly count if `touse' & `nn' == 1
                if r(N) > 0 {
                    quietly replace `touse' = 0 if `touse' & `nn' == 1
                    local changed 1
                }
                drop `nn'
            }
        }
        if "`mode'" == "xt" {
            capture xtreg `varlist' `x' i.__lp_fb if `touse' `wx', fe vce(cluster `clv') nonest
        }
        else if "`mode'" == "two" {
            capture regress `varlist' `x' i.__lp_fa i.__lp_fb if `touse' `wx', vce(cluster `clv')
        }
        else {
            capture regress `varlist' `x' i.__lp_fa if `touse' `wx', vce(cluster `clv')
        }
        local rc = _rc
        if `rc' == 0 & `dovc' {
            if "`mode'" == "xt" capture predict double `eps' if e(sample), e
            else capture predict double `eps' if e(sample), residuals
            if _rc == 0 local resok 1
        }
    }
    if `rc' == 0 {
        quietly generate byte `smp' = e(sample)
        mata: _lpddd_mark("__lp_u", "`smp'")
    }

    * xtreg, fe counts only the identified indicator variables among the degrees of
    * freedom; reghdfe, with group effects nested in the clusters, counts every level
    * of the other fixed effect but one. The variance is rescaled to the count of
    * reghdfe so that the two engines report the same standard errors.
    scalar `adj' = 1
    if `rc' == 0 & "`engine'" != "reghdfe" & "`mode'" == "xt" & `nest' == 1 {
        matrix `bf' = e(b)
        _ms_omit_info `bf'
        local kx = colsof(`bf') - r(k_omit)
        matrix `om' = r(omit)
        local nx : word count `x'
        local kreg 0
        forvalues k = 1/`nx' {
            if `om'[1, `k'] == 0 local ++kreg
        }
        quietly levelsof __lp_fb if e(sample), local(lv)
        local nl : word count `lv'
        local kr = `kreg' + `nl'
        if e(N) - `kr' > 0 & e(N) - `kx' > 0 {
            scalar `adj' = (e(N) - `kx') / (e(N) - `kr')
        }
    }

    if `rc' == 0 {
        scalar `N' = e(N)
        scalar `df' = e(df_r)
        scalar `ncl' = e(N_clust)
        if `nby' > 0 {
            forvalues l = 1/`nby' {
                quietly count if `smp' & __lp_by == `l'
                matrix `nbym'[1, `l'] = r(N)
                capture scalar `est' = _b[__lp_B`l']
                if _rc == 0 {
                    scalar `var' = _se[__lp_B`l']
                    if `var' > 0 & `var' < . {
                        matrix `bby'[1, `l'] = `est'
                        matrix `seby'[1, `l'] = `var' * sqrt(`adj')
                        scalar `b' = 0
                        scalar `se' = 1
                    }
                }
            }
        }
        else if "`agg'" == "ols" {
            capture scalar `b' = _b[`d']
            if _rc == 0 scalar `se' = _se[`d'] * sqrt(`adj')
            else scalar `b' = .
        }
        else {
            matrix `bf' = e(b)
            matrix `Vf' = e(V) * `adj'
            local cn : colnames `bf'
            tempvar es
            quietly generate byte `es' = e(sample)
            scalar `tot' = 0
            forvalues k = 1/`nst' {
                matrix `wk'[1, `k'] = 0
                local nm : word `k' of `cn'
                local base = substr("`nm'", strrpos("`nm'", ".") + 1, .)
                if "`base'" == "__lp_D`k'" {
                    if `Vf'[`k', `k'] > 0 & `Vf'[`k', `k'] < . {
                        matrix `bk'[1, `k'] = `bf'[1, `k']
                        if "`agg'" == "equal" matrix `wk'[1, `k'] = 1
                        else {
                            quietly count if `es' & __lp_D`k' == 1
                            matrix `wk'[1, `k'] = r(N)
                        }
                        scalar `tot' = `tot' + `wk'[1, `k']
                    }
                }
            }
            if `tot' > 0 {
                scalar `est' = 0
                scalar `var' = 0
                forvalues k = 1/`nst' {
                    matrix `wk'[1, `k'] = `wk'[1, `k'] / `tot'
                }
                forvalues k = 1/`nst' {
                    if `wk'[1, `k'] > 0 {
                        scalar `est' = `est' + `wk'[1, `k'] * `bf'[1, `k']
                        forvalues l = 1/`nst' {
                            if `wk'[1, `l'] > 0 {
                                scalar `var' = `var' + `wk'[1, `k'] * `wk'[1, `l'] * `Vf'[`k', `l']
                            }
                        }
                    }
                }
                scalar `b' = `est'
                scalar `se' = sqrt(`var')
            }
        }
    }
    * influence of every observation on the estimate, summed by cluster in Mata:
    *   estimate = c * inv(X'WX) * X'W y, with X the treatment indicators after the fixed
    *   effects are removed; influence of observation i = c * inv(X'WX) * x_i * w_i * e_i
    if `rc' == 0 & `dovc' & `resok' & `col' > 0 & `se' > 0 & `se' < . {
        local ok 1
        local rlist ""
        local i 0
        foreach v of local x {
            local ++i
            tempvar r`i'
            if "`engine'" == "reghdfe" {
                capture reghdfe `v' if `smp' `wx', absorb(`fe') residuals(`r`i'')
            }
            else if "`mode'" == "xt" {
                capture xtreg `v' i.__lp_fb if `smp' `wx', fe
                if _rc == 0 capture predict double `r`i'' if `smp', e
            }
            else if "`mode'" == "two" {
                capture regress `v' i.__lp_fa i.__lp_fb if `smp' `wx'
                if _rc == 0 capture predict double `r`i'' if `smp', residuals
            }
            else {
                capture regress `v' i.__lp_fa if `smp' `wx'
                if _rc == 0 capture predict double `r`i'' if `smp', residuals
            }
            if _rc != 0 local ok 0
            local rlist `rlist' `r`i''
        }
        if `ok' & `nby' > 0 {
            * one influence per state: row l of inv(X'WX) times x_i * w_i * e_i
            if "`wtype'" != "" capture matrix accum `Am' = `rlist' if `smp' [iweight = __lp_w], noconstant
            else capture matrix accum `Am' = `rlist' if `smp', noconstant
            if _rc == 0 {
                matrix `Ai' = syminv(`Am')
                forvalues l = 1/`nby' {
                    if `seby'[1, `l'] < . {
                        capture drop `zz'
                        capture drop `psi'
                        quietly generate double `zz' = 0 if `smp'
                        forvalues k = 1/`nby' {
                            quietly replace `zz' = `zz' + `Ai'[`l', `k'] * `r`k'' if `smp'
                        }
                        quietly generate double `psi' = `zz' * `eps' `wmul' if `smp'
                        local cl = `col' + `l' - 1
                        mata: _lpddd_acc("`psi'", "`clv'", "`smp'", `cl')
                    }
                }
                local vc 1
            }
            local bydone 1
        }
        if `ok' & !`bydone' {
            if "`agg'" == "ols" {
                quietly generate double `zz' = `r1'^2 `wmul' if `smp'
                quietly summarize `zz', meanonly
                if r(sum) > 0 & r(sum) < . quietly replace `zz' = `r1' / r(sum) if `smp'
                else local ok 0
            }
            else {
                if "`wtype'" != "" capture matrix accum `Am' = `rlist' if `smp' [iweight = __lp_w], noconstant
                else capture matrix accum `Am' = `rlist' if `smp', noconstant
                if _rc != 0 local ok 0
                else {
                    matrix `Ai' = syminv(`Am')
                    matrix `cm' = `wk' * `Ai'
                    quietly generate double `zz' = 0 if `smp'
                    forvalues k = 1/`nst' {
                        quietly replace `zz' = `zz' + `cm'[1, `k'] * `r`k'' if `smp'
                    }
                }
            }
        }
        if `ok' & !`bydone' {
            quietly generate double `psi' = `zz' * `eps' `wmul' if `smp'
            mata: _lpddd_acc("`psi'", "`clv'", "`smp'", `col')
            local vc 1
        }
    }
    return scalar vc = `vc'
    return matrix bby = `bby'
    return matrix seby = `seby'
    return matrix nby = `nbym'
    return scalar b = `b'
    return scalar se = `se'
    return scalar N = `N'
    return scalar df = `df'
    return scalar ncl = `ncl'
    return scalar rc = `rc'
    return matrix bk = `bk'
    return matrix wk = `wk'
end


program define _lpddd_parsesave, rclass
    version 15.1
    syntax anything(name=fn) [, replace]
    return local file `"`fn'"'
    return local replace "`replace'"
end


* ---------------------------------------------------------------------- Mata
version 15.1
mata:
mata set matastrict off

void _lpddd_init(real scalar ncl, real scalar nc, real scalar nu)
{
    external real matrix LPDDD_S
    external real colvector LPDDD_U
    LPDDD_S = J(ncl, nc, 0)
    LPDDD_U = J(nu, 1, 0)
}

void _lpddd_mark(string scalar uvar, string scalar touse)
{
    external real colvector LPDDD_U
    real colvector u
    u = st_data(., uvar, touse)
    if (rows(u) > 0) LPDDD_U[u] = J(rows(u), 1, 1)
}

void _lpddd_acc(string scalar psi, string scalar cl, string scalar touse, real scalar col)
{
    external real matrix LPDDD_S
    real matrix X
    real scalar i
    X = st_data(., (psi, cl), touse)
    for (i = 1; i <= rows(X); i++) {
        if (X[i, 1] < . & X[i, 2] < .) {
            LPDDD_S[X[i, 2], col] = LPDDD_S[X[i, 2], col] + X[i, 1]
        }
    }
}

void _lpddd_V(string scalar ixname, string scalar sename, string scalar vname)
{
    external real matrix LPDDD_S
    real rowvector ix, se, ss, c
    real matrix S, V
    real scalar j
    ix = st_matrix(ixname)
    se = st_matrix(sename)
    S = LPDDD_S[., ix]
    ss = colsum(S:^2)
    c = J(1, cols(S), 0)
    for (j = 1; j <= cols(S); j++) {
        if (ss[j] > 0) c[j] = se[j] / sqrt(ss[j])
    }
    V = quadcross(S, S) :* (c' * c)
    V = (V + V') / 2
    for (j = 1; j <= cols(S); j++) {
        V[j, j] = se[j]^2
    }
    st_matrix(vname, V)
}

void _lpddd_esample(string scalar uvar, string scalar outvar)
{
    external real colvector LPDDD_U
    real colvector u, res
    real scalar i
    u = st_data(., uvar)
    res = J(rows(u), 1, 0)
    for (i = 1; i <= rows(u); i++) {
        if (u[i] < . & u[i] <= rows(LPDDD_U)) res[i] = LPDDD_U[u[i]]
    }
    st_store(., outvar, res)
}
end
