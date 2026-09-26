*! version 0.1.2  24sep2026  Joris Pinkse
*! quadriceps: positive-weight cubature rules for the Gaussian weight (ghpos) and the cube (lepos)
*! the Stata twin of Quadriceps.jl (Julia), quadriceps-py (Python) and quadriceps-r (R)
*! https://github.com/NittanyLion/quadriceps-stata

program quadriceps, rclass
    version 16
    _quadriceps_load
    gettoken sub 0 : 0, parse(" ,")
    local sub = lower(`"`sub'"')
    if inlist("`sub'", "gh", "le") {
        _quadriceps_rule `sub' `0'
    }
    else if "`sub'" == "nnodes" {
        _quadriceps_nnodes `0'
    }
    else if "`sub'" == "ruleinfo" {
        _quadriceps_ruleinfo `0'
    }
    else if "`sub'" == "rules" {
        _quadriceps_rules `0'
    }
    else if "`sub'" == "check" {
        _quadriceps_check `0'
    }
    else if "`sub'" == "version" {
        _quadriceps_version
    }
    else {
        di as err "quadriceps: unknown subcommand `sub'; use gh, le, nnodes, ruleinfo, rules, check or version (see {help quadriceps})"
        exit 198
    }
    return add
end

* The Mata code is in quadriceps.mata (functions defined inside an ado-file would be private to it).
* Compile it once per session, and again after the package has been updated.
program _quadriceps_load
    version 16
    capture mata: assert(quadriceps_mata_version() == "0.1.2")
    if _rc == 0 exit
    capture mata: mata drop quadriceps_*() ghpos() lepos()
    quietly findfile quadriceps.mata
    run `"`r(fn)'"'
end

* d and q (positional) or p(): the degree a call asks for. Sets s(d) and s(p).
program _quadriceps_degree, sclass
    version 16
    syntax [anything(name=dq id="d and q")] [, P(numlist max=1 integer >=0)]
    tokenize `dq'
    if "`1'" == "" {
        di as err "the dimension d is required"
        exit 198
    }
    if "`3'" != "" {
        di as err "too many arguments: give d and optionally q, then options"
        exit 198
    }
    capture confirm integer number `1'
    if _rc {
        di as err "d must be a whole number, got `1'"
        exit 198
    }
    if `1' < 1 {
        di as err "the dimension d must be at least 1, got `1'"
        exit 198
    }
    local d `1'
    if "`2'" == "" & "`p'" == "" {
        di as err "give q (the second argument) or p(): the number of nodes of the one-dimensional Gauss rule, or the degree"
        exit 198
    }
    if "`2'" != "" & "`p'" != "" {
        di as err "give q or p(), not both"
        exit 198
    }
    if "`2'" != "" {
        capture confirm integer number `2'
        if _rc {
            di as err "q must be a whole number, got `2'"
            exit 198
        }
        if `2' < 1 {
            di as err "q must be at least 1, got `2'"
            exit 198
        }
        local p = 2 * `2' - 1
    }
    sreturn local d `d'
    sreturn local p `p'
end

program _quadriceps_family
    version 16
    args fam
    if !inlist("`fam'", "gh", "le") {
        di as err "the family must be gh (Gaussian weight) or le (uniform weight on the cube), got `fam'"
        exit 198
    }
end

