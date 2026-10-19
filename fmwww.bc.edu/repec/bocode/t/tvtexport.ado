*! tvtexport 1.1.0  13oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Publication tables for TVTHRESH estimates: LaTeX, Markdown, RTF or CSV.
*!
*! This is not a general-purpose table writer and does not try to be one.
*! What it knows that a general one does not is WHERE EACH COMMAND PUTS ITS
*! THRESHOLD, so the table carries the three panels a threshold paper
*! actually reports -- coefficients, the threshold itself, and the tests --
*! rather than a coefficient block with the interesting part left out.

program define tvtexport
    version 15

    syntax [using/] [, ///
        EST(string)                   ///
        FORMat(string)                ///
        Title(string)                 ///
        NOTE(string)                  ///
        Level(cilevel)                ///
        STARs(string)                 ///
        noCOEFs                       ///
        noTHReshold                   ///
        noTESTs                       ///
        noDIAGnostics                 ///
        REPLACE ]

    * ------------------------------------------------------- the format
    if "`format'" == "" {
        if `"`using'"' != "" {
            local ext = lower(substr(`"`using'"', strpos(`"`using'"', ".") + 1, .))
            if "`ext'" == "tex"  local format latex
            if "`ext'" == "md"   local format markdown
            if "`ext'" == "rtf"  local format rtf
            if "`ext'" == "csv"  local format csv
        }
    }
    if "`format'" == "" local format markdown
    local format = lower("`format'")
    if !inlist("`format'", "latex", "markdown", "rtf", "csv") {
        display as error "{bf:format()} must be {bf:latex}, {bf:markdown}," ///
            " {bf:rtf} or {bf:csv}"
        exit 198
    }

    if "`stars'" == "" local stars 0.10 0.05 0.01
    local nst : word count `stars'
    if `nst' != 3 {
        display as error "{bf:stars()} needs exactly three levels," ///
            " largest first, e.g. {bf:stars(0.10 0.05 0.01)}"
        exit 198
    }
    local s1 : word 1 of `stars'
    local s2 : word 2 of `stars'
    local s3 : word 3 of `stars'
    * THE ORDER IS NOT COSMETIC. The star logic applies the three cutoffs
    * in sequence, each overwriting the last, so it only gives the right
    * answer if they DESCEND. Fed stars(0.01 0.05 0.10) it would award
    * *** to a p-value of 0.08 -- significant at ten percent, printed as
    * significant at one -- and the table would carry inverted stars into
    * a paper with nothing to show anything was wrong. Checked, not
    * merely documented.
    if !(`s1' > `s2' & `s2' > `s3') {
        display as error "{bf:stars()} must be strictly DESCENDING," ///
            " e.g. {bf:stars(0.10 0.05 0.01)}"
        display as error "you gave `stars', which would print more stars" ///
            " for a weaker result"
        exit 198
    }
    if `s3' <= 0 | `s1' >= 1 {
        display as error "{bf:stars()} levels must lie strictly between" ///
            " 0 and 1"
        exit 198
    }

    * --------------------------------------------- which estimates to use
    if "`est'" == "" {
        if "`e(cmd)'" == "" {
            display as error "no estimation results in memory"
            display as error "{bf:tvtexport} writes a table from TVTHRESH" ///
                " estimates. Either run an"
            display as error "estimator first, or name stored ones with" ///
                " {bf:est(}{it:namelist}{bf:)}."
            exit 301
        }
        tempname cur
        quietly estimates store `cur'
        local est `cur'
    }
    local ncol : word count `est'

    * verify each one is ours, and collect what we need BEFORE writing
    local k 0
    foreach e of local est {
        local ++k
        capture quietly estimates restore `e'
        if _rc {
            display as error "stored estimates {bf:`e'} not found"
            exit 111
        }
        local c`k'cmd "`e(cmd)'"
        if substr("`c`k'cmd'", 1, 3) != "tvt" {
            display as error "{bf:`e'} was left by {bf:`c`k'cmd''}," ///
                " which is not a TVTHRESH estimator"
            display as error "{bf:tvtexport} reads the threshold out of" ///
                " e(), so it only knows this"
            display as error "library's commands."
            exit 198
        }
        local c`k'dep   "`e(depvar)'"
        local c`k'ttl   "`e(title)'"
        local c`k'N     = e(N)
    }

    * --------------------------------------------------------- the rows
    * the union of coefficient names, in first-appearance order
    local allnm
    forvalues j = 1/`ncol' {
        local e : word `j' of `est'
        quietly estimates restore `e'
        local nm : colnames e(b)
        local eq : coleq e(b)
        local nn : word count `nm'
        forvalues i = 1/`nn' {
            local v : word `i' of `nm'
            local q : word `i' of `eq'
            local key "`q'!`v'"
            local seen 0
            foreach a of local allnm {
                if "`a'" == "`key'" local seen 1
            }
            if !`seen' local allnm `allnm' `key'
        }
    }

    tempname fh
    if `"`using'"' == "" {
        * no file: show it on screen as markdown
        local format markdown
        local toscreen 1
    }
    else {
        local toscreen 0
        capture confirm file `"`using'"'
        if _rc == 0 & "`replace'" == "" {
            display as error "file `using' already exists; use" ///
                " {bf:replace}"
            exit 602
        }
        file open `fh' using `"`using'"', write text replace
    }

    * ------------------------------------------------------------ write
    Wopen `fh' `toscreen' "`format'" `ncol' `"`title'"'

    * --- header row
    local hdr "Dependent variable"
    forvalues j = 1/`ncol' {
        local hdr `"`hdr'|`c`j'dep'"'
    }
    Wrow `fh' `toscreen' "`format'" `ncol' `"`hdr'"' head
    local hdr "Specification"
    forvalues j = 1/`ncol' {
        local hdr `"`hdr'|`c`j'cmd'"'
    }
    Wrow `fh' `toscreen' "`format'" `ncol' `"`hdr'"' sub

    * --- panel A: coefficients
    local anyse 0
    if "`coefs'" != "nocoefs" {
        Wpanel `fh' `toscreen' "`format'" `ncol' "A. Coefficients"
        local lasteq ""
        foreach key of local allnm {
            local q = substr("`key'", 1, strpos("`key'", "!") - 1)
            local v = substr("`key'", strpos("`key'", "!") + 1, .)
            if "`q'" != "`lasteq'" & "`q'" != "_" & "`q'" != "" {
                Wpanel `fh' `toscreen' "`format'" `ncol' "  `q'"
                local lasteq "`q'"
            }
            local r1 "`v'"
            local r2 " "
            forvalues j = 1/`ncol' {
                local e : word `j' of `est'
                quietly estimates restore `e'
                capture local b = _b[`q':`v']
                if _rc {
                    local r1 `"`r1'|"'
                    local r2 `"`r2'|"'
                    continue
                }
                local s = _se[`q':`v']
                if `b' == 0 & `s' == 0 {
                    local r1 `"`r1'|"'
                    local r2 `"`r2'|"'
                    continue
                }
                local st ""
                if `s' > 0 & `s' < . {
                    local p = 2*normal(-abs(`b'/`s'))
                    if `p' <= `s1' local st "*"
                    if `p' <= `s2' local st "**"
                    if `p' <= `s3' local st "***"
                }
                local r1 `"`r1'|`=string(`b',"%9.4f")'`st'"'
                * A standard error of EXACTLY zero is not an estimate of
                * anything -- it means the command posted a zero e(V)
                * because ereturn post demands one. tvtcovdep does exactly
                * that, deliberately, and printing "(0.0000)" underneath
                * its coefficients would be the one thing it refuses to
                * claim. Leave the cell blank instead.
                if `s' > 0 & `s' < . {
                    local r2 `"`r2'|(`=string(`s',"%9.4f")')"'
                    local anyse 1
                }
                else local r2 `"`r2'|"'
            }
            Wrow `fh' `toscreen' "`format'" `ncol' `"`r1'"'
            Wrow `fh' `toscreen' "`format'" `ncol' `"`r2'"'
        }
    }

    * --- panel B: the threshold itself, which is the point of the table
    if "`threshold'" != "nothreshold" {
        Wpanel `fh' `toscreen' "`format'" `ncol' "B. The threshold"
        foreach it in gamma1 gamma0 threshold gamma_const m c bwidth {
            local lbl "`it'"
            if "`it'" == "gamma1"      local lbl "gamma_1 (intercept)"
            if "`it'" == "gamma0"      local lbl "gamma_0 (intercept)"
            if "`it'" == "threshold"   local lbl "threshold level"
            if "`it'" == "gamma_const" local lbl "constant-threshold comparison"
            if "`it'" == "m"           local lbl "memory m"
            if "`it'" == "c"           local lbl "percentile c"
            if "`it'" == "bwidth"      local lbl "smoothing bandwidth"
            local any 0
            local r "`lbl'"
            forvalues j = 1/`ncol' {
                local e : word `j' of `est'
                quietly estimates restore `e'
                * SOME OF THESE NAMES ARE MATRICES IN SOME COMMANDS.
                * tvtcoint and tvtcovdep both store e(gamma1) as a ROW
                * VECTOR of threshold slopes, one per z, and reading a
                * matrix-valued e() in a scalar expression is r(509),
                * "matrix operators that return matrices not allowed in
                * this context" -- which crashed the whole table rather
                * than skipping one row. The vector is written out below,
                * a row per z; here the read is simply guarded.
                capture local val = e(`it')
                if _rc local val = .
                if `val' < . {
                    local r `"`r'|`=string(`val',"%9.4f")'"'
                    local any 1
                }
                else local r `"`r'|"'
            }
            if `any' Wrow `fh' `toscreen' "`format'" `ncol' `"`r'"'
        }

        * --- the threshold SLOPES, which are a vector and so need a row
        * each. The union of z names across the columns, in first
        * appearance order, so two commands with different z lists line up.
        local allz
        forvalues j = 1/`ncol' {
            local e : word `j' of `est'
            quietly estimates restore `e'
            capture confirm matrix e(gamma1)
            if !_rc {
                tempname G
                matrix `G' = e(gamma1)
                local gn : colnames `G'
                foreach zz of local gn {
                    local seen 0
                    foreach a of local allz {
                        if "`a'" == "`zz'" local seen 1
                    }
                    if !`seen' local allz `allz' `zz'
                }
            }
        }
        foreach zz of local allz {
            local r "gamma_1 on `zz'"
            local any 0
            forvalues j = 1/`ncol' {
                local e : word `j' of `est'
                quietly estimates restore `e'
                local val = .
                capture confirm matrix e(gamma1)
                if !_rc {
                    tempname G
                    matrix `G' = e(gamma1)
                    local gn : colnames `G'
                    local pos 0
                    local k 0
                    foreach a of local gn {
                        local ++k
                        if "`a'" == "`zz'" local pos `k'
                    }
                    if `pos' > 0 local val = `G'[1, `pos']
                    * a command that SELECTS its threshold variables
                    * reports an exact zero for the ones it dropped; that
                    * is an exclusion, not an estimate of zero, so leave
                    * the cell blank exactly as the coefficient panel does
                    capture confirm matrix e(zselected)
                    if !_rc & `pos' > 0 {
                        tempname ZS
                        matrix `ZS' = e(zselected)
                        if `ZS'[1, `pos'] == 0 local val = .
                    }
                }
                if `val' < . {
                    local r `"`r'|`=string(`val',"%9.4f")'"'
                    local any 1
                }
                else local r `"`r'|"'
            }
            if `any' Wrow `fh' `toscreen' "`format'" `ncol' `"`r'"'
        }
        * regime sizes, whatever each command calls them
        local r "observations per regime"
        local any 0
        forvalues j = 1/`ncol' {
            local e : word `j' of `est'
            quietly estimates restore `e'
            local lo = .
            local hi = .
            if e(N_lower) < . {
                local lo = e(N_lower)
                local hi = e(N_upper)
            }
            else if e(N_below) < . {
                local lo = e(N_below)
                local hi = e(N_above)
            }
            if `lo' < . {
                local r `"`r'|`=string(`lo',"%9.0f")' / `=string(`hi',"%9.0f")'"'
                local any 1
            }
            else local r `"`r'|"'
        }
        if `any' Wrow `fh' `toscreen' "`format'" `ncol' `"`r'"'
    }

    * --- panel C: the tests
    if "`tests'" != "notests" {
        * a panel header with nothing under it is worse than no panel, and
        * tvtindex reports no test at all, so look before writing it
        local anytest 0
        foreach t in F1 F2 F1C F1T score wald supW aveW expW supLM aveLM expLM {
            forvalues j = 1/`ncol' {
                local e : word `j' of `est'
                quietly estimates restore `e'
                capture local tv = e(`t')
                if _rc local tv = .
                if `tv' < . local anytest 1
            }
        }
        if `anytest' Wpanel `fh' `toscreen' "`format'" `ncol' "C. Tests"
        foreach t in F1 F2 F1C F1T score wald supW aveW expW supLM aveLM expLM {
            local lbl "`t'"
            if "`t'" == "F1"    local lbl "F1  (no threshold effect)"
            if "`t'" == "F2"    local lbl "F2  (threshold is constant)"
            if "`t'" == "F1C"   local lbl "F1C (linear vs constant kink)"
            if "`t'" == "F1T"   local lbl "F1T (linear vs moving kink)"
            if "`t'" == "score" local lbl "score (no threshold effect)"
            if "`t'" == "wald"  local lbl "Wald (no threshold effect)"
            local any 0
            local r "`lbl'"
            local rp " "
            forvalues j = 1/`ncol' {
                local e : word `j' of `est'
                quietly estimates restore `e'
                capture local tv = e(`t')
                if _rc local tv = .
                if `tv' < . {
                    capture local pv = e(p_`t')
                    if _rc local pv = .
                    local st ""
                    if `pv' < . {
                        if `pv' <= `s1' local st "*"
                        if `pv' <= `s2' local st "**"
                        if `pv' <= `s3' local st "***"
                    }
                    local r `"`r'|`=string(`tv',"%9.3f")'`st'"'
                    if `pv' < . local rp `"`rp'|[`=string(`pv',"%5.3f")']"'
                    else        local rp `"`rp'|"'
                    local any 1
                }
                else {
                    local r  `"`r'|"'
                    local rp `"`rp'|"'
                }
            }
            if `any' {
                Wrow `fh' `toscreen' "`format'" `ncol' `"`r'"'
                Wrow `fh' `toscreen' "`format'" `ncol' `"`rp'"'
            }
        }
    }

    * --- panel D: diagnostics
    if "`diagnostics'" != "nodiagnostics" {
        Wpanel `fh' `toscreen' "`format'" `ncol' "D. Fit"
        foreach d in ssr ssr_lin ssr_const reps npi simreps N {
            local lbl "`d'"
            if "`d'" == "ssr"       local lbl "SSR, threshold model"
            if "`d'" == "ssr_lin"   local lbl "SSR, linear model"
            if "`d'" == "ssr_const" local lbl "SSR, constant threshold"
            if "`d'" == "reps"      local lbl "bootstrap replications"
            if "`d'" == "npi"       local lbl "posterior draws"
            if "`d'" == "simreps"   local lbl "simulation draws"
            if "`d'" == "N"         local lbl "Observations"
            local any 0
            local r "`lbl'"
            forvalues j = 1/`ncol' {
                local e : word `j' of `est'
                quietly estimates restore `e'
                capture local dv = e(`d')
                if _rc local dv = .
                if `dv' < . {
                    local fmt = cond(inlist("`d'","reps","npi","simreps","N"), ///
                                     "%9.0fc", "%12.4f")
                    local r `"`r'|`=string(`dv',"`fmt'")'"'
                    local any 1
                }
                else local r `"`r'|"'
            }
            if `any' Wrow `fh' `toscreen' "`format'" `ncol' `"`r'"'
        }
    }

    * The default note must describe THIS table. tvtcovdep reports no
    * standard errors at all, so promising them in parentheses underneath
    * a table that has none would be the table telling a small lie.
    local nt `"`note'"'
    if `"`nt'"' == "" {
        if `anyse' local nt "Standard errors in parentheses, p-values in brackets."
        else       local nt "p-values in brackets. No standard errors are reported."
    }
    local nt `"`nt' Stars: * p<`s1', ** p<`s2', *** p<`s3'."'
    Wclose `fh' `toscreen' "`format'" `ncol' `"`nt'"'

    if !`toscreen' {
        file close `fh'
        display as text "table written to " as result `"`using'"' ///
            as text " (`format', `ncol' column" ///
            cond(`ncol'>1,"s","") ")"
    }
end

* =====================================================================
* the four writers. Rows arrive as a single string with | separators, so
* only these four programs know anything about the output format.
* =====================================================================
program define Wopen
    version 15
    args fh scr fmt ncol title
    if "`fmt'" == "latex" {
        local spec "l"
        forvalues j = 1/`ncol' {
            local spec "`spec'c"
        }
        Put `fh' `scr' "\begin{table}[htbp]"
        Put `fh' `scr' "\centering"
        if `"`title'"' != "" Put `fh' `scr' `"\caption{`title'}"'
        Put `fh' `scr' "\begin{tabular}{`spec'}"
        Put `fh' `scr' "\toprule"
    }
    else if "`fmt'" == "rtf" {
        Put `fh' `scr' "{\rtf1\ansi\deff0"
        Put `fh' `scr' "{\fonttbl{\f0 Times New Roman;}}"
        if `"`title'"' != "" Put `fh' `scr' `"\f0\fs24\b `title'\b0\par"'
        Put `fh' `scr' "\f0\fs20"
    }
    else if "`fmt'" == "csv" {
        if `"`title'"' != "" Put `fh' `scr' `""`title'""'
    }
    else {
        if `"`title'"' != "" {
            Put `fh' `scr' `"**`title'**"'
            Put `fh' `scr' ""
        }
    }
