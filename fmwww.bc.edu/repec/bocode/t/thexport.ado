*! thexport 1.0.0  06oct2026
*! Dr Merwan Roudane (merwanroudane920@gmail.com) github.com/merwanroudane
*!
*! Export a publication table from any THRESHKIT fit: LaTeX, Markdown or CSV.
*!
*! See thexport.sthlp. The design principle: a threshold model's table needs
*! things an ordinary regression table does not, and leaving them out is the
*! commonest way such a table misleads. So the footer is not decoration -- it
*! carries the threshold, its CONFIDENCE SET (which need not be an interval),
*! the regime sizes, and the no-threshold test with its BOOTSTRAP p-value. A
*! table that reports a threshold as a bare point estimate, or quotes a
*! nominal p-value for a statistic that was maximised over a grid, is exactly
*! the error this command exists to prevent.

program define thexport, rclass
    version 15

    syntax [using/] [, ///
        FORMat(string)      ///
        REPLACE             ///
        TITLE(string)       ///
        Level(cilevel)      ///
        DECimals(integer 3) ///
        NOFooter            ///
        NOStars             ///
        NOTE(string)        ///
        ]

    * ---- it must be a THRESHKIT fit.
    * The membership test is done with strpos on a padded list, not with the
    * "list ... in ..." extended function: that function takes macro NAMES,
    * not literals, and quietly returns 0 when handed a value.
    if "`e(cmd)'" == "" {
        display as error "no estimation results in memory"
        exit 301
    }
    local known "thregress thtar thkink thstr thstar thmtar thqreg thtqar"
    local known "`known' thqkink thivreg thtvar thtvecm thstvar thunitroot"
    local wascmd "`e(cmd)'"
    if strpos(" `known' ", " `wascmd' ") == 0 {
        display as error "{bf:thexport} works after a THRESHKIT estimation"
        display as error "command. {bf:e(cmd)} is {bf:`wascmd'}, which is not"
        display as error "one of: `known'"
        exit 301
    }

    if "`level'" == "" local level = c(level)

    if "`format'" == "" {
        if `"`using'"' != "" {
            local ext = lower(substr(`"`using'"', strrpos(`"`using'"', ".") + 1, .))
            if "`ext'" == "tex" local format latex
            if "`ext'" == "md"  local format markdown
            if "`ext'" == "txt" local format markdown
            if "`ext'" == "csv" local format csv
        }
        if "`format'" == "" local format latex
    }
    local format = lower("`format'")
    if !inlist("`format'", "latex", "markdown", "csv") {
        display as error "format() must be latex, markdown or csv"
        exit 198
    }
    if `decimals' < 1 | `decimals' > 8 {
        display as error "decimals() must be between 1 and 8"
        exit 198
    }
    local fmt "%12.`decimals'f"
    if "`title'" == "" local title "Threshold model estimates"
    * footer-line count, so r(n_note) is defined whether or not the footer runs
    local nnote 0

    * ---- the coefficient block
    tempname B V
    matrix `B' = e(b)
    matrix `V' = e(V)
    local k = colsof(`B')
    local cn : colnames `B'
    local ce : coleq `B'

    * the distinct equations, in order -- these become the table's panels
    local eqs ""
    foreach q of local ce {
        local seen : list q in eqs
        if !`seen' local eqs `eqs' `q'
    }
    local neq : word count `eqs'
    local eq1 : word 1 of `eqs'
    * a single unnamed equation means a flat table, not a panelled one
    if `neq' == 1 & ("`eq1'" == "_" | "`eq1'" == "") local neq 0

    local crit = invnormal(1 - (100 - `level')/200)

    * ---- open the file, or preview on the screen
    tempname fh
    local toscreen = (`"`using'"' == "")
    if !`toscreen' {
        if "`replace'" == "" {
            capture confirm new file `"`using'"'
            if _rc {
                display as error `"file `using' already exists; use {bf:replace}"'
                exit 602
            }
        }
        file open `fh' using `"`using'"', write text replace
    }

    * ==================================================== the header
    * No dollar signs anywhere in the LaTeX. Stata expands $z and $p as
    * GLOBAL MACROS inside a double-quoted string, so a header written as
    * \$z\$ would silently come out empty -- the column heading would just
    * vanish, and nothing would report an error. Italic z and p need no
    * math mode, so the problem is avoided rather than escaped.
    if "`format'" == "latex" {
        _tk_xline `toscreen' "`fh'" "\begin{table}[htbp]"
        _tk_xline `toscreen' "`fh'" "\centering"
        _tk_xline `toscreen' "`fh'" "\caption{`title'}"
        _tk_xline `toscreen' "`fh'" "\begin{tabular}{lrrrr}"
        _tk_xline `toscreen' "`fh'" "\toprule"
        _tk_xline `toscreen' "`fh'" " & Coef. & Std. err. & {\itshape z} & {\itshape p} \\"
        _tk_xline `toscreen' "`fh'" "\midrule"
    }
    else if "`format'" == "markdown" {
        _tk_xline `toscreen' "`fh'" "## `title'"
        _tk_xline `toscreen' "`fh'" ""
        _tk_xline `toscreen' "`fh'" "| | Coef. | Std. err. | z | p |"
        _tk_xline `toscreen' "`fh'" "|---|---:|---:|---:|---:|"
    }
    else {
        _tk_xline `toscreen' "`fh'" "equation,term,coef,se,z,p,ci_low,ci_high"
    }

    local lasteq ""
    forvalues j = 1/`k' {
        local nm : word `j' of `cn'
        local eq : word `j' of `ce'
        local b  = `B'[1,`j']
        local se = sqrt(`V'[`j',`j'])
        local z  = cond(`se' > 0 & `se' < ., `b'/`se', .)
        local pv = cond(`z' < ., 2*normal(-abs(`z')), .)
        local lo = `b' - `crit'*`se'
        local hi = `b' + `crit'*`se'

        local st ""
        if "`nostars'" == "" & `pv' < . {
            if `pv' < 0.01      local st "***"
            else if `pv' < 0.05 local st "**"
            else if `pv' < 0.10 local st "*"
        }

        * a panel header whenever the equation changes
        if `neq' > 0 & "`eq'" != "`lasteq'" {
            local eqlab = subinstr("`eq'", "_", " ", .)
            if "`format'" == "latex" {
                if "`lasteq'" != "" _tk_xline `toscreen' "`fh'" "\addlinespace"
                _tk_xline `toscreen' "`fh'" "\multicolumn{5}{l}{\textit{`eqlab'}} \\"
            }
            else if "`format'" == "markdown" {
                _tk_xline `toscreen' "`fh'" "| **`eqlab'** | | | | |"
            }
            local lasteq "`eq'"
        }

        if "`format'" == "latex" {
            * LaTeX-escape the term name. Names come from colnames e(b) and
            * routinely carry underscores (_cons) and hashes (factor-variable
            * interactions); unescaped, those break the compile of the USER'S
            * document, not of anything in Stata -- the worst place to find
            * out. Done inline rather than in a subroutine because a Stata
            * subroutine reads `0' WITH its enclosing quotes, which would put
            * literal quote marks into the table.
            local nmx `"`nm'"'
            local nmx = subinstr(`"`nmx'"', "_", "\_", .)
            local nmx = subinstr(`"`nmx'"', "#", "\#", .)
            local nmx = subinstr(`"`nmx'"', "&", "\&", .)
            local nmx = subinstr(`"`nmx'"', "%", "\%", .)
            local row = "`nmx' & " + trim(string(`b', "`fmt'")) + "`st' & " ///
                + trim(string(`se', "`fmt'")) + " & " + trim(string(`z', "%8.2f")) ///
                + " & " + trim(string(`pv', "%6.3f")) + " \\"
            _tk_xline `toscreen' "`fh'" "`row'"
        }
        else if "`format'" == "markdown" {
            local row = "| `nm' | " + trim(string(`b', "`fmt'")) + "`st' | " ///
                + trim(string(`se', "`fmt'")) + " | " + trim(string(`z', "%8.2f")) ///
                + " | " + trim(string(`pv', "%6.3f")) + " |"
            _tk_xline `toscreen' "`fh'" "`row'"
        }
        else {
            local row = "`eq',`nm'," + string(`b', "%20.10g") + "," ///
                + string(`se', "%20.10g") + "," + string(`z', "%20.10g") ///
                + "," + string(`pv', "%20.10g") + "," ///
                + string(`lo', "%20.10g") + "," + string(`hi', "%20.10g")
            local row = subinstr("`row'", " ", "", .)
            _tk_xline `toscreen' "`fh'" "`row'"
        }
    }

    * ==================================================== the footer
    * This is the part that matters. The notes accumulate in NUMBERED locals
    * rather than one space-separated list: a list of quoted strings
    * re-tokenised by foreach is a quoting trap, and these strings contain
    * brackets, commas and semicolons.
    if "`nofooter'" == "" {
        if "`format'" == "latex" _tk_xline `toscreen' "`fh'" "\midrule"
        else if "`format'" == "markdown" _tk_xline `toscreen' "`fh'" ""

        local nn 0

        * ---- the threshold(s), and the confidence SET.
        * The result names here are the ones the package actually posts, and
        * they were read off the ado files rather than assumed: the
        * multiple-threshold vector is e(thresholds), the interval endpoints
        * are the SCALARS e(gamma_lo) and e(gamma_hi), and the contiguity
        * flag is e(ci_contiguous). Guessing these would have produced a
        * table with an empty footer and no error of any kind.
        local multi 0
        capture confirm matrix e(thresholds)
        if !_rc {
            tempname GG
            matrix `GG' = e(thresholds)
            local ng = colsof(`GG')
            if rowsof(`GG') > 1 & `ng' == 1 {
                matrix `GG' = `GG''
                local ng = colsof(`GG')
            }
            if `ng' > 1 {
                local multi 1
                local gl ""
                forvalues j = 1/`ng' {
                    local gj = trim(string(`GG'[1,`j'], "`fmt'"))
                    local gl = cond(`j' == 1, "`gj'", "`gl', `gj'")
                }
                local ++nn
                local nl`nn' "Thresholds: `gl'"
            }
        }
        if !`multi' & e(gamma1) < . & e(gamma2) < . {
            local multi 1
            local ++nn
            local nl`nn' "Thresholds: `=trim(string(e(gamma1),"`fmt'"))', `=trim(string(e(gamma2),"`fmt'"))'"
        }
        if !`multi' & e(gamma) < . {
            local g = trim(string(e(gamma), "`fmt'"))
            local cib ""
            if e(gamma_lo) < . & e(gamma_hi) < . {
                local cib = " [" + trim(string(e(gamma_lo), "`fmt'")) ///
                    + ", " + trim(string(e(gamma_hi), "`fmt'")) + "]"
            }
            local ++nn
            local nl`nn' "Threshold: `g'`cib'"
            * and whether that bracket is actually an interval. A missing
            * e(ci_contiguous) is not a claim that it is -- it is silence,
            * so only an explicit 0 produces the warning.
            if e(ci_contiguous) == 0 {
                local ++nn
                local nl`nn' "The confidence SET is not an interval; the bracket above is its convex hull."
                if e(ci_npoints) < . {
                    local ++nn
                    local nl`nn' "The inverted test accepts `=e(ci_npoints)' separate grid points."
                }
            }
        }

        * ---- regime sizes and N.
        * e(N_regime1) and e(N_regime2) are posted as scalars, but only
        * those two: a three-regime fit has no e(N_regime3), and its counts
        * live in the MATRIX e(nobs_regime). Reading only the scalars would
        * silently report two regime sizes for a three-regime model, which
        * is worse than reporting none. So the matrix is preferred wherever
        * it exists and the scalars are the fallback.
        local rs ""
        capture confirm matrix e(nobs_regime)
        if !_rc {
            tempname NR
            matrix `NR' = e(nobs_regime)
            local nrr = rowsof(`NR')
            local nrc = colsof(`NR')
            if `nrr' >= `nrc' {
                forvalues r = 1/`nrr' {
                    if `NR'[`r',1] < . local rs "`rs' `=`NR'[`r',1]'"
                }
            }
            else {
                forvalues r = 1/`nrc' {
                    if `NR'[1,`r'] < . local rs "`rs' `=`NR'[1,`r']'"
                }
            }
        }
        if "`rs'" == "" {
            forvalues r = 1/4 {
                if e(N_regime`r') < . local rs "`rs' `=e(N_regime`r')'"
            }
        }
        if "`rs'" != "" {
            local ++nn
            local nl`nn' "Regime sizes:`rs'"
        }
        if e(N) < . {
            local ++nn
            local nl`nn' "Observations: `=e(N)'"
        }

        * ---- the no-threshold test, with its BOOTSTRAP p-value. A nominal
        * p-value for a statistic maximised over a grid is not a p-value.
        if e(p) < . {
            local tl "Test of no threshold"
            if "`e(teststat)'" != "" local tl "`tl' (`e(teststat)')"
            local tl "`tl': "
            * whichever statistic the fitting command posted. e(lm) is NOT
            * one of them in this package; the names below were read off the
            * ado files.
            if e(stat) < .       local tl "`tl'`=trim(string(e(stat),"`fmt'"))'"
            else if e(supf) < .  local tl "`tl'`=trim(string(e(supf),"`fmt'"))'"
            else if e(suplm) < . local tl "`tl'`=trim(string(e(suplm),"`fmt'"))'"
            local tl "`tl', bootstrap p = `=trim(string(e(p),"%6.3f"))'"
            if e(boot_reps) < . local tl "`tl' (`=e(boot_reps)' reps)"
            local ++nn
            local nl`nn' "`tl'"
        }
        if "`e(vcelab)'" != "" {
            local ++nn
            local nl`nn' "Std. errors: `e(vcelab)'"
        }

        * ---- the standing caveats. Not boilerplate: a reader who takes a
        * threshold point estimate at face value has misread the table.
        local ++nn
        local nl`nn' "The threshold has no standard error: its limit distribution is not normal."
        local ++nn
        local nl`nn' "Slope inference conditions on the estimated threshold."
        if "`nostars'" == "" {
            local ++nn
            local nl`nn' "* p<0.10, ** p<0.05, *** p<0.01"
        }
        if `"`note'"' != "" {
            local ++nn
            local nl`nn' `"`note'"'
        }

        forvalues i = 1/`nn' {
            local L `"`nl`i''"'
            if "`format'" == "latex" {
                * escaped inline, for the same reason as the term names: a
                * Stata subroutine receives `0' WITH its enclosing quotes,
                * so passing a quoted note to a helper would put literal
                * quote marks into the document.
                local Lx `"`L'"'
                local Lx = subinstr(`"`Lx'"', "_", "\_", .)
                local Lx = subinstr(`"`Lx'"', "#", "\#", .)
                local Lx = subinstr(`"`Lx'"', "&", "\&", .)
                local Lx = subinstr(`"`Lx'"', "%", "\%", .)
                _tk_xline `toscreen' "`fh'" "\multicolumn{5}{p{0.86\textwidth}}{\footnotesize `Lx'} \\"
            }
            else if "`format'" == "markdown" {
                _tk_xline `toscreen' "`fh'" `"`L'  "'
            }
            else {
                local esc = subinstr(`"`L'"', ",", ";", .)
                _tk_xline `toscreen' "`fh'" "note,,,,,,,`esc'"
            }
        }
        local nnote `nn'
    }

    if "`format'" == "latex" {
        _tk_xline `toscreen' "`fh'" "\bottomrule"
        _tk_xline `toscreen' "`fh'" "\end{tabular}"
        _tk_xline `toscreen' "`fh'" "\end{table}"
    }

    if !`toscreen' {
        file close `fh'
        display as text "table written to " as result `"`using'"' ///
            as text " (`format')"
        display as text "  " as result `k' as text " coefficients" ///
            cond(`neq' > 0, " in `neq' panels", "")
        if "`nofooter'" != "" {
            display as error "  {bf:nofooter} suppressed the threshold, its"
            display as error "  confidence set, the regime sizes and the"
            display as error "  no-threshold test. A threshold table without"
            display as error "  those is incomplete in ways a reader cannot"
            display as error "  detect -- put them back before publishing."
        }
    }

    return local format  "`format'"
    return scalar k_coef = `k'
    return scalar n_eq   = `neq'
    return scalar n_note = `nnote'
end

* ----------------------------------------------------------------------
* Write one line, to the file or to the screen. Factored out so the body
* above reads as the table it produces rather than as I/O plumbing.
program define _tk_xline
    version 15
    args toscreen fh
    local txt `"`3'"'
    if `toscreen' display as text `"`macval(txt)'"'
    else file write `fh' `"`macval(txt)'"' _n
end
