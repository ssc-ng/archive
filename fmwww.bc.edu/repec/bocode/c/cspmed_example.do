* cspmed_example.do
* Examples for cspmed: causal mediation analysis for cross-sectional and
* complex-survey data. All data are simulated with known effects.
* True values for d1 = 1, d0 = 0 in the linear designs (Parts A, C, D):
*   NDE = 1.5,  NIE via m1 = 0.8*1.0 = 0.8,  NIE via m2 = -0.5*0.6 = -0.3
*   NIE = 0.5,  TE = 2.0,  PM = 0.25

clear all
set more off
set seed 20261114

* =====================================================================
* PART A. Complex survey: 5 strata x 20 PSUs x 15 respondents,
*         sampling weights and intra-cluster correlation
*         estimator: ols
* =====================================================================
set obs 100
gen psu     = _n
gen stratum = ceil(psu/20)
gen double r_d  = rnormal()
gen double r_m1 = rnormal()
gen double r_m2 = rnormal()
gen double r_y  = rnormal()
expand 15
gen double x  = rnormal() + 0.5*stratum
gen double d  = 0.5*x + 0.7*r_d + rnormal()
gen double m1 =  0.8*d + 0.3*x + 0.5*r_m1 + rnormal()
gen double m2 = -0.5*d + 0.3*x + 0.5*r_m2 + rnormal()
gen double y  = 1.5*d + 1.0*m1 + 0.6*m2 + 0.5*x + 0.8*r_y + rnormal()
gen double wt = runiform(1, 3)
drop r_*

* 1. Ignoring the design (understates the uncertainty here)
cspmed y, treatment(d) mediators(m1 m2) controls(x)

* 2. Design-based inference: declare the design once with svyset ...
svyset psu [pw = wt], strata(stratum)
cspmed y, treatment(d) mediators(m1 m2) controls(x) svy

* 3. ... or give it directly (identical results)
cspmed y [pw = wt], treatment(d) mediators(m1 m2) controls(x) cluster(psu) strata(stratum) nodiag

* 4. Treatment x mediator interactions in the outcome model
cspmed y, treatment(d) mediators(m1 m2) controls(x) svy interaction nodiag

* 5. PSU bootstrap within strata
cspmed y, treatment(d) mediators(m1 m2) controls(x) svy bootstrap(199) seed(1) nodiag

* 6. Stored results (e(diag) exists only when nodiag is not specified)
quietly cspmed y, treatment(d) mediators(m1 m2) controls(x) svy
ereturn list
matrix list e(effects)
matrix list e(diag)

* =====================================================================
* PART B. Binary outcome and binary mediator
*         estimators: logit, probit (counterfactual effects)
* =====================================================================
gen double u1 = runiform()
gen double u2 = runiform()
* latent-index models with logistic errors
gen byte m2b = (-0.2 - 0.5*d + 0.3*x + ln(u1/(1 - u1)) > 0)
gen byte yb  = (-0.5 + 1.5*d + 1.0*m1 + 0.6*m2b + 0.5*x - 2 + ln(u2/(1 - u2)) > 0)
drop u1 u2

* 7. Logit outcome; m1 continuous (Gaussian model) and m2b binary (logit model);
*    effects are differences in counterfactual probabilities
cspmed yb, treatment(d) mediators(m1 m2b) controls(x) estimator(logit) svy

* 8. Probit outcome
cspmed yb, treatment(d) mediators(m1 m2b) controls(x) estimator(probit) svy nodiag

* 9. Logit with a treatment x mediator interaction
cspmed yb, treatment(d) mediators(m1 m2b) controls(x) estimator(logit) svy interaction nodiag

* =====================================================================
* PART C. Endogenous treatment and endogenous mediators
*         estimator: iv (external instruments and Lewbel instruments)
* =====================================================================
clear
set obs 3000
gen double x1 = rnormal()
gen double x2 = rnormal()
gen double z  = rnormal()                      // instrument for the treatment
gen double U  = rnormal()                      // unobserved confounder
gen double d  = 0.8*z + 0.5*x1 + 0.6*U + rnormal()
* mediator errors are heteroskedastic in x1 and x2 (needed for Lewbel instruments)
gen double m1 =  0.8*d + 0.3*x1 + 0.3*x2 + 0.7*U + exp(0.5*x1 + 0.3*x2)*rnormal()
gen double m2 = -0.5*d + 0.3*x1 + 0.3*x2 - 0.5*U + exp(0.4*x2)*rnormal()
gen double y  = 1.5*d + 1.0*m1 + 0.6*m2 + 0.5*x1 + 0.5*x2 + U + rnormal()

* 10. OLS is biased: U confounds treatment, mediators and outcome
cspmed y, treatment(d) mediators(m1 m2) controls(x1 x2) nodiag

* 11. Instrumenting only the treatment: TE is fine, but NDE and NIE are still
*     biased because the mediators are endogenous too (cspmed prints a note)
cspmed y, treatment(d) mediators(m1 m2) controls(x1 x2) estimator(iv) ivs(z) nodiag

