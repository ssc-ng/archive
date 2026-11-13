*! ev 0.2.2  EViews-style expressions as a prefix for estimation commands
*! Authors: Matthew Yeung and Aaron Tao
*!          School of Open Learning, Hong Kong Metropolitan University
*!          myeung@hkmu.edu.hk
program define ev, eclass
    version 14.0
    capture _on_colon_parse `0'
    if _rc {
        di as err "syntax: ev [, time(var) panel(var) freq(#) keep any]: estimator depvar exprlist [if] [in] [weight] [, options]"
        exit 198
    }
    local pre  `"`s(before)'"'
    local cmd  `"`s(after)'"'
    local 0 `"`pre'"'
    syntax [, Time(varname) Panel(varname) KEEP Freq(integer 0) ANY DELta(integer 0)]
    local useperm = ("`keep'" != "")

    gettoken cname rest : cmd
    if inlist("`cname'","reg","regr","regre","regres") local cname "regress"
    local okcmds "regress xtreg areg poisson nbreg logit probit ologit oprobit tobit qreg rreg newey glm xtpoisson xtlogit xtprobit xtnbreg mixed xtmixed reghdfe ppmlhdfe"
    local isok : list posof "`cname'" in okcmds
    if `isok' == 0 & "`any'" == "" {
        di as err "ev: `cname' not in the supported list; add the any option to try it"
        di as err "supported: `okcmds'"
        exit 199
    }

    * ---- split off options at first depth-0 comma
    local n = strlen(`"`rest'"')
    local depth 0
    local cpos 0
    forvalues i = 1/`n' {
        local ch = substr(`"`rest'"', `i', 1)
        if inlist("`ch'","(","[") local ++depth
        else if inlist("`ch'",")","]") local --depth
        else if "`ch'" == "," & `depth' == 0 {
            local cpos = `i'
            continue, break
        }
    }
    if `cpos' > 0 {
        local head = substr(`"`rest'"', 1, `cpos'-1)
        local opts = substr(`"`rest'"', `cpos', .)
    }
    else {
        local head `"`rest'"'
        local opts ""
    }

    * ---- tokenise head at depth-0 spaces; if / in / [weight] / || go to tail
    local head `"`head' "'
    local n = strlen(`"`head'"')
    local depth 0
    local tok ""
    local ntok 0
    local tail ""
    local intail 0
    forvalues i = 1/`n' {
        local ch = substr(`"`head'"', `i', 1)
        if `intail' {
            local tail `"`tail'`ch'"'
            continue
        }
        if inlist("`ch'","(","[") local ++depth
        if inlist("`ch'",")","]") local --depth
        if "`ch'" == " " & `depth' == 0 {
            if `"`tok'"' != "" {
                if inlist(`"`tok'"',"if","in") | substr(`"`tok'"',1,1) == "[" | substr(`"`tok'"',1,2) == "||" {
                    local intail 1
                    local tail `"`tok' "'
                }
                else {
                    local ++ntok
                    local tok`ntok' `"`tok'"'
                }
                local tok ""
            }
        }
        else local tok `"`tok'`ch'"'
    }
    if `ntok' < 2 {
        di as err "need a dependent variable and at least one regressor"
        exit 198
    }

    * ---- expand lag ranges x(-1 to -4) into separate tokens
    local M 0
    forvalues k = 1/`ntok' {
        local t `"`tok`k''"'
        if regexm(`"`t'"', "^([A-Za-z_][A-Za-z0-9_]*)\( *(-?[0-9]+) +to +(-?[0-9]+) *\)$") {
            local nm = regexs(1)
            local r1 = real(regexs(2))
            local r2 = real(regexs(3))
            local stp = cond(`r2' >= `r1', 1, -1)
            forvalues j = `r1'(`stp')`r2' {
                local ++M
                local tl`M' "`nm'(`j')"
            }
        }
        else {
            local ++M
            local tl`M' `"`t'"'
        }
    }

    * ---- remember tsset state (including delta)
    capture tsset
    local had = (_rc == 0)
    local t0 "`r(timevar)'"
    local p0 "`r(panelvar)'"
    local d0 = r(tdelta)
    if "`panel'" != "" & "`time'" == "" {
        di as err "panel() requires time()"
        exit 198
    }
    forvalues i = 1/60 {
        tempvar tv`i'
    }

    local nv 0
    local vlist ""
    local labs ""
    local timeset_by_us 0

    capture noisily {
        if "`time'" != "" {
            local dd = 1
            if `delta' > 0 local dd = `delta'
            else if `had' & "`time'" == "`t0'" local dd = `d0'
            if "`panel'" != "" xtset `panel' `time', delta(`dd')
            else tsset `time', delta(`dd')
            local timeset_by_us 1
        }
        capture tsset
        local declared = (_rc == 0)
        local cur_t "`r(timevar)'"
        local cur_p "`r(panelvar)'"
        local cur_fmt "`r(tsfmt)'"
        local cur_delta = r(tdelta)
        if missing(`cur_delta') local cur_delta 1

        if substr("`cname'",1,2) == "xt" & "`cname'" != "xtmixed" & "`cur_p'" == "" {
            di as err "ev: `cname' needs a panel. Use xtset first, or ev, panel(var) time(var): ..."
            error 459
        }

        forvalues k = 1/`M' {
            local t `"`tl`k''"'
            local orig `"`t'"'
            if lower(`"`t'"') == "c" continue
            if lower(`"`t'"') == "@trend" local t "@trend()"

            local plain = regexm(`"`t'"', "^[A-Za-z_0-9.#]+$")
            if !`plain' & strpos(`"`t'"',"(") == 0 & strpos(`"`t'"',"-") == 0 {
                capture unab _u : `t'
                if !_rc {
                    local plain 1
                    local t "`_u'"
                }
            }
            if `plain' {
                foreach w of local t {
                    local vlist `vlist' `w'
                    local labs `labs' `w'
                }
                continue
            }

            * ---- innermost-first function expansion
            local guard 0
            while regexm(`"`t'"', "([A-Za-z_@][A-Za-z0-9_.]*)\(([^()]*)\)") & `guard' < 50 {
                local ++guard
                local whole = regexs(0)
                local fn0   = regexs(1)
                local args  = regexs(2)
                local fn = subinstr(lower("`fn0'"), "@", "", .)
                tokenize `"`args'"', parse(",")
                local a1 = strtrim(`"`1'"')
                local a2 = strtrim(`"`3'"')
                local a3 = strtrim(`"`5'"')

                local ismath = inlist("`fn'","log","ln","exp","sqrt","abs")
                local ists   = inlist("`fn'","d","dlog","pch","pcha","pchy","movav","trend")
                local isfn   = `ismath' | `ists'
                local timedep = (!`isfn') | `ists'
                local expr ""

                if `timedep' & !`declared' {
                    di as err "ev: `whole' needs time-series data. Declare it with tsset/xtset, or use ev, time(var) [panel(var)]: ..."
                    error 459
                }

                if !`isfn' {
                    capture confirm variable `fn0'
                    if _rc | "`a2'" != "" {
                        di as err "ev: unknown function or variable `fn0'(`args')"
                        error 198
                    }
                    capture confirm integer number `a1'
                    if _rc {
                        di as err "ev: lag/lead argument must be an integer in `whole'"
                        error 198
                    }
                    if `a1' == 0 local expr "`fn0'"
                    else {
                        local m = abs(`a1')
                        local op = cond(`a1' < 0, "L", "F")
                        local expr "`op'`m'.`fn0'"
                    }
                }
                else if inlist("`fn'","log","ln") local expr "ln(`a1')"
                else if "`fn'" == "exp"  local expr "exp(`a1')"
                else if "`fn'" == "sqrt" local expr "sqrt(`a1')"
                else if "`fn'" == "abs"  local expr "abs(`a1')"
                else if "`fn'" == "trend" {
                    if "`a1'" == "" {
                        quietly summarize `cur_t', meanonly
                        local base = r(min)
                    }
                    else local base = real("`a1'")
                    if missing(`base') {
                        di as err "ev: bad base in `whole'"
                        error 198
                    }
                    local expr "(`cur_t' - `base')/`cur_delta'"
                }
                else {
                    capture confirm variable `a1'
                    if _rc {
                        local ++nv
                        if `nv' > 60 {
                            di as err "ev: expression too complex"
                            error 198
                        }
                        if `useperm' local nn "_evtmp`nv'"
                        else local nn "`tv`nv''"
                        _ev_mk, name(`nn') expr(`"`a1'"')
                        local a1 "`nn'"
                    }
                    if "`fn'" == "dlog" {
                        local ++nv
                        if `nv' > 60 {
                            di as err "ev: expression too complex"
                            error 198
                        }
                        if `useperm' local nn "_evtmp`nv'"
                        else local nn "`tv`nv''"
                        _ev_mk, name(`nn') expr(`"ln(`a1')"')
                        local a1 "`nn'"
                    }
                    if inlist("`fn'","d","dlog") {
                        local o = cond("`a2'" == "", 1, real("`a2'"))
                        if missing(`o') | `o' < 1 {
                            di as err "ev: bad difference order in `whole'"
                            error 198
                        }
                        if "`a3'" == "" local expr "D`o'.`a1'"
                        else {
                            capture confirm integer number `a3'
                            if _rc {
                                di as err "ev: bad seasonal lag in `whole'"
                                error 198
                            }
                            local expr "D`o'.S`a3'.`a1'"
                        }
                    }
                    else if "`fn'" == "pch" local expr "(`a1'/L.`a1' - 1)"
                    else if inlist("`fn'","pcha","pchy") {
                        local f = `freq'
                        if `f' == 0 {
                            local fm = substr("`cur_fmt'",1,3)
                            local f = cond("`fm'"=="%tq",4,cond("`fm'"=="%tm",12,cond("`fm'"=="%tw",52,cond("`fm'"=="%th",2,cond("`fm'"=="%ty",1,0)))))
                        }
                        if `f' == 0 {
                            di as err "ev: cannot infer periods per year for `whole'; use the freq(#) option"
                            error 198
                        }
                        if "`fn'" == "pcha" local expr "((`a1'/L.`a1')^`f' - 1)"
                        else local expr "(`a1'/L`f'.`a1' - 1)"
                    }
                    else if "`fn'" == "movav" {
                        local mw = real("`a2'")
                        if missing(`mw') | `mw' < 1 | `mw' > 60 {
                            di as err "ev: movav needs a window size 1-60 in `whole'"
                            error 198
                        }
                        local expr "`a1'"
                        forvalues j = 1/`=`mw'-1' {
                            local expr "`expr' + L`j'.`a1'"
                        }
                        local expr "(`expr')/`mw'"
                    }
                }

                local ++nv
                if `nv' > 60 {
                    di as err "ev: expression too complex"
                    error 198
                }
                if `useperm' local nn "_evtmp`nv'"
                else local nn "`tv`nv''"
                _ev_mk, name(`nn') expr(`"`expr'"')
                local t = subinstr(`"`t'"', `"`whole'"', "`nn'", 1)
            }
            if `guard' >= 50 {
                di as err "ev: could not parse `orig'"
                error 198
            }

            * ---- label and final variable for this token
            local lab = `"`orig'"'
            if regexm(`"`orig'"', "^[A-Za-z_][A-Za-z0-9_.]*\(-[0-9]+\)$") {
                local lab = subinstr(`"`lab'"', "(-", "_L", 1)
            }
            foreach c in "(" ")" "," "/" "^" "*" " " "+" "-" "@" {
                local lab = subinstr(`"`lab'"', "`c'", "_", .)
            }
            while strpos("`lab'", "__") {
                local lab = subinstr("`lab'", "__", "_", .)
            }
            while substr("`lab'", 1, 1) == "_" {
                local lab = substr("`lab'", 2, .)
            }
            if substr("`lab'", -1, 1) == "_" local lab = substr("`lab'", 1, strlen("`lab'")-1)

            capture confirm variable `t'
            local isvar = (_rc == 0)
            if `isvar' & !`useperm' {
                local fv "`t'"
            }
            else {
                if `useperm' local fv = abbrev("_ev_`lab'", 32)
                else {
                    local ++nv
                    if `nv' > 60 {
                        di as err "ev: expression too complex"
                        error 198
                    }
                    local fv "`tv`nv''"
                }
                _ev_mk, name(`fv') expr(`"`t'"')
            }
            local vlist `vlist' `fv'
            local labs  `labs' `=abbrev("`lab'",32)'
        }

        * ---- run the estimator
        quietly `cname' `vlist' `tail' `opts'

        * ---- relabel coefficients (non-keep mode)
        if !`useperm' {
            tempname b V
            matrix `b' = e(b)
            matrix `V' = e(V)
            local cn : colnames `b'
            local newcn ""
            foreach c of local cn {
                local pfx ""
                local c2 "`c'"
                if substr("`c'",1,2) == "o." {
                    local pfx "o."
                    local c2 = substr("`c'",3,.)
                }
                local new "`c'"
                local j 0
                foreach v of local vlist {
                    local ++j
                    if "`c2'" == "`v'" local new "`pfx'`: word `j' of `labs''"
                }
                local newcn `newcn' `new'
            }
            capture {
                matrix colnames `b' = `newcn'
                matrix colnames `V' = `newcn'
                matrix rownames `V' = `newcn'
                ereturn repost b = `b' V = `V', rename
            }
            if _rc {
                di as txt "(ev: could not relabel coefficients; temporary names are shown)"
            }
            else {
                local dep : word 1 of `labs'
                ereturn local depvar "`dep'"
            }
        }
        ereturn local ev_cmdline `"`cmd'"'
        local ecmd "`e(cmd)'"
        if "`ecmd'" == "" local ecmd "`cname'"
        `ecmd'
    }
    local rc = _rc

    * ---- drop intermediates left by keep mode
    if `useperm' capture drop _evtmp*

    * ---- restore the user's tsset state
    if `timeset_by_us' {
        if `had' {
            if "`p0'" != "" capture xtset `p0' `t0', delta(`d0')
            else capture tsset `t0', delta(`d0')
        }
        else capture tsset, clear
    }
    if `rc' exit `rc'
end

program define _ev_mk
    syntax , name(string) expr(string)
    capture drop `name'
    quietly generate double `name' = `expr'
end
