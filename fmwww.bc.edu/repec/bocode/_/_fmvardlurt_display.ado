*! _fmvardlurt_display  version 1.0.0  13oct2026
*! Result tables of fmvardlurt; reads everything from e(), so typing -fmvardlurt-
*! without arguments redisplays them.

capture program drop _fmvardlurt_display
program define _fmvardlurt_display
    version 14
    syntax [, NOTable]
    if "`e(cmd)'" != "fmvardlurt" {
        di as err "last estimates not found"
        exit 301
    }
    local W 78
    local k     = e(k)
    local p     = e(opt_p)
    local fk    = e(freq)
    local qlist "`e(opt_q)'"
    local qtxt : subinstr local qlist " " ",", all
    local boot  = e(boot)
    local alpha = e(alpha)
    tempname cv ict
    matrix `cv'  = e(cv)
    matrix `ict' = e(ic_table)

    // ---------------------------------------------------------------
    // selection table (lag search only)
    // ---------------------------------------------------------------
    if "`notable'" == "" & "`e(lags)'" == "selected" {
        local ml = e(maxlag)
        local nk = colsof(`ict')
        di as txt _n "{hline `W'}"
        di as res _col(3) upper("`e(ic)'") " over (p, q, frequency); common q for all covariates; selected *"
        di as txt "{hline `W'}"
        di as txt _col(3) "  p   q" _c
        forvalues j = 1/`nk' {
            local kk = cond("`e(freqsel)'" == "fixed", `fk', `j')
            di as txt %12s "k=`kk'" _c
        }
        di as txt ""
        local row 0
        forvalues pp = 0/`ml' {
            forvalues qq = 0/`ml' {
                local ++row
                di as txt _col(3) %3.0f `pp' %4.0f `qq' _c
                forvalues j = 1/`nk' {
                    local v = el(`ict', `row', `j')
                    local kk = cond("`e(freqsel)'" == "fixed", `fk', `j')
                    local oq : word 1 of `qlist'
                    if `v' >= . di as txt %12s "." _c
                    else if `pp' == `p' & `qq' == `oq' & `kk' == `fk' di as res %11.3f `v' "*" _c
                    else di as txt %11.3f `v' " " _c
                }
                di as txt ""
            }
        }
    }

    // ---------------------------------------------------------------
    // Table 1
    // ---------------------------------------------------------------
    local spec "ARDL(`p'; `qtxt')"
    if e(contemp) == 1 local spec "`spec' + D.x"
    local ftxt = cond(`fk' == 0, "none (plain test)", "k = `fk' (" + "`e(freqsel)'" + ", kmax = " + string(e(kmax)) + ")")
    di as txt _n "{hline `W'}"
    di as res _col(3) "Table 1: Fourier multivariate ARDL unit-root test"
    di as txt "{hline `W'}"
    di as txt _col(3) "Dependent variable :" _col(25) as res "`e(depvar)'"
    di as txt _col(3) "Covariates (k = `k')" _col(23) ": " as res "`e(indepvars)'"
    di as txt _col(3) "Deterministics     :" _col(25) as res "Case `e(case)' (`e(casename)')"
    di as txt _col(3) "Specification      :" _col(25) as res "`spec'" as txt "  (lags `e(lags)'" ///
        cond("`e(lags)'" == "selected", " by " + upper("`e(ic)'"), "") ")"
    di as txt _col(3) "Fourier frequency  :" _col(25) as res "`ftxt'"
    di as txt _col(3) "Sample             :" _col(25) as res "`e(t_start)'-`e(t_end)'" ///
        as txt "  T = " as res e(T) as txt ", observations used = " as res e(N)
    di as txt _col(3) "R-squared (D.y)    :" _col(25) as res %7.4f e(r2) ///
        as txt "   residual df = " as res e(df_r)
    di as txt "{hline `W'}"
    di as txt _col(3) "Statistic" _col(30) "Value" _col(42) "Bootstrap p" _col(57) "H0"
    di as txt "{hline `W'}"
    di as txt _col(3) "t (L.y)" _col(24) as res %11.4f e(tstat) _col(44) %7.4f e(p_t) ///
        _col(57) as txt "unit root (pi = 0)"
    di as txt _col(3) "F (L.x), Wald/k" _col(24) as res %11.4f e(fstat) _col(44) %7.4f e(p_f) ///
        _col(57) as txt "no level relation"
    if `fk' > 0 {
        di as txt _col(3) "F (sin, cos), Wald/2" _col(24) as res %11.4f e(ffstat) _col(44) %7.4f e(p_ff) ///
            _col(57) as txt "no Fourier component"
    }
    di as txt "{hline `W'}"
    if `boot' == 1 {
        di as txt _col(3) "Bootstrap: " e(B) " valid draws; joint null pi = delta = 0; no drift or Fourier"
        di as txt _col(3) "component in the generating process; " ///
            cond(e(reselect) == 1, "lag and frequency search repeated in each draw.", "lags and frequency fixed in the draws.")
    }

    // ---------------------------------------------------------------
    // Table 2: critical values
    // ---------------------------------------------------------------
    if `boot' == 1 {
        local dl = strtrim(string(100*`alpha', "%6.2f")) + "%"
        di as txt _n "{hline `W'}"
        di as res _col(3) "Table 2: Bootstrap critical values"
        di as txt "{hline `W'}"
        di as txt _col(3) "Level" _col(24) "10%" _col(35) "5%" _col(45) "2.5%" _col(57) "1%" _col(66) "`dl' (dec.)"
        di as txt "{hline `W'}"
        local rn1 "t (lower tail)"
        local rn2 "F (upper tail)"
        local rn3 "F Fourier (upper)"
        local last = cond(`fk' > 0, 3, 2)
        forvalues r = 1/`last' {
            di as txt _col(3) "`rn`r''" _c
            forvalues c = 1/5 {
                di as res _col(`=10 + 11*`c'') %9.3f el(`cv', `r', `c') _c
            }
            di as txt ""
        }
        di as txt "{hline `W'}"

        // -----------------------------------------------------------
        // Table 3: decision
        // -----------------------------------------------------------
        local rt = (e(p_t) < `alpha')
        local rf = (e(p_f) < `alpha')
        local cs = 1 + `rt' + 2*`rf'
        local c1 "Case I   : unit root, no cointegration"
        local c2 "Case II  : stationary (no level relation needed)"
        local c3 "Case III : degenerate (F rejects only; possibly I(2))"
        local c4 "Case IV  : cointegration between y and the covariates"
        di as txt _n "{hline `W'}"
        di as res _col(3) "Table 3: Four-case decision at the `dl' level (Sam et al. 2025)"
        di as txt "{hline `W'}"
        di as txt _col(3) "t rejects: " as res cond(`rt', "yes", "no") ///
            as txt "     F rejects: " as res cond(`rf', "yes", "no")
        di as res _col(3) "`c`cs''"
        if `fk' > 0 {
            local rff = (e(p_ff) < `alpha')
            if `rff' == 0 {
                di as txt _col(3) "Note: the Fourier terms are not significant (p = " %5.3f e(p_ff) ///
                    "); the test without them (freq(0)) is more powerful."
            }
        }
        di as txt "{hline `W'}"
    }
end
