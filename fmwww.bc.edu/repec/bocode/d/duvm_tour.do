* duvm_tour.do — a guided tour of duvm on the Mexican cereal groups (ENIGH 2014).
* Run from the folder that holds mexico_2014_cereals.dta (net get duvm).
clear all
set more off
use mexico_2014_cereals, clear
describe w* luv* hhsize hh_current_inc psu sweight rururb sex educ age decile quintile

* 1. What will the data support?  (no estimation yet)
duvmdiag corn wheat rice other [aw=sweight], hhsize(hhsize) expend(hh_current_inc) ///
    cluster(psu) region(rururb) indcat(sex educ) indcon(age)

* 2. The model, linearized standard errors clustered by psu (the default)
duvm corn wheat rice other [aw=sweight], hhsize(hhsize) expend(hh_current_inc) ///
    cluster(psu) region(rururb) indcat(sex educ) indcon(age)
estat quality
estat elasticities, unrestricted
estat elasticities, noquality

* 3. Unweighted, as in Deaton's original programs
duvm corn wheat rice other, hhsize(hhsize) expend(hh_current_inc) ///
    cluster(psu) region(rururb) indcat(sex educ) indcon(age)

* 4. The survey design: strata and PSUs read from svyset
svyset psu [pweight=sweight], strata(strata) vce(linearized) singleunit(missing)
duvm corn wheat rice other, hhsize(hhsize) expend(hh_current_inc) ///
    cluster(psu) region(rururb) indcat(sex educ) indcon(age) vce(svy)

* 5. The bootstrap of both stages (200 replications), and Deaton's shortcut
duvm corn wheat rice other [aw=sweight], hhsize(hhsize) expend(hh_current_inc) ///
    cluster(psu) region(rururb) indcat(sex educ) indcon(age) vce(bootstrap, reps(200) seed(1))
duvm corn wheat rice other [aw=sweight], hhsize(hhsize) expend(hh_current_inc) ///
    cluster(psu) region(rururb) indcat(sex educ) indcon(age) vce(bootstrap, reps(200) seed(1) shortcut)

* 6. Own-price elasticities by decile of per capita expenditure
duvm corn wheat rice other [aw=sweight], hhsize(hhsize) expend(hh_current_inc) ///
    cluster(psu) region(rururb) indcat(sex educ) indcon(age) hgroup(decile)

* 7. Unit values corrected for the selection of the buyers (Heckman). The
*    diagnostic first (Table D3): for other cereals, bought by 16% of the
*    households, the Mills ratio is almost collinear with ln x and the warning
*    advises to leave the good uncorrected; the correction is then applied to
*    the other three goods. The coefficient of the Mills ratio is under Table 3
duvmdiag corn wheat rice other [aw=sweight], hhsize(hhsize) expend(hh_current_inc) ///
    cluster(psu) region(rururb) indcat(sex educ) indcon(age) selection
duvm corn wheat rice other [aw=sweight], hhsize(hhsize) expend(hh_current_inc) ///
    cluster(psu) region(rururb) indcat(sex educ) indcon(age) selgoods(corn wheat rice)

* 8. The formulas of the Stata code published with Deaton (1997), for the record
*    (unweighted, as his code is), and one of its departures from the book alone
duvm corn wheat rice other, hhsize(hhsize) expend(hh_current_inc) ///
    cluster(psu) region(rururb) indcat(sex educ) indcon(age) compat vce(none)
duvm corn wheat rice other, hhsize(hhsize) expend(hh_current_inc) ///
    cluster(psu) region(rururb) indcat(sex educ) indcon(age) compatflags(sign) vce(none)

* 9. The tables with significance stars, and the same tables written to a file
*    (the extension gives the format: .docx .tex .xlsx .csv .md; give a full
*    path to write elsewhere than the current folder)
duvm corn wheat rice other [aw=sweight], hhsize(hhsize) expend(hh_current_inc) ///
    cluster(psu) region(rururb) indcat(sex educ) indcon(age) stars
duvm, stars dec(2)
duvm corn wheat rice other [aw=sweight], hhsize(hhsize) expend(hh_current_inc) ///
    cluster(psu) region(rururb) indcat(sex educ) indcon(age) notable saveres(duvm_results.docx)
duvm corn wheat rice other [aw=sweight], hhsize(hhsize) expend(hh_current_inc) ///
    cluster(psu) region(rururb) indcat(sex educ) indcon(age) hgroup(quintile) notable saveres(duvm_results.tex)

* 10. Engel curves: the budget share, the unit value (quality) and the quantity,
*     as variables (predict) and as graphs (estat engel)
duvm corn wheat rice other [aw=sweight], hhsize(hhsize) expend(hh_current_inc) ///
    cluster(psu) region(rururb) indcat(sex educ) indcon(age) notable
predict w_corn, share good(corn)
predict se_w_corn, share good(corn) stdp
predict lnv_*, quality
predict lnq_*, quantity
estat engel
estat engel, quality lnx
estat engel, quantity normalize
drop w_corn se_w_corn lnv_* lnq_*

* 11. The stored results
duvm corn wheat rice other [aw=sweight], hhsize(hhsize) expend(hh_current_inc) ///
    cluster(psu) region(rururb) indcat(sex educ) indcon(age) notable
ereturn list
matrix list e(elast_price), format(%8.4f)
matrix list e(se_elast_price), format(%8.4f)
