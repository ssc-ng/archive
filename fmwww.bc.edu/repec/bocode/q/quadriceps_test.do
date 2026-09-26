* quadriceps_test.do -- tests of the Stata package quadriceps.  Run:
*
*     do quadriceps_test.do
*
* after installing the package (net install quadriceps, from(...)), or with a checkout of the
* repository on the ado-path (adopath + "path/to/quadriceps-stata").  Every check is one
* expect(); nothing stops at a failure.  The script writes quadriceps_test.log next to itself
* and ends with a summary line "N checks, M failed" followed by the failed checks, if any.
* Please send the whole log to the author when something fails.

version 16
clear all
set more off
capture log close qt
log using quadriceps_test.log, replace text name(qt)
about
display "`c(current_date)' `c(current_time)'  Stata `c(stata_version)' `c(os)' `c(machine_type)'"

quadriceps version              // loads the package, including its Mata functions
local GATE 1e-11                // every stored rule passed this gate when the data were built

global QT_checks 0
global QT_failed 0
global QT_fails ""

program qt_expect
    args ok what
    global QT_checks = $QT_checks + 1
    if !`ok' {
        global QT_failed = $QT_failed + 1
        global QT_fails `"$QT_fails`what'; "'
        display as error "FAIL: `what'"
    }
end

* qt_rc rc "what" command...: the command must fail with return code rc ("any": any nonzero)
program qt_rc
    gettoken rc 0 : 0
    gettoken what 0 : 0
    capture `0'
    local got = _rc
    if "`rc'" == "any" {
        local ok = (`got' != 0)
        local want any nonzero
    }
    else {
        local ok = (`got' == `rc')
        local want `rc'
    }
    qt_expect `ok' "`what' (rc `got', wanted `want')"
end

* qt_frame name n d "what": the frame holds an n x d rule in x1..xd, w with positive weights
program qt_frame
    args name n d what
    frame `name' {
        qt_expect `=_N == `n'' "`what': `n' observations"
        local vars
        forvalues k = 1/`d' {
            local vars `vars' x`k'
        }
        capture confirm variable `vars' w
        qt_expect `=_rc == 0' "`what': variables x1..x`d' w"
        capture confirm variable x`=`d' + 1'
        qt_expect `=_rc != 0' "`what': no variable x`=`d' + 1'"
        if _N > 0 {
            summarize w, meanonly
            qt_expect `=r(min) > 0' "`what': positive weights"
        }
    }
end

* --- the command interface ------------------------------------------------------------------

ghpos 3 4
qt_expect `=r(n) == 27' "ghpos 3 4: r(n)"
qt_expect `=r(d) == 3 & r(p) == 7 & r(normalize) == 1 & r(pragmatic) == 0' "ghpos 3 4: r(d) r(p) r(normalize) r(pragmatic)"
qt_expect `="`r(family)'" == "gh" & "`r(frame)'" == "quadriceps"' "ghpos 3 4: r(family) r(frame)"
qt_frame quadriceps 27 3 "ghpos 3 4"
frame quadriceps {
    generate double f = w * x1^2 * x2^4
    summarize f, meanonly
    qt_expect `=abs(r(sum) - 3) < 1e-12' "ghpos 3 4: E[Z1^2 Z2^4] = 3"
    summarize w, meanonly
    qt_expect `=abs(r(sum) - 1) < 1e-12' "ghpos 3 4: weights sum to 1"
}
ghpos 3 4                                           // the default frame is overwritten without replace
qt_frame quadriceps 27 3 "ghpos 3 4 again"

quadriceps gh 3 4, matrix(A)
ghpos 3, p(7) matrix(B)
qt_expect `=mreldif(A, B) == 0' "quadriceps gh = ghpos, and p(7) = q 4"
ghpos 3, p(6) matrix(B)
qt_expect `=mreldif(A, B) == 0' "even p gets the next odd degree"
qt_expect `=colsof(B) == 4 & rowsof(B) == 27' "matrix() is n x (d + 1)"
local names : colnames B
qt_expect `="`names'" == "x1 x2 x3 w"' "matrix() column names"

lepos 2 5, frame(square) replace
qt_expect `=r(n) == 17 & "`r(frame)'" == "square"' "lepos 2 5: 17 nodes in frame square"
qt_frame square 17 2 "lepos 2 5"
frame square {
    generate double f = w * x1^3 * x2^2
    summarize f, meanonly
    qt_expect `=abs(r(sum) - 1/12) < 1e-12' "lepos 2 5: E[U1^3 U2^2] = 1/12"
    summarize x1, meanonly
    qt_expect `=r(min) > 0 & r(max) < 1' "lepos 2 5: nodes inside the unit square"
}
qt_rc 110 "existing frame without replace" lepos 2 5, frame(square)
lepos 2 5, frame(square) replace
qt_frame square 17 2 "lepos 2 5 with replace"
frame drop square