* 12. External instrument for the treatment + Lewbel (2012) heteroskedasticity-
*     based instruments for the mediators: NDE, NIE and TE all identified;
*     check the first-stage F, Hansen J and the heteroskedasticity tests
cspmed y, treatment(d) mediators(m1 m2) controls(x1 x2) estimator(iv) ivs(z) lewbel(mediators)

* 13. Lewbel instruments for both treatment and mediators (no external instrument)
cspmed y, treatment(d) mediators(m1 m2) controls(x1 x2) estimator(iv) lewbel(both) nodiag

* 14. Choosing the heteroskedasticity drivers explicitly
cspmed y, treatment(d) mediators(m1 m2) controls(x1 x2) estimator(iv) ivs(z) lewbel(mediators) lewbelvars(x1 x2) nodiag

* =====================================================================
* PART D. Nonlinear confounding
*         estimator: dml (double machine learning, cross-fitting)
* =====================================================================
clear
set obs 3000
gen double x1 = rnormal()
gen double x2 = rnormal()
gen double d  = tanh(x1) + 0.5*sin(2*x2) + 0.4*x1*x2 + rnormal()
gen double g  = cos(x1) + 0.5*x1*x2
gen double m1 =  0.8*d + g + rnormal()
gen double m2 = -0.5*d + 0.5*g + rnormal()
gen double y  = 1.5*d + 1.0*m1 + 0.6*m2 + sin(x2) + 0.7*x1*x2 + rnormal()

* 15. DML with a cubic series learner and 5 folds
cspmed y, treatment(d) mediators(m1 m2) controls(x1 x2) estimator(dml) poly(3) seed(1)

* 16. For comparison: OLS with linear controls is biased in this design
cspmed y, treatment(d) mediators(m1 m2) controls(x1 x2) nodiag

* =====================================================================
* PART E. Ordered and multinomial outcomes
*         estimators: ologit, oprobit, mlogit, mprobit
*         m1 continuous (Gaussian model), mb binary (logit or probit model)
* =====================================================================
clear
set obs 80
gen psu     = _n
gen stratum = ceil(psu/20)
gen double r_u = rnormal()
expand 20
gen double wt = runiform(1, 3)
gen double x  = rnormal() + 0.3*stratum
gen double d  = 0.5*x + 0.5*r_u + rnormal()
gen double m1 = 0.8*d + 0.3*x + rnormal()
gen byte   mb = runiform() < invlogit(-0.2 - 0.6*d + 0.3*x)
* ordered outcome with 4 categories (e.g. a 1-4 rating): latent logistic index
gen double ys = 0.6*d + 0.5*m1 + 0.4*mb + 0.3*x + 0.4*r_u + logit(runiform())
gen byte   yo = 1 + (ys > -0.5) + (ys > 1) + (ys > 2.5)
* unordered outcome with 3 categories (e.g. inactive, employee, self-employed):
* random-utility model with type-I extreme value errors
gen double u1 = -ln(-ln(runiform()))
gen double u2 =  0.3 + 0.8*d - 0.4*m1 + 0.5*mb + 0.2*x - ln(-ln(runiform()))
gen double u3 = -0.2 - 0.6*d + 0.5*m1 - 0.3*mb + 0.3*x - ln(-ln(runiform()))
gen byte   ym = cond(u1 >= max(u2, u3), 1, cond(u2 >= u3, 2, 3))
drop r_u ys u1 u2 u3
svyset psu [pw = wt], strata(stratum)
tabulate yo
tabulate ym

* 17. Ordered logit: effects on E[yo] (in rating points) and on each Pr(yo = k);
*     the category effects add up to zero
cspmed yo, treatment(d) mediators(m1 mb) controls(x) estimator(ologit) svy

* 18. Ordered probit with treatment x mediator interactions
cspmed yo, treatment(d) mediators(m1 mb) controls(x) estimator(oprobit) svy interaction nodiag

* 19. Multinomial logit (base outcome = lowest category)
cspmed ym, treatment(d) mediators(m1 mb) controls(x) estimator(mlogit) svy

* 20. Multinomial probit
cspmed ym, treatment(d) mediators(m1 mb) controls(x) estimator(mprobit) svy nodiag

* 21. The outcome model is the usual one: compare the log likelihood with mprobit
display "cspmed log likelihood: " e(ll)
mprobit ym d m1 mb x [pw = wt], baseoutcome(1)
display "mprobit log likelihood: " e(ll)

* 22. Effects for one category, e.g. the NIE on Pr(ym = 2), with its standard error
quietly cspmed ym, treatment(d) mediators(m1 mb) controls(x) estimator(mlogit) svy nodiag
matrix E = e(effects)
display "NIE on Pr(ym = 2) = " el(E, rownumb(E, "c2:NIE"), 1) ///
    "  (se " el(E, rownumb(E, "c2:NIE"), 2) ")"

* 23. PSU bootstrap
cspmed yo, treatment(d) mediators(m1 mb) controls(x) estimator(ologit) svy bootstrap(199) seed(1) nodiag
