* xtcsddiag_example.do: examples for xtcsddiag, xtcdmax and xtcollin
* 16 APEC economies, 2000-2023: ecological footprint (EF), internet use (NET), trade (GLB)
version 14
clear all
set more off
use xtcsddiag_apec, clear
xtset id year
generate lnEF = ln(EF)
generate NET2 = NET^2

* 1. Residual diagnostics: CCE (default), mean group, two-way fixed effects
xtcsddiag lnEF NET NET2 GLB, seed(20261025)
xtcsddiag lnEF NET NET2 GLB, estimator(mg) seed(20261025) units
xtcsddiag lnEF NET NET2 GLB, estimator(fe) seed(20261025) generate(e_fe)
return list
matrix list r(table)

* 2. Cross-sectional dependence of the residuals
xtcdmax e_fe
xtcdmax lnEF NET NET2 GLB          // residuals of unit-by-unit OLS

* 3. Collinearity of the design each estimator uses
xtreg lnEF NET NET2 GLB, fe
xtcollin, vdp
xtcollin NET NET2 GLB, transform(twoway)
xtcollin NET NET2 GLB, transform(fd)
xtcollin NET NET2 GLB, transform(cce) ccevars(lnEF NET NET2 GLB) units
xtcollin NET NET2 GLB, transform(none) units
