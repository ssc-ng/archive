*! lillardhaz_d0 v1.0.0  25sep2026
*! General d0 evaluator for lillardhaz: any combination of
*! {probit, lognormal, pgompertz} for eq1 x {lognormal, pgompertz} for eq2,
*! with or without Gaussian-copula correlation between the two equations.
*! Author: Nobutaka Fukuda, Tohoku University <nobutaka.fukuda@tohoku.ac.jp>
*!
*! Driven by globals set by lillardhaz.ado before calling `ml model d0`:
*!   $LH_eq1type   "probit" | "lognormal" | "pgompertz"
*!   $LH_eq2type   "lognormal" | "pgompertz"
*!   $LH_nodes1    space-separated interior nodes for eq1 (if pgompertz)
*!   $LH_nodes2    space-separated interior nodes for eq2 (if pgompertz)
*!   $LH_corr      1 (correlated) or 0 (independent -- rho fixed at 0,
*!                 no atanh_rho equation is part of the model)
*!
*! Equation layout (built by the wrapper to match):
*!   eq(1)                = eq1 location index
*!   eq(2 .. 1+A1)         = eq1 ancillary scalars (A1 of them: 1 for
*!                            lognormal [ln_sigma1], K1 for pgompertz
*!                            [segment slopes], 0 for probit)
*!   eq(2+A1)              = eq2 location index
*!   eq(3+A1 .. 2+A1+A2)   = eq2 ancillary scalars (A2: 1 for lognormal,
*!                            K2 for pgompertz)
*!   eq(3+A1+A2)           = atanh_rho, only present if $LH_corr==1
*!
*! See docs/manual.html for the full derivation of every branch below
*! (Gaussian-copula joint likelihood, corrected relative to the
*! (1-rho^2)-inverted formula found throughout the original .do files
*! this package is based on) and its simulation-based verification.

