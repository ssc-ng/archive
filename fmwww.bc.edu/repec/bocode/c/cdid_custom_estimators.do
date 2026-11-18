*! cdid_custom_estimators.do: user-written treatment estimators through Mata callbacks
*! Requires cdid 1.0.0.0 on StataNow 19.5; the ordinary-mode steps also require csdid 2.0.2.
*! Run the whole file with:  do cdid_custom_estimators.do
version 19.5
clear
mata: mata mlib index

* -----------------------------------------------------------------------------
* 1. Define two callbacks (see help cdid_custom for the full interface)
* -----------------------------------------------------------------------------
* my_att      weighted difference in mean outcome changes between treated and
*             comparison units, for panel comparisons (r.panel == 1).
* my_rcs_att  weighted four-cell contrast of means, for comparisons supplied as
*             stacked observations (r.panel == 0): repeated cross sections and
*             ordinary-mode unbalanced panels.
* Both ignore covariates (r.covariates); they illustrate the interface only.
* The optional payload is a Mata scalar that counts calls.

mata:
struct cdid_callback_result scalar my_att(
    struct cdid_callback_request scalar r, pointer() scalar payload)
{
    real scalar m, mt, mc
    real colvector dy, wt, wc, psi
    if (payload != NULL) *payload = *payload + 1
    if (r.panel != 1) _error(498)
    m = rows(r.D)
    dy = r.y1 - r.y0
    wt = r.i_weights :* r.D
    wc = r.i_weights :* (1 :- r.D)
    if (sum(wt) <= 0 | sum(wc) <= 0) _error(459)
    mt = sum(wt :* dy) / sum(wt)
    mc = sum(wc :* dy) / sum(wc)
    psi = m :* (wt :* (dy :- mt) / sum(wt) - wc :* (dy :- mc) / sum(wc))
    return(cdid_callback_result_make(mt - mc, psi, psi / m))
}

struct cdid_callback_result scalar my_rcs_att(
    struct cdid_callback_request scalar r, pointer() scalar payload)
{
    real scalar m, d, p, sign, mu, att
    real colvector weight, psi
    if (payload != NULL) *payload = *payload + 1
    if (r.panel != 0) _error(498)
    m = rows(r.D); att = 0; psi = J(m, 1, 0)
    for (d = 0; d <= 1; d++) for (p = 0; p <= 1; p++) {
        weight = r.i_weights :* (r.D :== d) :* (r.post :== p)
        if (sum(weight) <= 0) _error(459)
        mu = sum(weight :* r.y) / sum(weight)
        sign = (d == p ? 1 : -1)
        att = att + sign * mu
        psi = psi + sign * m :* weight :* (r.y :- mu) / sum(weight)
    }
    return(cdid_callback_result_make(att, psi, J(0, 1, .)))
}
end

* -----------------------------------------------------------------------------
* 2. Simulate a staggered panel with missing unit-period observations
* -----------------------------------------------------------------------------
* 400 units observed 2001 to 2008; cohorts first treated in 2004, 2006 and
* 2007, plus never-treated units (first_treat = 0); about 10% of unit-period
* observations are missing.

set seed 2026
quietly set obs 400
generate long id = _n
generate double u = runiform()
generate int first_treat = cond(u < .3, 0, cond(u < .55, 2004, cond(u < .8, 2006, 2007)))
generate double x = rnormal()
quietly expand 8
bysort id: generate int year = 2000 + _n
generate double y = 0.3*(year - 2000) + 0.5*x + (first_treat > 0 & year >= first_treat) + rnormal()
quietly drop if runiform() < .1
drop u

* -----------------------------------------------------------------------------
* 3. Chained estimation with the panel callback
* -----------------------------------------------------------------------------
mata: my_calls = 0
cdid y x, ivar(id) time(year) gvar(first_treat) method(custom) callback(my_att) payload(my_calls)
mata: printf("my_att was called %g times\n", my_calls)
estat simple

* -----------------------------------------------------------------------------
* 4. Ordinary estimation on the balanced subpanel with the same callback
* -----------------------------------------------------------------------------
cdid y x, ivar(id) time(year) gvar(first_treat) mode(ordinary) method(custom) callback(my_att)
estat simple

* -----------------------------------------------------------------------------
* 5. Ordinary estimation keeping unbalanced units: stacked comparisons
* -----------------------------------------------------------------------------
cdid y, ivar(id) time(year) gvar(first_treat) mode(ordinary) allowunbalanced ///
    method(custom) callback(my_rcs_att)

* -----------------------------------------------------------------------------
* 6. Conditional pretrend test in ordinary mode with the callback
* -----------------------------------------------------------------------------
cdid_pretest y x, ivar(id) time(year) gvar(first_treat) mode(ordinary) ///
    method(custom) callback(my_att) biters(199)
return list
