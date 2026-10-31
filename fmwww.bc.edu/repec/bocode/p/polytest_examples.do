* polytest_examples.do -- examples from the article
version 14
clear all
set more off
webuse nhanes2f, clear
polytest heartatk diabetes highbp health, triplets seed(1)
polytest weight health highbp, polyserial bins(8) seed(1)

* power illustration: binary items from a non-Gaussian copula
clear
set seed 2026
set obs 2000
gen double f = rnormal()
gen double v = exp(.6*f)
gen byte b1 = f > 0
gen byte b2 = .5*f + sqrt(.75)*rnormal()*v/sqrt(exp(.72)) > .3
gen byte b3 = .4*f + sqrt(.84)*rnormal()*v/sqrt(exp(.72)) > -.4
polycorr b1 b2 b3, fit
polytest b1 b2 b3, seed(4)