lepos 2 5, mata(QX Qw)
mata: st_numscalar("qt_ok", rows(QX) == 17 & cols(QX) == 2 & rows(Qw) == 17 & abs(sum(Qw) - 1) < 1e-12)
qt_expect `=qt_ok' "mata(): X and w"
mata: mata drop QX Qw

* one dimension: the 3-node Gauss rules in closed form
ghpos 1 3, matrix(G)
matrix H = (-sqrt(3), 1/6 \ 0, 4/6 \ sqrt(3), 1/6)
qt_expect `=mreldif(G, H) < 1e-12' "GH 3-node rule"
qt_frame quadriceps 3 1 "ghpos 1 3"
ghpos 1, p(4) nonormalize matrix(G)
matrix H = (-sqrt(1.5), sqrt(_pi)/6 \ 0, 4*sqrt(_pi)/6 \ sqrt(1.5), sqrt(_pi)/6)
qt_expect `=mreldif(G, H) < 1e-12' "GH 3-node rule, weight exp(-x^2)"
lepos 1 3, nonormalize matrix(G)
matrix H = (-sqrt(0.6), 5/9 \ 0, 8/9 \ sqrt(0.6), 5/9)
qt_expect `=mreldif(G, H) < 1e-12' "Le 3-node rule on [-1,1]"
lepos 1 3, matrix(G)
matrix H = ((1 - sqrt(0.6))/2, 5/18 \ 0.5, 4/9 \ (1 + sqrt(0.6))/2, 5/18)
qt_expect `=mreldif(G, H) < 1e-12' "Le 3-node rule on [0,1]"

* nonormalize
ghpos 2 4, nonormalize
frame quadriceps {
    summarize w, meanonly
    qt_expect `=abs(r(sum) - _pi) < 1e-12' "GH mass pi"
    generate double f = w * x1^2 * x2^4
    summarize f, meanonly
    qt_expect `=abs(r(sum) - (sqrt(_pi)/2) * (3*sqrt(_pi)/4)) < 1e-12' "GH x1^2 x2^4, weight exp(-|x|^2)"
}
lepos 3 3, nonormalize
qt_expect `=r(normalize) == 0' "r(normalize) with nonormalize"
frame quadriceps {
    summarize w, meanonly
    qt_expect `=abs(r(sum) - 8) < 1e-12' "Le mass 8"
    summarize x1, meanonly
    qt_expect `=r(min) > -1 & r(max) < 1' "Le nodes inside [-1,1]^3"
    generate double f = w * x1^2 * x3^2
    summarize f, meanonly
    qt_expect `=abs(r(sum) - 8/9) < 1e-12' "Le x1^2 x3^2 over [-1,1]^3"
    replace f = w * x1 * x2^2
    summarize f, meanonly
    qt_expect `=abs(r(sum)) < 1e-14' "Le odd moment"
}