* quadriceps gh|le d [q] [, p() pragmatic nonormalize frame() replace matrix() mata()]
program _quadriceps_rule, rclass
    version 16
    gettoken fam 0 : 0
    syntax [anything(name=dq id="d and q")] [, P(numlist max=1 integer >=0) PRAGmatic NONORMalize ///
        FRAME(name) REPlace MATrix(name) MATA(namelist min=2 max=2)]
    _quadriceps_degree `dq', `=cond("`p'" != "", "p(`p')", "")'
    local d `s(d)'
    local p `s(p)'
    local prag = ("`pragmatic'" != "")
    local norm = ("`nonormalize'" == "")
    if "`frame'" == "" {
        local frame quadriceps
        local replace replace             // the package's own frame is always overwritten
    }
    if "`frame'" == "`c(frame)'" {
        di as err "frame `frame' is the current frame; give another name in frame()"
        exit 198
    }
    tempname N
    mata: __quadriceps_X = .
    mata: __quadriceps_w = .
    capture noisily mata: quadriceps_rule("`fam'", `d', `p', `prag', `norm', __quadriceps_X, __quadriceps_w)
    if _rc {
        local rc = _rc
        capture mata: mata drop __quadriceps_X __quadriceps_w
        exit `rc'
    }
    if "`replace'" != "" {
        capture frame drop `frame'
    }
    capture frame create `frame'
    if _rc {
        capture mata: mata drop __quadriceps_X __quadriceps_w
        di as err "frame `frame' already exists; specify replace, or another name in frame()"
        exit 110
    }
    frame `frame' {
        mata: quadriceps_todata(__quadriceps_X, __quadriceps_w)
    }
    if "`matrix'" != "" {
        capture noisily mata: quadriceps_tomatrix("`matrix'", __quadriceps_X, __quadriceps_w)
        if _rc {
            local rc = _rc
            capture mata: mata drop __quadriceps_X __quadriceps_w
            exit `rc'
        }
    }
    if "`mata'" != "" {
        tokenize `mata'
        mata: `1' = __quadriceps_X
        mata: `2' = __quadriceps_w
    }
    mata: st_numscalar("`N'", rows(__quadriceps_w))
    mata: mata drop __quadriceps_X __quadriceps_w
    local fname = cond("`fam'" == "gh", "GH", "Le")
    di as txt "`fname' rule of degree " as res `p' as txt " in " as res `d' as txt " dimension" ///
        cond(`d' == 1, "", "s") ": " as res `N' as txt " nodes, in frame " as res "`frame'" ///
        as txt " (variables x1" cond(`d' == 1, "", "..x`d'") ", w)"
    return scalar n = `N'
    return scalar d = `d'
    return scalar p = `p'
    return scalar normalize = `norm'
    return scalar pragmatic = `prag'
    return local family `fam'
    return local frame `frame'
end

* quadriceps nnodes gh|le d [q] [, p() pragmatic]
program _quadriceps_nnodes, rclass
    version 16
    gettoken fam 0 : 0
    local fam = lower("`fam'")
    _quadriceps_family `fam'
    syntax [anything(name=dq id="d and q")] [, P(numlist max=1 integer >=0) PRAGmatic]
    _quadriceps_degree `dq', `=cond("`p'" != "", "p(`p')", "")'
    local d `s(d)'
    local p `s(p)'
    local prag = ("`pragmatic'" != "")
    tempname N
    mata: st_numscalar("`N'", quadriceps_nnodes("`fam'", `d', `p', `prag'))
    di as txt "nodes: " as res %21.0g `N'
    return scalar n = `N'
    return scalar d = `d'
    return scalar p = `p'
    return local family `fam'
end

* quadriceps ruleinfo gh|le d [q] [, p() pragmatic]
program _quadriceps_ruleinfo, rclass
    version 16
    gettoken fam 0 : 0
    local fam = lower("`fam'")
    _quadriceps_family `fam'
    syntax [anything(name=dq id="d and q")] [, P(numlist max=1 integer >=0) PRAGmatic]
    _quadriceps_degree `dq', `=cond("`p'" != "", "p(`p')", "")'
    local d `s(d)'
    local p `s(p)'
    local prag = ("`pragmatic'" != "")
    tempname F
    mata: quadriceps_ruleinfo_st("`fam'", `d', `p', `prag', "`F'")
    return matrix factors = `F'
    forvalues k = 1/`nfactors' {
        return local origin`k' `"`origin`k''"'
    }
    return scalar nfactors = `nfactors'
    return scalar n = `n'
    return scalar d = `d'
    return scalar p = `p'
    return local family `fam'
end

* quadriceps rules [gh|le]
program _quadriceps_rules, rclass
    version 16
    syntax [anything(name=fams id="family")]
    local fams = lower("`fams'")
    if "`fams'" == "" local fams gh le
    foreach fam of local fams {
        _quadriceps_family `fam'
        mata: quadriceps_rules_st("`fam'")
    }
end

* quadriceps check gh|le d [q] [, p() pragmatic]: the largest relative monomial error of the rule
program _quadriceps_check, rclass
    version 16
    gettoken fam 0 : 0
    local fam = lower("`fam'")
    _quadriceps_family `fam'
    syntax [anything(name=dq id="d and q")] [, P(numlist max=1 integer >=0) PRAGmatic]
    _quadriceps_degree `dq', `=cond("`p'" != "", "p(`p')", "")'
    local d `s(d)'
    local p `s(p)'
    local prag = ("`pragmatic'" != "")
    tempname E N
    mata: quadriceps_check_st("`fam'", `d', `p', `prag', "`E'", "`N'")
    di as txt "largest relative monomial error up to degree " as res `p' as txt ": " as res %10.3e `E' ///
        as txt " (" as res `N' as txt " nodes)"
    return scalar err = `E'
    return scalar n = `N'
    return scalar d = `d'
    return scalar p = `p'
    return local family `fam'
end

program _quadriceps_version, rclass
    version 16
    tempname C
    mata: quadriceps_version_st("`C'")
    di as txt "quadriceps 0.1.2 (24sep2026): " as res `C' as txt " stored rules, data format QUADRICEPS1"
    return local version 0.1.2
    return scalar cells = `C'
end
