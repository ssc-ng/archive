*! rmstpath 0.1.3 16oct2026 -- unadjusted KM RMST difference paths
*
* License: MIT (full notice follows; the analysis code is unchanged).
* MIT License
*
* Copyright (c) 2026 Christina Laternser
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
program define rmstpath, rclass
    version 14.2
    syntax varname(numeric) [if] [in], TAU(string asis) ///
        [PRIMARY(real -1) LEVEL(cilevel) NOGRAPH CISTYLE(string) ///
         SAVING(string asis) REPLACE UNITS(string) NAME(name) *]

    local group `varlist'
    if `level' <= 0 | `level' >= 100 {
        di as error "level() must be strictly between 0 and 100"
        exit 198
    }

    * Reject weighted stset data rather than silently doing an unweighted analysis.
    st_is 2 analysis
    local st_wv : char _dta[st_wv]
    local st_wt : char _dta[st_wt]
    if `"`st_wv'"' != "" | `"`st_wt'"' != "" {
        di as error "weighted stset data are not supported by rmstpath"
        di as error "unset survival weights or use a method that handles them"
        exit 198
    }
    foreach v in _t _t0 _d {
        capture confirm numeric variable `v'
        if _rc {
            di as error "stset variable `v' not found; run stset first"
            exit 119
        }
    }

    tempvar touse
    marksample touse
    quietly replace `touse' = 0 if _st != 1
    quietly count if `touse'
    if r(N) == 0 {
        di as error "no stset observations in the requested sample"
        exit 2000
    }
    quietly count if `touse' & (_t0 != 0 | _t < 0)
    if r(N) {
        di as error "v0.1 requires each observation to enter at time zero"
        di as error "delayed entry and multiple-record survival data are unsupported"
        exit 198
    }
    * stset, id() records the name in a dataset characteristic (not _id).
    local st_id : char _dta[st_id]
    if `"`st_id'"' != "" {
        capture isid `st_id' if `touse'
        if _rc {
            di as error "rmstpath requires one survival record per subject"
            exit 198
        }
    }
    quietly count if `touse' & !inlist(_d, 0, 1)
    if r(N) {
        di as error "_d must contain only zero or one in the analysis sample"
        exit 459
    }

    quietly levelsof `group' if `touse', local(groups)
    local ngroups : word count `groups'
    if `ngroups' != 2 {
        di as error "exactly two observed numeric group values are required"
        exit 198
    }
    local g0 : word 1 of `groups'
    local g1 : word 2 of `groups'

    capture noisily numlist `"`tau'"', range(>0) sort min(2)
    if _rc {
        di as error "tau() must specify at least two positive horizons"
        exit 198
    }
    local taus `r(numlist)'
    local prev = -1
    foreach t of local taus {
        if `t' <= `prev' {
            di as error "tau() horizons must be distinct"
            exit 198
        }
        local prev = `t'
    }
    local nt : word count `taus'
    local maxtau : word `nt' of `taus'

    if `primary' != -1 {
        if `primary' <= 0 {
            di as error "primary() must be a positive horizon included in tau()"
            exit 198
        }
        local found = 0
        foreach t of local taus {
            if abs(`primary' - `t') < 1e-10 local found = 1
        }
        if !`found' {
            di as error "primary() must equal one of the tau() horizons"
            exit 198
        }
    }

    quietly summarize _t if `touse' & `group' == `g0', meanonly
    local max0 = r(max)
    quietly count if `touse' & `group' == `g0'
    local n0 = r(N)
    quietly count if `touse' & `group' == `g0' & _d == 1
    local d0 = r(N)
    quietly summarize _t if `touse' & `group' == `g1', meanonly
    local max1 = r(max)
    quietly count if `touse' & `group' == `g1'
    local n1 = r(N)
    quietly count if `touse' & `group' == `g1' & _d == 1
    local d1 = r(N)
    if `maxtau' > `max0' | `maxtau' > `max1' {
        di as error "largest tau() exceeds observed follow-up in at least one group"
        di as error "maximum group follow-up: `g0' = `max0'; `g1' = `max1'"
        exit 198
    }

    if `"`cistyle'"' == "" local cistyle "band"
    local cistyle = lower(strtrim(`"`cistyle'"'))
    if !inlist("`cistyle'", "band", "lines") {
        di as error "cistyle() must be band or lines"
        exit 198
    }

    * Plot labels follow the stset time scale; users should specify units().
    if `"`units'"' == "" local units "time units"
    local units = strtrim(`"`units'"')

    * Stata-conventional saving(filename[, replace]); retain legacy top-level
    * replace for scripts written against the experimental v0.1.2 command.
    * Use compound quotes for the raw saving() argument, but let gettoken
    * strip the outer filename quotes so we can safely re-quote at save.
    local savefile `"`saving'"'
    local savereplace `replace'
    if `"`saving'"' != "" {
        gettoken savefile saveextra : saving, parse(",")
        local saveextra = strtrim(`"`saveextra'"')
        if `"`saveextra'"' != "" {
            gettoken sep saveextra : saveextra, parse(",")
            local saveextra = lower(strtrim(`"`saveextra'"'))
            if `"`sep'"' != "," | `"`saveextra'"' != "replace" {
                di as error "saving() suboption must be replace"
                exit 198
            }
            local savereplace replace
        }
        if `"`savefile'"' == "" {
            di as error "saving() requires a filename"
            exit 198
        }
    }
    else if "`replace'" != "" {
        di as error "replace requires saving()"
        exit 198
    }

    tempname R
    mata: rmstpath__work("`group'", "`touse'", "`taus'", ///
        `g0', `g1', `level', "`R'")
    matrix colnames `R' = tau rmst0 rmst1 diff se ll ul nrisk0 nrisk1

    di as txt _newline "RMST path: unadjusted Kaplan-Meier estimates"
    di as txt "Group 0 = `g0' (N=`n0'); group 1 = `g1' (N=`n1')"
    di as txt "Difference = group 1 - group 0; `level'% pointwise normal CI"
    di as txt "    Tau    RMST0    RMST1     Diff       SE    Lower    Upper    Risk0 Risk1"
    di as txt "--------------------------------------------------------------------------"
    forvalues i = 1/`nt' {
        di as res %7.2f `R'[`i',1] " " ///
            %8.3f `R'[`i',2] " " %8.3f `R'[`i',3] " " ///
            %8.3f `R'[`i',4] " " %8.3f `R'[`i',5] " " ///
            %8.3f `R'[`i',6] " " %8.3f `R'[`i',7] " " ///
            %5.0f `R'[`i',8] " " %5.0f `R'[`i',9]
    }
    di as txt "--------------------------------------------------------------------------"
    di as txt "CI = Greenwood plug-in, pointwise; not a simultaneous band."
    di as txt "Risk0/Risk1 = numbers at risk just before each horizon."
    if `d0' == 0 | `d1' == 0 {
        di as error "Caution: a group has no events; Greenwood SE may be zero."
    }
    quietly count if `touse' & `group' == `g0' & _t >= `maxtau'
    local nr0 = r(N)
    quietly count if `touse' & `group' == `g1' & _t >= `maxtau'
    local nr1 = r(N)
    if `nr0' < 10 | `nr1' < 10 {
        di as text "Caution: fewer than 10 at risk in a group at the last horizon."
    }

    if `"`saving'"' != "" {
        preserve
        quietly clear
        quietly svmat double `R', names(col)
        if "`savereplace'" == "" {
            quietly save `"`savefile'"'
        }
        else {
            quietly save `"`savefile'"', replace
        }
        restore
    }

    local graphname "RMSTPath"
    local graphnameopt "name(RMSTPath, replace)"
    if "`name'" != "" {
        local graphname "`name'"
        local graphnameopt "name(`name')"
    }
    if "`nograph'" == "" {
        preserve
        * The plotting grid includes every pooled failure time, tau() points,
        * zero, max(tau), and a fine grid for curvature of pointwise CIs.
        * RMST difference has exact event-time knots; table remains unchanged.
        tempvar ptau pdiff pll pul
        quietly generate double `ptau' = .
        quietly generate double `pdiff' = .
        quietly generate double `pll' = .
        quietly generate double `pul' = .
        mata: rmstpath__plotfill("`group'", "`touse'", "`taus'", ///
            `g0', `g1', `level', "`ptau' `pdiff' `pll' `pul'")

        local pline ""
        local primarynote ""
        if `primary' != -1 {
            local pline "xline(`primary', lcolor(gs8) lpattern(shortdash))"
            local primarynote `"note("Primary horizon = `primary' `units' (vertical dashed line)", size(small))"'
        }
        * Permit ordinary twoway graph options and an explicit graph name.
        * User-supplied title/label/region overrides suppress our defaults.
        local gtitle `"title("Restricted mean survival time path")"'
        local gsubtitle `"subtitle("Pointwise `level'% confidence intervals")"'
        local gxtitle `"xtitle("Follow-up horizon (`units')")"'
        local gytitle `"ytitle("RMST difference (group 1 - group 0; `units')")"'
        local greg "graphregion(color(white))"
        local preg "plotregion(color(white))"
        local glegend "legend(off)"
        local opts_l = lower(`"`options'"')
        if regexm(`"`opts_l'"', "(^|[ ,])title[(]") local gtitle ""
        if regexm(`"`opts_l'"', "(^|[ ,])subtitle[(]") local gsubtitle ""
        if regexm(`"`opts_l'"', "(^|[ ,])xtitle[(]") local gxtitle ""
        if regexm(`"`opts_l'"', "(^|[ ,])ytitle[(]") local gytitle ""
        if regexm(`"`opts_l'"', "(^|[ ,])graphregion[(]") local greg ""
        if regexm(`"`opts_l'"', "(^|[ ,])plotregion[(]") local preg ""
        if regexm(`"`opts_l'"', "(^|[ ,])legend[(]") local glegend ""
        if regexm(`"`opts_l'"', "(^|[ ,])note[(]") local primarynote ""
        if regexm(`"`opts_l'"', "(^|[ ,])xline[(]") local pline ""

        if "`cistyle'" == "band" {
            twoway (rarea `pll' `pul' `ptau', sort color(gs14) lcolor(gs14)) ///
                (line `pdiff' `ptau', sort lcolor(black) lpattern(solid) lwidth(medthick)), ///
                `glegend' yline(0, lcolor(gs8) lpattern(dash)) ///
                `pline' `primarynote' `gxtitle' `gytitle' ///
                `gtitle' `gsubtitle' `greg' `preg' `graphnameopt' `options'
        }
        else {
            twoway (line `pll' `ptau', sort lcolor(gs9) lpattern(dash)) ///
                (line `pul' `ptau', sort lcolor(gs9) lpattern(dash)) ///
                (line `pdiff' `ptau', sort lcolor(black) lpattern(solid) lwidth(medthick)), ///
                `glegend' yline(0, lcolor(gs8) lpattern(dash)) ///
                `pline' `primarynote' `gxtitle' `gytitle' ///
                `gtitle' `gsubtitle' `greg' `preg' `graphnameopt' `options'
        }
        restore
    }

    return matrix results = `R'
    return scalar level = `level'
    return scalar n0 = `n0'
    return scalar n1 = `n1'
    return scalar events0 = `d0'
    return scalar events1 = `d1'
    return scalar max_follow0 = `max0'
    return scalar max_follow1 = `max1'
    return scalar group0 = `g0'
    return scalar group1 = `g1'
    return scalar k_tau = `nt'
    if `primary' != -1 return scalar primary = `primary'
    return local cmd "rmstpath"
    return local ci "Greenwood plug-in, pointwise normal"
    if `"`nograph'"' == "" return local graph_name "`graphname'"
end

capture mata: mata drop rmstpath__one()
capture mata: mata drop rmstpath__work()
capture mata: mata drop rmstpath__oneplot()
capture mata: mata drop rmstpath__plotfill()
mata:
real matrix rmstpath__one(real matrix X, real rowvector taus)
{
    real scalar n, j, start, e, tt, deaths, risk, prev, area, surv
    real scalar i, k, mu, v, tail
    real colvector evtime, evarea, evsurv, evw
    real matrix answer

    n = rows(X)
    X = X[order(X, 1), .]
    evtime = J(n, 1, .)
    evarea = J(n, 1, .)
    evsurv = J(n, 1, .)
    evw = J(n, 1, 0)
    j = 1
    e = 0
    prev = 0
    area = 0
    surv = 1
    risk = n
    while (j <= n) {
        tt = X[j, 1]
        start = j
        deaths = 0
        while (j <= n) {
            if (X[j, 1] != tt) break
            deaths = deaths + X[j, 2]
            j = j + 1
        }
        area = area + (tt - prev) * surv
        if (deaths > 0) {
            e = e + 1
            evtime[e] = tt
            evarea[e] = area
            surv = surv * (1 - deaths / risk)
            evsurv[e] = surv
            if (risk > deaths) evw[e] = deaths / (risk * (risk - deaths))
        }
        risk = risk - (j - start)
        prev = tt
    }

    answer = J(cols(taus), 3, .)
    for (i = 1; i <= cols(taus); i++) {
        k = 0
        while (k < e) {
            if (evtime[k+1] >= taus[i]) break
            k = k + 1
        }
        if (k == 0) mu = taus[i]
        else mu = evarea[k] + (taus[i] - evtime[k]) * evsurv[k]
        v = 0
        for (j = 1; j <= k; j++) {
            tail = mu - evarea[j]
            v = v + evw[j] * tail * tail
        }
        // Number at risk immediately before horizon tau (includes exits at tau).
        answer[i, .] = (mu, v, sum(X[,1] :>= taus[i]))
    }
    return(answer)
}

void rmstpath__work(string scalar groupvar, string scalar markvar,
    string scalar tstr, real scalar g0, real scalar g1,
    real scalar level, string scalar resultname)
{
    real matrix D, G0, G1, M0, M1, result
    real rowvector taus
    real scalar i, se, z
    taus = strtoreal(tokens(tstr))
    D = st_data(., ("_t", "_d", groupvar), markvar)
    G0 = select(D[, (1,2)], D[,3] :== g0)
    G1 = select(D[, (1,2)], D[,3] :== g1)
    M0 = rmstpath__one(G0, taus)
    M1 = rmstpath__one(G1, taus)
    result = J(cols(taus), 9, .)
    z = invnormal(1 - (1 - level / 100) / 2)
    for (i = 1; i <= cols(taus); i++) {
        se = sqrt(M0[i,2] + M1[i,2])
        result[i,.] = (taus[i], M0[i,1], M1[i,1],
            M1[i,1] - M0[i,1], se,
            M1[i,1] - M0[i,1] - z*se,
            M1[i,1] - M0[i,1] + z*se,
            M0[i,3], M1[i,3])
    }
    st_matrix(resultname, result)
}

// Numerically stable forward recursion for plotting at sorted horizons.
// At each event time, update V and Q with the increment in integrated KM;
// a new Greenwood weight contributes zero tail at its own event time.
real matrix rmstpath__oneplot(real matrix X, real colvector H)
{
    real scalar n, j, start, deaths, risk, prev, area, surv
    real scalar W, Q, V, tt, inc, mu, i, vk
    real matrix ans
    n = rows(X)
    X = X[order(X, 1), .]
    j=1; prev=0; area=0; surv=1; risk=n; W=0; Q=0; V=0
    ans = J(rows(H), 2, .)
    for (i=1; i<=rows(H); i++) {
        while (j<=n) {
            tt = X[j,1]
            if (tt >= H[i]) break
            inc = (tt-prev)*surv
            V = V + 2*inc*Q + inc*inc*W
            Q = Q + inc*W
            area = area + inc
            start = j; deaths=0
            while (j<=n) {
                if (X[j,1]!=tt) break
                deaths = deaths + X[j,2]
                j = j+1
            }
            if (deaths>0) {
                surv = surv*(1 - deaths/risk)
                if (risk>deaths) W = W + deaths/(risk*(risk-deaths))
            }
            risk = risk-(j-start)
            prev = tt
        }
        inc = (H[i]-prev)*surv
        mu = area+inc
        vk = V + 2*inc*Q + inc*inc*W
        if (vk<0 & vk>-1e-12) vk=0
        ans[i,.] = (mu, vk)
    }
    return(ans)
}

void rmstpath__plotfill(string scalar groupvar, string scalar markvar,
    string scalar tstr, real scalar g0, real scalar g1, real scalar level,
    string scalar vars)
{
    real matrix D, G0, G1, A0, A1, R, C0, C1, B0, B1
    real colvector H, E, dense
    real rowvector taus
    real scalar i, m, z
    string rowvector v
    taus = strtoreal(tokens(tstr))
    D = st_data(., ("_t","_d",groupvar), markvar)
    G0 = select(D[,(1,2)], D[,3]:==g0)
    G1 = select(D[,(1,2)], D[,3]:==g1)
    E = select(D[,1], (D[,2]:==1):&(D[,1]:<=taus[cols(taus)]))
    dense = (0::200) :* (taus[cols(taus)]/200)
    H = uniqrows(sort((dense\taus'\E),1))
    m = rows(H)
    A0 = rmstpath__oneplot(G0,H)
    A1 = rmstpath__oneplot(G1,H)
    // Guard against disagreement between new plot recursion and validated engine.
    // The reference engine is called only at the small user-supplied tau() grid.
    C0 = rmstpath__oneplot(G0,taus')
    C1 = rmstpath__oneplot(G1,taus')
    B0 = rmstpath__one(G0,taus)
    B1 = rmstpath__one(G1,taus)
    if (max(abs(C0-B0[,(1,2)]))>1e-8 | max(abs(C1-B1[,(1,2)]))>1e-8) {
        errprintf("plotting recursion disagrees with table results; graph not drawn\n")
        _error(459)
    }
    z = invnormal(1-(1-level/100)/2)
    R = J(m,4,.)
    for (i=1;i<=m;i++) {
        R[i,1] = H[i]
        R[i,2] = A1[i,1]-A0[i,1]
        R[i,3] = R[i,2]-z*sqrt(A0[i,2]+A1[i,2])
        R[i,4] = R[i,2]+z*sqrt(A0[i,2]+A1[i,2])
    }
    if (st_nobs()<m) st_addobs(m-st_nobs())
    v = tokens(vars)
    st_store((1::m),v,R)
}

end
