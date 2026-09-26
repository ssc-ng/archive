*! sreg_rgen 1.0.0 24sep2026 -- Generate stratified randomized experiments
program define sreg_rgen, rclass
    version 14.2
    syntax , N(integer) [NMAX(integer 50) STRata(integer 10) ///
        TAU(numlist) GAMMA(numlist min=3 max=3) INDIVidual NOCOVariates ///
        SMALLSTRata MIXEDSTRata K(integer 3) NSMALL(integer -1) ///
        TREATSizes(numlist) ALLOCATION(name) STRATUMEFFECTS(numlist) ///
        TREATMENTEffects(name) CLEAR]
    if "`clear'" == "" & (c(N) > 0 | c(k) > 0) {
        di as error "Data in memory; specify clear to replace them."
        exit 4
    }
    if "`tau'" == "" local tau 0
    if "`gamma'" == "" local gamma .4 .2 1
    local cl = ("`individual'" == "")
    local cov = ("`nocovariates'" == "")
    local ss = ("`smallstrata'" != "")
    local mix = ("`mixedstrata'" != "")
    if `ss' & `mix' {
        di as error "Specify smallstrata or mixedstrata, not both."
        exit 198
    }
    capture quietly mata: sreg_rgen_version()
    if _rc == 3499 {
        quietly findfile sreg_rgen.mata
        quietly do "`r(fn)'"
    }
    // Validation and generation precede replacement; preserve also protects against storage errors.
    preserve
    capture noisily mata: sreg_rgen_run(`n', `nmax', `strata', `cl', `cov', `ss', `mix', `k', `nsmall')
    local rc = _rc
    if `rc' {
        restore
        exit `rc'
    }
    restore, not
    return scalar N = _N
    return scalar N_units = `n'
    return scalar cluster = `cl'
    return scalar N_treatments = `: word count `tau''
    return scalar n_small = `actualsmall'
    return local design "`gendesign'"
end