end

program define Wrow
    version 15
    gettoken fh   0 : 0
    gettoken scr  0 : 0
    gettoken fmt  0 : 0
    gettoken ncl  0 : 0
    gettoken row  0 : 0
    local kind `"`0'"'
    local out ""
    local n = 0
    local rest `"`row'"'
    * exactly ncl+1 cells, always. Splitting until the remainder is empty
    * would silently drop a trailing EMPTY cell, which is exactly what a
    * row for a quantity only one column reports looks like.
    forvalues c = 1/`=`ncl'+1' {
        local p = strpos(`"`rest'"', "|")
        if `p' == 0 {
            local cell `"`rest'"'
            local rest ""
        }
        else {
            local cell = substr(`"`rest'"', 1, `p' - 1)
            local rest = substr(`"`rest'"', `p' + 1, .)
        }
        local ++n
        local cell = trim(`"`cell'"')
        if "`fmt'" == "latex" {
            local cell = subinstr(`"`cell'"', "_", "\_", .)
            if "`kind'" == "head" local cell `"\textbf{`cell'}"'
            if `n' == 1 local out `"`cell'"'
            else        local out `"`out' & `cell'"'
        }
        else if "`fmt'" == "csv" {
            if `n' == 1 local out `""`cell'""'
            else        local out `"`out',"`cell'""'
        }
        else if "`fmt'" == "rtf" {
            if `n' == 1 local out `"`cell'"'
            else        local out `"`out'\tab `cell'"'
        }
        else {
            if `n' == 1 local out `"| `cell' "'
            else        local out `"`out'| `cell' "'
        }
    }
    if "`fmt'" == "latex" {
        Put `fh' `scr' `"`out' \\"'
        if "`kind'" == "sub" Put `fh' `scr' "\midrule"
    }
    else if "`fmt'" == "rtf" {
        Put `fh' `scr' `"`out'\par"'
    }
    else if "`fmt'" == "csv" {
        Put `fh' `scr' `"`out'"'
    }
    else {
        Put `fh' `scr' `"`out'|"'
        if "`kind'" == "sub" {
            local sep "|"
            forvalues j = 1/`n' {
                local sep "`sep'---|"
            }
            Put `fh' `scr' `"`sep'"'
        }
    }
