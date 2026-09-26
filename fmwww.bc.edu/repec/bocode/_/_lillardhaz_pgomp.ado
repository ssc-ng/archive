*! _lillardhaz_pgomp v1.0.0  25sep2026
*! Internal helper: piecewise Gompertz survival S(t) and density f(t) for
*! an arbitrary number of segments, given a per-observation location
*! variable, a 1xK matrix of segment slopes, and a space-separated list of
*! K-1 interior nodes. Generates its two output variables directly (Stata
*! subroutines share the caller's dataset in memory; r()-returns cannot
*! carry per-observation results, hence this interface).
*!
*! ln h(t) = theta + L_k + slope_k*(t - node_{k-1})  for t in segment k
*! with L_k built recursively so the log-hazard is continuous across nodes
*! (Lillard 1993, eq. following footnote 6: piecewise-linear-in-time log
*! hazard, i.e. piecewise Gompertz). See docs/manual.html.
*!
*! Usage: _lillardhaz_pgomp theta slopes_matname "node list" timevar Sout fout
*! Author: Nobutaka Fukuda, Tohoku University <nobutaka.fukuda@tohoku.ac.jp>

capture program drop _lillardhaz_pgomp
program define _lillardhaz_pgomp
    version 17
    args theta slopes nodes t Sout fout
    quietly {
        local K = colsof(`slopes')

        * cumulative level and start-node for each segment (fixed given
        * current slope values; recomputed every ml iteration since slopes
        * change, but these are scalars -- cheap)
        tempname levels startnodes
        matrix `levels' = J(1, `K', 0)
        matrix `startnodes' = J(1, `K', 0)
        local cumlevel = 0
        local prevnode = 0
        forvalues k = 1/`K' {
            matrix `levels'[1,`k'] = `cumlevel'
            matrix `startnodes'[1,`k'] = `prevnode'
            if `k' < `K' {
                local thisnode : word `k' of `nodes'
                local seglen = `thisnode' - `prevnode'
                local slope_k = `slopes'[1,`k']
                local cumlevel = `cumlevel' + `slope_k'*`seglen'
                local prevnode = `thisnode'
            }
        }

        * which segment does each observation's own time fall into
        tempvar m
        gen double `m' = `K'
        forvalues k = 1/`=`K'-1' {
            local thisnode : word `k' of `nodes'
            replace `m' = `k' if `t' < `thisnode' & `m'==`K'
        }

        tempvar H h
        gen double `H' = 0
        gen double `h' = .
        forvalues k = 1/`K' {
            local lev_k = `levels'[1,`k']
            local sl_k  = `slopes'[1,`k']
            local sn_k  = `startnodes'[1,`k']
            if `k' < `K' {
                local thisnode : word `k' of `nodes'
                local seglen = `thisnode' - `sn_k'
                replace `H' = `H' + exp(`theta')*cond(abs(`sl_k')<1e-8, exp(`lev_k')*`seglen', ///
                    exp(`lev_k')/`sl_k'*(exp(`sl_k'*`seglen')-1)) if `m' > `k'
            }
            replace `H' = `H' + exp(`theta')*cond(abs(`sl_k')<1e-8, exp(`lev_k')*(`t'-`sn_k'), ///
                exp(`lev_k')/`sl_k'*(exp(`sl_k'*(`t'-`sn_k'))-1)) if `m'==`k'
            replace `h' = exp(`theta'+`lev_k'+`sl_k'*(`t'-`sn_k')) if `m'==`k'
        }

        gen double `Sout' = exp(-`H')
        gen double `fout' = `h'*`Sout'
    }
end
