version 14.2
clear all
set more off
set seed 18092026

* modelaudit v0.1.4 — minimal public examples
*
* These examples use simulated data only.

set obs 500

gen double x = rnormal()
gen double z = rnormal()
gen byte y = runiform() < invlogit(-1.8 + .65*x - .25*z)

* Deliberately create a sample change in models that include z.
replace z = . in 1/25

quietly logit y x
estimates store M1

quietly logit y x z
estimates store M2

quietly logit y x z c.x#c.z
estimates store M3

* Compare every model with the first model.
modelaudit M1 M2 M3, focal(x) samples

* Compare each model with the immediately preceding model.
modelaudit M1 M2 M3, focal(x) previous samples

* Raw-coefficient display can be forced explicitly.
quietly regress x z
estimates store R1

quietly regress x z c.z#c.z
estimates store R2

modelaudit R1 R2, focal(z) coef