end

program define Wpanel
    version 15
    args fh scr fmt ncol lbl
    if "`fmt'" == "latex" {
        local l = subinstr(`"`lbl'"', "_", "\_", .)
        Put `fh' `scr' `"\multicolumn{`=`ncol'+1'}{l}{\textit{`l'}} \\"'
    }
    else if "`fmt'" == "rtf" {
        Put `fh' `scr' `"\i `lbl'\i0\par"'
    }
    else if "`fmt'" == "csv" {
        Put `fh' `scr' `""`lbl'""'
    }
    else {
        local out `"| *`lbl'* "'
        forvalues j = 1/`ncol' {
            local out `"`out'| "'
        }
        Put `fh' `scr' `"`out'|"'
    }
end

program define Wclose
    version 15
    args fh scr fmt ncol note
    if "`fmt'" == "latex" {
        Put `fh' `scr' "\bottomrule"
        Put `fh' `scr' "\end{tabular}"
        if `"`note'"' != "" {
            local nt = subinstr(`"`note'"', "_", "\_", .)
            local nt = subinstr(`"`nt'"', "<", "$<$", .)
            Put `fh' `scr' `"\begin{tablenotes}\small \item `nt'\end{tablenotes}"'
        }
        Put `fh' `scr' "\end{table}"
    }
    else if "`fmt'" == "rtf" {
        if `"`note'"' != "" Put `fh' `scr' `"\par\fs16 `note'\par"'
        Put `fh' `scr' "}"
    }
    else if "`fmt'" == "csv" {
        if `"`note'"' != "" Put `fh' `scr' `""`note'""'
    }
    else {
        Put `fh' `scr' ""
        if `"`note'"' != "" Put `fh' `scr' `"*`note'*"'
    }
end

program define Put
    version 15
    gettoken fh  0 : 0
    gettoken scr 0 : 0
    * `0' still carries its compound-quote delimiters after gettoken, so
    * it is expanded rather than re-quoted -- `"`0'"' would print them
    local txt `0'
    if `scr' {
        display as text `"`txt'"'
    }
    else {
        file write `fh' `"`txt'"' _n
    }
end