* nnodes, ruleinfo, check
quadriceps nnodes gh 5 7
qt_expect `=r(n) == 1135' "nnodes gh 5 7 = 1135"
quadriceps nnodes le 2, p(10)
local n10 = r(n)
quadriceps nnodes le 2 6
qt_expect `=r(n) == `n10'' "nnodes: p(10) and q = 6 agree"
quadriceps ruleinfo gh 4 5
qt_expect `=r(nfactors) == 1 & "`r(origin1)'" != ""' "ruleinfo gh 4 5: one factor"
quadriceps ruleinfo gh 7 5, pragmatic
qt_expect `=r(nfactors) == 2' "ruleinfo gh 7 5 pragmatic: two factors"
matrix F = r(factors)
qt_expect `=F[1,1] + F[2,1] == 7' "ruleinfo: factor dimensions sum to 7"
qt_expect `=F[1,3] * F[2,3] == r(n)' "ruleinfo: node counts multiply to r(n)"
qt_expect `="`r(origin1)'" != "" & "`r(origin2)'" != ""' "ruleinfo: origins"
quadriceps ruleinfo gh 1 4
qt_expect `=r(nfactors) == 1 & "`r(origin1)'" == "Gauss" & r(n) == 4' "ruleinfo gh 1 4: Gauss"
quadriceps check gh 4 5
qt_expect `=r(err) < `GATE' & r(n) > 0' "check gh 4 5"
quadriceps check le 1 30
qt_expect `=r(err) < 1e-13' "check le 1 30"
quadriceps check gh 1 25
qt_expect `=r(err) < 1e-12' "check gh 1 25"
quadriceps rules gh
quadriceps rules le
quadriceps rules
quadriceps version
qt_expect `=r(cells) > 100' "version: cells"

* no rule: error unless pragmatic
qt_rc 499 "gh six dimensions" ghpos 6 3
qt_rc 499 "le six dimensions" lepos 6 3
qt_rc 499 "gh d = 3 beyond the degrees" ghpos 3 40
qt_rc 499 "gh d = 3 beyond the degrees, even p" ghpos 3, p(78)
qt_rc 499 "nnodes beyond the degrees" quadriceps nnodes le 4 40
qt_rc 499 "no rule with frame(): frame not created" ghpos 6 3, frame(nosuchrule)
capture frame drop nosuchrule
qt_expect `=_rc != 0' "no rule with frame(): frame nosuchrule does not exist"
quadriceps nnodes gh 6 3, pragmatic
qt_expect `=r(n) <= 3^6' "fallback no dearer than the grid"

* argument errors
qt_rc 198 "neither q nor p" ghpos 2
qt_rc 198 "both q and p" ghpos 2 3, p(5)
qt_rc 198 "d = 0" ghpos 0 3
qt_rc 198 "q = 0" ghpos 2 0
qt_rc any "p = -1" ghpos 2, p(-1)
qt_rc 198 "fractional d" ghpos 2.5 3
qt_rc 198 "three arguments" ghpos 2 3 4
qt_rc 198 "unknown family" quadriceps nnodes la 2 3
qt_rc 198 "unknown subcommand" quadriceps foo 2 3
qt_rc any "current frame" ghpos 2 2, frame(default)

* pragmatic fallback
ghpos 4 5, pragmatic matrix(A)
ghpos 4 5, matrix(B)
qt_expect `=mreldif(A, B) == 0' "stored GH cell unchanged by pragmatic"
lepos 2 11, pragmatic matrix(A)
lepos 2 11, matrix(B)
qt_expect `=mreldif(A, B) == 0' "stored Le cell unchanged by pragmatic"
foreach fam in gh le {
    foreach dq in "6 4" "7 3" "8 2" {
        tokenize `dq'
        local d `1'
        local q `2'
        quadriceps nnodes `fam' `d' `q', pragmatic
        local n = r(n)
        quadriceps `fam' `d' `q', pragmatic
        qt_expect `=r(n) == `n' & r(pragmatic) == 1' "fallback `fam' d=`d' q=`q': size"
        qt_frame quadriceps `n' `d' "fallback `fam' d=`d' q=`q'"
        frame quadriceps {
            summarize w, meanonly
            qt_expect `=abs(r(sum) - 1) < 1e-12' "fallback `fam' d=`d' q=`q': weights sum to 1"
        }
        quadriceps check `fam' `d' `q', pragmatic
        qt_expect `=r(err) < `GATE'' "fallback `fam' d=`d' q=`q': exactness"
        quadriceps ruleinfo `fam' `d' `q', pragmatic
        matrix F = r(factors)
        local sumd 0
        local prodn 1
        forvalues k = 1/`=rowsof(F)' {
            local sumd = `sumd' + F[`k', 1]
            local prodn = `prodn' * F[`k', 3]
        }
        qt_expect `=`sumd' == `d' & `prodn' == `n'' "fallback `fam' d=`d' q=`q': ruleinfo"
        local cheapest 1
        forvalues j = 1/`=floor(`d' / 2)' {
            quadriceps nnodes `fam' `j' `q', pragmatic
            local nj = r(n)
            quadriceps nnodes `fam' `=`d' - `j'' `q', pragmatic
            if `n' > `nj' * r(n) local cheapest 0
        }
        qt_expect `cheapest' "fallback `fam' d=`d' q=`q': cheapest split"
    }
}
lepos 6 2, nonormalize pragmatic
frame quadriceps {
    summarize w, meanonly
    qt_expect `=abs(r(sum) - 2^6) < 1e-10' "fallback with nonormalize: mass 64"
    generate double f = w * x6^2
    summarize f, meanonly
    qt_expect `=abs(r(sum) - 2^6/3) < 1e-10' "fallback with nonormalize: x6^2"
}
quadriceps nnodes gh 60 16, pragmatic
qt_expect `=r(n) > 2^53' "huge counts are reported"
qt_rc 498 "huge rules are refused" ghpos 60 16, pragmatic

* --- every stored rule, in Mata ------------------------------------------------------------