capture program drop lillardhaz_d0
program define lillardhaz_d0
    version 17
    args todo b lnf
    quietly {

    local eq1type "$LH_eq1type"
    local eq2type "$LH_eq2type"
    local corr = $LH_corr

    * -------- eq1: location + ancillary parameters --------
    tempvar theta1
    mleval `theta1' = `b', eq(1)

    local nexteq = 2
    if "`eq1type'" == "lognormal" {
        tempvar lnsig1
        mleval `lnsig1' = `b', eq(`nexteq')
        local nexteq = `nexteq' + 1
    }
    else if "`eq1type'" == "pgompertz" {
        local nodes1 "$LH_nodes1"
        local K1 : word count `nodes1'
        local K1 = `K1' + 1
        tempname slopes1
        matrix `slopes1' = J(1, `K1', 0)
        forvalues k = 1/`K1' {
            tempvar sl
            mleval `sl' = `b', eq(`nexteq')
            summarize `sl', meanonly
            matrix `slopes1'[1,`k'] = r(mean)
            local nexteq = `nexteq' + 1
        }
    }

    * -------- eq2: location + ancillary parameters --------
    tempvar theta2
    mleval `theta2' = `b', eq(`nexteq')
    local nexteq = `nexteq' + 1

    if "`eq2type'" == "lognormal" {
        tempvar lnsig2
        mleval `lnsig2' = `b', eq(`nexteq')
        local nexteq = `nexteq' + 1
    }
    else {
        local nodes2 "$LH_nodes2"
        local K2 : word count `nodes2'
        local K2 = `K2' + 1
        tempname slopes2
        matrix `slopes2' = J(1, `K2', 0)
        forvalues k = 1/`K2' {
            tempvar sl
            mleval `sl' = `b', eq(`nexteq')
            summarize `sl', meanonly
            matrix `slopes2'[1,`k'] = r(mean)
            local nexteq = `nexteq' + 1
        }
    }

    * -------- correlation --------
    tempvar rho
    if `corr' == 1 {
        tempvar atrho
        mleval `atrho' = `b', eq(`nexteq')
        gen double `rho' = tanh(`atrho')
    }
    else {
        gen double `rho' = 0
    }

    * ==================================================================
    * eq1 marginal: z1 (copula residual), and either f1/S1 (hazard) or
    * w1 (probit index) as appropriate
    * ==================================================================
    tempvar z1 f1 S1
    if "`eq1type'" == "probit" {
        * probit's own latent index IS its copula residual; no separate
        * z1/f1/S1 needed -- handled directly via `theta1' below.
    }
    else if "`eq1type'" == "lognormal" {
        tempvar sigma1
        gen double `sigma1' = exp(`lnsig1')
        gen double `z1' = (ln($ML_y1) - `theta1')/`sigma1'
        gen double `f1' = normalden(`z1')/(`sigma1'*$ML_y1)
        gen double `S1' = 1 - normal(`z1')
    }
    else {
        * pgompertz: general K1-segment survival/density, then z1 via the
        * probability integral transform (verified against the log-normal
        * closed form and against direct simulation; see manual.html)
        _lillardhaz_pgomp `theta1' `slopes1' "`nodes1'" $ML_y1 `S1' `f1'
        gen double `z1' = invnormal(1-`S1')
    }

    * ==================================================================
    * eq2 marginal: always a hazard type. Its TIME depvar's $ML_y# index
    * depends on how many depvars eq1 contributed: probit's equation
    * carries only 1 depvar (the binary outcome), so eq2's time is $ML_y2;
    * a hazard eq1 carries 2 depvars (time, failure), so eq2's time is
    * $ML_y3. (Its failure indicator is one further along in each case,
    * $ML_y3/$ML_y4 respectively -- already handled correctly below since
    * that's branched separately per eq1type.)
    * ==================================================================
    if "`eq1type'" == "probit" local y2time "$ML_y2"
    else                        local y2time "$ML_y3"

    tempvar z2 f2 S2
    if "`eq2type'" == "lognormal" {
        tempvar sigma2
        gen double `sigma2' = exp(`lnsig2')
        gen double `z2' = (ln(`y2time') - `theta2')/`sigma2'
        gen double `f2' = normalden(`z2')/(`sigma2'*`y2time')
        gen double `S2' = 1 - normal(`z2')
    }
    else {
        _lillardhaz_pgomp `theta2' `slopes2' "`nodes2'" `y2time' `S2' `f2'
        gen double `z2' = invnormal(1-`S2')
    }

    * ==================================================================
    * joint log-likelihood
    * ==================================================================
    tempvar a cont
    gen double `a' = sqrt(1-`rho'^2)
    gen double `cont' = .

    if "`eq1type'" == "probit" {
        * $ML_y1 here is the binary outcome (0/1); $ML_y3 is eq2's failure
        * indicator (see wrapper for exact depvar ordering)
        replace `cont' = `f2'*normal((`theta1'+`rho'*`z2')/`a')            if $ML_y1==1 & $ML_y3==1
        replace `cont' = normal(`theta1') - binormal(`theta1', `z2', -`rho') if $ML_y1==1 & $ML_y3==0
        replace `cont' = `f2'*normal(-(`theta1'+`rho'*`z2')/`a')           if $ML_y1==0 & $ML_y3==1
        replace `cont' = binormal(-`theta1', -`z2', -`rho')                if $ML_y1==0 & $ML_y3==0
    }
    else {
        * both eq1, eq2 are hazard types; $ML_y2 = eq1 failure, $ML_y4 = eq2 failure
        replace `cont' = exp( -(`z1'^2-2*`rho'*`z1'*`z2'+`z2'^2)/(2*`a'^2) )/(2*_pi*`a') * `f1'/normalden(`z1') * `f2'/normalden(`z2') if $ML_y2==1 & $ML_y4==1
        replace `cont' = `f1' * (1 - normal((`z2'-`rho'*`z1')/`a'))  if $ML_y2==1 & $ML_y4==0
        replace `cont' = `f2' * (1 - normal((`z1'-`rho'*`z2')/`a'))  if $ML_y2==0 & $ML_y4==1
        replace `cont' = binormal(-`z1', -`z2', `rho')                if $ML_y2==0 & $ML_y4==0
    }

    mlsum `lnf' = ln(`cont')
    if (`todo'==0 | `lnf'>=.) exit
    }
end
