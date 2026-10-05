*! _bd_parse.ado — infer the levels ARDL order from a regressor varlist
*! Version 1.0.0
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*!
*! Different commands label p and q differently: aardl reports
*! "ARDL(1,0,0)" for a model whose e(ecmvars) is
*!     L.y L.x L.z L1.D.y D.x D.z
*! which in LEVELS is an ARDL(2,1,1).  Rather than trying to track each
*! command's convention, bootdiag reads the regressor list itself and
*! works out the implied maximum lag of every variable.  The levels
*! order recovered this way is correct by construction.
*!
*! Term            implied maximum lag of the base variable
*!   x                 0
*!   L.x / L1.x        1
*!   L#.x              #
*!   D.x               1
*!   LD.x / L1D.x      2
*!   L#D.x             # + 1
*!   L(a/b).x          b
*!   L(a/b)D.x         b + 1
*!   D2.x              2
*!
*! Returns:
*!   r(ylev)  base name of the dependent variable
*!   r(xlev)  base names of the other regressors, in order
*!   r(p)     implied levels AR order
*!   r(qlist) implied levels lag order for each element of r(xlev)
*!   r(det)   terms that are not functions of a model variable
*!            (constant, trend, Fourier, dummies)

program define _bd_parse, rclass
    version 16.0
    syntax , depvar(string) rhs(string) [ ylev(string) ]

    * ---- base name of the dependent variable -------------------------
    local dv = trim("`depvar'")
    if "`ylev'" != "" local yb "`ylev'"
    else {
        local yb : subinstr local dv "D." "", all
        local yb = trim("`yb'")
        * strip any leading operator block such as L2D.
        if regexm("`yb'", "^[A-Za-z]*[0-9()/]*\.(.+)$") local yb = regexs(1)
    }

    local p 0
    local xb ""
    local ql ""
    local det ""

    foreach term of local rhs {
        local t = trim("`term'")
        if "`t'" == "" continue
        if "`t'" == "_cons" {
            local det "`det' _cons"
            continue
        }

        _bd_term, term("`t'")
        local base "`r(base)'"
        local lagm = r(lagmax)

        if `lagm' >= . {
            * not parseable as a lagged model variable: treat as
            * deterministic / exogenous and hold it fixed
            local det "`det' `t'"
            continue
        }

        if "`base'" == "`yb'" {
            if `lagm' > `p' local p = `lagm'
        }
        else {
            * is this base already recorded?
            local pos 0
            local i 0
            foreach b of local xb {
                local ++i
                if "`b'" == "`base'" local pos `i'
            }
            if `pos' == 0 {
                local xb "`xb' `base'"
                local ql "`ql' `lagm'"
            }
            else {
                local cur : word `pos' of `ql'
                if `lagm' > `cur' {
                    local nl ""
                    local i 0
                    foreach c of local ql {
                        local ++i
                        if `i' == `pos' local nl "`nl' `lagm'"
                        else            local nl "`nl' `c'"
                    }
                    local ql "`nl'"
                }
            }
        }
    }

    return local ylev  "`yb'"
    return local xlev  = trim("`xb'")
    return local qlist = trim("`ql'")
    return scalar p    = `p'
    return local det   = trim("`det'")
end


*-----------------------------------------------------------------------
* _bd_term — decompose one time-series term into base name + max lag
*-----------------------------------------------------------------------
program define _bd_term, rclass
    version 16.0
    syntax , term(string)

    local t = trim("`term'")

    * plain variable, no operator
    capture confirm variable `t'
    if !_rc & !strpos("`t'", ".") {
        return local base "`t'"
        return scalar lagmax = 0
        exit
    }

    if !strpos("`t'", ".") {
        return local base ""
        return scalar lagmax = .
        exit
    }

    * split operator block from the base name at the LAST period
    local pos = strrpos("`t'", ".")
    local op   = substr("`t'", 1, `pos' - 1)
    local base = substr("`t'", `pos' + 1, .)

    local lag 0
    local dif 0
    local rest = upper("`op'")

    * ---- L(a/b) or L# ------------------------------------------------
    if regexm("`rest'", "L\(([0-9]+)/([0-9]+)\)") {
        local lag = real(regexs(2))
        local rest = subinstr("`rest'", regexs(0), "", 1)
    }
    else if regexm("`rest'", "L([0-9]+)") {
        local lag = real(regexs(1))
        local rest = subinstr("`rest'", regexs(0), "", 1)
    }
    else if regexm("`rest'", "L") {
        local lag 1
        local rest = subinstr("`rest'", "L", "", 1)
    }

    * ---- D# ----------------------------------------------------------
    if regexm("`rest'", "D([0-9]+)") {
        local dif = real(regexs(1))
        local rest = subinstr("`rest'", regexs(0), "", 1)
    }
    else if regexm("`rest'", "D") {
        local dif 1
        local rest = subinstr("`rest'", "D", "", 1)
    }

    * Forms such as L1.D.y carry an internal period, which survives the
    * operator split; drop any stray separators before the final check.
    local rest = subinstr("`rest'", ".", "", .)

    * anything left over (S., F., factor notation) -> not a plain lag
    if trim("`rest'") != "" {
        return local base ""
        return scalar lagmax = .
        exit
    }

    capture confirm variable `base'
    if _rc {
        return local base ""
        return scalar lagmax = .
        exit
    }

    return local base "`base'"
    return scalar lagmax = `lag' + `dif'
end