mata:
QT_mchecks = 0
QT_mfails = J(0, 1, "")
void qt_mexpect(real scalar ok, string scalar what)
{
    external real scalar QT_mchecks
    external string colvector QT_mfails
    QT_mchecks = QT_mchecks + 1
    if (!ok) {
        QT_mfails = QT_mfails \ what
        printf("{err}FAIL: %s\n", what)
    }
}
GATE = 1e-11
quadriceps_catalog(M = J(0, 0, .), origin = J(0, 1, ""))
qt_mexpect(rows(M) > 100 & all(mod(M[., 3], 2) :== 1) & all(M[., 2] :>= 2) & all(M[., 4] :== (M[., 3] :+ 1) / 2), "catalog")
qt_mexpect(all(M[., 10] :< GATE) & all(M[., 11] :> 0), "catalog: relerr and minweight")
for (i = 1; i <= rows(M); i++) {
    fam = M[i, 1]
    famname = (fam ? "le" : "gh")
    d = M[i, 2]
    p = M[i, 3]
    n = M[i, 5]
    id = sprintf("%s d=%g p=%g", famname, d, p)
    quadriceps_rule(famname, d, p, 0, 1, X = J(0, 0, .), w = J(0, 1, .))
    qt_mexpect(rows(X) == n & cols(X) == d & rows(w) == n, id + " size")
    qt_mexpect(all(w :> 0), id + " positive weights")
    qt_mexpect(abs(sum(w) - 1) <= 1e-12, id + " weights sum to 1")
    qt_mexpect(quadriceps_exactness(X, w, p, famname) < GATE, id + " exactness")
    if (fam == 1) qt_mexpect(all(X :> 0) & all(X :< 1), id + " interior")
    qt_mexpect(quadriceps_nnodes(famname, d, p, 0) <= n, id + " monotone")
    qt_mexpect(quadriceps_nnodes(famname, d, p, 1) == quadriceps_nnodes(famname, d, p, 0), id + " no product beats it")
    X2 = J(0, 0, .)
    w2 = J(0, 1, .)
    if (fam == 0) ghpos(d, (p + 1) / 2, X2, w2)
    else lepos(d, (p + 1) / 2, X2, w2)
    qt_mexpect(X2 == X & w2 == w, id + " q form")
}
// beyond the stored degrees: the fallback is no dearer than the grid
for (fam = 0; fam <= 1; fam++) {
    famname = (fam ? "le" : "gh")
    q = max(select(M[., 4], M[., 1] :== fam :& M[., 2] :== 3)) + 1
    qt_mexpect(quadriceps_nnodes(famname, 3, 2 * q - 1, 1) <= q^3, famname + " beyond the degrees: fallback no dearer than the grid")
}
// d = 4 beyond the degrees: the split 2 + 2 into stored rules beats the grid
q = max(select(M[., 4], M[., 1] :== 0 :& M[., 2] :== 4)) + 1
quadriceps_rule("gh", 4, 2 * q - 1, 1, 1, X = J(0, 0, .), w = J(0, 1, .))
qt_mexpect(rows(X) == quadriceps_nnodes("gh", 4, 2 * q - 1, 1) & rows(X) < q^4, "gh d = 4 beyond the degrees: size")
qt_mexpect(all(w :> 0) & abs(sum(w) - 1) < 1e-12 & quadriceps_exactness(X, w, 2 * q - 1, "gh") < GATE, "gh d = 4 beyond the degrees: valid")
// the data file
fh = fopen(findfile("quadriceps_rules.bin"), "r")
B = fread(fh, 200)
fclose(fh)
qt_mexpect(substr(B, 1, strpos(B, char(10)) - 1) == sprintf("QUADRICEPS1 fmt=1 endian=little cells=%g index_fields=8 float=binary64 order=row-major layout=x1..xd,w families=0:gh,1:le", rows(M)), "header of quadriceps_rules.bin")
printf("{txt}Mata: %g checks, %g failed\n", QT_mchecks, rows(QT_mfails))
st_global("QT_mchecks", strofreal(QT_mchecks))
st_global("QT_mfailed", strofreal(rows(QT_mfails)))
st_global("QT_mfails", (rows(QT_mfails) ? invtokens((QT_mfails :+ "; ")') : ""))
end

* --- summary ---------------------------------------------------------------------------------

capture frame drop quadriceps
local checks = $QT_checks + $QT_mchecks
local failed = $QT_failed + $QT_mfailed
display as text _n "`checks' checks, " cond(`failed', "{err}", "{res}") "`failed' failed"
if `failed' {
    display as error "failed:"
    display as error `"$QT_fails"'
    display as error `"$QT_mfails"'
}
log close qt
if `failed' error 9
