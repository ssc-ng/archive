*******************************************************
* FAILSAFE 0.1.6 -- public examples
*******************************************************
version 14.2
clear all
set more off
set seed 18092060

display as text "Example 1: binary logistic model"
set obs 500
gen double x = rnormal()
gen byte group = mod(_n,3) + 1
gen double p = invlogit(-1.4 + .55*x + .20*(group==2) - .15*(group==3))
gen byte y = runiform() < p

logit y x i.group
failsafe
failsafe, cells mincell(5)

display as text _newline "Example 2: clustered VCE with user-specified threshold"
clear
set seed 18092061
set obs 600
gen int hospital = ceil(_n/30)
gen double x = rnormal()
gen double p = invlogit(-1.2 + .5*x)
gen byte y = runiform() < p

logit y x, vce(cluster hospital)
failsafe
failsafe, minclusters(25)

display as text _newline "Example 3: Cox model"
clear
set seed 18092062
set obs 400
gen double x = rnormal()
gen double event_t = -ln(runiform()) / exp(.35*x)
gen double censor_t = 1.5 + 3*runiform()
gen double t = min(event_t, censor_t)
gen byte fail = event_t <= censor_t
stset t, failure(fail)

stcox x
failsafe

display as result _newline "FAILSAFE PUBLIC EXAMPLES COMPLETED."
