*! version 3.0  9/25/2026
* rctable: RCT results table (ITT or LATE), 3-digit precision.
* Improvements over 2.7: estimation dispatch fixed (no double estimation,
* no duplicated p-values), broken `quiet` prefixes removed, empty-cluster()
* bug fixed, LATE block repaired (typo `=`treatment'=`, stale locals,
* wrong p-value formula), number formatting factored into a helper,
* r(table) used for p-values, row count computed from actual step,
* excel export option fixed, validation fails fast.

cap program drop rctable
program define rctable

version 16.0

    *---------------------------------------------------------------------
    * Syntax
    *---------------------------------------------------------------------
    syntax [varlist] [using] [if] [pw aw fw], TREATment(varlist) ///
        [CONTrol(varlist fv) BASEControl(varlist) CLUSTer(varlist) ///
         ESTimator(name) TREAted(varlist) PValue keep QValue(name) ///
         quiet latex sd SHEET(string asis)]

    *---------------------------------------------------------------------
    * Validation
    *---------------------------------------------------------------------
    if !mi("`pvalue'") & !mi("`qvalue'") {
        dis as error "Cannot specify both p and q values"
        exit 100
    }

    * Normalise estimator; treated() implies LATE
    local estimator = lower("`estimator'")
    if !mi("`treated'") & mi("`estimator'") local estimator "late"
    if mi("`estimator'") local estimator "itt"
    if !inlist("`estimator'", "itt", "late") {
        dis as error "Estimator must be ITT or LATE"
        exit 198
    }
    local nbranches = wordcount("`treatment'")
    if "`estimator'" == "late" {
        if `nbranches' > 1 {
            dis as error "LATE not available with multiple treatment branches"
            exit 100
        }
        if wordcount("`treated'") > 1 {
            dis as error "LATE available with a single treated variable only"
            exit 100
        }
    }

    if !mi("`qvalue'") {
        local okmethods "bonferroni sidak holm holland hochberg simes yekutieli bky"
        if !`: list posof "`qvalue'" in okmethods' {
            dis as error `"Unrecognised method `qvalue'"'
            exit 198
        }
        if "`qvalue'" != "bky" {
            cap which qqvalue
            if _rc ssc install qqvalue
        }
        dis "Qvalues are based on `qvalue'"
    }

    *---------------------------------------------------------------------
    * Setup
    *---------------------------------------------------------------------
    if mi("`keep'") {
        preserve
        foreach cvar in VAR LAB N_ind N_clust A C {
            cap confirm variable `cvar'
            if !_rc {
                dis as error "Dataset should not include: VAR LAB N_ind N_clust A C COEF*"
                exit 100
            }
        }
        cap ds COEF*
        if !_rc drop COEF*
    }

    tokenize `treatment'

    local c = 0
    foreach tv of local treatment {
        local ++c
        gen COEF`c' = ""
    }
    foreach v in VAR LAB A C N_ind N_clust {
        gen `v' = ""
    }

    * cluster option string (empty cluster() was a hard error before)
    if !mi("`cluster'") local clustopt "cluster(`cluster')"

    * rows needed: per outcome 2 rows, +1 if p or q row
    local rowstep = 2 + (!mi("`pvalue'") | !mi("`qvalue'"))
    local ntests = wordcount("`varlist'")
    local need = `rowstep' * `ntests' + 5
    if `need' > _N cap set obs `need'

    *---------------------------------------------------------------------
    * Main loop over outcomes
    *---------------------------------------------------------------------
    local pvalues ""
    local j = 1
    local k = 1
    foreach i of local varlist {

        *--- baseline control for this outcome (in order of varlist) ---*
        local cont ""
        if !mi("`basecontrol'") {
            if `k' == 1 & wordcount("`basecontrol'") != `ntests' {
                dis as error "Number of variables different from number of baseline control"
                exit 100
            }
            local cont : word `k' of `basecontrol'
        }

        *--- estimate ---*
        if !mi("`quiet'") {
            dis "*******"
            dis "Outcome `i'"
            dis "Outcome: Intent-to-Treat estimation"
            dis "********"
        }

        if "`estimator'" == "itt" {
            if !mi("`quiet'") ///
                reg `i' `treatment' `control' `cont' [`weight'`exp'] `if', `clustopt' r
            else ///
                qui reg `i' `treatment' `control' `cont' [`weight'`exp'] `if', `clustopt' r
        }
        else {
            if !mi("`quiet'") {
                dis "Treatment on the treated estimation"
                ivregress 2sls `i' (`treated' = `treatment') `control' `cont' ///
                    [`weight'`exp'] `if', `clustopt' r
            }
            else ///
                qui ivregress 2sls `i' (`treated' = `treatment') `control' `cont' ///
                    [`weight'`exp'] `if', `clustopt' r
        }
		quiet {
		  *--- coefficients, SEs, stars, p-values ---*
        * r(table) works identically for reg and ivregress
        tempname R
        matrix `R' = r(table)

        local h = 0
        foreach tv of local treatment {
            local ++h
            if "`estimator'" == "itt" local bname `tv'
            else local bname `treated'
            local b    = `R'["b",      "`bname'"]
            local se   = `R'["se",     "`bname'"]
            local pval = `R'["pvalue", "`bname'"]

            _rctfmt `b'
            local stars : di cond(`pval'<=0.01, "***", ///
                             cond(`pval'<=0.05, "**", ///
                             cond(`pval'<=0.10, "*", "")))
            replace COEF`h' = "`s(fmt)'`stars'" if _n == `j'

            _rctfmt `se'
            replace COEF`h' = "(`s(fmt)')" if _n == `j' + 1

            if !mi("`pvalue'") {
                replace COEF`h' = "[" + string(`pval', "%7.2f") + "]" if _n == `j' + 2
            }
            if !mi("`qvalue'") {
                local pvalues "`pvalues' `pval'"
            }
        }

        *--- labels ---*
        local t : variable label `i'
        replace VAR = "`i'" if _n == `j'
        replace LAB = cond(mi("`t'"), "`i'", "`t'") if _n == `j'

        *--- control-group dummy: 1 when all treatment vars == 0 ---*
        local temoin "`1'==0"
        forval v = 2/`c' {
            local temoin "`temoin' & ``v''==0"
        }
        tempvar T0
        gen `T0' = cond(`temoin', 1, 0) if `1' != .

        *--- control mean (and SD) ---*
        if mi("`if'") qui sum `i' [`weight'`exp'] if `T0'==1, d
        else           qui sum `i' [`weight'`exp'] `if' & `T0'==1, d
        _rctfmt r(mean)
        replace C = "`s(fmt)'" if _n == `j'
        if !mi("`sd'") {
            _rctfmt r(sd)
            replace C = "[`s(fmt)']" if _n == `j' + 1
        }

        *--- full-sample mean (and SD) ---*
        if mi("`if'") qui sum `i' [`weight'`exp'], d
        else           qui sum `i' [`weight'`exp'] `if', d
        _rctfmt r(mean)
        replace A = "`s(fmt)'" if _n == `j'
        if !mi("`sd'") {
            _rctfmt r(sd)
            replace A = "[`s(fmt)']" if _n == `j' + 1
        }

        *--- sample sizes ---*
        replace N_ind = string(e(N), "%7.0fc") if _n == `j'
        cap confirm scalar e(N_clust)
        if !_rc replace N_clust = string(e(N_clust), "%7.0fc") if _n == `j'
        else replace N_clust = N_ind if _n == `j'

      

        local j = `j' + `rowstep'
        local ++k
		}
    }

    *---------------------------------------------------------------------
    * q-values
    *---------------------------------------------------------------------
    if !mi("`qvalue'") & "`qvalue'" != "bky" {
        tempvar P Q
        quiet {
		gen `P' = .
        local count = 1
        foreach p of local pvalues {
            replace `P' = `p' if _n == `count'
            local ++count
        }
		}
        if !mi("`quiet'") {
		quiet qqvalue `P', method(`qvalue') qvalue(`Q')
		}
        quiet {
		local j = 0
        local qcount = 0
        foreach varq of local varlist {
            local j = `j' + `rowstep'
            forval h = 1/`c' {
                local ++qcount
                local qs = string(`Q'[`qcount'], "%7.3f")
                replace COEF`h' = "[`qs']" if _n == `j'
            }
        }
    }

    if "`qvalue'" == "bky" {
        tempvar Q q order rank
        gen `Q' = .
        local count = 1
        foreach p of local pvalues {
            replace `Q' = `p' if _n == `count'
            local ++count
        }
        qui sum `Q'
        local totalpvals = r(N)

        gen int `order' = _n
        sort `Q'
        gen int `rank' = _n if `Q' != .
        gen `q' = 1 if `Q' != .

        local qval = 1
        while `qval' > 0 {
            local qval_adj = `qval' / (1 + `qval')

            * First stage
            tempvar f1 r1 rrank1 tot1
            gen `f1' = `qval_adj' * `rank' / `totalpvals'
            gen `r1' = (`f1' >= `Q') if `Q' != .
            gen `rrank1' = `r1' * `rank'
            egen `tot1' = max(`rrank1')

            * Second stage
            tempvar f2 r2 rrank2 tot2
            local qval_2st = `qval_adj' * (`totalpvals' / (`totalpvals' - `tot1'[1]))
            gen `f2' = `qval_2st' * `rank' / `totalpvals'
            gen `r2' = (`f2' >= `Q') if `Q' != .
            gen `rrank2' = `r2' * `rank'
            egen `tot2' = max(`rrank2')

            replace `q' = `qval' if `rank' <= `tot2' & `rank' != .
            drop `f1' `r1' `rrank1' `tot1' `f2' `r2' `rrank2' `tot2'
            local qval = `qval' - 0.001
        }
        qui sort `order'

        local j = 0
        local qcount = 0
        foreach varq of local varlist {
            local j = `j' + `rowstep'
            forval h = 1/`c' {
                local ++qcount
                local qs = string(`q'[`qcount'], "%7.3f")
                replace COEF`h' = "[`qs']" if _n == `j'
			}
            }
        }
    }

    *---------------------------------------------------------------------
    * Summary rows: Observations / Clusters
    *---------------------------------------------------------------------
  quiet {
  local j = `j' - `rowstep'          // last row used by the loop
    replace VAR = "Observations" if _n == `j' + 1

    if mi("`if'") count if `1' != .
    else          count `if' & `1' != .
    replace N_ind = string(r(N), "%7.0fc") if _n == `j' + 1

    if mi("`if'") count if `T0' == 1
    else          count `if' & `T0' == 1
    replace C = string(r(N), "%7.0fc") if _n == `j' + 1

    local l = 1
    foreach tv of local treatment {
        if mi("`if'") count if `tv' == 1
        else          count `if' & `tv' == 1
        replace COEF`l' = string(r(N), "%7.0fc") if _n == `j' + 1
        local ++l
    }

    if !mi("`cluster'") {
        replace VAR = "Clusters" if _n == `j' + 2

        duplicates report `cluster' `if'
        replace N_ind = string(r(unique_value), "%7.0fc") if _n == `j' + 2

        if mi("`if'") duplicates report `cluster' if `T0' == 1
        else          duplicates report `cluster' `if' & `T0' == 1
        replace C = string(r(unique_value), "%7.0fc") if _n == `j' + 2

        local l = 1
        foreach tv of local treatment {
            if mi("`if'") duplicates report `cluster' if `tv' == 1
            else          duplicates report `cluster' `if' & `tv' == 1
            replace COEF`l' = string(r(unique_value), "%7.0fc") if _n == `j' + 2
            local ++l
        }
    }
  }
    *---------------------------------------------------------------------
    * Export to Excel
    *---------------------------------------------------------------------
    if !mi("`using'") & mi("`latex'") {
        if !mi("`sheet'") {
            gettoken worksheet option : sheet, parse(,)
            export excel VAR LAB N_ind N_clust A C COEF* `using', ///
                sheet(`worksheet' `option') firstrow(var)
        }
        else {
            export excel VAR LAB N_ind N_clust A C COEF* `using', ///
                firstrow(var) replace
        }
    }

    *---------------------------------------------------------------------
    * Export to LaTeX
    *---------------------------------------------------------------------
    if !mi("`latex'") {
        cap which listtab
        if _rc ssc install listtab

        forval h = 1/`c' {
            local COEFS "`COEFS' COEF`h'"
            if `h' == 1 local COEFS_tex "T`h'"
            else local COEFS_tex "`COEFS_tex' & T`h' "
        }
        local word = `c'
        forval C = 1/`word' {
            local Cs "`Cs' c"
        }

        #delimit ;
        listtab LAB N_ind N_clust C `COEFS' if COEF1!="" | LAB!="" `using',
            replace rstyle(tabular) head("
\begin{threeparttable}[htbp]
  \centering
  \caption{}
    \begin{tabular}{lccc`Cs'}
    \toprule
    \toprule
	& N  & Cluster  & C  &  `COEFS_tex' \\
\cmidrule{2-`=4+`word''}")
foot(" \bottomrule \bottomrule
    \end{tabular}
  \label{}
          \begin{tablenotes}[flushleft]
\item
  \end{tablenotes}
\end{threeparttable}");
        #delimit cr
    }

    if !mi("`keep'") order VAR LAB N_ind N_clust A C COEF*, last
    if mi("`keep'") restore

end

*----------------------------------------------------------------------
* Helper: adaptive 3-digit formatting of a scalar
*----------------------------------------------------------------------
cap program drop _rctfmt
program define _rctfmt, sclass
    args x
    local a = abs(`x')
    local f = cond(`a' < 10,   "%7.3f", ///
             cond(`a' < 100,  "%7.2f", ///
             cond(`a' < 1000, "%7.1f", "%7.0f")))
    local s = string(`x', "`f'")
    if "`s'" == "-0.000" local s "0.000"
    sreturn local fmt "`s'"
end
