* polycopula_examples.do -- examples from the article
version 14
clear all
set more off
webuse gsem_cfa, clear
polycopula att1 att2 att3
* simulated lower-tail dependence (Clayton, tau = .5)
clear
set seed 12
set obs 2000
gen double u = runiform()
gen double w = runiform()
gen double v = (u^(-2)*(w^(-2/3) - 1) + 1)^(-1/2)
gen byte x = (u > .2) + (u > .5) + (u > .8)
gen byte y = (v > .35) + (v > .75)
polytest x y u, seed(1) triplets
polycopula x y

* robust polychoric under careless responding (10% uniform answers, 5-point items)
clear
set seed 31
set obs 1000
matrix C = (1, .5 \ .5, 1)
drawnorm z1 z2, corr(C)
gen byte x = (z1 > -1.5) + (z1 > -.5) + (z1 > .5) + (z1 > 1.5)
gen byte y = (z2 > -1.5) + (z2 > -.5) + (z2 > .5) + (z2 > 1.5)
gen byte careless = runiform() < .1
replace x = floor(5*runiform()) if careless
replace y = floor(5*runiform()) if careless
polycopula x y, copulas(gaussian) robust
polycopula x y, copulas(gaussian) robust cutoff(.3)
